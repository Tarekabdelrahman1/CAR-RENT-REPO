output "web_instance_ids" {
  description = "IDs of the web tier EC2 instances"
  value       = aws_instance.web_server[*].id
}

output "web_private_ips" {
  description = "Private IPs of the web tier EC2 instances"
  value       = aws_instance.web_server[*].private_ip
}