output "aws_vpc_id" {
  description = "ECS VPC Id"
  value       = aws_vpc.ecs-cluster-vpc.id
}

data "aws_subnet_ids" "private-subnets" {
  vpc_id = aws_vpc.ecs-cluster-vpc.id

  tags = {
    Type = "Private"
  }
}

data "aws_subnet_ids" "public-subnets" {
  vpc_id = aws_vpc.ecs-cluster-vpc.id

  tags = {
    Type = "Public"
  }
}

output "subnet_cidr_blocks_private" {
  value = data.aws_subnet_ids.private-subnets.ids
}

output "subnet_cidr_blocks_public" {
  value = data.aws_subnet_ids.public-subnets.ids
}

output "vpc_cidr_block" {
  value = aws_vpc.ecs-cluster-vpc.cidr_block
}
