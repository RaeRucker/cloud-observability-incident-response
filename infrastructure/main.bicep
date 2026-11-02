// Monitoring baseline (resource group scope):
//   - Two action groups by response type: page (on-call) and ticket
//   - Log alerts generated from alerts/alert-catalog.json
//   - Dynamic-threshold CPU metric alert across every VM in the subscription and region
//   - Service Health incident alert
//   - Alert processing rule that suppresses notifications during the weekly
//     maintenance window (alerts still fire and are recorded; only actions are removed)
//   - Operations workbook (dashboards/operations-workbook.json)
//
// Deploy: az deployment group create -g <rg> --template-file infrastructure/main.bicep \
//           --parameters infrastructure/lab.bicepparam

param location string = resourceGroup().location

@description('Resource ID of the Log Analytics workspace that log alerts query.')
param workspaceId string

@description('Recipients for paging alerts (on-call distribution list).')
param pageEmails array

@description('Recipients for ticket-level alerts (team mailbox or ITSM email ingestion address).')
param ticketEmails array

@description('Optional incident-management webhook (for example a PagerDuty Events API v2 integration URL). Treated as a secret.')
@secure()
param pagingWebhookUrl string = ''

@description('Suppress alert notifications in the weekly maintenance window (Sunday 02:00-06:00 UTC).')
param enableMaintenanceSuppression bool = true

param tags object = {
  workload: 'observability'
  managedBy: 'bicep'
}

var catalog = loadJsonContent('../alerts/alert-catalog.json')

resource pageGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'ag-page-oncall'
  location: 'Global'
  tags: tags
  properties: {
    groupShortName: 'page'
    enabled: true
    emailReceivers: [for (email, i) in pageEmails: {
      name: 'page-email-${i}'
      emailAddress: email
      useCommonAlertSchema: true
    }]
    webhookReceivers: empty(pagingWebhookUrl) ? [] : [
      {
        name: 'incident-management'
        serviceUri: pagingWebhookUrl
        useCommonAlertSchema: true
      }
    ]
  }
}

resource ticketGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'ag-ticket'
  location: 'Global'
  tags: tags
  properties: {
    groupShortName: 'ticket'
    enabled: true
    emailReceivers: [for (email, i) in ticketEmails: {
      name: 'ticket-email-${i}'
      emailAddress: email
      useCommonAlertSchema: true
    }]
  }
}

// Paging alerts also create a ticket, so every page leaves a record.
var routes = {
  page: [
    pageGroup.id
    ticketGroup.id
  ]
  ticket: [
    ticketGroup.id
  ]
  none: []
}

resource logAlerts 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = [for a in catalog.logAlerts: {
  name: 'la-${a.id}'
  location: location
  tags: union(tags, {
    runbook: a.runbook
    route: a.route
  })
  properties: {
    displayName: a.displayName
    description: '${a.description} Runbook: ${a.runbook}'
    severity: a.severity
    enabled: true
    scopes: [
      workspaceId
    ]
    evaluationFrequency: a.frequency
    windowSize: a.window
    autoMitigate: a.autoMitigate
    muteActionsDuration: a.autoMitigate ? null : a.muteActionsDuration
    criteria: {
      allOf: [
        {
          query: a.query
          timeAggregation: a.timeAggregation
          metricMeasureColumn: a.timeAggregation == 'Count' ? null : a.metricMeasureColumn
          operator: a.operator
          threshold: a.threshold
          dimensions: [for d in a.dimensions: {
            name: d
            operator: 'Include'
            values: [
              '*'
            ]
          }]
          failingPeriods: {
            numberOfEvaluationPeriods: a.evaluationPeriods
            minFailingPeriodsToAlert: a.minFailingPeriods
          }
        }
      ]
    }
    actions: {
      actionGroups: routes[a.route]
      customProperties: {
        runbook: a.runbook
        catalogEntry: a.id
      }
    }
  }
}]

// Dynamic thresholds learn each VM's normal CPU pattern, which avoids a single
// static number that is noisy for batch servers and blind for idle ones.
resource vmCpuAnomaly 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'ma-vm-cpu-anomaly'
  location: 'global'
  tags: union(tags, {
    runbook: 'runbooks/vm-cpu-anomaly.md'
    route: 'ticket'
  })
  properties: {
    description: 'VM CPU significantly above its learned baseline for 3 of the last 4 five-minute periods. Runbook: runbooks/vm-cpu-anomaly.md'
    severity: 3
    enabled: true
    scopes: [
      subscription().id
    ]
    targetResourceType: 'Microsoft.Compute/virtualMachines'
    targetResourceRegion: location
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    autoMitigate: true
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          criterionType: 'DynamicThresholdCriterion'
          name: 'cpu-above-baseline'
          metricNamespace: 'Microsoft.Compute/virtualMachines'
          metricName: 'Percentage CPU'
          operator: 'GreaterThan'
          alertSensitivity: 'Medium'
          timeAggregation: 'Average'
          failingPeriods: {
            numberOfEvaluationPeriods: 4
            minFailingPeriodsToAlert: 3
          }
        }
      ]
    }
    actions: [
      {
        actionGroupId: ticketGroup.id
      }
    ]
  }
}

resource serviceHealth 'Microsoft.Insights/activityLogAlerts@2020-10-01' = {
  name: 'al-service-health-incident'
  location: 'Global'
  tags: union(tags, {
    runbook: 'runbooks/service-health-incident.md'
    route: 'page'
  })
  properties: {
    description: 'Azure has declared a service incident affecting this subscription. Runbook: runbooks/service-health-incident.md'
    enabled: true
    scopes: [
      subscription().id
    ]
    condition: {
      allOf: [
        {
          field: 'category'
          equals: 'ServiceHealth'
        }
        {
          field: 'properties.incidentType'
          equals: 'Incident'
        }
      ]
    }
    actions: {
      actionGroups: [
        {
          actionGroupId: pageGroup.id
        }
        {
          actionGroupId: ticketGroup.id
        }
      ]
    }
  }
}

// Planned maintenance (patching, AKS node-image upgrades) causes expected restarts
// and brief heartbeat gaps. Suppressing notifications in that window removes
// predictable noise. Alerts still fire and remain visible in Azure Monitor.
resource maintenanceSuppression 'Microsoft.AlertsManagement/actionRules@2021-08-08' = if (enableMaintenanceSuppression) {
  name: 'apr-maintenance-window'
  location: 'Global'
  tags: tags
  properties: {
    description: 'Remove notifications (not alerts) during the Sunday 02:00-06:00 UTC maintenance window.'
    enabled: true
    scopes: [
      resourceGroup().id
      subscription().id
    ]
    schedule: {
      timeZone: 'UTC'
      recurrences: [
        {
          recurrenceType: 'Weekly'
          daysOfWeek: [
            'Sunday'
          ]
          startTime: '02:00:00'
          endTime: '06:00:00'
        }
      ]
    }
    actions: [
      {
        actionType: 'RemoveAllActionGroups'
      }
    ]
  }
}

resource workbook 'Microsoft.Insights/workbooks@2023-06-01' = {
  name: guid(resourceGroup().id, 'operations-workbook')
  location: location
  tags: tags
  kind: 'shared'
  properties: {
    displayName: 'Operations overview'
    category: 'workbook'
    sourceId: workspaceId
    serializedData: loadTextContent('../dashboards/operations-workbook.json')
  }
}

output pageActionGroupId string = pageGroup.id
output ticketActionGroupId string = ticketGroup.id
output logAlertNames array = [for (a, i) in catalog.logAlerts: logAlerts[i].name]
