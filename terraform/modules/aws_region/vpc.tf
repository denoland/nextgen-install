// Copyright Deno Land Inc. All Rights Reserved. Proprietary and confidential.

resource "aws_vpc" "shh_vpc" {
  cidr_block                       = "192.168.0.0/16"
  enable_dns_support               = true
  enable_dns_hostnames             = true
  instance_tenancy                 = "default"
  assign_generated_ipv6_cidr_block = true

  tags = {
    Name                     = "${var.eks_cluster_name}-vpc",
    "karpenter.sh/discovery" = var.eks_cluster_name,
  }
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.shh_vpc.id
}

resource "aws_subnet" "shh_subnet1" {
  availability_zone               = local.eks_cluster_az1
  cidr_block                      = cidrsubnet(aws_vpc.shh_vpc.cidr_block, 4, 8)
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.shh_vpc.ipv6_cidr_block, 8, 128)
  vpc_id                          = aws_vpc.shh_vpc.id
  map_public_ip_on_launch         = true
  assign_ipv6_address_on_creation = true

  tags = {
    Name                                            = "${var.eks_cluster_name}-subnet1",
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "",
    "kubernetes.io/role/elb"                        = "1",
    "karpenter.sh/discovery"                        = var.eks_cluster_name,
  }
}

resource "aws_subnet" "shh_subnet2" {
  availability_zone               = local.eks_cluster_az2
  cidr_block                      = cidrsubnet(aws_vpc.shh_vpc.cidr_block, 4, 9)
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.shh_vpc.ipv6_cidr_block, 8, 129)
  vpc_id                          = aws_vpc.shh_vpc.id
  map_public_ip_on_launch         = true
  assign_ipv6_address_on_creation = true

  tags = {
    Name                                            = "${var.eks_cluster_name}-subnet2",
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "",
    "kubernetes.io/role/elb"                        = "1",
  }
}

resource "aws_internet_gateway" "shh_internet_gateway" {
  vpc_id = aws_vpc.shh_vpc.id
}

resource "aws_route" "shh_route" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.shh_internet_gateway.id
  route_table_id         = aws_route_table.shh_route_table.id
}

resource "aws_route_table" "shh_route_table" {
  vpc_id = aws_vpc.shh_vpc.id
}

resource "aws_route_table_association" "shh_assouciation1" {
  route_table_id = aws_route_table.shh_route_table.id
  subnet_id      = aws_subnet.shh_subnet1.id
}

resource "aws_route_table_association" "shh_assouciation2" {
  route_table_id = aws_route_table.shh_route_table.id
  subnet_id      = aws_subnet.shh_subnet2.id
}
