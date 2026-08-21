# ==============================================================================
# Purpose: Implements hardened AWS ECR Private Registry with KMS encryption,
#          immutable tags, automated scan-on-push, and lifecycle retention.
# ==============================================================================

data "aws_caller_identity" "current" {}

# 1. Customer Managed KMS Key for ECR Image Encryption
resource "aws_kms_key" "ecr_kms_key" {
  description             = "Customer managed KMS Key for ECR image layer encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootPermissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion",
          "kms:GenerateDataKey*",
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*"
        ]
        Resource = "*"
      }
    ]
  })
}

# 2. Hardened ECR Repository
resource "aws_ecr_repository" "secure_registry" {
  name                 = var.repository_name
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.ecr_kms_key.arn
  }
}

# 3. ECR Lifecycle Policy (Prunes untagged images older than 14 days)
resource "aws_ecr_lifecycle_policy" "cleanup_policy" {
  repository = aws_ecr_repository.secure_registry.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images older than 14 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 14
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}