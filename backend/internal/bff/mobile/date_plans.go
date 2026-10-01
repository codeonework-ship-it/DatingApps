package mobile

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgconn"
)

// Date plans (migration 091). A matched pair turns a conversation into a
// concrete plan: a time window, a venue category and area, an optional note.
// Every status a member sets is fanned out, inside the same transaction, to
// that member's explicitly selected trusted contacts, through
// matching.notify_date_plan_status(). The other member of the match is always
// told about decisions.

var allowedDatePlanVenues = map[string]bool{
	"coffee": true, "meal": true, "drinks": true, "walk": true,
	"activity": true, "event": true, "video_call": true, "other": true,
}

var (
	errDatePlanNotFound      = errors.New("date plan not found")
	errDatePlanAlreadyOpen   = errors.New("a date plan is already open for this match")
	errDatePlanMatchInactive = errors.New("date plans require an active match")
	errDatePlanForbidden     = errors.New("only a member of this match can act on its plan")
	errDatePlanNotInvitee    = errors.New("only the invited member can accept or decline")
	errDatePlanStale         = errors.New("date plan is no longer open")
	errDatePlanTooEarly      = errors.New("check in after the plan starts")
	errDatePlanDebriefEarly  = errors.New("the debrief opens once the plan starts")
)

const (
	datePlanMaxNoteRunes   = 280
	datePlanMaxVenueRunes  = 120
	datePlanMaxReasonRunes = 200
	datePlanMaxGroups      = 10
	datePlanMaxWindow      = 12 * time.Hour
	datePlanMaxHorizon     = 90 * 24 * time.Hour
)

type datePlanCheckin struct {
	UserID string `json:"user_id"`
	Status string `json:"status"`
	At     string `json:"at"`
	Note   string `json:"note,omitempty"`
}

type datePlanView struct {
	AtmospherePreferences    []string          `json:"atmosphere_preferences"`
	AccessibilityPreferences []string          `json:"accessibility_preferences"`
	PendingProposerID        string            `json:"pending_proposer_id"`
	BudgetPreference         string            `json:"budget_preference"`
	MutualSecondYes          bool              `json:"mutual_second_yes"`
	ID                       string            `json:"id"`
	MatchID                  string            `json:"match_id"`
	ProposerUserID           string            `json:"proposer_user_id"`
	InviteeUserID            string            `json:"invitee_user_id"`
	Status                   string            `json:"status"`
	WindowStart              string            `json:"window_start"`
	WindowEnd                string            `json:"window_end"`
	VenueCategory            string            `json:"venue_category"`
	VenueName                string            `json:"venue_name,omitempty"`
	VenueArea                string            `json:"venue_area,omitempty"`
	Note                     string            `json:"note,omitempty"`
	ProposerGroupIDs         []string          `json:"proposer_group_ids"`
	InviteeGroupIDs          []string          `json:"invitee_group_ids"`
	CheckinDueAt             string            `json:"checkin_due_at"`
	DecidedAt                string            `json:"decided_at,omitempty"`
	CancelledAt              string            `json:"cancelled_at,omitempty"`
	CancelledByUserID        string            `json:"cancelled_by_user_id,omitempty"`
	CancelReason             string            `json:"cancel_reason,omitempty"`
	CreatedAt                string            `json:"created_at"`
	UpdatedAt                string            `json:"updated_at"`
	LockVersion              int               `json:"lock_version"`
	ViewerRole               string            `json:"viewer_role"`
	PartnerUserID            string            `json:"partner_user_id"`
	PartnerName              string            `json:"partner_name"`
	Checkins                 []datePlanCheckin `json:"checkins"`
	NextAction               string            `json:"next_action"`
	FriendRecipients         int               `json:"friend_recipients,omitempty"`
	Debrief                  *datePlanDebrief  `json:"debrief,omitempty"`
	PartnerDebriefed         bool              `json:"partner_debriefed"`
	ResolvedStatus           string            `json:"resolved_status,omitempty"`
}

// datePlanDebrief is one member's private post-date answers. The other member
// only ever learns that a debrief exists (PartnerDebriefed).
type datePlanDebrief struct {
	ShareMutualInterest bool   `json:"share_mutual_interest"`
	UserID              string `json:"user_id"`
	Happened            bool   `json:"happened"`
	WouldMeetAgain      *bool  `json:"would_meet_again,omitempty"`
	FeltSafe            *bool  `json:"felt_safe,omitempty"`
	Note                string `json:"note,omitempty"`
	CreatedAt           string `json:"created_at"`
}

type datePlanProposal struct {
	SourceBlogResponseID                            string
	AtmospherePreferences, AccessibilityPreferences []string
	SharedWindow                                    *datingWindow
	BudgetPreference                                string
	MatchID                                         string
	ProposerID                                      string
	WindowStart                                     time.Time
	WindowEnd                                       time.Time
	VenueCategory                                   string
	VenueName                                       string
	VenueArea                                       string
	Note                                            string
	GroupIDs                                        []string
}

type datePlanShareGroup struct {
	ID   string `json:"id"`
	Name string `json:"name"`
}

// datePlanRow mirrors matching.match_date_plans plus the partner's name.
type datePlanRow struct {
	AtmospherePreferences, AccessibilityPreferences            []string
	PendingProposerID, BudgetPreference                        string
	ID, MatchID, ProposerID, InviteeID, Status, VenueCategory  string
	WindowStart, WindowEnd, CheckinDueAt, CreatedAt, UpdatedAt time.Time
	VenueName, VenueArea, Note, CancelledBy, CancelReason      sql.NullString
	DecidedAt, CancelledAt                                     sql.NullTime
	ProposerGroupIDs, InviteeGroupIDs                          []string
	LockVersion                                                int
	ProposerName, InviteeName                                  string
}

type datePlanService struct {
	db  *sql.DB
	now func() time.Time
}

func newDatePlanService(db *sql.DB) *datePlanService {
	if db == nil {
		return nil
	}
	return &datePlanService{db: db, now: func() time.Time { return time.Now().UTC() }}
}

// ── Validation ───────────────────────────────────────────────────────────────

