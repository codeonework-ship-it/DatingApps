package mobile

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
)

// newLiveRoomFixture is the shared Postgres fixture plus migration 117. Rooms
// the fixture members host, and moderation rows about them, are removed
// before the members are.
func newLiveRoomFixture(t *testing.T) datePlanFixture {
	f := newBlogTrustFixture(t)
	var ready bool
	if err := f.db.QueryRow(`SELECT EXISTS(SELECT 1 FROM information_schema.columns
 WHERE table_schema='matching' AND table_name='conversation_room_participants' AND column_name='last_seen_at')
 AND to_regclass('matching.social_messages') IS NOT NULL`).Scan(&ready); err != nil || !ready {
		t.Skip("migration 117_conversation_rooms_live_chat is not applied")
	}
	members := []string{f.proposer, f.invitee, f.proposerFriend, f.inviteeFriend, f.blockedFriend, f.groupMate, f.stranger}
	t.Cleanup(func() {
		for _, id := range members {
			_, _ = f.db.Exec(`DELETE FROM matching.conversation_room_moderation_actions WHERE target_user_id=$1 OR actor_user_id=$1`, id)
			_, _ = f.db.Exec(`DELETE FROM matching.conversation_rooms WHERE created_by_user_id=$1`, id)
		}
	})
	return f
}

func seededRoomID(t *testing.T, f datePlanFixture, slug string) string {
	t.Helper()
	var id string
	if err := f.db.QueryRow(`SELECT id::text FROM matching.conversation_rooms WHERE slug=$1`, slug).Scan(&id); err != nil {
		t.Fatalf("seeded room %s: %v", slug, err)
	}
	return id
}

func roomCall(t *testing.T, f datePlanFixture, handler func(http.ResponseWriter, *http.Request), method, user, roomID, body string) (int, map[string]any) {
	t.Helper()
	rec := httptest.NewRecorder()
	params := map[string]string{}
	if roomID != "" {
		params["roomID"] = roomID
	}
	handler(rec, blogRoute(method, user, body, params))
	out := map[string]any{}
	_ = json.Unmarshal(rec.Body.Bytes(), &out)
	return rec.Code, out
}

