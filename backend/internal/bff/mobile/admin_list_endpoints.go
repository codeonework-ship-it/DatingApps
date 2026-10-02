package mobile

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"net/http"
	"slices"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
)

// SQL-backed pages for the admin list endpoints that used to go through the
// mediator or an unpaged repository call. Each returns the same item type the
// older path returned, so the JSON shape is unchanged; the handler adds
// total, limit and offset (see admin_list_query.go).

// adminListDB is the SQL pool the paged admin lists read from, or nil when
// the deployment has none (the handlers then keep their older path).
func (s *Server) adminListDB() *sql.DB {
	if s == nil || s.store == nil || s.store.profileRepo == nil {
		return nil
	}
	return s.store.profileRepo.pg
}

// ── activities ──────────────────────────────────────────────────────────────

var adminActivitiesSpec = adminListSpec{
	DefaultLimit: 100, MaxLimit: 500,
	Sorts:       map[string]string{"created_at": "created_at"},
	DefaultSort: "created_at", TieBreak: "id {dir}",
}

type activityListFilter struct {
	UserID, ActorUserID, Member string
	EventName, EventDomain      string
	ExcludeDomains              []string
}

func parseActivityListFilter(r *http.Request) (activityListFilter, error) {
	var f activityListFilter
	var err error
	if f.UserID, err = adminUUIDParam(r, "user_id"); err != nil {
		return f, err
	}
	if f.ActorUserID, err = adminUUIDParam(r, "actor_user_id"); err != nil {
		return f, err
	}
	if f.Member, err = adminUUIDParam(r, "member"); err != nil {
		return f, err
	}
	values := r.URL.Query()
	f.EventName = strings.TrimSpace(values.Get("event_name"))
	f.EventDomain = strings.TrimSpace(values.Get("event_domain"))
	for _, raw := range values["exclude_domain"] {
		for _, domain := range strings.Split(raw, ",") {
			if domain = strings.TrimSpace(domain); domain != "" && !slices.Contains(f.ExcludeDomains, domain) {
				f.ExcludeDomains = append(f.ExcludeDomains, domain)
			}
		}
	}
	if len(f.ExcludeDomains) > 20 {
		return f, errors.New("exclude_domain accepts at most 20 domains")
	}
	return f, nil
}

func listActivityEventsPage(ctx context.Context, db adminPageQueryer, f activityListFilter, p adminListParams) ([]activityEvent, int, error) {
	filter := newSQLFilter()
	filter.Eq("user_id", f.UserID).Eq("actor_user_id", f.ActorUserID)
	if f.Member != "" {
		member := filter.Arg(f.Member)
		filter.Where("(user_id = " + member + " OR actor_user_id = " + member + ")")
	}
	filter.Eq("event_name", f.EventName).Eq("event_domain", f.EventDomain)
	if len(f.ExcludeDomains) > 0 {
		placeholders := make([]string, 0, len(f.ExcludeDomains))
		for _, domain := range f.ExcludeDomains {
			placeholders = append(placeholders, filter.Arg(domain))
		}
		filter.Where("(event_domain IS NULL OR event_domain NOT IN (" + strings.Join(placeholders, ",") + "))")
	}
	filter.Search(p.Q, "event_name", "event_domain")
	filter.TimeRange("created_at", p)
	rows, total, err := queryAdminMapPage(ctx, db,
		`id,event_name,event_domain,user_id,actor_user_id,payload,created_at`,
		` FROM matching.activity_events`, filter, p)
	if err != nil {
		return nil, 0, err
	}
	items := make([]activityEvent, 0, len(rows))
	for _, row := range rows {
		items = append(items, mapActivityEventRow(row))
	}
	return items, total, nil
}