func parseDatePlanProposal(payload map[string]any, matchID, proposerID string, now time.Time) (datePlanProposal, error) {
	p := datePlanProposal{MatchID: strings.TrimSpace(matchID), ProposerID: strings.TrimSpace(proposerID)}
	if _, err := uuid.Parse(p.MatchID); err != nil {
		return p, errors.New("match id must be a valid UUID")
	}
	p.SourceBlogResponseID = strings.TrimSpace(toString(payload["source_blog_response_id"]))
	if p.SourceBlogResponseID != "" {
		if _, err := uuid.Parse(p.SourceBlogResponseID); err != nil {
			return p, errors.New("invalid chapter response")
		}
	}
	start, err := parseDatePlanTime(payload["window_start"])
	if err != nil {
		return p, fmt.Errorf("window_start %w", err)
	}
	end, err := parseDatePlanTime(payload["window_end"])
	if err != nil {
		return p, fmt.Errorf("window_end %w", err)
	}
	if !end.After(start) {
		return p, errors.New("window_end must be after window_start")
	}
	if end.Sub(start) > datePlanMaxWindow {
		return p, errors.New("a plan window can be at most 12 hours")
	}
	if start.Before(now.Add(-time.Hour)) {
		return p, errors.New("window_start must be in the future")
	}
	if start.After(now.Add(datePlanMaxHorizon)) {
		return p, errors.New("window_start must be within the next 90 days")
	}
	p.WindowStart, p.WindowEnd = start, end
	p.VenueCategory = strings.ToLower(strings.TrimSpace(toString(payload["venue_category"])))
	if !allowedDatePlanVenues[p.VenueCategory] {
		return p, errors.New("venue_category must be coffee, meal, drinks, walk, activity, event, video_call, or other")
	}
	p.VenueName = strings.TrimSpace(toString(payload["venue_name"]))
	p.VenueArea = strings.TrimSpace(toString(payload["venue_area"]))
	p.Note = strings.TrimSpace(toString(payload["note"]))
	if utf8.RuneCountInString(p.VenueName) > datePlanMaxVenueRunes ||
		utf8.RuneCountInString(p.VenueArea) > datePlanMaxVenueRunes {
		return p, errors.New("venue_name and venue_area must be 120 characters or fewer")
	}
	if utf8.RuneCountInString(p.Note) > datePlanMaxNoteRunes {
		return p, errors.New("note must be 280 characters or fewer")
	}
	groups, err := parseDatePlanGroupIDs(payload["group_ids"])
	if err != nil {
		return p, err
	}
	p.BudgetPreference = strings.TrimSpace(toString(payload["budget_preference"]))
	if p.BudgetPreference == "" {
		p.BudgetPreference = "flexible"
	}
	if !datingChoice(p.BudgetPreference, "flexible", "free", "modest", "treat") {
		return p, errors.New("Choose a supported budget preference")
	}
	p.AtmospherePreferences, err = parsePlanChoices(payload["atmosphere_preferences"], datePlanAtmospheres, 3, "atmosphere")
	if err != nil {
		return p, err
	}
	p.AccessibilityPreferences, err = parsePlanChoices(payload["accessibility_preferences"], datePlanAccessibility, 6, "accessibility")
	if err != nil {
		return p, err
	}
	if _, present := payload["atmosphere_preferences"]; !present {
		p.AtmospherePreferences = nil
	}
	if _, present := payload["accessibility_preferences"]; !present {
		p.AccessibilityPreferences = nil
	}
	p.SharedWindow, err = parsePlanSharedWindow(payload["shared_window"], start, end)
	if err != nil {
		return p, err
	}
	p.GroupIDs = groups
	return p, nil
}

func parseDatePlanTime(value any) (time.Time, error) {
	raw := strings.TrimSpace(toString(value))
	if raw == "" {
		return time.Time{}, errors.New("is required (RFC 3339)")
	}
	parsed, err := time.Parse(time.RFC3339, raw)
	if err != nil {
		return time.Time{}, errors.New("must be an RFC 3339 timestamp")
	}
	return parsed.UTC(), nil
}

func parseDatePlanGroupIDs(value any) ([]string, error) {
	out := []string{}
	if value == nil {
		return out, nil
	}
	items, ok := value.([]any)
	if !ok {
		return nil, errors.New("group_ids must be a list of group UUIDs")
	}
	seen := map[string]bool{}
	for _, item := range items {
		id := strings.TrimSpace(toString(item))
		if _, err := uuid.Parse(id); err != nil {
			return nil, errors.New("group_ids must be a list of group UUIDs")
		}
		if !seen[id] {
			seen[id] = true
			out = append(out, id)
		}
	}
	if len(out) > datePlanMaxGroups {
		return nil, errors.New("a plan can be shared with at most 10 groups")
	}
	return out, nil
}

// datePlanNextAction is the server-authoritative next step for the viewer:
// decide → upcoming → checkin → debrief → none, then propose once resolved.
func datePlanNextAction(status, viewerRole string, checkins []datePlanCheckin, viewerID string, now, windowStart time.Time, debriefed bool) string {
	switch status {
	case "proposed":
		if viewerRole == "invitee" {
			return "decide"
		}
		return "await_decision"
	case "accepted":
		if now.Before(windowStart) {
			return "upcoming"
		}
		checkedIn := false
		for _, c := range checkins {
			if c.UserID == viewerID {
				checkedIn = true
			}
		}
		if !checkedIn {
			return "checkin"
		}
		if !debriefed {
			return "debrief"
		}
		return "none"
	default:
		return "propose"
	}
}

// ── Persistence ──────────────────────────────────────────────────────────────

const datePlanSelect = `
	SELECT p.id::text, p.match_id::text, p.proposer_user_id::text, p.invitee_user_id::text,
	       p.status, p.venue_category, p.window_start, p.window_end, p.checkin_due_at,
	       p.created_at, p.updated_at, p.venue_name, p.venue_area, p.note,
	       p.cancelled_by_user_id::text, p.cancel_reason, p.decided_at, p.cancelled_at,
	       array_to_json(p.proposer_group_ids)::text, array_to_json(p.invitee_group_ids)::text, p.lock_version,
	       COALESCE(NULLIF(BTRIM(pu.name),''),'Your match'),
	       COALESCE(NULLIF(BTRIM(iu.name),''),'Your match'), COALESCE(p.pending_proposer_id,p.proposer_user_id)::text,p.budget_preference, array_to_json(p.atmosphere_preferences)::text, array_to_json(p.accessibility_preferences)::text
	FROM matching.match_date_plans p
	JOIN user_management.users pu ON pu.id=p.proposer_user_id
	JOIN user_management.users iu ON iu.id=p.invitee_user_id`

