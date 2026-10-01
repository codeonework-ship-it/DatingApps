package mobile

// Business development / commercial reports (/v1/admin/business/...).
//
// Every report here obeys the same rules (documents/BUSINESS_REPORTS_2026-10-01.md):
//   - a bounded window (since/until, default the last 30 days) in a reporting
//     time zone (UTC by default, Asia/Kolkata or any IANA zone on request);
//   - aggregation happens in SQL; nothing loads a whole table into memory;
//   - money is stored and computed in minor units and presented per currency.
//     Different currencies are never added together;
//   - live and sandbox data are separated by `mode` (live by default). Local
//     activations (provider "local"/"internal") never count as revenue, and
//     administrative grants and promotions are never revenue or buyers;
//   - member-level counts from 1 to 4 are shown as "<5" and per-member
//     averages over fewer than 5 members are withheld;
//   - every GET report can be exported with format=csv (table=<name>).
//
// Billing is excluded from release 1 (PEN-25), so empty windows are normal:
// reports return zeros and empty lists, never errors, when there is no data.

import (
	"context"
	"database/sql"
	"encoding/csv"
	"errors"
	"fmt"
	"math"
	"net/http"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
)

const (
	businessSmallCount      = 5
	businessMaxWindowDays   = 1100
	businessMaxBuckets      = 400
	businessReleaseNote     = "Billing is excluded from release 1 (PEN-25). Zero live revenue is expected until billing ships; sandbox rows come from QA and are reported only in sandbox mode."
	businessSuppressedLabel = "<5"
)

var (
	businessReadRoles   = []string{"admin", "finance", "ops_admin", "analyst"}
	businessSpendRoles  = []string{"admin", "finance"}
	businessMarketRoles = []string{"admin", "finance", "ops_admin"}
)

// registerBusinessReportRoutes keeps the business surface in one place so the
// shared router only carries a single line for it.
func (s *Server) registerBusinessReportRoutes(v1 chi.Router) {
	v1.Get("/admin/business/revenue", s.adminBusinessRevenue)
	v1.Get("/admin/business/subscriptions", s.adminBusinessSubscriptions)
	v1.Get("/admin/business/conversion", s.adminBusinessConversion)
	v1.Get("/admin/business/funnel", s.adminBusinessFunnel)
	v1.Get("/admin/business/coins", s.adminBusinessCoins)
	v1.Get("/admin/business/referrals", s.adminBusinessReferrals)
	v1.Get("/admin/business/markets", s.adminBusinessMarkets)
	v1.Post("/admin/business/markets", s.adminBusinessSaveMarket)
	v1.Get("/admin/business/investor-pack", s.adminBusinessInvestorPack)
	v1.Get("/admin/business/marketing-spend", s.adminBusinessListSpend)
	v1.Post("/admin/business/marketing-spend", s.adminBusinessCreateSpend)
	v1.Put("/admin/business/marketing-spend/{spendID}", s.adminBusinessUpdateSpend)
	v1.Delete("/admin/business/marketing-spend/{spendID}", s.adminBusinessDeleteSpend)
}

// ── parameters ───────────────────────────────────────────────────────────────

type businessParams struct {
	Since  time.Time
	Until  time.Time
	TZ     string
	Loc    *time.Location
	Mode   string
	Bucket string
	Format string
	Table  string
	// AnalyticsExclusions is set when analytics.member_exclusions exists.
	AnalyticsExclusions bool
}

func (p businessParams) modes() []string {
	switch p.Mode {
	case "sandbox":
		return []string{"sandbox"}
	case "all":
		return []string{"live", "sandbox"}
	}
	return []string{"live"}
}

func (p businessParams) window() map[string]any {
	return map[string]any{
		"since":    p.Since.UTC().Format(time.RFC3339),
		"until":    p.Until.UTC().Format(time.RFC3339),
		"timezone": p.TZ,
		"bucket":   p.Bucket,
		"note":     "since is inclusive, until is exclusive; buckets are calendar days/ISO weeks/months in the reporting time zone",
	}
}

type businessDefaults struct {
	Days   int // rolling window ending at the start of tomorrow (reporting tz)
	Months int // month-aligned window ending at the start of next month
	Bucket string
}

func parseBusinessParams(r *http.Request, def businessDefaults) (businessParams, error) {
	q := r.URL.Query()
	p := businessParams{TZ: "UTC", Mode: "live", Bucket: def.Bucket}
	if tz := strings.TrimSpace(q.Get("tz")); tz != "" {
		if len(tz) > 64 {
			return p, errors.New("tz is not a valid IANA time zone")
		}
		p.TZ = tz
	}
	loc, err := time.LoadLocation(p.TZ)
	if err != nil || p.TZ == "Local" {
		return p, errors.New("tz is not a valid IANA time zone (for example UTC or Asia/Kolkata)")
	}
	p.Loc = loc
	switch mode := strings.ToLower(strings.TrimSpace(q.Get("mode"))); mode {
	case "", "live":
		p.Mode = "live"
	case "sandbox", "all":
		p.Mode = mode
	default:
		return p, errors.New("mode must be live, sandbox or all")
	}
	if bucket := strings.ToLower(strings.TrimSpace(q.Get("bucket"))); bucket != "" {
		if bucket != "day" && bucket != "week" && bucket != "month" {
			return p, errors.New("bucket must be day, week or month")
		}
		p.Bucket = bucket
	}
	if p.Bucket == "" {
		p.Bucket = "day"
	}
	p.Format = strings.ToLower(strings.TrimSpace(q.Get("format")))
	if p.Format != "" && p.Format != "json" && p.Format != "csv" {
		return p, errors.New("format must be json or csv")
	}
	p.Table = strings.TrimSpace(q.Get("table"))

	now := time.Now().In(loc)
	if def.Months > 0 {
		p.Until = time.Date(now.Year(), now.Month()+1, 1, 0, 0, 0, 0, loc)
		p.Since = p.Until.AddDate(0, -def.Months, 0)
	} else {
		days := def.Days
		if days <= 0 {
			days = 30
		}
		p.Until = time.Date(now.Year(), now.Month(), now.Day()+1, 0, 0, 0, 0, loc)
		p.Since = p.Until.AddDate(0, 0, -days)
	}
	if raw := strings.TrimSpace(q.Get("since")); raw != "" {
		t, err := parseBusinessTime(raw, loc, false)
		if err != nil {
			return p, errors.New("since must be RFC3339 or YYYY-MM-DD")
		}
		p.Since = t
	}
	if raw := strings.TrimSpace(q.Get("until")); raw != "" {
		t, err := parseBusinessTime(raw, loc, true)
		if err != nil {
			return p, errors.New("until must be RFC3339 or YYYY-MM-DD")
		}
		p.Until = t
	}
	if !p.Since.Before(p.Until) {
		return p, errors.New("since must be before until")
	}
	if p.Until.Sub(p.Since) > businessMaxWindowDays*24*time.Hour {
		return p, fmt.Errorf("window is limited to %d days", businessMaxWindowDays)
	}
	if n := len(businessBucketLabels(p)); n > businessMaxBuckets {
		return p, fmt.Errorf("window has %d %s buckets; choose a coarser bucket (limit %d)", n, p.Bucket, businessMaxBuckets)
	}
	return p, nil
}

