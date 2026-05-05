resource "aws_lb" "public_alb" {
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-alb"
    Tier = "public"
  })
}

resource "aws_lb_target_group" "web_tg" {
  name        = "${local.name_prefix}-web-tg"
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
    Name = "${local.name_prefix}-web-tg"
    Tier = "web"
  })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.public_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "web" {
  count = length(var.target_ids)

  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = var.target_ids[count.index]
  port             = var.target_port
}