type datePlanScanner interface {
	Scan(dest ...any) error
}

func scanDatePlanRow(sc datePlanScanner) (datePlanRow, error) {
	var row datePlanRow
	var proposerGroups, inviteeGroups, atmospheres, accessibility string
	err := sc.Scan(
		&row.ID, &row.MatchID, &row.ProposerID, &row.InviteeID,
		&row.Status, &row.VenueCategory, &row.WindowStart, &row.WindowEnd, &row.CheckinDueAt,
		&row.CreatedAt, &row.UpdatedAt, &row.VenueName, &row.VenueArea, &row.Note,
		&row.CancelledBy, &row.CancelReason, &row.DecidedAt, &row.CancelledAt,
		&proposerGroups, &inviteeGroups, &row.LockVersion,
		&row.ProposerName, &row.InviteeName, &row.PendingProposerID, &row.BudgetPreference, &atmospheres, &accessibility,
	)
	if err != nil {
		return row, err
	}
	row.AtmospherePreferences = decodeJSONStringList(atmospheres)
	row.AccessibilityPreferences = decodeJSONStringList(accessibility)
	row.ProposerGroupIDs = decodeJSONStringList(proposerGroups)
	row.InviteeGroupIDs = decodeJSONStringList(inviteeGroups)
	return row, nil
}

// decodeJSONStringList reads a JSON array of strings; anything else is empty.
func decodeJSONStringList(raw string) []string {
	out := []string{}
	if strings.TrimSpace(raw) == "" {
		return out
	}
	_ = json.Unmarshal([]byte(raw), &out)
	if out == nil {
		out = []string{}
	}
	return out
}

// jsonStringList encodes a list for a `$n::jsonb` parameter that SQL turns
// into an array with ARRAY(SELECT jsonb_array_elements_text($n::jsonb)).
func jsonStringList(items []string) string {
	if items == nil {
		items = []string{}
	}
	encoded, _ := json.Marshal(items)
	return string(encoded)
}

