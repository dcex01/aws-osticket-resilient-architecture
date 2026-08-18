locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ==========================================================
# Application Load Balancer
# ==========================================================

resource "aws_lb" "main" {
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    var.alb_security_group_id
  ]

  subnets = var.public_subnet_ids

  enable_deletion_protection = false

  tags = {
    Name = "${local.name_prefix}-alb"
  }
}

# ==========================================================
# Target Group
# ==========================================================

resource "aws_lb_target_group" "helpdesk" {
  name = "${local.name_prefix}-tg"

  port     = 80
  protocol = "HTTP"

  vpc_id = var.vpc_id

  target_type = "instance"

  deregistration_delay = 30

  health_check {
    enabled = true

    protocol = "HTTP"
    path     = "/"
    port     = "traffic-port"

    healthy_threshold   = 2
    unhealthy_threshold = 3

    interval = 30
    timeout  = 5

    matcher = "200-399"
  }

  tags = {
    Name = "${local.name_prefix}-tg"
  }
}

# ==========================================================
# HTTP Listener
# ==========================================================

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn

  port     = 80
  protocol = "HTTP"

  default_action {
    type = "forward"

    target_group_arn = aws_lb_target_group.helpdesk.arn
  }
}