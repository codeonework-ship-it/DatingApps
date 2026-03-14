package mobile

import (
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"go.uber.org/zap"

	"github.com/verified-dating/backend/internal/platform/config"
	"github.com/verified-dating/backend/internal/platform/observability"
)

func TestServer_AttachSpotlightDiscoveryAddsMetadataAndSummary(t *testing.T) {
	cfg := config.Config{
		APIPrefix:        "/v1",
		AuthGRPCAddr:     "127.0.0.1:19091",
		ProfileGRPCAddr:  "127.0.0.1:19092",
		MatchingGRPCAddr: "127.0.0.1:19093",
		ChatGRPCAddr:     "127.0.0.1:19094",
	}
	reg := prometheus.NewRegistry()
	metrics := observability.NewHTTPMetrics(reg)

	server, err := NewServer(cfg, zap.NewNop(), metrics)
	if err != nil {
		t.Fatalf("NewServer() error = %v", err)
	}
	defer server.Close()

	server.store.mu.Lock()
	server.store.profiles["user-free-1"] = profileDraft{UserID: "user-free-1", ProfileCompletion: 80}
	server.store.profiles["user-paid-1"] = profileDraft{UserID: "user-paid-1", ProfileCompletion: 88}
	server.store.subscriptions["user-paid-1"] = userSubscription{UserID: "user-paid-1", PlanID: "premium", PlanName: "Premium"}
	server.store.userBadges["user-free-1"] = map[string]trustBadge{
		trustBadgePromptCompleter: {BadgeCode: trustBadgePromptCompleter, Status: "active"},
	}
	server.store.mu.Unlock()

	resp := map[string]any{
		"candidates": []any{
			map[string]any{"id": "user-free-1", "name": "Free User"},
			map[string]any{"id": "user-paid-1", "name": "Paid User"},
			map[string]any{"id": "user-free-2", "name": "Free User 2"},
			map[string]any{"id": "user-free-3", "name": "Free User 3"},
		},
	}

	server.attachSpotlightDiscovery(resp, "viewer-1")

	summary, ok := resp["spotlight_summary"].(map[string]any)
	if !ok {
		t.Fatalf("expected spotlight_summary in discovery response")
	}
	if summary["active"] != true {
		t.Fatalf("expected spotlight summary to be active")
	}

	candidates, ok := resp["candidates"].([]any)
	if !ok || len(candidates) == 0 {
		t.Fatalf("expected candidates in discovery response")
	}

	foundSpotlight := false
	for _, item := range candidates {
		row, ok := item.(map[string]any)
		if !ok {
			continue
		}
		if _, exists := row["spotlight_tier"]; !exists {
			t.Fatalf("expected spotlight_tier metadata on candidate")
		}
		if _, exists := row["spotlight_score"]; !exists {
			t.Fatalf("expected spotlight_score metadata on candidate")
		}
		if row["is_spotlight"] == true {
			foundSpotlight = true
		}
	}
	if !foundSpotlight {
		t.Fatalf("expected at least one spotlight candidate")
	}
}

