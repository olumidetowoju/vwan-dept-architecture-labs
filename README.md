# 🌐 Azure Virtual WAN Architecture — Department-Optimized Course
**Tutor:** ChatGPT × Olumide  
**GitHub Repo:** `olumidetowoju/vwan-dept-architecture-labs`  
**Subscription ID:** 56d9a9d0-65a3-4aea-9957-ff103f641f9c  
**Region:** East US  
**Naming Prefix:** `clab-dev-001`

---

## 🎯 Course Objective
Build one Azure network that serves departments with **different security and performance needs** using **Azure Virtual WAN**.  
You’ll deploy → test → destroy each lab to control costs.  
All content is written in **textbook + hands-on lab style** with **Mermaid diagrams**.

---

## 🗂️ Clickable Syllabus

| Day | Topic | Lab File |
|:---:|:------|:---------|
| 1 | [Foundations & Prereqs](labs/day01-foundations.md) | Environment setup & mental model |
| 2 | Deploy Virtual WAN & Core Hub | *(next)* |
| 3 | Secure Hub with Azure Firewall Manager | *(next)* |
| 4 | Routing Intent & Dept Profiles | *(next)* |
| 5 | Branch & Remote Connectivity | *(later)* |
| 6 | Observability & Telemetry | *(later)* |
| 7 | Multi-Region DR | *(later)* |
| 8 | NVAs & 3rd-Party Firewalls | *(later)* |
| 9 | Guardrails & Governance | *(later)* |
| 10 | Cost Management & Cleanup | *(later)* |

---

## 🧠 Concept Analogy
Think of Azure Virtual WAN as a network of airports ✈️:

| Concept | Analogy | Purpose |
|----------|----------|---------|
| Virtual WAN | 🌎 Airline Alliance | Global backbone connecting all regional hubs |
| Virtual Hub | 🏢 Regional Airport | Routes and manages local VNets |
| Secured Hub | 🔐 Airport with central security | Adds Azure Firewall / NVA for inspection |
| Routing Intent | 🧭 Airport signs | Directs traffic to security or express lane |

---

## 🏗️ Overall Architecture Preview
```mermaid
flowchart LR
  VWAN[Azure Virtual WAN (Global Backbone)]
  HUB[Virtual Hub (East US)]
  A[Dept A – Strict Security]
  B[Dept B – Balanced]
  C[Dept C – Performance]
  FW[Azure Firewall / NVA]

  VWAN --> HUB --> FW
  HUB <--> A
  HUB <--> B
  HUB <--> C
  A -->|All traffic via FW| FW
  B -->|Internet via FW| FW
  B -->|Private Direct| HUB
  C -->|Private Direct| HUB
```

---

🧰 Tools & Conventions
Azure CLI + Portal for hands-on steps

nano for editing files

Mermaid diagrams for visual understanding

Bicep templates (in /bicep) for reproducible deploys

Cleanup scripts to control costs

💵 Free-Tier Guideline
Each lab ends with a cleanup block:

bash
Copy code
az group delete -n clab-dev-rg --yes --no-wait
Only keep resources alive while testing.

🚀 Begin the Course
➡ Start with Day 1 – Foundations & Prereqs
