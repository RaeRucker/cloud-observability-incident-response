# Runbook: AKS container restarting repeatedly

Alert: `la-aks-container-restarts` · Severity: 3 · Route: ticket

## What it means

A container restarted more than three times in 30 minutes. The workload may still be serving if other replicas are healthy. The cause is almost always visible in the previous container's logs.

## Triage

```bash
kubectl get pods -n <ns> -o wide
kubectl logs <pod> -n <ns> --previous
kubectl get pod <pod> -n <ns> -o jsonpath='{.status.containerStatuses[0].lastState.terminated}'
```

Exit code 137 with `OOMKilled` means the memory limit was hit. Exit code 137 without it means the liveness probe killed the container. Any other non-zero code is an application error.

## Resolution

Follow the decision tree in the [AKS troubleshooting runbook](https://github.com/RaeRucker/aks-operations-reliability/blob/main/runbooks/troubleshooting-runbook.md#5-container-exits-crashloopbackoff-error-oomkilled). Check `kubectl rollout history` first. Most crash loops follow a deployment or config change, and `rollout undo` plus a config restore is the fastest mitigation.

## Escalation

If every replica of a service is restarting (users affected), raise to Sev 1.
