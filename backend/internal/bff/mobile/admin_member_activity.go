package mobile

import (
	"context"
	"database/sql"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"slices"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
)

// Member action log for operators (migration 132).
//
//	GET /admin/activity                     every member action, paged
//	GET /admin/members/{userID}/activity    the same, fixed to one member, plus a summary
//	GET /admin/activity/stream              live tail: actions newer than a cursor
//	GET /admin/activity/catalog             the action catalog and its coverage
//
// Four sources are merged with UNION ALL into one shape:
//
//	request   matching.activity_events, domain member_action (plus api_request
//	          reads with include_reads=true), written by the activity middleware
//	event     every other matching.activity_events domain: the named events
//	          handlers record explicitly (wallet.coins.purchase, gestures …)
//	security  audit.security_events, member and operator originated
//	domain    platform.domain_event_outbox rows naming a member, without the
//	          copies the outbox keeps of the three tables above and without
//	          fan-out bookkeeping (*_deliveries, *_outbox, *_counters, *_reads)
//
// Every filter is applied inside each branch (time and member on the branch's
// own indexed columns), and the page is ordered by (at, source, id).
//
// Readable by the roles that read /admin/activities (admin, ops_admin,
// trust_safety, moderator, analyst; see isMemberActivityAdminPath). Analysts
// see no IP address, device id or user agent.

var adminMemberActivitySpec = adminListSpec{
	DefaultLimit: 100, MaxLimit: 500,
	Sorts:       map[string]string{"at": "a.at {dir}"},
	DefaultSort: "at", TieBreak: "a.source {dir}, a.id {dir}",
}

const (
	memberActivitySourceRequest  = "request"
	memberActivitySourceEvent    = "event"
	memberActivitySourceSecurity = "security"
	memberActivitySourceDomain   = "domain"

	memberActivityStreamDefaultLimit = 50
	memberActivityStreamMaxLimit     = 200
	// memberActivityStreamSettle keeps the live tail this far behind the
	// clock, so a row whose transaction commits a moment after its timestamp
	// is not skipped by a cursor that already passed that timestamp.
	memberActivityStreamSettle = 2 * time.Second
)

var memberActivitySources = []string{
	memberActivitySourceRequest, memberActivitySourceEvent,
	memberActivitySourceSecurity, memberActivitySourceDomain,
}

type memberActivityFilter struct {
	Member       string
	ActorUserID  string
	Action       string
	Category     string
	Method       string
	Outcome      string
	Sources      map[string]bool
	IncludeReads bool
}

func parseMemberActivityFilter(r *http.Request) (memberActivityFilter, error) {
	values := r.URL.Query()
	f := memberActivityFilter{Sources: map[string]bool{}}
	var err error
	if f.Member, err = adminUUIDParam(r, "member"); err != nil {
		return f, err
	}
	if f.ActorUserID, err = adminUUIDParam(r, "actor_user_id"); err != nil {
		return f, err
	}
	f.Action = strings.TrimSpace(values.Get("action"))
	if len([]rune(f.Action)) > 120 {
		return f, errors.New("action must be at most 120 characters")
	}
	if f.Category = strings.TrimSpace(values.Get("category")); f.Category != "" && !isMemberActionCategory(f.Category) {
		return f, fmt.Errorf("category must be one of: %s", strings.Join(memberActionCategories, ", "))
	}
	if f.Method = strings.ToUpper(strings.TrimSpace(values.Get("method"))); f.Method != "" &&
		!slices.Contains([]string{http.MethodGet, http.MethodPost, http.MethodPut, http.MethodPatch, http.MethodDelete}, f.Method) {
		return f, errors.New("method must be GET, POST, PUT, PATCH or DELETE")
	}
	if f.Outcome = strings.ToLower(strings.TrimSpace(values.Get("outcome"))); f.Outcome != "" &&
		!slices.Contains([]string{"success", "client_error", "server_error"}, f.Outcome) {
		return f, errors.New("outcome must be success, client_error or server_error")
	}
	for _, raw := range values["source"] {
		for _, source := range strings.Split(raw, ",") {
			source = strings.ToLower(strings.TrimSpace(source))
			switch {
			case source == "" || source == "all":
				for _, name := range memberActivitySources {
					f.Sources[name] = true
				}
			case slices.Contains(memberActivitySources, source):
				f.Sources[source] = true
			default:
				return f, errors.New("source must be request, event, security, domain or all")
			}
		}
	}
	if len(f.Sources) == 0 {
		for _, name := range memberActivitySources {
			f.Sources[name] = true
		}
	}
	switch strings.ToLower(strings.TrimSpace(values.Get("include_reads"))) {
	case "", "false", "0", "no":
	case "true", "1", "yes":
		f.IncludeReads = true
	default:
		return f, errors.New("include_reads must be true or false")
	}
	return f, nil
}

