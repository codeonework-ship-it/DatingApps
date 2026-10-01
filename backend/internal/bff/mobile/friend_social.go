package mobile

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"
)

// Friend vouches and friend-made intros (migration 096).
//
// A vouch is written by an accepted friend and shown on the subject's public
// profile only after the subject approves it. An intro is made by a member
// between two of their accepted friends; when both accept, a match is created
// through the ordinary matches table.

var (
	errVouchNotFound     = errors.New("vouch not found")
	errVouchNotFriend    = errors.New("you can only vouch for an accepted friend")
	errVouchForbidden    = errors.New("only the member the vouch is about can decide on it")
	errVouchExists       = errors.New("you already vouched for this friend")
	errIntroNotFound     = errors.New("intro not found")
	errIntroNotFriends   = errors.New("both people must be your accepted friends")
	errIntroUnavailable  = errors.New("an intro is not available for this pair")
	errIntroForbidden    = errors.New("only the people being introduced can answer")
	errIntroAlreadyOpen  = errors.New("an intro between these two is already open")
	errIntroNotOpen      = errors.New("this intro is no longer open")
	errIntroNotPublished = errors.New("both people need a complete profile before an intro")
)

const (
	vouchMinRunes        = 12
	vouchMaxRunes        = 200
	introMessageMaxRunes = 200
	publicVouchLimit     = 3
)

type friendVouchView struct {
	ID          string `json:"id"`
	SubjectID   string `json:"subject_user_id"`
	SubjectName string `json:"subject_name"`
	VoucherID   string `json:"voucher_user_id"`
	VoucherName string `json:"voucher_name"`
	Text        string `json:"text"`
	Status      string `json:"status"`
	CreatedAt   string `json:"created_at"`
	DecidedAt   string `json:"decided_at,omitempty"`
}

type publicVouchView struct {
	Text        string `json:"text"`
	VoucherName string `json:"voucher_name"`
	ApprovedAt  string `json:"approved_at"`
}

type introPreview struct {
	UserID     string   `json:"user_id"`
	Name       string   `json:"name"`
	Age        *int     `json:"age,omitempty"`
	City       string   `json:"city,omitempty"`
	IsVerified bool     `json:"is_verified"`
	PhotoURLs  []string `json:"photo_urls"`
}

type friendIntroView struct {
	ID             string        `json:"id"`
	IntroducerID   string        `json:"introducer_user_id"`
	IntroducerName string        `json:"introducer_name"`
	Message        string        `json:"message,omitempty"`
	Status         string        `json:"status"`
	MyDecision     string        `json:"my_decision,omitempty"`
	Other          *introPreview `json:"other,omitempty"`
	FirstName      string        `json:"first_name,omitempty"`
	SecondName     string        `json:"second_name,omitempty"`
	MatchID        string        `json:"match_id,omitempty"`
	ExpiresAt      string        `json:"expires_at"`
	CreatedAt      string        `json:"created_at"`
}

type friendSocialService struct {
	db  *sql.DB
	now func() time.Time
}

func newFriendSocialService(db *sql.DB) *friendSocialService {
	if db == nil {
		return nil
	}
	return &friendSocialService{db: db, now: func() time.Time { return time.Now().UTC() }}
}

func validateVouchText(text string) (string, error) {
	trimmed := strings.TrimSpace(text)
	n := utf8.RuneCountInString(trimmed)
	if n < vouchMinRunes || n > vouchMaxRunes {
		return "", errors.New("a vouch must be between 12 and 200 characters")
	}
	return trimmed, nil
}

func validateIntroMessage(message string) (string, error) {
	trimmed := strings.TrimSpace(message)
	if utf8.RuneCountInString(trimmed) > introMessageMaxRunes {
		return "", errors.New("message must be 200 characters or fewer")
	}
	return trimmed, nil
}

func isPgException(err error, fragment string) bool {
	return err != nil && strings.Contains(strings.ToLower(err.Error()), strings.ToLower(fragment))
}

