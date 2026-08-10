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

# Web Server Creation using Module
module "web_server" {
  source        = "./modules/ec2-instance"
  instance_type = "t3.micro"
  instance_name = "WebServer-Modern"
}

# App Server Creation using the Same Module
module "app_server" {
  source        = "./modules/ec2-instance"
  instance_type = "t3.micro"
  instance_name = "AppServer-Modern"
}