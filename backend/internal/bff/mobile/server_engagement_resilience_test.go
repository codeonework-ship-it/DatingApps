package mobile

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
)

func TestServer_QuestReviewRetry_ReplaysCachedResponse(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	upsertTemplateBody := `{
		"creator_user_id": "user-a",
		"prompt_template": "Share one relationship value and a concrete example.",
		"min_chars": 20,
		"max_chars": 200
	}`
	upsertReq := httptest.NewRequest(
		http.MethodPut,
		"/v1/matches/match-resilience-review/quest-template",
		strings.NewReader(upsertTemplateBody),
	)
	upsertReq.Header.Set("Content-Type", "application/json")
	upsertRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(upsertRec, upsertReq)
	if upsertRec.Code != http.StatusOK {
		t.Fatalf("upsert template code = %d body=%s", upsertRec.Code, upsertRec.Body.String())
	}

	submitBody := `{
		"submitter_user_id": "user-a",
		"response_text": "I prioritize emotional accountability and I revisit conflict with calm follow-through and clearer commitments."
	}`
	submitReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/matches/match-resilience-review/quest-workflow/submit",
		strings.NewReader(submitBody),
	)
	submitReq.Header.Set("Content-Type", "application/json")
	submitRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(submitRec, submitReq)
	if submitRec.Code != http.StatusOK {
		t.Fatalf("submit workflow code = %d body=%s", submitRec.Code, submitRec.Body.String())
	}

	reviewBody := `{
		"reviewer_user_id": "user-b",
		"decision_status": "approved"
	}`
	firstReviewReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/matches/match-resilience-review/quest-workflow/review",
		strings.NewReader(reviewBody),
	)
	firstReviewReq.Header.Set("Content-Type", "application/json")
	firstReviewReq.Header.Set("Idempotency-Key", "idem-review-1")
	firstReviewRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(firstReviewRec, firstReviewReq)
	if firstReviewRec.Code != http.StatusOK {
		t.Fatalf("first review code=%d body=%s", firstReviewRec.Code, firstReviewRec.Body.String())
	}
	firstPayload := decodeJSONMap(t, firstReviewRec.Body.Bytes())
	firstWorkflow := toMap(t, firstPayload["quest_workflow"])
	if got := stringValue(firstWorkflow["status"]); got != "approved" {
		t.Fatalf("expected approved after first review, got %q", got)
	}

	retryReviewReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/matches/match-resilience-review/quest-workflow/review",
		strings.NewReader(reviewBody),
	)
	retryReviewReq.Header.Set("Content-Type", "application/json")
	retryReviewReq.Header.Set("Idempotency-Key", "idem-review-1")
	retryReviewRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(retryReviewRec, retryReviewReq)
	if retryReviewRec.Code != http.StatusOK {
		t.Fatalf("retry review code=%d body=%s", retryReviewRec.Code, retryReviewRec.Body.String())
	}
	if got := retryReviewRec.Header().Get("X-Idempotent-Replay"); got != "true" {
		t.Fatalf("expected replay header true, got %q", got)
	}

	getReq := httptest.NewRequest(http.MethodGet, "/v1/matches/match-resilience-review/quest-workflow", nil)
	getRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(getRec, getReq)
	if getRec.Code != http.StatusOK {
		t.Fatalf("get workflow code=%d body=%s", getRec.Code, getRec.Body.String())
	}
	getPayload := decodeJSONMap(t, getRec.Body.Bytes())
	workflow := toMap(t, getPayload["quest_workflow"])
	if got := stringValue(workflow["status"]); got != "approved" {
		t.Fatalf("expected approved status after retry, got %q", got)
	}
}

