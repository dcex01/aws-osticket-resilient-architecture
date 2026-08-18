locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ==========================================================
# CloudWatch Log Group
# ==========================================================

resource "aws_cloudwatch_log_group" "osticket" {
  name              = "/ecs/${local.name_prefix}-osticket"
  retention_in_days = 7

  tags = {
    Name = "${local.name_prefix}-osticket-logs"
  }
}

# ==========================================================
# ECS Task Execution Role
# ==========================================================

resource "aws_iam_role" "execution" {
  name = "${local.name_prefix}-osticket-execution-role"

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
}

resource "aws_iam_role_policy_attachment" "execution" {
  role = aws_iam_role.execution.name

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ==========================================================
# Permissions for Secrets Manager
# ==========================================================

resource "aws_iam_role_policy" "secrets" {
  name = "${local.name_prefix}-osticket-secrets"

  role = aws_iam_role.execution.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "secretsmanager:GetSecretValue"
        ]

        Resource = var.secret_arn
      }
    ]
  })
}

# ==========================================================
# ECS Task Role
# ==========================================================

resource "aws_iam_role" "task" {
  name = "${local.name_prefix}-osticket-task-role"

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
}

# ==========================================================
# ECS Task Definition
# ==========================================================

resource "aws_ecs_task_definition" "osticket" {
  family = "${local.name_prefix}-osticket"

  network_mode = "host"

  requires_compatibilities = [
    "EC2"
  ]

  cpu    = "256"
  memory = "512"

  execution_role_arn = aws_iam_role.execution.arn
  task_role_arn      = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name      = "osticket"
      image     = var.image_uri
      essential = true

      cpu    = 256
      memory = 512

      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "DB_HOST"
          value = var.rds_endpoint
        },
        {
          name  = "DB_PORT"
          value = tostring(var.rds_port)
        },
        {
          name  = "DB_NAME"
          value = var.rds_database_name
        },
        {
          name  = "TABLE_PREFIX"
          value = "ost_"
        },
        {
          name  = "ADMIN_EMAIL"
          value = var.admin_email
        }
      ]

      secrets = [
        {
          name      = "DB_USER"
          valueFrom = "${var.secret_arn}:username::"
        },
        {
          name      = "DB_PASSWORD"
          valueFrom = "${var.secret_arn}:password::"
        },
        {
          name      = "SECRET_SALT"
          valueFrom = "${var.secret_arn}:secret_salt::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          awslogs-group         = aws_cloudwatch_log_group.osticket.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "osticket"
        }
      }
    }
  ])

  tags = {
    Name = "${local.name_prefix}-osticket-task"
  }
}

# ==========================================================
# ECS Service
# ==========================================================

resource "aws_ecs_service" "osticket" {
  name = "${local.name_prefix}-osticket-service"

  cluster         = var.ecs_cluster_name
  task_definition = aws_ecs_task_definition.osticket.arn

  desired_count = 2

  enable_ecs_managed_tags = true

  capacity_provider_strategy {
    capacity_provider = var.capacity_provider_name
    weight            = 1
    base              = 0
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "osticket"
    container_port   = 80
  }

  placement_constraints {
    type = "distinctInstance"
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 100

  health_check_grace_period_seconds = 120

  depends_on = [
    aws_iam_role_policy_attachment.execution,
    aws_iam_role_policy.secrets
  ]

  tags = {
    Name = "${local.name_prefix}-osticket-service"
  }
}