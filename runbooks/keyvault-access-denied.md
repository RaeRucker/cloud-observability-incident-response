# Runbook: Key Vault access denied spike

Alert: `la-keyvault-access-denied-spike` · Severity: 3 · Route: ticket

## What it means

One caller received more than 20 `403 Forbidden` responses from a vault in 15 minutes. The two explanations need very different responses:

- Misconfiguration (common): an application's identity lost its role, or a new deployment uses a different identity.
- Probing (rare, serious): something is enumerating secrets it shouldn't have access to.

## Triage

```kusto
AzureDiagnostics
| where TimeGenerated > ago(1h)
| where ResourceProvider == 'MICROSOFT.KEYVAULT' and httpStatusCode_d == 403
| project TimeGenerated, Resource, OperationName, CallerIPAddress, identity_claim_appid_g, identity_claim_upn_s, requestUri_s
| order by TimeGenerated desc
```

1. Known identity? Look up the app ID: `az ad sp show --id <appid> --query displayName`. If it's a known workload, check whether its role assignment changed recently (Activity Log, `Microsoft.Authorization/roleAssignments/delete`).
2. Operations requested: repeated `SecretGet` on the same secret suggests an app retry loop. `SecretList` across many names suggests enumeration.
3. Source IP: internal (private endpoint or VNet) vs unexpected public address.

## Resolution

Misconfiguration: restore the correct role assignment (*Key Vault Secrets User*) through IaC, not by hand. Suspected probing: treat it as a security incident. Disable or rotate the calling identity's credentials, preserve the logs, and escalate to security.

## Escalation

Unknown identity or unexpected source IP: escalate to the security team immediately (Sev 1).
