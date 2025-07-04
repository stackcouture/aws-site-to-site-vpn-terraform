> 🚧 **Terraform Automation In Progress**
>
> This project is currently under active development.
> Terraform automation for all VPN components (VGW, CGW, EC2, etc.) is partially implemented.
>
> ✅ Manual steps (like OpenSwan setup on Ireland EC2) are fully documented.
> 🔄 Terraform modules and automation will be updated and integrated soon.
>
> 📌 Follow or star this repo to get updates.

---

# 🛡️ AWS Site-to-Site VPN (Mumbai ↔ Ireland) — Terraform Demo

This repository demonstrates how to configure a **Site-to-Site VPN** connection between two AWS VPCs using **Terraform** and **manual OpenSwan setup**, simulating an on-premises data center with an EC2 instance in the **Ireland** region.

> ✅ This setup is for **educational/demo purposes only** and simulates on-prem connectivity without needing physical infrastructure.

---

## 🗺️ Architecture Overview

```text
Mumbai VPC (VPC-A) [10.1.0.0/16]
└── Private EC2 Instance (no public IP)
    └── Connected via VGW + VPN

        🔗 Site-to-Site VPN (IPSec)

Ireland VPC (VPC-B) [10.2.0.0/16]
└── Public EC2 (OpenSwan VPN Server)
    └── Simulates On-Premise Firewall
```

### 🧰 Components Used

* **Terraform**: For provisioning AWS infrastructure
* **OpenSwan**: Installed manually on Ireland EC2 for VPN tunnel
* **Amazon Linux 2**
* **Site-to-Site VPN**: AWS-managed tunnels (IKEv1)
* **Static Routing**: Manual subnet route setup (no BGP)

---

## 📦 Folder Structure

```
├── terraform/
│   ├── mumbai-vpc.tf         # VPC-A (Mumbai) with private subnet
│   ├── ireland-vpc.tf        # VPC-B (Ireland) with public subnet
│   ├── vpn-resources.tf      # VGW, CGW, Site-to-Site VPN
│   ├── ec2-instance.tf       # EC2 instances on both sides
│   └── variables.tf
├── scripts/
│   └── openswan-setup.sh     # Manual setup script for Ireland EC2
├── diagram/
│   └── vpn-architecture.png  # Network topology diagram
└── README.md
```

---

## 🧾 Prerequisites

* AWS CLI configured
* Terraform v1.4+ installed
* Key pairs for both Mumbai and Ireland regions
* MobaXterm or SSH client for EC2 login
* Inbound ports UDP 500 & 4500 open for IPSec
* `terraform.tfvars` or define these variables manually:

  ```hcl
  mumbai_region  = "ap-south-1"
  ireland_region = "eu-west-1"
  ```

---

## 🚀 Deployment Steps

### 1. Clone the Repo

```bash
git clone https://github.com/stackcouture/aws-site-to-site-vpn-terraform.git
cd aws-site-to-site-vpn-terraform
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Plan and Apply

```bash
terraform plan
terraform apply
```

### ☑️ Resources Created

* **Mumbai**: VPC-A, Private EC2, VGW, VPN Connection
* **Ireland**: VPC-B, Public EC2 (OpenSwan), CGW

---

## 🔧 OpenSwan Configuration (Ireland EC2)

1. Connect to the Ireland EC2 instance using your `.pem` key via MobaXterm or SSH.
2. Follow the steps inside `scripts/openswan-setup.sh`.
3. Modify the following files based on AWS VPN config:

   * `/etc/ipsec.d/aws.conf`
   * `/etc/ipsec.secrets`
4. Start and enable IPsec service:

```bash
sudo systemctl enable --now ipsec
sudo systemctl status ipsec
```

---

## 🧪 Validation

* ✅ From Ireland EC2, ping the Mumbai private EC2 IP
* ✅ Verify VPN tunnel status in AWS Console (should be UP)
* ✅ Use `ipsec auto --status` on Ireland EC2 to check IPsec connection



## 📜 License

MIT License — fork, clone, contribute freely.

---

## 📈 Stay Tuned

Star ⭐ this repo to receive updates as Terraform modules for full automation are rolled out.
