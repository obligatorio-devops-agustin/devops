variable "environment" {
  description = "Environment for the bucket (dev, staging, master)"
  type        = string
}

variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1" # Cambia si usas otra región
}