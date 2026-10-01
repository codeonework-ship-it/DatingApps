package mobile

import (
	"context"
	"database/sql"
	"errors"
	"sort"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"
)

// Friend requests (migration 116).
//
// A request is one pending row requester -> recipient in
// matching.friend_connections; a friendship is two accepted rows. Rules:
//
//   - Sending again never downgrades: an accepted friendship stays accepted
//     and a repeated request returns the open one unchanged.
//   - Asking someone who already asked you accepts their request (mutual).
//   - Either member having blocked the other makes requests and accepts
//     unavailable; both must be active adult dating members.
//   - After a decline the same requester waits 7 days before asking again.
//   - A member sends at most 30 requests in any 24 hours; cancelling does not
//     give the request back.
//   - The recipient is notified of a request, the requester of an accept. A
//     decline is silent.
//   - Where a request started (search, match, profile, room, group) is kept.
//
// The Postgres path below is used whenever the native database is available;
// the in-memory store applies the same rules for tests and the mock backend.

const (
	friendRequestCooldown  = 7 * 24 * time.Hour
	friendRequestsPerDay   = 30
	friendSearchMinRunes   = 3
	friendSearchMaxRunes   = 40
	friendSearchLimit      = 10
	friendUnavailableText  = "This member isn't available for friend requests."
	friendCooldownText     = "You can't send this member another request yet. Try again in a few days."
	friendDailyLimitText   = "You've sent 30 friend requests today. Try again tomorrow."
	friendRequestGoneText  = "This friend request is no longer open."
	friendSearchShortText  = "Type at least 3 letters of a name or username."
	friendSourceText       = "source must be one of search, match, profile, room or group"
	friendNotificationKind = "friend_plan"
)

var friendRequestSources = map[string]bool{"search": true, "match": true, "profile": true, "room": true, "group": true}

// normalizeFriendSource validates where a request started. Empty is allowed
// for older clients and is stored as NULL.
func normalizeFriendSource(raw string) (string, error) {
	source := strings.ToLower(strings.TrimSpace(raw))
	if source == "" || friendRequestSources[source] {
		return source, nil
	}
	return "", activityFail(400, friendSourceText)
}

// friendCandidate is a member offered by the Add friend search. Only what a
// member card shows: no age, bio, gender or exact location.
type friendCandidate struct {
	UserID   string `json:"user_id"`
	Name     string `json:"name"`
	Username string `json:"username"`
	City     string `json:"city,omitempty"`
	PhotoURL string `json:"photo_url,omitempty"`
	// none, friends, outgoing (I asked) or incoming (they asked).
	Relationship string `json:"relationship"`
}

// normalizeFriendQuery lowercases and trims a search, dropping a leading @.
func normalizeFriendQuery(raw string) (string, error) {
	q := strings.ToLower(strings.TrimSpace(raw))
	q = strings.TrimSpace(strings.TrimPrefix(q, "@"))
	n := utf8.RuneCountInString(q)
	if n < friendSearchMinRunes {
		return "", activityFail(400, friendSearchShortText)
	}
	if n > friendSearchMaxRunes {
		q = string([]rune(q)[:friendSearchMaxRunes])
	}
	return q, nil
}

