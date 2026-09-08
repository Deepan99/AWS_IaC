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

# 3. Generate High-Grade SSL/TLS Certificate for Ingress Gateway
mkdir -p /etc/pki/tls/certs /etc/pki/tls/private

cat << 'SSL_CONF' > /tmp/openssl_san.cnf
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = req_ext

[dn]
C = IN
ST = Maharashtra
L = Mumbai
O = Enterprise Cloud
OU = Network Security
CN = 13.207.69.181

[req_ext]
subjectAltName = @alt_names

[alt_names]
IP.1 = 13.207.69.181
IP.2 = 10.0.1.52
DNS.1 = hub.corp.internal
DNS.2 = proxy.corp.internal
DNS.3 = spoke1.corp.internal
DNS.4 = spoke2.corp.internal
DNS.5 = *.corp.internal
SSL_CONF

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/pki/tls/private/hub.key \
  -out /etc/pki/tls/certs/hub.crt \
  -config /tmp/openssl_san.cnf \
  -extensions req_ext

chmod 600 /etc/pki/tls/private/hub.key
chmod 644 /etc/pki/tls/certs/hub.crt

# 4. Configure NGINX Ingress Reverse Proxy with HTTPS (Port 443), WAF Shield, and Rate Limiting
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
                    '"$http_user_agent" "$http_x_forwarded_for" '
                    'ssl_proto: $ssl_protocol cipher: $ssl_cipher '
                    'upstream: $upstream_addr status: $upstream_status response_time: $upstream_response_time';
    access_log /var/log/nginx/access.log main;
    sendfile on;
    tcp_nopush on;
    keepalive_timeout 65;
    types_hash_max_size 4096;
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # AWS VPC DNS Resolver
    resolver 10.0.0.2 169.254.169.253 valid=10s ipv6=off;

    # WAF Rate Limiting Zone (10 req/s, Burst=15)
    limit_req_zone $binary_remote_addr zone=waf_rate_limit:10m rate=10r/s;
    limit_req_status 429;

    # WAF Bad Bot & Scanner Blocklist
    map $http_user_agent $bad_bot {
        default 0;
        ~*(sqlmap|nikto|wpscan|dirbuster|acunetix|masscan|nessus|nmap|zgrab|morfeus) 1;
    }

    # Upstream Production HA Cluster (Active-Active Round Robin + Auto-Failover)
    upstream spoke1_prod_cluster {
        server node1.prod.corp.internal:80 max_fails=2 fail_timeout=5s;
        server node2.prod.corp.internal:80 max_fails=2 fail_timeout=5s;
        keepalive 32;
    }

    # Port 80 -> Strict 301 Permanent Redirect to HTTPS
    server {
        listen 80 default_server;
        server_name _;
        return 301 https://$host$request_uri;
    }

    # Port 443 -> TLS 1.2 & 1.3 Terminated Ingress Gateway + WAF Shield
    server {
        listen 443 ssl default_server;
        server_name _;

        ssl_certificate /etc/pki/tls/certs/hub.crt;
        ssl_certificate_key /etc/pki/tls/private/hub.key;

        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_prefer_server_ciphers on;
        ssl_ciphers HIGH:!aNULL:!MD5:!3DES:!CAMELLIA:!AES128;
        ssl_session_cache shared:SSL:10m;
        ssl_session_timeout 10m;

        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

        # Apply Global Rate Limiting
        limit_req zone=waf_rate_limit burst=15 nodelay;

        # Block Malicious User-Agents
        if ($bad_bot) {
            return 403;
        }

        # Block Exploit Probes
        location ~* (\.env|\.git|\.aws|\.\./|union.*select|eval\() {
            default_type text/html;
            return 403 '<!DOCTYPE html><html><head><title>403 Forbidden</title></head><body style="background:#0f172a;color:#f8fafc;font-family:sans-serif;text-align:center;padding:50px;"><h1>🚫 403 Forbidden: WAF Threat Blocked</h1><p>The Zero-Cost WAF Shield blocked this request.</p></body></html>';
        }

        # Custom 429 Rate Limit Exceeded Page
        error_page 429 = @rate_limited;
        location @rate_limited {
            default_type text/html;
            return 429 '<!DOCTYPE html><html><head><title>429 Too Many Requests</title></head><body style="background:#0f172a;color:#f8fafc;font-family:sans-serif;text-align:center;padding:50px;"><h1>⚡ 429 Rate Limit Exceeded</h1><p>Anti-DDoS WAF active (Max 10 req/s). Please slow down.</p></body></html>';
        }

        # Gateway Portal (Root)
        location = / {
            default_type text/html;
            return 200 '<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Enterprise Cloud Gateway (HTTPS + WAF)</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #0f172a; color: #f8fafc; display: flex; justify-content: center; align-items: center; min-height: 100vh; margin: 0; }
    .card { background: #1e293b; padding: 2.5rem; border-radius: 1rem; box-shadow: 0 20px 25px -5px rgba(0,0,0,0.5); border: 1px solid #334155; max-width: 600px; width: 100%; }
    .badge { display: inline-block; padding: 0.35rem 0.85rem; border-radius: 9999px; font-weight: 700; font-size: 0.875rem; background-color: #3b82f6; color: #ffffff; text-transform: uppercase; }
    .waf-badge { display: inline-block; padding: 0.35rem 0.85rem; border-radius: 9999px; font-weight: 700; font-size: 0.875rem; background-color: #10b981; color: #ffffff; text-transform: uppercase; margin-left: 0.5rem; }
    h1 { margin-top: 1rem; font-size: 1.75rem; color: #60a5fa; }
    p { color: #94a3b8; font-size: 0.95rem; }
    .btn-group { display: flex; flex-direction: column; gap: 0.75rem; margin-top: 1.5rem; }
    .btn { display: flex; justify-content: space-between; align-items: center; padding: 1rem 1.25rem; background: #0f172a; color: #f8fafc; text-decoration: none; border-radius: 0.5rem; border: 1px solid #334155; font-weight: 600; transition: all 0.2s; }
    .btn:hover { border-color: #3b82f6; background: #1e293b; transform: translateY(-2px); }
    .btn-prod { border-left: 4px solid #10b981; }
    .btn-dev { border-left: 4px solid #f59e0b; }
    .tag { font-size: 0.75rem; padding: 0.2rem 0.6rem; border-radius: 4px; }
    .tag-prod { background: #064e3b; color: #6ee7b7; }
    .tag-dev { background: #78350f; color: #fcd34d; }
    .footer { color: #64748b; font-size: 0.8rem; text-align: center; margin-top: 1.5rem; border-top: 1px solid #334155; padding-top: 1rem; }
  </style>
</head>
<body>
  <div class="card">
    <div>
      <span class="badge">Central Hub Router</span>
      <span class="waf-badge">🛡️ WAF & Anti-DDoS Active</span>
    </div>
    <h1>🏢 Enterprise Service Gateway</h1>
    <p>Zero-Cost Multi-VPC Hub-and-Spoke Routing Architecture with End-to-End SSL/TLS Termination & WAF Protection.</p>
    
    <div class="btn-group">
      <a href="/prod/" class="btn btn-prod">
        <span>🚀 Spoke 1: Production HA Cluster</span>
        <span class="tag tag-prod">Node A + Node B (WAF Protected)</span>
      </a>
      <a href="/dev/" class="btn btn-dev">
        <span>🧪 Spoke 2: Development Web App</span>
        <span class="tag tag-dev">Isolated Spoke (WAF Protected)</span>
      </a>
    </div>

    <div class="footer">
      AWS Zero-Cost Enterprise Hub-and-Spoke Architecture • Strict 301 HTTPS & WAF Enforced
    </div>
  </div>
</body>
</html>';
        }

        # Path-based routing to Spoke 1 Production HA Cluster
        location /prod/ {
            proxy_pass http://spoke1_prod_cluster/;
            proxy_http_version 1.1;
            proxy_set_header Connection "";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto https;
            proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
            proxy_connect_timeout 2s;
            proxy_read_timeout 5s;
        }

        # Path-based routing to Spoke 2 Development App
        location /dev/ {
            set $backend_dev "http://spoke2.corp.internal:80";
            proxy_pass $backend_dev/;
            proxy_http_version 1.1;
            proxy_set_header Connection "";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto https;
        }
    }
}
NGINX_EOF

systemctl daemon-reload
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
