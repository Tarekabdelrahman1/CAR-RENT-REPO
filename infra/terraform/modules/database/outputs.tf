output "db_endpoint" {
  value = aws_db_instance.main.address
}

output "db_port" {
  value = aws_db_instance.main.port
}

output "db_name" {
  value = aws_db_instance.main.db_name
}

output "db_master_user_secret_arn" {
  value = aws_db_instance.main.master_user_secret[0].secret_arn
}