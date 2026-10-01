package mobile

import (
	"context"
	"database/sql"
	"encoding/csv"
	"errors"
	"fmt"
	"math"
	"net/http"
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
)

// Product analytics reports over the durable snapshots of migration 123
// (analytics.*). Read-only for the analyst role; the rebuild and the test
// account flags are admin-only (principalCanAccessAdminRoute).
//
// Every count from 1 to analyticsSuppressBelow-1 is withheld ("<5") in JSON and
// CSV, and so is every ratio or median built on such a count. Definitions live
// in documents/PRODUCT_ANALYTICS_REPORTS_2026-10-01.md and are served by
// GET /v1/admin/analytics/definitions.
const (
	analyticsSuppressBelow = 5
	analyticsMaxRangeDays  = 400
	analyticsMaxCohortWeek = 12
)

type analyticsMetricDef struct {
	Key        string  `json:"key"`
	Label      string  `json:"label"`
	Agg        string  `json:"aggregation"`
	Surface    string  `json:"surface,omitempty"`
	Definition string  `json:"definition"`
	Num        string  `json:"numerator,omitempty"`
	NumAgg     string  `json:"-"`
	Den        string  `json:"denominator,omitempty"`
	DenAgg     string  `json:"-"`
	Scale      float64 `json:"scale,omitempty"`
	Unit       string  `json:"unit,omitempty"`
}

// Aggregation over a period: sum (additive daily counts), avg (mean of the
// daily value over built days, for dau) and last (value on the last built day
// of the period, for the rolling wau/mau).
var analyticsMetricCatalog = []analyticsMetricDef{
	{Key: "dau", Label: "Daily active members", Agg: "avg", Definition: "Reportable members with an active day (authenticated session use, sign-in or any in-product action) on the UTC day."},
	{Key: "wau", Label: "Weekly active members", Agg: "last", Definition: "Distinct reportable members active on any of the 7 UTC days ending on the day."},
	{Key: "mau", Label: "Monthly active members", Agg: "last", Definition: "Distinct reportable members active on any of the 30 UTC days ending on the day."},
	{Key: "signups", Label: "New members", Agg: "sum", Surface: "onboarding", Definition: "Accounts created (users.created_at) on the day."},
	{Key: "profile_completions", Label: "Profiles completed", Agg: "sum", Surface: "onboarding", Definition: "Members whose first profile_setup_completions row falls on the day."},
	{Key: "verifications", Label: "Verifications approved", Agg: "sum", Definition: "verification_states moved to verified (reviewed_at) on the day."},
	{Key: "sessions_started", Label: "Sign-ins", Agg: "sum", Definition: "auth_sessions created on the day."},
	{Key: "likes", Label: "Likes", Agg: "sum", Surface: "discovery", Definition: "swipes with is_like on the day, attributed to the liker."},
	{Key: "passes", Label: "Passes", Agg: "sum", Surface: "discovery", Definition: "swipes without is_like on the day."},
	{Key: "matches", Label: "Match participations", Agg: "sum", Definition: "Matches created on the day, counted once for each of the two members (total ÷ 2 = new pairs)."},
	{Key: "messages_sent", Label: "Match messages", Agg: "sum", Surface: "chat", Definition: "Match chat messages sent (gift messages excluded), attributed to the sender."},
	{Key: "first_messages", Label: "Conversations opened", Agg: "sum", Definition: "First message ever sent in a match, attributed to the opener."},
	{Key: "conversations_replied", Label: "Conversations with a reply", Agg: "sum", Definition: "First message from the second member of a match after the opener wrote, attributed to the replier."},
	{Key: "date_plans_proposed", Label: "Date plans proposed", Agg: "sum", Surface: "date_plans", Definition: "match_date_plans created, attributed to the proposer."},
	{Key: "date_plans_accepted", Label: "Date plans accepted", Agg: "sum", Surface: "date_plans", Definition: "Plans whose first transition to accepted happened on the day, attributed to the accepting member."},
	{Key: "debriefs_submitted", Label: "Debriefs submitted", Agg: "sum", Surface: "date_plans", Definition: "Date debriefs recorded on the day."},
	{Key: "dates_kept", Label: "Dates kept", Agg: "sum", Definition: "Plans whose first 'it happened' debrief was recorded on the day and that no participant reported as not happened, attributed to that member."},
	{Key: "graduations", Label: "Graduations", Agg: "sum", Definition: "match_graduations confirmed on the day, attributed to the proposer (one per pair)."},
	{Key: "chapters_published", Label: "Chapters published", Agg: "sum", Surface: "chapters", Definition: "chapter_publications created on the day, not revoked and approved by the partner when there is one."},
	{Key: "blog_posts_published", Label: "Blog posts published", Agg: "sum", Surface: "blog", Definition: "blog_posts published on the day and not deleted."},
	{Key: "blog_reactions", Label: "Blog reactions", Agg: "sum", Surface: "blog", Definition: "blog_likes created on the day."},
	{Key: "blog_comments", Label: "Blog comments", Agg: "sum", Surface: "blog", Definition: "blog_comments created on the day."},
	{Key: "photos_shared", Label: "Theme photos shared", Agg: "sum", Surface: "themes", Definition: "photo_theme_entries created on the day and not rejected."},
	{Key: "photo_reactions", Label: "Theme photo reactions", Agg: "sum", Surface: "themes", Definition: "photo_entry_likes created on the day."},
	{Key: "club_posts", Label: "Club posts", Agg: "sum", Surface: "clubs", Definition: "club_posts created on the day."},
	{Key: "club_joins", Label: "Club joins", Agg: "sum", Surface: "clubs", Definition: "club_members joined on the day (owners excluded)."},
	{Key: "room_messages", Label: "Room messages", Agg: "sum", Surface: "rooms", Definition: "social_messages in conversation room channels."},
	{Key: "room_joins", Label: "Room joins", Agg: "sum", Surface: "rooms", Definition: "conversation_room_participants whose joined_at is on the day (a re-join moves joined_at)."},
	{Key: "groups_created", Label: "Groups created", Agg: "sum", Surface: "groups", Definition: "community_groups created on the day."},
	{Key: "group_joins", Label: "Group joins", Agg: "sum", Surface: "groups", Definition: "community_group_members joined on the day (owners excluded; a re-join moves joined_at)."},
	{Key: "group_messages", Label: "Group messages", Agg: "sum", Surface: "groups", Definition: "social_messages in group channels."},
	{Key: "friend_requests_sent", Label: "Friend requests sent", Agg: "sum", Surface: "friends", Definition: "friend_request_sends on the day."},
	{Key: "friend_requests_accepted", Label: "Friend requests accepted", Agg: "sum", Surface: "friends", Definition: "Accepted friendships whose second (accepting) row was created on the day."},
	{Key: "friend_messages", Label: "Friend messages", Agg: "sum", Surface: "friends", Definition: "social_messages in friend channels."},
	{Key: "gifts_sent", Label: "Gifts sent", Agg: "sum", Surface: "gifts", Definition: "match_gift_sends that are not system gifts and not cancelled."},
	{Key: "xp_awarded", Label: "XP awarded", Agg: "sum", Definition: "Sum of positive xp_ledger.awarded_xp on the day."},
	{Key: "rewards_claimed", Label: "Rewards claimed", Agg: "sum", Surface: "rewards", Definition: "progression.reward_claims on the day."},
	{Key: "reports_filed", Label: "Reports filed", Agg: "sum", Surface: "safety", Definition: "moderation_reports plus blog_cases with a reporter, attributed to the reporter."},
	{Key: "blocks", Label: "Blocks", Agg: "sum", Surface: "safety", Definition: "blocked_users rows created, attributed to the blocker."},
	{Key: "active_days_without_match", Label: "Active days without a new match", Agg: "sum", Definition: "Active member-days with no match created for that member on the day."},
	{Key: "good_days", Label: "Good days", Agg: "sum", Definition: "Active member-days with no new match that included an entertainment action (chapters, blog, themes, clubs, rooms, groups, friends, rewards)."},
	{Key: "stickiness", Label: "Stickiness (DAU/MAU)", Agg: "derived", Num: "dau", NumAgg: "avg", Den: "mau", DenAgg: "last", Scale: 100, Unit: "%", Definition: "Average DAU in the period ÷ MAU on its last day."},
	{Key: "plans_kept_per_active_member", Label: "Plans kept per active member", Agg: "derived", Num: "dates_kept", NumAgg: "sum", Den: "wau", DenAgg: "last", Scale: 1, Unit: "per member", Definition: "Dates kept in the period ÷ WAU on its last day. At weekly grain this is the north star."},
	{Key: "good_day_share", Label: "Good-day share", Agg: "derived", Num: "good_days", NumAgg: "sum", Den: "active_days_without_match", DenAgg: "sum", Scale: 100, Unit: "%", Definition: "Good days ÷ active days without a new match. Filter gender=female for the women's rate."},
	{Key: "matches_per_active_member", Label: "Match participations per active member", Agg: "derived", Num: "matches", NumAgg: "sum", Den: "wau", DenAgg: "last", Scale: 1, Unit: "per member", Definition: "Match participations in the period ÷ WAU on its last day."},
	{Key: "reports_per_1k_dau", Label: "Reports per 1,000 DAU", Agg: "derived", Num: "reports_filed", NumAgg: "sum", Den: "dau", DenAgg: "sum", Scale: 1000, Unit: "per 1k active member-days", Definition: "Reports filed ÷ active member-days × 1,000."},
}

var analyticsSurfaceCatalog = []struct{ Key, Label, Actions string }{
	{"onboarding", "Onboarding & profile", "sign-up, first profile completion"},
	{"discovery", "Discovery", "likes and passes"},
	{"chat", "Match chat", "messages sent"},
	{"date_plans", "Date plans", "proposals, acceptances, debriefs"},
	{"chapters", "Chapters", "couple chapters published"},
	{"blog", "Blog", "posts, reactions, comments"},
	{"themes", "Photo themes", "photos shared, reactions"},
	{"clubs", "Book & film clubs", "posts, joins"},
	{"rooms", "Conversation rooms", "messages, joins"},
	{"groups", "Lifestyle groups", "groups created, joins, messages"},
	{"friends", "Friends", "requests sent and accepted, friend chat"},
	{"gifts", "Gifts", "gifts sent"},
	{"rewards", "Rewards", "rewards claimed"},
	{"safety", "Safety tools", "reports filed, blocks"},
}

var analyticsEntertainmentSurfaces = "'chapters','blog','themes','clubs','rooms','groups','friends','rewards'"

var analyticsSegmentDims = []string{"gender", "city", "age_band", "account_age_band", "level_band"}

