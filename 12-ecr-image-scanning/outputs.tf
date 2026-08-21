output "ecr_repository_url" {
  description = "The URL of the hardened ECR repository"
  value       = aws_ecr_repository.secure_registry.repository_url
}

output "ecr_kms_key_arn" {
  description = "KMS Key ARN securing the ECR images"
  value       = aws_kms_key.ecr_kms_key.arn
}