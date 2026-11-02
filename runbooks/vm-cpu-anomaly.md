# Runbook: VM CPU above learned baseline

Alert: `ma-vm-cpu-anomaly` · Severity: 3 · Route: ticket · Dynamic threshold, 3 of 4 five-minute periods

## What it means

A VM's CPU is significantly higher than its own learned pattern. A batch server at 90% every night won't fire. An idle server suddenly at 60% will. High CPU is a symptom; the useful question is *which process, and since when*.

## Triage

1. Process: on the VM, `Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 Name, Id, CPU, WS` (Windows) or `top -o %CPU` (Linux).
2. Correlate: a deployment, a scheduled task, antivirus scan timing, or a traffic increase (application metrics).
3. Impact: is response time affected? If not, this can wait for business hours.

## Common causes

Antivirus full scans, runaway application threads, Windows Update or .NET NGEN after patching, and cryptomining on a compromised host. For the last one, look for unknown processes or outbound connections, and treat as a security incident.

## Escalation

Unknown process with outbound network activity: escalate to security.
