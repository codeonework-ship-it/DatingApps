package observability

import (
	"encoding/json"
	"os"
	"strings"
	"testing"
)

func TestReliabilityDashboardAndAlertsAreProvisionable(t *testing.T) {
	dashboardBytes, err := os.ReadFile("../../../observability/grafana/dashboards/api/reliability-10m.json")
	if err != nil {
		t.Fatal(err)
	}
	var dashboard struct {
		UID    string `json:"uid"`
		Panels []struct {
			Title   string `json:"title"`
			Targets []struct {
				Expression string `json:"expr"`
			} `json:"targets"`
		} `json:"panels"`
	}
	if err := json.Unmarshal(dashboardBytes, &dashboard); err != nil {
		t.Fatalf("dashboard is not valid JSON: %v", err)
	}
	if dashboard.UID != "verified-dating-reliability" || len(dashboard.Panels) < 7 {
		t.Fatalf("dashboard must retain its stable UID and core panels: uid=%q panels=%d", dashboard.UID, len(dashboard.Panels))
	}
	joined := string(dashboardBytes)
	for _, metric := range []string{
		"verified_dating_http_request_duration_seconds_bucket",
		"verified_dating_reliability_request_timeouts_total",
		"verified_dating_reliability_requests_shed_total",
		"verified_dating_reliability_idempotency_replays_total",
		"verified_dating_reliability_idempotency_conflicts_total",
		"verified_dating_reliability_idempotency_expired_leases",
		"verified_dating_reliability_postgres_in_use_connections",
		"verified_dating_notification_oldest_pending_age_seconds",
	} {
		if !strings.Contains(joined, metric) {
			t.Fatalf("dashboard missing required metric %s", metric)
		}
	}

	alerts, err := os.ReadFile("../../../observability/prometheus/rules/reliability-10m.yml")
	if err != nil {
		t.Fatal(err)
	}
	alertText := string(alerts)
	for _, alert := range []string{
		"VerifiedDatingHTTPP99LatencyHigh",
		"VerifiedDatingHTTPErrorBudgetBurn",
		"VerifiedDatingRequestTimeoutRateHigh",
		"VerifiedDatingBulkheadShedding",
		"VerifiedDatingNotificationQueueLagHigh",
		"VerifiedDatingPostgresDeadlocks",
		"VerifiedDatingIdempotencyExpiredLeases",
		"VerifiedDatingIdempotencyRetentionBacklog",
		"VerifiedDatingPostgresPoolSaturation",
	} {
		if !strings.Contains(alertText, "alert: "+alert) {
			t.Fatalf("alert rules missing %s", alert)
		}
	}
	if strings.Count(alertText, "runbook_url:") < 8 {
		t.Fatal("every reliability alert must link to a runbook")
	}

	provisioning, err := os.ReadFile("../../../observability/grafana/provisioning/dashboards/connect.yml")
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(provisioning), "${GRAFANA_DASHBOARDS_DIR}/api") {
		t.Fatal("Grafana provisioning must load the installed per-folder dashboard directories")
	}

	datasource, err := os.ReadFile("../../../observability/grafana/provisioning/datasources/prometheus.yml")
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(datasource), "${PROMETHEUS_URL}") {
		t.Fatal("Grafana datasource must be environment-provisionable")
	}

	alertmanager, err := os.ReadFile("../../../observability/alertmanager/alertmanager.yml.tmpl")
	if err != nil {
		t.Fatal(err)
	}
	alertmanagerText := string(alertmanager)
	for _, required := range []string{"severity=\"page\"", "oncall-page", "${ALERTMANAGER_PAGE_WEBHOOK_URL}", "${ALERTMANAGER_TICKET_WEBHOOK_URL}"} {
		if !strings.Contains(alertmanagerText, required) {
			t.Fatalf("Alertmanager paging template missing %s", required)
		}
	}
}
