package mobile

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/prometheus/client_golang/prometheus"
	"go.uber.org/zap"

	"github.com/verified-dating/backend/internal/platform/config"
	"github.com/verified-dating/backend/internal/platform/observability"
)

func TestServer_QuestWorkflowApproveFlow(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	upsertTemplateBody := `{
		"creator_user_id": "user-a",
		"prompt_template": "Share your most meaningful travel memory with honest details.",
		"min_chars": 20,
		"max_chars": 200
	}`
	upsertTemplateReq := httptest.NewRequest(
		http.MethodPut,
		"/v1/matches/match-approve/quest-template",
		strings.NewReader(upsertTemplateBody),
	)
	upsertTemplateReq.Header.Set("Content-Type", "application/json")
	upsertTemplateRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(upsertTemplateRec, upsertTemplateReq)
	if upsertTemplateRec.Code != http.StatusOK {
		t.Fatalf("upsert template code = %d body=%s", upsertTemplateRec.Code, upsertTemplateRec.Body.String())
	}

	submitBody := `{
		"submitter_user_id": "user-a",
		"response_text": "I traveled alone through Kerala, met local artists, and learned how patience and listening changed how I build trust in relationships."
	}`
	submitReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/matches/match-approve/quest-workflow/submit",
		strings.NewReader(submitBody),
	)
	submitReq.Header.Set("Content-Type", "application/json")
	submitRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(submitRec, submitReq)
	if submitRec.Code != http.StatusOK {
		t.Fatalf("submit workflow code = %d body=%s", submitRec.Code, submitRec.Body.String())
	}

	getReq := httptest.NewRequest(http.MethodGet, "/v1/matches/match-approve/quest-workflow", nil)
	getRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(getRec, getReq)
	if getRec.Code != http.StatusOK {
		t.Fatalf("get workflow code = %d body=%s", getRec.Code, getRec.Body.String())
	}
	getPayload := decodeJSONMap(t, getRec.Body.Bytes())
	workflow := toMap(t, getPayload["quest_workflow"])
	if got := stringValue(workflow["status"]); got != "pending" {
		t.Fatalf("expected pending status after submit, got %q", got)
	}
	if got := stringValue(workflow["unlock_state"]); got != "quest_under_review" {
		t.Fatalf("expected unlock_state quest_under_review after submit, got %q", got)
	}

	reviewBody := `{
		"reviewer_user_id": "user-b",
		"decision_status": "approved"
	}`
	reviewReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/matches/match-approve/quest-workflow/review",
		strings.NewReader(reviewBody),
	)
	reviewReq.Header.Set("Content-Type", "application/json")
	reviewRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(reviewRec, reviewReq)
	if reviewRec.Code != http.StatusOK {
		t.Fatalf("review workflow code = %d body=%s", reviewRec.Code, reviewRec.Body.String())
	}

	getAfterReq := httptest.NewRequest(http.MethodGet, "/v1/matches/match-approve/quest-workflow", nil)
	getAfterRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(getAfterRec, getAfterReq)
	if getAfterRec.Code != http.StatusOK {
		t.Fatalf("get workflow after review code = %d body=%s", getAfterRec.Code, getAfterRec.Body.String())
	}
	getAfterPayload := decodeJSONMap(t, getAfterRec.Body.Bytes())
	workflowAfter := toMap(t, getAfterPayload["quest_workflow"])
	if got := stringValue(workflowAfter["status"]); got != "approved" {
		t.Fatalf("expected approved status after review, got %q", got)
	}
	if got := stringValue(workflowAfter["unlock_state"]); got != "conversation_unlocked" {
		t.Fatalf("expected unlock_state conversation_unlocked after approval, got %q", got)
	}
}

