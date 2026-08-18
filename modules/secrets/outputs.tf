output "secret_arn" {
  value = aws_secretsmanager_secret.db_credentials.arn
}

output "secret_name" {
  value = aws_secretsmanager_secret.db_credentials.name
}

output "db_username" {
  value = "osticket_admin"
}

output "db_password" {
  value     = random_password.db_password.result
  sensitive = true
}
output "osticket_secret_salt" {
  value     = random_password.osticket_secret_salt.result
  sensitive = true
}