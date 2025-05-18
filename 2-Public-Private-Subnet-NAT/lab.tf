# Terraform block
terraform {
  required_version = ">= 1.0.0"
}

# AWS provider
provider "aws" {
  region = "us-east-1"
}

# VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = var.cidr_block["vpc"]
  tags = {
    Name = "Lab2VPC"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "Lab2InternetGateway"
  }
}

# Public Subnet
resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = var.cidr_block["subnet1"]
  map_public_ip_on_launch = true
  tags = {
    Name = "Lab2Subnet1"
  }
}

# Route Table for Public Subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.my_vpc.id
  route {
    cidr_block = var.cidr_block["anyone"]
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "Lab2PublicRouteTable"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.public.id
}

# Public EC2 Instance
resource "aws_instance" "public_instance" {
  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.subnet1.id
  associate_public_ip_address = true
  key_name                    = var.myKey
  vpc_security_group_ids      = [aws_security_group.sg-ec2-public.id]
  tags = {
    Name = "Lab2Instance-public"
  }
}

# Private Subnet
resource "aws_subnet" "subnet2" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = var.cidr_block["subnet2"]
  tags = {
    Name = "Lab2Subnet2"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "ngw" {
  domain = "vpc"
  tags = {
    Name = "Lab2EIP"
  }
}

# NAT Gateway in Public Subnet
resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.ngw.id
  subnet_id     = aws_subnet.subnet1.id
  depends_on    = [aws_internet_gateway.igw]
  tags = {
    Name = "Lab2NATGateway"
  }
}

# Route Table for Private Subnet
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.my_vpc.id
  route {
    cidr_block     = var.cidr_block["anyone"]
    nat_gateway_id = aws_nat_gateway.ngw.id
  }
  tags = {
    Name = "Lab2PrivateRouteTable"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.private.id
}

# Private EC2 Instance
resource "aws_instance" "private_instance" {
  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.subnet2.id
  user_data                   = file("${path.module}/user_data.sh")
  vpc_security_group_ids      = [aws_security_group.sg-ec2-private.id]
  key_name                    = var.myKey
  tags = {
    Name = "Lab2Instance-private"
  }
}

# Security Group for Public Instance
resource "aws_security_group" "sg-ec2-public" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.cidr_block["anyone"]]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.cidr_block["anyone"]]
  }
}

# Security Group for Private Instance
resource "aws_security_group" "sg-ec2-private" {
  name        = "allow_http_and_ssh_from_public"
  description = "Allow HTTP and SSH from public instance"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description     = "Allow HTTP from public subnet"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = [var.cidr_block["subnet1"]]
  }

  ingress {
    description     = "Allow SSH from public EC2 security group"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.sg-ec2-public.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.cidr_block["anyone"]]
  }
}
