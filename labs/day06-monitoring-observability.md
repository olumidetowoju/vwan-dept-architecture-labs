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

🧩 2️⃣ Enable Flow Logs v2 on Dept VNets

Attach diagnostic settings at each subnet level.

for vnet in deptA-vnet deptB-vnet deptC-vnet; do
  az network watcher flow-log create \
    --location $LOCATION \
    --name ${vnet}-flowlog \
    --resource-group $RG \
    --nsg ${vnet}-nsg \
    --storage-account ${PREFIX}${ENV}flowstore \
    --enabled true \
    --format JSON \
    --version 2 \
    --log-analytics-workspace "/subscriptions/$SUB_ID/resourcegroups/$RG/providers/microsoft.operationalinsights/workspaces/$LA_NAME"
done

Verify Flow Logs:

az network watcher flow-log list --location $LOCATION -o table

🧩 3️⃣ Configure Connection Monitor

Use Connection Monitor v2 to validate inter-VNet and on-prem reachability.

az network watcher connection-monitor create \
  --name deptA-to-deptB \
  --resource-group $RG \
  --location $LOCATION \
  --endpoint-source deptA-vm \
  --endpoint-dest deptB-vm \
  --test-groups name=tcpTest,protocol=Tcp,port=443


Start monitoring:

az network watcher connection-monitor start \
  --name deptA-to-deptB -g $RG


Show recent results:

az network watcher connection-monitor query \
  --name deptA-to-deptB -g $RG --output table

🧩 4️⃣ Visualize Metrics in Workbooks

In the Azure Portal:

Navigate to Virtual WAN → Insights

Add tiles for VPN Gateway Throughput and Branch Status

Open Logs → NetworkMetrics
Sample query:

AzureDiagnostics
| where Category == "FlowLog"
| summarize Count = count() by bin(TimeGenerated, 5m), Direction_s
| render timechart


Save as a custom workbook: vWAN Traffic Flow Overview

🧹 Cleanup (Optional)

To stop all diagnostics and minimize costs:
