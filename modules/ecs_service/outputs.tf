output "service_name" {
  value = aws_ecs_service.osticket.name
}

output "task_definition_arn" {
  value = aws_ecs_task_definition.osticket.arn
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.osticket.name
}

output "execution_role_arn" {
  value = aws_iam_role.execution.arn
}