# Runbook: AKS node not ready

Alert: `la-aks-node-not-ready` · Severity: 1 · Route: page

## What it means

A node reported a status other than Ready for 10 minutes. Pods on it stop being managed. After about 5 minutes of `Unknown`, Kubernetes evicts and reschedules them.

## Triage

1. `kubectl get nodes` and `kubectl describe node <node>`. `Unknown` means the kubelet can't be reached (VM down or network). `False` with pressure conditions means the node is up but unhealthy.
2. Check AKS Diagnose and solve problems → Node health, and the VMSS instance's Resource health.
3. Confirm workloads recovered: `kubectl get pods -A -o wide | grep -v Running`.

## Resolution

Prefer AKS auto-repair (it acts on nodes NotReady for more than 10 minutes) and the cluster autoscaler. If a node is stuck, `az aks nodepool delete-machines` (or cordon, drain, and scale) replaces it cleanly. Detailed walkthrough: [aks-operations-reliability, Scenario 06](https://github.com/RaeRucker/aks-operations-reliability/blob/main/scenarios/06-node-not-ready/README.md).

## Escalation

More than one node NotReady at once, or the system pool affected: raise to Sev 0. Open an Azure support case if the cause is platform-side.