func TestServer_QuestWorkflowRejectAndCooldownFlow(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	upsertTemplateBody := `{
		"creator_user_id": "user-a",
		"prompt_template": "Explain how you maintain boundaries and empathy during conflict.",
		"min_chars": 20,
		"max_chars": 200
	}`
	upsertTemplateReq := httptest.NewRequest(
		http.MethodPut,
		"/v1/matches/match-reject/quest-template",
		strings.NewReader(upsertTemplateBody),
	)
	upsertTemplateReq.Header.Set("Content-Type", "application/json")
	upsertTemplateRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(upsertTemplateRec, upsertTemplateReq)
	if upsertTemplateRec.Code != http.StatusOK {
		t.Fatalf("upsert template code = %d body=%s", upsertTemplateRec.Code, upsertTemplateRec.Body.String())
	}

	submitBody := `{
		"submitter_user_id": "user-a",
		"response_text": "I name my emotions clearly, ask for pauses, and return to discussion with concrete requests while protecting both empathy and boundaries."
	}`
	submitReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/matches/match-reject/quest-workflow/submit",
		strings.NewReader(submitBody),
	)
	submitReq.Header.Set("Content-Type", "application/json")
	submitRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(submitRec, submitReq)
	if submitRec.Code != http.StatusOK {
		t.Fatalf("submit workflow code = %d body=%s", submitRec.Code, submitRec.Body.String())
	}

	rejectWithoutReasonBody := `{
		"reviewer_user_id": "user-b",
		"decision_status": "rejected"
	}`
	rejectWithoutReasonReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/matches/match-reject/quest-workflow/review",
		strings.NewReader(rejectWithoutReasonBody),
	)
	rejectWithoutReasonReq.Header.Set("Content-Type", "application/json")
	rejectWithoutReasonRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rejectWithoutReasonRec, rejectWithoutReasonReq)
	if rejectWithoutReasonRec.Code != http.StatusBadRequest {
		t.Fatalf("reject without reason code = %d body=%s", rejectWithoutReasonRec.Code, rejectWithoutReasonRec.Body.String())
	}

	rejectBody := `{
		"reviewer_user_id": "user-b",
		"decision_status": "rejected",
		"review_reason": "Needs clearer examples and accountability details"
	}`
	rejectReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/matches/match-reject/quest-workflow/review",
		strings.NewReader(rejectBody),
	)
	rejectReq.Header.Set("Content-Type", "application/json")
	rejectRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rejectRec, rejectReq)
	if rejectRec.Code != http.StatusOK {
		t.Fatalf("reject workflow code = %d body=%s", rejectRec.Code, rejectRec.Body.String())
	}

	reSubmitReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/matches/match-reject/quest-workflow/submit",
		strings.NewReader(submitBody),
	)
	reSubmitReq.Header.Set("Content-Type", "application/json")
	reSubmitRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(reSubmitRec, reSubmitReq)
	if reSubmitRec.Code != http.StatusBadGateway {
		t.Fatalf("submit during cooldown code = %d body=%s", reSubmitRec.Code, reSubmitRec.Body.String())
	}

	getReq := httptest.NewRequest(http.MethodGet, "/v1/matches/match-reject/quest-workflow", nil)
	getRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(getRec, getReq)
	if getRec.Code != http.StatusOK {
		t.Fatalf("get workflow code = %d body=%s", getRec.Code, getRec.Body.String())
	}
	getPayload := decodeJSONMap(t, getRec.Body.Bytes())
	workflow := toMap(t, getPayload["quest_workflow"])
	if got := stringValue(workflow["status"]); got != "cooldown" {
		t.Fatalf("expected cooldown status after rejected review, got %q", got)
	}
	if got := stringValue(workflow["review_reason"]); got == "" {
		t.Fatalf("expected review reason after rejection")
	}
}

