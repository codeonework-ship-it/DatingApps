package mobile

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
)

// Conversation Rooms as live chat rooms (migration 117).
//
// A room is a place to drop in and talk, like the topic chat rooms of the
// early web: always-on public rooms seeded by the migration ("Late-night
// talks", "Bengaluru hangout" ...) and short rooms members host. Joining
// puts a member in the room's chat channel (shared chat engine, kind "room");
// if they click with someone they add them as a friend from the member list.
//
// Rules, all enforced here or in the channel spec below:
//   - Members: an active adult dating member with a participant row that is
//     joined, not left and seen within the last 24 hours. A member who
//     disappears for a day lapses quietly and rejoins with one tap; capacity
//     counts only current members.
//   - Here now: a member whose presence heartbeat is under two minutes old.
//   - Chat is open while the room is: always-on rooms until an operator
//     closes them, hosted rooms until their end time. Closing ends the chat.
//   - Blocks: a member can still join a public room that someone they blocked
//     (or who blocked them) is in. The chat engine hides each side's messages
//     and real-time events from the other, and the member list leaves them
//     out. A room hosted by someone either side blocked is hidden and cannot
//     be joined, so a host never moderates someone who blocked them.
//   - Moderation: only the room's hosts and moderators (and operators, through
//     the admin path) warn, mute, unmute or remove. Moderators cannot act on
//     moderators; nobody but an operator acts on a host; nobody acts on
//     themselves. A muted member reads but cannot post until the mute ends
//     (10 minutes, an hour, or the session: the room's end, 24 hours for
//     always-on rooms). A removed member cannot rejoin until the session
//     ends (24 hours for always-on rooms).
//   - Hosting: a member may host one open room at a time and start at most
//     three a day; rooms last 30 minutes to 3 hours, start within 7 days and
//     hold 2 to 50 people. A host may close their own room.

const (
	roomHereNowSeconds   = 120
	roomAlwaysOnRemoval  = 24 * time.Hour
	roomMemberCapacity   = 50
	roomMemberDefaultCap = 30
	roomHostOpenLimit    = 1
	roomHostDailyLimit   = 3
	roomTitleMaxRunes    = 60
	roomAboutMaxRunes    = 280
	roomReasonMaxRunes   = 280
	roomMembersPageLimit = 200
)

var roomCategories = map[string]string{
	"talk": "forum", "interests": "interests", "active": "hiking", "city": "city",
}

// roomMemberActiveSQL: participant alias p is in the room now.
const roomMemberActiveSQL = `p.status IN ('joined','active') AND p.left_at IS NULL
 AND COALESCE(p.last_seen_at,p.joined_at) > NOW()-interval '24 hours'`

// roomOpenSQL: room alias r accepts members and chat.
const roomOpenSQL = `r.lifecycle_state NOT IN ('closed','cancelled') AND (r.always_on OR r.ends_at > NOW())`

const roomHereSQL = `p.last_seen_at > NOW()-interval '2 minutes'`

const roomStateSQL = `CASE WHEN r.lifecycle_state IN ('closed','cancelled') THEN 'closed' WHEN r.always_on THEN 'active'
 WHEN r.ends_at IS NULL OR r.ends_at <= NOW() THEN 'closed' WHEN r.starts_at > NOW() THEN 'scheduled' ELSE 'active' END`

// roomHostVisibleSQL: room alias r is not hosted by someone either side of
// viewer blocked.
func roomHostVisibleSQL(viewer string) string {
	return `(r.created_by_user_id IS NULL OR r.created_by_user_id=` + viewer + ` OR ` + socialNotBlockedSQL("r.created_by_user_id", viewer) + `)`
}

func init() {
	members := `SELECT p.user_id FROM matching.conversation_room_participants p
 JOIN matching.conversation_rooms r ON r.id=p.room_id
 WHERE p.room_id=c.ref_id AND ` + roomMemberActiveSQL + ` AND ` + roomOpenSQL
	registerChannelSpec(channelSpec{
		Kind:          "room",
		MembersSQL:    members,
		ModeratorsSQL: members + ` AND p.role IN ('host','moderator')`,
		TitleSQL:      `(SELECT r.title FROM matching.conversation_rooms r WHERE r.id=c.ref_id)`,
		Notify:        false,
		Route:         "/rooms",
		// A muted member keeps reading but cannot post until the mute ends
		// (migration 119).
		ReadOnlySQL: `SELECT p.user_id,p.muted_until FROM matching.conversation_room_participants p
 WHERE p.room_id=c.ref_id AND p.muted_until>NOW()`,
		ReadOnlyMessage: "You're muted in this room",
	})
}

// liveRoom is a room as one member sees it.
type liveRoom struct {
	ID             string     `json:"id"`
	Slug           string     `json:"slug"`
	Title          string     `json:"title"`
	Theme          string     `json:"theme"`
	Description    string     `json:"description"`
	Category       string     `json:"category"`
	IconKey        string     `json:"icon_key"`
	Emoji          string     `json:"emoji"`
	RoomType       string     `json:"room_type"`
	City           string     `json:"city"`
	AlwaysOn       bool       `json:"always_on"`
	LifecycleState string     `json:"lifecycle_state"`
	StartsAt       *time.Time `json:"starts_at"`
	EndsAt         *time.Time `json:"ends_at"`
	Capacity       int        `json:"capacity"`
	MemberCount    int        `json:"participant_count"`
	HereNow        int        `json:"here_now"`
	FriendsHere    int        `json:"friends_here"`
	IsParticipant  bool       `json:"is_participant"`
	MyRole         string     `json:"my_role"`
	CanModerate    bool       `json:"can_moderate"`
	IsHost         bool       `json:"is_host"`
	HostName       string     `json:"host_name"`
	ChannelID      string     `json:"channel_id,omitempty"`
	sortOrder      int
}

