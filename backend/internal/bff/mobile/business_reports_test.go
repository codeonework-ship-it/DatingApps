package mobile

import (
	"context"
	"database/sql"
	"encoding/csv"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)

// The Postgres fixtures live in 2001 (and 2002 for the funnel) so windowed
// aggregates only ever see the rows seeded here, whatever else the shared
// local database holds.
const (
	bizSince = "2001-01-01"
	bizUntil = "2001-04-30" // inclusive date → until 2001-05-01
)

type bizFixture struct {
	db      *sql.DB
	server  *Server
	router  http.Handler
	suffix  string
	city    string
	users   map[string]string
	roles   map[string]bool
	actorID string
}

func newBizFixture(t *testing.T) *bizFixture {
	t.Helper()
	dsn := os.Getenv("PROFILE_TEST_DATABASE_URL")
	if dsn == "" {
		t.Skip("PROFILE_TEST_DATABASE_URL is not set")
	}
	db, err := sql.Open("pgx", dsn)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = db.Close() })
	f := &bizFixture{db: db, suffix: strings.ReplaceAll(uuid.NewString()[:8], "-", ""), users: map[string]string{}, roles: map[string]bool{"user": true, "finance": true}}
	f.city = "Bizqa Town " + f.suffix
	f.server = &Server{store: &runtimeStore{profileRepo: &profileRepository{pg: db}}}
	r := chi.NewRouter()
	r.Use(func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
			p := securityPrincipal{UserID: f.actorID, SessionID: "biz", Roles: f.roles}
			next.ServeHTTP(w, req.WithContext(context.WithValue(req.Context(), securityPrincipalContextKey{}, p)))
		})
	})
	r.Route("/v1", func(v1 chi.Router) {
		f.server.registerBusinessReportRoutes(v1)
		v1.Get("/admin/billing/revenue-analytics", f.server.adminRevenueAnalytics)
		v1.Get("/admin/billing/stats", f.server.adminBillingStats)
	})
	f.router = r
	f.actorID = uuid.NewString()
	return f
}

func (f *bizFixture) exec(t *testing.T, q string, args ...any) {
	t.Helper()
	if _, err := f.db.Exec(q, args...); err != nil {
		t.Fatalf("%v\n%s", err, q)
	}
}

func (f *bizFixture) member(t *testing.T, key, gender string, created time.Time, verified bool) string {
	t.Helper()
	id := uuid.NewString()
	username := "bizrpt" + f.suffix + strings.ToLower(key)
	f.exec(t, `INSERT INTO user_management.users (id, username, name, date_of_birth, gender, city, is_verified, created_at)
		VALUES ($1,$2,'Business QA','1992-02-02',$3,$4,$5,$6)`, id, username, gender, f.city, verified, created)
	f.users[key] = id
	t.Cleanup(func() { _, _ = f.db.Exec(`DELETE FROM user_management.users WHERE id=$1`, id) })
	return id
}

func (f *bizFixture) subscription(t *testing.T, user, plan, cycle, status, provider string, amount int64, start time.Time, cancelAtEnd bool, end *time.Time) string {
	t.Helper()
	var id string
	if err := f.db.QueryRow(`INSERT INTO matching.billing_subscriptions_runtime
		(user_id, plan_code, status, billing_cycle, start_date, end_date, auto_renew, provider, provider_subscription_id, cancel_at_period_end, amount_minor, currency, created_at, updated_at)
		VALUES ($1,$2,$3,$4,$5,$6,NOT $7,$8,$9,$7,$10,'INR',$5,$5) RETURNING id::text`,
		user, plan, status, cycle, start, end, cancelAtEnd, provider, "sub_biz_"+uuid.NewString(), amount).Scan(&id); err != nil {
		t.Fatal(err)
	}
	return id
}

func (f *bizFixture) payment(t *testing.T, user, subID, provider, status, reason, currency string, amount, refunded int64, created time.Time, periodStart, periodEnd *time.Time, checkoutID string) {
	t.Helper()
	var sub, checkout any
	if subID != "" {
		sub = subID
	}
	if checkoutID != "" {
		checkout = checkoutID
	}
	f.exec(t, `INSERT INTO matching.billing_payments_runtime
		(user_id, subscription_id, amount_paise, currency, status, provider, provider_payment_id, paid_at, created_at, updated_at,
		 billing_reason, period_start, period_end, refunded_amount_paise, checkout_id)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$8,$8,$9,$10,$11,$12,$13)`,
		user, sub, amount, currency, status, provider, "pay_biz_"+uuid.NewString(), created, reason, periodStart, periodEnd, refunded, checkout)
}

func day(s string) time.Time {
	t, err := time.Parse(time.RFC3339, s)
	if err != nil {
		t, _ = time.Parse("2006-01-02", s)
	}
	return t.UTC()
}

func tp(s string) *time.Time { t := day(s); return &t }

func (f *bizFixture) get(t *testing.T, path string, want int) map[string]any {
	t.Helper()
	rec := httptest.NewRecorder()
	f.router.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, path, nil))
	if rec.Code != want {
		t.Fatalf("GET %s = %d, want %d: %s", path, rec.Code, want, rec.Body.String())
	}
	var out map[string]any
	_ = json.Unmarshal(rec.Body.Bytes(), &out)
	return out
}

