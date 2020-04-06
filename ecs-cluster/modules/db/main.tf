
##########################################################################

resource "aws_db_parameter_group" "aurora_db_postgres11_parameter_group" {
  name        = "test-aurora-db-postgres11-parameter-group"
  family      = "aurora-postgresql9.6"
  description = "test-aurora-db-postgres11-parameter-group"
}

resource "aws_rds_cluster_parameter_group" "aurora_cluster_postgres11_parameter_group" {
  name        = "test-aurora-postgres11-cluster-parameter-group"
  family      = "aurora-postgresql9.6"
  description = "test-aurora-postgres11-cluster-parameter-group"
}



module "db" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "~> 2.0"

  name = "ecs-internal-aurora-postgres"

  engine         = "aurora-postgresql"
  engine_version = "9.6.9"

  vpc_id  = module.network.aws_vpc_id
  subnets = module.network.subnet_cidr_blocks_private

  replica_count           = 1
  allowed_security_groups = [aws_security_group.rds-sg.id]
  allowed_cidr_blocks     = [module.network.vpc_cidr_block]
  instance_type           = "db.r4.large"
  storage_encrypted       = true
  apply_immediately       = true
  monitoring_interval     = 10

  db_parameter_group_name         = aws_db_parameter_group.aurora_db_postgres11_parameter_group.id
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora_cluster_postgres11_parameter_group.id

  tags = {
    Environment = "develop"
    Terraform   = "true"
  }
}


############################
# Example of security group
############################
resource "aws_security_group" "rds-sg" {
  name_prefix = "default"
  description = "For application servers"
  vpc_id      = module.network.aws_vpc_id
}

resource "aws_security_group_rule" "allow_access" {
  type                     = "ingress"
  from_port                = module.db.this_rds_cluster_port
  to_port                  = module.db.this_rds_cluster_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.rds-sg.id
  security_group_id        = module.db.this_security_group_id
}