type roomMember struct {
	UserID       string    `json:"user_id"`
	Name         string    `json:"name"`
	PhotoURL     string    `json:"photo_url"`
	Role         string    `json:"role"`
	HereNow      bool      `json:"here_now"`
	JoinedAt     time.Time `json:"joined_at"`
	IsMe         bool      `json:"is_me"`
	FriendStatus string    `json:"friend_status"`
	// MutedUntil is shown to the room's hosts and moderators, and to the
	// muted member themselves.
	MutedUntil *time.Time `json:"muted_until,omitempty"`
}

// roomSelectSQL reads rooms for viewer $1.
func roomSelectSQL() string {
	count := func(extra string) string {
		return `(SELECT COUNT(*) FROM matching.conversation_room_participants p JOIN user_management.users u ON u.id=p.user_id
 WHERE p.room_id=r.id AND ` + roomMemberActiveSQL + ` AND ` + blogActive + extra + `)`
	}
	return `SELECT r.id::text,COALESCE(r.slug,''),r.title,COALESCE(NULLIF(r.description,''),r.topic,''),
 COALESCE(r.category,'talk'),COALESCE(r.icon_key,'forum'),COALESCE(r.emoji,''),r.room_type,COALESCE(r.city,''),
 r.always_on,` + roomStateSQL + `,r.starts_at,r.ends_at,r.capacity,r.sort_order,
 ` + count(``) + `,
 ` + count(` AND `+roomHereSQL) + `,
 ` + count(` AND p.user_id<>$1::uuid AND matching.accepted_friends($1::uuid,p.user_id)`) + `,
 COALESCE((SELECT p.role FROM matching.conversation_room_participants p WHERE p.room_id=r.id AND p.user_id=$1::uuid AND ` + roomMemberActiveSQL + `),''),
 COALESCE((SELECT COALESCE(NULLIF(u.name,''),u.username,'') FROM user_management.users u WHERE u.id=r.created_by_user_id),''),
 COALESCE(r.created_by_user_id=$1::uuid,FALSE),
 COALESCE((SELECT ch.id::text FROM matching.social_channels ch WHERE ch.kind='room' AND ch.ref_id=r.id),'')
 FROM matching.conversation_rooms r`
}

type rowScanner interface{ Scan(dest ...any) error }

func scanLiveRoom(row rowScanner) (liveRoom, error) {
	var lr liveRoom
	var starts, ends sql.NullTime
	var channel string
	var host bool
	err := row.Scan(&lr.ID, &lr.Slug, &lr.Title, &lr.Description, &lr.Category, &lr.IconKey, &lr.Emoji, &lr.RoomType, &lr.City,
		&lr.AlwaysOn, &lr.LifecycleState, &starts, &ends, &lr.Capacity, &lr.sortOrder,
		&lr.MemberCount, &lr.HereNow, &lr.FriendsHere, &lr.MyRole, &lr.HostName, &host, &channel)
	if err != nil {
		return lr, err
	}
	lr.Theme = lr.Title
	if starts.Valid {
		t := starts.Time.UTC()
		lr.StartsAt = &t
	}
	if ends.Valid && !lr.AlwaysOn {
		t := ends.Time.UTC()
		lr.EndsAt = &t
	}
	lr.IsHost = host
	lr.IsParticipant = lr.MyRole != ""
	lr.CanModerate = lr.MyRole == "host" || lr.MyRole == "moderator"
	if lr.IsParticipant && lr.LifecycleState != roomLifecycleClosed {
		lr.ChannelID = channel
	}
	return lr, nil
}

var roomStateRank = map[string]int{roomLifecycleActive: 0, roomLifecycleScheduled: 1, roomLifecycleClosed: 2}

// listLiveRooms lists rooms for actor. state "" means every room that has
// not closed; closed rooms are listed for a week with state=closed.
func listLiveRooms(ctx context.Context, q blogQuerier, actor, state, category string, friendOnly bool, limit int) ([]liveRoom, error) {
	if limit <= 0 || limit > 200 {
		limit = 100
	}
	state = strings.ToLower(strings.TrimSpace(state))
	category = strings.ToLower(strings.TrimSpace(category))
	rows, err := q.QueryContext(ctx, roomSelectSQL()+`
 WHERE r.lifecycle_state<>'cancelled' AND `+roomHostVisibleSQL("$1::uuid")+`
   AND (($2='' AND `+roomStateSQL+`<>'closed') OR `+roomStateSQL+`=$2)
   AND (`+roomStateSQL+`<>'closed' OR COALESCE(r.ends_at,r.updated_at)>NOW()-interval '7 days')
   AND ($3='' OR r.category=$3)
 ORDER BY r.always_on DESC,r.sort_order,r.starts_at
 LIMIT 500`, actor, state, category)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []liveRoom{}
	for rows.Next() {
		lr, err := scanLiveRoom(rows)
		if err != nil {
			return nil, err
		}
		if friendOnly && lr.FriendsHere == 0 && !lr.IsParticipant {
			continue
		}
		out = append(out, lr)
	}
	if err = rows.Err(); err != nil {
		return nil, err
	}
	// Live rooms first, busiest first; then the room's own order.
	sort.SliceStable(out, func(i, j int) bool {
		a, b := out[i], out[j]
		if roomStateRank[a.LifecycleState] != roomStateRank[b.LifecycleState] {
			return roomStateRank[a.LifecycleState] < roomStateRank[b.LifecycleState]
		}
		if a.HereNow != b.HereNow {
			return a.HereNow > b.HereNow
		}
		if a.AlwaysOn != b.AlwaysOn {
			return a.AlwaysOn
		}
		return a.sortOrder < b.sortOrder
	})
	if len(out) > limit {
		out = out[:limit]
	}
	return out, nil
}

// getLiveRoom reads one room actor may see, or errDatePlanNotFound.
func getLiveRoom(ctx context.Context, q blogQuerier, actor, roomID string) (liveRoom, error) {
	lr, err := scanLiveRoom(q.QueryRowContext(ctx, roomSelectSQL()+`
 WHERE r.id=$2::uuid AND r.lifecycle_state<>'cancelled' AND `+roomHostVisibleSQL("$1::uuid"), actor, roomID))
	if errors.Is(err, sql.ErrNoRows) {
		return lr, errDatePlanNotFound
	}
	return lr, err
}

