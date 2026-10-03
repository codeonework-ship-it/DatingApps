package mobile

import (
	"context"
	"crypto/sha256"
	"database/sql"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/mail"
	"regexp"
	"strconv"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
)

// Support ticket system (migration 126). Members raise queries from the app
// (/v1/support/...), signed-out visitors from the website contact form
// (/v1/support/contact) and the support team works them from the operator
// console (/v1/admin/support/..., support_admin.go).
//
// Every ticket carries SLA targets derived from its priority and category,
// an append-only event trail and messages that are either public replies or
// internal notes. Members only ever see public messages on their own tickets.
// documents/SUPPORT_TICKET_SYSTEM_2026-10-01.md describes the workflow.

const (
	supportSubjectMinRunes     = 4
	supportSubjectMaxRunes     = 120
	supportBodyMaxRunes        = 5000
	supportRatingCommentRunes  = 1000
	supportMaxAttachmentsPerMs = 5
	supportMaxAttachmentsPerTk = 20
	supportMaxOpenTickets      = 10
	supportTicketsPerHour      = 5
	supportTicketsPerDay       = 15
	supportRepliesPerHour      = 30
	supportDuplicateWindow     = 10 * time.Minute
	supportAutoCloseAfter      = 7 * 24 * time.Hour
	supportReopenWindow        = 14 * 24 * time.Hour
	supportPreviewRunes        = 140
	supportAgentDisplayName    = "Connect Support"
)

type supportCategorySpec struct {
	Team     string
	Priority string
}

// supportCategories maps each member-facing category to the queue that owns
// it and its starting priority. Safety reports go to Trust & Safety at high
// priority with a tighter SLA (supportSLATargets).
var supportCategories = map[string]supportCategorySpec{
	"account_login":     {Team: "general", Priority: "normal"},
	"verification":      {Team: "trust_safety", Priority: "normal"},
	"payments_billing":  {Team: "billing", Priority: "normal"},
	"safety_harassment": {Team: "trust_safety", Priority: "high"},
	"matches_chat":      {Team: "general", Priority: "normal"},
	"technical":         {Team: "technical", Priority: "normal"},
	"feature_request":   {Team: "general", Priority: "low"},
	"privacy_data":      {Team: "privacy", Priority: "normal"},
	"other":             {Team: "general", Priority: "normal"},
}

// supportCategoryOrder is the order members are offered categories in
// (GET /support/categories). Every key of supportCategories appears once.
var supportCategoryOrder = []string{
	"account_login", "verification", "payments_billing", "safety_harassment", "matches_chat",
	"technical", "feature_request", "privacy_data", "other",
}

// supportCategoryLabels are English labels for clients without their own
// (the app shows its localized labels, keyed by category).
var supportCategoryLabels = map[string]string{
	"account_login":     "Account & login",
	"verification":      "Verification",
	"payments_billing":  "Payments & billing",
	"safety_harassment": "Safety & harassment",
	"matches_chat":      "Matches & chat",
	"technical":         "Technical problem",
	"feature_request":   "Feature request",
	"privacy_data":      "Privacy & data request",
	"other":             "Other",
}

var (
	supportStatuses       = map[string]bool{"new": true, "open": true, "pending_member": true, "on_hold": true, "resolved": true, "closed": true}
	supportActiveStatuses = map[string]bool{"new": true, "open": true, "pending_member": true, "on_hold": true}
	supportPriorities     = map[string]bool{"low": true, "normal": true, "high": true, "urgent": true}
	supportTeams          = map[string]bool{"general": true, "trust_safety": true, "billing": true, "privacy": true, "technical": true}
	supportChannels       = map[string]bool{"app": true, "website": true, "email": true}
	supportPlatforms      = map[string]bool{"android": true, "ios": true, "web": true, "macos": true, "windows": true, "linux": true}
	supportPriorityRank   = map[string]int{"urgent": 4, "high": 3, "normal": 2, "low": 1}
	supportTagPattern     = regexp.MustCompile(`^[a-z0-9][a-z0-9_-]{0,31}$`)
	supportVersionPattern = regexp.MustCompile(`^[0-9A-Za-z][0-9A-Za-z.+\- ()]{0,31}$`)
)

var (
	supportTicketsCreated = promauto.NewCounterVec(prometheus.CounterOpts{
		Namespace: "verified_dating", Subsystem: "support", Name: "tickets_created_total",
		Help: "Support tickets raised, by channel and category.",
	}, []string{"channel", "category"})
	supportOpenTickets = promauto.NewGaugeVec(prometheus.GaugeOpts{
		Namespace: "verified_dating", Subsystem: "support", Name: "open_tickets",
		Help: "Unresolved support tickets by priority (refreshed by the support SLA worker).",
	}, []string{"priority"})
	supportSLABreaches = promauto.NewGaugeVec(prometheus.GaugeOpts{
		Namespace: "verified_dating", Subsystem: "support", Name: "sla_breached_tickets",
		Help: "Unresolved support tickets currently past an SLA target, by target (first_response, resolution).",
	}, []string{"target"})
)

var (
	errSupportNotFound      = errors.New("support ticket not found")
	errSupportUnavailable   = errors.New("support persistence is unavailable")
	errSupportClosed        = errors.New("this request is closed; start a new request if you still need help")
	errSupportReopenExpired = errors.New("this request can no longer be reopened; start a new request instead")
)

// supportError carries an HTTP status and a stable error_code to the handler.
type supportError struct {
	status     int
	code       string
	message    string
	retryAfter time.Duration
}

func (e *supportError) Error() string { return e.message }

func newSupportError(status int, code, message string) *supportError {
	return &supportError{status: status, code: code, message: message}
}

func writeSupportError(w http.ResponseWriter, err error) {
	var se *supportError
	if errors.As(err, &se) {
		payload := map[string]any{"success": false, "error": se.message, "error_code": se.code}
		if se.retryAfter > 0 {
			seconds := int(se.retryAfter.Round(time.Second).Seconds())
			if seconds < 1 {
				seconds = 1
			}
			w.Header().Set("Retry-After", strconv.Itoa(seconds))
			payload["retry_after_seconds"] = seconds
		}
		writeJSON(w, se.status, payload)
		return
	}
	var ue *mediaUploadError
	if errors.As(err, &ue) {
		code := "SUPPORT_ATTACHMENT_INVALID"
		switch ue.status {
		case http.StatusUnsupportedMediaType:
			code = "SUPPORT_ATTACHMENT_TYPE"
		case http.StatusRequestEntityTooLarge:
			code = "SUPPORT_ATTACHMENT_TOO_LARGE"
		}
		writeJSON(w, ue.status, map[string]any{"success": false, "error": ue.message, "error_code": code})
		return
	}
	switch {
	case errors.Is(err, errSupportNotFound), errors.Is(err, sql.ErrNoRows):
		writeError(w, http.StatusNotFound, errSupportNotFound)
	case errors.Is(err, errSupportUnavailable):
		writeError(w, http.StatusServiceUnavailable, err)
	case errors.Is(err, context.Canceled), errors.Is(err, context.DeadlineExceeded):
		writeError(w, http.StatusServiceUnavailable, errors.New("support request timed out"))
	default:
		writeError(w, http.StatusServiceUnavailable, errors.New("support service is temporarily unavailable"))
	}
}

func (s *Server) supportDB() (*sql.DB, error) {
	if s == nil || s.store == nil || s.store.profileRepo == nil || s.store.profileRepo.pg == nil {
		return nil, errSupportUnavailable
	}
	return s.store.profileRepo.pg, nil
}