// memberActivityCursor is the opaque stream position: the (at, source, id) of
// the last action returned.
type memberActivityCursor struct {
	At     time.Time `json:"at"`
	Source string    `json:"s"`
	ID     string    `json:"id"`
}

func (c memberActivityCursor) encode() string {
	raw, _ := json.Marshal(c)
	return base64.RawURLEncoding.EncodeToString(raw)
}

func decodeMemberActivityCursor(raw string) (memberActivityCursor, error) {
	var cursor memberActivityCursor
	decoded, err := base64.RawURLEncoding.DecodeString(strings.TrimSpace(raw))
	if err != nil {
		return cursor, errors.New("after is not a valid cursor")
	}
	if err := json.Unmarshal(decoded, &cursor); err != nil || cursor.At.IsZero() || len(cursor.ID) > 64 || len(cursor.Source) > 16 {
		return memberActivityCursor{}, errors.New("after is not a valid cursor")
	}
	return cursor, nil
}

// memberActivityQueryOptions are the parts of the union that differ between
// the list, the summary and the stream.
type memberActivityQueryOptions struct {
	From, To     time.Time // [From, To) on each source's timestamp; zero is open
	Q            string
	After        *memberActivityCursor
	SettledOnly  bool // only rows older than memberActivityStreamSettle
	SkipCategory bool // the summary counts every category
	// BranchLimit > 0 makes each branch return only its first BranchLimit
	// rows in (at, source, id) BranchOrder ("ASC" or "DESC") order. A page of
	// the merged log needs at most offset+limit rows from any one branch, and
	// a per-branch ORDER BY … LIMIT is served by that branch's time index;
	// one ORDER BY over the whole union is not (it sorts every row).
	BranchLimit int
	BranchOrder string
	// DomainAggregateTypes, when not nil, are the outbox aggregate types in
	// the requested category (memberActivityDomainTypes).
	DomainAggregateTypes []string
}

// memberActivityDomainTypes lists the outbox aggregate types whose category is
// category. The outbox has a few hundred distinct types and millions of rows:
// the types are read with a loose index scan over
// idx_domain_event_aggregate_sequence and classified here once.
func memberActivityDomainTypes(ctx context.Context, db adminPageQueryer, f memberActivityFilter) ([]string, error) {
	if f.Category == "" || !f.Sources[memberActivitySourceDomain] {
		return nil, nil
	}
	rows, err := db.QueryContext(ctx, `WITH RECURSIVE t(v) AS (
		  SELECT MIN(aggregate_type) FROM platform.domain_event_outbox
		  UNION ALL
		  SELECT (SELECT MIN(aggregate_type) FROM platform.domain_event_outbox WHERE aggregate_type > t.v)
		  FROM t WHERE t.v IS NOT NULL)
		SELECT v FROM t WHERE v IS NOT NULL AND `+memberEventCategorySQL("v")+` = $1`, f.Category)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	types := []string{}
	for rows.Next() {
		var value string
		if err := rows.Scan(&value); err != nil {
			return nil, err
		}
		types = append(types, value)
	}
	return types, rows.Err()
}

// memberActivityColumns is the common column list every branch produces, in
// this order.
const memberActivityColumns = `id, at, source, member_id, actor_id, actor_role, category, action_key, action_label,
	method, route, status_code, outcome, duration_ms, entity_type, entity_id, ip, device_id, platform,
	app_version, user_agent, request_id, correlation_id, session_id, details`

