package mobile

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestServer_MatchNudgeLifecycle(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	sendBody := `{
		"match_id": "match-nudge-1",
		"user_id": "user-nudged-1",
		"counterparty_user_id": "user-counterparty-1",
		"nudge_type": "stalled_3h"
	}`
	sendReq := httptest.NewRequest(http.MethodPost, "/v1/engagement/match-nudges/send", strings.NewReader(sendBody))
	sendReq.Header.Set("Content-Type", "application/json")
	sendRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(sendRec, sendReq)
	if sendRec.Code != http.StatusOK {
		t.Fatalf("send nudge code=%d body=%s", sendRec.Code, sendRec.Body.String())
	}

	sendPayload := decodeJSONMap(t, sendRec.Body.Bytes())
	nudge := toMap(t, sendPayload["nudge"])
	nudgeID := stringValue(nudge["id"])
	if nudgeID == "" {
		t.Fatalf("expected nudge id")
	}

	clickBody := `{"user_id":"user-nudged-1"}`
	clickReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/engagement/match-nudges/"+nudgeID+"/click",
		strings.NewReader(clickBody),
	)
	clickReq.Header.Set("Content-Type", "application/json")
	clickRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(clickRec, clickReq)
	if clickRec.Code != http.StatusOK {
		t.Fatalf("click nudge code=%d body=%s", clickRec.Code, clickRec.Body.String())
	}

	resumeBody := `{"user_id":"user-nudged-1", "trigger_nudge_id":"` + nudgeID + `"}`
	resumeReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/engagement/matches/match-nudge-1/resume",
		strings.NewReader(resumeBody),
	)
	resumeReq.Header.Set("Content-Type", "application/json")
	resumeRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(resumeRec, resumeReq)
	if resumeRec.Code != http.StatusOK {
		t.Fatalf("resume code=%d body=%s", resumeRec.Code, resumeRec.Body.String())
	}

	server.store.mu.RLock()
	activities := server.store.listActivities(40)
	server.store.mu.RUnlock()
	assertActionSeen(t, activities, "match_nudge_sent")
	assertActionSeen(t, activities, "match_nudge_clicked")
	assertActionSeen(t, activities, "conversation_resumed")
}

func TestServer_MatchNudgeDailyCap(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	firstBody := `{
		"match_id": "match-cap-1",
		"user_id": "user-cap",
		"counterparty_user_id": "user-cap-counterparty",
		"nudge_type": "stalled_3h"
	}`
	secondBody := `{
		"match_id": "match-cap-2",
		"user_id": "user-cap",
		"counterparty_user_id": "user-cap-counterparty",
		"nudge_type": "stalled_24h"
	}`
	thirdBody := `{
		"match_id": "match-cap-3",
		"user_id": "user-cap",
		"counterparty_user_id": "user-cap-counterparty",
		"nudge_type": "stalled_24h"
	}`

	for _, body := range []string{firstBody, secondBody} {
		req := httptest.NewRequest(http.MethodPost, "/v1/engagement/match-nudges/send", strings.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		server.Handler().ServeHTTP(rec, req)
		if rec.Code != http.StatusOK {
			t.Fatalf("expected initial nudge send success, got code=%d body=%s", rec.Code, rec.Body.String())
		}
	}

	thirdReq := httptest.NewRequest(http.MethodPost, "/v1/engagement/match-nudges/send", strings.NewReader(thirdBody))
	thirdReq.Header.Set("Content-Type", "application/json")
	thirdRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(thirdRec, thirdReq)
	if thirdRec.Code != http.StatusTooManyRequests {
		t.Fatalf("expected daily cap status=429, got code=%d body=%s", thirdRec.Code, thirdRec.Body.String())
	}
}

func TestServer_MatchNudgeSuppressedWhenBlockedOrReported(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	server.store.blockUser("user-safety", "user-safety-counterparty")

	blockedBody := `{
		"match_id": "match-safety-1",
		"user_id": "user-safety",
		"counterparty_user_id": "user-safety-counterparty",
		"nudge_type": "stalled_3h"
	}`
	blockedReq := httptest.NewRequest(http.MethodPost, "/v1/engagement/match-nudges/send", strings.NewReader(blockedBody))
	blockedReq.Header.Set("Content-Type", "application/json")
	blockedRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(blockedRec, blockedReq)
	if blockedRec.Code != http.StatusConflict {
		t.Fatalf("expected blocked nudge status=409, got code=%d body=%s", blockedRec.Code, blockedRec.Body.String())
	}

	server.store.unblockUser("user-safety", "user-safety-counterparty")
	_, err := server.store.createReport("user-safety", "user-safety-counterparty", "harassment", "recent issue")
	if err != nil {
		t.Fatalf("create report error=%v", err)
	}

	reportedReq := httptest.NewRequest(http.MethodPost, "/v1/engagement/match-nudges/send", strings.NewReader(blockedBody))
	reportedReq.Header.Set("Content-Type", "application/json")
	reportedRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(reportedRec, reportedReq)
	if reportedRec.Code != http.StatusConflict {
		t.Fatalf("expected reported nudge status=409, got code=%d body=%s", reportedRec.Code, reportedRec.Body.String())
	}
}
