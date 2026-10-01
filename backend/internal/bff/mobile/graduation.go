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
	"github.com/jackc/pgx/v5/pgconn"
)

// Graduation (migration 094). When a matched pair becomes a couple they leave
// Connect together and the product celebrates it instead of hiding it. Either
// member of an active, unlocked match proposes; the other confirms or
// declines; the proposer can withdraw while the proposal is open. On confirm,
// inside one transaction, the match is marked graduated (never unmatched, so
// the chat stays), both members are paused from discovery, each opted-in
// member's friends are told, reward rows are recorded for billing, and the
// domain event and audit rows are written.

var (
	errGraduationNotFound      = errors.New("graduation not found")
	errGraduationAlreadyOpen   = errors.New("a graduation proposal is already open for this match")
	errGraduationMatchInactive = errors.New("graduation requires an active match")
	errGraduationAlreadyDone   = errors.New("this match has already graduated")
	errGraduationForbidden     = errors.New("only a member of this match can act on its graduation")
	errGraduationNotPartner    = errors.New("only the other member can confirm or decline")
	errGraduationNotProposer   = errors.New("only the proposer can withdraw")
	errGraduationStale         = errors.New("graduation proposal is no longer open")
	errDiscoveryPauseNotFound  = errors.New("discovery is not paused")
)

const (
	graduationMaxNoteRunes = 200
	discoveryPauseManual   = "manual"
	discoveryPauseGraduate = "graduated"
)

type graduationReward struct {
	UserID string         `json:"user_id"`
	Kind   string         `json:"kind"`
	Status string         `json:"status"`
	Detail map[string]any `json:"detail"`
}

type graduationView struct {
	ID                       string             `json:"id"`
	MatchID                  string             `json:"match_id"`
	ProposerUserID           string             `json:"proposer_user_id"`
	PartnerUserID            string             `json:"partner_user_id"`
	Status                   string             `json:"status"`
	Note                     string             `json:"note,omitempty"`
	ProposerShareWithFriends bool               `json:"proposer_share_with_friends"`
	PartnerShareWithFriends  bool               `json:"partner_share_with_friends"`
	DecidedAt                string             `json:"decided_at,omitempty"`
	DecidedByUserID          string             `json:"decided_by_user_id,omitempty"`
	CreatedAt                string             `json:"created_at"`
	UpdatedAt                string             `json:"updated_at"`
	LockVersion              int                `json:"lock_version"`
	ViewerRole               string             `json:"viewer_role"`
	OtherUserID              string             `json:"other_user_id"`
	OtherName                string             `json:"other_name"`
	ShareWithFriends         bool               `json:"share_with_friends"`
	NextAction               string             `json:"next_action"`
	FriendRecipients         int                `json:"friend_recipients,omitempty"`
	Rewards                  []graduationReward `json:"rewards"`
}

type discoveryPauseView struct {
	Reason    string `json:"reason"`
	PausedAt  string `json:"paused_at"`
	ResumedAt string `json:"resumed_at,omitempty"`
}

// graduationRow mirrors matching.match_graduations plus both members' names.
type graduationRow struct {
	ID, MatchID, ProposerID, PartnerID, Status string
	Note, DecidedBy                            sql.NullString
	ProposerShare, PartnerShare                bool
	DecidedAt                                  sql.NullTime
	CreatedAt, UpdatedAt                       time.Time
	LockVersion                                int
	ProposerName, PartnerName                  string
}

type graduationService struct {
	db  *sql.DB
	now func() time.Time
}

func newGraduationService(db *sql.DB) *graduationService {
	if db == nil {
		return nil
	}
	return &graduationService{db: db, now: func() time.Time { return time.Now().UTC() }}
}

// ── Validation ───────────────────────────────────────────────────────────────

// parseGraduationNote trims and bounds the optional note.
func parseGraduationNote(value any) (string, error) {
	note := strings.TrimSpace(toString(value))
	if note == "<nil>" {
		note = ""
	}
	if utf8.RuneCountInString(note) > graduationMaxNoteRunes {
		return "", errors.New("note must be 200 characters or fewer")
	}
	return note, nil
}