func (f *bizFixture) send(t *testing.T, method, path, body string, want int) map[string]any {
	t.Helper()
	rec := httptest.NewRecorder()
	req := httptest.NewRequest(method, path, strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	f.router.ServeHTTP(rec, req)
	if rec.Code != want {
		t.Fatalf("%s %s = %d, want %d: %s", method, path, rec.Code, want, rec.Body.String())
	}
	var out map[string]any
	_ = json.Unmarshal(rec.Body.Bytes(), &out)
	return out
}

func findRow(t *testing.T, rows any, match map[string]any) map[string]any {
	t.Helper()
	list, _ := rows.([]any)
	for _, item := range list {
		row, _ := item.(map[string]any)
		ok := true
		for k, v := range match {
			if row[k] != v {
				ok = false
				break
			}
		}
		if ok {
			return row
		}
	}
	t.Fatalf("no row matching %v in %v", match, rows)
	return nil
}

func num(v any) int64 {
	switch x := v.(type) {
	case float64:
		return int64(x)
	case int64:
		return x
	}
	return -1
}

// seedBusinessHistory seeds a small but complete commercial history in 2001:
// subscriptions with renewals, an upgrade, a yearly plan, a cancellation and
// a lapse; coin purchases with a partial refund and a chargeback; a GBP
// purchase; sandbox and local rows that must never count as live revenue; and
// an admin top-up that must never count as a purchase.
func seedBusinessHistory(t *testing.T, f *bizFixture) {
	t.Helper()
	jan10 := day("2001-01-10T00:00:00Z")
	a := f.member(t, "a", "female", jan10, true)
	b := f.member(t, "b", "male", jan10, true)
	c := f.member(t, "c", "female", jan10, true)
	d := f.member(t, "d", "male", jan10, true)
	e := f.member(t, "e", "female", jan10, true)
	ff := f.member(t, "f", "male", jan10, true)
	for _, k := range []string{"g", "h", "i"} {
		f.member(t, k, "other", day("2001-01-20T00:00:00Z"), false)
	}

	// A: monthly 1000, three paid periods, cancelled at period end (Apr 15).
	subA := f.subscription(t, a, "gold", "monthly", "cancelled", "stripe", 1000, day("2001-01-15T00:00:00Z"), true, tp("2001-04-15T00:00:00Z"))
	f.payment(t, a, subA, "stripe", "success", "subscription_create", "INR", 1000, 0, day("2001-01-15T00:00:00Z"), tp("2001-01-15T00:00:00Z"), tp("2001-02-15T00:00:00Z"), "")
	f.payment(t, a, subA, "stripe", "success", "subscription_cycle", "INR", 1000, 0, day("2001-02-15T00:00:00Z"), tp("2001-02-15T00:00:00Z"), tp("2001-03-15T00:00:00Z"), "")
	f.payment(t, a, subA, "stripe", "success", "subscription_cycle", "INR", 1000, 0, day("2001-03-15T00:00:00Z"), tp("2001-03-15T00:00:00Z"), tp("2001-04-15T00:00:00Z"), "")
	// B: monthly 1000 → 2000 from Mar 20, lapses after Apr 20 (payment failed).
	subB := f.subscription(t, b, "diamond", "monthly", "expired", "stripe", 2000, day("2001-01-20T00:00:00Z"), false, tp("2001-04-27T00:00:00Z"))
	f.payment(t, b, subB, "stripe", "success", "subscription_create", "INR", 1000, 0, day("2001-01-20T00:00:00Z"), tp("2001-01-20T00:00:00Z"), tp("2001-02-20T00:00:00Z"), "")
	f.payment(t, b, subB, "stripe", "success", "subscription_cycle", "INR", 1000, 0, day("2001-02-20T00:00:00Z"), tp("2001-02-20T00:00:00Z"), tp("2001-03-20T00:00:00Z"), "")
	f.payment(t, b, subB, "stripe", "success", "subscription_cycle", "INR", 2000, 0, day("2001-03-20T00:00:00Z"), tp("2001-03-20T00:00:00Z"), tp("2001-04-20T00:00:00Z"), "")
	// C: yearly 12000 from Feb 5.
	subC := f.subscription(t, c, "gold", "yearly", "active", "stripe", 12000, day("2001-02-05T00:00:00Z"), false, nil)
	f.payment(t, c, subC, "stripe", "success", "subscription_create", "INR", 12000, 0, day("2001-02-05T00:00:00Z"), tp("2001-02-05T00:00:00Z"), tp("2002-02-05T00:00:00Z"), "")
	// D: coin purchase 500, 200 refunded; admin top-up is not revenue.
	f.exec(t, `INSERT INTO matching.user_wallets(user_id, coin_balance) VALUES ($1, 1070), ($2, 200)`, d, e)
	f.payment(t, d, "", "stripe", "partially_refunded", "coin_purchase", "INR", 500, 200, day("2001-01-25T00:00:00Z"), nil, nil, "")
	f.exec(t, `INSERT INTO matching.wallet_coin_purchases(id,user_id,package_id,source,provider,idempotency_key,coins,amount_minor,currency,wallet_balance_after,created_at)
		VALUES (gen_random_uuid(),$1,'bizqa-pack','buy','stripe',$2,100,500,'INR',100,'2001-01-25T00:00:00Z'),
		       (gen_random_uuid(),$1,'admin','admin_topup','internal',$3,1000,0,'coins',1100,'2001-01-26T00:00:00Z'),
		       (gen_random_uuid(),$1,'bizqa-pack','buy','sandbox',$4,50,250,'INR',1150,'2001-01-27T00:00:00Z')`,
		d, "biz-buy-"+f.suffix, "biz-grant-"+f.suffix, "biz-sbx-"+f.suffix)
	f.exec(t, `INSERT INTO matching.wallet_coin_debits(user_id, source, coins_requested, coins_debited, coins_shortfall, wallet_balance_after, created_at)
		VALUES ($1,'purchase_refund',80,80,0,1070,'2001-01-28T00:00:00Z')`, d)
	// E: GBP coin purchase at 20:00 UTC on Jan 31 (Feb 1 in India) and a failed attempt.
	f.payment(t, e, "", "stripe", "success", "coin_purchase", "GBP", 999, 0, day("2001-01-31T20:00:00Z"), nil, nil, "")
	f.exec(t, `INSERT INTO matching.wallet_coin_purchases(id,user_id,package_id,source,provider,idempotency_key,coins,amount_minor,currency,wallet_balance_after,created_at)
		VALUES (gen_random_uuid(),$1,'bizqa-pack','buy','stripe',$2,200,999,'GBP',200,'2001-01-31T20:00:00Z')`, e, "biz-gbp-"+f.suffix)
	f.payment(t, e, "", "stripe", "failed", "coin_purchase", "INR", 999, 0, day("2001-02-11T00:00:00Z"), nil, nil, "")
	// F: a fully refunded subscription period and a charged-back coin purchase.
	subF := f.subscription(t, ff, "gold", "monthly", "cancelled", "stripe", 1000, day("2001-03-03T00:00:00Z"), false, tp("2001-03-04T00:00:00Z"))
	f.payment(t, ff, subF, "stripe", "refunded", "subscription_create", "INR", 1000, 1000, day("2001-03-03T00:00:00Z"), tp("2001-03-03T00:00:00Z"), tp("2001-04-03T00:00:00Z"), "")
	f.payment(t, ff, "", "stripe", "chargeback", "coin_purchase", "INR", 700, 0, day("2001-03-10T00:00:00Z"), nil, nil, "")
	// Sandbox and local rows: never live revenue.
	f.payment(t, a, "", "sandbox", "success", "coin_purchase", "INR", 5555, 0, day("2001-01-16T00:00:00Z"), nil, nil, "")
	f.payment(t, a, "", "local", "success", "local_activation", "INR", 4999, 0, day("2001-01-17T00:00:00Z"), nil, nil, "")
}

func window(path string) string {
	sep := "?"
	if strings.Contains(path, "?") {
		sep = "&"
	}
	return path + sep + "since=" + bizSince + "&until=" + bizUntil
}

func TestBusinessRevenueWindowExclusionsAndCurrenciesPostgres(t *testing.T) {
	f := newBizFixture(t)
	seedBusinessHistory(t, f)

	out := f.get(t, window("/v1/admin/business/revenue?bucket=month"), http.StatusOK)
	inr := findRow(t, out["totals"], map[string]any{"currency": "INR"})
	// gross = A 3000 + B 4000 + C 12000 + D 500 + F 1000 (refunded) + F 700 (chargeback)
	if num(inr["gross_minor"]) != 21200 || num(inr["refunded_minor"]) != 1200 || num(inr["chargeback_minor"]) != 700 || num(inr["net_minor"]) != 19300 {
		t.Fatalf("INR totals wrong: %+v", inr)
	}
	if inr["net"] != "193.00" || inr["market"] != "India" {
		t.Fatalf("INR presentation wrong: %+v", inr)
	}
	if inr["paying_members"] != "<5" || num(inr["failed_payments"]) != 1 {
		t.Fatalf("payers must be suppressed and the failed attempt counted: %+v", inr)
	}
	if inr["arppu_minor"] != nil {
		t.Fatalf("ARPPU over fewer than five payers must be withheld: %+v", inr)
	}
	gbp := findRow(t, out["totals"], map[string]any{"currency": "GBP"})
	if num(gbp["gross_minor"]) != 999 || num(gbp["net_minor"]) != 999 || gbp["net"] != "9.99" {
		t.Fatalf("GBP totals wrong (currencies must stay separate): %+v", gbp)
	}
	if list, _ := out["totals"].([]any); len(list) != 2 {
		t.Fatalf("expected exactly INR and GBP totals, got %v", out["totals"])
	}
	status := out["data_status"].(map[string]any)
	if num(status["sandbox_payments_in_window"]) != 1 || num(status["local_payments_in_window"]) != 1 || status["sandbox_hint"] == nil {
		t.Fatalf("data status must report sandbox and local rows separately: %+v", status)
	}
	// Month trend: INR Jan net = A 1000 + B 1000 + D 300.
	jan := findRow(t, out["trend"], map[string]any{"bucket": "2001-01-01", "currency": "INR"})
	if num(jan["net_minor"]) != 2300 || num(jan["coin_package_net_minor"]) != 300 || num(jan["subscription_net_minor"]) != 2000 {
		t.Fatalf("January INR trend wrong: %+v", jan)
	}
	gbpJan := findRow(t, out["trend"], map[string]any{"bucket": "2001-01-01", "currency": "GBP"})
	if num(gbpJan["net_minor"]) != 999 {
		t.Fatalf("GBP Jan 31 20:00Z is January in UTC: %+v", gbpJan)
	}
	// Reporting in Asia/Kolkata moves the GBP purchase into February.
	ist := f.get(t, window("/v1/admin/business/revenue?bucket=month&tz=Asia/Kolkata"), http.StatusOK)
	if row := findRow(t, ist["trend"], map[string]any{"bucket": "2001-02-01", "currency": "GBP"}); num(row["net_minor"]) != 999 {
		t.Fatalf("GBP purchase must fall in February IST: %+v", row)
	}
	// Product split.
	coin := findRow(t, out["by_product"], map[string]any{"currency": "INR", "product_type": "coin_package"})
	if num(coin["net_minor"]) != 300 || num(coin["chargeback_minor"]) != 700 {
		t.Fatalf("coin product wrong: %+v", coin)
	}
	// City pooling: fewer than five payers in the city never shows a city row.
	cities, _ := out["by_city"].([]any)
	for _, c := range cities {
		if row := c.(map[string]any); row["city"] == strings.ToLower(f.city) {
			t.Fatalf("a city with fewer than five payers must be pooled: %+v", row)
		}
	}

	// Sandbox mode sees only sandbox money.
	sbx := f.get(t, window("/v1/admin/business/revenue?mode=sandbox"), http.StatusOK)
	if row := findRow(t, sbx["totals"], map[string]any{"currency": "INR"}); num(row["gross_minor"]) != 5555 {
		t.Fatalf("sandbox mode wrong: %+v", row)
	}

	// The corrected billing analytics agree with the business report and
	// exclude admin top-ups and sandbox coin buys from purchases.
	legacy := f.get(t, window("/v1/admin/billing/revenue-analytics"), http.StatusOK)
	if row := findRow(t, legacy["revenue"], map[string]any{"currency": "INR"}); num(row["net_minor"]) != 19300 || num(row["gross_minor"]) != 21200 {
		t.Fatalf("revenue analytics disagree with the business report: %+v", row)
	}
	coins := legacy["coin_purchases"].(map[string]any)
	if num(coins["purchased_coins"]) != 300 {
		t.Fatalf("purchased coins must be live buys only (100 INR + 200 GBP): %+v", coins)
	}
	if grants := coins["non_revenue"].(map[string]any)["admin_topup"].(map[string]any); num(grants["coins"]) != 1000 || grants["revenue"] != false {
		t.Fatalf("admin top-up must be reported as non-revenue: %+v", grants)
	}
	stats := f.get(t, window("/v1/admin/billing/stats"), http.StatusOK)
	if stats["multi_currency"] != true || stats["total_revenue_minor"] != nil || num(stats["total_coins_purchased"]) != 300 {
		t.Fatalf("billing stats must not add currencies together: %+v", stats)
	}

	// CSV export of the totals table.
	rec := httptest.NewRecorder()
	f.router.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, window("/v1/admin/business/revenue?format=csv&table=totals"), nil))
	if rec.Code != http.StatusOK || !strings.HasPrefix(rec.Header().Get("Content-Type"), "text/csv") || !strings.Contains(rec.Header().Get("Content-Disposition"), "business-revenue-totals-live-20010101-20010501.csv") {
		t.Fatalf("csv export = %d %v", rec.Code, rec.Header())
	}
	records, err := csv.NewReader(strings.NewReader(rec.Body.String())).ReadAll()
	if err != nil || len(records) != 3 || records[0][0] != "currency" {
		t.Fatalf("csv body wrong: %v %q", err, rec.Body.String())
	}
	for _, r := range records[1:] {
		if r[0] == "INR" && (r[6] != "193.00" || r[10] != "<5") {
			t.Fatalf("csv INR row wrong: %v", r)
		}
	}
	f.get(t, window("/v1/admin/business/revenue?format=csv&table=nope"), http.StatusBadRequest)
}