func TestServer_ActivitySummaryRetry_PersistsPartialTimeoutSummary(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	startBody := `{
		"match_id": "match-resilience-activity",
		"initiator_user_id": "user-a",
		"participant_user_id": "user-b"
	}`
	startReq := httptest.NewRequest(http.MethodPost, "/v1/activities/sessions/start", strings.NewReader(startBody))
	startReq.Header.Set("Content-Type", "application/json")
	startRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(startRec, startReq)
	if startRec.Code != http.StatusOK {
		t.Fatalf("start activity session code=%d body=%s", startRec.Code, startRec.Body.String())
	}
	startPayload := decodeJSONMap(t, startRec.Body.Bytes())
	session := toMap(t, startPayload["session"])
	sessionID := stringValue(session["id"])
	if sessionID == "" {
		t.Fatalf("expected session id")
	}

	submitBody := `{"user_id":"user-a","responses":["clarity","respect"]}`
	submitReq := httptest.NewRequest(http.MethodPost, "/v1/activities/sessions/"+sessionID+"/submit", strings.NewReader(submitBody))
	submitReq.Header.Set("Content-Type", "application/json")
	submitRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(submitRec, submitReq)
	if submitRec.Code != http.StatusOK {
		t.Fatalf("submit activity code=%d body=%s", submitRec.Code, submitRec.Body.String())
	}

	server.store.mu.Lock()
	existing := server.store.activitySessions[sessionID]
	existing.ExpiresAt = time.Now().UTC().Add(-1 * time.Second).Format(time.RFC3339)
	server.store.activitySessions[sessionID] = existing
	server.store.mu.Unlock()

	summaryReq1 := httptest.NewRequest(http.MethodGet, "/v1/activities/sessions/"+sessionID+"/summary", nil)
	summaryRec1 := httptest.NewRecorder()
	server.Handler().ServeHTTP(summaryRec1, summaryReq1)
	if summaryRec1.Code != http.StatusOK {
		t.Fatalf("summary first code=%d body=%s", summaryRec1.Code, summaryRec1.Body.String())
	}
	payload1 := decodeJSONMap(t, summaryRec1.Body.Bytes())
	summary1 := toMap(t, payload1["summary"])
	if got := stringValue(summary1["status"]); got != activitySessionStatusPartialTimeout {
		t.Fatalf("expected partial_timeout status, got %q", got)
	}

	summaryReq2 := httptest.NewRequest(http.MethodGet, "/v1/activities/sessions/"+sessionID+"/summary", nil)
	summaryRec2 := httptest.NewRecorder()
	server.Handler().ServeHTTP(summaryRec2, summaryReq2)
	if summaryRec2.Code != http.StatusOK {
		t.Fatalf("summary retry code=%d body=%s", summaryRec2.Code, summaryRec2.Body.String())
	}
	payload2 := decodeJSONMap(t, summaryRec2.Body.Bytes())
	summary2 := toMap(t, payload2["summary"])
	if stringValue(summary2["status"]) != activitySessionStatusPartialTimeout {
		t.Fatalf("expected partial_timeout status on retry")
	}
	if summary1["generated_at"] != summary2["generated_at"] {
		t.Fatalf("expected persisted summary generated_at to remain stable across retries")
	}
}

func TestServer_GestureDecisionRetry_ReplaysCachedResponseAndAvoidsDuplicateActivity(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	createBody := `{
		"sender_user_id": "user-a",
		"receiver_user_id": "user-b",
		"gesture_type": "thoughtful_opener",
		"content_text": "I value consistency, calm communication, and respectful effort.",
		"tone": "warm"
	}`
	createReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/matches/match-resilience-gesture/gestures",
		strings.NewReader(createBody),
	)
	createReq.Header.Set("Content-Type", "application/json")
	createRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(createRec, createReq)
	if createRec.Code != http.StatusOK {
		t.Fatalf("create gesture code=%d body=%s", createRec.Code, createRec.Body.String())
	}
	createPayload := decodeJSONMap(t, createRec.Body.Bytes())
	gesture := toMap(t, createPayload["gesture"])
	gestureID := stringValue(gesture["id"])
	if gestureID == "" {
		t.Fatalf("expected gesture id")
	}

	decisionBody := `{"reviewer_user_id":"user-b","decision":"appreciate"}`
	firstDecisionReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/matches/match-resilience-gesture/gestures/"+gestureID+"/decision",
		strings.NewReader(decisionBody),
	)
	firstDecisionReq.Header.Set("Content-Type", "application/json")
	firstDecisionReq.Header.Set("Idempotency-Key", "idem-gesture-decision-1")
	firstDecisionRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(firstDecisionRec, firstDecisionReq)
	if firstDecisionRec.Code != http.StatusOK {
		t.Fatalf("first decision code=%d body=%s", firstDecisionRec.Code, firstDecisionRec.Body.String())
	}

	retryDecisionReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/matches/match-resilience-gesture/gestures/"+gestureID+"/decision",
		strings.NewReader(decisionBody),
	)
	retryDecisionReq.Header.Set("Content-Type", "application/json")
	retryDecisionReq.Header.Set("Idempotency-Key", "idem-gesture-decision-1")
	retryDecisionRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(retryDecisionRec, retryDecisionReq)
	if retryDecisionRec.Code != http.StatusOK {
		t.Fatalf("retry decision code=%d body=%s", retryDecisionRec.Code, retryDecisionRec.Body.String())
	}
	if got := retryDecisionRec.Header().Get("X-Idempotent-Replay"); got != "true" {
		t.Fatalf("expected replay header true, got %q", got)
	}

	activities := server.store.listActivities(100)
	count := 0
	for _, item := range activities {
		if item.Action == "gesture.decision" {
			count++
		}
	}
	if count != 1 {
		t.Fatalf("expected exactly one gesture.decision activity, got %d", count)
	}
}
