module "network" {
  source = "../../modules/network"

  project_name = "car-rent"
  environment  = "dev"

  vpc_cidr = "10.0.0.0/16"

  azs = [
    "us-east-1a",
    "us-east-1b"
  ]

  public_subnet_cidrs = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]

  private_web_subnets = {
    "us-east-1a" = "10.0.11.0/24"
    "us-east-1b" = "10.0.12.0/24"
  }

  private_app_subnets = {
    "us-east-1a" = "10.0.21.0/24"
    "us-east-1b" = "10.0.22.0/24"
  }

  private_db_subnets = {
    "us-east-1a" = "10.0.31.0/24"
    "us-east-1b" = "10.0.32.0/24"
  }
}

module "security" {
  source = "../../modules/security"

  project_name = "car-rent"
  environment  = "dev"

  vpc_id = module.network.vpc_id

  create_rds_sg = true

  extra_tags = {
    Team = "DevOps-Team"
  }
}

module "web_tier" {
  source = "../../modules/web_tier"

  project_name = "car-rent"
  environment  = "dev"
  aws_region   = "us-east-1"

  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_web_subnet_ids
  web_sg_id          = module.security.web_tier_sg_id
}