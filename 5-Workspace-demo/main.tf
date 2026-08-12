provider "aws" {
  region = "us-east-1"
}

locals {
  instance_type = {
    default = "t3.micro"
    dev     = "t3.micro"
    prod    = "t3.small"
  }
}

# IAM Role for EC2 Instance 
resource "aws_iam_role" "workspace_ec2_role" {
  name = "workspace-ec2-role-${terraform.workspace}"

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

resource "aws_iam_instance_profile" "workspace_ec2_profile" {
  name = "workspace-ec2-profile-${terraform.workspace}"
  role = aws_iam_role.workspace_ec2_role.name
}

# EC2 Instance with Full Security Specs
resource "aws_instance" "my_app" {
  ami                  = "ami-0c7217cdde317cfec" # Ubuntu AMI
  instance_type        = lookup(local.instance_type, terraform.workspace, "t3.micro")
  
  # IAM Instance Profile Attached 
  iam_instance_profile = aws_iam_instance_profile.workspace_ec2_profile.name

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
    Name        = "App-Server-${terraform.workspace}"
    Environment = terraform.workspace
  }
}