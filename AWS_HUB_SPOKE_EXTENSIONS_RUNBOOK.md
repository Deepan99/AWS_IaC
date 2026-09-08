# 🚀 AWS Zero-Cost Hub-and-Spoke Enterprise Network Runbook

## 📌 Architecture Overview & Resource Inventory

**Region**: `ap-south-1` (Mumbai)  
**AWS Account ID**: `456508992151`  
**IAM User**: `network-admin`  

```text
                                       ┌────────────────────────────────────────────────────────┐
                                       │    🌐 Route 53 Private Hosted Zone: "corp.internal"    │
                                       │       • spoke1.corp.internal ➔ 10.1.1.124              │
                                       │       • hub.corp.internal    ➔ 10.0.1.11               │
                                       │       • proxy.corp.internal  ➔ 10.0.1.11               │
                                       └───────────────┬──────────────────────┬─────────────────┘
                                                       │                      │
                                          Associated   │                      │ Associated
                                                       ▼                      ▼
┌──────────────────────────────────────────────────────────┐      ┌──────────────────────────────────────────────────────────┐
│ Hub VPC (10.0.0.0/16) - vpc-01b4ac4e0a26e39d8            │      │ Spoke 1 Prod VPC (10.1.0.0/16) - vpc-02edc6d0e8625e9e0   │
│                                                          │      │                                                          │
│  [🏢 Hub-Central-NAT-Router]                             │      │  [🔒 Spoke1-Prod-App]                                   │
│     • Instance ID: i-0264974f1480d2907 (t3.micro)        │      │     • Instance ID: i-0992e7365571592d5 (t3.micro)        │
│     • Public IP: 13.234.204.131                          │      │     • Private IP: 10.1.1.124 (Strictly Private)          │
│     • Private IP: 10.0.1.11                              │      │     • Subnet: Spoke1-Private-Subnet-1 (10.1.1.0/24)      │
│     • Subnet: Hub-Public-Subnet-1 (10.0.1.0/24)          │      │     • Security Group: Spoke1-Prod-SG (sg-06bc46255c30f55ad│
│     • Security Group: Hub-NAT-Router-SG                  │      │     • App: Python Web App (Port 80)                      │
│     • Ingress Proxy: NGINX (Port 80)                     │      └────────────────────────────▲─────────────────────────────┘
│     • Egress Firewall: Squid (Port 3128)                 │                                   │
└────────────────────────────┬─────────────────────────────┘                                   │
                             │                                                                 │
                             └─────────────────────── VPC Peering Link ────────────────────────┘
                                                 (pcx-0c864c3fa7bb0c3a5)
                                                    Latency: ~0.16 ms
```

---

## 🗂️ Resource Inventory Table

| Component | Resource ID / Name | CIDR / Subnet | IP Address | Details |
| :--- | :--- | :--- | :--- | :--- |
| **Hub VPC** | `vpc-01b4ac4e0a26e39d8` | `10.0.0.0/16` | - | Central Management & Routing Hub |
| **Hub Public Subnet** | `subnet-07eb7fd49e511809c` | `10.0.1.0/24` | - | Public subnet with IGW route |
| **Hub Router EC2** | `i-0264974f1480d2907` | - | `13.234.204.131` / `10.0.1.11` | Ingress Proxy, NAT Router, Egress Firewall |
| **Spoke 1 Prod VPC** | `vpc-02edc6d0e8625e9e0` | `10.1.0.0/16` | - | Production Workloads |
| **Spoke 1 Private Subnet**| `subnet-02592c9554671325f` | `10.1.1.0/24` | - | Isolated private subnet |
| **Spoke 1 App EC2** | `i-0992e7365571592d5` | - | `10.1.1.124` | Private Production Web App |
| **Spoke 2 Dev VPC** | `vpc-0d373a2cbb27acc03` | `10.2.0.0/16` | - | Development Workloads |
| **VPC Peering (Hub ➔ Spoke 1)** | `pcx-0c864c3fa7bb0c3a5` | - | - | Active Peering Connection |
| **VPC Peering (Hub ➔ Spoke 2)** | `pcx-0b9e92b8432dcdc2c` | - | - | Active Peering Connection |
| **Private Hosted Zone** | `Z0700500SU18U0NWJYH0` | `corp.internal` | - | Route 53 Multi-VPC Association |

---

## 🛠️ Completed Extensions Summary

