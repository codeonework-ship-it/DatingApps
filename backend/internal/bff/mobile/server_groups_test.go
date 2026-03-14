package mobile

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestServer_CommunityGroupCreateInviteAcceptLifecycle(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	createBody := `{
		"owner_user_id":"user-owner-1",
		"name":"Bengaluru Weekend Explorers",
		"city":"Bengaluru",
		"topic":"City Hangouts",
		"description":"Plan weekend city meetups.",
		"visibility":"private",
		"invitee_user_ids":["user-invite-1","user-invite-2"]
	}`
	createReq := httptest.NewRequest(http.MethodPost, "/v1/engagement/groups", strings.NewReader(createBody))
	createReq.Header.Set("Content-Type", "application/json")
	createRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(createRec, createReq)
	if createRec.Code != http.StatusCreated {
		t.Fatalf("create group code=%d body=%s", createRec.Code, createRec.Body.String())
	}

	createPayload := decodeJSONMap(t, createRec.Body.Bytes())
	group := toMap(t, createPayload["group"])
	groupID := stringValue(group["id"])
	if groupID == "" {
		t.Fatalf("expected group id")
	}
	if got := int(group["member_count"].(float64)); got != 1 {
		t.Fatalf("expected owner to be first member, got=%d", got)
	}

	invitesReq := httptest.NewRequest(http.MethodGet, "/v1/engagement/group-invites?user_id=user-invite-1", nil)
	invitesRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(invitesRec, invitesReq)
	if invitesRec.Code != http.StatusOK {
		t.Fatalf("list invites code=%d body=%s", invitesRec.Code, invitesRec.Body.String())
	}

	respondBody := `{"user_id":"user-invite-1","decision":"accept"}`
	respondReq := httptest.NewRequest(http.MethodPost, "/v1/engagement/groups/"+groupID+"/invites/respond", strings.NewReader(respondBody))
	respondReq.Header.Set("Content-Type", "application/json")
	respondRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(respondRec, respondReq)
	if respondRec.Code != http.StatusOK {
		t.Fatalf("respond invite code=%d body=%s", respondRec.Code, respondRec.Body.String())
	}

	groupsReq := httptest.NewRequest(http.MethodGet, "/v1/engagement/groups?user_id=user-invite-1&joined_only=true", nil)
	groupsRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(groupsRec, groupsReq)
	if groupsRec.Code != http.StatusOK {
		t.Fatalf("list groups code=%d body=%s", groupsRec.Code, groupsRec.Body.String())
	}
	groupsPayload := decodeJSONMap(t, groupsRec.Body.Bytes())
	groupsRaw, ok := groupsPayload["groups"].([]any)
	if !ok || len(groupsRaw) != 1 {
		t.Fatalf("expected one joined group for invited user")
	}
	joinedGroup := toMap(t, groupsRaw[0])
	if got := boolValue(joinedGroup["is_member"]); !got {
		t.Fatalf("expected invited user to become group member")
	}
}

func TestServer_CommunityGroupInviteRequiresMemberAccess(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	createBody := `{
		"owner_user_id":"user-owner-2",
		"name":"Bengaluru Fan Club",
		"city":"Bengaluru",
		"topic":"Fanclub",
		"description":"Fan discussions",
		"visibility":"private"
	}`
	createReq := httptest.NewRequest(http.MethodPost, "/v1/engagement/groups", strings.NewReader(createBody))
	createReq.Header.Set("Content-Type", "application/json")
	createRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(createRec, createReq)
	if createRec.Code != http.StatusCreated {
		t.Fatalf("create group code=%d body=%s", createRec.Code, createRec.Body.String())
	}
	createPayload := decodeJSONMap(t, createRec.Body.Bytes())
	groupID := stringValue(toMap(t, createPayload["group"])["id"])

	inviteBody := `{"inviter_user_id":"outsider-user","invitee_user_ids":["any-user"]}`
	inviteReq := httptest.NewRequest(http.MethodPost, "/v1/engagement/groups/"+groupID+"/invites", strings.NewReader(inviteBody))
	inviteReq.Header.Set("Content-Type", "application/json")
	inviteRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(inviteRec, inviteReq)
	if inviteRec.Code != http.StatusForbidden {
		t.Fatalf("expected forbidden invite by outsider, got=%d body=%s", inviteRec.Code, inviteRec.Body.String())
	}

	payload := decodeJSONMap(t, inviteRec.Body.Bytes())
	if got := stringValue(payload["error_code"]); got != "GROUP_ACCESS_DENIED" {
		t.Fatalf("expected GROUP_ACCESS_DENIED, got %q", got)
	}
}
