aws_region  = "us-east-1"
environment = "prod"

vpc_cidr = "10.0.0.0/16"

public_subnets = [
  "10.0.1.0/24",
  "10.0.2.0/24"
]

private_subnets = [
  "10.0.3.0/24",
  "10.0.4.0/24",
  "10.0.5.0/24",
  "10.0.6.0/24"
]

availability_zones = [
  "us-east-1a",
  "us-east-1b",
  "us-east-1c"
]

instance_type = "t3.micro"
key_name      = "your-ec2-key-name"

db_name           = "exampledb"
db_username       = "dbadmin"
db_password       = "CHANGE_ME"
db_instance_class = "db.t3.micro"

alarm_email_endpoints = []

alb_response_time_threshold = 1
ec2_cpu_high_threshold      = 80
rds_cpu_threshold           = 80
log_retention_days          = 30

cdn_price_class     = "PriceClass_100"
cdn_certificate_arn = ""

ecs_min_size           = 1
ecs_max_size           = 4
ecs_desired_capacity   = 2
frontend_desired_count = 2
backend_desired_count  = 2
