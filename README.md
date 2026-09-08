# AWS Zero-Cost Hub-and-Spoke Enterprise Network

A production-ready, highly available Infrastructure as Code (IaC) project deploying an enterprise **Zero-Cost Hub-and-Spoke Network Architecture** on AWS. This architecture replaces **~$380+/month ($4,552/year)** in paid AWS services (Application Load Balancer, NAT Gateway, AWS Network Firewall, and Transit Gateway) using hardened open-source solutions (NGINX, Squid, Linux iptables, VPC Peering, Route 53, and AWS Systems Manager).

---

## 🏗️ Architecture Overview

```text
                                       ┌────────────────────────────────────────────────────────┐
                                       │    🌐 Route 53 Private Hosted Zone: "corp.internal"    │
                                       │       • node1.prod.corp.internal ➔ 10.1.1.160 (Node A) │
                                       │       • node2.prod.corp.internal ➔ 10.1.1.188 (Node B) │
                                       │       • spoke2.corp.internal     ➔ 10.2.1.164 (Dev)    │
                                       │       • hub.corp.internal        ➔ 10.0.1.52 (Hub)     │
                                       │       • proxy.corp.internal      ➔ 10.0.1.52 (Squid)   │
                                       └───────────────┬──────────────────────┬─────────────────┘
                                                       │                      │
                                          Associated   │                      │ Associated
                                                       ▼                      ▼
┌──────────────────────────────────────────────────────────┐      ┌──────────────────────────────────────────────────────────┐
│ Hub VPC (10.0.0.0/16)                                    │      │ Spoke 1 Prod VPC (10.1.0.0/16) - Air-Gapped Workload     │
│                                                          │      │                                                          │
│  [🏢 Central Hub Router & Ingress Load Balancer]         │      │  [🔒 Spoke1-Prod-App-A]       [🔒 Spoke1-Prod-App-B]     │
│     • Public IP: 13.207.69.181                           │      │     • IP: 10.1.1.160             • IP: 10.1.1.188        │
│     • Private IP: 10.0.1.52                              │      │     • Role: HA Node A            • Role: HA Node B       │
│     • L7 Ingress Gateway Portal (Port 80)                │      │     • High Availability Round-Robin Load Balanced        │
│     • Squid Domain Egress Firewall (Port 3128)           │      │     • Passive Health Check & Auto-Failover (< 5s)        │
│     • Zero-Trust SSM Management (0 Open SSH Ports)       │      └────────────────────────────▲─────────────────────────────┘
└────────────────────────────┬─────────────────────────────┘                                   │
                             │                                                                 │
                             ├─────────────────────── VPC Peering Link ────────────────────────┘
                             │                           (Latency: < 0.20 ms)
                             │
                             ▼
┌──────────────────────────────────────────────────────────┐
│ Spoke 2 Dev VPC (10.2.0.0/16) - Air-Gapped Sandbox       │
│                                                          │
│  [🧪 Spoke2-Dev-App]                                     │
│     • Private IP: 10.2.1.164                             │
│     • Ingress: Meditated exclusively via Hub /dev/ route │
│     • Lateral Movement to Prod (10.1.0.0/16): BLOCKED 🚫 │
└──────────────────────────────────────────────────────────┘
```

### 🌟 Enterprise Milestones & Completed Extensions

1. **Central Ingress Proxy ($0 ALB Alternative)**: Hub NGINX reverse proxy with dynamic runtime AWS resolver.
2. **Central Egress Firewall ($0 AWS Network Firewall Alternative)**: Squid forward proxy on Port 3128 with domain whitelist (`.amazonlinux.com`, `.github.com`, `.pypi.org`).
3. **Multi-VPC Service Discovery**: Route 53 Private Hosted Zone `corp.internal` associated across Hub, Spoke 1, and Spoke 2.
4. **Centralized VPC Flow Logs & Telemetry**: CloudWatch Log Group `/aws/vpc/hub-spoke-flow-logs` capturing packet flows with `VPCFlowLogsDeliveryRole`.
5. **Multi-Environment Layer-7 Ingress Routing**: Path-based gateway (`/` Gateway Portal, `/prod/` Production App, `/dev/` Development App).
6. **Zero-Trust Management**: AWS Systems Manager (SSM) Session Manager browser terminal; **100% Inbound Port 22 (SSH) revoked** across all Security Groups.
7. **High Availability (HA) Backend & Auto-Failover**: Dual redundant backend nodes in Spoke 1 with NGINX active-active round-robin and auto-failover.
8. **Automated Threat Detection Alarms**: CloudWatch Alarms monitoring suspicious `REJECT` packet volume across VPC perimeters.
9. **Curated Threat Hunting Suite**: Pre-built CloudWatch Logs Insights queries for top rejected IPs and cross-VPC lateral movement detection.
10. **Enterprise GitOps CI/CD**: Fully automated GitHub Actions workflow with S3 remote state locking, DynamoDB, Dependabot, and drift detection.