// buildMemberActivityUnion returns "(branch) UNION ALL (branch) …" with its
// arguments bound in filter. Base conditions (time, member, actor) go on each
// branch's own columns so its indexes apply; conditions on derived columns
// (category, outcome, method, action, q, cursor) wrap each branch.
func buildMemberActivityUnion(f memberActivityFilter, opts memberActivityQueryOptions, filter *sqlFilter) string {
	var fromArg, toArg, memberArg, actorArg, settleArg, afterAtArg string
	if !opts.From.IsZero() {
		fromArg = filter.Arg(opts.From)
	}
	if !opts.To.IsZero() {
		toArg = filter.Arg(opts.To)
	}
	if f.Member != "" {
		memberArg = filter.Arg(f.Member)
	}
	if f.ActorUserID != "" {
		actorArg = filter.Arg(f.ActorUserID)
	}
	if opts.SettledOnly {
		settleArg = filter.Arg(time.Now().UTC().Add(-memberActivityStreamSettle))
	}
	if opts.After != nil {
		afterAtArg = filter.Arg(opts.After.At)
	}
	base := func(timeColumn, subjectColumn, actorColumn string) []string {
		clauses := []string{}
		if fromArg != "" {
			clauses = append(clauses, timeColumn+" >= "+fromArg)
		}
		if toArg != "" {
			clauses = append(clauses, timeColumn+" < "+toArg)
		}
		if settleArg != "" {
			clauses = append(clauses, timeColumn+" < "+settleArg)
		}
		if afterAtArg != "" {
			clauses = append(clauses, timeColumn+" >= "+afterAtArg)
		}
		if actorArg != "" {
			clauses = append(clauses, actorColumn+" = "+actorArg)
		}
		return clauses
	}

	derived := []string{}
	var actionArg, categoryArg string
	if f.Action != "" {
		actionArg = filter.Arg(f.Action)
		derived = append(derived, "action_key = "+actionArg)
	}
	if f.Category != "" && !opts.SkipCategory {
		categoryArg = filter.Arg(f.Category)
		derived = append(derived, "category = "+categoryArg)
	}
	if f.Method != "" {
		derived = append(derived, "method = "+filter.Arg(f.Method))
	}
	if f.Outcome != "" {
		derived = append(derived, "outcome = "+filter.Arg(f.Outcome))
	}
	if q := strings.TrimSpace(opts.Q); q != "" {
		pattern := filter.Arg("%" + escapeILIKE(q) + "%")
		derived = append(derived, "(action_label ILIKE "+pattern+` ESCAPE '\' OR route ILIKE `+pattern+
			` ESCAPE '\' OR action_key ILIKE `+pattern+` ESCAPE '\')`)
	}
	if opts.After != nil {
		derived = append(derived, "(at, source, id) > ("+afterAtArg+"::timestamptz, "+filter.Arg(opts.After.Source)+
			"::text, "+filter.Arg(opts.After.ID)+"::text)")
	}
	branchTail := ""
	if opts.BranchLimit > 0 {
		dir := "DESC"
		if opts.BranchOrder == "ASC" {
			dir = "ASC"
		}
		branchTail = fmt.Sprintf(" ORDER BY at %s, source %s, id %s LIMIT %d", dir, dir, dir, opts.BranchLimit)
	}
	wrap := func(inner string) string {
		if len(derived) == 0 && branchTail == "" {
			return "(" + inner + ")"
		}
		conditions := ""
		if len(derived) > 0 {
			conditions = " WHERE " + strings.Join(derived, " AND ")
		}
		return "(SELECT * FROM (" + inner + ") b" + conditions + branchTail + ")"
	}
	where := func(clauses []string) string {
		if len(clauses) == 0 {
			return ""
		}
		return " WHERE " + strings.Join(clauses, " AND ")
	}

	// A member filter matches the subject OR the actor. An OR over two
	// columns cannot be served by one ordered index, so each source is split
	// into "member is the subject" and "member is the actor but not the
	// subject": two disjoint parts, each a newest-first scan of its own index.
	branches := []string{}
	addBranch := func(subjectColumn, actorColumn string, clauses []string, table, inner string) {
		if memberArg == "" {
			branches = append(branches, wrap(strings.Replace(inner, "{source}", table, 1)+where(clauses)))
			return
		}
		// The member's rows are read first through the member index
		// (OFFSET 0 keeps the planner from walking the global time index
		// instead, which it prefers when it wrongly assumes the member's rows
		// are spread evenly over time) and then ordered.
		alias := table[strings.LastIndex(table, " ")+1:]
		fenced := func(conditions []string) string {
			return strings.Replace(inner, "{source}", "(SELECT * FROM "+table+where(conditions)+" OFFSET 0) "+alias, 1)
		}
		asSubject := append(append([]string{}, clauses...), subjectColumn+" = "+memberArg)
		asActor := append(append([]string{}, clauses...), actorColumn+" = "+memberArg,
			"("+subjectColumn+" IS NULL OR "+subjectColumn+" <> "+memberArg+")")
		branches = append(branches, wrap(fenced(asSubject)), wrap(fenced(asActor)))
	}
	if f.Sources[memberActivitySourceRequest] {
		clauses := base("e.created_at", "e.user_id", "e.actor_user_id")
		if f.IncludeReads {
			clauses = append(clauses, "e.event_domain IN ('member_action','api_request')")
		} else {
			clauses = append(clauses, "e.event_domain = 'member_action'")
		}
		// Action and category are also matched on the stored details, so the
		// expression indexes of migration 132 serve a rare key or category
		// without walking every member action.
		if actionArg != "" {
			clauses = append(clauses, "e.payload #>> '{details,action_key}' = "+actionArg)
		}
		if categoryArg != "" && f.Category != memberCategoryOther {
			clauses = append(clauses, "e.payload #>> '{details,action_category}' = "+categoryArg)
		}
		addBranch("e.user_id", "e.actor_user_id", clauses, "matching.activity_events e", `SELECT e.id::text AS id, e.created_at AS at, 'request'::text AS source,
			e.user_id::text AS member_id, e.actor_user_id::text AS actor_id, d->>'actor_role' AS actor_role,
			COALESCE(d->>'action_category', '`+memberCategoryOther+`') AS category,
			d->>'action_key' AS action_key, COALESCE(d->>'action_label', e.event_name) AS action_label,
			COALESCE(d->>'method', split_part(e.event_name, ' ', 1)) AS method,
			COALESCE(d->>'route', d->>'path', e.payload->>'resource') AS route,
			CASE WHEN d->>'status_code' ~ '^[0-9]{1,4}$' THEN (d->>'status_code')::int END AS status_code,
			COALESCE(d->>'outcome', CASE WHEN e.payload->>'status' IN ('client_error','server_error') THEN e.payload->>'status' ELSE 'success' END) AS outcome,
			CASE WHEN d->>'duration_ms' ~ '^[0-9]{1,12}$' THEN (d->>'duration_ms')::bigint END AS duration_ms,
			e.entity_table AS entity_type, e.entity_id AS entity_id, host(e.ip_address) AS ip,
			e.source_device_id AS device_id, e.source_platform AS platform, d->>'app_version' AS app_version,
			d->>'user_agent' AS user_agent, e.request_id AS request_id, e.correlation_id AS correlation_id,
			d->>'session_id' AS session_id, d AS details
			FROM {source}
			CROSS JOIN LATERAL (SELECT CASE WHEN jsonb_typeof(e.payload->'details') = 'object'
			                               THEN e.payload->'details' ELSE '{}'::jsonb END AS d) x`)
	}
	if f.Sources[memberActivitySourceEvent] {
		clauses := append(base("e.created_at", "e.user_id", "e.actor_user_id"),
			"e.event_domain NOT IN ('member_action','api_request')")
		addBranch("e.user_id", "e.actor_user_id", clauses, "matching.activity_events e", `SELECT e.id::text AS id, e.created_at AS at, 'event'::text AS source,
			e.user_id::text AS member_id,
			COALESCE(e.actor_user_id::text, NULLIF(e.payload->>'actor', '')) AS actor_id, NULL::text AS actor_role,
			`+memberEventCategorySQL("e.event_name")+` AS category,
			e.event_name AS action_key, translate(e.event_name, '._', '  ') AS action_label,
			NULL::text AS method, NULLIF(e.payload->>'resource', '') AS route, NULL::int AS status_code,
			CASE WHEN e.payload->>'status' IN ('client_error','server_error','failure','failed','denied')
			     THEN CASE WHEN e.payload->>'status' = 'server_error' THEN 'server_error' ELSE 'client_error' END
			     ELSE 'success' END AS outcome,
			NULL::bigint AS duration_ms, e.entity_table AS entity_type, e.entity_id AS entity_id,
			host(e.ip_address) AS ip, e.source_device_id AS device_id, e.source_platform AS platform,
			NULL::text AS app_version, NULL::text AS user_agent, e.request_id AS request_id,
			e.correlation_id AS correlation_id, NULL::text AS session_id, e.payload AS details
			FROM {source}`)
	}
	if f.Sources[memberActivitySourceSecurity] {
		clauses := base("s.occurred_at", "s.subject_user_id", "s.actor_user_id")
		addBranch("s.subject_user_id", "s.actor_user_id", clauses, "audit.security_events s", `SELECT s.id::text AS id, s.occurred_at AS at, 'security'::text AS source,
			s.subject_user_id::text AS member_id, s.actor_user_id::text AS actor_id, s.actor_role AS actor_role,
			`+memberEventCategorySQL("s.event_type")+` AS category,
			s.event_type AS action_key, translate(s.event_type, '._', '  ') AS action_label,
			NULL::text AS method, NULL::text AS route, NULL::int AS status_code, 'success'::text AS outcome,
			NULL::bigint AS duration_ms, s.resource_type AS entity_type, s.resource_id AS entity_id,
			NULL::text AS ip, NULL::text AS device_id, NULL::text AS platform, NULL::text AS app_version,
			NULL::text AS user_agent, NULL::text AS request_id, s.correlation_id AS correlation_id,
			NULL::text AS session_id, s.payload AS details
			FROM {source}`)
	}
	if f.Sources[memberActivitySourceDomain] {
		clauses := append(base("o.occurred_at", "o.subject_user_id", "o.actor_user_id"),
			"(o.subject_user_id IS NOT NULL OR o.actor_user_id IS NOT NULL)",
			"o.aggregate_type <> 'matching.activity_events'",
			"o.aggregate_type NOT LIKE 'audit.%'",
			`o.aggregate_type !~ '(_deliveries|_outbox|_counters|_reads)$'`)
		if categoryArg != "" && opts.DomainAggregateTypes != nil {
			// A domain event's category follows its aggregate type; the
			// caller resolved the category to its aggregate types
			// (memberActivityDomainTypes), so the outbox is filtered on a
			// plain list instead of running the rules on every row.
			if len(opts.DomainAggregateTypes) == 0 {
				clauses = append(clauses, "FALSE")
			} else {
				clauses = append(clauses, "o.aggregate_type = ANY("+filter.Arg(opts.DomainAggregateTypes)+"::text[])")
			}
		}
		addBranch("o.subject_user_id", "o.actor_user_id", clauses, "platform.domain_event_outbox o", `SELECT o.event_id::text AS id, o.occurred_at AS at, 'domain'::text AS source,
			o.subject_user_id::text AS member_id, o.actor_user_id::text AS actor_id, NULL::text AS actor_role,
			`+memberEventCategorySQL("o.aggregate_type")+` AS category,
			o.event_name AS action_key, translate(o.event_name, '._', '  ') AS action_label,
			NULL::text AS method, NULL::text AS route, NULL::int AS status_code, 'success'::text AS outcome,
			NULL::bigint AS duration_ms, o.aggregate_type AS entity_type, o.aggregate_id AS entity_id,
			NULL::text AS ip, NULL::text AS device_id, NULL::text AS platform, NULL::text AS app_version,
			NULL::text AS user_agent, NULL::text AS request_id, o.correlation_id AS correlation_id,
			NULL::text AS session_id,
			jsonb_build_object('sequence_id', o.sequence_id, 'producer', o.producer,
			                   'payload', o.payload, 'metadata', o.metadata) AS details
			FROM {source}`)
	}
	if len(branches) == 0 {
		// Unreachable (parse always selects a source); keeps the SQL valid.
		return `SELECT ` + memberActivityColumns + ` FROM (SELECT NULL::text AS id, NULL::timestamptz AS at,
			NULL::text AS source, NULL::text AS member_id, NULL::text AS actor_id, NULL::text AS actor_role,
			NULL::text AS category, NULL::text AS action_key, NULL::text AS action_label, NULL::text AS method,
			NULL::text AS route, NULL::int AS status_code, NULL::text AS outcome, NULL::bigint AS duration_ms,
			NULL::text AS entity_type, NULL::text AS entity_id, NULL::text AS ip, NULL::text AS device_id,
			NULL::text AS platform, NULL::text AS app_version, NULL::text AS user_agent, NULL::text AS request_id,
			NULL::text AS correlation_id, NULL::text AS session_id, NULL::jsonb AS details) z WHERE FALSE`
	}
	return strings.Join(branches, "\nUNION ALL\n")
}

