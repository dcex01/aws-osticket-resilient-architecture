variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "ecs_cluster_name" {
  type = string
}

variable "capacity_provider_name" {
  type = string
}

variable "image_uri" {
  type = string
}

variable "target_group_arn" {
  type = string
}

variable "secret_arn" {
  type = string
}

variable "rds_endpoint" {
  type = string
}

variable "rds_port" {
  type    = number
  default = 3306
}

variable "rds_database_name" {
  type = string
}
variable "admin_email" {
  type = string
}
variable "aws_region" {
  description = "AWS region where the ECS service is deployed"
  type        = string
}