// filterActivityMaps applies the activity filters to rows from the older
// (repository or in-memory) path, newest first, so that path keeps working
// with the same parameters. It only sees the rows that path returned.
func filterActivityMaps(rows []map[string]any, f activityListFilter, p adminListParams) ([]map[string]any, int) {
	q := strings.ToLower(p.Q)
	matched := make([]map[string]any, 0, len(rows))
	for _, row := range rows {
		userID := strings.ToLower(toString(row["user_id"]))
		actor := strings.ToLower(toString(row["actor"]))
		name := toString(row["action"])
		domain := activityEventDomain(toString(row["domain"]))
		switch {
		case f.UserID != "" && userID != f.UserID,
			f.ActorUserID != "" && actor != f.ActorUserID,
			f.Member != "" && userID != f.Member && actor != f.Member,
			f.EventName != "" && name != f.EventName,
			f.EventDomain != "" && domain != f.EventDomain,
			slices.Contains(f.ExcludeDomains, domain),
			q != "" && !strings.Contains(strings.ToLower(name), q) && !strings.Contains(strings.ToLower(domain), q):
			continue
		}
		if !p.From.IsZero() || !p.To.IsZero() {
			created, err := time.Parse(time.RFC3339Nano, toString(row["created_at"]))
			if err != nil || !p.InRange(created) {
				continue
			}
		}
		matched = append(matched, row)
	}
	if p.Order == "asc" {
		slices.Reverse(matched)
	}
	total := len(matched)
	start := min(p.Offset, total)
	end := min(start+p.Limit, total)
	return matched[start:end], total
}

// ── verifications ───────────────────────────────────────────────────────────

var adminVerificationsSpec = adminListSpec{
	DefaultLimit: 100, MaxLimit: 500,
	Sorts: map[string]string{
		"submitted_at": "v.submitted_at {dir} NULLS LAST",
		"updated_at":   "v.updated_at {dir} NULLS LAST",
	},
	DefaultSort: "submitted_at", TieBreak: "v.user_id {dir}",
}

func listVerificationsPage(ctx context.Context, db adminPageQueryer, status, userID string, p adminListParams) ([]verificationState, int, error) {
	filter := newSQLFilter()
	filter.Eq("v.status", strings.ToLower(strings.TrimSpace(status))).Eq("v.user_id", userID)
	filter.Search(p.Q, "v.user_id::text", "u.username")
	filter.TimeRange("v.submitted_at", p)
	items := make([]verificationState, 0)
	total, err := queryAdminPage(ctx, db,
		`v.user_id::text,v.status,v.rejection_reason,v.submitted_at,v.reviewed_at,v.reviewed_by::text,
		 (COALESCE(v.details,'{}'::jsonb) ? 'id_document' AND COALESCE(v.details,'{}'::jsonb) ? 'selfie')`,
		` FROM matching.verification_states v LEFT JOIN user_management.users u ON u.id=v.user_id`,
		filter, p, func(rows *sql.Rows) error {
			item, err := scanVerification(rows)
			if err == nil {
				items = append(items, item)
			}
			return err
		})
	return items, total, err
}

// ── moderation reports ──────────────────────────────────────────────────────

var adminReportsSpec = adminListSpec{
	DefaultLimit: 100, MaxLimit: 500,
	Sorts:       map[string]string{"created_at": "created_at"},
	DefaultSort: "created_at", TieBreak: "id {dir}",
}

type reportListFilter struct {
	Status, Category           string
	ReporterUserID, ReportedID string
}

func listReportsPage(ctx context.Context, db adminPageQueryer, f reportListFilter, p adminListParams) ([]moderationReport, int, error) {
	filter := newSQLFilter()
	if strings.TrimSpace(f.Status) != "" {
		filter.Eq("status", mapReportStatusToDB(f.Status))
	}
	filter.Eq("reason", f.Category).Eq("reporter_user_id", f.ReporterUserID).Eq("reported_user_id", f.ReportedID)
	filter.Search(p.Q, "description", "reason")
	filter.TimeRange("created_at", p)
	items := make([]moderationReport, 0)
	total, err := queryAdminPage(ctx, db,
		`id::text,reporter_user_id::text,reported_user_id::text,reason,COALESCE(description,''),status,
		 COALESCE(action,''),COALESCE(reviewed_by::text,''),reviewed_at,created_at`,
		` FROM matching.moderation_reports`, filter, p, func(rows *sql.Rows) error {
			var item moderationReport
			var reviewedAt sql.NullTime
			var createdAt time.Time
			if err := rows.Scan(&item.ID, &item.ReporterUserID, &item.ReportedUserID, &item.Reason, &item.Description,
				&item.Status, &item.Action, &item.ReviewedBy, &reviewedAt, &createdAt); err != nil {
				return err
			}
			item.Status = mapReportStatusFromDB(item.Status)
			item.CreatedAt = createdAt.UTC().Format(time.RFC3339)
			if reviewedAt.Valid {
				item.ReviewedAt = reviewedAt.Time.UTC().Format(time.RFC3339)
			}
			items = append(items, item)
			return nil
		})
	return items, total, err
}

