package mobile

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestServer_GestureTimelineDecisionAndScore(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	createBody := `{
		"sender_user_id": "user-a",
		"receiver_user_id": "user-b",
		"gesture_type": "thoughtful_opener",
		"content_text": "I noticed your reading list and loved how reflective your profile feels. I value consistency and calm communication, and I would like to know what intentional effort means to you in a relationship.",
		"tone": "warm"
	}`
	createReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/matches/match-gesture-1/gestures",
		strings.NewReader(createBody),
	)
	createReq.Header.Set("Content-Type", "application/json")
	createRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(createRec, createReq)
	if createRec.Code != http.StatusOK {
		t.Fatalf("create gesture code = %d body=%s", createRec.Code, createRec.Body.String())
	}

	createPayload := decodeJSONMap(t, createRec.Body.Bytes())
	gesture := toMap(t, createPayload["gesture"])
	gestureID := stringValue(gesture["id"])
	if gestureID == "" {
		t.Fatalf("expected gesture id")
	}
	if got := stringValue(gesture["status"]); got != "sent" {
		t.Fatalf("expected status sent, got %q", got)
	}

	timelineReq := httptest.NewRequest(http.MethodGet, "/v1/matches/match-gesture-1/timeline", nil)
	timelineRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(timelineRec, timelineReq)
	if timelineRec.Code != http.StatusOK {
		t.Fatalf("timeline code = %d body=%s", timelineRec.Code, timelineRec.Body.String())
	}

	timelinePayload := decodeJSONMap(t, timelineRec.Body.Bytes())
	timeline, ok := timelinePayload["timeline"].([]any)
	if !ok || len(timeline) == 0 {
		t.Fatalf("expected non-empty timeline payload")
	}

	decisionBody := `{
		"reviewer_user_id": "user-b",
		"decision": "appreciate"
	}`
	decisionReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/matches/match-gesture-1/gestures/"+gestureID+"/decision",
		strings.NewReader(decisionBody),
	)
	decisionReq.Header.Set("Content-Type", "application/json")
	decisionRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(decisionRec, decisionReq)
	if decisionRec.Code != http.StatusOK {
		t.Fatalf("decision code = %d body=%s", decisionRec.Code, decisionRec.Body.String())
	}

	decisionPayload := decodeJSONMap(t, decisionRec.Body.Bytes())
	updatedGesture := toMap(t, decisionPayload["gesture"])
	if got := stringValue(updatedGesture["status"]); got != "appreciated" {
		t.Fatalf("expected appreciated status after decision, got %q", got)
	}

	scoreReq := httptest.NewRequest(
		http.MethodGet,
		"/v1/matches/match-gesture-1/gestures/"+gestureID+"/score",
		nil,
	)
	scoreRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(scoreRec, scoreReq)
	if scoreRec.Code != http.StatusOK {
		t.Fatalf("score code = %d body=%s", scoreRec.Code, scoreRec.Body.String())
	}

	scorePayload := decodeJSONMap(t, scoreRec.Body.Bytes())
	effort := toMap(t, scorePayload["effort_score"])
	if got := stringValue(effort["gesture_id"]); got != gestureID {
		t.Fatalf("expected score for gesture %s, got %q", gestureID, got)
	}
	if got := stringValue(effort["status"]); got != "appreciated" {
		t.Fatalf("expected appreciated status in score payload, got %q", got)
	}
}

func TestServer_GestureScoreFlagsProfanity(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	createBody := `{
		"sender_user_id": "user-a",
		"receiver_user_id": "user-b",
		"gesture_type": "micro_card",
		"content_text": "This is a thoughtful card but it includes shit language to trigger moderation signals while still having enough words for baseline quality checks.",
		"tone": "direct"
	}`
	createReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/matches/match-gesture-2/gestures",
		strings.NewReader(createBody),
	)
	createReq.Header.Set("Content-Type", "application/json")
	createRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(createRec, createReq)
	if createRec.Code != http.StatusOK {
		t.Fatalf("create gesture code = %d body=%s", createRec.Code, createRec.Body.String())
	}

	createPayload := decodeJSONMap(t, createRec.Body.Bytes())
	gesture := toMap(t, createPayload["gesture"])
	gestureID := stringValue(gesture["id"])
	if gestureID == "" {
		t.Fatalf("expected gesture id")
	}

	scoreReq := httptest.NewRequest(
		http.MethodGet,
		"/v1/matches/match-gesture-2/gestures/"+gestureID+"/score",
		nil,
	)
	scoreRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(scoreRec, scoreReq)
	if scoreRec.Code != http.StatusOK {
		t.Fatalf("score code = %d body=%s", scoreRec.Code, scoreRec.Body.String())
	}

	scorePayload := decodeJSONMap(t, scoreRec.Body.Bytes())
	effort := toMap(t, scorePayload["effort_score"])
	if flagged, ok := effort["profanity_flagged"].(bool); !ok || !flagged {
		t.Fatalf("expected profanity_flagged true, got %v", effort["profanity_flagged"])
	}
	if flagged, ok := effort["safety_flagged"].(bool); !ok || !flagged {
		t.Fatalf("expected safety_flagged true, got %v", effort["safety_flagged"])
	}
}