// parseGraduationDecision accepts confirm or decline, case-insensitively.
func parseGraduationDecision(value any) (string, error) {
	decision := strings.ToLower(strings.TrimSpace(toString(value)))
	if decision != "confirm" && decision != "decline" {
		return "", errors.New("decision must be confirm or decline")
	}
	return decision, nil
}

// parseDiscoveryPauseReason accepts only a manual pause from the member; the
// graduated reason is written by the graduation flow alone.
func parseDiscoveryPauseReason(value any) (string, error) {
	reason := strings.ToLower(strings.TrimSpace(toString(value)))
	if reason == "" || reason == "<nil>" {
		return discoveryPauseManual, nil
	}
	if reason != discoveryPauseManual {
		return "", errors.New("reason must be manual")
	}
	return reason, nil
}

// graduationNextAction is the server-authoritative next step for the viewer.
func graduationNextAction(status, viewerRole string) string {
	switch status {
	case "proposed":
		if viewerRole == "partner" {
			return "decide"
		}
		if viewerRole == "proposer" {
			return "await_decision"
		}
		return "none"
	case "confirmed":
		return "celebrate"
	default:
		return "propose"
	}
}

// ── Persistence ──────────────────────────────────────────────────────────────

const graduationSelect = `
	SELECT g.id::text, g.match_id::text, g.proposer_user_id::text, g.partner_user_id::text,
	       g.status, g.note, g.decided_by_user_id::text,
	       g.proposer_share_with_friends, g.partner_share_with_friends,
	       g.decided_at, g.created_at, g.updated_at, g.lock_version,
	       COALESCE(NULLIF(BTRIM(pu.name),''),'Your match'),
	       COALESCE(NULLIF(BTRIM(iu.name),''),'Your match')
	FROM matching.match_graduations g
	JOIN user_management.users pu ON pu.id=g.proposer_user_id
	JOIN user_management.users iu ON iu.id=g.partner_user_id`

func scanGraduationRow(sc datePlanScanner) (graduationRow, error) {
	var row graduationRow
	err := sc.Scan(
		&row.ID, &row.MatchID, &row.ProposerID, &row.PartnerID,
		&row.Status, &row.Note, &row.DecidedBy,
		&row.ProposerShare, &row.PartnerShare,
		&row.DecidedAt, &row.CreatedAt, &row.UpdatedAt, &row.LockVersion,
		&row.ProposerName, &row.PartnerName,
	)
	return row, err
}

func (s *graduationService) view(row graduationRow, rewards []graduationReward, viewerID string) graduationView {
	if rewards == nil {
		rewards = []graduationReward{}
	}
	view := graduationView{
		ID: row.ID, MatchID: row.MatchID, ProposerUserID: row.ProposerID, PartnerUserID: row.PartnerID,
		Status: row.Status, Note: row.Note.String,
		ProposerShareWithFriends: row.ProposerShare, PartnerShareWithFriends: row.PartnerShare,
		DecidedByUserID: row.DecidedBy.String,
		CreatedAt:       row.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:       row.UpdatedAt.UTC().Format(time.RFC3339),
		LockVersion:     row.LockVersion, Rewards: rewards,
	}
	if row.DecidedAt.Valid {
		view.DecidedAt = row.DecidedAt.Time.UTC().Format(time.RFC3339)
	}
	switch viewerID {
	case row.ProposerID:
		view.ViewerRole, view.OtherUserID, view.OtherName = "proposer", row.PartnerID, row.PartnerName
		view.ShareWithFriends = row.ProposerShare
	case row.PartnerID:
		view.ViewerRole, view.OtherUserID, view.OtherName = "partner", row.ProposerID, row.ProposerName
		view.ShareWithFriends = row.PartnerShare
	default:
		view.ViewerRole = "observer"
	}
	view.NextAction = graduationNextAction(row.Status, view.ViewerRole)
	return view
}

