variable "aws_region" {
  description = "AWS deployment region"
  type        = string
  default     = "us-east-1"
}

variable "alert_email" {
  description = "Security alert notification endpoint email"
  type        = string
  default     = "security-ops@example.com"
}