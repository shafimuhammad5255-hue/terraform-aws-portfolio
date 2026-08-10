variable "instance_type" {
  description = "Type of EC2 Instance"
  type        = string
  default     = "t3.micro"
}

variable "instance_name" {
  description = "Name tag for the instance"
  type        = string
  default     = "My-Module-EC2"
}