var analyticsSegmentValues = map[string][]string{
	"gender":           {"female", "male", "other", "unknown"},
	"age_band":         {"18-24", "25-29", "30-34", "35-44", "45+", "unknown"},
	"account_age_band": {"day_0", "days_1_6", "days_7_29", "days_30_89", "days_90_plus", "unknown"},
	"level_band":       {"L1-L3", "L4-L7", "L8-L10"},
}

func analyticsMetric(key string) (analyticsMetricDef, bool) {
	for _, m := range analyticsMetricCatalog {
		if m.Key == key {
			return m, true
		}
	}
	return analyticsMetricDef{}, false
}

// ── Parameters ───────────────────────────────────────────────────────────────

type analyticsSegments map[string]string

type analyticsParams struct {
	From, To time.Time
	Seg      analyticsSegments
	Grain    string
	GroupBy  string
	Format   string
	Table    string
	Latest   time.Time
}

type analyticsInputError struct{ msg string }

func (e analyticsInputError) Error() string { return e.msg }

func analyticsBad(format string, args ...any) error {
	return analyticsInputError{fmt.Sprintf(format, args...)}
}

// latestBuiltDay is the newest day with rollups, or yesterday when none exist.
func latestBuiltDay(ctx context.Context, db *sql.DB) time.Time {
	var day sql.NullTime
	_ = db.QueryRowContext(ctx, `SELECT MAX(day) FROM analytics.snapshot_days WHERE built_at IS NOT NULL`).Scan(&day)
	if day.Valid {
		return utcDay(day.Time)
	}
	return utcDay(time.Now()).AddDate(0, 0, -1)
}

func parseAnalyticsDay(raw string) (time.Time, error) {
	t, err := time.Parse(time.DateOnly, strings.TrimSpace(raw))
	if err != nil {
		return time.Time{}, analyticsBad("dates must be YYYY-MM-DD")
	}
	return t, nil
}

func analyticsParamsFromRequest(r *http.Request, latest time.Time, defaultDays int) (analyticsParams, error) {
	q := r.URL.Query()
	p := analyticsParams{Seg: analyticsSegments{}, Grain: "day", Format: "json", Latest: latest}
	p.To = latest
	for _, key := range []string{"to", "as_of"} {
		if raw := q.Get(key); raw != "" {
			day, err := parseAnalyticsDay(raw)
			if err != nil {
				return p, err
			}
			p.To = day
		}
	}
	p.From = p.To.AddDate(0, 0, -(defaultDays - 1))
	if raw := q.Get("from"); raw != "" {
		day, err := parseAnalyticsDay(raw)
		if err != nil {
			return p, err
		}
		p.From = day
	}
	if p.To.Before(p.From) {
		return p, analyticsBad("from must not be after to")
	}
	if int(p.To.Sub(p.From).Hours()/24)+1 > analyticsMaxRangeDays {
		return p, analyticsBad("a report covers at most %d days", analyticsMaxRangeDays)
	}
	for _, dim := range analyticsSegmentDims {
		value := strings.TrimSpace(q.Get(dim))
		if value == "" || strings.EqualFold(value, "all") {
			continue
		}
		if dim == "city" {
			if len(value) > 100 {
				return p, analyticsBad("city is too long")
			}
		} else if !containsString(analyticsSegmentValues[dim], value) {
			return p, analyticsBad("%s must be one of %s", dim, strings.Join(analyticsSegmentValues[dim], ", "))
		}
		p.Seg[dim] = value
	}
	if g := strings.TrimSpace(q.Get("grain")); g != "" {
		if g != "day" && g != "week" && g != "month" {
			return p, analyticsBad("grain must be day, week or month")
		}
		p.Grain = g
	}
	if g := strings.TrimSpace(q.Get("group_by")); g != "" && g != "none" {
		if !containsString(analyticsSegmentDims, g) {
			return p, analyticsBad("group_by must be one of %s", strings.Join(analyticsSegmentDims, ", "))
		}
		p.GroupBy = g
	}
	if f := strings.ToLower(strings.TrimSpace(q.Get("format"))); f == "csv" || strings.Contains(r.Header.Get("Accept"), "text/csv") {
		p.Format = "csv"
	} else if f != "" && f != "json" {
		return p, analyticsBad("format must be json or csv")
	}
	p.Table = strings.TrimSpace(q.Get("table"))
	return p, nil
}

// rollupSQL filters analytics.daily_metrics (alias) by the requested segment
// cells. Placeholders start at $start; skip omits one dimension.
func (seg analyticsSegments) rollupSQL(alias string, start int, skip string) (string, []any) {
	var b strings.Builder
	var args []any
	for _, dim := range analyticsSegmentDims {
		value := seg[dim]
		if value == "" || dim == skip {
			continue
		}
		args = append(args, value)
		idx := start + len(args) - 1
		if dim == "city" {
			fmt.Fprintf(&b, " AND %s.city = analytics.normalize_city($%d::text)", alias, idx)
		} else {
			fmt.Fprintf(&b, " AND %s.%s = $%d::text", alias, dim, idx)
		}
	}
	return b.String(), args
}

// memberSQL filters analytics.reportable_members (alias) by segment. Bands
// that depend on a date use asOf (an SQL date expression); level band is the
// member's current level.
func (seg analyticsSegments) memberSQL(alias, asOf string, start int, skip string) (string, []any) {
	var b strings.Builder
	var args []any
	for _, dim := range analyticsSegmentDims {
		value := seg[dim]
		if value == "" || dim == skip {
			continue
		}
		args = append(args, value)
		idx := start + len(args) - 1
		switch dim {
		case "gender":
			fmt.Fprintf(&b, " AND %s.gender = $%d::text", alias, idx)
		case "city":
			fmt.Fprintf(&b, " AND %s.city = analytics.normalize_city($%d::text)", alias, idx)
		case "age_band":
			fmt.Fprintf(&b, " AND analytics.age_band(%s.date_of_birth, %s) = $%d::text", alias, asOf, idx)
		case "account_age_band":
			fmt.Fprintf(&b, " AND analytics.account_age_band((%s.created_at AT TIME ZONE 'UTC')::date, %s) = $%d::text", alias, asOf, idx)
		case "level_band":
			fmt.Fprintf(&b, " AND analytics.level_band(COALESCE((SELECT l.current_level FROM progression.user_level_state l WHERE l.user_id = %s.user_id), 1)) = $%d::text", alias, idx)
		}
	}
	return b.String(), args
}

// ── Tables, suppression, output ──────────────────────────────────────────────

type analyticsColumn struct {
	Key     string  `json:"key"`
	Label   string  `json:"label"`
	Kind    string  `json:"kind"` // dimension | count | ratio | median | number
	Unit    string  `json:"unit,omitempty"`
	Num     string  `json:"-"`
	Den     string  `json:"-"`
	Scale   float64 `json:"-"`
	Support string  `json:"-"`
}

type analyticsRaw map[string]any

type analyticsTable struct {
	Name    string
	Columns []analyticsColumn
	Rows    []map[string]any
}

func analyticsNumber(v any) (float64, bool) {
	switch n := v.(type) {
	case nil:
		return 0, false
	case int:
		return float64(n), true
	case int64:
		return float64(n), true
	case float64:
		if math.IsNaN(n) || math.IsInf(n, 0) {
			return 0, false
		}
		return n, true
	case sql.NullFloat64:
		return n.Float64, n.Valid
	case sql.NullInt64:
		return float64(n.Int64), n.Valid
	}
	return 0, false
}

// analyticsSmall: a count that would identify too few members to publish.
func analyticsSmall(v any) bool {
	n, ok := analyticsNumber(v)
	return ok && n > 0 && n < analyticsSuppressBelow
}

func analyticsRound(v float64, places int) any {
	if v == math.Trunc(v) && math.Abs(v) < 1e15 {
		return int64(v)
	}
	p := math.Pow(10, float64(places))
	return math.Round(v*p) / p
}

func finalizeAnalyticsRow(cols []analyticsColumn, raw analyticsRaw) map[string]any {
	out := map[string]any{}
	suppressed := []string{}
	for _, col := range cols {
		switch col.Kind {
		case "dimension":
			out[col.Key] = raw[col.Key]
		case "count", "number":
			v, ok := analyticsNumber(raw[col.Key])
			gate := raw[col.Key]
			if col.Support != "" {
				gate = raw[col.Support]
			}
			switch {
			case analyticsSmall(gate):
				out[col.Key] = nil
				suppressed = append(suppressed, col.Key)
			case !ok:
				out[col.Key] = nil
			default:
				out[col.Key] = analyticsRound(v, 2)
			}
		case "ratio":
			n, nok := analyticsNumber(raw[col.Num])
			d, dok := analyticsNumber(raw[col.Den])
			switch {
			case analyticsSmall(raw[col.Num]) || analyticsSmall(raw[col.Den]):
				out[col.Key] = nil
				suppressed = append(suppressed, col.Key)
			case !nok || !dok || d == 0:
				out[col.Key] = nil
			default:
				scale := col.Scale
				if scale == 0 {
					scale = 1
				}
				out[col.Key] = analyticsRound(n/d*scale, 4)
			}
		case "median":
			v, ok := analyticsNumber(raw[col.Key])
			switch {
			case analyticsSmall(raw[col.Support]):
				out[col.Key] = nil
				suppressed = append(suppressed, col.Key)
			case !ok:
				out[col.Key] = nil
			default:
				out[col.Key] = analyticsRound(v, 2)
			}
		}
	}
	out["suppressed"] = suppressed
	return out
}

func newAnalyticsTable(name string, cols []analyticsColumn, raws []analyticsRaw) analyticsTable {
	t := analyticsTable{Name: name, Columns: cols, Rows: make([]map[string]any, 0, len(raws))}
	for _, raw := range raws {
		t.Rows = append(t.Rows, finalizeAnalyticsRow(cols, raw))
	}
	return t
}

var analyticsCSVUnsafe = regexp.MustCompile(`^[=+\-@\t\r]`)

func analyticsCSVCell(row map[string]any, key string) string {
	if list, ok := row["suppressed"].([]string); ok && containsString(list, key) {
		return fmt.Sprintf("<%d", analyticsSuppressBelow)
	}
	switch v := row[key].(type) {
	case nil:
		return ""
	case string:
		// Member-entered text (city names) must not become a spreadsheet formula.
		if analyticsCSVUnsafe.MatchString(v) {
			return "'" + v
		}
		return v
	case time.Time:
		return v.Format(time.DateOnly)
	case float64:
		return strconv.FormatFloat(v, 'f', -1, 64)
	case int64:
		return strconv.FormatInt(v, 10)
	case bool:
		return strconv.FormatBool(v)
	default:
		return fmt.Sprint(v)
	}
}