func enqueueNotificationTx(ctx context.Context, tx *sql.Tx, recipient, actor, eventType, category, referenceID, dedupeKey, title, body, route string, payload map[string]any, priority int) error {
	if payload == nil {
		payload = map[string]any{}
	}
	encoded, err := json.Marshal(payload)
	if err != nil {
		return err
	}
	_, err = tx.ExecContext(ctx, `
		SELECT matching.enqueue_notification(
		  $1::uuid, NULLIF($2,'')::uuid, $3, $4, NULLIF($5,'')::uuid, $6, $7, $8, $9, $10::jsonb, $11::smallint)`,
		recipient, actor, eventType, category, referenceID, dedupeKey, title, body, route, string(encoded), priority)
	return err
}

func publishFriendSocialEventTx(ctx context.Context, tx *sql.Tx, eventName, aggregateType, aggregateID, subjectID, actorID string, payload map[string]any) error {
	if payload == nil {
		payload = map[string]any{}
	}
	encoded, err := json.Marshal(payload)
	if err != nil {
		return err
	}
	_, err = tx.ExecContext(ctx, `
		SELECT platform.publish_domain_event(
		  $1, 1, $2, $3, 'mobile-bff.friend-social',
		  NULLIF($4,'')::uuid, NULLIF($5,'')::uuid, NULL, NULL, $6, $7::jsonb, '{}'::jsonb, NOW())`,
		eventName, aggregateType, aggregateID, subjectID, actorID,
		"friend-social:"+eventName+":"+aggregateID+":"+actorID, string(encoded))
	return err
}

func memberName(ctx context.Context, q interface {
	QueryRowContext(context.Context, string, ...any) *sql.Row
}, userID, fallback string) string {
	var name sql.NullString
	if err := q.QueryRowContext(ctx, `SELECT name FROM user_management.users WHERE id=$1::uuid`, userID).Scan(&name); err != nil {
		return fallback
	}
	if trimmed := strings.TrimSpace(name.String); trimmed != "" {
		return trimmed
	}
	return fallback
}

// ── Vouches ──────────────────────────────────────────────────────────────────

const vouchSelect = `
	SELECT v.id::text, v.subject_user_id::text, COALESCE(NULLIF(BTRIM(su.name),''),'A member'),
	       v.voucher_user_id::text, COALESCE(NULLIF(BTRIM(vu.name),''),'A friend'),
	       v.text, v.status, v.created_at, v.decided_at
	FROM matching.friend_vouches v
	JOIN user_management.users su ON su.id=v.subject_user_id
	JOIN user_management.users vu ON vu.id=v.voucher_user_id`

func scanVouch(sc datePlanScanner) (friendVouchView, error) {
	var v friendVouchView
	var created time.Time
	var decided sql.NullTime
	err := sc.Scan(&v.ID, &v.SubjectID, &v.SubjectName, &v.VoucherID, &v.VoucherName,
		&v.Text, &v.Status, &created, &decided)
	if err != nil {
		return v, err
	}
	v.CreatedAt = created.UTC().Format(time.RFC3339)
	if decided.Valid {
		v.DecidedAt = decided.Time.UTC().Format(time.RFC3339)
	}
	return v, nil
}

func (s *friendSocialService) writeVouch(ctx context.Context, voucherID, subjectID, text string) (friendVouchView, error) {
	if _, err := uuid.Parse(strings.TrimSpace(subjectID)); err != nil || subjectID == voucherID {
		return friendVouchView{}, errors.New("for_user_id must be another member's UUID")
	}
	clean, err := validateVouchText(text)
	if err != nil {
		return friendVouchView{}, err
	}
	tx, err := s.db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		return friendVouchView{}, err
	}
	defer func() { _ = tx.Rollback() }()
	var id string
	err = tx.QueryRowContext(ctx, `
		INSERT INTO matching.friend_vouches(subject_user_id, voucher_user_id, text)
		VALUES ($1::uuid, $2::uuid, $3) RETURNING id::text`, subjectID, voucherID, clean).Scan(&id)
	switch {
	case isPgException(err, "accepted friend"):
		return friendVouchView{}, errVouchNotFriend
	case isUniqueViolation(err):
		return friendVouchView{}, errVouchExists
	case err != nil:
		return friendVouchView{}, err
	}
	voucherName := memberName(ctx, tx, voucherID, "A friend")
	if err = enqueueNotificationTx(ctx, tx, subjectID, voucherID, "friend_vouch.received", "friend_plan", id,
		"friend-vouch:"+id+":received", voucherName+" vouched for you",
		"Approve it to show it on your profile.", "/friends/vouches",
		map[string]any{"vouch_id": id, "voucher_user_id": voucherID, "voucher_name": voucherName}, 5); err != nil {
		return friendVouchView{}, err
	}
	if err = publishFriendSocialEventTx(ctx, tx, "friend_vouch.written", "friend_vouch", id, subjectID, voucherID, nil); err != nil {
		return friendVouchView{}, err
	}
	view, err := scanVouch(tx.QueryRowContext(ctx, vouchSelect+` WHERE v.id=$1::uuid`, id))
	if err != nil {
		return friendVouchView{}, err
	}
	return view, tx.Commit()
}

