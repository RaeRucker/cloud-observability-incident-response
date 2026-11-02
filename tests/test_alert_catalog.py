"""
Enforces the rules in docs/alert-design.md against alerts/alert-catalog.json,
and checks that the compiled Bicep and the workbook are consistent with it.

Run: pytest -v tests/   (the compiled-template test needs the Bicep CLI on PATH)
"""
import json
import re
import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parent.parent
CATALOG = json.loads((ROOT / "alerts" / "alert-catalog.json").read_text())
ALERTS = CATALOG["logAlerts"]
IDS = [a["id"] for a in ALERTS]

KNOWN_TABLES = {"Heartbeat", "InsightsMetrics", "AddonAzureBackupJobs", "KubeNodeInventory", "KubePodInventory", "AzureDiagnostics"}
ROUTE_FOR_SEVERITY = {0: "page", 1: "page", 2: "ticket", 3: "ticket", 4: "none"}


def iso_minutes(duration: str) -> int:
    m = re.fullmatch(r"PT(?:(\d+)H)?(?:(\d+)M)?", duration)
    assert m, f"unsupported ISO 8601 duration {duration}"
    return int(m.group(1) or 0) * 60 + int(m.group(2) or 0)


def test_ids_are_unique_and_kebab_case():
    assert len(IDS) == len(set(IDS))
    for i in IDS:
        assert re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*", i), i


@pytest.mark.parametrize("alert", ALERTS, ids=IDS)
class TestAlertRules:
    def test_route_matches_severity(self, alert):
        assert alert["route"] == ROUTE_FOR_SEVERITY[alert["severity"]]

    def test_runbook_exists_and_names_the_alert(self, alert):
        path = ROOT / alert["runbook"]
        assert path.is_file(), f"missing runbook {alert['runbook']}"
        assert f"la-{alert['id']}" in path.read_text(), "runbook must reference the deployed alert name"

    def test_window_covers_evaluation_frequency(self, alert):
        assert iso_minutes(alert["window"]) >= iso_minutes(alert["frequency"])

    def test_queries_a_known_table(self, alert):
        first_token = alert["query"].split("\n", 1)[0].strip()
        assert first_token in KNOWN_TABLES

    def test_dimensions_exist_in_query(self, alert):
        for d in alert["dimensions"]:
            assert re.search(rf"\b{re.escape(d)}\b", alert["query"]), f"dimension {d} is not produced by the query"

    def test_measure_column_consistent_with_aggregation(self, alert):
        if alert["timeAggregation"] == "Count":
            assert "metricMeasureColumn" not in alert
        else:
            col = alert.get("metricMeasureColumn")
            assert col and col in alert["query"]

    def test_failing_periods_are_valid(self, alert):
        assert 1 <= alert["minFailingPeriods"] <= alert["evaluationPeriods"] <= 6

    def test_non_resolving_alerts_are_muted(self, alert):
        if not alert["autoMitigate"]:
            assert "muteActionsDuration" in alert, "an alert that never auto-resolves must mute repeats"

    def test_description_is_specific(self, alert):
        assert len(alert["description"]) >= 60


def test_paging_alerts_require_corroboration_or_are_leading_indicators():
    """A page on a single sample should be rare; each one must be justified by a short window."""
    for a in ALERTS:
        if a["route"] == "page" and a["minFailingPeriods"] == 1:
            assert iso_minutes(a["frequency"]) <= 15, a["id"]


def test_incident_follow_up_alert_exists():
    assert any(a.get("addedBy") == "INC-SIM-0001" for a in ALERTS)


def test_workbook_is_valid_and_has_query_panels():
    wb = json.loads((ROOT / "dashboards" / "operations-workbook.json").read_text())
    assert wb["version"] == "Notebook/1.0"
    panels = [i for i in wb["items"] if i["type"] == 3]
    assert len(panels) >= 6
    for p in panels:
        assert p["content"]["query"].split("\n", 1)[0].strip() in KNOWN_TABLES


@pytest.mark.skipif(not shutil.which("bicep"), reason="Bicep CLI not installed")
def test_compiled_template_deploys_every_catalog_alert(tmp_path):
    out = tmp_path / "main.json"
    subprocess.run(["bicep", "build", str(ROOT / "infrastructure" / "main.bicep"), "--outfile", str(out)], check=True)
    template = json.loads(out.read_text())
    resources = template["resources"]
    resources = resources.values() if isinstance(resources, dict) else resources
    rule = next(r for r in resources if r["type"] == "Microsoft.Insights/scheduledQueryRules")
    assert "copy" in rule, "log alerts must be generated from the catalog"
    assert "logAlerts" in json.dumps(rule["copy"])
    assert any(r["type"] == "Microsoft.AlertsManagement/actionRules" for r in resources)