func (s *graduationService) loadRewards(ctx context.Context, q profileRowsReader, graduationID string) ([]graduationReward, error) {
	rows, err := q.QueryContext(ctx, `
		SELECT user_id::text, kind, status, detail::text
		FROM matching.graduation_rewards WHERE graduation_id=$1::uuid ORDER BY created_at, user_id`, graduationID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []graduationReward{}
	for rows.Next() {
		var r graduationReward
		var detail string
		if err := rows.Scan(&r.UserID, &r.Kind, &r.Status, &detail); err != nil {
			return nil, err
		}
		r.Detail = map[string]any{}
		_ = json.Unmarshal([]byte(detail), &r.Detail)
		out = append(out, r)
	}
	return out, rows.Err()
}

// matchState reads the pair, whether the match is active and whether it has
// already graduated.
func (s *graduationService) matchState(ctx context.Context, q profileRowReader, matchID string) (first, second string, active, graduated bool, err error) {
	var unmatched sql.NullTime
	var endedReason sql.NullString
	var s1, s2 string
	var b1, b2 bool
	err = q.QueryRowContext(ctx, `
		SELECT user_id_1::text, user_id_2::text, user_1_status, user_2_status,
		       user_1_blocked, user_2_blocked, unmatched_at, ended_reason
		FROM matching.matches WHERE id=$1::uuid`, matchID).
		Scan(&first, &second, &s1, &s2, &b1, &b2, &unmatched, &endedReason)
	if err != nil {
		return "", "", false, false, err
	}
	active = !unmatched.Valid && s1 == "active" && s2 == "active" && !b1 && !b2
	graduated = endedReason.Valid && endedReason.String == discoveryPauseGraduate
	return first, second, active, graduated, nil
}

// assertMember confirms the viewer belongs to the match.
func (s *graduationService) assertMember(ctx context.Context, matchID, userID string) error {
	if _, err := uuid.Parse(strings.TrimSpace(matchID)); err != nil {
		return errGraduationNotFound
	}
	first, second, _, _, err := s.matchState(ctx, s.db, matchID)
	if errors.Is(err, sql.ErrNoRows) {
		return errGraduationNotFound
	}
	if err != nil {
		return err
	}
	if userID != first && userID != second {
		return errGraduationForbidden
	}
	return nil
}

func (s *graduationService) fanOut(ctx context.Context, tx *sql.Tx, graduationID, actorID, status string, sides []string) (int, error) {
	var notified int
	err := tx.QueryRowContext(ctx, `
		SELECT matching.notify_graduation(
		  $1::uuid, $2::uuid, $3,
		  ARRAY(SELECT jsonb_array_elements_text($4::jsonb))::text[])`,
		graduationID, actorID, status, jsonStringList(sides)).Scan(&notified)
	return notified, err
}

// propose opens a graduation proposal and tells the other member.
func (s *graduationService) propose(ctx context.Context, matchID, proposerID, note string, share bool) (graduationView, error) {
	if _, err := uuid.Parse(strings.TrimSpace(matchID)); err != nil {
		return graduationView{}, errGraduationNotFound
	}
	tx, err := s.db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		return graduationView{}, err
	}
	defer func() { _ = tx.Rollback() }()

	first, second, active, graduated, err := s.matchState(ctx, tx, matchID)
	if errors.Is(err, sql.ErrNoRows) {
		return graduationView{}, errGraduationNotFound
	}
	if err != nil {
		return graduationView{}, err
	}
	if proposerID != first && proposerID != second {
		return graduationView{}, errGraduationForbidden
	}
	if graduated {
		return graduationView{}, errGraduationAlreadyDone
	}
	if !active {
		return graduationView{}, errGraduationMatchInactive
	}
	partner := second
	if proposerID == second {
		partner = first
	}
	var open int
	if err = tx.QueryRowContext(ctx, `
		SELECT COUNT(*) FROM matching.match_graduations
		WHERE match_id=$1::uuid AND status='proposed'`, matchID).Scan(&open); err != nil {
		return graduationView{}, err
	}
	if open > 0 {
		return graduationView{}, errGraduationAlreadyOpen
	}
	var graduationID string
	if err = tx.QueryRowContext(ctx, `
		INSERT INTO matching.match_graduations(
		  match_id, proposer_user_id, partner_user_id, note, proposer_share_with_friends
		) VALUES ($1::uuid,$2::uuid,$3::uuid,NULLIF($4,''),$5)
		RETURNING id::text`,
		matchID, proposerID, partner, note, share).Scan(&graduationID); err != nil {
		if isUniqueViolation(err) {
			return graduationView{}, errGraduationAlreadyOpen
		}
		return graduationView{}, err
	}
	if err = insertSecurityEventTx(ctx, tx, "graduation.proposed", proposerID, "user",
		partner, "graduation", graduationID,
		map[string]any{"match_id": matchID, "share_with_friends": share}); err != nil {
		return graduationView{}, err
	}
	notified, err := s.fanOut(ctx, tx, graduationID, proposerID, "proposed", nil)
	if err != nil {
		return graduationView{}, err
	}
	row, err := scanGraduationRow(tx.QueryRowContext(ctx, graduationSelect+` WHERE g.id=$1::uuid`, graduationID))
	if err != nil {
		return graduationView{}, err
	}
	if err = tx.Commit(); err != nil {
		return graduationView{}, err
	}
	view := s.view(row, nil, proposerID)
	view.FriendRecipients = notified
	return view, nil
}

