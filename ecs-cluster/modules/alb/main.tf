###################
# IAM Role Policy #
##################
resource "aws_iam_role_policy" "ecs_alb_policy" {
  name = format("%s_alb", replace(lower(var.name), " ", "_"))
  role = aws_iam_role.ecs_alb_role.id

  policy = <<-EOF
  {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Sid": "VisualEditor0",
              "Effect": "Allow",
              "Action": [
                  "ec2:Describe*",
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
resource "aws_iam_role" "ecs_alb_role" {
  name               = format("%s_alb", replace(lower(var.name), " ", "_"))
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
resource "aws_security_group" "ecs_alb_sg" {
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
# ALB #
#######
resource aws_alb_target_group ecs_alb_tg {
  name     = replace(lower(var.name), " ", "-")
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id


  tags = {
    Terraform = "true"
    Name      = var.name
    Env       = var.environment_tag
  }
}

resource "aws_alb" "main" {
  name            = replace(lower(var.name), " ", "-")
  subnets         = var.subnet_cidr_blocks_public
  security_groups = [aws_security_group.ecs_alb_sg.id]

  tags = {
    Terraform = "true"
    Name      = var.name
    Env       = var.environment_tag
  }
}

resource "aws_alb_listener" "front_end" {
  load_balancer_arn = aws_alb.main.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.ecs_alb_tg.id
    type             = "forward"
  }
}