// ── SLA ──────────────────────────────────────────────────────────────────────

// supportSLATargets returns the first-response and resolution targets.
// Calendar time; safety reports are capped at 1h / 24h whatever their priority.
func supportSLATargets(category, priority string) (time.Duration, time.Duration) {
	first, resolution := 24*time.Hour, 72*time.Hour
	switch priority {
	case "urgent":
		first, resolution = time.Hour, 8*time.Hour
	case "high":
		first, resolution = 4*time.Hour, 24*time.Hour
	case "low":
		first, resolution = 48*time.Hour, 168*time.Hour
	}
	if category == "safety_harassment" {
		first = min(first, time.Hour)
		resolution = min(resolution, 24*time.Hour)
	}
	return first, resolution
}

// ── ticket model ─────────────────────────────────────────────────────────────

type supportTicket struct {
	ID, Reference                   string
	RequesterMemberID               string
	ContactEmail, ContactName       string
	Category, Subject               string
	Status, Priority, Team, Channel string
	AssigneeID                      string
	Tags                            []string
	AppVersion, Platform, OSVersion string
	DeviceModel, Locale             string
	ClientErrorIssueID              string
	FirstResponseDueAt              time.Time
	ResolutionDueAt                 time.Time
	FirstRespondedAt, ResolvedAt    *time.Time
	ClosedAt, SLAPausedAt           *time.Time
	FirstResponseBreached           bool
	ResolutionBreached              bool
	SatisfactionRating              int
	SatisfactionComment             string
	RatedAt                         *time.Time
	MergedIntoID                    string
	MemberLastReadAt                *time.Time
	LastMemberMessageAt             *time.Time
	LastAgentReplyAt                *time.Time
	LastActivityAt, CreatedAt       time.Time
	UpdatedAt                       time.Time
	RequestHash                     string
}

const supportTicketColumns = `t.id::text, t.reference, COALESCE(t.requester_member_id::text,''),
	COALESCE(t.contact_email,''), COALESCE(t.contact_name,''), t.category, t.subject, t.status,
	t.priority, t.team, t.channel, COALESCE(t.assignee_id::text,''), COALESCE(array_to_json(t.tags)::text,'[]'),
	COALESCE(t.app_version,''), COALESCE(t.platform,''), COALESCE(t.os_version,''),
	COALESCE(t.device_model,''), COALESCE(t.locale,''), COALESCE(t.client_error_issue_id::text,''),
	t.first_response_due_at, t.resolution_due_at, t.first_responded_at, t.resolved_at, t.closed_at,
	t.sla_paused_at, t.first_response_breached, t.resolution_breached,
	COALESCE(t.satisfaction_rating,0), COALESCE(t.satisfaction_comment,''), t.rated_at,
	COALESCE(t.merged_into_id::text,''), t.member_last_read_at, t.last_member_message_at,
	t.last_agent_reply_at, t.last_activity_at, t.request_hash, t.created_at, t.updated_at`

type supportScanner interface{ Scan(...any) error }

func timePtr(value sql.NullTime) *time.Time {
	if !value.Valid {
		return nil
	}
	t := value.Time.UTC()
	return &t
}

// scanSupportTicketRow scans supportTicketColumns followed by extra targets.
func scanSupportTicketRow(row supportScanner, extra ...any) (*supportTicket, error) {
	var t supportTicket
	var tags string
	var firstResponded, resolved, closed, paused, rated, lastRead, lastMember, lastAgent sql.NullTime
	targets := []any{&t.ID, &t.Reference, &t.RequesterMemberID, &t.ContactEmail, &t.ContactName,
		&t.Category, &t.Subject, &t.Status, &t.Priority, &t.Team, &t.Channel, &t.AssigneeID, &tags,
		&t.AppVersion, &t.Platform, &t.OSVersion, &t.DeviceModel, &t.Locale, &t.ClientErrorIssueID,
		&t.FirstResponseDueAt, &t.ResolutionDueAt, &firstResponded, &resolved, &closed, &paused,
		&t.FirstResponseBreached, &t.ResolutionBreached, &t.SatisfactionRating, &t.SatisfactionComment, &rated,
		&t.MergedIntoID, &lastRead, &lastMember, &lastAgent, &t.LastActivityAt, &t.RequestHash, &t.CreatedAt, &t.UpdatedAt}
	if err := row.Scan(append(targets, extra...)...); err != nil {
		return nil, err
	}
	t.Tags = []string{}
	_ = json.Unmarshal([]byte(tags), &t.Tags)
	t.FirstRespondedAt, t.ResolvedAt, t.ClosedAt, t.SLAPausedAt = timePtr(firstResponded), timePtr(resolved), timePtr(closed), timePtr(paused)
	t.RatedAt, t.MemberLastReadAt, t.LastMemberMessageAt, t.LastAgentReplyAt = timePtr(rated), timePtr(lastRead), timePtr(lastMember), timePtr(lastAgent)
	t.FirstResponseDueAt, t.ResolutionDueAt = t.FirstResponseDueAt.UTC(), t.ResolutionDueAt.UTC()
	t.LastActivityAt, t.CreatedAt, t.UpdatedAt = t.LastActivityAt.UTC(), t.CreatedAt.UTC(), t.UpdatedAt.UTC()
	return &t, nil
}

type supportQuerier interface {
	QueryRowContext(context.Context, string, ...any) *sql.Row
	QueryContext(context.Context, string, ...any) (*sql.Rows, error)
	ExecContext(context.Context, string, ...any) (sql.Result, error)
}

func loadSupportTicket(ctx context.Context, q supportQuerier, id string, forUpdate bool) (*supportTicket, error) {
	if _, err := uuid.Parse(id); err != nil {
		return nil, errSupportNotFound
	}
	query := `SELECT ` + supportTicketColumns + ` FROM support.tickets t WHERE t.id=$1`
	if forUpdate {
		query += ` FOR UPDATE`
	}
	t, err := scanSupportTicketRow(q.QueryRowContext(ctx, query, id))
	if errors.Is(err, sql.ErrNoRows) {
		return nil, errSupportNotFound
	}
	return t, err
}

func (t *supportTicket) active() bool { return supportActiveStatuses[t.Status] }

// latchBreaches records missed targets; the flags never clear.
func (t *supportTicket) latchBreaches(now time.Time) {
	if t.FirstRespondedAt == nil && t.active() && now.After(t.FirstResponseDueAt) {
		t.FirstResponseBreached = true
	}
	if t.FirstRespondedAt != nil && t.FirstRespondedAt.After(t.FirstResponseDueAt) {
		t.FirstResponseBreached = true
	}
	if t.active() && t.Status != "pending_member" && now.After(t.ResolutionDueAt) {
		t.ResolutionBreached = true
	}
	if t.ResolvedAt != nil && t.ResolvedAt.After(t.ResolutionDueAt) {
		t.ResolutionBreached = true
	}
}

