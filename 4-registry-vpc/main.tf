module "my_vpc" {
  # GitHub source with an exact Git Commit Hash
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git?ref=2980145ed022a18f26a11e8609bebf7662c5b967"

  name = "portfolio-registry-vpc"
  cidr = var.vpc_cidr

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = false
  enable_vpn_gateway = false

  tags = {
    Environment = "dev"
    Portfolio   = "terraform-aws-portfolio"
  }
}