func (s *datePlanService) loadCheckins(ctx context.Context, q interface {
	QueryContext(context.Context, string, ...any) (*sql.Rows, error)
}, planID string) ([]datePlanCheckin, error) {
	rows, err := q.QueryContext(ctx, `
		SELECT user_id::text, checkin_status, checkin_at, COALESCE(checkin_note,'')
		FROM matching.match_date_plan_participants
		WHERE plan_id=$1::uuid AND checkin_status IS NOT NULL
		ORDER BY checkin_at`, planID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []datePlanCheckin{}
	for rows.Next() {
		var c datePlanCheckin
		var at time.Time
		if err := rows.Scan(&c.UserID, &c.Status, &at, &c.Note); err != nil {
			return nil, err
		}
		c.At = at.UTC().Format(time.RFC3339)
		out = append(out, c)
	}
	return out, rows.Err()
}

func (s *datePlanService) loadDebriefs(ctx context.Context, q interface {
	QueryContext(context.Context, string, ...any) (*sql.Rows, error)
}, planID string) (map[string]datePlanDebrief, error) {
	rows, err := q.QueryContext(ctx, `
		SELECT user_id::text, happened, would_meet_again, felt_safe, COALESCE(note,''), created_at, share_mutual_interest
		FROM matching.match_date_plan_debriefs WHERE plan_id=$1::uuid`, planID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := map[string]datePlanDebrief{}
	for rows.Next() {
		var d datePlanDebrief
		var again, safe sql.NullBool
		var at time.Time
		if err := rows.Scan(&d.UserID, &d.Happened, &again, &safe, &d.Note, &at, &d.ShareMutualInterest); err != nil {
			return nil, err
		}
		if again.Valid {
			v := again.Bool
			d.WouldMeetAgain = &v
		}
		if safe.Valid {
			v := safe.Bool
			d.FeltSafe = &v
		}
		d.CreatedAt = at.UTC().Format(time.RFC3339)
		out[d.UserID] = d
	}
	return out, rows.Err()
}

func (s *datePlanService) view(row datePlanRow, checkins []datePlanCheckin, viewerID string) datePlanView {
	return s.viewWithDebriefs(row, checkins, nil, viewerID)
}

func (s *datePlanService) viewWithDebriefs(row datePlanRow, checkins []datePlanCheckin, debriefs map[string]datePlanDebrief, viewerID string) datePlanView {
	view := datePlanView{
		AtmospherePreferences: row.AtmospherePreferences, AccessibilityPreferences: row.AccessibilityPreferences,
		PendingProposerID: row.PendingProposerID, BudgetPreference: row.BudgetPreference,
		ID: row.ID, MatchID: row.MatchID, ProposerUserID: row.ProposerID, InviteeUserID: row.InviteeID,
		Status: row.Status, WindowStart: row.WindowStart.UTC().Format(time.RFC3339),
		WindowEnd: row.WindowEnd.UTC().Format(time.RFC3339), VenueCategory: row.VenueCategory,
		VenueName: row.VenueName.String, VenueArea: row.VenueArea.String, Note: row.Note.String,
		ProposerGroupIDs: row.ProposerGroupIDs, InviteeGroupIDs: row.InviteeGroupIDs,
		CheckinDueAt:      row.CheckinDueAt.UTC().Format(time.RFC3339),
		CancelledByUserID: row.CancelledBy.String, CancelReason: row.CancelReason.String,
		CreatedAt: row.CreatedAt.UTC().Format(time.RFC3339), UpdatedAt: row.UpdatedAt.UTC().Format(time.RFC3339),
		LockVersion: row.LockVersion, Checkins: checkins,
	}
	if row.DecidedAt.Valid {
		view.DecidedAt = row.DecidedAt.Time.UTC().Format(time.RFC3339)
	}
	if row.CancelledAt.Valid {
		view.CancelledAt = row.CancelledAt.Time.UTC().Format(time.RFC3339)
	}
	switch viewerID {
	case row.ProposerID:
		view.ViewerRole, view.PartnerUserID, view.PartnerName = "proposer", row.InviteeID, row.InviteeName
	case row.InviteeID:
		view.ViewerRole, view.PartnerUserID, view.PartnerName = "invitee", row.ProposerID, row.ProposerName
	default:
		view.ViewerRole = "observer"
	}
	if own, ok := debriefs[viewerID]; ok {
		copyOwn := own
		view.Debrief = &copyOwn
	}
	if _, ok := debriefs[view.PartnerUserID]; ok {
		view.PartnerDebriefed = true
	}
	if view.ViewerRole != "observer" {
		a, b := debriefs[row.ProposerID], debriefs[row.InviteeID]
		view.MutualSecondYes = mutualSecondYes(a, b)
	}
	view.NextAction = datePlanNextAction(
		row.Status, view.ViewerRole, checkins, viewerID, s.now(), row.WindowStart, view.Debrief != nil,
	)
	if row.Status == "proposed" && row.PendingProposerID != "" && view.ViewerRole != "observer" {
		view.NextAction = "decide"
		if row.PendingProposerID == viewerID {
			view.NextAction = "await_decision"
		}
	}
	return view
}

func mutualSecondYes(a, b datePlanDebrief) bool {
	return a.Happened && b.Happened && a.ShareMutualInterest && b.ShareMutualInterest && a.WouldMeetAgain != nil && *a.WouldMeetAgain && b.WouldMeetAgain != nil && *b.WouldMeetAgain
}

func (s *datePlanService) matchMembers(ctx context.Context, q interface {
	QueryRowContext(context.Context, string, ...any) *sql.Row
}, matchID string) (first, second string, active bool, err error) {
	var unmatched sql.NullTime
	var s1, s2 string
	var b1, b2 bool
	err = q.QueryRowContext(ctx, `
		SELECT user_id_1::text, user_id_2::text, user_1_status, user_2_status,
		       user_1_blocked, user_2_blocked, unmatched_at
		FROM matching.matches WHERE id=$1::uuid`, matchID).
		Scan(&first, &second, &s1, &s2, &b1, &b2, &unmatched)
	if err != nil {
		return "", "", false, err
	}
	active = !unmatched.Valid && s1 == "active" && s2 == "active" && !b1 && !b2
	return first, second, active, nil
}

func (s *datePlanService) appendEvent(ctx context.Context, tx *sql.Tx, planID, actorID, eventType, from, to, reason string, metadata map[string]any) error {
	if metadata == nil {
		metadata = map[string]any{}
	}
	encoded, err := json.Marshal(metadata)
	if err != nil {
		return err
	}
	_, err = tx.ExecContext(ctx, `
		INSERT INTO matching.match_date_plan_events(
		  plan_id, actor_user_id, event_type, from_status, to_status, reason, metadata
		) VALUES ($1::uuid, NULLIF($2,'')::uuid, $3, NULLIF($4,''), NULLIF($5,''), NULLIF($6,''), $7::jsonb)`,
		planID, actorID, eventType, from, to, reason, string(encoded))
	return err
}

func (s *datePlanService) fanOut(ctx context.Context, tx *sql.Tx, planID, actorID, status string, sides []string, notifyPartner bool) (int, error) {
	var notified int
	err := tx.QueryRowContext(ctx, `
		SELECT matching.notify_date_plan_status(
		  $1::uuid, $2::uuid, $3,
		  ARRAY(SELECT jsonb_array_elements_text($4::jsonb))::text[], $5)`,
		planID, actorID, status, jsonStringList(sides), notifyPartner).Scan(&notified)
	return notified, err
}

// assertMember confirms the viewer belongs to the match.
func (s *datePlanService) assertMember(ctx context.Context, matchID, userID string) error {
	if _, err := uuid.Parse(strings.TrimSpace(matchID)); err != nil {
		return errDatePlanNotFound
	}
	first, second, _, err := s.matchMembers(ctx, s.db, matchID)
	if errors.Is(err, sql.ErrNoRows) {
		return errDatePlanNotFound
	}
	if err != nil {
		return err
	}
	if userID != first && userID != second {
		return errDatePlanForbidden
	}
	return nil
}

// propose creates the plan, its participant rows and the proposer-side fan-out.
func (s *datePlanService) propose(ctx context.Context, p datePlanProposal) (datePlanView, error) {
	tx, err := s.db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		return datePlanView{}, err
	}
	defer func() { _ = tx.Rollback() }()

	first, second, active, err := s.matchMembers(ctx, tx, p.MatchID)
	if errors.Is(err, sql.ErrNoRows) {
		return datePlanView{}, errDatePlanNotFound
	}
	if err != nil {
		return datePlanView{}, err
	}
	if p.ProposerID != first && p.ProposerID != second {
		return datePlanView{}, errDatePlanForbidden
	}
	if !active {
		return datePlanView{}, errDatePlanMatchInactive
	}
	invitee := second
	if p.ProposerID == second {
		invitee = first
	}
	if _, err = activeDatingPair(ctx, tx, p.MatchID, p.ProposerID, false); err != nil {
		return datePlanView{}, err
	}
	if p.SourceBlogResponseID != "" {
		v, e := readBlogResponse(ctx, tx, p.ProposerID, p.SourceBlogResponseID)
		if e != nil || !v.Revealed || v.MatchID != p.MatchID || v.PartnerID != invitee {
			return datePlanView{}, errDatePlanForbidden
		}
	}
	if err = validatePlanSharedWindow(ctx, tx, p, invitee, s.now()); err != nil {
		return datePlanView{}, err
	}
	var open int
	if err = tx.QueryRowContext(ctx, `
		SELECT COUNT(*) FROM matching.match_date_plans
		WHERE match_id=$1::uuid AND status IN ('proposed','accepted')`, p.MatchID).Scan(&open); err != nil {
		return datePlanView{}, err
	}
	if open > 0 {
		return datePlanView{}, errDatePlanAlreadyOpen
	}
	var planID string
	if err = tx.QueryRowContext(ctx, `
		INSERT INTO matching.match_date_plans(
		  match_id, proposer_user_id, invitee_user_id, window_start, window_end,
		  venue_category, venue_name, venue_area, note, proposer_group_ids, checkin_due_at
		) VALUES ($1::uuid,$2::uuid,$3::uuid,$4::timestamptz,$5::timestamptz,$6,
		          NULLIF($7,''),NULLIF($8,''),NULLIF($9,''),
		          ARRAY(SELECT jsonb_array_elements_text($10::jsonb))::uuid[],
		          $5::timestamptz + INTERVAL '1 hour')
		RETURNING id::text`,
		p.MatchID, p.ProposerID, invitee, p.WindowStart, p.WindowEnd, p.VenueCategory,
		p.VenueName, p.VenueArea, p.Note, jsonStringList(p.GroupIDs)).Scan(&planID); err != nil {
		if isUniqueViolation(err) {
			return datePlanView{}, errDatePlanAlreadyOpen
		}
		return datePlanView{}, err
	}
	if _, err = tx.ExecContext(ctx, `
		INSERT INTO matching.match_date_plan_participants(plan_id, user_id)
		VALUES ($1::uuid,$2::uuid),($1::uuid,$3::uuid)`, planID, p.ProposerID, invitee); err != nil {
		return datePlanView{}, err
	}
	if p.SourceBlogResponseID != "" {
		if _, err = tx.ExecContext(ctx, `UPDATE matching.match_date_plans SET source_blog_response_id=$2 WHERE id=$1`, planID, p.SourceBlogResponseID); err != nil {
			return datePlanView{}, err
		}
	}
	if p.BudgetPreference == "" {
		p.BudgetPreference = "flexible"
	}
	if _, err = tx.ExecContext(ctx, `UPDATE matching.match_date_plans SET budget_preference=$2,atmosphere_preferences=ARRAY(SELECT jsonb_array_elements_text($3::jsonb)),accessibility_preferences=ARRAY(SELECT jsonb_array_elements_text($4::jsonb)) WHERE id=$1::uuid`, planID, p.BudgetPreference, jsonStringList(p.AtmospherePreferences), jsonStringList(p.AccessibilityPreferences)); err != nil {
		return datePlanView{}, err
	}
	if err = s.appendEvent(ctx, tx, planID, p.ProposerID, "proposed", "", "proposed", "",
		map[string]any{"group_count": len(p.GroupIDs)}); err != nil {
		return datePlanView{}, err
	}
	if err = insertSecurityEventTx(ctx, tx, "date_plan.proposed", p.ProposerID, "user",
		invitee, "date_plan", planID, map[string]any{"match_id": p.MatchID}); err != nil {
		return datePlanView{}, err
	}
	notified, err := s.fanOut(ctx, tx, planID, p.ProposerID, "proposed", []string{"proposer"}, true)
	if err != nil {
		return datePlanView{}, err
	}
	row, err := scanDatePlanRow(tx.QueryRowContext(ctx, datePlanSelect+` WHERE p.id=$1::uuid`, planID))
	if err != nil {
		return datePlanView{}, err
	}
	if err = tx.Commit(); err != nil {
		return datePlanView{}, err
	}
	view := s.view(row, []datePlanCheckin{}, p.ProposerID)
	view.FriendRecipients = notified
	return view, nil
}

// decide records the invitee's accept or decline. On accept the invitee's own
// friends and chosen groups also hear about the plan.
func (s *datePlanService) decide(ctx context.Context, matchID, planID, actorID, decision string, groupIDs []string, versions ...int) (datePlanView, error) {
	if decision != "accept" && decision != "decline" {
		return datePlanView{}, errors.New("decision must be accept or decline")
	}
	tx, err := s.db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		return datePlanView{}, err
	}
	defer func() { _ = tx.Rollback() }()
	row, err := scanDatePlanRow(tx.QueryRowContext(ctx,
		datePlanSelect+` WHERE p.id=$1::uuid AND p.match_id=$2::uuid FOR UPDATE OF p`, planID, matchID))
	if errors.Is(err, sql.ErrNoRows) {
		return datePlanView{}, errDatePlanNotFound
	}
	if err != nil {
		return datePlanView{}, err
	}
	if actorID != row.ProposerID && actorID != row.InviteeID {
		return datePlanView{}, errDatePlanForbidden
	}
	pending := row.PendingProposerID
	if pending == "" {
		pending = row.ProposerID
	}
	if actorID == pending {
		return datePlanView{}, errDatePlanNotInvitee
	}
	if (len(versions) > 0 && versions[0] != row.LockVersion) || (len(versions) == 0 && row.LockVersion > 0) {
		return datePlanView{}, errDatingConflict
	}
	if _, err = activeDatingPair(ctx, tx, matchID, actorID, false); err != nil {
		return datePlanView{}, err
	}
	if row.Status != "proposed" {
		return datePlanView{}, errDatePlanStale
	}
	status := "accepted"
	sides := []string{"proposer", "invitee"}
	if decision == "decline" {
		status = "declined"
		sides = nil
	}
	if _, err = tx.ExecContext(ctx, `
		UPDATE matching.match_date_plans
		SET status=$2, decided_at=NOW(),
		    invitee_group_ids=CASE WHEN $4::uuid=invitee_user_id AND $5=0 THEN ARRAY(SELECT jsonb_array_elements_text($3::jsonb))::uuid[] ELSE invitee_group_ids END,
		    resolved_at=CASE WHEN $2='declined' THEN NOW() ELSE resolved_at END
		WHERE id=$1::uuid`, planID, status, jsonStringList(groupIDs), actorID, row.LockVersion); err != nil {
		return datePlanView{}, err
	}
	if err = s.appendEvent(ctx, tx, planID, actorID, status, "proposed", status, "",
		map[string]any{"group_count": len(groupIDs)}); err != nil {
		return datePlanView{}, err
	}
	if err = insertSecurityEventTx(ctx, tx, "date_plan."+status, actorID, "user",
		row.ProposerID, "date_plan", planID, map[string]any{"match_id": matchID}); err != nil {
		return datePlanView{}, err
	}
	notified, err := s.fanOut(ctx, tx, planID, actorID, status, sides, true)
	if err != nil {
		return datePlanView{}, err
	}
	updated, err := scanDatePlanRow(tx.QueryRowContext(ctx, datePlanSelect+` WHERE p.id=$1::uuid`, planID))
	if err != nil {
		return datePlanView{}, err
	}
	if err = tx.Commit(); err != nil {
		return datePlanView{}, err
	}
	view := s.view(updated, []datePlanCheckin{}, actorID)
	view.FriendRecipients = notified
	return view, nil
}

