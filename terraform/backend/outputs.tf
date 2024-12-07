output "vpc_id" {
  value = module.vpc.vpc_id
}

output "ecs_cluster_name" {
  value = module.ecs.ecs_cluster_name
}

output "api_gateway_endpoint" {
  value = module.api_gateway.api_gateway_endpoint
}