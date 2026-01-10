resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
}

# 🔹 Internet Gateway (MANDATORY)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
}

# 🔹 Public subnet (for NAT)
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.20.10.0/24"
  map_public_ip_on_launch = true
   tags = {
    Name = "public-subnet"
  }
}

# 🔹 Private subnet (backend servers)
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.20.1.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "ap-south-1b"
  tags = {
    Name = "private-backend-subnet"
  }
}

resource "aws_subnet" "private1" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.20.3.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "ap-south-1a"
  tags = {
    Name = "private-backend-subnet1"
  }
}
resource "aws_subnet" "private_db" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.20.2.0/24"
  map_public_ip_on_launch = false

  tags = {
    Name = "private-db-subnet"
  }
}


# 🔹 Elastic IP for NAT
resource "aws_eip" "nat" {
  domain = "vpc"
}

# 🔹 NAT Gateway (MUST be public subnet)
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  depends_on = [aws_internet_gateway.igw]
}

# 🔹 Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.this.id
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

# 🔹 Private Route Table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.this.id
}
resource "aws_route_table" "private_rt1" {
  vpc_id = aws_vpc.this.id
}

resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}
resource "aws_route" "private_nat1" {
  route_table_id         = aws_route_table.private_rt1.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private_rt.id
}
resource "aws_route_table_association" "private_db_assoc" {
  subnet_id      = aws_subnet.private_db.id
  route_table_id = aws_route_table.private_rt.id
}
resource "aws_route_table_association" "private_assoc1" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_security_group" "bastion_sg" {
  name   = "bastion-sg"
  vpc_id = aws_vpc.this.id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # replace this
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