// ── moderation appeals ──────────────────────────────────────────────────────

var adminAppealsSpec = adminListSpec{
	DefaultLimit: 100, MaxLimit: 500,
	Sorts: map[string]string{
		"created_at":      "created_at",
		"sla_deadline_at": "sla_deadline_at",
	},
	DefaultSort: "created_at", TieBreak: "id {dir}",
}

func listModerationAppealsPage(ctx context.Context, db adminPageQueryer, status, userID, reportID string, p adminListParams) ([]moderationAppeal, int, error) {
	filter := newSQLFilter()
	filter.Eq("status", strings.ToLower(strings.TrimSpace(status))).
		Eq("requester_user_id", userID).Eq("report_id", reportID)
	filter.Search(p.Q, "reason", "COALESCE(description,'')")
	filter.TimeRange("created_at", p)
	items := make([]moderationAppeal, 0)
	total, err := queryAdminPage(ctx, db, appealSelect, ` FROM matching.moderation_appeals`, filter, p,
		func(rows *sql.Rows) error {
			item, err := scanAppeal(rows)
			if err == nil {
				items = append(items, item)
			}
			return err
		})
	return items, total, err
}

// ── SOS alerts ──────────────────────────────────────────────────────────────

var adminSOSSpec = adminListSpec{
	DefaultLimit: 100, MaxLimit: 500,
	Sorts:       map[string]string{"created_at": "created_at", "triggered_at": "created_at"},
	DefaultSort: "created_at", TieBreak: "id {dir}",
}

var errAdminSOSStatus = errors.New("status must be active, open, acknowledged or resolved")

// sosStatusClause maps the API status ("active" | "resolved", or a stored
// status) to SQL.
func sosStatusClause(filter *sqlFilter, status string) error {
	switch strings.ToLower(strings.TrimSpace(status)) {
	case "":
		return nil
	case "active":
		filter.Where("status IN ('open','acknowledged')")
	case "open", "acknowledged", "resolved":
		filter.Eq("status", strings.ToLower(strings.TrimSpace(status)))
	default:
		return errAdminSOSStatus
	}
	return nil
}

func listSOSAlertsPage(ctx context.Context, db adminPageQueryer, status, level, userID string, p adminListParams) ([]sosAlert, int, error) {
	filter := newSQLFilter()
	if err := sosStatusClause(filter, status); err != nil {
		return nil, 0, err
	}
	filter.Eq("level", strings.ToLower(strings.TrimSpace(level))).Eq("user_id", userID)
	filter.Search(p.Q, "COALESCE(message,'')", "COALESCE(resolved_note,'')")
	filter.TimeRange("created_at", p)
	items := make([]sosAlert, 0)
	total, err := queryAdminPage(ctx, db, sosSelect, ` FROM matching.sos_alerts`, filter, p,
		func(rows *sql.Rows) error {
			item, err := scanSOS(rows)
			if err == nil {
				items = append(items, item)
			}
			return err
		})
	return items, total, err
}

// ── account recovery ────────────────────────────────────────────────────────

var adminRecoverySpec = adminListSpec{
	DefaultLimit: 100, MaxLimit: 200,
	Sorts:       map[string]string{"created_at": "q.created_at"},
	DefaultSort: "created_at", DefaultOrder: "asc", TieBreak: "q.id {dir}",
}

const recoveryRequestColumns = `q.id::text, q.user_id::text, COALESCE(c.username,''), COALESCE(q.member_message,''),
		       q.status, q.created_at,
		       EXISTS(SELECT 1 FROM matching.verification_states v
		              WHERE v.user_id = q.user_id AND v.status = 'verified'),
		       (u.erased_at IS NULL AND u.deletion_effective_at IS NULL
		        AND NOT COALESCE(c.is_disabled, TRUE)),
		       COALESCE(q.identity_check,''), COALESCE(q.resolved_by::text,''), q.resolved_at`

const recoveryRequestFrom = `
		FROM user_management.account_recovery_requests q
		JOIN user_management.users u ON u.id = q.user_id
		LEFT JOIN user_management.auth_credentials c ON c.user_id = q.user_id`

