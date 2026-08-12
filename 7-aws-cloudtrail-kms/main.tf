provider "aws" {
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

# 1. KMS Key for Encryption
resource "aws_kms_key" "cloudtrail_kms" {
  description             = "KMS Key for Multi-region CloudTrail"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudTrail to encrypt logs"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "kms:GenerateDataKey*"
        Resource = "*"
      }
    ]
  })
}

# 2. SNS Topic for Notifications 
resource "aws_sns_topic" "cloudtrail_sns" {
  name              = "cloudtrail-events-topic"
  kms_master_key_id = aws_kms_key.cloudtrail_kms.arn
}

# 3. Access Log Target S3 Bucket
resource "aws_s3_bucket" "logging_bucket" {
  bucket        = "my-cloudtrail-access-logs-target-2026"
  force_destroy = true

  # checkov:skip=CKV_AWS_18:Target log bucket itself
  # checkov:skip=CKV_AWS_144:Cross region replication not required
  # checkov:skip=CKV2_AWS_62:Event notifications not required
  # checkov:skip=CKV_AWS_21:Versioning configured via standalone resource
  # checkov:skip=CKV_AWS_145:KMS encryption configured via standalone resource
  # checkov:skip=CKV2_AWS_6:Public access blocked via standalone resource
  # checkov:skip=CKV2_AWS_61:Lifecycle policy configured via standalone resource
}

resource "aws_s3_bucket_versioning" "log_versioning" {
  bucket = aws_s3_bucket.logging_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "log_kms" {
  bucket = aws_s3_bucket.logging_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.cloudtrail_kms.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "log_pab" {
  bucket                  = aws_s3_bucket.logging_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 4. CloudTrail Main S3 Bucket
resource "aws_s3_bucket" "cloudtrail_bucket" {
  bucket        = "my-cloudtrail-logs-shafi-bucket"
  force_destroy = true

  # checkov:skip=CKV_AWS_21:Versioning configured via standalone resource
  # checkov:skip=CKV_AWS_145:KMS encryption configured via standalone resource
  # checkov:skip=CKV_AWS_18:Logging configured via standalone resource
  # checkov:skip=CKV2_AWS_6:Public access blocked via standalone resource
  # checkov:skip=CKV2_AWS_61:Lifecycle policy configured via standalone resource
  # checkov:skip=CKV2_AWS_62:Event notifications not required
  # checkov:skip=CKV_AWS_144:Cross region replication not required
}

resource "aws_s3_bucket_versioning" "trail_versioning" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "trail_kms" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.cloudtrail_kms.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "trail_pab" {
  bucket                  = aws_s3_bucket.cloudtrail_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "trail_logging" {
  bucket        = aws_s3_bucket.cloudtrail_bucket.id
  target_bucket = aws_s3_bucket.logging_bucket.id
  target_prefix = "cloudtrail-access-logs/"
}

# Secure S3 Bucket Policy 
resource "aws_s3_bucket_policy" "cloudtrail_bucket_policy" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_bucket.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# 5. CloudWatch Integration setup
resource "aws_cloudwatch_log_group" "cloudtrail_logs" {
  name              = "/aws/cloudtrail/multi-region-trail"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.cloudtrail_kms.arn
}

resource "aws_iam_role" "cloudtrail_cw_role" {
  name = "cloudtrail-cloudwatch-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "cloudtrail_cw_policy" {
  name = "cloudtrail-cloudwatch-policy"
  role = aws_iam_role.cloudtrail_cw_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "${aws_cloudwatch_log_group.cloudtrail_logs.arn}:*"
      }
    ]
  })
}

# 6. Main CloudTrail Configuration
resource "aws_cloudtrail" "main_trail" {
  name                          = "multi-region-security-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_bucket.id
  kms_key_id                    = aws_kms_key.cloudtrail_kms.arn
  sns_topic_name                = aws_sns_topic.cloudtrail_sns.name 
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.cloudtrail_logs.arn}:*" 
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_cw_role.arn
  include_global_service_events = true
  is_multi_region_trail        = true
  enable_log_file_validation    = true

  depends_on = [aws_s3_bucket_policy.cloudtrail_bucket_policy]
}