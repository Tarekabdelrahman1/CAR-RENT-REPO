locals {
  env_config = {
    dev = {
      instance_size  = "t3.micro"
      instance_count = 1
    }
    test = {
      instance_size  = "t3.small"
      instance_count = 2
    }
    prod = {
      instance_size  = "t3.medium"
      instance_count = 3
    }
  }

  # by default it will use dev enviroment
  current_setup = lookup(local.env_config, var.environment, local.env_config["dev"])

  # AMi to be updated
  region_amis = {
    "us-east-1"  = "ami-0ed094fb1304fd857"
    "eu-west-1"  = "ami-01dd271720c1ba44f"
    "ap-south-1" = "ami-02eb7a4783e7e9317"
  }

  current_ami = lookup(local.region_amis, var.aws_region, local.region_amis["us-east-1"])
}
