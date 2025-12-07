resource "aws_db_instance" "main" {
    identifier = "${var.environment}-mysql"
    allocated_storage = 10
    storage_type = "gp2"
    engine = "mysql"
    engine_version = "8.0"
    instance_class = var.db_instance_class
    db_name = var.db_name
    username = var.db_username
    password = var.db_password
    parameter_group_name = "default.mysql8.0"
    skip_final_snapshot = true
    db_subnet_group_name = var.db_subnet_group_id
    vpc_security_group_ids = [var.security_group_id]
    tags = {
        Name        = "${var.environment}-mysql"
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
