# ==============================================================================
# SPOKE 1 PRIVATE PRODUCTION APP SERVERS (HA CLUSTER)
# ==============================================================================

# Node A
resource "aws_instance" "spoke1_app" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.spoke1_private.id
  vpc_security_group_ids      = [aws_security_group.spoke1_sg.id]
  associate_public_ip_address = false

  user_data = file("${path.module}/scripts/spoke1_bootstrap.sh")

  tags = {
    Name        = "Spoke1-Prod-App"
    Environment = "Production"
    Tier        = "App"
    Role        = "HA-Backend-Node-A"
  }
}

# Node B (High Availability Redundant Node)
resource "aws_instance" "spoke1_app_b" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.spoke1_private.id
  vpc_security_group_ids      = [aws_security_group.spoke1_sg.id]
  associate_public_ip_address = false

  user_data = file("${path.module}/scripts/spoke1_bootstrap.sh")

  tags = {
    Name        = "Spoke1-Prod-App-B"
    Environment = "Production"
    Tier        = "App"
    Role        = "HA-Backend-Node-B"
  }
}

# ==============================================================================
# SPOKE 2 PRIVATE DEVELOPMENT APP SERVER
# ==============================================================================

resource "aws_instance" "spoke2_app" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.spoke2_private.id
  vpc_security_group_ids      = [aws_security_group.spoke2_sg.id]
  associate_public_ip_address = false

  tags = {
    Name        = "Spoke2-Dev-App"
    Environment = "Development"
    Tier        = "App"
  }
}