// parseBusinessTime accepts RFC3339 or a calendar date in the reporting zone.
// A date given as `until` is inclusive, so it means the start of the next day.
func parseBusinessTime(raw string, loc *time.Location, inclusiveDate bool) (time.Time, error) {
	if t, err := time.Parse(time.RFC3339, raw); err == nil {
		return t, nil
	}
	t, err := time.ParseInLocation("2006-01-02", raw, loc)
	if err != nil {
		return time.Time{}, err
	}
	if inclusiveDate {
		t = t.AddDate(0, 0, 1)
	}
	return t, nil
}

func businessBucketStart(t time.Time, bucket string, loc *time.Location) time.Time {
	t = t.In(loc)
	switch bucket {
	case "month":
		return time.Date(t.Year(), t.Month(), 1, 0, 0, 0, 0, loc)
	case "week":
		day := time.Date(t.Year(), t.Month(), t.Day(), 0, 0, 0, 0, loc)
		offset := (int(day.Weekday()) + 6) % 7 // Monday = 0, like date_trunc('week')
		return day.AddDate(0, 0, -offset)
	}
	return time.Date(t.Year(), t.Month(), t.Day(), 0, 0, 0, 0, loc)
}

func businessBucketNext(t time.Time, bucket string) time.Time {
	switch bucket {
	case "month":
		return t.AddDate(0, 1, 0)
	case "week":
		return t.AddDate(0, 0, 7)
	}
	return t.AddDate(0, 0, 1)
}

// businessBucketLabels lists every bucket in the window so empty periods
// appear as zeros rather than gaps.
func businessBucketLabels(p businessParams) []string {
	labels := []string{}
	for t := businessBucketStart(p.Since, p.Bucket, p.Loc); t.Before(p.Until); t = businessBucketNext(t, p.Bucket) {
		labels = append(labels, t.Format("2006-01-02"))
		if len(labels) > businessMaxBuckets+1 {
			break
		}
	}
	return labels
}

// businessBoundaries are the snapshot instants for point-in-time metrics
// (MRR, subscribers): the window start, every bucket start inside the window,
// and the window end. Instants after now are dropped (and the end clamped to
// now) so a window that runs into the future never shows paid-up periods
// "churning" before they have had a chance to renew.
func businessBoundaries(p businessParams) ([]time.Time, []string) {
	now := time.Now()
	times := []time.Time{p.Since}
	labels := []string{businessBucketStart(p.Since, p.Bucket, p.Loc).Format("2006-01-02")}
	for t := businessBucketNext(businessBucketStart(p.Since, p.Bucket, p.Loc), p.Bucket); t.Before(p.Until) && !t.After(now); t = businessBucketNext(t, p.Bucket) {
		times = append(times, t)
		labels = append(labels, t.Format("2006-01-02"))
	}
	end := p.Until
	if end.After(now) {
		end = now
	}
	if end.After(times[len(times)-1]) {
		times = append(times, end)
		labels = append(labels, end.In(p.Loc).Format("2006-01-02"))
	}
	return times, labels
}

// ── access, persistence and context ─────────────────────────────────────────

func (s *Server) businessDB() (*sql.DB, error) {
	if s.store == nil || s.store.profileRepo == nil || s.store.profileRepo.pg == nil {
		return nil, errors.New("business reports need the Postgres store")
	}
	return s.store.profileRepo.pg, nil
}

func (s *Server) businessContext(r *http.Request) (context.Context, context.CancelFunc) {
	timeout := s.cfg.BFFRequestTimeout()
	if timeout < 20*time.Second {
		timeout = 20 * time.Second
	}
	return context.WithTimeout(r.Context(), timeout)
}

// businessAccess applies the role rule inside the handler as well as in the
// security middleware, so a handler mounted elsewhere cannot leak reports.
func businessAccess(w http.ResponseWriter, r *http.Request, roles []string) (securityPrincipal, bool) {
	principal, _, ok := operatorRoleFor(r, roles...)
	if !ok {
		writeError(w, http.StatusForbidden, fmt.Errorf("this report requires one of the roles: %s", strings.Join(roles, ", ")))
		return principal, false
	}
	return principal, true
}

// businessBegin opens the request's read-only snapshot so every figure in one
// report comes from the same point in time.
func (s *Server) businessBegin(w http.ResponseWriter, r *http.Request, def businessDefaults) (businessParams, *sql.Tx, context.Context, func(), bool) {
	if _, ok := businessAccess(w, r, businessReadRoles); !ok {
		return businessParams{}, nil, nil, nil, false
	}
	p, err := parseBusinessParams(r, def)
	if err != nil {
		writeError(w, http.StatusBadRequest, err)
		return p, nil, nil, nil, false
	}
	db, err := s.businessDB()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return p, nil, nil, nil, false
	}
	ctx, cancel := s.businessContext(r)
	tx, err := db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelRepeatableRead, ReadOnly: true})
	if err != nil {
		cancel()
		writeError(w, http.StatusServiceUnavailable, errors.New("report snapshot unavailable"))
		return p, nil, nil, nil, false
	}
	done := func() {
		_ = tx.Rollback()
		cancel()
	}
	_ = tx.QueryRowContext(ctx, `SELECT to_regclass('analytics.member_exclusions') IS NOT NULL`).Scan(&p.AnalyticsExclusions)
	return p, tx, ctx, done, true
}

type businessQueryer interface {
	QueryContext(ctx context.Context, query string, args ...any) (*sql.Rows, error)
	QueryRowContext(ctx context.Context, query string, args ...any) *sql.Row
}

