# Security Best Practices for AWS Hub-and-Spoke Network

This document outlines security best practices for the zero-cost hub-and-spoke network architecture.

---

## Security Group Recommendations

### Current Configuration

**Hub Security Group (Hub-NAT-Router-SG)**:
- SSH (22): Open to 0.0.0.0/0
- HTTP (80): Open to 0.0.0.0/0
- HTTPS (443): Open to 0.0.0.0/0
- Squid Proxy (3128): Open to 10.0.0.0/8

**Spoke 1 Security Group (Spoke1-Prod-SG)**:
- All traffic: Allowed from Hub VPC (10.0.0.0/16)

### Recommended Improvements

#### 1. Restrict SSH Access

**Current Risk**: SSH open to entire internet (0.0.0.0/0)

**Recommended Actions**:
- **Option A**: Restrict to your specific IP address
  ```bash
  # Replace with your public IP
  cidr_blocks = ["YOUR_PUBLIC_IP/32"]
  ```

- **Option B**: Use AWS Systems Manager Session Manager (no SSH keys needed)
  - No public SSH access required
  - Audit logging built-in
  - No open ports needed

- **Option C**: Use AWS bastion host with VPN
  - Deploy bastion in separate management VPC
  - Connect via VPN or AWS Client VPN

#### 2. Add HTTPS/TLS Termination

**Current Risk**: HTTP traffic is unencrypted

**Recommended Actions**:
- Add TLS certificate via AWS Certificate Manager (ACM) - FREE
- Configure NGINX with SSL/TLS
- Redirect HTTP to HTTPS
- Use Let's Encrypt or ACM for certificates

#### 3. Implement Squid Proxy Authentication

**Current Risk**: No authentication on egress proxy

**Recommended Actions**:
- Add basic authentication to Squid configuration
- Use IP-based restrictions for proxy access
- Implement proxy authentication with local users or LDAP

#### 4. Network ACLs (NACLs) as Additional Layer

**Current Risk**: Only security groups provide network filtering

**Recommended Actions**:
- Add NACLs at subnet level for stateless filtering
- Block known malicious IPs at NACL level
- Implement deny-all default with explicit allow rules

#### 5. Enable VPC Flow Logs

**Current Risk**: No visibility into network traffic patterns

**Recommended Actions**:
- Enable VPC Flow Logs to CloudWatch Logs
- Set up CloudWatch Insights queries for security analysis
- Create alarms for suspicious traffic patterns
- Note: Flow Logs incur minimal cost (~$0.50 per GB)

#### 6. Implement IP Whitelisting for Ingress

**Current Risk**: Anyone can access the public endpoint

**Recommended Actions**:
- Restrict HTTP/HTTPS to known IP ranges
- Use AWS WAF (Web Application Firewall) for additional protection
- Implement rate limiting on NGINX

#### 7. Regular Security Audits

**Recommended Actions**:
- Review security group rules monthly
- Remove unused rules
- Audit IAM permissions regularly
- Enable AWS Config for compliance monitoring
- Use AWS Trusted Advisor for security recommendations

---

## IAM Security Best Practices

### Current Configuration

**Network Administrator Policy**:
- Full access to EC2 networking resources
- Full access to Route 53
- Full access to ELB, Direct Connect, Network Firewall
- Limited read access to other services

### Recommended Improvements

#### 1. Implement MFA (Multi-Factor Authentication)

**Status**: Already documented in CONSOLE_MANUAL_GUIDE.md

**Action**: Ensure all IAM users have MFA enabled

#### 2. Use IAM Roles Instead of Long-Term Credentials

**Recommended Actions**:
- Create IAM roles for EC2 instances
- Use instance profiles for applications
- Rotate access keys regularly (if using access keys)

#### 3. Implement Least Privilege

**Current**: Broad permissions for network admin

**Recommended Actions**:
- Break down policy into smaller, scoped policies
- Create separate roles for different operational tasks
- Use condition-based permissions where possible

#### 4. Enable AWS CloudTrail

**Recommended Actions**:
- Enable CloudTrail for all regions
- Log to S3 bucket with encryption
- Set up CloudTrail alarms for suspicious API calls
- Note: CloudTrail management events are FREE

---

## Infrastructure Security

### 1. Enable Encryption at Rest

**Recommended Actions**:
- Use encrypted EBS volumes for EC2 instances
- Enable S3 bucket encryption for any S3 resources
- Use KMS (Key Management Service) for key management

### 2. Enable Encryption in Transit

**Recommended Actions**:
- Use TLS/SSL for all communications
- Implement certificate pinning for internal services
- Use VPN for administrative access

### 3. Patch Management

**Recommended Actions**:
- Regularly update EC2 instances with security patches
- Use AWS Systems Manager Patch Manager
- Automate patching during maintenance windows

### 4. Network Segmentation

**Current**: Hub and Spoke VPCs with peering

**Recommended Actions**:
- Consider separate VPCs for different security levels
- Implement strict routing between security zones
- Use separate subnets for different tiers (web, app, data)

---

## Monitoring and Alerting

### 1. CloudWatch Alarms

**Recommended Alarms**:
- CPU utilization > 80% for 5 minutes
- Status check failures for EC2 instances
- VPC peering connection failures
- Unusual network traffic patterns

### 2. Security Hub Integration

**Recommended Actions**:
- Enable AWS Security Hub (FREE tier available)
- Aggregate security findings from multiple services
- Implement automated security checks

### 3. GuardDuty (Optional - Paid)

**Note**: GuardDuty incurs cost (~$4.50 per million events)

**Benefits**:
- Threat detection for EC2, S3, IAM
- Machine learning-based anomaly detection
- Integration with Security Hub

---

## Cost vs Security Trade-offs

| Security Measure | Cost | Priority | Impact |
| :--- | :--- | :--- | :--- |
| Restrict SSH to specific IP | FREE | High | Reduces attack surface significantly |
| Enable MFA | FREE | High | Prevents credential theft attacks |
| Enable CloudTrail | FREE | High | Audit trail for compliance |
| VPC Flow Logs | ~$0.50/GB | Medium | Network visibility and forensics |
| TLS/SSL Certificates | FREE (ACM) | High | Encrypts data in transit |
| AWS WAF | Paid (~$5/mo + usage) | Low | Additional application protection |
| GuardDuty | Paid (~$4.50M events) | Low | Advanced threat detection |

---

## Quick Security Checklist

- [ ] SSH access restricted to specific IP or using Session Manager
- [ ] MFA enabled for all IAM users
- [ ] CloudTrail enabled across all regions
- [ ] VPC Flow Logs enabled for critical VPCs
- [ ] Security groups reviewed and unused rules removed
- [ ] TLS/SSL implemented for all HTTP endpoints
- [ ] Regular patch management schedule established
- [ ] CloudWatch alarms configured for critical resources
- [ ] IAM policies follow least privilege principle
- [ ] Backup and disaster recovery procedures documented
- [ ] Incident response plan created and tested
