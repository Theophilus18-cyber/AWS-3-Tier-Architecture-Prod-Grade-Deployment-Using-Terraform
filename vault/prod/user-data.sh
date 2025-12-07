#!/bin/bash
# Production Vault Server User Data Script

set -e

# Variables from Terraform
KMS_KEY_ID="${kms_key_id}"
AWS_REGION="${aws_region}"
VAULT_VERSION="${vault_version}"

echo "=========================================="
echo "Setting up Vault Production Server"
echo "=========================================="

# Update system
apt-get update
apt-get install -y gpg wget jq

# Add HashiCorp GPG key
wget -O- https://apt.releases.hashicorp.com/gpg | \
  gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

# Add HashiCorp repo
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
tee /etc/apt/sources.list.d/hashicorp.list

# Install Vault
apt-get update
apt-get install -y vault=$VAULT_VERSION

# Create Vault user and directories
useradd --system --home /etc/vault.d --shell /bin/false vault || true
mkdir -p /opt/vault/data
mkdir -p /etc/vault.d
chown -R vault:vault /opt/vault
chown -R vault:vault /etc/vault.d

# Format and mount data volume
if [ ! -d "/mnt/vault-data" ]; then
  mkdir -p /mnt/vault-data
  
  # Check if volume is already formatted
  if ! blkid /dev/xvdf; then
    mkfs.ext4 /dev/xvdf
  fi
  
  # Mount volume
  mount /dev/xvdf /mnt/vault-data
  
  # Add to fstab for auto-mount on reboot
  echo "/dev/xvdf /mnt/vault-data ext4 defaults,nofail 0 2" >> /etc/fstab
  
  # Set permissions
  mkdir -p /mnt/vault-data/data
  chown -R vault:vault /mnt/vault-data
fi

# Create Vault configuration
cat > /etc/vault.d/vault.hcl <<EOF
# Production Vault Configuration

ui = true

storage "file" {
  path = "/mnt/vault-data/data"
}

listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_disable   = 1
  #  For production, enable TLS:
  # tls_cert_file = "/etc/vault.d/vault.crt"
  # tls_key_file  = "/etc/vault.d/vault.key"
}

seal "awskms" {
  region     = "$AWS_REGION"
  kms_key_id = "$KMS_KEY_ID"
}

api_addr = "http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8200"
cluster_addr = "http://$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4):8201"

# Enable audit logging
# audit device will be enabled after initialization
EOF

chown vault:vault /etc/vault.d/vault.hcl
chmod 640 /etc/vault.d/vault.hcl

# Create systemd service
cat > /etc/systemd/system/vault.service <<'SYSTEMD'
[Unit]
Description=HashiCorp Vault
Documentation=https://www.vaultproject.io/docs/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/vault.d/vault.hcl

[Service]
Type=notify
User=vault
Group=vault
ProtectSystem=full
ProtectHome=read-only
PrivateTmp=yes
PrivateDevices=yes
SecureBits=keep-caps
AmbientCapabilities=CAP_IPC_LOCK
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
NoNewPrivileges=yes
ExecStart=/usr/bin/vault server -config=/etc/vault.d/vault.hcl
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
KillSignal=SIGINT
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
LimitNOFILE=65536
LimitMEMLOCK=infinity

[Install]
WantedBy=multi-user.target
SYSTEMD

# Enable and start Vault
systemctl daemon-reload
systemctl enable vault
systemctl start vault

echo "=========================================="
echo "Vault Production Server Setup Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Initialize Vault: vault operator init"
echo "2. Save the unseal keys and root token securely"
echo "3. Vault will auto-unseal using AWS KMS"
echo "4. Configure AppRole authentication"
echo "5. Enable audit logging"
echo ""
