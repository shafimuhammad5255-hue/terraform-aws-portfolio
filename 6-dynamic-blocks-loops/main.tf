# 1. KMS Key for S3 Encryption
resource "aws_kms_key" "s3_key" {
  description             = "KMS key for S3 bucket encryption"
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

# 2. Audit Log Bucket (Centralized logging)
resource "aws_s3_bucket" "log_bucket" {
  bucket        = "my-central-audit-log-bucket-9988"
  force_destroy = true

  # checkov:skip=CKV_AWS_18: "This is the target log bucket itself"
  # checkov:skip=CKV_AWS_144: "Cross-region replication not required for lab setup"
  # checkov:skip=CKV2_AWS_62: "Event notifications not required for audit bucket"
}

resource "aws_s3_bucket_versioning" "log_bucket_v" {
  bucket = aws_s3_bucket.log_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "log_bucket_e" {
  bucket = aws_s3_bucket.log_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "log_bucket_p" {
  bucket                  = aws_s3_bucket.log_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "log_bucket_l" {
  bucket = aws_s3_bucket.log_bucket.id

  rule {
    id     = "log_lifecycle"
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


# 3. Main Application S3 Buckets
resource "aws_s3_bucket" "my_buckets" {
  for_each      = toset(["dev-app-data-bucket-9988", "prod-app-data-bucket-9988"])
  bucket        = each.value
  force_destroy = true

  # Suppressing False Positives caused by Checkov not recognizing attached standalone resources
  # checkov:skip=CKV_AWS_21: "Versioning enabled via aws_s3_bucket_versioning"
  # checkov:skip=CKV_AWS_145: "KMS encryption enabled via aws_s3_bucket_server_side_encryption_configuration"
  # checkov:skip=CKV_AWS_18: "Access logging enabled via aws_s3_bucket_logging"
  # checkov:skip=CKV2_AWS_6: "Public access blocked via aws_s3_bucket_public_access_block"
  # checkov:skip=CKV2_AWS_61: "Lifecycle policy configured via aws_s3_bucket_lifecycle_configuration"
  # checkov:skip=CKV2_AWS_62: "Event notifications not needed for application buckets"
  # checkov:skip=CKV_AWS_144: "Cross-region replication not required"

  tags = {
    Environment = each.key
  }
}

# Attachments for my_buckets
resource "aws_s3_bucket_logging" "my_buckets_logging" {
  for_each      = aws_s3_bucket.my_buckets
  bucket        = each.value.id
  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "s3-access-logs/${each.key}/"
}

resource "aws_s3_bucket_versioning" "my_buckets_versioning" {
  for_each = aws_s3_bucket.my_buckets
  bucket   = each.value.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "my_buckets_crypto" {
  for_each = aws_s3_bucket.my_buckets
  bucket   = each.value.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "my_buckets_block" {
  for_each = aws_s3_bucket.my_buckets

  bucket                  = each.value.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "my_buckets_lifecycle" {
  for_each = aws_s3_bucket.my_buckets
  bucket   = each.value.id

  rule {
    id     = "expire_old_versions_and_cleanup"
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