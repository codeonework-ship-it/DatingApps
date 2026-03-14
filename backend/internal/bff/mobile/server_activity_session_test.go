package mobile

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
)

func TestServer_ActivitySessionLifecycleComplete(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	startBody := `{
		"match_id": "match-activity-1",
		"initiator_user_id": "user-a",
		"participant_user_id": "user-b",
		"activity_type": "value_match_round"
	}`
	startReq := httptest.NewRequest(http.MethodPost, "/v1/activities/sessions/start", strings.NewReader(startBody))
	startReq.Header.Set("Content-Type", "application/json")
	startRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(startRec, startReq)
	if startRec.Code != http.StatusOK {
		t.Fatalf("start activity session code = %d body=%s", startRec.Code, startRec.Body.String())
	}
	startPayload := decodeJSONMap(t, startRec.Body.Bytes())
	session := toMap(t, startPayload["session"])
	sessionID := stringValue(session["id"])
	if sessionID == "" {
		t.Fatalf("expected session id")
	}
	if got := stringValue(session["status"]); got != activitySessionStatusActive {
		t.Fatalf("expected active status, got %q", got)
	}

	submitABody := `{
		"user_id": "user-a",
		"responses": ["family", "consistency", "communication"]
	}`
	submitAReq := httptest.NewRequest(http.MethodPost, "/v1/activities/sessions/"+sessionID+"/submit", strings.NewReader(submitABody))
	submitAReq.Header.Set("Content-Type", "application/json")
	submitARec := httptest.NewRecorder()
	server.Handler().ServeHTTP(submitARec, submitAReq)
	if submitARec.Code != http.StatusOK {
		t.Fatalf("submit A code = %d body=%s", submitARec.Code, submitARec.Body.String())
	}

	submitBBody := `{
		"user_id": "user-b",
		"responses": ["honesty", "patience", "shared goals"]
	}`
	submitBReq := httptest.NewRequest(http.MethodPost, "/v1/activities/sessions/"+sessionID+"/submit", strings.NewReader(submitBBody))
	submitBReq.Header.Set("Content-Type", "application/json")
	submitBRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(submitBRec, submitBReq)
	if submitBRec.Code != http.StatusOK {
		t.Fatalf("submit B code = %d body=%s", submitBRec.Code, submitBRec.Body.String())
	}
	submitBPayload := decodeJSONMap(t, submitBRec.Body.Bytes())
	sessionAfter := toMap(t, submitBPayload["session"])
	if got := stringValue(sessionAfter["status"]); got != activitySessionStatusCompleted {
		t.Fatalf("expected completed status after both submissions, got %q", got)
	}

	summaryReq := httptest.NewRequest(http.MethodGet, "/v1/activities/sessions/"+sessionID+"/summary?user_id=user-a", nil)
	summaryRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(summaryRec, summaryReq)
	if summaryRec.Code != http.StatusOK {
		t.Fatalf("summary code = %d body=%s", summaryRec.Code, summaryRec.Body.String())
	}
	summaryPayload := decodeJSONMap(t, summaryRec.Body.Bytes())
	summary := toMap(t, summaryPayload["summary"])
	if got := stringValue(summary["status"]); got != activitySessionStatusCompleted {
		t.Fatalf("expected summary status completed, got %q", got)
	}
	if got := int(summary["responses_submitted"].(float64)); got != 2 {
		t.Fatalf("expected 2 responses submitted, got %d", got)
	}

	server.store.mu.RLock()
	activities := server.store.listActivities(100)
	server.store.mu.RUnlock()
	assertActionSeen(t, activities, "mini_activity_started")
	assertActionSeen(t, activities, "mini_activity_completed")
	assertActionSeen(t, activities, "mini_activity_shared")
}