func (p analyticsParams) segmentEcho() map[string]string {
	out := map[string]string{}
	for _, dim := range analyticsSegmentDims {
		if p.Seg[dim] != "" {
			out[dim] = p.Seg[dim]
		}
	}
	return out
}

func writeAnalyticsReport(w http.ResponseWriter, p analyticsParams, report string, tables []analyticsTable, meta map[string]any) {
	if p.Format == "csv" {
		table := tables[0]
		if p.Table != "" {
			found := false
			for _, t := range tables {
				if t.Name == p.Table {
					table, found = t, true
				}
			}
			if !found {
				writeError(w, http.StatusBadRequest, fmt.Errorf("table must be one of %s", analyticsTableNames(tables)))
				return
			}
		}
		writeAnalyticsCSV(w, p, report, table)
		return
	}
	out := map[string]any{}
	for _, t := range tables {
		out[t.Name] = map[string]any{"columns": t.Columns, "rows": t.Rows}
	}
	if meta == nil {
		meta = map[string]any{}
	}
	meta["suppression"] = fmt.Sprintf("Counts from 1 to %d, and ratios or medians built on them, are withheld and listed in each row's suppressed keys.", analyticsSuppressBelow-1)
	meta["latest_built_day"] = p.Latest.Format(time.DateOnly)
	writeJSON(w, http.StatusOK, map[string]any{
		"success": true, "report": report,
		"from": p.From.Format(time.DateOnly), "to": p.To.Format(time.DateOnly),
		"segments": p.segmentEcho(), "tables": out, "meta": meta,
	})
}

func analyticsTableNames(tables []analyticsTable) string {
	names := make([]string, 0, len(tables))
	for _, t := range tables {
		names = append(names, t.Name)
	}
	return strings.Join(names, ", ")
}

// writeAnalyticsCSV streams the rows, flushing as it goes.
func writeAnalyticsCSV(w http.ResponseWriter, p analyticsParams, report string, table analyticsTable) {
	filename := fmt.Sprintf("connect_%s_%s_%s_%s.csv", report, table.Name, p.From.Format("20060102"), p.To.Format("20060102"))
	w.Header().Set("Content-Type", "text/csv; charset=utf-8")
	w.Header().Set("Content-Disposition", `attachment; filename="`+filename+`"`)
	w.Header().Set("Cache-Control", "no-store")
	w.Header().Set("X-Analytics-Suppression", fmt.Sprintf("counts 1-%d shown as <%d", analyticsSuppressBelow-1, analyticsSuppressBelow))
	w.WriteHeader(http.StatusOK)
	cw := csv.NewWriter(w)
	header := make([]string, 0, len(table.Columns))
	for _, col := range table.Columns {
		header = append(header, col.Key)
	}
	_ = cw.Write(header)
	flusher, _ := w.(http.Flusher)
	for i, row := range table.Rows {
		record := make([]string, 0, len(table.Columns))
		for _, col := range table.Columns {
			record = append(record, analyticsCSVCell(row, col.Key))
		}
		if err := cw.Write(record); err != nil {
			return
		}
		if (i+1)%250 == 0 {
			cw.Flush()
			if flusher != nil {
				flusher.Flush()
			}
		}
	}
	cw.Flush()
}

// analyticsRequest resolves the database and the common parameters, writing
// the error response itself when it cannot.
func (s *Server) analyticsRequest(w http.ResponseWriter, r *http.Request, defaultDays int) (*sql.DB, analyticsParams, bool) {
	db, err := s.growthDB()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("analytics storage is unavailable"))
		return nil, analyticsParams{}, false
	}
	p, err := analyticsParamsFromRequest(r, latestBuiltDay(r.Context(), db), defaultDays)
	if err != nil {
		writeError(w, http.StatusBadRequest, err)
		return nil, analyticsParams{}, false
	}
	return db, p, true
}

func analyticsQueryFailed(w http.ResponseWriter, err error) {
	if errors.Is(err, context.DeadlineExceeded) || errors.Is(err, context.Canceled) {
		writeError(w, http.StatusServiceUnavailable, errors.New("the analytics query took too long; narrow the date range"))
		return
	}
	writeError(w, http.StatusServiceUnavailable, errors.New("analytics are unavailable"))
}

func dayArg(t time.Time) string { return t.Format(time.DateOnly) }

// ── KPI summary ──────────────────────────────────────────────────────────────

type analyticsTileSpec struct {
	key, label, unit, definition string
	value, previous              analyticsColumn
}

// GET /v1/admin/analytics/kpis
func (s *Server) adminAnalyticsKPIs(w http.ResponseWriter, r *http.Request) {
	db, p, ok := s.analyticsRequest(w, r, 1)
	if !ok {
		return
	}
	ctx := r.Context()
	asOf := dayArg(p.To)
	segSQL, segArgs := p.Seg.rollupSQL("d", 2, "")
	sums := map[string]map[int]float64{} // metric -> days before asOf -> value
	femaleWAU := map[int]float64{}
	rows, err := db.QueryContext(ctx, `
		SELECT d.metric, ($1::date - d.day) AS back, d.gender = 'female' AS female, SUM(d.value)
		  FROM analytics.daily_metrics d
		 WHERE d.day BETWEEN $1::date - 13 AND $1::date
		   AND d.metric IN ('dau','wau','mau','signups','dates_kept','matches','reports_filed','blocks')`+segSQL+`
		 GROUP BY 1, 2, 3`, append([]any{asOf}, segArgs...)...)
	if err != nil {
		analyticsQueryFailed(w, err)
		return
	}
	for rows.Next() {
		var metric string
		var back int
		var female bool
		var value float64
		if err := rows.Scan(&metric, &back, &female, &value); err != nil {
			rows.Close()
			analyticsQueryFailed(w, err)
			return
		}
		if sums[metric] == nil {
			sums[metric] = map[int]float64{}
		}
		sums[metric][back] += value
		if metric == "wau" && female {
			femaleWAU[back] += value
		}
	}
	rows.Close()
	window := func(metric string, from, to int) float64 {
		var total float64
		for back := from; back <= to; back++ {
			total += sums[metric][back]
		}
		return total
	}
	raw := analyticsRaw{
		"dau": sums["dau"][0], "dau_prev": sums["dau"][7],
		"wau": sums["wau"][0], "wau_prev": sums["wau"][7],
		"mau": sums["mau"][0], "mau_prev": sums["mau"][7],
		"signups": window("signups", 0, 6), "signups_prev": window("signups", 7, 13),
		"dates_kept": window("dates_kept", 0, 6), "dates_kept_prev": window("dates_kept", 7, 13),
		"matches": window("matches", 0, 6), "matches_prev": window("matches", 7, 13),
		"reports": window("reports_filed", 0, 6), "reports_prev": window("reports_filed", 7, 13),
		"blocks": window("blocks", 0, 6), "blocks_prev": window("blocks", 7, 13),
		"dau_days": window("dau", 0, 6), "dau_days_prev": window("dau", 7, 13),
		"female_wau": femaleWAU[0], "female_wau_prev": femaleWAU[7],
	}
	goodDayApplies := p.Seg["gender"] == "" || p.Seg["gender"] == "female"
	if goodDayApplies {
		memberSQL, memberArgs := p.Seg.memberSQL("m", "$1::date", 2, "gender")
		var current, previous int64
		err := db.QueryRowContext(ctx, `
			SELECT COUNT(DISTINCT s.user_id) FILTER (WHERE s.day BETWEEN $1::date - 6 AND $1::date),
			       COUNT(DISTINCT s.user_id) FILTER (WHERE s.day BETWEEN $1::date - 13 AND $1::date - 7)
			  FROM analytics.member_surface_days s
			  JOIN analytics.reportable_members m ON m.user_id = s.user_id
			 WHERE m.gender = 'female' AND s.day BETWEEN $1::date - 13 AND $1::date
			   AND s.surface IN (`+analyticsEntertainmentSurfaces+`)
			   AND NOT EXISTS (
			     SELECT 1 FROM matching.matches x
			      WHERE (x.user_id_1 = s.user_id OR x.user_id_2 = s.user_id)
			        AND x.created_at >= (s.day::timestamp AT TIME ZONE 'UTC')
			        AND x.created_at < ((s.day + 1)::timestamp AT TIME ZONE 'UTC'))`+memberSQL,
			append([]any{asOf}, memberArgs...)...).Scan(&current, &previous)
		if err != nil {
			analyticsQueryFailed(w, err)
			return
		}
		raw["good_women"], raw["good_women_prev"] = current, previous
	}
	count := func(key string) analyticsColumn { return analyticsColumn{Key: key, Kind: "count"} }
	ratio := func(num, den string, scale float64) analyticsColumn {
		return analyticsColumn{Key: num + "_per_" + den, Kind: "ratio", Num: num, Den: den, Scale: scale}
	}
	specs := []analyticsTileSpec{
		{"dau", "DAU", "members", "Reportable members active on the as-of UTC day.", count("dau"), count("dau_prev")},
		{"wau", "WAU", "members", "Distinct reportable members active in the 7 days ending on the as-of day.", count("wau"), count("wau_prev")},
		{"mau", "MAU", "members", "Distinct reportable members active in the 30 days ending on the as-of day.", count("mau"), count("mau_prev")},
		{"stickiness", "Stickiness (DAU/MAU)", "%", "DAU ÷ MAU on the as-of day.", ratio("dau", "mau", 100), ratio("dau_prev", "mau_prev", 100)},
		{"new_members", "New members (7 days)", "members", "Reportable accounts created in the 7 days ending on the as-of day.", count("signups"), count("signups_prev")},
		{"plans_kept_per_active_member", "Weekly plans kept per active member", "per member", "North star: dates kept in the 7 days ending on the as-of day ÷ WAU. Launch-to-live target (assumption): 0.08.", ratio("dates_kept", "wau", 1), ratio("dates_kept_prev", "wau_prev", 1)},
		{"womens_good_day_rate", "Women's weekly good-day rate", "%", "Women with at least one good day (an entertainment action on a day with no new match) in the 7 days ÷ female WAU.", ratio("good_women", "female_wau", 100), ratio("good_women_prev", "female_wau_prev", 100)},
		{"matches_per_active_member", "Match participations per active member (7 days)", "per member", "Match participations in 7 days ÷ WAU.", ratio("matches", "wau", 1), ratio("matches_prev", "wau_prev", 1)},
		{"reports_per_1k_dau", "Reports per 1,000 DAU (7 days)", "per 1k", "Reports filed in 7 days ÷ active member-days × 1,000.", ratio("reports", "dau_days", 1000), ratio("reports_prev", "dau_days_prev", 1000)},
		{"blocks_per_1k_dau", "Blocks per 1,000 DAU (7 days)", "per 1k", "Blocks in 7 days ÷ active member-days × 1,000.", ratio("blocks", "dau_days", 1000), ratio("blocks_prev", "dau_days_prev", 1000)},
	}
	tiles := make([]map[string]any, 0, len(specs))
	for _, spec := range specs {
		if spec.key == "womens_good_day_rate" && !goodDayApplies {
			continue
		}
		value := spec.value
		value.Key = "value"
		previous := spec.previous
		previous.Key = "previous"
		if value.Kind == "count" {
			raw["value"], raw["previous"] = raw[spec.value.Key], raw[spec.previous.Key]
		}
		row := finalizeAnalyticsRow([]analyticsColumn{value, previous}, raw)
		row["key"], row["label"], row["unit"], row["definition"] = spec.key, spec.label, spec.unit, spec.definition
		tiles = append(tiles, row)
	}
	table := analyticsTable{Name: "tiles", Columns: []analyticsColumn{
		{Key: "key", Label: "KPI", Kind: "dimension"}, {Key: "label", Label: "Label", Kind: "dimension"},
		{Key: "value", Label: "Value", Kind: "number"}, {Key: "previous", Label: "Same day last week", Kind: "number"},
		{Key: "unit", Label: "Unit", Kind: "dimension"}, {Key: "definition", Label: "Definition", Kind: "dimension"},
	}, Rows: tiles}
	p.From = p.To
	writeAnalyticsReport(w, p, "kpis", []analyticsTable{table}, map[string]any{
		"as_of":   asOf,
		"compare": "previous = the same window ending 7 days earlier",
	})
}

