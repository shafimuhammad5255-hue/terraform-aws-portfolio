output "demo_bucket_name" {
  description = "The name of the demo S3 bucket created for testing"
  value       = aws_s3_bucket.demo_security_bucket.bucket
}

output "lambda_role_arn" {
  description = "The ARN of the IAM role used by the SecOps Lambda function"
  value       = aws_iam_role.lambda_exec_role.arn
}