func scanRecoveryRequestView(rows *sql.Rows) (recoveryRequestView, error) {
	var view recoveryRequestView
	var created time.Time
	var resolved sql.NullTime
	if err := rows.Scan(&view.ID, &view.UserID, &view.Username, &view.MemberMessage, &view.Status,
		&created, &view.IdentityVerified, &view.AccountRecoverable, &view.IdentityCheck,
		&view.ResolvedBy, &resolved); err != nil {
		return recoveryRequestView{}, err
	}
	view.CreatedAt = created.UTC().Format(time.RFC3339)
	if resolved.Valid {
		view.ResolvedAt = resolved.Time.UTC().Format(time.RFC3339)
	}
	return view, nil
}

func (r *profileRepository) listRecoveryRequestsPage(ctx context.Context, status string, p adminListParams) ([]recoveryRequestView, int, error) {
	if r == nil || r.pg == nil {
		return nil, 0, errors.New("account recovery persistence is unavailable")
	}
	if err := r.expireRecoveryRequests(ctx); err != nil {
		return nil, 0, err
	}
	filter := newSQLFilter()
	filter.Eq("q.status", status)
	filter.Search(p.Q, "c.username", "q.member_message")
	filter.TimeRange("q.created_at", p)
	items := []recoveryRequestView{}
	total, err := queryAdminPage(ctx, r.pg, recoveryRequestColumns, recoveryRequestFrom, filter, p,
		func(rows *sql.Rows) error {
			view, err := scanRecoveryRequestView(rows)
			if err == nil {
				items = append(items, view)
			}
			return err
		})
	return items, total, err
}

// ── media moderation ────────────────────────────────────────────────────────

var adminMediaModerationSpec = adminListSpec{
	DefaultLimit: 50, MaxLimit: 200,
	Sorts:       map[string]string{"uploaded_at": "p.uploaded_at"},
	DefaultSort: "uploaded_at", DefaultOrder: "asc", TieBreak: "p.id {dir}",
}

func (r *profileRepository) listMediaModerationReviewsPage(ctx context.Context, status string, p adminListParams) ([]mediaModerationReviewItem, int, error) {
	status = strings.TrimSpace(status)
	if status == "" {
		status = mediaModerationReviewRequired
	}
	if status != mediaModerationReviewRequired && status != "provider_error" {
		return nil, 0, errors.New("status must be review_required or provider_error")
	}
	filter := newSQLFilter("p.deleted_at IS NULL")
	filter.Eq("p.moderation_status", status)
	filter.Search(p.Q, "u.username")
	filter.TimeRange("p.uploaded_at", p)
	items := make([]mediaModerationReviewItem, 0)
	total, err := queryAdminPage(ctx, r.pg,
		`p.id::text,p.user_id::text,u.username,p.photo_url,COALESCE(p.mime_type,''),
		       COALESCE(p.width_px,0),COALESCE(p.height_px,0),COALESCE(p.size_bytes,0),
		       p.moderation_status,COALESCE(p.moderation_reason,''),
		       COALESCE(p.moderation_provider,''),COALESCE(p.moderation_model_version,''),
		       COALESCE(p.moderation_confidence,0)::real,p.moderation_labels,p.uploaded_at`,
		`
		FROM user_management.photos p
		JOIN user_management.users u ON u.id=p.user_id`, filter, p, func(rows *sql.Rows) error {
			item, err := scanMediaModerationReviewItem(rows)
			if err == nil {
				items = append(items, item)
			}
			return err
		})
	return items, total, err
}

// adminListError writes a 400 for bad list parameters.
func writeAdminListParamError(w http.ResponseWriter, err error) {
	writeError(w, http.StatusBadRequest, fmt.Errorf("invalid list parameters: %w", err))
}

// withUnpagedTotal adds the paging keys to a response from an older path
// that cannot count or skip rows: total is what it returned, offset is 0.
func withUnpagedTotal(resp map[string]any, key string, p adminListParams) map[string]any {
	total := 0
	switch items := resp[key].(type) {
	case []map[string]any:
		total = len(items)
	case []any:
		total = len(items)
	}
	resp["total"] = total
	resp["limit"] = p.Limit
	resp["offset"] = 0
	return resp
}

// ── catalog, engagement and billing lists (formerly data-access selects) ────
//
// These lists used the PostgREST-style client, which can neither count nor
// escape ILIKE input. With a SQL pool they run here; without one the handlers
// keep the client path.