func TestServer_QuestWorkflowRateLimitSaturation(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	upsertTemplateBody := `{
		"creator_user_id": "user-a",
		"prompt_template": "Describe one real relationship lesson and what changed in your behavior.",
		"min_chars": 20,
		"max_chars": 220
	}`
	upsertTemplateReq := httptest.NewRequest(
		http.MethodPut,
		"/v1/matches/match-rate-limit/quest-template",
		strings.NewReader(upsertTemplateBody),
	)
	upsertTemplateReq.Header.Set("Content-Type", "application/json")
	upsertTemplateRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(upsertTemplateRec, upsertTemplateReq)
	if upsertTemplateRec.Code != http.StatusOK {
		t.Fatalf("upsert template code = %d body=%s", upsertTemplateRec.Code, upsertTemplateRec.Body.String())
	}

	submitBody := `{
		"submitter_user_id": "user-a",
		"response_text": "I learned to listen without defending immediately and to summarize what I heard before reacting, which changed conflicts into collaborative conversations."
	}`

	for attempt := 1; attempt <= 5; attempt++ {
		req := httptest.NewRequest(
			http.MethodPost,
			"/v1/matches/match-rate-limit/quest-workflow/submit",
			strings.NewReader(submitBody),
		)
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		server.Handler().ServeHTTP(rec, req)
		if rec.Code != http.StatusOK {
			t.Fatalf("attempt %d expected 200, got %d body=%s", attempt, rec.Code, rec.Body.String())
		}
	}

	sixthReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/matches/match-rate-limit/quest-workflow/submit",
		strings.NewReader(submitBody),
	)
	sixthReq.Header.Set("Content-Type", "application/json")
	sixthRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(sixthRec, sixthReq)
	if sixthRec.Code != http.StatusBadGateway {
		t.Fatalf("sixth submit expected 502, got %d body=%s", sixthRec.Code, sixthRec.Body.String())
	}
}

func TestServer_ChatSendBlockedWhenQuestLocked(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	upsertTemplateBody := `{
		"creator_user_id": "user-a",
		"prompt_template": "Share one value conflict and how you addressed it constructively.",
		"min_chars": 20,
		"max_chars": 200
	}`
	upsertTemplateReq := httptest.NewRequest(
		http.MethodPut,
		"/v1/matches/match-chat-locked/quest-template",
		strings.NewReader(upsertTemplateBody),
	)
	upsertTemplateReq.Header.Set("Content-Type", "application/json")
	upsertTemplateRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(upsertTemplateRec, upsertTemplateReq)
	if upsertTemplateRec.Code != http.StatusOK {
		t.Fatalf("upsert template code = %d body=%s", upsertTemplateRec.Code, upsertTemplateRec.Body.String())
	}

	unlockReq := httptest.NewRequest(http.MethodGet, "/v1/matches/match-chat-locked/unlock-state", nil)
	unlockRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(unlockRec, unlockReq)
	if unlockRec.Code != http.StatusOK {
		t.Fatalf("unlock-state code = %d body=%s", unlockRec.Code, unlockRec.Body.String())
	}
	unlockPayload := decodeJSONMap(t, unlockRec.Body.Bytes())
	if got := stringValue(unlockPayload["unlock_state"]); got != "quest_pending" {
		t.Fatalf("expected unlock_state quest_pending, got %q", got)
	}

	chatBody := `{"sender_id":"user-a","text":"hello"}`
	chatReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/chat/match-chat-locked/messages",
		strings.NewReader(chatBody),
	)
	chatReq.Header.Set("Content-Type", "application/json")
	chatRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(chatRec, chatReq)
	if chatRec.Code != http.StatusLocked {
		t.Fatalf("chat locked expected 423, got %d body=%s", chatRec.Code, chatRec.Body.String())
	}

	chatPayload := decodeJSONMap(t, chatRec.Body.Bytes())
	if got := stringValue(chatPayload["error_code"]); got != "CHAT_LOCKED_REQUIREMENT_PENDING" {
		t.Fatalf("expected CHAT_LOCKED_REQUIREMENT_PENDING, got %q", got)
	}
	if got := stringValue(chatPayload["unlock_policy_variant"]); got != "require_quest_template" {
		t.Fatalf("expected unlock_policy_variant require_quest_template, got %q", got)
	}

	activitiesReq := httptest.NewRequest(http.MethodGet, "/v1/admin/activities?limit=100", nil)
	activitiesRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(activitiesRec, activitiesReq)
	if activitiesRec.Code != http.StatusOK {
		t.Fatalf("activities code = %d body=%s", activitiesRec.Code, activitiesRec.Body.String())
	}
	activitiesPayload := decodeJSONMap(t, activitiesRec.Body.Bytes())
	activities, ok := activitiesPayload["activities"].([]any)
	if !ok {
		t.Fatalf("expected activities array")
	}

	foundChatLockedTelemetry := false
	for _, item := range activities {
		activity, ok := item.(map[string]any)
		if !ok {
			continue
		}
		if stringValue(activity["action"]) != "chat.locked" {
			continue
		}
		details := toMap(t, activity["details"])
		if stringValue(details["unlock_policy_variant"]) == "require_quest_template" {
			foundChatLockedTelemetry = true
			break
		}
	}
	if !foundChatLockedTelemetry {
		t.Fatalf("expected chat.locked activity with unlock_policy_variant telemetry")
	}
}