// cancel withdraws an open plan. Friends who were told about it are told
// again; a never-accepted proposal only reaches the proposer's circle.
func (s *datePlanService) cancel(ctx context.Context, matchID, planID, actorID, reason string) (datePlanView, error) {
	if utf8.RuneCountInString(reason) > datePlanMaxReasonRunes {
		return datePlanView{}, errors.New("reason must be 200 characters or fewer")
	}
	tx, err := s.db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		return datePlanView{}, err
	}
	defer func() { _ = tx.Rollback() }()
	row, err := scanDatePlanRow(tx.QueryRowContext(ctx,
		datePlanSelect+` WHERE p.id=$1::uuid AND p.match_id=$2::uuid FOR UPDATE OF p`, planID, matchID))
	if errors.Is(err, sql.ErrNoRows) {
		return datePlanView{}, errDatePlanNotFound
	}
	if err != nil {
		return datePlanView{}, err
	}
	if actorID != row.ProposerID && actorID != row.InviteeID {
		return datePlanView{}, errDatePlanForbidden
	}
	if row.Status != "proposed" && row.Status != "accepted" {
		return datePlanView{}, errDatePlanStale
	}
	sides := []string{"proposer"}
	if row.Status == "accepted" {
		sides = []string{"proposer", "invitee"}
	}
	if _, err = tx.ExecContext(ctx, `
		UPDATE matching.match_date_plans
		SET status='cancelled', cancelled_at=NOW(), cancelled_by_user_id=$2::uuid,
		    cancel_reason=NULLIF($3,''), resolved_at=NOW()
		WHERE id=$1::uuid`, planID, actorID, reason); err != nil {
		return datePlanView{}, err
	}
	if err = s.appendEvent(ctx, tx, planID, actorID, "cancelled", row.Status, "cancelled", reason, nil); err != nil {
		return datePlanView{}, err
	}
	partner := row.InviteeID
	if actorID == row.InviteeID {
		partner = row.ProposerID
	}
	if err = insertSecurityEventTx(ctx, tx, "date_plan.cancelled", actorID, "user",
		partner, "date_plan", planID, map[string]any{"match_id": matchID, "from_status": row.Status}); err != nil {
		return datePlanView{}, err
	}
	notified, err := s.fanOut(ctx, tx, planID, actorID, "cancelled", sides, true)
	if err != nil {
		return datePlanView{}, err
	}
	updated, err := scanDatePlanRow(tx.QueryRowContext(ctx, datePlanSelect+` WHERE p.id=$1::uuid`, planID))
	if err != nil {
		return datePlanView{}, err
	}
	checkins, err := s.loadCheckins(ctx, tx, planID)
	if err != nil {
		return datePlanView{}, err
	}
	if err = tx.Commit(); err != nil {
		return datePlanView{}, err
	}
	view := s.view(updated, checkins, actorID)
	view.FriendRecipients = notified
	return view, nil
}

