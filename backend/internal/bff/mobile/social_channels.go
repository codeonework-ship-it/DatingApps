package mobile

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)

// Shared chat engine (migration 115): friend conversations, Conversation Room
// chat and group chat all store messages in matching.social_messages. A
// channelSpec says who belongs to a channel, read live from the owning
// feature's tables, so leaving, unfriending or blocking applies at once. New
// messages fan out through matching.realtime_outbox to the chat websocket.
//
// Feature code registers a spec for its kind (see registerChannelSpec) and
// gets a channel id with ensureRefChannel (rooms, groups) or
// ensureFriendChannel.

// channelSpec binds one kind of channel to its membership rules. Every SQL
// fragment may use channel alias c (c.id, c.ref_id, c.user_low, c.user_high)
// and must select a single uuid column of user ids.
type channelSpec struct {
	Kind string
	// MembersSQL selects the user ids who may read and post.
	MembersSQL string
	// ModeratorsSQL selects user ids who may remove other members'
	// messages. Empty means only senders delete their own.
	ModeratorsSQL string
	// TitleSQL is a text expression naming the channel for viewer $1.
	TitleSQL string
	// Notify sends recipients a notification (at most one per channel every
	// ten minutes) in addition to the real-time event.
	Notify bool
	// Route opened by notifications, e.g. "/friends".
	Route string
	// ReadOnlySQL, when set, selects (user id, until) rows: members who may
	// read but not post until then (a NULL until lasts until lifted), for
	// example a member muted in a room. Same aliases as MembersSQL.
	ReadOnlySQL string
	// ReadOnlyMessage explains read-only membership, e.g. "You're muted in
	// this room"; the engine adds when it ends.
	ReadOnlyMessage string
}

var channelSpecs = map[string]channelSpec{}

// registerChannelSpec makes a channel kind available. Call it from an init
// function in the feature's file.
func registerChannelSpec(spec channelSpec) { channelSpecs[spec.Kind] = spec }

func init() { registerChannelSpec(friendChannelSpec) }

const (
	socialMessageMaxRunes  = 2000
	socialMessagesPerMin   = 20
	socialPageSize         = 50
	socialNotifyBucketMins = 10
)

// socialActiveMember: users alias u is an active adult dating member.
const socialActiveMember = blogActive

// socialNotBlockedSQL: neither user blocked the other.
func socialNotBlockedSQL(a, b string) string {
	return `NOT EXISTS(SELECT 1 FROM user_management.blocked_users bl WHERE (bl.user_id=` + a + ` AND bl.blocked_user_id=` + b + `) OR (bl.user_id=` + b + ` AND bl.blocked_user_id=` + a + `))`
}

// friendChannelSpec: the two members of an accepted, unblocked friendship.
var friendChannelSpec = channelSpec{
	Kind: "friend",
	MembersSQL: `SELECT v.uid FROM (VALUES (c.user_low),(c.user_high)) v(uid)
 WHERE EXISTS(SELECT 1 FROM matching.friend_connections f WHERE f.user_id=c.user_low AND f.friend_user_id=c.user_high AND f.status='accepted')
   AND EXISTS(SELECT 1 FROM matching.friend_connections f WHERE f.user_id=c.user_high AND f.friend_user_id=c.user_low AND f.status='accepted')
   AND ` + socialNotBlockedSQL("c.user_low", "c.user_high"),
	TitleSQL: `(SELECT COALESCE(NULLIF(u.name,''),u.username,'A friend') FROM user_management.users u
 WHERE u.id=CASE WHEN c.user_low=$1::uuid THEN c.user_high ELSE c.user_low END)`,
	Notify: true,
	Route:  "/friends",
}

// membersSQL wraps a spec's members with the active-account rule.
func (s channelSpec) membersSQL() string {
	return `SELECT m.uid FROM (` + s.MembersSQL + `) m(uid) JOIN user_management.users u ON u.id=m.uid WHERE ` + socialActiveMember
}

type socialChannel struct {
	ID            string     `json:"id"`
	Kind          string     `json:"kind"`
	RefID         string     `json:"ref_id,omitempty"`
	Title         string     `json:"title"`
	PeerID        string     `json:"peer_id,omitempty"`
	MemberCount   int        `json:"member_count"`
	CanModerate   bool       `json:"can_moderate"`
	LastMessageAt *time.Time `json:"last_message_at"`
	LastMessage   string     `json:"last_message"`
	UnreadCount   int        `json:"unread_count"`
	// ReadOnly: the member may read but not post (see channelSpec.ReadOnlySQL),
	// until ReadOnlyUntil (nil: until lifted).
	ReadOnly        bool       `json:"read_only"`
	ReadOnlyUntil   *time.Time `json:"read_only_until"`
	ReadOnlyMessage string     `json:"read_only_message,omitempty"`
	// Muted: the member silenced notifications for this conversation, until
	// MutedUntil (nil while muted: until they turn them back on).
	Muted      bool       `json:"muted"`
	MutedUntil *time.Time `json:"muted_until"`
}

