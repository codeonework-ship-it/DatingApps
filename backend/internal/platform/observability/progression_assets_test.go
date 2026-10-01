package observability

import (
	"encoding/json"
	"os"
	"strings"
	"testing"

	"github.com/prometheus/client_golang/prometheus"
)

func TestProgressionProductionMetricsDashboardAndAlerts(t *testing.T) {
	registry := prometheus.NewRegistry()
	NewBFFMetrics(registry)
	families, err := registry.Gather()
	if err != nil {
		t.Fatal(err)
	}
	names := map[string]bool{}
	for _, family := range families {
		names[family.GetName()] = true
	}
	for _, name := range []string{
		"verified_dating_progression_projection_queue_depth",
		"verified_dating_progression_projection_processing",
		"verified_dating_progression_projection_dead_letters",
		"verified_dating_progression_projection_oldest_pending_age_seconds",
		"verified_dating_progression_projection_completion_p95_seconds",
		"verified_dating_progression_open_fraud_cases",
		"verified_dating_progression_cap_denials_15m",
	} {
		if !names[name] {
			t.Fatalf("progression collector missing %s", name)
		}
	}

	dashboardBytes, err := os.ReadFile("../../../observability/grafana/dashboards/product/progression-production.json")
	if err != nil {
		t.Fatal(err)
	}
	var dashboard struct {
		UID    string `json:"uid"`
		Panels []any  `json:"panels"`
	}
	if err = json.Unmarshal(dashboardBytes, &dashboard); err != nil {
		t.Fatalf("progression dashboard is invalid JSON: %v", err)
	}
	if dashboard.UID != "verified-dating-progression" || len(dashboard.Panels) != 7 {
		t.Fatalf("unexpected progression dashboard: uid=%q panels=%d", dashboard.UID, len(dashboard.Panels))
	}
	joined := string(dashboardBytes)
	for name := range names {
		if strings.HasPrefix(name, "verified_dating_progression_") && !strings.Contains(joined, name) {
			t.Fatalf("dashboard missing progression metric %s", name)
		}
	}

	alerts, err := os.ReadFile("../../../observability/prometheus/rules/progression-production.yml")
	if err != nil {
		t.Fatal(err)
	}
	alertText := string(alerts)
	for _, alert := range []string{
		"VerifiedDatingProgressionProjectionLagHigh",
		"VerifiedDatingProgressionQueueDepthHigh",
		"VerifiedDatingProgressionCompletionP95High",
		"VerifiedDatingProgressionDeadLetters",
		"VerifiedDatingProgressionCriticalFraudQueue",
		"VerifiedDatingProgressionCapDenialSpike",
	} {
		if !strings.Contains(alertText, "alert: "+alert) {
			t.Fatalf("progression alert rules missing %s", alert)
		}
	}
	if strings.Count(alertText, "runbook_url:") != 6 || !strings.Contains(alertText, "owner: progression-oncall") || !strings.Contains(alertText, "owner: trust-safety-oncall") {
		t.Fatal("progression alerts must identify an owner and runbook")
	}
}
