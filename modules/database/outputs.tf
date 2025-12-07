output "db_endpoint" {
  value       = aws_db_instance.main.endpoint
  description = "The connection endpoint for the database"
}

output "db_name" {
  value       = aws_db_instance.main.db_name
  description = "The database name"
}

output "db_instance_id" {
  value       = aws_db_instance.main.id
  description = "The database instance ID"
}