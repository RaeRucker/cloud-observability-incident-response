using 'main.bicep'

// Workspace from the landing zone (rg-<prefix>-<env>-platform) or any existing workspace.
param workspaceId = '/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/rg-contoso-dev-platform/providers/Microsoft.OperationalInsights/workspaces/law-contoso-dev'
param pageEmails = [
  'oncall@example.com'
]
param ticketEmails = [
  'ops-tickets@example.com'
]
// Supply at deploy time, never in this file:
//   --parameters pagingWebhookUrl="$PAGING_WEBHOOK_URL"
param enableMaintenanceSuppression = true