type lockedRoom struct {
	alwaysOn bool
	state    string
	capacity int
	endsAt   sql.NullTime
	title    string
	hostID   string
}

// lockLiveRoom locks a room actor may see for a membership change.
func lockLiveRoom(ctx context.Context, tx *sql.Tx, actor, roomID string) (lockedRoom, error) {
	var lr lockedRoom
	var host sql.NullString
	err := tx.QueryRowContext(ctx, `SELECT r.always_on,`+roomStateSQL+`,r.capacity,r.ends_at,r.title,r.created_by_user_id::text
 FROM matching.conversation_rooms r WHERE r.id=$1::uuid AND r.lifecycle_state<>'cancelled' FOR UPDATE`, roomID).
		Scan(&lr.alwaysOn, &lr.state, &lr.capacity, &lr.endsAt, &lr.title, &host)
	if errors.Is(err, sql.ErrNoRows) {
		return lr, errDatePlanNotFound
	}
	if err != nil {
		return lr, err
	}
	lr.hostID = host.String
	if actor != "" && lr.hostID != "" && lr.hostID != actor {
		var visible bool
		if err = tx.QueryRowContext(ctx, `SELECT `+socialNotBlockedSQL("$1::uuid", "$2::uuid"), lr.hostID, actor).Scan(&visible); err != nil {
			return lr, err
		}
		if !visible {
			return lr, errDatePlanNotFound
		}
	}
	return lr, nil
}

// joinLiveRoom adds actor to a room and returns it with its chat channel.
// Joining a room the member is already in refreshes their presence.
func joinLiveRoom(ctx context.Context, db *sql.DB, actor, roomID string) (liveRoom, error) {
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return liveRoom{}, err
	}
	defer tx.Rollback()
	if err = lockBlogAuthor(ctx, tx, actor); err != nil {
		return liveRoom{}, err
	}
	room, err := lockLiveRoom(ctx, tx, actor, roomID)
	if err != nil {
		return liveRoom{}, err
	}
	if room.state == roomLifecycleClosed {
		return liveRoom{}, errRoomClosed
	}
	var removed bool
	if err = tx.QueryRowContext(ctx, `SELECT EXISTS(SELECT 1 FROM matching.conversation_room_blocks
 WHERE room_id=$1::uuid AND blocked_user_id=$2::uuid AND (expires_at IS NULL OR expires_at>NOW()))`, roomID, actor).Scan(&removed); err != nil {
		return liveRoom{}, err
	}
	if removed {
		return liveRoom{}, errRoomBlockedActiveSession
	}
	var member bool
	if err = tx.QueryRowContext(ctx, `SELECT EXISTS(SELECT 1 FROM matching.conversation_room_participants p
 WHERE p.room_id=$1::uuid AND p.user_id=$2::uuid AND `+roomMemberActiveSQL+`)`, roomID, actor).Scan(&member); err != nil {
		return liveRoom{}, err
	}
	if member {
		_, err = tx.ExecContext(ctx, `UPDATE matching.conversation_room_participants SET last_seen_at=NOW() WHERE room_id=$1::uuid AND user_id=$2::uuid`, roomID, actor)
	} else {
		var count int
		if err = tx.QueryRowContext(ctx, `SELECT COUNT(*) FROM matching.conversation_room_participants p JOIN user_management.users u ON u.id=p.user_id
 WHERE p.room_id=$1::uuid AND `+roomMemberActiveSQL+` AND `+blogActive, roomID).Scan(&count); err != nil {
			return liveRoom{}, err
		}
		if count >= room.capacity {
			return liveRoom{}, errRoomCapacityReached
		}
		_, err = tx.ExecContext(ctx, `INSERT INTO matching.conversation_room_participants AS p(room_id,user_id,status,role,joined_at,last_seen_at,left_at)
 VALUES($1::uuid,$2::uuid,'joined','participant',NOW(),NOW(),NULL)
 ON CONFLICT (room_id,user_id) DO UPDATE SET status='joined',left_at=NULL,joined_at=NOW(),last_seen_at=NOW(),
  role=CASE WHEN p.status='removed' THEN 'participant' ELSE p.role END`, roomID, actor)
	}
	if err != nil {
		return liveRoom{}, err
	}
	if _, err = ensureRefChannel(ctx, tx, "room", roomID); err != nil {
		return liveRoom{}, err
	}
	if err = tx.Commit(); err != nil {
		return liveRoom{}, err
	}
	return getLiveRoom(ctx, db, actor, roomID)
}

// leaveLiveRoom takes actor out of the room and its chat at once. A host
// keeps their role and can come back.
func leaveLiveRoom(ctx context.Context, db *sql.DB, actor, roomID string) (liveRoom, error) {
	res, err := db.ExecContext(ctx, `UPDATE matching.conversation_room_participants p SET status='left',left_at=NOW()
 WHERE p.room_id=$1::uuid AND p.user_id=$2::uuid AND p.status IN ('joined','active') AND p.left_at IS NULL`, roomID, actor)
	if err != nil {
		return liveRoom{}, err
	}
	if n, _ := res.RowsAffected(); n == 0 {
		if _, err = getLiveRoom(ctx, db, actor, roomID); err != nil {
			return liveRoom{}, err
		}
		return liveRoom{}, errRoomNotParticipant
	}
	return getLiveRoom(ctx, db, actor, roomID)
}