func TestBusinessRevenueAgreesWithReconciliationPostgres(t *testing.T) {
	f := newBizFixture(t)
	seedBusinessHistory(t, f)
	since, until := day(bizSince), day("2001-05-01")
	recon, err := newBillingRepository(f.db).reconcile(context.Background(), since, until)
	if err != nil {
		t.Fatal(err)
	}
	rev := recon["revenue"].(map[string]any)
	out := f.get(t, window("/v1/admin/business/revenue?mode=all"), http.StatusOK)
	var gross, net, refunded, chargeback int64
	for _, item := range out["totals"].([]any) {
		row := item.(map[string]any)
		gross += num(row["gross_minor"])
		net += num(row["net_minor"])
		refunded += num(row["refunded_minor"])
		chargeback += num(row["chargeback_minor"])
	}
	if gross != rev["gross_minor"].(int64) || net != rev["net_minor"].(int64) || refunded != rev["refunded_minor"].(int64) || chargeback != rev["chargeback_minor"].(int64) {
		t.Fatalf("business (live+sandbox) and reconciliation disagree: business gross=%d net=%d refunded=%d chargeback=%d; reconciliation %+v", gross, net, refunded, chargeback, rev)
	}
	if rev["local_activation_minor"].(int64) != 4999 {
		t.Fatalf("both reports must exclude the local activation: %+v", rev)
	}
}

