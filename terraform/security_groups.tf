# ==============================================================================
# SECURITY GROUPS & FIREWALL RULES
# ==============================================================================

# Hub Security Group (Ingress Proxy, Squid Egress, SSH)
resource "aws_security_group" "hub_sg" {
  name        = "Hub-NAT-Router-SG"
  description = "Hub Ingress Reverse Proxy, Squid Egress, and Management"
  vpc_id      = aws_vpc.hub.id

  # SSH Management
  ingress {
    description = "SSH Administration"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Ingress Proxy (Zero-Cost ALB)
  ingress {
    description = "Public HTTP Ingress"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Public HTTPS Ingress"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Squid Forward Egress Proxy
  ingress {
    description = "Squid Proxy from Spoke VPCs"
    from_port   = 3128
    to_port     = 3128
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Hub-NAT-Router-SG"
  }
}

# Spoke 1 Prod Security Group
resource "aws_security_group" "spoke1_sg" {
  name        = "Spoke1-Prod-SG"
  description = "Allow all traffic exclusively from Hub VPC"
  vpc_id      = aws_vpc.spoke1.id

  ingress {
    description = "Allow All Inbound from Hub VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.hub_vpc_cidr]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Spoke1-Prod-SG"
  }
}

# Spoke 2 Dev Security Group
resource "aws_security_group" "spoke2_sg" {
  name        = "Spoke2-Dev-SG"
  description = "Allow all traffic exclusively from Hub VPC"
  vpc_id      = aws_vpc.spoke2.id

  ingress {
    description = "Allow All Inbound from Hub VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.hub_vpc_cidr]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Spoke2-Dev-SG"
  }
}
