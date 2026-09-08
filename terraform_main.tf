# ==============================================================================
# AWS Zero-Cost Hub-and-Spoke Enterprise Network - Terraform Blueprint
# Region: ap-south-1 (Mumbai)
# Includes:
#   - Hub VPC (10.0.0.0/16), Spoke 1 Prod VPC (10.1.0.0/16), Spoke 2 Dev VPC (10.2.0.0/16)
#   - VPC Peering Connections & Bidirectional Routing
#   - Hub NAT/Router EC2 (NGINX Central Ingress + Squid Egress Firewall)
#   - Spoke 1 Private Prod App EC2 (Isolated Web Server)
#   - Route 53 Private Hosted Zone (corp.internal) associated with all 3 VPCs
# ==============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "AWS deployment region"
  type        = string
  default     = "ap-south-1"
}

variable "key_name" {
  description = "EC2 Key Pair Name"
  type        = string
  default     = "hub-vpc-key"
}

variable "instance_type" {
  description = "EC2 Instance Type"
  type        = string
  default     = "t3.micro"
}

# ==============================================================================
# 1. NETWORKING - HUB VPC (10.0.0.0/16)
# ==============================================================================
resource "aws_vpc" "hub_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "hub-VPC", Environment = "Hub" }
}

resource "aws_internet_gateway" "hub_igw" {
  vpc_id = aws_vpc.hub_vpc.id
  tags   = { Name = "Hub-IGW" }
}

resource "aws_subnet" "hub_public_subnet" {
  vpc_id                  = aws_vpc.hub_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags = { Name = "Hub-Public-Subnet-1" }
}

resource "aws_route_table" "hub_public_rt" {
  vpc_id = aws_vpc.hub_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.hub_igw.id
  }
  route {
    cidr_block                = "10.1.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.hub_to_spoke1.id
  }
  route {
    cidr_block                = "10.2.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.hub_to_spoke2.id
  }
  tags = { Name = "Hub-Public-RT" }
}

resource "aws_route_table_association" "hub_public_assoc" {
  subnet_id      = aws_subnet.hub_public_subnet.id
  route_table_id = aws_route_table.hub_public_rt.id
}

# ==============================================================================
# 2. NETWORKING - SPOKE 1 PROD VPC (10.1.0.0/16)
# ==============================================================================
resource "aws_vpc" "spoke1_vpc" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "Spoke1-Prod-VPC", Environment = "Production" }
}

resource "aws_subnet" "spoke1_private_subnet" {
  vpc_id                  = aws_vpc.spoke1_vpc.id
  cidr_block              = "10.1.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = false
  tags = { Name = "Spoke1-Private-Subnet-1" }
}

resource "aws_route_table" "spoke1_private_rt" {
  vpc_id = aws_vpc.spoke1_vpc.id
  route {
    cidr_block                = "10.0.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.hub_to_spoke1.id
  }
  tags = { Name = "Spoke1-Prod-RT" }
}

resource "aws_route_table_association" "spoke1_private_assoc" {
  subnet_id      = aws_subnet.spoke1_private_subnet.id
  route_table_id = aws_route_table.spoke1_private_rt.id
}

# ==============================================================================
# 3. NETWORKING - SPOKE 2 DEV VPC (10.2.0.0/16)
# ==============================================================================
resource "aws_vpc" "spoke2_vpc" {
  cidr_block           = "10.2.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "Spoke2-Dev-VPC", Environment = "Development" }
}

resource "aws_subnet" "spoke2_private_subnet" {
  vpc_id                  = aws_vpc.spoke2_vpc.id
  cidr_block              = "10.2.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = false
  tags = { Name = "Spoke2-Private-Subnet-1" }
}

resource "aws_route_table" "spoke2_private_rt" {
  vpc_id = aws_vpc.spoke2_vpc.id
  route {
    cidr_block                = "10.0.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.hub_to_spoke2.id
  }
  tags = { Name = "Spoke2-Dev-RT" }
}

resource "aws_route_table_association" "spoke2_private_assoc" {
  subnet_id      = aws_subnet.spoke2_private_subnet.id
  route_table_id = aws_route_table.spoke2_private_rt.id
}

