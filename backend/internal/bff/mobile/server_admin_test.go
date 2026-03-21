package mobile

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"go.uber.org/zap"

	"github.com/verified-dating/backend/internal/platform/config"
	"github.com/verified-dating/backend/internal/platform/observability"
)

func TestServer_AdminVerificationAndActivityFlow(t *testing.T) {
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

	submitReq := httptest.NewRequest(http.MethodPost, "/v1/verification/user-123/submit", strings.NewReader("{}"))
	submitReq.Header.Set("Content-Type", "application/json")
	submitRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(submitRec, submitReq)
	if submitRec.Code != http.StatusOK {
		t.Fatalf("submit verification code = %d", submitRec.Code)
	}

	listReq := httptest.NewRequest(http.MethodGet, "/v1/admin/verifications?status=pending", nil)
	listRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(listRec, listReq)
	if listRec.Code != http.StatusOK {
		t.Fatalf("list verifications code = %d", listRec.Code)
	}

	var listPayload map[string]any
	if err := json.Unmarshal(listRec.Body.Bytes(), &listPayload); err != nil {
		t.Fatalf("decode list payload: %v", err)
	}
	verifications, ok := listPayload["verifications"].([]any)
	if !ok || len(verifications) == 0 {
		t.Fatalf("expected at least one verification item")
	}

	approveReq := httptest.NewRequest(http.MethodPost, "/v1/admin/verifications/user-123/approve", strings.NewReader("{}"))
	approveReq.Header.Set("Content-Type", "application/json")
	approveReq.Header.Set("X-Admin-User", "qa-admin")
	approveRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(approveRec, approveReq)
	if approveRec.Code != http.StatusOK {
		t.Fatalf("approve verification code = %d", approveRec.Code)
	}

	submitAgainReq := httptest.NewRequest(http.MethodPost, "/v1/verification/user-123/submit", strings.NewReader("{}"))
	submitAgainReq.Header.Set("Content-Type", "application/json")
	submitAgainRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(submitAgainRec, submitAgainReq)
	if submitAgainRec.Code != http.StatusOK {
		t.Fatalf("submit verification (again) code = %d", submitAgainRec.Code)
	}

	billingReq := httptest.NewRequest(http.MethodGet, "/v1/billing/plans", nil)
	billingRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(billingRec, billingReq)
	if billingRec.Code != http.StatusOK {
		t.Fatalf("billing plans code = %d", billingRec.Code)
	}

	rejectBody := "rejection_reason=document+blurred"
	rejectReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/admin/verifications/user-123/reject",
		strings.NewReader(rejectBody),
	)
	rejectReq.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	rejectReq.Header.Set("X-Admin-User", "qa-admin")
	rejectRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rejectRec, rejectReq)
	if rejectRec.Code != http.StatusOK {
		t.Fatalf("reject verification code = %d", rejectRec.Code)
	}

	activityReq := httptest.NewRequest(http.MethodGet, "/v1/admin/activities?limit=50", nil)
	activityRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(activityRec, activityReq)
	if activityRec.Code != http.StatusOK {
		t.Fatalf("list activities code = %d", activityRec.Code)
	}

	var activityPayload map[string]any
	if err := json.Unmarshal(activityRec.Body.Bytes(), &activityPayload); err != nil {
		t.Fatalf("decode activity payload: %v", err)
	}
	activities, ok := activityPayload["activities"].([]any)
	if !ok || len(activities) == 0 {
		t.Fatalf("expected activity records after requests")
	}

	foundBillingPolicyDimension := false
	for _, item := range activities {
		activity, ok := item.(map[string]any)
		if !ok {
			continue
		}
		details, ok := activity["details"].(map[string]any)
		if !ok {
			continue
		}
		if _, exists := details["monetization_matrix_version"]; exists {
			foundBillingPolicyDimension = true
		}
	}
	if !foundBillingPolicyDimension {
		t.Fatalf("expected at least one activity event to include monetization_matrix_version")
	}
}

