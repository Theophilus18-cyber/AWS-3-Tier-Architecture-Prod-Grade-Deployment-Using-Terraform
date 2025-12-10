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

# Compute Module (App and Web Tiers)
# Compute Module (App and Web Tiers)
module "compute" {
  source                = "./modules/compute"
  ami_id                = var.ami_id
  instance_type         = var.instance_type
  key_name              = var.key_name
  web_security_group_id = module.security.web_security_group_id
  app_security_group_id = module.security.app_security_group_id
  public_subnet_ids     = module.network.public_subnet_ids
  app_subnet_ids        = module.network.app_subnet_ids
  cpu_threshold         = var.cpu_threshold
  web_min_size          = var.web_min_size
  web_max_size          = var.web_max_size
  web_desired_capacity  = var.web_desired_capacity
  app_min_size          = var.app_min_size
  app_max_size          = var.app_max_size
  app_desired_capacity  = var.app_desired_capacity
  environment           = var.environment

  # Database connection for App Tier
  db_endpoint = replace(module.database.db_endpoint, ":5432", "") # Remove port if included
  db_username = var.db_username
  db_password = var.db_password
  db_name     = var.db_name

  # Docker Hub
  dockerhub_username = var.dockerhub_username
}

# Load Balancer Module
module "loadbalancer" {
  source                = "./modules/loadbalancer"
  vpc_id                = module.network.vpc_id
  public_subnet_ids     = module.network.public_subnet_ids
  web_security_group_id = module.security.web_security_group_id
  web_asg_id            = module.compute.web_asg_id
  environment           = var.environment
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

  # Auto Scaling Groups
  web_asg_name = module.compute.web_asg_name
  app_asg_name = module.compute.app_asg_name

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

