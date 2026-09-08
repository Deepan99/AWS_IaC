# ==============================================================================
# OUTPUTS
# ==============================================================================

output "hub_public_ip" {
  description = "Public IP of Hub Ingress Proxy & NAT Router"
  value       = aws_instance.hub_router.public_ip
}

output "hub_private_ip" {
  description = "Private IP of Hub NAT Router"
  value       = aws_instance.hub_router.private_ip
}

output "spoke1_private_ip" {
  description = "Private IP of Spoke 1 Production App"
  value       = aws_instance.spoke1_app.private_ip
}

output "ingress_proxy_url" {
  description = "Public Browser URL to access the Spoke 1 App via Hub Ingress Proxy"
  value       = "http://${aws_instance.hub_router.public_ip}"
}

output "internal_dns_url" {
  description = "Internal Route 53 URL for Spoke 1 App"
  value       = "http://spoke1.${var.private_domain_name}"
}

output "egress_proxy_address" {
  description = "Central Squid Egress Proxy Address for Spokes"
  value       = "http://proxy.${var.private_domain_name}:3128"
}

output "hub_vpc_id" {
  description = "Hub VPC ID"
  value       = aws_vpc.hub.id
}

output "spoke1_vpc_id" {
  description = "Spoke 1 VPC ID"
  value       = aws_vpc.spoke1.id
}

output "spoke2_vpc_id" {
  description = "Spoke 2 VPC ID"
  value       = aws_vpc.spoke2.id
}

output "route53_hosted_zone_id" {
  description = "Route 53 Private Hosted Zone ID"
  value       = aws_route53_zone.internal.id
}
