terraform {
  backend "s3" {
    bucket         = "my-car-rent-terraform-state-bucket" # MUST exist in AWS first!
    key            = "dev/terraform.tfstate"             
    region         = "us-east-1"
    profile        = "demo"                               
    dynamodb_table = "terraform-state-lock"               # MUST exist in AWS first for state lock!
  }
}
