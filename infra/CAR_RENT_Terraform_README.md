# CAR-RENT Infrastructure README

## Overview

This README documents the current Terraform infrastructure for the CAR-RENT project.

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
    └── iam/
```

---

# Dev Environment

The `dev` environment connects all Terraform modules together.

It creates:

- VPC and subnets
- Security groups
- Web and App EC2 instances
- Public and Internal Application Load Balancers
- Private RDS PostgreSQL database
- IAM roles and instance profiles
- Remote Terraform state configuration

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

`use_lockfile = true` enables native S3 state locking and replaces the older DynamoDB lock table approach.

The backend bucket should have:

```text
Versioning enabled
Encryption enabled
Public access blocked
```

---

# Terraform Modules

## 1. network

**Path:** `infra/terraform/modules/network`

Creates the base VPC networking layer.

Resources:

- VPC
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

CIDR layout:

```text
VPC: 10.0.0.0/16

Public:
- 10.0.1.0/24
- 10.0.2.0/24

Private Web:
- 10.0.11.0/24
- 10.0.12.0/24

Private App:
- 10.0.21.0/24
- 10.0.22.0/24

Private DB:
- 10.0.31.0/24
- 10.0.32.0/24
```

Outputs:

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

**Path:** `infra/terraform/modules/security`

Creates security groups for all tiers.

Security flow:

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

Rules:

```text
Public ALB SG:
- inbound 80/443 from 0.0.0.0/0
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

Outputs:

```text
public_alb_sg_id
web_tier_sg_id
internal_alb_sg_id
app_tier_sg_id
rds_sg_id
```

---

## 3. public_alb

**Path:** `infra/terraform/modules/public_alb`

Creates the public Application Load Balancer.

Flow:

```text
Internet
  ↓
Public ALB :80
  ↓
Web Tier :80
```

Resources:

- Public Application Load Balancer
- Web target group
- HTTP listener on port 80
- Target group attachments for Web EC2 instances

Outputs:

```text
alb_arn
alb_dns_name
alb_zone_id
web_target_group_arn
http_listener_arn
```

---

## 4. web_tier

**Path:** `infra/terraform/modules/web_tier`

Creates private EC2 instances for the Web Tier.

Responsibilities:

- Receive traffic from the Public ALB
- Serve frontend traffic on port 80
- Forward backend/API traffic to the Internal ALB
- Store the Internal ALB URL locally
- Attach IAM instance profile for SSM access

Environment-based sizing:

```text
dev  -> t3.micro, 1 instance
test -> t3.small, 2 instances
prod -> t3.medium, 3 instances
```

Terraform writes the backend URL to:

```text
/etc/car-rent-web.env
```

Expected content:

```bash
APP_BACKEND_URL=http://internal-alb-dns-name
```

IAM permissions:

```text
AmazonSSMManagedInstanceCore
```

The Web Tier does not have database secret access.

Outputs:

```text
web_instance_ids
web_private_ips
```

---

## 5. internal_alb

**Path:** `infra/terraform/modules/internal_alb`

Creates an internal Application Load Balancer between Web and App.

Flow:

```text
Web Tier
  ↓ HTTP :80
Internal ALB
  ↓ HTTP :8000
App Tier
```

Resources:

- Internal Application Load Balancer
- App target group
- HTTP listener on port 80
- Target group attachments for App EC2 instances

Outputs:

```text
internal_alb_arn
internal_alb_dns_name
internal_alb_zone_id
app_target_group_arn
http_listener_arn
```

---

## 6. app_tier

**Path:** `infra/terraform/modules/app_tier`

Creates private EC2 instances for the App Tier.

Responsibilities:

- Receive traffic from the Internal ALB
- Run backend/API workload on port 8000
- Connect to RDS PostgreSQL
- Read DB credentials from Secrets Manager using IAM
- Store DB connection metadata locally

Environment-based sizing:

```text
dev  -> t3.micro, 1 instance
test -> t3.small, 2 instances
prod -> t3.medium, 3 instances
```

Terraform writes database metadata to:

```text
/etc/car-rent-app.env
```

Expected content:

```bash
DB_SECRET_ARN=arn:aws:secretsmanager:...
DB_HOST=car-rent-dev-postgres.xxxxxx.us-east-1.rds.amazonaws.com
DB_NAME=carrent
DB_PORT=5432
```

The database password is not stored in Git, Terraform code, user data, or plain text variables. The App Tier receives only metadata and uses its IAM role to read credentials from Secrets Manager.

IAM permissions:

```text
AmazonSSMManagedInstanceCore
secretsmanager:GetSecretValue
secretsmanager:DescribeSecret
```

Outputs:

```text
app_instance_ids
app_private_ips
```

---

## 7. database

**Path:** `infra/terraform/modules/database`

Creates the private RDS PostgreSQL database layer.

Resources:

- DB subnet group
- RDS PostgreSQL instance
- AWS-managed master user password through Secrets Manager

Settings:

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

The database uses:

```hcl
manage_master_user_password = true
```

This makes RDS create and manage the master password in Secrets Manager.

Outputs:

```text
db_endpoint
db_port
db_name
db_master_user_secret_arn
```

---

## 8. iam

**Path:** `infra/terraform/modules/iam`

Creates IAM roles, policies, and instance profiles for App and Web EC2 instances.

App EC2 role:

```text
AmazonSSMManagedInstanceCore
secretsmanager:GetSecretValue
secretsmanager:DescribeSecret
```

Secret access is scoped only to the RDS secret ARN.

Web EC2 role:

```text
AmazonSSMManagedInstanceCore
```

Design:

