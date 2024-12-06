provider "aws" {
  region = var.aws_region
}

# VPC
resource "aws_vpc" "backend" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.environment}-vpc"
  }
}

data "aws_availability_zones" "available" {}

# Subnets
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.backend.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.environment}-public-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "private" {
  count                   = length(var.private_subnet_cidrs)
  vpc_id                  = aws_vpc.backend.id
  cidr_block              = var.private_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.environment}-private-subnet-${count.index + 1}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.backend.id
}

# NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
}

# Route Table for Public Subnets
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.backend.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_subnet_association" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

# Route Table for Private Subnets
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.backend.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

resource "aws_route_table_association" "private_subnet_association" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_route_table.id
}

# Security Groups
resource "aws_security_group" "alb" {
  name        = "${var.environment}-alb-sg"
  vpc_id      = aws_vpc.backend.id
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

resource "aws_security_group" "ecs_service" {
  name        = "${var.environment}-ecs-sg"
  vpc_id      = aws_vpc.backend.id
  description = "Allow ALB to communicate with ECS tasks"

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

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
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_service.id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tg[count.index].arn
    container_name   = var.services[count.index]
    container_port   = 8080
  }
}

# Load Balancer
resource "aws_lb" "ecs_alb" {
  name               = "${var.environment}-ecs-alb"
  internal           = false
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id
  load_balancer_type = "application"
  enable_deletion_protection = false
}

resource "aws_lb_target_group" "ecs_tg" {
  count       = length(var.services)
  name        = "${var.services[count.index]}-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.backend.id
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

# API Gateway
resource "aws_apigatewayv2_api" "api" {
  name          = var.api_gateway_name
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "stage" {
  api_id = aws_apigatewayv2_api.api.id
  name   = var.environment
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "ecs_integration" {
  count             = length(var.api_routes)
  api_id            = aws_apigatewayv2_api.api.id
  integration_type  = "HTTP_PROXY"
  integration_method = var.api_routes[count.index].method
  integration_uri   = "http://${aws_lb.ecs_alb.dns_name}${var.api_routes[count.index].path}"
}

resource "aws_apigatewayv2_route" "routes" {
  count    = length(var.api_routes)
  api_id   = aws_apigatewayv2_api.api.id
  route_key = "${var.api_routes[count.index].method} ${var.api_routes[count.index].path}"
  target = "integrations/${aws_apigatewayv2_integration.ecs_integration[count.index].id}"
}