// setStatus applies a status transition and its clock side effects.
func (t *supportTicket) setStatus(next string, now time.Time) {
	if t.Status == next {
		return
	}
	t.latchBreaches(now)
	wasFinished := t.Status == "resolved" || t.Status == "closed"
	// The resolution clock stops while waiting on the member: shift the due
	// time by the paused span when the ticket leaves pending_member.
	if t.Status == "pending_member" && t.SLAPausedAt != nil {
		t.ResolutionDueAt = t.ResolutionDueAt.Add(now.Sub(*t.SLAPausedAt))
		t.SLAPausedAt = nil
	}
	switch next {
	case "pending_member":
		paused := now
		t.SLAPausedAt = &paused
		if wasFinished {
			t.ResolvedAt, t.ClosedAt = nil, nil
		}
	case "resolved":
		resolved := now
		t.ResolvedAt, t.ClosedAt = &resolved, nil
	case "closed":
		closed := now
		t.ClosedAt = &closed
	default: // new, open, on_hold
		if wasFinished {
			// A reopened ticket gets a fresh resolution target.
			_, resolution := supportSLATargets(t.Category, t.Priority)
			t.ResolutionDueAt = now.Add(resolution)
		}
		t.ResolvedAt, t.ClosedAt = nil, nil
	}
	t.Status = next
	t.latchBreaches(now)
}

// retarget recomputes due times after a priority or category change while
// keeping any pause/reopen shift already applied to the resolution target.
func (t *supportTicket) retarget(newCategory, newPriority string) {
	_, oldResolution := supportSLATargets(t.Category, t.Priority)
	first, resolution := supportSLATargets(newCategory, newPriority)
	shift := t.ResolutionDueAt.Sub(t.CreatedAt.Add(oldResolution))
	if t.FirstRespondedAt == nil {
		t.FirstResponseDueAt = t.CreatedAt.Add(first)
	}
	t.ResolutionDueAt = t.CreatedAt.Add(resolution).Add(shift)
	t.Category, t.Priority = newCategory, newPriority
}

func atRisk(now, created, due time.Time) bool {
	window := due.Sub(created)
	return !now.Before(due.Add(-window / 4))
}

// slaState mirrors supportSLABreachedSQL / supportSLAAtRiskSQL.
func (t *supportTicket) slaState(now time.Time) (string, string, string) {
	first := "ok"
	switch {
	case t.FirstResponseBreached:
		first = "breached"
	case t.FirstRespondedAt != nil || !t.active():
		first = "met"
	case now.After(t.FirstResponseDueAt):
		first = "breached"
	case atRisk(now, t.CreatedAt, t.FirstResponseDueAt):
		first = "at_risk"
	}
	resolution := "ok"
	switch {
	case t.ResolutionBreached:
		resolution = "breached"
	case !t.active():
		resolution = "met"
	case t.Status == "pending_member":
		resolution = "paused"
	case now.After(t.ResolutionDueAt):
		resolution = "breached"
	case atRisk(now, t.CreatedAt, t.ResolutionDueAt):
		resolution = "at_risk"
	}
	state := "ok"
	switch {
	case first == "breached" || resolution == "breached":
		state = "breached"
	case first == "at_risk" || resolution == "at_risk":
		state = "at_risk"
	case resolution == "paused":
		state = "paused"
	case resolution == "met":
		state = "met"
	}
	return state, first, resolution
}

// SQL forms of the SLA state, for queue filters and the dashboard.
const (
	supportActiveSQL      = `t.status IN ('new','open','pending_member','on_hold')`
	supportSLABreachedSQL = `(t.first_response_breached OR t.resolution_breached OR (` + supportActiveSQL + ` AND (
		(t.first_responded_at IS NULL AND t.first_response_due_at < NOW()) OR
		(t.status <> 'pending_member' AND t.resolution_due_at < NOW()))))`
	supportSLAAtRiskSQL = `(` + supportActiveSQL + ` AND NOT ` + supportSLABreachedSQL + ` AND (
		(t.first_responded_at IS NULL AND NOW() >= t.first_response_due_at - (t.first_response_due_at - t.created_at)/4) OR
		(t.status <> 'pending_member' AND NOW() >= t.resolution_due_at - (t.resolution_due_at - t.created_at)/4)))`
)

func saveSupportTicketTx(ctx context.Context, q supportQuerier, t *supportTicket, now time.Time) error {
	t.latchBreaches(now)
	tags, _ := json.Marshal(t.Tags)
	rating := sql.NullInt64{Int64: int64(t.SatisfactionRating), Valid: t.SatisfactionRating > 0}
	_, err := q.ExecContext(ctx, `
		UPDATE support.tickets SET
		  category=$2, subject=$3, status=$4, priority=$5, team=$6,
		  assignee_id=NULLIF($7,'')::uuid, tags=ARRAY(SELECT jsonb_array_elements_text($8::jsonb)),
		  client_error_issue_id=NULLIF($9,'')::uuid,
		  first_response_due_at=$10, resolution_due_at=$11, first_responded_at=$12,
		  resolved_at=$13, closed_at=$14, sla_paused_at=$15,
		  first_response_breached=$16, resolution_breached=$17,
		  satisfaction_rating=$18, satisfaction_comment=NULLIF($19,''), rated_at=$20,
		  merged_into_id=NULLIF($21,'')::uuid, member_last_read_at=$22,
		  last_member_message_at=$23, last_agent_reply_at=$24, last_activity_at=$25,
		  updated_at=NOW()
		WHERE id=$1`,
		t.ID, t.Category, t.Subject, t.Status, t.Priority, t.Team, t.AssigneeID, string(tags),
		t.ClientErrorIssueID, t.FirstResponseDueAt, t.ResolutionDueAt, t.FirstRespondedAt,
		t.ResolvedAt, t.ClosedAt, t.SLAPausedAt, t.FirstResponseBreached, t.ResolutionBreached,
		rating, t.SatisfactionComment, t.RatedAt, t.MergedIntoID, t.MemberLastReadAt,
		t.LastMemberMessageAt, t.LastAgentReplyAt, t.LastActivityAt)
	return err
}

// supportActor is whoever caused a change.
type supportActor struct {
	Kind string // member, contact, agent, system
	ID   string
}

func insertSupportEventTx(ctx context.Context, q supportQuerier, ticketID string, actor supportActor, eventType, from, to string, payload map[string]any) error {
	if payload == nil {
		payload = map[string]any{}
	}
	encoded, err := json.Marshal(payload)
	if err != nil {
		return err
	}
	_, err = q.ExecContext(ctx, `
		INSERT INTO support.ticket_events (ticket_id, event_type, actor_kind, actor_id, from_value, to_value, payload, created_at)
		VALUES ($1, $2, $3, NULLIF($4,'')::uuid, NULLIF($5,''), NULLIF($6,''), $7::jsonb, clock_timestamp())`,
		ticketID, eventType, actor.Kind, actor.ID, truncateRunes(from, 200), truncateRunes(to, 200), string(encoded))
	return err
}

// insertSupportMessageTx stores a message and links the actor's pending
// attachments to it.
func insertSupportMessageTx(ctx context.Context, q supportQuerier, ticketID string, actor supportActor, visibility, body, cannedID string, attachmentIDs []string) (string, error) {
	var messageID string
	if err := q.QueryRowContext(ctx, `
		INSERT INTO support.ticket_messages (ticket_id, author_kind, author_id, visibility, body, canned_response_id, created_at)
		VALUES ($1, $2, NULLIF($3,'')::uuid, $4, $5, NULLIF($6,'')::uuid, clock_timestamp())
		RETURNING id::text`, ticketID, actor.Kind, actor.ID, visibility, body, cannedID).Scan(&messageID); err != nil {
		return "", err
	}
	if len(attachmentIDs) == 0 {
		return messageID, nil
	}
	var existing int
	if err := q.QueryRowContext(ctx, `SELECT COUNT(*) FROM support.ticket_attachments WHERE ticket_id=$1 AND deleted_at IS NULL`, ticketID).Scan(&existing); err != nil {
		return "", err
	}
	if existing+len(attachmentIDs) > supportMaxAttachmentsPerTk {
		return "", newSupportError(http.StatusConflict, "SUPPORT_ATTACHMENT_LIMIT", fmt.Sprintf("A request can hold at most %d attachments.", supportMaxAttachmentsPerTk))
	}
	for _, id := range attachmentIDs {
		result, err := q.ExecContext(ctx, `
			UPDATE support.ticket_attachments SET ticket_id=$2, message_id=$3, expires_at=NULL
			WHERE id=$1 AND uploader_id=$4 AND message_id IS NULL AND deleted_at IS NULL`,
			id, ticketID, messageID, actor.ID)
		if err != nil {
			return "", err
		}
		if affected, _ := result.RowsAffected(); affected != 1 {
			return "", newSupportError(http.StatusBadRequest, "SUPPORT_ATTACHMENT_NOT_FOUND", "An attachment was not found or is already used. Upload it again.")
		}
	}
	return messageID, nil
}

