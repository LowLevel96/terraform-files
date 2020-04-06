#############################
# ECS Container Definition #
############################
module ecs-container-definition {
  source          = "cloudposse/ecs-container-definition/aws"
  version         = "0.23.0"
  container_name  = "grafana"
  container_image = "grafana/grafana:latest"

  port_mappings = [
    {
      containerPort = 3000
      hostPort      = 80
      protocol      = "tcp"
    }
  ]
}

########################
# ECS Task Definition #
#######################
resource aws_ecs_task_definition grafana_task {
  family                = "grafana_task"
  container_definitions = module.ecs-container-definition.json

  volume {
    name      = "service-storage"
    host_path = "/ecs/service-storage"
  }

  tags = {
    Terraform = "true"
    Name      = var.name
    Env       = var.environment_tag
  }
}


resource aws_ecs_service grafana-service {
  name            = replace(lower(format("%s Grafana", var.name)), " ", "_")
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.grafana_task.arn
  desired_count   = 2
  iam_role        = var.elb_role_arn
  depends_on      = [var.elb_policy]

  ordered_placement_strategy {
    type  = "binpack"
    field = "cpu"
  }

  load_balancer {
    elb_name       = var.elb_name
    container_name = "grafana"
    container_port = 3000
  }
}


data aws_route53_zone zone_selected {
  name         = var.route_53_zone
  private_zone = false
}

resource aws_route53_record grafana-dns {
  zone_id = data.aws_route53_zone.zone_selected.zone_id
  name    = format("grafana.%s", var.route_53_zone)
  type    = "CNAME"
  ttl     = "5"

  records = [var.dns_name]
}


##################################
# IAM Role Policy For CloudWatch#
#################################
resource aws_iam_role_policy grafana_policy {
  name = replace(lower(format("%s Grafana CloudWatch", var.name)), " ", "_")
  role = aws_iam_role.grafana_policy.id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "AllowReadingMetricsFromCloudWatch",
        "Effect": "Allow",
        "Action": [
          "cloudwatch:DescribeAlarmsForMetric",
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:GetMetricData"
        ],
        "Resource": "*"
      },
      {
        "Sid": "AllowReadingTagsInstancesRegionsFromEC2",
        "Effect": "Allow",
        "Action": ["ec2:DescribeTags", "ec2:DescribeInstances", "ec2:DescribeRegions"],
        "Resource": "*"
      },
      {
        "Sid": "AllowReadingResourcesForTags",
        "Effect": "Allow",
        "Action": "tag:GetResources",
        "Resource": "*"
      }
    ]
  }
  EOF
}

############################
# IAM Role For CloudWatch #
###########################
resource aws_iam_role grafana_policy {
  name               = replace(lower(format("%s Grafana CloudWatch", var.name)), " ", "_")
  assume_role_policy = data.aws_iam_policy_document.grafana_datasource_assume_role.json

  tags = {
    Terraform = "true"
    Name      = var.name
    Env       = var.environment_tag
  }
}


data aws_iam_policy_document grafana_datasource_assume_role {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = [var.instance_role_arn]
      type        = "AWS"
    }

    effect = "Allow"
  }
}
