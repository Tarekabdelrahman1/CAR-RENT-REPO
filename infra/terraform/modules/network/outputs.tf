output "vpc_id" {
  description = "vpc_id"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "public_subnet_ids"
  value = [
    aws_subnet.public_1a.id,
    aws_subnet.public_1b.id
  ]
}

output "private_subnet_ids" {
  description = "private_subnet_ids"
  value = [
    aws_subnet.private_1a.id,
    aws_subnet.private_1b.id
  ]
}

output "nat_gateway_id" {
  description = "nat gateway id"
  value       = aws_nat_gateway.public_nat_gw.id
}