func TestBusinessSubscriptionsMRRMovementsAndChurnPostgres(t *testing.T) {
	f := newBizFixture(t)
	seedBusinessHistory(t, f)
	out := f.get(t, window("/v1/admin/business/subscriptions?bucket=month"), http.StatusOK)
	want := map[string]int64{"2001-01-01": 0, "2001-02-01": 2000, "2001-03-01": 3000, "2001-04-01": 4000, "2001-05-01": 1000}
	for label, mrr := range want {
		row := findRow(t, out["mrr"], map[string]any{"label": label, "currency": "INR"})
		if num(row["mrr_minor"]) != mrr || num(row["arr_minor"]) != mrr*12 {
			t.Fatalf("MRR at %s = %v, want %d", label, row, mrr)
		}
	}
	type move struct{ newM, exp, con, churn int64 }
	moves := map[string]move{
		"2001-01-01": {2000, 0, 0, 0},
		"2001-02-01": {1000, 0, 0, 0},
		"2001-03-01": {0, 1000, 0, 0},
		"2001-04-01": {0, 0, 0, 3000},
	}
	for bucket, m := range moves {
		row := findRow(t, out["movements"], map[string]any{"bucket": bucket, "currency": "INR"})
		if num(row["new_minor"]) != m.newM || num(row["expansion_minor"]) != m.exp || num(row["contraction_minor"]) != m.con || num(row["churned_minor"]) != m.churn {
			t.Fatalf("movements %s wrong: %+v", bucket, row)
		}
		if num(row["mrr_start_minor"])+num(row["new_minor"])+num(row["expansion_minor"])-num(row["contraction_minor"])-num(row["churned_minor"]) != num(row["mrr_end_minor"]) {
			t.Fatalf("movements must bridge start to end: %+v", row)
		}
	}
	apr := findRow(t, out["movements"], map[string]any{"bucket": "2001-04-01", "currency": "INR"})
	if apr["churned_subscribers"] != "<5" || apr["logo_churn_rate"] != nil {
		t.Fatalf("small churn counts must be suppressed: %+v", apr)
	}
	if rate, _ := apr["revenue_churn_rate"].(float64); rate != 0.75 {
		t.Fatalf("revenue churn = 3000/4000, got %+v", apr["revenue_churn_rate"])
	}
	reasons := out["churn"].(map[string]any)["reasons"]
	if row := findRow(t, reasons, map[string]any{"reason": "member_cancelled"}); row["subscribers"] != "<5" {
		t.Fatalf("A cancelled at period end: %+v", row)
	}
	if row := findRow(t, reasons, map[string]any{"reason": "payment_failed"}); row["subscribers"] != "<5" {
		t.Fatalf("B lapsed: %+v", row)
	}
	if row := findRow(t, reasons, map[string]any{"reason": "refunded"}); num(row["subscribers"]) != 0 {
		t.Fatalf("F never had MRR so it cannot churn: %+v", row)
	}
	if trials := out["trials"].(map[string]any); trials["offered"] != false {
		t.Fatalf("trials must be reported as not offered: %+v", trials)
	}
}

