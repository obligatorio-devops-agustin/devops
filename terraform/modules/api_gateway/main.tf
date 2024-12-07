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
  integration_uri   = "http://${var.ecs_alb_dns}${var.api_routes[count.index].path}"
}

resource "aws_apigatewayv2_route" "routes" {
  count    = length(var.api_routes)
  api_id   = aws_apigatewayv2_api.api.id
  route_key = "${var.api_routes[count.index].method} ${var.api_routes[count.index].path}"
  target = "integrations/${aws_apigatewayv2_integration.ecs_integration[count.index].id}"
}