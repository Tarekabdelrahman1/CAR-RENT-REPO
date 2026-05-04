output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_web_subnet_ids" {
  description = "Private web tier subnet IDs"
  value = [
    for key, subnet in aws_subnet.private :
    subnet.id if startswith(key, "web-")
  ]
}

output "private_app_subnet_ids" {
  description = "Private app tier subnet IDs"
  value = [
    for key, subnet in aws_subnet.private :
    subnet.id if startswith(key, "app-")
  ]
}

output "private_db_subnet_ids" {
  description = "Private database tier subnet IDs"
  value = [
    for key, subnet in aws_subnet.private :
    subnet.id if startswith(key, "db-")
  ]
}

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = aws_nat_gateway.public_nat_gw.id
}