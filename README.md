#  Enterprise AWS Infrastructure as Code (IaC) & DevSecOps Portfolio

![DevSecOps Security Audit](https://github.com/shafimuhammad5255-hue/terraform-aws-portfolio/actions/workflows/devsecops.yml/badge.svg)

This repository contains production-grade **Terraform** infrastructure modules for AWS, hardened and audited against industry security standards using **Checkov** to achieve a **0 Failed Checks** benchmark.



##  Security & Compliance Status

- **Static Analysis Tool:** [Checkov](https://www.checkov.io/)
- **Total Security Checks:** 200+
- **Failed Checks:** **0** (100% Compliant)
- **Frameworks Covered:** CIS AWS Benchmarks, AWS Foundational Security Best Practices



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



##  DevSecOps & Security Hardening Highlights

Security Control,  Implementation Details 

| **Identity & Access (IAM)** : Removed `*` wildcards from KMS key policies; enforced strict service principals. 

| **Compute (EC2)** : Enforced IMDSv2 (`http_tokens = required`), EBS volume encryption, and attached IAM profiles. 

| **Storage (S3)** : Blocked all public access, enabled versioning, KMS encryption, and access logging across all buckets.

| **Networking (VPC)** : Configured VPC Flow Logs and restricted default Security Group ingress/egress rules. 

| **Supply Chain** : Locked third-party Terraform registry module sources using immutable Git commit SHAs. 



##  How to Audit & Run Scans Locally

To verify the security compliance of this repository:

1. **Install Checkov:**
   ```bash
   pip install checkov