func TestLiveRoomsSeededListJoinChatAndLeave(t *testing.T) {
	f := newLiveRoomFixture(t)
	ctx := context.Background()
	s := blogServer(f)

	// The always-on rooms are listed for everyone, with no channel until joined.
	rooms, err := listLiveRooms(ctx, f.db, f.proposer, "", "", false, 200)
	if err != nil {
		t.Fatal(err)
	}
	seen := map[string]liveRoom{}
	for _, r := range rooms {
		seen[r.Slug] = r
	}
	for _, slug := range []string{"late-night-talks", "first-date-stories", "bookworms-corner", "foodies-table", "bengaluru-hangout", "mumbai-locals"} {
		r, ok := seen[slug]
		if !ok {
			t.Fatalf("seeded room %s not listed", slug)
		}
		if !r.AlwaysOn || r.LifecycleState != roomLifecycleActive || r.EndsAt != nil || r.Capacity != 200 || r.Category == "" || r.IconKey == "" {
			t.Fatalf("seeded room shape %s: %+v", slug, r)
		}
	}
	code, out := roomCall(t, f, s.listConversationRooms, http.MethodGet, f.proposer, "", "")
	if code != 200 || len(out["rooms"].([]any)) < 16 {
		t.Fatal("list over HTTP", code, out)
	}
	if code, out = roomCall(t, f, s.listConversationRooms, http.MethodGet, "", "", ""); code != 401 {
		t.Fatal("anonymous list", code, out)
	}

	roomID := seededRoomID(t, f, "late-night-talks")
	detail, err := getLiveRoom(ctx, f.db, f.proposer, roomID)
	if err != nil || detail.IsParticipant || detail.ChannelID != "" {
		t.Fatal("a non-member sees the channel", err, detail)
	}

	// Joining returns the chat channel.
	code, out = roomCall(t, f, s.joinConversationRoom, http.MethodPost, f.proposer, roomID, `{}`)
	if code != 200 || out["channel_id"] == "" || out["channel_id"] == nil {
		t.Fatal("join", code, out)
	}
	channelID := out["channel_id"].(string)
	room := out["room"].(map[string]any)
	if room["is_participant"] != true || room["my_role"] != "participant" || room["can_moderate"] != false || room["here_now"].(float64) < 1 {
		t.Fatal("joined room view", room)
	}
	// Joining again is harmless and returns the same channel.
	if again, err := joinLiveRoom(ctx, f.db, f.proposer, roomID); err != nil || again.ChannelID != channelID {
		t.Fatal("rejoin", err, again.ChannelID)
	}
	// Someone else's id in the body is refused.
	if code, _ = roomCall(t, f, s.joinConversationRoom, http.MethodPost, f.stranger, roomID, `{"user_id":"`+f.proposer+`"}`); code != 403 {
		t.Fatal("joined as someone else", code)
	}

	// Members only: the list is for people in the room.
	if code, _ = roomCall(t, f, s.roomMembersHandler, http.MethodGet, f.stranger, roomID, ""); code != 404 {
		t.Fatal("a non-member read the member list", code)
	}
	if _, err = joinLiveRoom(ctx, f.db, f.proposerFriend, roomID); err != nil {
		t.Fatal(err)
	}
	if _, err = joinLiveRoom(ctx, f.db, f.stranger, roomID); err != nil {
		t.Fatal(err)
	}
	members, err := listRoomMembers(ctx, f.db, f.proposer, roomID)
	if err != nil {
		t.Fatal(err)
	}
	status := map[string]string{}
	for _, m := range members {
		status[m.UserID] = m.FriendStatus
		if m.UserID != f.proposer && m.UserID != f.proposerFriend && m.UserID != f.stranger {
			continue // someone else using the shared local database
		}
		if m.Name == "" || !m.HereNow || m.Role != "participant" {
			t.Fatal("member card", m)
		}
	}
	if status[f.proposer] != "me" || status[f.proposerFriend] != "friends" || status[f.stranger] != "none" {
		t.Fatal("friend hints", status)
	}
	if listed, _ := getLiveRoom(ctx, f.db, f.proposer, roomID); listed.FriendsHere != 1 {
		t.Fatal("friends here", listed.FriendsHere)
	}
	if _, err = f.db.Exec(`INSERT INTO matching.friend_connections(user_id,friend_user_id,status) VALUES($1,$2,'pending')`, f.proposer, f.stranger); err != nil {
		t.Fatal(err)
	}
	members, _ = listRoomMembers(ctx, f.db, f.proposer, roomID)
	for _, m := range members {
		if m.UserID == f.stranger && m.FriendStatus != "requested" {
			t.Fatal("pending request hint", m.FriendStatus)
		}
	}
	members, _ = listRoomMembers(ctx, f.db, f.stranger, roomID)
	for _, m := range members {
		if m.UserID == f.proposer && m.FriendStatus != "incoming" {
			t.Fatal("incoming request hint", m.FriendStatus)
		}
	}

	// Chat runs through the shared engine: members post, others cannot.
	m, err := sendSocialMessage(ctx, f.db, f.proposer, channelID, uuid.NewString(), "Anyone else up?")
	if err != nil {
		t.Fatal(err)
	}
	if _, err = sendSocialMessage(ctx, f.db, f.invitee, channelID, uuid.NewString(), "hi"); !errors.Is(err, errDatePlanNotFound) {
		t.Fatal("a non-member posted", err)
	}
	if _, _, err = listSocialMessages(ctx, f.db, f.stranger, channelID, "", 10); err != nil {
		t.Fatal(err)
	}
	ch, _, err := loadChannel(ctx, f.db, f.stranger, channelID)
	if err != nil || ch.Kind != "room" || ch.Title != "Late-night talks" || ch.CanModerate || ch.MemberCount < 3 {
		t.Fatal("room channel", err, ch)
	}
	var events int
	_ = f.db.QueryRow(`SELECT COUNT(*) FROM matching.realtime_outbox WHERE channel_id=$1 AND recipient_user_id=$2`, channelID, f.stranger).Scan(&events)
	if events != 1 {
		t.Fatal("room fan-out", events)
	}
	// Room messages are reported to the shared case queue.
	if caseID, err := createBlogCase(ctx, f.db, f.stranger, "social_message", m.ID, "harassment", ""); err != nil || caseID == "" {
		t.Fatal("report a room message", err)
	}

	// Presence: "away" stops counting someone as here now.
	before, _ := getLiveRoom(ctx, f.db, f.proposer, roomID)
	code, out = roomCall(t, f, s.roomPresenceHandler, http.MethodPost, f.stranger, roomID, `{"state":"away"}`)
	if code != 200 || int(out["here_now"].(float64)) != before.HereNow-1 {
		t.Fatal("away presence", code, out, before.HereNow)
	}
	if code, out = roomCall(t, f, s.roomPresenceHandler, http.MethodPost, f.stranger, roomID, `{}`); code != 200 || int(out["here_now"].(float64)) != before.HereNow {
		t.Fatal("heartbeat presence", code, out)
	}
	if code, out = roomCall(t, f, s.roomPresenceHandler, http.MethodPost, f.invitee, roomID, `{}`); code != 409 || out["error_code"] != "ROOM_NOT_JOINED" {
		t.Fatal("presence from a non-member", code, out)
	}

	// Leaving revokes the chat at once.
	if code, out = roomCall(t, f, s.leaveConversationRoom, http.MethodPost, f.stranger, roomID, ``); code != 200 || out["left"] != true {
		t.Fatal("leave", code, out)
	}
	if _, err = sendSocialMessage(ctx, f.db, f.stranger, channelID, uuid.NewString(), "still here?"); !errors.Is(err, errDatePlanNotFound) {
		t.Fatal("posted after leaving", err)
	}
	if _, _, err = loadChannel(ctx, f.db, f.stranger, channelID); !errors.Is(err, errDatePlanNotFound) {
		t.Fatal("read after leaving", err)
	}
	if code, out = roomCall(t, f, s.leaveConversationRoom, http.MethodPost, f.stranger, roomID, ``); code != 409 || out["error_code"] != "ROOM_NOT_JOINED" {
		t.Fatal("leave twice", code, out)
	}
	// A member who lapses for a day drops out until they rejoin.
	if _, err = f.db.Exec(`UPDATE matching.conversation_room_participants SET last_seen_at=NOW()-interval '25 hours',joined_at=NOW()-interval '25 hours' WHERE room_id=$1 AND user_id=$2`, roomID, f.proposerFriend); err != nil {
		t.Fatal(err)
	}
	if lapsed, _ := getLiveRoom(ctx, f.db, f.proposerFriend, roomID); lapsed.IsParticipant {
		t.Fatal("a lapsed member still counts as in the room")
	}

	// Ordinary participants cannot moderate.
	code, out = roomCall(t, f, s.moderateConversationRoom, http.MethodPost, f.proposer, roomID,
		`{"target_user_id":"`+f.stranger+`","action":"warn_user"}`)
	if code != 403 {
		t.Fatal("a participant moderated a public room", code, out)
	}
}

