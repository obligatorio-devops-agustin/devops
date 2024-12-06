variable "environment" {
  description = "Environment (dev, staging, master)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
}

variable "dockerhub_username" {
  description = "DockerHub username"
  type        = string
}

variable "services" {
  description = "List of microservices to deploy"
  type        = list(string)
}

variable "api_gateway_name" {
  description = "Name for the API Gateway"
  type        = string
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

variable "api_routes" {
  description = "API Gateway routes with methods and paths"
  type = list(object({
    method = string
    path   = string
  }))
}
