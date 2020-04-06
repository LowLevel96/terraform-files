output elb_role_arn {
  value = aws_iam_role.ecs_elb_role.arn
}

output elb_name {
  value = aws_elb.ecs-cluster-elb.name
}

output dns_name {
  value = aws_elb.ecs-cluster-elb.dns_name
}

output elb_policy {
  value = aws_iam_role_policy.ecs_elb_policy
}
