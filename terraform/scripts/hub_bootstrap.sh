#!/bin/bash
set -e

# Update and install required packages
dnf update -y
dnf install -y nginx squid iptables-services

# 1. Enable Kernel IP Forwarding
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

# 2. Configure Linux iptables
iptables -t nat -A POSTROUTING -o ens5 -j MASQUERADE
iptables -I INPUT -p tcp --dport 80 -j ACCEPT
iptables -I INPUT -p tcp --dport 443 -j ACCEPT
iptables -I INPUT -p tcp --dport 3128 -j ACCEPT
iptables-save > /etc/sysconfig/iptables

# 3. Configure NGINX Ingress Reverse Proxy with Route 53 Service Discovery
cat << 'NGINX_EOF' > /etc/nginx/nginx.conf
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log notice;
pid /run/nginx.pid;
include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    access_log /var/log/nginx/access.log main;
    sendfile on;
    keepalive_timeout 65;
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # AWS VPC DNS Resolver
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
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_connect_timeout 5s;
            proxy_read_timeout 60s;
        }
    }
}
NGINX_EOF

systemctl enable --now nginx

# 4. Configure Squid Egress Firewall Whitelist
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
access_log daemon:/var/log/squid/access.log squid
SQUID_CONF

chown -R root:squid /etc/squid
systemctl enable --now squid
