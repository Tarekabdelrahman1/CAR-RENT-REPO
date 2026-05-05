output "app_instance_ids" {
  description = "IDs of the app tier EC2 instances"
  value       = aws_instance.app_server[*].id
}

output "app_private_ips" {
  description = "Private IPs of the app tier EC2 instances"
  value       = aws_instance.app_server[*].private_ip
}