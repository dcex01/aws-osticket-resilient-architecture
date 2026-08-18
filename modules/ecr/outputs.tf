output "repository_name" {
  description = "ECR repository name"
  value       = aws_ecr_repository.helpdesk.name
}

output "repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.helpdesk.repository_url
}

output "repository_arn" {
  description = "ECR repository ARN"
  value       = aws_ecr_repository.helpdesk.arn
}
output "prometheus_repository_url" {
  value = aws_ecr_repository.prometheus.repository_url
}

output "grafana_repository_url" {
  value = aws_ecr_repository.grafana.repository_url
}

output "node_exporter_repository_url" {
  value = aws_ecr_repository.node_exporter.repository_url
}

output "cadvisor_repository_url" {
  value = aws_ecr_repository.cadvisor.repository_url
}
