#!/bin/bash

# HashiCorp Vault Setup Script
# This script installs and configures Vault on Ubuntu EC2 instance

set -e

echo "=========================================="
echo "HashiCorp Vault Setup Script"
echo "=========================================="

# Update system
echo "Updating system packages..."
sudo apt update && sudo apt install -y gpg wget

# Add HashiCorp GPG key
echo "Adding HashiCorp GPG key..."
wget -O- https://apt.releases.hashicorp.com/gpg | \
  sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

# Add repo to APT sources
echo "Adding HashiCorp repository..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list

# Update and install Vault
echo "Installing Vault..."
sudo apt update && sudo apt install -y vault

# Verify installation
echo "Verifying Vault installation..."
vault --version

echo "=========================================="
echo "Vault installed successfully!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. For DEV/STAGING: Run './start-vault-dev.sh'"
echo "2. For PRODUCTION: Configure Vault properly (see setup-vault-prod.sh)"
echo ""
