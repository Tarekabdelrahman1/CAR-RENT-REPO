variable "project_name" {
  type = string
}

variable "environment" {
  type        = string
  description = "dev, test, or prod"
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "web_sg_id" {
  type = string
}
variable "aws_region" {
  description = "AWS region used to select the AMI"
  type        = string
}