// ── input validation ─────────────────────────────────────────────────────────

func supportCleanText(value string, maxRunes int) string {
	value = strings.Map(func(r rune) rune {
		if r == '\n' || r == '\t' {
			return r
		}
		if r < 0x20 || r == 0x7f {
			return -1
		}
		return r
	}, strings.ReplaceAll(value, "\r\n", "\n"))
	value = strings.TrimSpace(value)
	if maxRunes > 0 && utf8.RuneCountInString(value) > maxRunes {
		return string([]rune(value)[:maxRunes])
	}
	return value
}

// supportSingleLine collapses whitespace; callers check or cap the length.
func supportSingleLine(value string) string {
	return strings.Join(strings.Fields(supportCleanText(value, 0)), " ")
}

type supportTicketInput struct {
	Category, Subject, Description string
	AttachmentIDs                  []string
	AppVersion, Platform           string
	OSVersion, DeviceModel, Locale string
}

func validateSupportTicketInput(payload map[string]any) (supportTicketInput, error) {
	in := supportTicketInput{
		Category:    strings.ToLower(strings.TrimSpace(toString(payload["category"]))),
		Subject:     supportSingleLine(toString(payload["subject"])),
		Description: supportCleanText(toString(payload["description"]), 0),
	}
	if in.Description == "" {
		// The first app release sent "body".
		in.Description = supportCleanText(toString(payload["body"]), 0)
	}
	if _, ok := supportCategories[in.Category]; !ok {
		return in, newSupportError(http.StatusBadRequest, "SUPPORT_INVALID_CATEGORY", "Choose a valid category.")
	}
	if n := utf8.RuneCountInString(in.Subject); n < supportSubjectMinRunes || n > supportSubjectMaxRunes {
		return in, newSupportError(http.StatusBadRequest, "SUPPORT_INVALID_SUBJECT", fmt.Sprintf("Subject must be %d-%d characters.", supportSubjectMinRunes, supportSubjectMaxRunes))
	}
	if n := utf8.RuneCountInString(in.Description); n < 1 || n > supportBodyMaxRunes {
		return in, newSupportError(http.StatusBadRequest, "SUPPORT_INVALID_DESCRIPTION", fmt.Sprintf("Describe the problem in 1-%d characters.", supportBodyMaxRunes))
	}
	ids, err := supportAttachmentIDs(payload["attachment_ids"])
	if err != nil {
		return in, err
	}
	in.AttachmentIDs = ids
	if v := strings.TrimSpace(toString(payload["app_version"])); v != "" && supportVersionPattern.MatchString(v) {
		in.AppVersion = v
	}
	if v := strings.ToLower(strings.TrimSpace(toString(payload["platform"]))); supportPlatforms[v] {
		in.Platform = v
	}
	in.OSVersion = truncateRunes(supportSingleLine(toString(payload["os_version"])), 32)
	in.DeviceModel = truncateRunes(supportSingleLine(toString(payload["device_model"])), 64)
	if v := strings.TrimSpace(toString(payload["locale"])); clientErrorLocale.MatchString(v) && len(v) <= 16 {
		in.Locale = v
	}
	return in, nil
}

func supportAttachmentIDs(raw any) ([]string, error) {
	if raw == nil {
		return nil, nil
	}
	list, ok := raw.([]any)
	if !ok {
		return nil, newSupportError(http.StatusBadRequest, "SUPPORT_INVALID_ATTACHMENTS", "attachment_ids must be a list.")
	}
	if len(list) > supportMaxAttachmentsPerMs {
		return nil, newSupportError(http.StatusBadRequest, "SUPPORT_INVALID_ATTACHMENTS", fmt.Sprintf("Attach at most %d files per message.", supportMaxAttachmentsPerMs))
	}
	seen := map[string]bool{}
	ids := make([]string, 0, len(list))
	for _, item := range list {
		id := strings.TrimSpace(toString(item))
		if _, err := uuid.Parse(id); err != nil {
			return nil, newSupportError(http.StatusBadRequest, "SUPPORT_INVALID_ATTACHMENTS", "attachment_ids must be upload ids.")
		}
		if !seen[id] {
			seen[id] = true
			ids = append(ids, id)
		}
	}
	return ids, nil
}

func supportRequestFingerprint(category, subject, description string) string {
	normalise := func(value string) string { return strings.ToLower(strings.Join(strings.Fields(value), " ")) }
	sum := sha256.Sum256([]byte(category + "\x00" + normalise(subject) + "\x00" + normalise(description)))
	return hex.EncodeToString(sum[:])
}

// ── creating tickets ─────────────────────────────────────────────────────────

type supportCreateResult struct {
	TicketID  string
	Duplicate bool
	Reference string
}

