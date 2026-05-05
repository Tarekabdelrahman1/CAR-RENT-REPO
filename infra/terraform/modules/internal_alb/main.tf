resource "aws_lb" "internal_alb" {
  name               = "${local.name_prefix}-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [var.internal_alb_sg_id]
  subnets            = var.private_subnet_ids

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-alb"
    Tier = "internal"
  })
}

resource "aws_lb_target_group" "app_tg" {
  name        = "${local.name_prefix}-app-tg"
  port        = var.target_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = var.health_check_path
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200-399"
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-app-tg"
    Tier = "app"
  })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.internal_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "app" {
  count = length(var.target_ids)

  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = var.target_ids[count.index]
  port             = var.target_port
}