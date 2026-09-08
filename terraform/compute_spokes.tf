# ==============================================================================
# SPOKE 1 PRIVATE PRODUCTION APP SERVER
# ==============================================================================

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
  }
}