func TestLiveRoomsBlocksHostingAndModeration(t *testing.T) {
	f := newLiveRoomFixture(t)
	ctx := context.Background()
	s := blogServer(f)

	// A blocked pair can share a public room; each side's messages are hidden.
	publicID := seededRoomID(t, f, "movie-night")
	for _, u := range []string{f.proposer, f.blockedFriend} {
		if _, err := joinLiveRoom(ctx, f.db, u, publicID); err != nil {
			t.Fatal("join across a block", err)
		}
	}
	pub, _ := getLiveRoom(ctx, f.db, f.proposer, publicID)
	if _, err := sendSocialMessage(ctx, f.db, f.proposer, pub.ChannelID, uuid.NewString(), "Any thriller picks?"); err != nil {
		t.Fatal(err)
	}
	if msgs, _, err := listSocialMessages(ctx, f.db, f.blockedFriend, pub.ChannelID, "", 50); err != nil {
		t.Fatal(err)
	} else {
		for _, m := range msgs {
			if m.SenderID == f.proposer {
				t.Fatal("a blocked member's message was shown")
			}
		}
	}
	if members, _ := listRoomMembers(ctx, f.db, f.blockedFriend, publicID); len(members) == 0 {
		t.Fatal("member list empty")
	} else {
		for _, m := range members {
			if m.UserID == f.proposer {
				t.Fatal("a blocked member is listed")
			}
		}
	}

	// Hosting: the proposer starts a small room and is its host.
	code, out := roomCall(t, f, s.createRoomHandler, http.MethodPost, f.proposer, "",
		`{"title":"  Sunday  book swap ","description":"Bring one book you loved.","category":"interests","capacity":3,"duration_minutes":60}`)
	if code != 201 {
		t.Fatal("create room", code, out)
	}
	hosted := out["room"].(map[string]any)
	roomID := hosted["id"].(string)
	if hosted["title"] != "Sunday book swap" || hosted["my_role"] != "host" || hosted["can_moderate"] != true || hosted["is_host"] != true || hosted["channel_id"] == "" {
		t.Fatal("hosted room", hosted)
	}
	if code, out = roomCall(t, f, s.createRoomHandler, http.MethodPost, f.proposer, "", `{"title":"Another one"}`); code != 409 {
		t.Fatal("a second open room", code, out)
	}
	if code, _ = roomCall(t, f, s.createRoomHandler, http.MethodPost, f.invitee, "", `{"title":"x"}`); code != 400 {
		t.Fatal("short title", code)
	}
	// Hidden from, and closed to, someone the host blocked or was blocked by.
	if _, err := getLiveRoom(ctx, f.db, f.blockedFriend, roomID); !errors.Is(err, errDatePlanNotFound) {
		t.Fatal("a blocked member sees the hosted room", err)
	}
	if code, _ = roomCall(t, f, s.joinConversationRoom, http.MethodPost, f.blockedFriend, roomID, `{}`); code != 404 {
		t.Fatal("a blocked member joined the hosted room", code)
	}

	// Capacity 3: host, invitee and stranger fill it.
	for _, u := range []string{f.invitee, f.stranger} {
		if _, err := joinLiveRoom(ctx, f.db, u, roomID); err != nil {
			t.Fatal(err)
		}
	}
	if code, out = roomCall(t, f, s.joinConversationRoom, http.MethodPost, f.groupMate, roomID, `{}`); code != 409 || out["error_code"] != "ROOM_CAPACITY_REACHED" {
		t.Fatal("over capacity", code, out)
	}

	// Spoofing the moderator is refused; a participant cannot moderate.
	code, _ = roomCall(t, f, s.moderateConversationRoom, http.MethodPost, f.stranger, roomID,
		`{"moderator_user_id":"`+f.proposer+`","target_user_id":"`+f.invitee+`","action":"remove_user"}`)
	if code != 403 {
		t.Fatal("moderated as the host", code)
	}
	code, _ = roomCall(t, f, s.moderateConversationRoom, http.MethodPost, f.stranger, roomID,
		`{"target_user_id":"`+f.invitee+`","action":"remove_user"}`)
	if code != 403 {
		t.Fatal("a participant removed someone", code)
	}
	if code, _ = roomCall(t, f, s.moderateConversationRoom, http.MethodPost, f.proposer, roomID,
		`{"target_user_id":"`+f.invitee+`","action":"ban"}`); code != 400 {
		t.Fatal("unsupported action", code)
	}

	// The host warns, then removes; the removed member cannot rejoin.
	code, out = roomCall(t, f, s.moderateConversationRoom, http.MethodPost, f.proposer, roomID,
		`{"moderator_user_id":"`+f.proposer+`","target_user_id":"`+f.stranger+`","action":"warn_user","reason":"Keep it kind"}`)
	if code != 200 || out["moderation_action"].(map[string]any)["action"] != roomModerationActionWarn {
		t.Fatal("warn", code, out)
	}
	if f.notifications(t, f.stranger, "room.moderation.warn") != 1 {
		t.Fatal("warning notification")
	}
	code, out = roomCall(t, f, s.moderateConversationRoom, http.MethodPost, f.proposer, roomID,
		`{"target_user_id":"`+f.stranger+`","action":"remove_user"}`)
	if code != 200 {
		t.Fatal("remove", code, out)
	}
	hostedChannel := hosted["channel_id"].(string)
	if _, err := sendSocialMessage(ctx, f.db, f.stranger, hostedChannel, uuid.NewString(), "hey"); !errors.Is(err, errDatePlanNotFound) {
		t.Fatal("a removed member posted", err)
	}
	if code, out = roomCall(t, f, s.joinConversationRoom, http.MethodPost, f.stranger, roomID, `{}`); code != 409 || out["error_code"] != "ROOM_BLOCKED_ACTIVE_SESSION" {
		t.Fatal("rejoin after removal", code, out)
	}
	if code, out = roomCall(t, f, s.roomPresenceHandler, http.MethodPost, f.stranger, roomID, `{}`); code != 409 || out["error_code"] != "ROOM_BLOCKED_ACTIVE_SESSION" {
		t.Fatal("presence after removal", code, out)
	}
	var expires, ends string
	_ = f.db.QueryRow(`SELECT b.expires_at::text,r.ends_at::text FROM matching.conversation_room_blocks b JOIN matching.conversation_rooms r ON r.id=b.room_id WHERE b.room_id=$1 AND b.blocked_user_id=$2`, roomID, f.stranger).Scan(&expires, &ends)
	if expires == "" || expires != ends {
		t.Fatal("a hosted room's removal lasts until it ends", expires, ends)
	}
	// The host can remove a message in their room.
	msg, err := sendSocialMessage(ctx, f.db, f.invitee, hostedChannel, uuid.NewString(), "spam spam")
	if err != nil {
		t.Fatal(err)
	}
	if err = deleteSocialMessage(ctx, f.db, f.proposer, hostedChannel, msg.ID); err != nil {
		t.Fatal("host removes a message", err)
	}

	// Operators: remove from an always-on room for 24 hours, appoint a
	// moderator; moderators cannot act on each other or on hosts.
	operator := httptest.NewRecorder()
	req := blogRoute(http.MethodPost, f.groupMate, `{"target_user_id":"`+f.proposer+`","action":"remove_user"}`, map[string]string{"roomID": publicID})
	s.adminRoomActionHandler(operator, req)
	if operator.Code != 403 {
		t.Fatal("a member used the operator path", operator.Code)
	}
	if _, _, err = moderateLiveRoom(ctx, f.db, f.groupMate, publicID, f.blockedFriend, "remove_user", "spam", true); err != nil {
		t.Fatal("operator removal", err)
	}
	var hours float64
	_ = f.db.QueryRow(`SELECT EXTRACT(EPOCH FROM expires_at-NOW())/3600 FROM matching.conversation_room_blocks WHERE room_id=$1 AND blocked_user_id=$2`, publicID, f.blockedFriend).Scan(&hours)
	if hours < 23.9 || hours > 24.1 {
		t.Fatal("always-on removal lasts 24 hours", hours)
	}
	if _, err = joinLiveRoom(ctx, f.db, f.invitee, publicID); err != nil {
		t.Fatal(err)
	}
	if _, err = joinLiveRoom(ctx, f.db, f.inviteeFriend, publicID); err != nil {
		t.Fatal(err)
	}
	if err = setLiveRoomRole(ctx, f.db, f.groupMate, publicID, f.invitee, "moderator"); err != nil {
		t.Fatal(err)
	}
	if err = setLiveRoomRole(ctx, f.db, f.groupMate, publicID, f.inviteeFriend, "moderator"); err != nil {
		t.Fatal(err)
	}
	if _, _, err = moderateLiveRoom(ctx, f.db, f.invitee, publicID, f.inviteeFriend, "warn_user", "", false); err == nil {
		t.Fatal("a moderator warned another moderator")
	}
	if _, _, err = moderateLiveRoom(ctx, f.db, f.invitee, publicID, f.proposer, "warn_user", "", false); err != nil {
		t.Fatal("moderator warns a participant", err)
	}
	if _, _, err = moderateLiveRoom(ctx, f.db, f.invitee, publicID, "", "close_room", "", false); err == nil {
		t.Fatal("a moderator closed an always-on room")
	}
	if ch, _, err := loadChannel(ctx, f.db, f.invitee, pub.ChannelID); err != nil || !ch.CanModerate {
		t.Fatal("room moderators can remove messages", err)
	}

	// The host closes their room; chat ends with it.
	if _, _, err = moderateLiveRoom(ctx, f.db, f.proposer, roomID, "", "close_room", "", false); err != nil {
		t.Fatal("host closes", err)
	}
	if _, _, err = loadChannel(ctx, f.db, f.proposer, hostedChannel); !errors.Is(err, errDatePlanNotFound) {
		t.Fatal("chat stayed open after the room closed", err)
	}
	if code, out = roomCall(t, f, s.joinConversationRoom, http.MethodPost, f.groupMate, roomID, `{}`); code != 409 || out["error_code"] != "ROOM_CLOSED" {
		t.Fatal("join a closed room", code, out)
	}
	closed, err := listLiveRooms(ctx, f.db, f.proposer, "closed", "", false, 200)
	if err != nil {
		t.Fatal(err)
	}
	found := false
	for _, r := range closed {
		found = found || r.ID == roomID
	}
	if !found || strings.TrimSpace(roomID) == "" {
		t.Fatal("closed rooms are listed with state=closed")
	}
}

