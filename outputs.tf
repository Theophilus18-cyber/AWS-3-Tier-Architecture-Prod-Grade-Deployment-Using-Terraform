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

# ECR Outputs
output "ecr_backend_repository_url" {
  value       = module.ecr.backend_repository_url
  description = "ECR repository URL for backend images"
}

output "ecr_frontend_repository_url" {
  value       = module.ecr.frontend_repository_url
  description = "ECR repository URL for frontend images"
}

# ECS Outputs
output "ecs_cluster_name" {
  value       = module.ecs.cluster_name
  description = "The name of the ECS cluster"
}

output "ecs_frontend_service_name" {
  value       = module.ecs.frontend_service_name
  description = "The name of the frontend ECS service"
}

output "ecs_backend_service_name" {
  value       = module.ecs.backend_service_name
  description = "The name of the backend ECS service"
}