type socialMessage struct {
	ID              string    `json:"id"`
	ChannelID       string    `json:"channel_id"`
	SenderID        string    `json:"sender_id"`
	SenderName      string    `json:"sender_name"`
	SenderPhotoURL  string    `json:"sender_photo_url"`
	Body            string    `json:"body"`
	ClientMessageID string    `json:"client_message_id"`
	CreatedAt       time.Time `json:"created_at"`
	Deleted         bool      `json:"deleted"`
	Mine            bool      `json:"mine"`
}

// socialMemberCardSQL: name and first approved photo for user column col.
func socialMemberCardSQL(col string) string {
	return `COALESCE((SELECT COALESCE(NULLIF(u2.name,''),u2.username,'') FROM user_management.users u2 WHERE u2.id=` + col + `),''),
 COALESCE((SELECT ph.photo_url FROM user_management.photos ph WHERE ph.user_id=` + col + ` AND ph.deleted_at IS NULL
  AND ph.lifecycle_status='active' AND ph.moderation_status='approved' ORDER BY ph.ordering,ph.id LIMIT 1),'')`
}

// loadChannel reads a channel the actor belongs to, or errDatePlanNotFound.
func loadChannel(ctx context.Context, q blogQuerier, actor, channelID string) (socialChannel, channelSpec, error) {
	var ch socialChannel
	var ref, low, high sql.NullString
	err := q.QueryRowContext(ctx, `SELECT id::text,kind,ref_id::text,user_low::text,user_high::text,last_message_at FROM matching.social_channels WHERE id=$1::uuid`, channelID).
		Scan(&ch.ID, &ch.Kind, &ref, &low, &high, &ch.LastMessageAt)
	if errors.Is(err, sql.ErrNoRows) {
		return ch, channelSpec{}, errDatePlanNotFound
	}
	if err != nil {
		return ch, channelSpec{}, err
	}
	spec, ok := channelSpecs[ch.Kind]
	if !ok {
		return ch, spec, errDatePlanNotFound
	}
	ch.RefID = ref.String
	if ch.Kind == "friend" {
		if low.String == actor {
			ch.PeerID = high.String
		} else {
			ch.PeerID = low.String
		}
	}
	moderators := `FALSE`
	if spec.ModeratorsSQL != "" {
		moderators = `$1::uuid IN (` + spec.ModeratorsSQL + `)`
	}
	readOnly, readOnlyUntil := `FALSE`, `NULL::timestamptz`
	if spec.ReadOnlySQL != "" {
		readOnly = `EXISTS(SELECT 1 FROM (` + spec.ReadOnlySQL + `) ro(uid,until) WHERE ro.uid=$1::uuid)`
		readOnlyUntil = `(SELECT ro.until FROM (` + spec.ReadOnlySQL + `) ro(uid,until) WHERE ro.uid=$1::uuid ORDER BY ro.until DESC NULLS FIRST LIMIT 1)`
	}
	var member bool
	var roUntil, mutedUntil sql.NullTime
	err = q.QueryRowContext(ctx, `SELECT $1::uuid IN (`+spec.membersSQL()+`),`+moderators+`,
 (SELECT COUNT(*) FROM (`+spec.membersSQL()+`) mm),COALESCE(`+spec.TitleSQL+`,''),
 `+readOnly+`,`+readOnlyUntil+`,
 COALESCE((SELECT sp.muted_until>NOW() FROM matching.social_channel_prefs sp WHERE sp.channel_id=c.id AND sp.user_id=$1::uuid),FALSE),
 (SELECT sp.muted_until FROM matching.social_channel_prefs sp WHERE sp.channel_id=c.id AND sp.user_id=$1::uuid AND sp.muted_until>NOW() AND isfinite(sp.muted_until))
 FROM matching.social_channels c WHERE c.id=$2::uuid`, actor, channelID).
		Scan(&member, &ch.CanModerate, &ch.MemberCount, &ch.Title, &ch.ReadOnly, &roUntil, &ch.Muted, &mutedUntil)
	if err != nil {
		return ch, spec, err
	}
	if !member {
		return ch, spec, errDatePlanNotFound
	}
	if ch.ReadOnly {
		ch.ReadOnlyMessage = spec.ReadOnlyMessage
		if roUntil.Valid {
			t := roUntil.Time.UTC()
			ch.ReadOnlyUntil = &t
		}
	}
	if mutedUntil.Valid {
		t := mutedUntil.Time.UTC()
		ch.MutedUntil = &t
	}
	return ch, spec, nil
}

// socialReadOnlyError: the member may read this conversation but not post.
type socialReadOnlyError struct {
	msg   string
	until *time.Time
}

func (e socialReadOnlyError) Error() string { return e.msg }

