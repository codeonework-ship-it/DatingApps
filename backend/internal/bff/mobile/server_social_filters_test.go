package mobile

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"net/url"
	"testing"
	"time"
)

func TestServer_ApplyAdvancedFilterToRows(t *testing.T) {
	server := newQuestWorkflowTestServer(t)

	pet := "dog"
	country := "India"
	viewer := defaultDraft("viewer-1")
	viewer.IntentTags = []string{"long-term"}
	viewer.PetPreference = &pet
	viewer.Country = &country
	server.store.profiles["viewer-1"] = viewer

	targetGood := defaultDraft("target-good")
	targetGood.DateOfBirth = "1998-01-15"
	targetGood.IntentTags = []string{"long-term", "new friends"}
	targetGood.PetPreference = &pet
	targetGood.Country = &country
	server.store.profiles["target-good"] = targetGood

	targetBad := defaultDraft("target-bad")
	targetBad.DateOfBirth = "1998-01-15"
	targetBad.IntentTags = []string{"casual"}
	server.store.profiles["target-bad"] = targetBad

	rows := []any{
		map[string]any{"id": "target-good"},
		map[string]any{"id": "target-bad"},
	}

	query := url.Values{}
	query.Set("intent_tags", "long-term")
	query.Set("pet_preference", "dog")
	query.Set("country", "India")
	criteria := server.buildAdvancedCriteria("viewer-1", query)
	filtered, summary := server.applyAdvancedFilterToRows(rows, "id", criteria)
	if len(filtered) != 1 {
		t.Fatalf("expected 1 filtered row, got %d", len(filtered))
	}
	first, _ := filtered[0].(map[string]any)
	if first["id"] != "target-good" {
		t.Fatalf("unexpected remaining id: %v", first["id"])
	}
	if summary["filtered_out_count"] != 1 {
		t.Fatalf("expected filtered_out_count=1, got %v", summary["filtered_out_count"])
	}
}

func TestServer_ApplyAdvancedFilterToRows_AgeRange(t *testing.T) {
	server := newQuestWorkflowTestServer(t)

	targetYoung := defaultDraft("target-young")
	targetYoung.DateOfBirth = "2004-01-15"
	server.store.profiles["target-young"] = targetYoung

	targetOlder := defaultDraft("target-older")
	targetOlder.DateOfBirth = "1988-01-15"
	server.store.profiles["target-older"] = targetOlder

	rows := []any{
		map[string]any{"id": "target-young"},
		map[string]any{"id": "target-older"},
	}
	criteria := advancedFilterCriteria{minAgeYears: 18, maxAgeYears: 30}

	filtered, summary := server.applyAdvancedFilterToRows(rows, "id", criteria)
	if len(filtered) != 1 {
		t.Fatalf("expected 1 age-filtered row, got %d", len(filtered))
	}
	first, _ := filtered[0].(map[string]any)
	if first["id"] != "target-young" {
		t.Fatalf("unexpected remaining id: %v", first["id"])
	}
	if summary["filtered_out_count"] != 1 {
		t.Fatalf("expected filtered_out_count=1, got %v", summary["filtered_out_count"])
	}
}