// memberActivityCountCap bounds the total of the merged log. The sources
// together hold millions of rows; counting them all on every page would cost
// seconds, so the count stops after this many matches and the response says
// total_capped. Per member and per window the real total is usually far lower.
const memberActivityCountCap = 10000

// listMemberActivityPage runs one page of the merged log: total (capped at
// memberActivityCountCap) and the page ordered by (at, source, id).
//
// queryAdminPage is not used here because its COUNT and its page share one
// FROM; this log needs a capped count and a per-branch top-N page.
func listMemberActivityPage(ctx context.Context, db adminPageQueryer, f memberActivityFilter, p adminListParams) ([]map[string]any, int, bool, error) {
	domainTypes, err := memberActivityDomainTypes(ctx, db, f)
	if err != nil {
		return nil, 0, false, err
	}
	countFilter := newSQLFilter()
	countUnion := buildMemberActivityUnion(f, memberActivityQueryOptions{
		From: p.From, To: p.To, Q: p.Q, DomainAggregateTypes: domainTypes,
	}, countFilter)
	var counted int
	if err := db.QueryRowContext(ctx, fmt.Sprintf(`SELECT COUNT(*) FROM (SELECT 1 FROM (%s) a LIMIT %d) c`,
		countUnion, memberActivityCountCap+1), countFilter.Args()...).Scan(&counted); err != nil {
		return nil, 0, false, err
	}
	total, capped := counted, counted > memberActivityCountCap
	if capped {
		total = memberActivityCountCap
	}
	items := make([]map[string]any, 0, p.Limit)
	if counted == 0 || (!capped && p.Offset >= counted) {
		return items, total, capped, nil
	}

	filter := newSQLFilter()
	union := buildMemberActivityUnion(f, memberActivityQueryOptions{
		From: p.From, To: p.To, Q: p.Q, BranchLimit: p.Offset + p.Limit, BranchOrder: p.direction(),
		DomainAggregateTypes: domainTypes,
	}, filter)
	query := `SELECT a.* FROM (` + union + `) a ORDER BY ` + p.OrderBy() + p.LimitOffset()
	rows, err := db.QueryContext(ctx, query, filter.Args()...)
	if err != nil {
		return nil, 0, false, err
	}
	defer rows.Close()
	columns, err := rows.ColumnTypes()
	if err != nil {
		return nil, 0, false, err
	}
	for rows.Next() {
		item, err := scanAdminRowMap(rows, columns)
		if err != nil {
			return nil, 0, false, err
		}
		items = append(items, item)
	}
	return items, total, capped, rows.Err()
}

