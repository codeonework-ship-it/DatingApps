package mobile

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
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
	targetGood.IntentTags = []string{"long-term", "new friends"}
	targetGood.PetPreference = &pet
	targetGood.Country = &country
	server.store.profiles["target-good"] = targetGood

	targetBad := defaultDraft("target-bad")
	targetBad.IntentTags = []string{"casual"}
	server.store.profiles["target-bad"] = targetBad

	rows := []any{
		map[string]any{"id": "target-good"},
		map[string]any{"id": "target-bad"},
	}

	criteria := server.buildAdvancedCriteria("viewer-1", nil)
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
