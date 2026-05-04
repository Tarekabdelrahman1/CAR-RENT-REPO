variable "project_name" {
  description = "Project name used for resource naming and tags"
  type        = string
}

variable "environment" {
  description = "Environment name such as dev, staging, or prod"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "azs" {
  description = "Availability zones used by the network module"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_web_subnets" {
  description = "Private web tier subnets as AZ to CIDR map"
  type        = map(string)
}

variable "private_app_subnets" {
  description = "Private app tier subnets as AZ to CIDR map"
  type        = map(string)
}

variable "private_db_subnets" {
  description = "Private database tier subnets as AZ to CIDR map"
  type        = map(string)
}