func TestServer_AdminAnalyticsOverviewIncludesFeatureFlagsAndFunnelMetrics(t *testing.T) {
	cfg := config.Config{
		APIPrefix:                  "/v1",
		AuthGRPCAddr:               "127.0.0.1:19091",
		ProfileGRPCAddr:            "127.0.0.1:19092",
		MatchingGRPCAddr:           "127.0.0.1:19093",
		ChatGRPCAddr:               "127.0.0.1:19094",
		FeatureEngagementUnlockMVP: true,
		FeatureDigitalGestures:     true,
		FeatureMiniActivities:      true,
		FeatureTrustBadges:         true,
		FeatureConversationRooms:   true,
	}
	reg := prometheus.NewRegistry()
	metrics := observability.NewHTTPMetrics(reg)

	server, err := NewServer(cfg, zap.NewNop(), metrics)
	if err != nil {
		t.Fatalf("NewServer() error = %v", err)
	}
	defer server.Close()

	now := time.Now().UTC().Format(time.RFC3339)
	server.store.mu.Lock()
	server.store.questWorkflows["match-analytics-1"] = questSubmissionWorkflow{
		MatchID:      "match-analytics-1",
		Status:       questWorkflowStatusApproved,
		UnlockState:  "conversation_unlocked",
		AttemptCount: 2,
	}
	server.store.matchGestures["match-analytics-1"] = []matchGesture{
		{ID: "gesture-1", MatchID: "match-analytics-1", Status: "appreciated", CreatedAt: now, UpdatedAt: now},
		{ID: "gesture-2", MatchID: "match-analytics-1", Status: "declined", CreatedAt: now, UpdatedAt: now},
	}
	server.store.activitySessions["session-analytics-1"] = activitySession{
		ID:      "session-analytics-1",
		MatchID: "match-analytics-1",
		Status:  activitySessionStatusCompleted,
	}
	server.store.reports = append(server.store.reports, moderationReport{
		ID:             "rep-analytics-1",
		ReporterUserID: "user-1",
		ReportedUserID: "user-2",
		Reason:         "abuse",
		Status:         "pending",
		CreatedAt:      now,
	})
	server.store.activities = append(server.store.activities,
		activityEvent{ID: "act-analytics-1", Action: "POST /v1/swipe", Status: "success", CreatedAt: now},
		activityEvent{ID: "act-analytics-2", Action: "POST /v1/chat/match/messages", Status: "success", CreatedAt: now},
		activityEvent{
			ID:       "act-analytics-3",
			Action:   "POST /v1/matches/match-analytics-1/quest-workflow/submit",
			Status:   "success",
			Resource: "/v1/matches/match-analytics-1/quest-workflow/submit",
			Details: map[string]any{
				"unlock_policy_variant": "require_quest_template",
			},
			CreatedAt: now,
		},
		activityEvent{
			ID:       "act-analytics-4",
			Action:   "chat.locked",
			Status:   "client_error",
			Resource: "/chat/match-analytics-1/messages",
			Details: map[string]any{
				"unlock_policy_variant": "require_quest_template",
			},
			CreatedAt: now,
		},
	)
	server.store.mu.Unlock()

	req := httptest.NewRequest(http.MethodGet, "/v1/admin/analytics/overview", nil)
	rec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("admin analytics overview code = %d body=%s", rec.Code, rec.Body.String())
	}

	var payload map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &payload); err != nil {
		t.Fatalf("decode analytics payload: %v", err)
	}

	metricsMap, ok := payload["metrics"].(map[string]any)
	if !ok {
		t.Fatalf("expected metrics payload")
	}
	if got := toString(metricsMap["unlock_policy_variant"]); got != "require_quest_template" {
		t.Fatalf("expected unlock_policy_variant require_quest_template, got %q", got)
	}
	compliance, ok := metricsMap["monetization_policy_compliance"].(map[string]any)
	if !ok {
		t.Fatalf("expected monetization_policy_compliance map")
	}
	if blocked := adminIntValue(compliance["blocked_core_feature_count"]); blocked != 0 {
		t.Fatalf("expected blocked_core_feature_count=0, got %d", blocked)
	}
	if nonBlocking := adminBoolValue(compliance["core_progression_non_blocking"]); !nonBlocking {
		t.Fatalf("expected core_progression_non_blocking=true")
	}

	featureFlags, ok := metricsMap["feature_flags"].(map[string]any)
	if !ok {
		t.Fatalf("expected feature_flags map")
	}
	if enabled, _ := featureFlags["conversation_rooms"].(bool); !enabled {
		t.Fatalf("expected conversation_rooms feature flag enabled")
	}

	funnel, ok := metricsMap["funnel_metrics"].(map[string]any)
	if !ok {
		t.Fatalf("expected funnel_metrics map")
	}

	requiredKeys := []string{
		"unlock_completion_rate",
		"unlock_attempt_count_by_policy",
		"chat_lock_count_by_policy",
		"gesture_acceptance_rate",
		"activity_completion_rate",
		"report_rate_per_1k_interactions",
	}
	for _, key := range requiredKeys {
		if _, exists := funnel[key]; !exists {
			t.Fatalf("expected funnel metric key %q", key)
		}
	}
}

