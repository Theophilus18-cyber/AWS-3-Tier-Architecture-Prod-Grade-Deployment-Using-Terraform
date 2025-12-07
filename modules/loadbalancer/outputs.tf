output "alb_dns_name" {
  value       = aws_lb.web.dns_name
  description = "The DNS name of the Application Load Balancer"
}

output "alb_arn" {
  value       = aws_lb.web.arn
  description = "The ARN of the Application Load Balancer"
}

output "alb_arn_suffix" {
  value       = aws_lb.web.arn_suffix
  description = "The ARN suffix of the Application Load Balancer (for CloudWatch)"
}

output "target_group_arn" {
  value       = aws_lb_target_group.web.arn
  description = "The ARN of the Target Group"
}

output "target_group_arn_suffix" {
  value       = aws_lb_target_group.web.arn_suffix
  description = "The ARN suffix of the Target Group (for CloudWatch)"
}
