terraform {
  required_version = ">= 1.5.0"
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

# AWS Caller Identity & Region for KMS Key Policy
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# --- KMS Key Policy Document for CloudWatch Logs ---
# ts:skip=CKV_AWS_111 Suppress wildcard action check for KMS root delegation
# ts:skip=CKV_AWS_109 Suppress permissions management constraint for KMS root policy
# ts:skip=CKV_AWS_356 Suppress wildcard resource constraint as KMS key policy requires '*' to avoid circular dependency
data "aws_iam_policy_document" "waf_kms_policy" {
  #checkov:skip=CKV_AWS_111: "Root account delegation requires kms:* actions"
  #checkov:skip=CKV_AWS_109: "Root account policy manages permissions for the key itself"
  #checkov:skip=CKV_AWS_356: "KMS Key policies require resource * by design"

  statement {
    sid    = "EnableRootPermissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowCloudWatchLogs"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = ["*"]
  }
}

# --- KMS Key with Policy (CKV_AWS_158, CKV2_AWS_64) ---
resource "aws_kms_key" "waf_log_key" {
  description             = "KMS Key for WAF CloudWatch Log Group"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.waf_kms_policy.json

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "DevSecOps-Portfolio"
  }
}

# --- CloudWatch Log Group with 365 Days Retention (CKV_AWS_338) ---
resource "aws_cloudwatch_log_group" "waf_log_group" {
  name              = "aws-waf-logs-${var.environment}-alb"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.waf_log_key.arn

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# --- WAF Web ACL ---
resource "aws_wafv2_web_acl" "main" {
  name        = "${var.environment}-alb-waf"
  description = "Production WAF WebACL protecting ALB against OWASP Top 10"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  # Rule 1: AWS Managed Common Rule Set
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 10

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSCommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  # Rule 2: SQL Injection & Bad Inputs
  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 20

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "KnownBadInputsMetric"
      sampled_requests_enabled   = true
    }
  }

  # Rule 3: Anti-DDoS Rate Limiting
  rule {
    name     = "RateLimitRule"
    priority = 30

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.rate_limit
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.environment}-web-acl-metric"
    sampled_requests_enabled   = true
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "DevSecOps-Portfolio"
  }
}

# --- WAF Logging Configuration (CKV2_AWS_31) ---
resource "aws_wafv2_web_acl_logging_configuration" "main" {
  log_destination_configs = [aws_cloudwatch_log_group.waf_log_group.arn]
  resource_arn            = aws_wafv2_web_acl.main.arn
}