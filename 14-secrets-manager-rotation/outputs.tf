output "secret_arn" {
  description = "ARN of the provisioned AWS Secret"
  value       = aws_secretsmanager_secret.db_secret.arn
}

output "kms_key_arn" {
  description = "ARN of the KMS Key used to encrypt the secret"
  value       = aws_kms_key.secrets_key.arn
}

output "rotation_lambda_arn" {
  description = "ARN of the Lambda function handling secret rotation"
  value       = aws_lambda_function.rotator.arn
}