// memberActivitySummary counts the member's actions by category over the
// window and reports first/last seen and distinct devices and IP addresses.
func memberActivitySummary(ctx context.Context, db adminPageQueryer, f memberActivityFilter, p adminListParams) (map[string]any, error) {
	filter := newSQLFilter()
	union := buildMemberActivityUnion(f, memberActivityQueryOptions{From: p.From, To: p.To, Q: p.Q, SkipCategory: true}, filter)
	var byCategory []byte
	var first, last sql.NullTime
	var devices, ips, total int64
	err := db.QueryRowContext(ctx, `WITH a AS (`+union+`)
		SELECT (SELECT COALESCE(jsonb_object_agg(category, n), '{}'::jsonb)
		          FROM (SELECT category, COUNT(*) AS n FROM a GROUP BY category) c),
		       MIN(at), MAX(at), COUNT(DISTINCT device_id), COUNT(DISTINCT ip), COUNT(*)
		FROM a`, filter.Args()...).Scan(&byCategory, &first, &last, &devices, &ips, &total)
	if err != nil {
		return nil, err
	}
	counts := map[string]any{}
	_ = json.Unmarshal(byCategory, &counts)
	for _, category := range memberActionCategories {
		if _, ok := counts[category]; !ok {
			counts[category] = 0
		}
	}
	summary := map[string]any{
		"by_category":      counts,
		"total":            total,
		"distinct_devices": devices,
		"distinct_ips":     ips,
		"first_seen":       nil,
		"last_seen":        nil,
	}
	if first.Valid {
		summary["first_seen"] = first.Time.UTC().Format(time.RFC3339Nano)
	}
	if last.Valid {
		summary["last_seen"] = last.Time.UTC().Format(time.RFC3339Nano)
	}
	return summary, nil
}

