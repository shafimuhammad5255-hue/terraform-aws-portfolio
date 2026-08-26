variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Target deployment environment"
  type        = string
  default     = "prod"
}

variable "rotation_days" {
  description = "Number of days between automatic secret rotations"
  type        = number
  default     = 30
}