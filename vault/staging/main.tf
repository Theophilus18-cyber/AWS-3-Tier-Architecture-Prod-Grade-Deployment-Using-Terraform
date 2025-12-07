# Staging Environment - Vault Server Setup
# This creates a Vault server running in DEV MODE for staging

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
resource "aws_security_group" "vault_staging" {
  name_prefix = "vault-staging-sg"
  description = "Security group for Vault staging server"
  vpc_id      = var.vpc_id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
    description = "SSH access"
  }

  # Vault API/UI access
  ingress {
    from_port   = 8200
    to_port     = 8200
    protocol    = "tcp"
    cidr_blocks = var.allowed_vault_cidr
    description = "Vault API and UI"
  }

  # Outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "vault-staging-sg"
    Environment = "staging"
    ManagedBy   = "Terraform"
  }
}

# EC2 Instance for Vault Server
resource "aws_instance" "vault_staging" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = var.subnet_id

  vpc_security_group_ids = [aws_security_group.vault_staging.id]

  user_data = <<-EOF
              #!/bin/bash
              set -e
              
              # Update system
              apt-get update
              apt-get install -y gpg wget
              
              # Add HashiCorp GPG key
              wget -O- https://apt.releases.hashicorp.com/gpg | \
                gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
              
              # Add HashiCorp repo
              echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
              https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
              tee /etc/apt/sources.list.d/hashicorp.list
              
              # Install Vault
              apt-get update
              apt-get install -y vault
              
              # Create systemd service for Vault dev mode
              cat > /etc/systemd/system/vault-dev.service <<'SYSTEMD'
              [Unit]
              Description=HashiCorp Vault Dev Mode (Staging)
              Documentation=https://www.vaultproject.io/docs/
              After=network-online.target
              Wants=network-online.target
              
              [Service]
              Type=simple
              User=root
              ExecStart=/usr/bin/vault server -dev -dev-listen-address="0.0.0.0:8200"
              Restart=on-failure
              RestartSec=5
              Environment="VAULT_ADDR=http://0.0.0.0:8200"
              
              [Install]
              WantedBy=multi-user.target
              SYSTEMD
              
              # Start Vault dev service
              systemctl daemon-reload
              systemctl enable vault-dev
              systemctl start vault-dev
              
              echo "Vault staging server started!"
              EOF

  tags = {
    Name        = "vault-staging-server"
    Environment = "staging"
    ManagedBy   = "Terraform"
    Purpose     = "HashiCorp Vault Staging Server"
  }

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
    tags = {
      Name = "vault-staging-root-volume"
    }
  }
}

# Elastic IP for Vault Server
resource "aws_eip" "vault_staging" {
  instance = aws_instance.vault_staging.id
  domain   = "vpc"

  tags = {
    Name        = "vault-staging-eip"
    Environment = "staging"
    ManagedBy   = "Terraform"
  }
}
