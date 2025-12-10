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

variable "web_security_group_id" {
  description = "ID of web tier security group"
  type        = string
}

variable "app_security_group_id" {
  description = "ID of app tier security group"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "app_subnet_ids" {
  description = "List of app subnet IDs"
  type        = list(string)
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

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "db_endpoint" {
  description = "Database endpoint"
  type        = string
  default     = ""
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = ""
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "donations"
}

variable "dockerhub_username" {
  description = "Docker Hub username for pulling images"
  type        = string
  default     = "theophilus18cyber" # Default or passed from main
}
