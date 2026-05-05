# CAR-RENT Infrastructure README

## Overview

This README documents the current Terraform infrastructure for the CAR-RENT project and explains how the Ansible engineer should integrate with it.

The project is built as a multi-tier AWS architecture using reusable Terraform modules.

```text
Internet
  ↓
Public ALB
  ↓
Private Web Tier
  ↓
Internal ALB
  ↓
Private App Tier
  ↓
Secrets Manager
  ↓
Private RDS PostgreSQL
```

---

## Traffic Flow

```text
User Browser
  ↓ HTTP :80
Public ALB
  ↓ HTTP :80
Private Web EC2
  ↓ HTTP :80
Internal ALB
  ↓ HTTP :8000
Private App EC2
  ↓ PostgreSQL :5432
Private RDS PostgreSQL
```

---

## Repository Structure

```text
infra/terraform/
├── environments/
│   └── dev/
│       ├── backend.tf
│       ├── main.tf
│       ├── providers.tf
│       └── variables.tf
│
└── modules/
    ├── network/
    ├── security/
    ├── public_alb/
    ├── internal_alb/
    ├── web_tier/
    ├── app_tier/
    ├── database/
    ├── iam/
    └── ansible_ssm/
```

---

# Environment

## dev

The `dev` environment wires all Terraform modules together.

Main responsibilities:

- Create the VPC and subnets
- Create security groups
- Create Web and App EC2 instances
- Create Public and Internal ALBs
- Create private RDS PostgreSQL
- Create IAM roles and instance profiles
- Create the Ansible SSM payload bucket
- Store Terraform state in S3 remote backend

Provider configuration:

```hcl
provider "aws" {
  region  = "us-east-1"
  profile = "project"
}
```

---

# Terraform Remote Backend

Terraform state is stored remotely in S3.

```hcl
terraform {
  backend "s3" {
    bucket       = "car-rent-terraform-state-bucket"
    key          = "dev/terraform.tfstate"
    region       = "us-east-1"
    profile      = "project"
    use_lockfile = true
  }
}
```

## Why S3 Lockfile Instead of DynamoDB

The backend uses native S3 lockfile locking:

```hcl
use_lockfile = true
```

This avoids the older DynamoDB state-locking table approach.

The S3 state bucket must exist before running:

```bash
terraform init
```

The backend bucket should have:

```text
Versioning enabled
Encryption enabled
Public access blocked
```

---

# Terraform Modules

## 1. network

**Path:**

```text
infra/terraform/modules/network
```

## Purpose

Creates the base VPC networking layer.

## Resources

- `aws_vpc`
- Public subnets
- Private Web subnets
- Private App subnets
- Private DB subnets
- Internet Gateway
- NAT Gateway
- Elastic IP for NAT Gateway
- Public route table
- Private route table
- Route table associations

## CIDR Layout

```text
VPC:
- 10.0.0.0/16

Public subnets:
- 10.0.1.0/24
- 10.0.2.0/24

Private Web subnets:
- 10.0.11.0/24
- 10.0.12.0/24

Private App subnets:
- 10.0.21.0/24
- 10.0.22.0/24

Private DB subnets:
- 10.0.31.0/24
- 10.0.32.0/24
```

## Notes

Private Web and App subnets are associated with the private route table that routes outbound internet traffic through NAT Gateway.

The DB subnets are created separately for the RDS subnet group.

## Outputs

```text
vpc_id
public_subnet_ids
private_web_subnet_ids
private_app_subnet_ids
private_db_subnet_ids
nat_gateway_id
```

---

## 2. security

**Path:**

```text
infra/terraform/modules/security
```

## Purpose

Creates the security groups that control traffic between all tiers.

## Security Group Flow

```text
Public ALB SG
  ↓
Web Tier SG
  ↓
Internal ALB SG
  ↓
App Tier SG
  ↓
RDS SG
```

## Rules

```text
Public ALB SG:
- inbound 80 from 0.0.0.0/0
- inbound 443 from 0.0.0.0/0
- outbound all

Web Tier SG:
- inbound 80 from Public ALB SG only
- outbound all

Internal ALB SG:
- inbound 80 from Web Tier SG only
- outbound all

App Tier SG:
- inbound 8000 from Internal ALB SG only
- outbound all

RDS SG:
- inbound 5432 from App Tier SG only
- outbound all
```