func TestServer_FriendsEndpointsFlow(t *testing.T) {
	server := newQuestWorkflowTestServer(t)

	addReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/friends/user-a",
		bytes.NewBufferString(`{"friend_user_id":"user-b"}`),
	)
	addReq.Header.Set("Content-Type", "application/json")
	addRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(addRec, addReq)
	if addRec.Code != http.StatusOK {
		t.Fatalf("expected status 200 on add friend, got %d", addRec.Code)
	}
	var addPayload map[string]any
	if err := json.Unmarshal(addRec.Body.Bytes(), &addPayload); err != nil {
		t.Fatalf("failed to decode add response: %v", err)
	}
	friend, _ := addPayload["friend"].(map[string]any)
	if friend["status"] != "pending" || friend["direction"] != "outgoing" {
		t.Fatalf("friend request must remain outgoing/pending until consent: %#v", friend)
	}

	incomingReq := httptest.NewRequest(http.MethodGet, "/v1/friends/user-b", nil)
	incomingRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(incomingRec, incomingReq)
	var incomingPayload map[string]any
	if err := json.Unmarshal(incomingRec.Body.Bytes(), &incomingPayload); err != nil {
		t.Fatalf("failed to decode incoming response: %v", err)
	}
	incomingRows, _ := incomingPayload["friends"].([]any)
	if len(incomingRows) != 1 {
		t.Fatalf("recipient must see one incoming request, got %#v", incomingRows)
	}
	incoming, _ := incomingRows[0].(map[string]any)
	if incoming["direction"] != "incoming" || incoming["status"] != "pending" {
		t.Fatalf("recipient request direction/status mismatch: %#v", incoming)
	}

	decisionReq := httptest.NewRequest(http.MethodPost, "/v1/friends/user-b/user-a/decision", bytes.NewBufferString(`{"decision":"accept"}`))
	decisionReq.Header.Set("Content-Type", "application/json")
	decisionRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(decisionRec, decisionReq)
	if decisionRec.Code != http.StatusOK {
		t.Fatalf("expected status 200 on accept friend, got %d: %s", decisionRec.Code, decisionRec.Body.String())
	}

	listReq := httptest.NewRequest(http.MethodGet, "/v1/friends/user-a", nil)
	listRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(listRec, listReq)
	if listRec.Code != http.StatusOK {
		t.Fatalf("expected status 200 on list friends, got %d", listRec.Code)
	}

	var listPayload map[string]any
	if err := json.Unmarshal(listRec.Body.Bytes(), &listPayload); err != nil {
		t.Fatalf("failed to decode list response: %v", err)
	}
	friendsRaw, _ := listPayload["friends"].([]any)
	if len(friendsRaw) == 0 {
		t.Fatalf("expected at least one friend")
	}

	activitiesReq := httptest.NewRequest(http.MethodGet, "/v1/friends/user-a/activities", nil)
	activitiesRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(activitiesRec, activitiesReq)
	if activitiesRec.Code != http.StatusOK {
		t.Fatalf("expected status 200 on friend activities, got %d", activitiesRec.Code)
	}
}

func TestServer_FriendRequestDeclineAndBlockPreventConnection(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	if _, err := server.store.addFriend("user-a", "user-b"); err != nil {
		t.Fatalf("create request: %v", err)
	}
	if _, err := server.store.decideFriendRequest("user-b", "user-a", "decline"); err != nil {
		t.Fatalf("decline request: %v", err)
	}
	if got := server.store.listFriends("user-a"); len(got) != 0 {
		t.Fatalf("declined request must disappear for requester: %#v", got)
	}
	if got := server.store.listFriends("user-b"); len(got) != 0 {
		t.Fatalf("declined request must disappear for recipient: %#v", got)
	}

	// A decline starts a 7-day cooldown for the requester (migration 116).
	if _, err := server.store.addFriend("user-a", "user-b"); err == nil {
		t.Fatal("re-request inside the decline cooldown must fail")
	}
	server.store.friendDeclines["user-a|user-b"] = time.Now().Add(-8 * 24 * time.Hour)
	if _, err := server.store.addFriend("user-a", "user-b"); err != nil {
		t.Fatalf("recreate request: %v", err)
	}
	if err := server.store.blockUser("user-b", "user-a"); err != nil {
		t.Fatalf("block requester: %v", err)
	}
	if _, err := server.store.decideFriendRequest("user-b", "user-a", "accept"); err == nil {
		t.Fatal("blocked request must not be accepted")
	}
	if _, err := server.store.addFriend("user-a", "user-b"); err == nil {
		t.Fatal("blocked pair must not create another friend request")
	}
}
