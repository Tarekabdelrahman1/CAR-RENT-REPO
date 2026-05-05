locals {


  name_prefix = "${var.project_name}-${var.environment}-public"
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}