func (s *friendSocialService) decideVouch(ctx context.Context, subjectID, vouchID, decision string) (friendVouchView, error) {
	status := map[string]string{"approve": "approved", "hide": "hidden"}[decision]
	if status == "" {
		return friendVouchView{}, errors.New("decision must be approve or hide")
	}
	tx, err := s.db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		return friendVouchView{}, err
	}
	defer func() { _ = tx.Rollback() }()
	current, err := scanVouch(tx.QueryRowContext(ctx, vouchSelect+` WHERE v.id=$1::uuid FOR UPDATE OF v`, vouchID))
	if errors.Is(err, sql.ErrNoRows) {
		return friendVouchView{}, errVouchNotFound
	}
	if err != nil {
		return friendVouchView{}, err
	}
	if current.SubjectID != subjectID {
		return friendVouchView{}, errVouchForbidden
	}
	if current.Status == "withdrawn" {
		return friendVouchView{}, errVouchNotFound
	}
	if _, err = tx.ExecContext(ctx, `UPDATE matching.friend_vouches SET status=$2 WHERE id=$1::uuid`, vouchID, status); err != nil {
		return friendVouchView{}, err
	}
	if status == "approved" && current.Status != "approved" {
		subjectName := memberName(ctx, tx, subjectID, "Your friend")
		if err = enqueueNotificationTx(ctx, tx, current.VoucherID, subjectID, "friend_vouch.approved", "friend_plan", vouchID,
			"friend-vouch:"+vouchID+":approved", subjectName+" approved your vouch",
			"It now shows on their profile.", "/friends/vouches",
			map[string]any{"vouch_id": vouchID}, 4); err != nil {
			return friendVouchView{}, err
		}
	}
	if err = publishFriendSocialEventTx(ctx, tx, "friend_vouch."+status, "friend_vouch", vouchID, subjectID, subjectID, nil); err != nil {
		return friendVouchView{}, err
	}
	view, err := scanVouch(tx.QueryRowContext(ctx, vouchSelect+` WHERE v.id=$1::uuid`, vouchID))
	if err != nil {
		return friendVouchView{}, err
	}
	return view, tx.Commit()
}

// withdrawVouch lets the voucher take a vouch back, or the subject remove it.
func (s *friendSocialService) withdrawVouch(ctx context.Context, actorID, vouchID string) error {
	tx, err := s.db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		return err
	}
	defer func() { _ = tx.Rollback() }()
	current, err := scanVouch(tx.QueryRowContext(ctx, vouchSelect+` WHERE v.id=$1::uuid FOR UPDATE OF v`, vouchID))
	if errors.Is(err, sql.ErrNoRows) {
		return errVouchNotFound
	}
	if err != nil {
		return err
	}
	if actorID != current.VoucherID && actorID != current.SubjectID {
		return errVouchForbidden
	}
	status := "withdrawn"
	if actorID == current.SubjectID {
		status = "hidden"
	}
	if _, err = tx.ExecContext(ctx, `UPDATE matching.friend_vouches SET status=$2 WHERE id=$1::uuid`, vouchID, status); err != nil {
		return err
	}
	if err = publishFriendSocialEventTx(ctx, tx, "friend_vouch."+status, "friend_vouch", vouchID, current.SubjectID, actorID, nil); err != nil {
		return err
	}
	return tx.Commit()
}

