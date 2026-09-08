# ==============================================================================
# HUB ROUTER / NGINX INGRESS / SQUID EGRESS FIREWALL EC2
# ==============================================================================

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_instance" "hub_router" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.hub_public.id
  vpc_security_group_ids      = [aws_security_group.hub_sg.id]
  source_dest_check           = false # Crucial for NAT routing
  associate_public_ip_address = true

  user_data = file("${path.module}/scripts/hub_bootstrap.sh")

  tags = {
    Name = "Hub-Central-NAT-Router"
    Role = "IngressProxy-NAT-EgressFirewall"
  }
}