## Outputs

```text
public_alb_sg_id
web_tier_sg_id
internal_alb_sg_id
app_tier_sg_id
rds_sg_id
```

---

## 3. public_alb

**Path:**

```text
infra/terraform/modules/public_alb
```

## Purpose

Creates the public Application Load Balancer that receives traffic from users and forwards it to the private Web Tier.

## Resources

- Public Application Load Balancer
- Web target group
- HTTP listener on port 80
- Target group attachments for Web EC2 instances

## Flow

```text
Internet
  ↓
Public ALB :80
  ↓
Web Tier :80
```

## Important Settings

```text
ALB visibility: public
ALB type: application
Listener: HTTP 80
Target type: instance
Target port: 80
```

## Outputs

```text
alb_arn
alb_dns_name
alb_zone_id
web_target_group_arn
http_listener_arn
```

---

## 4. web_tier

**Path:**

```text
infra/terraform/modules/web_tier
```

## Purpose

Creates EC2 instances for the private Web Tier.

## Responsibilities

- Receive traffic from the Public ALB
- Serve the frontend on port 80
- Forward backend/API traffic to the Internal ALB
- Store the Internal ALB URL locally for the app deployment
- Attach an IAM instance profile for SSM access

## EC2 Sizing

The module uses environment-based sizing:

```text
dev  -> t3.micro, 1 instance
test -> t3.small, 2 instances
prod -> t3.medium, 3 instances
```

## Backend URL Handoff

Terraform writes the Internal ALB URL to:

```text
/etc/car-rent-web.env
```

Expected file content:

```bash
APP_BACKEND_URL=http://internal-alb-dns-name
```

This file is used later by Ansible or the application runtime so that the Web Tier knows where to send backend/API requests.

## IAM

The Web Tier uses a dedicated IAM instance profile.

Permissions:

```text
AmazonSSMManagedInstanceCore
```

The Web Tier does not have permission to read database secrets.

## Outputs

```text
web_instance_ids
web_private_ips
```

---

## 5. internal_alb

**Path:**

```text
infra/terraform/modules/internal_alb
```

## Purpose

Creates an internal Application Load Balancer between the Web Tier and App Tier.

## Resources

- Internal Application Load Balancer
- App target group
- HTTP listener on port 80
- Target group attachments for App EC2 instances

## Flow

```text
Web Tier
  ↓ HTTP :80
Internal ALB
  ↓ HTTP :8000
App Tier
```

## Important Settings

```text
ALB visibility: internal
ALB type: application
Listener: HTTP 80
Target type: instance
Target port: 8000
```

## Outputs

```text
internal_alb_arn
internal_alb_dns_name
internal_alb_zone_id
app_target_group_arn
http_listener_arn
```

---

## 6. app_tier

**Path:**

```text
infra/terraform/modules/app_tier
```

## Purpose

Creates EC2 instances for the private App Tier.

## Responsibilities

- Receive traffic from the Internal ALB
- Run backend/API workload on port 8000
- Connect to RDS PostgreSQL
- Read DB credentials from Secrets Manager using IAM
- Store DB connection metadata locally for the app deployment

## EC2 Sizing

The module uses environment-based sizing:

```text
dev  -> t3.micro, 1 instance
test -> t3.small, 2 instances
prod -> t3.medium, 3 instances
```

## Database Handoff File

Terraform writes database connection metadata to:

```text
/etc/car-rent-app.env
```

Expected file content:

```bash
DB_SECRET_ARN=arn:aws:secretsmanager:...
DB_HOST=car-rent-dev-postgres.xxxxxx.us-east-1.rds.amazonaws.com
DB_NAME=carrent
DB_PORT=5432
```

## Important Security Note

The database password is not written to EC2 user data, Git, Terraform code, or plain text variables.

The App Tier receives:

```text
DB_SECRET_ARN
DB_HOST
DB_NAME
DB_PORT
```

Then the application uses the App EC2 IAM role to read the actual username/password from AWS Secrets Manager at runtime.

## IAM

The App Tier uses a dedicated IAM instance profile.

Permissions:

```text
AmazonSSMManagedInstanceCore
secretsmanager:GetSecretValue
secretsmanager:DescribeSecret
```