// stripeTestMode reports whether the configured Stripe key is a test key, in
// which case every "stripe" row in this environment is test money.
func (s *Server) stripeTestMode() bool {
	key := strings.TrimSpace(s.cfg.StripeSecretKey)
	return strings.HasPrefix(key, "sk_test_") || strings.HasPrefix(key, "rk_test_")
}

// businessModeExpr classifies a payments, checkout or wallet row as live,
// sandbox or local. Local rows ("local" activations, "internal" and "promo"
// wallet credits) moved no money.
func businessModeExpr(alias string, stripeTest bool) string {
	st := "FALSE"
	if stripeTest {
		st = "TRUE"
	}
	return fmt.Sprintf(`(CASE WHEN %[1]s.provider IN ('local','internal','promo') THEN 'local'
		WHEN %[1]s.provider='sandbox' OR (%[1]s.provider='stripe' AND %[2]s) OR COALESCE(%[1]s.metadata->>'livemode','')='false' THEN 'sandbox'
		ELSE 'live' END)`, alias, st)
}

// memberFilter selects real dating members: not operators, not introducer
// accounts, not erased, and — when product analytics (migration 123) is
// installed — not test accounts flagged by its exclusion rules, so member
// counts agree with the analytics reports.
func (p businessParams) memberFilter(alias string) string {
	base := fmt.Sprintf(`%[1]s.account_kind='dating' AND %[1]s.erased_at IS NULL
		AND NOT EXISTS (SELECT 1 FROM user_management.auth_account_roles rr WHERE rr.user_id=%[1]s.id AND rr.role<>'user')`, alias)
	if p.AnalyticsExclusions {
		base += fmt.Sprintf(` AND NOT EXISTS (SELECT 1 FROM analytics.member_exclusions ex WHERE ex.user_id=%s.id)`, alias)
	}
	return base
}

// businessNetExpr is the net contribution of one payment row, identical to
// the reconciliation report: settled money minus refunds; disputed money is
// held and chargebacks are lost, so neither is net revenue.
func businessNetExpr(alias string) string {
	return fmt.Sprintf(`(CASE %[1]s.status WHEN 'success' THEN %[1]s.amount_paise WHEN 'partially_refunded' THEN %[1]s.amount_paise-%[1]s.refunded_amount_paise ELSE 0 END)`, alias)
}

const businessChargedStatuses = `('success','partially_refunded','refunded','disputed','chargeback')`

// ── suppression and money presentation ──────────────────────────────────────

// suppressCount hides member-level counts from 1 to 4.
func suppressCount(n int64) any {
	if n > 0 && n < businessSmallCount {
		return businessSuppressedLabel
	}
	return n
}

func businessRatio(num, den float64) any {
	if den <= 0 || math.IsNaN(num) {
		return nil
	}
	return math.Round(num/den*10000) / 10000
}

// perMember withholds an average over fewer than five members.
func perMember(amount, members int64) any {
	if members < businessSmallCount {
		return nil
	}
	return int64(math.Round(float64(amount) / float64(members)))
}

var zeroDecimalCurrencies = map[string]bool{"JPY": true, "KRW": true, "VND": true, "CLP": true, "ISK": true, "UGX": true}

// majorUnits renders minor units as a decimal string in the currency's
// precision; it never converts between currencies.
func majorUnits(minor int64, currency string) string {
	if zeroDecimalCurrencies[strings.ToUpper(currency)] {
		return strconv.FormatInt(minor, 10)
	}
	sign := ""
	if minor < 0 {
		sign = "-"
		minor = -minor
	}
	return fmt.Sprintf("%s%d.%02d", sign, minor/100, minor%100)
}

func majorUnitsAny(minor any, currency string) any {
	switch v := minor.(type) {
	case int64:
		return majorUnits(v, currency)
	case int:
		return majorUnits(int64(v), currency)
	}
	return nil
}

func currencyMarket(currency string) string {
	switch strings.ToUpper(currency) {
	case "INR":
		return "India"
	case "GBP":
		return "United Kingdom"
	case "EUR":
		return "Eurozone"
	case "PLN":
		return "Poland"
	case "CHF":
		return "Switzerland"
	case "USD":
		return "United States"
	case "":
		return "Unknown"
	}
	return strings.ToUpper(currency)
}

// moneyTotals accumulates payment rows with reconciliation semantics.
type moneyTotals struct {
	Payments, Settled, Failed, Pending     int64
	RefundCount, ChargebackCount, Disputes int64
	Gross, Refunded, Chargeback, Disputed  int64
	Net                                    int64
}

func (m *moneyTotals) add(status string, count, amount, refunded int64) {
	m.Payments += count
	switch status {
	case "success":
		m.Gross += amount
		m.Net += amount
		m.Settled += count
	case "partially_refunded":
		m.Gross += amount
		m.Refunded += refunded
		m.Net += amount - refunded
		m.Settled += count
		m.RefundCount += count
	case "refunded":
		m.Gross += amount
		m.Refunded += amount
		m.Settled += count
		m.RefundCount += count
	case "disputed":
		m.Gross += amount
		m.Disputed += amount
		m.Settled += count
		m.Disputes += count
	case "chargeback":
		m.Gross += amount
		m.Chargeback += amount
		m.Settled += count
		m.ChargebackCount += count
	case "failed":
		m.Failed += count
	default:
		m.Pending += count
	}
}

func (m moneyTotals) fields(currency string) map[string]any {
	return map[string]any{
		"currency":               currency,
		"market":                 currencyMarket(currency),
		"gross_minor":            m.Gross,
		"gross":                  majorUnits(m.Gross, currency),
		"refunded_minor":         m.Refunded,
		"refunded":               majorUnits(m.Refunded, currency),
		"chargeback_minor":       m.Chargeback,
		"chargeback":             majorUnits(m.Chargeback, currency),
		"disputed_minor":         m.Disputed,
		"disputed":               majorUnits(m.Disputed, currency),
		"net_minor":              m.Net,
		"net":                    majorUnits(m.Net, currency),
		"payments":               m.Payments,
		"settled_payments":       m.Settled,
		"failed_payments":        m.Failed,
		"pending_payments":       m.Pending,
		"refund_rate":            businessRatio(float64(m.Refunded), float64(m.Gross)),
		"refund_count_rate":      businessRatio(float64(m.RefundCount), float64(m.Settled)),
		"chargeback_rate":        businessRatio(float64(m.ChargebackCount), float64(m.Settled)),
		"chargeback_amount_rate": businessRatio(float64(m.Chargeback), float64(m.Gross)),
	}
}

