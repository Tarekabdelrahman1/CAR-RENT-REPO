# 1. Launch Template: Defines the "blueprint" for each EC2 instance
resource "aws_launch_template" "app_lt" {
  name_prefix   = "${var.project_name}-${var.environment}-lt-"
  image_id      = local.current_ami
  instance_type = local.current_setup.instance_size

  iam_instance_profile {
    name = var.iam_instance_profile_name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.app_sg_id]
  }

  # User data must be Base64 encoded for Launch Templates
  user_data = base64encode(<<-EOF
    #!/bin/bash
    cat > /etc/car-rent-app.env <<APPENV
    DB_SECRET_ARN=${var.db_secret_arn}
    DB_HOST=${var.db_host}
    DB_NAME=${var.db_name}
    DB_PORT=${var.db_port}
    APPENV
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.project_name}-${var.environment}-app"
      Environment = var.environment
      Tier        = "app"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# 2. Autoscaling Group: Manages the lifecycle and quantity of instances
resource "aws_autoscaling_group" "app_asg" {
  name                = "${var.project_name}-${var.environment}-asg"
  
  # ASG automatically handles distribution across these subnets (replaces manual modulo math)
  vpc_zone_identifier = var.private_subnet_ids

  # Defined capacity limits
  desired_capacity = local.current_setup.instance_count
  min_size         = 1
  max_size         = 5 

  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }

  # Health monitoring settings
  health_check_type         = "EC2"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-app-asg"
    propagate_at_launch = true # Ensures instances created by ASG receive this tag
  }
}


