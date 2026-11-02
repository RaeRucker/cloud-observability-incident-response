# Runbook: Azure Backup job failed

Alert: `la-backup-job-failed` · Severity: 2 · Route: ticket · Notifications muted 6 h per item after firing

## What it means

A backup job for one protected item failed. A single failure is a gap in the recovery points. Repeated failures mean the item is drifting outside its RPO.

## Triage

1. Open the vault: Backup jobs → filter Failed and read Error code and Recommended action. These are usually specific.
2. Check whether other items are failing at the same time (the workbook panel *Failed backup jobs (24h)*). Many items failing together points to a shared dependency (network egress, vault, extension rollout). One item points to that VM.

## Common error codes

| Code | Meaning | Action |
|---|---|---|
| `UserErrorGuestAgentStatusUnavailable` | VM agent not responding | Restart the `WindowsAzureGuestAgent` service; check that the VM is running |
| `ExtensionSnapshotFailedNoNetwork` / `UserErrorBcmDatasourceNotPresent` | Snapshot extension can't reach Azure | Check NSG/firewall egress to the `AzureBackup`, `Storage`, and `AzureActiveDirectory` service tags |
| `UserErrorVmNotInDesirableState` | VM state transition in progress | Retry after the operation completes |
| `UserErrorSQLLogBackupFailed` / log backup errors | SQL workload backup issue | Follow [sql-log-backup-chain-stalled.md](sql-log-backup-chain-stalled.md) |

## Resolution and verification

Fix the cause, then Backup now on the item and confirm the job completes. A failure without a successful retry isn't resolved. This alert does not auto-resolve (`autoMitigate: false`), so close it manually once a job succeeds.

## Escalation

Two consecutive daily failures for a Tier 1 item, or any failure affecting more than five items: raise to Sev 1 and page.
