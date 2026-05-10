# 1. Launch Template: The blueprint for the Web Tier instances
resource "aws_launch_template" "web_lt" {
  name_prefix   = "${var.project_name}-${var.environment}-web-lt-"
  image_id      = local.current_ami
  instance_type = local.current_setup.instance_size

  iam_instance_profile {
    name = var.iam_instance_profile_name
  }

  network_interfaces {
    associate_public_ip_address = false # Web servers in private subnets
    security_groups             = [var.web_sg_id]
  }

  # User data must be Base64 encoded for Launch Templates
  # This stores the Internal ALB URL for the application backend
  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo "APP_BACKEND_URL=${var.app_backend_url}" > /etc/car-rent-web.env
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name          = "${var.project_name}-${var.environment}-web"
      Environment   = var.environment
      AppBackendURL = var.app_backend_url
      Tier          = "web"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# 2. Autoscaling Group: Manages the fleet of Web servers
resource "aws_autoscaling_group" "web_asg" {
  name                = "${var.project_name}-${var.environment}-web-asg"
  
  # Automatically distributes instances across web subnets (replacing manual modulo logic)
  vpc_zone_identifier = var.private_subnet_ids

  # Define scaling boundaries
  desired_capacity = local.current_setup.instance_count
  min_size         = 1
  max_size         = 5 

  launch_template {
    id      = aws_launch_template.web_lt.id
    version = "$Latest"
  }

  # Health check settings
  health_check_type         = "EC2"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-web-asg"
    propagate_at_launch = true # Inherit this tag on all instances created by this ASG
  }
}
