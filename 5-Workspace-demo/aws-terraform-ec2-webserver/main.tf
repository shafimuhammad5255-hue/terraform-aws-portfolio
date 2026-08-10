terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# 1. VPC
resource "aws_vpc" "custom_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "modular-vpc"
  }
}

# 2. Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.custom_vpc.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "modular-public-subnet"
  }
}

# 3. Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.custom_vpc.id

  tags = {
    Name = "modular-igw"
  }
}

# 4. Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.custom_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "modular-public-rt"
  }
}

# 5. Route Table Association
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# 6. Key Pair (Key File local-ൽ ഉണ്ടായിരിക്കണം)
resource "aws_key_pair" "deployer" {
  key_name   = var.key_name
  public_key = file("${path.module}/my-aws-key.pub")
}

# 7. Security Group
resource "aws_security_group" "ssh_sg" {
  name        = "modular-ssh-sg"
  description = "Allow SSH access"
  vpc_id      = aws_vpc.custom_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # ആവശ്യമുണ്ടെങ്കിൽ സ്വന്തം IP നൽകാം
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 8. EC2 Instance
resource "aws_instance" "ssh_server" {
  ami                    = "ami-0c7217cdde317cfec" # Ubuntu 26.04 LTS
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_subnet.id
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.ssh_sg.id]

  tags = {
    Name = "Modular-Secured-EC2"
  }
}