resource "aws_iam_role" "rds_monitoring" {
  name = "${var.environment}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_db_instance" "main" {
  identifier           = "${var.environment}-mysql"
  allocated_storage    = 10
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = var.db_instance_class
  db_name              = var.db_name
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = "default.mysql8.0"

  # Security & Encryption
  storage_encrypted                   = true
  iam_database_authentication_enabled = true

  # Deletion Protection (Enable for Prod)
  deletion_protection = var.environment == "prod" ? true : false
  #checkov:skip=CKV_AWS_293:Deletion protection enabled for prod only
  #checkov:skip=CKV_AWS_157:Multi-AZ disabled for cost savings
  #checkov:skip=CKV_AWS_129:CloudWatch logs disabled for cost savings
  #checkov:skip=CKV2_AWS_60:Copy tags not critical for demo

  # Backups & Maintenance
  backup_retention_period    = var.environment == "prod" ? 7 : 1
  auto_minor_version_upgrade = true

  # Monitoring
  performance_insights_enabled = true
  #checkov:skip=CKV_AWS_354:Performance Insights KMS key pending setup
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn

  # Availability (Multi-AZ for Prod)
  multi_az = var.environment == "prod" ? true : false

  skip_final_snapshot    = true
  db_subnet_group_name   = var.db_subnet_group_id
  vpc_security_group_ids = [var.security_group_id]

  tags = {
    Name        = "${var.environment}-mysql-primary"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Read Replica for Scaling (Production Only)
resource "aws_db_instance" "replica" {
  count = var.environment == "prod" ? 1 : 0

  identifier          = "${var.environment}-mysql-replica"
  replicate_source_db = aws_db_instance.main.identifier
  instance_class      = var.db_instance_class
  storage_type        = "gp2"
  #checkov:skip=CKV2_AWS_60:Copy tags not critical for demo

  # Replicas don't need username/password/db_name (inherited from source)

  skip_final_snapshot    = true
  vpc_security_group_ids = [var.security_group_id]
  # Note: db_subnet_group_name is often inherited or auto-selected, but can be specified if needed

  tags = {
    Name        = "${var.environment}-mysql-replica"
    Environment = var.environment
  }
}



/*

#use this commented code and remove the obe above  if u wanna skip final snapshot per environment basically for prod environment its gonna make snapshot which is gonna charge u if u just wanted free tier deployement of db 

locals {
  # Define whether to skip final snapshot per environment
  skip_snapshot_map = {
    dev     = true
    staging = true
    prod    = false
  }
}

# -----------------------
# RDS Instance
# -----------------------
resource "aws_db_instance" "main" {
  identifier             = "${var.environment}-mysql"
  allocated_storage      = 10
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = var.db_instance_class
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  parameter_group_name   = "default.mysql8.0"
  skip_final_snapshot    = local.skip_snapshot_map[var.environment]
  db_subnet_group_name   = var.db_subnet_group_id
  vpc_security_group_ids = [var.security_group_id]
  tags = {
    Name        = "${var.environment}-mysql"
    Environment = var.environment
  }
}
*/
