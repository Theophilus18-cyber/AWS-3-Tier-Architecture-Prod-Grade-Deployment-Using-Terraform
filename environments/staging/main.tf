# Trigger Staging Deployment
module "main" {
  source = "../../"

  # Pass all variables from variables.tf to the root module
  environment = var.environment
  aws_region  = var.aws_region

  vpc_cidr           = var.vpc_cidr
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  availability_zones = var.availability_zones

  instance_type = var.instance_type
  key_name      = var.key_name

  db_name           = var.db_name
  db_username       = var.db_username
  db_password       = var.db_password
  db_instance_class = var.db_instance_class

  alarm_email_endpoints       = var.alarm_email_endpoints
  alb_response_time_threshold = var.alb_response_time_threshold
  ec2_cpu_high_threshold      = var.ec2_cpu_high_threshold
  rds_cpu_threshold           = var.rds_cpu_threshold
  log_retention_days          = var.log_retention_days

  cdn_price_class     = var.cdn_price_class
  cdn_certificate_arn = var.cdn_certificate_arn

  # ECS Configuration
  ecs_min_size           = var.ecs_min_size
  ecs_max_size           = var.ecs_max_size
  ecs_desired_capacity   = var.ecs_desired_capacity
  frontend_desired_count = var.frontend_desired_count
  backend_desired_count  = var.backend_desired_count
}
