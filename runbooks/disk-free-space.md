# Runbook: Disk free space low (below 10%) / critical (below 5%)

Alerts: `la-disk-free-low` (Sev 2, ticket) · `la-disk-free-critical` (Sev 1, page)

## What it means

A logical disk's minimum free space dropped below the threshold. Running out of space breaks writes: SQL Server stops (error 9002 on a full log), IIS stops logging, Windows Update fails. The question is not only "what can I delete" but why is it growing.

## Triage

1. Rate of growth: run the workbook panel *Lowest free disk space per VM*, or:

   ```kusto
   InsightsMetrics
   | where TimeGenerated > ago(24h) and Computer == '<vm>'
   | where Namespace == 'LogicalDisk' and Name == 'FreeSpacePercentage'
   | extend Disk = tostring(parse_json(Tags)['vm.azm.ms/mountId'])
   | summarize FreePercent = min(Val) by bin(TimeGenerated, 15m), Disk
   | render timechart
   ```

   A steady slope means something is writing continuously, and the trend tells you how long you have. A step change means a single large write (a dump file, an upgrade, a restore).

2. What is growing? On the VM: `Get-ChildItem <drive>:\ -Directory | ForEach-Object { [pscustomobject]@{ Path = $_.FullName; GB = [math]::Round((Get-ChildItem $_.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum / 1GB, 1) } } | Sort-Object GB -Descending | Select-Object -First 10`. Tools like WizTree are faster on large volumes.

## Common causes

| Finding | Root cause to look for |
|---|---|
| SQL `.ldf` transaction log growing | Log backups not running or failing, so the log can't truncate. Check [sql-log-backup-chain-stalled.md](sql-log-backup-chain-stalled.md). See [INC-SIM-0001](../incidents/INC-SIM-0001/incident-report.md). |
| `C:\Windows\SoftwareDistribution`, WinSxS | Update cache. `DISM /Online /Cleanup-Image /StartComponentCleanup` |
| IIS or application logs | No log rotation configured |
| Memory dumps (`*.dmp`) | A crashing process. The crash is the real issue. |

## Resolution

Free space safely first (move or compress logs, clear caches). Never delete database files. Extend the disk if the growth is legitimate: Disk → Size + performance, then extend the volume in Disk Management. Then fix the cause.

## Escalation

Critical (below 5%) on a database or domain controller volume: page the DBA or the identity owner immediately.