func TestServer_UnlockStateRequiresQuestByDefaultWhenTemplateMissing(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	req := httptest.NewRequest(http.MethodGet, "/v1/matches/match-no-template/unlock-state", nil)
	rec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("unlock-state code = %d body=%s", rec.Code, rec.Body.String())
	}
	payload := decodeJSONMap(t, rec.Body.Bytes())
	if got := stringValue(payload["unlock_state"]); got != "quest_pending" {
		t.Fatalf("expected unlock_state quest_pending, got %q", got)
	}
	if got := boolValue(payload["has_requirement"]); !got {
		t.Fatalf("expected has_requirement true, got false")
	}
	if got := boolValue(payload["chat_unlocked"]); got {
		t.Fatalf("expected chat_unlocked false, got true")
	}
	if got := stringValue(payload["unlock_policy_variant"]); got != "require_quest_template" {
		t.Fatalf("expected unlock_policy_variant require_quest_template, got %q", got)
	}
}

func TestServer_AssistedReviewAutoApprove_WhenThresholdsSatisfied(t *testing.T) {
	server := newQuestWorkflowTestServerWithConfig(t, func(cfg *config.Config) {
		cfg.FeatureAssistedReviewAutomation = true
		cfg.AssistedReviewMinChars = 80
		cfg.AssistedReviewMinWordCount = 12
	})
	defer server.Close()

	upsertTemplateBody := `{
		"creator_user_id": "user-b",
		"prompt_template": "Explain a meaningful disagreement and what you learned.",
		"min_chars": 20,
		"max_chars": 400
	}`
	upsertTemplateReq := httptest.NewRequest(
		http.MethodPut,
		"/v1/matches/match-assisted-auto/quest-template",
		strings.NewReader(upsertTemplateBody),
	)
	upsertTemplateReq.Header.Set("Content-Type", "application/json")
	upsertTemplateRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(upsertTemplateRec, upsertTemplateReq)
	if upsertTemplateRec.Code != http.StatusOK {
		t.Fatalf("upsert template code = %d body=%s", upsertTemplateRec.Code, upsertTemplateRec.Body.String())
	}

	submitBody := `{
		"submitter_user_id":"user-a",
		"response_text":"I handled a disagreement by listening carefully first, summarizing her point before mine, and agreeing on shared values and boundaries. We both left feeling respected and clear about the next steps."}`
	submitReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/matches/match-assisted-auto/quest-workflow/submit",
		strings.NewReader(submitBody),
	)
	submitReq.Header.Set("Content-Type", "application/json")
	submitRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(submitRec, submitReq)
	if submitRec.Code != http.StatusOK {
		t.Fatalf("submit code = %d body=%s", submitRec.Code, submitRec.Body.String())
	}

	submitPayload := decodeJSONMap(t, submitRec.Body.Bytes())
	workflow := toMap(t, submitPayload["quest_workflow"])
	if got := stringValue(workflow["status"]); got != "approved" {
		t.Fatalf("expected assisted auto-review to approve workflow, got %q", got)
	}
	if got := stringValue(workflow["unlock_state"]); got != "conversation_unlocked" {
		t.Fatalf("expected unlock_state conversation_unlocked, got %q", got)
	}
	if got := stringValue(workflow["review_reason"]); !strings.HasPrefix(got, autoReviewReasonPrefix) {
		t.Fatalf("expected review_reason prefixed by %q, got %q", autoReviewReasonPrefix, got)
	}

	activitiesReq := httptest.NewRequest(http.MethodGet, "/v1/admin/activities?limit=100", nil)
	activitiesRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(activitiesRec, activitiesReq)
	if activitiesRec.Code != http.StatusOK {
		t.Fatalf("activities code = %d body=%s", activitiesRec.Code, activitiesRec.Body.String())
	}
	activitiesPayload := decodeJSONMap(t, activitiesRec.Body.Bytes())
	activities, ok := activitiesPayload["activities"].([]any)
	if !ok {
		t.Fatalf("expected activities array")
	}

	foundAutoAudit := false
	for _, item := range activities {
		activity, ok := item.(map[string]any)
		if !ok {
			continue
		}
		if stringValue(activity["action"]) != "quest.review.auto" {
			continue
		}
		details := toMap(t, activity["details"])
		if strings.HasPrefix(stringValue(details["review_reason"]), autoReviewReasonPrefix) {
			foundAutoAudit = true
			break
		}
	}
	if !foundAutoAudit {
		t.Fatalf("expected quest.review.auto audit event with assisted rationale")
	}
}

