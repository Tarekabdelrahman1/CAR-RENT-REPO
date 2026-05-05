# Remote Terraform Backend
# Author: Emad Singab
#
# State is stored in S3 with native S3 locking using `use_lockfile = true`.
# This avoids the older DynamoDB lock table approach.
# The bucket must exist before `terraform init`.
terraform {
  backend "s3" {
    bucket       = "car-rent-terraform-state-bucket"
    key          = "dev/terraform.tfstate"
    region       = "us-east-1"
    profile      = "project"
    use_lockfile = true
  }
}