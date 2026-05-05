locals {
  name_prefix = "${var.project_name}-${var.environment}-internal"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}