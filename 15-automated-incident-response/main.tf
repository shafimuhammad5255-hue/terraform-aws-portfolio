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

# AWS അക്കൗണ്ട് ഐഡി എടുക്കാൻ
data "aws_caller_identity" "current" {}

resource "random_id" "bucket_id" {
  byte_length = 4
}

# --- KMS Key for Encryption ---

resource "aws_kms_key" "secops_key" {
  description             = "KMS key for SecOps Incident Response resources"
  enable_key_rotation     = true
  deletion_window_in_days = 7

  # CKV2_AWS_64 പരിഹരിക്കാനുള്ള പോളിസി
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
      }
    ]
  })
}

resource "aws_kms_alias" "secops_key_alias" {
  name          = "alias/secops-remediation-key"
  target_key_id = aws_kms_key.secops_key.key_id
}

# --- S3 Production Environment ---

# checkov:skip=CKV_AWS_144: Cross-region replication not required for logs in this architecture
# checkov:skip=CKV2_AWS_62: Event notifications not required for access logs bucket
resource "aws_s3_bucket" "s3_access_logs" {
  bucket = "secops-access-logs-${random_id.bucket_id.hex}"
}

# CKV_AWS_21 പരിഹരിക്കാൻ Log Bucket Versioning
resource "aws_s3_bucket_versioning" "log_bucket_versioning" {
  bucket = aws_s3_bucket.s3_access_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# CKV2_AWS_61 പരിഹരിക്കാൻ Log Bucket Lifecycle
resource "aws_s3_bucket_lifecycle_configuration" "log_bucket_lifecycle" {
  bucket = aws_s3_bucket.s3_access_logs.id
  rule {
    id     = "log-expiration"
    status = "Enabled"
    expiration {
      days = 90
    }
  }
}

resource "aws_s3_bucket_public_access_block" "log_bucket_pab" {
  bucket                  = aws_s3_bucket.s3_access_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "log_bucket_enc" {
  bucket = aws_s3_bucket.s3_access_logs.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.secops_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# checkov:skip=CKV_AWS_144: Multi-region setup is out of scope for this specific single-region architecture
# checkov:skip=CKV_AWS_53: Skip PAB block_public_acls for demo to test auto-remediation
# checkov:skip=CKV_AWS_54: Skip PAB block_public_policy for demo to test auto-remediation
# checkov:skip=CKV_AWS_55: Skip PAB ignore_public_acls for demo to test auto-remediation
# checkov:skip=CKV_AWS_56: Skip PAB restrict_public_buckets for demo to test auto-remediation
# checkov:skip=CKV2_AWS_6: Skip general PAB check for demo
resource "aws_s3_bucket" "demo_security_bucket" {
  bucket = "secops-demo-bucket-${random_id.bucket_id.hex}"
}

# CKV2_AWS_61 പരിഹരിക്കാൻ Demo Bucket Lifecycle
resource "aws_s3_bucket_lifecycle_configuration" "demo_bucket_lifecycle" {
  bucket = aws_s3_bucket.demo_security_bucket.id
  rule {
    id     = "demo-expiration"
    status = "Enabled"
    expiration {
      days = 30
    }
  }
}

resource "aws_s3_bucket_versioning" "demo_bucket_versioning" {
  bucket = aws_s3_bucket.demo_security_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "demo_logging" {
  bucket        = aws_s3_bucket.demo_security_bucket.id
  target_bucket = aws_s3_bucket.s3_access_logs.id
  target_prefix = "demo-bucket-logs/"
}

resource "aws_s3_bucket_notification" "demo_bucket_notification" {
  bucket      = aws_s3_bucket.demo_security_bucket.id
  eventbridge = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "demo_bucket_enc" {
  bucket = aws_s3_bucket.demo_security_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.secops_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# --- IAM Roles & Policies ---

resource "aws_iam_role" "lambda_exec_role" {
  name = "secops-lambda-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# checkov:skip=CKV_AWS_274: Admin/FullAccess is required for the lambda to revert broad S3 public access settings dynamically.
resource "aws_iam_role_policy_attachment" "lambda_s3_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy" "lambda_prod_permissions" {
  name = "lambda_prod_permissions"
  role = aws_iam_role.lambda_exec_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["xray:PutTraceSegments", "xray:PutTelemetryRecords"]
        Resource = "*" 
      },
      {
        Effect = "Allow"
        Action = ["sqs:SendMessage"]
        Resource = aws_sqs_queue.lambda_dlq.arn 
      },
      {
        Effect = "Allow"
        Action = ["kms:GenerateDataKey", "kms:Decrypt"]
        Resource = aws_kms_key.secops_key.arn 
      }
    ]
  })
}

# --- Lambda Production Environment ---

resource "aws_sqs_queue" "lambda_dlq" {
  name                              = "secops-remediation-dlq"
  kms_master_key_id                 = aws_kms_key.secops_key.arn
  kms_data_key_reuse_period_seconds = 300
}

resource "aws_signer_signing_profile" "lambda_signer" {
  platform_id = "AWSLambda-SHA384-ECDSA"
}

resource "aws_lambda_code_signing_config" "lambda_signing_config" {
  allowed_publishers {
    signing_profile_version_arns = [aws_signer_signing_profile.lambda_signer.version_arn]
  }
  policies {
    untrusted_artifact_on_deployment = "Enforce"
  }
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "lambda_function.py"
  output_path = "lambda_function.zip"
}

# checkov:skip=CKV_AWS_117: Architectural Decision - Lambda only calls AWS public APIs (S3).
resource "aws_lambda_function" "secops_auto_remediation" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "s3-public-access-auto-remediator"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  reserved_concurrent_executions = 50

  code_signing_config_arn = aws_lambda_code_signing_config.lambda_signing_config.arn 

  tracing_config {
    mode = "Active"
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_dlq.arn
  }
}

# --- EventBridge Resources ---

resource "aws_cloudwatch_event_rule" "s3_public_access_rule" {
  name        = "detect-s3-public-access"
  description = "Triggers Lambda when someone attempts to make an S3 bucket public"

  event_pattern = jsonencode({
    source = ["aws.s3"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventName = [
        "PutBucketAcl",
        "PutBucketPublicAccessBlock",
        "PutBucketPolicy"
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "trigger_lambda" {
  rule      = aws_cloudwatch_event_rule.s3_public_access_rule.name
  target_id = "TriggerAutoRemediationLambda"
  arn       = aws_lambda_function.secops_auto_remediation.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.secops_auto_remediation.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.s3_public_access_rule.arn
}