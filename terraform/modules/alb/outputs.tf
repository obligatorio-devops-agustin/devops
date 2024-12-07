output "alb_dns_name" {
  value = aws_lb.ecs_alb.dns_name
}
output "alb_security_group_id" {
  value = aws_security_group.alb.id
}
output "ecs_tg_arn" {
  value = aws_lb_target_group.ecs_tg[*].arn
}