// ── data status (empty states, live vs sandbox) ─────────────────────────────

func (s *Server) businessDataStatus(ctx context.Context, q businessQueryer, p businessParams) map[string]any {
	counts := map[string]int64{"live": 0, "sandbox": 0, "local": 0}
	rows, err := q.QueryContext(ctx, `SELECT `+businessModeExpr("p", s.stripeTestMode())+` AS mode, COUNT(*)
		FROM matching.billing_payments_runtime p WHERE p.created_at >= $1 AND p.created_at < $2 GROUP BY 1`, p.Since, p.Until)
	if err == nil {
		for rows.Next() {
			var mode string
			var n int64
			if rows.Scan(&mode, &n) == nil {
				counts[mode] = n
			}
		}
		rows.Close()
	}
	flag := false
	_ = q.QueryRowContext(ctx, `SELECT COALESCE((SELECT value_bool FROM matching.platform_feature_flags WHERE key='billing_enabled'),FALSE)`).Scan(&flag)
	provider := strings.TrimSpace(s.cfg.PaymentsProvider)
	selected := int64(0)
	for _, m := range p.modes() {
		selected += counts[m]
	}
	status := map[string]any{
		"billing_flag_enabled":       flag,
		"payments_provider":          provider,
		"payment_mode":               billingPaymentMode(provider, s.cfg.StripeSecretKey),
		"stripe_test_keys":           s.stripeTestMode(),
		"release_1_billing_excluded": true,
		"release_note":               businessReleaseNote,
		"live_payments_in_window":    counts["live"],
		"sandbox_payments_in_window": counts["sandbox"],
		"local_payments_in_window":   counts["local"],
		"selected_payments":          selected,
		"empty":                      selected == 0,
	}
	if p.Mode == "live" && counts["sandbox"] > 0 {
		status["sandbox_hint"] = "Sandbox payments exist in this window; switch mode to sandbox to inspect them. They are not revenue."
	}
	return status
}

func businessEnvelope(report string, p businessParams) map[string]any {
	return map[string]any{
		"report": report,
		"window": p.window(),
		"mode":   p.Mode,
		"suppression": map[string]any{
			"threshold": businessSmallCount,
			"rule":      "member-level counts from 1 to 4 are shown as \"<5\"; per-member averages over fewer than 5 members are null",
		},
	}
}

// ── CSV export ──────────────────────────────────────────────────────────────

type businessTable struct {
	Name    string
	Columns []string
	Rows    [][]any
}

func businessTableNames(tables []businessTable) []string {
	out := make([]string, 0, len(tables))
	for _, t := range tables {
		out = append(out, t.Name)
	}
	return out
}

func csvCell(v any) string {
	switch x := v.(type) {
	case nil:
		return ""
	case string:
		// Neutralise spreadsheet formulas in operator- or member-entered text.
		if x != "" && strings.ContainsAny(x[:1], "=+-@\t\r") {
			return "'" + x
		}
		return x
	case int:
		return strconv.Itoa(x)
	case int64:
		return strconv.FormatInt(x, 10)
	case float64:
		return strconv.FormatFloat(x, 'f', -1, 64)
	case bool:
		return strconv.FormatBool(x)
	}
	return fmt.Sprint(v)
}

// writeBusinessReport writes JSON, or the requested table as CSV.
func writeBusinessReport(w http.ResponseWriter, p businessParams, payload map[string]any, tables []businessTable) {
	payload["tables"] = businessTableNames(tables)
	if p.Format != "csv" {
		writeJSON(w, http.StatusOK, payload)
		return
	}
	if len(tables) == 0 {
		writeError(w, http.StatusBadRequest, errors.New("this report has no CSV table"))
		return
	}
	table := tables[0]
	if p.Table != "" {
		found := false
		for _, t := range tables {
			if t.Name == p.Table {
				table, found = t, true
				break
			}
		}
		if !found {
			writeError(w, http.StatusBadRequest, fmt.Errorf("table must be one of: %s", strings.Join(businessTableNames(tables), ", ")))
			return
		}
	}
	report, _ := payload["report"].(string)
	filename := fmt.Sprintf("business-%s-%s-%s-%s-%s.csv", report, table.Name, p.Mode,
		p.Since.In(p.Loc).Format("20060102"), p.Until.In(p.Loc).Format("20060102"))
	w.Header().Set("Content-Type", "text/csv; charset=utf-8")
	w.Header().Set("Content-Disposition", `attachment; filename="`+filename+`"`)
	w.Header().Set("Cache-Control", "no-store")
	w.WriteHeader(http.StatusOK)
	cw := csv.NewWriter(w)
	_ = cw.Write(table.Columns)
	for _, row := range table.Rows {
		record := make([]string, len(row))
		for i, v := range row {
			record[i] = csvCell(v)
		}
		_ = cw.Write(record)
	}
	cw.Flush()
}

// ── active members (ARPU denominators) ──────────────────────────────────────

// businessActiveMembers counts members active in [since, until). It prefers
// the product analytics daily snapshots (analytics.member_active_days) when
// every day of the window has been built. Otherwise it falls back to
// platform.member_last_activity, which keeps only first and last activity per
// member: exact for a window ending now, and an upper bound (activity span
// overlaps the window) for a historical window.
func businessActiveMembers(ctx context.Context, q businessQueryer, p businessParams, since, until time.Time) (int64, string) {
	if v, ok := analyticsSnapshotActives(ctx, q, since, until); ok {
		return v, "analytics daily snapshots (analytics.member_active_days)"
	}
	var n int64
	if err := q.QueryRowContext(ctx, `
		SELECT COUNT(*) FROM platform.member_last_activity a
		JOIN user_management.users u ON u.id=a.user_id
		WHERE a.last_active_at >= $1 AND a.first_active_at < $2 AND `+p.memberFilter("u"), since, until).Scan(&n); err != nil {
		return 0, "unavailable"
	}
	if time.Since(until) < 36*time.Hour {
		return n, "member_last_activity (members active since the window start)"
	}
	return n, "member_last_activity span overlap (upper bound; historical actives need analytics snapshots)"
}

