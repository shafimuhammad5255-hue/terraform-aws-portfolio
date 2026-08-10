terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# 🚀 AWS Official VPC Module from Terraform Registry
module "my_vpc" {
  source  = "terraform-aws-modules/vpc/aws"  # രജിസ്ട്രിയിലെ ഔദ്യോഗിക പാത്ത്
  version = "5.19.0"                         # മൊഡ്യൂളിന്റെ വേർഷൻ

  name = "My-Production-VPC"
  cidr = "10.0.0.0/16"

  # Availability Zones & Subnets
  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  # NAT Gateway Settings (പ്രൈവറ്റ് സബ്നെറ്റുകൾക്ക് ഇന്റർനെറ്റ് കിട്ടാൻ)
  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Environment = "Dev"
    Terraform   = "true"
  }
}