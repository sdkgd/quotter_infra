#####################################################
# VPC
#####################################################

resource "aws_vpc" "this" {
  cidr_block = "10.0.0.0/16"
  tags={
    Name=local.app_name
  }
}

#####################################################
# Internet Gateway
#####################################################

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags={
    Name=local.app_name
  }
}

#####################################################
# Subnet
#####################################################

resource "aws_subnet" "public_1a" {
  vpc_id = aws_vpc.this.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-northeast-1a"
  tags={
    Name="${local.app_name}-public-1a"
  }
}

resource "aws_subnet" "public_1c" {
  vpc_id = aws_vpc.this.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-northeast-1c"
  tags={
    Name="${local.app_name}-public-1c"
  }
}

resource "aws_subnet" "private_1a" {
  vpc_id = aws_vpc.this.id
  cidr_block = "10.0.10.0/24"
  availability_zone = "ap-northeast-1a"
  tags={
    Name="${local.app_name}-private-1a"
  }
}

resource "aws_subnet" "private_1c" {
  vpc_id = aws_vpc.this.id
  cidr_block = "10.0.20.0/24"
  availability_zone = "ap-northeast-1c"
  tags={
    Name="${local.app_name}-private-1c"
  }
}

#####################################################
# Elastic IP for NAT Gateway
#####################################################

resource "aws_eip" "nat_1a" {
  domain = "vpc"
  tags = {
    Name="${local.app_name}-eip-for-natgw-1a"
  }
}

resource "aws_eip" "nat_1c" {
  domain = "vpc"
  tags = {
    Name="${local.app_name}-eip-for-natgw-1c"
  }
}

#####################################################
# NAT Gateway
#####################################################

resource "aws_nat_gateway" "nat_1a" {
  subnet_id = aws_subnet.public_1a.id
  allocation_id = aws_eip.nat_1a.id
  tags = {
    Name="${local.app_name}-natgw-1a"
  }
}

resource "aws_nat_gateway" "nat_1c" {
  subnet_id = aws_subnet.public_1c.id
  allocation_id = aws_eip.nat_1c.id
  tags = {
    Name="${local.app_name}-natgw-1c"
  }
}

#####################################################
# Public Subnet Route Table
#####################################################

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name="${local.app_name}-public"
  }
}

resource "aws_route" "internet_gateway_public" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.this.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1a_to_ig" {
  subnet_id = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1c_to_ig" {
  subnet_id = aws_subnet.public_1c.id
  route_table_id = aws_route_table.public.id
}

#####################################################
# Private Subnet Route Table for AZ1a
#####################################################

resource "aws_route_table" "private_1a" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name="${local.app_name}-private-1a"
  }
}

resource "aws_route" "nat_gateway_private_1a" {
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat_1a.id
  route_table_id = aws_route_table.private_1a.id
}

resource "aws_route_table_association" "private_1a" {
  subnet_id = aws_subnet.private_1a.id
  route_table_id = aws_route_table.private_1a.id
}

#####################################################
# Private Subnet Route Table for AZ1c
#####################################################

resource "aws_route_table" "private_1c" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name="${local.app_name}-private-1c"
  }
}

resource "aws_route" "nat_gateway_private_1c" {
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat_1c.id
  route_table_id = aws_route_table.private_1c.id
}

resource "aws_route_table_association" "private_1c" {
  subnet_id = aws_subnet.private_1c.id
  route_table_id = aws_route_table.private_1c.id
}