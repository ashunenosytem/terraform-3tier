resource "aws_instance" "backend" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.backend_sg.id]
  key_name      = "bastion-new"
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    amazon-linux-extras install docker -y
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ec2-user

    yum install git -y

    cd /home/ec2-user
    git clone https://github.com/Ashutosh-Ahirwar/ExpenseTracker.git
    cd ExpenseTracker/backend

    cat <<EOT > .env
    PORT=5000
    MONGO_URI=mongodb://${aws_instance.database.private_ip}:27017/expense
    EOT

    cat <<EOT > Dockerfile
    FROM node:18
    WORKDIR /app
    COPY package*.json ./
    RUN npm install
    COPY . .
    EXPOSE 5000
    CMD ["npm", "start"]
    EOT

    docker build -t expense-backend .
    docker run -d \
      --restart always \
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
  key_name      = "bastion-new"
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
  key_name      = "bastion-new"

  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

  tags = {
    Name = "bastion-host"
  }
}

