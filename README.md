# AWS Infrastructure as Code (IaC) with Terraform 

This repository showcases my journey and practical implementations of Infrastructure as Code using **Terraform** on **AWS**. It covers concepts from basic resource provisioning to advanced modular structures, state management, workspaces, and dynamic configurations.



##  Concepts & Hands-on Projects

### 1. `ec2-basics`
- Basic provider setup and provisioning an AWS EC2 instance.
- Understanding core Terraform lifecycle commands (`init`, `plan`, `apply`, `destroy`).

### 2. `s3-dynamodb-remote-backend`
- Configured **Remote State Management** using AWS S3.
- Implemented **State Locking** using AWS DynamoDB to prevent concurrent executions.

### 3. `custom-modules`
- Created reusable custom local modules for EC2 instances.
- Practiced input variables (`variables.tf`) and output values (`outputs.tf`).

### 4. `registry-vpc`
- Utilized official Terraform Registry modules to provision a multi-AZ VPC infrastructure (19+ networking resources).

### 5. `workspace-demo`
- Implemented **Terraform Workspaces** (`dev`, `prod`) for isolated environment configurations.
- Dynamic variable lookup using `local` scopes based on `terraform.workspace`.

### 6. `dynamic-blocks-loops`
- Optimized code using Terraform loops (`for_each`) for resource creation.
- Used `dynamic` blocks for repeating nested configurations (Security Group ingress rules).



##  Security Best Practices Implemented
- Used `.gitignore` to prevent committing sensitive state files and provider binaries to Git.
- Restricted SSH access patterns and adhered to least privilege principles.
- Managed remote backend with state locking.


*Created as part of my Cloud Security & Infrastructure Learning Journey.