output "alb_dns_name" {
  value       = module.compute.alb_dns_name
  description = "The public URL for your Go application backend"
}

output "s3_bucket_name" {
  value       = module.storage.s3_bucket_name
  description = "The name of your frontend S3 bucket"
}

output "cloudfront_id" {
  value       = module.storage.cloudfront_id
  description = "The ID of your CDN distribution"
}