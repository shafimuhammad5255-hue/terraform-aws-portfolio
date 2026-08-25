variable "aws_region" {
  description = "Target AWS Region"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Target Deployment Environment"
  type        = string
  default     = "prod"
}

variable "rate_limit" {
  description = "Max requests allowed per 5 minutes per IP"
  type        = number
  default     = 1000
}