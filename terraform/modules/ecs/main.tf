# ECS Cluster
resource "aws_ecs_cluster" "backend_cluster" {
  name = "${var.environment}-ecs-cluster"
}

resource "aws_iam_role" "ecs_task_execution" {
  count = var.use_existing_iam_role ? 0 : 1

  name               = "${var.environment}-ecs-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  count = var.use_existing_iam_role ? 0 : 1

  role       = aws_iam_role.ecs_task_execution[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Referenciar el ARN del rol existente si no se puede crear uno
locals {
  ecs_task_execution_role_arn = var.use_existing_iam_role ? var.existing_iam_role_arn : aws_iam_role.ecs_task_execution[0].arn
}

variable "orders_service_env" {
  type = map(string)
  default = {}
}

locals {
  orders_service_env = {
    PAYMENTS_URL = "http://${var.ecs_alb_dns}/payments"
    SHIPPING_URL = "http://${var.ecs_alb_dns}/shipping"
    PRODUCTS_URL = "http://${var.ecs_alb_dns}/products"
  }
}

# ECS Task Definitions
resource "aws_ecs_task_definition" "tasks" {
  count                 = length(var.services)
  family                = var.services[count.index]
  network_mode          = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                   = "256"
  memory                = "512"
  execution_role_arn    = local.ecs_task_execution_role_arn
  container_definitions = jsonencode([{
    name      = var.services[count.index]
    image     = "${var.dockerhub_username}/${var.services[count.index]}:${var.environment}-${var.github_sha}"
    cpu       = 256
    memory    = 512
    essential = true
    portMappings = [ {
      containerPort = 8080
      protocol      = "tcp"
    } ]
    environment = var.services[count.index] == "orders" ? [
      {
        name  = "PAYMENTS_URL"
        value = local.orders_service_env.PAYMENTS_URL
      },
      {
        name  = "SHIPPING_URL"
        value = local.orders_service_env.SHIPPING_URL
      },
      {
        name  = "PRODUCTS_URL"
        value = local.orders_service_env.PRODUCTS_URL
      }
    ] : []
  }])
}

# ECS Services
resource "aws_ecs_service" "services" {
  count = length(var.services)
  name                = var.services[count.index]
  cluster             = aws_ecs_cluster.backend_cluster.id
  task_definition     = aws_ecs_task_definition.tasks[count.index].arn
  desired_count       = 1
  launch_type         = "FARGATE"
  network_configuration {
    subnets          = var.private_subnets
    security_groups  = [aws_security_group.ecs_service.id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = var.ecs_tg_arn[count.index]
    container_name   = var.services[count.index]
    container_port   = 8080
  }
}

resource "aws_security_group" "ecs_service" {
  name        = "${var.environment}-ecs-sg"
  vpc_id      = var.vpc_id
  description = "Allow ALB to communicate with ECS tasks"

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
    self = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