func readOnlyError(ch socialChannel) socialReadOnlyError {
	msg := ch.ReadOnlyMessage
	if msg == "" {
		msg = "You can read this conversation but can't post in it"
	}
	if ch.ReadOnlyUntil != nil {
		at := ch.ReadOnlyUntil.UTC()
		stamp := at.Format("15:04")
		if now := time.Now().UTC(); at.YearDay() != now.YearDay() || at.Year() != now.Year() {
			stamp = at.Format("2 Jan, 15:04")
		}
		msg += " until " + stamp + " UTC"
	}
	return socialReadOnlyError{msg: msg + ".", until: ch.ReadOnlyUntil}
}

// writeSocialError adds the read-only case to writeActivityError.
func writeSocialError(w http.ResponseWriter, err error) {
	var ro socialReadOnlyError
	if errors.As(err, &ro) {
		writeJSON(w, http.StatusForbidden, map[string]any{
			"success": false, "error": ro.msg, "error_code": "CHANNEL_READ_ONLY", "read_only_until": ro.until,
		})
		return
	}
	writeActivityError(w, err, socialUnavailable)
}

// ensureRefChannel returns the channel for a room or group, creating it on
// first use. Callers check membership themselves before exposing it.
func ensureRefChannel(ctx context.Context, q blogQuerier, kind, refID string) (string, error) {
	if _, ok := channelSpecs[kind]; !ok || kind == "friend" {
		return "", errors.New("unknown channel kind " + kind)
	}
	var id string
	err := q.QueryRowContext(ctx, `WITH ins AS (
 INSERT INTO matching.social_channels(kind,ref_id) VALUES($1,$2::uuid) ON CONFLICT (kind,ref_id) WHERE ref_id IS NOT NULL DO NOTHING RETURNING id::text)
 SELECT id FROM ins UNION ALL SELECT id::text FROM matching.social_channels WHERE kind=$1 AND ref_id=$2::uuid LIMIT 1`, kind, refID).Scan(&id)
	return id, err
}

// ensureFriendChannel returns the conversation between two accepted,
// unblocked friends, creating it on first use.
func ensureFriendChannel(ctx context.Context, db *sql.DB, actor, friendID string) (socialChannel, error) {
	if actor == friendID {
		return socialChannel{}, activityFail(400, "Choose a friend to talk to.")
	}
	low, high := actor, friendID
	if high < low {
		low, high = high, low
	}
	var id string
	err := db.QueryRowContext(ctx, `WITH ins AS (
 INSERT INTO matching.social_channels(kind,user_low,user_high) VALUES('friend',$1::uuid,$2::uuid) ON CONFLICT (user_low,user_high) WHERE kind='friend' DO NOTHING RETURNING id::text)
 SELECT id FROM ins UNION ALL SELECT id::text FROM matching.social_channels WHERE kind='friend' AND user_low=$1::uuid AND user_high=$2::uuid LIMIT 1`, low, high).Scan(&id)
	if err != nil {
		return socialChannel{}, err
	}
	ch, _, err := loadChannel(ctx, db, actor, id)
	if errors.Is(err, errDatePlanNotFound) {
		return ch, activityFail(403, "You can message accepted friends you haven't blocked.")
	}
	return ch, err
}

// listSocialMessages returns up to limit messages before the message id
// (newest page when empty), oldest first, hiding senders either side blocked.
func listSocialMessages(ctx context.Context, q blogQuerier, actor, channelID, before string, limit int) ([]socialMessage, bool, error) {
	if limit <= 0 || limit > 100 {
		limit = socialPageSize
	}
	args := []any{actor, channelID, limit + 1}
	cursor := ``
	if before != "" {
		cursor = ` AND (m.created_at,m.id) < (SELECT created_at,id FROM matching.social_messages WHERE id=$4::uuid AND channel_id=$2::uuid)`
		args = append(args, before)
	}
	rows, err := q.QueryContext(ctx, `SELECT m.id::text,m.channel_id::text,m.sender_id::text,`+socialMemberCardSQL("m.sender_id")+`,
 CASE WHEN m.deleted_at IS NULL AND m.moderation_state='active' THEN m.body ELSE '' END,m.client_message_id::text,m.created_at,
 (m.deleted_at IS NOT NULL OR m.moderation_state<>'active'),m.sender_id=$1::uuid
 FROM matching.social_messages m
 WHERE m.channel_id=$2::uuid AND `+socialNotBlockedSQL("m.sender_id", "$1::uuid")+cursor+`
 ORDER BY m.created_at DESC,m.id DESC LIMIT $3`, args...)
	if err != nil {
		return nil, false, err
	}
	defer rows.Close()
	out := []socialMessage{}
	for rows.Next() {
		var m socialMessage
		if err = rows.Scan(&m.ID, &m.ChannelID, &m.SenderID, &m.SenderName, &m.SenderPhotoURL, &m.Body, &m.ClientMessageID, &m.CreatedAt, &m.Deleted, &m.Mine); err != nil {
			return nil, false, err
		}
		out = append(out, m)
	}
	if err = rows.Err(); err != nil {
		return nil, false, err
	}
	more := len(out) > limit
	if more {
		out = out[:limit]
	}
	for i, j := 0, len(out)-1; i < j; i, j = i+1, j-1 {
		out[i], out[j] = out[j], out[i]
	}
	return out, more, nil
}

