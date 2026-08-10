terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # 🚀 updated backend block with S3 Native State Locking
 /* backend "s3" {
    bucket       = "my-tfstate-bucket-2026"
    key          = "global/s3/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true # DynamoDB-ക്ക് പകരം ഇത് നൽകുക
    encrypt      = true
  }*/
}

provider "aws" {
  region = "us-east-1"
}

# 1. State File സൂക്ഷിക്കാൻ Secure S3 Bucket
resource "aws_s3_bucket" "terraform_state" {
  bucket        = "my-tfstate-bucket-2026"
  force_destroy = true

  tags = {
    Name = "Terraform-State-Storage"
  }
}

# S3 Bucket-ൽ Versioning എനേബിൾ ചെയ്യുന്നു
resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}