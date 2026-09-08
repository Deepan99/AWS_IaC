# AWS Zero-Cost Hub-and-Spoke Enterprise Network

A production-ready Infrastructure as Code (IaC) project for deploying a zero-cost hub-and-spoke network architecture on AWS. This project replaces expensive AWS services (ALB, NAT Gateway, Network Firewall, Transit Gateway) with open-source alternatives (NGINX, Squid, VPC Peering).

---

## 🏗️ Architecture Overview

```
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
│     • NGINX Ingress Proxy (Port 80)                      │      │     • Private IP: 10.1.1.124 (Strictly Private)          │
│     • Squid Egress Firewall (Port 3128)                  │      │     • Python Web App (Port 80)                          │
│     • Public IP: Auto-assigned                           │      └────────────────────────────▲─────────────────────────────┘
└────────────────────────────┬─────────────────────────────┘                                   │
                             │                                                                 │
                             └─────────────────────── VPC Peering Link ────────────────────────┘
```

### Key Features

- **Zero-Cost Alternatives**: Replaces ~$370/month AWS services with open-source solutions
- **Central Ingress Proxy**: NGINX reverse proxy for load balancing (replaces ALB)
- **Egress Firewall**: Squid proxy with domain whitelisting (replaces Network Firewall)
- **Private DNS**: Route 53 Private Hosted Zone for service discovery
- **VPC Peering**: Direct VPC-to-VPC connectivity (replaces Transit Gateway)
- **Dual IaC Support**: Both CloudFormation and Terraform implementations

---

## 📁 Project Structure

```text
.
├── .github/
│   └── workflows/
│       └── terraform-deploy.yml    # GitHub Actions CI/CD workflow
├── terraform/
│   ├── scripts/
│   │   ├── hub_bootstrap.sh        # Hub instance bootstrap script
│   │   └── spoke1_bootstrap.sh     # Spoke 1 instance bootstrap script
│   ├── backend.tf.example          # Remote state configuration example
│   ├── compute_hub.tf              # Hub EC2 instance
│   ├── compute_spokes.tf           # Spoke EC2 instances
│   ├── outputs.tf                  # Output variables
│   ├── route53.tf                  # Route 53 Private Hosted Zone
│   ├── security_groups.tf          # Security groups
│   ├── terraform.tfvars            # Environment variables
│   ├── variables.tf                # Input variable declarations
│   ├── versions.tf                 # Terraform version constraints
│   ├── vpc_hub.tf                  # Hub VPC configuration
│   ├── vpc_peering.tf              # VPC peering connections
│   └── vpc_spokes.tf               # Spoke VPCs configuration
├── AWS_HUB_SPOKE_EXTENSIONS_RUNBOOK.md   # Architecture & operations guide
├── CONSOLE_MANUAL_GUIDE.md               # Manual IAM setup guide
├── SECURITY_BEST_PRACTICES.md            # Security recommendations
├── cloudformation_stack.yaml             # CloudFormation template
├── iam-network-admin-policy.json         # IAM policy for network admin
└── terraform_main.tf                     # Single-file Terraform version
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
