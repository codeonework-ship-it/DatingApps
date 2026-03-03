package mobile

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
)

func TestServer_ListConversationRoomsLifecycleStatesSupported(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	now := time.Now().UTC()
	seedConversationRoomsForTest(server, now)

	req := httptest.NewRequest(http.MethodGet, "/v1/rooms?user_id=user-a&limit=10", nil)
	rec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("list rooms code=%d body=%s", rec.Code, rec.Body.String())
	}

	payload := decodeJSONMap(t, rec.Body.Bytes())
	rooms, ok := payload["rooms"].([]any)
	if !ok {
		t.Fatalf("expected rooms array")
	}
	if len(rooms) != 3 {
		t.Fatalf("expected 3 rooms, got %d", len(rooms))
	}

	statesByID := map[string]string{}
	for _, row := range rooms {
		room := toMap(t, row)
		statesByID[stringValue(room["id"])] = stringValue(room["lifecycle_state"])
	}

	if got := statesByID["room-active-test"]; got != roomLifecycleActive {
		t.Fatalf("expected active state, got %q", got)
	}
	if got := statesByID["room-scheduled-test"]; got != roomLifecycleScheduled {
		t.Fatalf("expected scheduled state, got %q", got)
	}
	if got := statesByID["room-closed-test"]; got != roomLifecycleClosed {
		t.Fatalf("expected closed state, got %q", got)
	}

	activeReq := httptest.NewRequest(http.MethodGet, "/v1/rooms?state=active&limit=10", nil)
	activeRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(activeRec, activeReq)
	if activeRec.Code != http.StatusOK {
		t.Fatalf("list active rooms code=%d body=%s", activeRec.Code, activeRec.Body.String())
	}
	activePayload := decodeJSONMap(t, activeRec.Body.Bytes())
	activeRooms, ok := activePayload["rooms"].([]any)
	if !ok || len(activeRooms) != 1 {
		t.Fatalf("expected one active room")
	}
}

func TestServer_JoinConversationRoomCapacityEnforced(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	now := time.Now().UTC()
	server.store.mu.Lock()
	server.store.rooms = map[string]conversationRoomRecord{
		"room-capacity-test": {
			ID:          "room-capacity-test",
			Theme:       "Capacity",
			Description: "Capacity enforcement test",
			StartsAt:    now.Add(-10 * time.Minute),
			EndsAt:      now.Add(50 * time.Minute),
			Capacity:    1,
		},
	}
	server.store.roomParticipants = map[string]map[string]conversationRoomParticipant{}
	server.store.mu.Unlock()

	joinReqOne := httptest.NewRequest(
		http.MethodPost,
		"/v1/rooms/room-capacity-test/join",
		strings.NewReader(`{"user_id":"user-a"}`),
	)
	joinReqOne.Header.Set("Content-Type", "application/json")
	joinRecOne := httptest.NewRecorder()
	server.Handler().ServeHTTP(joinRecOne, joinReqOne)
	if joinRecOne.Code != http.StatusOK {
		t.Fatalf("first join code=%d body=%s", joinRecOne.Code, joinRecOne.Body.String())
	}

	joinReqTwo := httptest.NewRequest(
		http.MethodPost,
		"/v1/rooms/room-capacity-test/join",
		strings.NewReader(`{"user_id":"user-b"}`),
	)
	joinReqTwo.Header.Set("Content-Type", "application/json")
	joinRecTwo := httptest.NewRecorder()
	server.Handler().ServeHTTP(joinRecTwo, joinReqTwo)
	if joinRecTwo.Code != http.StatusConflict {
		t.Fatalf("second join expected conflict, got=%d body=%s", joinRecTwo.Code, joinRecTwo.Body.String())
	}

	payload := decodeJSONMap(t, joinRecTwo.Body.Bytes())
	if got := stringValue(payload["error_code"]); got != "ROOM_CAPACITY_REACHED" {
		t.Fatalf("expected ROOM_CAPACITY_REACHED, got %q", got)
	}
}

