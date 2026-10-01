package mobile

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
)

func TestSocialFriendChatPostgres(t *testing.T) {
	f := newBlogTrustFixture(t)
	var ready bool
	if err := f.db.QueryRow(`SELECT to_regclass('matching.social_messages') IS NOT NULL`).Scan(&ready); err != nil || !ready {
		t.Skip("migration 115_social_channels is not applied")
	}
	ctx := context.Background()
	t.Cleanup(func() {
		_, _ = f.db.Exec(`DELETE FROM matching.social_channels WHERE kind='friend' AND (user_low IN ($1,$2,$3,$4) OR user_high IN ($1,$2,$3,$4))`, f.proposer, f.proposerFriend, f.blockedFriend, f.stranger)
		_, _ = f.db.Exec(`DELETE FROM matching.notification_outbox WHERE recipient_user_id IN ($1,$2)`, f.proposer, f.proposerFriend)
	})

	// Only accepted, unblocked friends can open a conversation.
	if _, err := ensureFriendChannel(ctx, f.db, f.proposer, f.stranger); err == nil {
		t.Fatal("opened a conversation with a non-friend")
	}
	if _, err := ensureFriendChannel(ctx, f.db, f.proposer, f.blockedFriend); err == nil {
		t.Fatal("opened a conversation across a block")
	}
	ch, err := ensureFriendChannel(ctx, f.db, f.proposer, f.proposerFriend)
	if err != nil || ch.Kind != "friend" || ch.PeerID != f.proposerFriend || ch.MemberCount != 2 || ch.Title == "" {
		t.Fatal("open friend channel", err, ch)
	}
	again, err := ensureFriendChannel(ctx, f.db, f.proposerFriend, f.proposer)
	if err != nil || again.ID != ch.ID || again.PeerID != f.proposer {
		t.Fatal("both friends share one conversation", err, again.ID, ch.ID)
	}

	clientID := uuid.NewString()
	m, err := sendSocialMessage(ctx, f.db, f.proposer, ch.ID, clientID, "  Coffee on Sunday?  ")
	if err != nil || m.Body != "Coffee on Sunday?" || !m.Mine || m.SenderName == "" {
		t.Fatal("send", err, m)
	}
	if dup, err := sendSocialMessage(ctx, f.db, f.proposer, ch.ID, clientID, "Coffee on Sunday?"); err != nil || dup.ID != m.ID {
		t.Fatal("a retried send must not post twice", err, dup.ID, m.ID)
	}
	if _, err := sendSocialMessage(ctx, f.db, f.stranger, ch.ID, uuid.NewString(), "hi"); !errors.Is(err, errDatePlanNotFound) {
		t.Fatal("a stranger posted into a friend conversation", err)
	}
	if _, err := sendSocialMessage(ctx, f.db, f.proposer, ch.ID, uuid.NewString(), "   "); err == nil {
		t.Fatal("empty message accepted")
	}
	if _, err := sendSocialMessage(ctx, f.db, f.proposer, ch.ID, uuid.NewString(), strings.Repeat("a", 2001)); err == nil {
		t.Fatal("over-long message accepted")
	}

	// The friend gets a real-time event and one notification; the sender none.
	var events int
	_ = f.db.QueryRow(`SELECT COUNT(*) FROM matching.realtime_outbox WHERE channel_id=$1 AND recipient_user_id=$2 AND event_type='social.message.created'`, ch.ID, f.proposerFriend).Scan(&events)
	if events != 1 {
		t.Fatal("realtime fan-out", events)
	}
	_ = f.db.QueryRow(`SELECT COUNT(*) FROM matching.realtime_outbox WHERE channel_id=$1 AND recipient_user_id=$2`, ch.ID, f.proposer).Scan(&events)
	if events != 0 {
		t.Fatal("the sender received their own event", events)
	}
	reply, err := sendSocialMessage(ctx, f.db, f.proposerFriend, ch.ID, uuid.NewString(), "Yes! The bookshop café?")
	if err != nil {
		t.Fatal(err)
	}
	var notices int
	_ = f.db.QueryRow(`SELECT COUNT(*) FROM matching.notification_outbox WHERE recipient_user_id=$1 AND event_type='social.message.new'`, f.proposer).Scan(&notices)
	if notices != 1 {
		t.Fatal("friend message notification", notices)
	}

	// Paging, unread counts and reads.
	page, more, err := listSocialMessages(ctx, f.db, f.proposer, ch.ID, "", 1)
	if err != nil || len(page) != 1 || !more || page[0].ID != reply.ID {
		t.Fatal("newest page", err, len(page), more)
	}
	older, more, err := listSocialMessages(ctx, f.db, f.proposer, ch.ID, page[0].ID, 10)
	if err != nil || len(older) != 1 || more || older[0].ID != m.ID {
		t.Fatal("older page", err, len(older), more)
	}
	list, err := listSocialChannels(ctx, f.db, f.proposer)
	if err != nil {
		t.Fatal(err)
	}
	var mine *socialChannel
	for i := range list {
		if list[i].ID == ch.ID {
			mine = &list[i]
		}
	}
	if mine == nil || mine.UnreadCount != 1 || mine.LastMessage != reply.Body {
		t.Fatal("conversation list", mine)
	}
	if err = markSocialRead(ctx, f.db, f.proposer, ch.ID); err != nil {
		t.Fatal(err)
	}
	if got, _, _ := loadChannel(ctx, f.db, f.proposer, ch.ID); got.ID == "" {
		t.Fatal("reload channel")
	}
	summary := ch
	if err = fillSocialSummary(ctx, f.db, f.proposer, &summary); err != nil || summary.UnreadCount != 0 {
		t.Fatal("read clears unread", err, summary.UnreadCount)
	}

	// Only the sender deletes; a friend conversation has no moderators.
	if err = deleteSocialMessage(ctx, f.db, f.proposerFriend, ch.ID, m.ID); err == nil {
		t.Fatal("deleted someone else's message")
	}
	if err = deleteSocialMessage(ctx, f.db, f.proposer, ch.ID, m.ID); err != nil {
		t.Fatal(err)
	}
	if got, err := readSocialMessage(ctx, f.db, f.proposerFriend, ch.ID, m.ID); err != nil || !got.Deleted || got.Body != "" {
		t.Fatal("deleted message is a tombstone", err, got)
	}

	// HTTP: list, send and the realtime cursor.
	s := blogServer(f)
	rec := httptest.NewRecorder()
	s.socialMessagesHandler(rec, blogRoute(http.MethodGet, f.proposer, "", map[string]string{"channelID": ch.ID}))
	var out map[string]any
	_ = json.Unmarshal(rec.Body.Bytes(), &out)
	if rec.Code != 200 || out["realtime_cursor"] == nil || len(out["messages"].([]any)) != 2 {
		t.Fatal("list over HTTP", rec.Code, rec.Body.String())
	}
	rec = httptest.NewRecorder()
	s.socialMessagesHandler(rec, blogRoute(http.MethodPost, f.proposer, `{"body":"See you there","client_message_id":"`+uuid.NewString()+`"}`, map[string]string{"channelID": ch.ID}))
	if rec.Code != 201 {
		t.Fatal("send over HTTP", rec.Code, rec.Body.String())
	}

	// Reports go to the shared case queue.
	caseID, err := createBlogCase(ctx, f.db, f.proposer, "social_message", reply.ID, "harassment", "")
	if err != nil || caseID == "" {
		t.Fatal("report a chat message", err)
	}

	// Ending the friendship closes the conversation for both.
	if _, err = f.db.Exec(`UPDATE matching.friend_connections SET status='pending' WHERE user_id=$1 AND friend_user_id=$2`, f.proposerFriend, f.proposer); err != nil {
		t.Fatal(err)
	}
	if _, _, err = loadChannel(ctx, f.db, f.proposer, ch.ID); !errors.Is(err, errDatePlanNotFound) {
		t.Fatal("conversation stayed open after the friendship ended", err)
	}
}