func newQuestWorkflowTestServer(t *testing.T) *Server {
	t.Helper()

	cfg := config.Config{
		APIPrefix:        "/v1",
		AuthGRPCAddr:     "127.0.0.1:19091",
		ProfileGRPCAddr:  "127.0.0.1:19092",
		MatchingGRPCAddr: "127.0.0.1:19093",
		ChatGRPCAddr:     "127.0.0.1:19094",
	}
	return newQuestWorkflowTestServerWithConfig(t, func(target *config.Config) {
		*target = cfg
	})
}

func newQuestWorkflowTestServerWithConfig(t *testing.T, mutate func(*config.Config)) *Server {
	t.Helper()

	cfg := config.Config{
		APIPrefix:        "/v1",
		AuthGRPCAddr:     "127.0.0.1:19091",
		ProfileGRPCAddr:  "127.0.0.1:19092",
		MatchingGRPCAddr: "127.0.0.1:19093",
		ChatGRPCAddr:     "127.0.0.1:19094",
	}
	if mutate != nil {
		mutate(&cfg)
	}
	reg := prometheus.NewRegistry()
	metrics := observability.NewHTTPMetrics(reg)

	server, err := NewServer(cfg, zap.NewNop(), metrics)
	if err != nil {
		t.Fatalf("NewServer() error = %v", err)
	}
	return server
}

func decodeJSONMap(t *testing.T, raw []byte) map[string]any {
	t.Helper()

	var payload map[string]any
	if err := json.Unmarshal(raw, &payload); err != nil {
		t.Fatalf("decode json payload: %v", err)
	}
	return payload
}

func toMap(t *testing.T, value any) map[string]any {
	t.Helper()

	out, ok := value.(map[string]any)
	if !ok {
		t.Fatalf("expected map payload, got %T", value)
	}
	return out
}

func stringValue(value any) string {
	if s, ok := value.(string); ok {
		return s
	}
	return ""
}

func boolValue(value any) bool {
	if b, ok := value.(bool); ok {
		return b
	}
	return false
}