### 🚀 Extension 1: Central NGINX Ingress Reverse Proxy (Zero-Cost ALB)
- **Problem**: AWS Application Load Balancer (ALB) costs ~$20/month.
- **Solution**: Hub EC2 instance configured with NGINX acting as a high-performance reverse proxy.
- **Traffic Flow**: 
  1. User navigates to `http://13.234.204.131` (or `http://spoke1.corp.internal`).
  2. NGINX receives the request on Port 80.
  3. Securely proxies across **VPC Peering** (`pcx-0c864c3fa7bb0c3a5`) to `10.1.1.124:80`.
- **Key Config** (`/etc/nginx/nginx.conf` on Hub):
  ```nginx
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
  ```

---

### 🛡️ Extension 2: Central Outbound Egress Inspection & Domain Whitelisting (Squid Firewall)
- **Problem**: AWS Network Firewall costs ~$285/month. Private EC2 instances without egress filtering can be hijacked to exfiltrate data or reach attacker C2 servers.
- **Solution**: Squid Forward Proxy deployed on Hub (`10.0.1.11:3128`) with strict domain whitelisting.
- **Domain Whitelist** (`/etc/squid/allowed_domains.txt`):
  - `.amazonlinux.com` (Package updates)
  - `.aws.amazon.com` / `.amazonaws.com`
  - `.github.com` / `.githubusercontent.com`
  - `.pypi.org` / `.pythonhosted.org`
- **Verification**:
  - `curl -I -x http://proxy.corp.internal:3128 https://github.com` ➔ `HTTP 200 OK` (Allowed)
  - `curl -I -x http://proxy.corp.internal:3128 http://example.com` ➔ `HTTP 403 Forbidden` (Blocked by Firewall)

---

### 🌐 Extension 3: Centralized Multi-VPC Private DNS (Amazon Route 53)
- **Problem**: Hardcoding private IP addresses (`10.1.1.124`) breaks easily when instances are replaced.
- **Solution**: Amazon Route 53 Private Hosted Zone `corp.internal` associated across Hub, Spoke 1, and Spoke 2 VPCs.
- **Records**:
  - `spoke1.corp.internal` ➔ `10.1.1.160`
  - `spoke2.corp.internal` ➔ `10.2.1.x`
  - `hub.corp.internal` ➔ `10.0.1.52`
  - `proxy.corp.internal` ➔ `10.0.1.52`
- **Service Discovery**: Hub NGINX and Spoke workloads dynamically resolve internal hostnames with sub-millisecond response.

---

### 📊 Extension 4: Centralized VPC Flow Logs & Security Telemetry (CloudWatch Logs)
- **Problem**: In an enterprise multi-VPC architecture, lack of network packet visibility prevents incident response and threat detection.
- **Solution**: Centralized CloudWatch Log Group `/aws/vpc/hub-spoke-flowlogs` (7-day cost-optimized retention) capturing network flows across Hub, Spoke 1 Prod, and Spoke 2 Dev VPCs.
- **Role**: `VPCFlowLogsDeliveryRole` delivering packet-level ACCEPT/REJECT telemetry.

---

### 🚦 Extension 6: Layer-7 Multi-Environment Ingress Routing & Gateway Portal
- **Problem**: Multiple internal spoke environments (Prod vs Dev) need public access without creating multiple internet gateways, public IPs, or paying for multiple ALBs.
- **Solution**: Hub NGINX Reverse Proxy performs path-based Layer-7 routing with zero lateral movement between environments:
  - `http://<Hub-IP>/` ➔ Central Service Gateway Portal
  - `http://<Hub-IP>/prod/` ➔ Proxied to Spoke 1 Prod App (`spoke1.corp.internal:80`)
  - `http://<Hub-IP>/dev/` ➔ Proxied to Spoke 2 Dev App (`spoke2.corp.internal:80`)
- **Security Rule**: Spoke 1 (Prod) and Spoke 2 (Dev) remain completely air-gapped from each other.

---

### 🔒 Extension 7: Zero-Trust Management with AWS Systems Manager (SSM) & Port 22 Lockdown
- **Problem**: Inbound Port 22 (SSH) open to the internet (`0.0.0.0/0`) is the #1 attack vector for automated brute-force attacks and requires risky `.pem` private key management.
- **Solution**:
  1. EC2 instances managed via AWS Systems Manager (`EC2-SSM-Managed-Role` with `AmazonSSMManagedInstanceCore`).
  2. **100% Inbound Port 22 (SSH) Revoked** across Hub, Spoke 1, and Spoke 2 Security Groups.
  3. Hub Security Group allows only HTTP (80), HTTPS (443), and Squid (3128).
  4. Spoke Security Groups allow only HTTP (80) and ICMP strictly from the Hub VPC (`10.0.0.0/16`).
  5. Administrators connect via 1-click browser shell terminal in EC2 Console with full IAM governance and zero open management ports.