---

## 📁 Project Structure

```text
.
├── .github/
│   ├── workflows/
│   │   ├── terraform-deploy.yml    # GitOps CI/CD pipeline (speculative plan + apply on merge)
│   │   └── drift-detection.yml     # Daily cloud configuration drift scanner
│   ├── CODEOWNERS                  # Repository code ownership policy
│   ├── PULL_REQUEST_TEMPLATE.md    # Enterprise PR review template
│   └── dependabot.yml              # Automated security dependency scanner
├── terraform/
│   ├── scripts/
│   │   ├── hub_bootstrap.sh        # Hub NGINX HA Load Balancer & Squid bootstrap
│   │   └── spoke1_bootstrap.sh     # Spoke 1 Python App & systemd bootstrap
│   ├── backend.tf                  # Remote S3 state storage & DynamoDB lock table
│   ├── compute_hub.tf              # Hub NAT Router & Ingress Gateway EC2
│   ├── compute_spokes.tf           # Spoke 1 HA Cluster (Node A + B) & Spoke 2 Dev EC2
│   ├── outputs.tf                  # Output variables
│   ├── route53.tf                  # Route 53 Private Hosted Zone & A-records
│   ├── security_groups.tf          # Least-privilege Zero-Trust security groups
│   ├── terraform.tfvars            # Environment variables
│   ├── variables.tf                # Input variable declarations
│   ├── versions.tf                 # Terraform version constraints
│   ├── vpc_hub.tf                  # Hub VPC configuration
│   ├── vpc_peering.tf              # VPC peering connections
│   └── vpc_spokes.tf               # Spoke VPCs configuration
├── AWS_HUB_SPOKE_EXTENSIONS_RUNBOOK.md   # Complete technical runbook & DR procedures
├── CONSOLE_MANUAL_GUIDE.md               # Manual AWS Console guide
├── SECURITY_BEST_PRACTICES.md            # Zero-Trust security baseline
├── cloudformation_stack.yaml             # CloudFormation template equivalent
└── iam-network-admin-policy.json         # Least-privilege IAM policy
```

---

## 🚀 Quick Start

### Prerequisites

- AWS Account with appropriate permissions
- Terraform >= 1.5.0 installed locally
- EC2 Key Pair created in AWS

### Local Deployment

```bash
# 1. Clone the repository
git clone https://github.com/Deepan99/AWS_IaC.git
cd AWS_IaC

# 2. Configure AWS credentials
aws configure

# 3. Update terraform.tfvars with your key pair name
# Edit terraform/terraform.tfvars and set key_name

# 4. Initialize Terraform
cd terraform
terraform init

# 5. Review the plan
terraform plan

# 6. Apply the configuration
terraform apply -auto-approve

# 7. Get the outputs
terraform output
```

---

## 🔄 CI/CD with GitHub Actions

This project uses GitHub Actions for automated Terraform deployment. The workflow runs `terraform plan` on PRs and `terraform apply` when PRs are merged.

### Setup Instructions

#### 1. Configure GitHub Secrets

Navigate to your repository settings: `Settings` → `Secrets and variables` → `Actions` → `New repository secret`

Add the following secrets:

| Secret Name | Description | Example |
| :--- | :--- | :--- |
| `AWS_ACCESS_KEY_ID` | AWS access key for deployment | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key for deployment | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |
| `AWS_REGION` | AWS region for deployment | `ap-south-1` |

#### 2. Create AWS IAM User for CI/CD