// touchRoomPresence records a heartbeat (or "away") and returns the room.
// Heartbeats closer than 20 seconds apart are not written.
func touchRoomPresence(ctx context.Context, db *sql.DB, actor, roomID string, away bool) (liveRoom, error) {
	_, err := db.ExecContext(ctx, `UPDATE matching.conversation_room_participants p
 SET last_seen_at=CASE WHEN $3 THEN NOW()-interval '5 minutes' ELSE NOW() END
 WHERE p.room_id=$1::uuid AND p.user_id=$2::uuid AND `+roomMemberActiveSQL+`
   AND ($3 OR p.last_seen_at IS NULL OR p.last_seen_at<NOW()-interval '20 seconds')
   AND EXISTS(SELECT 1 FROM matching.conversation_rooms r WHERE r.id=p.room_id AND `+roomOpenSQL+`)`, roomID, actor, away)
	if err != nil {
		return liveRoom{}, err
	}
	lr, err := getLiveRoom(ctx, db, actor, roomID)
	if err != nil {
		return lr, err
	}
	if lr.LifecycleState == roomLifecycleClosed {
		return lr, errRoomClosed
	}
	if !lr.IsParticipant {
		var removed bool
		if err = db.QueryRowContext(ctx, `SELECT EXISTS(SELECT 1 FROM matching.conversation_room_blocks
 WHERE room_id=$1::uuid AND blocked_user_id=$2::uuid AND (expires_at IS NULL OR expires_at>NOW()))`, roomID, actor).Scan(&removed); err != nil {
			return lr, err
		}
		if removed {
			return lr, errRoomBlockedActiveSession
		}
		return lr, errRoomNotParticipant
	}
	return lr, nil
}

// listRoomMembers lists the people in a room for one of its members, hosts
// first, then who is here now. Members either side blocked are left out.
func listRoomMembers(ctx context.Context, q blogQuerier, actor, roomID string) ([]roomMember, error) {
	var role string
	err := q.QueryRowContext(ctx, `SELECT p.role FROM matching.conversation_room_participants p
 JOIN matching.conversation_rooms r ON r.id=p.room_id
 WHERE p.room_id=$1::uuid AND p.user_id=$2::uuid AND `+roomMemberActiveSQL+` AND `+roomOpenSQL, roomID, actor).Scan(&role)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, errDatePlanNotFound
	}
	if err != nil {
		return nil, err
	}
	moderator := role == "host" || role == "moderator"
	rows, err := q.QueryContext(ctx, `SELECT p.user_id::text,`+socialMemberCardSQL("p.user_id")+`,p.role,
 COALESCE(`+roomHereSQL+`,FALSE),p.joined_at,p.user_id=$1::uuid,
 CASE WHEN p.user_id=$1::uuid THEN 'me'
  WHEN matching.accepted_friends($1::uuid,p.user_id) THEN 'friends'
  WHEN EXISTS(SELECT 1 FROM matching.friend_connections f WHERE f.user_id=$1::uuid AND f.friend_user_id=p.user_id AND f.status='pending') THEN 'requested'
  WHEN EXISTS(SELECT 1 FROM matching.friend_connections f WHERE f.user_id=p.user_id AND f.friend_user_id=$1::uuid AND f.status='pending') THEN 'incoming'
  ELSE 'none' END,
 CASE WHEN (p.user_id=$1::uuid OR $4) AND p.muted_until>NOW() THEN p.muted_until END
 FROM matching.conversation_room_participants p JOIN user_management.users u ON u.id=p.user_id
 WHERE p.room_id=$2::uuid AND `+roomMemberActiveSQL+` AND `+blogActive+`
   AND (p.user_id=$1::uuid OR `+socialNotBlockedSQL("p.user_id", "$1::uuid")+`)
 ORDER BY CASE p.role WHEN 'host' THEN 0 WHEN 'moderator' THEN 1 ELSE 2 END,
  COALESCE(`+roomHereSQL+`,FALSE) DESC,p.last_seen_at DESC NULLS LAST,p.user_id
 LIMIT $3`, actor, roomID, roomMembersPageLimit, moderator)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []roomMember{}
	for rows.Next() {
		var m roomMember
		var muted sql.NullTime
		if err = rows.Scan(&m.UserID, &m.Name, &m.PhotoURL, &m.Role, &m.HereNow, &m.JoinedAt, &m.IsMe, &m.FriendStatus, &muted); err != nil {
			return nil, err
		}
		if muted.Valid {
			t := muted.Time.UTC()
			m.MutedUntil = &t
		}
		out = append(out, m)
	}
	return out, rows.Err()
}

// normalizeRoomAction maps request values to stored actions.
func normalizeRoomAction(action string) (string, bool) {
	switch strings.ToLower(strings.TrimSpace(action)) {
	case "warn", roomModerationActionWarn:
		return "warn", true
	case "remove", roomModerationActionRemove:
		return "remove", true
	case "close", "close_room":
		return "close", true
	case "mute", roomModerationActionMute:
		return "mute", true
	case "unmute", roomModerationActionUnmute:
		return "unmute", true
	}
	return "", false
}

// publicRoomAction is the action name returned to clients.
func publicRoomAction(stored string) string {
	switch stored {
	case "warn":
		return roomModerationActionWarn
	case "remove":
		return roomModerationActionRemove
	case "close":
		return "close_room"
	case "mute":
		return roomModerationActionMute
	case "unmute":
		return roomModerationActionUnmute
	}
	return stored
}

const (
	roomModerationActionMute   = "mute_user"
	roomModerationActionUnmute = "unmute_user"
	// roomMuteMaxMinutes caps a custom mute; "session" covers longer.
	roomMuteMaxMinutes = 24 * 60
)

// roomModerationRequest is one host, moderator or operator action.
type roomModerationRequest struct {
	Actor, RoomID, Target, Action, Reason string
	// Duration of a mute: "10m", "1h" or "session" (until the room ends; 24
	// hours for always-on rooms). Minutes (1-1440), when set, wins. A mute
	// with neither lasts 10 minutes.
	Duration string
	Minutes  int
	// Operator skips the room-role check (the admin path checks operator
	// roles) and may act on hosts.
	Operator bool
}

