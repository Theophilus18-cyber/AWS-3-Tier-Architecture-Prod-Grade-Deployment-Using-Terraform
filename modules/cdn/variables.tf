variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "origin_domain_name" {
  description = "The domain name of the origin (ALB, S3, etc.)"
  type        = string
}

variable "enabled" {
  description = "Enable CloudFront distribution"
  type        = bool
  default     = true
}

variable "price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"
}

variable "certificate_arn" {
  description = "Optional ACM certificate ARN for HTTPS (leave empty to use default CloudFront cert)"
  type        = string
  default     = ""
}
