# 1. KMS Key for CloudWatch Logs
resource "aws_kms_key" "log_key" {
  description             = "KMS key for CloudWatch log group encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::123456789012:root" #  Restricted to account root instead of "*"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
}

#  CloudWatch Log Group with KMS & 365 Days Retention
resource "aws_cloudwatch_log_group" "vpc_log_group" {
  name              = "/aws/vpc-flow-log/modular-vpc"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.log_key.arn
}

# 2. IAM Role for VPC Flow Logs
resource "aws_iam_role" "vpc_flow_log_role" {
  name = "vpc-flow-log-role"

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

# 3. VPC Configuration
resource "aws_vpc" "custom_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "modular-vpc"
  }
}

# 4. VPC Flow Logging Enabled 
resource "aws_flow_log" "vpc_flow_log" {
  iam_role_arn    = aws_iam_role.vpc_flow_log_role.arn
  log_destination = aws_cloudwatch_log_group.vpc_log_group.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.custom_vpc.id
}

# 5. Restrict Default Security Group 
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.custom_vpc.id
}

# 6. Public Subnet (Fixes - map_public_ip set to false)
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.custom_vpc.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = false

  tags = {
    Name = "modular-public-subnet"
  }
}

# 7. Security Group for SSH 
resource "aws_security_group" "ssh_sg" {
  name        = "ssh-security-group"
  description = "Security group allowing restricted SSH access"
  vpc_id      = aws_vpc.custom_vpc.id

  ingress {
    description = "Allow SSH access from specific admin IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # Restricted range instead of 0.0.0.0/0
  }

  egress {
    description = "Allow HTTPS outbound traffic only"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

# 8. Key Pair
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key-workspace"
  public_key = file("${path.module}/id_rsa.pub")
}

# 9. IAM Role & Instance Profile for EC2 
resource "aws_iam_role" "ssh_server_role" {
  name = "ssh-server-ec2-role"

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

resource "aws_iam_instance_profile" "ssh_server_profile" {
  name = "ssh-server-ec2-profile"
  role = aws_iam_role.ssh_server_role.name
}

# 10. EC2 Instance
resource "aws_instance" "ssh_server" {
  ami                  = "ami-0c7217cdde317cfec"
  instance_type        = var.instance_type
  subnet_id            = aws_subnet.public_subnet.id
  key_name             = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.ssh_sg.id]
  iam_instance_profile = aws_iam_instance_profile.ssh_server_profile.name

  root_block_device {
    encrypted = true
  }

  monitoring    = true
  ebs_optimized = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2
    http_put_response_hop_limit = 1
  }

  tags = {
    Name = "Modular-Secured-EC2"
  }
}