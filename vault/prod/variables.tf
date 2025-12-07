variable "aws_region" {
  description = "AWS region for Vault server"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "VPC ID where Vault server will be deployed"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for Vault server (should be in a private subnet with NAT gateway)"
  type        = string
}

variable "availability_zone" {
  description = "Availability zone for EBS volume (must match subnet AZ)"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for Vault server"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "SSH key pair name for EC2 instance"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR blocks allowed to SSH into Vault server (restrict to bastion/VPN)"
  type        = list(string)
}

variable "allowed_vault_cidr" {
  description = "CIDR blocks allowed to access Vault API (restrict to application subnets)"
  type        = list(string)
}

variable "vault_data_volume_size" {
  description = "Size of EBS volume for Vault data in GB"
  type        = number
  default     = 50
}

variable "vault_version" {
  description = "Version of Vault to install"
  type        = string
  default     = "1.15.0-1"
}

variable "enable_audit_logging" {
  description = "Enable audit logging to CloudWatch"
  type        = bool
  default     = true
}