// createSupportTicket stores a new ticket with its first message. requester
// is a member id (app) or empty for a contact-form ticket (contactEmail set).
func createSupportTicket(ctx context.Context, db *sql.DB, in supportTicketInput, channel, memberID, contactEmail, contactName string, now time.Time) (supportCreateResult, error) {
	spec := supportCategories[in.Category]
	priority := spec.Priority
	firstTarget, resolutionTarget := supportSLATargets(in.Category, priority)
	hash := supportRequestFingerprint(in.Category, in.Subject, in.Description)
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return supportCreateResult{}, err
	}
	defer func() { _ = tx.Rollback() }()

	// Serialise one requester's creates so the limits and the duplicate
	// guard cannot be raced by parallel submissions.
	lockKey := "support:create:" + memberID
	if memberID == "" {
		lockKey = "support:create:contact:" + strings.ToLower(contactEmail)
	}
	if _, err = tx.ExecContext(ctx, `SELECT pg_advisory_xact_lock(hashtext($1))`, lockKey); err != nil {
		return supportCreateResult{}, err
	}
	requesterSQL, requesterArg := `t.requester_member_id=$1::uuid`, memberID
	if memberID == "" {
		requesterSQL, requesterArg = `t.requester_member_id IS NULL AND lower(t.contact_email)=lower($1)`, contactEmail
	}
	var dupID, dupRef string
	err = tx.QueryRowContext(ctx, `SELECT t.id::text, t.reference FROM support.tickets t
		WHERE `+requesterSQL+` AND t.request_hash=$2 AND t.created_at > $3 AND t.status <> 'closed'
		ORDER BY t.created_at DESC LIMIT 1`, requesterArg, hash, now.Add(-supportDuplicateWindow)).Scan(&dupID, &dupRef)
	if err == nil {
		return supportCreateResult{TicketID: dupID, Reference: dupRef, Duplicate: true}, nil
	}
	if !errors.Is(err, sql.ErrNoRows) {
		return supportCreateResult{}, err
	}
	var lastHour, lastDay, open int
	var oldestInHour sql.NullTime
	if err = tx.QueryRowContext(ctx, `SELECT
		  COUNT(*) FILTER (WHERE t.created_at > $2),
		  COUNT(*) FILTER (WHERE t.created_at > $3),
		  COUNT(*) FILTER (WHERE `+supportActiveSQL+`),
		  MIN(t.created_at) FILTER (WHERE t.created_at > $2)
		FROM support.tickets t WHERE `+requesterSQL, requesterArg, now.Add(-time.Hour), now.Add(-24*time.Hour)).Scan(&lastHour, &lastDay, &open, &oldestInHour); err != nil {
		return supportCreateResult{}, err
	}
	perHour, perDay := supportTicketsPerHour, supportTicketsPerDay
	if memberID == "" {
		perHour, perDay = supportContactPerEmailHour, supportContactPerEmailDay
	}
	if lastHour >= perHour || lastDay >= perDay {
		wait := time.Hour
		if lastHour >= perHour && oldestInHour.Valid {
			wait = time.Until(oldestInHour.Time.Add(time.Hour))
		}
		e := newSupportError(http.StatusTooManyRequests, "SUPPORT_RATE_LIMITED", "You've sent several requests recently. Please wait before opening another, or reply on an existing request.")
		e.retryAfter = max(wait, time.Minute)
		return supportCreateResult{}, e
	}
	if memberID != "" && open >= supportMaxOpenTickets {
		return supportCreateResult{}, newSupportError(http.StatusConflict, "SUPPORT_TOO_MANY_OPEN", "You have several open requests. Please reply on one of them or close those you no longer need.")
	}

	var ticketID, reference string
	if err = tx.QueryRowContext(ctx, `
		INSERT INTO support.tickets (reference, requester_member_id, contact_email, contact_name, category, subject,
		  status, priority, team, channel, app_version, platform, os_version, device_model, locale,
		  first_response_due_at, resolution_due_at, last_member_message_at, last_activity_at, request_hash, created_at, updated_at)
		VALUES (support.next_ticket_reference(), NULLIF($1,'')::uuid, NULLIF($2,''), NULLIF($3,''), $4, $5,
		  'new', $6, $7, $8, NULLIF($9,''), NULLIF($10,''), NULLIF($11,''), NULLIF($12,''), NULLIF($13,''),
		  $14, $15, $16, $16, $17, $16, $16)
		RETURNING id::text, reference`,
		memberID, contactEmail, contactName, in.Category, in.Subject, priority, spec.Team, channel,
		in.AppVersion, in.Platform, in.OSVersion, in.DeviceModel, in.Locale,
		now.Add(firstTarget), now.Add(resolutionTarget), now, hash).Scan(&ticketID, &reference); err != nil {
		return supportCreateResult{}, err
	}
	actor := supportActor{Kind: "member", ID: memberID}
	if memberID == "" {
		actor = supportActor{Kind: "contact"}
	}
	if _, err = insertSupportMessageTx(ctx, tx, ticketID, actor, "public", in.Description, "", in.AttachmentIDs); err != nil {
		return supportCreateResult{}, err
	}
	if err = insertSupportEventTx(ctx, tx, ticketID, actor, "created", "", "new", map[string]any{
		"category": in.Category, "priority": priority, "team": spec.Team, "channel": channel,
	}); err != nil {
		return supportCreateResult{}, err
	}
	if err = tx.Commit(); err != nil {
		return supportCreateResult{}, err
	}
	supportTicketsCreated.WithLabelValues(channel, in.Category).Inc()
	return supportCreateResult{TicketID: ticketID, Reference: reference}, nil
}

// ── member views ─────────────────────────────────────────────────────────────

type supportAttachmentView struct {
	ID, MessageID, Filename, ContentType string
	SizeBytes                            int
}

// memberSupportListSQL selects a member's tickets with list extras.
const memberSupportListSQL = `SELECT ` + supportTicketColumns + `,
	(SELECT COUNT(*) FROM support.ticket_messages m WHERE m.ticket_id=t.id AND m.visibility='public')::int,
	(SELECT COUNT(*) FROM support.ticket_messages m WHERE m.ticket_id=t.id AND m.visibility='public'
	   AND m.author_kind IN ('agent','system') AND m.created_at > COALESCE(t.member_last_read_at,'-infinity'::timestamptz))::int,
	COALESCE(lm.body,''), COALESCE(lm.author_kind,''), COALESCE(mt.reference,'')
	FROM support.tickets t
	LEFT JOIN LATERAL (SELECT m.body, m.author_kind FROM support.ticket_messages m
	   WHERE m.ticket_id=t.id AND m.visibility='public' ORDER BY m.created_at DESC, m.id DESC LIMIT 1) lm ON TRUE
	LEFT JOIN support.tickets mt ON mt.id=t.merged_into_id`

type memberSupportRow struct {
	ticket        *supportTicket
	messageCount  int
	unread        int
	lastBody      string
	lastAuthor    string
	mergedIntoRef string
}

func scanMemberSupportRow(row supportScanner) (memberSupportRow, error) {
	var out memberSupportRow
	t, err := scanSupportTicketRow(row, &out.messageCount, &out.unread, &out.lastBody, &out.lastAuthor, &out.mergedIntoRef)
	out.ticket = t
	return out, err
}

func supportTimeValue(t *time.Time) any {
	if t == nil {
		return nil
	}
	return t.UTC().Format(time.RFC3339)
}

func supportMemberAuthor(kind string) string {
	switch kind {
	case "member", "contact":
		return "member"
	case "agent":
		return "agent"
	default:
		return "system"
	}
}

func supportPreview(body string) string {
	return truncateRunes(strings.Join(strings.Fields(body), " "), supportPreviewRunes)
}

func (t *supportTicket) reopenUntil() *time.Time {
	if t.Status != "closed" || t.ClosedAt == nil || t.MergedIntoID != "" {
		return nil
	}
	until := t.ClosedAt.Add(supportReopenWindow)
	return &until
}

func (t *supportTicket) memberCanReopen(now time.Time) bool {
	if t.MergedIntoID != "" {
		return false
	}
	if t.Status == "resolved" {
		return true
	}
	until := t.reopenUntil()
	return until != nil && now.Before(*until)
}

func memberTicketView(row memberSupportRow, now time.Time) map[string]any {
	t := row.ticket
	var satisfaction any
	if t.SatisfactionRating > 0 {
		satisfaction = map[string]any{"rating": t.SatisfactionRating, "comment": t.SatisfactionComment, "rated_at": supportTimeValue(t.RatedAt)}
	}
	var merged any
	if row.mergedIntoRef != "" {
		merged = row.mergedIntoRef
	}
	lastAuthor := any(nil)
	if row.lastAuthor != "" {
		lastAuthor = supportMemberAuthor(row.lastAuthor)
	}
	return map[string]any{
		"id": t.ID, "reference": t.Reference, "category": t.Category, "subject": t.Subject,
		"status": t.Status, "channel": t.Channel,
		"created_at": t.CreatedAt.Format(time.RFC3339), "updated_at": t.UpdatedAt.Format(time.RFC3339),
		"last_activity_at": t.LastActivityAt.Format(time.RFC3339),
		"resolved_at":      supportTimeValue(t.ResolvedAt), "closed_at": supportTimeValue(t.ClosedAt),
		"reopen_until":  supportTimeValue(t.reopenUntil()),
		"message_count": row.messageCount, "unread_count": row.unread,
		"last_message_preview": supportPreview(row.lastBody), "last_message_author": lastAuthor,
		"can_reply":    t.MergedIntoID == "" && (t.Status != "closed" || t.memberCanReopen(now)),
		"can_close":    t.Status != "closed",
		"can_reopen":   t.memberCanReopen(now),
		"can_rate":     (t.Status == "resolved" || t.Status == "closed") && t.SatisfactionRating == 0 && t.MergedIntoID == "",
		"satisfaction": satisfaction, "merged_into_reference": merged,
	}
}