```text
App Role = SSM + DB secret access
Web Role = SSM only
```

Outputs:

```text
app_instance_profile_name
app_instance_profile_arn
app_ec2_role_arn
web_instance_profile_name
web_instance_profile_arn
web_ec2_role_arn
```

---

# Shared Prerequisites Outside the dev Terraform Stack

## Ansible SSM Payload Bucket

The Ansible SSM payload bucket is created outside the Terraform `dev` stack.

Current bucket:

```text
car-rent-dev-ansible-ssm-emad
```

This bucket is a shared tooling resource used by Ansible to upload temporary module payloads when connecting through the AWS SSM connection plugin.

It is intentionally outside the dev Terraform stack, so `terraform destroy` removes only the application infrastructure and does not delete the shared Ansible bucket.

Recommended bucket configuration:

```text
Public access blocked
Server-side encryption enabled
Versioning suspended
Lifecycle cleanup enabled for temporary payloads
```

---

# Terraform Commands

Run commands from:

```text
infra/terraform/environments/dev
```

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
terraform destroy
terraform state list
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

---

# Ansible Integration Handoff

This infrastructure is prepared to be managed by Ansible through AWS Systems Manager.

The target EC2 instances are private and should not be accessed through SSH or a bastion host.

## What Is Already Prepared

The infrastructure provides:

```text
Private EC2 instances
IAM instance profiles with SSM access
Outbound internet access through NAT
AWS Systems Manager connectivity
S3 bucket for Ansible SSM temporary payloads
Environment metadata files written by Terraform
```

Ansible should use AWS SSM as the connection method.

```text
Ansible Control Node
  ↓
AWS Systems Manager
  ↓
Private EC2 Instances
```

---

## Required Tools

Install the following tools on the machine that will run Ansible:

```text
Ansible
AWS CLI
AWS Session Manager Plugin
amazon.aws Ansible collection
boto3
botocore
```

Install Python dependencies:

```bash
pip install boto3 botocore
```

Install the AWS Ansible collection:

```bash
ansible-galaxy collection install amazon.aws
```

Verify AWS access:

```bash
aws sts get-caller-identity --profile project
```

---

## AWS Profile

Use this AWS CLI profile:

```text
project
```

Region:

```text
us-east-1
```

---

## SSM Connectivity Check

Before running any Ansible playbooks, confirm that the EC2 instances are visible in AWS Systems Manager:

```bash
aws ssm describe-instance-information \
  --region us-east-1 \
  --profile project \
  --query "InstanceInformationList[*].[InstanceId,ComputerName,PingStatus]" \
  --output table
```

Expected result:

```text
Instances should appear as Online
```

If instances are not online, check:

```text
IAM instance profile
AmazonSSMManagedInstanceCore policy
SSM Agent status
Private subnet outbound access through NAT
AWS profile and region
```

---

## Ansible SSM Payload Bucket

Use this S3 bucket for Ansible SSM temporary payloads:

```text
car-rent-dev-ansible-ssm-emad
```

This bucket is created outside the Terraform dev stack and should be reused by Ansible.

It is not part of `terraform destroy`.

---

## Inventory Setup

Create an Ansible dynamic inventory file:

```text
ansible/inventories/aws_ec2.yml
```

Example:

```yaml
plugin: amazon.aws.aws_ec2

regions:
  - us-east-1

profile: project

filters:
  tag:Environment: dev
  instance-state-name: running

hostnames:
  - instance-id

compose:
  ansible_host: instance_id
  ansible_connection: "'amazon.aws.aws_ssm'"
  ansible_aws_ssm_region: "'us-east-1'"
  ansible_aws_ssm_profile: "'project'"
  ansible_aws_ssm_bucket_name: "'car-rent-dev-ansible-ssm-emad'"
  ansible_python_interpreter: "'/usr/bin/python3'"

strict: false
```

This inventory discovers the running EC2 instances in the `dev` environment and connects to them through SSM.

---

## Validate Inventory

Run:

```bash
ansible-inventory -i inventories/aws_ec2.yml --graph
```

This should return the discovered EC2 instances.

---

## Test Ansible Connection

Run:

```bash
ansible all -i inventories/aws_ec2.yml -m ping
```

Expected result:

```text
SUCCESS => {
  "ping": "pong"
}
```

This confirms that:

```text
AWS credentials are valid
Dynamic inventory can discover EC2 instances
SSM can reach the private instances
The S3 payload bucket works
Ansible can execute commands without SSH
```

---

## Useful Test Commands

Check hostnames:

```bash
ansible all -i inventories/aws_ec2.yml -m command -a "hostname"
```

Check operating system information:

```bash
ansible all -i inventories/aws_ec2.yml -m command -a "cat /etc/os-release"
```

Check Terraform-provided environment files:

```bash
ansible all -i inventories/aws_ec2.yml -m shell -a "ls -l /etc/car-rent-*.env || true"
```

Read environment metadata:

```bash
ansible all -i inventories/aws_ec2.yml -m shell -a "cat /etc/car-rent-*.env || true"
```

---

## Running Playbooks

After creating the required Ansible playbooks and roles, run them using the same inventory:

```bash
ansible-playbook -i inventories/aws_ec2.yml playbooks/site.yml
```

Or run any specific playbook:

```bash
ansible-playbook -i inventories/aws_ec2.yml playbooks/<playbook-name>.yml
```

---

## Integration Summary

```text
Connection method: AWS SSM
SSH required: No
Bastion required: No
Public IP required: No
Inventory source: AWS EC2 dynamic inventory
Temporary payload bucket: car-rent-dev-ansible-ssm-emad
AWS profile: project
Region: us-east-1
```

