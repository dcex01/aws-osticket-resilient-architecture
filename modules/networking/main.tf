data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  azs = slice(
    data.aws_availability_zones.available.names,
    0,
    2
  )
}

# ============================================================
# VPC
# ============================================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

# ============================================================
# INTERNET GATEWAY
# ============================================================

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-igw"
  }
}

# ============================================================
# PUBLIC SUBNETS
# ALB + initially ECS EC2 nodes
# ============================================================

resource "aws_subnet" "public" {
  count = 2

  vpc_id = aws_vpc.main.id

  cidr_block = var.public_subnet_cidrs[count.index]

  availability_zone = local.azs[count.index]

  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name_prefix}-public-${count.index + 1}"
    Tier = "public"
  }
}

# ============================================================
# PRIVATE APPLICATION SUBNETS
#
# Reserved for ECS nodes/services when NAT Gateway
# or VPC endpoints are enabled later.
# ============================================================

resource "aws_subnet" "application" {
  count = 2

  vpc_id = aws_vpc.main.id

  cidr_block = var.app_subnet_cidrs[count.index]

  availability_zone = local.azs[count.index]

  map_public_ip_on_launch = false

  tags = {
    Name = "${local.name_prefix}-app-${count.index + 1}"
    Tier = "application"
  }
}

# ============================================================
# PRIVATE DATABASE SUBNETS
# ============================================================

resource "aws_subnet" "database" {
  count = 2

  vpc_id = aws_vpc.main.id

  cidr_block = var.database_subnet_cidrs[count.index]

  availability_zone = local.azs[count.index]

  map_public_ip_on_launch = false

  tags = {
    Name = "${local.name_prefix}-db-${count.index + 1}"
    Tier = "database"
  }
}

# ============================================================
# PUBLIC ROUTE TABLE
# ============================================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-public-rt"
  }
}

resource "aws_route" "public_internet" {
  route_table_id = aws_route_table.public.id

  destination_cidr_block = "0.0.0.0/0"

  gateway_id = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public" {
  count = 2

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ============================================================
# APPLICATION PRIVATE ROUTE TABLE
#
# No default Internet route intentionally.
# No NAT Gateway = no fixed NAT cost.
# ============================================================

resource "aws_route_table" "application" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-app-rt"
  }
}

resource "aws_route_table_association" "application" {
  count = 2

  subnet_id      = aws_subnet.application[count.index].id
  route_table_id = aws_route_table.application.id
}

# ============================================================
# DATABASE ROUTE TABLE
#
# Completely private.
# ============================================================

resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-db-rt"
  }
}

resource "aws_route_table_association" "database" {
  count = 2

  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}

# ============================================================
# SECURITY GROUP - ALB
# ============================================================

resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Security group for HelpDesk Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-alb-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id

  description = "HTTP from Internet"

  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"

  cidr_ipv4 = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id

  description = "HTTPS from Internet"

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"

  cidr_ipv4 = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "alb_outbound" {
  security_group_id = aws_security_group.alb.id

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}

# ============================================================
# SECURITY GROUP - ECS
#
# Application can only be reached by the ALB.
# No direct Internet access to the container port.
# ============================================================

resource "aws_security_group" "ecs" {
  name        = "${local.name_prefix}-ecs-sg"
  description = "Security group for ECS EC2 nodes"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-ecs-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
  security_group_id = aws_security_group.ecs.id

  description = "Application traffic from ALB"

  from_port   = var.app_port
  to_port     = var.app_port
  ip_protocol = "tcp"

  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_egress_rule" "ecs_outbound" {
  security_group_id = aws_security_group.ecs.id

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}

# ============================================================
# SECURITY GROUP - RDS
#
# PostgreSQL accepts connections ONLY from ECS.
# ============================================================

resource "aws_security_group" "rds" {
  name        = "${local.name_prefix}-rds-sg"
  description = "Security group for PostgreSQL RDS"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-rds-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "mysql_from_ecs" {
  security_group_id = aws_security_group.rds.id

  description = "MySQL access from ECS only"

  from_port   = 3306
  to_port     = 3306
  ip_protocol = "tcp"

  referenced_security_group_id = aws_security_group.ecs.id
}

resource "aws_vpc_security_group_egress_rule" "rds_outbound" {
  security_group_id = aws_security_group.rds.id

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}
# ==========================================================
# Monitoring - ECS internal traffic
# ==========================================================

resource "aws_vpc_security_group_ingress_rule" "node_exporter_from_ecs" {
  security_group_id = aws_security_group.ecs.id

  description = "Node Exporter from ECS nodes"

  from_port   = 9100
  to_port     = 9100
  ip_protocol = "tcp"

  referenced_security_group_id = aws_security_group.ecs.id
}

resource "aws_vpc_security_group_ingress_rule" "cadvisor_from_ecs" {
  security_group_id = aws_security_group.ecs.id

  description = "cAdvisor from ECS nodes"

  from_port   = 8080
  to_port     = 8080
  ip_protocol = "tcp"

  referenced_security_group_id = aws_security_group.ecs.id
}

resource "aws_vpc_security_group_ingress_rule" "prometheus_from_ecs" {
  security_group_id = aws_security_group.ecs.id

  description = "Prometheus from ECS nodes"

  from_port   = 9090
  to_port     = 9090
  ip_protocol = "tcp"

  referenced_security_group_id = aws_security_group.ecs.id
}
# ==========================================================
# Grafana - ECS internal traffic
# ==========================================================

resource "aws_vpc_security_group_ingress_rule" "grafana_from_ecs" {
  security_group_id = aws_security_group.ecs.id

  description = "Grafana from ECS nodes"

  from_port   = 3000
  to_port     = 3000
  ip_protocol = "tcp"

  referenced_security_group_id = aws_security_group.ecs.id
}