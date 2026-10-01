package mobile

import (
	"bytes"
	"database/sql"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
)

// HTTP for live Conversation Rooms (live_rooms.go). With the SQL store the
// existing /v1/rooms routes use these; without it (unit tests, store-less
// deployments) they keep the older in-memory behaviour in server_rooms.go.

const roomsUnavailable = "Rooms are temporarily unavailable. Please retry."

// readRoomJSON decodes an optional JSON body (an empty body is {}).
func readRoomJSON(w http.ResponseWriter, r *http.Request) (map[string]any, bool) {
	payload := map[string]any{}
	if r.Body == nil {
		return payload, true
	}
	defer r.Body.Close()
	raw, err := io.ReadAll(io.LimitReader(r.Body, 64<<10))
	if err != nil {
		writeError(w, 400, errors.New("unreadable request body"))
		return nil, false
	}
	if len(bytes.TrimSpace(raw)) == 0 {
		return payload, true
	}
	if err = json.Unmarshal(raw, &payload); err != nil || payload == nil {
		writeError(w, 400, errors.New("request body must be a JSON object"))
		return nil, false
	}
	return payload, true
}

// roomActorMatches rejects a body that names someone other than the caller
// (the security middleware does the same when it runs).
func roomActorMatches(w http.ResponseWriter, actor string, body map[string]any, keys ...string) bool {
	for _, key := range keys {
		if v := strings.TrimSpace(toString(body[key])); v != "" && v != actor {
			writeError(w, 403, errors.New("request actor does not match the authenticated user"))
			return false
		}
	}
	return true
}

// writeRoomError maps room errors to friendly messages and stable codes.
func writeRoomError(w http.ResponseWriter, err error) {
	conflict := func(code, msg string) {
		writeJSON(w, http.StatusConflict, map[string]any{"success": false, "error": msg, "error_code": code})
	}
	switch {
	case errors.Is(err, errRoomClosed):
		conflict("ROOM_CLOSED", "This room has closed.")
	case errors.Is(err, errRoomCapacityReached):
		conflict("ROOM_CAPACITY_REACHED", "This room is full right now. Try again in a little while.")
	case errors.Is(err, errRoomBlockedActiveSession):
		conflict("ROOM_BLOCKED_ACTIVE_SESSION", "A host removed you from this room. You can rejoin when this session ends.")
	case errors.Is(err, errRoomNotParticipant):
		conflict("ROOM_NOT_JOINED", "You're not in this room.")
	case errors.Is(err, errRoomModerationNotActive):
		conflict("ROOM_NOT_ACTIVE", "This room has closed.")
	case errors.Is(err, errRoomModerationAction):
		writeError(w, 400, errors.New("action must be warn_user, mute_user, unmute_user, remove_user or close_room"))
	default:
		writeActivityError(w, err, roomsUnavailable)
	}
}

func roomPathID(w http.ResponseWriter, r *http.Request) (string, bool) {
	id := strings.TrimSpace(chi.URLParam(r, "roomID"))
	return id, activityUUID(w, id)
}

// GET /v1/rooms
func (s *Server) liveRoomsList(w http.ResponseWriter, r *http.Request, db *sql.DB) {
	actor, err := requestPrincipal(r)
	if err != nil {
		writeError(w, 401, err)
		return
	}
	q := r.URL.Query()
	state := strings.ToLower(strings.TrimSpace(q.Get("state")))
	friendOnly := parseBoolQuery(q.Get("friend_only"))
	rooms, err := listLiveRooms(r.Context(), db, actor.UserID, state, q.Get("category"), friendOnly, parseRoomLimit(q.Get("limit"), 100))
	if err != nil {
		writeRoomError(w, err)
		return
	}
	w.Header().Set("Cache-Control", "private, no-store")
	writeJSON(w, 200, map[string]any{
		"rooms": rooms, "count": len(rooms), "state_filter": state, "friend_only": friendOnly,
		"categories": []map[string]string{
			{"key": "talk", "label": "Talk"}, {"key": "interests", "label": "Interests"},
			{"key": "active", "label": "Out & about"}, {"key": "city", "label": "Your city"},
		},
	})
}

// POST /v1/rooms
func (s *Server) createRoomHandler(w http.ResponseWriter, r *http.Request) {
	actor, db, ok := s.socialContext(w, r)
	if !ok {
		return
	}
	body, ok := readRoomJSON(w, r)
	if !ok || !roomActorMatches(w, actor, body, "user_id", "host_user_id", "created_by_user_id") {
		return
	}
	d := roomDraft{
		Title: toString(body["title"]), Description: toString(body["description"]), Category: toString(body["category"]),
	}
	if v, ok := toInt(body["duration_minutes"]); ok {
		d.DurationMinutes = v
	}
	if v, ok := toInt(body["capacity"]); ok {
		d.Capacity = v
	}
	if raw := strings.TrimSpace(toString(body["starts_at"])); raw != "" {
		t, err := time.Parse(time.RFC3339, raw)
		if err != nil {
			writeError(w, 400, errors.New("starts_at must be an RFC 3339 time"))
			return
		}
		d.StartsAt = &t
	}
	room, err := createLiveRoom(r.Context(), db, actor, d)
	if err != nil {
		writeRoomError(w, err)
		return
	}
	writeJSON(w, 201, map[string]any{"room": room})
}