func readSocialMessage(ctx context.Context, q blogQuerier, actor, channelID, messageID string) (socialMessage, error) {
	var m socialMessage
	err := q.QueryRowContext(ctx, `SELECT m.id::text,m.channel_id::text,m.sender_id::text,`+socialMemberCardSQL("m.sender_id")+`,
 CASE WHEN m.deleted_at IS NULL AND m.moderation_state='active' THEN m.body ELSE '' END,m.client_message_id::text,m.created_at,
 (m.deleted_at IS NOT NULL OR m.moderation_state<>'active'),m.sender_id=$1::uuid
 FROM matching.social_messages m WHERE m.id=$3::uuid AND m.channel_id=$2::uuid`, actor, channelID, messageID).
		Scan(&m.ID, &m.ChannelID, &m.SenderID, &m.SenderName, &m.SenderPhotoURL, &m.Body, &m.ClientMessageID, &m.CreatedAt, &m.Deleted, &m.Mine)
	if errors.Is(err, sql.ErrNoRows) {
		return m, errDatePlanNotFound
	}
	return m, err
}

// sendSocialMessage posts body to a channel the actor belongs to. A repeated
// client message id returns the original message without posting again.
func sendSocialMessage(ctx context.Context, db *sql.DB, actor, channelID, clientID, body string) (socialMessage, error) {
	body = strings.TrimSpace(body)
	if body == "" {
		return socialMessage{}, blogInputError("Write a message first.")
	}
	if runeLen(body) > socialMessageMaxRunes {
		return socialMessage{}, blogInputError("Messages can be up to 2000 characters.")
	}
	if _, err := uuid.Parse(clientID); err != nil {
		return socialMessage{}, blogInputError("client_message_id must be a UUID")
	}
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return socialMessage{}, err
	}
	defer tx.Rollback()
	if err = lockBlogAuthor(ctx, tx, actor); err != nil {
		return socialMessage{}, err
	}
	var existing string
	err = tx.QueryRowContext(ctx, `SELECT id::text FROM matching.social_messages WHERE sender_id=$1 AND client_message_id=$2::uuid`, actor, clientID).Scan(&existing)
	if err == nil {
		m, readErr := readSocialMessage(ctx, tx, actor, channelID, existing)
		if readErr != nil {
			return m, readErr
		}
		return m, tx.Commit()
	}
	if !errors.Is(err, sql.ErrNoRows) {
		return socialMessage{}, err
	}
	ch, spec, err := loadChannel(ctx, tx, actor, channelID)
	if err != nil {
		return socialMessage{}, err
	}
	if ch.ReadOnly {
		return socialMessage{}, readOnlyError(ch)
	}
	var recent int
	if err = tx.QueryRowContext(ctx, `SELECT COUNT(*) FROM matching.social_messages WHERE sender_id=$1 AND created_at>NOW()-interval '1 minute'`, actor).Scan(&recent); err != nil {
		return socialMessage{}, err
	}
	if recent >= socialMessagesPerMin {
		return socialMessage{}, activityFail(429, "You're sending messages quickly. Take a breath and try again in a minute.")
	}
	var id string
	if err = tx.QueryRowContext(ctx, `INSERT INTO matching.social_messages(channel_id,sender_id,body,client_message_id) VALUES($1,$2,$3,$4::uuid) RETURNING id::text`, channelID, actor, body, clientID).Scan(&id); err != nil {
		return socialMessage{}, err
	}
	if _, err = tx.ExecContext(ctx, `UPDATE matching.social_channels SET last_message_at=NOW() WHERE id=$1`, channelID); err != nil {
		return socialMessage{}, err
	}
	if _, err = tx.ExecContext(ctx, `INSERT INTO matching.social_channel_reads(channel_id,user_id,last_read_at) VALUES($1,$2,NOW())
 ON CONFLICT (channel_id,user_id) DO UPDATE SET last_read_at=NOW()`, channelID, actor); err != nil {
		return socialMessage{}, err
	}
	m, err := readSocialMessage(ctx, tx, actor, channelID, id)
	if err != nil {
		return m, err
	}
	if err = fanOutSocialEvent(ctx, tx, spec, channelID, actor, "social.message.created", map[string]any{
		"channel_id": channelID, "channel_kind": ch.Kind, "message_id": id, "sender_id": actor,
	}); err != nil {
		return m, err
	}
	if spec.Notify {
		if err = notifySocialRecipients(ctx, tx, spec, ch, actor, m); err != nil {
			return m, err
		}
	}
	return m, tx.Commit()
}

