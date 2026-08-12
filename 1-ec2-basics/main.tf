# 0. KMS Key with Restricted Policy for CloudWatch Logs
resource "aws_kms_key" "basics_log_key" {
  description             = "KMS key for EC2 basics CloudWatch log group encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::123456789012:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
}

# CloudWatch Log Group with KMS Encryption & Retention
resource "aws_cloudwatch_log_group" "vpc_log_group" {
  name              = "/aws/vpc-flow-log/basics-vpc"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.basics_log_key.arn
}

# IAM Role for VPC Flow Logs
resource "aws_iam_role" "vpc_flow_log_role" {
  name = "vpc-flow-log-role-basics"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}

# 1. VPC Configuration
resource "aws_vpc" "custom_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "modular-vpc"
  }
}

# Enable VPC Flow Logs
resource "aws_flow_log" "vpc_flow_log" {
  iam_role_arn    = aws_iam_role.vpc_flow_log_role.arn
  log_destination = aws_cloudwatch_log_group.vpc_log_group.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.custom_vpc.id
}

#(Enable Default VPC Security Group Restriction)
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.custom_vpc.id
}

# 2. Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.custom_vpc.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = false #Fixed: Disable auto-assign public IP

  tags = {
    Name = "modular-public-subnet"
  }
}

# 3. Security Group
resource "aws_security_group" "ssh_sg" {
  name        = "modular-ssh-sg"
  description = "Security group for SSH access with strict restrictions"
  vpc_id      = aws_vpc.custom_vpc.id

  ingress {
    description = "Allow SSH from internal VPC CIDR only" 
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr] # Restricted internal network access
  }

  egress {
    description = "Allow HTTPS outbound traffic only" 
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name = "ssh-secured-sg"
  }
}

# 4. Key Pair
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key-basics"
  public_key = file("${path.module}/id_rsa.pub")
}

# 5. IAM Role & Profile for EC2 (Fixes CKV2_AWS_41)
resource "aws_iam_role" "ec2_role" {
  name = "ec2-basics-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-basics-instance-profile"
  role = aws_iam_role.ec2_role.name
}

# 6. EC2 Instance 
resource "aws_instance" "ssh_server" {
  ami                  = "ami-0c7217cdde317cfec"
  instance_type        = var.instance_type
  subnet_id            = aws_subnet.public_subnet.id
  key_name             = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.ssh_sg.id]
  
  # IAM Instance Profile Attached 
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  # Enable EBS Optimization 
  ebs_optimized = true

  # Enable Detailed Monitoring 
  monitoring = true

  # Encrypt EBS Root Volume 
  root_block_device {
    encrypted = true
  }

  # Enforce IMDSv2 
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = {
    Name = "Modular-Secured-EC2"
  }
}