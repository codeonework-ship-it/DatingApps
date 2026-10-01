package mobile

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/verified-dating/backend/internal/platform/config"
)

func TestFeatureFlagForRouteCoversReleaseExcludedAliases(t *testing.T) {
	tests := map[string]string{
		"/v1/wallet/user-1/coins/buy":                "billing_enabled",
		"/v1/wallet/user-1/coins":                    "",
		"/v1/verification/user-1/submit":             "identity_verification_enabled",
		"/v1/verification/user-1":                    "",
		"/v1/matches/match-1/unlock-requirements":    "quest_workflow_v2_enabled",
		"/v1/matches/match-1/gestures":               "digital_gestures_enabled",
		"/v1/matches/match-1/gestures/g-1/decision":  "digital_gestures_enabled",
		"/v1/matches/match-1/unlock-state":           "",
		"/v1/matches/match-1/quest-template":         "quest_workflow_v2_enabled",
		"/v1/engagement/voice-icebreakers/user-1/up": "voice_icebreakers_enabled",
	}
	for path, want := range tests {
		if got := featureFlagForRoute("/v1", path); got != want {
			t.Errorf("featureFlagForRoute(%q)=%q, want %q", path, got, want)
		}
	}
}

func newReleaseTestServer(t *testing.T, environment string, excluded []string) *Server {
	t.Helper()
	return newQuestWorkflowTestServerWithConfig(t, func(cfg *config.Config) {
		cfg.Environment = environment
		cfg.ReleaseExcludedFlags = excluded
	})
}

// The release contract's excluded capabilities are rejected by the server
// command, whatever the runtime flag says (release_contract.v1.json scope_rule).
func TestReleaseExcludedCapabilitiesAreRejectedServerSide(t *testing.T) {
	server := newReleaseTestServer(t, "production", config.FirstReleaseExcludedFlags)
	defer server.Close()

	for _, path := range []string{
		"/v1/chat/match-1/gifts/send",
		"/v1/billing/checkout",
		"/v1/wallet/user-1/coins/buy",
		"/v1/calls/start",
		"/v1/matches/match-1/unlock-requirements",
		"/v1/verification/user-1/submit",
		"/v1/progression/user-1/rewards/claim",
	} {
		req := httptest.NewRequest(http.MethodPost, path, strings.NewReader(`{}`))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		server.Handler().ServeHTTP(rec, req)
		if rec.Code != http.StatusForbidden || !strings.Contains(rec.Body.String(), "FEATURE_EXCLUDED_FROM_RELEASE") {
			t.Errorf("%s: code=%d body=%s", path, rec.Code, rec.Body.String())
		}
	}

	req := httptest.NewRequest(http.MethodGet, "/v1/config/flags", nil)
	rec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("config flags code=%d body=%s", rec.Code, rec.Body.String())
	}
	payload := decodeJSONMap(t, rec.Body.Bytes())
	flags, _ := payload["flags"].([]any)
	reported := map[string]any{}
	for _, raw := range flags {
		row, _ := raw.(map[string]any)
		reported[toString(row["key"])] = row["value_bool"]
	}
	for _, key := range config.FirstReleaseExcludedFlags {
		if reported[key] != false {
			t.Errorf("config/flags %s = %v, want false", key, reported[key])
		}
	}
	if reported["safety_sos_enabled"] == false {
		t.Errorf("a released capability was reported off: %v", reported)
	}
}

// Without a payment provider, coin and plan activation credit value with no
// payment; that must only work in an explicitly local environment.
func TestProviderlessSelfCreditIsLocalOnly(t *testing.T) {
	for _, environment := range []string{"production", "staging", "qa", ""} {
		server := newReleaseTestServer(t, environment, nil)
		buy := httptest.NewRequest(http.MethodPost, "/v1/wallet/wallet-user/coins/buy",
			strings.NewReader(`{"package_id":"starter_pack","coins":8,"amount_minor":199,"currency":"INR"}`))
		buy.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		server.Handler().ServeHTTP(rec, buy)
		if rec.Code != http.StatusConflict || !strings.Contains(rec.Body.String(), "PAYMENT_PROVIDER_REQUIRED") {
			t.Errorf("env %q coin buy: code=%d body=%s", environment, rec.Code, rec.Body.String())
		}

		sub := httptest.NewRequest(http.MethodPost, "/v1/billing/subscribe",
			strings.NewReader(`{"user_id":"wallet-user","plan_id":"premium","billing_cycle":"monthly"}`))
		sub.Header.Set("Content-Type", "application/json")
		rec = httptest.NewRecorder()
		server.Handler().ServeHTTP(rec, sub)
		if rec.Code != http.StatusConflict {
			t.Errorf("env %q subscribe: code=%d body=%s", environment, rec.Code, rec.Body.String())
		}
		server.Close()
	}
}
