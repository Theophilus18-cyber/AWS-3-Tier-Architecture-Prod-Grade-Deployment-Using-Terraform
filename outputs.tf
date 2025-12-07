output "vpc_id" {
  value       = module.network.vpc_id
  description = "The ID of the VPC"
}

output "alb_dns_name" {
  value       = module.loadbalancer.alb_dns_name
  description = "The DNS name of the Application Load Balancer"
}

output "db_endpoint" {
  value       = module.database.db_endpoint
  description = "The connection endpoint for the database"
  sensitive   = true
}