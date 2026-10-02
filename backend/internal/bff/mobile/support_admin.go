package mobile

import (
	"context"
	"database/sql"
	"encoding/csv"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)

// Operator side of the support ticket system (/v1/admin/support/...). The
// queue, ticket detail with internal notes and member context, assignment,
// replies and notes, canned responses, merges, bulk actions, the SLA
// dashboard and the CSV export. Route access is enforced by
// principalCanAccessAdminRoute; handlers check the role again.

// supportAgentRoles may work tickets. analyst may read the dashboard only.
var supportAgentRoles = []string{"admin", "ops_admin", "support", "trust_safety", "moderator"}

var supportReferencePattern = regexp.MustCompile(`(?i)^CN-[0-9]{4}-[0-9]{6,}$`)

func principalIsSupportAgent(principal securityPrincipal) bool {
	for _, role := range supportAgentRoles {
		if principal.Roles[role] {
			return true
		}
	}
	return false
}

func (s *Server) supportOperator(w http.ResponseWriter, r *http.Request) (string, bool) {
	principal, ok := principalFromRequest(r)
	if !ok || strings.TrimSpace(principal.UserID) == "" {
		writeError(w, http.StatusUnauthorized, errors.New("authenticated operator role is required"))
		return "", false
	}
	if !principalIsSupportAgent(principal) {
		writeError(w, http.StatusForbidden, errors.New("a support operator role is required"))
		return "", false
	}
	return principal.UserID, true
}

func (s *Server) supportOperatorDB(w http.ResponseWriter, r *http.Request) (string, *sql.DB, bool) {
	operatorID, ok := s.supportOperator(w, r)
	if !ok {
		return "", nil, false
	}
	db, err := s.supportDB()
	if err != nil {
		writeSupportError(w, err)
		return "", nil, false
	}
	return operatorID, db, true
}

// ── admin views ──────────────────────────────────────────────────────────────

const adminSupportFrom = `
	FROM support.tickets t
	LEFT JOIN user_management.users ru ON ru.id=t.requester_member_id
	LEFT JOIN user_management.users au ON au.id=t.assignee_id
	LEFT JOIN support.tickets mt ON mt.id=t.merged_into_id`

const adminSupportSelect = `SELECT ` + supportTicketColumns + `,
	COALESCE(ru.name,''), COALESCE(ru.username,''), COALESCE(au.name,''), COALESCE(mt.reference,''),
	(SELECT COUNT(*) FROM support.ticket_messages m WHERE m.ticket_id=t.id)::int` + adminSupportFrom

type adminSupportRow struct {
	ticket                  *supportTicket
	requesterName, username string
	assigneeName, mergedRef string
	messageCount            int
}

func scanAdminSupportRow(row supportScanner) (adminSupportRow, error) {
	var out adminSupportRow
	t, err := scanSupportTicketRow(row, &out.requesterName, &out.username, &out.assigneeName, &out.mergedRef, &out.messageCount)
	out.ticket = t
	return out, err
}

func loadAdminSupportRow(ctx context.Context, q supportQuerier, ticketID string) (adminSupportRow, error) {
	if _, err := uuid.Parse(ticketID); err != nil {
		return adminSupportRow{}, errSupportNotFound
	}
	row, err := scanAdminSupportRow(q.QueryRowContext(ctx, adminSupportSelect+` WHERE t.id=$1`, ticketID))
	if errors.Is(err, sql.ErrNoRows) {
		return row, errSupportNotFound
	}
	return row, err
}

func adminTicketView(row adminSupportRow, now time.Time) map[string]any {
	t := row.ticket
	state, first, resolution := t.slaState(now)
	requester := map[string]any{"kind": "member", "member_id": supportOptional(t.RequesterMemberID),
		"display_name": row.requesterName, "username": supportOptional(row.username), "email": nil}
	if t.RequesterMemberID == "" {
		name := t.ContactName
		if name == "" {
			name = t.ContactEmail
		}
		requester = map[string]any{"kind": "contact", "member_id": nil, "display_name": name, "username": nil, "email": t.ContactEmail}
	}
	var assignee, satisfaction, merged any
	if t.AssigneeID != "" {
		assignee = map[string]any{"id": t.AssigneeID, "name": row.assigneeName}
	}
	if t.SatisfactionRating > 0 {
		satisfaction = map[string]any{"rating": t.SatisfactionRating, "comment": t.SatisfactionComment, "rated_at": supportTimeValue(t.RatedAt)}
	}
	if t.MergedIntoID != "" {
		merged = map[string]any{"id": t.MergedIntoID, "reference": row.mergedRef}
	}
	awaiting := t.LastMemberMessageAt != nil && (t.LastAgentReplyAt == nil || t.LastMemberMessageAt.After(*t.LastAgentReplyAt)) && t.active()
	return map[string]any{
		"id": t.ID, "reference": t.Reference, "category": t.Category, "subject": t.Subject,
		"status": t.Status, "priority": t.Priority, "team": t.Team, "channel": t.Channel,
		"requester": requester, "assignee": assignee, "tags": t.Tags,
		"app_version": supportOptional(t.AppVersion), "platform": supportOptional(t.Platform),
		"os_version": supportOptional(t.OSVersion), "device_model": supportOptional(t.DeviceModel),
		"locale": supportOptional(t.Locale), "client_error_issue_id": supportOptional(t.ClientErrorIssueID),
		"first_response_due_at": t.FirstResponseDueAt.Format(time.RFC3339),
		"resolution_due_at":     t.ResolutionDueAt.Format(time.RFC3339),
		"first_responded_at":    supportTimeValue(t.FirstRespondedAt),
		"resolved_at":           supportTimeValue(t.ResolvedAt), "closed_at": supportTimeValue(t.ClosedAt),
		"sla":            map[string]any{"state": state, "first_response": first, "resolution": resolution},
		"awaiting_agent": awaiting, "satisfaction": satisfaction, "merged_into": merged,
		"message_count": row.messageCount,
		"created_at":    t.CreatedAt.Format(time.RFC3339), "updated_at": t.UpdatedAt.Format(time.RFC3339),
		"last_activity_at": t.LastActivityAt.Format(time.RFC3339),
	}
}

func supportOptional(value string) any {
	if value == "" {
		return nil
	}
	return value
}

func (s *Server) writeAdminTicket(w http.ResponseWriter, ctx context.Context, db *sql.DB, ticketID string, status int, extra map[string]any) {
	row, err := loadAdminSupportRow(ctx, db, ticketID)
	if err != nil {
		writeSupportError(w, err)
		return
	}
	payload := map[string]any{"success": true, "ticket": adminTicketView(row, time.Now().UTC())}
	for k, v := range extra {
		payload[k] = v
	}
	writeJSON(w, status, payload)
}

// ── queue ────────────────────────────────────────────────────────────────────

func supportListParam(values url.Values, key string, allowed map[string]bool) ([]string, error) {
	raw := strings.TrimSpace(values.Get(key))
	if raw == "" {
		return nil, nil
	}
	out := []string{}
	for _, part := range strings.Split(raw, ",") {
		part = strings.ToLower(strings.TrimSpace(part))
		if part == "" {
			continue
		}
		if !allowed[part] {
			return nil, newSupportError(http.StatusBadRequest, "SUPPORT_INVALID_FILTER", fmt.Sprintf("unknown %s %q", key, part))
		}
		out = append(out, part)
	}
	return out, nil
}

func supportCategorySet() map[string]bool {
	set := map[string]bool{}
	for key := range supportCategories {
		set[key] = true
	}
	return set
}

