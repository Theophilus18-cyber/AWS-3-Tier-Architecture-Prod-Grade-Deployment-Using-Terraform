output "db_endpoint" {
  value = module.main.db_endpoint
}

output "alb_dns_name" {
  value = module.main.alb_dns_name
}

output "cloudfront_domain_name" {
  value = module.main.cloudfront_domain_name
}
