provider "aws" {
  region = "eu-west-1"
}

module "network" {
  source = ".//modules/network"

  network_name    = var.name
  region          = var.region
  environment_tag = var.environment_tag

  cidr_block         = "10.0.0.0/16"
  cidr_block_newbits = 8
  subnet_1_zone      = "a"
  subnet_2_zone      = "c"
}

module "ecs_cluster" {
  source  = "infrablocks/ecs-cluster/aws"
  version = "2.2.0"

  region     = var.region
  vpc_id     = module.network.aws_vpc_id
  subnet_ids = module.network.subnet_cidr_blocks_private

  component             = "internal"
  deployment_identifier = var.environment_tag

  cluster_name                         = replace(lower(var.name), " ", "_")
  cluster_instance_ssh_public_key_path = "~/.ssh/id_rsa.pub"
  cluster_instance_type                = var.cluster_instance_type

  cluster_minimum_size     = var.min_size
  cluster_maximum_size     = var.max_size
  cluster_desired_capacity = var.desired_capacity
}

module "elb" {
  source = ".//modules/elb"

  name                      = var.name
  environment_tag           = var.environment_tag
  vpc_id                    = module.network.aws_vpc_id
  subnet_cidr_blocks_public = module.network.subnet_cidr_blocks_public
}

module "grafana-deploy" {
  source = ".//modules/grafana-deploy"

  name            = var.name
  environment_tag = var.environment_tag
  elb_role_arn    = module.elb.elb_role_arn
  route_53_zone   = var.route_53_zone

  elb_name = module.elb.elb_name
  dns_name = module.elb.dns_name

  elb_policy = module.elb.elb_policy
  cluster_id = module.ecs_cluster.cluster_id

  instance_role_arn = module.ecs_cluster.instance_role_arn
}

#
# module "db" {
#   source = ".//modules/network"
# }