# ==============================================================================
# 4. VPC PEERING CONNECTIONS
# ==============================================================================
resource "aws_vpc_peering_connection" "hub_to_spoke1" {
  vpc_id      = aws_vpc.hub_vpc.id
  peer_vpc_id = aws_vpc.spoke1_vpc.id
  auto_accept = true
  tags        = { Name = "Hub-to-Spoke1-Peering" }
}

resource "aws_vpc_peering_connection" "hub_to_spoke2" {
  vpc_id      = aws_vpc.hub_vpc.id
  peer_vpc_id = aws_vpc.spoke2_vpc.id
  auto_accept = true
  tags        = { Name = "Hub-to-Spoke2-Peering" }
}

# ==============================================================================
# 5. SECURITY GROUPS
# ==============================================================================
resource "aws_security_group" "hub_sg" {
  name        = "Hub-NAT-Router-SG"
  description = "Allow Ingress HTTP/HTTPS, SSH, and Squid Egress Proxy from Spokes"
  vpc_id      = aws_vpc.hub_vpc.id

  # SSH Management
  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Ingress Reverse Proxy (Zero-Cost ALB)
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

  # Egress Firewall Proxy (Squid)
  ingress {
    description = "Squid Proxy from Spoke VPCs"
    from_port   = 3128
    to_port     = 3128
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  # Outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "Hub-NAT-Router-SG" }
}

resource "aws_security_group" "spoke1_sg" {
  name        = "Spoke1-Prod-SG"
  description = "Allow traffic exclusively from Hub VPC"
  vpc_id      = aws_vpc.spoke1_vpc.id

  ingress {
    description = "Allow All Traffic from Hub VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "Spoke1-Prod-SG" }
}

# ==============================================================================
# 6. ROUTE 53 PRIVATE HOSTED ZONE (corp.internal)
# ==============================================================================
resource "aws_route53_zone" "internal" {
  name = "corp.internal"

  vpc {
    vpc_id = aws_vpc.hub_vpc.id
  }

  tags = {
    Name = "corp.internal-PrivateZone"
  }
}

resource "aws_route53_zone_association" "spoke1_assoc" {
  zone_id = aws_route53_zone.internal.id
  vpc_id  = aws_vpc.spoke1_vpc.id
}

resource "aws_route53_zone_association" "spoke2_assoc" {
  zone_id = aws_route53_zone.internal.id
  vpc_id  = aws_vpc.spoke2_vpc.id
}

resource "aws_route53_record" "spoke1_record" {
  zone_id = aws_route53_zone.internal.id
  name    = "spoke1.corp.internal"
  type    = "A"
  ttl     = 60
  records = [aws_instance.spoke1_app.private_ip]
}

resource "aws_route53_record" "hub_record" {
  zone_id = aws_route53_zone.internal.id
  name    = "hub.corp.internal"
  type    = "A"
  ttl     = 60
  records = [aws_instance.hub_router.private_ip]
}

resource "aws_route53_record" "proxy_record" {
  zone_id = aws_route53_zone.internal.id
  name    = "proxy.corp.internal"
  type    = "A"
  ttl     = 60
  records = [aws_instance.hub_router.private_ip]
}

# ==============================================================================
# 7. EC2 INSTANCES & BOOTSTRAP USER DATA
# ==============================================================================
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# Hub Router / NGINX Ingress / Squid Egress Firewall
resource "aws_instance" "hub_router" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.hub_public_subnet.id
  vpc_security_group_ids      = [aws_security_group.hub_sg.id]
  source_dest_check           = false # Required for NAT routing
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y nginx squid iptables-services

              # 1. Configure iptables for NAT & Ingress
              echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
              sysctl -p
              iptables -t nat -A POSTROUTING -o ens5 -j MASQUERADE
              iptables -I INPUT -p tcp --dport 80 -j ACCEPT
              iptables -I INPUT -p tcp --dport 443 -j ACCEPT
              iptables -I INPUT -p tcp --dport 3128 -j ACCEPT
              iptables-save > /etc/sysconfig/iptables

              # 2. Configure NGINX Ingress Proxy with Route 53 Resolver
              cat << 'NGINX_EOF' > /etc/nginx/nginx.conf
              user nginx;
              worker_processes auto;
              events { worker_connections 1024; }
              http {
                  resolver 10.0.0.2 169.254.169.253 valid=10s;
                  upstream spoke1_backend {
                      server spoke1.corp.internal:80 max_fails=3 fail_timeout=10s;
                      keepalive 32;
                  }
                  server {
                      listen 80 default_server;
                      server_name _;
                      location / {
                          proxy_pass http://spoke1_backend;
                          proxy_http_version 1.1;
                          proxy_set_header Connection "";
                          proxy_set_header Host $host;
                          proxy_set_header X-Real-IP $remote_addr;
                          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                      }
                  }
              }
              NGINX_EOF
              systemctl enable --now nginx

              # 3. Configure Squid Egress Firewall Whitelist
              cat << 'SQUID_DOMAINS' > /etc/squid/allowed_domains.txt
              .amazonlinux.com
              .aws.amazon.com
              .amazonaws.com
              .github.com
              .githubusercontent.com
              .pypi.org
              .pythonhosted.org
              SQUID_DOMAINS

              cat << 'SQUID_CONF' > /etc/squid/squid.conf
              acl spoke_networks src 10.0.0.0/8
              acl allowed_domains dstdomain "/etc/squid/allowed_domains.txt"
              acl SSL_ports port 443
              acl Safe_ports port 80
              acl Safe_ports port 443
              acl CONNECT method CONNECT
              http_access deny !Safe_ports
              http_access deny CONNECT !SSL_ports
              http_access allow localhost
              http_access allow spoke_networks allowed_domains
              http_access deny all
              http_port 3128
              forwarded_for delete
              request_header_access Via deny all
              SQUID_CONF
              systemctl enable --now squid
              EOF

  tags = { Name = "Hub-Central-NAT-Router", Role = "IngressProxy-NAT-Firewall" }
}

# Spoke 1 Private Prod App Server
resource "aws_instance" "spoke1_app" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.spoke1_private_subnet.id
  vpc_security_group_ids      = [aws_security_group.spoke1_sg.id]
  associate_public_ip_address = false

  user_data = <<-EOF
              #!/bin/bash
              mkdir -p /var/www/app
              cat << 'HTML_EOF' > /var/www/app/index.html
              <!DOCTYPE html>
              <html>
              <head>
                <title>Spoke 1 Production Server</title>
                <style>
                  body { font-family: sans-serif; background: #0f172a; color: #f8fafc; text-align: center; padding: 50px 20px; }
                  .card { background: #1e293b; border-radius: 12px; padding: 40px; max-width: 650px; margin: 0 auto; box-shadow: 0 10px 25px rgba(0,0,0,0.5); }
                  h1 { color: #38bdf8; }
                  .info { background: #0f172a; border-radius: 8px; padding: 15px; margin: 20px 0; text-align: left; font-family: monospace; }
                </style>
              </head>
              <body>
                <div class="card">
                  <h1>🎉 Hello from Private Spoke 1!</h1>
                  <p>100% Private Workload routed via Zero-Cost Hub Ingress Proxy & Route 53 DNS.</p>
                  <div class="info">
                    • Hostname: spoke1.corp.internal<br>
                    • Subnet: Spoke1-Private-Subnet-1 (10.1.1.0/24)<br>
                    • Egress Proxy: proxy.corp.internal:3128
                  </div>
                </div>
              </body>
              </html>
              HTML_EOF

              cat << 'SVC_EOF' > /etc/systemd/system/spoke-app.service
              [Unit]
              Description=Spoke 1 Private App Web Server
              After=network.target
              [Service]
              WorkingDirectory=/var/www/app
              ExecStart=/usr/bin/python3 -m http.server 80
              Restart=always
              [Install]
              WantedBy=multi-user.target
              SVC_EOF

              systemctl daemon-reload
              systemctl enable --now spoke-app
              EOF

  tags = { Name = "Spoke1-Prod-App", Environment = "Production", Tier = "App" }
}

# ==============================================================================
# 8. OUTPUTS
# ==============================================================================
output "hub_public_ip" {
  description = "Hub Instance Public IP"
  value       = aws_instance.hub_router.public_ip
}

output "ingress_proxy_url" {
  description = "Public URL for Ingress Web Application"
  value       = "http://${aws_instance.hub_router.public_ip}"
}

output "route53_internal_domain" {
  description = "Internal Route 53 Domain"
  value       = "http://spoke1.corp.internal"
}