func loadMemberSupportRow(ctx context.Context, q supportQuerier, memberID, ticketID string) (memberSupportRow, error) {
	if _, err := uuid.Parse(ticketID); err != nil {
		return memberSupportRow{}, errSupportNotFound
	}
	row, err := scanMemberSupportRow(q.QueryRowContext(ctx, memberSupportListSQL+` WHERE t.id=$1 AND t.requester_member_id=$2::uuid`, ticketID, memberID))
	if errors.Is(err, sql.ErrNoRows) {
		return row, errSupportNotFound
	}
	return row, err
}

// supportAttachmentsByMessage loads live attachments of a ticket's messages.
func supportAttachmentsByMessage(ctx context.Context, q supportQuerier, ticketID string) (map[string][]supportAttachmentView, error) {
	rows, err := q.QueryContext(ctx, `SELECT id::text, message_id::text, filename, content_type, size_bytes
		FROM support.ticket_attachments WHERE ticket_id=$1 AND deleted_at IS NULL ORDER BY created_at, id`, ticketID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := map[string][]supportAttachmentView{}
	for rows.Next() {
		var a supportAttachmentView
		if err := rows.Scan(&a.ID, &a.MessageID, &a.Filename, &a.ContentType, &a.SizeBytes); err != nil {
			return nil, err
		}
		out[a.MessageID] = append(out[a.MessageID], a)
	}
	return out, rows.Err()
}

func (s *Server) memberSupportMessages(ctx context.Context, q supportQuerier, ticketID string) ([]map[string]any, error) {
	attachments, err := supportAttachmentsByMessage(ctx, q, ticketID)
	if err != nil {
		return nil, err
	}
	rows, err := q.QueryContext(ctx, `SELECT id::text, author_kind, body, created_at FROM support.ticket_messages
		WHERE ticket_id=$1 AND visibility='public' ORDER BY created_at, id`, ticketID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	messages := make([]map[string]any, 0)
	for rows.Next() {
		var id, kind, body string
		var created time.Time
		if err := rows.Scan(&id, &kind, &body, &created); err != nil {
			return nil, err
		}
		messages = append(messages, s.memberMessageView(ticketID, id, kind, body, created, attachments[id]))
	}
	return messages, rows.Err()
}

func (s *Server) memberMessageView(ticketID, id, kind, body string, created time.Time, attachments []supportAttachmentView) map[string]any {
	author := supportMemberAuthor(kind)
	var name any
	if author == "agent" || author == "system" {
		name = supportAgentDisplayName
	}
	files := make([]map[string]any, 0, len(attachments))
	for _, a := range attachments {
		files = append(files, map[string]any{
			"id": a.ID, "filename": a.Filename, "content_type": a.ContentType, "size_bytes": a.SizeBytes,
			"url": s.apiPrefix() + "/support/tickets/" + ticketID + "/attachments/" + a.ID,
		})
	}
	return map[string]any{"id": id, "author": author, "author_name": name, "body": body,
		"created_at": created.UTC().Format(time.RFC3339), "attachments": files}
}

func (s *Server) apiPrefix() string {
	prefix := strings.TrimRight(s.cfg.APIPrefix, "/")
	if prefix == "" {
		return "/v1"
	}
	return prefix
}

func (s *Server) writeMemberTicket(w http.ResponseWriter, ctx context.Context, db *sql.DB, memberID, ticketID string, status int, extra map[string]any) {
	row, err := loadMemberSupportRow(ctx, db, memberID, ticketID)
	if err != nil {
		writeSupportError(w, err)
		return
	}
	payload := map[string]any{"success": true, "ticket": memberTicketView(row, time.Now().UTC())}
	for k, v := range extra {
		payload[k] = v
	}
	writeJSON(w, status, payload)
}

// ── member handlers ──────────────────────────────────────────────────────────

func (s *Server) supportMember(w http.ResponseWriter, r *http.Request) (string, *sql.DB, bool) {
	principal, err := requestPrincipal(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return "", nil, false
	}
	db, err := s.supportDB()
	if err != nil {
		writeSupportError(w, err)
		return "", nil, false
	}
	return principal.UserID, db, true
}

// supportListCategories returns the categories a member can choose and the
// limits the server enforces, so clients never offer a choice or a file the
// server would refuse. Behind support_ticketing_enabled like every member
// route, so a 200 also tells the app that requests can be raised.
func (s *Server) supportListCategories(w http.ResponseWriter, r *http.Request) {
	if _, err := requestPrincipal(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	categories := make([]map[string]any, 0, len(supportCategoryOrder))
	for _, key := range supportCategoryOrder {
		categories = append(categories, map[string]any{
			"key": key, "label": supportCategoryLabels[key], "safety": key == "safety_harassment",
		})
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"success":    true,
		"categories": categories,
		"limits": map[string]any{
			"subject_min_chars": supportSubjectMinRunes, "subject_max_chars": supportSubjectMaxRunes,
			"body_max_chars": supportBodyMaxRunes, "rating_comment_max_chars": supportRatingCommentRunes,
			"attachments_per_message": supportMaxAttachmentsPerMs, "attachments_per_ticket": supportMaxAttachmentsPerTk,
			"image_max_bytes": supportImageMaxBytes, "pdf_max_bytes": supportPDFMaxBytes,
			"attachment_types": []string{"image/jpeg", "image/png", "application/pdf"},
		},
	})
}

func (s *Server) supportCreateTicket(w http.ResponseWriter, r *http.Request) {
	memberID, db, ok := s.supportMember(w, r)
	if !ok {
		return
	}
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	in, err := validateSupportTicketInput(payload)
	if err != nil {
		writeSupportError(w, err)
		return
	}
	result, err := createSupportTicket(r.Context(), db, in, "app", memberID, "", "", time.Now().UTC())
	if err != nil {
		writeSupportError(w, err)
		return
	}
	row, err := loadMemberSupportRow(r.Context(), db, memberID, result.TicketID)
	if err != nil {
		writeSupportError(w, err)
		return
	}
	messages, err := s.memberSupportMessages(r.Context(), db, result.TicketID)
	if err != nil {
		writeSupportError(w, err)
		return
	}
	status := http.StatusCreated
	body := map[string]any{"success": true, "ticket": memberTicketView(row, time.Now().UTC()), "messages": messages}
	if result.Duplicate {
		status = http.StatusOK
		body["duplicate"] = true
	}
	writeJSON(w, status, body)
}

func (s *Server) supportListTickets(w http.ResponseWriter, r *http.Request) {
	memberID, db, ok := s.supportMember(w, r)
	if !ok {
		return
	}
	filter := ""
	switch strings.ToLower(strings.TrimSpace(r.URL.Query().Get("status"))) {
	case "active", "open":
		filter = ` AND t.status <> 'closed'`
	case "closed":
		filter = ` AND t.status = 'closed'`
	}
	rows, err := db.QueryContext(r.Context(), memberSupportListSQL+` WHERE t.requester_member_id=$1::uuid`+filter+`
		ORDER BY (t.status='closed'), t.last_activity_at DESC LIMIT $2`, memberID, boundedQueryLimit(r, 50, 100))
	if err != nil {
		writeSupportError(w, err)
		return
	}
	defer rows.Close()
	now := time.Now().UTC()
	tickets := make([]map[string]any, 0)
	unread, open := 0, 0
	for rows.Next() {
		row, err := scanMemberSupportRow(rows)
		if err != nil {
			writeSupportError(w, err)
			return
		}
		unread += row.unread
		if row.ticket.active() {
			open++
		}
		tickets = append(tickets, memberTicketView(row, now))
	}
	if err := rows.Err(); err != nil {
		writeSupportError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"success": true, "tickets": tickets, "unread_total": unread, "open_total": open})
}

func (s *Server) supportGetTicket(w http.ResponseWriter, r *http.Request) {
	memberID, db, ok := s.supportMember(w, r)
	if !ok {
		return
	}
	ticketID := chi.URLParam(r, "ticketID")
	if _, err := loadMemberSupportRow(r.Context(), db, memberID, ticketID); err != nil {
		writeSupportError(w, err)
		return
	}
	if _, err := db.ExecContext(r.Context(), `UPDATE support.tickets SET member_last_read_at=clock_timestamp() WHERE id=$1 AND requester_member_id=$2::uuid`, ticketID, memberID); err != nil {
		writeSupportError(w, err)
		return
	}
	messages, err := s.memberSupportMessages(r.Context(), db, ticketID)
	if err != nil {
		writeSupportError(w, err)
		return
	}
	s.writeMemberTicket(w, r.Context(), db, memberID, ticketID, http.StatusOK, map[string]any{"messages": messages})
}

// memberTicketTx locks one of the member's tickets for a change.
func memberTicketTx(ctx context.Context, db *sql.DB, memberID, ticketID string) (*sql.Tx, *supportTicket, error) {
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return nil, nil, err
	}
	t, err := loadSupportTicket(ctx, tx, ticketID, true)
	if err == nil && t.RequesterMemberID != memberID {
		err = errSupportNotFound
	}
	if err != nil {
		_ = tx.Rollback()
		return nil, nil, err
	}
	return tx, t, nil
}

