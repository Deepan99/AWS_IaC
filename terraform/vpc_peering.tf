# ==============================================================================
# VPC PEERING CONNECTIONS
# ==============================================================================

resource "aws_vpc_peering_connection" "hub_to_spoke1" {
  vpc_id      = aws_vpc.hub.id
  peer_vpc_id = aws_vpc.spoke1.id
  auto_accept = true

  tags = {
    Name = "Hub-to-Spoke1-Peering"
  }
}

resource "aws_vpc_peering_connection" "hub_to_spoke2" {
  vpc_id      = aws_vpc.hub.id
  peer_vpc_id = aws_vpc.spoke2.id
  auto_accept = true

  tags = {
    Name = "Hub-to-Spoke2-Peering"
  }
}
