data "aws_ami" "latest_ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 1. IAM Role for EC2
resource "aws_iam_role" "ec2_role" {
  name = "${var.instance_name}-ec2-role"

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

# 2. IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.instance_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# 3. EC2 Instance Resource
resource "aws_instance" "my_server" {
  ami                  = data.aws_ami.latest_ubuntu.id
  instance_type        = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name #  IAM Profile attached

  root_block_device {
    encrypted = true
  }

  monitoring    = true
  ebs_optimized = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # Enforce IMDSv2
    http_put_response_hop_limit = 1
  }

  tags = {
    Name = var.instance_name
  }
}