func qualifiedTable(schema, table string) string {
	return pgx.Identifier{schema, table}.Sanitize()
}

// activeFilter maps the console's yes/no switch onto a boolean column.
func activeFilter(filter *sqlFilter, column, value string) {
	switch strings.TrimSpace(value) {
	case "yes":
		filter.Where(column + " = TRUE")
	case "no":
		filter.Where(column + " = FALSE")
	}
}

var adminGiftCatalogSpec = adminListSpec{
	DefaultLimit: 50, MaxLimit: 500,
	Sorts: map[string]string{
		"sort_order":  "sort_order {dir}, created_at {dir}",
		"created_at":  "created_at",
		"price_coins": "price_coins",
		"name":        "name",
	},
	DefaultSort: "sort_order", DefaultOrder: "asc", TieBreak: "id {dir}",
}

func listGiftCatalogPage(ctx context.Context, db adminPageQueryer, table string, r *http.Request, p adminListParams) ([]map[string]any, int, error) {
	values := r.URL.Query()
	filter := newSQLFilter()
	filter.Eq("category", values.Get("category")).Eq("tier", values.Get("tier"))
	activeFilter(filter, "is_active", values.Get("active"))
	filter.Search(p.Q, "name", "id")
	filter.TimeRange("created_at", p)
	return queryAdminMapPage(ctx, db,
		`id,name,gif_url,tier,price_coins,icon_key,icon_emoji,category,description,max_per_match_per_day,is_active,sort_order,start_date,end_date,created_at,updated_at`,
		` FROM `+table, filter, p)
}

var adminPromptsSpec = adminListSpec{
	DefaultLimit: 100, MaxLimit: 500,
	Sorts: map[string]string{
		"created_at":  "created_at",
		"active_date": "active_date {dir} NULLS LAST",
	},
	DefaultSort: "created_at", TieBreak: "id {dir}",
}

func listEngagementPromptsPage(ctx context.Context, db adminPageQueryer, schema string, r *http.Request, p adminListParams) ([]map[string]any, int, error) {
	values := r.URL.Query()
	filter := newSQLFilter()
	filter.Eq("category", values.Get("category"))
	activeFilter(filter, "is_active", values.Get("active"))
	filter.Search(p.Q, "question_text", "category")
	filter.TimeRange("created_at", p)
	return queryAdminMapPage(ctx, db,
		`id,question_text,category,active_date,is_active,response_count,created_by,created_at`,
		` FROM `+qualifiedTable(schema, "admin_daily_prompts"), filter, p)
}

var adminNudgesSpec = adminListSpec{
	DefaultLimit: 100, MaxLimit: 500,
	Sorts:       map[string]string{"created_at": "created_at", "clicked_at": "clicked_at {dir} NULLS LAST"},
	DefaultSort: "created_at", TieBreak: "id {dir}",
}

func listEngagementNudgesPage(ctx context.Context, db adminPageQueryer, schema string, r *http.Request, p adminListParams) ([]map[string]any, int, error) {
	values := r.URL.Query()
	filter := newSQLFilter()
	filter.Eq("nudge_type", values.Get("nudge_type")).Eq("status", values.Get("status"))
	filter.UUIDEq("user_id", values.Get("user_id")).UUIDEq("match_id", values.Get("match_id"))
	switch strings.TrimSpace(values.Get("clicked")) {
	case "yes":
		filter.Where("clicked_at IS NOT NULL")
	case "no":
		filter.Where("clicked_at IS NULL")
	}
	filter.Search(p.Q, "nudge_type")
	filter.TimeRange("created_at", p)
	return queryAdminMapPage(ctx, db,
		`id,match_id,user_id,counterparty_user_id,nudge_type,created_at,clicked_at`,
		` FROM `+qualifiedTable(schema, "match_nudges"), filter, p)
}

var adminBillingTransactionsSpec = adminListSpec{
	DefaultLimit: 50, MaxLimit: 500,
	Sorts: map[string]string{
		"created_at":   "created_at",
		"amount_minor": "amount_minor",
		"coins":        "coins",
	},
	DefaultSort: "created_at", TieBreak: "id {dir}",
}