---

### ⚡ Extension 8: High Availability (HA) Backend & Load Balancing with Auto-Failover
- **Problem**: Single point of failure (SPOF) in Spoke 1 Prod — if instance `10.1.1.160` fails or reboots, production is offline ($0 ALB alternative needed).
- **Solution**:
  1. Dual redundant backend instances deployed in Spoke 1 Prod:
     - **Node A**: `10.1.1.160` (`node1.prod.corp.internal`)
     - **Node B**: `10.1.1.188` (`node2.prod.corp.internal`)
  2. Hub NGINX Upstream Cluster (`spoke1_prod_cluster`) configured for **Active-Active Round Robin** load balancing.
  3. **Auto-Failover with Zero Downtime**: Passive health checks (`max_fails=2 fail_timeout=5s`). If Node A is offline, NGINX instantly routes 100% of `/prod/` traffic to Node B with 0 dropped requests.

---

## 🧪 Verification & Health Check Commands

### 1. Web Endpoints & HA Round Robin Check:
```bash
# Querying /prod/ repeatedly alternates between Node A and Node B:
curl -s http://13.207.69.181/prod/ | grep "Node"
curl -I http://13.207.69.181/       # ➔ HTTP 200 OK (Gateway Portal)
curl -I http://13.207.69.181/dev/   # ➔ HTTP 200 OK (Spoke 2 Dev App)
```

### 2. Zero-Trust SSH Lockdown Check:
```powershell
# This command should immediately TIMEOUT or REJECT because Port 22 is completely closed:
ssh -i "<key>.pem" ec2-user@13.207.69.181
```

### 3. Systems Manager (SSM) 1-Click Access:
👉 Go to **EC2 Console** ➔ Select any instance ➔ Click **Connect** ➔ **Session Manager** ➔ **Connect**.

---

## 🚨 Disaster Recovery Procedures

### Hub Router Failure Recovery

If the Hub Router instance (`i-0264974f1480d2907`) becomes unresponsive:

1. **Check Instance Status**:
   ```bash
   aws ec2 describe-instance-status --instance-ids i-0264974f1480d2907 --region ap-south-1
   ```

2. **Reboot Instance** (if responsive):
   ```bash
   aws ec2 reboot-instances --instance-ids i-0264974f1480d2907 --region ap-south-1
   ```

3. **Terminate and Replace** (if unresponsive):
   ```bash
   # Terminate failed instance
   aws ec2 terminate-instances --instance-ids i-0264974f1480d2907 --region ap-south-1

   # Launch new instance using Terraform or CloudFormation
   cd terraform
   terraform apply -replace=aws_instance.hub_router
   ```

4. **Update Route 53 DNS Records** (if IP changes):
   - New instance will automatically update Route 53 records via Terraform/CloudFormation
   - Verify: `nslookup spoke1.corp.internal`

### Spoke Instance Failure Recovery

If Spoke 1 App instance (`i-0992e7365571592d5`) fails:

1. **Replace via Terraform**:
   ```bash
   cd terraform
   terraform apply -replace=aws_instance.spoke1_app
   ```

2. **Verify Connectivity**:
   ```bash
   # From Hub
   ssh 10.1.1.124
   curl http://localhost:80
   ```

### VPC Peering Connection Recovery

If VPC peering becomes inactive:

1. **Check Peering Status**:
   ```bash
   aws ec2 describe-vpc-peering-connections --vpc-peering-connection-ids pcx-0c864c3fa7bb0c3a5 --region ap-south-1
   ```

2. **Re-establish Peering** (if deleted):
   ```bash
   cd terraform
   terraform apply -replace=aws_vpc_peering_connection.hub_to_spoke1
   ```

### Complete Infrastructure Recovery

To recover entire infrastructure from scratch:

1. **Using Terraform**:
   ```bash
   cd terraform
   terraform init
   terraform apply -auto-approve
   ```

2. **Using CloudFormation**:
   ```bash
   aws cloudformation create-stack \
     --stack-name aws-hub-spoke-network \
     --template-body file://cloudformation_stack.yaml \
     --parameters ParameterKey=KeyName,ParameterValue=hub-vpc-key \
     --capabilities CAPABILITY_IAM \
     --region ap-south-1
   ```

### Backup Recommendations

- **Document critical resource IDs** (VPC IDs, Instance IDs, Peering IDs)
- **Save Terraform state** securely (S3 + DynamoDB for remote state)
- **Regular snapshots** of EC2 instances (manual AMI creation before major changes)
- **Export CloudFormation stack** as backup template
