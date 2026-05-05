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

variable "app_sg_id" {
  type = string
}
variable "aws_region" {
  description = "AWS region used to select the AMI"
  type        = string
}
variable "iam_instance_profile_name" {
  type    = string
  default = null
}

variable "db_secret_arn" {
  type    = string
  default = null
}
variable "db_host" {
  type    = string
  default = null
}

variable "db_name" {
  type    = string
  default = "carrent"
}

variable "db_port" {
  type    = number
  default = 5432
}