// The security middleware refuses a room moderation that names someone else
// as the moderator.
func TestRoomModeratorIdentityIsEnforced(t *testing.T) {
	for _, key := range []string{"moderator_user_id", "moderator_id"} {
		req := httptest.NewRequest(http.MethodPost, "/v1/rooms/x/moderate", strings.NewReader(`{"`+key+`":"someone-else","target_user_id":"t","action":"warn_user"}`))
		req.Header.Set("Content-Type", "application/json")
		if err := enforceBodyIdentity(req, "me"); err == nil {
			t.Fatalf("%s spoof accepted", key)
		}
		req = httptest.NewRequest(http.MethodPost, "/v1/rooms/x/moderate", strings.NewReader(`{"`+key+`":"me","target_user_id":"t","action":"warn_user"}`))
		req.Header.Set("Content-Type", "application/json")
		if err := enforceBodyIdentity(req, "me"); err != nil {
			t.Fatalf("%s self rejected: %v", key, err)
		}
	}
}

func TestNormalizeRoomAction(t *testing.T) {
	for in, want := range map[string]string{"warn": "warn", "warn_user": "warn", "REMOVE_USER": "remove", "close_room": "close",
		"mute": "mute", "mute_user": "mute", "unmute_user": "unmute"} {
		if got, ok := normalizeRoomAction(in); !ok || got != want {
			t.Fatalf("%s -> %s", in, got)
		}
		if want == "mute" && publicRoomAction(want) != roomModerationActionMute {
			t.Fatal("public mute action", publicRoomAction(want))
		}
	}
	for _, in := range []string{"ban", "kick", ""} {
		if _, ok := normalizeRoomAction(in); ok {
			t.Fatalf("%s accepted", in)
		}
	}
}

