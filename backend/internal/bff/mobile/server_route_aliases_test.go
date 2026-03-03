package mobile

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestServer_RouteAliases_QuestWorkflowParity(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	upsertBody := `{
		"creator_user_id": "user-a",
		"prompt_template": "Share one meaningful value and how it changed your behavior.",
		"min_chars": 20,
		"max_chars": 200
	}`
	upsertReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/matches/match-alias-quest/unlock-requirements",
		strings.NewReader(upsertBody),
	)
	upsertReq.Header.Set("Content-Type", "application/json")
	upsertRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(upsertRec, upsertReq)
	if upsertRec.Code != http.StatusOK {
		t.Fatalf("upsert alias code=%d body=%s", upsertRec.Code, upsertRec.Body.String())
	}

	submitBody := `{
		"submitter_user_id": "user-a",
		"response_text": "I learned to communicate boundaries clearly and to repair quickly after misunderstandings."
	}`
	submitReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/matches/match-alias-quest/quests/submit",
		strings.NewReader(submitBody),
	)
	submitReq.Header.Set("Content-Type", "application/json")
	submitRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(submitRec, submitReq)
	if submitRec.Code != http.StatusOK {
		t.Fatalf("submit alias code=%d body=%s", submitRec.Code, submitRec.Body.String())
	}

	reviewBody := `{
		"reviewer_user_id": "user-b",
		"decision_status": "approved"
	}`
	reviewReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/matches/match-alias-quest/quests/submission-any/review",
		strings.NewReader(reviewBody),
	)
	reviewReq.Header.Set("Content-Type", "application/json")
	reviewRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(reviewRec, reviewReq)
	if reviewRec.Code != http.StatusOK {
		t.Fatalf("review alias code=%d body=%s", reviewRec.Code, reviewRec.Body.String())
	}

	getReq := httptest.NewRequest(http.MethodGet, "/v1/matches/match-alias-quest/quests", nil)
	getRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(getRec, getReq)
	if getRec.Code != http.StatusOK {
		t.Fatalf("get alias code=%d body=%s", getRec.Code, getRec.Body.String())
	}
	payload := decodeJSONMap(t, getRec.Body.Bytes())
	workflow := toMap(t, payload["quest_workflow"])
	if got := stringValue(workflow["status"]); got != "approved" {
		t.Fatalf("expected approved status from alias flow, got %q", got)
	}
}

func TestServer_RouteAliases_GestureEndpointsParity(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	createBody := `{
		"sender_user_id": "user-a",
		"receiver_user_id": "user-b",
		"gesture_type": "thoughtful_opener",
		"content_text": "I appreciate your clarity and I value intentional communication with consistency.",
		"tone": "warm"
	}`
	createReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/matches/match-alias-gesture/gestures",
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

	listReq := httptest.NewRequest(http.MethodGet, "/v1/matches/match-alias-gesture/gestures", nil)
	listRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(listRec, listReq)
	if listRec.Code != http.StatusOK {
		t.Fatalf("list gestures alias code=%d body=%s", listRec.Code, listRec.Body.String())
	}
	listPayload := decodeJSONMap(t, listRec.Body.Bytes())
	if _, ok := listPayload["timeline"].([]any); !ok {
		t.Fatalf("expected timeline payload for gestures alias")
	}

	respondBody := `{
		"reviewer_user_id": "user-b",
		"decision": "appreciate"
	}`
	respondReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/matches/match-alias-gesture/gestures/"+gestureID+"/respond",
		strings.NewReader(respondBody),
	)
	respondReq.Header.Set("Content-Type", "application/json")
	respondRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(respondRec, respondReq)
	if respondRec.Code != http.StatusOK {
		t.Fatalf("respond alias code=%d body=%s", respondRec.Code, respondRec.Body.String())
	}
}

func TestServer_RouteAliases_ActivityEndpointsParity(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	startBody := `{
		"match_id": "match-alias-activity",
		"initiator_user_id": "user-a",
		"participant_user_id": "user-b",
		"activity_type": "this_or_that"
	}`
	startReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/matches/match-alias-activity/activities/start",
		strings.NewReader(startBody),
	)
	startReq.Header.Set("Content-Type", "application/json")
	startRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(startRec, startReq)
	if startRec.Code != http.StatusOK {
		t.Fatalf("start alias code=%d body=%s", startRec.Code, startRec.Body.String())
	}
	startPayload := decodeJSONMap(t, startRec.Body.Bytes())
	session := toMap(t, startPayload["session"])
	sessionID := stringValue(session["id"])
	if sessionID == "" {
		t.Fatalf("expected session id from alias start")
	}

	submitBody := `{"user_id":"user-a","responses":["A","B"]}`
	submitReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/activities/"+sessionID+"/responses",
		strings.NewReader(submitBody),
	)
	submitReq.Header.Set("Content-Type", "application/json")
	submitRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(submitRec, submitReq)
	if submitRec.Code != http.StatusOK {
		t.Fatalf("submit alias code=%d body=%s", submitRec.Code, submitRec.Body.String())
	}

	summaryReq := httptest.NewRequest(http.MethodGet, "/v1/activities/"+sessionID+"/summary", nil)
	summaryRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(summaryRec, summaryReq)
	if summaryRec.Code != http.StatusOK {
		t.Fatalf("summary alias code=%d body=%s", summaryRec.Code, summaryRec.Body.String())
	}
	summaryPayload := decodeJSONMap(t, summaryRec.Body.Bytes())
	if _, ok := summaryPayload["summary"].(map[string]any); !ok {
		t.Fatalf("expected summary payload from alias summary route")
	}
}

func TestServer_RouteAliases_DeprecationHeadersPresent(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	upsertBody := `{
		"creator_user_id": "user-a",
		"prompt_template": "Share one value you practice daily.",
		"min_chars": 10,
		"max_chars": 120
	}`
	upsertReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/matches/match-alias-deprecation/unlock-requirements",
		strings.NewReader(upsertBody),
	)
	upsertReq.Header.Set("Content-Type", "application/json")
	upsertRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(upsertRec, upsertReq)

	if upsertRec.Code != http.StatusOK {
		t.Fatalf("upsert alias code=%d body=%s", upsertRec.Code, upsertRec.Body.String())
	}
	if got := upsertRec.Header().Get("Deprecation"); got != "true" {
		t.Fatalf("expected Deprecation=true header, got %q", got)
	}
	if got := upsertRec.Header().Get("Sunset"); got == "" {
		t.Fatalf("expected Sunset header on alias response")
	}
	if got := upsertRec.Header().Get("Link"); !strings.Contains(got, "/v1/matches/{matchID}/quest-template") {
		t.Fatalf("expected successor Link header, got %q", got)
	}
}