// ── Trends ───────────────────────────────────────────────────────────────────

// GET /v1/admin/analytics/trends?metric=&grain=&group_by=
func (s *Server) adminAnalyticsTrends(w http.ResponseWriter, r *http.Request) {
	db, p, ok := s.analyticsRequest(w, r, 28)
	if !ok {
		return
	}
	key := strings.TrimSpace(r.URL.Query().Get("metric"))
	if key == "" {
		key = "dau"
	}
	metric, found := analyticsMetric(key)
	if !found {
		writeError(w, http.StatusBadRequest, errors.New("unknown metric; see /v1/admin/analytics/definitions"))
		return
	}
	type part struct{ metric, agg string }
	parts := []part{{metric.Key, metric.Agg}}
	if metric.Agg == "derived" {
		parts = []part{{metric.Num, metric.NumAgg}, {metric.Den, metric.DenAgg}}
	}
	names := make([]string, 0, len(parts))
	for _, pt := range parts {
		names = append(names, pt.metric)
	}
	group := "'all'"
	if p.GroupBy != "" {
		group = "d." + p.GroupBy // whitelisted in analyticsParamsFromRequest
	}
	segSQL, segArgs := p.Seg.rollupSQL("d", 5, "")
	query := `
		WITH periods AS (
		  SELECT date_trunc($3, day::timestamp)::date AS period, MAX(day) AS last_day, COUNT(*) AS days
		    FROM analytics.snapshot_days
		   WHERE built_at IS NOT NULL AND day BETWEEN $1::date AND $2::date
		   GROUP BY 1
		), agg AS (
		  SELECT date_trunc($3, d.day::timestamp)::date AS period, ` + group + ` AS seg, d.metric, d.day, SUM(d.value) AS v
		    FROM analytics.daily_metrics d
		   WHERE d.metric = ANY(string_to_array($4, ',')) AND d.day BETWEEN $1::date AND $2::date` + segSQL + `
		   GROUP BY 1, 2, 3, 4
		)
		SELECT p.period, p.days, a.seg, a.metric,
		       COALESCE(SUM(a.v), 0), COALESCE(SUM(a.v) FILTER (WHERE a.day = p.last_day), 0)
		  FROM periods p LEFT JOIN agg a ON a.period = p.period
		 GROUP BY p.period, p.days, a.seg, a.metric
		 ORDER BY p.period, a.seg`
	args := append([]any{dayArg(p.From), dayArg(p.To), p.Grain, strings.Join(names, ",")}, segArgs...)
	rows, err := db.QueryContext(r.Context(), query, args...)
	if err != nil {
		analyticsQueryFailed(w, err)
		return
	}
	defer rows.Close()
	type cellKey struct {
		period time.Time
		seg    string
	}
	var order []cellKey
	cells := map[cellKey]map[string]float64{}
	days := map[time.Time]float64{}
	for rows.Next() {
		var period time.Time
		var nDays int64
		var seg, name sql.NullString
		var sum, last float64
		if err := rows.Scan(&period, &nDays, &seg, &name, &sum, &last); err != nil {
			analyticsQueryFailed(w, err)
			return
		}
		days[period] = float64(nDays)
		segment := "all"
		if seg.Valid {
			segment = seg.String
		} else if p.GroupBy != "" {
			continue // a built period with no rows for any segment
		}
		k := cellKey{period, segment}
		if cells[k] == nil {
			cells[k] = map[string]float64{}
			order = append(order, k)
		}
		if name.Valid {
			cells[k][name.String+":sum"] = sum
			cells[k][name.String+":last"] = last
		}
	}
	if err := rows.Err(); err != nil {
		analyticsQueryFailed(w, err)
		return
	}
	value := func(c map[string]float64, pt part, nDays float64) float64 {
		switch pt.agg {
		case "avg":
			if nDays == 0 {
				return 0
			}
			return c[pt.metric+":sum"] / nDays
		case "last":
			return c[pt.metric+":last"]
		default:
			return c[pt.metric+":sum"]
		}
	}
	cols := []analyticsColumn{{Key: "period", Label: "Period start", Kind: "dimension"}}
	if p.GroupBy != "" {
		cols = append(cols, analyticsColumn{Key: "segment", Label: p.GroupBy, Kind: "dimension"})
	}
	if metric.Agg == "derived" {
		cols = append(cols,
			analyticsColumn{Key: "numerator", Label: metric.Num, Kind: "count"},
			analyticsColumn{Key: "denominator", Label: metric.Den, Kind: "count"},
			analyticsColumn{Key: "value", Label: metric.Label, Kind: "ratio", Num: "numerator", Den: "denominator", Scale: metric.Scale, Unit: metric.Unit})
	} else {
		cols = append(cols, analyticsColumn{Key: "value", Label: metric.Label, Kind: "count"})
	}
	raws := make([]analyticsRaw, 0, len(order))
	for _, k := range order {
		raw := analyticsRaw{"period": k.period.Format(time.DateOnly), "segment": k.seg}
		if metric.Agg == "derived" {
			raw["numerator"] = value(cells[k], parts[0], days[k.period])
			raw["denominator"] = value(cells[k], parts[1], days[k.period])
		} else {
			raw["value"] = value(cells[k], parts[0], days[k.period])
		}
		raws = append(raws, raw)
	}
	meta := map[string]any{"metric": metric, "grain": p.Grain, "group_by": p.GroupBy}
	if len(raws) == 0 {
		meta["warning"] = "No snapshot days are built in this range yet."
	}
	writeAnalyticsReport(w, p, "trends", []analyticsTable{newAnalyticsTable("series", cols, raws)}, meta)
}

// ── Activation funnel ────────────────────────────────────────────────────────

var analyticsFunnelSteps = []struct{ key, label, column string }{
	{"signup", "Signed up", "signup_at"},
	{"terms", "Accepted terms", "terms_at"},
	{"profile_complete", "Completed profile", "profile_complete_at"},
	{"verified", "Verified", "verified_at"},
	{"first_like", "First like", "first_like_at"},
	{"first_match", "First match", "first_match_at"},
	{"first_message", "First message", "first_message_at"},
	{"two_way", "Two-way conversation", "two_way_at"},
	{"plan_accepted", "Date plan accepted", "plan_accepted_at"},
	{"date_kept", "Date kept", "date_kept_at"},
}