func TestServer_ActivitySessionPartialTimeoutAndSummaryPersistence(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	startBody := `{
		"match_id": "match-activity-2",
		"initiator_user_id": "user-a",
		"participant_user_id": "user-b"
	}`
	startReq := httptest.NewRequest(http.MethodPost, "/v1/activities/sessions/start", strings.NewReader(startBody))
	startReq.Header.Set("Content-Type", "application/json")
	startRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(startRec, startReq)
	if startRec.Code != http.StatusOK {
		t.Fatalf("start activity session code = %d body=%s", startRec.Code, startRec.Body.String())
	}
	startPayload := decodeJSONMap(t, startRec.Body.Bytes())
	session := toMap(t, startPayload["session"])
	sessionID := stringValue(session["id"])
	if sessionID == "" {
		t.Fatalf("expected session id")
	}

	submitABody := `{
		"user_id": "user-a",
		"responses": ["clarity", "kindness"]
	}`
	submitAReq := httptest.NewRequest(http.MethodPost, "/v1/activities/sessions/"+sessionID+"/submit", strings.NewReader(submitABody))
	submitAReq.Header.Set("Content-Type", "application/json")
	submitARec := httptest.NewRecorder()
	server.Handler().ServeHTTP(submitARec, submitAReq)
	if submitARec.Code != http.StatusOK {
		t.Fatalf("submit A code = %d body=%s", submitARec.Code, submitARec.Body.String())
	}

	server.store.mu.Lock()
	existing := server.store.activitySessions[sessionID]
	existing.ExpiresAt = time.Now().UTC().Add(-1 * time.Second).Format(time.RFC3339)
	server.store.activitySessions[sessionID] = existing
	server.store.mu.Unlock()

	summaryReq := httptest.NewRequest(http.MethodGet, "/v1/activities/sessions/"+sessionID+"/summary", nil)
	summaryRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(summaryRec, summaryReq)
	if summaryRec.Code != http.StatusOK {
		t.Fatalf("summary code = %d body=%s", summaryRec.Code, summaryRec.Body.String())
	}
	summaryPayload := decodeJSONMap(t, summaryRec.Body.Bytes())
	summary := toMap(t, summaryPayload["summary"])
	if got := stringValue(summary["status"]); got != activitySessionStatusPartialTimeout {
		t.Fatalf("expected partial_timeout summary status, got %q", got)
	}
	if got := int(summary["responses_submitted"].(float64)); got != 1 {
		t.Fatalf("expected 1 response submitted, got %d", got)
	}

	submitBBody := `{
		"user_id": "user-b",
		"responses": ["mutual respect"]
	}`
	submitBReq := httptest.NewRequest(http.MethodPost, "/v1/activities/sessions/"+sessionID+"/submit", strings.NewReader(submitBBody))
	submitBReq.Header.Set("Content-Type", "application/json")
	submitBRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(submitBRec, submitBReq)
	if submitBRec.Code != http.StatusRequestTimeout {
		t.Fatalf("expected timeout after session expiry, got %d body=%s", submitBRec.Code, submitBRec.Body.String())
	}
}

func TestServer_ActivitySessionThisOrThatReplayLimit(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	startBody := `{
		"match_id": "match-activity-replay-limit",
		"initiator_user_id": "user-a",
		"participant_user_id": "user-b",
		"activity_type": "this_or_that"
	}`

	for attempt := 1; attempt <= 2; attempt++ {
		startReq := httptest.NewRequest(http.MethodPost, "/v1/activities/sessions/start", strings.NewReader(startBody))
		startReq.Header.Set("Content-Type", "application/json")
		startRec := httptest.NewRecorder()
		server.Handler().ServeHTTP(startRec, startReq)
		if startRec.Code != http.StatusOK {
			t.Fatalf("attempt %d expected 200, got %d body=%s", attempt, startRec.Code, startRec.Body.String())
		}
	}

	thirdReq := httptest.NewRequest(http.MethodPost, "/v1/activities/sessions/start", strings.NewReader(startBody))
	thirdReq.Header.Set("Content-Type", "application/json")
	thirdRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(thirdRec, thirdReq)
	if thirdRec.Code != http.StatusBadRequest {
		t.Fatalf("expected 400 on replay limit, got %d body=%s", thirdRec.Code, thirdRec.Body.String())
	}
	if !strings.Contains(strings.ToLower(thirdRec.Body.String()), "weekly replay limit") {
		t.Fatalf("expected weekly replay limit message, got %s", thirdRec.Body.String())
	}
}
