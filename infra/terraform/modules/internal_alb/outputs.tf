output "internal_alb_arn" {
  description = "Internal ALB ARN"
  value       = aws_lb.internal_alb.arn
}

output "internal_alb_dns_name" {
  description = "Internal ALB DNS name"
  value       = aws_lb.internal_alb.dns_name
}

output "internal_alb_zone_id" {
  description = "Internal ALB hosted zone ID"
  value       = aws_lb.internal_alb.zone_id
}

output "app_target_group_arn" {
  description = "App target group ARN"
  value       = aws_lb_target_group.app_tg.arn
}

output "http_listener_arn" {
  description = "HTTP listener ARN"
  value       = aws_lb_listener.http.arn
}