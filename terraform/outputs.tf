output "website_endpoint" {
  description = "S3 Bucket website endpoint"
  value       = aws_s3_bucket_website_configuration.frontend.website_endpoint
}