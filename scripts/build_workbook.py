"""Builds dashboards/operations-workbook.json (Azure Monitor workbook format) from
the panel list below. Run after editing a panel: python scripts/build_workbook.py"""
import json
from pathlib import Path

PANELS = [
    ("Hosts", None, None),
    ("Agent heartbeat by VM (last 24h)", "table", """Heartbeat
| where TimeGenerated > ago(24h)
| summarize LastHeartbeat = max(TimeGenerated) by Computer, OSType
| extend MinutesSilent = datetime_diff('minute', now(), LastHeartbeat)
| extend State = iff(MinutesSilent > 10, 'Silent', 'OK')
| order by MinutesSilent desc"""),
    ("Lowest free disk space per VM", "table", """InsightsMetrics
| where TimeGenerated > ago(1h)
| where Namespace == 'LogicalDisk' and Name == 'FreeSpacePercentage'
| extend Disk = tostring(parse_json(Tags)['vm.azm.ms/mountId'])
| summarize FreePercent = round(min(Val), 1) by Computer, Disk
| order by FreePercent asc"""),
    ("Backup", None, None),
    ("Backup job outcomes (7 days)", "barchart", """AddonAzureBackupJobs
| where TimeGenerated > ago(7d) and JobOperation in ('Backup', 'Log')
| summarize arg_max(TimeGenerated, *) by JobUniqueId
| summarize Jobs = count() by bin(JobStartDateTime, 1d), JobStatus"""),
    ("Failed backup jobs (24h)", "table", """AddonAzureBackupJobs
| where TimeGenerated > ago(24h) and JobStatus == 'Failed'
| summarize arg_max(TimeGenerated, *) by JobUniqueId
| project JobStartDateTime, JobOperation, JobFailureCode, BackupItemUniqueId
| order by JobStartDateTime desc"""),
    ("Kubernetes", None, None),
    ("Nodes not Ready", "table", """KubeNodeInventory
| where TimeGenerated > ago(15m)
| summarize arg_max(TimeGenerated, Status) by ClusterName, Computer
| where Status != 'Ready'"""),
    ("Container restarts (1h)", "table", """KubePodInventory
| where TimeGenerated > ago(1h) and ContainerRestartCount > 0
| summarize Restarts = max(ContainerRestartCount) - min(ContainerRestartCount) by ClusterName, Namespace, Name
| where Restarts > 0
| order by Restarts desc"""),
    ("Security", None, None),
    ("Key Vault denied requests by caller (24h)", "table", """AzureDiagnostics
| where TimeGenerated > ago(24h)
| where ResourceProvider == 'MICROSOFT.KEYVAULT' and httpStatusCode_d == 403
| summarize Denied = count() by Resource, CallerIPAddress, identity_claim_appid_g
| order by Denied desc"""),
]

items = []
for i, (title, viz, query) in enumerate(PANELS):
    if query is None:
        items.append({"type": 1, "name": f"header-{i}", "content": {"json": f"## {title}"}})
        continue
    items.append({
        "type": 3,
        "name": f"panel-{i}",
        "content": {
            "version": "KqlItem/1.0",
            "title": title,
            "query": query,
            "size": 0,
            "queryType": 0,
            "resourceType": "microsoft.operationalinsights/workspaces",
            "visualization": viz,
        },
    })

workbook = {
    "version": "Notebook/1.0",
    "items": [{"type": 1, "name": "intro", "content": {"json": "# Operations overview\nHost health, backup outcomes, Kubernetes stability, and Key Vault access. Each panel matches an alert in `alerts/alert-catalog.json`."}}] + items,
    "isLocked": False,
    "fallbackResourceIds": [],
}
out = Path(__file__).resolve().parent.parent / "dashboards" / "operations-workbook.json"
out.write_text(json.dumps(workbook, indent=2) + "\n")
print(f"wrote {out.name}: {sum(1 for x in items if x['type'] == 3)} query panels")
