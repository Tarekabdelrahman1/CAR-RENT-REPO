locals {
  prefix    = "${var.project_name}-${var.environment}"
  alb_ports = [80, 443]
}