// decide records the partner's confirm or decline. Confirming graduates the
// match, pauses both members from discovery, records rewards and tells each
// opted-in member's friends — all in the same transaction.
func (s *graduationService) decide(ctx context.Context, matchID, graduationID, actorID, decision string, share bool) (graduationView, error) {
	tx, err := s.db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		return graduationView{}, err
	}
	defer func() { _ = tx.Rollback() }()
	row, err := scanGraduationRow(tx.QueryRowContext(ctx,
		graduationSelect+` WHERE g.id=$1::uuid AND g.match_id=$2::uuid FOR UPDATE OF g`, graduationID, matchID))
	if errors.Is(err, sql.ErrNoRows) {
		return graduationView{}, errGraduationNotFound
	}
	if err != nil {
		return graduationView{}, err
	}
	if actorID != row.ProposerID && actorID != row.PartnerID {
		return graduationView{}, errGraduationForbidden
	}
	if actorID != row.PartnerID {
		return graduationView{}, errGraduationNotPartner
	}
	if row.Status != "proposed" {
		return graduationView{}, errGraduationStale
	}
	status := "confirmed"
	if decision == "decline" {
		status = "declined"
		share = false
	}
	if _, err = tx.ExecContext(ctx, `
		UPDATE matching.match_graduations
		SET status=$2, decided_at=NOW(), decided_by_user_id=$3::uuid, partner_share_with_friends=$4
		WHERE id=$1::uuid`, graduationID, status, actorID, share); err != nil {
		return graduationView{}, err
	}
	var sides []string
	if status == "confirmed" {
		if err = s.graduateMatch(ctx, tx, row, graduationID); err != nil {
			return graduationView{}, err
		}
		if row.ProposerShare {
			sides = append(sides, "proposer")
		}
		if share {
			sides = append(sides, "partner")
		}
	}
	if err = insertSecurityEventTx(ctx, tx, "graduation."+status, actorID, "user",
		row.ProposerID, "graduation", graduationID,
		map[string]any{"match_id": matchID, "share_with_friends": share}); err != nil {
		return graduationView{}, err
	}
	notified, err := s.fanOut(ctx, tx, graduationID, actorID, status, sides)
	if err != nil {
		return graduationView{}, err
	}
	updated, err := scanGraduationRow(tx.QueryRowContext(ctx, graduationSelect+` WHERE g.id=$1::uuid`, graduationID))
	if err != nil {
		return graduationView{}, err
	}
	rewards, err := s.loadRewards(ctx, tx, graduationID)
	if err != nil {
		return graduationView{}, err
	}
	if err = tx.Commit(); err != nil {
		return graduationView{}, err
	}
	view := s.view(updated, rewards, actorID)
	view.FriendRecipients = notified
	return view, nil
}

