resource "aws_instance" "app_server" {
  count = local.current_setup.instance_count

  ami                  = local.current_ami
  instance_type        = local.current_setup.instance_size
  iam_instance_profile = var.iam_instance_profile_name

  # round robin to distribute created servers on the available app subnets
  subnet_id              = var.private_subnet_ids[count.index % length(var.private_subnet_ids)]
  vpc_security_group_ids = [var.app_sg_id]

  # Store database connection metadata on the App instance.
  # The database password is not stored here.
  # The App uses DB_SECRET_ARN with its IAM Role to read credentials from Secrets Manager.
  # DB_HOST / DB_NAME / DB_PORT come from the RDS module outputs.
  user_data = <<-EOF
    #!/bin/bash
    cat > /etc/car-rent-app.env <<APPENV
    DB_SECRET_ARN=${var.db_secret_arn}
    DB_HOST=${var.db_host}
    DB_NAME=${var.db_name}
    DB_PORT=${var.db_port}
    APPENV
  EOF

  user_data_replace_on_change = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-app-${count.index + 1}"
    Environment = var.environment
    Tier        = "app"
  }
}