func TestServer_SpotlightFairnessIncludesNonPremium(t *testing.T) {
	cfg := config.Config{
		APIPrefix:        "/v1",
		AuthGRPCAddr:     "127.0.0.1:19091",
		ProfileGRPCAddr:  "127.0.0.1:19092",
		MatchingGRPCAddr: "127.0.0.1:19093",
		ChatGRPCAddr:     "127.0.0.1:19094",
	}
	reg := prometheus.NewRegistry()
	metrics := observability.NewHTTPMetrics(reg)

	server, err := NewServer(cfg, zap.NewNop(), metrics)
	if err != nil {
		t.Fatalf("NewServer() error = %v", err)
	}
	defer server.Close()

	server.store.mu.Lock()
	for _, userID := range []string{"paid-1", "paid-2", "paid-3", "paid-4", "paid-5"} {
		server.store.profiles[userID] = profileDraft{UserID: userID, ProfileCompletion: 90}
		server.store.subscriptions[userID] = userSubscription{UserID: userID, PlanID: "vip", PlanName: "VIP"}
	}
	for _, userID := range []string{"free-1", "free-2", "free-3"} {
		server.store.profiles[userID] = profileDraft{UserID: userID, ProfileCompletion: 92}
		server.store.userBadges[userID] = map[string]trustBadge{
			trustBadgePromptCompleter:   {BadgeCode: trustBadgePromptCompleter, Status: "active"},
			trustBadgeConsistentProfile: {BadgeCode: trustBadgeConsistentProfile, Status: "active"},
		}
	}
	server.store.mu.Unlock()

	candidates := []any{}
	for _, userID := range []string{"paid-1", "paid-2", "paid-3", "paid-4", "paid-5", "free-1", "free-2", "free-3"} {
		candidates = append(candidates, map[string]any{"id": userID, "name": userID})
	}
	resp := map[string]any{"candidates": candidates}

	server.attachSpotlightDiscovery(resp, "viewer-1")

	spotlightProfiles, ok := resp["spotlight_profiles"].([]any)
	if !ok || len(spotlightProfiles) == 0 {
		t.Fatalf("expected spotlight_profiles list")
	}

	foundNonPremium := false
	for _, item := range spotlightProfiles {
		row, ok := item.(map[string]any)
		if !ok {
			continue
		}
		tier := row["spotlight_tier"]
		if tier == "bronze" || tier == "silver" {
			foundNonPremium = true
			break
		}
	}
	if !foundNonPremium {
		t.Fatalf("expected fairness to include at least one non-premium spotlight profile")
	}
}

func TestServer_SpotlightSwipeOutcomeTelemetry(t *testing.T) {
	cfg := config.Config{
		APIPrefix:        "/v1",
		AuthGRPCAddr:     "127.0.0.1:19091",
		ProfileGRPCAddr:  "127.0.0.1:19092",
		MatchingGRPCAddr: "127.0.0.1:19093",
		ChatGRPCAddr:     "127.0.0.1:19094",
	}
	reg := prometheus.NewRegistry()
	metrics := observability.NewHTTPMetrics(reg)

	server, err := NewServer(cfg, zap.NewNop(), metrics)
	if err != nil {
		t.Fatalf("NewServer() error = %v", err)
	}
	defer server.Close()

	server.store.mu.Lock()
	server.store.spotlightLastResetDate = time.Now().UTC().Format("2006-01-02")
	server.store.spotlightEligibleUsers["target-user"] = "gold"
	server.store.mu.Unlock()

	req := httptest.NewRequest(http.MethodPost, "/v1/swipe", nil)
	_ = req
	server.store.recordSpotlightSwipeOutcome("target-user", true, true)

	server.store.mu.RLock()
	likes := server.store.spotlightLikeByTier["gold"]
	matches := server.store.spotlightMatchByTier["gold"]
	server.store.mu.RUnlock()

	if likes != 1 {
		t.Fatalf("expected 1 gold like outcome, got %d", likes)
	}
	if matches != 1 {
		t.Fatalf("expected 1 gold match outcome, got %d", matches)
	}
}

func TestApplyDiscoveryMode_SpotlightOnlyReplacesCandidates(t *testing.T) {
	resp := map[string]any{
		"candidates": []any{
			map[string]any{"id": "user-a"},
			map[string]any{"id": "user-b"},
		},
		"spotlight_profiles": []any{
			map[string]any{"id": "user-s1", "is_spotlight": true},
		},
	}

	applyDiscoveryMode(resp, "spotlight")

	candidates, ok := resp["candidates"].([]any)
	if !ok {
		t.Fatalf("expected candidates list in response")
	}
	if len(candidates) != 1 {
		t.Fatalf("expected spotlight-only candidate list length 1, got %d", len(candidates))
	}
	if mode := resp["discovery_mode"]; mode != "spotlight" {
		t.Fatalf("expected discovery_mode spotlight, got %v", mode)
	}
}