func (s *friendSocialService) listVouches(ctx context.Context, userID string) (aboutMe, written []friendVouchView, err error) {
	rows, err := s.db.QueryContext(ctx, vouchSelect+`
		WHERE (v.subject_user_id=$1::uuid OR v.voucher_user_id=$1::uuid) AND v.status<>'withdrawn'
		ORDER BY v.created_at DESC LIMIT 100`, userID)
	if err != nil {
		return nil, nil, err
	}
	defer rows.Close()
	aboutMe, written = []friendVouchView{}, []friendVouchView{}
	for rows.Next() {
		v, err := scanVouch(rows)
		if err != nil {
			return nil, nil, err
		}
		if v.SubjectID == userID {
			aboutMe = append(aboutMe, v)
		} else {
			written = append(written, v)
		}
	}
	return aboutMe, written, rows.Err()
}

// publicVouches returns approved vouches for a profile the viewer may see.
func (s *friendSocialService) publicVouches(ctx context.Context, viewerID, subjectID string) ([]publicVouchView, error) {
	if _, err := uuid.Parse(strings.TrimSpace(subjectID)); err != nil {
		return nil, errVouchNotFound
	}
	rows, err := s.db.QueryContext(ctx, `
		SELECT v.text, COALESCE(NULLIF(BTRIM(split_part(BTRIM(vu.name),' ',1)),''),'A friend'), v.decided_at
		FROM matching.friend_vouches v
		JOIN user_management.users vu ON vu.id=v.voucher_user_id
		WHERE v.subject_user_id=$2::uuid AND v.status='approved'
		  AND vu.is_active AND NOT vu.is_banned
		  AND NOT EXISTS (SELECT 1 FROM user_management.blocked_users b
		                  WHERE (b.user_id=$1::uuid AND b.blocked_user_id=$2::uuid)
		                     OR (b.user_id=$2::uuid AND b.blocked_user_id=$1::uuid))
		ORDER BY v.decided_at DESC LIMIT $3`, viewerID, subjectID, publicVouchLimit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []publicVouchView{}
	for rows.Next() {
		var v publicVouchView
		var at sql.NullTime
		if err := rows.Scan(&v.Text, &v.VoucherName, &at); err != nil {
			return nil, err
		}
		if at.Valid {
			v.ApprovedAt = at.Time.UTC().Format(time.RFC3339)
		}
		out = append(out, v)
	}
	return out, rows.Err()
}

// ── Intros ───────────────────────────────────────────────────────────────────

const introSelect = `
	SELECT i.id::text, i.introducer_user_id::text, COALESCE(NULLIF(BTRIM(iu.name),''),'A friend'),
	       i.first_user_id::text, COALESCE(NULLIF(BTRIM(fu.name),''),'A friend'),
	       i.second_user_id::text, COALESCE(NULLIF(BTRIM(su.name),''),'A friend'),
	       COALESCE(i.message,''), i.first_decision, i.second_decision, i.status,
	       COALESCE(i.match_id::text,''), i.expires_at, i.created_at
	FROM matching.friend_intros i
	JOIN user_management.users iu ON iu.id=i.introducer_user_id
	JOIN user_management.users fu ON fu.id=i.first_user_id
	JOIN user_management.users su ON su.id=i.second_user_id`

type introRow struct {
	ID, IntroducerID, IntroducerName       string
	FirstID, FirstName                     string
	SecondID, SecondName                   string
	Message, FirstDecision, SecondDecision string
	Status, MatchID                        string
	ExpiresAt, CreatedAt                   time.Time
}

func scanIntro(sc datePlanScanner) (introRow, error) {
	var r introRow
	err := sc.Scan(&r.ID, &r.IntroducerID, &r.IntroducerName, &r.FirstID, &r.FirstName,
		&r.SecondID, &r.SecondName, &r.Message, &r.FirstDecision, &r.SecondDecision,
		&r.Status, &r.MatchID, &r.ExpiresAt, &r.CreatedAt)
	return r, err
}

func (s *friendSocialService) preview(ctx context.Context, viewerID, userID string) (*introPreview, error) {
	profile, found, err := loadPublicProfile(ctx, s.db, viewerID, userID)
	if err != nil {
		return nil, err
	}
	if !found {
		return nil, nil
	}
	p := &introPreview{UserID: userID, Name: toString(profile["name"]), City: toString(profile["city"])}
	if verified, ok := profile["is_verified"].(bool); ok {
		p.IsVerified = verified
	}
	if age, ok := profile["age"].(int); ok {
		p.Age = &age
	}
	if photos, ok := profile["photoUrls"].([]string); ok {
		p.PhotoURLs = photos
	}
	if p.PhotoURLs == nil {
		p.PhotoURLs = []string{}
	}
	return p, nil
}

// viewFor renders an intro for a viewer: an invitee sees the other person's
// preview and their own decision; the introducer sees names and status only.
func (s *friendSocialService) viewFor(ctx context.Context, row introRow, viewerID string) (friendIntroView, error) {
	view := friendIntroView{
		ID: row.ID, IntroducerID: row.IntroducerID, IntroducerName: row.IntroducerName,
		Message: row.Message, Status: row.Status, MatchID: row.MatchID,
		ExpiresAt: row.ExpiresAt.UTC().Format(time.RFC3339), CreatedAt: row.CreatedAt.UTC().Format(time.RFC3339),
	}
	switch viewerID {
	case row.FirstID, row.SecondID:
		otherID := row.SecondID
		view.MyDecision = row.FirstDecision
		if viewerID == row.SecondID {
			otherID = row.FirstID
			view.MyDecision = row.SecondDecision
		}
		preferences, err := loadDatingPreferences(ctx, s.db, otherID, s.now())
		if err != nil {
			return view, err
		}
		own, err := loadDatingPreferences(ctx, s.db, viewerID, s.now())
		if err != nil {
			return view, err
		}
		var permission bool
		if err = s.db.QueryRowContext(ctx, `SELECT matching.introducer_can_introduce($1,$2) AND matching.introducer_can_introduce($1,$3)`, row.IntroducerID, viewerID, otherID).Scan(&permission); err != nil {
			return view, err
		}
		if !permission || !preferences.AllowFriendIntros || !own.AllowFriendIntros {
			view.Message = ""
			view.Status = "unavailable"
			view.MatchID = ""
			return view, nil
		}
		other, err := s.preview(ctx, viewerID, otherID)
		if err != nil {
			return view, err
		}
		if other == nil {
			other = &introPreview{UserID: otherID, Name: "A member", PhotoURLs: []string{}}
		}
		// A friend-only introduction uses this member's scoped permission,
		// never the broader sharing preferences for ordinary member friends.
		var kind string
		if err = s.db.QueryRowContext(ctx, `SELECT account_kind FROM user_management.users WHERE id=$1`, row.IntroducerID).Scan(&kind); err != nil {
			return view, err
		}
		if kind == "introducer" {
			if err = s.db.QueryRowContext(ctx, `SELECT share_photo,share_city FROM matching.introducer_consents WHERE introducer_user_id=$1 AND member_user_id=$2 AND revoked_at IS NULL AND status='active'`, row.IntroducerID, otherID).Scan(&preferences.IntroSharePhoto, &preferences.IntroShareCity); err != nil {
				return view, err
			}
		}
		if !preferences.IntroSharePhoto {
			other.PhotoURLs = []string{}
		}
		if !preferences.IntroShareCity {
			other.City = ""
		}
		view.Other = other
	default:
		// A friend gets a receipt, not a window into either person's dating.
		view.Status = "sent"
		view.MatchID = ""
		view.FirstName = row.FirstName
		view.SecondName = row.SecondName
	}
	return view, nil
}

func (s *friendSocialService) makeIntro(ctx context.Context, introducerID, firstID, secondID, message string) (friendIntroView, error) {
	for _, id := range []string{firstID, secondID} {
		if _, err := uuid.Parse(strings.TrimSpace(id)); err != nil || id == introducerID {
			return friendIntroView{}, errors.New("first_user_id and second_user_id must be two other members")
		}
	}
	if firstID == secondID {
		return friendIntroView{}, errors.New("choose two different friends")
	}
	clean, err := validateIntroMessage(message)
	if err != nil {
		return friendIntroView{}, err
	}
	var permitted bool
	if err = s.db.QueryRowContext(ctx, `SELECT matching.introducer_can_introduce($1,$2) AND matching.introducer_can_introduce($1,$3)`, introducerID, firstID, secondID).Scan(&permitted); err != nil {
		return friendIntroView{}, err
	}
	if !permitted {
		return friendIntroView{}, errIntroUnavailable
	}
	// Both must be published to each other, or the invitees would see nothing.
	for _, pair := range [][2]string{{firstID, secondID}, {secondID, firstID}} {
		p, err := s.preview(ctx, pair[0], pair[1])
		if err != nil {
			return friendIntroView{}, err
		}
		if p == nil {
			return friendIntroView{}, errIntroNotPublished
		}
	}
	tx, err := s.db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		return friendIntroView{}, err
	}
	defer func() { _ = tx.Rollback() }()
	var kind string
	if err = tx.QueryRowContext(ctx, `SELECT account_kind FROM user_management.users WHERE id=$1 FOR UPDATE`, introducerID).Scan(&kind); err != nil {
		return friendIntroView{}, err
	}
	if kind == "introducer" {
		var count int
		if err = tx.QueryRowContext(ctx, `SELECT count(*) FROM matching.friend_intros WHERE introducer_user_id=$1 AND created_at>NOW()-INTERVAL '1 day'`, introducerID).Scan(&count); err != nil {
			return friendIntroView{}, err
		}
		if count >= 5 {
			return friendIntroView{}, errIntroUnavailable
		}
	}
	var id string
	err = tx.QueryRowContext(ctx, `
		INSERT INTO matching.friend_intros(introducer_user_id, first_user_id, second_user_id, message)
		VALUES ($1::uuid, $2::uuid, $3::uuid, NULLIF($4,'')) RETURNING id::text`,
		introducerID, firstID, secondID, clean).Scan(&id)
	switch {
	case isPgException(err, "accepted friends of the introducer"):
		return friendIntroView{}, errIntroNotFriends
	case isPgException(err, "already matched"), isPgException(err, "preferences"), isPgException(err, "unavailable for this pair"):
		return friendIntroView{}, errIntroUnavailable
	case isUniqueViolation(err):
		return friendIntroView{}, errIntroAlreadyOpen
	case err != nil:
		return friendIntroView{}, err
	}
	introducerName := memberName(ctx, tx, introducerID, "A friend")
	for _, invitee := range []string{firstID, secondID} {
		if err = enqueueNotificationTx(ctx, tx, invitee, introducerID, "friend_intro.received", "friend_plan", id,
			"friend-intro:"+id+":received:"+invitee, introducerName+" wants to introduce you to someone",
			"Have a look and decide privately.", "/friends/intros",
			map[string]any{"intro_id": id, "introducer_user_id": introducerID, "introducer_name": introducerName}, 6); err != nil {
			return friendIntroView{}, err
		}
	}
	if err = insertSecurityEventTx(ctx, tx, "friend_intro.created", introducerID, "user", firstID, "friend_intro", id,
		map[string]any{"second_user_id": secondID}); err != nil {
		return friendIntroView{}, err
	}
	if err = publishFriendSocialEventTx(ctx, tx, "friend_intro.created", "friend_intro", id, introducerID, introducerID, nil); err != nil {
		return friendIntroView{}, err
	}
	row, err := scanIntro(tx.QueryRowContext(ctx, introSelect+` WHERE i.id=$1::uuid`, id))
	if err != nil {
		return friendIntroView{}, err
	}
	if err = tx.Commit(); err != nil {
		return friendIntroView{}, err
	}
	return s.viewFor(ctx, row, introducerID)
}

