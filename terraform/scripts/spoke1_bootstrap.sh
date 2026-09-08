#!/bin/bash
set -e

mkdir -p /var/www/app
cat << 'HTML_EOF' > /var/www/app/index.html
<!DOCTYPE html>
<html>
<head>
  <title>Spoke 1 Production Server</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #0f172a; color: #f8fafc; text-align: center; padding: 50px 20px; }
    .card { background: #1e293b; border-radius: 12px; padding: 40px; max-width: 650px; margin: 0 auto; box-shadow: 0 10px 25px -5px rgba(0,0,0,0.5); border: 1px solid #334155; }
    h1 { color: #38bdf8; font-size: 28px; margin-bottom: 10px; }
    .badge { display: inline-block; background: #0284c7; color: white; padding: 6px 14px; border-radius: 9999px; font-weight: 600; font-size: 14px; margin-bottom: 20px; }
    p { font-size: 16px; line-height: 1.6; color: #94a3b8; }
    .info-box { background: #0f172a; border-radius: 8px; padding: 15px; margin: 25px 0 10px 0; text-align: left; font-family: monospace; font-size: 14px; border: 1px solid #334155; color: #a5f3fc; }
  </style>
</head>
<body>
  <div class="card">
    <div class="badge">🚀 AWS Zero-Cost Architecture</div>
    <h1>🎉 Hello from Private Spoke 1!</h1>
    <p>This production workload is <strong>100% private</strong> with NO Public IP, NO direct Internet Gateway, and zero hourly ALB charges.</p>
    <div class="info-box">
      • <strong>Hostname:</strong> spoke1.corp.internal<br>
      • <strong>Server:</strong> Spoke1-Prod-App (Private Subnet)<br>
      • <strong>Ingress Proxy:</strong> Hub NGINX Ingress (hub.corp.internal)<br>
      • <strong>Egress Firewall:</strong> Squid Proxy (proxy.corp.internal:3128)<br>
      • <strong>Inter-VPC Link:</strong> AWS VPC Peering (0.16ms latency)
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
Type=simple
WorkingDirectory=/var/www/app
ExecStart=/usr/bin/python3 -m http.server 80
Restart=always
User=root

[Install]
WantedBy=multi-user.target
SVC_EOF

systemctl daemon-reload
systemctl enable --now spoke-app
