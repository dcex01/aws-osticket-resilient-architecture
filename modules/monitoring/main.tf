locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ==========================================================
# Node Exporter Task Definition
# ==========================================================

resource "aws_ecs_task_definition" "node_exporter" {
  family                   = "${local.name_prefix}-node-exporter"
  network_mode             = "host"
  requires_compatibilities = ["EC2"]

  container_definitions = jsonencode([
    {
      name      = "node-exporter"
      image     = var.node_exporter_image
      essential = true

      memoryReservation = 128
      memory            = 256

      portMappings = [
        {
          containerPort = 9100
          hostPort      = 9100
          protocol      = "tcp"
        }
      ]

      command = [
        "--path.rootfs=/host"
      ]

      mountPoints = [
        {
          sourceVolume  = "rootfs"
          containerPath = "/host"
          readOnly      = true
        }
      ]
    }
  ])

  volume {
    name      = "rootfs"
    host_path = "/"
  }

  tags = {
    Name = "${local.name_prefix}-node-exporter"
  }
}

# ==========================================================
# Node Exporter DAEMON Service
# ==========================================================

resource "aws_ecs_service" "node_exporter" {
  name            = "${local.name_prefix}-node-exporter"
  cluster         = var.ecs_cluster_name
  task_definition = aws_ecs_task_definition.node_exporter.arn

  scheduling_strategy = "DAEMON"
  launch_type         = "EC2"

  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100

  tags = {
    Name = "${local.name_prefix}-node-exporter"
  }
}

# ==========================================================
# cAdvisor Task Definition
# ==========================================================

resource "aws_ecs_task_definition" "cadvisor" {
  family                   = "${local.name_prefix}-cadvisor"
  network_mode             = "host"
  requires_compatibilities = ["EC2"]

  container_definitions = jsonencode([
    {
      name       = "cadvisor"
      image      = var.cadvisor_image
      essential  = true
      privileged = true

      memoryReservation = 256
      memory            = 512

      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]

      mountPoints = [
        {
          sourceVolume  = "rootfs"
          containerPath = "/rootfs"
          readOnly      = true
        },
        {
          sourceVolume  = "varrun"
          containerPath = "/var/run"
          readOnly      = false
        },
        {
          sourceVolume  = "sys"
          containerPath = "/sys"
          readOnly      = true
        },
        {
          sourceVolume  = "docker"
          containerPath = "/var/lib/docker"
          readOnly      = true
        }
      ]
    }
  ])

  volume {
    name      = "rootfs"
    host_path = "/"
  }

  volume {
    name      = "varrun"
    host_path = "/var/run"
  }

  volume {
    name      = "sys"
    host_path = "/sys"
  }

  volume {
    name      = "docker"
    host_path = "/var/lib/docker"
  }

  tags = {
    Name = "${local.name_prefix}-cadvisor"
  }
}

# ==========================================================
# cAdvisor DAEMON Service
# ==========================================================

resource "aws_ecs_service" "cadvisor" {
  name            = "${local.name_prefix}-cadvisor"
  cluster         = var.ecs_cluster_name
  task_definition = aws_ecs_task_definition.cadvisor.arn

  scheduling_strategy = "DAEMON"
  launch_type         = "EC2"

  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100

  tags = {
    Name = "${local.name_prefix}-cadvisor"
  }
}

# ==========================================================
# Prometheus IAM Task Role
# ==========================================================

resource "aws_iam_role" "prometheus" {
  name = "${local.name_prefix}-prometheus-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-prometheus-task-role"
  }
}

resource "aws_iam_role_policy" "prometheus_ec2_discovery" {
  name = "${local.name_prefix}-prometheus-ec2-discovery"
  role = aws_iam_role.prometheus.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeAvailabilityZones"
        ]

        Resource = "*"
      }
    ]
  })
}

# ==========================================================
# Prometheus Task Definition
# ==========================================================

resource "aws_ecs_task_definition" "prometheus" {
  family                   = "${local.name_prefix}-prometheus"
  network_mode             = "host"
  requires_compatibilities = ["EC2"]

  task_role_arn = aws_iam_role.prometheus.arn

  container_definitions = jsonencode([
    {
      name      = "prometheus"
      image     = var.prometheus_image
      essential = true

      memoryReservation = 64
      memory            = 256

      portMappings = [
        {
          containerPort = 9090
          hostPort      = 9090
          protocol      = "tcp"
        }
      ]

      command = [
        "--config.file=/etc/prometheus/prometheus.yml",
        "--storage.tsdb.path=/prometheus",
        "--storage.tsdb.retention.time=7d",
        "--web.enable-lifecycle"
      ]
    }
  ])

  tags = {
    Name = "${local.name_prefix}-prometheus"
  }
}

# ==========================================================
# Prometheus ECS Service
# ==========================================================

resource "aws_ecs_service" "prometheus" {
  name            = "${local.name_prefix}-prometheus"
  cluster         = var.ecs_cluster_name
  task_definition = aws_ecs_task_definition.prometheus.arn

  desired_count = 1
  launch_type   = "EC2"

  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100

  tags = {
    Name = "${local.name_prefix}-prometheus"
  }
}
# ==========================================================
# Grafana ECS Task Execution Role
# ==========================================================