// graduateMatch applies the confirmed outcome to the match, discovery and
// rewards. The match keeps both statuses active so the chat stays open.
func (s *graduationService) graduateMatch(ctx context.Context, tx *sql.Tx, row graduationRow, graduationID string) error {
	result, err := tx.ExecContext(ctx, `
		UPDATE matching.matches
		SET ended_reason='graduated', lock_version=lock_version+1
		WHERE id=$1::uuid AND unmatched_at IS NULL
		  AND user_1_status='active' AND user_2_status='active'
		  AND NOT user_1_blocked AND NOT user_2_blocked`, row.MatchID)
	if err != nil {
		return err
	}
	if n, _ := result.RowsAffected(); n != 1 {
		return errGraduationMatchInactive
	}
	for _, member := range []string{row.ProposerID, row.PartnerID} {
		if err := s.pauseTx(ctx, tx, member, discoveryPauseGraduate); err != nil {
			return err
		}
		if err := insertSecurityEventTx(ctx, tx, "discovery.paused", member, "system",
			member, "discovery_pause", member,
			map[string]any{"reason": discoveryPauseGraduate, "graduation_id": graduationID}); err != nil {
			return err
		}
		// Billing has no subscription-pause primitive yet (billing_*.go only
		// cancels or ends). Record the reward as pending for a billing worker
		// rather than inventing billing behaviour here: a member with a live
		// subscription earns a pause, everyone else a referral credit.
		if _, err := tx.ExecContext(ctx, `
			INSERT INTO matching.graduation_rewards(graduation_id, user_id, kind, status, detail)
			SELECT $1::uuid, $2::uuid,
			       CASE WHEN EXISTS (
			         SELECT 1 FROM matching.billing_subscriptions_runtime b
			         WHERE b.user_id=$2::uuid AND b.status IN ('incomplete','active','past_due')
			       ) THEN 'subscription_pause' ELSE 'referral_credit' END,
			       'pending',
			       jsonb_build_object(
			         'note', 'Recorded at graduation; billing has no pause primitive yet, a billing worker applies this reward.',
			         'match_id', $3::text, 'recorded_at', NOW()
			       )
			ON CONFLICT (graduation_id, user_id) DO NOTHING`, graduationID, member, row.MatchID); err != nil {
			return err
		}
	}
	return nil
}

// withdraw closes an open proposal on the proposer's request.
func (s *graduationService) withdraw(ctx context.Context, matchID, graduationID, actorID string) (graduationView, error) {
	tx, err := s.db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		return graduationView{}, err
	}
	defer func() { _ = tx.Rollback() }()
	row, err := scanGraduationRow(tx.QueryRowContext(ctx,
		graduationSelect+` WHERE g.id=$1::uuid AND g.match_id=$2::uuid FOR UPDATE OF g`, graduationID, matchID))
	if errors.Is(err, sql.ErrNoRows) {
		return graduationView{}, errGraduationNotFound
	}
	if err != nil {
		return graduationView{}, err
	}
	if actorID != row.ProposerID && actorID != row.PartnerID {
		return graduationView{}, errGraduationForbidden
	}
	if actorID != row.ProposerID {
		return graduationView{}, errGraduationNotProposer
	}
	if row.Status != "proposed" {
		return graduationView{}, errGraduationStale
	}
	if _, err = tx.ExecContext(ctx, `
		UPDATE matching.match_graduations
		SET status='withdrawn', decided_at=NOW(), decided_by_user_id=$2::uuid
		WHERE id=$1::uuid`, graduationID, actorID); err != nil {
		return graduationView{}, err
	}
	if err = insertSecurityEventTx(ctx, tx, "graduation.withdrawn", actorID, "user",
		row.PartnerID, "graduation", graduationID, map[string]any{"match_id": matchID}); err != nil {
		return graduationView{}, err
	}
	if _, err = s.fanOut(ctx, tx, graduationID, actorID, "withdrawn", nil); err != nil {
		return graduationView{}, err
	}
	updated, err := scanGraduationRow(tx.QueryRowContext(ctx, graduationSelect+` WHERE g.id=$1::uuid`, graduationID))
	if err != nil {
		return graduationView{}, err
	}
	if err = tx.Commit(); err != nil {
		return graduationView{}, err
	}
	return s.view(updated, nil, actorID), nil
}