func TestServer_AdminAnalyticsOverviewIncludesRoseGiftFunnelMetrics(t *testing.T) {
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

	now := time.Now().UTC().Format(time.RFC3339)
	server.store.mu.Lock()
	server.store.activities = append(server.store.activities,
		activityEvent{
			ID:       "gift-analytics-1",
			UserID:   "gift-user-1",
			Actor:    "gift-user-1",
			Action:   "gift_panel_opened",
			Status:   "success",
			Resource: "/chat/match-analytics-gift-1/gifts/events",
			Details: map[string]any{
				"match_id":      "match-analytics-gift-1",
				"wallet_coins":  12,
				"catalog_count": 8,
			},
			CreatedAt: now,
		},
		activityEvent{
			ID:       "gift-analytics-2",
			UserID:   "gift-user-1",
			Actor:    "gift-user-1",
			Action:   "gift_preview_opened",
			Status:   "success",
			Resource: "/chat/match-analytics-gift-1/gifts/events",
			Details: map[string]any{
				"match_id":    "match-analytics-gift-1",
				"gift_id":     "rose_blue_rare",
				"tier":        "premium_common",
				"price_coins": 1,
			},
			CreatedAt: now,
		},
		activityEvent{
			ID:       "gift-analytics-3",
			UserID:   "gift-user-1",
			Actor:    "gift-user-1",
			Action:   "gift_send_attempted",
			Status:   "attempt",
			Resource: "/chat/match-analytics-gift-1/gifts/send",
			Details: map[string]any{
				"match_id": "match-analytics-gift-1",
				"gift_id":  "rose_blue_rare",
			},
			CreatedAt: now,
		},
		activityEvent{
			ID:       "gift-analytics-4",
			UserID:   "gift-user-1",
			Actor:    "gift-user-1",
			Action:   "gift_send_succeeded",
			Status:   "success",
			Resource: "/chat/match-analytics-gift-1/gifts/send",
			Details: map[string]any{
				"match_id":        "match-analytics-gift-1",
				"gift_id":         "rose_blue_rare",
				"price_coins":     1,
				"remaining_coins": 11,
			},
			CreatedAt: now,
		},
		activityEvent{
			ID:       "gift-analytics-5",
			UserID:   "gift-user-1",
			Actor:    "gift-user-1",
			Action:   "wallet.topup",
			Status:   "success",
			Resource: "/wallet/gift-user-1/coins/top-up",
			Details: map[string]any{
				"amount":  5,
				"reason":  "qa_seed",
				"balance": 16,
			},
			CreatedAt: now,
		},
	)
	server.store.mu.Unlock()

	req := httptest.NewRequest(http.MethodGet, "/v1/admin/analytics/overview", nil)
	rec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("admin analytics overview code = %d body=%s", rec.Code, rec.Body.String())
	}

	var payload map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &payload); err != nil {
		t.Fatalf("decode analytics payload: %v", err)
	}
	metricsMap, ok := payload["metrics"].(map[string]any)
	if !ok {
		t.Fatalf("expected metrics payload")
	}
	funnel, ok := metricsMap["funnel_metrics"].(map[string]any)
	if !ok {
		t.Fatalf("expected funnel_metrics payload")
	}

	if got := adminIntValue(funnel["gift_panel_opened_count"]); got != 1 {
		t.Fatalf("expected gift_panel_opened_count=1, got %d", got)
	}
	if got := adminIntValue(funnel["gift_preview_opened_count"]); got != 1 {
		t.Fatalf("expected gift_preview_opened_count=1, got %d", got)
	}
	if got := adminIntValue(funnel["gift_send_attempted_count"]); got != 1 {
		t.Fatalf("expected gift_send_attempted_count=1, got %d", got)
	}
	if got := adminIntValue(funnel["gift_send_success_count"]); got != 1 {
		t.Fatalf("expected gift_send_success_count=1, got %d", got)
	}
	if got := adminIntValue(funnel["gift_coins_earned_total"]); got != 5 {
		t.Fatalf("expected gift_coins_earned_total=5, got %d", got)
	}
	if got := adminIntValue(funnel["gift_coins_spent_total"]); got != 1 {
		t.Fatalf("expected gift_coins_spent_total=1, got %d", got)
	}

	tierDistribution, ok := funnel["gift_send_tier_distribution"].(map[string]any)
	if !ok {
		t.Fatalf("expected gift_send_tier_distribution map")
	}
	if got := adminIntValue(tierDistribution["premium_common"]); got != 1 {
		t.Fatalf("expected premium_common tier distribution count=1, got %d", got)
	}
}

func adminIntValue(value any) int {
	switch typed := value.(type) {
	case int:
		return typed
	case int32:
		return int(typed)
	case int64:
		return int(typed)
	case float64:
		return int(typed)
	default:
		return 0
	}
}

func adminBoolValue(value any) bool {
	if typed, ok := value.(bool); ok {
		return typed
	}
	return false
}
