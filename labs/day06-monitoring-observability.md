# 📊 Day 6 – Monitoring & Observability

In this module, you’ll enable visibility into your Virtual WAN environment — viewing health, logs, and connection analy>

---

## 🎯 Objectives

By the end of this lab you will:

1. Enable **vWAN Insights** to monitor hubs and connections
2. Configure **Network Watcher** and **Connection Monitor**
3. Enable **Flow Logs v2** on critical subnets
4. Visualize network flow data in **Azure Monitor Workbooks**

---

## 🧠 Concept Recap

| Component | Purpose |
|------------|----------|
| **vWAN Insights** | Native dashboard showing hub health, link throughput, latency, and branch status |
| **Flow Logs v2** | Captures traffic metadata at NSG/subnet level |
| **Connection Monitor** | Tests end-to-end reachability between resources |
| **Workbooks / Log Analytics** | Visual dashboards for trend visualization and troubleshooting |

---
🖼️ Diagram – Monitoring Flow
```mermaid
sequenceDiagram
    participant DeptA as Dept A VNet
    participant DeptB as Dept B VNet
    participant Hub as Virtual WAN Hub
    participant LA as Log Analytics Workspace
    participant CM as Connection Monitor
    participant User as You (Olumide)

    DeptA->>Hub: Send metrics, flow logs (JSON v2)
    DeptB->>Hub: Send metrics, flow logs (JSON v2)
    Hub->>LA: Push diagnostic & telemetry streams
    Hub->>CM: Trigger reachability tests (TCP 443)
    CM-->>Hub: Return status = Connected/Failed
    LA-->>User: Aggregate data into Insights & Workbooks
    User->>LA: Query AzureDiagnostics in Kusto
    User-->>Hub: Adjust routing or NSG based on metrics
```

---