// streamMemberActivity returns up to limit actions strictly after the cursor,
// oldest first; without a cursor, the latest limit actions, oldest first.
// Only settled rows (older than memberActivityStreamSettle) are returned.
func streamMemberActivity(ctx context.Context, db adminPageQueryer, f memberActivityFilter, after *memberActivityCursor, limit int) ([]map[string]any, error) {
	domainTypes, err := memberActivityDomainTypes(ctx, db, f)
	if err != nil {
		return nil, err
	}
	filter := newSQLFilter()
	direction := "ASC"
	if after == nil {
		direction = "DESC"
	}
	union := buildMemberActivityUnion(f, memberActivityQueryOptions{
		After: after, SettledOnly: true, BranchLimit: limit, BranchOrder: direction,
		DomainAggregateTypes: domainTypes,
	}, filter)
	query := fmt.Sprintf(`SELECT a.* FROM (%s) a ORDER BY a.at %s, a.source %s, a.id %s LIMIT %d`,
		union, direction, direction, direction, limit)
	rows, err := db.QueryContext(ctx, query, filter.Args()...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	columns, err := rows.ColumnTypes()
	if err != nil {
		return nil, err
	}
	items := make([]map[string]any, 0, limit)
	for rows.Next() {
		item, err := scanAdminRowMap(rows, columns)
		if err != nil {
			return nil, err
		}
		items = append(items, item)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	if after == nil {
		slices.Reverse(items)
	}
	return items, nil
}

// presentMemberActions fills labels and keys the SQL cannot (catalog lookups
// for request rows written before the catalog existed, humanised event
// names) and hides network identifiers from roles that may not see them.
func presentMemberActions(items []map[string]any, prefix string, networkVisible bool) {
	for _, item := range items {
		source := toString(item["source"])
		key := strings.TrimSpace(toString(item["action_key"]))
		if source == memberActivitySourceRequest {
			if key == "" {
				if def, ok := lookupMemberAction(prefix, toString(item["method"]), toString(item["route"])); ok {
					item["action_key"], item["action_label"], item["category"] = def.Key, def.Label, def.Category
				}
			}
		} else if key != "" {
			item["action_label"] = humaniseEventName(key)
		}
		if !networkVisible {
			item["ip"], item["device_id"], item["user_agent"] = nil, nil, nil
			if details, ok := item["details"].(map[string]any); ok {
				delete(details, "user_agent")
				delete(details, "device_id")
			}
		}
	}
}

// principalSeesNetworkContext reports whether the operator may see IP
// addresses, device ids and user agents. Analysts read the log without them.
func principalSeesNetworkContext(r *http.Request) bool {
	principal, ok := principalFromRequest(r)
	if !ok {
		return false
	}
	return principal.Roles["admin"] || principal.Roles["ops_admin"] ||
		principal.Roles["trust_safety"] || principal.Roles["moderator"]
}

func (s *Server) memberActivityDB(w http.ResponseWriter, r *http.Request) (*sql.DB, bool) {
	if _, err := authenticatedOperatorID(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return nil, false
	}
	db := s.adminListDB()
	if db == nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("member activity store unavailable"))
		return nil, false
	}
	return db, true
}

