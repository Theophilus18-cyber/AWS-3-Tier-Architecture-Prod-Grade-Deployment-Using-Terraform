
# SNS Topic for Alarm Notifications


resource "aws_sns_topic" "alarms" {
  name = "${var.environment}-infrastructure-alarms"

  tags = {
    Name        = "${var.environment}-infrastructure-alarms"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_sns_topic_subscription" "alarm_email" {
  count     = length(var.alarm_email_endpoints)
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email_endpoints[count.index]
}


# CloudWatch Log Groups


resource "aws_cloudwatch_log_group" "web_tier" {
  name              = "/aws/ec2/${var.environment}/web-tier"
  retention_in_days = var.log_retention_days
  #checkov:skip=CKV_AWS_158:KMS encryption skipped for cost/complexity in demo

  tags = {
    Name        = "${var.environment}-web-tier-logs"
    Environment = var.environment
    Tier        = "web"
    ManagedBy   = "Terraform"
  }
}

resource "aws_cloudwatch_log_group" "app_tier" {
  name              = "/aws/ec2/${var.environment}/app-tier"
  retention_in_days = var.log_retention_days
  #checkov:skip=CKV_AWS_158:KMS encryption skipped for cost/complexity in demo

  tags = {
    Name        = "${var.environment}-app-tier-logs"
    Environment = var.environment
    Tier        = "app"
    ManagedBy   = "Terraform"
  }
}

resource "aws_cloudwatch_log_group" "database" {
  name              = "/aws/rds/${var.environment}/database"
  retention_in_days = var.log_retention_days
  #checkov:skip=CKV_AWS_158:KMS encryption skipped for cost/complexity in demo

  tags = {
    Name        = "${var.environment}-database-logs"
    Environment = var.environment
    Tier        = "database"
    ManagedBy   = "Terraform"
  }
}

# ALB CloudWatch Alarms


resource "aws_cloudwatch_metric_alarm" "alb_target_response_time" {
  alarm_name          = "${var.environment}-alb-high-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = var.alb_response_time_threshold
  alarm_description   = "This metric monitors ALB target response time"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  tags = {
    Name        = "${var.environment}-alb-response-time-alarm"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  alarm_name          = "${var.environment}-alb-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = var.alb_unhealthy_host_threshold
  alarm_description   = "This metric monitors unhealthy hosts behind ALB"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }

  tags = {
    Name        = "${var.environment}-alb-unhealthy-hosts-alarm"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "${var.environment}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Sum"
  threshold           = var.alb_5xx_threshold
  alarm_description   = "This metric monitors 5xx errors from ALB targets"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  tags = {
    Name        = "${var.environment}-alb-5xx-errors-alarm"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}


# EC2 Auto Scaling Group Alarms


resource "aws_cloudwatch_metric_alarm" "web_asg_cpu_high" {
  alarm_name          = "${var.environment}-web-asg-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = var.ec2_cpu_high_threshold
  alarm_description   = "This metric monitors web tier CPU utilization"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    AutoScalingGroupName = var.web_asg_name
  }

  tags = {
    Name        = "${var.environment}-web-cpu-high-alarm"
    Environment = var.environment
    Tier        = "web"
    ManagedBy   = "Terraform"
  }
}

resource "aws_cloudwatch_metric_alarm" "app_asg_cpu_high" {
  alarm_name          = "${var.environment}-app-asg-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = var.ec2_cpu_high_threshold
  alarm_description   = "This metric monitors app tier CPU utilization"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    AutoScalingGroupName = var.app_asg_name
  }

  tags = {
    Name        = "${var.environment}-app-cpu-high-alarm"
    Environment = var.environment
    Tier        = "app"
    ManagedBy   = "Terraform"
  }
}

resource "aws_cloudwatch_metric_alarm" "web_asg_memory_high" {
  count               = var.enable_detailed_monitoring ? 1 : 0
  alarm_name          = "${var.environment}-web-asg-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = "120"
  statistic           = "Average"
  threshold           = var.ec2_memory_high_threshold
  alarm_description   = "This metric monitors web tier memory utilization"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    AutoScalingGroupName = var.web_asg_name
  }

  tags = {
    Name        = "${var.environment}-web-memory-high-alarm"
    Environment = var.environment
    Tier        = "web"
    ManagedBy   = "Terraform"
  }
}

resource "aws_cloudwatch_metric_alarm" "app_asg_memory_high" {
  count               = var.enable_detailed_monitoring ? 1 : 0
  alarm_name          = "${var.environment}-app-asg-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = "120"
  statistic           = "Average"
  threshold           = var.ec2_memory_high_threshold
  alarm_description   = "This metric monitors app tier memory utilization"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    AutoScalingGroupName = var.app_asg_name
  }

  tags = {
    Name        = "${var.environment}-app-memory-high-alarm"
    Environment = var.environment
    Tier        = "app"
    ManagedBy   = "Terraform"
  }
}


# RDS Database Alarms


resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "${var.environment}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "120"
  statistic           = "Average"
  threshold           = var.rds_cpu_threshold
  alarm_description   = "This metric monitors RDS CPU utilization"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    DBInstanceIdentifier = var.db_instance_id
  }

  tags = {
    Name        = "${var.environment}-rds-cpu-high-alarm"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_free_storage_low" {
  alarm_name          = "${var.environment}-rds-free-storage-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.rds_storage_threshold
  alarm_description   = "This metric monitors RDS free storage space"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    DBInstanceIdentifier = var.db_instance_id
  }

  tags = {
    Name        = "${var.environment}-rds-storage-low-alarm"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_connections_high" {
  alarm_name          = "${var.environment}-rds-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "120"
  statistic           = "Average"
  threshold           = var.rds_connections_threshold
  alarm_description   = "This metric monitors RDS database connections"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    DBInstanceIdentifier = var.db_instance_id
  }

  tags = {
    Name        = "${var.environment}-rds-connections-high-alarm"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_read_latency" {
  alarm_name          = "${var.environment}-rds-read-latency-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ReadLatency"
  namespace           = "AWS/RDS"
  period              = "120"
  statistic           = "Average"
  threshold           = var.rds_read_latency_threshold
  alarm_description   = "This metric monitors RDS read latency"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    DBInstanceIdentifier = var.db_instance_id
  }

  tags = {
    Name        = "${var.environment}-rds-read-latency-alarm"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_write_latency" {
  alarm_name          = "${var.environment}-rds-write-latency-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "WriteLatency"
  namespace           = "AWS/RDS"
  period              = "120"
  statistic           = "Average"
  threshold           = var.rds_write_latency_threshold
  alarm_description   = "This metric monitors RDS write latency"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    DBInstanceIdentifier = var.db_instance_id
  }

  tags = {
    Name        = "${var.environment}-rds-write-latency-alarm"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}


# CloudWatch Dashboard


resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.environment}-infrastructure-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # ALB Metrics
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", { stat = "Average", label = "Response Time" }],
            [".", "RequestCount", { stat = "Sum", label = "Request Count" }],
            [".", "HTTPCode_Target_5XX_Count", { stat = "Sum", label = "5XX Errors" }],
            [".", "HTTPCode_Target_4XX_Count", { stat = "Sum", label = "4XX Errors" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "ALB Performance Metrics"
          yAxis = {
            left = {
              label = "Count/Time"
            }
          }
        }
      },
      # EC2 Web Tier Metrics
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", { stat = "Average", label = "Web Tier CPU" }],
            ["...", { stat = "Maximum", label = "Web Tier CPU Max" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Web Tier CPU Utilization"
          yAxis = {
            left = {
              label = "Percent"
              min   = 0
              max   = 100
            }
          }
        }
      },
      # EC2 App Tier Metrics
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", { stat = "Average", label = "App Tier CPU" }],
            ["...", { stat = "Maximum", label = "App Tier CPU Max" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "App Tier CPU Utilization"
          yAxis = {
            left = {
              label = "Percent"
              min   = 0
              max   = 100
            }
          }
        }
      },
      # RDS Metrics
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", { stat = "Average", label = "DB CPU" }],
            [".", "DatabaseConnections", { stat = "Average", label = "DB Connections" }],
            [".", "FreeStorageSpace", { stat = "Average", label = "Free Storage (Bytes)" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "RDS Performance Metrics"
        }
      },
      # RDS Latency
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/RDS", "ReadLatency", { stat = "Average", label = "Read Latency" }],
            [".", "WriteLatency", { stat = "Average", label = "Write Latency" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "RDS Latency Metrics"
          yAxis = {
            left = {
              label = "Seconds"
            }
          }
        }
      },
      # Auto Scaling Group Metrics
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/AutoScaling", "GroupDesiredCapacity", { stat = "Average", label = "Web Desired" }],
            [".", "GroupInServiceInstances", { stat = "Average", label = "Web In Service" }],
            [".", "GroupMinSize", { stat = "Average", label = "Web Min" }],
            [".", "GroupMaxSize", { stat = "Average", label = "Web Max" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Web Tier Auto Scaling Metrics"
          yAxis = {
            left = {
              label = "Instance Count"
            }
          }
        }
      }
    ]
  })
}


# CloudWatch Composite Alarm (Optional)

resource "aws_cloudwatch_composite_alarm" "infrastructure_critical" {
  count             = var.enable_composite_alarms ? 1 : 0
  alarm_name        = "${var.environment}-infrastructure-critical"
  alarm_description = "Composite alarm for critical infrastructure issues"
  actions_enabled   = true
  alarm_actions     = [aws_sns_topic.alarms.arn]

  alarm_rule = join(" OR ", [
    "ALARM(${aws_cloudwatch_metric_alarm.rds_cpu_high.alarm_name})",
    "ALARM(${aws_cloudwatch_metric_alarm.rds_free_storage_low.alarm_name})",
    "ALARM(${aws_cloudwatch_metric_alarm.alb_unhealthy_hosts.alarm_name})"
  ])

  tags = {
    Name        = "${var.environment}-infrastructure-critical-alarm"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}


# CloudWatch Metric Filters for Custom Logs


resource "aws_cloudwatch_log_metric_filter" "error_count" {
  name           = "${var.environment}-error-count"
  log_group_name = aws_cloudwatch_log_group.app_tier.name
  pattern        = "[ERROR]"

  metric_transformation {
    name      = "ErrorCount"
    namespace = "${var.environment}/ApplicationLogs"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "application_errors" {
  alarm_name          = "${var.environment}-application-errors-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ErrorCount"
  namespace           = "${var.environment}/ApplicationLogs"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.app_error_threshold
  alarm_description   = "This metric monitors application error logs"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  treat_missing_data  = "notBreaching"

  tags = {
    Name        = "${var.environment}-app-errors-alarm"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
