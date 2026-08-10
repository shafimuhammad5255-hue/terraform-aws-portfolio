terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# 1. Dynamic Block വഴി മൾട്ടിപ്പിൾ Security Group Rules ഉണ്ടാക്കുന്നു
locals {
  ingress_ports = [80, 443, 22, 8080] # Open ആക്കേണ്ട പോർട്ടുകൾ
}

resource "aws_security_group" "web_sg" {
  name        = "dynamic-sg-demo"
  description = "Security Group with Dynamic Ingress Rules"

  # 🚀 Dynamic Block - പോർട്ടുകൾ ഡൈനാമിക് ആയി ലൂപ്പ് ചെയ്യുന്നു
  dynamic "ingress" {
    for_each = local.ingress_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 2. for_each ഉപയോഗിച്ച് വ്യത്യസ്ത പേരുള്ള S3 Buckets ഉണ്ടാക്കുന്നു
resource "aws_s3_bucket" "my_buckets" {
  for_each = toset(["dev-app-data-bucket-9988", "prod-app-data-bucket-9988"])

  bucket = each.value

  tags = {
    Environment = each.key
  }
}