
# SNS Topic Outputs


output "sns_topic_arn" {
  description = "ARN of the SNS topic for alarms"
  value       = aws_sns_topic.alarms.arn
}

output "sns_topic_name" {
  description = "Name of the SNS topic for alarms"
  value       = aws_sns_topic.alarms.name
}

# CloudWatch Log Group Outputs


output "web_tier_log_group_name" {
  description = "Name of the web tier CloudWatch log group"
  value       = aws_cloudwatch_log_group.web_tier.name
}

output "app_tier_log_group_name" {
  description = "Name of the app tier CloudWatch log group"
  value       = aws_cloudwatch_log_group.app_tier.name
}

output "database_log_group_name" {
  description = "Name of the database CloudWatch log group"
  value       = aws_cloudwatch_log_group.database.name
}


# CloudWatch Dashboard Outputs


output "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "dashboard_arn" {
  description = "ARN of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_arn
}


# Alarm Outputs


output "alb_alarms" {
  description = "Map of ALB alarm names and ARNs"
  value = {
    response_time   = aws_cloudwatch_metric_alarm.alb_target_response_time.arn
    unhealthy_hosts = aws_cloudwatch_metric_alarm.alb_unhealthy_hosts.arn
    errors_5xx      = aws_cloudwatch_metric_alarm.alb_5xx_errors.arn
  }
}

output "ec2_alarms" {
  description = "Map of EC2 alarm names and ARNs"
  value = {
    web_cpu_high = aws_cloudwatch_metric_alarm.web_asg_cpu_high.arn
    app_cpu_high = aws_cloudwatch_metric_alarm.app_asg_cpu_high.arn
  }
}

output "rds_alarms" {
  description = "Map of RDS alarm names and ARNs"
  value = {
    cpu_high         = aws_cloudwatch_metric_alarm.rds_cpu_high.arn
    storage_low      = aws_cloudwatch_metric_alarm.rds_free_storage_low.arn
    connections_high = aws_cloudwatch_metric_alarm.rds_connections_high.arn
    read_latency     = aws_cloudwatch_metric_alarm.rds_read_latency.arn
    write_latency    = aws_cloudwatch_metric_alarm.rds_write_latency.arn
  }
}

output "application_error_alarm_arn" {
  description = "ARN of the application error alarm"
  value       = aws_cloudwatch_metric_alarm.application_errors.arn
}