func escapeLike(s string) string {
	return strings.NewReplacer(`\`, `\\`, `%`, `\%`, `_`, `\_`).Replace(s)
}

// ---------------------------------------------------------------------------
// Postgres
// ---------------------------------------------------------------------------

// friendCardColumns: name, username, city and first approved photo of users
// alias u.
const friendCardColumns = `COALESCE(NULLIF(u.name,''),u.username,''),u.username,COALESCE(u.city,''),
 COALESCE((SELECT ph.photo_url FROM user_management.photos ph WHERE ph.user_id=u.id AND ph.deleted_at IS NULL
  AND ph.lifecycle_status='active' AND ph.moderation_status='approved' ORDER BY ph.ordering,ph.id LIMIT 1),'')`

// listFriendsPG returns accepted friends and open requests both ways, with
// each member's card. Members who are no longer active, or where either side
// blocked the other, are left out.
func listFriendsPG(ctx context.Context, q blogQuerier, me string) ([]friendConnection, error) {
	rows, err := q.QueryContext(ctx, `WITH raw AS (
  SELECT f.friend_user_id AS other,f.status,CASE WHEN f.status='pending' THEN 'outgoing' ELSE '' END AS direction,
         f.source,f.created_at,f.updated_at
  FROM matching.friend_connections f WHERE f.user_id=$1::uuid AND f.status IN ('accepted','pending')
  UNION ALL
  SELECT f.user_id,'pending','incoming',f.source,f.created_at,f.updated_at
  FROM matching.friend_connections f WHERE f.friend_user_id=$1::uuid AND f.status='pending'
), one AS (
  SELECT DISTINCT ON (other) * FROM raw ORDER BY other,(status='accepted') DESC,updated_at DESC
)
SELECT r.other::text,r.status,r.direction,COALESCE(r.source,''),r.created_at,r.updated_at,`+friendCardColumns+`
FROM one r JOIN user_management.users u ON u.id=r.other
WHERE `+blogActive+` AND `+socialNotBlockedSQL("r.other", "$1::uuid")+`
ORDER BY r.updated_at DESC,r.other`, me)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []friendConnection{}
	for rows.Next() {
		var f friendConnection
		var created, updated time.Time
		if err = rows.Scan(&f.FriendID, &f.Status, &f.Direction, &f.Source, &created, &updated,
			&f.FriendName, &f.FriendUsername, &f.FriendCity, &f.FriendPhotoURL); err != nil {
			return nil, err
		}
		f.UserID = me
		f.CreatedAt = created.UTC().Format(time.RFC3339)
		f.UpdatedAt = updated.UTC().Format(time.RFC3339)
		if f.FriendName == "" {
			f.FriendName = "Friend"
		}
		out = append(out, f)
	}
	return out, rows.Err()
}

// readFriendPG is my view of one connection (zero value when none).
func readFriendPG(ctx context.Context, q blogQuerier, me, other string) (friendConnection, error) {
	all, err := listFriendsPG(ctx, q, me)
	if err != nil {
		return friendConnection{}, err
	}
	for _, f := range all {
		if f.FriendID == other {
			return f, nil
		}
	}
	return friendConnection{}, nil
}

// lockFriendPair serialises every change between two members.
func lockFriendPair(ctx context.Context, tx *sql.Tx, a, b string) error {
	if b < a {
		a, b = b, a
	}
	_, err := tx.ExecContext(ctx, `SELECT pg_advisory_xact_lock(hashtextextended('friend-pair:'||$1||':'||$2,0))`, a, b)
	return err
}

// friendStatusTx is the status of the from -> to row ("" when none).
func friendStatusTx(ctx context.Context, tx *sql.Tx, from, to string) (status, source string, err error) {
	var src sql.NullString
	err = tx.QueryRowContext(ctx, `SELECT status,source FROM matching.friend_connections WHERE user_id=$1::uuid AND friend_user_id=$2::uuid FOR UPDATE`, from, to).Scan(&status, &src)
	if errors.Is(err, sql.ErrNoRows) {
		return "", "", nil
	}
	return status, src.String, err
}

// friendAvailableTx: other is an active member and neither blocked the other.
func friendAvailableTx(ctx context.Context, tx *sql.Tx, me, other string) error {
	var ok bool
	err := tx.QueryRowContext(ctx, `SELECT EXISTS(SELECT 1 FROM user_management.users u WHERE u.id=$2::uuid AND `+blogActive+`)
 AND `+socialNotBlockedSQL("$1::uuid", "$2::uuid"), me, other).Scan(&ok)
	if err != nil {
		return err
	}
	if !ok {
		return activityFail(404, friendUnavailableText)
	}
	return nil
}

// acceptFriendTx makes requester and recipient friends, clears declines
// between them, writes both activity rows and tells the requester.
func acceptFriendTx(ctx context.Context, tx *sql.Tx, recipient, requester, source string) error {
	if _, err := tx.ExecContext(ctx, `INSERT INTO matching.friend_connections AS f (user_id,friend_user_id,status,source)
 VALUES ($1::uuid,$2::uuid,'accepted',NULLIF($3,'')),($2::uuid,$1::uuid,'accepted',NULLIF($3,''))
 ON CONFLICT (user_id,friend_user_id) DO UPDATE SET status='accepted',updated_at=NOW(),source=COALESCE(f.source,EXCLUDED.source)`,
		requester, recipient, source); err != nil {
		return err
	}
	if _, err := tx.ExecContext(ctx, `DELETE FROM matching.friend_request_declines
 WHERE (requester_id=$1::uuid AND recipient_id=$2::uuid) OR (requester_id=$2::uuid AND recipient_id=$1::uuid)`, requester, recipient); err != nil {
		return err
	}
	if _, err := tx.ExecContext(ctx, `INSERT INTO matching.friend_activity_feed (user_id,friend_user_id,activity_type,title,description,metadata)
 VALUES ($1::uuid,$2::uuid,'friend_connected','Friend request accepted','You can now message and plan things together.',jsonb_build_object('source',$3::text)),
        ($2::uuid,$1::uuid,'friend_connected','Friend request accepted','You can now message and plan things together.',jsonb_build_object('source',$3::text))`,
		requester, recipient, source); err != nil {
		return err
	}
	name := memberName(ctx, tx, recipient, "Your friend")
	return enqueueNotificationTx(ctx, tx, requester, recipient, "friend_request.accepted", friendNotificationKind, recipient,
		"friend-accepted:"+requester+":"+recipient+":"+time.Now().UTC().Format("2006-01-02"),
		name+" accepted your friend request", "You can message each other now.", "/friends",
		map[string]any{"friend_user_id": recipient, "friend_name": name}, 5)
}

// sendFriendRequestPG applies every request rule in one transaction.
func sendFriendRequestPG(ctx context.Context, db *sql.DB, me, other, source string) (friendConnection, error) {
	if _, err := uuid.Parse(other); err != nil {
		return friendConnection{}, activityFail(404, friendUnavailableText)
	}
	if me == other {
		return friendConnection{}, activityFail(400, "You can't add yourself as a friend.")
	}
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return friendConnection{}, err
	}
	defer tx.Rollback()
	if err = lockBlogAuthor(ctx, tx, me); err != nil {
		return friendConnection{}, err
	}
	if err = lockFriendPair(ctx, tx, me, other); err != nil {
		return friendConnection{}, err
	}
	if err = friendAvailableTx(ctx, tx, me, other); err != nil {
		return friendConnection{}, err
	}
	mine, _, err := friendStatusTx(ctx, tx, me, other)
	if err != nil {
		return friendConnection{}, err
	}
	theirs, theirSource, err := friendStatusTx(ctx, tx, other, me)
	if err != nil {
		return friendConnection{}, err
	}
	switch {
	case mine == "accepted" || theirs == "accepted":
		// Already friends: never downgrade. Repair a half-accepted pair left
		// by older builds (a re-sent request used to overwrite one side with
		// pending) so both rows say accepted again.
		if theirs == "accepted" && mine != "accepted" {
			if _, err = tx.ExecContext(ctx, `INSERT INTO matching.friend_connections (user_id,friend_user_id,status) VALUES ($1::uuid,$2::uuid,'accepted')
 ON CONFLICT (user_id,friend_user_id) DO UPDATE SET status='accepted',updated_at=NOW()`, me, other); err != nil {
				return friendConnection{}, err
			}
		}
		if mine == "accepted" && theirs == "pending" {
			if _, err = tx.ExecContext(ctx, `UPDATE matching.friend_connections SET status='accepted',updated_at=NOW()
 WHERE user_id=$1::uuid AND friend_user_id=$2::uuid AND status='pending'`, other, me); err != nil {
				return friendConnection{}, err
			}
		}
	case theirs == "pending":
		// Mutual: they asked first, so this is an accept.
		if theirSource == "" {
			theirSource = source
		}
		if err = acceptFriendTx(ctx, tx, me, other, theirSource); err != nil {
			return friendConnection{}, err
		}
	case mine == "pending":
		// Already asked: leave the open request as it is.
	default:
		var cooling bool
		if err = tx.QueryRowContext(ctx, `SELECT EXISTS(SELECT 1 FROM matching.friend_request_declines
 WHERE requester_id=$1::uuid AND recipient_id=$2::uuid AND declined_at>NOW()-make_interval(secs=>$3))`,
			me, other, friendRequestCooldown.Seconds()).Scan(&cooling); err != nil {
			return friendConnection{}, err
		}
		if cooling {
			return friendConnection{}, activityFail(429, friendCooldownText)
		}
		var sent int
		if err = tx.QueryRowContext(ctx, `SELECT COUNT(*) FROM matching.friend_request_sends WHERE requester_id=$1::uuid AND created_at>NOW()-interval '24 hours'`, me).Scan(&sent); err != nil {
			return friendConnection{}, err
		}
		if sent >= friendRequestsPerDay {
			return friendConnection{}, activityFail(429, friendDailyLimitText)
		}
		if _, err = tx.ExecContext(ctx, `INSERT INTO matching.friend_connections AS f (user_id,friend_user_id,status,source)
 VALUES ($1::uuid,$2::uuid,'pending',NULLIF($3,''))
 ON CONFLICT (user_id,friend_user_id) DO UPDATE SET status='pending',source=EXCLUDED.source,created_at=NOW(),updated_at=NOW()`, me, other, source); err != nil {
			return friendConnection{}, err
		}
		if _, err = tx.ExecContext(ctx, `INSERT INTO matching.friend_request_sends (requester_id,recipient_id,source) VALUES ($1::uuid,$2::uuid,NULLIF($3,''))`, me, other, source); err != nil {
			return friendConnection{}, err
		}
		name := memberName(ctx, tx, me, "Someone")
		if err = enqueueNotificationTx(ctx, tx, other, me, "friend_request.received", friendNotificationKind, me,
			"friend-request:"+me+":"+other+":"+time.Now().UTC().Format("2006-01-02"),
			name+" wants to be friends", "Accept to message each other and plan things together.", "/friends",
			map[string]any{"requester_user_id": me, "requester_name": name, "source": source}, 5); err != nil {
			return friendConnection{}, err
		}
	}
	view, err := readFriendPG(ctx, tx, me, other)
	if err != nil {
		return friendConnection{}, err
	}
	return view, tx.Commit()
}

// decideFriendRequestPG accepts or declines requester's pending request.
func decideFriendRequestPG(ctx context.Context, db *sql.DB, me, requester, decision string) (friendConnection, error) {
	decision = strings.ToLower(strings.TrimSpace(decision))
	if decision != "accept" && decision != "decline" {
		return friendConnection{}, activityFail(400, "decision must be accept or decline")
	}
	if _, err := uuid.Parse(requester); err != nil || requester == me {
		return friendConnection{}, activityFail(404, friendRequestGoneText)
	}
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return friendConnection{}, err
	}
	defer tx.Rollback()
	if err = lockBlogAuthor(ctx, tx, me); err != nil {
		return friendConnection{}, err
	}
	if err = lockFriendPair(ctx, tx, me, requester); err != nil {
		return friendConnection{}, err
	}
	status, source, err := friendStatusTx(ctx, tx, requester, me)
	if err != nil {
		return friendConnection{}, err
	}
	if status != "pending" {
		return friendConnection{}, activityFail(404, friendRequestGoneText)
	}
	if decision == "decline" {
		if err = declineFriendTx(ctx, tx, requester, me); err != nil {
			return friendConnection{}, err
		}
		return friendConnection{}, tx.Commit()
	}
	if err = friendAvailableTx(ctx, tx, me, requester); err != nil {
		return friendConnection{}, err
	}
	if err = acceptFriendTx(ctx, tx, me, requester, source); err != nil {
		return friendConnection{}, err
	}
	view, err := readFriendPG(ctx, tx, me, requester)
	if err != nil {
		return friendConnection{}, err
	}
	return view, tx.Commit()
}

// declineFriendTx removes the request and starts the requester's cooldown.
func declineFriendTx(ctx context.Context, tx *sql.Tx, requester, recipient string) error {
	if _, err := tx.ExecContext(ctx, `DELETE FROM matching.friend_connections WHERE user_id=$1::uuid AND friend_user_id=$2::uuid AND status='pending'`, requester, recipient); err != nil {
		return err
	}
	_, err := tx.ExecContext(ctx, `INSERT INTO matching.friend_request_declines (requester_id,recipient_id,declined_at) VALUES ($1::uuid,$2::uuid,NOW())
 ON CONFLICT (requester_id,recipient_id) DO UPDATE SET declined_at=NOW()`, requester, recipient)
	return err
}

// removeFriendPG ends a friendship, cancels my request, or (when only their
// request is open) declines it.
func removeFriendPG(ctx context.Context, db *sql.DB, me, other string) error {
	if _, err := uuid.Parse(other); err != nil {
		return nil
	}
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()
	if err = lockFriendPair(ctx, tx, me, other); err != nil {
		return err
	}
	mine, _, err := friendStatusTx(ctx, tx, me, other)
	if err != nil {
		return err
	}
	theirs, _, err := friendStatusTx(ctx, tx, other, me)
	if err != nil {
		return err
	}
	if theirs == "pending" && mine == "" {
		if err = declineFriendTx(ctx, tx, other, me); err != nil {
			return err
		}
		return tx.Commit()
	}
	if _, err = tx.ExecContext(ctx, `DELETE FROM matching.friend_connections
 WHERE (user_id=$1::uuid AND friend_user_id=$2::uuid) OR (user_id=$2::uuid AND friend_user_id=$1::uuid)`, me, other); err != nil {
		return err
	}
	return tx.Commit()
}

// friendSearchVisibleSQL: member u has not opted out of friend search
// (user_settings.friend_search_visible, migration 120; default on).
const friendSearchVisibleSQL = `COALESCE((SELECT st.friend_search_visible FROM user_management.user_settings st WHERE st.user_id=u.id),TRUE)`

// friendSearchVisiblePG reads the member's "Let people find me in friend
// search" setting. Members without a settings row are findable.
func friendSearchVisiblePG(ctx context.Context, q blogQuerier, me string) (bool, error) {
	var visible bool
	err := q.QueryRowContext(ctx, `SELECT COALESCE((SELECT friend_search_visible FROM user_management.user_settings WHERE user_id=$1::uuid),TRUE)`, me).Scan(&visible)
	return visible, err
}

// setFriendSearchVisiblePG stores the setting, creating the settings row with
// its defaults when the member has none yet.
func setFriendSearchVisiblePG(ctx context.Context, db *sql.DB, me string, visible bool) error {
	_, err := db.ExecContext(ctx, `INSERT INTO user_management.user_settings(user_id,friend_search_visible,updated_at) VALUES($1::uuid,$2,NOW())
 ON CONFLICT (user_id) DO UPDATE SET friend_search_visible=EXCLUDED.friend_search_visible,updated_at=NOW()
 WHERE user_management.user_settings.friend_search_visible IS DISTINCT FROM EXCLUDED.friend_search_visible`, me, visible)
	return err
}

// searchFriendCandidatesPG finds active adult dating members by username or
// name prefix (any word of the name), excluding me, anyone either side
// blocked and anyone who turned off "Let people find me in friend search".
// At most 10, exact username first.
func searchFriendCandidatesPG(ctx context.Context, db *sql.DB, me, rawQuery string) ([]friendCandidate, error) {
	q, err := normalizeFriendQuery(rawQuery)
	if err != nil {
		return nil, err
	}
	var active bool
	if err = db.QueryRowContext(ctx, `SELECT EXISTS(SELECT 1 FROM user_management.users u WHERE u.id=$1::uuid AND `+blogActive+`)`, me).Scan(&active); err != nil {
		return nil, err
	}
	if !active {
		return nil, errDatePlanForbidden
	}
	prefix := escapeLike(q) + "%"
	rows, err := db.QueryContext(ctx, `SELECT u.id::text,`+friendCardColumns+`,
 CASE WHEN EXISTS(SELECT 1 FROM matching.friend_connections f WHERE f.status='accepted'
        AND ((f.user_id=$1::uuid AND f.friend_user_id=u.id) OR (f.user_id=u.id AND f.friend_user_id=$1::uuid))) THEN 'friends'
      WHEN EXISTS(SELECT 1 FROM matching.friend_connections f WHERE f.user_id=$1::uuid AND f.friend_user_id=u.id AND f.status='pending') THEN 'outgoing'
      WHEN EXISTS(SELECT 1 FROM matching.friend_connections f WHERE f.user_id=u.id AND f.friend_user_id=$1::uuid AND f.status='pending') THEN 'incoming'
      ELSE 'none' END
FROM user_management.users u
WHERE u.id<>$1::uuid AND `+blogActive+` AND `+socialNotBlockedSQL("u.id", "$1::uuid")+` AND `+friendSearchVisibleSQL+`
  AND (lower(u.username) LIKE $2 ESCAPE '\' OR lower(u.name) LIKE $2 ESCAPE '\' OR lower(u.name) LIKE '% '||$2 ESCAPE '\')
ORDER BY (lower(u.username)=$3) DESC,(lower(u.name)=$3) DESC,lower(u.name),u.id
LIMIT $4`, me, prefix, q, friendSearchLimit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []friendCandidate{}
	for rows.Next() {
		var c friendCandidate
		if err = rows.Scan(&c.UserID, &c.Name, &c.Username, &c.City, &c.PhotoURL, &c.Relationship); err != nil {
			return nil, err
		}
		out = append(out, c)
	}
	return out, rows.Err()
}

// ---------------------------------------------------------------------------
// In-memory store (tests and the mock backend)
// ---------------------------------------------------------------------------

// addFriendFrom sends a friend request from userID to friendUserID.
func (m *runtimeStore) addFriendFrom(userID, friendUserID, source string) (friendConnection, error) {
	trimmedUserID := strings.TrimSpace(userID)
	trimmedFriendID := strings.TrimSpace(friendUserID)
	if trimmedUserID == "" || trimmedFriendID == "" {
		return friendConnection{}, errors.New("user_id and friend_user_id are required")
	}
	if trimmedUserID == trimmedFriendID {
		return friendConnection{}, errors.New("cannot add yourself as friend")
	}
	source, err := normalizeFriendSource(source)
	if err != nil {
		return friendConnection{}, err
	}
	if m.friendPairBlocked(trimmedUserID, trimmedFriendID) {
		return friendConnection{}, errors.New("friend request is unavailable")
	}

	if m.socialRepo != nil {
		connection, repoErr := m.socialRepo.addFriend(context.Background(), trimmedUserID, trimmedFriendID, source, time.Now().UTC())
		if repoErr == nil {
			return connection, nil
		}
		if m.durableEngagementRequired() || !isSocialRepoPersistenceUnavailable(repoErr) {
			return friendConnection{}, repoErr
		}
	}

	m.mu.Lock()
	defer m.mu.Unlock()
	if existing, ok := m.friends[trimmedUserID][trimmedFriendID]; ok && existing.Status == "accepted" {
		return existing, nil
	}
	if theirs, ok := m.friends[trimmedFriendID][trimmedUserID]; ok {
		switch theirs.Status {
		case "accepted":
			return m.friends[trimmedUserID][trimmedFriendID], nil
		case "pending":
			if theirs.Source == "" {
				theirs.Source = source
			}
			return m.acceptFriendLocked(trimmedUserID, trimmedFriendID, theirs), nil
		}
	}
	if existing, ok := m.friends[trimmedUserID][trimmedFriendID]; ok && existing.Status == "pending" {
		return existing, nil
	}
	now := time.Now().UTC()
	if declined, ok := m.friendDeclines[trimmedUserID+"|"+trimmedFriendID]; ok && now.Sub(declined) < friendRequestCooldown {
		return friendConnection{}, activityFail(429, friendCooldownText)
	}
	recent := []time.Time{}
	for _, at := range m.friendSends[trimmedUserID] {
		if now.Sub(at) < 24*time.Hour {
			recent = append(recent, at)
		}
	}
	if len(recent) >= friendRequestsPerDay {
		return friendConnection{}, activityFail(429, friendDailyLimitText)
	}
	if m.friendSends == nil {
		m.friendSends = map[string][]time.Time{}
	}
	m.friendSends[trimmedUserID] = append(recent, now)
	if _, ok := m.friends[trimmedUserID]; !ok {
		m.friends[trimmedUserID] = make(map[string]friendConnection)
	}
	friendName := "Friend"
	if draft, ok := m.profiles[trimmedFriendID]; ok && strings.TrimSpace(draft.Name) != "" {
		friendName = strings.TrimSpace(draft.Name)
	}
	stamp := now.Format(time.RFC3339)
	connection := friendConnection{
		UserID:     trimmedUserID,
		FriendID:   trimmedFriendID,
		Status:     "pending",
		Direction:  "outgoing",
		CreatedAt:  stamp,
		UpdatedAt:  stamp,
		FriendName: friendName,
		Source:     source,
	}
	m.friends[trimmedUserID][trimmedFriendID] = connection
	return connection, nil
}

// recordFriendDeclineLocked starts requester's cooldown. Caller holds m.mu.
func (m *runtimeStore) recordFriendDeclineLocked(requester, recipient string) {
	if m.friendDeclines == nil {
		m.friendDeclines = map[string]time.Time{}
	}
	m.friendDeclines[requester+"|"+recipient] = time.Now().UTC()
}

// searchFriendCandidates is the in-memory search over profile drafts.
func (m *runtimeStore) searchFriendCandidates(me, rawQuery string) ([]friendCandidate, error) {
	q, err := normalizeFriendQuery(rawQuery)
	if err != nil {
		return nil, err
	}
	m.mu.RLock()
	defer m.mu.RUnlock()
	out := []friendCandidate{}
	for id, draft := range m.profiles {
		if id == me || m.friendPairBlockedLocked(me, id) || m.friendSearchHidden[id] {
			continue
		}
		name := strings.ToLower(strings.TrimSpace(draft.Name))
		username := strings.ToLower(strings.TrimSpace(draft.Username))
		if !strings.HasPrefix(username, q) && !strings.HasPrefix(name, q) && !strings.Contains(name, " "+q) {
			continue
		}
		c := friendCandidate{UserID: id, Name: strings.TrimSpace(draft.Name), Username: draft.Username, Relationship: "none"}
		if draft.City != nil {
			c.City = *draft.City
		}
		if mine, ok := m.friends[me][id]; ok {
			c.Relationship = map[string]string{"accepted": "friends", "pending": "outgoing"}[mine.Status]
		}
		if theirs, ok := m.friends[id][me]; ok && c.Relationship == "none" {
			c.Relationship = map[string]string{"accepted": "friends", "pending": "incoming"}[theirs.Status]
		}
		if c.Relationship == "" {
			c.Relationship = "none"
		}
		out = append(out, c)
	}
	sort.Slice(out, func(i, j int) bool {
		if out[i].Name != out[j].Name {
			return strings.ToLower(out[i].Name) < strings.ToLower(out[j].Name)
		}
		return out[i].UserID < out[j].UserID
	})
	if len(out) > friendSearchLimit {
		out = out[:friendSearchLimit]
	}
	return out, nil
}

// friendSearchVisible is the in-memory "Let people find me in friend search"
// setting (default on).
func (m *runtimeStore) friendSearchVisible(userID string) bool {
	m.mu.RLock()
	defer m.mu.RUnlock()
	return !m.friendSearchHidden[userID]
}

func (m *runtimeStore) setFriendSearchVisible(userID string, visible bool) {
	m.mu.Lock()
	defer m.mu.Unlock()
	if m.friendSearchHidden == nil {
		m.friendSearchHidden = map[string]bool{}
	}
	if visible {
		delete(m.friendSearchHidden, userID)
	} else {
		m.friendSearchHidden[userID] = true
	}
}