func (s *friendSocialService) decideIntro(ctx context.Context, actorID, introID, decision string) (friendIntroView, error) {
	if decision != "accept" && decision != "decline" {
		return friendIntroView{}, errors.New("decision must be accept or decline")
	}
	tx, err := s.db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		return friendIntroView{}, err
	}
	defer func() { _ = tx.Rollback() }()
	var introducerID string
	if err = tx.QueryRowContext(ctx, `SELECT introducer_user_id::text FROM matching.friend_intros WHERE id=$1::uuid`, introID).Scan(&introducerID); errors.Is(err, sql.ErrNoRows) {
		return friendIntroView{}, errIntroNotFound
	} else if err != nil {
		return friendIntroView{}, err
	}
	if _, err = tx.ExecContext(ctx, `SELECT id FROM user_management.users WHERE id=$1 FOR UPDATE`, introducerID); err != nil {
		return friendIntroView{}, err
	}
	row, err := scanIntro(tx.QueryRowContext(ctx, introSelect+` WHERE i.id=$1::uuid FOR UPDATE OF i`, introID))
	if errors.Is(err, sql.ErrNoRows) {
		return friendIntroView{}, errIntroNotFound
	}
	if err != nil {
		return friendIntroView{}, err
	}
	if actorID != row.FirstID && actorID != row.SecondID {
		return friendIntroView{}, errIntroForbidden
	}
	if row.Status != "open" || !row.ExpiresAt.After(s.now()) {
		return friendIntroView{}, errIntroNotOpen
	}
	if decision == "accept" {
		for _, pair := range [][2]string{{row.FirstID, row.SecondID}, {row.SecondID, row.FirstID}} {
			_, visible, err := loadPublicProfile(ctx, tx, pair[0], pair[1])
			if err != nil {
				return friendIntroView{}, err
			}
			if !visible {
				return friendIntroView{}, errIntroUnavailable
			}
		}
		for _, id := range []string{row.FirstID, row.SecondID} {
			preference, err := loadDatingPreferences(ctx, tx, id, s.now())
			if err != nil {
				return friendIntroView{}, err
			}
			if !preference.AllowFriendIntros {
				return friendIntroView{}, errIntroUnavailable
			}
		}
	}
	column := "first_decision"
	if actorID == row.SecondID {
		column = "second_decision"
	}
	value := "accepted"
	if decision == "decline" {
		value = "declined"
	}
	if _, err = tx.ExecContext(ctx, `UPDATE matching.friend_intros SET `+column+`=$2 WHERE id=$1::uuid`, introID, value); err != nil {
		return friendIntroView{}, err
	}
	if value == "declined" {
		if _, err = tx.ExecContext(ctx, `UPDATE matching.friend_intros SET status='declined' WHERE id=$1::uuid`, introID); err != nil {
			return friendIntroView{}, err
		}

	} else {
		var matchID sql.NullString
		if err = tx.QueryRowContext(ctx, `SELECT matching.friend_intro_match($1::uuid)::text`, introID).Scan(&matchID); err != nil {
			return friendIntroView{}, err
		}
	}
	if err = publishFriendSocialEventTx(ctx, tx, "friend_intro."+value, "friend_intro", introID, actorID, actorID, nil); err != nil {
		return friendIntroView{}, err
	}
	updated, err := scanIntro(tx.QueryRowContext(ctx, introSelect+` WHERE i.id=$1::uuid`, introID))
	if err != nil {
		return friendIntroView{}, err
	}
	if err = tx.Commit(); err != nil {
		return friendIntroView{}, err
	}
	return s.viewFor(ctx, updated, actorID)
}

