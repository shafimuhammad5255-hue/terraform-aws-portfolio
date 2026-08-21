variable "aws_region" {
  description = "AWS deployment region"
  type        = string
  default     = "us-east-1"
}

variable "repository_name" {
  description = "Name of the secure private ECR repository"
  type        = string
  default     = "production-secure-microservices"
}