// analyticsSnapshotActives reads distinct active members from the product
// analytics snapshots (migration 123) when that report is installed and has
// built every UTC day in the window. Days are UTC dates of since/until.
func analyticsSnapshotActives(ctx context.Context, q businessQueryer, since, until time.Time) (int64, bool) {
	var installed bool
	if err := q.QueryRowContext(ctx, `SELECT to_regclass('analytics.member_active_days') IS NOT NULL AND to_regclass('analytics.snapshot_days') IS NOT NULL AND to_regclass('analytics.member_exclusions') IS NOT NULL`).Scan(&installed); err != nil || !installed {
		return 0, false
	}
	start := since.UTC().Truncate(24 * time.Hour)
	end := until.UTC().Truncate(24 * time.Hour)
	if !end.After(start) {
		return 0, false
	}
	var complete bool
	var n int64
	if err := q.QueryRowContext(ctx, `
		SELECT (SELECT COUNT(*) FROM analytics.snapshot_days d WHERE d.day >= $1::date AND d.day < $2::date AND d.built_at IS NOT NULL) = ($2::date - $1::date),
		       (SELECT COUNT(DISTINCT a.user_id) FROM analytics.member_active_days a
		        WHERE a.day >= $1::date AND a.day < $2::date
		          AND NOT EXISTS (SELECT 1 FROM analytics.member_exclusions e WHERE e.user_id=a.user_id))`,
		start.Format("2006-01-02"), end.Format("2006-01-02")).Scan(&complete, &n); err != nil || !complete {
		return 0, false
	}
	return n, true
}

// ── revenue ─────────────────────────────────────────────────────────────────

type revenueRow struct {
	Bucket, Currency, ProductType, ProductCode, Mode, Status string
	Count, Amount, Refunded                                  int64
}

func (s *Server) queryRevenueRows(ctx context.Context, q businessQueryer, p businessParams) ([]revenueRow, error) {
	rows, err := q.QueryContext(ctx, `
		WITH pay AS (
		  SELECT p.currency, p.status, p.amount_paise, p.refunded_amount_paise,
		         to_char(date_trunc($3, p.created_at AT TIME ZONE $4), 'YYYY-MM-DD') AS bucket,
		         CASE WHEN p.billing_reason='coin_purchase' OR c.kind='coin_package' THEN 'coin_package'
		              WHEN p.subscription_id IS NOT NULL OR p.billing_reason LIKE 'subscription%' THEN 'subscription'
		              ELSE 'other' END AS product_type,
		         COALESCE(CASE WHEN p.billing_reason='coin_purchase' OR c.kind='coin_package' THEN c.package_id
		                       ELSE COALESCE(s.plan_code, p.metadata->>'plan_code') || COALESCE(':'||s.billing_cycle,'') END,'unknown') AS product_code,
		         `+businessModeExpr("p", s.stripeTestMode())+` AS mode
		  FROM matching.billing_payments_runtime p
		  LEFT JOIN matching.billing_subscriptions_runtime s ON s.id=p.subscription_id
		  LEFT JOIN matching.billing_checkout_sessions c ON c.id=p.checkout_id
		  WHERE p.created_at >= $1 AND p.created_at < $2
		)
		SELECT bucket, currency, product_type, product_code, mode, status,
		       COUNT(*), COALESCE(SUM(amount_paise),0), COALESCE(SUM(refunded_amount_paise),0)
		FROM pay GROUP BY 1,2,3,4,5,6 ORDER BY 1,2,3,4,5,6`, p.Since, p.Until, p.Bucket, p.TZ)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []revenueRow{}
	for rows.Next() {
		var row revenueRow
		if err := rows.Scan(&row.Bucket, &row.Currency, &row.ProductType, &row.ProductCode, &row.Mode, &row.Status, &row.Count, &row.Amount, &row.Refunded); err != nil {
			return nil, err
		}
		out = append(out, row)
	}
	return out, rows.Err()
}

// revenueTotalsByCurrency is the single definition of windowed revenue used
// by the business report, the corrected billing analytics and billing stats.
func (s *Server) revenueTotalsByCurrency(ctx context.Context, q businessQueryer, p businessParams) (map[string]*moneyTotals, map[string]*moneyTotals, []revenueRow, error) {
	rows, err := s.queryRevenueRows(ctx, q, p)
	if err != nil {
		return nil, nil, nil, err
	}
	selected := map[string]bool{}
	for _, m := range p.modes() {
		selected[m] = true
	}
	totals := map[string]*moneyTotals{}
	local := map[string]*moneyTotals{}
	for _, row := range rows {
		target := totals
		if row.Mode == "local" {
			target = local
		} else if !selected[row.Mode] {
			continue
		}
		if target[row.Currency] == nil {
			target[row.Currency] = &moneyTotals{}
		}
		target[row.Currency].add(row.Status, row.Count, row.Amount, row.Refunded)
	}
	return totals, local, rows, nil
}

type payerCount struct {
	Payers, Charged int64
}

func (s *Server) payingMembers(ctx context.Context, q businessQueryer, p businessParams, since, until time.Time) (map[string]payerCount, error) {
	rows, err := q.QueryContext(ctx, `
		SELECT p.currency,
		       COUNT(DISTINCT p.user_id) FILTER (WHERE p.status IN ('success','partially_refunded')),
		       COUNT(DISTINCT p.user_id) FILTER (WHERE p.status IN `+businessChargedStatuses+`)
		FROM matching.billing_payments_runtime p
		WHERE p.created_at >= $1 AND p.created_at < $2 AND `+businessModeExpr("p", s.stripeTestMode())+` = ANY($3)
		GROUP BY p.currency`, since, until, p.modes())
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := map[string]payerCount{}
	for rows.Next() {
		var currency string
		var c payerCount
		if err := rows.Scan(&currency, &c.Payers, &c.Charged); err != nil {
			return nil, err
		}
		out[currency] = c
	}
	return out, rows.Err()
}