Secret access is restricted to the RDS master user secret ARN.

## Outputs

```text
app_instance_ids
app_private_ips
```

---

## 7. database

**Path:**

```text
infra/terraform/modules/database
```

## Purpose

Creates the private RDS PostgreSQL database layer.

## Resources

- DB subnet group
- RDS PostgreSQL instance
- AWS-managed master user password through Secrets Manager

## Main Settings

```text
Engine: PostgreSQL
Engine version: 16.3
Port: 5432
Instance class: db.t3.micro
Allocated storage: 20 GB
Storage encryption: enabled
Public access: disabled
Multi-AZ: disabled
Backups: disabled for dev
Deletion protection: disabled for dev
Final snapshot on destroy: skipped for dev
```

## Secrets Manager Integration

The database uses:

```hcl
manage_master_user_password = true
```

This makes AWS RDS create and manage the master password in AWS Secrets Manager.

## Why This Matters

This avoids storing DB passwords in:

```text
Terraform code
Git history
tfvars files
EC2 user data
Plain text shell scripts
```

## Outputs

```text
db_endpoint
db_port
db_name
db_master_user_secret_arn
```

---

## 8. iam

**Path:**

```text
infra/terraform/modules/iam
```

## Purpose

Creates IAM roles, policies, and instance profiles for App and Web EC2 instances.

## App EC2 IAM Role

The App role is used by App EC2 instances.

Permissions:

```text
AmazonSSMManagedInstanceCore
secretsmanager:GetSecretValue
secretsmanager:DescribeSecret
```

The Secrets Manager policy is scoped only to:

```text
module.database.db_master_user_secret_arn
```

## Web EC2 IAM Role

The Web role is used by Web EC2 instances.

Permissions:

```text
AmazonSSMManagedInstanceCore
```

The Web Tier does not need access to the RDS secret.

## Design Principle

```text
App Role = SSM + DB secret access
Web Role = SSM only
```

This follows least privilege.

## Outputs

```text
app_instance_profile_name
app_instance_profile_arn
app_ec2_role_arn
web_instance_profile_name
web_instance_profile_arn
web_ec2_role_arn
```

---

## 9. ansible_ssm

**Path:**

```text
infra/terraform/modules/ansible_ssm
```

## Purpose

Creates the S3 bucket used by Ansible when connecting to private EC2 instances through AWS Systems Manager.

## Why This Bucket Exists

Ansible's SSM connection plugin uploads temporary module payloads to S3 before executing them on the target instances through SSM.

## Resources

- S3 bucket
- Public access block
- Server-side encryption using AES256
- Versioning suspended

## Versioning Design

```text
Terraform state bucket:
- Versioning enabled

Ansible SSM payload bucket:
- Versioning suspended
```

The Ansible payload bucket keeps versioning suspended because Ansible uploads temporary execution files and deletes them after use. If versioning is enabled, deleted temporary payloads can remain in S3 version history.

## Output

```text
ansible_ssm_bucket_name
```

---

# Terraform Commands

Run commands from:

```text
infra/terraform/environments/dev
```

## Initialize

```bash
terraform init
```

## Format

```bash
terraform fmt -recursive
```

## Validate

```bash
terraform validate
```

## Plan

```bash
terraform plan
```

## Apply

```bash
terraform apply
```

## Check State

```bash
terraform state list
```

---

# Current Infrastructure Status

```text
Network module completed
Security module completed
Public ALB module completed
Web Tier module completed
Internal ALB module completed
App Tier module completed
Database module completed
IAM module completed
Ansible SSM bucket completed
Terraform remote backend completed
SSM access tested
Ansible ping over SSM tested
```

---

# Important Ports

```text
Public ALB      : 80 / 443
Web Tier        : 80
Internal ALB    : 80
App Tier        : 8000
RDS PostgreSQL  : 5432
```

---

# Security Summary

```text
Public users can reach only the Public ALB.
Web instances are private.
App instances are private.
RDS is private.
Only Public ALB can reach Web Tier.
Only Web Tier can reach Internal ALB.
Only Internal ALB can reach App Tier.
Only App Tier can reach RDS PostgreSQL.
Database password is managed by AWS Secrets Manager.
App Tier reads the DB secret using IAM.
Web Tier has no DB secret access.
```

---