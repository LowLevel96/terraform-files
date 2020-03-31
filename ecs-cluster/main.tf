provider "aws" {
  region = "eu-west-1"
}

module "network" {
  source = ".//modules/networking"
}


module "ecs_cluster" {
  source  = "infrablocks/ecs-cluster/aws"
  version = "2.2.0"

  region     = "eu-west-1"
  vpc_id     = module.network.aws_vpc_id
  subnet_ids = module.network.subnet_cidr_blocks_private

  component             = "internal"
  deployment_identifier = "develop"

  cluster_name                         = "ecs-cluster"
  cluster_instance_ssh_public_key_path = "~/.ssh/id_rsa.pub"
  cluster_instance_type                = "t2.small"

  cluster_minimum_size     = 1
  cluster_maximum_size     = 2
  cluster_desired_capacity = 1

}

module "ecs-container-definition" {
  source          = "cloudposse/ecs-container-definition/aws"
  version         = "0.23.0"
  container_name  = "grafana"
  container_image = "grafana/grafana:latest"

  port_mappings = [
    {
      containerPort = 3000
      hostPort      = 3000
      protocol      = "tcp"
    }
  ]
}

resource "aws_ecs_task_definition" "grafana_task" {
  family                = "grafana_task"
  container_definitions = module.ecs-container-definition.json

  volume {
    name      = "service-storage"
    host_path = "/ecs/service-storage"
  }
}

resource "aws_iam_role_policy" "ecs_elb_policy" {
  name = "ecs-elb-role-policy"
  role = aws_iam_role.ecs_elb_role.id

  policy = <<-EOF
  {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Sid": "VisualEditor0",
              "Effect": "Allow",
              "Action": [
                  "elasticloadbalancing:DescribeLoadBalancerAttributes",
                  "elasticloadbalancing:DescribeLoadBalancers",
                  "elasticloadbalancing:DescribeTags",
                  "elasticloadbalancing:DescribeLoadBalancerPolicies",
                  "elasticloadbalancing:DescribeLoadBalancerPolicyTypes",
                  "elasticloadbalancing:DescribeInstanceHealth"
              ],
              "Resource": "*"
          },
          {
              "Sid": "VisualEditor1",
              "Effect": "Allow",
              "Action": "elasticloadbalancing:*",
              "Resource": "*"
          }
      ]
  }
  EOF
}

resource "aws_iam_role" "ecs_elb_role" {
  name               = "ecs-elb-role"
  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ecs.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF
}

resource "aws_security_group" "ecs-elb-sg" {
  name        = "ecs-elb-sg"
  description = "Allow TCP inbound traffic"
  vpc_id      = module.network.aws_vpc_id

  ingress {
    description = "TCP from VPC"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ECS ELB SG"
  }
}

resource "aws_elb" "ecs-cluster-elb" {
  name            = "ecs-cluster-elb"
  subnets         = module.network.subnet_cidr_blocks_public
  security_groups = [aws_security_group.ecs-elb-sg.id]

  listener {
    instance_port     = 3000
    instance_protocol = "tcp"
    lb_port           = 3000
    lb_protocol       = "tcp"
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "ECS Cluster Service Load Balancer"
  }
}

resource "aws_ecs_service" "grafana-service" {
  name            = "grafana-service"
  cluster         = module.ecs_cluster.cluster_id
  task_definition = aws_ecs_task_definition.grafana_task.arn
  desired_count   = 2
  iam_role        = aws_iam_role.ecs_elb_role.arn
  depends_on      = [aws_iam_role_policy.ecs_elb_policy]

  ordered_placement_strategy {
    type  = "binpack"
    field = "cpu"
  }

  load_balancer {
    elb_name       = aws_elb.ecs-cluster-elb.name
    container_name = "grafana"
    container_port = 3000
  }
}

data "aws_route53_zone" "zone_selected" {
  name         = "dusanstojnic.com."
  private_zone = false
}

resource "aws_route53_record" "grafana-dns" {
  zone_id = data.aws_route53_zone.zone_selected.zone_id
  name    = "grafana.dusanstojnic.com."
  type    = "CNAME"
  ttl     = "5"

  records = [aws_elb.ecs-cluster-elb.dns_name]
}

# output "json" {
#   description = "Container definition in JSON format"
#   value       = module.ecs-container-definition.json
# }