func operatorRoute(method, user, body string, params map[string]string) *http.Request {
	r := blogRoute(method, user, body, params)
	return r.WithContext(context.WithValue(r.Context(), securityPrincipalContextKey{}, securityPrincipal{UserID: user, Roles: map[string]bool{"user": true, "trust_safety": true}}))
}

func roomEvents(t *testing.T, f datePlanFixture, channelID, user, eventType string) int {
	t.Helper()
	var n int
	if err := f.db.QueryRow(`SELECT COUNT(*) FROM matching.realtime_outbox WHERE channel_id=$1 AND recipient_user_id=$2 AND event_type=$3`, channelID, user, eventType).Scan(&n); err != nil {
		t.Fatal(err)
	}
	return n
}

func roomMuteLog(t *testing.T, f datePlanFixture, roomID, target, action string) int {
	t.Helper()
	var n int
	if err := f.db.QueryRow(`SELECT COUNT(*) FROM matching.conversation_room_moderation_actions WHERE room_id=$1 AND target_user_id=$2 AND action=$3`, roomID, target, action).Scan(&n); err != nil {
		t.Fatal(err)
	}
	return n
}

func mutedMembers(t *testing.T, f datePlanFixture, viewer, roomID string) map[string]*time.Time {
	t.Helper()
	members, err := listRoomMembers(context.Background(), f.db, viewer, roomID)
	if err != nil {
		t.Fatal(err)
	}
	out := map[string]*time.Time{}
	for _, m := range members {
		out[m.UserID] = m.MutedUntil
	}
	return out
}

