# Outputs for Terraform Remote State Bootstrap

output "s3_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.tf_state.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.tf_state.arn
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for state locking"
  value       = aws_dynamodb_table.tf_lock.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  value       = aws_dynamodb_table.tf_lock.arn
}

output "region" {
  description = "AWS region where resources are created"
  value       = "us-east-1"
}

output "backend_config" {
  description = "Backend configuration to use in your main project"
  value       = <<-EOT
    terraform {
      backend "s3" {
        bucket         = "${aws_s3_bucket.tf_state.bucket}"
        region         = "us-east-1"
        dynamodb_table = "${aws_dynamodb_table.tf_lock.name}"
        encrypt        = true
      }
    }
    
    Environment-specific state keys:
    - Dev:     key = "environments/dev/terraform.tfstate"
    - Staging: key = "environments/staging/terraform.tfstate"
    - Prod:    key = "environments/prod/terraform.tfstate"
  EOT
}
