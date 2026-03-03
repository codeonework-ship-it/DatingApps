package mobile

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
)

func TestServer_ModerateConversationRoomEndpointAvailable(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	seedActiveModerationRoom(server, "room-moderation-endpoint")

	req := httptest.NewRequest(
		http.MethodPost,
		"/v1/rooms/room-moderation-endpoint/moderate",
		strings.NewReader(`{
			"moderator_user_id":"mod-1",
			"target_user_id":"user-a",
			"action":"warn_user",
			"reason":"policy reminder"
		}`),
	)
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("moderate endpoint code=%d body=%s", rec.Code, rec.Body.String())
	}

	payload := decodeJSONMap(t, rec.Body.Bytes())
	action := toMap(t, payload["moderation_action"])
	if got := stringValue(action["action"]); got != roomModerationActionWarn {
		t.Fatalf("expected warn_user action, got %q", got)
	}
}

func TestServer_ModerationAuditTrailPersisted(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	seedActiveModerationRoom(server, "room-moderation-audit")

	req := httptest.NewRequest(
		http.MethodPost,
		"/v1/rooms/room-moderation-audit/moderate",
		strings.NewReader(`{
			"moderator_user_id":"mod-2",
			"target_user_id":"user-b",
			"action":"warn_user",
			"reason":"off-topic discussion"
		}`),
	)
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("moderate endpoint code=%d body=%s", rec.Code, rec.Body.String())
	}

	server.store.mu.RLock()
	actions := server.store.roomModerationActions["room-moderation-audit"]
	server.store.mu.RUnlock()
	if len(actions) != 1 {
		t.Fatalf("expected 1 persisted moderation action, got %d", len(actions))
	}
	if actions[0].ModeratorUserID != "mod-2" {
		t.Fatalf("expected moderator mod-2, got %q", actions[0].ModeratorUserID)
	}
	if actions[0].TargetUserID != "user-b" {
		t.Fatalf("expected target user-b, got %q", actions[0].TargetUserID)
	}
}

func TestServer_RemovedUserBlockedFromActiveRoomSession(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	seedActiveModerationRoom(server, "room-moderation-block")

	joinReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/rooms/room-moderation-block/join",
		strings.NewReader(`{"user_id":"user-c"}`),
	)
	joinReq.Header.Set("Content-Type", "application/json")
	joinRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(joinRec, joinReq)
	if joinRec.Code != http.StatusOK {
		t.Fatalf("join code=%d body=%s", joinRec.Code, joinRec.Body.String())
	}

	moderateReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/rooms/room-moderation-block/moderate",
		strings.NewReader(`{
			"moderator_user_id":"mod-3",
			"target_user_id":"user-c",
			"action":"remove_user",
			"reason":"policy violation"
		}`),
	)
	moderateReq.Header.Set("Content-Type", "application/json")
	moderateRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(moderateRec, moderateReq)
	if moderateRec.Code != http.StatusOK {
		t.Fatalf("moderate remove code=%d body=%s", moderateRec.Code, moderateRec.Body.String())
	}

	rejoinReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/rooms/room-moderation-block/join",
		strings.NewReader(`{"user_id":"user-c"}`),
	)
	rejoinReq.Header.Set("Content-Type", "application/json")
	rejoinRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rejoinRec, rejoinReq)
	if rejoinRec.Code != http.StatusConflict {
		t.Fatalf("rejoin expected conflict, got=%d body=%s", rejoinRec.Code, rejoinRec.Body.String())
	}

	payload := decodeJSONMap(t, rejoinRec.Body.Bytes())
	if got := stringValue(payload["error_code"]); got != "ROOM_BLOCKED_ACTIVE_SESSION" {
		t.Fatalf("expected ROOM_BLOCKED_ACTIVE_SESSION, got %q", got)
	}
}

func TestServer_ModerateConversationRoomRejectsInvalidAction(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	seedActiveModerationRoom(server, "room-moderation-invalid-action")

	req := httptest.NewRequest(
		http.MethodPost,
		"/v1/rooms/room-moderation-invalid-action/moderate",
		strings.NewReader(`{
			"moderator_user_id":"mod-4",
			"target_user_id":"user-z",
			"action":"mute_user",
			"reason":"unsupported policy action"
		}`),
	)
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected 400 for invalid action, got=%d body=%s", rec.Code, rec.Body.String())
	}
}

func TestServer_RemoveUserRequiresActiveRoomTransition(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	now := time.Now().UTC()
	server.store.mu.Lock()
	server.store.rooms = map[string]conversationRoomRecord{
		"room-moderation-not-active": {
			ID:          "room-moderation-not-active",
			Theme:       "Closed Moderation Room",
			Description: "Closed room for transition validation",
			StartsAt:    now.Add(-2 * time.Hour),
			EndsAt:      now.Add(-1 * time.Hour),
			Capacity:    10,
		},
	}
	server.store.roomParticipants = map[string]map[string]conversationRoomParticipant{}
	server.store.roomModerationActions = map[string][]conversationRoomModerationAction{}
	server.store.roomActiveBlocks = map[string]map[string]conversationRoomBlock{}
	server.store.mu.Unlock()

	req := httptest.NewRequest(
		http.MethodPost,
		"/v1/rooms/room-moderation-not-active/moderate",
		strings.NewReader(`{
			"moderator_user_id":"mod-5",
			"target_user_id":"user-y",
			"action":"remove_user",
			"reason":"attempt remove outside active window"
		}`),
	)
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, req)

	if rec.Code != http.StatusConflict {
		t.Fatalf("expected 409 for non-active removal, got=%d body=%s", rec.Code, rec.Body.String())
	}
	payload := decodeJSONMap(t, rec.Body.Bytes())
	if got := stringValue(payload["error_code"]); got != "ROOM_NOT_ACTIVE" {
		t.Fatalf("expected ROOM_NOT_ACTIVE, got %q", got)
	}
}

func seedActiveModerationRoom(server *Server, roomID string) {
	now := time.Now().UTC()
	server.store.mu.Lock()
	defer server.store.mu.Unlock()

	server.store.rooms = map[string]conversationRoomRecord{
		roomID: {
			ID:          roomID,
			Theme:       "Moderation Room",
			Description: "Moderation test room",
			StartsAt:    now.Add(-15 * time.Minute),
			EndsAt:      now.Add(45 * time.Minute),
			Capacity:    10,
		},
	}
	server.store.roomParticipants = map[string]map[string]conversationRoomParticipant{}
	server.store.roomModerationActions = map[string][]conversationRoomModerationAction{}
	server.store.roomActiveBlocks = map[string]map[string]conversationRoomBlock{}
}