func sortedKeys[T any](m map[string]T) []string {
	keys := make([]string, 0, len(m))
	for k := range m {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	return keys
}

func (s *Server) adminBusinessRevenue(w http.ResponseWriter, r *http.Request) {
	p, tx, ctx, done, ok := s.businessBegin(w, r, businessDefaults{Days: 30, Bucket: "day"})
	if !ok {
		return
	}
	defer done()
	totals, local, rows, err := s.revenueTotalsByCurrency(ctx, tx, p)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	payers, err := s.payingMembers(ctx, tx, p, p.Since, p.Until)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	active, activeSource := businessActiveMembers(ctx, tx, p, p.Since, p.Until)
	selected := map[string]bool{}
	for _, m := range p.modes() {
		selected[m] = true
	}

	totalRows := []map[string]any{}
	totalsTable := businessTable{Name: "totals", Columns: []string{"currency", "market", "gross", "refunded", "chargeback", "disputed", "net", "payments", "settled_payments", "failed_payments", "paying_members", "arppu", "arpu", "refund_rate", "chargeback_rate"}}
	for _, currency := range sortedKeys(totals) {
		m := totals[currency]
		f := m.fields(currency)
		pc := payers[currency]
		f["paying_members"] = suppressCount(pc.Payers)
		f["charged_members"] = suppressCount(pc.Charged)
		arppu := perMember(m.Net, pc.Payers)
		arpu := perMember(m.Net, active)
		f["arppu_minor"], f["arppu"] = arppu, majorUnitsAny(arppu, currency)
		f["arpu_minor"], f["arpu"] = arpu, majorUnitsAny(arpu, currency)
		totalRows = append(totalRows, f)
		totalsTable.Rows = append(totalsTable.Rows, []any{currency, currencyMarket(currency), f["gross"], f["refunded"], f["chargeback"], f["disputed"], f["net"], m.Payments, m.Settled, m.Failed, f["paying_members"], f["arppu"], f["arpu"], f["refund_rate"], f["chargeback_rate"]})
	}

	// Trend: bucket × currency, split by product type.
	type trendKey struct{ bucket, currency string }
	trendTotals := map[trendKey]*moneyTotals{}
	productNet := map[trendKey]map[string]int64{}
	byProduct := map[string]*moneyTotals{}
	productMeta := map[string][3]string{}
	currencies := map[string]bool{}
	for _, row := range rows {
		if !selected[row.Mode] {
			continue
		}
		currencies[row.Currency] = true
		k := trendKey{row.Bucket, row.Currency}
		if trendTotals[k] == nil {
			trendTotals[k] = &moneyTotals{}
			productNet[k] = map[string]int64{}
		}
		trendTotals[k].add(row.Status, row.Count, row.Amount, row.Refunded)
		var single moneyTotals
		single.add(row.Status, row.Count, row.Amount, row.Refunded)
		productNet[k][row.ProductType] += single.Net
		pk := row.Currency + "|" + row.ProductType + "|" + row.ProductCode
		if byProduct[pk] == nil {
			byProduct[pk] = &moneyTotals{}
			productMeta[pk] = [3]string{row.Currency, row.ProductType, row.ProductCode}
		}
		byProduct[pk].add(row.Status, row.Count, row.Amount, row.Refunded)
	}
	trend := []map[string]any{}
	trendTable := businessTable{Name: "trend", Columns: []string{"bucket", "currency", "gross", "refunded", "chargeback", "disputed", "net", "subscription_net", "coin_package_net", "other_net", "settled_payments", "refund_rate", "chargeback_rate"}}
	for _, label := range businessBucketLabels(p) {
		for _, currency := range sortedKeys(currencies) {
			k := trendKey{label, currency}
			m := moneyTotals{}
			if trendTotals[k] != nil {
				m = *trendTotals[k]
			}
			pn := productNet[k]
			f := m.fields(currency)
			f["bucket"] = label
			f["subscription_net_minor"] = pn["subscription"]
			f["coin_package_net_minor"] = pn["coin_package"]
			f["other_net_minor"] = pn["other"]
			trend = append(trend, f)
			trendTable.Rows = append(trendTable.Rows, []any{label, currency, f["gross"], f["refunded"], f["chargeback"], f["disputed"], f["net"], majorUnits(pn["subscription"], currency), majorUnits(pn["coin_package"], currency), majorUnits(pn["other"], currency), m.Settled, f["refund_rate"], f["chargeback_rate"]})
		}
	}
	products := []map[string]any{}
	productTable := businessTable{Name: "by_product", Columns: []string{"currency", "product_type", "product_code", "payments", "gross", "refunded", "chargeback", "net"}}
	for _, pk := range sortedKeys(byProduct) {
		meta := productMeta[pk]
		m := byProduct[pk]
		f := m.fields(meta[0])
		f["product_type"], f["product_code"] = meta[1], meta[2]
		products = append(products, f)
		productTable.Rows = append(productTable.Rows, []any{meta[0], meta[1], meta[2], m.Payments, f["gross"], f["refunded"], f["chargeback"], f["net"]})
	}

	cities, cityTable, err := s.revenueByCity(ctx, tx, p)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	localRows := []map[string]any{}
	for _, currency := range sortedKeys(local) {
		localRows = append(localRows, map[string]any{"currency": currency, "payments": local[currency].Payments, "amount_minor": local[currency].Gross, "revenue": false})
	}
	var giftCoins, giftSends int64
	_ = tx.QueryRowContext(ctx, `SELECT COALESCE(SUM(total_cost_coins),0), COUNT(*) FROM matching.match_gift_sends WHERE created_at >= $1 AND created_at < $2 AND total_cost_coins > 0`, p.Since, p.Until).Scan(&giftCoins, &giftSends)

	payload := businessEnvelope("revenue", p)
	payload["data_status"] = s.businessDataStatus(ctx, tx, p)
	payload["totals"] = totalRows
	payload["trend"] = trend
	payload["by_product"] = products
	payload["by_city"] = cities
	payload["gifts"] = map[string]any{
		"paid_gift_sends": giftSends,
		"coins_spent":     giftCoins,
		"note":            "Gifts are paid with coins. Money is recognised when coins are bought (product coin_package); gift spend is a coin sink, see the coin economy report.",
	}
	payload["local_activations"] = localRows
	payload["active_members"] = map[string]any{"count": suppressCount(active), "source": activeSource}
	payload["reconciliation"] = map[string]any{"path": "/v1/admin/billing/reconciliation", "note": "Gross and net here equal the reconciliation report for mode=all (live + sandbox) over the same window and currency."}
	payload["definitions"] = map[string]string{
		"gross":           "Charged payments (success, partially_refunded, refunded, disputed, chargeback) by payment created_at, in minor units of the payment currency",
		"net":             "success amount + (partially_refunded amount - refunded amount); disputed (held) and chargeback (lost) money is not net",
		"refund_rate":     "refunded amount / gross amount",
		"chargeback_rate": "chargeback payments / charged payments (processor definition); chargeback_amount_rate is by amount",
		"arppu":           "net / members with a success or partially_refunded payment in the window, per currency",
		"arpu":            "net / active members in the window (see active_members.source)",
	}
	writeBusinessReport(w, p, payload, []businessTable{trendTable, totalsTable, productTable, cityTable})
}

// revenueByCity pools cities with fewer than five paying members so no
// individual's spend can be read off a city row.
func (s *Server) revenueByCity(ctx context.Context, q businessQueryer, p businessParams) ([]map[string]any, businessTable, error) {
	table := businessTable{Name: "by_city", Columns: []string{"city", "currency", "paying_members", "net"}}
	rows, err := q.QueryContext(ctx, `
		SELECT COALESCE(NULLIF(lower(btrim(u.city)),''),'unknown'), p.currency,
		       COUNT(DISTINCT p.user_id) FILTER (WHERE p.status IN ('success','partially_refunded')),
		       COALESCE(SUM(`+businessNetExpr("p")+`),0)
		FROM matching.billing_payments_runtime p
		JOIN user_management.users u ON u.id=p.user_id
		WHERE p.created_at >= $1 AND p.created_at < $2 AND `+businessModeExpr("p", s.stripeTestMode())+` = ANY($3)
		  AND p.status IN `+businessChargedStatuses+`
		GROUP BY 1,2 ORDER BY 4 DESC`, p.Since, p.Until, p.modes())
	if err != nil {
		return nil, table, err
	}
	defer rows.Close()
	out := []map[string]any{}
	pooledPayers := map[string]int64{}
	pooledNet := map[string]int64{}
	for rows.Next() {
		var city, currency string
		var payers, net int64
		if err := rows.Scan(&city, &currency, &payers, &net); err != nil {
			return nil, table, err
		}
		if payers < businessSmallCount {
			pooledPayers[currency] += payers
			pooledNet[currency] += net
			continue
		}
		out = append(out, map[string]any{"city": city, "currency": currency, "paying_members": payers, "net_minor": net, "net": majorUnits(net, currency)})
		table.Rows = append(table.Rows, []any{city, currency, payers, majorUnits(net, currency)})
	}
	for _, currency := range sortedKeys(pooledNet) {
		label := "other cities (each <5 paying members)"
		out = append(out, map[string]any{"city": label, "currency": currency, "paying_members": suppressCount(pooledPayers[currency]), "net_minor": pooledNet[currency], "net": majorUnits(pooledNet[currency], currency), "pooled": true})
		table.Rows = append(table.Rows, []any{label, currency, suppressCount(pooledPayers[currency]), majorUnits(pooledNet[currency], currency)})
	}
	return out, table, rows.Err()
}

// ── corrected legacy billing analytics ──────────────────────────────────────

// coinCreditSummary splits wallet credits into money-backed purchases (by
// mode) and non-revenue credits (grants, promotions, refunds of gifts).
func (s *Server) coinCreditSummary(ctx context.Context, q businessQueryer, p businessParams) ([]map[string]any, map[string]any, int64, error) {
	rows, err := q.QueryContext(ctx, `
		SELECT w.source, `+businessModeExpr("w", s.stripeTestMode())+` AS mode, w.currency,
		       COUNT(*), COALESCE(SUM(w.coins),0), COALESCE(SUM(w.amount_minor),0), COUNT(DISTINCT w.user_id)
		FROM matching.wallet_coin_purchases w
		WHERE w.created_at >= $1 AND w.created_at < $2
		GROUP BY 1,2,3 ORDER BY 1,2,3`, p.Since, p.Until)
	if err != nil {
		return nil, nil, 0, err
	}
	defer rows.Close()
	selected := map[string]bool{}
	for _, m := range p.modes() {
		selected[m] = true
	}
	purchases := []map[string]any{}
	credits := map[string]any{}
	var purchasedCoins int64
	for rows.Next() {
		var source, mode, currency string
		var count, coins, amount, users int64
		if err := rows.Scan(&source, &mode, &currency, &count, &coins, &amount, &users); err != nil {
			return nil, nil, 0, err
		}
		if source == "buy" && mode != "local" {
			if !selected[mode] {
				continue
			}
			purchasedCoins += coins
			purchases = append(purchases, map[string]any{"currency": currency, "mode": mode, "count": count, "coins": coins, "amount_minor": amount, "amount": majorUnits(amount, currency), "buyers": suppressCount(users)})
			continue
		}
		key := source
		if source == "buy" {
			key = "local_buy"
		}
		prev, _ := credits[key].(map[string]any)
		if prev == nil {
			prev = map[string]any{"count": int64(0), "coins": int64(0), "revenue": false}
		}
		prev["count"] = prev["count"].(int64) + count
		prev["coins"] = prev["coins"].(int64) + coins
		credits[key] = prev
	}
	return purchases, credits, purchasedCoins, rows.Err()
}

func (s *Server) legacyBillingParams(w http.ResponseWriter, r *http.Request) (businessParams, *sql.Tx, context.Context, func(), bool) {
	if err := requireAdminUser(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return businessParams{}, nil, nil, nil, false
	}
	p, err := parseBusinessParams(r, businessDefaults{Days: 30, Bucket: "day"})
	if err != nil {
		writeError(w, http.StatusBadRequest, err)
		return p, nil, nil, nil, false
	}
	db, err := s.businessDB()
	if err != nil {
		return p, nil, nil, nil, true
	}
	ctx, cancel := s.businessContext(r)
	tx, err := db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelRepeatableRead, ReadOnly: true})
	if err != nil {
		cancel()
		writeError(w, http.StatusServiceUnavailable, errors.New("report snapshot unavailable"))
		return p, nil, nil, nil, false
	}
	return p, tx, ctx, func() { _ = tx.Rollback(); cancel() }, true
}