// GET /v1/rooms/{roomID}
func (s *Server) roomDetailHandler(w http.ResponseWriter, r *http.Request) {
	actor, db, ok := s.socialContext(w, r)
	if !ok {
		return
	}
	roomID, ok := roomPathID(w, r)
	if !ok {
		return
	}
	room, err := getLiveRoom(r.Context(), db, actor, roomID)
	if err == nil && room.IsParticipant && room.ChannelID == "" && room.LifecycleState != roomLifecycleClosed {
		room.ChannelID, err = ensureRefChannel(r.Context(), db, "room", roomID)
	}
	if err != nil {
		writeRoomError(w, err)
		return
	}
	writeJSON(w, 200, map[string]any{"room": room, "guidelines": roomGuidelines})
}

var roomGuidelines = []string{
	"Be kind. Everyone here is a real, verified member.",
	"Keep personal details (numbers, addresses) for people you trust.",
	"Tap a name to add a friend, report or block.",
}

// GET /v1/rooms/{roomID}/members
func (s *Server) roomMembersHandler(w http.ResponseWriter, r *http.Request) {
	actor, db, ok := s.socialContext(w, r)
	if !ok {
		return
	}
	roomID, ok := roomPathID(w, r)
	if !ok {
		return
	}
	members, err := listRoomMembers(r.Context(), db, actor, roomID)
	if err != nil {
		writeRoomError(w, err)
		return
	}
	here := 0
	for _, m := range members {
		if m.HereNow {
			here++
		}
	}
	writeJSON(w, 200, map[string]any{"members": members, "count": len(members), "here_now": here})
}

// POST /v1/rooms/{roomID}/join
func (s *Server) liveRoomJoin(w http.ResponseWriter, r *http.Request, db *sql.DB) {
	actor, roomID, _, ok := s.liveRoomRequest(w, r, "user_id")
	if !ok {
		return
	}
	room, err := joinLiveRoom(r.Context(), db, actor, roomID)
	if err != nil {
		writeRoomError(w, err)
		return
	}
	s.recordRoomActivity(actor, actor, "room.participation.join", roomID, map[string]any{"room_id": roomID, "here_now": room.HereNow})
	writeJSON(w, 200, map[string]any{"room": room, "joined": true, "channel_id": room.ChannelID})
}

// POST /v1/rooms/{roomID}/leave
func (s *Server) liveRoomLeave(w http.ResponseWriter, r *http.Request, db *sql.DB) {
	actor, roomID, _, ok := s.liveRoomRequest(w, r, "user_id")
	if !ok {
		return
	}
	room, err := leaveLiveRoom(r.Context(), db, actor, roomID)
	if err != nil {
		writeRoomError(w, err)
		return
	}
	s.recordRoomActivity(actor, actor, "room.participation.leave", roomID, map[string]any{"room_id": roomID})
	writeJSON(w, 200, map[string]any{"room": room, "left": true})
}

// POST /v1/rooms/{roomID}/presence
func (s *Server) roomPresenceHandler(w http.ResponseWriter, r *http.Request) {
	db, err := s.growthDB()
	if err != nil {
		writeError(w, 503, errors.New(roomsUnavailable))
		return
	}
	actor, roomID, body, ok := s.liveRoomRequest(w, r, "user_id")
	if !ok {
		return
	}
	away := strings.EqualFold(strings.TrimSpace(toString(body["state"])), "away")
	room, err := touchRoomPresence(r.Context(), db, actor, roomID, away)
	if err != nil {
		writeRoomError(w, err)
		return
	}
	writeJSON(w, 200, map[string]any{"room": room, "here_now": room.HereNow, "participant_count": room.MemberCount})
}

// POST /v1/rooms/{roomID}/moderate
func (s *Server) liveRoomModerate(w http.ResponseWriter, r *http.Request, db *sql.DB) {
	actor, roomID, body, ok := s.liveRoomRequest(w, r, "moderator_user_id", "moderator_id", "user_id")
	if !ok {
		return
	}
	target := strings.TrimSpace(toString(body["target_user_id"]))
	room, entry, err := applyRoomModeration(r.Context(), db, roomModerationFromBody(actor, roomID, body, false))
	if err != nil {
		writeRoomError(w, err)
		return
	}
	s.recordRoomActivity(target, actor, "room.moderation.action", roomID, map[string]any{
		"room_id": roomID, "moderation_action": entry.Action, "moderation_action_id": entry.ID,
	})
	writeJSON(w, 200, map[string]any{"room": room, "moderation_action": entry, "policy_enforced": true})
}

// roomModerationFromBody reads {target_user_id, action, reason, duration,
// duration_minutes} for the member and operator moderation routes.
func roomModerationFromBody(actor, roomID string, body map[string]any, operator bool) roomModerationRequest {
	req := roomModerationRequest{
		Actor: actor, RoomID: roomID, Operator: operator,
		Target:   strings.TrimSpace(toString(body["target_user_id"])),
		Action:   toString(body["action"]),
		Reason:   toString(body["reason"]),
		Duration: toString(body["duration"]),
	}
	if v, ok := toInt(body["duration_minutes"]); ok {
		req.Minutes = v
		if v == 0 {
			req.Minutes = -1 // explicit 0 is out of range
		}
	}
	return req
}