Create an IAM user with programmatic access and attach the following policy (or use the network-admin policy):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "route53:*",
        "vpc:*"
      ],
      "Resource": "*"
    }
  ]
}
```

#### 3. Deployment Workflow

**For New Changes:**

1. Create a new branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes and commit:
   ```bash
   git add .
   git commit -m "Add your feature"
   ```

3. Push to GitHub:
   ```bash
   git push origin feature/your-feature-name
   ```

4. Create a Pull Request on GitHub

5. **GitHub Actions will automatically run `terraform plan`** and comment the plan on your PR

6. Review the plan output in the PR comments

7. **Merge the PR** to trigger `terraform apply`

**The infrastructure will be deployed automatically after PR merge!**

---

## 📖 Documentation

- **[Architecture Runbook](AWS_HUB_SPOKE_EXTENSIONS_RUNBOOK.md)** - Detailed architecture overview, resource inventory, and health check commands
- **[Console Setup Guide](CONSOLE_MANUAL_GUIDE.md)** - Manual IAM user setup in AWS Console
- **[Security Best Practices](SECURITY_BEST_PRACTICES.md)** - Security recommendations and hardening guide
- **[Disaster Recovery](AWS_HUB_SPOKE_EXTENSIONS_RUNBOOK.md#-disaster-recovery-procedures)** - Recovery procedures for failures

---

## 💰 Cost Breakdown

### Free Resources (No Charge)
- VPC, Subnets, Route Tables
- Internet Gateway
- Security Groups & NACLs
- VPC Peering
- EC2 t3.micro instances (within free tier limits)

### Paid Resources (Minimal Cost)
- **Route 53 Hosted Zone**: ~$0.50/month
- **EC2 Instances**: ~$8-10/month (if outside free tier)
- **Data Transfer**: Standard AWS data transfer rates apply

### Cost Savings vs Traditional Architecture

| Traditional Service | Monthly Cost | Zero-Cost Alternative | Savings |
| :--- | :--- | :--- | :--- |
| Application Load Balancer | ~$20 | NGINX on EC2 | $20/mo |
| NAT Gateway | ~$32 | EC2 with iptables | $32/mo |
| Network Firewall | ~$285 | Squid Proxy | $285/mo |
| Transit Gateway | ~$36 | VPC Peering | $36/mo |
| **Total Savings** | **~$373/mo** | **~$0** | **~$373/mo** |

---

## 🔧 Configuration

### Terraform Variables

Edit `terraform/terraform.tfvars` to customize:

```hcl
aws_region                 = "ap-south-1"
environment                = "production"
key_name                   = "your-ec2-key-pair-name"
instance_type              = "t3.micro"
hub_vpc_cidr               = "10.0.0.0/16"
spoke1_vpc_cidr            = "10.1.0.0/16"
spoke2_vpc_cidr            = "10.2.0.0/16"
private_domain_name        = "corp.internal"
```

### Remote State (Optional)

For team collaboration, configure remote state storage:

1. Copy `terraform/backend.tf.example` to `terraform/backend.tf`
2. Update the bucket and DynamoDB table names
3. Run `terraform init` to migrate state

See `terraform/backend.tf.example` for detailed setup instructions.

---

## 🧪 Testing

After deployment, verify the setup:

```bash
# 1. Check Hub instance
ssh -i <your-key.pem> ec2-user@<hub-public-ip>
sudo systemctl status nginx
sudo systemctl status squid

# 2. Check Spoke 1 app (from Hub)
ssh <spoke1-private-ip>
curl http://localhost:80

# 3. Test DNS resolution
nslookup spoke1.corp.internal
nslookup hub.corp.internal

# 4. Test ingress proxy
curl http://<hub-public-ip>

# 5. Test egress firewall
curl -I -x http://proxy.corp.internal:3128 https://github.com
```

---

## 🗑️ Cleanup

To destroy all resources:

```bash
cd terraform
terraform destroy -auto-approve
```

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a Pull Request
5. CI/CD will run `terraform plan` automatically
6. Merge after approval to deploy

---

## 📄 License

This project is provided as-is for educational and production use.

---

## 🆘 Support

For issues or questions:
- Review the [Architecture Runbook](AWS_HUB_SPOKE_EXTENSIONS_RUNBOOK.md)
- Check [Security Best Practices](SECURITY_BEST_PRACTICES.md)
- Open an issue on GitHub
