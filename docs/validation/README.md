# Local validation results

Actual output, captured on 2026-11-02. No Azure resources were deployed, and no alerts were evaluated against real data.

## Bicep
```text
$ bicep build infrastructure/main.bicep && bicep lint infrastructure/main.bicep && bicep build-params infrastructure/lab.bicepparam
(no errors, no warnings; Bicep 0.48.1)
```

## Alert catalog, workbook, and template tests
```text
$ pytest -v tests/
tests/test_alert_catalog.py::test_ids_are_unique_and_kebab_case PASSED
tests/test_alert_catalog.py::TestAlertRules::test_route_matches_severity[vm-heartbeat-missing] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_route_matches_severity[disk-free-low] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_route_matches_severity[disk-free-critical] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_route_matches_severity[backup-job-failed] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_route_matches_severity[sql-log-backup-chain-stalled] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_route_matches_severity[aks-node-not-ready] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_route_matches_severity[aks-container-restarts] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_route_matches_severity[keyvault-access-denied-spike] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_runbook_exists_and_names_the_alert[vm-heartbeat-missing] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_runbook_exists_and_names_the_alert[disk-free-low] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_runbook_exists_and_names_the_alert[disk-free-critical] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_runbook_exists_and_names_the_alert[backup-job-failed] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_runbook_exists_and_names_the_alert[sql-log-backup-chain-stalled] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_runbook_exists_and_names_the_alert[aks-node-not-ready] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_runbook_exists_and_names_the_alert[aks-container-restarts] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_runbook_exists_and_names_the_alert[keyvault-access-denied-spike] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_window_covers_evaluation_frequency[vm-heartbeat-missing] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_window_covers_evaluation_frequency[disk-free-low] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_window_covers_evaluation_frequency[disk-free-critical] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_window_covers_evaluation_frequency[backup-job-failed] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_window_covers_evaluation_frequency[sql-log-backup-chain-stalled] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_window_covers_evaluation_frequency[aks-node-not-ready] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_window_covers_evaluation_frequency[aks-container-restarts] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_window_covers_evaluation_frequency[keyvault-access-denied-spike] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_queries_a_known_table[vm-heartbeat-missing] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_queries_a_known_table[disk-free-low] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_queries_a_known_table[disk-free-critical] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_queries_a_known_table[backup-job-failed] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_queries_a_known_table[sql-log-backup-chain-stalled] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_queries_a_known_table[aks-node-not-ready] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_queries_a_known_table[aks-container-restarts] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_queries_a_known_table[keyvault-access-denied-spike] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_dimensions_exist_in_query[vm-heartbeat-missing] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_dimensions_exist_in_query[disk-free-low] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_dimensions_exist_in_query[disk-free-critical] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_dimensions_exist_in_query[backup-job-failed] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_dimensions_exist_in_query[sql-log-backup-chain-stalled] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_dimensions_exist_in_query[aks-node-not-ready] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_dimensions_exist_in_query[aks-container-restarts] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_dimensions_exist_in_query[keyvault-access-denied-spike] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_measure_column_consistent_with_aggregation[vm-heartbeat-missing] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_measure_column_consistent_with_aggregation[disk-free-low] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_measure_column_consistent_with_aggregation[disk-free-critical] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_measure_column_consistent_with_aggregation[backup-job-failed] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_measure_column_consistent_with_aggregation[sql-log-backup-chain-stalled] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_measure_column_consistent_with_aggregation[aks-node-not-ready] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_measure_column_consistent_with_aggregation[aks-container-restarts] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_measure_column_consistent_with_aggregation[keyvault-access-denied-spike] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_failing_periods_are_valid[vm-heartbeat-missing] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_failing_periods_are_valid[disk-free-low] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_failing_periods_are_valid[disk-free-critical] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_failing_periods_are_valid[backup-job-failed] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_failing_periods_are_valid[sql-log-backup-chain-stalled] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_failing_periods_are_valid[aks-node-not-ready] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_failing_periods_are_valid[aks-container-restarts] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_failing_periods_are_valid[keyvault-access-denied-spike] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_non_resolving_alerts_are_muted[vm-heartbeat-missing] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_non_resolving_alerts_are_muted[disk-free-low] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_non_resolving_alerts_are_muted[disk-free-critical] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_non_resolving_alerts_are_muted[backup-job-failed] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_non_resolving_alerts_are_muted[sql-log-backup-chain-stalled] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_non_resolving_alerts_are_muted[aks-node-not-ready] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_non_resolving_alerts_are_muted[aks-container-restarts] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_non_resolving_alerts_are_muted[keyvault-access-denied-spike] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_description_is_specific[vm-heartbeat-missing] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_description_is_specific[disk-free-low] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_description_is_specific[disk-free-critical] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_description_is_specific[backup-job-failed] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_description_is_specific[sql-log-backup-chain-stalled] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_description_is_specific[aks-node-not-ready] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_description_is_specific[aks-container-restarts] PASSED
tests/test_alert_catalog.py::TestAlertRules::test_description_is_specific[keyvault-access-denied-spike] PASSED
tests/test_alert_catalog.py::test_paging_alerts_require_corroboration_or_are_leading_indicators PASSED
tests/test_alert_catalog.py::test_incident_follow_up_alert_exists PASSED
tests/test_alert_catalog.py::test_workbook_is_valid_and_has_query_panels PASSED
tests/test_alert_catalog.py::test_compiled_template_deploys_every_catalog_alert PASSED
============================== 77 passed in 1.74s ==============================
```

## Logic App definition
```text
$ python -m json.tool reporting/backup-daily-report/logic-app/workflow.json
(valid JSON)
```

## Not yet validated

| Check | Status |
|---|---|
| Deployment of alerts, action groups, processing rule, and workbook | Not run |
| KQL queries against a populated workspace | Not run. Queries use documented table schemas (Heartbeat, InsightsMetrics, AddonAzureBackupJobs, KubePodInventory, KubeNodeInventory, AzureDiagnostics); field names should be confirmed in a live workspace. |
| Logic App run | Not run in this repository |
| INC-SIM-0001 | Simulated by design; not an executed failure |
