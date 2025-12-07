#!/bin/bash

# Start Vault in Development Mode
# ⚠️ WARNING: This is NOT secure and should ONLY be used for dev/staging testing

set -e

echo "=========================================="
echo "Starting Vault in Development Mode"
echo "⚠️  NOT FOR PRODUCTION USE"
echo "=========================================="

# Set Vault address
export VAULT_ADDR='http://0.0.0.0:8200'

echo ""
echo "Starting Vault server in dev mode..."
echo "Vault will be accessible at: http://0.0.0.0:8200"
echo ""
echo "⚠️  Keep this terminal open - Vault will stop if you close it"
echo "⚠️  Root token will be displayed below - SAVE IT!"
echo ""

# Start Vault in dev mode
vault server -dev -dev-listen-address="0.0.0.0:8200"
