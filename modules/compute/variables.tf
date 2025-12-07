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