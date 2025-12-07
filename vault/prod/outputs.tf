output "vault_public_ip" {
  description = "Public IP address of Vault server"
  value       = aws_eip.vault_prod.public_ip
}

output "vault_instance_id" {
  description = "EC2 instance ID of Vault server"
  value       = aws_instance.vault_prod.id
}

output "vault_url" {
  description = "Vault server URL"
  value       = "http://${aws_eip.vault_prod.public_ip}:8200"
}

output "kms_key_id" {
  description = "KMS key ID for Vault auto-unseal"
  value       = aws_kms_key.vault.id
}

output "kms_key_arn" {
  description = "KMS key ARN for Vault auto-unseal"
  value       = aws_kms_key.vault.arn
}

output "vault_data_volume_id" {
  description = "EBS volume ID for Vault data"
  value       = aws_ebs_volume.vault_data.id
}

output "ssh_command" {
  description = "SSH command to connect to Vault server"
  value       = "ssh -i ${var.key_name}.pem ubuntu@${aws_eip.vault_prod.public_ip}"
}

output "initialization_steps" {
  description = "Steps to initialize and configure Vault"
  value       = <<-EOT
    
    ========================================
    Vault Production Server Created!
    ========================================
    
      CRITICAL: Follow these steps carefully
    
    1. SSH into the server:
       ssh -i ${var.key_name}.pem ubuntu@${aws_eip.vault_prod.public_ip}
    
    2. Check Vault status:
       systemctl status vault
       export VAULT_ADDR='http://127.0.0.1:8200'
       vault status
    
    3. Initialize Vault (FIRST TIME ONLY):
       vault operator init
       
         CRITICAL: Save the unseal keys and root token in a secure location!
         You will need these to recover Vault if needed
         Vault will auto-unseal using AWS KMS, but keep these safe
    
    4. Verify auto-unseal is working:
       vault status
       # Should show "Sealed: false"
    
    5. Login with root token:
       vault login <root-token>
    
    6. Enable audit logging:
       vault audit enable file file_path=/var/log/vault/audit.log
    
    7. Configure AppRole authentication:
       vault auth enable approle
       
       # Create policy (see configure-vault.sh)
       vault policy write terraform /path/to/policy.hcl
       
       # Create AppRole
       vault write auth/approle/role/terraform \
         secret_id_ttl=10m \
         token_num_uses=10 \
         token_ttl=20m \
         token_max_ttl=30m \
         secret_id_num_uses=40 \
         token_policies=terraform
    
    8. Enable secrets engine:
       vault secrets enable -path=kv kv-v2
    
    9. Store your first secret:
       vault kv put kv/prod/database password="your-secure-password"
    
    10. Get Role ID and Secret ID for Terraform:
        vault read auth/approle/role/terraform/role-id
        vault write -f auth/approle/role/terraform/secret-id
    
    11. Access Vault UI:
        http://${aws_eip.vault_prod.public_ip}:8200
    
    ========================================
    Security Reminders:
    ========================================
    
    ✓ Vault is using AWS KMS for auto-unseal
    ✓ Data is encrypted at rest on EBS volume
    ✓ Keep unseal keys in a secure location (split among team members)
    ✓ Rotate secrets regularly
    ✓ Enable TLS for production use (update listener config)
    ✓ Restrict security group rules to specific IPs
    ✓ Enable CloudWatch monitoring
    ✓ Set up backup procedures for /mnt/vault-data
    
      TODO for production:
    - Enable TLS/HTTPS
    - Set up proper DNS
    - Configure backup and disaster recovery
    - Implement monitoring and alerting
    - Set up high availability (multiple Vault nodes)
    
  EOT
}