// roomMuteUntil works out when a mute ends, never after a hosted room does.
func roomMuteUntil(now time.Time, room lockedRoom, duration string, minutes int) (time.Time, string, error) {
	sessionEnd := now.Add(roomAlwaysOnRemoval)
	if !room.alwaysOn && room.endsAt.Valid {
		sessionEnd = room.endsAt.Time.UTC()
	}
	var until time.Time
	label := ""
	if minutes != 0 {
		if minutes < 1 || minutes > roomMuteMaxMinutes {
			return until, "", blogInputError("Mute for 1 minute to 24 hours.")
		}
		until, label = now.Add(time.Duration(minutes)*time.Minute), strconv.Itoa(minutes)+"m"
	} else {
		switch strings.ToLower(strings.TrimSpace(duration)) {
		case "", "10m":
			until, label = now.Add(10*time.Minute), "10m"
		case "1h", "60m":
			until, label = now.Add(time.Hour), "1h"
		case "session", "room", "24h":
			until, label = sessionEnd, "session"
		default:
			return until, "", blogInputError("duration must be 10m, 1h or session")
		}
	}
	if until.After(sessionEnd) {
		until = sessionEnd
	}
	return until, label, nil
}

// roomMuteSpan describes a mute for the muted member's notification.
func roomMuteSpan(label string, alwaysOn bool) string {
	switch label {
	case "10m":
		return "for 10 minutes"
	case "1h":
		return "for an hour"
	case "session":
		if alwaysOn {
			return "for 24 hours"
		}
		return "until the room ends"
	}
	return "for a while"
}

// moderateLiveRoom applies a host, moderator or operator action. operator
// skips the room-role check (the admin path checks operator roles).
func moderateLiveRoom(ctx context.Context, db *sql.DB, actor, roomID, target, action, reason string, operator bool) (liveRoom, conversationRoomModerationAction, error) {
	return applyRoomModeration(ctx, db, roomModerationRequest{
		Actor: actor, RoomID: roomID, Target: target, Action: action, Reason: reason, Operator: operator,
	})
}

// applyRoomModeration warns, mutes, unmutes or removes a member, or closes
// the room.
func applyRoomModeration(ctx context.Context, db *sql.DB, req roomModerationRequest) (liveRoom, conversationRoomModerationAction, error) {
	actor, roomID, target, reason, operator := req.Actor, req.RoomID, req.Target, req.Reason, req.Operator
	var entry conversationRoomModerationAction
	stored, ok := normalizeRoomAction(req.Action)
	if !ok {
		return liveRoom{}, entry, errRoomModerationAction
	}
	reason = strings.TrimSpace(reason)
	if runeLen(reason) > roomReasonMaxRunes {
		return liveRoom{}, entry, blogInputError("Keep the reason under 280 characters.")
	}
	if stored != "close" {
		if _, err := uuid.Parse(target); err != nil {
			return liveRoom{}, entry, blogInputError("Choose who this applies to.")
		}
		if target == actor {
			return liveRoom{}, entry, blogInputError("You can't moderate yourself.")
		}
	}
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return liveRoom{}, entry, err
	}
	defer tx.Rollback()
	viewer := actor
	if operator {
		viewer = ""
	} else if err = lockBlogAuthor(ctx, tx, actor); err != nil {
		return liveRoom{}, entry, err
	}
	room, err := lockLiveRoom(ctx, tx, viewer, roomID)
	if err != nil {
		return liveRoom{}, entry, err
	}
	actorRole := ""
	if !operator {
		_ = tx.QueryRowContext(ctx, `SELECT p.role FROM matching.conversation_room_participants p
 WHERE p.room_id=$1::uuid AND p.user_id=$2::uuid AND `+roomMemberActiveSQL, roomID, actor).Scan(&actorRole)
		if actorRole != "host" && actorRole != "moderator" {
			return liveRoom{}, entry, activityFail(403, "Only this room's hosts and moderators can do that.")
		}
	}
	meta := map[string]any{"operator": operator}
	notifyTitle, notifyBody := "", ""
	var mutedUntil *time.Time
	logged := true
	switch stored {
	case "close":
		if !operator && (actorRole != "host" || room.alwaysOn) {
			return liveRoom{}, entry, activityFail(403, "Only the host can close this room.")
		}
		if _, err = tx.ExecContext(ctx, `UPDATE matching.conversation_rooms SET lifecycle_state='closed',updated_at=NOW() WHERE id=$1::uuid`, roomID); err != nil {
			return liveRoom{}, entry, err
		}
	default:
		var targetRole, targetStatus string
		err = tx.QueryRowContext(ctx, `SELECT role,status FROM matching.conversation_room_participants WHERE room_id=$1::uuid AND user_id=$2::uuid FOR UPDATE`, roomID, target).
			Scan(&targetRole, &targetStatus)
		if errors.Is(err, sql.ErrNoRows) {
			return liveRoom{}, entry, errRoomNotParticipant
		}
		if err != nil {
			return liveRoom{}, entry, err
		}
		if !operator && (targetRole == "host" || (actorRole == "moderator" && targetRole == "moderator")) {
			return liveRoom{}, entry, activityFail(403, "You can't moderate another host or moderator.")
		}
		switch stored {
		case "mute", "unmute":
			if targetStatus == "removed" || targetStatus == "left" {
				return liveRoom{}, entry, errRoomNotParticipant
			}
			if room.state == roomLifecycleClosed {
				return liveRoom{}, entry, errRoomModerationNotActive
			}
			var changed bool
			notifyTitle, notifyBody, mutedUntil, changed, err = setRoomMute(ctx, tx, req, room, stored == "mute", meta)
			if err != nil {
				return liveRoom{}, entry, err
			}
			// Unmuting someone who isn't muted changes nothing and logs nothing.
			logged = changed
		case "warn":
			if targetStatus == "removed" || targetStatus == "left" {
				return liveRoom{}, entry, errRoomNotParticipant
			}
			notifyTitle = "A reminder from " + room.title
			notifyBody = "A host asked you to keep the conversation kind and on topic."
			if reason != "" {
				notifyBody = "A host asked you to keep the conversation kind: " + reason
			}
		default:
			if room.state == roomLifecycleClosed {
				return liveRoom{}, entry, errRoomModerationNotActive
			}
			expires := time.Now().UTC().Add(roomAlwaysOnRemoval)
			if !room.alwaysOn && room.endsAt.Valid {
				expires = room.endsAt.Time
			}
			if _, err = tx.ExecContext(ctx, `UPDATE matching.conversation_room_participants SET status='removed',left_at=NOW(),role='participant'
 WHERE room_id=$1::uuid AND user_id=$2::uuid`, roomID, target); err != nil {
				return liveRoom{}, entry, err
			}
			if _, err = tx.ExecContext(ctx, `INSERT INTO matching.conversation_room_blocks(room_id,blocked_user_id,blocked_by_user_id,reason,created_at,expires_at)
 VALUES($1::uuid,$2::uuid,(SELECT id FROM user_management.users WHERE id=$3::uuid),$4,NOW(),$5)
 ON CONFLICT (room_id,blocked_user_id) DO UPDATE SET blocked_by_user_id=EXCLUDED.blocked_by_user_id,reason=EXCLUDED.reason,created_at=NOW(),expires_at=EXCLUDED.expires_at`,
				roomID, target, actor, reason, expires); err != nil {
				return liveRoom{}, entry, err
			}
			notifyTitle = "You left " + room.title
			notifyBody = "A host removed you from this room. You can rejoin when this session ends."
			if room.alwaysOn {
				notifyBody = "A host removed you from this room. You can rejoin after 24 hours."
			}
		}
	}
	createdAt := time.Now().UTC()
	var targetArg any
	if stored != "close" {
		targetArg = target
	}
	metadata, err := json.Marshal(meta)
	if err != nil {
		return liveRoom{}, entry, err
	}
	if logged {
		if err = tx.QueryRowContext(ctx, `INSERT INTO matching.conversation_room_moderation_actions(room_id,actor_user_id,target_user_id,action,reason,metadata)
 VALUES($1::uuid,(SELECT id FROM user_management.users WHERE id=$2::uuid),$3::uuid,$4,$5,$6::jsonb) RETURNING id::text,created_at`,
			roomID, actor, targetArg, stored, reason, string(metadata)).Scan(&entry.ID, &createdAt); err != nil {
			return liveRoom{}, entry, err
		}
	}
	if notifyTitle != "" && logged {
		payload := map[string]any{"room_id": roomID, "action": publicRoomAction(stored)}
		if mutedUntil != nil {
			payload["muted_until"] = mutedUntil.Format(time.RFC3339)
		}
		if err = enqueueNotificationTx(ctx, tx, target, "", "room.moderation."+stored, "safety", roomID,
			"room-moderation:"+entry.ID, notifyTitle, notifyBody, "/rooms", payload, 6); err != nil {
			return liveRoom{}, entry, err
		}
	}
	if err = tx.Commit(); err != nil {
		return liveRoom{}, entry, err
	}
	entry.RoomID, entry.ModeratorUserID, entry.Action, entry.Reason = roomID, actor, publicRoomAction(stored), reason
	if stored != "close" {
		entry.TargetUserID = target
	}
	entry.CreatedAt = createdAt.UTC().Format(time.RFC3339)
	entry.MutedUntil = mutedUntil
	if operator {
		lr, err := getLiveRoom(ctx, db, actor, roomID)
		if errors.Is(err, errDatePlanNotFound) {
			return liveRoom{ID: roomID}, entry, nil
		}
		return lr, entry, err
	}
	lr, err := getLiveRoom(ctx, db, actor, roomID)
	return lr, entry, err
}

