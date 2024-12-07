variable "environment" {
  description = "Environment (dev, staging, master)"
  type        = string
}
variable "api_gateway_name" {
  description = "Name for the API Gateway"
  type        = string
}
variable "api_routes" {
  description = "API Gateway routes with methods and paths"
  type = list(object({
    method = string
    path   = string
  }))
}
variable "ecs_alb_dns" {
  type = string
}