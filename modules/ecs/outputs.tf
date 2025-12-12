output "cluster_id" {
  value       = aws_ecs_cluster.main.id
  description = "The ID of the ECS cluster"
}

output "cluster_name" {
  value       = aws_ecs_cluster.main.name
  description = "The name of the ECS cluster"
}

output "cluster_arn" {
  value       = aws_ecs_cluster.main.arn
  description = "The ARN of the ECS cluster"
}

output "frontend_service_name" {
  value       = aws_ecs_service.frontend.name
  description = "The name of the frontend ECS service"
}

output "backend_service_name" {
  value       = aws_ecs_service.backend.name
  description = "The name of the backend ECS service"
}

output "ecs_asg_name" {
  value       = aws_autoscaling_group.ecs.name
  description = "The name of the ECS Auto Scaling Group"
}

output "ecs_asg_arn" {
  value       = aws_autoscaling_group.ecs.arn
  description = "The ARN of the ECS Auto Scaling Group"
}

output "task_execution_role_arn" {
  value       = aws_iam_role.ecs_task_execution.arn
  description = "The ARN of the ECS task execution role"
}
