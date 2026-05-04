module "network" {
  source = "../../modules/network"

  project_name = "car-rent"
  environment  = "dev"

  vpc_cidr = "10.0.0.0/16"

  public_1a_cidr = "10.0.1.0/24"
  public_1b_cidr = "10.0.2.0/24"

  private_1a_cidr = "10.0.11.0/24"
  private_1b_cidr = "10.0.12.0/24"

  az_1a = "us-east-1a"
  az_1b = "us-east-1b"
}

module "security" {
  source = "../../modules/security"

  project_name = "car-rent"
  environment  = "dev"

  vpc_id = module.network.vpc_id

  create_rds_sg = true
  extra_tags = {
    "Team" = "DevOps-Team"
  }
