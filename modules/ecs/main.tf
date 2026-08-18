locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ==========================================================
# ECS Optimized Amazon Linux 2023 AMI
# ==========================================================

data "aws_ssm_parameter" "ecs_optimized_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended/image_id"
}

# ==========================================================
# ECS Cluster
# ==========================================================

resource "aws_ecs_cluster" "main" {
  name = "${local.name_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${local.name_prefix}-cluster"
  }
}

# ==========================================================
# IAM Role for EC2 ECS Container Instances
# ==========================================================

resource "aws_iam_role" "ecs_instance" {
  name = "${local.name_prefix}-ecs-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-ecs-instance-role"
  }
}

# ECS permissions
resource "aws_iam_role_policy_attachment" "ecs_instance" {
  role = aws_iam_role.ecs_instance.name

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# Systems Manager access
resource "aws_iam_role_policy_attachment" "ssm" {
  role = aws_iam_role.ecs_instance.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# ==========================================================
# IAM Instance Profile
# ==========================================================

resource "aws_iam_instance_profile" "ecs" {
  name = "${local.name_prefix}-ecs-instance-profile"

  role = aws_iam_role.ecs_instance.name
}

# ==========================================================
# Launch Template
# ==========================================================

resource "aws_launch_template" "ecs" {
  name_prefix = "${local.name_prefix}-ecs-"

  image_id      = data.aws_ssm_parameter.ecs_optimized_ami.value
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs.name
  }

  vpc_security_group_ids = [
    var.ecs_security_group_id
  ]

  user_data = base64encode(
    templatefile(
      "${path.module}/user_data.sh.tpl",
      {
        cluster_name = aws_ecs_cluster.main.name
      }
    )
  )

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.root_volume_size
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"

    # Required so containers can use IMDS correctly
    # where applicable.
    http_put_response_hop_limit = 2
  }

  monitoring {
    enabled = false
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${local.name_prefix}-ecs-node"
    }
  }

  tag_specifications {
    resource_type = "volume"

    tags = {
      Name = "${local.name_prefix}-ecs-volume"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ==========================================================
# Auto Scaling Group
#
# Fixed laboratory capacity:
# min     = 2
# desired = 2
# max     = 2
# ==========================================================

resource "aws_autoscaling_group" "ecs" {
  name = "${local.name_prefix}-ecs-asg"

  min_size         = 2
  desired_capacity = 2
  max_size         = 2

  vpc_zone_identifier = var.public_subnet_ids

  health_check_type         = "EC2"
  health_check_grace_period = 300

  protect_from_scale_in = false

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-ecs-node"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = var.project_name
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }
}

# ==========================================================
# ECS Capacity Provider
# ==========================================================

resource "aws_ecs_capacity_provider" "main" {
  name = "${local.name_prefix}-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecs.arn

    managed_scaling {
      status = "DISABLED"
    }

    managed_termination_protection = "DISABLED"
  }

  tags = {
    Name = "${local.name_prefix}-capacity-provider"
  }
}

# ==========================================================
# Attach Capacity Provider to ECS Cluster
# ==========================================================

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = [
    aws_ecs_capacity_provider.main.name
  ]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    weight            = 1
    base              = 0
  }
}