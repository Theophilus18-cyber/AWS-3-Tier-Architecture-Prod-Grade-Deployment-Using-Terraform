output "vpc_id" {
  value       = aws_vpc.main.id
  description = "The ID of the VPC"
}

output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "List of public subnet IDs"
}

output "app_subnet_ids" {
  value       = [aws_subnet.private[0].id, aws_subnet.private[1].id]
  description = "List of app subnet IDs"
}

output "database_subnet_ids" {
  value       = [aws_subnet.private[2].id, aws_subnet.private[3].id]
  description = "List of database subnet IDs"
}

output "db_subnet_group_id" {
  value       = aws_db_subnet_group.database.id
  description = "ID of the database subnet group"
}