// billingRevenueAnalytics backs GET /v1/admin/billing/revenue-analytics with
// the same windowed, mode-separated, currency-aware definitions as the
// business revenue report.
func (s *Server) billingRevenueAnalytics(w http.ResponseWriter, r *http.Request) {
	p, tx, ctx, done, ok := s.legacyBillingParams(w, r)
	if !ok {
		return
	}
	if tx == nil {
		writeJSON(w, http.StatusOK, map[string]any{"window": p.window(), "mode": p.Mode, "revenue": []any{}, "coin_purchases": map[string]any{}, "subscriptions": map[string]any{}, "payments": map[string]any{}, "source": "unavailable"})
		return
	}
	defer done()
	totals, local, rows, err := s.revenueTotalsByCurrency(ctx, tx, p)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	payers, err := s.payingMembers(ctx, tx, p, p.Since, p.Until)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	revenue := []map[string]any{}
	for _, currency := range sortedKeys(totals) {
		f := totals[currency].fields(currency)
		f["paying_members"] = suppressCount(payers[currency].Payers)
		revenue = append(revenue, f)
	}
	selected := map[string]bool{}
	for _, m := range p.modes() {
		selected[m] = true
	}
	byStatus := map[string]map[string]any{}
	var paymentCount int64
	for _, row := range rows {
		if !selected[row.Mode] {
			continue
		}
		paymentCount += row.Count
		k := row.Status + "|" + row.Currency
		if byStatus[k] == nil {
			byStatus[k] = map[string]any{"status": row.Status, "currency": row.Currency, "count": int64(0), "amount_minor": int64(0), "refunded_minor": int64(0)}
		}
		byStatus[k]["count"] = byStatus[k]["count"].(int64) + row.Count
		byStatus[k]["amount_minor"] = byStatus[k]["amount_minor"].(int64) + row.Amount
		byStatus[k]["refunded_minor"] = byStatus[k]["refunded_minor"].(int64) + row.Refunded
	}
	statusRows := []map[string]any{}
	for _, k := range sortedKeys(byStatus) {
		statusRows = append(statusRows, byStatus[k])
	}
	purchases, credits, purchasedCoins, err := s.coinCreditSummary(ctx, tx, p)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	subStatus := map[string]any{}
	subPlan := map[string]any{}
	subRows, err := tx.QueryContext(ctx, `
		SELECT status, plan_code||':'||billing_cycle, COUNT(*) FROM matching.billing_subscriptions_runtime s
		WHERE `+businessModeExpr("s", s.stripeTestMode())+` = ANY($1) GROUP BY 1,2`, p.modes())
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	for subRows.Next() {
		var status, plan string
		var n int64
		if err := subRows.Scan(&status, &plan, &n); err != nil {
			subRows.Close()
			writeError(w, http.StatusBadGateway, err)
			return
		}
		prev, _ := subStatus[status].(int64)
		subStatus[status] = prev + n
		if status == "active" || status == "past_due" {
			prevPlan, _ := subPlan[plan].(int64)
			subPlan[plan] = prevPlan + n
		}
	}
	subRows.Close()
	for k, v := range subStatus {
		subStatus[k] = suppressCount(v.(int64))
	}
	for k, v := range subPlan {
		subPlan[k] = suppressCount(v.(int64))
	}
	var startedInWindow int64
	_ = tx.QueryRowContext(ctx, `SELECT COUNT(*) FROM matching.billing_subscriptions_runtime s WHERE s.start_date >= $1 AND s.start_date < $2 AND `+businessModeExpr("s", s.stripeTestMode())+` = ANY($3)`, p.Since, p.Until, p.modes()).Scan(&startedInWindow)
	localRows := []map[string]any{}
	for _, currency := range sortedKeys(local) {
		localRows = append(localRows, map[string]any{"currency": currency, "payments": local[currency].Payments, "amount_minor": local[currency].Gross, "revenue": false})
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"window":      p.window(),
		"mode":        p.Mode,
		"data_status": s.businessDataStatus(ctx, tx, p),
		"revenue":     revenue,
		"payments":    map[string]any{"total": paymentCount, "by_status": statusRows},
		"coin_purchases": map[string]any{
			"purchases":       purchases,
			"purchased_coins": purchasedCoins,
			"non_revenue":     credits,
			"note":            "Only source=buy credits backed by a provider payment are purchases; admin top-ups, promotions, bootstrap/opening balances and gift refunds are never revenue or buyers.",
		},
		"subscriptions": map[string]any{
			"by_status":         subStatus,
			"active_by_plan":    subPlan,
			"started_in_window": suppressCount(startedInWindow),
			"note":              "by_status is the current state of subscriptions for the selected mode; local activations are excluded.",
		},
		"local_activations": localRows,
		"reconciliation":    "/v1/admin/billing/reconciliation",
		"source":            "db",
	})
}

