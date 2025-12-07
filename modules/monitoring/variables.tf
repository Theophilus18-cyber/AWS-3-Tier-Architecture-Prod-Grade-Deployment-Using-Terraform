
# General Variables


variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}


# SNS Configuration


variable "alarm_email_endpoints" {
  description = "List of email addresses to receive alarm notifications"
  type        = list(string)
  default     = []
}


# CloudWatch Log Configuration


variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}


# ALB Monitoring Variables


variable "alb_arn_suffix" {
  description = "ARN suffix of the Application Load Balancer"
  type        = string
}

variable "target_group_arn_suffix" {
  description = "ARN suffix of the target group"
  type        = string
}

variable "alb_response_time_threshold" {
  description = "Threshold for ALB response time in seconds"
  type        = number
  default     = 1.0
}

variable "alb_unhealthy_host_threshold" {
  description = "Threshold for unhealthy host count"
  type        = number
  default     = 1
}

variable "alb_5xx_threshold" {
  description = "Threshold for 5xx error count"
  type        = number
  default     = 10
}


# EC2 Auto Scaling Group Variables


variable "web_asg_name" {
  description = "Name of the web tier Auto Scaling Group"
  type        = string
}

variable "app_asg_name" {
  description = "Name of the app tier Auto Scaling Group"
  type        = string
}

variable "ec2_cpu_high_threshold" {
  description = "Threshold for EC2 CPU utilization percentage"
  type        = number
  default     = 80
}

variable "ec2_memory_high_threshold" {
  description = "Threshold for EC2 memory utilization percentage"
  type        = number
  default     = 80
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed monitoring with CloudWatch Agent (requires agent installation)"
  type        = bool
  default     = false
}


# RDS Database Variables


variable "db_instance_id" {
  description = "RDS database instance identifier"
  type        = string
}

variable "rds_cpu_threshold" {
  description = "Threshold for RDS CPU utilization percentage"
  type        = number
  default     = 80
}

variable "rds_storage_threshold" {
  description = "Threshold for RDS free storage space in bytes (default: 2GB)"
  type        = number
  default     = 2147483648 # 2GB in bytes
}

variable "rds_connections_threshold" {
  description = "Threshold for RDS database connections"
  type        = number
  default     = 80
}

variable "rds_read_latency_threshold" {
  description = "Threshold for RDS read latency in seconds"
  type        = number
  default     = 0.1
}

variable "rds_write_latency_threshold" {
  description = "Threshold for RDS write latency in seconds"
  type        = number
  default     = 0.1
}


# Application Monitoring Variables


variable "app_error_threshold" {
  description = "Threshold for application error count in logs"
  type        = number
  default     = 50
}


# Advanced Features


variable "enable_composite_alarms" {
  description = "Enable composite alarms for combined alert conditions"
  type        = bool
  default     = false
}
