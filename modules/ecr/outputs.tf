output "backend_repository_url" {
  value       = aws_ecr_repository.backend.repository_url
  description = "URL of the backend ECR repository"
}

output "frontend_repository_url" {
  value       = aws_ecr_repository.frontend.repository_url
  description = "URL of the frontend ECR repository"
}

output "backend_repository_arn" {
  value       = aws_ecr_repository.backend.arn
  description = "ARN of the backend ECR repository"
}

output "frontend_repository_arn" {
  value       = aws_ecr_repository.frontend.arn
  description = "ARN of the frontend ECR repository"
}

output "registry_id" {
  value       = aws_ecr_repository.backend.registry_id
  description = "The registry ID where the repository was created"
}
