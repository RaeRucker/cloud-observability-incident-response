# Runbook: SQL log backups stalled

Alert: `la-sql-log-backup-chain-stalled` · Severity: 1 · Route: page · Added after [INC-SIM-0001](../incidents/INC-SIM-0001/incident-report.md)

## What it means

A SQL database protected by Azure Backup (FULL recovery model) has had no successful log backup for 60 minutes. Two risks grow every minute:

1. Data loss window (RPO): point-in-time restore only covers up to the last log backup.
2. Disk exhaustion: the transaction log can't truncate until its contents are backed up, so it keeps growing until the log disk is full. Then the database stops accepting writes (SQL error 9002).

This is a leading indicator. It fires hours before the disk alert would.

## Triage

1. Vault → Backup jobs, filtered to *Log* operations for the database. Read the error.
2. Why can't the log truncate? On the SQL VM: `SELECT name, log_reuse_wait_desc FROM sys.databases;`. `LOG_BACKUP` confirms that missing log backups are what's holding the log.
3. Log disk headroom: check free space on the log volume and the growth rate (see [disk-free-space.md](disk-free-space.md)) to estimate time to full.

## Common causes

| Evidence | Cause |
|---|---|
| Error mentions network, or the job times out | Egress from the VM to the Azure Backup service is blocked (NSG or firewall change) |
| `UserErrorSQLPODoesNotExist` / login errors | The `NT SERVICE\AzureWLBackupPluginSvc` login was removed or lost `sysadmin` |
| `UserErrorParentFullBackupMissing` | Log chain broken by an out-of-band backup or a recovery model change. Run an on-demand full backup. |

## Resolution

Fix the cause, then trigger an on-demand log backup and confirm `log_reuse_wait_desc` returns to `NOTHING`. Don't shrink the log or switch to SIMPLE recovery as a fix. That breaks the log chain and loses point-in-time recovery.

## Escalation

If the log disk will fill within 2 hours, page the DBA immediately and prepare to extend the log disk as a bridge.