func listBillingTransactionsPage(ctx context.Context, db adminPageQueryer, schema, userID string, r *http.Request, p adminListParams) ([]map[string]any, int, error) {
	values := r.URL.Query()
	filter := newSQLFilter()
	filter.Eq("source", values.Get("source")).Eq("provider", values.Get("provider")).Eq("user_id", userID)
	filter.Eq("package_id", values.Get("package_id")).Eq("currency", values.Get("currency"))
	filter.Search(p.Q, "COALESCE(purchase_ref,'')", "user_id::text", "COALESCE(package_id,'')")
	filter.TimeRange("created_at", p)
	return queryAdminMapPage(ctx, db,
		`id,user_id,package_id,source,provider,coins,amount_minor,currency,purchase_ref,created_at`,
		` FROM `+qualifiedTable(schema, "wallet_coin_purchases"), filter, p)
}

var adminSubscriptionsSpec = adminListSpec{
	DefaultLimit: 50, MaxLimit: 500,
	Sorts: map[string]string{
		"created_at":         "created_at",
		"updated_at":         "updated_at",
		"current_period_end": "current_period_end {dir} NULLS LAST",
	},
	DefaultSort: "created_at", TieBreak: "id {dir}",
}

func listSubscriptionsPage(ctx context.Context, db adminPageQueryer, schema, userID string, r *http.Request, p adminListParams) ([]map[string]any, int, error) {
	values := r.URL.Query()
	filter := newSQLFilter()
	filter.Eq("status", values.Get("status")).Eq("plan_code", values.Get("plan_code"))
	filter.Eq("provider", values.Get("provider")).Eq("user_id", userID)
	filter.Search(p.Q, "COALESCE(provider_subscription_id,'')", "user_id::text", "plan_code")
	filter.TimeRange("created_at", p)
	return queryAdminMapPage(ctx, db,
		`id,user_id,plan_code,status,billing_cycle,start_date,end_date,next_billing_date,auto_renew,cancel_at_period_end,current_period_end,provider,provider_subscription_id,payment_method_brand,payment_method_last4,amount_minor,currency,created_at,updated_at`,
		` FROM `+qualifiedTable(schema, "billing_subscriptions_runtime"), filter, p)
}

var adminPaymentsSpec = adminListSpec{
	DefaultLimit: 50, MaxLimit: 500,
	Sorts: map[string]string{
		"created_at":   "created_at",
		"paid_at":      "paid_at {dir} NULLS LAST",
		"amount_paise": "amount_paise",
	},
	DefaultSort: "created_at", TieBreak: "id {dir}",
}

func listPaymentsPage(ctx context.Context, db adminPageQueryer, schema, userID string, r *http.Request, p adminListParams) ([]map[string]any, int, error) {
	values := r.URL.Query()
	filter := newSQLFilter()
	filter.Eq("status", values.Get("status")).Eq("provider", values.Get("provider")).Eq("user_id", userID)
	filter.Eq("billing_reason", values.Get("billing_reason"))
	filter.Search(p.Q, "COALESCE(provider_payment_id,'')", "COALESCE(provider_invoice_id,'')", "user_id::text")
	filter.TimeRange("created_at", p)
	return queryAdminMapPage(ctx, db,
		`id,user_id,subscription_id,amount_paise,currency,status,provider,provider_order_id,provider_payment_id,provider_invoice_id,billing_reason,payment_method_brand,payment_method_last4,refunded_amount_paise,failure_reason,paid_at,created_at,metadata`,
		` FROM `+qualifiedTable(schema, "billing_payments_runtime"), filter, p)
}

var adminWebhookEventsSpec = adminListSpec{
	DefaultLimit: 50, MaxLimit: 500,
	Sorts: map[string]string{
		"received_at":      "received_at",
		"event_created_at": "event_created_at {dir} NULLS LAST",
	},
	DefaultSort: "received_at", TieBreak: "id {dir}",
}

func listWebhookEventsPage(ctx context.Context, db adminPageQueryer, schema string, r *http.Request, p adminListParams) ([]map[string]any, int, error) {
	values := r.URL.Query()
	filter := newSQLFilter()
	filter.Eq("status", values.Get("status")).Eq("event_type", values.Get("event_type")).Eq("provider", values.Get("provider"))
	filter.Search(p.Q, "event_id", "event_type")
	filter.TimeRange("received_at", p)
	return queryAdminMapPage(ctx, db,
		`id,provider,event_id,event_type,event_created_at,received_at,processed_at,status,error`,
		` FROM `+qualifiedTable(schema, "billing_webhook_events"), filter, p)
}
