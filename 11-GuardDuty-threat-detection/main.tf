# ==============================================================================
# Purpose: Enables GuardDuty threat detection & builds automated SNS incident alerting.
# ==============================================================================

# 1. Enable GuardDuty Detector with S3 Protection
resource "aws_guardduty_detector" "primary" {
  enable = true

  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = false
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = true
        }
      }
    }
  }
}

# 2. KMS Key for Encrypting SNS Topic
resource "aws_kms_key" "sns_encryption_key" {
  description             = "KMS Key for GuardDuty SNS Topic encryption"
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
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowEventBridgeToUseKey"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey*"
        ]
        Resource = "*"
      }
    ]
  })
}

data "aws_caller_identity" "current" {}

# 3. Encrypted SNS Topic for Security Alerts
resource "aws_sns_topic" "guardduty_alerts" {
  name              = "guardduty-high-severity-alerts"
  kms_master_key_id = aws_kms_key.sns_encryption_key.id
}

# 4. EventBridge Rule filtering High Severity Findings (Severity >= 7.0)
resource "aws_cloudwatch_event_rule" "guardduty_high_severity" {
  name        = "guardduty-high-severity-findings"
  description = "Captures high severity GuardDuty findings (severity >= 7)"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
    detail = {
      severity = [
        7, 7.0, 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7, 7.8, 7.9,
        8, 8.0, 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7, 8.8, 8.9
      ]
    }
  })
}

# 5. SNS Topic Policy allowing EventBridge publisher
resource "aws_sns_topic_policy" "default" {
  arn = aws_sns_topic.guardduty_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEventBridgePublish"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.guardduty_alerts.arn
      }
    ]
  })
}

# 6. EventBridge Target connecting Rule to SNS Topic
resource "aws_cloudwatch_event_target" "sns_target" {
  rule      = aws_cloudwatch_event_rule.guardduty_high_severity.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.guardduty_alerts.arn
}