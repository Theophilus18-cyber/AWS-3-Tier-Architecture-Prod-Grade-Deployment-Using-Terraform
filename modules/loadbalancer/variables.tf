variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "web_security_group_id" {
  description = "ID of web tier security group"
  type        = string
}

variable "web_asg_id" {
  description = "ID of web tier auto scaling group"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

/*
variable "alb_certificate_arn" {
  description = "ARN of the ALB certificate"
  type        = string
}
*/