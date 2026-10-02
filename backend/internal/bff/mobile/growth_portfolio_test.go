package mobile

import (
	"testing"
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
