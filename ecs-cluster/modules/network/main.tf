################
# VPC Resource #
###############
resource aws_vpc ecs-cluster-vpc {
  cidr_block = var.cidr_block

  tags = {
    Terraform = "true"
    Name      = format("%s VPC", var.network_name)
    Env       = var.environment_tag
  }
}

###################
# Subnet Resource #
##################
resource "aws_subnet" "private-1" {
  vpc_id            = aws_vpc.ecs-cluster-vpc.id
  cidr_block        = cidrsubnet(aws_vpc.ecs-cluster-vpc.cidr_block, var.cidr_block_newbits, 0)
  availability_zone = format("%s%s", var.region, var.subnet_1_zone)

  tags = {
    Terraform = "true"
    Name      = format("%s Private - %s", var.network_name, var.subnet_1_zone)
    Env       = var.environment_tag
    Type      = "Private"
  }
}

resource "aws_subnet" "private-2" {
  vpc_id            = aws_vpc.ecs-cluster-vpc.id
  cidr_block        = cidrsubnet(aws_vpc.ecs-cluster-vpc.cidr_block, var.cidr_block_newbits, 1)
  availability_zone = format("%s%s", var.region, var.subnet_2_zone)

  tags = {
    Terraform = "true"
    Name      = format("%s Private - %s", var.network_name, var.subnet_2_zone)
    Env       = var.environment_tag
    Type      = "Private"
  }
}

resource "aws_subnet" "public-1" {
  vpc_id            = aws_vpc.ecs-cluster-vpc.id
  cidr_block        = cidrsubnet(aws_vpc.ecs-cluster-vpc.cidr_block, var.cidr_block_newbits, 100)
  availability_zone = format("%s%s", var.region, var.subnet_1_zone)

  tags = {
    Terraform = "true"
    Name      = format("%s Public - %s", var.network_name, var.subnet_1_zone)
    Env       = var.environment_tag
    Type      = "Public"
  }
}

resource "aws_subnet" "public-2" {
  vpc_id            = aws_vpc.ecs-cluster-vpc.id
  cidr_block        = cidrsubnet(aws_vpc.ecs-cluster-vpc.cidr_block, var.cidr_block_newbits, 101)
  availability_zone = format("%s%s", var.region, var.subnet_2_zone)

  tags = {
    Terraform = "true"
    Name      = format("%s Public - %s", var.network_name, var.subnet_2_zone)
    Env       = var.environment_tag
    Type      = "Public"
  }
}

####################
# Internet Gateway #
###################
resource "aws_internet_gateway" "ecs-internet-gateway" {
  vpc_id = aws_vpc.ecs-cluster-vpc.id

  tags = {
    Terraform = "true"
    Name      = format("%s", var.network_name)
    Env       = var.environment_tag
  }
}

#################
# Route Tables #
###############
resource "aws_route_table_association" "ecs-public-1-route-table" {
  subnet_id      = aws_subnet.public-1.id
  route_table_id = aws_vpc.ecs-cluster-vpc.main_route_table_id
}

resource "aws_route_table_association" "ecs-public-2-route-table" {
  subnet_id      = aws_subnet.public-2.id
  route_table_id = aws_vpc.ecs-cluster-vpc.main_route_table_id
}

resource "aws_default_route_table" "ecs-public-route-table" {
  default_route_table_id = aws_vpc.ecs-cluster-vpc.main_route_table_id

  tags = {
    Terraform = "true"
    Env       = var.environment_tag
    Name      = format("%s Public", var.network_name)
  }
}

resource "aws_route_table" "ecs-private-route-table" {
  vpc_id = aws_vpc.ecs-cluster-vpc.id

  tags = {
    Terraform = "true"
    Env       = var.environment_tag
    Name      = format("%s Private", var.network_name)
  }
}

resource "aws_route_table_association" "ecs-private-1-route-table" {
  subnet_id      = aws_subnet.private-1.id
  route_table_id = aws_route_table.ecs-private-route-table.id
}

resource "aws_route_table_association" "ecs-private-2-route-table" {
  subnet_id      = aws_subnet.private-2.id
  route_table_id = aws_route_table.ecs-private-route-table.id
}

#################
# NAT Gateways #
###############
resource "aws_eip" "ecs-public-1-ng-eip" {
  vpc              = true
  public_ipv4_pool = "amazon"

  tags = {
    Terraform = "true"
    Env       = var.environment_tag
    Name      = format("%s Public %s", var.network_name, var.subnet_1_zone)
  }
}

resource "aws_nat_gateway" "ecs-public-1-gw" {
  allocation_id = aws_eip.ecs-public-1-ng-eip.id
  subnet_id     = aws_subnet.public-1.id

  tags = {
    Terraform = "true"
    Env       = var.environment_tag
    Name      = format("%s Public %s", var.network_name, var.subnet_1_zone)
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
  nat_gateway_id         = aws_nat_gateway.ecs-public-1-gw.id
  depends_on             = [aws_nat_gateway.ecs-public-1-gw]
}
