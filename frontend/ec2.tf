resource "aws_instance" "frontend" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public-frontend.id
  vpc_security_group_ids      = [aws_security_group.frontend_sg.id]
  associate_public_ip_address = true
user_data = templatefile("${path.module}/frontend-userdata.sh", {
  backend_private_ip = var.backend-alb-dns
})

  tags = {
    Name = "frontend-ec2"
  }
}