// checkin records "safe" or "need_help" for the acting member and tells that
// member's circle. Need-help goes out as a safety notification at top priority.
func (s *datePlanService) checkin(ctx context.Context, matchID, planID, actorID, status, note string) (datePlanView, error) {
	if status != "safe" && status != "need_help" {
		return datePlanView{}, errors.New("status must be safe or need_help")
	}
	if utf8.RuneCountInString(note) > datePlanMaxReasonRunes {
		return datePlanView{}, errors.New("note must be 200 characters or fewer")
	}
	tx, err := s.db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		return datePlanView{}, err
	}
	defer func() { _ = tx.Rollback() }()
	row, err := scanDatePlanRow(tx.QueryRowContext(ctx,
		datePlanSelect+` WHERE p.id=$1::uuid AND p.match_id=$2::uuid FOR UPDATE OF p`, planID, matchID))
	if errors.Is(err, sql.ErrNoRows) {
		return datePlanView{}, errDatePlanNotFound
	}
	if err != nil {
		return datePlanView{}, err
	}
	if actorID != row.ProposerID && actorID != row.InviteeID {
		return datePlanView{}, errDatePlanForbidden
	}
	if row.Status != "accepted" {
		return datePlanView{}, errDatePlanStale
	}
	if s.now().Before(row.WindowStart) {
		return datePlanView{}, errDatePlanTooEarly
	}
	var previous sql.NullString
	if err = tx.QueryRowContext(ctx, `
		SELECT checkin_status FROM matching.match_date_plan_participants
		WHERE plan_id=$1::uuid AND user_id=$2::uuid FOR UPDATE`, planID, actorID).Scan(&previous); err != nil {
		return datePlanView{}, err
	}
	if _, err = tx.ExecContext(ctx, `
		UPDATE matching.match_date_plan_participants
		SET checkin_status=$3, checkin_at=NOW(), checkin_note=NULLIF($4,'')
		WHERE plan_id=$1::uuid AND user_id=$2::uuid`, planID, actorID, status, note); err != nil {
		return datePlanView{}, err
	}
	side := "proposer"
	if actorID == row.InviteeID {
		side = "invitee"
	}
	notified := 0
	// A repeated identical check-in is a no-op for the circle.
	if !previous.Valid || previous.String != status {
		if err = s.appendEvent(ctx, tx, planID, actorID, "checkin_"+status, "accepted", "accepted", note, nil); err != nil {
			return datePlanView{}, err
		}
		if err = insertSecurityEventTx(ctx, tx, "date_plan.checkin_"+status, actorID, "user",
			"", "date_plan", planID, map[string]any{"match_id": matchID}); err != nil {
			return datePlanView{}, err
		}
		if notified, err = s.fanOut(ctx, tx, planID, actorID, status, []string{side}, status == "safe"); err != nil {
			return datePlanView{}, err
		}
	}
	checkins, err := s.loadCheckins(ctx, tx, planID)
	if err != nil {
		return datePlanView{}, err
	}
	debriefs, err := s.loadDebriefs(ctx, tx, planID)
	if err != nil {
		return datePlanView{}, err
	}
	if err = tx.Commit(); err != nil {
		return datePlanView{}, err
	}
	view := s.viewWithDebriefs(row, checkins, debriefs, actorID)
	view.FriendRecipients = notified
	return view, nil
}

