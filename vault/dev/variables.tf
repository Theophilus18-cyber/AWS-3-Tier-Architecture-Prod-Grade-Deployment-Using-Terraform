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
  description = "Subnet ID for Vault server"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for Vault server"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "SSH key pair name for EC2 instance"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR blocks allowed to SSH into Vault server"
  type        = list(string)
  default     = ["0.0.0.0/0"] #  Restrict this in production!
}

variable "allowed_vault_cidr" {
  description = "CIDR blocks allowed to access Vault API/UI"
  type        = list(string)
  default     = ["0.0.0.0/0"] #  Restrict this in production!
}