// Room mute: a muted member reads but cannot post until the mute ends or a
// host lifts it; the rule set matches warn and remove.
func TestLiveRoomMutePostgres(t *testing.T) {
	f := newLiveRoomFixture(t)
	var ready bool
	if err := f.db.QueryRow(`SELECT to_regclass('matching.social_channel_prefs') IS NOT NULL`).Scan(&ready); err != nil || !ready {
		t.Skip("migration 119_chat_mutes is not applied")
	}
	ctx := context.Background()
	s := blogServer(f)
	t.Cleanup(func() {
		_, _ = f.db.Exec(`DELETE FROM matching.notification_outbox WHERE recipient_user_id IN ($1,$2,$3,$4) AND event_type LIKE 'room.moderation.%'`, f.proposer, f.invitee, f.stranger, f.inviteeFriend)
	})

	hosted, err := createLiveRoom(ctx, f.db, f.proposer, roomDraft{Title: "Mute rehearsal", Category: "talk", DurationMinutes: 120})
	if err != nil {
		t.Fatal(err)
	}
	roomID, channelID := hosted.ID, hosted.ChannelID
	for _, u := range []string{f.invitee, f.stranger, f.inviteeFriend} {
		if _, err = joinLiveRoom(ctx, f.db, u, roomID); err != nil {
			t.Fatal(err)
		}
	}
	mute := func(actor, target, extra string) (int, map[string]any) {
		return roomCall(t, f, s.moderateConversationRoom, http.MethodPost, actor, roomID,
			`{"target_user_id":"`+target+`","action":"mute_user"`+extra+`}`)
	}

	// The rule set: participants can't mute, nobody mutes themselves, and a
	// spoofed moderator is refused.
	if code, out := mute(f.stranger, f.invitee, ``); code != 403 {
		t.Fatal("a participant muted someone", code, out)
	}
	if code, out := mute(f.proposer, f.proposer, ``); code != 400 {
		t.Fatal("the host muted themselves", code, out)
	}
	if code, out := mute(f.stranger, f.invitee, `,"moderator_user_id":"`+f.proposer+`"`); code != 403 {
		t.Fatal("muted as the host", code, out)
	}
	if code, out := mute(f.proposer, f.stranger, `,"duration":"forever"`); code != 400 {
		t.Fatal("unknown duration", code, out)
	}

	// The host mutes the stranger for ten minutes.
	before := time.Now().UTC()
	code, out := mute(f.proposer, f.stranger, `,"duration":"10m","reason":"Cool off"`)
	if code != 200 {
		t.Fatal("mute", code, out)
	}
	entry := out["moderation_action"].(map[string]any)
	if entry["action"] != roomModerationActionMute || entry["muted_until"] == nil {
		t.Fatal("mute entry", entry)
	}
	until, _ := time.Parse(time.RFC3339, entry["muted_until"].(string))
	if d := until.Sub(before); d < 9*time.Minute || d > 11*time.Minute {
		t.Fatal("10 minute mute", d)
	}
	if roomMuteLog(t, f, roomID, f.stranger, "mute") != 1 {
		t.Fatal("mute is logged")
	}
	var meta string
	_ = f.db.QueryRow(`SELECT metadata::text FROM matching.conversation_room_moderation_actions WHERE room_id=$1 AND target_user_id=$2 AND action='mute'`, roomID, f.stranger).Scan(&meta)
	if !strings.Contains(meta, "muted_until") || !strings.Contains(meta, `"duration": "10m"`) {
		t.Fatal("mute metadata", meta)
	}
	if f.notifications(t, f.stranger, "room.moderation.mute") != 1 {
		t.Fatal("the muted member is told")
	}
	if roomEvents(t, f, channelID, f.stranger, "social.channel.updated") != 1 {
		t.Fatal("an open chat hears about the mute")
	}

	// Muted: reads, cannot post (403 CHANNEL_READ_ONLY with the end time).
	_, err = sendSocialMessage(ctx, f.db, f.stranger, channelID, uuid.NewString(), "but wait")
	var ro socialReadOnlyError
	if !errors.As(err, &ro) || ro.until == nil || !strings.HasPrefix(ro.msg, "You're muted in this room until ") {
		t.Fatal("a muted member posted", err)
	}
	rec := httptest.NewRecorder()
	s.socialMessagesHandler(rec, blogRoute(http.MethodPost, f.stranger, `{"body":"hello?","client_message_id":"`+uuid.NewString()+`"}`, map[string]string{"channelID": channelID}))
	var refused map[string]any
	_ = json.Unmarshal(rec.Body.Bytes(), &refused)
	if rec.Code != 403 || refused["error_code"] != "CHANNEL_READ_ONLY" || refused["read_only_until"] == nil || !strings.Contains(refused["error"].(string), "muted") {
		t.Fatal("read-only over HTTP", rec.Code, rec.Body.String())
	}
	if _, err = sendSocialMessage(ctx, f.db, f.proposer, channelID, uuid.NewString(), "Welcome, everyone"); err != nil {
		t.Fatal(err)
	}
	if msgs, _, err := listSocialMessages(ctx, f.db, f.stranger, channelID, "", 10); err != nil || len(msgs) == 0 {
		t.Fatal("a muted member still reads", err, len(msgs))
	}
	if roomEvents(t, f, channelID, f.stranger, "social.message.created") != 1 {
		t.Fatal("a muted member still gets real-time messages")
	}
	ch, _, err := loadChannel(ctx, f.db, f.stranger, channelID)
	if err != nil || !ch.ReadOnly || ch.ReadOnlyUntil == nil || ch.ReadOnlyMessage == "" {
		t.Fatal("channel shows read-only", err, ch)
	}
	if other, _, _ := loadChannel(ctx, f.db, f.invitee, channelID); other.ReadOnly {
		t.Fatal("someone else is read-only")
	}
	// Hosts and the member see the mute; other participants don't.
	if got := mutedMembers(t, f, f.proposer, roomID); got[f.stranger] == nil || got[f.invitee] != nil {
		t.Fatal("host's member list", got)
	}
	if got := mutedMembers(t, f, f.invitee, roomID); got[f.stranger] != nil {
		t.Fatal("a participant sees who is muted")
	}
	if got := mutedMembers(t, f, f.stranger, roomID); got[f.stranger] == nil {
		t.Fatal("the muted member sees their own mute")
	}
	// Leaving and rejoining doesn't shake off a mute.
	if _, err = leaveLiveRoom(ctx, f.db, f.stranger, roomID); err != nil {
		t.Fatal(err)
	}
	if _, err = joinLiveRoom(ctx, f.db, f.stranger, roomID); err != nil {
		t.Fatal(err)
	}
	if ch, _, _ = loadChannel(ctx, f.db, f.stranger, channelID); !ch.ReadOnly {
		t.Fatal("rejoining lifted the mute")
	}

	// Unmute: posting works again; a second unmute changes and logs nothing.
	code, out = roomCall(t, f, s.moderateConversationRoom, http.MethodPost, f.proposer, roomID,
		`{"target_user_id":"`+f.stranger+`","action":"unmute_user"}`)
	if code != 200 || out["moderation_action"].(map[string]any)["action"] != roomModerationActionUnmute {
		t.Fatal("unmute", code, out)
	}
	if _, err = sendSocialMessage(ctx, f.db, f.stranger, channelID, uuid.NewString(), "Thanks, all good"); err != nil {
		t.Fatal("posting after unmute", err)
	}
	if code, out = roomCall(t, f, s.moderateConversationRoom, http.MethodPost, f.proposer, roomID,
		`{"target_user_id":"`+f.stranger+`","action":"unmute"}`); code != 200 {
		t.Fatal("repeat unmute", code, out)
	}
	if roomMuteLog(t, f, roomID, f.stranger, "unmute") != 1 || f.notifications(t, f.stranger, "room.moderation.unmute") != 1 {
		t.Fatal("unmute logged and notified once")
	}
	if roomEvents(t, f, channelID, f.stranger, "social.channel.updated") != 2 {
		t.Fatal("an open chat hears about the unmute")
	}

	// Muting again (idempotent replays just move the end); "session" lasts
	// until the hosted room ends; custom minutes work.
	for i := 0; i < 2; i++ {
		if code, out = mute(f.proposer, f.stranger, `,"duration":"session"`); code != 200 {
			t.Fatal("session mute", code, out)
		}
	}
	var mutedTo, ends time.Time
	_ = f.db.QueryRow(`SELECT p.muted_until,r.ends_at FROM matching.conversation_room_participants p JOIN matching.conversation_rooms r ON r.id=p.room_id WHERE p.room_id=$1 AND p.user_id=$2`, roomID, f.stranger).Scan(&mutedTo, &ends)
	if !mutedTo.Equal(ends) {
		t.Fatal("a session mute lasts until the room ends", mutedTo, ends)
	}
	if code, out = mute(f.proposer, f.invitee, `,"duration_minutes":5`); code != 200 {
		t.Fatal("custom mute", code, out)
	}
	if code, out = mute(f.proposer, f.invitee, `,"duration_minutes":0`); code != 400 {
		t.Fatal("a zero-minute mute", code, out)
	}
	// Expiry: once the time passes the member can post without an unmute.
	if _, err = f.db.Exec(`UPDATE matching.conversation_room_participants SET muted_until=NOW()-interval '1 second' WHERE room_id=$1 AND user_id=$2`, roomID, f.invitee); err != nil {
		t.Fatal(err)
	}
	if _, err = sendSocialMessage(ctx, f.db, f.invitee, channelID, uuid.NewString(), "Back again"); err != nil {
		t.Fatal("posting after the mute expired", err)
	}
	if got := mutedMembers(t, f, f.proposer, roomID); got[f.invitee] != nil {
		t.Fatal("an expired mute is still listed")
	}

	// Moderators mute participants, not other moderators or the host; only
	// operators act on a host.
	if err = setLiveRoomRole(ctx, f.db, f.groupMate, roomID, f.invitee, "moderator"); err != nil {
		t.Fatal(err)
	}
	if code, out = mute(f.invitee, f.stranger, `,"duration":"1h"`); code != 200 {
		t.Fatal("a moderator mutes a participant", code, out)
	}
	if code, out = mute(f.invitee, f.proposer, ``); code != 403 {
		t.Fatal("a moderator muted the host", code, out)
	}
	if err = setLiveRoomRole(ctx, f.db, f.groupMate, roomID, f.inviteeFriend, "moderator"); err != nil {
		t.Fatal(err)
	}
	if code, out = mute(f.invitee, f.inviteeFriend, ``); code != 403 {
		t.Fatal("a moderator muted a moderator", code, out)
	}
	rec = httptest.NewRecorder()
	s.adminRoomActionHandler(rec, blogRoute(http.MethodPost, f.groupMate, `{"target_user_id":"`+f.proposer+`","action":"mute_user"}`, map[string]string{"roomID": roomID}))
	if rec.Code != 403 {
		t.Fatal("a member used the operator mute", rec.Code)
	}
	rec = httptest.NewRecorder()
	s.adminRoomActionHandler(rec, operatorRoute(http.MethodPost, f.groupMate, `{"target_user_id":"`+f.proposer+`","action":"mute_user","duration":"1h"}`, map[string]string{"roomID": roomID}))
	if rec.Code != 200 {
		t.Fatal("an operator mutes the host", rec.Code, rec.Body.String())
	}
	if _, err = sendSocialMessage(ctx, f.db, f.proposer, channelID, uuid.NewString(), "hm"); err == nil {
		t.Fatal("a muted host posted")
	}
	rec = httptest.NewRecorder()
	s.adminRoomActionHandler(rec, operatorRoute(http.MethodPost, f.groupMate, `{"target_user_id":"`+f.proposer+`","action":"unmute_user"}`, map[string]string{"roomID": roomID}))
	if rec.Code != 200 {
		t.Fatal("an operator unmutes the host", rec.Code, rec.Body.String())
	}
	var operatorFlag bool
	_ = f.db.QueryRow(`SELECT (metadata->>'operator')::boolean FROM matching.conversation_room_moderation_actions WHERE room_id=$1 AND target_user_id=$2 AND action='mute'`, roomID, f.proposer).Scan(&operatorFlag)
	if !operatorFlag {
		t.Fatal("operator mutes are marked in the log")
	}

	// Always-on rooms: a session mute lasts 24 hours.
	publicID := seededRoomID(t, f, "gamers-lounge")
	for _, u := range []string{f.proposer, f.stranger} {
		if _, err = joinLiveRoom(ctx, f.db, u, publicID); err != nil {
			t.Fatal(err)
		}
	}
	if _, entry, err := applyRoomModeration(ctx, f.db, roomModerationRequest{Actor: f.groupMate, RoomID: publicID, Target: f.stranger, Action: "mute_user", Duration: "session", Operator: true}); err != nil || entry.MutedUntil == nil {
		t.Fatal("always-on session mute", err)
	} else if h := time.Until(*entry.MutedUntil).Hours(); h < 23.9 || h > 24.1 {
		t.Fatal("always-on session mute lasts 24 hours", h)
	}
	if _, _, err = applyRoomModeration(ctx, f.db, roomModerationRequest{Actor: f.groupMate, RoomID: publicID, Target: f.stranger, Action: "unmute_user", Operator: true}); err != nil {
		t.Fatal(err)
	}

	// A closed room can't be moderated.
	if _, _, err = moderateLiveRoom(ctx, f.db, f.proposer, roomID, "", "close_room", "", false); err != nil {
		t.Fatal(err)
	}
	if _, _, err = applyRoomModeration(ctx, f.db, roomModerationRequest{Actor: f.groupMate, RoomID: roomID, Target: f.stranger, Action: "mute_user", Operator: true}); !errors.Is(err, errRoomModerationNotActive) {
		t.Fatal("muted in a closed room", err)
	}
}

