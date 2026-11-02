# Setup guide: daily backup report Logic App

These steps use the Azure portal. Plan on about 20 minutes.

## 1. Create the Logic App

1. In the portal, select Create a resource → Logic App.
2. Plan type: Consumption. One run a day costs a few cents a month.
3. Pick a resource group and region, then Review + create.

## 2. Turn on its managed identity

The Logic App signs in to Azure as itself, so no passwords or secrets are stored anywhere.

1. Open the Logic App → Settings → Identity.
2. Under System assigned, set Status: On → Save.

## 3. Give the identity read access

The identity only needs to read backup data.

1. Go to the subscription (or a management group to cover many subscriptions) → Access control (IAM).
2. Select Add → Add role assignment.
3. Role: `Reader`.
4. Members: *Managed identity* → select your Logic App.
5. Review + assign.

Repeat for each subscription the report should cover.

## 4. Paste in the workflow

1. Open the Logic App → Development Tools → Logic app code view.
2. Replace the contents with [`../logic-app/workflow.json`](../logic-app/workflow.json).
3. Save. The designer will show the Office 365 connection as invalid. That's expected and fixed in the next step.

## 5. Connect Outlook

1. Open the Logic app designer.
2. Select the Send_report action → Change connection → Add new, and sign in with the mailbox that should send the report (a shared or service mailbox is best).
3. Do the same on Send_failure_alert, choosing the connection you just created.
4. Save.

## 6. Set the parameters

In the designer, open Parameters (top toolbar) and set:

| Parameter | Value |
|---|---|
| `subscriptionIds` | `["<sub-id-1>", "<sub-id-2>"]` |
| `reportRecipients` | `team@yourcompany.com; client-it@client.com` (separate addresses with `;`) |
| `failureRecipients` | Your ops or on-call mailbox |
| `reportTitle` | For example `Contoso Daily Azure Backup Report` |

## 7. Test it

1. Select Run trigger → Run.
2. Open the run in Run history. Each step shows green or red, and you can click any step to see its inputs and outputs. This is the fastest way to troubleshoot.
3. Check the inbox.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| A `Query_*` step fails with 403 | The identity doesn't have Reader on that subscription | Step 3 |
| A `Query_*` step returns an empty `data` array | Wrong subscription ID, or nothing is protected there | Run the same query in Resource Graph Explorer to compare |
| Times in the CSV look 4–5 hours off | Times are converted to Eastern | Change `Eastern Standard Time` in the `Select_*_csv` steps to your Windows time zone ID |
| You get two emails each morning | An older copy of the report is still enabled | Disable the old Logic App, and delete it after a few clean runs |
| More than 1,000 protected items | The Resource Graph page limit | Add paging with a `$skipToken` loop, or split the report by subscription |

## Optional: Azure Workbook for a single pane of glass

The same queries power an interactive dashboard:

1. Open Azure Monitor → Workbooks → New.
2. Add → Add query, set Data source: Azure Resource Graph, and choose your subscriptions.
3. Paste a query from [`../queries/resource-graph/`](../queries/resource-graph/), set the visualization (Grid for lists, Tiles for `summary.kql`), and select Done editing.
4. For history beyond 14 days, add a query with Data source: Logs and use the queries in [`../queries/log-analytics/`](../queries/log-analytics/). These need vault Diagnostic settings sending to Log Analytics in Resource specific mode.
5. Save the workbook to a shared resource group so the team can open it.
