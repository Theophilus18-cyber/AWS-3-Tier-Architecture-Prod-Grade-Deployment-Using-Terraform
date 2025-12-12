terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  #uncomment for remote state 
  # backend "s3" {
  #   bucket         = "your-bucket-name"
  #}

}

provider "aws" {
  region = var.aws_region

  # Use AWS CLI configuration or environment variables instead of hardcoded credentials
  # access_key and secret_key will be automatically picked up from:
  # 1. AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables
  # 2. AWS CLI configuration (~/.aws/credentials)
  # 3. IAM roles (if running on EC2)

  # Only uncomment these lines if you need to override the above methods
  # access_key = var.access_key
  # secret_key = var.secret_key
}

#network module

module "network" {

  source = "./modules/network"

  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  environment     = var.environment

  availability_zones = var.availability_zones
}


#security module

module "security" {
  source = "./modules/security"

  environment = var.environment
  vpc_id      = module.network.vpc_id

}

module "database" {
  source = "./modules/database"

  db_subnet_group_id = module.network.db_subnet_group_id
  security_group_id  = module.security.db_security_group_id
  environment        = var.environment
  db_name            = var.db_name

  db_username       = var.db_username
  db_password       = var.db_password
  db_instance_class = var.db_instance_class

}

# ECR Module - Container Registry
module "ecr" {
  source = "./modules/ecr"

  environment = var.environment
}

# Load Balancer Module
module "loadbalancer" {
  source                = "./modules/loadbalancer"
  vpc_id                = module.network.vpc_id
  public_subnet_ids     = module.network.public_subnet_ids
  web_security_group_id = module.security.web_security_group_id
  use_ecs               = true  # Using ECS, not ASG
  environment           = var.environment
}

# ECS Module - Container Orchestration
module "ecs" {
  source = "./modules/ecs"

  environment           = var.environment
  aws_region            = var.aws_region
  instance_type         = var.instance_type
  key_name              = var.key_name
  ecs_security_group_id = module.security.ecs_security_group_id
  private_subnet_ids    = module.network.app_subnet_ids

  # ECS Instance Sizing
  ecs_min_size         = var.ecs_min_size
  ecs_max_size         = var.ecs_max_size
  ecs_desired_capacity = var.ecs_desired_capacity

  # Container Images from ECR
  frontend_image = module.ecr.frontend_repository_url
  backend_image  = module.ecr.backend_repository_url

  # ECS Service Configuration
  frontend_desired_count = var.frontend_desired_count
  backend_desired_count  = var.backend_desired_count

  # Target Groups for Load Balancer
  frontend_target_group_arn = module.loadbalancer.target_group_arn
  backend_target_group_arn  = module.loadbalancer.backend_target_group_arn

  # Database Connection
  db_endpoint = replace(module.database.db_endpoint, ":5432", "")
  db_username = var.db_username
  db_password = var.db_password
  db_name     = var.db_name

  log_retention_days = var.log_retention_days
}

# Monitoring Module
module "monitoring" {
  source = "./modules/monitoring"

  environment = var.environment
  aws_region  = var.aws_region

  # SNS Configuration
  alarm_email_endpoints = var.alarm_email_endpoints

  # ALB Configuration
  alb_arn_suffix          = module.loadbalancer.alb_arn_suffix
  target_group_arn_suffix = module.loadbalancer.target_group_arn_suffix

  # ECS Auto Scaling Groups (replacing old ASG)
  web_asg_name = module.ecs.ecs_asg_name
  app_asg_name = module.ecs.ecs_asg_name

  # RDS Configuration
  db_instance_id = module.database.db_instance_id

  # Optional: Customize thresholds (use variables for environment-specific values)
  alb_response_time_threshold = var.alb_response_time_threshold
  ec2_cpu_high_threshold      = var.ec2_cpu_high_threshold
  rds_cpu_threshold           = var.rds_cpu_threshold
  log_retention_days          = var.log_retention_days
}

# CDN Module (CloudFront)
module "cdn" {
  source = "./modules/cdn"

  environment        = var.environment
  origin_domain_name = module.loadbalancer.alb_dns_name         # ← Gets DNS from loadbalancer output
  enabled            = var.environment == "prod" ? true : false # Only enable in prod
  price_class        = var.cdn_price_class
  certificate_arn    = var.cdn_certificate_arn
}
