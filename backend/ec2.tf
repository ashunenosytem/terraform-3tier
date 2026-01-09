resource "aws_instance" "backend" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.backend_sg.id]
  key_name               = "bastionNew"

  user_data = <<-EOF
#!/bin/bash
set -e
exec > /var/log/user-data.log 2>&1

yum update -y
amazon-linux-extras install docker -y
systemctl start docker
systemctl enable docker

# allow ec2-user to run docker
usermod -aG docker ec2-user

yum install git -y

cd /home/ec2-user
git clone https://github.com/Ashutosh-Ahirwar/ExpenseTracker.git
cd ExpenseTracker/backend

# ---- PATCH server.js (listen on all interfaces) ----
sed -i 's/app.listen(PORT/app.listen(PORT, "0.0.0.0"/' server.js

# ---- ENV FILE (CRITICAL FIX) ----
cat <<EOT > .env
PORT=5000
MONGO_URI=mongodb://${aws_instance.database.private_ip}:27017/expense
JWT_SECRET=e581372412881a8a196c46b1d9d13f45a42be030085c4ba2baad205a8bd822c3
CLIENT_URL=*
EOT

# ---- DOCKERFILE ----
cat <<EOT > Dockerfile
FROM node:18
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 5000
CMD ["npm", "start"]
EOT

# ---- BUILD & RUN ----
docker build -t expense-backend .

docker run -d \
  --restart always \
  --name expense-backend \
  -p 5000:5000 \
  --env-file .env \
  expense-backend
EOF

  depends_on = [aws_instance.database]

  tags = {
    Name = "backend-ec2"
  }
}


resource "aws_instance" "database" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private_db.id
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  key_name      = "bastionNew"
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    amazon-linux-extras install docker -y
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ec2-user

    docker run -d \
      --name mongodb \
      --restart always \
      -p 27017:27017 \
      -v mongo-data:/data/db \
      mongo:6
  EOF
  tags = {
    Name = "mongodb-ec2"
  }
}
resource "aws_instance" "bastion" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public.id
  key_name      = "bastionNew"

  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

  tags = {
    Name = "bastion-host"
  }
}

