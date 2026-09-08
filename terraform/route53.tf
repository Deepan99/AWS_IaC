# ==============================================================================
# ROUTE 53 PRIVATE HOSTED ZONE & MULTI-VPC ASSOCIATIONS
# ==============================================================================

resource "aws_route53_zone" "internal" {
  name = var.private_domain_name

  vpc {
    vpc_id = aws_vpc.hub.id
  }

  tags = {
    Name = "${var.private_domain_name}-PrivateZone"
  }
}

resource "aws_route53_zone_association" "spoke1_assoc" {
  zone_id = aws_route53_zone.internal.id
  vpc_id  = aws_vpc.spoke1.id
}

resource "aws_route53_zone_association" "spoke2_assoc" {
  zone_id = aws_route53_zone.internal.id
  vpc_id  = aws_vpc.spoke2.id
}

# Internal A-Records
resource "aws_route53_record" "spoke1_record" {
  zone_id = aws_route53_zone.internal.id
  name    = "spoke1.${var.private_domain_name}"
  type    = "A"
  ttl     = 60
  records = [aws_instance.spoke1_app.private_ip]
}

resource "aws_route53_record" "hub_record" {
  zone_id = aws_route53_zone.internal.id
  name    = "hub.${var.private_domain_name}"
  type    = "A"
  ttl     = 60
  records = [aws_instance.hub_router.private_ip]
}

resource "aws_route53_record" "proxy_record" {
  zone_id = aws_route53_zone.internal.id
  name    = "proxy.${var.private_domain_name}"
  type    = "A"
  ttl     = 60
  records = [aws_instance.hub_router.private_ip]
}