func TestBusinessConversionCohortsLTVAndFunnelPostgres(t *testing.T) {
	f := newBizFixture(t)
	seedBusinessHistory(t, f)
	out := f.get(t, window("/v1/admin/business/conversion"), http.StatusOK)
	cohort := findRow(t, out["cohorts"], map[string]any{"cohort": "2001-01"})
	if num(cohort["members"]) != 9 || cohort["paid_7d"] != "<5" || num(cohort["paid_30d"]) != 5 || num(cohort["paid_to_date"]) != 6 {
		t.Fatalf("cohort conversion wrong: %+v", cohort)
	}
	if rate, _ := cohort["conversion_to_date"].(float64); rate != 0.6667 {
		t.Fatalf("conversion to date = 6/9, got %v", cohort["conversion_to_date"])
	}
	ltv := findRow(t, out["ltv"], map[string]any{"cohort": "2001-01", "currency": "INR"})
	curve := ltv["cumulative_net_per_member_minor"].([]any)
	// Cumulative INR net per member: Jan 2300/9, Feb 16300/9, Mar 19300/9.
	if num(curve[0]) != 256 || num(curve[1]) != 1811 || num(curve[2]) != 2144 || num(curve[3]) != 2144 {
		t.Fatalf("LTV curve wrong: %v", curve[:4])
	}

	// Funnel in its own window (2002): 6 coin checkouts, 5 completed, 5 paid, 1 refunded.
	user := f.users["a"]
	for i := 0; i < 6; i++ {
		var id string
		status := "completed"
		if i == 5 {
			status = "expired"
		}
		if err := f.db.QueryRow(`INSERT INTO matching.billing_checkout_sessions(user_id, kind, package_id, coins, provider, status, amount_minor, currency, created_at)
			VALUES ($1,'coin_package','bizqa-pack',100,'stripe',$2,500,'INR','2002-01-05T00:00:00Z') RETURNING id::text`, user, status).Scan(&id); err != nil {
			t.Fatal(err)
		}
		if i < 5 {
			payStatus := "success"
			if i == 0 {
				payStatus = "refunded"
			}
			f.payment(t, user, "", "stripe", payStatus, "coin_purchase", "INR", 500, 0, day("2002-01-05T00:00:00Z"), nil, nil, id)
		}
	}
	funnel := f.get(t, "/v1/admin/business/funnel?since=2002-01-01&until=2002-01-31", http.StatusOK)
	totals := funnel["totals"].(map[string]any)
	if num(totals["created"]) != 6 || num(totals["completed"]) != 5 || num(totals["paid"]) != 5 || totals["refunded"] != "<5" {
		t.Fatalf("funnel totals wrong: %+v", totals)
	}
	if rate, _ := totals["paid_rate"].(float64); rate != 0.8333 {
		t.Fatalf("paid rate = 5/6, got %v", totals["paid_rate"])
	}
	detail := findRow(t, funnel["detail"], map[string]any{"product": "bizqa-pack"})
	if detail["platform"] != "not_captured" || detail["members"] != "<5" {
		t.Fatalf("funnel detail wrong: %+v", detail)
	}
}

