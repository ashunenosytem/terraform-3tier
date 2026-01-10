resource "aws_vpc" "frontend" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-frontend-vpc"
  }
}

resource "aws_internet_gateway" "igw-frontend" {
  vpc_id = aws_vpc.frontend.id
}

resource "aws_subnet" "public-frontend" {
  vpc_id                  = aws_vpc.frontend.id
  cidr_block              = "10.10.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-frontend-public-subnet"
  }
}
resource "aws_subnet" "public1-frontend" {
  vpc_id                  = aws_vpc.frontend.id
  cidr_block              = "10.10.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-frontend-public-subnet1"
  }
}

resource "aws_route_table" "rt-frontend" {
  vpc_id = aws_vpc.frontend.id
}
resource "aws_route_table" "rt1-frontend" {
  vpc_id = aws_vpc.frontend.id
}
resource "aws_route" "internet-frontend" {
  route_table_id         = aws_route_table.rt-frontend.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw-frontend.id
}
resource "aws_route" "internet1-frontend" {
  route_table_id         = aws_route_table.rt1-frontend.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw-frontend.id
}

resource "aws_route_table_association" "assoc-frontend" {
  subnet_id      = aws_subnet.public-frontend.id
  route_table_id = aws_route_table.rt-frontend.id
}
resource "aws_route_table_association" "assoc1-frontend" {
  subnet_id      = aws_subnet.public1-frontend.id
  route_table_id = aws_route_table.rt1-frontend.id
}
# resource "aws_launch_template" "backend_lt" {
#   name_prefix   = "backend-lt-"
#   image_id      = data.aws_ami.amazon_linux.id
#   instance_type = "t3.micro"

#   vpc_security_group_ids = [
#     aws_security_group.backend_sg.id
#   ]
#   user_data = templatefile("${path.module}/frontend-userdata.sh", {
#   backend_private_ip = var.backend_private_ip
# })

# }