// billingStatsSummary backs GET /v1/admin/billing/stats.
func (s *Server) billingStatsSummary(w http.ResponseWriter, r *http.Request) {
	p, tx, ctx, done, ok := s.legacyBillingParams(w, r)
	if !ok {
		return
	}
	if tx == nil {
		writeJSON(w, http.StatusOK, map[string]any{
			"total_coins_purchased": 0, "total_revenue_minor": 0, "revenue_by_currency": []any{},
			"unique_buyers": 0, "transaction_count": 0, "source": "unavailable", "window": p.window(), "mode": p.Mode,
		})
		return
	}
	defer done()
	totals, _, _, err := s.revenueTotalsByCurrency(ctx, tx, p)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	_, _, purchasedCoins, err := s.coinCreditSummary(ctx, tx, p)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	var buyers int64
	_ = tx.QueryRowContext(ctx, `
		SELECT COUNT(DISTINCT p.user_id) FROM matching.billing_payments_runtime p
		WHERE p.created_at >= $1 AND p.created_at < $2 AND p.status IN ('success','partially_refunded')
		  AND `+businessModeExpr("p", s.stripeTestMode())+` = ANY($3)`, p.Since, p.Until, p.modes()).Scan(&buyers)
	byCurrency := []map[string]any{}
	var settled int64
	var single any = int64(0)
	currency := ""
	for _, c := range sortedKeys(totals) {
		m := totals[c]
		settled += m.Settled
		byCurrency = append(byCurrency, map[string]any{"currency": c, "net_minor": m.Net, "net": majorUnits(m.Net, c), "gross_minor": m.Gross, "gross": majorUnits(m.Gross, c)})
	}
	switch len(totals) {
	case 0:
		currency = strings.ToUpper(strings.TrimSpace(s.cfg.PaymentsCurrency))
	case 1:
		for c, m := range totals {
			currency, single = c, m.Net
		}
	default:
		single = nil // never add different currencies together
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"window":                p.window(),
		"mode":                  p.Mode,
		"total_coins_purchased": purchasedCoins,
		"total_revenue_minor":   single,
		"total_revenue":         majorUnitsAny(single, currency),
		"currency":              currency,
		"multi_currency":        len(totals) > 1,
		"revenue_by_currency":   byCurrency,
		"unique_buyers":         suppressCount(buyers),
		"transaction_count":     settled,
		"release_note":          businessReleaseNote,
		"source":                "db",
	})
}
