output "vault_public_ip" {
  description = "Public IP address of Vault server"
  value       = aws_eip.vault_dev.public_ip
}

output "vault_instance_id" {
  description = "EC2 instance ID of Vault server"
  value       = aws_instance.vault_dev.id
}

output "vault_url" {
  description = "Vault server URL"
  value       = "http://${aws_eip.vault_dev.public_ip}:8200"
}

output "ssh_command" {
  description = "SSH command to connect to Vault server"
  value       = "ssh -i ${var.key_name}.pem ubuntu@${aws_eip.vault_dev.public_ip}"
}

output "next_steps" {
  description = "Next steps to configure Vault"
  value       = <<-EOT
    
    ========================================
    Vault Dev Server Created Successfully!
    ========================================
    
    1. SSH into the server:
       ssh -i ${var.key_name}.pem ubuntu@${aws_eip.vault_dev.public_ip}
    
    2. Check Vault status:
       systemctl status vault-dev
    
    3. Get the root token from logs:
       sudo journalctl -u vault-dev | grep "Root Token"
    
    4. Set environment variables:
       export VAULT_ADDR='http://0.0.0.0:8200'
       export VAULT_TOKEN='<root-token-from-logs>'
    
    5. Configure AppRole:
       Run the configure-vault.sh script from the vault directory
    
    6. Access Vault UI:
       http://${aws_eip.vault_dev.public_ip}:8200
    
      This is a DEV MODE server - NOT for production use!
    
  EOT
}