resource "aws_iam_role" "grafana_execution" {
  name = "${local.name_prefix}-grafana-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-grafana-execution-role"
  }
}

# ==========================================================
# Grafana Execution Role - ECS Managed Policy
# ==========================================================

resource "aws_iam_role_policy_attachment" "grafana_execution" {
  role       = aws_iam_role.grafana_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ==========================================================
# Grafana Execution Role - Secrets Manager Access
# ==========================================================

resource "aws_iam_role_policy" "grafana_smtp_secret" {
  name = "${local.name_prefix}-grafana-smtp-secret"
  role = aws_iam_role.grafana_execution.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "AllowGrafanaSecrets"
        Effect = "Allow"

        Action = [
          "secretsmanager:GetSecretValue"
        ]

        Resource = [
          var.grafana_smtp_secret_arn,
          var.grafana_database_secret_arn
        ]
      }
    ]
  })
}

# ==========================================================
# Grafana Task Definition
# ==========================================================

resource "aws_ecs_task_definition" "grafana" {
  family                   = "${local.name_prefix}-grafana"
  network_mode             = "host"
  requires_compatibilities = ["EC2"]

  execution_role_arn = aws_iam_role.grafana_execution.arn
  task_role_arn = aws_iam_role.grafana_task.arn

  container_definitions = jsonencode([
    {
      name      = "grafana"
      image     = var.grafana_image
      essential = true

      memoryReservation = 128
      memory            = 512

      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
          protocol      = "tcp"
        }
      ]

      # ====================================================
      # Grafana General Configuration
      # ====================================================

      environment = [
        {
          name  = "GF_SECURITY_ADMIN_USER"
          value = "admin"
        },
        {
          name  = "GF_USERS_ALLOW_SIGN_UP"
          value = "false"
        },
        {
          name  = "GF_SERVER_HTTP_PORT"
          value = "3000"
        },

        # ==================================================
        # Amazon SES SMTP
        # ==================================================

        {
          name  = "GF_SMTP_ENABLED"
          value = "true"
        },
        {
          name  = "GF_SMTP_HOST"
          value = "email-smtp.us-east-1.amazonaws.com:587"
        },
        {
          name  = "GF_SMTP_FROM_ADDRESS"
          value = var.grafana_smtp_from_address
        },
        {
          name  = "GF_SMTP_FROM_NAME"
          value = "Helpdesk Grafana"
        },
        {
          name  = "GF_SMTP_STARTTLS_POLICY"
          value = "MandatoryStartTLS"
        },
        {
          name  = "GF_SMTP_SKIP_VERIFY"
          value = "false"
        },

        # ==================================================
        # Persistent Grafana Database - RDS MySQL
        # ==================================================

        {
          name  = "GF_DATABASE_TYPE"
          value = "mysql"
        },
        {
          name  = "GF_DATABASE_HOST"
          value = var.grafana_database_host
        },
        {
          name  = "GF_DATABASE_NAME"
          value = var.grafana_database_name
        }
      ]

      # ====================================================
      # Credentials from AWS Secrets Manager
      # ====================================================

      secrets = [
        # --------------------------------------------------
        # SES SMTP
        # --------------------------------------------------

        {
          name      = "GF_SMTP_USER"
          valueFrom = "${var.grafana_smtp_secret_arn}:username::"
        },
        {
          name      = "GF_SMTP_PASSWORD"
          valueFrom = "${var.grafana_smtp_secret_arn}:password::"
        },

        # --------------------------------------------------
        # Grafana RDS MySQL
        # --------------------------------------------------

        {
          name      = "GF_DATABASE_USER"
          valueFrom = "${var.grafana_database_secret_arn}:username::"
        },
        {
          name      = "GF_DATABASE_PASSWORD"
          valueFrom = "${var.grafana_database_secret_arn}:password::"
        }
      ]
    }
  ])

  tags = {
    Name = "${local.name_prefix}-grafana"
  }
}

# ==========================================================
# Grafana ECS Service
# ==========================================================

resource "aws_ecs_service" "grafana" {
  name            = "${local.name_prefix}-grafana"
  cluster         = var.ecs_cluster_name
  task_definition = aws_ecs_task_definition.grafana.arn

  desired_count = 1
  launch_type   = "EC2"

  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100

  depends_on = [
    aws_iam_role_policy_attachment.grafana_execution,
    aws_iam_role_policy.grafana_smtp_secret
  ]

  tags = {
    Name = "${local.name_prefix}-grafana"
  }
}
# ==========================================================
# Grafana ECS Task Role
# ==========================================================

resource "aws_iam_role" "grafana_task" {
  name = "${local.name_prefix}-grafana-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-grafana-task-role"
  }
}

resource "aws_iam_role_policy" "grafana_sns_publish" {
  name = "${local.name_prefix}-grafana-sns-publish"
  role = aws_iam_role.grafana_task.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "PublishGrafanaAlerts"
        Effect = "Allow"

        Action = [
          "sns:Publish"
        ]

        Resource = var.grafana_sns_topic_arn
      }
    ]
  })
}