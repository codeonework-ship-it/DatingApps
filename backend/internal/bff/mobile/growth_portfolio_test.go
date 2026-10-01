package mobile

import (
	"testing"
	"time"
)

func TestGrowthPortfolioRoutesAreFailClosed(t *testing.T) {
	t.Parallel()
	cases := map[string]string{
		"/v1/support/tickets":                  "support_ticketing_enabled",
		"/v1/support/tickets/t-1/messages":     "support_ticketing_enabled",
		"/v1/growth/events":                    "growth_events_enabled",
		"/v1/growth/referrals/redeem":          "referrals_enabled",
		"/v1/growth/partnerships":              "partnerships_enabled",
		"/v1/growth/imports/consents":          "social_imports_enabled",
		"/v1/growth/history/location-checkins": "member_history_enabled",
		"/v1/growth/recommendations":           "recommendation_graph_enabled",
		"/v1/growth/admirer-gifts":             "admirer_gifts_enabled",
		"/v1/growth/paid-xp":                   "paid_xp_enabled",
	}
	for route, want := range cases {
		if got := featureFlagForRoute("/v1", route); got != want {
			t.Errorf("featureFlagForRoute(%q)=%q want %q", route, got, want)
		}
	}
	if got := featureFlagForRoute("/v1", "/v1/growth/portfolio"); got != "" {
		t.Fatalf("portfolio governance route must remain readable; got flag %q", got)
	}
}

func TestSupportDeadlinesPrioritizeSafetyAndUrgentRequests(t *testing.T) {
	t.Parallel()
	now := time.Date(2026, 9, 27, 12, 0, 0, 0, time.UTC)
	first, resolution := supportDeadlines("technical", "normal", now)
	if first.Sub(now) != 4*time.Hour || resolution.Sub(now) != 24*time.Hour {
		t.Fatalf("normal deadlines=(%s,%s)", first.Sub(now), resolution.Sub(now))
	}
	first, resolution = supportDeadlines("safety", "normal", now)
	if first.Sub(now) != 15*time.Minute || resolution.Sub(now) != 24*time.Hour {
		t.Fatalf("safety deadlines=(%s,%s)", first.Sub(now), resolution.Sub(now))
	}
	first, resolution = supportDeadlines("safety", "urgent", now)
	if first.Sub(now) != 15*time.Minute || resolution.Sub(now) != 4*time.Hour {
		t.Fatalf("urgent safety deadlines=(%s,%s)", first.Sub(now), resolution.Sub(now))
	}
}

func TestSupportRequestHashBindsEveryCommandField(t *testing.T) {
	t.Parallel()
	base := supportRequestHash("account", "normal", "Cannot sign in", "The app rejects my password")
	changes := []string{
		supportRequestHash("technical", "normal", "Cannot sign in", "The app rejects my password"),
		supportRequestHash("account", "high", "Cannot sign in", "The app rejects my password"),
		supportRequestHash("account", "normal", "Different subject", "The app rejects my password"),
		supportRequestHash("account", "normal", "Cannot sign in", "Different body"),
	}
	for _, changed := range changes {
		if changed == base {
			t.Fatal("request hash does not bind all idempotent command fields")
		}
	}
	if err := validateGrowthGuardrails(); err != nil {
		t.Fatal(err)
	}
}
