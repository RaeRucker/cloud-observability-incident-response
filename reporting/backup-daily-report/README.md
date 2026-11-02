# Daily Azure Backup Report (Logic App)

A Logic App that emails a daily Azure Backup health report at 6:00 AM Eastern. It runs in production. [`logic-app/workflow.json`](logic-app/workflow.json) is the workflow definition exported from code view, with identifying details removed (see [Sanitization](#sanitization)).

## Background

The built-in Azure Backup report email gives you charts and CSVs, but it doesn't answer the questions leadership and engineers actually ask: is everything protected, what failed, is each vault configured the way it should be, and are the databases covered. I started from Microsoft's [Azure Backup report email template](https://aka.ms/AzureBackupReportEmail) and built a custom report on top of it: my own HTML layout, plus new sections that query Azure Resource Graph and the ARM API directly with a managed identity.

## What's in the email

| # | Section | Source |
|---|---|---|
| 01 | Executive summary: protected, failed, and stale items by workload type | Log Analytics (Backup Reports functions) + Resource Graph |
| 02 | Failed backup jobs, or a "no failed jobs" line | Log Analytics |
| 03 | Backup policy assignments: which systems are on each policy, with policy settings | Resource Graph |
| 04 | Vault health: redundancy, immutability, soft delete, cross-region restore, and missing tier policies per vault | Resource Graph |
| 05 | Database backups: PostgreSQL (Backup vault) and Azure SQL short-term and long-term retention | Resource Graph + ARM API |
| 06 | Backup storage trend chart per vault | Log Analytics |
| 07 | Month-to-date storage growth per vault, in GB | Log Analytics |

CSV attachments: `JobList`, `PolicyAssignments`, `BackupInstanceList`, `PoliciesList`, `BillingGroupList`, policy adherence (daily and weekly), and optimization lists (inactive resources, retention, backup schedule).

If the core report scopes fail, a separate failure email goes to the operations mailbox instead.

## How it works

```text
Recurrence (daily, 6:00 AM Eastern)
  │
  ├─ Scope 1-3   Microsoft Backup Reports KQL functions → Log Analytics
  │              (jobs, backup instances, billing groups, policies,
  │               adherence, optimization grids, trend charts)
  ├─ Scope 4     Resource Graph (HTTP + managed identity)
  │              policy assignments → per-policy HTML blocks
  ├─ Scope 5     Resource Graph: PostgreSQL backup instances
  │              ARM API per SQL database: short- and long-term retention
  ├─ Scope 6     Executive summary: KPIs + estate counts (Recovery Services
  │              vaults, Backup vaults, SQL), stale = source resource deleted
  ├─ Scope 7     Vault health: settings per vault, compares each vault's
  │              policies against the expected "Tier-*" VM policy set
  ├─ Scope 8     Month-to-date storage change per vault
  │
  └─ If any core scope failed ──► failure email to ops mailbox
     else ──► build HTML ──► Graph: create draft message with
              attachments (Office 365 connector) ──► send draft
```

Design choices:

- The email is sent through Microsoft Graph (create a draft, then send it) rather than the plain "Send an email" action. Graph supports file attachments and inline chart images in the same message.
- Resource Graph and ARM calls use the Logic App's system-assigned managed identity. There are no stored credentials.
- A resource is "stale" when its backup item still exists but the source resource doesn't, which catches deleted VMs and databases that are still being billed for backup storage.
- Vault health flags a vault if it's missing any of the tier policies (`Tier-*`) that exist elsewhere, so policy drift between vaults shows up in the report.

## Requirements

- Recovery Services vault and Backup vault diagnostic settings sending to a Log Analytics workspace, using resource-specific tables (`AddonAzureBackup*`).
- The Logic App's managed identity has the Reader role on each subscription in scope (Resource Graph and SQL retention APIs).
- An Azure Monitor Logs API connection with read access to the workspace.
- An Office 365 Outlook API connection signed in as the mailbox that sends the report.

## Setup

1. Create a Consumption Logic App and turn on its system-assigned managed identity (Identity, then System assigned, then On).
2. Give that identity the Reader role on each subscription you want in the report (Subscription, then Access control (IAM), then Add role assignment).
3. Open the Logic App in code view and paste in `workflow.json`.
4. In the designer, fix the two connections (Azure Monitor Logs and Office 365 Outlook) so they point at connections in your environment.
5. Set the `workspacesToQuery` parameter to your Log Analytics workspace resource ID.
6. Replace the placeholder recipients (`contoso.com`) in the `Compose` action and the failure email.
7. Run the trigger manually and check the email before relying on the schedule.

## Sanitization

Removed or replaced compared with the production export:

- Subscription ID (replaced with zeros), resource group, workspace, and Logic App connection names
- All recipient addresses (replaced with `contoso.com` placeholders) and named individuals on CC
- Company and client names in the subject, header, and footer, and the embedded company logo

The logic, queries, and layout are unchanged.

## Known limitations

- The failure check only looks at the first three scopes. If Scope 4-8 fails, the report still sends with those sections empty or using fallback content. Extending the condition to cover every scope is the next improvement.
- The Microsoft Backup Reports functions make up most of the file's size. They're kept as-is so the template can be updated from Microsoft's version.
