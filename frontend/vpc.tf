resource "aws_vpc" "frontend" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-frontend-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.frontend.id
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.frontend.id
  cidr_block              = "10.10.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-frontend-public-subnet"
  }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.frontend.id
}
resource "aws_route" "internet" {
  route_table_id         = aws_route_table.rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.rt.id
}
