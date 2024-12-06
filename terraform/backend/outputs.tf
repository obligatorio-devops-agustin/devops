output "vpc_id" {
  value = aws_vpc.backend.id
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.backend_cluster.name
}

output "api_gateway_endpoint" {
  value = aws_apigatewayv2_api.api.api_endpoint
}