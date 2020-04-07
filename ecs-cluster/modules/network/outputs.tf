output aws_vpc_id {
  description = "ECS VPC Id"
  value       = aws_vpc.ecs-cluster-vpc.id
}

data aws_subnet_ids private-subnets {
  vpc_id = aws_vpc.ecs-cluster-vpc.id

  depends_on = [aws_vpc.ecs-cluster-vpc, aws_subnet.private-1, aws_subnet.private-2, aws_subnet.public-1, aws_subnet.public-2]

  tags = {
    Type = "Private"
  }
}

data aws_subnet_ids public_subnets {
  vpc_id = aws_vpc.ecs-cluster-vpc.id

  depends_on = [aws_vpc.ecs-cluster-vpc, aws_subnet.private-1, aws_subnet.private-2, aws_subnet.public-1, aws_subnet.public-2]

  tags = {
    Type = "Public"
  }
}

data aws_security_group vpc-default-sg {
  vpc_id = aws_vpc.ecs-cluster-vpc.id
  name   = "default"
}

output subnet_cidr_blocks_private {
  value = data.aws_subnet_ids.private-subnets.ids
}

output subnet_cidr_blocks_public {
  value = data.aws_subnet_ids.public_subnets.ids
}

output vpc_cidr_block {
  value = aws_vpc.ecs-cluster-vpc.cidr_block
}

output vpc_default_sg {
  value = data.aws_security_group.vpc-default-sg.id
}