// fanOutSocialEvent queues a real-time event for every member except the
// actor and anyone either side has blocked.
func fanOutSocialEvent(ctx context.Context, tx *sql.Tx, spec channelSpec, channelID, actor, eventType string, payload map[string]any) error {
	encoded, err := json.Marshal(payload)
	if err != nil {
		return err
	}
	_, err = tx.ExecContext(ctx, `INSERT INTO matching.realtime_outbox(recipient_user_id,channel_id,event_type,payload)
 SELECT r.uid,c.id,$3,$4::jsonb FROM matching.social_channels c, LATERAL (`+spec.membersSQL()+`) r(uid)
 WHERE c.id=$1::uuid AND r.uid<>$2::uuid AND `+socialNotBlockedSQL("r.uid", "$2::uuid"), channelID, actor, eventType, string(encoded))
	return err
}

// notifySocialRecipients notifies members (not the sender, not across a
// block, not anyone who muted this conversation) at most once per channel
// every ten minutes.
func notifySocialRecipients(ctx context.Context, tx *sql.Tx, spec channelSpec, ch socialChannel, actor string, m socialMessage) error {
	rows, err := tx.QueryContext(ctx, `SELECT r.uid::text FROM matching.social_channels c, LATERAL (`+spec.membersSQL()+`) r(uid)
 WHERE c.id=$1::uuid AND r.uid<>$2::uuid AND `+socialNotBlockedSQL("r.uid", "$2::uuid")+`
   AND NOT EXISTS(SELECT 1 FROM matching.social_channel_prefs sp WHERE sp.channel_id=c.id AND sp.user_id=r.uid AND sp.muted_until>NOW())`, ch.ID, actor)
	if err != nil {
		return err
	}
	recipients := []string{}
	for rows.Next() {
		var id string
		if err = rows.Scan(&id); err != nil {
			rows.Close()
			return err
		}
		recipients = append(recipients, id)
	}
	if err = rows.Err(); err != nil {
		rows.Close()
		return err
	}
	rows.Close()
	bucket := time.Now().UTC().Unix() / (socialNotifyBucketMins * 60)
	preview := m.Body
	if runeLen(preview) > 80 {
		preview = string([]rune(preview)[:77]) + "…"
	}
	title := "New message from " + m.SenderName
	if m.SenderName == "" {
		title = "New message from a friend"
	}
	for _, r := range recipients {
		if err = enqueueNotificationTx(ctx, tx, r, actor, "social.message.new", "message", ch.ID,
			"social:"+ch.ID+":"+r+":"+strconv.FormatInt(bucket, 10), title, preview, spec.Route,
			map[string]any{"channel_id": ch.ID, "channel_kind": ch.Kind, "message_id": m.ID}, 2); err != nil {
			return err
		}
	}
	return nil
}

// deleteSocialMessage: senders delete their own; moderators remove others'.
func deleteSocialMessage(ctx context.Context, db *sql.DB, actor, channelID, messageID string) error {
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()
	ch, spec, err := loadChannel(ctx, tx, actor, channelID)
	if err != nil {
		return err
	}
	var sender string
	var gone bool
	err = tx.QueryRowContext(ctx, `SELECT sender_id::text,(deleted_at IS NOT NULL OR moderation_state<>'active') FROM matching.social_messages WHERE id=$1::uuid AND channel_id=$2::uuid FOR UPDATE`, messageID, channelID).Scan(&sender, &gone)
	if errors.Is(err, sql.ErrNoRows) {
		return errDatePlanNotFound
	}
	if err != nil {
		return err
	}
	if gone {
		return tx.Commit()
	}
	switch {
	case sender == actor:
		_, err = tx.ExecContext(ctx, `UPDATE matching.social_messages SET deleted_at=NOW(),deleted_by=$2 WHERE id=$1::uuid`, messageID, actor)
	case ch.CanModerate:
		_, err = tx.ExecContext(ctx, `UPDATE matching.social_messages SET moderation_state='removed',deleted_at=NOW(),deleted_by=$2 WHERE id=$1::uuid`, messageID, actor)
	default:
		return activityFail(403, "Only the sender or a host can remove this message.")
	}
	if err != nil {
		return err
	}
	if err = fanOutSocialEvent(ctx, tx, spec, channelID, actor, "social.message.deleted", map[string]any{
		"channel_id": channelID, "channel_kind": ch.Kind, "message_id": messageID,
	}); err != nil {
		return err
	}
	return tx.Commit()
}

func markSocialRead(ctx context.Context, db *sql.DB, actor, channelID string) error {
	if _, _, err := loadChannel(ctx, db, actor, channelID); err != nil {
		return err
	}
	_, err := db.ExecContext(ctx, `INSERT INTO matching.social_channel_reads(channel_id,user_id,last_read_at) VALUES($1,$2,NOW())
 ON CONFLICT (channel_id,user_id) DO UPDATE SET last_read_at=NOW()`, channelID, actor)
	return err
}

