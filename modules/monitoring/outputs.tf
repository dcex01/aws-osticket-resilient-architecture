output "node_exporter_service_name" {
  value = aws_ecs_service.node_exporter.name
}

output "cadvisor_service_name" {
  value = aws_ecs_service.cadvisor.name
}