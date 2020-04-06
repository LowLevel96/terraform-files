###################
# IAM Role Policy #
##################
resource "aws_iam_role_policy" "ecs_elb_policy" {
  name = format("%s_elb", replace(lower(var.name), " ", "_"))
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

#############
# IAM Role #
############
resource "aws_iam_role" "ecs_elb_role" {
  name               = format("%s_elb", replace(lower(var.name), " ", "_"))
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

  tags = {
    Terraform = "true"
    Name      = var.name
    Env       = var.environment_tag
  }
}

###################
# Security Group #
##################
resource "aws_security_group" "ecs-elb-sg" {
  name        = var.name
  description = "Allow TCP inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "TCP from VPC"
    from_port   = 80
    to_port     = 80
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
    Terraform = "true"
    Name      = var.name
    Env       = var.environment_tag
  }
}

########
# ELB #
#######
resource "aws_elb" "ecs-cluster-elb" {
  name            = replace(lower(var.name), " ", "-")
  subnets         = var.subnet_cidr_blocks_public
  security_groups = [aws_security_group.ecs-elb-sg.id]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Terraform = "true"
    Name      = var.name
    Env       = var.environment_tag
  }
}
