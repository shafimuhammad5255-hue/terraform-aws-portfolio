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

# ബക്കറ്റിന്റെ പേര് എല്ലായിടത്തും unique ആകാൻ വേണ്ടിയുള്ള ഒരു random ID
resource "random_id" "bucket_id" {
  byte_length = 4
}

# നമ്മുടെ ടെസ്റ്റിംഗ് ബക്കറ്റ് (The Demo Target)
resource "aws_s3_bucket" "demo_security_bucket" {
  bucket = "secops-demo-bucket-${random_id.bucket_id.hex}"

  tags = {
    Name        = "SecOps Demo Bucket"
    Environment = "Dev"
  }
}
# Lambda-യ്ക്ക് പ്രവർത്തിക്കാനുള്ള IAM Role
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

# S3 പബ്ലിക് ആക്കുന്നത് തടയാൻ Lambda-യ്ക്ക് പെർമിഷൻ കൊടുക്കുന്നു
resource "aws_iam_role_policy_attachment" "lambda_s3_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# 1. പൈത്തൺ ഫയലിനെ ZIP ആക്കി മാറ്റുന്നു
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "lambda_function.py"
  output_path = "lambda_function.zip"
}

# 2. AWS Lambda ഫംഗ്ഷൻ ഡിപ്ലോയ് ചെയ്യുന്നു
resource "aws_lambda_function" "secops_auto_remediation" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "s3-public-access-auto-remediator"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}

# 3. EventBridge Rule: S3 ബക്കറ്റ് പബ്ലിക് ആക്കാൻ ശ്രമിക്കുന്നത് കണ്ടുപിടിക്കാൻ
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

# 4. EventBridge-നെ ലാംഡയുമായി ബന്ധിപ്പിക്കുന്നു
resource "aws_cloudwatch_event_target" "trigger_lambda" {
  rule      = aws_cloudwatch_event_rule.s3_public_access_rule.name
  target_id = "TriggerAutoRemediationLambda"
  arn       = aws_lambda_function.secops_auto_remediation.arn
}

# 5. EventBridge-ന് ലാംഡ റൺ ചെയ്യാനുള്ള പെർമിഷൻ കൊടുക്കുന്നു
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.secops_auto_remediation.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.s3_public_access_rule.arn
}