// listSocialChannels lists the actor's conversations that have messages,
// newest first, with unread counts.
func listSocialChannels(ctx context.Context, db *sql.DB, actor string) ([]socialChannel, error) {
	out := []socialChannel{}
	for _, spec := range channelSpecs {
		rows, err := db.QueryContext(ctx, `SELECT c.id::text FROM matching.social_channels c
 WHERE c.kind=$2 AND c.last_message_at IS NOT NULL AND $1::uuid IN (`+spec.membersSQL()+`)
 ORDER BY c.last_message_at DESC LIMIT 100`, actor, spec.Kind)
		if err != nil {
			return nil, err
		}
		ids := []string{}
		for rows.Next() {
			var id string
			if err = rows.Scan(&id); err != nil {
				rows.Close()
				return nil, err
			}
			ids = append(ids, id)
		}
		err = rows.Err()
		rows.Close()
		if err != nil {
			return nil, err
		}
		for _, id := range ids {
			ch, _, err := loadChannel(ctx, db, actor, id)
			if errors.Is(err, errDatePlanNotFound) {
				continue
			}
			if err != nil {
				return nil, err
			}
			if err = fillSocialSummary(ctx, db, actor, &ch); err != nil {
				return nil, err
			}
			out = append(out, ch)
		}
	}
	// Newest conversation first across kinds.
	for i := 1; i < len(out); i++ {
		for j := i; j > 0 && after(out[j].LastMessageAt, out[j-1].LastMessageAt); j-- {
			out[j], out[j-1] = out[j-1], out[j]
		}
	}
	return out, nil
}

func after(a, b *time.Time) bool {
	if a == nil {
		return false
	}
	return b == nil || a.After(*b)
}

func fillSocialSummary(ctx context.Context, q blogQuerier, actor string, ch *socialChannel) error {
	return q.QueryRowContext(ctx, `SELECT
 COALESCE((SELECT CASE WHEN m.deleted_at IS NULL AND m.moderation_state='active' THEN m.body ELSE 'Message removed' END
  FROM matching.social_messages m WHERE m.channel_id=$2::uuid AND `+socialNotBlockedSQL("m.sender_id", "$1::uuid")+`
  ORDER BY m.created_at DESC,m.id DESC LIMIT 1),''),
 (SELECT COUNT(*) FROM matching.social_messages m WHERE m.channel_id=$2::uuid AND m.sender_id<>$1::uuid
  AND m.deleted_at IS NULL AND m.moderation_state='active' AND `+socialNotBlockedSQL("m.sender_id", "$1::uuid")+`
  AND m.created_at>COALESCE((SELECT r.last_read_at FROM matching.social_channel_reads r WHERE r.channel_id=$2::uuid AND r.user_id=$1::uuid),'-infinity'))`,
		actor, ch.ID).Scan(&ch.LastMessage, &ch.UnreadCount)
}

// socialRealtimeCursor is the newest outbox sequence for the member, so a
// chat screen can open the websocket without replaying older events.
func socialRealtimeCursor(ctx context.Context, q blogQuerier, actor string) (int64, error) {
	var cursor int64
	err := q.QueryRowContext(ctx, `SELECT COALESCE(MAX(sequence_id),0) FROM matching.realtime_outbox WHERE recipient_user_id=$1`, actor).Scan(&cursor)
	return cursor, err
}

// ---------------------------------------------------------------------------
// HTTP
// ---------------------------------------------------------------------------

const socialUnavailable = "Chat is temporarily unavailable. Please retry."

func (s *Server) socialContext(w http.ResponseWriter, r *http.Request) (string, *sql.DB, bool) {
	actor, err := requestPrincipal(r)
	if err != nil {
		writeError(w, 401, err)
		return "", nil, false
	}
	db, err := s.growthDB()
	if err != nil {
		writeError(w, 503, err)
		return "", nil, false
	}
	w.Header().Set("Cache-Control", "private, no-store")
	return actor.UserID, db, true
}

// GET /v1/social/channels
func (s *Server) socialChannelsHandler(w http.ResponseWriter, r *http.Request) {
	actor, db, ok := s.socialContext(w, r)
	if !ok {
		return
	}
	channels, err := listSocialChannels(r.Context(), db, actor)
	if err != nil {
		writeSocialError(w, err)
		return
	}
	writeJSON(w, 200, map[string]any{"channels": channels})
}

