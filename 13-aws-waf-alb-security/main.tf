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

resource "aws_wafv2_web_acl" "main" {
  name        = "${var.environment}-alb-waf"
  description = "Production WAF WebACL protecting ALB against OWASP Top 10"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  # Rule 1: AWS Managed Common Rule Set (OWASP Top 10 Risks)
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

  # Rule 2: SQL Injection & Bad Inputs Prevention
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

  # Rule 3: Anti-DDoS Rate Limiting (1000 requests per 5 mins per IP)
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

# (WAF2 Logging Configuration)

# WAF ലോഗുകൾ സ്റ്റോർ ചെയ്യാനുള്ള CloudWatch Log Group (പേര് 'aws-waf-logs-' എന്ന് തുടങ്ങണം)
resource "aws_cloudwatch_log_group" "waf_log_group" {
  name              = "aws-waf-logs-${var.environment}-alb"
  retention_in_days = 30

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# WAF-നെ CloudWatch Log Group-മായി ബന്ധിപ്പിക്കുന്ന Logging Configuration
resource "aws_wafv2_web_acl_logging_configuration" "main" {
  log_destination_configs = [aws_cloudwatch_log_group.waf_log_group.arn]
  resource_arn            = aws_wafv2_web_acl.main.arn
}