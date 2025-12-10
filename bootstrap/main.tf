provider "aws" {
  region = "us-east-1"
}

# S3 bucket for Terraform state
resource "aws_s3_bucket" "tf_state" {
  bucket = "terraform-state-donation-app-theophilus" # Change this to a globally unique name

  tags = {
    Name        = "Terraform State Bucket"
    Environment = "bootstrap"
    ManagedBy   = "Terraform"
  }
}

# Enable versioning on the S3 bucket
resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access to the bucket
resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB table for state locking
resource "aws_dynamodb_table" "tf_lock" {
  name         = "terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform State Lock"
    Environment = "bootstrap"
    ManagedBy   = "Terraform"
  }
}

# Create a local file with backend configuration for automation
resource "local_file" "backend_config" {
  filename = "${path.module}/backend-config.json"
  content = jsonencode({
    s3_bucket      = aws_s3_bucket.tf_state.bucket
    dynamodb_table = aws_dynamodb_table.tf_lock.name
    region         = "us-east-1"
    encrypt        = true
    environments = {
      dev = {
        key = "environments/dev/terraform.tfstate"
      }
      staging = {
        key = "environments/staging/terraform.tfstate"
      }
      prod = {
        key = "environments/prod/terraform.tfstate"
      }
    }
  })
}

