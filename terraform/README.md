# 🚀 AWS Zero-Cost Enterprise Hub-and-Spoke Terraform Project

Modular, production-ready Infrastructure as Code (IaC) for AWS Hub-and-Spoke topology with Ingress Load Balancing, Egress Firewall, and Multi-VPC Private DNS.

---

## 📁 Project Structure

```text
terraform/
├── versions.tf            # Terraform & AWS provider requirements + default tags
├── variables.tf           # Input variable declarations
├── terraform.tfvars       # Environment configuration values
├── outputs.tf             # Output variables (Public IP, URLs, DNS endpoints)
├── vpc_hub.tf             # Hub VPC, Public Subnet, IGW & Route Table
├── vpc_spokes.tf          # Spoke 1 (Prod) and Spoke 2 (Dev) VPCs & Private Subnets
├── vpc_peering.tf         # VPC Peering Connections & Cross-VPC Routes
├── security_groups.tf     # Security Groups for Hub Router and Spokes
├── route53.tf             # Route 53 Private Hosted Zone (corp.internal) & A-records
├── compute_hub.tf         # Hub Ingress Proxy / NAT Router / Squid Firewall EC2
├── compute_spokes.tf      # Spoke 1 Private Production App EC2
└── scripts/
    ├── hub_bootstrap.sh   # Automated setup of NGINX, Squid, and iptables
    └── spoke1_bootstrap.sh# Automated setup of Spoke 1 demo web application
```

---

## ⚡ Deployment Instructions

### 1. Initialize Terraform
```bash
terraform init
```

### 2. Validate & Plan
```bash
terraform plan
```

### 3. Apply / Provision Infrastructure
```bash
terraform apply -auto-approve
```

### 4. Destroy / Clean up
```bash
terraform destroy -auto-approve
```
