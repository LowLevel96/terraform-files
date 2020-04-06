output vpc_id {
  value = module.network.aws_vpc_id
}

output grafana_aws_iam_role {
  value = module.grafana-deploy.aws_iam_role
}