// setRoomMute mutes (or unmutes) req.Target in a locked room and tells them
// over the chat websocket so an open chat updates its composer at once. The
// mute's end and duration go into the log's meta. It
// returns the notification to send, when the mute ends, and whether anything
// changed (unmuting someone who isn't muted changes nothing).
func setRoomMute(ctx context.Context, tx *sql.Tx, req roomModerationRequest, room lockedRoom, mute bool, meta map[string]any) (string, string, *time.Time, bool, error) {
	var channelID string
	if err := tx.QueryRowContext(ctx, `SELECT id::text FROM matching.social_channels WHERE kind='room' AND ref_id=$1::uuid`, req.RoomID).Scan(&channelID); err != nil && !errors.Is(err, sql.ErrNoRows) {
		return "", "", nil, false, err
	}
	if !mute {
		res, err := tx.ExecContext(ctx, `UPDATE matching.conversation_room_participants SET muted_until=NULL,muted_by_user_id=NULL
 WHERE room_id=$1::uuid AND user_id=$2::uuid AND muted_until>NOW()`, req.RoomID, req.Target)
		if err != nil {
			return "", "", nil, false, err
		}
		if n, _ := res.RowsAffected(); n == 0 {
			return "", "", nil, false, nil
		}
		if err = signalSocialMember(ctx, tx, channelID, "room", req.Target, map[string]any{"reason": "unmuted"}); err != nil {
			return "", "", nil, false, err
		}
		return "You can post in " + room.title + " again", "A host lifted your mute. Welcome back to the conversation.", nil, true, nil
	}
	until, label, err := roomMuteUntil(time.Now().UTC(), room, req.Duration, req.Minutes)
	if err != nil {
		return "", "", nil, false, err
	}
	if _, err = tx.ExecContext(ctx, `UPDATE matching.conversation_room_participants
 SET muted_until=$3,muted_by_user_id=(SELECT id FROM user_management.users WHERE id=$4::uuid)
 WHERE room_id=$1::uuid AND user_id=$2::uuid`, req.RoomID, req.Target, until, req.Actor); err != nil {
		return "", "", nil, false, err
	}
	meta["muted_until"], meta["duration"] = until.Format(time.RFC3339), label
	if err = signalSocialMember(ctx, tx, channelID, "room", req.Target, map[string]any{
		"reason": "muted", "read_only_until": until.Format(time.RFC3339),
	}); err != nil {
		return "", "", nil, false, err
	}
	body := "A host muted you " + roomMuteSpan(label, room.alwaysOn) + ". You can still read along."
	if req.Reason != "" {
		body = "A host muted you " + roomMuteSpan(label, room.alwaysOn) + ": " + req.Reason + " You can still read along."
	}
	return "You're muted in " + room.title, body, &until, true, nil
}

