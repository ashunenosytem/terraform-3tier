resource "aws_instance" "frontend" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.frontend_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
#!/bin/bash
set -euo pipefail

# Log everything
exec > /var/log/user-data.log 2>&1

echo "===== Frontend user-data started ====="

yum update -y
yum install -y docker git

systemctl start docker
systemctl enable docker

# Clone repo
sudo su -
git clone https://github.com/Ashutosh-Ahirwar/ExpenseTracker.git
cd ExpenseTracker/frontend/expense-tracker

# Inject backend URL
sed -i "s|localhost:5000|${var.backend_url}:5000|g" src/config.js

# Dockerfile (FIXED for Vite)
FROM node:18 as build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOT

# Build & run
docker build -t expense-frontend .
docker run -d \
  --restart always \
  --name expense-frontend \
  -p 80:80 \
  expense-frontend

echo "===== Frontend user-data completed ====="
EOF

  tags = {
    Name = "frontend-ec2"
  }
}
