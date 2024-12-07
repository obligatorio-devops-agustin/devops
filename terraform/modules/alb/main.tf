# Load Balancer
resource "aws_lb" "ecs_alb" {
  name               = "${var.environment}-ecs-alb"
  internal           = false
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnets[*]
  load_balancer_type = "application"
  enable_deletion_protection = false
}

resource "aws_lb_target_group" "ecs_tg" {
  count       = length(var.services)
  name        = "${var.services[count.index]}-${var.environment}-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  health_check {
    path                = "/${var.services[count.index]}/health"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }
}

resource "aws_lb_listener" "ecs_listener" {
  load_balancer_arn = aws_lb.ecs_alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_tg[0].arn
  }
}

resource "aws_lb_listener_rule" "ecs_listener_rules" {
  count           = length(var.services)
  listener_arn    = aws_lb_listener.ecs_listener.arn
  priority        = count.index + 1
  condition {
    path_pattern {
      values = ["/${var.services[count.index]}/*"]
    }
  }
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_tg[count.index].arn
  }
}

# Security Groups
resource "aws_security_group" "alb" {
  name        = "${var.environment}-alb-sg"
  vpc_id      = var.vpc_id
  description = "Allow HTTP access for ALB"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}