// setLiveRoomRole lets an operator appoint or step down a room moderator.
// The member must have joined the room at some point and not be removed.
func setLiveRoomRole(ctx context.Context, db *sql.DB, operatorID, roomID, memberID, role string) error {
	if role != "moderator" && role != "participant" {
		return blogInputError("role must be moderator or participant")
	}
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()
	if _, err = lockLiveRoom(ctx, tx, "", roomID); err != nil {
		return err
	}
	res, err := tx.ExecContext(ctx, `UPDATE matching.conversation_room_participants SET role=$3
 WHERE room_id=$1::uuid AND user_id=$2::uuid AND status<>'removed' AND role<>'host'`, roomID, memberID, role)
	if err != nil {
		return err
	}
	if n, _ := res.RowsAffected(); n == 0 {
		return errRoomNotParticipant
	}
	if _, err = tx.ExecContext(ctx, `INSERT INTO matching.conversation_room_moderation_actions(room_id,actor_user_id,target_user_id,action,metadata)
 VALUES($1::uuid,(SELECT id FROM user_management.users WHERE id=$2::uuid),$3::uuid,'set_role',jsonb_build_object('role',$4::text,'operator',true))`,
		roomID, operatorID, memberID, role); err != nil {
		return err
	}
	return tx.Commit()
}

type roomDraft struct {
	Title, Description, Category string
	StartsAt                     *time.Time
	DurationMinutes, Capacity    int
}

// createLiveRoom starts a room hosted by actor.
func createLiveRoom(ctx context.Context, db *sql.DB, actor string, d roomDraft) (liveRoom, error) {
	d.Title = strings.Join(strings.Fields(d.Title), " ")
	d.Description = strings.TrimSpace(d.Description)
	d.Category = strings.ToLower(strings.TrimSpace(d.Category))
	if n := runeLen(d.Title); n < 3 || n > roomTitleMaxRunes {
		return liveRoom{}, blogInputError("Give the room a name of 3 to 60 characters.")
	}
	if runeLen(d.Description) > roomAboutMaxRunes {
		return liveRoom{}, blogInputError("Keep the description under 280 characters.")
	}
	if d.Category == "" {
		d.Category = "talk"
	}
	icon, ok := roomCategories[d.Category]
	if !ok {
		return liveRoom{}, blogInputError("Choose a category: talk, interests, active or city.")
	}
	if d.DurationMinutes == 0 {
		d.DurationMinutes = 60
	}
	if d.DurationMinutes < 30 || d.DurationMinutes > 180 {
		return liveRoom{}, blogInputError("Rooms run for 30 minutes to 3 hours.")
	}
	if d.Capacity == 0 {
		d.Capacity = roomMemberDefaultCap
	}
	if d.Capacity < 2 || d.Capacity > roomMemberCapacity {
		return liveRoom{}, blogInputError("Rooms hold 2 to 50 people.")
	}
	now := time.Now().UTC()
	starts := now
	if d.StartsAt != nil {
		starts = d.StartsAt.UTC()
		if starts.Before(now.Add(-5*time.Minute)) || starts.After(now.Add(7*24*time.Hour)) {
			return liveRoom{}, blogInputError("Start the room now or within the next 7 days.")
		}
		if starts.Before(now) {
			starts = now
		}
	}
	ends := starts.Add(time.Duration(d.DurationMinutes) * time.Minute)
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return liveRoom{}, err
	}
	defer tx.Rollback()
	if err = lockBlogAuthor(ctx, tx, actor); err != nil {
		return liveRoom{}, err
	}
	var open, today int
	if err = tx.QueryRowContext(ctx, `SELECT
 (SELECT COUNT(*) FROM matching.conversation_rooms r WHERE r.created_by_user_id=$1::uuid AND NOT r.always_on AND `+roomOpenSQL+`),
 (SELECT COUNT(*) FROM matching.conversation_rooms r WHERE r.created_by_user_id=$1::uuid AND r.created_at>NOW()-interval '24 hours')`, actor).
		Scan(&open, &today); err != nil {
		return liveRoom{}, err
	}
	if open >= roomHostOpenLimit {
		return liveRoom{}, activityFail(409, "You're already hosting a room. Close it or let it finish before starting another.")
	}
	if today >= roomHostDailyLimit {
		return liveRoom{}, activityFail(429, "You can start up to 3 rooms a day. Try again tomorrow.")
	}
	var id string
	if err = tx.QueryRowContext(ctx, `INSERT INTO matching.conversation_rooms
 (title,description,topic,room_type,always_on,category,icon_key,capacity,lifecycle_state,starts_at,ends_at,created_by_user_id)
 VALUES($1,$2,$1,'member',FALSE,$3,$4,$5,'scheduled',$6,$7,$8::uuid) RETURNING id::text`,
		d.Title, d.Description, d.Category, icon, d.Capacity, starts, ends, actor).Scan(&id); err != nil {
		return liveRoom{}, err
	}
	if _, err = tx.ExecContext(ctx, `INSERT INTO matching.conversation_room_participants(room_id,user_id,status,role,joined_at,last_seen_at)
 VALUES($1::uuid,$2::uuid,'joined','host',NOW(),NOW())`, id, actor); err != nil {
		return liveRoom{}, err
	}
	if _, err = ensureRefChannel(ctx, tx, "room", id); err != nil {
		return liveRoom{}, err
	}
	if err = tx.Commit(); err != nil {
		return liveRoom{}, err
	}
	return getLiveRoom(ctx, db, actor, id)
}