// buildSupportQueueFilter turns queue query parameters into a WHERE clause.
func buildSupportQueueFilter(values url.Values, operatorID string) (string, []any, error) {
	where := []string{"TRUE"}
	args := []any{}
	arg := func(value any) string {
		args = append(args, value)
		return "$" + strconv.Itoa(len(args))
	}
	inList := func(column string, list []string) {
		encoded, _ := json.Marshal(list)
		where = append(where, column+` IN (SELECT jsonb_array_elements_text(`+arg(string(encoded))+`::jsonb))`)
	}
	switch status := strings.ToLower(strings.TrimSpace(values.Get("status"))); status {
	case "", "active":
		where = append(where, supportActiveSQL)
	case "all":
	default:
		list, err := supportListParam(values, "status", supportStatuses)
		if err != nil {
			return "", nil, err
		}
		inList("t.status", list)
	}
	for _, spec := range []struct {
		key, column string
		allowed     map[string]bool
	}{
		{"category", "t.category", supportCategorySet()},
		{"priority", "t.priority", supportPriorities},
		{"team", "t.team", supportTeams},
		{"channel", "t.channel", supportChannels},
	} {
		list, err := supportListParam(values, spec.key, spec.allowed)
		if err != nil {
			return "", nil, err
		}
		if len(list) > 0 {
			inList(spec.column, list)
		}
	}
	switch assignee := strings.TrimSpace(values.Get("assignee")); assignee {
	case "":
	case "me":
		where = append(where, `t.assignee_id=`+arg(operatorID)+`::uuid`)
	case "unassigned":
		where = append(where, `t.assignee_id IS NULL`)
	default:
		if _, err := uuid.Parse(assignee); err != nil {
			return "", nil, newSupportError(http.StatusBadRequest, "SUPPORT_INVALID_FILTER", "assignee must be me, unassigned or an operator id")
		}
		where = append(where, `t.assignee_id=`+arg(assignee)+`::uuid`)
	}
	if member := strings.TrimSpace(values.Get("member")); member != "" {
		if _, err := uuid.Parse(member); err != nil {
			return "", nil, newSupportError(http.StatusBadRequest, "SUPPORT_INVALID_FILTER", "member must be a member id")
		}
		where = append(where, `t.requester_member_id=`+arg(member)+`::uuid`)
	}
	switch sla := strings.ToLower(strings.TrimSpace(values.Get("sla"))); sla {
	case "":
	case "breached":
		where = append(where, supportSLABreachedSQL)
	case "at_risk":
		where = append(where, supportSLAAtRiskSQL)
	default:
		return "", nil, newSupportError(http.StatusBadRequest, "SUPPORT_INVALID_FILTER", "sla must be breached or at_risk")
	}
	if q := strings.TrimSpace(values.Get("q")); q != "" {
		if utf8.RuneCountInString(q) > 100 {
			q = truncateRunes(q, 100)
		}
		if supportReferencePattern.MatchString(q) {
			where = append(where, `t.reference=`+arg(strings.ToUpper(q)))
		} else {
			escaped := strings.NewReplacer(`\`, `\\`, `%`, `\%`, `_`, `\_`).Replace(q)
			like := arg("%" + escaped + "%")
			exact := arg(strings.ToLower(q))
			where = append(where, `(t.subject ILIKE `+like+` OR t.reference ILIKE `+like+` OR ru.username ILIKE `+like+
				` OR ru.name ILIKE `+like+` OR lower(t.contact_email)=`+exact+` OR t.id::text=`+exact+`)`)
		}
	}
	return strings.Join(where, " AND "), args, nil
}

func supportQueueOrder(sortKey string) string {
	priority := `CASE t.priority WHEN 'urgent' THEN 4 WHEN 'high' THEN 3 WHEN 'normal' THEN 2 ELSE 1 END`
	switch sortKey {
	case "priority":
		return priority + ` DESC, t.created_at`
	case "updated":
		return `t.last_activity_at DESC, t.id`
	case "created":
		return `t.created_at DESC, t.id`
	case "oldest":
		return `t.created_at, t.id`
	default: // sla: the next due target first
		return `LEAST(CASE WHEN t.first_responded_at IS NULL AND ` + supportActiveSQL + ` THEN t.first_response_due_at END,
		              CASE WHEN ` + supportActiveSQL + ` AND t.status <> 'pending_member' THEN t.resolution_due_at END) NULLS LAST, ` + priority + ` DESC, t.created_at`
	}
}

func (s *Server) adminSupportQueue(w http.ResponseWriter, r *http.Request) {
	operatorID, db, ok := s.supportOperatorDB(w, r)
	if !ok {
		return
	}
	where, args, err := buildSupportQueueFilter(r.URL.Query(), operatorID)
	if err != nil {
		writeSupportError(w, err)
		return
	}
	limit := boundedQueryLimit(r, 50, 200)
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	offset = max(0, min(offset, 100000))
	var total int
	if err := db.QueryRowContext(r.Context(), `SELECT COUNT(*)`+adminSupportFrom+` WHERE `+where, args...).Scan(&total); err != nil {
		writeSupportError(w, err)
		return
	}
	query := adminSupportSelect + ` WHERE ` + where + ` ORDER BY ` + supportQueueOrder(r.URL.Query().Get("sort")) +
		fmt.Sprintf(` LIMIT %d OFFSET %d`, limit, offset)
	rows, err := db.QueryContext(r.Context(), query, args...)
	if err != nil {
		writeSupportError(w, err)
		return
	}
	defer rows.Close()
	now := time.Now().UTC()
	tickets := make([]map[string]any, 0)
	for rows.Next() {
		row, err := scanAdminSupportRow(rows)
		if err != nil {
			writeSupportError(w, err)
			return
		}
		tickets = append(tickets, adminTicketView(row, now))
	}
	if err := rows.Err(); err != nil {
		writeSupportError(w, err)
		return
	}
	counts := map[string]int{"new": 0, "open": 0, "pending_member": 0, "on_hold": 0, "resolved": 0, "closed": 0}
	countRows, err := db.QueryContext(r.Context(), `SELECT status, COUNT(*) FROM support.tickets GROUP BY status`)
	if err != nil {
		writeSupportError(w, err)
		return
	}
	defer countRows.Close()
	for countRows.Next() {
		var status string
		var n int
		if err := countRows.Scan(&status, &n); err != nil {
			writeSupportError(w, err)
			return
		}
		counts[status] = n
	}
	writeJSON(w, http.StatusOK, map[string]any{"success": true, "tickets": tickets, "total": total, "limit": limit, "offset": offset, "counts": counts})
}

// ── detail ───────────────────────────────────────────────────────────────────

func (s *Server) adminSupportTicketDetail(w http.ResponseWriter, r *http.Request) {
	_, db, ok := s.supportOperatorDB(w, r)
	if !ok {
		return
	}
	ctx := r.Context()
	row, err := loadAdminSupportRow(ctx, db, chi.URLParam(r, "ticketID"))
	if err != nil {
		writeSupportError(w, err)
		return
	}
	t := row.ticket
	messages, err := s.adminSupportMessages(ctx, db, t)
	if err != nil {
		writeSupportError(w, err)
		return
	}
	events, err := adminSupportEvents(ctx, db, t.ID)
	if err != nil {
		writeSupportError(w, err)
		return
	}
	var memberContext any
	if t.RequesterMemberID != "" {
		mc, err := supportMemberContext(ctx, db, t.RequesterMemberID)
		if err != nil {
			writeSupportError(w, err)
			return
		}
		memberContext = mc
	}
	related, err := supportRelatedTickets(ctx, db, t)
	if err != nil {
		writeSupportError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"success": true, "ticket": adminTicketView(row, time.Now().UTC()),
		"messages": messages, "events": events, "member_context": memberContext, "related_tickets": related})
}

func (s *Server) adminSupportMessages(ctx context.Context, q supportQuerier, t *supportTicket) ([]map[string]any, error) {
	attachments, err := supportAttachmentsByMessage(ctx, q, t.ID)
	if err != nil {
		return nil, err
	}
	rows, err := q.QueryContext(ctx, `SELECT m.id::text, m.author_kind, COALESCE(m.author_id::text,''), COALESCE(u.name,''),
		m.visibility, m.body, m.created_at, COALESCE(m.canned_response_id::text,'')
		FROM support.ticket_messages m LEFT JOIN user_management.users u ON u.id=m.author_id
		WHERE m.ticket_id=$1 ORDER BY m.created_at, m.id`, t.ID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := make([]map[string]any, 0)
	for rows.Next() {
		var id, kind, authorID, name, visibility, body, canned string
		var created time.Time
		if err := rows.Scan(&id, &kind, &authorID, &name, &visibility, &body, &created, &canned); err != nil {
			return nil, err
		}
		switch kind {
		case "contact":
			name = t.ContactName
			if name == "" {
				name = t.ContactEmail
			}
		case "system":
			name = "System"
		}
		out = append(out, map[string]any{"id": id, "author_kind": kind, "author_id": supportOptional(authorID), "author_name": name,
			"visibility": visibility, "body": body, "created_at": created.UTC().Format(time.RFC3339),
			"canned_response_id": supportOptional(canned), "attachments": s.messageAttachmentsAdmin(attachments[id])})
	}
	return out, rows.Err()
}

func (s *Server) messageAttachmentsAdmin(list []supportAttachmentView) []map[string]any {
	out := make([]map[string]any, 0, len(list))
	for _, a := range list {
		out = append(out, map[string]any{"id": a.ID, "filename": a.Filename, "content_type": a.ContentType, "size_bytes": a.SizeBytes,
			"url": s.apiPrefix() + "/admin/support/attachments/" + a.ID + "/content"})
	}
	return out
}

func adminSupportEvents(ctx context.Context, q supportQuerier, ticketID string) ([]map[string]any, error) {
	rows, err := q.QueryContext(ctx, `SELECT e.id, e.event_type, e.actor_kind, COALESCE(e.actor_id::text,''), COALESCE(u.name,''),
		COALESCE(e.from_value,''), COALESCE(e.to_value,''), e.created_at
		FROM support.ticket_events e LEFT JOIN user_management.users u ON u.id=e.actor_id
		WHERE e.ticket_id=$1 ORDER BY e.id`, ticketID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := make([]map[string]any, 0)
	for rows.Next() {
		var id int64
		var eventType, kind, actorID, name, from, to string
		var created time.Time
		if err := rows.Scan(&id, &eventType, &kind, &actorID, &name, &from, &to, &created); err != nil {
			return nil, err
		}
		if kind == "system" {
			name = "System"
		}
		out = append(out, map[string]any{"id": id, "event_type": eventType, "actor_kind": kind, "actor_id": supportOptional(actorID),
			"actor_name": name, "from_value": supportOptional(from), "to_value": supportOptional(to), "created_at": created.UTC().Format(time.RFC3339)})
	}
	return out, rows.Err()
}

// supportMemberContext is the minimum an agent needs to help: account state,
// verification and recent report counts. No profile content, messages or
// location.
func supportMemberContext(ctx context.Context, q supportQuerier, memberID string) (map[string]any, error) {
	var id, name, username, verification string
	var joined time.Time
	var active, banned, suspended, deactivated, deletionPending, erased bool
	var reportsAgainst, openAgainst, reportsFiled, tickets int
	err := q.QueryRowContext(ctx, `SELECT u.id::text, COALESCE(u.name,''), COALESCE(u.username,''), u.created_at,
		  u.is_active, COALESCE(u.is_banned,FALSE),
		  COALESCE(u.suspended_at IS NOT NULL AND (u.suspended_until IS NULL OR u.suspended_until > NOW()), FALSE),
		  u.deactivated_at IS NOT NULL, u.deletion_requested_at IS NOT NULL, u.erased_at IS NOT NULL,
		  COALESCE((SELECT v.status FROM matching.verification_states v WHERE v.user_id=u.id ORDER BY v.updated_at DESC LIMIT 1),'unverified'),
		  (SELECT COUNT(*) FROM matching.moderation_reports r WHERE r.reported_user_id=u.id AND r.created_at > NOW() - INTERVAL '90 days')::int,
		  (SELECT COUNT(*) FROM matching.moderation_reports r WHERE r.reported_user_id=u.id AND r.status IN ('pending','reviewed'))::int,
		  (SELECT COUNT(*) FROM matching.moderation_reports r WHERE r.reporter_user_id=u.id AND r.created_at > NOW() - INTERVAL '90 days')::int,
		  (SELECT COUNT(*) FROM support.tickets st WHERE st.requester_member_id=u.id)::int
		FROM user_management.users u WHERE u.id=$1::uuid`, memberID).Scan(&id, &name, &username, &joined,
		&active, &banned, &suspended, &deactivated, &deletionPending, &erased, &verification,
		&reportsAgainst, &openAgainst, &reportsFiled, &tickets)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	status := "active"
	switch {
	case erased:
		status = "erased"
	case banned:
		status = "banned"
	case suspended:
		status = "suspended"
	case deletionPending:
		status = "deletion_pending"
	case deactivated || !active:
		status = "deactivated"
	}
	return map[string]any{"member_id": id, "name": name, "username": username, "account_status": status,
		"joined_at": joined.UTC().Format(time.RFC3339), "verification_status": verification,
		"reports_against_90d": reportsAgainst, "open_reports_against": openAgainst, "reports_filed_90d": reportsFiled,
		"tickets_total": tickets}, nil
}

func supportRelatedTickets(ctx context.Context, q supportQuerier, t *supportTicket) ([]map[string]any, error) {
	query := `SELECT id::text, reference, subject, status, created_at FROM support.tickets WHERE id<>$1 AND `
	arg := t.RequesterMemberID
	if arg != "" {
		query += `requester_member_id=$2::uuid`
	} else {
		query += `requester_member_id IS NULL AND lower(contact_email)=lower($2)`
		arg = t.ContactEmail
	}
	rows, err := q.QueryContext(ctx, query+` ORDER BY created_at DESC LIMIT 10`, t.ID, arg)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := make([]map[string]any, 0)
	for rows.Next() {
		var id, reference, subject, status string
		var created time.Time
		if err := rows.Scan(&id, &reference, &subject, &status, &created); err != nil {
			return nil, err
		}
		out = append(out, map[string]any{"id": id, "reference": reference, "subject": subject, "status": status, "created_at": created.UTC().Format(time.RFC3339)})
	}
	return out, rows.Err()
}

// ── changes ──────────────────────────────────────────────────────────────────

type supportChanges struct {
	Status, Priority, Category, Team *string
	AssigneeID, ClientErrorIssueID   *string
	Tags                             *[]string
}

func optionalLower(payload map[string]any, key string) *string {
	raw, present := payload[key]
	if !present || raw == nil {
		return nil
	}
	value := strings.ToLower(strings.TrimSpace(toString(raw)))
	return &value
}

func parseSupportChanges(payload map[string]any) (supportChanges, error) {
	var ch supportChanges
	bad := func(message string) error {
		return newSupportError(http.StatusBadRequest, "SUPPORT_INVALID_CHANGE", message)
	}
	if ch.Status = optionalLower(payload, "status"); ch.Status != nil && !supportStatuses[*ch.Status] {
		return ch, bad("status must be new, open, pending_member, on_hold, resolved or closed")
	}
	if ch.Priority = optionalLower(payload, "priority"); ch.Priority != nil && !supportPriorities[*ch.Priority] {
		return ch, bad("priority must be low, normal, high or urgent")
	}
	if ch.Category = optionalLower(payload, "category"); ch.Category != nil {
		if _, ok := supportCategories[*ch.Category]; !ok {
			return ch, bad("unknown category")
		}
	}
	if ch.Team = optionalLower(payload, "team"); ch.Team != nil && !supportTeams[*ch.Team] {
		return ch, bad("team must be general, trust_safety, billing, privacy or technical")
	}
	if ch.AssigneeID = optionalLower(payload, "assignee_id"); ch.AssigneeID != nil && *ch.AssigneeID != "" {
		if _, err := uuid.Parse(*ch.AssigneeID); err != nil {
			return ch, bad("assignee_id must be an operator id or empty to unassign")
		}
	}
	if ch.ClientErrorIssueID = optionalLower(payload, "client_error_issue_id"); ch.ClientErrorIssueID != nil && *ch.ClientErrorIssueID != "" {
		if _, err := uuid.Parse(*ch.ClientErrorIssueID); err != nil {
			return ch, bad("client_error_issue_id must be a client error issue id or empty")
		}
	}
	if raw, present := payload["tags"]; present && raw != nil {
		list, ok := raw.([]any)
		if !ok || len(list) > 20 {
			return ch, bad("tags must be a list of at most 20 tags")
		}
		tags := []string{}
		seen := map[string]bool{}
		for _, item := range list {
			tag := strings.ToLower(strings.TrimSpace(toString(item)))
			if !supportTagPattern.MatchString(tag) {
				return ch, bad("tags use lowercase letters, digits, '-' or '_' (max 32)")
			}
			if !seen[tag] {
				seen[tag] = true
				tags = append(tags, tag)
			}
		}
		sort.Strings(tags)
		ch.Tags = &tags
	}
	return ch, nil
}

func supportOperatorCanAssign(ctx context.Context, q supportQuerier, userID string) (bool, error) {
	var ok bool
	err := q.QueryRowContext(ctx, `SELECT EXISTS(SELECT 1 FROM user_management.auth_account_roles r
		JOIN user_management.users u ON u.id=r.user_id
		WHERE r.user_id=$1::uuid AND r.role IN ('admin','ops_admin','support','trust_safety','moderator')
		  AND u.is_active AND u.erased_at IS NULL)`, userID).Scan(&ok)
	return ok, err
}

var supportStatusNotices = map[string][2]string{
	"resolved": {"Your request is resolved", "We've marked %s as resolved. Reply if anything still isn't right, or rate your experience."},
	"closed":   {"Your request is closed", "%s is now closed. You can reopen it from Help & Support for 14 days."},
}

// supportApplyChanges updates one ticket as an operator, in its own
// transaction, recording an event per changed field.
func supportApplyChanges(ctx context.Context, db *sql.DB, operatorID, ticketID string, ch supportChanges, now time.Time) error {
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer func() { _ = tx.Rollback() }()
	t, err := loadSupportTicket(ctx, tx, ticketID, true)
	if err != nil {
		return err
	}
	if t.MergedIntoID != "" && (ch.Status != nil || ch.Priority != nil || ch.Category != nil) {
		return newSupportError(http.StatusConflict, "SUPPORT_TICKET_MERGED", "This ticket was merged; work the ticket it was merged into.")
	}
	actor := supportActor{Kind: "agent", ID: operatorID}
	type change struct{ event, from, to string }
	changes := []change{}
	if ch.Category != nil && *ch.Category != t.Category {
		from := t.Category
		priority := t.Priority
		if *ch.Category == "safety_harassment" && supportPriorityRank[priority] < supportPriorityRank["high"] && ch.Priority == nil {
			priority = "high"
		}
		if priority != t.Priority {
			changes = append(changes, change{"priority_changed", t.Priority, priority})
		}
		t.retarget(*ch.Category, priority)
		changes = append(changes, change{"category_changed", from, t.Category})
		if ch.Team == nil && supportCategories[t.Category].Team != t.Team {
			changes = append(changes, change{"team_changed", t.Team, supportCategories[t.Category].Team})
			t.Team = supportCategories[t.Category].Team
		}
	}
	if ch.Priority != nil && *ch.Priority != t.Priority {
		changes = append(changes, change{"priority_changed", t.Priority, *ch.Priority})
		t.retarget(t.Category, *ch.Priority)
	}
	if ch.Team != nil && *ch.Team != t.Team {
		changes = append(changes, change{"team_changed", t.Team, *ch.Team})
		t.Team = *ch.Team
	}
	if ch.AssigneeID != nil && *ch.AssigneeID != t.AssigneeID {
		if *ch.AssigneeID != "" {
			ok, err := supportOperatorCanAssign(ctx, tx, *ch.AssigneeID)
			if err != nil {
				return err
			}
			if !ok {
				return newSupportError(http.StatusBadRequest, "SUPPORT_INVALID_ASSIGNEE", "Tickets can only be assigned to active support operators.")
			}
			changes = append(changes, change{"assigned", t.AssigneeID, *ch.AssigneeID})
		} else {
			changes = append(changes, change{"unassigned", t.AssigneeID, ""})
		}
		t.AssigneeID = *ch.AssigneeID
	}
	if ch.Tags != nil && strings.Join(*ch.Tags, ",") != strings.Join(t.Tags, ",") {
		changes = append(changes, change{"tags_changed", strings.Join(t.Tags, ","), strings.Join(*ch.Tags, ",")})
		t.Tags = *ch.Tags
	}
	if ch.ClientErrorIssueID != nil && *ch.ClientErrorIssueID != t.ClientErrorIssueID {
		if *ch.ClientErrorIssueID != "" {
			var exists bool
			if err := tx.QueryRowContext(ctx, `SELECT EXISTS(SELECT 1 FROM platform.client_error_issues WHERE id=$1::uuid)`, *ch.ClientErrorIssueID).Scan(&exists); err != nil {
				return err
			}
			if !exists {
				return newSupportError(http.StatusBadRequest, "SUPPORT_INVALID_CHANGE", "client error issue not found")
			}
		}
		changes = append(changes, change{"client_error_linked", t.ClientErrorIssueID, *ch.ClientErrorIssueID})
		t.ClientErrorIssueID = *ch.ClientErrorIssueID
	}
	statusChanged := ""
	if ch.Status != nil && *ch.Status != t.Status {
		changes = append(changes, change{"status_changed", t.Status, *ch.Status})
		t.setStatus(*ch.Status, now)
		statusChanged = *ch.Status
	}
	if len(changes) == 0 {
		return tx.Commit()
	}
	if err = saveSupportTicketTx(ctx, tx, t, now); err != nil {
		return err
	}
	for _, c := range changes {
		if err = insertSupportEventTx(ctx, tx, t.ID, actor, c.event, c.from, c.to, nil); err != nil {
			return err
		}
	}
	if notice, ok := supportStatusNotices[statusChanged]; ok {
		if err = supportNotifyMemberTx(ctx, tx, t, operatorID, "support.status",
			fmt.Sprintf("support:status:%s:%s:%d", t.ID, statusChanged, now.UnixNano()),
			notice[0], fmt.Sprintf(notice[1], t.Reference)); err != nil {
			return err
		}
	}
	return tx.Commit()
}

func (s *Server) adminSupportUpdateTicket(w http.ResponseWriter, r *http.Request) {
	operatorID, db, ok := s.supportOperatorDB(w, r)
	if !ok {
		return
	}
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	ch, err := parseSupportChanges(payload)
	if err != nil {
		writeSupportError(w, err)
		return
	}
	ticketID := chi.URLParam(r, "ticketID")
	if err := supportApplyChanges(r.Context(), db, operatorID, ticketID, ch, time.Now().UTC()); err != nil {
		writeSupportError(w, err)
		return
	}
	s.writeAdminTicket(w, r.Context(), db, ticketID, http.StatusOK, nil)
}

// supportClaim assigns a ticket to the operator; a new ticket becomes open.
func supportClaim(ctx context.Context, db *sql.DB, operatorID, ticketID string, force bool, now time.Time) error {
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer func() { _ = tx.Rollback() }()
	t, err := loadSupportTicket(ctx, tx, ticketID, true)
	if err != nil {
		return err
	}
	if t.AssigneeID != "" && t.AssigneeID != operatorID && !force {
		return newSupportError(http.StatusConflict, "SUPPORT_ALREADY_ASSIGNED", "Another operator already owns this ticket.")
	}
	actor := supportActor{Kind: "agent", ID: operatorID}
	if t.AssigneeID != operatorID {
		if err = insertSupportEventTx(ctx, tx, t.ID, actor, "assigned", t.AssigneeID, operatorID, map[string]any{"claimed": true}); err != nil {
			return err
		}
		t.AssigneeID = operatorID
	}
	if t.Status == "new" {
		if err = insertSupportEventTx(ctx, tx, t.ID, actor, "status_changed", "new", "open", nil); err != nil {
			return err
		}
		t.setStatus("open", now)
	}
	if err = saveSupportTicketTx(ctx, tx, t, now); err != nil {
		return err
	}
	return tx.Commit()
}

func (s *Server) adminSupportClaim(w http.ResponseWriter, r *http.Request) {
	operatorID, db, ok := s.supportOperatorDB(w, r)
	if !ok {
		return
	}
	force := r.URL.Query().Get("force") == "1"
	ticketID := chi.URLParam(r, "ticketID")
	if err := supportClaim(r.Context(), db, operatorID, ticketID, force, time.Now().UTC()); err != nil {
		writeSupportError(w, err)
		return
	}
	s.writeAdminTicket(w, r.Context(), db, ticketID, http.StatusOK, nil)
}

// ── replies and notes ────────────────────────────────────────────────────────

func supportFirstName(name, fallback string) string {
	fields := strings.Fields(name)
	if len(fields) == 0 || fields[0] == erasureTombstone {
		return fallback
	}
	return fields[0]
}

func renderSupportCanned(body, memberName, reference, agentName string) string {
	return strings.NewReplacer("{{member_name}}", memberName, "{{reference}}", reference, "{{agent_name}}", agentName).Replace(body)
}

func supportCannedForTicket(ctx context.Context, q supportQuerier, t *supportTicket, operatorID, responseID string) (string, error) {
	if _, err := uuid.Parse(responseID); err != nil {
		return "", newSupportError(http.StatusNotFound, "SUPPORT_CANNED_NOT_FOUND", "canned response not found")
	}
	var body, memberName, agentName string
	err := q.QueryRowContext(ctx, `SELECT c.body,
		  COALESCE((SELECT name FROM user_management.users WHERE id=NULLIF($2,'')::uuid),''),
		  COALESCE((SELECT name FROM user_management.users WHERE id=$3::uuid),'')
		FROM support.canned_responses c WHERE c.id=$1 AND c.is_active`, responseID, t.RequesterMemberID, operatorID).Scan(&body, &memberName, &agentName)
	if errors.Is(err, sql.ErrNoRows) {
		return "", newSupportError(http.StatusNotFound, "SUPPORT_CANNED_NOT_FOUND", "canned response not found")
	}
	if err != nil {
		return "", err
	}
	if t.RequesterMemberID == "" {
		memberName = t.ContactName
	}
	return renderSupportCanned(body, supportFirstName(memberName, "there"), t.Reference, supportFirstName(agentName, "The team")), nil
}

type supportAgentReply struct {
	Body, Visibility, CannedID, Status string
}

// supportAgentReplyTx stores an operator reply or note. A public reply sets
// the first response, assigns an unowned ticket to the replier, moves
// new/open tickets to pending_member (unless a status is given) and notifies
// the member.
func supportAgentReplyTx(ctx context.Context, db *sql.DB, operatorID, ticketID string, in supportAgentReply, now time.Time) (string, error) {
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return "", err
	}
	defer func() { _ = tx.Rollback() }()
	t, err := loadSupportTicket(ctx, tx, ticketID, true)
	if err != nil {
		return "", err
	}
	if t.MergedIntoID != "" {
		return "", newSupportError(http.StatusConflict, "SUPPORT_TICKET_MERGED", "This ticket was merged; reply on the ticket it was merged into.")
	}
	if in.Body == "" && in.CannedID != "" {
		if in.Body, err = supportCannedForTicket(ctx, tx, t, operatorID, in.CannedID); err != nil {
			return "", err
		}
	}
	if in.Body == "" || utf8.RuneCountInString(in.Body) > supportBodyMaxRunes {
		return "", newSupportError(http.StatusBadRequest, "SUPPORT_INVALID_BODY", fmt.Sprintf("Write 1-%d characters.", supportBodyMaxRunes))
	}
	if in.CannedID != "" {
		if _, err := uuid.Parse(in.CannedID); err != nil {
			return "", newSupportError(http.StatusNotFound, "SUPPORT_CANNED_NOT_FOUND", "canned response not found")
		}
		result, err := tx.ExecContext(ctx, `UPDATE support.canned_responses SET usage_count=usage_count+1 WHERE id=$1 AND is_active`, in.CannedID)
		if err != nil {
			return "", err
		}
		if n, _ := result.RowsAffected(); n == 0 {
			return "", newSupportError(http.StatusNotFound, "SUPPORT_CANNED_NOT_FOUND", "canned response not found")
		}
	}
	actor := supportActor{Kind: "agent", ID: operatorID}
	messageID, err := insertSupportMessageTx(ctx, tx, t.ID, actor, in.Visibility, in.Body, in.CannedID, nil)
	if err != nil {
		return "", err
	}
	previous := t.Status
	next := in.Status
	if in.Visibility == "public" {
		if t.FirstRespondedAt == nil {
			responded := now
			t.FirstRespondedAt = &responded
		}
		t.LastAgentReplyAt, t.LastActivityAt = &now, now
		if t.AssigneeID == "" {
			t.AssigneeID = operatorID
			if err = insertSupportEventTx(ctx, tx, t.ID, actor, "assigned", "", operatorID, map[string]any{"auto": "reply"}); err != nil {
				return "", err
			}
		}
		if next == "" && (t.Status == "new" || t.Status == "open") {
			next = "pending_member"
		}
	}
	if next != "" && next != t.Status {
		t.setStatus(next, now)
	}
	if err = saveSupportTicketTx(ctx, tx, t, now); err != nil {
		return "", err
	}
	eventType := "note_added"
	payload := map[string]any{"message_id": messageID}
	if in.CannedID != "" {
		payload["canned_response_id"] = in.CannedID
	}
	if in.Visibility == "public" {
		eventType = "agent_replied"
		if t.RequesterMemberID == "" {
			payload["delivery"] = "email_by_agent"
		}
	}
	if err = insertSupportEventTx(ctx, tx, t.ID, actor, eventType, "", "", payload); err != nil {
		return "", err
	}
	if previous != t.Status {
		if err = insertSupportEventTx(ctx, tx, t.ID, actor, "status_changed", previous, t.Status, nil); err != nil {
			return "", err
		}
	}
	if in.Visibility == "public" {
		if err = supportNotifyMemberTx(ctx, tx, t, operatorID, "support.reply", "support:reply:"+messageID,
			"Connect Support replied", "There's a new reply on your request "+t.Reference+"."); err != nil {
			return "", err
		}
	} else if notice, ok := supportStatusNotices[t.Status]; ok && previous != t.Status {
		if err = supportNotifyMemberTx(ctx, tx, t, operatorID, "support.status",
			fmt.Sprintf("support:status:%s:%s:%d", t.ID, t.Status, now.UnixNano()), notice[0], fmt.Sprintf(notice[1], t.Reference)); err != nil {
			return "", err
		}
	}
	return messageID, tx.Commit()
}

func (s *Server) adminSupportReply(w http.ResponseWriter, r *http.Request) {
	operatorID, db, ok := s.supportOperatorDB(w, r)
	if !ok {
		return
	}
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	in := supportAgentReply{
		Body:       supportCleanText(toString(payload["body"]), 0),
		Visibility: strings.ToLower(strings.TrimSpace(toString(payload["visibility"]))),
		CannedID:   strings.TrimSpace(toString(payload["canned_response_id"])),
		Status:     strings.ToLower(strings.TrimSpace(toString(payload["status"]))),
	}
	if in.Visibility == "" {
		in.Visibility = "public"
	}
	if in.Visibility != "public" && in.Visibility != "internal" {
		writeSupportError(w, newSupportError(http.StatusBadRequest, "SUPPORT_INVALID_VISIBILITY", "visibility must be public or internal"))
		return
	}
	if in.Status != "" && !supportStatuses[in.Status] {
		writeSupportError(w, newSupportError(http.StatusBadRequest, "SUPPORT_INVALID_CHANGE", "unknown status"))
		return
	}
	ticketID := chi.URLParam(r, "ticketID")
	messageID, err := supportAgentReplyTx(r.Context(), db, operatorID, ticketID, in, time.Now().UTC())
	if err != nil {
		writeSupportError(w, err)
		return
	}
	row, err := loadAdminSupportRow(r.Context(), db, ticketID)
	if err != nil {
		writeSupportError(w, err)
		return
	}
	messages, err := s.adminSupportMessages(r.Context(), db, row.ticket)
	if err != nil {
		writeSupportError(w, err)
		return
	}
	var message map[string]any
	for _, m := range messages {
		if m["id"] == messageID {
			message = m
		}
	}
	writeJSON(w, http.StatusCreated, map[string]any{"success": true, "ticket": adminTicketView(row, time.Now().UTC()), "message": message})
}

func (s *Server) adminSupportCannedPreview(w http.ResponseWriter, r *http.Request) {
	operatorID, db, ok := s.supportOperatorDB(w, r)
	if !ok {
		return
	}
	t, err := loadSupportTicket(r.Context(), db, chi.URLParam(r, "ticketID"), false)
	if err != nil {
		writeSupportError(w, err)
		return
	}
	body, err := supportCannedForTicket(r.Context(), db, t, operatorID, chi.URLParam(r, "responseID"))
	if err != nil {
		writeSupportError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"success": true, "body": body})
}

// ── merge ────────────────────────────────────────────────────────────────────

// supportMerge folds source into target: messages and attachments move,
// the source closes with merged_into set, both trails record the merge.
// Only tickets from the same requester can be merged.
func supportMerge(ctx context.Context, db *sql.DB, operatorID, sourceID, targetID string, now time.Time) error {
	if sourceID == targetID {
		return newSupportError(http.StatusBadRequest, "SUPPORT_INVALID_MERGE", "A ticket cannot be merged into itself.")
	}
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer func() { _ = tx.Rollback() }()
	// Lock in id order so two opposite merges cannot deadlock.
	first, second := sourceID, targetID
	if second < first {
		first, second = second, first
	}
	locked := map[string]*supportTicket{}
	for _, id := range []string{first, second} {
		t, err := loadSupportTicket(ctx, tx, id, true)
		if err != nil {
			return err
		}
		locked[id] = t
	}
	source, target := locked[sourceID], locked[targetID]
	if source.MergedIntoID != "" || target.MergedIntoID != "" {
		return newSupportError(http.StatusConflict, "SUPPORT_INVALID_MERGE", "One of these tickets was already merged.")
	}
	sameRequester := source.RequesterMemberID != "" && source.RequesterMemberID == target.RequesterMemberID ||
		source.RequesterMemberID == "" && target.RequesterMemberID == "" && strings.EqualFold(source.ContactEmail, target.ContactEmail)
	if !sameRequester {
		return newSupportError(http.StatusConflict, "SUPPORT_INVALID_MERGE", "Only tickets from the same requester can be merged.")
	}
	if target.Status == "closed" {
		return newSupportError(http.StatusConflict, "SUPPORT_INVALID_MERGE", "Reopen the target ticket before merging into it.")
	}
	if _, err = tx.ExecContext(ctx, `UPDATE support.ticket_messages SET ticket_id=$2 WHERE ticket_id=$1`, source.ID, target.ID); err != nil {
		return err
	}
	if _, err = tx.ExecContext(ctx, `UPDATE support.ticket_attachments SET ticket_id=$2 WHERE ticket_id=$1`, source.ID, target.ID); err != nil {
		return err
	}
	system := supportActor{Kind: "system"}
	if _, err = insertSupportMessageTx(ctx, tx, target.ID, system, "public",
		fmt.Sprintf("Request %s (%s) was merged into this one.", source.Reference, source.Subject), "", nil); err != nil {
		return err
	}
	if at := source.LastMemberMessageAt; at != nil && (target.LastMemberMessageAt == nil || at.After(*target.LastMemberMessageAt)) {
		target.LastMemberMessageAt = at
	}
	if target.Status == "resolved" {
		target.setStatus("open", now)
	}
	target.LastActivityAt = now
	previous := source.Status
	source.setStatus("closed", now)
	source.MergedIntoID, source.LastActivityAt = target.ID, now
	if err = saveSupportTicketTx(ctx, tx, source, now); err != nil {
		return err
	}
	if err = saveSupportTicketTx(ctx, tx, target, now); err != nil {
		return err
	}
	actor := supportActor{Kind: "agent", ID: operatorID}
	if err = insertSupportEventTx(ctx, tx, source.ID, actor, "merged_into", previous, target.Reference, map[string]any{"target_id": target.ID}); err != nil {
		return err
	}
	if err = insertSupportEventTx(ctx, tx, target.ID, actor, "merged", source.Reference, target.Reference, map[string]any{"source_id": source.ID}); err != nil {
		return err
	}
	return tx.Commit()
}

func (s *Server) adminSupportMerge(w http.ResponseWriter, r *http.Request) {
	operatorID, db, ok := s.supportOperatorDB(w, r)
	if !ok {
		return
	}
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	target := strings.TrimSpace(toString(payload["into_ticket_id"]))
	if ref := strings.TrimSpace(toString(payload["into_reference"])); target == "" && supportReferencePattern.MatchString(ref) {
		if err := db.QueryRowContext(r.Context(), `SELECT id::text FROM support.tickets WHERE reference=$1`, strings.ToUpper(ref)).Scan(&target); err != nil {
			writeSupportError(w, err)
			return
		}
	}
	if _, err := uuid.Parse(target); err != nil {
		writeSupportError(w, newSupportError(http.StatusBadRequest, "SUPPORT_INVALID_MERGE", "into_ticket_id (or into_reference) is required"))
		return
	}
	if err := supportMerge(r.Context(), db, operatorID, chi.URLParam(r, "ticketID"), target, time.Now().UTC()); err != nil {
		writeSupportError(w, err)
		return
	}
	s.writeAdminTicket(w, r.Context(), db, target, http.StatusOK, nil)
}

// ── bulk ─────────────────────────────────────────────────────────────────────

func (s *Server) adminSupportBulk(w http.ResponseWriter, r *http.Request) {
	operatorID, db, ok := s.supportOperatorDB(w, r)
	if !ok {
		return
	}
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	rawIDs, _ := payload["ticket_ids"].([]any)
	if len(rawIDs) == 0 || len(rawIDs) > 100 {
		writeSupportError(w, newSupportError(http.StatusBadRequest, "SUPPORT_INVALID_BULK", "ticket_ids must list 1-100 tickets"))
		return
	}
	action := strings.ToLower(strings.TrimSpace(toString(payload["action"])))
	value := strings.ToLower(strings.TrimSpace(toString(payload["value"])))
	var ch supportChanges
	switch action {
	case "claim":
	case "assign":
		ch.AssigneeID = &value
	case "status":
		ch.Status = &value
	case "priority":
		ch.Priority = &value
	default:
		writeSupportError(w, newSupportError(http.StatusBadRequest, "SUPPORT_INVALID_BULK", "action must be claim, assign, status or priority"))
		return
	}
	if action != "claim" {
		changes := map[string]any{}
		switch action {
		case "assign":
			changes["assignee_id"] = value
		default:
			changes[action] = value
		}
		if _, err := parseSupportChanges(changes); err != nil {
			writeSupportError(w, err)
			return
		}
	}
	now := time.Now().UTC()
	updated := []string{}
	failed := []map[string]any{}
	seen := map[string]bool{}
	for _, raw := range rawIDs {
		id := strings.TrimSpace(toString(raw))
		if seen[id] {
			continue
		}
		seen[id] = true
		var err error
		if action == "claim" {
			err = supportClaim(r.Context(), db, operatorID, id, false, now)
		} else {
			err = supportApplyChanges(r.Context(), db, operatorID, id, ch, now)
		}
		if err != nil {
			message := "update failed"
			var se *supportError
			if errors.As(err, &se) {
				message = se.message
			} else if errors.Is(err, errSupportNotFound) {
				message = errSupportNotFound.Error()
			}
			failed = append(failed, map[string]any{"id": id, "error": message})
			continue
		}
		updated = append(updated, id)
	}
	writeJSON(w, http.StatusOK, map[string]any{"success": true, "updated": updated, "failed": failed})
}

// ── dashboard ────────────────────────────────────────────────────────────────

func (s *Server) adminSupportDashboard(w http.ResponseWriter, r *http.Request) {
	principal, ok := principalFromRequest(r)
	if !ok || (!principalIsSupportAgent(principal) && !principal.Roles["analyst"]) {
		writeError(w, http.StatusForbidden, errors.New("a support operator or analyst role is required"))
		return
	}
	db, err := s.supportDB()
	if err != nil {
		writeSupportError(w, err)
		return
	}
	days, _ := strconv.Atoi(r.URL.Query().Get("days"))
	if days < 1 || days > 365 {
		days = 30
	}
	dashboard, err := supportDashboard(r.Context(), db, days, time.Now().UTC())
	if err != nil {
		writeSupportError(w, err)
		return
	}
	dashboard["success"] = true
	writeJSON(w, http.StatusOK, dashboard)
}

func supportDashboard(ctx context.Context, db *sql.DB, days int, now time.Time) (map[string]any, error) {
	since := now.AddDate(0, 0, -days)
	group := func(column string, keys []string) (map[string]int, error) {
		out := map[string]int{}
		for _, k := range keys {
			out[k] = 0
		}
		rows, err := db.QueryContext(ctx, `SELECT `+column+`, COUNT(*) FROM support.tickets t WHERE `+supportActiveSQL+` GROUP BY 1`)
		if err != nil {
			return nil, err
		}
		defer rows.Close()
		for rows.Next() {
			var key string
			var n int
			if err := rows.Scan(&key, &n); err != nil {
				return nil, err
			}
			out[key] = n
		}
		return out, rows.Err()
	}
	byStatus, err := group("t.status", []string{"new", "open", "pending_member", "on_hold"})
	if err != nil {
		return nil, err
	}
	byPriority, err := group("t.priority", []string{"low", "normal", "high", "urgent"})
	if err != nil {
		return nil, err
	}
	byTeam, err := group("t.team", []string{"general", "trust_safety", "billing", "privacy", "technical"})
	if err != nil {
		return nil, err
	}
	var firstBreaches, resolutionBreaches, atRiskCount int
	var medianFirst, medianResolution sql.NullFloat64
	if err := db.QueryRowContext(ctx, `SELECT
		  COUNT(*) FILTER (WHERE `+supportActiveSQL+` AND (t.first_response_breached OR (t.first_responded_at IS NULL AND t.first_response_due_at < NOW()))),
		  COUNT(*) FILTER (WHERE `+supportActiveSQL+` AND (t.resolution_breached OR (t.status <> 'pending_member' AND t.resolution_due_at < NOW()))),
		  COUNT(*) FILTER (WHERE `+supportSLAAtRiskSQL+`)
		FROM support.tickets t`).Scan(&firstBreaches, &resolutionBreaches, &atRiskCount); err != nil {
		return nil, err
	}
	if err := db.QueryRowContext(ctx, `SELECT
		  percentile_cont(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM (t.first_responded_at - t.created_at))/60)
		    FILTER (WHERE t.first_responded_at IS NOT NULL AND t.created_at >= $1),
		  percentile_cont(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM (t.resolved_at - t.created_at))/60)
		    FILTER (WHERE t.resolved_at IS NOT NULL AND t.resolved_at >= $1)
		FROM support.tickets t`, since).Scan(&medianFirst, &medianResolution); err != nil {
		return nil, err
	}
	var csatAverage sql.NullFloat64
	var csatResponses int
	distribution := map[string]int{"1": 0, "2": 0, "3": 0, "4": 0, "5": 0}
	rows, err := db.QueryContext(ctx, `SELECT satisfaction_rating, COUNT(*) FROM support.tickets
		WHERE satisfaction_rating IS NOT NULL AND rated_at >= $1 GROUP BY 1`, since)
	if err != nil {
		return nil, err
	}
	total := 0
	for rows.Next() {
		var rating, n int
		if err := rows.Scan(&rating, &n); err != nil {
			rows.Close()
			return nil, err
		}
		distribution[strconv.Itoa(rating)] = n
		csatResponses += n
		total += rating * n
	}
	rows.Close()
	if csatResponses > 0 {
		csatAverage = sql.NullFloat64{Float64: float64(total) / float64(csatResponses), Valid: true}
	}
	daily := []map[string]any{}
	rows, err = db.QueryContext(ctx, `SELECT d::date::text,
		  (SELECT COUNT(*) FROM support.tickets t WHERE t.created_at >= d AND t.created_at < d + INTERVAL '1 day')::int,
		  (SELECT COUNT(*) FROM support.tickets t WHERE t.resolved_at >= d AND t.resolved_at < d + INTERVAL '1 day')::int
		FROM generate_series(date_trunc('day', $1::timestamptz AT TIME ZONE 'UTC') AT TIME ZONE 'UTC',
		                     date_trunc('day', $2::timestamptz AT TIME ZONE 'UTC') AT TIME ZONE 'UTC', INTERVAL '1 day') d
		ORDER BY d`, since, now)
	if err != nil {
		return nil, err
	}
	for rows.Next() {
		var day string
		var created, resolved int
		if err := rows.Scan(&day, &created, &resolved); err != nil {
			rows.Close()
			return nil, err
		}
		daily = append(daily, map[string]any{"day": day, "created": created, "resolved": resolved})
	}
	rows.Close()
	byCategory := []map[string]any{}
	rows, err = db.QueryContext(ctx, `SELECT t.category,
		  COUNT(*) FILTER (WHERE `+supportActiveSQL+`)::int,
		  COUNT(*) FILTER (WHERE t.created_at >= $1)::int
		FROM support.tickets t GROUP BY t.category ORDER BY 3 DESC, 1`, since)
	if err != nil {
		return nil, err
	}
	for rows.Next() {
		var category string
		var open, created int
		if err := rows.Scan(&category, &open, &created); err != nil {
			rows.Close()
			return nil, err
		}
		byCategory = append(byCategory, map[string]any{"category": category, "open": open, "created": created})
	}
	rows.Close()
	var safetyOpen, safetyBreached, safetyAtRisk int
	if err := db.QueryRowContext(ctx, `SELECT
		  COUNT(*) FILTER (WHERE `+supportActiveSQL+`),
		  COUNT(*) FILTER (WHERE `+supportActiveSQL+` AND `+supportSLABreachedSQL+`),
		  COUNT(*) FILTER (WHERE `+supportSLAAtRiskSQL+`)
		FROM support.tickets t WHERE t.category='safety_harassment'`).Scan(&safetyOpen, &safetyBreached, &safetyAtRisk); err != nil {
		return nil, err
	}
	nullable := func(v sql.NullFloat64) any {
		if !v.Valid {
			return nil
		}
		return float64(int(v.Float64*10+0.5)) / 10
	}
	return map[string]any{
		"window_days": days, "open_by_status": byStatus, "open_by_priority": byPriority, "open_by_team": byTeam,
		"breaches":                      map[string]any{"first_response": firstBreaches, "resolution": resolutionBreaches, "at_risk": atRiskCount},
		"median_first_response_minutes": nullable(medianFirst), "median_resolution_minutes": nullable(medianResolution),
		"csat":  map[string]any{"average": nullable(csatAverage), "responses": csatResponses, "distribution": distribution},
		"daily": daily, "by_category": byCategory,
		"safety": map[string]any{"open": safetyOpen, "breached": safetyBreached, "at_risk": safetyAtRisk},
	}, nil
}

// ── CSV export ───────────────────────────────────────────────────────────────

// csvSafe defuses spreadsheet formula injection.
func csvSafe(value string) string {
	if value != "" && strings.ContainsRune("=+-@\t\r", rune(value[0])) {
		return "'" + value
	}
	return value
}

func minutesBetween(from time.Time, to *time.Time) string {
	if to == nil {
		return ""
	}
	return strconv.FormatFloat(to.Sub(from).Minutes(), 'f', 1, 64)
}

// adminSupportExport streams the filtered queue as CSV. Operational fields
// only: no subjects, message text, names or email addresses.
func (s *Server) adminSupportExport(w http.ResponseWriter, r *http.Request) {
	operatorID, db, ok := s.supportOperatorDB(w, r)
	if !ok {
		return
	}
	values := r.URL.Query()
	if values.Get("status") == "" {
		values.Set("status", "all")
	}
	where, args, err := buildSupportQueueFilter(values, operatorID)
	if err != nil {
		writeSupportError(w, err)
		return
	}
	rows, err := db.QueryContext(r.Context(), adminSupportSelect+` WHERE `+where+` ORDER BY t.created_at DESC LIMIT 10000`, args...)
	if err != nil {
		writeSupportError(w, err)
		return
	}
	defer rows.Close()
	now := time.Now().UTC()
	w.Header().Set("Content-Type", "text/csv; charset=utf-8")
	w.Header().Set("Content-Disposition", fmt.Sprintf(`attachment; filename="support-tickets-%s.csv"`, now.Format("20060102-1504")))
	w.Header().Set("Cache-Control", "private, no-store")
	out := csv.NewWriter(w)
	_ = out.Write([]string{"reference", "created_at", "channel", "category", "team", "priority", "status", "requester_kind",
		"assignee", "first_response_due_at", "first_responded_at", "first_response_minutes", "resolution_due_at", "resolved_at",
		"resolution_minutes", "closed_at", "first_response_breached", "resolution_breached", "sla_state", "satisfaction_rating", "tags", "merged_into"})
	formatTime := func(t *time.Time) string {
		if t == nil {
			return ""
		}
		return t.UTC().Format(time.RFC3339)
	}
	for rows.Next() {
		row, err := scanAdminSupportRow(rows)
		if err != nil {
			break
		}
		t := row.ticket
		state, _, _ := t.slaState(now)
		kind := "member"
		if t.RequesterMemberID == "" {
			kind = "contact"
		}
		rating := ""
		if t.SatisfactionRating > 0 {
			rating = strconv.Itoa(t.SatisfactionRating)
		}
		due, resDue := t.FirstResponseDueAt, t.ResolutionDueAt
		_ = out.Write([]string{t.Reference, t.CreatedAt.Format(time.RFC3339), t.Channel, t.Category, t.Team, t.Priority, t.Status, kind,
			csvSafe(row.assigneeName), formatTime(&due), formatTime(t.FirstRespondedAt), minutesBetween(t.CreatedAt, t.FirstRespondedAt),
			formatTime(&resDue), formatTime(t.ResolvedAt), minutesBetween(t.CreatedAt, t.ResolvedAt), formatTime(t.ClosedAt),
			strconv.FormatBool(t.FirstResponseBreached), strconv.FormatBool(t.ResolutionBreached), state, rating,
			csvSafe(strings.Join(t.Tags, " ")), row.mergedRef})
	}
	out.Flush()
}

// ── agents and canned responses ──────────────────────────────────────────────

func (s *Server) adminSupportAgents(w http.ResponseWriter, r *http.Request) {
	_, db, ok := s.supportOperatorDB(w, r)
	if !ok {
		return
	}
	rows, err := db.QueryContext(r.Context(), `SELECT u.id::text, COALESCE(u.name,''),
		  array_to_json(array_agg(DISTINCT r.role ORDER BY r.role))::text,
		  (SELECT COUNT(*) FROM support.tickets t WHERE t.assignee_id=u.id AND `+supportActiveSQL+`)::int
		FROM user_management.auth_account_roles r JOIN user_management.users u ON u.id=r.user_id
		WHERE r.role IN ('admin','ops_admin','support','trust_safety','moderator') AND u.is_active AND u.erased_at IS NULL
		GROUP BY u.id ORDER BY lower(COALESCE(u.name,'')), u.id LIMIT 500`)
	if err != nil {
		writeSupportError(w, err)
		return
	}
	defer rows.Close()
	agents := make([]map[string]any, 0)
	for rows.Next() {
		var id, name, rolesJSON string
		var open int
		if err := rows.Scan(&id, &name, &rolesJSON, &open); err != nil {
			writeSupportError(w, err)
			return
		}
		roles := []string{}
		_ = json.Unmarshal([]byte(rolesJSON), &roles)
		agents = append(agents, map[string]any{"id": id, "name": name, "roles": roles, "open_assigned": open})
	}
	writeJSON(w, http.StatusOK, map[string]any{"success": true, "agents": agents})
}

const supportCannedColumns = `id::text, title, body, COALESCE(category,''), is_active, usage_count, updated_at`

func scanCannedResponse(row supportScanner) (map[string]any, error) {
	var id, title, body, category string
	var active bool
	var usage int
	var updated time.Time
	if err := row.Scan(&id, &title, &body, &category, &active, &usage, &updated); err != nil {
		return nil, err
	}
	return map[string]any{"id": id, "title": title, "body": body, "category": supportOptional(category),
		"is_active": active, "usage_count": usage, "updated_at": updated.UTC().Format(time.RFC3339)}, nil
}

func (s *Server) adminSupportListCanned(w http.ResponseWriter, r *http.Request) {
	_, db, ok := s.supportOperatorDB(w, r)
	if !ok {
		return
	}
	query := `SELECT ` + supportCannedColumns + ` FROM support.canned_responses`
	if r.URL.Query().Get("include_inactive") != "1" {
		query += ` WHERE is_active`
	}
	rows, err := db.QueryContext(r.Context(), query+` ORDER BY is_active DESC, usage_count DESC, lower(title) LIMIT 500`)
	if err != nil {
		writeSupportError(w, err)
		return
	}
	defer rows.Close()
	list := make([]map[string]any, 0)
	for rows.Next() {
		item, err := scanCannedResponse(rows)
		if err != nil {
			writeSupportError(w, err)
			return
		}
		list = append(list, item)
	}
	writeJSON(w, http.StatusOK, map[string]any{"success": true, "canned_responses": list})
}

func parseCannedInput(payload map[string]any, partial bool) (map[string]any, error) {
	out := map[string]any{}
	bad := func(message string) error {
		return newSupportError(http.StatusBadRequest, "SUPPORT_INVALID_CANNED", message)
	}
	if raw, ok := payload["title"]; ok || !partial {
		title := supportSingleLine(toString(raw))
		if n := utf8.RuneCountInString(title); n < 1 || n > 120 {
			return nil, bad("title must be 1-120 characters")
		}
		out["title"] = title
	}
	if raw, ok := payload["body"]; ok || !partial {
		body := supportCleanText(toString(raw), 0)
		if n := utf8.RuneCountInString(body); n < 1 || n > supportBodyMaxRunes {
			return nil, bad("body must be 1-5000 characters")
		}
		out["body"] = body
	}
	if raw, ok := payload["category"]; ok {
		category := strings.ToLower(strings.TrimSpace(toString(raw)))
		if _, known := supportCategories[category]; category != "" && !known {
			return nil, bad("unknown category")
		}
		out["category"] = category
	}
	if raw, ok := payload["is_active"]; ok && partial {
		active, isBool := raw.(bool)
		if !isBool {
			return nil, bad("is_active must be true or false")
		}
		out["is_active"] = active
	}
	return out, nil
}

func supportCannedConflict(err error) error {
	if err != nil && strings.Contains(err.Error(), "uq_support_canned_title") {
		return newSupportError(http.StatusConflict, "SUPPORT_CANNED_EXISTS", "A canned response with this title already exists.")
	}
	return err
}

func (s *Server) adminSupportCreateCanned(w http.ResponseWriter, r *http.Request) {
	operatorID, db, ok := s.supportOperatorDB(w, r)
	if !ok {
		return
	}
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	in, err := parseCannedInput(payload, false)
	if err != nil {
		writeSupportError(w, err)
		return
	}
	category, _ := in["category"].(string)
	item, err := scanCannedResponse(db.QueryRowContext(r.Context(), `INSERT INTO support.canned_responses (title, body, category, created_by, updated_by)
		VALUES ($1, $2, NULLIF($3,''), $4::uuid, $4::uuid) RETURNING `+supportCannedColumns, in["title"], in["body"], category, operatorID))
	if err != nil {
		writeSupportError(w, supportCannedConflict(err))
		return
	}
	writeJSON(w, http.StatusCreated, map[string]any{"success": true, "canned_response": item})
}

func (s *Server) adminSupportUpdateCanned(w http.ResponseWriter, r *http.Request) {
	operatorID, db, ok := s.supportOperatorDB(w, r)
	if !ok {
		return
	}
	responseID := chi.URLParam(r, "responseID")
	if _, err := uuid.Parse(responseID); err != nil {
		writeSupportError(w, newSupportError(http.StatusNotFound, "SUPPORT_CANNED_NOT_FOUND", "canned response not found"))
		return
	}
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	in, err := parseCannedInput(payload, true)
	if err != nil {
		writeSupportError(w, err)
		return
	}
	title, hasTitle := in["title"].(string)
	body, hasBody := in["body"].(string)
	category, hasCategory := in["category"].(string)
	active, hasActive := in["is_active"].(bool)
	item, err := scanCannedResponse(db.QueryRowContext(r.Context(), `UPDATE support.canned_responses SET
		  title=CASE WHEN $2 THEN $3 ELSE title END,
		  body=CASE WHEN $4 THEN $5 ELSE body END,
		  category=CASE WHEN $6 THEN NULLIF($7,'') ELSE category END,
		  is_active=CASE WHEN $8 THEN $9 ELSE is_active END,
		  updated_by=$10::uuid, updated_at=NOW()
		WHERE id=$1 RETURNING `+supportCannedColumns,
		responseID, hasTitle, title, hasBody, body, hasCategory, category, hasActive, active, operatorID))
	if errors.Is(err, sql.ErrNoRows) {
		writeSupportError(w, newSupportError(http.StatusNotFound, "SUPPORT_CANNED_NOT_FOUND", "canned response not found"))
		return
	}
	if err != nil {
		writeSupportError(w, supportCannedConflict(err))
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"success": true, "canned_response": item})
}

func (s *Server) adminSupportDeleteCanned(w http.ResponseWriter, r *http.Request) {
	operatorID, db, ok := s.supportOperatorDB(w, r)
	if !ok {
		return
	}
	responseID := chi.URLParam(r, "responseID")
	if _, err := uuid.Parse(responseID); err != nil {
		writeSupportError(w, newSupportError(http.StatusNotFound, "SUPPORT_CANNED_NOT_FOUND", "canned response not found"))
		return
	}
	// Deactivated, not deleted: past replies keep their reference.
	item, err := scanCannedResponse(db.QueryRowContext(r.Context(), `UPDATE support.canned_responses
		SET is_active=FALSE, updated_by=$2::uuid, updated_at=NOW() WHERE id=$1 RETURNING `+supportCannedColumns, responseID, operatorID))
	if errors.Is(err, sql.ErrNoRows) {
		writeSupportError(w, newSupportError(http.StatusNotFound, "SUPPORT_CANNED_NOT_FOUND", "canned response not found"))
		return
	}
	if err != nil {
		writeSupportError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"success": true, "canned_response": item})
}
