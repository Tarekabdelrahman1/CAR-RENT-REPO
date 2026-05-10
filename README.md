# 🚗 CAR-RENT: Enterprise-Grade AWS Cloud Architecture

<img width="1884" height="862" alt="Screenshot 2026-05-09 232128" src="https://github.com/user-attachments/assets/43fae64e-368c-4ac8-9d52-bec9abc2d337" />


## 📌 Overview

CAR-RENT is a highly available and fully automated car rental platform built using a modern full-stack architecture and deployed on AWS using Infrastructure as Code and configuration management tools.

The platform combines:

- React frontend
- Laravel backend
- PostgreSQL database
- Terraform infrastructure provisioning
- Ansible automation
- AWS Systems Manager (SSM)

---

# 🏗️ Architecture Overview

The infrastructure is deployed in the AWS `us-east-1` region across two Availability Zones for high availability and fault tolerance.

## Network Topology

### Public Subnets
- `10.0.1.0/24`
- `10.0.2.0/24`

Used for:
- Internet Gateway
- NAT Gateways
- Public Application Load Balancer

### Private Web Subnets
- `10.0.11.0/24`
- `10.0.12.0/24`

Used for:
- React frontend instances
- Auto Scaling Group

### Private App Subnets
- `10.0.21.0/24`
- `10.0.22.0/24`

Used for:
- Internal Load Balancer
- Laravel backend instances
- Auto Scaling Group

### Private DB Subnets
- `10.0.31.0/24`
- `10.0.32.0/24`

Used for:
- Amazon RDS PostgreSQL

---

# 🔐 Security Architecture

Traffic flow is restricted using Security Groups:

```text
Internet
   ↓
Public ALB
   ↓
Web Tier
   ↓
Internal ALB
   ↓
Application Tier
   ↓
Database Tier
