locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "random_password" "db_password" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name = "${local.name_prefix}/database/credentials"

  recovery_window_in_days = 0

  tags = {
    Name = "${local.name_prefix}-db-secret"
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id

  secret_string = jsonencode({
    username    = "osticket_admin"
    password    = random_password.db_password.result
    secret_salt = random_password.osticket_secret_salt.result
  })
}
resource "random_password" "osticket_secret_salt" {
  length  = 64
  special = false
}