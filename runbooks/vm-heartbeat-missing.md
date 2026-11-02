# Runbook: VM stopped sending heartbeats

Alert: `la-vm-heartbeat-missing` · Severity: 1 · Route: page

## What it means

The Azure Monitor Agent on a VM sent a heartbeat within the last hour but not in the last 10 minutes. This is a *monitoring* signal: the VM may be down, or the VM may be fine and only the agent or its network path is broken. The first job is to tell those apart.

## Triage (first 5 minutes)

1. Is the VM running? Portal: VM → Overview (power state) and Resource health. Or `az vm get-instance-view -g <rg> -n <vm> --query "instanceView.statuses[].displayStatus"`.
2. Is the service on it reachable? Test the application endpoint (HTTP check, SQL port). If users are affected, raise to Sev 0 and follow the incident process.
3. Planned work? Check the change calendar and the Activity Log for the VM (restart, resize, extension update). The maintenance-window processing rule only covers Sunday 02:00-06:00 UTC.

## Common causes

| Evidence | Cause | Action |
|---|---|---|
| VM stopped or deallocated | Shutdown, auto-shutdown schedule, Spot eviction | Start the VM if it should be running, and find out who or what stopped it (Activity Log) |
| VM running, Resource health *Unavailable* | Host or platform issue | Follow [service-health-incident.md](service-health-incident.md); Azure usually heals or redeploys |
| VM running and app reachable, no heartbeat | Agent stopped, DCR association removed, outbound to `*.ods.opinsights.azure.com` blocked | Check the `AzureMonitorWindowsAgent` / `azuremonitoragent` service; check NSG/firewall egress; check the VM's DCR associations |
| Boot diagnostics show a stuck boot or a BSOD | Guest OS failure | Use Serial Console; restore from backup if the OS is unrecoverable |

## Known limitation

The alert's query window is 1 hour. A VM silent for more than an hour drops out of the results, and the alert auto-resolves even though nothing recovered. Treat an auto-resolve without a confirmed fix as unresolved. A future improvement is pairing this alert with the platform VM availability metric.

## Escalation

If the VM is unavailable and the cause isn't found within 30 minutes, escalate to the platform team lead. Open an Azure support case if Resource health reports a platform problem.
