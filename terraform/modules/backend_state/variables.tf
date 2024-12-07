variable "environment" {
  description = "Environment for the bucket (dev, staging, master)"
  type        = string
}

variable "state_bucket_name" {
  description = "Name of the S3 bucket to store Terraform state"
}

variable "lock_table_name" {
  description = "Name of the DynamoDB table for state locking"
}
