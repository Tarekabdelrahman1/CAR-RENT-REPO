###
# network
###
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
######
#security
######
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
#######
# DataBase 
#######
module "database" {
  source = "../../modules/database"

  project_name = "car-rent"
  environment  = "dev"

  db_subnet_ids        = module.network.private_db_subnet_ids
  db_security_group_id = module.security.rds_sg_id

  db_name     = "carrent"
  db_username = "caradmin"

  common_tags = {
    Project     = "car-rent"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

######
# IAM
######
module "iam" {
  source = "../../modules/iam"

  project_name  = "car-rent"
  environment   = "dev"
  db_secret_arn = module.database.db_master_user_secret_arn

  common_tags = {
    Project     = "car-rent"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
######
# app_tier
######
module "app_tier" {
  source = "../../modules/app_tier"

  project_name = "car-rent"
  environment  = "dev"
  aws_region   = "us-east-1"

  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_app_subnet_ids
  app_sg_id          = module.security.app_tier_sg_id

  iam_instance_profile_name = module.iam.app_instance_profile_name

  db_secret_arn = module.database.db_master_user_secret_arn
  db_host       = module.database.db_endpoint
  db_name       = module.database.db_name
  db_port       = module.database.db_port
}
######
# internal_alb
######
module "internal_alb" {
  source = "../../modules/internal_alb"

  project_name = "car-rent"
  environment  = "dev"

  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_app_subnet_ids
  internal_alb_sg_id = module.security.internal_alb_sg_id

  target_ids  = module.app_tier.app_instance_ids
  target_port = 8000
}
######
# web_tier
######
module "web_tier" {
  source = "../../modules/web_tier"

  project_name = "car-rent"
  environment  = "dev"
  aws_region   = "us-east-1"

  vpc_id                    = module.network.vpc_id
  private_subnet_ids        = module.network.private_web_subnet_ids
  web_sg_id                 = module.security.web_tier_sg_id
  iam_instance_profile_name = module.iam.web_instance_profile_name
  app_backend_url           = "http://${module.internal_alb.internal_alb_dns_name}"
}
#######
# public_alb
#######
module "public_alb" {
  source = "../../modules/public_alb"

  project_name      = "car-rent"
  environment       = "dev"
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  alb_sg_id         = module.security.public_alb_sg_id

  target_ids  = module.web_tier.web_instance_ids
  target_port = 80
}
# =========================
# Ansible SSM Bucket
# =========================
module "ansible_ssm" {
  source = "../../modules/ansible_ssm"

  project_name = "car-rent"
  environment  = "dev"

  bucket_name = "car-rent-dev-ansible-ssm-emad"
}