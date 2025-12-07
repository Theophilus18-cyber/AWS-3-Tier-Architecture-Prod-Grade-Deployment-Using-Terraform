output "web_asg_id" {
  value       = aws_autoscaling_group.web.id
  description = "ID of web tier auto scaling group"
}

output "web_asg_name" {
  value       = aws_autoscaling_group.web.name
  description = "Name of web tier auto scaling group"
}

output "app_asg_id" {
  value       = aws_autoscaling_group.app.id
  description = "ID of app tier auto scaling group"
}

output "app_asg_name" {
  value       = aws_autoscaling_group.app.name
  description = "Name of app tier auto scaling group"
}
