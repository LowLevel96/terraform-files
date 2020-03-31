provider "aws" {
  region = "eu-west-1"
}

################
# VPC Resource #
###############
resource "aws_vpc" "ecs-cluster-vpc" {
  cidr_block = "10.0.0.0/26"

  tags = {
    Terraform = "true"
    Name      = "ECS Cluster VPC"
    Env       = "develop"
  }
}

###################
# Subnet Resource #
##################
resource "aws_subnet" "private-a" {
  vpc_id            = aws_vpc.ecs-cluster-vpc.id
  cidr_block        = "10.0.0.0/28"
  availability_zone = "eu-west-1a"

  tags = {
    Terraform = "true"
    Name      = "ECS Private Subnet - a"
    Env       = "develop"
    Type      = "Private"
  }
}

resource "aws_subnet" "private-c" {
  vpc_id            = aws_vpc.ecs-cluster-vpc.id
  cidr_block        = "10.0.0.16/28"
  availability_zone = "eu-west-1c"

  tags = {
    Terraform = "true"
    Name      = "ECS Private Subnet - c"
    Env       = "develop"
    Type      = "Private"
  }
}

resource "aws_subnet" "public-a" {
  vpc_id            = aws_vpc.ecs-cluster-vpc.id
  cidr_block        = "10.0.0.32/28"
  availability_zone = "eu-west-1a"

  tags = {
    Terraform = "true"
    Name      = "ECS Public Subnet - a"
    Env       = "develop"
    Type      = "Public"
  }
}

resource "aws_subnet" "public-c" {
  vpc_id            = aws_vpc.ecs-cluster-vpc.id
  cidr_block        = "10.0.0.48/28"
  availability_zone = "eu-west-1c"

  tags = {
    Terraform = "true"
    Name      = "ECS Public Subnet - c"
    Env       = "develop"
    Type      = "Public"
  }
}

####################
# Internet Gateway #
###################
resource "aws_internet_gateway" "ecs-internet-gateway" {
  vpc_id = aws_vpc.ecs-cluster-vpc.id

  tags = {
    Name = "ECS Cluster IG"
  }
}

#################
# Route Tables #
###############
resource "aws_route_table_association" "ecs-public-a-route-table" {
  subnet_id      = aws_subnet.public-a.id
  route_table_id = aws_vpc.ecs-cluster-vpc.main_route_table_id
}

resource "aws_route_table_association" "ecs-public-c-route-table" {
  subnet_id      = aws_subnet.public-c.id
  route_table_id = aws_vpc.ecs-cluster-vpc.main_route_table_id
}

resource "aws_default_route_table" "ecs-public-route-table" {
  default_route_table_id = aws_vpc.ecs-cluster-vpc.main_route_table_id

  tags = {
    Name = "ECS Public Route Table"
  }
}

resource "aws_route_table" "ecs-private-route-table" {
  vpc_id = aws_vpc.ecs-cluster-vpc.id

  tags = {
    Name = "ECS Private Route Table"
  }
}

resource "aws_route_table_association" "ecs-private-a-route-table" {
  subnet_id      = aws_subnet.private-a.id
  route_table_id = aws_route_table.ecs-private-route-table.id
}

resource "aws_route_table_association" "ecs-private-c-route-table" {
  subnet_id      = aws_subnet.private-c.id
  route_table_id = aws_route_table.ecs-private-route-table.id
}

#################
# NAT Gateways #
###############
resource "aws_eip" "ecs-public-a-ng-eip" {
  vpc              = true
  public_ipv4_pool = "amazon"

  tags = {
    Name = "ECS Public A - EIP"
  }
}

resource "aws_nat_gateway" "ecs-public-a-gw" {
  allocation_id = aws_eip.ecs-public-a-ng-eip.id
  subnet_id     = aws_subnet.public-a.id

  tags = {
    Name = "ECS Public A - GW"
  }
}

#########################
# Route Tables - Routes #
########################
resource "aws_route" "ecs-ig-route" {
  route_table_id         = aws_default_route_table.ecs-public-route-table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ecs-internet-gateway.id
  depends_on             = [aws_default_route_table.ecs-public-route-table]
}

resource "aws_route" "ecs-ng-a-route" {
  route_table_id         = aws_route_table.ecs-private-route-table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.ecs-public-a-gw.id
  depends_on             = [aws_nat_gateway.ecs-public-a-gw]
}
