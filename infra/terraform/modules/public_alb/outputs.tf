output "alb_arn" {
  description = "Public ALB ARN"
  value       = aws_lb.public_alb.arn
}

output "alb_dns_name" {
  description = "Public ALB DNS name"
  value       = aws_lb.public_alb.dns_name
}

output "alb_zone_id" {
  description = "Public ALB hosted zone ID"
  value       = aws_lb.public_alb.zone_id
}

output "web_target_group_arn" {
  description = "Web target group ARN"
  value       = aws_lb_target_group.web_tg.arn
}

output "http_listener_arn" {
  description = "HTTP listener ARN"
  value       = aws_lb_listener.http.arn
}