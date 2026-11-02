# Runbook: Azure Service Health incident

Alert: `al-service-health-incident` · Route: page

## What it means

Microsoft declared an incident for a service and region your subscription uses. Your resources may or may not be affected.

## Triage

1. Read the incident in Service Health → Service issues: affected services, regions, and the *Potential impact* tab listing your resources.
2. Check whether your own alerts or users confirm impact. Many incidents affect a small fraction of resources.
3. Note the tracking ID for status updates and post-incident reports.

## Response

- No impact: monitor the incident updates; no action.
- Impact on a single-region workload: decide on failover using the DR runbook ([azure-disaster-recovery-engineering](https://github.com/RaeRucker/azure-disaster-recovery-engineering)). The decision belongs to the incident commander and business owner, not to whoever was paged first.
- Communicate: tell stakeholders what's affected, that it's a platform incident (with the tracking ID), and when the next update will come.

## After

Download the Post Incident Review from Service Health (published within about 14 days) and attach it to your own incident record.
