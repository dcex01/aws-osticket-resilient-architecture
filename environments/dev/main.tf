module "networking" {
  source = "../../modules/networking"

  project_name = var.project_name
  environment  = var.environment

  vpc_cidr = var.vpc_cidr

  public_subnet_cidrs = [
    "10.10.1.0/24",
    "10.10.2.0/24"
  ]

  app_subnet_cidrs = [
    "10.10.11.0/24",
    "10.10.12.0/24"
  ]

  database_subnet_cidrs = [
    "10.10.21.0/24",
    "10.10.22.0/24"
  ]

  app_port = var.app_port
}
# ==========================================================
# ECR
# ==========================================================

module "ecr" {
  source = "../../modules/ecr"

  project_name = var.project_name
  environment  = var.environment
}

# ==========================================================
# ALB
# ==========================================================

module "alb" {
  source = "../../modules/alb"

  project_name = var.project_name
  environment  = var.environment

  vpc_id = module.networking.vpc_id

  public_subnet_ids = module.networking.public_subnet_ids

  alb_security_group_id = module.networking.alb_security_group_id
}

# ==========================================================
# ECS
# ==========================================================

module "ecs" {
  source = "../../modules/ecs"

  project_name = var.project_name
  environment  = var.environment

  instance_type = var.ecs_instance_type

  public_subnet_ids = module.networking.public_subnet_ids

  ecs_security_group_id = module.networking.ecs_security_group_id

  root_volume_size = 30
}
module "secrets" {
  source = "../../modules/secrets"

  project_name = var.project_name
  environment  = var.environment
}
# ==========================================================
# RDS MySQL
# ==========================================================

module "rds" {
  source = "../../modules/rds"

  project_name = var.project_name
  environment  = var.environment

  database_subnet_ids = module.networking.database_subnet_ids

  rds_security_group_id = module.networking.rds_security_group_id

  db_username = module.secrets.db_username
  db_password = module.secrets.db_password

  instance_class    = "db.t3.micro"
  allocated_storage = 20
}
module "s3" {
  source = "../../modules/s3"

  project_name = var.project_name
  environment  = var.environment
}
module "ecs_service" {
  source      = "../../modules/ecs_service"
  admin_email = var.admin_email
  aws_region  = "us-east-1"

  project_name = var.project_name
  environment  = var.environment

  ecs_cluster_name       = module.ecs.cluster_name
  capacity_provider_name = module.ecs.capacity_provider_name

  image_uri = "${module.ecr.repository_url}:1.18.4-ha4"

  target_group_arn = module.alb.target_group_arn

  secret_arn = module.secrets.secret_arn

  rds_endpoint      = module.rds.db_endpoint
  rds_port          = module.rds.db_port
  rds_database_name = module.rds.db_name
}
module "monitoring" {
  source = "../../modules/monitoring"

  project_name = var.project_name
  environment  = var.environment

  ecs_cluster_name = module.ecs.cluster_name

  node_exporter_image = "${module.ecr.node_exporter_repository_url}:v1.12.1"
  cadvisor_image      = "${module.ecr.cadvisor_repository_url}:v0.60.5"

  prometheus_image = "${module.ecr.prometheus_repository_url}:v3.13.1-ecs"
  grafana_image    = "${module.ecr.grafana_repository_url}:13.1.1"

  grafana_smtp_secret_arn     = var.grafana_smtp_secret_arn
  grafana_smtp_from_address   = var.grafana_smtp_from_address
  grafana_database_secret_arn = var.grafana_database_secret_arn
  grafana_database_host       = var.grafana_database_host
  grafana_database_name       = "grafana"
  grafana_sns_topic_arn       = var.grafana_sns_topic_arn
}