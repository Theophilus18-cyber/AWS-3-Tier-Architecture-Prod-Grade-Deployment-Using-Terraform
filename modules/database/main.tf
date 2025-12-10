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

  # Backups are REQUIRED for Read Replicas
  # We enable them for Prod (7 days retention) or if you need replicas in other envs
  backup_retention_period = var.environment == "prod" ? 7 : 0

  skip_final_snapshot    = true
  db_subnet_group_name   = var.db_subnet_group_id
  vpc_security_group_ids = [var.security_group_id]

  tags = {
    Name        = "${var.environment}-mysql-primary"
    Environment = var.environment
  }
}

# Read Replica for Scaling (Production Only)
resource "aws_db_instance" "replica" {
  count = var.environment == "prod" ? 1 : 0

  identifier          = "${var.environment}-mysql-replica"
  replicate_source_db = aws_db_instance.main.identifier
  instance_class      = var.db_instance_class
  storage_type        = "gp2"

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
