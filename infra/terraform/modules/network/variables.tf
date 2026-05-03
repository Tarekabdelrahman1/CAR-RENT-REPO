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
variable "public_1a_cidr" {
  description = "CIDR block for public subnet 1a"
  type        = string
}

variable "public_1b_cidr" {
  description = "CIDR block for public subnet 1b"
  type        = string
}

variable "private_1a_cidr" {
  description = "CIDR block for private subnet 1a"
  type        = string
}

variable "private_1b_cidr" {
  description = "CIDR block for private subnet 1b"
  type        = string
}

variable "az_1a" {
  description = "Availability Zone 1a"
  type        = string
}

variable "az_1b" {
  description = "Availability Zone 1b"
  type        = string
}