func TestBusinessCoinEconomyPostgres(t *testing.T) {
	f := newBizFixture(t)
	seedBusinessHistory(t, f)
	out := f.get(t, window("/v1/admin/business/coins?bucket=month"), http.StatusOK)
	sources := out["sources"].(map[string]any)
	if num(sources["purchased"].(map[string]any)["coins"]) != 300 {
		t.Fatalf("purchased coins must be live buys only: %+v", sources)
	}
	nonRevenue := sources["non_revenue"].(map[string]any)
	if num(nonRevenue["admin_topup"].(map[string]any)["coins"]) != 1000 {
		t.Fatalf("admin grant must be a non-revenue source: %+v", nonRevenue)
	}
	jan := findRow(t, out["trend"], map[string]any{"bucket": "2001-01-01"})
	if num(jan["purchased"]) != 300 || num(jan["granted"]) != 1000 || num(jan["clawback_debits"]) != 80 {
		t.Fatalf("January coin flows wrong: %+v", jan)
	}
	liability := out["liability"].(map[string]any)
	if num(liability["outstanding_coins"]) < 1270 {
		t.Fatalf("liability must include the seeded balances: %+v", liability)
	}
	sandbox := f.get(t, window("/v1/admin/business/coins?mode=sandbox"), http.StatusOK)
	if num(sandbox["sources"].(map[string]any)["purchased"].(map[string]any)["coins"]) != 50 {
		t.Fatalf("sandbox coin buys must be reported only in sandbox mode: %+v", sandbox["sources"])
	}
}

func TestBusinessReferralsKFactorPostgres(t *testing.T) {
	f := newBizFixture(t)
	seedBusinessHistory(t, f)
	codeID := uuid.NewString()
	code := strings.ToUpper("BIZQA" + f.suffix)
	f.exec(t, `INSERT INTO growth.referral_codes(id, owner_id, code, status, created_at) VALUES ($1,$2,$3,'active','2001-01-11T00:00:00Z')`, codeID, f.users["a"], code)
	for _, k := range []string{"g", "h", "i"} {
		f.exec(t, `INSERT INTO growth.referral_redemptions(code_id, referred_member_id, status, created_at) VALUES ($1,$2,'recorded','2001-01-20T00:00:00Z')`, codeID, f.users[k])
	}
	t.Cleanup(func() {
		_, _ = f.db.Exec(`DELETE FROM growth.referral_redemptions WHERE code_id=$1`, codeID)
		_, _ = f.db.Exec(`DELETE FROM growth.referral_codes WHERE id=$1`, codeID)
	})
	out := f.get(t, window("/v1/admin/business/referrals"), http.StatusOK)
	row := findRow(t, out["k_factor"].(map[string]any)["by_cohort"], map[string]any{"cohort": "2001-01"})
	if num(row["members"]) != 9 || row["referral_signups_30d"] != "<5" {
		t.Fatalf("k-factor cohort wrong: %+v", row)
	}
	if k, _ := row["k_referral"].(float64); k != 0.3333 {
		t.Fatalf("K = 3 accepted / 9 members, got %v", row["k_referral"])
	}
	refs := out["referrals"].(map[string]any)
	if refs["redemptions"].(map[string]any)["accepted"] != "<5" {
		t.Fatalf("redemptions must be suppressed: %+v", refs)
	}
}

func TestBusinessMarketReadinessGatesPostgres(t *testing.T) {
	f := newBizFixture(t)
	seedBusinessHistory(t, f)
	key := "bizqa-" + f.suffix
	t.Cleanup(func() { _, _ = f.db.Exec(`DELETE FROM business.launch_markets WHERE city_key=$1`, key) })
	save := func(target int, share float64, want int) {
		body, _ := json.Marshal(map[string]any{"city_key": key, "display_name": "Bizqa Town", "country": "QA", "currency": "INR",
			"aliases": []string{strings.ToLower(f.city)}, "verified_target": target, "max_gender_share": share})
		f.send(t, http.MethodPost, "/v1/admin/business/markets", string(body), want)
	}
	status := func() map[string]any {
		out := f.get(t, "/v1/admin/business/markets", http.StatusOK)
		return findRow(t, out["markets"], map[string]any{"city_key": key})
	}
	save(5, 0.6, http.StatusCreated)
	row := status()
	if row["status"] != "ready" || num(row["members"]) != 9 || num(row["verified_members"]) != 6 {
		t.Fatalf("6 verified, 3/3 women/men against a target of 5 must be ready: %+v", row)
	}
	gender := row["gates"].(map[string]any)["gender_balance"].(map[string]any)
	if gender["largest_share"] != 0.5 || gender["met"] != true {
		t.Fatalf("gender gate wrong: %+v", gender)
	}
	save(10, 0.6, http.StatusOK)
	if row = status(); row["status"] != "approaching" {
		t.Fatalf("6 of 10 verified is approaching: %+v", row)
	}
	save(100, 0.6, http.StatusOK)
	if row = status(); row["status"] != "not_ready" {
		t.Fatalf("6 of 100 verified is not ready: %+v", row)
	}
	f.send(t, http.MethodPost, "/v1/admin/business/markets", `{"city_key":"all","display_name":"x","country":"QA","currency":"INR"}`, http.StatusBadRequest)
	f.roles = map[string]bool{"user": true, "analyst": true}
	save(5, 0.6, http.StatusForbidden)
}