// liveRoomRequest authenticates, reads the room id and an optional body, and
// checks any actor fields name the caller.
func (s *Server) liveRoomRequest(w http.ResponseWriter, r *http.Request, actorKeys ...string) (string, string, map[string]any, bool) {
	principal, err := requestPrincipal(r)
	if err != nil {
		writeError(w, 401, err)
		return "", "", nil, false
	}
	roomID, ok := roomPathID(w, r)
	if !ok {
		return "", "", nil, false
	}
	body, ok := readRoomJSON(w, r)
	if !ok || !roomActorMatches(w, principal.UserID, body, actorKeys...) {
		return "", "", nil, false
	}
	w.Header().Set("Cache-Control", "private, no-store")
	return principal.UserID, roomID, body, true
}

func (s *Server) recordRoomActivity(user, actor, action, roomID string, details map[string]any) {
	if s.store == nil {
		return
	}
	s.store.recordActivity(activityEvent{
		UserID: user, Actor: actor, Action: action, Status: "success",
		Resource: "/rooms/" + roomID, Details: details,
	})
}

// ---------------------------------------------------------------------------
// Operators
// ---------------------------------------------------------------------------

// GET /v1/admin/moderation/rooms
func (s *Server) adminRoomsHandler(w http.ResponseWriter, r *http.Request) {
	if _, err := blogModerator(r); err != nil {
		writeError(w, 403, err)
		return
	}
	db, err := s.growthDB()
	if err != nil {
		writeError(w, 503, errors.New(roomsUnavailable))
		return
	}
	rooms, actions, err := listRoomsForOperators(r.Context(), db)
	if err != nil {
		writeRoomError(w, err)
		return
	}
	w.Header().Set("Cache-Control", "private, no-store")
	writeJSON(w, 200, map[string]any{"rooms": rooms, "recent_actions": actions})
}

// POST /v1/admin/moderation/rooms/{roomID}/actions
func (s *Server) adminRoomActionHandler(w http.ResponseWriter, r *http.Request) {
	operator, err := blogModerator(r)
	if err != nil {
		writeError(w, 403, err)
		return
	}
	db, err := s.growthDB()
	if err != nil {
		writeError(w, 503, errors.New(roomsUnavailable))
		return
	}
	roomID, ok := roomPathID(w, r)
	if !ok {
		return
	}
	body, ok := readRoomJSON(w, r)
	if !ok {
		return
	}
	room, entry, err := applyRoomModeration(r.Context(), db, roomModerationFromBody(operator, roomID, body, true))
	if err != nil {
		writeRoomError(w, err)
		return
	}
	s.recordRoomActivity(entry.TargetUserID, operator, "room.moderation.operator", roomID, map[string]any{
		"room_id": roomID, "moderation_action": entry.Action, "moderation_action_id": entry.ID,
	})
	writeJSON(w, 200, map[string]any{"room": room, "moderation_action": entry})
}

// POST /v1/admin/moderation/rooms/{roomID}/roles
func (s *Server) adminRoomRoleHandler(w http.ResponseWriter, r *http.Request) {
	operator, err := blogModerator(r)
	if err != nil {
		writeError(w, 403, err)
		return
	}
	db, err := s.growthDB()
	if err != nil {
		writeError(w, 503, errors.New(roomsUnavailable))
		return
	}
	roomID, ok := roomPathID(w, r)
	if !ok {
		return
	}
	body, ok := readRoomJSON(w, r)
	if !ok {
		return
	}
	member := strings.TrimSpace(toString(body["member_id"]))
	if !activityUUID(w, member) {
		return
	}
	role := strings.ToLower(strings.TrimSpace(toString(body["role"])))
	if err = setLiveRoomRole(r.Context(), db, operator, roomID, member, role); err != nil {
		writeRoomError(w, err)
		return
	}
	s.recordRoomActivity(member, operator, "room.role.set", roomID, map[string]any{"room_id": roomID, "role": role})
	writeJSON(w, 200, map[string]any{"member_id": member, "role": role})
}

// GET /v1/admin/moderation/rooms/{roomID}/members
func (s *Server) adminRoomMembersHandler(w http.ResponseWriter, r *http.Request) {
	if _, err := blogModerator(r); err != nil {
		writeError(w, 403, err)
		return
	}
	db, err := s.growthDB()
	if err != nil {
		writeError(w, 503, errors.New(roomsUnavailable))
		return
	}
	roomID, ok := roomPathID(w, r)
	if !ok {
		return
	}
	members, err := listRoomMembersForOperators(r.Context(), db, roomID)
	if err != nil {
		writeRoomError(w, err)
		return
	}
	w.Header().Set("Cache-Control", "private, no-store")
	writeJSON(w, 200, map[string]any{"members": members, "count": len(members)})
}
