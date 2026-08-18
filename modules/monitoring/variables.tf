variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "ecs_cluster_name" {
  type = string
}

variable "node_exporter_image" {
  type = string
}

variable "cadvisor_image" {
  type = string
}

variable "prometheus_image" {
  type = string
}

variable "grafana_image" {
  type = string
}

# ==========================================================
# Grafana SMTP
# ==========================================================

variable "grafana_smtp_secret_arn" {
  type = string
}

variable "grafana_smtp_from_address" {
  type = string
}

# ==========================================================
# Grafana Database
# ==========================================================

variable "grafana_database_secret_arn" {
  type = string
}

variable "grafana_database_host" {
  type = string
}

variable "grafana_database_name" {
  type    = string
  default = "grafana"
}

variable "grafana_sns_topic_arn" {
  description = "SNS topic ARN used by Grafana alerts"
  type        = string
}