// matchGraduation returns the open or confirmed graduation (if any), recent
// history, and whether the viewer may propose.
func (s *graduationService) matchGraduation(ctx context.Context, matchID, viewerID string) (current *graduationView, history []graduationView, active, graduated bool, err error) {
	if _, err = uuid.Parse(strings.TrimSpace(matchID)); err != nil {
		return nil, nil, false, false, errGraduationNotFound
	}
	first, second, active, graduated, err := s.matchState(ctx, s.db, matchID)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil, false, false, errGraduationNotFound
	}
	if err != nil {
		return nil, nil, false, false, err
	}
	if viewerID != first && viewerID != second {
		return nil, nil, false, false, errGraduationForbidden
	}
	rows, err := s.db.QueryContext(ctx, graduationSelect+`
		WHERE g.match_id=$1::uuid ORDER BY g.created_at DESC LIMIT 20`, matchID)
	if err != nil {
		return nil, nil, false, false, err
	}
	defer rows.Close()
	history = []graduationView{}
	for rows.Next() {
		row, err := scanGraduationRow(rows)
		if err != nil {
			return nil, nil, false, false, err
		}
		var rewards []graduationReward
		if row.Status == "confirmed" {
			if rewards, err = s.loadRewards(ctx, s.db, row.ID); err != nil {
				return nil, nil, false, false, err
			}
		}
		view := s.view(row, rewards, viewerID)
		if current == nil && (row.Status == "proposed" || row.Status == "confirmed") {
			copyView := view
			current = &copyView
			continue
		}
		history = append(history, view)
	}
	if err = rows.Err(); err != nil {
		return nil, nil, false, false, err
	}
	return current, history, active, graduated, nil
}

// ── Discovery pauses ─────────────────────────────────────────────────────────

func (s *graduationService) pauseTx(ctx context.Context, tx *sql.Tx, userID, reason string) error {
	_, err := tx.ExecContext(ctx, `
		INSERT INTO user_management.discovery_pauses(user_id, reason, paused_at, resumed_at)
		VALUES ($1::uuid, $2, NOW(), NULL)
		ON CONFLICT (user_id) DO UPDATE
		SET reason=EXCLUDED.reason,
		    paused_at=CASE WHEN user_management.discovery_pauses.resumed_at IS NULL
		                   THEN user_management.discovery_pauses.paused_at ELSE NOW() END,
		    resumed_at=NULL`, userID, reason)
	return err
}

// pauseState reads the member's own pause. paused is false once resumed.
func (s *graduationService) pauseState(ctx context.Context, userID string) (paused bool, view *discoveryPauseView, err error) {
	var reason string
	var pausedAt time.Time
	var resumedAt sql.NullTime
	err = s.db.QueryRowContext(ctx, `
		SELECT reason, paused_at, resumed_at FROM user_management.discovery_pauses
		WHERE user_id=$1::uuid`, userID).Scan(&reason, &pausedAt, &resumedAt)
	if errors.Is(err, sql.ErrNoRows) {
		return false, nil, nil
	}
	if err != nil {
		return false, nil, err
	}
	view = &discoveryPauseView{Reason: reason, PausedAt: pausedAt.UTC().Format(time.RFC3339)}
	if resumedAt.Valid {
		view.ResumedAt = resumedAt.Time.UTC().Format(time.RFC3339)
	}
	return !resumedAt.Valid, view, nil
}

// pause hides the member from discovery on their own request.
func (s *graduationService) pause(ctx context.Context, userID, reason string) (*discoveryPauseView, error) {
	tx, err := s.db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		return nil, err
	}
	defer func() { _ = tx.Rollback() }()
	if err = s.pauseTx(ctx, tx, userID, reason); err != nil {
		return nil, err
	}
	if err = insertSecurityEventTx(ctx, tx, "discovery.paused", userID, "user",
		userID, "discovery_pause", userID, map[string]any{"reason": reason}); err != nil {
		return nil, err
	}
	if _, err = tx.ExecContext(ctx, `
		SELECT platform.publish_domain_event(
		  'discovery.paused', 1, 'discovery.pause', $1::text, 'mobile-bff.graduation',
		  $1::uuid, $1::uuid, NULL, NULL,
		  'discovery:paused:' || $1::text || ':' || to_char(NOW(), 'YYYYMMDDHH24MISSUS'),
		  jsonb_build_object('reason', $2::text), '{}'::jsonb, NOW())`, userID, reason); err != nil {
		return nil, err
	}
	if err = tx.Commit(); err != nil {
		return nil, err
	}
	_, view, err := s.pauseState(ctx, userID)
	return view, err
}