func (s *friendSocialService) listIntros(ctx context.Context, userID string) (received, made []friendIntroView, err error) {
	rows, err := s.db.QueryContext(ctx, introSelect+`
		WHERE i.introducer_user_id=$1::uuid OR i.first_user_id=$1::uuid OR i.second_user_id=$1::uuid
		ORDER BY i.created_at DESC,i.id LIMIT 100`, userID)
	if err != nil {
		return nil, nil, err
	}
	defer rows.Close()
	var items []introRow
	for rows.Next() {
		r, err := scanIntro(rows)
		if err != nil {
			return nil, nil, err
		}
		items = append(items, r)
	}
	if err = rows.Err(); err != nil {
		return nil, nil, err
	}
	received, made = []friendIntroView{}, []friendIntroView{}
	for _, r := range items {
		view, err := s.viewFor(ctx, r, userID)
		if err != nil {
			return nil, nil, err
		}
		if r.IntroducerID == userID {
			made = append(made, view)
		} else {
			received = append(received, view)
		}
	}
	return received, made, nil
}

// sweep expires open intros past their deadline. Missing function = 0.
func (s *friendSocialService) sweep(ctx context.Context) (int, error) {
	var n int
	err := s.db.QueryRowContext(ctx, `
		SELECT CASE WHEN to_regproc('matching.friend_intro_sweep') IS NULL THEN 0
		            ELSE matching.friend_intro_sweep(NOW()) END`).Scan(&n)
	return n, err
}