// adminListMemberActivity serves GET /admin/activity.
func (s *Server) adminListMemberActivity(w http.ResponseWriter, r *http.Request) {
	s.serveMemberActivity(w, r, "")
}

// adminMemberActivity serves GET /admin/members/{userID}/activity.
func (s *Server) adminMemberActivity(w http.ResponseWriter, r *http.Request) {
	member := strings.ToLower(strings.TrimSpace(chi.URLParam(r, "userID")))
	if !uuidPattern.MatchString(member) {
		writeAdminListParamError(w, errors.New("userID must be a UUID"))
		return
	}
	s.serveMemberActivity(w, r, member)
}

func (s *Server) serveMemberActivity(w http.ResponseWriter, r *http.Request, member string) {
	db, ok := s.memberActivityDB(w, r)
	if !ok {
		return
	}
	params, err := parseAdminListParams(r, adminMemberActivitySpec)
	if err != nil {
		writeAdminListParamError(w, err)
		return
	}
	filter, err := parseMemberActivityFilter(r)
	if err != nil {
		writeAdminListParamError(w, err)
		return
	}
	if member != "" {
		filter.Member = member
	}
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	items, total, capped, err := listMemberActivityPage(ctx, db, filter, params)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	presentMemberActions(items, s.cfg.APIPrefix, principalSeesNetworkContext(r))
	resp := map[string]any{"actions": items, "total_capped": capped}
	if member != "" {
		resp["member_id"] = member
		summary, err := memberActivitySummary(ctx, db, filter, params)
		if err != nil {
			writeError(w, http.StatusBadGateway, err)
			return
		}
		if !principalSeesNetworkContext(r) {
			summary["distinct_ips"] = nil
			summary["distinct_devices"] = nil
		}
		resp["summary"] = summary
	}
	writeJSON(w, http.StatusOK, params.Page(resp, total))
}

