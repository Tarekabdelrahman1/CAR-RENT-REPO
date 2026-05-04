variable "vpc_id" {
  description = "The ID of the VPC where the security groups will be created"
  type        = string
}

variable "project_name" {
  description = "The name of the project, used as a prefix for naming resources"
  type        = string
}

variable "environment" {
  description = "The deployment environment (e.g., dev, test, prod)"
  type        = string
}

variable "create_rds_sg" {
  description = "A boolean flag to control whether the RDS security group is created or not"
  type        = bool
  default     = true
}

variable "extra_tags" {
  description = "A map of additional tags to apply to the security group resources"
  type        = map(string)
  default = {
    "Team" = "DevOps"
  }
}