func TestRoomMuteUntil(t *testing.T) {
	now := time.Date(2026, 10, 1, 20, 0, 0, 0, time.UTC)
	hosted := lockedRoom{endsAt: sql.NullTime{Time: now.Add(30 * time.Minute), Valid: true}}
	if until, label, err := roomMuteUntil(now, hosted, "1h", 0); err != nil || label != "1h" || !until.Equal(now.Add(30*time.Minute)) {
		t.Fatal("a mute never outlasts the room", until, label, err)
	}
	if until, _, _ := roomMuteUntil(now, hosted, "", 0); !until.Equal(now.Add(10 * time.Minute)) {
		t.Fatal("default mute is 10 minutes", until)
	}
	always := lockedRoom{alwaysOn: true}
	if until, label, _ := roomMuteUntil(now, always, "session", 0); label != "session" || !until.Equal(now.Add(24*time.Hour)) {
		t.Fatal("always-on session", until)
	}
	if until, _, _ := roomMuteUntil(now, always, "", 90); !until.Equal(now.Add(90 * time.Minute)) {
		t.Fatal("custom minutes", until)
	}
	for _, bad := range []struct {
		d string
		m int
	}{{"2d", 0}, {"", 1441}, {"", -1}} {
		if _, _, err := roomMuteUntil(now, always, bad.d, bad.m); err == nil {
			t.Fatal("accepted", bad)
		}
	}
	if roomMuteSpan("session", false) != "until the room ends" || roomMuteSpan("session", true) != "for 24 hours" {
		t.Fatal("mute spans")
	}
}

