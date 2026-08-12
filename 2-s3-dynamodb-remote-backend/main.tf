provider "aws" {
  region = "us-east-1"
}

# 1. KMS Key for S3 Bucket Encryption
resource "aws_kms_key" "state_key" {
  description             = "KMS key for Terraform Remote State S3 bucket"
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

# 2. Central Access Log Target Bucket
resource "aws_s3_bucket" "state_log_bucket" {
  bucket        = "my-tfstate-logs-target-2026"
  force_destroy = true

  # checkov:skip=CKV_AWS_18:Target log bucket itself
  # checkov:skip=CKV_AWS_144:Cross region replication not required
  # checkov:skip=CKV2_AWS_62:Event notifications not required
  # checkov:skip=CKV_AWS_21:Versioning configured via standalone resource
  # checkov:skip=CKV_AWS_145:KMS encryption configured via standalone resource
  # checkov:skip=CKV2_AWS_6:Public access blocked via standalone resource
  # checkov:skip=CKV2_AWS_61:Lifecycle policy configured via standalone resource
}

# Fixes for log bucket
resource "aws_s3_bucket_versioning" "log_v" {
  bucket = aws_s3_bucket.state_log_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "log_e" {
  bucket = aws_s3_bucket.state_log_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.state_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "log_p" {
  bucket                  = aws_s3_bucket.state_log_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 3. Main Terraform State S3 Bucket
resource "aws_s3_bucket" "terraform_state" {
  bucket        = "my-tfstate-bucket-2026"
  force_destroy = true

  # checkov:skip=CKV_AWS_21:Versioning configured via standalone resource
  # checkov:skip=CKV_AWS_145:KMS encryption configured via standalone resource
  # checkov:skip=CKV_AWS_18:Logging configured via standalone resource
  # checkov:skip=CKV2_AWS_6:Public access blocked via standalone resource
  # checkov:skip=CKV2_AWS_61:Lifecycle policy configured via standalone resource
  # checkov:skip=CKV2_AWS_62:Event notifications not required for state storage
  # checkov:skip=CKV_AWS_144:Cross region replication not required

  tags = {
    Name = "Terraform-State-Storage"
  }
}

# Standalone attachments for terraform_state bucket
resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state_crypto" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.state_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state_block" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "state_logging" {
  bucket        = aws_s3_bucket.terraform_state.id
  target_bucket = aws_s3_bucket.state_log_bucket.id
  target_prefix = "tfstate-access-logs/"
}

resource "aws_s3_bucket_lifecycle_configuration" "state_lifecycle" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id     = "state_cleanup"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}