// debrief records the member's private answers and resolves the plan once
// both members have answered. Answers can be changed until the plan resolves.
func (s *datePlanService) debrief(ctx context.Context, matchID, planID, actorID string, happened bool, wouldMeetAgain, feltSafe *bool, note string, shareMutual ...bool) (datePlanView, error) {
	if utf8.RuneCountInString(note) > datePlanMaxNoteRunes {
		return datePlanView{}, errors.New("note must be 280 characters or fewer")
	}
	tx, err := s.db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		return datePlanView{}, err
	}
	defer func() { _ = tx.Rollback() }()
	row, err := scanDatePlanRow(tx.QueryRowContext(ctx,
		datePlanSelect+` WHERE p.id=$1::uuid AND p.match_id=$2::uuid FOR UPDATE OF p`, planID, matchID))
	if errors.Is(err, sql.ErrNoRows) {
		return datePlanView{}, errDatePlanNotFound
	}
	if err != nil {
		return datePlanView{}, err
	}
	if actorID != row.ProposerID && actorID != row.InviteeID {
		return datePlanView{}, errDatePlanForbidden
	}
	if row.Status != "accepted" {
		return datePlanView{}, errDatePlanStale
	}
	if s.now().Before(row.WindowStart) {
		return datePlanView{}, errDatePlanDebriefEarly
	}
	if _, err = activeDatingPair(ctx, tx, matchID, actorID, false); err != nil {
		return datePlanView{}, err
	}
	share := len(shareMutual) > 0 && shareMutual[0] && happened && wouldMeetAgain != nil && *wouldMeetAgain
	if !happened {
		wouldMeetAgain = nil
		feltSafe = nil
	}
	var again, safe any
	if wouldMeetAgain != nil {
		again = *wouldMeetAgain
	}
	if feltSafe != nil {
		safe = *feltSafe
	}
	if _, err = tx.ExecContext(ctx, `
		INSERT INTO matching.match_date_plan_debriefs(
		  plan_id, user_id, happened, would_meet_again, felt_safe, note, share_mutual_interest
		) VALUES ($1::uuid, $2::uuid, $3, $4, $5, NULLIF($6,''),$7)
		ON CONFLICT (plan_id, user_id) DO UPDATE
		SET happened=EXCLUDED.happened, would_meet_again=EXCLUDED.would_meet_again,
		    felt_safe=EXCLUDED.felt_safe, note=EXCLUDED.note,share_mutual_interest=EXCLUDED.share_mutual_interest`,
		planID, actorID, happened, again, safe, note, share); err != nil {
		return datePlanView{}, err
	}
	partner := row.InviteeID
	if actorID == row.InviteeID {
		partner = row.ProposerID
	}
	if err = s.appendEvent(ctx, tx, planID, actorID, "debrief_given", "accepted", "accepted", "",
		map[string]any{"happened": happened}); err != nil {
		return datePlanView{}, err
	}
	if feltSafe != nil && !*feltSafe {
		// A member who did not feel safe is a trust-and-safety signal about
		// the other member, recorded for operators without auto-reporting.
		if err = insertSecurityEventTx(ctx, tx, "date_plan.felt_unsafe", actorID, "user",
			partner, "date_plan", planID, map[string]any{"match_id": matchID}); err != nil {
			return datePlanView{}, err
		}
	}
	var resolved sql.NullString
	if err = tx.QueryRowContext(ctx, `
		SELECT matching.resolve_date_plan_from_debriefs($1::uuid, $2::uuid)`, planID, actorID).Scan(&resolved); err != nil {
		return datePlanView{}, err
	}
	updated, err := scanDatePlanRow(tx.QueryRowContext(ctx, datePlanSelect+` WHERE p.id=$1::uuid`, planID))
	if err != nil {
		return datePlanView{}, err
	}
	checkins, err := s.loadCheckins(ctx, tx, planID)
	if err != nil {
		return datePlanView{}, err
	}
	debriefs, err := s.loadDebriefs(ctx, tx, planID)
	if err != nil {
		return datePlanView{}, err
	}
	if mutualSecondYes(debriefs[row.ProposerID], debriefs[row.InviteeID]) {
		for _, recipient := range []string{row.ProposerID, row.InviteeID} {
			if err = enqueueNotificationTx(ctx, tx, recipient, "", "date_plan.second_yes", "message", planID, "second-yes:"+planID+":"+recipient, "A second yes, from both of you", "You both chose to share that you would like to meet again.", "/plans", map[string]any{"plan_id": planID, "match_id": matchID}, 5); err != nil {
				return datePlanView{}, err
			}
		}
	}
	if err = tx.Commit(); err != nil {
		return datePlanView{}, err
	}
	view := s.viewWithDebriefs(updated, checkins, debriefs, actorID)
	view.ResolvedStatus = resolved.String
	return view, nil
}

// matchPlans returns the open plan (if any), recent history and the groups the
// viewer can share with.
func (s *datePlanService) matchPlans(ctx context.Context, matchID, viewerID string) (*datePlanView, []datePlanView, []datePlanShareGroup, error) {
	first, second, _, err := s.matchMembers(ctx, s.db, matchID)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil, nil, errDatePlanNotFound
	}
	if err != nil {
		return nil, nil, nil, err
	}
	if viewerID != first && viewerID != second {
		return nil, nil, nil, errDatePlanForbidden
	}
	rows, err := s.db.QueryContext(ctx, datePlanSelect+`
		WHERE p.match_id=$1::uuid ORDER BY p.created_at DESC LIMIT 20`, matchID)
	if err != nil {
		return nil, nil, nil, err
	}
	defer rows.Close()
	var open *datePlanView
	history := []datePlanView{}
	for rows.Next() {
		row, err := scanDatePlanRow(rows)
		if err != nil {
			return nil, nil, nil, err
		}
		checkins, err := s.loadCheckins(ctx, s.db, row.ID)
		if err != nil {
			return nil, nil, nil, err
		}
		debriefs, err := s.loadDebriefs(ctx, s.db, row.ID)
		if err != nil {
			return nil, nil, nil, err
		}
		view := s.viewWithDebriefs(row, checkins, debriefs, viewerID)
		if open == nil && (row.Status == "proposed" || row.Status == "accepted") {
			copyView := view
			open = &copyView
			continue
		}
		history = append(history, view)
	}
	if err = rows.Err(); err != nil {
		return nil, nil, nil, err
	}
	return open, history, []datePlanShareGroup{}, nil // Legacy group sharing is retired.
}

