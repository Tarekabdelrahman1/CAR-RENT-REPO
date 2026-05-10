# 🚗 CAR-RENT: Enterprise-Grade AWS Cloud Architecture

<img width="2816" height="1536" alt="Gemini_Generated_Image_70dkru70dkru70dk" src="https://github.com/user-attachments/assets/2fad8a01-6f95-4a16-ae9d-faf8850bbc91" />


<img width="1884" height="862" alt="Screenshot 2026-05-09 232128" src="https://github.com/user-attachments/assets/43fae64e-368c-4ac8-9d52-bec9abc2d337" />

## 📌 Overview

CAR-RENT is a highly available and fully automated car rental platform built using a modern full-stack architecture and deployed on AWS using Infrastructure as Code and configuration management tools.

The platform combines:
- **Frontend:** React
- **Backend:** Laravel (PHP)
- **Database:** PostgreSQL (Amazon RDS)
- **Infrastructure as Code (IaC):** Terraform
- **Configuration Management:** Ansible
- **Secure Access & Automation:** AWS Systems Manager (SSM)

---

## 🏗️ Architecture Overview

The infrastructure is deployed in the AWS `us-east-1` region across two Availability Zones (`us-east-1a` and `us-east-1b`) for high availability and fault tolerance.

### Network Topology (VPC CIDR: `10.0.0.0/16`)

#### 1. Public Subnets (`10.0.1.0/24`, `10.0.2.0/24`)
* **Resources:** Internet Gateway, NAT Gateways, Public Application Load Balancer (ALB).
* **Purpose:** Serves as the entry point for end-user traffic and provides outbound internet access for private instances via NAT.

#### 2. Private Web Subnets (`10.0.11.0/24`, `10.0.12.0/24`)
* **Resources:** React frontend EC2 instances inside an Auto Scaling Group (ASG).
* **Purpose:** Hosts the presentation layer. Completely isolated from direct internet access.

#### 3. Private App Subnets (`10.0.21.0/24`, `10.0.22.0/24`)
* **Resources:** Internal Application Load Balancer, Laravel backend EC2 instances inside an ASG.
* **Purpose:** Hosts the business logic layer. The Internal ALB routes API traffic from the Web tier to the App tier.

#### 4. Private DB Subnets (`10.0.31.0/24`, `10.0.32.0/24`)
* **Resources:** Amazon RDS PostgreSQL (Primary and Standby/Replica).
* **Purpose:** Secure, highly available data storage.

---

## 🔐 Security Architecture

Security is implemented using a principle of least privilege. Instances are deployed without public IP addresses, and SSH (Port 22) is completely disabled. All administrative access and remote code execution are handled securely via **AWS Systems Manager (SSM)**.

### Security Group Traffic Flow

Traffic flow is strictly restricted between tiers using AWS Security Groups:

| Source | Destination | Protocol/Port | Description |
| :--- | :--- | :--- | :--- |
| **Internet (0.0.0.0/0)** | Public ALB SG | HTTP (80) / HTTPS (443) | End-user web traffic |
| **Public ALB SG** | Web Tier SG | HTTP (80) | Traffic forwarded to React servers |
| **Web Tier SG** | Internal ALB SG | HTTP (80) | API requests from Frontend to Internal Router |
| **Internal ALB SG** | App Tier SG | HTTP (8000 / 80) | API requests forwarded to Laravel servers |
| **App Tier SG** | Database SG | TCP (5432) | Database queries from Laravel to PostgreSQL |

---

## ⚙️ Automation & Deployment Lifecycle

We utilize a modern DevOps toolchain to ensure zero-downtime, reproducible deployments.

### 1. Infrastructure Provisioning (Terraform)
Terraform is used to define and provision the entire AWS backbone:
* VPC, Subnets, Route Tables, and Internet/NAT Gateways.
* Security Groups and IAM Instance Profiles.
* Application Load Balancers and Target Groups.
* Auto Scaling Groups (ASG) and Launch Templates.
* RDS PostgreSQL Database.

### 2. Configuration Management (Ansible + AWS SSM)
Instead of using traditional SSH/Bastion hosts, we leverage **AWS Systems Manager (SSM) Run Command** to execute Ansible playbooks directly on the private instances.
* **Web Tier Ansible:** Installs Node.js/Nginx, pulls the latest React code, builds the static assets, and configures reverse proxies.
* **App Tier Ansible:** Installs PHP, Composer, Nginx, pulls the Laravel codebase, runs migrations, and manages environment variables.

### 3. High Availability & Auto Scaling
* **Target Tracking Scaling:** The ASGs monitor average CPU utilization. If traffic spikes, new instances are automatically spun up.
* **User Data Bootstrapping:** When a new instance scales up, the EC2 Launch Template automatically installs the SSM agent and triggers the Ansible deployment to ensure the new node matches the current production state before being attached to the Load Balancer.

---

## 🚀 Getting Started

### Prerequisites
* [Terraform](https://www.terraform.io/downloads.html) (v1.x.x)
* [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate IAM permissions
* [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)

### Deployment Steps
1. **Clone the repository:**
   ```bash
   git clone [https://github.com/your-username/car-rent-infrastructure.git](https://github.com/your-username/car-rent-infrastructure.git)
   cd car-rent-infrastructure/terraform
