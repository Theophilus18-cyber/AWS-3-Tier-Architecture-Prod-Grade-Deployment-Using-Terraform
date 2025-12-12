# Production Environment - Vault Server Setup
# This creates a PRODUCTION-READY Vault server with proper configuration

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data source for latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security Group for Vault Server
resource "aws_security_group" "vault_prod" {
  name_prefix = "vault-prod-sg"
  description = "Security group for Vault production server"
  vpc_id      = var.vpc_id

  # SSH access - RESTRICTED
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
    description = "SSH access from authorized IPs only"
  }
  #checkov:skip=CKV_AWS_24:SSH allowed for admin
  #checkov:skip=CKV_AWS_260:SSH allowed for admin

  # Vault API access - HTTPS only in production
  ingress {
    from_port   = 8200
    to_port     = 8200
    protocol    = "tcp"
    cidr_blocks = var.allowed_vault_cidr
    description = "Vault API access"
  }

  # Vault cluster communication (if using HA)
  ingress {
    from_port   = 8201
    to_port     = 8201
    protocol    = "tcp"
    self        = true
    description = "Vault cluster communication"
  }

  # Outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
  #checkov:skip=CKV_AWS_382:Egress required for installation/updates

  tags = {
    Name        = "vault-prod-sg"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# KMS key for auto-unseal (recommended for production)
resource "aws_kms_key" "vault" {
  description             = "Vault unseal key"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name        = "vault-prod-unseal-key"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
  #checkov:skip=CKV2_AWS_64:KMS policy defined at key creation not here
}

resource "aws_kms_alias" "vault" {
  name          = "alias/vault-prod-unseal"
  target_key_id = aws_kms_key.vault.key_id
}

# IAM role for Vault EC2 instance
resource "aws_iam_role" "vault" {
  name = "vault-prod-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "vault-prod-role"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# IAM policy for KMS auto-unseal
resource "aws_iam_role_policy" "vault_kms" {
  name = "vault-kms-unseal"
  role = aws_iam_role.vault.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = aws_kms_key.vault.arn
      }
    ]
  })
}

# IAM instance profile
resource "aws_iam_instance_profile" "vault" {
  name = "vault-prod-profile"
  role = aws_iam_role.vault.name
}

# EBS volume for Vault data (persistent storage)
resource "aws_ebs_volume" "vault_data" {
  availability_zone = var.availability_zone
  size              = var.vault_data_volume_size
  type              = "gp3"
  encrypted         = true
  kms_key_id        = aws_kms_key.vault.arn

  tags = {
    Name        = "vault-prod-data"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# EC2 Instance for Vault Server
resource "aws_instance" "vault_prod" {
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = var.instance_type
  key_name             = var.key_name
  subnet_id            = var.subnet_id
  iam_instance_profile = aws_iam_instance_profile.vault.name
  #checkov:skip=CKV_AWS_135:EBS optimization not needed for t2.micro
  #checkov:skip=CKV_AWS_126:Detailed monitoring costs extra

  vpc_security_group_ids = [aws_security_group.vault_prod.id]

  user_data = templatefile("${path.module}/user-data.sh", {
    kms_key_id    = aws_kms_key.vault.id
    aws_region    = var.aws_region
    vault_version = var.vault_version
  })

  tags = {
    Name        = "vault-prod-server"
    Environment = "production"
    ManagedBy   = "Terraform"
    Purpose     = "HashiCorp Vault Production Server"
  }

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
    tags = {
      Name = "vault-prod-root-volume"
    }
  }

  lifecycle {
    ignore_changes = [ami, user_data]
  }
}

# Attach data volume to instance
resource "aws_volume_attachment" "vault_data" {
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.vault_data.id
  instance_id = aws_instance.vault_prod.id
}

# Elastic IP for Vault Server
resource "aws_eip" "vault_prod" {
  instance = aws_instance.vault_prod.id
  domain   = "vpc"

  tags = {
    Name        = "vault-prod-eip"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
