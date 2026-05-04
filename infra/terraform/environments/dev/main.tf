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