// adminStreamMemberActivity serves GET /admin/activity/stream.
func (s *Server) adminStreamMemberActivity(w http.ResponseWriter, r *http.Request) {
	db, ok := s.memberActivityDB(w, r)
	if !ok {
		return
	}
	filter, err := parseMemberActivityFilter(r)
	if err != nil {
		writeAdminListParamError(w, err)
		return
	}
	var after *memberActivityCursor
	if raw := strings.TrimSpace(r.URL.Query().Get("after")); raw != "" {
		cursor, err := decodeMemberActivityCursor(raw)
		if err != nil {
			writeAdminListParamError(w, err)
			return
		}
		after = &cursor
	}
	limit := boundedQueryLimit(r, memberActivityStreamDefaultLimit, memberActivityStreamMaxLimit)
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	items, err := streamMemberActivity(ctx, db, filter, after, limit)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	presentMemberActions(items, s.cfg.APIPrefix, principalSeesNetworkContext(r))

	var next memberActivityCursor
	switch {
	case len(items) > 0:
		last := items[len(items)-1]
		at, _ := time.Parse(time.RFC3339Nano, toString(last["at"]))
		next = memberActivityCursor{At: at, Source: toString(last["source"]), ID: toString(last["id"])}
	case after != nil:
		next = *after
	default:
		// Nothing yet: start the tail at the settled edge so the next call
		// returns only newer actions.
		next = memberActivityCursor{At: time.Now().UTC().Add(-memberActivityStreamSettle)}
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"actions":   items,
		"cursor":    next.encode(),
		"limit":     limit,
		"settle_ms": memberActivityStreamSettle.Milliseconds(),
	})
}

// adminMemberActionCatalog serves GET /admin/activity/catalog.
func (s *Server) adminMemberActionCatalog(w http.ResponseWriter, r *http.Request) {
	if _, err := authenticatedOperatorID(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	coverage := s.actionCoverage
	if coverage.MutatingRoutes == 0 && s.router != nil {
		coverage = computeMemberActionCoverage(s.router, s.cfg.APIPrefix)
	}
	resp := map[string]any{
		"categories": memberActionCategories,
		"actions":    memberActionCatalogEntries(s.cfg.APIPrefix),
		"coverage":   coverage,
		"capture": map[string]any{
			"member_action_durable_writes":  memberActionDurableWrites.Load(),
			"member_action_fallback_writes": memberActionFallbackWrites.Load(),
			"sync_write_timeout_ms":         memberActionWriteTimeout.Milliseconds(),
		},
		"sources_unregistered": []string{},
	}
	if db := s.adminListDB(); db != nil {
		ctx, cancel := s.withRequestTimeout(r.Context())
		defer cancel()
		unregistered, err := unregisteredEventSources(ctx, db)
		if err != nil {
			writeError(w, http.StatusBadGateway, err)
			return
		}
		resp["sources_unregistered"] = unregistered
	}
	writeJSON(w, http.StatusOK, resp)
}

// unregisteredEventSources lists product tables with no domain event source,
// using the same coverage rule as /admin/events/metrics.
func unregisteredEventSources(ctx context.Context, db adminPageQueryer) ([]string, error) {
	rows, err := db.QueryContext(ctx, `
		SELECT n.nspname || '.' || c.relname
		FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
		WHERE n.nspname IN ('user_management','matching','progression','audit')
		  AND c.relkind IN ('r','p') AND NOT c.relispartition
		  AND NOT EXISTS (
		    SELECT 1 FROM platform.event_source_registry r
		    WHERE r.source_schema=n.nspname AND r.source_table=c.relname AND r.enabled
		  )
		ORDER BY 1`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []string{}
	for rows.Next() {
		var name string
		if err := rows.Scan(&name); err != nil {
			return nil, err
		}
		out = append(out, name)
	}
	return out, rows.Err()
}
