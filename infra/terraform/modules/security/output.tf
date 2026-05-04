output "public_alb_sg_id" {
  value = aws_security_group.public_alb_sg.id
}

output "web_tier_sg_id" {
  value = aws_security_group.web_tier_sg.id
}

output "internal_alb_sg_id" {
  value = aws_security_group.internal_alb_sg.id
}

output "app_tier_sg_id" {
  value = aws_security_group.app_tier_sg.id
}

output "rds_sg_id" {
  value = var.create_rds_sg ? aws_security_group.rds_sg[0].id : null
}
