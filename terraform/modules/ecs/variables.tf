variable "environment" {}
variable "services" {
  type = list(string)
}
variable "subnets" {
  type = list(string)
}
variable "dockerhub_username" {
  type = string
}
variable "use_existing_iam_role" {
  description = "Flag to indicate whether to use an existing IAM role"
  type        = bool
  default     = true
}
variable "existing_iam_role_arn" {
  description = "ARN of an existing IAM role to use for ECS task execution"
  type        = string
  default     = "arn:aws:iam::388058371152:role/LabRole"
}
variable "github_sha" {
  description = "GitHub Commit SHA"
  type        = string
}
variable "ecs_alb_dns" {
  type = string
}
variable "vpc_id" {
  type = string
}
variable "alb_security_group_id" {
  type = string
}
variable "private_subnets" {
  type = list(string)
}
variable "ecs_tg_arn" {
  type = list(string)
}