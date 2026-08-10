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

# Workspace അനുസരിച്ച് Instance Type മാറ്റുന്നു
locals {
  instance_type = {
    default = "t3.micro"
    dev     = "t3.micro"
    prod    = "t3.small"
  }
}

resource "aws_instance" "my_app" {
  ami           = "ami-0c7217cdde317cfec" # Ubuntu AMI
  instance_type = lookup(local.instance_type, terraform.workspace, "t3.micro")

  tags = {
    Name        = "App-Server-${terraform.workspace}"
    Environment = terraform.workspace
  }
}