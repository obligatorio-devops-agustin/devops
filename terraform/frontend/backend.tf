terraform {
  backend "s3" {
    bucket         = "terraform-state-agustin"
    key            = "frontend/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock-table"
    encrypt        = true
  }
}