func (s *datePlanService) shareGroups(ctx context.Context, userID string) ([]datePlanShareGroup, error) {
	rows, err := s.db.QueryContext(ctx, `
		SELECT g.id::text, g.name
		FROM matching.community_group_members gm
		JOIN matching.community_groups g ON g.id=gm.group_id
		WHERE gm.user_id=$1::uuid AND gm.status='active'
		ORDER BY g.name LIMIT 50`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []datePlanShareGroup{}
	for rows.Next() {
		var g datePlanShareGroup
		if err := rows.Scan(&g.ID, &g.Name); err != nil {
			return nil, err
		}
		out = append(out, g)
	}
	return out, rows.Err()
}

// memberPlans lists the viewer's own plans across matches.
func (s *datePlanService) memberPlans(ctx context.Context, userID, scope string, limit int) ([]datePlanView, error) {
	filter := `AND (p.status IN ('proposed','accepted') OR p.window_end >= NOW() - INTERVAL '1 day')`
	if scope == "all" {
		filter = ""
	}
	rows, err := s.db.QueryContext(ctx, datePlanSelect+`
		WHERE (p.proposer_user_id=$1::uuid OR p.invitee_user_id=$1::uuid) `+filter+`
		ORDER BY CASE WHEN p.status IN ('proposed','accepted') THEN 0 ELSE 1 END, p.window_start
		LIMIT $2`, userID, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []datePlanView{}
	for rows.Next() {
		row, err := scanDatePlanRow(rows)
		if err != nil {
			return nil, err
		}
		checkins, err := s.loadCheckins(ctx, s.db, row.ID)
		if err != nil {
			return nil, err
		}
		debriefs, err := s.loadDebriefs(ctx, s.db, row.ID)
		if err != nil {
			return nil, err
		}
		out = append(out, s.viewWithDebriefs(row, checkins, debriefs, userID))
	}
	return out, rows.Err()
}

type friendPlanView struct {
	PlanID        string            `json:"plan_id"`
	FriendUserID  string            `json:"friend_user_id"`
	FriendName    string            `json:"friend_name"`
	PartnerName   string            `json:"partner_name"`
	Status        string            `json:"status"`
	LatestUpdate  string            `json:"latest_update"`
	Title         string            `json:"title"`
	Description   string            `json:"description"`
	WindowStart   string            `json:"window_start"`
	WindowEnd     string            `json:"window_end"`
	VenueCategory string            `json:"venue_category"`
	VenueArea     string            `json:"venue_area,omitempty"`
	Via           string            `json:"via"`
	UpdatedAt     string            `json:"updated_at"`
	Checkins      []datePlanCheckin `json:"checkins"`
}

// friendPlans lists the plans the viewer was told about, newest update first.
// It reads the feed rows written by the fan-out, so it reflects exactly what
// the viewer was entitled to see at the time.
func (s *datePlanService) friendPlans(ctx context.Context, viewerID string, limit int) ([]friendPlanView, error) {
	rows, err := s.db.QueryContext(ctx, `
		SELECT DISTINCT ON (f.metadata->>'plan_id')
		       f.metadata->>'plan_id', f.friend_user_id::text,
		       COALESCE(f.metadata->>'friend_name',''), COALESCE(f.metadata->>'partner_name',''),
		       p.status, f.activity_type, f.title, COALESCE(f.description,''),
		       p.window_start, p.window_end, p.venue_category, COALESCE(p.venue_area,''),
		       COALESCE(f.metadata->>'via','friend'), f.created_at
		FROM matching.friend_activity_feed f
		JOIN matching.match_date_plans p ON p.id=(f.metadata->>'plan_id')::uuid
		WHERE f.user_id=$1::uuid AND f.activity_type LIKE 'date_plan_%'
 AND EXISTS (SELECT 1 FROM matching.date_plan_trusted_recipients(p.id,f.friend_user_id,
 CASE WHEN f.friend_user_id=p.proposer_user_id THEN p.invitee_user_id ELSE p.proposer_user_id END) r
 WHERE r.recipient_user_id=$1::uuid)
		ORDER BY f.metadata->>'plan_id', f.created_at DESC`, viewerID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []friendPlanView{}
	for rows.Next() {
		var v friendPlanView
		var start, end, updated time.Time
		if err := rows.Scan(&v.PlanID, &v.FriendUserID, &v.FriendName, &v.PartnerName, &v.Status,
			&v.LatestUpdate, &v.Title, &v.Description, &start, &end, &v.VenueCategory, &v.VenueArea,
			&v.Via, &updated); err != nil {
			return nil, err
		}
		v.LatestUpdate = strings.TrimPrefix(v.LatestUpdate, "date_plan_")
		v.WindowStart = start.UTC().Format(time.RFC3339)
		v.WindowEnd = end.UTC().Format(time.RFC3339)
		v.UpdatedAt = updated.UTC().Format(time.RFC3339)
		checkins, err := s.loadCheckins(ctx, s.db, v.PlanID)
		if err != nil {
			return nil, err
		}
		// A friend only sees their friend's own check-in, never the date's.
		own := []datePlanCheckin{}
		for _, c := range checkins {
			if c.UserID == v.FriendUserID {
				own = append(own, c)
			}
		}
		v.Checkins = own
		out = append(out, v)
	}
	if err = rows.Err(); err != nil {
		return nil, err
	}
	// Newest update first, bounded.
	for i := 1; i < len(out); i++ {
		for j := i; j > 0 && out[j].UpdatedAt > out[j-1].UpdatedAt; j-- {
			out[j], out[j-1] = out[j-1], out[j]
		}
	}
	if len(out) > limit {
		out = out[:limit]
	}
	return out, nil
}

// sweep expires stale proposals, sends check-in reminders and escalations,
// and (once migration 092 is applied) debrief reminders.
func (s *datePlanService) sweep(ctx context.Context) (expired, reminders, escalations int, err error) {
	if _, err = s.db.ExecContext(ctx, `SELECT matching.expire_dating_availability()`); err != nil {
		return
	}
	err = s.db.QueryRowContext(ctx, `SELECT * FROM matching.date_plan_checkin_sweep(NOW())`).
		Scan(&expired, &reminders, &escalations)
	if err != nil {
		return expired, reminders, escalations, err
	}
	var debriefReminders int
	if err := s.db.QueryRowContext(ctx, `
		SELECT CASE WHEN to_regproc('matching.date_plan_debrief_sweep') IS NULL THEN 0
		            ELSE matching.date_plan_debrief_sweep(NOW()) END`).Scan(&debriefReminders); err == nil {
		reminders += debriefReminders
	}
	return expired, reminders, escalations, nil
}

func isUniqueViolation(err error) bool {
	if err == nil {
		return false
	}
	var pgErr *pgconn.PgError
	if errors.As(err, &pgErr) {
		return pgErr.Code == "23505"
	}
	msg := strings.ToLower(err.Error())
	return strings.Contains(msg, "23505") || strings.Contains(msg, "duplicate key")
}
