variable "environment" {}
variable "public_subnets" {
  type = list(string)
}
variable "services" {
  description = "List of microservices to deploy"
  type        = list(string)
}
variable "vpc_id" {
  type = string
}