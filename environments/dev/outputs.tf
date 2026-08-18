output "vpc_id" {
  value = module.networking.vpc_id
}

output "availability_zones" {
  value = module.networking.availability_zones
}

output "public_subnet_ids" {
  value = module.networking.public_subnet_ids
}

output "application_subnet_ids" {
  value = module.networking.application_subnet_ids
}

output "database_subnet_ids" {
  value = module.networking.database_subnet_ids
}

output "alb_security_group_id" {
  value = module.networking.alb_security_group_id
}

output "ecs_security_group_id" {
  value = module.networking.ecs_security_group_id
}

output "rds_security_group_id" {
  value = module.networking.rds_security_group_id
}
output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}

output "ecs_autoscaling_group_name" {
  value = module.ecs.autoscaling_group_name
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "alb_target_group_arn" {
  value = module.alb.target_group_arn
}
output "rds_endpoint" {
  value = module.rds.db_endpoint
}

output "rds_port" {
  value = module.rds.db_port
}

output "rds_database_name" {
  value = module.rds.db_name
}

output "database_secret_arn" {
  value = module.secrets.secret_arn
}
output "attachments_bucket_name" {
  value = module.s3.bucket_name
}

output "attachments_bucket_arn" {
  value = module.s3.bucket_arn
}
output "osticket_service_name" {
  value = module.ecs_service.service_name
}

output "osticket_task_definition_arn" {
  value = module.ecs_service.task_definition_arn
}

output "osticket_log_group_name" {
  value = module.ecs_service.log_group_name
}
output "prometheus_repository_url" {
  value = module.ecr.prometheus_repository_url
}

output "grafana_repository_url" {
  value = module.ecr.grafana_repository_url
}

output "node_exporter_repository_url" {
  value = module.ecr.node_exporter_repository_url
}

output "cadvisor_repository_url" {
  value = module.ecr.cadvisor_repository_url
}