// GET /v1/social/channels/{channelID}
func (s *Server) socialChannelHandler(w http.ResponseWriter, r *http.Request) {
	actor, db, ok := s.socialContext(w, r)
	if !ok {
		return
	}
	channelID := chi.URLParam(r, "channelID")
	if !activityUUID(w, channelID) {
		return
	}
	ch, _, err := loadChannel(r.Context(), db, actor, channelID)
	if err == nil {
		err = fillSocialSummary(r.Context(), db, actor, &ch)
	}
	if err != nil {
		writeSocialError(w, err)
		return
	}
	writeJSON(w, 200, map[string]any{"channel": ch})
}

// POST /v1/social/friends/{friendID}/channel
func (s *Server) socialFriendChannelHandler(w http.ResponseWriter, r *http.Request) {
	actor, db, ok := s.socialContext(w, r)
	if !ok {
		return
	}
	friendID := chi.URLParam(r, "friendID")
	if !activityUUID(w, friendID) {
		return
	}
	ch, err := ensureFriendChannel(r.Context(), db, actor, friendID)
	if err != nil {
		writeSocialError(w, err)
		return
	}
	writeJSON(w, 200, map[string]any{"channel": ch})
}

// GET and POST /v1/social/channels/{channelID}/messages
func (s *Server) socialMessagesHandler(w http.ResponseWriter, r *http.Request) {
	actor, db, ok := s.socialContext(w, r)
	if !ok {
		return
	}
	channelID := chi.URLParam(r, "channelID")
	if !activityUUID(w, channelID) {
		return
	}
	if r.Method == http.MethodPost {
		body, ok := readJSON(w, r)
		if !ok {
			return
		}
		m, err := sendSocialMessage(r.Context(), db, actor, channelID, toString(body["client_message_id"]), toString(body["body"]))
		if err != nil {
			writeSocialError(w, err)
			return
		}
		writeJSON(w, 201, map[string]any{"message": m})
		return
	}
	before := strings.TrimSpace(r.URL.Query().Get("before"))
	if before != "" && !activityUUID(w, before) {
		return
	}
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if _, _, err := loadChannel(r.Context(), db, actor, channelID); err != nil {
		writeSocialError(w, err)
		return
	}
	// The cursor is read before the page so no event between them is missed.
	cursor, err := socialRealtimeCursor(r.Context(), db, actor)
	if err != nil {
		writeSocialError(w, err)
		return
	}
	messages, more, err := listSocialMessages(r.Context(), db, actor, channelID, before, limit)
	if err != nil {
		writeSocialError(w, err)
		return
	}
	writeJSON(w, 200, map[string]any{"messages": messages, "has_more": more, "realtime_cursor": cursor})
}

// DELETE /v1/social/channels/{channelID}/messages/{messageID}
func (s *Server) socialMessageDeleteHandler(w http.ResponseWriter, r *http.Request) {
	actor, db, ok := s.socialContext(w, r)
	if !ok {
		return
	}
	channelID, messageID := chi.URLParam(r, "channelID"), chi.URLParam(r, "messageID")
	if !activityUUID(w, channelID, messageID) {
		return
	}
	if err := deleteSocialMessage(r.Context(), db, actor, channelID, messageID); err != nil {
		writeSocialError(w, err)
		return
	}
	writeJSON(w, 200, map[string]any{"deleted": true})
}

// POST /v1/social/channels/{channelID}/read
func (s *Server) socialReadHandler(w http.ResponseWriter, r *http.Request) {
	actor, db, ok := s.socialContext(w, r)
	if !ok {
		return
	}
	channelID := chi.URLParam(r, "channelID")
	if !activityUUID(w, channelID) {
		return
	}
	if err := markSocialRead(r.Context(), db, actor, channelID); err != nil {
		writeSocialError(w, err)
		return
	}
	writeJSON(w, 200, map[string]any{"read": true})
}

// readSocialMessageForReport captures a chat message the reporter can see,
// for the moderation case queue (content type social_message).
func readSocialMessageForReport(ctx context.Context, q blogQuerier, actor, messageID string) (string, any, error) {
	var channelID string
	if err := q.QueryRowContext(ctx, `SELECT channel_id::text FROM matching.social_messages WHERE id=$1::uuid`, messageID).Scan(&channelID); err != nil {
		return "", nil, errDatePlanNotFound
	}
	ch, _, err := loadChannel(ctx, q, actor, channelID)
	if err != nil {
		return "", nil, err
	}
	m, err := readSocialMessage(ctx, q, actor, channelID, messageID)
	if err != nil {
		return "", nil, err
	}
	if m.Deleted {
		return "", nil, errDatePlanNotFound
	}
	return m.SenderID, map[string]any{"title": "Chat message · " + ch.Title, "text": m.Body, "channel_kind": ch.Kind}, nil
}

// ---------------------------------------------------------------------------
// Notification mutes (migration 119)
// ---------------------------------------------------------------------------

// socialMuteDurations are the choices the app offers; "forever" lasts until
// the member turns notifications back on.
var socialMuteDurations = map[string]time.Duration{
	"1h": time.Hour, "8h": 8 * time.Hour, "1w": 7 * 24 * time.Hour, "forever": 0,
}

