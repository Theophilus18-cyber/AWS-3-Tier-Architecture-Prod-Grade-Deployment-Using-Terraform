#!/bin/bash

# Configure Vault AppRole and Policies
# Run this after Vault is started

set -e

echo "=========================================="
echo "Configuring Vault AppRole Authentication"
echo "=========================================="

# Check if VAULT_ADDR is set
if [ -z "$VAULT_ADDR" ]; then
    export VAULT_ADDR='http://0.0.0.0:8200'
    echo "Set VAULT_ADDR to: $VAULT_ADDR"
fi

# Check if VAULT_TOKEN is set (for dev mode, use root token)
if [ -z "$VAULT_TOKEN" ]; then
    echo "  VAULT_TOKEN not set. Please set it to your root token:"
    echo "export VAULT_TOKEN='your-root-token'"
    exit 1
fi

# Enable AppRole authentication
echo ""
echo "Enabling AppRole authentication..."
vault auth enable approle || echo "AppRole already enabled"

# Create Vault policy for Terraform
echo ""
echo "Creating Terraform policy..."
vault policy write terraform - <<EOF
path "*" {
  capabilities = ["list", "read"]
}
path "secrets/data/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
path "kv/data/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
path "secret/data/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
path "auth/token/create" {
  capabilities = ["create", "read", "update", "list"]
}
EOF

# Create AppRole and bind policy
echo ""
echo "Creating AppRole 'terraform'..."
vault write auth/approle/role/terraform \
    secret_id_ttl=10m \
    token_num_uses=10 \
    token_ttl=20m \
    token_max_ttl=30m \
    secret_id_num_uses=40 \
    token_policies=terraform

# Get Role ID
echo ""
echo "=========================================="
echo "Generating Role ID and Secret ID"
echo "=========================================="
echo ""
echo "Role ID:"
vault read auth/approle/role/terraform/role-id

echo ""
echo "Secret ID:"
vault write -f auth/approle/role/terraform/secret-id

echo ""
echo "=========================================="
echo "⚠️  IMPORTANT: Save the Role ID and Secret ID above!"
echo "You will need these for your Terraform configuration"
echo "=========================================="
echo ""

# Enable KV secrets engine
echo "Enabling KV secrets engine..."
vault secrets enable -path=kv kv-v2 || echo "KV secrets engine already enabled"

echo ""
echo "Configuration complete!"
echo ""
echo "Next steps:"
echo "1. Save your role_id and secret_id"
echo "2. Store secrets using: vault kv put kv/your-secret key=value"
echo "3. Update your Terraform configuration with the role_id and secret_id"
echo ""