// GET /v1/admin/analytics/funnel?cohort=week|all&within_days=
func (s *Server) adminAnalyticsFunnel(w http.ResponseWriter, r *http.Request) {
	db, p, ok := s.analyticsRequest(w, r, 56)
	if !ok {
		return
	}
	cohort := strings.TrimSpace(r.URL.Query().Get("cohort"))
	if cohort == "" {
		cohort = "week"
	}
	if cohort != "week" && cohort != "all" {
		writeError(w, http.StatusBadRequest, errors.New("cohort must be week or all"))
		return
	}
	within := 0
	if raw := strings.TrimSpace(r.URL.Query().Get("within_days")); raw != "" {
		n, err := strconv.Atoi(raw)
		if err != nil || n < 0 || n > 365 {
			writeError(w, http.StatusBadRequest, errors.New("within_days must be 0 (no limit) to 365"))
			return
		}
		within = n
	}
	memberSQL, memberArgs := p.Seg.memberSQL("m", "(mm.signup_at AT TIME ZONE 'UTC')::date", 4, "")
	// A step counts when it was reached (within the window) and every earlier
	// step was reached too: a strict funnel. Each tN is built in a lateral on
	// top of t(N-1).
	selects := []string{"COUNT(*) AS s0", "NULL::float8 AS mp0", "NULL::float8 AS ms0"}
	from := "c"
	stepCols := ""
	for i := 1; i < len(analyticsFunnelSteps); i++ {
		prev := "c.signup_at"
		if i > 1 {
			prev = fmt.Sprintf("x%d.t%d", i-1, i-1)
		}
		col := "c." + analyticsFunnelSteps[i].column
		from += fmt.Sprintf(" CROSS JOIN LATERAL (SELECT CASE WHEN %[1]s IS NOT NULL AND %[2]s IS NOT NULL AND ($3::int = 0 OR %[2]s <= c.signup_at + make_interval(days => $3::int)) THEN %[2]s END AS t%[3]d) x%[3]d",
			prev, col, i)
		stepCols += fmt.Sprintf(", x%d.t%d", i, i)
		selects = append(selects,
			fmt.Sprintf("COUNT(*) FILTER (WHERE t%d IS NOT NULL) AS s%d", i, i),
			fmt.Sprintf("percentile_cont(0.5) WITHIN GROUP (ORDER BY GREATEST(0, EXTRACT(EPOCH FROM t%[1]d - t%[2]d)) / 3600) FILTER (WHERE t%[1]d IS NOT NULL) AS mp%[1]d", i, i-1),
			fmt.Sprintf("percentile_cont(0.5) WITHIN GROUP (ORDER BY GREATEST(0, EXTRACT(EPOCH FROM t%[1]d - t0)) / 3600) FILTER (WHERE t%[1]d IS NOT NULL) AS ms%[1]d", i))
	}
	cohortExpr := "$1::date"
	if cohort == "week" {
		cohortExpr = "date_trunc('week', (mm.signup_at AT TIME ZONE 'UTC'))::date"
	}
	query := `
		WITH c AS (
		  SELECT mm.*, ` + cohortExpr + ` AS cohort
		    FROM analytics.member_milestones mm
		    JOIN analytics.reportable_members m ON m.user_id = mm.user_id
		   WHERE (mm.signup_at AT TIME ZONE 'UTC')::date BETWEEN $1::date AND $2::date` + memberSQL + `
		), steps AS (
		  SELECT c.cohort, c.signup_at AS t0` + stepCols + `
		    FROM ` + from + `
		)
		SELECT cohort, ` + strings.Join(selects, ", ") + `
		  FROM steps GROUP BY cohort ORDER BY cohort`
	args := append([]any{dayArg(p.From), dayArg(p.To), within}, memberArgs...)
	rows, err := db.QueryContext(r.Context(), query, args...)
	if err != nil {
		analyticsQueryFailed(w, err)
		return
	}
	defer rows.Close()
	n := len(analyticsFunnelSteps)
	var raws []analyticsRaw
	for rows.Next() {
		var cohortDay time.Time
		counts := make([]int64, n)
		medPrev := make([]sql.NullFloat64, n)
		medSignup := make([]sql.NullFloat64, n)
		dest := []any{&cohortDay}
		for i := 0; i < n; i++ {
			dest = append(dest, &counts[i], &medPrev[i], &medSignup[i])
		}
		if err := rows.Scan(dest...); err != nil {
			analyticsQueryFailed(w, err)
			return
		}
		label := cohortDay.Format(time.DateOnly)
		if cohort == "all" {
			label = dayArg(p.From) + ".." + dayArg(p.To)
		}
		for i, step := range analyticsFunnelSteps {
			prev := counts[0]
			if i > 0 {
				prev = counts[i-1]
			}
			raw := analyticsRaw{
				"cohort": label, "step": step.key, "step_label": step.label, "step_index": int64(i + 1),
				"members": counts[i], "previous_members": prev, "signups": counts[0],
				"median_hours_from_previous": medPrev[i], "median_hours_from_signup": medSignup[i],
			}
			raws = append(raws, raw)
		}
	}
	if err := rows.Err(); err != nil {
		analyticsQueryFailed(w, err)
		return
	}
	cols := []analyticsColumn{
		{Key: "cohort", Label: "Signup cohort", Kind: "dimension"},
		{Key: "step_index", Label: "#", Kind: "dimension"},
		{Key: "step", Label: "Step", Kind: "dimension"},
		{Key: "step_label", Label: "Step label", Kind: "dimension"},
		{Key: "members", Label: "Members", Kind: "count"},
		{Key: "conversion_from_previous", Label: "From previous step", Kind: "ratio", Num: "members", Den: "previous_members", Scale: 100, Unit: "%"},
		{Key: "conversion_from_signup", Label: "From signup", Kind: "ratio", Num: "members", Den: "signups", Scale: 100, Unit: "%"},
		{Key: "median_hours_from_previous", Label: "Median hours from previous step", Kind: "median", Support: "members", Unit: "hours"},
		{Key: "median_hours_from_signup", Label: "Median hours from signup", Kind: "median", Support: "members", Unit: "hours"},
	}
	writeAnalyticsReport(w, p, "funnel", []analyticsTable{newAnalyticsTable("steps", cols, raws)}, map[string]any{
		"cohort": cohort, "within_days": within,
		"definition": "Strict funnel: a member reaches a step only after reaching every earlier step. Steps come from analytics.member_milestones, refreshed with each snapshot run. Segments use gender and city as now, and age band at signup.",
	})
}

// ── Retention ────────────────────────────────────────────────────────────────

var analyticsExperimentKey = regexp.MustCompile(`^[a-z0-9_.-]{1,80}$`)

// GET /v1/admin/analytics/retention?grain=day|week&experiment=
func (s *Server) adminAnalyticsRetention(w http.ResponseWriter, r *http.Request) {
	db, p, ok := s.analyticsRequest(w, r, 84)
	if !ok {
		return
	}
	cohortGrain := p.Grain
	if r.URL.Query().Get("grain") == "" {
		cohortGrain = "week"
	}
	experiment := strings.TrimSpace(r.URL.Query().Get("experiment"))
	if experiment != "" && !analyticsExperimentKey.MatchString(experiment) {
		writeError(w, http.StatusBadRequest, errors.New("experiment must be an experiment key"))
		return
	}
	memberSQL, memberArgs := p.Seg.memberSQL("m", "(m.created_at AT TIME ZONE 'UTC')::date", 5, "")
	variantJoin, variantExpr := "", "'all'"
	if experiment != "" {
		variantJoin = " JOIN progression.experiment_assignments ea ON ea.user_id = m.user_id AND ea.experiment_key = $4"
		variantExpr = "ea.variant"
	} else {
		memberSQL = " AND $4::text = ''" + memberSQL
	}
	cohortCTE := `
		WITH h AS (
		  SELECT COALESCE(MAX(day), (NOW() AT TIME ZONE 'UTC')::date - 1) AS horizon
		    FROM analytics.snapshot_days WHERE built_at IS NOT NULL
		), c AS (
		  SELECT m.user_id, (m.created_at AT TIME ZONE 'UTC')::date AS sd,
		         date_trunc('week', (m.created_at AT TIME ZONE 'UTC'))::date AS sw, ` + variantExpr + ` AS variant
		    FROM analytics.reportable_members m` + variantJoin + `
		   WHERE (m.created_at AT TIME ZONE 'UTC')::date BETWEEN $1::date AND $2::date` + memberSQL + `
		)`
	args := append([]any{dayArg(p.From), dayArg(p.To), cohortGrain, experiment}, memberArgs...)
	retained := func(offset string) string {
		return fmt.Sprintf(`COUNT(*) FILTER (WHERE c.sd + %[1]s <= h.horizon),
		  COUNT(*) FILTER (WHERE c.sd + %[1]s <= h.horizon AND EXISTS (
		    SELECT 1 FROM analytics.member_active_days a WHERE a.user_id = c.user_id AND a.day = c.sd + %[1]s))`, offset)
	}
	rows, err := db.QueryContext(r.Context(), cohortCTE+`
		SELECT date_trunc($3, c.sd::timestamp)::date AS cohort, c.variant, COUNT(*),
		  `+retained("1")+`, `+retained("7")+`, `+retained("30")+`
		  FROM c CROSS JOIN h
		 GROUP BY 1, 2 ORDER BY 1, 2`, args...)
	if err != nil {
		analyticsQueryFailed(w, err)
		return
	}
	var summary []analyticsRaw
	for rows.Next() {
		var cohortDay time.Time
		var variant string
		var members, d1e, d1, d7e, d7, d30e, d30 int64
		if err := rows.Scan(&cohortDay, &variant, &members, &d1e, &d1, &d7e, &d7, &d30e, &d30); err != nil {
			rows.Close()
			analyticsQueryFailed(w, err)
			return
		}
		summary = append(summary, analyticsRaw{
			"cohort": cohortDay.Format(time.DateOnly), "variant": variant, "members": members,
			"d1_eligible": d1e, "d1_retained": d1, "d7_eligible": d7e, "d7_retained": d7, "d30_eligible": d30e, "d30_retained": d30,
		})
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		analyticsQueryFailed(w, err)
		return
	}

	triangle := map[string]analyticsRaw{}
	var triangleOrder []string
	rows, err = db.QueryContext(r.Context(), cohortCTE+`, sizes AS (
		  SELECT sw, variant, COUNT(*) AS members FROM c GROUP BY 1, 2
		)
		SELECT s.sw, s.variant, s.members, g.k,
		  (SELECT COUNT(*) FROM c c2
		    WHERE c2.sw = s.sw AND c2.variant = s.variant AND EXISTS (
		      SELECT 1 FROM analytics.member_active_days a
		       WHERE a.user_id = c2.user_id AND a.day BETWEEN s.sw + 7 * g.k AND s.sw + 7 * g.k + 6))
		  FROM sizes s CROSS JOIN h CROSS JOIN generate_series(0, `+strconv.Itoa(analyticsMaxCohortWeek)+`) g(k)
		 WHERE $3::text <> '' AND s.sw + 7 * g.k + 6 <= h.horizon
		 ORDER BY 1, 2, 4`, args...)
	if err != nil {
		analyticsQueryFailed(w, err)
		return
	}
	for rows.Next() {
		var week time.Time
		var variant string
		var members, retainedCount int64
		var k int
		if err := rows.Scan(&week, &variant, &members, &k, &retainedCount); err != nil {
			rows.Close()
			analyticsQueryFailed(w, err)
			return
		}
		id := week.Format(time.DateOnly) + "|" + variant
		if triangle[id] == nil {
			triangle[id] = analyticsRaw{"cohort_week": week.Format(time.DateOnly), "variant": variant, "members": members}
			triangleOrder = append(triangleOrder, id)
		}
		triangle[id][fmt.Sprintf("retained_week_%d", k)] = retainedCount
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		analyticsQueryFailed(w, err)
		return
	}
	summaryCols := []analyticsColumn{
		{Key: "cohort", Label: "Signup cohort", Kind: "dimension"},
		{Key: "variant", Label: "Variant", Kind: "dimension"},
		{Key: "members", Label: "Members", Kind: "count"},
		{Key: "d1", Label: "D1 retention", Kind: "ratio", Num: "d1_retained", Den: "d1_eligible", Scale: 100, Unit: "%"},
		{Key: "d7", Label: "D7 retention", Kind: "ratio", Num: "d7_retained", Den: "d7_eligible", Scale: 100, Unit: "%"},
		{Key: "d30", Label: "D30 retention", Kind: "ratio", Num: "d30_retained", Den: "d30_eligible", Scale: 100, Unit: "%"},
		{Key: "d1_eligible", Label: "D1 observed members", Kind: "count"},
		{Key: "d7_eligible", Label: "D7 observed members", Kind: "count"},
		{Key: "d30_eligible", Label: "D30 observed members", Kind: "count"},
	}
	triangleCols := []analyticsColumn{
		{Key: "cohort_week", Label: "Signup week", Kind: "dimension"},
		{Key: "variant", Label: "Variant", Kind: "dimension"},
		{Key: "members", Label: "Members", Kind: "count"},
	}
	for k := 0; k <= analyticsMaxCohortWeek; k++ {
		triangleCols = append(triangleCols, analyticsColumn{
			Key: fmt.Sprintf("week_%d", k), Label: fmt.Sprintf("Week %d", k), Kind: "ratio",
			Num: fmt.Sprintf("retained_week_%d", k), Den: "members", Scale: 100, Unit: "%",
		})
	}
	triangleRaws := make([]analyticsRaw, 0, len(triangleOrder))
	for _, id := range triangleOrder {
		raw := triangle[id]
		// Weeks not yet complete stay blank rather than reading as 0%.
		for k := 0; k <= analyticsMaxCohortWeek; k++ {
			if _, ok := raw[fmt.Sprintf("retained_week_%d", k)]; !ok {
				raw[fmt.Sprintf("retained_week_%d", k)] = nil
			}
		}
		triangleRaws = append(triangleRaws, raw)
	}
	writeAnalyticsReport(w, p, "retention", []analyticsTable{
		newAnalyticsTable("summary", summaryCols, summary),
		newAnalyticsTable("triangle", triangleCols, triangleRaws),
	}, map[string]any{
		"cohort_grain": cohortGrain, "experiment": experiment,
		"definition": "Dn: share of a signup cohort active on exactly UTC day signup+n, among members for whom that day has been observed. Week k: active on any day of the k-th week after the signup week. Activity before the snapshot history began is a lower bound (derived from durable timestamps).",
	})
}

