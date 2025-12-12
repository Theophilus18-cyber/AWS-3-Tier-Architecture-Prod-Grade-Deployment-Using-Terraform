

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

# Network variables
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "public_subnets" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnets" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = null
}

# Compute variables
variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
}

variable "instance_type" {
  description = "Instance type for EC2 instances"
  type        = string
}

variable "key_name" {
  description = "Key pair name for SSH access"
  type        = string
}

variable "cpu_threshold" {
  description = "CPU threshold for autoscaling policies"
  type        = number
}

variable "web_min_size" {
  description = "Minimum number of instances in web tier"
  type        = number
}

variable "web_max_size" {
  description = "Maximum number of instances in web tier"
  type        = number
}

variable "web_desired_capacity" {
  description = "Desired number of instances in web tier"
  type        = number
}

variable "app_min_size" {
  description = "Minimum number of instances in app tier"
  type        = number
}

variable "app_max_size" {
  description = "Maximum number of instances in app tier"
  type        = number
}

variable "app_desired_capacity" {
  description = "Desired number of instances in app tier"
  type        = number
}

# Database variables
variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "Database instance class"
  type        = string
}

# Monitoring variables
variable "alarm_email_endpoints" {
  description = "List of email addresses to receive alarm notifications"
  type        = list(string)
  default     = []
}

variable "alb_response_time_threshold" {
  description = "Threshold for ALB response time in seconds"
  type        = number
  default     = 1.0
}

variable "ec2_cpu_high_threshold" {
  description = "Threshold for EC2 CPU utilization percentage"
  type        = number
  default     = 80
}

variable "rds_cpu_threshold" {
  description = "Threshold for RDS CPU utilization percentage"
  type        = number
  default     = 80
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}

# CDN (CloudFront) variables
variable "cdn_price_class" {
  description = "CloudFront price class (PriceClass_100, PriceClass_200, PriceClass_All)"
  type        = string
  default     = "PriceClass_100"
}

variable "cdn_certificate_arn" {
  description = "Optional ACM certificate ARN for CloudFront HTTPS (leave empty to use default CloudFront cert)"
  type        = string
  default     = ""
}

# ECS Configuration
variable "ecs_min_size" {
  description = "Minimum number of ECS EC2 instances"
  type        = number
  default     = 1
}

variable "ecs_max_size" {
  description = "Maximum number of ECS EC2 instances"
  type        = number
  default     = 4
}

variable "ecs_desired_capacity" {
  description = "Desired number of ECS EC2 instances"
  type        = number
  default     = 2
}

variable "frontend_desired_count" {
  description = "Desired number of frontend ECS tasks"
  type        = number
  default     = 2
}

variable "backend_desired_count" {
  description = "Desired number of backend ECS tasks"
  type        = number
  default     = 2
}
