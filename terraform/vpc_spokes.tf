# ==============================================================================
# SPOKE 1 (PROD) & SPOKE 2 (DEV) NETWORKING
# ==============================================================================

# --- Spoke 1 (Prod VPC) ---
resource "aws_vpc" "spoke1" {
  cidr_block           = var.spoke1_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "Spoke1-Prod-VPC"
    Tier = "Production"
  }
}

resource "aws_subnet" "spoke1_private" {
  vpc_id                  = aws_vpc.spoke1.id
  cidr_block              = var.spoke1_private_subnet_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = false

  tags = {
    Name = "Spoke1-Private-Subnet-1"
    Type = "Private"
  }
}

resource "aws_route_table" "spoke1_private" {
  vpc_id = aws_vpc.spoke1.id

  route {
    cidr_block                = var.hub_vpc_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.hub_to_spoke1.id
  }

  tags = {
    Name = "Spoke1-Prod-RT"
  }
}

resource "aws_route_table_association" "spoke1_private_assoc" {
  subnet_id      = aws_subnet.spoke1_private.id
  route_table_id = aws_route_table.spoke1_private.id
}

# --- Spoke 2 (Dev VPC) ---
resource "aws_vpc" "spoke2" {
  cidr_block           = var.spoke2_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "Spoke2-Dev-VPC"
    Tier = "Development"
  }
}

resource "aws_subnet" "spoke2_private" {
  vpc_id                  = aws_vpc.spoke2.id
  cidr_block              = var.spoke2_private_subnet_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = false

  tags = {
    Name = "Spoke2-Private-Subnet-1"
    Type = "Private"
  }
}

resource "aws_route_table" "spoke2_private" {
  vpc_id = aws_vpc.spoke2.id

  route {
    cidr_block                = var.hub_vpc_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.hub_to_spoke2.id
  }

  tags = {
    Name = "Spoke2-Dev-RT"
  }
}

resource "aws_route_table_association" "spoke2_private_assoc" {
  subnet_id      = aws_subnet.spoke2_private.id
  route_table_id = aws_route_table.spoke2_private.id
}
