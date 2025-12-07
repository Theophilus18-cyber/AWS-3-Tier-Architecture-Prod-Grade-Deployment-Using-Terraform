output "web_security_group_id" {
  value       = aws_security_group.web.id
  description = "ID of web tier security group"
}

output "app_security_group_id" {
  value       = aws_security_group.app.id
  description = "ID of app tier security group"
}

output "db_security_group_id" {
  value       = aws_security_group.database.id
  description = "ID of database tier security group"
}

