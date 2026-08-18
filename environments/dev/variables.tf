variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "helpdesk"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.10.0.0/16"
}

variable "app_port" {
  description = "Application container port"
  type        = number
  default     = 80
}
variable "ecs_instance_type" {
  description = "EC2 instance type for ECS nodes"
  type        = string
  default     = "t3.micro"
}
variable "admin_email" {
  description = "Administrator email address"
  type        = string
}

variable "grafana_smtp_secret_arn" {
  description = "ARN of the Grafana SMTP secret in AWS Secrets Manager"
  type        = string
}

variable "grafana_smtp_from_address" {
  description = "Email address used by Grafana as sender"
  type        = string
}

variable "grafana_database_secret_arn" {
  description = "ARN of the Grafana database credentials secret"
  type        = string
}

variable "grafana_database_host" {
  description = "Grafana MySQL database endpoint"
  type        = string
}

variable "grafana_sns_topic_arn" {
  description = "SNS topic ARN used by Grafana alerts"
  type        = string
}