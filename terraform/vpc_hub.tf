# ==============================================================================
# HUB VPC & PUBLIC NETWORKING
# ==============================================================================

resource "aws_vpc" "hub" {
  cidr_block           = var.hub_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "hub-VPC"
    Role = "Hub-Router"
  }
}

resource "aws_internet_gateway" "hub_igw" {
  vpc_id = aws_vpc.hub.id

  tags = {
    Name = "Hub-IGW"
  }
}

resource "aws_subnet" "hub_public" {
  vpc_id                  = aws_vpc.hub.id
  cidr_block              = var.hub_public_subnet_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Hub-Public-Subnet-1"
    Type = "Public"
  }
}

resource "aws_route_table" "hub_public" {
  vpc_id = aws_vpc.hub.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.hub_igw.id
  }

  route {
    cidr_block                = var.spoke1_vpc_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.hub_to_spoke1.id
  }

  route {
    cidr_block                = var.spoke2_vpc_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.hub_to_spoke2.id
  }

  tags = {
    Name = "Hub-Public-RT"
  }
}

resource "aws_route_table_association" "hub_public_assoc" {
  subnet_id      = aws_subnet.hub_public.id
  route_table_id = aws_route_table.hub_public.id
}