// ── Feature engagement ───────────────────────────────────────────────────────

// GET /v1/admin/analytics/engagement
func (s *Server) adminAnalyticsEngagement(w http.ResponseWriter, r *http.Request) {
	db, p, ok := s.analyticsRequest(w, r, 28)
	if !ok {
		return
	}
	memberSQL, memberArgs := p.Seg.memberSQL("m", "$2::date", 3, "")
	args := append([]any{dayArg(p.From), dayArg(p.To)}, memberArgs...)
	var activeMembers, activeDays int64
	if err := db.QueryRowContext(r.Context(), `
		SELECT COUNT(DISTINCT a.user_id), COUNT(*)
		  FROM analytics.member_active_days a JOIN analytics.reportable_members m ON m.user_id = a.user_id
		 WHERE a.day BETWEEN $1::date AND $2::date`+memberSQL, args...).Scan(&activeMembers, &activeDays); err != nil {
		analyticsQueryFailed(w, err)
		return
	}
	rows, err := db.QueryContext(r.Context(), `
		WITH su AS (
		  SELECT s.surface, s.user_id, COUNT(*) AS days, SUM(s.actions) AS actions
		    FROM analytics.member_surface_days s JOIN analytics.reportable_members m ON m.user_id = s.user_id
		   WHERE s.day BETWEEN $1::date AND $2::date`+memberSQL+`
		   GROUP BY 1, 2
		)
		SELECT surface, COUNT(*), SUM(days), SUM(actions), COUNT(*) FILTER (WHERE days >= 2)
		  FROM su GROUP BY surface`, args...)
	if err != nil {
		analyticsQueryFailed(w, err)
		return
	}
	bySurface := map[string]analyticsRaw{}
	for rows.Next() {
		var surface string
		var users, memberDays, actions, repeat int64
		if err := rows.Scan(&surface, &users, &memberDays, &actions, &repeat); err != nil {
			rows.Close()
			analyticsQueryFailed(w, err)
			return
		}
		bySurface[surface] = analyticsRaw{"users": users, "member_days": memberDays, "actions": actions, "repeat_users": repeat}
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		analyticsQueryFailed(w, err)
		return
	}
	raws := make([]analyticsRaw, 0, len(analyticsSurfaceCatalog))
	for _, surface := range analyticsSurfaceCatalog {
		raw := bySurface[surface.Key]
		if raw == nil {
			raw = analyticsRaw{"users": int64(0), "member_days": int64(0), "actions": int64(0), "repeat_users": int64(0)}
		}
		raw["surface"], raw["surface_label"], raw["counted_actions"] = surface.Key, surface.Label, surface.Actions
		raw["active_members"], raw["active_member_days"] = activeMembers, activeDays
		raws = append(raws, raw)
	}
	cols := []analyticsColumn{
		{Key: "surface", Label: "Surface", Kind: "dimension"},
		{Key: "surface_label", Label: "Label", Kind: "dimension"},
		{Key: "users", Label: "Members using it", Kind: "count"},
		{Key: "reach", Label: "Share of active members", Kind: "ratio", Num: "users", Den: "active_members", Scale: 100, Unit: "%"},
		{Key: "dau_share", Label: "Share of active member-days (DAU share)", Kind: "ratio", Num: "member_days", Den: "active_member_days", Scale: 100, Unit: "%"},
		{Key: "actions", Label: "Actions", Kind: "count"},
		{Key: "actions_per_user", Label: "Actions per member using it", Kind: "ratio", Num: "actions", Den: "users", Scale: 1},
		{Key: "repeat_users", Label: "Members using it on 2+ days", Kind: "count"},
		{Key: "repeat_rate", Label: "Repeat use", Kind: "ratio", Num: "repeat_users", Den: "users", Scale: 100, Unit: "%"},
		{Key: "counted_actions", Label: "Counted actions", Kind: "dimension"},
	}
	writeAnalyticsReport(w, p, "engagement", []analyticsTable{newAnalyticsTable("surfaces", cols, raws)}, map[string]any{
		"active_members": finalizeAnalyticsRow([]analyticsColumn{{Key: "n", Kind: "count"}}, analyticsRaw{"n": activeMembers})["n"],
		"definition":     "Per surface over the range: members with at least one counted action, their share of members active in the range, their member-days as a share of all active member-days, actions per member, and members who came back to it on a second day.",
	})
}

// ── Liquidity by city ────────────────────────────────────────────────────────

// GET /v1/admin/analytics/liquidity
func (s *Server) adminAnalyticsLiquidity(w http.ResponseWriter, r *http.Request) {
	db, p, ok := s.analyticsRequest(w, r, 7)
	if !ok {
		return
	}
	// Gender is the breakdown here, so a gender filter would empty the ratio.
	memberSQL, memberArgs := p.Seg.memberSQL("m", "$2::date", 3, "gender")
	rows, err := db.QueryContext(r.Context(), `
		SELECT m.city, COUNT(*),
		       COUNT(*) FILTER (WHERE m.gender = 'female'), COUNT(*) FILTER (WHERE m.gender = 'male'),
		       COUNT(*) FILTER (WHERE m.gender NOT IN ('female', 'male'))
		  FROM analytics.reportable_members m
		 WHERE EXISTS (SELECT 1 FROM analytics.member_active_days a
		                WHERE a.user_id = m.user_id AND a.day BETWEEN $1::date AND $2::date)`+memberSQL+`
		 GROUP BY m.city`, append([]any{dayArg(p.From), dayArg(p.To)}, memberArgs...)...)
	if err != nil {
		analyticsQueryFailed(w, err)
		return
	}
	byCity := map[string]analyticsRaw{}
	var order []string
	for rows.Next() {
		var city string
		var active, women, men, other int64
		if err := rows.Scan(&city, &active, &women, &men, &other); err != nil {
			rows.Close()
			analyticsQueryFailed(w, err)
			return
		}
		byCity[city] = analyticsRaw{"city": city, "active_members": active, "women": women, "men": men, "other_or_unknown": other}
		order = append(order, city)
	}
	rows.Close()
	segSQL, segArgs := p.Seg.rollupSQL("d", 3, "gender")
	rows, err = db.QueryContext(r.Context(), `
		SELECT d.city,
		       SUM(d.value) FILTER (WHERE d.metric = 'signups'), SUM(d.value) FILTER (WHERE d.metric = 'matches'),
		       SUM(d.value) FILTER (WHERE d.metric = 'likes'), SUM(d.value) FILTER (WHERE d.metric = 'dates_kept')
		  FROM analytics.daily_metrics d
		 WHERE d.day BETWEEN $1::date AND $2::date AND d.metric IN ('signups', 'matches', 'likes', 'dates_kept')`+segSQL+`
		 GROUP BY d.city`, append([]any{dayArg(p.From), dayArg(p.To)}, segArgs...)...)
	if err != nil {
		analyticsQueryFailed(w, err)
		return
	}
	for rows.Next() {
		var city string
		var signups, matches, likes, kept sql.NullInt64
		if err := rows.Scan(&city, &signups, &matches, &likes, &kept); err != nil {
			rows.Close()
			analyticsQueryFailed(w, err)
			return
		}
		raw := byCity[city]
		if raw == nil {
			raw = analyticsRaw{"city": city, "active_members": int64(0), "women": int64(0), "men": int64(0), "other_or_unknown": int64(0)}
			byCity[city] = raw
			order = append(order, city)
		}
		raw["new_members"], raw["matches"], raw["likes"], raw["dates_kept"] = signups.Int64, matches.Int64, likes.Int64, kept.Int64
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		analyticsQueryFailed(w, err)
		return
	}
	raws := make([]analyticsRaw, 0, len(order))
	for _, city := range order {
		raw := byCity[city]
		for _, k := range []string{"new_members", "matches", "likes", "dates_kept"} {
			if _, ok := raw[k]; !ok {
				raw[k] = int64(0)
			}
		}
		raws = append(raws, raw)
	}
	sortAnalyticsRaws(raws, "active_members")
	cols := []analyticsColumn{
		{Key: "city", Label: "City", Kind: "dimension"},
		{Key: "active_members", Label: "Active members", Kind: "count"},
		{Key: "women", Label: "Women", Kind: "count"},
		{Key: "men", Label: "Men", Kind: "count"},
		{Key: "other_or_unknown", Label: "Other / not stated", Kind: "count"},
		{Key: "women_per_man", Label: "Women per man", Kind: "ratio", Num: "women", Den: "men", Scale: 1},
		{Key: "female_share", Label: "Women share", Kind: "ratio", Num: "women", Den: "active_members", Scale: 100, Unit: "%"},
		{Key: "new_members", Label: "New members", Kind: "count"},
		{Key: "matches", Label: "Match participations", Kind: "count"},
		{Key: "matches_per_active_member", Label: "Match participations per active member", Kind: "ratio", Num: "matches", Den: "active_members", Scale: 1},
		{Key: "likes_per_active_member", Label: "Likes per active member", Kind: "ratio", Num: "likes", Den: "active_members", Scale: 1},
		{Key: "dates_kept", Label: "Dates kept", Kind: "count"},
	}
	writeAnalyticsReport(w, p, "liquidity", []analyticsTable{newAnalyticsTable("cities", cols, raws)}, map[string]any{
		"definition": "Members active at least once in the range by their current city and gender; rollup counts by the city recorded when each day was built. The gender ratio is a coarse density signal and says nothing about who is seeking whom.",
	})
}

func sortAnalyticsRaws(raws []analyticsRaw, key string) {
	for i := 1; i < len(raws); i++ {
		for j := i; j > 0; j-- {
			a, _ := analyticsNumber(raws[j][key])
			b, _ := analyticsNumber(raws[j-1][key])
			if a <= b {
				break
			}
			raws[j], raws[j-1] = raws[j-1], raws[j]
		}
	}
}

