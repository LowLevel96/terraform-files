output vpc_id {
  value = module.network.aws_vpc_id
}

output grafana_aws_iam_role {
  value = module.grafana-deploy.aws_iam_role
}

output grafana_dns_address {
  value = format("Grafana URL: grafana.%s", replace(var.route_53_zone, ".", ""))
}
