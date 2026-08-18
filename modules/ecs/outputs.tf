output "cluster_id" {
  description = "ECS Cluster ID"
  value       = aws_ecs_cluster.main.id
}

output "cluster_name" {
  description = "ECS Cluster name"
  value       = aws_ecs_cluster.main.name
}

output "cluster_arn" {
  description = "ECS Cluster ARN"
  value       = aws_ecs_cluster.main.arn
}

output "autoscaling_group_name" {
  description = "ECS Auto Scaling Group name"
  value       = aws_autoscaling_group.ecs.name
}

output "capacity_provider_name" {
  description = "ECS Capacity Provider name"
  value       = aws_ecs_capacity_provider.main.name
}

output "launch_template_id" {
  description = "EC2 Launch Template ID"
  value       = aws_launch_template.ecs.id
}

output "ecs_instance_role_name" {
  description = "IAM role used by ECS EC2 instances"
  value       = aws_iam_role.ecs_instance.name
}