func TestBusinessMarketingSpendCACAndInvestorPackPostgres(t *testing.T) {
	f := newBizFixture(t)
	seedBusinessHistory(t, f)
	t.Cleanup(func() {
		_, _ = f.db.Exec(`DELETE FROM business.marketing_spend WHERE month IN ('2001-01-01','2001-02-01')`)
	})
	_, _ = f.db.Exec(`DELETE FROM business.marketing_spend WHERE month IN ('2001-01-01','2001-02-01')`)

	created := f.send(t, http.MethodPost, "/v1/admin/business/marketing-spend", `{"month":"2001-01","channel":"paid_social","market":"all","currency":"INR","amount":"900.00","note":"launch test"}`, http.StatusCreated)
	spend := created["spend"].(map[string]any)
	id := spend["id"].(string)
	if num(spend["amount_minor"]) != 90000 {
		t.Fatalf("amount must be stored in minor units: %+v", spend)
	}
	f.send(t, http.MethodPost, "/v1/admin/business/marketing-spend", `{"month":"2001-01","channel":"paid_social","market":"all","currency":"INR","amount_minor":90000}`, http.StatusOK)
	other := f.send(t, http.MethodPost, "/v1/admin/business/marketing-spend", `{"month":"2001-02","channel":"search","currency":"INR","amount_minor":5000}`, http.StatusCreated)
	otherID := other["spend"].(map[string]any)["id"].(string)
	f.send(t, http.MethodPut, "/v1/admin/business/marketing-spend/"+otherID, `{"month":"2001-01","channel":"paid_social","market":"all","currency":"INR","amount_minor":1}`, http.StatusConflict)
	f.send(t, http.MethodPost, "/v1/admin/business/marketing-spend", `{"month":"2001-01","channel":"billboards","currency":"INR","amount_minor":1}`, http.StatusBadRequest)
	f.send(t, http.MethodPost, "/v1/admin/business/marketing-spend", `{"month":"2001-01","channel":"search","market":"atlantis","currency":"INR","amount_minor":1}`, http.StatusBadRequest)
	f.send(t, http.MethodPost, "/v1/admin/business/marketing-spend", `{"month":"2001-01","channel":"search","currency":"INR","amount":"1.234"}`, http.StatusBadRequest)
	f.send(t, http.MethodDelete, "/v1/admin/business/marketing-spend/"+otherID, ``, http.StatusOK)
	f.send(t, http.MethodDelete, "/v1/admin/business/marketing-spend/"+otherID, ``, http.StatusNotFound)

	list := f.get(t, "/v1/admin/business/marketing-spend?since=2001-01-01&until=2001-03-31", http.StatusOK)
	cac := findRow(t, list["cac"], map[string]any{"month": "2001-01", "currency": "INR"})
	if num(cac["cac_minor"]) != 10000 || num(cac["new_members"]) != 9 {
		t.Fatalf("CAC = 90000 / 9 joiners: %+v", cac)
	}

	pack := f.get(t, window("/v1/admin/business/investor-pack"), http.StatusOK)
	months := pack["months"].([]any)
	if len(months) != 4 {
		t.Fatalf("expected four months, got %d", len(months))
	}
	jan := months[0].(map[string]any)
	if jan["month"] != "2001-01" || num(jan["new_members"]) != 9 || jan["mau"] != nil || jan["burn"] != "not available" {
		t.Fatalf("January pack wrong: %+v", jan)
	}
	janINR := findRow(t, jan["by_currency"], map[string]any{"currency": "INR"})
	if num(janINR["net_minor"]) != 2300 || num(janINR["mrr_minor"]) != 2000 || num(janINR["cac_minor"]) != 10000 {
		t.Fatalf("January INR KPIs wrong: %+v", janINR)
	}
	feb := months[1].(map[string]any)
	febINR := findRow(t, feb["by_currency"], map[string]any{"currency": "INR"})
	if num(febINR["net_minor"]) != 14000 || num(febINR["mrr_minor"]) != 3000 || febINR["cac"] != "needs spend data" {
		t.Fatalf("February INR KPIs wrong: %+v", febINR)
	}
	rec := httptest.NewRecorder()
	f.router.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, window("/v1/admin/business/investor-pack?format=csv"), nil))
	if rec.Code != http.StatusOK || !strings.Contains(rec.Body.String(), "needs spend data") || !strings.Contains(rec.Body.String(), "not available") {
		t.Fatalf("investor pack csv = %d %s", rec.Code, rec.Body.String())
	}

	f.roles = map[string]bool{"user": true, "analyst": true}
	f.send(t, http.MethodPost, "/v1/admin/business/marketing-spend", `{"month":"2001-01","channel":"search","currency":"INR","amount_minor":1}`, http.StatusForbidden)
	f.get(t, window("/v1/admin/business/investor-pack"), http.StatusOK)
	f.roles = map[string]bool{"user": true, "moderator": true}
	f.get(t, window("/v1/admin/business/revenue"), http.StatusForbidden)
	_ = id
}

