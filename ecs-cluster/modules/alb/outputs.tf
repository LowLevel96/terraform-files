output alb_role_arn {
  value = aws_iam_role.ecs_alb_role.arn
}

output alb_name {
  value = aws_alb.main.name
}

output dns_name {
  value = aws_alb.main.dns_name
}

output alb_policy {
  value = aws_iam_role_policy.ecs_alb_policy
}

output target_group_arn {
  value = aws_alb_target_group.ecs_alb_tg.arn
}

output aws_alb_zone_id {
  value = aws_alb.main.zone_id
}