// ── Safety health ────────────────────────────────────────────────────────────

var analyticsCaseSurface = map[string]string{
	"post": "blog", "response": "blog", "publication": "blog", "comment": "blog",
	"theme_entry": "themes", "photo_comment": "themes",
	"club": "clubs", "club_post": "clubs", "review": "clubs", "list": "clubs",
	"group": "groups",
}

// GET /v1/admin/analytics/safety
func (s *Server) adminAnalyticsSafety(w http.ResponseWriter, r *http.Request) {
	db, p, ok := s.analyticsRequest(w, r, 28)
	if !ok {
		return
	}
	grain := p.Grain
	if r.URL.Query().Get("grain") == "" {
		grain = "week"
	}
	ctx := r.Context()
	segSQL, segArgs := p.Seg.rollupSQL("d", 4, "")
	rows, err := db.QueryContext(ctx, `
		SELECT date_trunc($3, d.day::timestamp)::date,
		       COALESCE(SUM(d.value) FILTER (WHERE d.metric = 'reports_filed'), 0),
		       COALESCE(SUM(d.value) FILTER (WHERE d.metric = 'blocks'), 0),
		       COALESCE(SUM(d.value) FILTER (WHERE d.metric = 'dau'), 0)
		  FROM analytics.daily_metrics d
		 WHERE d.day BETWEEN $1::date AND $2::date AND d.metric IN ('reports_filed', 'blocks', 'dau')`+segSQL+`
		 GROUP BY 1 ORDER BY 1`, append([]any{dayArg(p.From), dayArg(p.To), grain}, segArgs...)...)
	if err != nil {
		analyticsQueryFailed(w, err)
		return
	}
	var trend []analyticsRaw
	for rows.Next() {
		var period time.Time
		var reports, blocks, dau int64
		if err := rows.Scan(&period, &reports, &blocks, &dau); err != nil {
			rows.Close()
			analyticsQueryFailed(w, err)
			return
		}
		trend = append(trend, analyticsRaw{"period": period.Format(time.DateOnly), "reports_filed": reports, "blocks": blocks, "active_member_days": dau})
	}
	rows.Close()

	// Time to action: every report in the range, whoever filed it, because the
	// queue's service level does not depend on the reporter.
	rows, err = db.QueryContext(ctx, `
		WITH q AS (
		  SELECT 'member_reports' AS queue, created_at, reviewed_at AS acted_at, review_deadline_at AS due_at
		    FROM matching.moderation_reports
		  UNION ALL
		  SELECT 'content_reports', created_at, resolved_at, review_due_at FROM matching.blog_cases
		)
		SELECT date_trunc($3, (q.created_at AT TIME ZONE 'UTC'))::date, q.queue, COUNT(*),
		       COUNT(*) FILTER (WHERE q.acted_at IS NOT NULL),
		       percentile_cont(0.5) WITHIN GROUP (ORDER BY GREATEST(0, EXTRACT(EPOCH FROM q.acted_at - q.created_at)) / 3600) FILTER (WHERE q.acted_at IS NOT NULL),
		       percentile_cont(0.9) WITHIN GROUP (ORDER BY GREATEST(0, EXTRACT(EPOCH FROM q.acted_at - q.created_at)) / 3600) FILTER (WHERE q.acted_at IS NOT NULL),
		       COUNT(*) FILTER (WHERE q.acted_at IS NOT NULL AND q.due_at IS NOT NULL),
		       COUNT(*) FILTER (WHERE q.acted_at IS NOT NULL AND q.due_at IS NOT NULL AND q.acted_at <= q.due_at),
		       COUNT(*) FILTER (WHERE q.acted_at IS NULL AND q.due_at < NOW())
		  FROM q
		 WHERE q.created_at >= ($1::date::timestamp AT TIME ZONE 'UTC') AND q.created_at < (($2::date + 1)::timestamp AT TIME ZONE 'UTC')
		 GROUP BY 1, 2 ORDER BY 1, 2`, dayArg(p.From), dayArg(p.To), grain)
	if err != nil {
		analyticsQueryFailed(w, err)
		return
	}
	var queues []analyticsRaw
	for rows.Next() {
		var period time.Time
		var queue string
		var total, acted, withDue, withinDue, overdue int64
		var median, p90 sql.NullFloat64
		if err := rows.Scan(&period, &queue, &total, &acted, &median, &p90, &withDue, &withinDue, &overdue); err != nil {
			rows.Close()
			analyticsQueryFailed(w, err)
			return
		}
		queues = append(queues, analyticsRaw{"period": period.Format(time.DateOnly), "queue": queue, "reports": total, "actioned": acted,
			"median_hours_to_action": median, "p90_hours_to_action": p90, "actioned_with_deadline": withDue,
			"actioned_within_deadline": withinDue, "open_past_deadline": overdue})
	}
	rows.Close()

	// Reports per 1,000 interactions by surface (the entertainment strategy's
	// guardrail): content cases by the surface their content lives on, member
	// reports against match chat.
	memberSQL, memberArgs := p.Seg.memberSQL("m", "$2::date", 3, "")
	interactions := map[string]int64{}
	rows, err = db.QueryContext(ctx, `
		SELECT s.surface, SUM(s.actions)
		  FROM analytics.member_surface_days s JOIN analytics.reportable_members m ON m.user_id = s.user_id
		 WHERE s.day BETWEEN $1::date AND $2::date`+memberSQL+`
		 GROUP BY 1`, append([]any{dayArg(p.From), dayArg(p.To)}, memberArgs...)...)
	if err != nil {
		analyticsQueryFailed(w, err)
		return
	}
	for rows.Next() {
		var surface string
		var n int64
		if err := rows.Scan(&surface, &n); err != nil {
			rows.Close()
			analyticsQueryFailed(w, err)
			return
		}
		interactions[surface] = n
	}
	rows.Close()
	reportsBySurface := map[string]int64{}
	rows, err = db.QueryContext(ctx, `
		SELECT 'member:' || 'chat', COUNT(*) FROM matching.moderation_reports
		 WHERE created_at >= ($1::date::timestamp AT TIME ZONE 'UTC') AND created_at < (($2::date + 1)::timestamp AT TIME ZONE 'UTC')
		UNION ALL
		SELECT content_type, COUNT(*) FROM matching.blog_cases
		 WHERE created_at >= ($1::date::timestamp AT TIME ZONE 'UTC') AND created_at < (($2::date + 1)::timestamp AT TIME ZONE 'UTC')
		 GROUP BY content_type`, dayArg(p.From), dayArg(p.To))
	if err != nil {
		analyticsQueryFailed(w, err)
		return
	}
	for rows.Next() {
		var kind string
		var n int64
		if err := rows.Scan(&kind, &n); err != nil {
			rows.Close()
			analyticsQueryFailed(w, err)
			return
		}
		surface := analyticsCaseSurface[kind]
		if kind == "member:chat" {
			surface = "chat"
		}
		if surface == "" {
			surface = "other"
		}
		reportsBySurface[surface] += n
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		analyticsQueryFailed(w, err)
		return
	}
	var bySurface []analyticsRaw
	for _, surface := range analyticsSurfaceCatalog {
		if surface.Key == "safety" || surface.Key == "onboarding" {
			continue
		}
		bySurface = append(bySurface, analyticsRaw{"surface": surface.Key, "surface_label": surface.Label,
			"reports": reportsBySurface[surface.Key], "interactions": interactions[surface.Key]})
	}
	trendCols := []analyticsColumn{
		{Key: "period", Label: "Period start", Kind: "dimension"},
		{Key: "reports_filed", Label: "Reports filed", Kind: "count"},
		{Key: "blocks", Label: "Blocks", Kind: "count"},
		{Key: "active_member_days", Label: "Active member-days", Kind: "count"},
		{Key: "reports_per_1k_dau", Label: "Reports per 1,000 DAU", Kind: "ratio", Num: "reports_filed", Den: "active_member_days", Scale: 1000},
		{Key: "blocks_per_1k_dau", Label: "Blocks per 1,000 DAU", Kind: "ratio", Num: "blocks", Den: "active_member_days", Scale: 1000},
	}
	queueCols := []analyticsColumn{
		{Key: "period", Label: "Period start", Kind: "dimension"},
		{Key: "queue", Label: "Queue", Kind: "dimension"},
		{Key: "reports", Label: "Reports", Kind: "count"},
		{Key: "actioned", Label: "Actioned", Kind: "count"},
		{Key: "median_hours_to_action", Label: "Median hours to action", Kind: "median", Support: "actioned", Unit: "hours"},
		{Key: "p90_hours_to_action", Label: "90th percentile hours to action", Kind: "median", Support: "actioned", Unit: "hours"},
		{Key: "within_deadline", Label: "Actioned within deadline", Kind: "ratio", Num: "actioned_within_deadline", Den: "actioned_with_deadline", Scale: 100, Unit: "%"},
		{Key: "open_past_deadline", Label: "Open past deadline now", Kind: "count"},
	}
	surfaceCols := []analyticsColumn{
		{Key: "surface", Label: "Surface", Kind: "dimension"},
		{Key: "surface_label", Label: "Label", Kind: "dimension"},
		{Key: "reports", Label: "Reports", Kind: "count"},
		{Key: "interactions", Label: "Interactions (counted actions)", Kind: "count"},
		{Key: "reports_per_1k_interactions", Label: "Reports per 1,000 interactions", Kind: "ratio", Num: "reports", Den: "interactions", Scale: 1000},
	}
	writeAnalyticsReport(w, p, "safety", []analyticsTable{
		newAnalyticsTable("trend", trendCols, trend),
		newAnalyticsTable("queues", queueCols, queues),
		newAnalyticsTable("by_surface", surfaceCols, bySurface),
	}, map[string]any{
		"grain":      grain,
		"definition": "Reports and blocks are attributed to the member who filed them and follow the segment filters; queue timings cover every report created in the range (member reports: reviewed_at vs review_deadline_at; content reports: resolved_at vs review_due_at).",
	})
}

// ── Definitions, snapshot status, rebuild, test-account flags ────────────────

