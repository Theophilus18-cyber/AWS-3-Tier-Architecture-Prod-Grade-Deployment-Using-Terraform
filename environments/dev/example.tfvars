# General
aws_region  = "us-east-1"
environment = "dev"

# Network
vpc_cidr = "10.10.0.0/16"

public_subnets = [
  "10.10.1.0/24",
  "10.10.2.0/24"
]

private_subnets = [
  "10.10.3.0/24",
  "10.10.4.0/24",
  "10.10.5.0/24",
  "10.10.6.0/24"
]

availability_zones = [
  "us-east-1a",
  "us-east-1b"
]

# Compute
instance_type = "t2.micro"
key_name      = "your-ec2-key-name"

# Database
db_name           = "exampledb"
db_username       = "dbadmin"
db_password       = "CHANGE_ME"
db_instance_class = "db.t3.micro"

# Monitoring
alarm_email_endpoints = [
  # "alerts@example.com"
]

alb_response_time_threshold = 1.0
ec2_cpu_high_threshold      = 80
rds_cpu_threshold           = 80
log_retention_days          = 30

# CDN
cdn_price_class = "PriceClass_100"
cdn_certificate_arn = ""