const socialMuteMaxMinutes = 30 * 24 * 60

// parseSocialMute reads {duration: 1h|8h|1w|forever} or {minutes: 1..43200}.
// forever is true for "until I turn it back on".
func parseSocialMute(body map[string]any) (time.Duration, bool, error) {
	if raw := strings.ToLower(strings.TrimSpace(toString(body["duration"]))); raw != "" {
		d, ok := socialMuteDurations[raw]
		if !ok {
			return 0, false, blogInputError("duration must be 1h, 8h, 1w or forever")
		}
		return d, d == 0, nil
	}
	if minutes, ok := toInt(body["minutes"]); ok {
		if minutes < 1 || minutes > socialMuteMaxMinutes {
			return 0, false, blogInputError("minutes must be between 1 and 43200")
		}
		return time.Duration(minutes) * time.Minute, false, nil
	}
	return 0, false, blogInputError("Choose how long to mute this conversation.")
}

// setSocialMute silences notifications from a conversation the actor belongs
// to for d, or until they turn them back on (forever). Setting it again
// replaces the previous choice.
func setSocialMute(ctx context.Context, db *sql.DB, actor, channelID string, d time.Duration, forever bool) (socialChannel, error) {
	if _, _, err := loadChannel(ctx, db, actor, channelID); err != nil {
		return socialChannel{}, err
	}
	until := any("infinity")
	if !forever {
		until = time.Now().UTC().Add(d)
	}
	if _, err := db.ExecContext(ctx, `INSERT INTO matching.social_channel_prefs(channel_id,user_id,muted_until,updated_at) VALUES($1::uuid,$2::uuid,$3::timestamptz,NOW())
 ON CONFLICT (channel_id,user_id) DO UPDATE SET muted_until=EXCLUDED.muted_until,updated_at=NOW()`, channelID, actor, until); err != nil {
		return socialChannel{}, err
	}
	return loadSocialChannelSummary(ctx, db, actor, channelID)
}

// clearSocialMute turns notifications back on (a no-op when not muted).
func clearSocialMute(ctx context.Context, db *sql.DB, actor, channelID string) (socialChannel, error) {
	if _, _, err := loadChannel(ctx, db, actor, channelID); err != nil {
		return socialChannel{}, err
	}
	if _, err := db.ExecContext(ctx, `UPDATE matching.social_channel_prefs SET muted_until=NULL,updated_at=NOW()
 WHERE channel_id=$1::uuid AND user_id=$2::uuid AND muted_until IS NOT NULL`, channelID, actor); err != nil {
		return socialChannel{}, err
	}
	return loadSocialChannelSummary(ctx, db, actor, channelID)
}

func loadSocialChannelSummary(ctx context.Context, q blogQuerier, actor, channelID string) (socialChannel, error) {
	ch, _, err := loadChannel(ctx, q, actor, channelID)
	if err == nil {
		err = fillSocialSummary(ctx, q, actor, &ch)
	}
	return ch, err
}

// signalSocialMember tells one member over the chat websocket that their own
// standing in a conversation changed (muted, unmuted), so an open chat
// refreshes. Nothing is sent when the conversation has no channel yet.
func signalSocialMember(ctx context.Context, tx *sql.Tx, channelID, kind, userID string, payload map[string]any) error {
	if channelID == "" {
		return nil
	}
	if payload == nil {
		payload = map[string]any{}
	}
	payload["channel_id"], payload["channel_kind"] = channelID, kind
	encoded, err := json.Marshal(payload)
	if err != nil {
		return err
	}
	_, err = tx.ExecContext(ctx, `INSERT INTO matching.realtime_outbox(recipient_user_id,channel_id,event_type,payload)
 VALUES($1::uuid,$2::uuid,'social.channel.updated',$3::jsonb)`, userID, channelID, string(encoded))
	return err
}

// PUT and DELETE /v1/social/channels/{channelID}/mute
func (s *Server) socialMuteHandler(w http.ResponseWriter, r *http.Request) {
	actor, db, ok := s.socialContext(w, r)
	if !ok {
		return
	}
	channelID := chi.URLParam(r, "channelID")
	if !activityUUID(w, channelID) {
		return
	}
	var ch socialChannel
	var err error
	if r.Method == http.MethodDelete {
		ch, err = clearSocialMute(r.Context(), db, actor, channelID)
	} else {
		body, ok := readRoomJSON(w, r)
		if !ok {
			return
		}
		d, forever, parseErr := parseSocialMute(body)
		if parseErr != nil {
			writeSocialError(w, parseErr)
			return
		}
		ch, err = setSocialMute(r.Context(), db, actor, channelID, d, forever)
	}
	if err != nil {
		writeSocialError(w, err)
		return
	}
	writeJSON(w, 200, map[string]any{"channel": ch, "muted": ch.Muted, "muted_until": ch.MutedUntil})
}