// GET /v1/admin/analytics/definitions
func (s *Server) adminAnalyticsDefinitions(w http.ResponseWriter, r *http.Request) {
	surfaces := make([]map[string]string, 0, len(analyticsSurfaceCatalog))
	for _, sf := range analyticsSurfaceCatalog {
		surfaces = append(surfaces, map[string]string{"key": sf.Key, "label": sf.Label, "counted_actions": sf.Actions})
	}
	steps := make([]map[string]string, 0, len(analyticsFunnelSteps))
	for _, st := range analyticsFunnelSteps {
		steps = append(steps, map[string]string{"key": st.key, "label": st.label, "column": st.column})
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"success": true, "metrics": analyticsMetricCatalog, "surfaces": surfaces, "funnel_steps": steps,
		"segments": map[string]any{
			"dimensions": analyticsSegmentDims, "values": analyticsSegmentValues,
			"city": "Free text, matched case-insensitively against the member's profile city.",
		},
		"suppression_threshold": analyticsSuppressBelow,
		"exclusions":            []string{"operator_account", "introducer_account", "erased_account", "flagged_test_account", "test_username", "test_email_domain"},
		"schedule":              "Each completed UTC day is built after midnight UTC and rebuilt once after the next midnight, then final.",
		"document":              "documents/PRODUCT_ANALYTICS_REPORTS_2026-10-01.md",
	})
}

// GET /v1/admin/analytics/snapshots
func (s *Server) adminAnalyticsSnapshots(w http.ResponseWriter, r *http.Request) {
	db, err := s.growthDB()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("analytics storage is unavailable"))
		return
	}
	ctx := r.Context()
	var built, final int64
	var first, last sql.NullTime
	if err := db.QueryRowContext(ctx, `SELECT COUNT(*) FILTER (WHERE built_at IS NOT NULL), COUNT(*) FILTER (WHERE final),
		MIN(day) FILTER (WHERE built_at IS NOT NULL), MAX(day) FILTER (WHERE built_at IS NOT NULL) FROM analytics.snapshot_days`).Scan(&built, &final, &first, &last); err != nil {
		analyticsQueryFailed(w, err)
		return
	}
	missing := []string{}
	rows, err := db.QueryContext(ctx, `
		SELECT d::date FROM generate_series((NOW() AT TIME ZONE 'UTC')::date - $1::int, (NOW() AT TIME ZONE 'UTC')::date - 1, INTERVAL '1 day') d
		 WHERE d::date >= (SELECT MIN((created_at AT TIME ZONE 'UTC')::date) FROM user_management.users)
		   AND NOT EXISTS (SELECT 1 FROM analytics.snapshot_days s WHERE s.day = d::date AND s.built_at IS NOT NULL)
		 ORDER BY 1`, analyticsSnapshotWindowDays)
	if err != nil {
		analyticsQueryFailed(w, err)
		return
	}
	for rows.Next() {
		var day time.Time
		if rows.Scan(&day) == nil {
			missing = append(missing, day.Format(time.DateOnly))
		}
	}
	rows.Close()
	runs := []map[string]any{}
	rows, err = db.QueryContext(ctx, `SELECT id::text, kind, from_day, to_day, status, requested_by, days_built, COALESCE(error, ''), started_at, finished_at
		FROM analytics.snapshot_runs ORDER BY started_at DESC LIMIT 20`)
	if err != nil {
		analyticsQueryFailed(w, err)
		return
	}
	for rows.Next() {
		var id, kind, status, by, message string
		var from, to, started time.Time
		var finished sql.NullTime
		var days int
		if err := rows.Scan(&id, &kind, &from, &to, &status, &by, &days, &message, &started, &finished); err != nil {
			rows.Close()
			analyticsQueryFailed(w, err)
			return
		}
		run := map[string]any{"id": id, "kind": kind, "from": from.Format(time.DateOnly), "to": to.Format(time.DateOnly),
			"status": status, "requested_by": by, "days_built": days, "error": message, "started_at": started}
		if finished.Valid {
			run["finished_at"] = finished.Time
		}
		runs = append(runs, run)
	}
	rows.Close()
	exclusions := map[string]int64{}
	rows, err = db.QueryContext(ctx, `SELECT reason, COUNT(*) FROM analytics.member_exclusions GROUP BY reason`)
	if err != nil {
		analyticsQueryFailed(w, err)
		return
	}
	for rows.Next() {
		var reason string
		var n int64
		if rows.Scan(&reason, &n) == nil {
			exclusions[reason] = n
		}
	}
	rows.Close()
	settings := []map[string]string{}
	rows, err = db.QueryContext(ctx, `SELECT key, value, description FROM analytics.report_settings ORDER BY key`)
	if err != nil {
		analyticsQueryFailed(w, err)
		return
	}
	for rows.Next() {
		var key, value, description string
		if rows.Scan(&key, &value, &description) == nil {
			settings = append(settings, map[string]string{"key": key, "value": value, "description": description})
		}
	}
	rows.Close()
	var reportable int64
	_ = db.QueryRowContext(ctx, `SELECT COUNT(*) FROM analytics.reportable_members`).Scan(&reportable)
	out := map[string]any{
		"success": true, "built_days": built, "final_days": final, "missing_days": missing,
		"runs": runs, "exclusions": exclusions, "settings": settings, "reportable_members": reportable,
		"window_days": analyticsSnapshotWindowDays,
	}
	if first.Valid {
		out["first_built_day"] = first.Time.Format(time.DateOnly)
		out["last_built_day"] = last.Time.Format(time.DateOnly)
	}
	writeJSON(w, http.StatusOK, out)
}

func (s *Server) analyticsWorker() *analyticsSnapshotWorker {
	if s.analyticsSnapshotWorker != nil {
		return s.analyticsSnapshotWorker
	}
	db, err := s.growthDB()
	if err != nil {
		return nil
	}
	return newAnalyticsSnapshotWorker(db, s.log, 0)
}

// POST /v1/admin/analytics/snapshots/rebuild {"from":"YYYY-MM-DD","to":"YYYY-MM-DD"}
func (s *Server) adminAnalyticsRebuild(w http.ResponseWriter, r *http.Request) {
	principal, err := requestPrincipal(r)
	if err != nil || !principal.Roles["admin"] {
		writeError(w, http.StatusForbidden, errors.New("only an admin can rebuild analytics snapshots"))
		return
	}
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	from, err := parseAnalyticsDay(toString(payload["from"]))
	if err != nil {
		writeError(w, http.StatusBadRequest, err)
		return
	}
	to, err := parseAnalyticsDay(toString(payload["to"]))
	if err != nil {
		writeError(w, http.StatusBadRequest, err)
		return
	}
	worker := s.analyticsWorker()
	if worker == nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("analytics storage is unavailable"))
		return
	}
	runID, err := worker.StartRebuild(from, to, "operator:"+principal.UserID)
	switch {
	case errors.Is(err, errAnalyticsSnapshotBusy):
		writeError(w, http.StatusConflict, err)
		return
	case err != nil:
		writeError(w, http.StatusBadRequest, err)
		return
	}
	writeJSON(w, http.StatusAccepted, map[string]any{
		"success": true, "run_id": runID, "status": "running",
		"from": dayArg(utcDay(from)), "to": dayArg(utcDay(to)),
		"note": "Track progress at GET /v1/admin/analytics/snapshots. Rebuilt days use today's state of the source tables; join timestamps that move on re-join (rooms, groups) and erased members' content cannot be recovered for old days.",
	})
}

// GET /v1/admin/analytics/excluded-accounts
func (s *Server) adminAnalyticsExcludedAccounts(w http.ResponseWriter, r *http.Request) {
	db, err := s.growthDB()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("analytics storage is unavailable"))
		return
	}
	rows, err := db.QueryContext(r.Context(), `SELECT x.user_id::text, u.username, x.reason, x.created_by, x.created_at
		FROM analytics.excluded_accounts x JOIN user_management.users u ON u.id = x.user_id
		ORDER BY x.created_at DESC LIMIT 500`)
	if err != nil {
		analyticsQueryFailed(w, err)
		return
	}
	defer rows.Close()
	accounts := []map[string]any{}
	for rows.Next() {
		var id, username, reason, by string
		var at time.Time
		if err := rows.Scan(&id, &username, &reason, &by, &at); err != nil {
			analyticsQueryFailed(w, err)
			return
		}
		accounts = append(accounts, map[string]any{"member_id": id, "username": username, "reason": reason, "created_by": by, "created_at": at})
	}
	writeJSON(w, http.StatusOK, map[string]any{"success": true, "accounts": accounts})
}

var analyticsUUID = regexp.MustCompile(`^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$`)

// POST /v1/admin/analytics/excluded-accounts {"member_id":"…","reason":"…"}
func (s *Server) adminAnalyticsExcludeAccount(w http.ResponseWriter, r *http.Request) {
	principal, err := requestPrincipal(r)
	if err != nil || !principal.Roles["admin"] {
		writeError(w, http.StatusForbidden, errors.New("only an admin can flag test accounts"))
		return
	}
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	memberID := strings.TrimSpace(toString(payload["member_id"]))
	reason := strings.TrimSpace(toString(payload["reason"]))
	if !analyticsUUID.MatchString(memberID) || len(reason) < 3 || len(reason) > 200 {
		writeError(w, http.StatusBadRequest, errors.New("provide member_id and a reason of 3 to 200 characters"))
		return
	}
	db, err := s.growthDB()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("analytics storage is unavailable"))
		return
	}
	res, err := db.ExecContext(r.Context(), `INSERT INTO analytics.excluded_accounts(user_id, reason, created_by)
		SELECT u.id, $2, $3 FROM user_management.users u WHERE u.id = $1::uuid
		ON CONFLICT (user_id) DO UPDATE SET reason = EXCLUDED.reason, created_by = EXCLUDED.created_by, created_at = NOW()`,
		memberID, reason, "operator:"+principal.UserID)
	if err != nil {
		analyticsQueryFailed(w, err)
		return
	}
	if n, _ := res.RowsAffected(); n == 0 {
		writeError(w, http.StatusNotFound, errors.New("member not found"))
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"success": true, "member_id": memberID,
		"note": "Member-level reports exclude the account immediately; rebuild past days for the daily rollups."})
}

// DELETE /v1/admin/analytics/excluded-accounts/{memberID}
func (s *Server) adminAnalyticsIncludeAccount(w http.ResponseWriter, r *http.Request) {
	principal, err := requestPrincipal(r)
	if err != nil || !principal.Roles["admin"] {
		writeError(w, http.StatusForbidden, errors.New("only an admin can change test account flags"))
		return
	}
	memberID := strings.TrimSpace(chi.URLParam(r, "memberID"))
	if !analyticsUUID.MatchString(memberID) {
		writeError(w, http.StatusBadRequest, errors.New("member id must be a UUID"))
		return
	}
	db, err := s.growthDB()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("analytics storage is unavailable"))
		return
	}
	if _, err := db.ExecContext(r.Context(), `DELETE FROM analytics.excluded_accounts WHERE user_id = $1::uuid`, memberID); err != nil {
		analyticsQueryFailed(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"success": true, "member_id": memberID})
}