// supportMemberReply adds a member message; it reopens resolved tickets (and
// closed ones inside the reopen window) and resets "waiting on member".
func supportMemberReply(ctx context.Context, db *sql.DB, memberID, ticketID, body string, attachmentIDs []string, now time.Time) (string, error) {
	var recent int
	if err := db.QueryRowContext(ctx, `SELECT COUNT(*) FROM support.ticket_messages m JOIN support.tickets t ON t.id=m.ticket_id
		WHERE m.author_id=$1::uuid AND m.author_kind='member' AND m.created_at > $2`, memberID, now.Add(-time.Hour)).Scan(&recent); err != nil {
		return "", err
	}
	if recent >= supportRepliesPerHour {
		e := newSupportError(http.StatusTooManyRequests, "SUPPORT_RATE_LIMITED", "You've sent a lot of messages in the last hour. Please wait a little before sending more.")
		e.retryAfter = 10 * time.Minute
		return "", e
	}
	tx, t, err := memberTicketTx(ctx, db, memberID, ticketID)
	if err != nil {
		return "", err
	}
	defer func() { _ = tx.Rollback() }()
	if t.MergedIntoID != "" {
		return "", newSupportError(http.StatusConflict, "SUPPORT_TICKET_MERGED", "This request was merged into another one. Please reply there.")
	}
	actor := supportActor{Kind: "member", ID: memberID}
	previous := t.Status
	switch t.Status {
	case "closed":
		if !t.memberCanReopen(now) {
			return "", newSupportError(http.StatusConflict, "SUPPORT_TICKET_CLOSED", errSupportClosed.Error())
		}
		t.setStatus("open", now)
	case "resolved", "pending_member":
		t.setStatus("open", now)
	}
	messageID, err := insertSupportMessageTx(ctx, tx, t.ID, actor, "public", body, "", attachmentIDs)
	if err != nil {
		return "", err
	}
	t.LastMemberMessageAt, t.LastActivityAt = &now, now
	if err = saveSupportTicketTx(ctx, tx, t, now); err != nil {
		return "", err
	}
	if previous != t.Status {
		eventType := "status_changed"
		if previous == "resolved" || previous == "closed" {
			eventType = "reopened"
		}
		if err = insertSupportEventTx(ctx, tx, t.ID, actor, eventType, previous, t.Status, map[string]any{"reason": "member_reply"}); err != nil {
			return "", err
		}
	}
	if err = insertSupportEventTx(ctx, tx, t.ID, actor, "member_replied", "", "", map[string]any{"message_id": messageID, "attachments": len(attachmentIDs)}); err != nil {
		return "", err
	}
	return messageID, tx.Commit()
}

func (s *Server) supportReply(w http.ResponseWriter, r *http.Request) {
	memberID, db, ok := s.supportMember(w, r)
	if !ok {
		return
	}
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	body := supportCleanText(toString(payload["body"]), 0)
	attachmentIDs, err := supportAttachmentIDs(payload["attachment_ids"])
	if err != nil {
		writeSupportError(w, err)
		return
	}
	if utf8.RuneCountInString(body) > supportBodyMaxRunes || (body == "" && len(attachmentIDs) == 0) {
		writeSupportError(w, newSupportError(http.StatusBadRequest, "SUPPORT_INVALID_BODY", fmt.Sprintf("Write a message of up to %d characters or attach a file.", supportBodyMaxRunes)))
		return
	}
	ticketID := chi.URLParam(r, "ticketID")
	messageID, err := supportMemberReply(r.Context(), db, memberID, ticketID, body, attachmentIDs, time.Now().UTC())
	if err != nil {
		writeSupportError(w, err)
		return
	}
	var kind, text string
	var created time.Time
	if err := db.QueryRowContext(r.Context(), `SELECT author_kind, body, created_at FROM support.ticket_messages WHERE id=$1`, messageID).Scan(&kind, &text, &created); err != nil {
		writeSupportError(w, err)
		return
	}
	attachments, err := supportAttachmentsByMessage(r.Context(), db, ticketID)
	if err != nil {
		writeSupportError(w, err)
		return
	}
	s.writeMemberTicket(w, r.Context(), db, memberID, ticketID, http.StatusCreated, map[string]any{
		"message": s.memberMessageView(ticketID, messageID, kind, text, created, attachments[messageID]),
	})
}

func (s *Server) supportCloseTicket(w http.ResponseWriter, r *http.Request) {
	memberID, db, ok := s.supportMember(w, r)
	if !ok {
		return
	}
	ticketID := chi.URLParam(r, "ticketID")
	now := time.Now().UTC()
	err := func() error {
		tx, t, err := memberTicketTx(r.Context(), db, memberID, ticketID)
		if err != nil {
			return err
		}
		defer func() { _ = tx.Rollback() }()
		if t.Status == "closed" {
			return nil
		}
		previous := t.Status
		t.setStatus("closed", now)
		t.LastActivityAt = now
		if err = saveSupportTicketTx(r.Context(), tx, t, now); err != nil {
			return err
		}
		if err = insertSupportEventTx(r.Context(), tx, t.ID, supportActor{Kind: "member", ID: memberID}, "closed_by_member", previous, "closed", nil); err != nil {
			return err
		}
		return tx.Commit()
	}()
	if err != nil {
		writeSupportError(w, err)
		return
	}
	s.writeMemberTicket(w, r.Context(), db, memberID, ticketID, http.StatusOK, nil)
}

