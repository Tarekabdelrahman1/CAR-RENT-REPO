resource "aws_instance" "web_server" {
  count = local.current_setup.instance_count

  ami           = local.current_ami
  instance_type = local.current_setup.instance_size

  # round robin to distribute created servers on the available web subnets
  subnet_id              = var.private_subnet_ids[count.index % length(var.private_subnet_ids)]
  vpc_security_group_ids = [var.web_sg_id]

  # Store the Internal ALB URL on the Web instance.
  # The Web Tier should not talk to App instances directly.
  # Instead, it sends backend/API traffic to the Internal ALB,
  # and the Internal ALB forwards requests to the App Tier target group.
  #
  # This file is a temporary handoff point for manual testing now,
  # and later Ansible can read or replace it when deploying the web app.
  user_data = <<-EOF
    #!/bin/bash
    echo "APP_BACKEND_URL=${var.app_backend_url}" > /etc/car-rent-web.env
  EOF

  user_data_replace_on_change = true

  tags = {
    Name          = "${var.project_name}-${var.environment}-web-${count.index + 1}"
    Environment   = var.environment
    AppBackendURL = var.app_backend_url
  }
}