## 📋 Pull Request Description

### 🎯 Type of Change
- [ ] 🚀 **New Feature / Extension** (New network component or security appliance)
- [ ] 🐛 **Bug Fix** (Routing, SG rule, or configuration fix)
- [ ] 🛡️ **Security Hardening** (Policy, firewall, or IAM least-privilege adjustment)
- [ ] 🧹 **Refactoring / Cleanup** (IaC modularization or formatting)
- [ ] 📝 **Documentation** (Runbook, architecture diagram, or guide update)

---

## 🏗️ Summary of Changes
- *Briefly describe what infrastructure components were modified or added.*
- *Reference related issue / milestone if applicable.*

---

## 🧪 Verification & Testing Checklist
- [ ] `terraform fmt -check` passes with zero formatting diffs.
- [ ] `terraform validate` confirms syntax and reference validity.
- [ ] `tfsec` / security scan shows zero high/critical vulnerabilities.
- [ ] `terraform plan` output reviewed and verified against S3 remote backend.
- [ ] Tested cross-VPC connectivity / DNS resolution in staging/dev.

---

## 💰 Cost & Resource Impact Assessment
- [ ] Estimated AWS monthly cost delta: **$0.00** (Zero-Cost / Free-Tier verified).
- [ ] No unmanaged or idle resources introduced (e.g. idle Elastic IPs, NAT Gateways).

---

## 🔄 Rollback Strategy
- *Explain how to revert this change if unexpected drift or outage occurs.*
