locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "aws_db_subnet_group" "main" {
  name = "${local.name_prefix}-db-subnet-group"

  subnet_ids = var.database_subnet_ids

  tags = {
    Name = "${local.name_prefix}-db-subnet-group"
  }
}

resource "aws_db_instance" "main" {
  identifier = "${local.name_prefix}-mysql"

  engine = "mysql"

  instance_class = var.instance_class

  allocated_storage = var.allocated_storage
  storage_type      = "gp3"

  db_name  = "osticket"
  username = var.db_username
  password = var.db_password

  port = 3306

  db_subnet_group_name = aws_db_subnet_group.main.name

  vpc_security_group_ids = [
    var.rds_security_group_id
  ]

  multi_az = false

  publicly_accessible = false

  storage_encrypted = true

  backup_retention_period = 1

  deletion_protection = false

  skip_final_snapshot = true

  apply_immediately = true

  auto_minor_version_upgrade = true

  performance_insights_enabled = false

  monitoring_interval = 0

  tags = {
    Name = "${local.name_prefix}-mysql"
  }
}