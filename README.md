# Enterprise AWS Infrastructure as Code (IaC) & DevSecOps Portfolio

![DevSecOps IaC and Container Security Audit](https://github.com/shafimuhammad5255-hue/terraform-aws-portfolio/actions/workflows/devsecops.yml/badge.svg)

Production-grade, modular AWS infrastructure built with **Terraform**, enforcing strict **Shift-Left Security** principles. Every module is hardened against industry benchmarks (CIS AWS Foundations, OWASP Top 10) and validated through automated multi-stage CI/CD security pipelines.

---

## 🛡️ Security & Compliance Architecture

| Layer | Tools / Technologies | Enforced Security Controls |
| :--- | :--- | :--- |
| **Static Analysis (IaC)** | Checkov, TFLint | 0 Failed Checks benchmark, automated policy-as-code enforcement. |
| **Secret Detection** | Gitleaks, TruffleHog | Pre-commit and CI blocking of hardcoded credentials/tokens. |
| **Container Security** | Trivy, Docker | Non-root runtime, minimal base images, continuous CVE vulnerability scans. |
| **Code Analysis (SAST)**| Bandit | Python AST security linting for automation & Lambda functions. |
| **Authentication** | GitHub Actions OIDC | Keyless AWS authentication eliminating long-lived IAM access keys. |

---

## 📂 Architecture & Hardened Modules

| Module Directory | Core Security Implementations |
| :--- | :--- |
| **`1-ec2-basics`** | Custom VPC segmentation, IMDSv2 mandatory tokens, default security group egress lockdown. |
| **`2-s3-dynamodb-remote-backend`** | Secure state locking, S3 bucket public access block, versioning, SSE-KMS encryption. |
| **`3-custom-modules`** | Reusable, isolated EC2 modules adhering to least-privilege networking. |
| **`4-registry-vpc`** | Multi-tier network architecture (Public/Private/Database subnets) with VPC Flow Logs. |
| **`5-Workspace-demo`** | Multi-environment isolation (Dev/Staging/Prod) using Terraform Workspaces. |
| **`6-dynamic-blocks-loops`** | Programmatic, repeatable security group rule management minimizing manual configuration drift. |
| **`7-aws-cloudtrail-kms`** | Multi-Region CloudTrail audit logging encrypted with Customer Managed Keys (CMK) and Log Validation. |
| **`8-container-security`** | Hardened container runtime, unprivileged user execution, read-only root filesystems. |
| **`9-github-OIDC-iam`** | OpenID Connect federated IAM roles restricted via GitHub repository claim conditions. |
| **`10-kubernetes-security-hardening`**| K8s Pod Security Standards, restrictive RBAC policies, and granular NetworkPolicies. |
| **`11-GuardDuty-threat-detection`**| Intelligent continuous threat detection for VPC Flow Logs, DNS logs, and S3 Data Events. |
| **`12-ecr-image-scanning`** | Continuous vulnerability image scanning on push with KMS-encrypted image repositories. |
| **`13-aws-waf-alb-security`** | WAFv2 WebACL with AWS Managed Rules (OWASP Top 10, Bad Inputs) and Anti-DDoS Rate Limiting. |
| **`14-secrets-manager-rotation`** | Automated secret rotation via KMS-encrypted AWS Secrets Manager and scoped Lambda functions. |
| **`15-automated-incident-response`**| Automated incident remediation using AWS EventBridge and Python Lambda functions. |

---

## 🔄 DevSecOps Pipeline Flow

```text
Local Development
  │
  ├── [Pre-commit Hooks] ── (Gitleaks, TFLint, Terraform fmt)
  │
Git Push to Main
  │
  └── [GitHub Actions CI/CD]
        ├── Checkov IaC Security Audit
        ├── Trivy Container Scan
        ├── Bandit SAST Scan
        └── Gitleaks Secrets Audit
        
```



## 🚀 Local Setup & Verification

1. **Clone the repository:**
  ```bash
  git clone https://github.com/shafimuhammad5255-hue/terraform-aws-portfolio.git
  cd terraform-aws-portfolio
  ```
2. Initialize Pre-commit Hooks:

  ```bash
  pip install pre-commit checkov
  pre-commit install
  ```
3. Run Pre-commit Manually:

  ```bash
  pre-commit run --all-files
  ```
---