func TestServer_ConversationParticipationEventsLogged(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	now := time.Now().UTC()
	server.store.mu.Lock()
	server.store.rooms = map[string]conversationRoomRecord{
		"room-events-test": {
			ID:          "room-events-test",
			Theme:       "Events",
			Description: "Event log test",
			StartsAt:    now.Add(-10 * time.Minute),
			EndsAt:      now.Add(50 * time.Minute),
			Capacity:    5,
		},
	}
	server.store.roomParticipants = map[string]map[string]conversationRoomParticipant{}
	server.store.mu.Unlock()

	joinReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/rooms/room-events-test/join",
		strings.NewReader(`{"user_id":"user-a"}`),
	)
	joinReq.Header.Set("Content-Type", "application/json")
	joinRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(joinRec, joinReq)
	if joinRec.Code != http.StatusOK {
		t.Fatalf("join code=%d body=%s", joinRec.Code, joinRec.Body.String())
	}

	leaveReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/rooms/room-events-test/leave",
		strings.NewReader(`{"user_id":"user-a"}`),
	)
	leaveReq.Header.Set("Content-Type", "application/json")
	leaveRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(leaveRec, leaveReq)
	if leaveRec.Code != http.StatusOK {
		t.Fatalf("leave code=%d body=%s", leaveRec.Code, leaveRec.Body.String())
	}

	activities := server.store.listActivities(50)
	hasJoinEvent := false
	hasLeaveEvent := false
	for _, item := range activities {
		if item.Action == "room.participation.join" && item.Status == "success" {
			hasJoinEvent = true
		}
		if item.Action == "room.participation.leave" && item.Status == "success" {
			hasLeaveEvent = true
		}
	}

	if !hasJoinEvent {
		t.Fatalf("expected room.participation.join activity event")
	}
	if !hasLeaveEvent {
		t.Fatalf("expected room.participation.leave activity event")
	}
}

func TestServer_ListConversationRoomsFriendOnlyFilter(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	now := time.Now().UTC()
	server.store.mu.Lock()
	server.store.rooms = map[string]conversationRoomRecord{
		"room-friends-visible": {
			ID:          "room-friends-visible",
			Theme:       "Friends Visible",
			Description: "Should appear with friend_only filter",
			StartsAt:    now.Add(-15 * time.Minute),
			EndsAt:      now.Add(45 * time.Minute),
			Capacity:    10,
		},
		"room-friends-hidden": {
			ID:          "room-friends-hidden",
			Theme:       "Friends Hidden",
			Description: "Should not appear with friend_only filter",
			StartsAt:    now.Add(-15 * time.Minute),
			EndsAt:      now.Add(45 * time.Minute),
			Capacity:    10,
		},
	}
	server.store.roomParticipants = map[string]map[string]conversationRoomParticipant{
		"room-friends-visible": {
			"friend-1": {UserID: "friend-1", JoinedAt: now.Add(-5 * time.Minute)},
		},
		"room-friends-hidden": {
			"stranger-1": {UserID: "stranger-1", JoinedAt: now.Add(-5 * time.Minute)},
		},
	}
	server.store.friends["user-a"] = map[string]friendConnection{
		"friend-1": {
			UserID:   "user-a",
			FriendID: "friend-1",
			Status:   "accepted",
		},
	}
	server.store.mu.Unlock()

	req := httptest.NewRequest(http.MethodGet, "/v1/rooms?user_id=user-a&friend_only=true", nil)
	rec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("list rooms friend_only code=%d body=%s", rec.Code, rec.Body.String())
	}

	payload := decodeJSONMap(t, rec.Body.Bytes())
	rooms, ok := payload["rooms"].([]any)
	if !ok {
		t.Fatalf("expected rooms array")
	}
	if len(rooms) != 1 {
		t.Fatalf("expected 1 room for friend_only filter, got %d", len(rooms))
	}
	room := toMap(t, rooms[0])
	if got := stringValue(room["id"]); got != "room-friends-visible" {
		t.Fatalf("unexpected room id %q", got)
	}
}

func seedConversationRoomsForTest(server *Server, now time.Time) {
	server.store.mu.Lock()
	defer server.store.mu.Unlock()

	server.store.rooms = map[string]conversationRoomRecord{
		"room-scheduled-test": {
			ID:          "room-scheduled-test",
			Theme:       "Scheduled",
			Description: "Scheduled room",
			StartsAt:    now.Add(1 * time.Hour),
			EndsAt:      now.Add(2 * time.Hour),
			Capacity:    10,
		},
		"room-active-test": {
			ID:          "room-active-test",
			Theme:       "Active",
			Description: "Active room",
			StartsAt:    now.Add(-30 * time.Minute),
			EndsAt:      now.Add(30 * time.Minute),
			Capacity:    10,
		},
		"room-closed-test": {
			ID:          "room-closed-test",
			Theme:       "Closed",
			Description: "Closed room",
			StartsAt:    now.Add(-2 * time.Hour),
			EndsAt:      now.Add(-1 * time.Hour),
			Capacity:    10,
		},
	}
	server.store.roomParticipants = map[string]map[string]conversationRoomParticipant{}
}
