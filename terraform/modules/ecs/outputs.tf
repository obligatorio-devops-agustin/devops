output "ecs_cluster_name" {
  value = aws_ecs_cluster.backend_cluster.name
}

output "task_definition_arns" {
  value = aws_ecs_task_definition.tasks[*].arn
}