// listRoomsForOperators lists every room with counts and the latest
// moderation actions, for the control panel.
func listRoomsForOperators(ctx context.Context, q blogQuerier) ([]liveRoom, []conversationRoomModerationAction, error) {
	rows, err := q.QueryContext(ctx, roomSelectSQL()+`
 WHERE r.lifecycle_state<>'cancelled' AND (`+roomStateSQL+`<>'closed' OR COALESCE(r.ends_at,r.updated_at)>NOW()-interval '30 days')
 ORDER BY r.always_on DESC,r.sort_order,r.starts_at DESC LIMIT 500`, uuid.Nil.String())
	if err != nil {
		return nil, nil, err
	}
	rooms := []liveRoom{}
	for rows.Next() {
		lr, err := scanLiveRoom(rows)
		if err != nil {
			rows.Close()
			return nil, nil, err
		}
		rooms = append(rooms, lr)
	}
	err = rows.Err()
	rows.Close()
	if err != nil {
		return nil, nil, err
	}
	actRows, err := q.QueryContext(ctx, `SELECT a.id::text,a.room_id::text,COALESCE(a.actor_user_id::text,''),COALESCE(a.target_user_id::text,''),a.action,COALESCE(a.reason,''),a.created_at
 FROM matching.conversation_room_moderation_actions a ORDER BY a.created_at DESC LIMIT 100`)
	if err != nil {
		return nil, nil, err
	}
	defer actRows.Close()
	actions := []conversationRoomModerationAction{}
	for actRows.Next() {
		var a conversationRoomModerationAction
		var at time.Time
		if err = actRows.Scan(&a.ID, &a.RoomID, &a.ModeratorUserID, &a.TargetUserID, &a.Action, &a.Reason, &at); err != nil {
			return nil, nil, err
		}
		a.Action = publicRoomAction(a.Action)
		a.CreatedAt = at.UTC().Format(time.RFC3339)
		actions = append(actions, a)
	}
	return rooms, actions, actRows.Err()
}

// operatorRoomMember is one person in a room as operators see it: current
// members plus anyone muted or removed whose mute or removal still runs.
type operatorRoomMember struct {
	UserID       string     `json:"user_id"`
	Name         string     `json:"name"`
	PhotoURL     string     `json:"photo_url"`
	Role         string     `json:"role"`
	Status       string     `json:"status"`
	JoinedAt     time.Time  `json:"joined_at"`
	LastSeenAt   *time.Time `json:"last_seen_at"`
	HereNow      bool       `json:"here_now"`
	InRoom       bool       `json:"in_room"`
	MutedUntil   *time.Time `json:"muted_until,omitempty"`
	RemovedUntil *time.Time `json:"removed_until,omitempty"`
}

// listRoomMembersForOperators lists a room's current members, then anyone
// still muted or removed from it, for the control panel. Blocks between
// members don't apply: operators see everyone.
func listRoomMembersForOperators(ctx context.Context, q blogQuerier, roomID string) ([]operatorRoomMember, error) {
	var exists bool
	if err := q.QueryRowContext(ctx, `SELECT EXISTS(SELECT 1 FROM matching.conversation_rooms WHERE id=$1::uuid)`, roomID).Scan(&exists); err != nil {
		return nil, err
	}
	if !exists {
		return nil, errDatePlanNotFound
	}
	rows, err := q.QueryContext(ctx, `WITH people AS (
 SELECT p.user_id,p.role,p.status,p.joined_at,p.last_seen_at,
  (`+roomMemberActiveSQL+`) AS in_room,
  CASE WHEN p.muted_until>NOW() THEN p.muted_until END AS muted_until,
  (SELECT CASE WHEN b.expires_at IS NULL THEN 'infinity'::timestamptz ELSE b.expires_at END FROM matching.conversation_room_blocks b
    WHERE b.room_id=p.room_id AND b.blocked_user_id=p.user_id AND (b.expires_at IS NULL OR b.expires_at>NOW())) AS removed_until
 FROM matching.conversation_room_participants p WHERE p.room_id=$1::uuid)
SELECT pp.user_id::text,`+socialMemberCardSQL("pp.user_id")+`,pp.role,pp.status,pp.joined_at,pp.last_seen_at,
 COALESCE(pp.in_room AND pp.last_seen_at>NOW()-interval '2 minutes',FALSE),pp.in_room,pp.muted_until,
 CASE WHEN isfinite(pp.removed_until) THEN pp.removed_until END,pp.removed_until IS NOT NULL
FROM people pp
WHERE pp.in_room OR pp.muted_until IS NOT NULL OR pp.removed_until IS NOT NULL
ORDER BY pp.in_room DESC,CASE pp.role WHEN 'host' THEN 0 WHEN 'moderator' THEN 1 ELSE 2 END,
 pp.last_seen_at DESC NULLS LAST,pp.user_id
LIMIT $2`, roomID, roomMembersPageLimit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []operatorRoomMember{}
	for rows.Next() {
		var m operatorRoomMember
		var seen, muted, removed sql.NullTime
		var removedForever bool
		if err = rows.Scan(&m.UserID, &m.Name, &m.PhotoURL, &m.Role, &m.Status, &m.JoinedAt, &seen, &m.HereNow, &m.InRoom, &muted, &removed, &removedForever); err != nil {
			return nil, err
		}
		m.JoinedAt = m.JoinedAt.UTC()
		for _, pair := range []struct {
			src sql.NullTime
			dst **time.Time
		}{{seen, &m.LastSeenAt}, {muted, &m.MutedUntil}, {removed, &m.RemovedUntil}} {
			if pair.src.Valid {
				t := pair.src.Time.UTC()
				*pair.dst = &t
			}
		}
		if removedForever && m.RemovedUntil == nil {
			// A removal with no end: report it far in the future.
			t := time.Date(9999, 12, 31, 0, 0, 0, 0, time.UTC)
			m.RemovedUntil = &t
		}
		out = append(out, m)
	}
	return out, rows.Err()
}