func socialCall(t *testing.T, handler func(http.ResponseWriter, *http.Request), method, user, channelID, body string) (int, map[string]any) {
	t.Helper()
	rec := httptest.NewRecorder()
	handler(rec, blogRoute(method, user, body, map[string]string{"channelID": channelID}))
	out := map[string]any{}
	_ = json.Unmarshal(rec.Body.Bytes(), &out)
	return rec.Code, out
}

// Muting a conversation's notifications: the engine skips the notification
// but real-time events still flow; the choice shows on the channel and in
// the conversation list; unmuting and expiry bring notifications back.
func TestSocialNotificationMutePostgres(t *testing.T) {
	f := newBlogTrustFixture(t)
	var ready bool
	if err := f.db.QueryRow(`SELECT to_regclass('matching.social_channel_prefs') IS NOT NULL`).Scan(&ready); err != nil || !ready {
		t.Skip("migration 119_chat_mutes is not applied")
	}
	ctx := context.Background()
	s := blogServer(f)
	clearNotices := func() {
		_, _ = f.db.Exec(`DELETE FROM matching.notification_outbox WHERE recipient_user_id IN ($1,$2) AND event_type='social.message.new'`, f.proposer, f.proposerFriend)
	}
	t.Cleanup(func() {
		_, _ = f.db.Exec(`DELETE FROM matching.social_channels WHERE kind='friend' AND (user_low IN ($1,$2) OR user_high IN ($1,$2))`, f.proposer, f.proposerFriend)
		clearNotices()
	})
	ch, err := ensureFriendChannel(ctx, f.db, f.proposer, f.proposerFriend)
	if err != nil {
		t.Fatal(err)
	}
	if ch.Muted || ch.MutedUntil != nil || ch.ReadOnly {
		t.Fatal("a new conversation is not muted", ch)
	}
	friendSays := func(body string) {
		t.Helper()
		if _, err := sendSocialMessage(ctx, f.db, f.proposerFriend, ch.ID, uuid.NewString(), body); err != nil {
			t.Fatal(err)
		}
	}
	notices := func() int { return f.notifications(t, f.proposer, "social.message.new") }
	events := func() int {
		var n int
		_ = f.db.QueryRow(`SELECT COUNT(*) FROM matching.realtime_outbox WHERE channel_id=$1 AND recipient_user_id=$2 AND event_type='social.message.created'`, ch.ID, f.proposer).Scan(&n)
		return n
	}
	clearNotices()

	// Validation and membership.
	if code, out := socialCall(t, s.socialMuteHandler, http.MethodPut, f.proposer, ch.ID, `{"duration":"2d"}`); code != 400 {
		t.Fatal("unknown duration", code, out)
	}
	if code, out := socialCall(t, s.socialMuteHandler, http.MethodPut, f.proposer, ch.ID, `{"minutes":0}`); code != 400 {
		t.Fatal("zero minutes", code, out)
	}
	if code, out := socialCall(t, s.socialMuteHandler, http.MethodPut, f.proposer, ch.ID, `{}`); code != 400 {
		t.Fatal("no duration", code, out)
	}
	if code, out := socialCall(t, s.socialMuteHandler, http.MethodPut, f.stranger, ch.ID, `{"duration":"1h"}`); code != 404 {
		t.Fatal("a non-member muted a conversation", code, out)
	}

	// Mute for an hour: no notification, but the real-time event arrives.
	before := time.Now().UTC()
	code, out := socialCall(t, s.socialMuteHandler, http.MethodPut, f.proposer, ch.ID, `{"duration":"1h"}`)
	if code != 200 || out["muted"] != true || out["muted_until"] == nil {
		t.Fatal("mute an hour", code, out)
	}
	until, _ := time.Parse(time.RFC3339Nano, out["muted_until"].(string))
	if d := until.Sub(before); d < 59*time.Minute || d > 61*time.Minute {
		t.Fatal("an hour", d)
	}
	// Repeating the same request is harmless.
	if code, again := socialCall(t, s.socialMuteHandler, http.MethodPut, f.proposer, ch.ID, `{"duration":"1h"}`); code != 200 || again["muted"] != true {
		t.Fatal("repeat mute", code, again)
	}
	friendSays("Are you free Sunday?")
	if notices() != 0 {
		t.Fatal("a muted conversation notified")
	}
	if events() != 1 {
		t.Fatal("real-time events still flow while muted", events())
	}
	if f.notifications(t, f.proposerFriend, "social.message.new") != 0 {
		t.Fatal("the sender was notified")
	}

	// The list and the channel carry the mute, only for the member who set it.
	list, err := listSocialChannels(ctx, f.db, f.proposer)
	if err != nil {
		t.Fatal(err)
	}
	found := false
	for _, c := range list {
		if c.ID == ch.ID {
			found = c.Muted && c.MutedUntil != nil
		}
	}
	if !found {
		t.Fatal("the conversation list shows the mute")
	}
	code, out = socialCall(t, s.socialChannelsHandler, http.MethodGet, f.proposer, "", "")
	if code != 200 || !strings.Contains(socialJSON(t, out), `"muted":true`) {
		t.Fatal("GET /social/channels shows muted", code, out)
	}
	if peer, _, _ := loadChannel(ctx, f.db, f.proposerFriend, ch.ID); peer.Muted {
		t.Fatal("the friend's side is muted too")
	}

	// Expiry: once the time passes notifications come back by themselves.
	if _, err = f.db.Exec(`UPDATE matching.social_channel_prefs SET muted_until=NOW()-interval '1 second' WHERE channel_id=$1 AND user_id=$2`, ch.ID, f.proposer); err != nil {
		t.Fatal(err)
	}
	if got, _, _ := loadChannel(ctx, f.db, f.proposer, ch.ID); got.Muted || got.MutedUntil != nil {
		t.Fatal("an expired mute still shows", got.Muted, got.MutedUntil)
	}
	friendSays("Hello?")
	if notices() != 1 {
		t.Fatal("notifications return after the mute expires", notices())
	}

	// Until I turn it back on: muted with no end time.
	clearNotices()
	code, out = socialCall(t, s.socialMuteHandler, http.MethodPut, f.proposer, ch.ID, `{"duration":"forever"}`)
	if code != 200 || out["muted"] != true || out["muted_until"] != nil {
		t.Fatal("mute until turned back on", code, out)
	}
	friendSays("Still there?")
	if notices() != 0 {
		t.Fatal("an indefinitely muted conversation notified")
	}

	// Unmute (twice: the second is a no-op) and notifications return.
	for i := 0; i < 2; i++ {
		if code, out = socialCall(t, s.socialMuteHandler, http.MethodDelete, f.proposer, ch.ID, ``); code != 200 || out["muted"] != false || out["muted_until"] != nil {
			t.Fatal("unmute", code, out)
		}
	}
	friendSays("Okay, call me!")
	if notices() != 1 {
		t.Fatal("notifications return after unmuting", notices())
	}
	// Custom minutes.
	if code, out = socialCall(t, s.socialMuteHandler, http.MethodPut, f.proposer, ch.ID, `{"minutes":15}`); code != 200 || out["muted"] != true {
		t.Fatal("15 minute mute", code, out)
	}
}

func socialJSON(t *testing.T, v any) string {
	t.Helper()
	raw, err := json.Marshal(v)
	if err != nil {
		t.Fatal(err)
	}
	return string(raw)
}

func TestParseSocialMute(t *testing.T) {
	for body, want := range map[string]time.Duration{"1h": time.Hour, "8H": 8 * time.Hour, "1w": 7 * 24 * time.Hour} {
		if d, forever, err := parseSocialMute(map[string]any{"duration": body}); err != nil || forever || d != want {
			t.Fatal(body, d, forever, err)
		}
	}
	if _, forever, err := parseSocialMute(map[string]any{"duration": "forever"}); err != nil || !forever {
		t.Fatal("forever", err)
	}
	if d, _, err := parseSocialMute(map[string]any{"minutes": float64(30)}); err != nil || d != 30*time.Minute {
		t.Fatal("minutes", d, err)
	}
	for _, bad := range []map[string]any{{}, {"duration": "2d"}, {"minutes": float64(0)}, {"minutes": float64(50000)}} {
		if _, _, err := parseSocialMute(bad); err == nil {
			t.Fatal("accepted", bad)
		}
	}
}
