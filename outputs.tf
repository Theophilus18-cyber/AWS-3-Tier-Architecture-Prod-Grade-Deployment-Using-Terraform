output "db_endpoint" {
  value       = module.database.db_endpoint
  description = "The connection endpoint for the database"
}

output "db_name" {
  value       = module.database.db_name
  description = "The name of the database"
}

output "alb_dns_name" {
  value       = module.loadbalancer.alb_dns_name
  description = "The DNS name of the Application Load Balancer"
}

output "cloudfront_domain_name" {
  value       = module.cdn.cloudfront_domain_name
  description = "The domain name of the CloudFront distribution (if enabled)"
}