// resume clears the member's pause so they return to discovery.
func (s *graduationService) resume(ctx context.Context, userID string) (*discoveryPauseView, error) {
	tx, err := s.db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		return nil, err
	}
	defer func() { _ = tx.Rollback() }()
	var reason string
	err = tx.QueryRowContext(ctx, `
		UPDATE user_management.discovery_pauses SET resumed_at=NOW()
		WHERE user_id=$1::uuid AND resumed_at IS NULL
		RETURNING reason`, userID).Scan(&reason)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, errDiscoveryPauseNotFound
	}
	if err != nil {
		return nil, err
	}
	if err = insertSecurityEventTx(ctx, tx, "discovery.resumed", userID, "user",
		userID, "discovery_pause", userID, map[string]any{"reason": reason}); err != nil {
		return nil, err
	}
	if _, err = tx.ExecContext(ctx, `
		SELECT platform.publish_domain_event(
		  'discovery.resumed', 1, 'discovery.pause', $1::text, 'mobile-bff.graduation',
		  $1::uuid, $1::uuid, NULL, NULL,
		  'discovery:resumed:' || $1::text || ':' || to_char(NOW(), 'YYYYMMDDHH24MISSUS'),
		  jsonb_build_object('reason', $2::text), '{}'::jsonb, NOW())`, userID, reason); err != nil {
		return nil, err
	}
	if err = tx.Commit(); err != nil {
		return nil, err
	}
	_, view, err := s.pauseState(ctx, userID)
	return view, err
}

// activePauses returns the members among ids who are currently paused.
// A missing table (migration 094 not applied) reads as nobody paused.
func activeDiscoveryPauses(ctx context.Context, db profileRowsReader, ids []string) (map[string]discoveryPauseView, error) {
	out := map[string]discoveryPauseView{}
	if db == nil || len(ids) == 0 {
		return out, nil
	}
	rows, err := db.QueryContext(ctx, `
		SELECT user_id::text, reason, paused_at FROM user_management.discovery_pauses
		WHERE resumed_at IS NULL AND user_id=ANY($1::uuid[])`, ids)
	if err != nil {
		if isUndefinedTable(err) {
			return out, nil
		}
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		var id, reason string
		var pausedAt time.Time
		if err := rows.Scan(&id, &reason, &pausedAt); err != nil {
			return nil, err
		}
		out[id] = discoveryPauseView{Reason: reason, PausedAt: pausedAt.UTC().Format(time.RFC3339)}
	}
	return out, rows.Err()
}

// filterPausedDiscovery removes paused members from the deck and, when the
// viewer is paused, empties the deck and explains why (discovery_paused).
func filterPausedDiscovery(ctx context.Context, db profileRowsReader, viewerID string, response map[string]any) error {
	ids := []string{}
	if _, err := uuid.Parse(strings.TrimSpace(viewerID)); err == nil {
		ids = append(ids, viewerID)
	}
	seen := map[string]bool{}
	for _, key := range []string{"candidates", "spotlight_profiles"} {
		rows, _ := response[key].([]any)
		for _, raw := range rows {
			row, _ := raw.(map[string]any)
			id := candidateIdentity(row)
			if _, err := uuid.Parse(id); err == nil && !seen[id] {
				ids = append(ids, id)
				seen[id] = true
			}
		}
	}
	paused, err := activeDiscoveryPauses(ctx, db, ids)
	if err != nil {
		return err
	}
	if own, ok := paused[viewerID]; ok {
		for _, key := range []string{"candidates", "spotlight_profiles"} {
			if _, exists := response[key]; exists {
				response[key] = []any{}
			}
		}
		response["discovery_paused"] = map[string]any{"reason": own.Reason, "paused_at": own.PausedAt}
		return nil
	}
	removed := 0
	for _, key := range []string{"candidates", "spotlight_profiles"} {
		rows, exists := response[key].([]any)
		if !exists {
			continue
		}
		kept := make([]any, 0, len(rows))
		for _, raw := range rows {
			row, ok := raw.(map[string]any)
			if ok {
				if _, hidden := paused[candidateIdentity(row)]; hidden {
					removed++
					continue
				}
			}
			kept = append(kept, raw)
		}
		response[key] = kept
	}
	if removed > 0 {
		response["pause_filter"] = map[string]any{"applied": true, "filtered": removed}
	}
	return nil
}

func isUndefinedTable(err error) bool {
	if err == nil {
		return false
	}
	var pgErr *pgconn.PgError
	if errors.As(err, &pgErr) {
		return pgErr.Code == "42P01"
	}
	return strings.Contains(err.Error(), "42P01")
}
