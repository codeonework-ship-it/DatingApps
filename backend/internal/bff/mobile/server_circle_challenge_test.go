package mobile

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestServer_CircleChallengeLifecycle(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	getReq := httptest.NewRequest(
		http.MethodGet,
		"/v1/engagement/circles/circle-blr-books/challenge?user_id=user-circle-1",
		nil,
	)
	getRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(getRec, getReq)
	if getRec.Code != http.StatusOK {
		t.Fatalf("get circle challenge code=%d body=%s", getRec.Code, getRec.Body.String())
	}

	getPayload := decodeJSONMap(t, getRec.Body.Bytes())
	view := toMap(t, getPayload["circle_challenge"])
	challenge := toMap(t, view["challenge"])
	challengeID := stringValue(challenge["id"])
	if challengeID == "" {
		t.Fatalf("expected challenge id")
	}

	submitBody := `{
		"user_id": "user-circle-1",
		"challenge_id": "` + challengeID + `",
		"entry_text": "One quote that changed my week: consistency beats intensity.",
		"image_url": "https://example.com/book.jpg"
	}`
	submitReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/engagement/circles/circle-blr-books/challenge/entries",
		strings.NewReader(submitBody),
	)
	submitReq.Header.Set("Content-Type", "application/json")
	submitRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(submitRec, submitReq)
	if submitRec.Code != http.StatusOK {
		t.Fatalf("submit circle challenge code=%d body=%s", submitRec.Code, submitRec.Body.String())
	}

	submitPayload := decodeJSONMap(t, submitRec.Body.Bytes())
	submitView := toMap(t, submitPayload["circle_challenge"])
	if got := int(submitView["participation_count"].(float64)); got != 1 {
		t.Fatalf("expected participation_count=1, got %d", got)
	}

	server.store.mu.RLock()
	activities := server.store.listActivities(40)
	server.store.mu.RUnlock()
	assertActionSeen(t, activities, "circle_challenge_viewed")
	assertActionSeen(t, activities, "circle_challenge_submitted")
}

func TestServer_CircleChallengeDuplicateSubmission(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	firstBody := `{
		"user_id": "user-circle-2",
		"entry_text": "My weekly challenge entry with enough detail."
	}`
	firstReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/engagement/circles/circle-blr-fitness/challenge/entries",
		strings.NewReader(firstBody),
	)
	firstReq.Header.Set("Content-Type", "application/json")
	firstRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(firstRec, firstReq)
	if firstRec.Code != http.StatusOK {
		t.Fatalf("first submit code=%d body=%s", firstRec.Code, firstRec.Body.String())
	}

	secondReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/engagement/circles/circle-blr-fitness/challenge/entries",
		strings.NewReader(firstBody),
	)
	secondReq.Header.Set("Content-Type", "application/json")
	secondRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(secondRec, secondReq)
	if secondRec.Code != http.StatusConflict {
		t.Fatalf("expected duplicate submit status=409, got code=%d body=%s", secondRec.Code, secondRec.Body.String())
	}
}

func TestServer_CircleChallengeNotFound(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	getReq := httptest.NewRequest(
		http.MethodGet,
		"/v1/engagement/circles/circle-unknown/challenge?user_id=user-circle-3",
		nil,
	)
	getRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(getRec, getReq)
	if getRec.Code != http.StatusNotFound {
		t.Fatalf("expected unknown circle status=404, got code=%d body=%s", getRec.Code, getRec.Body.String())
	}
}

func TestServer_JoinCircleAndChallengeViewMembership(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	joinReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/engagement/circles/circle-blr-books/join",
		strings.NewReader(`{"user_id":"user-circle-join-1"}`),
	)
	joinReq.Header.Set("Content-Type", "application/json")
	joinRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(joinRec, joinReq)
	if joinRec.Code != http.StatusOK {
		t.Fatalf("join circle code=%d body=%s", joinRec.Code, joinRec.Body.String())
	}
	joinPayload := decodeJSONMap(t, joinRec.Body.Bytes())
	membership := toMap(t, joinPayload["membership"])
	if got := boolValue(membership["is_joined"]); !got {
		t.Fatalf("expected membership is_joined=true")
	}

	getReq := httptest.NewRequest(
		http.MethodGet,
		"/v1/engagement/circles/circle-blr-books/challenge?user_id=user-circle-join-1",
		nil,
	)
	getRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(getRec, getReq)
	if getRec.Code != http.StatusOK {
		t.Fatalf("get circle challenge code=%d body=%s", getRec.Code, getRec.Body.String())
	}
	getPayload := decodeJSONMap(t, getRec.Body.Bytes())
	view := toMap(t, getPayload["circle_challenge"])
	if got := boolValue(view["is_joined"]); !got {
		t.Fatalf("expected challenge view is_joined=true")
	}

	server.store.mu.RLock()
	activities := server.store.listActivities(40)
	server.store.mu.RUnlock()
	assertActionSeen(t, activities, "circle_joined")
}