func (s *Server) supportReopenTicket(w http.ResponseWriter, r *http.Request) {
	memberID, db, ok := s.supportMember(w, r)
	if !ok {
		return
	}
	payload := map[string]any{}
	if r.ContentLength != 0 {
		var valid bool
		if payload, valid = readJSON(w, r); !valid {
			return
		}
	}
	reason := supportCleanText(toString(payload["reason"]), supportBodyMaxRunes)
	ticketID := chi.URLParam(r, "ticketID")
	now := time.Now().UTC()
	err := func() error {
		tx, t, err := memberTicketTx(r.Context(), db, memberID, ticketID)
		if err != nil {
			return err
		}
		defer func() { _ = tx.Rollback() }()
		if t.active() {
			return nil
		}
		if !t.memberCanReopen(now) {
			return newSupportError(http.StatusConflict, "SUPPORT_REOPEN_WINDOW_PASSED", errSupportReopenExpired.Error())
		}
		previous := t.Status
		actor := supportActor{Kind: "member", ID: memberID}
		t.setStatus("open", now)
		t.LastActivityAt = now
		if reason != "" {
			if _, err = insertSupportMessageTx(r.Context(), tx, t.ID, actor, "public", reason, "", nil); err != nil {
				return err
			}
			t.LastMemberMessageAt = &now
		}
		if err = saveSupportTicketTx(r.Context(), tx, t, now); err != nil {
			return err
		}
		if err = insertSupportEventTx(r.Context(), tx, t.ID, actor, "reopened", previous, "open", nil); err != nil {
			return err
		}
		return tx.Commit()
	}()
	if err != nil {
		writeSupportError(w, err)
		return
	}
	s.writeMemberTicket(w, r.Context(), db, memberID, ticketID, http.StatusOK, nil)
}

func (s *Server) supportRateTicket(w http.ResponseWriter, r *http.Request) {
	memberID, db, ok := s.supportMember(w, r)
	if !ok {
		return
	}
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	rating, _ := strconv.Atoi(strings.TrimSpace(toString(payload["rating"])))
	if f, isFloat := payload["rating"].(float64); isFloat {
		rating = int(f)
	}
	comment := supportCleanText(toString(payload["comment"]), 0)
	if rating < 1 || rating > 5 || utf8.RuneCountInString(comment) > supportRatingCommentRunes {
		writeSupportError(w, newSupportError(http.StatusBadRequest, "SUPPORT_INVALID_RATING", "Rate from 1 to 5; comments can be up to 1000 characters."))
		return
	}
	ticketID := chi.URLParam(r, "ticketID")
	now := time.Now().UTC()
	err := func() error {
		tx, t, err := memberTicketTx(r.Context(), db, memberID, ticketID)
		if err != nil {
			return err
		}
		defer func() { _ = tx.Rollback() }()
		if t.Status != "resolved" && t.Status != "closed" {
			return newSupportError(http.StatusConflict, "SUPPORT_NOT_RESOLVED", "You can rate a request once it is resolved.")
		}
		if t.SatisfactionRating > 0 {
			return newSupportError(http.StatusConflict, "SUPPORT_ALREADY_RATED", "You've already rated this request. Thank you!")
		}
		t.SatisfactionRating, t.SatisfactionComment, t.RatedAt = rating, comment, &now
		if err = saveSupportTicketTx(r.Context(), tx, t, now); err != nil {
			return err
		}
		if err = insertSupportEventTx(r.Context(), tx, t.ID, supportActor{Kind: "member", ID: memberID}, "rated", "", strconv.Itoa(rating), nil); err != nil {
			return err
		}
		return tx.Commit()
	}()
	if err != nil {
		writeSupportError(w, err)
		return
	}
	s.writeMemberTicket(w, r.Context(), db, memberID, ticketID, http.StatusOK, nil)
}

// ── website contact form (signed-out) ────────────────────────────────────────

const (
	supportContactPerEmailHour = 3
	supportContactPerEmailDay  = 10
	supportContactPerIPHour    = 5
	supportContactGlobalHour   = 300
	supportContactMaxBodyBytes = 32 << 10
)

var supportContactLimiter = newClientErrorRateLimiter(time.Now)

// supportContact accepts a ticket from a signed-out website visitor. It never
// creates or links an account: replies go to the address given, by email,
// from the support team. Abuse controls: a honeypot field, per-IP and global
// in-memory limits (the IP is never stored) and per-address limits.
func (s *Server) supportContact(w http.ResponseWriter, r *http.Request) {
	r.Header.Del("X-User-ID")
	r.Header.Del("X-Admin-User")
	db, err := s.supportDB()
	if err != nil {
		writeSupportError(w, err)
		return
	}
	r.Body = http.MaxBytesReader(w, r.Body, supportContactMaxBodyBytes)
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	// Bots fill every field. Pretend success so they learn nothing.
	if strings.TrimSpace(toString(payload["website"])) != "" {
		writeJSON(w, http.StatusAccepted, map[string]any{"success": true, "received": true})
		return
	}
	email := strings.TrimSpace(toString(payload["email"]))
	parsed, err := mail.ParseAddress(email)
	if err != nil || parsed.Address != email || len(email) > 254 || !strings.Contains(email[strings.LastIndex(email, "@")+1:], ".") {
		writeSupportError(w, newSupportError(http.StatusBadRequest, "SUPPORT_INVALID_EMAIL", "Enter a valid email address so we can reply."))
		return
	}
	name := truncateRunes(supportSingleLine(toString(payload["name"])), 100)
	in, err := validateSupportTicketInput(map[string]any{
		"category": payload["category"], "subject": payload["subject"], "description": payload["description"],
		"locale": payload["locale"], "platform": "web",
	})
	if err != nil {
		writeSupportError(w, err)
		return
	}
	if strings.Count(strings.ToLower(in.Description), "http") > 5 {
		writeSupportError(w, newSupportError(http.StatusBadRequest, "SUPPORT_INVALID_DESCRIPTION", "Please include fewer links."))
		return
	}
	rules := []clientErrorRateRule{
		{key: hashedLimiterKey("support-contact-ip:", clientIPForRateLimit(r)), limit: supportContactPerIPHour, window: time.Hour},
		{key: "support-contact-global", limit: supportContactGlobalHour, window: time.Hour},
	}
	if allowed, wait := supportContactLimiter.allow(rules, 1); !allowed {
		e := newSupportError(http.StatusTooManyRequests, "SUPPORT_RATE_LIMITED", "Too many requests. Please try again later.")
		e.retryAfter = wait
		writeSupportError(w, e)
		return
	}
	result, err := createSupportTicket(r.Context(), db, in, "website", "", strings.ToLower(email), name, time.Now().UTC())
	if err != nil {
		writeSupportError(w, err)
		return
	}
	writeJSON(w, http.StatusAccepted, map[string]any{"success": true, "received": true, "reference": result.Reference})
}

// ── notifications ────────────────────────────────────────────────────────────

func supportNotifyMemberTx(ctx context.Context, tx *sql.Tx, t *supportTicket, actorID, eventType, dedupe, title, body string) error {
	if t.RequesterMemberID == "" {
		return nil
	}
	return enqueueNotificationTx(ctx, tx, t.RequesterMemberID, actorID, eventType, "system", t.ID, dedupe,
		title, body, "/support/tickets/"+t.ID, map[string]any{"ticket_id": t.ID, "reference": t.Reference, "status": t.Status}, 6)
}
