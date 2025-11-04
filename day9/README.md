# 🚀 Day 9 – Infrastructure as Code (Terraform Automation)

**Quick Links:**  
[▶ 1. Overview](#1-overview) •  
[▶ 2. Architecture Diagram](#2-architecture-diagram) •  
[▶ 3. Folder Layout](#3-folder-layout) •  
[▶ 4. Terraform Setup](#4-terraform-setup) •  
[▶ 5. Core Networking (vWAN + Hub)](#5-core-networking-vwan--hub) •  
[▶ 6. Secured Hub + Firewall Policy](#6-secured-hub--firewall-policy) •  
[▶ 7. Storage Account + Private Endpoint](#7-storage-account--private-endpoint) •  
[▶ 8. Private DNS + Links](#8-private-dns--links) •  
[▶ 9. Policy Assignments + Exemptions](#9-policy-assignments--exemptions) •  
[▶ 10. Apply & Validate](#10-apply--validate)

---

## 1️ Overview
**Goal:** Convert everything from **Days 1–8** (vWAN, Firewall Policy, Private Link, DNS, and Policy Governance) into reproducible, idempotent **Terraform code**.

**Outcome:**  
You’ll be able to deploy the entire environment with:
```bash
terraform init
terraform plan
terraform apply -auto-approve

## 2️ Architecture Diagram
```mermaid
graph TD
    subgraph Azure
        A[Azure Virtual WAN] --> B[Secured Virtual Hub]
        B --> C[Azure Firewall (Policy = Alert)]
        B --> D[DeptA VNet]
        B --> E[DeptB VNet]
        B --> F[DeptC VNet]
        D --> G[Private Endpoint (Blob)]
        E --> G
        F --> G
        G --> H[Private DNS Zone<br/>privatelink.blob.core.windows.net]
        H --> I[Storage Account<br/>public access = disabled]
        C --> J[Azure Policy<br/>fwpolicy-threatintel]
    end
    style A fill:#f4f4f4,stroke:#333,stroke-width:1px
    style C fill:#fdd,stroke:#333
    style G fill:#cde,stroke:#333
    style I fill:#cfc,stroke:#333
```

---

🔒 Day 9 Focus: Everything in this diagram now becomes declarative Terraform.

## 3️ Folder Layout

vwan-dept-architecture-labs/
└── terraform/
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    ├── backend.tf
    ├── dev.tfvars
    └── modules/
        ├── vwan/
        ├── firewall/
        ├── storage/
        ├── private_dns/
        └── policy/
## 4️ Terraform Setup (main.tf)

terraform {
  required_version = ">= 1.8.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

## 5️ Core Networking (vWAN + Hub)

resource "azurerm_resource_group" "clab" {
  name     = "clab-dev-rg"
  location = "eastus"
}

resource "azurerm_virtual_wan" "dept" {
  name                = "clab-vwan"
  resource_group_name = azurerm_resource_group.clab.name
  location            = azurerm_resource_group.clab.location
}

resource "azurerm_virtual_hub" "core" {
  name                = "clab-hub"
  resource_group_name = azurerm_resource_group.clab.name
  location            = azurerm_resource_group.clab.location
  virtual_wan_id      = azurerm_virtual_wan.dept.id
  address_prefix      = "10.70.0.0/23"
}

## 6️ Secured Hub + Firewall Policy

resource "azurerm_firewall_policy" "dept_fw_policy" {
  name                = "clab-dev-fw-policy"
  resource_group_name = azurerm_resource_group.clab.name
  location            = azurerm_resource_group.clab.location
  threat_intel_mode   = "Alert"
}

resource "azurerm_firewall" "dept_fw" {
  name                = "clab-dev-fw"
  location            = azurerm_resource_group.clab.location
  resource_group_name = azurerm_resource_group.clab.name
  sku_name            = "AZFW_Hub"
  firewall_policy_id  = azurerm_firewall_policy.dept_fw_policy.id
  virtual_hub_id      = azurerm_virtual_hub.core.id
}

## 7️ Storage Account + Private Endpoint

resource "azurerm_storage_account" "dept_storage" {
  name                         = "clabdevflow1762127757"
  resource_group_name          = azurerm_resource_group.clab.name
  location                     = azurerm_resource_group.clab.location
  account_tier                 = "Standard"
  account_replication_type     = "LRS"
  allow_nested_items_to_be_public = false
  public_network_access        = "Disabled"
  allow_shared_key_access      = false
  network_rules {
    default_action = "Deny"
  }
}

resource "azurerm_virtual_network" "pe_vnet" {
  name                = "clab-pe-vnet"
  address_space       = ["10.200.0.0/24"]
  location            = azurerm_resource_group.clab.location
  resource_group_name = azurerm_resource_group.clab.name
}

resource "azurerm_subnet" "pe_subnet" {
  name                 = "pe-subnet"
  resource_group_name  = azurerm_resource_group.clab.name
  virtual_network_name = azurerm_virtual_network.pe_vnet.name
  address_prefixes     = ["10.200.0.0/27"]
  private_endpoint_network_policies = "Disabled"
}

resource "azurerm_private_endpoint" "storage_pe" {
  name                = "${azurerm_storage_account.dept_storage.name}-pe-blob"
  location            = azurerm_resource_group.clab.location
  resource_group_name = azurerm_resource_group.clab.name
  subnet_id           = azurerm_subnet.pe_subnet.id

  private_service_connection {
    name                           = "blob-connection"
    private_connection_resource_id = azurerm_storage_account.dept_storage.id
    subresource_names              = ["blob"]
  }
}

## 8️ Private DNS + Links

resource "azurerm_private_dns_zone" "blob_dns" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.clab.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob_link" {
  name                  = "link-clab-pe-vnet"
  resource_group_name   = azurerm_resource_group.clab.name
  private_dns_zone_name = azurerm_private_dns_zone.blob_dns.name
  virtual_network_id    = azurerm_virtual_network.pe_vnet.id
  registration_enabled  = false
}

## 9️ Policy Assignments + Exemptions

data "azurerm_policy_definition" "require_fwpolicy_ti" {
  name = "clab-dev-require-fwpolicy-threatintel"
}

resource "azurerm_policy_assignment" "fwpolicy_ti" {
  name                 = "clab-dev-fwpolicy-threatintel-assign"
  scope                = azurerm_firewall_policy.dept_fw_policy.id
  policy_definition_id = data.azurerm_policy_definition.require_fwpolicy_ti.id
}

resource "azurerm_policy_exemption" "pevnet_exempt" {
  name                 = "exempt-pevnet-ddos"
  scope                = azurerm_virtual_network.pe_vnet.id
  policy_assignment_id = azurerm_policy_assignment.fwpolicy_ti.id
  exemption_category   = "Waiver"
  display_name         = "PE VNet is internal-only"
}

🔟 Apply & Validate

terraform init
terraform validate
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars" -auto-approve

✅ Expected Results
vWAN, Hub, Firewall, and Storage all deployed automatically

Private Endpoint + Private DNS linked correctly

Firewall Policy ThreatIntelMode = Alert (Policy-compliant)

Zero manual CLI steps required

🧭 Navigation
Prev	Next
⬅️ Day 8 – Governance & Compliance	➡️ Day 10 – Continuous Compliance & Dashboard
