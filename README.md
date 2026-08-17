#  Enterprise AWS Infrastructure as Code (IaC) & DevSecOps Portfolio

![DevSecOps Security Audit](https://github.com/shafimuhammad5255-hue/terraform-aws-portfolio/actions/workflows/devsecops.yml/badge.svg)

This repository contains production-grade **Terraform** infrastructure modules for AWS, hardened and audited against industry security standards using **Checkov** to achieve a **0 Failed Checks** benchmark.



##  Security & Compliance Status

- **Static Analysis Tool:** [Checkov](https://www.checkov.io/)
- **Total Security Checks:** 200+
- **Failed Checks:** **0** (100% Compliant)
- **Frameworks Covered:** CIS AWS Benchmarks, AWS Foundational Security Best Practices
- **Container Vulnerability Scanner:** Trivy (Aqua Security)
- **Container Hardening:** Alpine-based lightweight base image, non-root user execution, 0 High/Critical CVEs.



##  Key Modules & Architecture

### 1. `1-ec2-basics`
- Provisioned AWS EC2 instances adhering to secure baseline specs.
- Enforced **IMDSv2** (Instance Metadata Service v2) to prevent SSRF credential theft.
- Enabled root volume encryption with AWS KMS.

### 2. `2-s3-dynamodb-remote-backend`
- Secure Terraform Remote State backend using S3 and DynamoDB for state locking.
- Configured Server-Side Encryption (SSE-KMS), Access Logging, and Versioning.

### 3. `3-custom-modules`
- Reusable Terraform modules for modular compute deployment.
- Enforced strict input validation and explicit resource tagging.

### 4. `4-registry-vpc`
- Multi-AZ VPC deployment via official Terraform Registry modules.
- **Supply Chain Security:** Module source pinned to exact **Git Commit Hashes (SHA)** instead of floating tags/versions to guarantee immutability.

### 5. `5-Workspace-demo`
- Multi-environment setup (`dev`, `prod`) using Terraform Workspaces.
- Hardened EC2 instances with **Detailed Monitoring**, **EBS Optimization**, and attached IAM Instance Profiles.

### 6. `6-dynamic-blocks-loops`
- Scalable resource iteration using Terraform `for_each` and dynamic blocks.
- Centralized S3 bucket creation with standalone Public Access Blocks and Logging configurations.

### 7. `7-aws-cloudtrail-kms`
- Enterprise-wide logging and auditing setup via AWS CloudTrail.
- **Custom KMS Key Policies:** Eliminated wildcard principals (`*`) to ensure strict Principle of Least Privilege.
- Integrated CloudTrail logs with **CloudWatch Log Groups** and **SNS Topics** for real-time security alerting.

### 8. `8-container-security` 
- Hardened Flask microservice containerized with multi-stage/alpine security best practices and audited via Trivy.

### 9. `9-github-OIDC-iam`
- **Keyless CI/CD Authentication:** Eliminated long-lived static AWS access keys by integrating OpenID Connect (OIDC) with GitHub Actions.
- **Audited Least Privilege:** Configured IAM trust relationships restricted strictly to the designated repository, branch, and role assumption.

### 10. `10-kubernetes-security-hardening`
- **Pod Security Standards (PSS):** Hardened deployment enforcing non-root users (`UID 10001`), read-only root filesystems, and dropping all standard Linux capabilities (`ALL`).
- **Granular RBAC:** Implemented least-privilege `ServiceAccount`, `Role`, and `RoleBinding` scoped strictly to namespace ConfigMaps.
- **Zero-Trust Microsegmentation:** Enforced `NetworkPolicy` with default-deny ingress/egress, isolating workload traffic exclusively to internal authorized endpoints.

##  DevSecOps & Security Hardening Highlights

Security Control,  Implementation Details 

| **Identity & Access (IAM)** : Removed `*` wildcards from KMS key policies; enforced strict service principals. 

| **Compute (EC2)** : Enforced IMDSv2 (`http_tokens = required`), EBS volume encryption, and attached IAM profiles. 

| **Storage (S3)** : Blocked all public access, enabled versioning, KMS encryption, and access logging across all buckets.

| **Networking (VPC)** : Configured VPC Flow Logs and restricted default Security Group ingress/egress rules. 

| **Supply Chain** : Locked third-party Terraform registry module sources using immutable Git commit SHAs. 

###  DevSecOps Pipeline & Automated Security Gates (Defense-in-Depth)

The CI/CD pipeline enforces automated shift-left security across 4 critical layers:

1. **IaC & Policy Compliance (Checkov):** Audits Terraform modules, GitHub Actions workflow permissions (`permissions: read-all`), and Dockerfile CIS standards.

2. **Container Vulnerability Management (Trivy):** Scans Docker images with strict gatekeeping (`exit-code: 1` on HIGH/CRITICAL CVEs). Remediated 71+ legacy vulnerabilities down to 0 using a hardened Alpine base and multi-stage builds.

3. **Static Application Security Testing - SAST (Bandit):** Automatically analyzes Python/Flask source code for security flaws and unsafe function executions.

4. **Secret Scanning (Gitleaks):** Scans commit history and codebase to prevent accidental leaks of AWS credentials, API keys, or private certificates.


## How to Audit & Run Scans Locally

To verify the security compliance and Shift-Left hooks of this repository locally:

1. **Install and Run Checkov (IaC Audit):**
   ```bash
   pip install checkov
   checkov -d .

2. **Install pre-commit Framework:**

   ```bash
   pip install pre-commit

3. **Activate as Git Hooks:**
   ```bash
   pre-commit install

4. **Test all hooks manually against the codebase:**
   ```bash
   pre-commit run --all-files