func TestBusinessReportsEmptyWindowPostgres(t *testing.T) {
	f := newBizFixture(t)
	for _, path := range []string{"revenue", "subscriptions", "conversion", "funnel", "coins", "referrals", "investor-pack", "marketing-spend"} {
		out := f.get(t, "/v1/admin/business/"+path+"?since=1990-01-01&until=1990-03-31&bucket=month", http.StatusOK)
		if out["report"] == nil {
			t.Fatalf("%s: missing report envelope: %+v", path, out)
		}
	}
	// Default windows over whatever the local database holds must not error.
	for _, path := range []string{"revenue", "subscriptions", "conversion", "funnel", "coins", "referrals", "markets", "investor-pack", "marketing-spend"} {
		f.get(t, "/v1/admin/business/"+path+"?mode=all", http.StatusOK)
		f.get(t, "/v1/admin/business/"+path+"?tz=Asia/Kolkata", http.StatusOK)
	}
	out := f.get(t, "/v1/admin/business/revenue?since=1990-01-01&until=1990-01-31", http.StatusOK)
	if list, _ := out["totals"].([]any); len(list) != 0 || out["data_status"].(map[string]any)["empty"] != true {
		t.Fatalf("an empty window must report empty, not error: %+v", out)
	}
	if !strings.Contains(out["data_status"].(map[string]any)["release_note"].(string), "PEN-25") {
		t.Fatalf("release note missing")
	}
	f.get(t, "/v1/admin/business/revenue?since=2001-02-01&until=2001-01-01", http.StatusBadRequest)
	f.get(t, "/v1/admin/business/revenue?tz=Mars/Base", http.StatusBadRequest)
	f.get(t, "/v1/admin/business/revenue?mode=everything", http.StatusBadRequest)
	f.get(t, "/v1/admin/business/revenue?since=2000-01-01&until=2001-12-31&bucket=day", http.StatusBadRequest)
}

func TestBusinessRoleMatrix(t *testing.T) {
	principal := func(roles ...string) securityPrincipal {
		set := map[string]bool{"user": true}
		for _, r := range roles {
			set[r] = true
		}
		return securityPrincipal{UserID: "op", Roles: set}
	}
	cases := []struct {
		roles  []string
		method string
		path   string
		want   bool
	}{
		{[]string{"finance"}, http.MethodGet, "/v1/admin/business/revenue", true},
		{[]string{"finance"}, http.MethodPost, "/v1/admin/business/marketing-spend", true},
		{[]string{"finance"}, http.MethodDelete, "/v1/admin/business/marketing-spend/x", true},
		{[]string{"finance"}, http.MethodPost, "/v1/admin/business/markets", true},
		{[]string{"finance"}, http.MethodGet, "/v1/admin/billing/reconciliation", true},
		{[]string{"finance"}, http.MethodGet, "/v1/admin/analytics/overview", true},
		{[]string{"finance"}, http.MethodPost, "/v1/admin/billing/grant-coins", false},
		{[]string{"finance"}, http.MethodGet, "/v1/admin/users", false},
		{[]string{"finance"}, http.MethodGet, "/v1/admin/moderation/reports", false},
		{[]string{"analyst"}, http.MethodGet, "/v1/admin/business/investor-pack", true},
		{[]string{"analyst"}, http.MethodPost, "/v1/admin/business/marketing-spend", false},
		{[]string{"ops_admin"}, http.MethodGet, "/v1/admin/business/markets", true},
		{[]string{"ops_admin"}, http.MethodPost, "/v1/admin/business/markets", true},
		{[]string{"ops_admin"}, http.MethodPost, "/v1/admin/business/marketing-spend", false},
		{[]string{"moderator"}, http.MethodGet, "/v1/admin/business/revenue", false},
		{[]string{"trust_safety"}, http.MethodGet, "/v1/admin/business/coins", false},
		{[]string{"admin"}, http.MethodPut, "/v1/admin/business/marketing-spend/x", true},
	}
	for _, tc := range cases {
		if got := principalCanAccessAdminRoute(principal(tc.roles...), "/v1", tc.method, tc.path); got != tc.want {
			t.Errorf("%v %s %s = %v, want %v", tc.roles, tc.method, tc.path, got, tc.want)
		}
	}
	req := httptest.NewRequest(http.MethodGet, "/v1/admin/business/revenue", nil)
	req = req.WithContext(context.WithValue(req.Context(), securityPrincipalContextKey{}, principal("finance")))
	if _, err := authenticatedOperatorID(req); err != nil {
		t.Fatalf("finance must be an operator role: %v", err)
	}
}

func TestBusinessHelpers(t *testing.T) {
	if suppressCount(0) != int64(0) || suppressCount(4) != "<5" || suppressCount(5) != int64(5) {
		t.Fatal("suppression thresholds wrong")
	}
	if perMember(1000, 4) != nil || perMember(1000, 5) != int64(200) {
		t.Fatal("per-member averages must need five members")
	}
	if majorUnits(19300, "INR") != "193.00" || majorUnits(-5, "EUR") != "-0.05" || majorUnits(500, "JPY") != "500" {
		t.Fatal("major unit formatting wrong")
	}
	if csvCell("=HYPERLINK(1)") != "'=HYPERLINK(1)" || csvCell(int64(-5)) != "-5" || csvCell(nil) != "" {
		t.Fatal("csv cells must neutralise formulas but keep numbers")
	}
	if v, err := parseMajorAmount("1,250.5", "INR"); err != nil || v != 125050 {
		t.Fatalf("parse amount = %d %v", v, err)
	}
	if _, err := parseMajorAmount("1.234", "EUR"); err == nil {
		t.Fatal("three decimals must be rejected")
	}
	loc, _ := time.LoadLocation("Asia/Kolkata")
	p := businessParams{Since: time.Date(2026, 9, 29, 0, 0, 0, 0, loc), Until: time.Date(2026, 10, 13, 0, 0, 0, 0, loc), Loc: loc, Bucket: "week"}
	if labels := businessBucketLabels(p); len(labels) != 3 || labels[0] != "2026-09-28" {
		t.Fatalf("ISO week buckets wrong: %v", labels)
	}
	if !strings.Contains(businessModeExpr("p", true), "p.provider='stripe' AND TRUE") {
		t.Fatal("stripe test keys must classify stripe rows as sandbox")
	}
}