// Operators list a room's members with mute and removal state; members
// can't use the operator route.
func TestAdminRoomMembersPostgres(t *testing.T) {
	f := newLiveRoomFixture(t)
	var ready bool
	if err := f.db.QueryRow(`SELECT to_regclass('matching.social_channel_prefs') IS NOT NULL`).Scan(&ready); err != nil || !ready {
		t.Skip("migration 119_chat_mutes is not applied")
	}
	ctx := context.Background()
	s := blogServer(f)
	hosted, err := createLiveRoom(ctx, f.db, f.proposer, roomDraft{Title: "Operator roll call", DurationMinutes: 60})
	if err != nil {
		t.Fatal(err)
	}
	roomID := hosted.ID
	for _, u := range []string{f.invitee, f.stranger, f.blockedFriend} {
		if _, err = joinLiveRoom(ctx, f.db, u, roomID); err != nil && u != f.blockedFriend {
			t.Fatal(err)
		}
	}
	if _, _, err = applyRoomModeration(ctx, f.db, roomModerationRequest{Actor: f.proposer, RoomID: roomID, Target: f.invitee, Action: "mute_user", Duration: "1h"}); err != nil {
		t.Fatal(err)
	}
	if _, _, err = moderateLiveRoom(ctx, f.db, f.proposer, roomID, f.stranger, "remove_user", "spam", false); err != nil {
		t.Fatal(err)
	}

	call := func(req *http.Request) (int, map[string]any) {
		rec := httptest.NewRecorder()
		s.adminRoomMembersHandler(rec, req)
		out := map[string]any{}
		_ = json.Unmarshal(rec.Body.Bytes(), &out)
		return rec.Code, out
	}
	if code, _ := call(blogRoute(http.MethodGet, f.proposer, "", map[string]string{"roomID": roomID})); code != 403 {
		t.Fatal("a host used the operator member list", code)
	}
	if code, _ := call(operatorRoute(http.MethodGet, f.groupMate, "", map[string]string{"roomID": uuid.NewString()})); code != 404 {
		t.Fatal("unknown room", code)
	}
	code, out := call(operatorRoute(http.MethodGet, f.groupMate, "", map[string]string{"roomID": roomID}))
	if code != 200 {
		t.Fatal("operator member list", code, out)
	}
	byID := map[string]map[string]any{}
	for _, raw := range out["members"].([]any) {
		m := raw.(map[string]any)
		byID[m["user_id"].(string)] = m
	}
	host := byID[f.proposer]
	if host == nil || host["role"] != "host" || host["in_room"] != true || host["here_now"] != true || host["name"] == "" || host["last_seen_at"] == nil {
		t.Fatal("host row", host)
	}
	muted := byID[f.invitee]
	if muted == nil || muted["muted_until"] == nil || muted["removed_until"] != nil || muted["in_room"] != true {
		t.Fatal("muted row", muted)
	}
	removed := byID[f.stranger]
	if removed == nil || removed["status"] != "removed" || removed["in_room"] != false || removed["removed_until"] == nil {
		t.Fatal("removed row", removed)
	}
	if out["members"].([]any)[0].(map[string]any)["user_id"] != f.proposer {
		t.Fatal("hosts come first", out["members"])
	}
}
