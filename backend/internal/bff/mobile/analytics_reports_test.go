package mobile

import (
	"context"
	"crypto/rand"
	"database/sql"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/verified-dating/backend/internal/platform/config"
)

// The fixture lives on days in 2001 so that no other data shares its cells:
// every assertion below is exact. analyticsDay0 is a Monday.
var analyticsDay0 = time.Date(2001, 3, 5, 0, 0, 0, 0, time.UTC)

type analyticsFixture struct {
	db           *sql.DB
	server       *Server
	city         string
	women, men   []string
	others       []string
	testAccount  string
	operator     string
	flagged      string
	allMemberIDs []string
}

func analyticsAt(day int, hour, minute int) time.Time {
	return analyticsDay0.AddDate(0, 0, day).Add(time.Duration(hour)*time.Hour + time.Duration(minute)*time.Minute)
}

func analyticsExec(t *testing.T, db *sql.DB, query string, args ...any) {
	t.Helper()
	if _, err := db.Exec(query, args...); err != nil {
		t.Fatalf("%v\n%s", err, query)
	}
}

func newAnalyticsFixture(t *testing.T) *analyticsFixture {
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
	var ready bool
	if err := db.QueryRow(`SELECT to_regclass('analytics.daily_metrics') IS NOT NULL`).Scan(&ready); err != nil || !ready {
		t.Skip("migration 123_product_analytics_snapshots is not applied")
	}
	suffix := strings.ReplaceAll(uuid.NewString()[:8], "-", "")
	f := &analyticsFixture{db: db, city: "anlcity " + suffix,
		server: &Server{store: &runtimeStore{profileRepo: &profileRepository{pg: db}}}}
	t.Cleanup(func() {
		ctx := context.Background()
		for _, id := range f.allMemberIDs {
			deleteTestMember(ctx, db, id)
			_, _ = db.Exec(`DELETE FROM user_management.auth_credentials WHERE user_id = $1`, id)
		}
		last := analyticsDay0.AddDate(0, 0, 40)
		_, _ = db.Exec(`DELETE FROM analytics.daily_metrics WHERE day BETWEEN $1 AND $2`, analyticsDay0, last)
		_, _ = db.Exec(`DELETE FROM analytics.member_active_days WHERE day BETWEEN $1 AND $2`, analyticsDay0, last)
		_, _ = db.Exec(`DELETE FROM analytics.member_surface_days WHERE day BETWEEN $1 AND $2`, analyticsDay0, last)
		_, _ = db.Exec(`DELETE FROM analytics.snapshot_days WHERE day BETWEEN $1 AND $2`, analyticsDay0.AddDate(0, 0, -40), last)
		_, _ = db.Exec(`DELETE FROM analytics.snapshot_runs WHERE from_day BETWEEN $1 AND $2`, analyticsDay0.AddDate(0, 0, -40), last)
	})
	seed := func(prefix, gender string, terms bool) string {
		id := uuid.NewString()
		f.allMemberIDs = append(f.allMemberIDs, id)
		username := prefix + strings.ReplaceAll(id[:8], "-", "")
		var g any = gender
		if gender == "" {
			g = nil
		}
		analyticsExec(t, db, `INSERT INTO user_management.users
			(id, username, name, date_of_birth, gender, city, country, created_at, terms_accepted, terms_accepted_at, profile_completion)
			VALUES ($1, $2, $3, '1975-06-01', $4, $5, 'Analytics QA', $6, $7, CASE WHEN $7 THEN $8::timestamptz END, 80)`,
			id, username, "Analytics "+prefix, g, f.city, analyticsAt(0, 10, 0), terms, analyticsAt(0, 10, 5))
		// Sessions and operator roles hang off credentials.
		analyticsExec(t, db, `INSERT INTO user_management.auth_credentials(user_id, username, password_hash) VALUES ($1, $2, 'not-a-real-hash')`, id, username)
		return id
	}
	for i := 0; i < 6; i++ {
		f.women = append(f.women, seed("anlw", "female", true))
		f.men = append(f.men, seed("anlm", "male", true))
	}
	f.others = []string{seed("anlo", "other", false), seed("anlo", "other", false)}
	f.testAccount = seed("anlqa_", "female", true)
	f.operator = seed("anlop", "female", true)
	f.flagged = seed("anlfl", "female", true)
	analyticsExec(t, db, `INSERT INTO user_management.auth_account_roles(user_id, role) VALUES ($1, 'admin')`, f.operator)
	analyticsExec(t, db, `INSERT INTO analytics.excluded_accounts(user_id, reason, created_by) VALUES ($1, 'QA device', 'test')`, f.flagged)

	couples := append(append([]string{}, f.women...), f.men...)
	for _, id := range couples {
		analyticsExec(t, db, `INSERT INTO user_management.profile_setup_completions(user_id, completed_at, idempotency_key) VALUES ($1, $2, $3)`,
			id, analyticsAt(0, 10, 10), "anl-"+id)
		analyticsExec(t, db, `INSERT INTO matching.verification_states(user_id, status, submitted_at, reviewed_at) VALUES ($1, 'verified', $2, $3)`,
			id, analyticsAt(0, 10, 20), analyticsAt(0, 10, 30))
	}
	// Excluded accounts are as busy as anyone; none of it may be counted.
	for _, id := range []string{f.testAccount, f.operator, f.flagged} {
		analyticsExec(t, db, `INSERT INTO matching.swipes(user_id, target_user_id, is_like, created_at) VALUES ($1, $2, TRUE, $3)`,
			id, f.men[0], analyticsAt(0, 11, 0))
	}
	for i := range f.women {
		w, m := f.women[i], f.men[i]
		analyticsExec(t, db, `INSERT INTO matching.swipes(user_id, target_user_id, is_like, created_at) VALUES ($1, $2, TRUE, $3), ($2, $1, TRUE, $4)`,
			w, m, analyticsAt(0, 11, 0), analyticsAt(0, 11, 30))
		low, high := w, m
		if high < low {
			low, high = high, low
		}
		matchID := uuid.NewString()
		analyticsExec(t, db, `INSERT INTO matching.matches(id, user_id_1, user_id_2, created_at) VALUES ($1, $2, $3, $4)`,
			matchID, low, high, analyticsAt(0, 12, 0))
		if i == 5 {
			analyticsExec(t, db, `INSERT INTO matching.messages(match_id, sender_id, text, created_at) VALUES ($1, $2, 'hi', $3)`,
				matchID, w, analyticsAt(0, 13, 0))
			continue
		}
		for k := 0; k < 3; k++ {
			analyticsExec(t, db, `INSERT INTO matching.messages(match_id, sender_id, text, created_at) VALUES ($1, $2, 'hi', $3), ($1, $4, 'hey', $5)`,
				matchID, w, analyticsAt(0, 13, 10*k), m, analyticsAt(0, 14, 10*k))
		}
		planID := uuid.NewString()
		analyticsExec(t, db, `INSERT INTO matching.match_date_plans(id, match_id, proposer_user_id, invitee_user_id, status, window_start, window_end, venue_category, created_at)
			VALUES ($1, $2, $3, $4, 'accepted', NOW() - INTERVAL '30 minutes', NOW() + INTERVAL '1 hour', 'coffee', $5)`,
			planID, matchID, w, m, analyticsAt(1, 9, 0))
		analyticsExec(t, db, `INSERT INTO matching.match_date_plan_events(plan_id, actor_user_id, event_type, from_status, to_status, created_at)
			VALUES ($1, $2, 'accepted', 'proposed', 'accepted', $3)`, planID, m, analyticsAt(1, 10, 0))
		analyticsExec(t, db, `INSERT INTO matching.match_date_plan_debriefs(plan_id, user_id, happened, created_at) VALUES ($1, $2, TRUE, $3)`,
			planID, w, analyticsAt(2, 9, 0))
		// An entertainment action on a day without a new match: a good day.
		analyticsExec(t, db, `INSERT INTO matching.friend_request_sends(requester_id, recipient_id, source, created_at) VALUES ($1, $2, 'search', $3)`,
			w, f.women[5], analyticsAt(3, 18, 0))
	}
	analyticsExec(t, db, `INSERT INTO matching.moderation_reports(reporter_user_id, reported_user_id, reason, created_at, reviewed_at, review_deadline_at, status)
		VALUES ($1, $2, 'harassment', $3, $4, $5, 'reviewed')`, f.women[5], f.men[5], analyticsAt(2, 8, 0), analyticsAt(2, 10, 0), analyticsAt(3, 8, 0))
	// Session-only activity: no product action, still an active day.
	session := func(id string, at time.Time) {
		token, refresh := make([]byte, 32), make([]byte, 32)
		_, _ = rand.Read(token)
		_, _ = rand.Read(refresh)
		analyticsExec(t, db, `INSERT INTO user_management.auth_sessions(user_id, access_token_hash, refresh_token_hash, access_expires_at, refresh_expires_at, created_at, last_used_at)
			VALUES ($1, $2, $3, $5, $6, $4, $4)`, id, token, refresh, at, at.Add(time.Hour), at.Add(48*time.Hour))
	}
	for i := 0; i < 3; i++ {
		session(f.women[i], analyticsAt(7, 9, 0))
		session(f.men[i], analyticsAt(7, 9, 0))
	}
	for i := 0; i < 5; i++ {
		session(f.women[i], analyticsAt(30, 9, 0))
	}
	return f
}

func (f *analyticsFixture) rebuild(t *testing.T) analyticsSnapshotRun {
	t.Helper()
	worker := newAnalyticsSnapshotWorker(f.db, nil, 0)
	// Through day 35 so the fifth cohort week (days 28-34) is fully observed.
	run, err := worker.Rebuild(context.Background(), analyticsDay0, analyticsDay0.AddDate(0, 0, 35), "test")
	if err != nil {
		t.Fatalf("rebuild: %v", err)
	}
	return run
}

func (f *analyticsFixture) get(t *testing.T, handler http.HandlerFunc, path string, status int) *httptest.ResponseRecorder {
	t.Helper()
	req := httptest.NewRequest(http.MethodGet, path, nil)
	req = req.WithContext(context.WithValue(req.Context(), securityPrincipalContextKey{},
		securityPrincipal{UserID: uuid.NewString(), Roles: map[string]bool{"analyst": true}}))
	rec := httptest.NewRecorder()
	handler(rec, req)
	if rec.Code != status {
		t.Fatalf("GET %s: expected %d got %d: %s", path, status, rec.Code, rec.Body.String())
	}
	return rec
}

type analyticsBody struct {
	Tables map[string]struct {
		Rows []map[string]any `json:"rows"`
	} `json:"tables"`
}

func (f *analyticsFixture) rows(t *testing.T, handler http.HandlerFunc, path, table string) []map[string]any {
	t.Helper()
	rec := f.get(t, handler, path, http.StatusOK)
	var body analyticsBody
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatalf("decode %s: %v", path, err)
	}
	return body.Tables[table].Rows
}

func (f *analyticsFixture) q(extra string) string {
	return "city=" + strings.ReplaceAll(f.city, " ", "%20") + extra
}

func analyticsDayParam(offset int) string {
	return analyticsDay0.AddDate(0, 0, offset).Format(time.DateOnly)
}

func analyticsWantValue(t *testing.T, label string, got any, want float64) {
	t.Helper()
	n, ok := analyticsNumber(got)
	if !ok || n != want {
		t.Fatalf("%s: got %v want %v", label, got, want)
	}
}

func analyticsWantSuppressed(t *testing.T, label string, row map[string]any, key string) {
	t.Helper()
	if row[key] != nil {
		t.Fatalf("%s: %s should be withheld, got %v", label, key, row[key])
	}
	list, _ := row["suppressed"].([]any)
	for _, k := range list {
		if k == key {
			return
		}
	}
	t.Fatalf("%s: %s not listed as suppressed in %v", label, key, row["suppressed"])
}

func analyticsFindRow(t *testing.T, rows []map[string]any, key, value string) map[string]any {
	t.Helper()
	for _, row := range rows {
		if fmt.Sprint(row[key]) == value {
			return row
		}
	}
	t.Fatalf("no row with %s=%s in %v", key, value, rows)
	return nil
}

func TestAnalyticsSnapshotsAndReportsPostgres(t *testing.T) {
	f := newAnalyticsFixture(t)
	run := f.rebuild(t)
	if run.DaysBuilt != 36 {
		t.Fatalf("expected 36 days built, got %d", run.DaysBuilt)
	}
	s := f.server

	t.Run("backfill derives active days from durable timestamps", func(t *testing.T) {
		var actions, sessions int
		if err := f.db.QueryRow(`SELECT COUNT(*) FILTER (WHERE a.day = $2 AND a.source = 'action'),
			COUNT(*) FILTER (WHERE a.day = $3)
			FROM analytics.member_active_days a JOIN user_management.users u ON u.id = a.user_id
			WHERE u.city = $1`, f.city, analyticsDay0, analyticsDay0.AddDate(0, 0, 7)).Scan(&actions, &sessions); err != nil {
			t.Fatal(err)
		}
		// 14 reportable + 3 excluded members acted on day 0; raw rows keep everyone.
		if actions != 17 || sessions != 6 {
			t.Fatalf("active days: day0 actions=%d (want 17), day7=%d (want 6)", actions, sessions)
		}
	})

	t.Run("exclusions and segment filters", func(t *testing.T) {
		rows := f.rows(t, s.adminAnalyticsTrends, "/v1/admin/analytics/trends?metric=signups&from="+analyticsDayParam(0)+"&to="+analyticsDayParam(0)+"&"+f.q(""), "series")
		analyticsWantValue(t, "signups (operator, test and flagged accounts excluded)", rows[0]["value"], 14)
		rows = f.rows(t, s.adminAnalyticsTrends, "/v1/admin/analytics/trends?metric=likes&from="+analyticsDayParam(0)+"&to="+analyticsDayParam(0)+"&"+f.q(""), "series")
		analyticsWantValue(t, "likes", rows[0]["value"], 12)
		rows = f.rows(t, s.adminAnalyticsTrends, "/v1/admin/analytics/trends?metric=signups&gender=female&age_band=25-29&level_band=L1-L3&account_age_band=day_0&from="+analyticsDayParam(0)+"&to="+analyticsDayParam(0)+"&"+f.q(""), "series")
		analyticsWantValue(t, "female signups", rows[0]["value"], 6)
		rows = f.rows(t, s.adminAnalyticsTrends, "/v1/admin/analytics/trends?metric=signups&group_by=gender&from="+analyticsDayParam(0)+"&to="+analyticsDayParam(0)+"&"+f.q(""), "series")
		analyticsWantValue(t, "male signups", analyticsFindRow(t, rows, "segment", "male")["value"], 6)
		analyticsWantSuppressed(t, "other signups (2)", analyticsFindRow(t, rows, "segment", "other"), "value")
		rows = f.rows(t, s.adminAnalyticsTrends, "/v1/admin/analytics/trends?metric=matches&from="+analyticsDayParam(0)+"&to="+analyticsDayParam(0)+"&"+f.q(""), "series")
		analyticsWantValue(t, "match participations", rows[0]["value"], 12)
		rows = f.rows(t, s.adminAnalyticsTrends, "/v1/admin/analytics/trends?metric=wau&grain=week&from="+analyticsDayParam(0)+"&to="+analyticsDayParam(6)+"&"+f.q(""), "series")
		analyticsWantValue(t, "WAU at the end of week 0", rows[0]["value"], 14)
		rows = f.rows(t, s.adminAnalyticsTrends, "/v1/admin/analytics/trends?metric=dau&grain=week&from="+analyticsDayParam(0)+"&to="+analyticsDayParam(6)+"&"+f.q(""), "series")
		analyticsWantValue(t, "average DAU over week 0 (35 member-days / 7)", rows[0]["value"], 5)
		f.get(t, s.adminAnalyticsTrends, "/v1/admin/analytics/trends?metric=nope", http.StatusBadRequest)
		f.get(t, s.adminAnalyticsTrends, "/v1/admin/analytics/trends?gender=robot", http.StatusBadRequest)
		f.get(t, s.adminAnalyticsTrends, "/v1/admin/analytics/trends?from=2026-01-01&to=2020-01-01", http.StatusBadRequest)
	})

	t.Run("kpis and north star", func(t *testing.T) {
		rows := f.rows(t, s.adminAnalyticsKPIs, "/v1/admin/analytics/kpis?as_of="+analyticsDayParam(6)+"&"+f.q(""), "tiles")
		analyticsWantValue(t, "WAU", analyticsFindRow(t, rows, "key", "wau")["value"], 14)
		analyticsWantValue(t, "MAU", analyticsFindRow(t, rows, "key", "mau")["value"], 14)
		analyticsWantValue(t, "new members", analyticsFindRow(t, rows, "key", "new_members")["value"], 14)
		analyticsWantValue(t, "plans kept per active member", analyticsFindRow(t, rows, "key", "plans_kept_per_active_member")["value"], 0.3571)
		analyticsWantValue(t, "women's good-day rate", analyticsFindRow(t, rows, "key", "womens_good_day_rate")["value"], 83.3333)
		analyticsWantValue(t, "matches per active member", analyticsFindRow(t, rows, "key", "matches_per_active_member")["value"], 0.8571)
		analyticsWantSuppressed(t, "reports per 1k (1 report)", analyticsFindRow(t, rows, "key", "reports_per_1k_dau"), "value")
		rows = f.rows(t, s.adminAnalyticsKPIs, "/v1/admin/analytics/kpis?as_of="+analyticsDayParam(6)+"&gender=male&"+f.q(""), "tiles")
		for _, row := range rows {
			if row["key"] == "womens_good_day_rate" {
				t.Fatal("the women's rate cannot apply to a male-only segment")
			}
		}
	})

	t.Run("activation funnel", func(t *testing.T) {
		rows := f.rows(t, s.adminAnalyticsFunnel, "/v1/admin/analytics/funnel?cohort=all&from="+analyticsDayParam(0)+"&to="+analyticsDayParam(0)+"&"+f.q(""), "steps")
		want := map[string]float64{"signup": 14, "terms": 12, "profile_complete": 12, "verified": 12, "first_like": 12,
			"first_match": 12, "first_message": 11, "two_way": 10, "plan_accepted": 10, "date_kept": 10}
		for step, n := range want {
			analyticsWantValue(t, step, analyticsFindRow(t, rows, "step", step)["members"], n)
		}
		firstMessage := analyticsFindRow(t, rows, "step", "first_message")
		analyticsWantValue(t, "first message from previous", firstMessage["conversion_from_previous"], 91.6667)
		analyticsWantValue(t, "date kept from signup", analyticsFindRow(t, rows, "step", "date_kept")["conversion_from_signup"], 71.4286)
		analyticsWantValue(t, "median hours signup to first match", analyticsFindRow(t, rows, "step", "first_match")["median_hours_from_signup"], 2)
		analyticsWantValue(t, "median hours profile to verified", analyticsFindRow(t, rows, "step", "verified")["median_hours_from_previous"], 0.33)
		rows = f.rows(t, s.adminAnalyticsFunnel, "/v1/admin/analytics/funnel?cohort=week&within_days=1&from="+analyticsDayParam(0)+"&to="+analyticsDayParam(0)+"&"+f.q(""), "steps")
		analyticsWantValue(t, "plan accepted within a day", analyticsFindRow(t, rows, "step", "plan_accepted")["members"], 10)
		analyticsWantValue(t, "date kept within a day", analyticsFindRow(t, rows, "step", "date_kept")["members"], 0)
		if rows[0]["cohort"] != analyticsDayParam(0) {
			t.Fatalf("weekly cohort should start on the Monday %s, got %v", analyticsDayParam(0), rows[0]["cohort"])
		}
	})

	t.Run("retention cohorts", func(t *testing.T) {
		rows := f.rows(t, s.adminAnalyticsRetention, "/v1/admin/analytics/retention?grain=day&from="+analyticsDayParam(0)+"&to="+analyticsDayParam(0)+"&"+f.q(""), "summary")
		if len(rows) != 1 {
			t.Fatalf("one daily cohort expected, got %v", rows)
		}
		analyticsWantValue(t, "cohort size", rows[0]["members"], 14)
		analyticsWantValue(t, "D1", rows[0]["d1"], 71.4286)
		analyticsWantValue(t, "D7", rows[0]["d7"], 42.8571)
		analyticsWantValue(t, "D30", rows[0]["d30"], 35.7143)
		triangle := f.rows(t, s.adminAnalyticsRetention, "/v1/admin/analytics/retention?from="+analyticsDayParam(0)+"&to="+analyticsDayParam(0)+"&"+f.q(""), "triangle")
		analyticsWantValue(t, "week 0", triangle[0]["week_0"], 100)
		analyticsWantValue(t, "week 1", triangle[0]["week_1"], 42.8571)
		analyticsWantValue(t, "week 2", triangle[0]["week_2"], 0)
		analyticsWantValue(t, "week 4", triangle[0]["week_4"], 35.7143)
		f.get(t, s.adminAnalyticsRetention, "/v1/admin/analytics/retention?experiment=DROP%20TABLE", http.StatusBadRequest)
	})

	t.Run("feature engagement", func(t *testing.T) {
		rows := f.rows(t, s.adminAnalyticsEngagement, "/v1/admin/analytics/engagement?from="+analyticsDayParam(0)+"&to="+analyticsDayParam(6)+"&"+f.q(""), "surfaces")
		plans := analyticsFindRow(t, rows, "surface", "date_plans")
		analyticsWantValue(t, "date plan users", plans["users"], 10)
		analyticsWantValue(t, "date plan actions", plans["actions"], 15)
		analyticsWantValue(t, "date plan repeat use", plans["repeat_rate"], 50)
		analyticsWantValue(t, "date plan member-day share", plans["dau_share"], 42.8571) // 15 member-days of 35
		chat := analyticsFindRow(t, rows, "surface", "chat")
		analyticsWantValue(t, "chat users", chat["users"], 11)
		analyticsWantValue(t, "chat actions", chat["actions"], 31)
		analyticsWantValue(t, "friends reach", analyticsFindRow(t, rows, "surface", "friends")["reach"], 35.7143)
		analyticsWantSuppressed(t, "safety tool users (1)", analyticsFindRow(t, rows, "surface", "safety"), "users")
		analyticsWantValue(t, "rooms unused", analyticsFindRow(t, rows, "surface", "rooms")["users"], 0)
	})

	t.Run("liquidity by city", func(t *testing.T) {
		rows := f.rows(t, s.adminAnalyticsLiquidity, "/v1/admin/analytics/liquidity?from="+analyticsDayParam(0)+"&to="+analyticsDayParam(6)+"&"+f.q(""), "cities")
		if len(rows) != 1 {
			t.Fatalf("expected one city, got %v", rows)
		}
		row := rows[0]
		analyticsWantValue(t, "active", row["active_members"], 14)
		analyticsWantValue(t, "women per man", row["women_per_man"], 1)
		analyticsWantValue(t, "matches per active member", row["matches_per_active_member"], 0.8571)
		analyticsWantSuppressed(t, "other or not stated (2)", row, "other_or_unknown")
	})

	t.Run("safety health", func(t *testing.T) {
		rows := f.rows(t, s.adminAnalyticsSafety, "/v1/admin/analytics/safety?from="+analyticsDayParam(0)+"&to="+analyticsDayParam(6)+"&"+f.q(""), "trend")
		analyticsWantValue(t, "active member-days", rows[0]["active_member_days"], 35)
		analyticsWantSuppressed(t, "reports (1)", rows[0], "reports_filed")
		analyticsWantSuppressed(t, "reports per 1k", rows[0], "reports_per_1k_dau")
		queues := f.rows(t, s.adminAnalyticsSafety, "/v1/admin/analytics/safety?from="+analyticsDayParam(0)+"&to="+analyticsDayParam(6)+"&"+f.q(""), "queues")
		analyticsWantSuppressed(t, "queue median with one report", analyticsFindRow(t, queues, "queue", "member_reports"), "median_hours_to_action")
	})

	t.Run("csv export is streamed with suppression", func(t *testing.T) {
		rec := f.get(t, s.adminAnalyticsTrends, "/v1/admin/analytics/trends?metric=signups&group_by=gender&format=csv&from="+analyticsDayParam(0)+"&to="+analyticsDayParam(0)+"&"+f.q(""), http.StatusOK)
		if ct := rec.Header().Get("Content-Type"); !strings.HasPrefix(ct, "text/csv") {
			t.Fatalf("content type %q", ct)
		}
		body := rec.Body.String()
		if !strings.HasPrefix(body, "period,segment,value\n") || !strings.Contains(body, analyticsDayParam(0)+",other,<5") ||
			!strings.Contains(body, analyticsDayParam(0)+",female,6") {
			t.Fatalf("unexpected csv:\n%s", body)
		}
		rec = f.get(t, s.adminAnalyticsSafety, "/v1/admin/analytics/safety?format=csv&table=by_surface&from="+analyticsDayParam(0)+"&to="+analyticsDayParam(6)+"&"+f.q(""), http.StatusOK)
		if !strings.HasPrefix(rec.Body.String(), "surface,surface_label,reports,interactions,reports_per_1k_interactions\n") {
			t.Fatalf("unexpected safety csv:\n%s", rec.Body.String())
		}
		f.get(t, s.adminAnalyticsSafety, "/v1/admin/analytics/safety?format=csv&table=nope", http.StatusBadRequest)
	})

	t.Run("rebuild is idempotent", func(t *testing.T) {
		fingerprint := func() string {
			var out string
			if err := f.db.QueryRow(`SELECT COALESCE(md5(string_agg(day::text || metric || gender || city || age_band || account_age_band || level_band || value::text, ',' ORDER BY day, metric, gender, city, age_band, account_age_band, level_band)), '')
				|| ':' || (SELECT COUNT(*) FROM analytics.member_surface_days WHERE day BETWEEN $1 AND $2)
				|| ':' || (SELECT COUNT(*) FROM analytics.member_active_days WHERE day BETWEEN $1 AND $2)
				FROM analytics.daily_metrics WHERE day BETWEEN $1 AND $2`, analyticsDay0, analyticsDay0.AddDate(0, 0, 35)).Scan(&out); err != nil {
				t.Fatal(err)
			}
			return out
		}
		before := fingerprint()
		f.rebuild(t)
		if after := fingerprint(); after != before {
			t.Fatalf("a second rebuild changed the snapshot: %s -> %s", before, after)
		}
		var runs int
		if err := f.db.QueryRow(`SELECT COUNT(*) FROM analytics.snapshot_runs WHERE from_day = $1 AND status = 'succeeded'`, analyticsDay0).Scan(&runs); err != nil || runs != 2 {
			t.Fatalf("expected two succeeded runs, got %d (%v)", runs, err)
		}
	})

	t.Run("concurrent runs are refused while the lock is held", func(t *testing.T) {
		worker := newAnalyticsSnapshotWorker(f.db, nil, 0)
		conn, err := worker.lockedConn(context.Background())
		if err != nil {
			t.Fatal(err)
		}
		_, err = worker.Rebuild(context.Background(), analyticsDay0, analyticsDay0, "test")
		releaseAnalyticsLock(conn)
		if err != errAnalyticsSnapshotBusy {
			t.Fatalf("expected busy, got %v", err)
		}
	})

	t.Run("flagging a test account applies to member-level reports at once", func(t *testing.T) {
		admin := securityPrincipal{UserID: uuid.NewString(), Roles: map[string]bool{"admin": true}}
		req := httptest.NewRequest(http.MethodPost, "/v1/admin/analytics/excluded-accounts",
			strings.NewReader(`{"member_id":"`+f.women[5]+`","reason":"QA phone"}`))
		req = req.WithContext(context.WithValue(req.Context(), securityPrincipalContextKey{}, admin))
		rec := httptest.NewRecorder()
		s.adminAnalyticsExcludeAccount(rec, req)
		if rec.Code != http.StatusOK {
			t.Fatalf("flag: %d %s", rec.Code, rec.Body.String())
		}
		rows := f.rows(t, s.adminAnalyticsRetention, "/v1/admin/analytics/retention?grain=day&from="+analyticsDayParam(0)+"&to="+analyticsDayParam(0)+"&"+f.q(""), "summary")
		analyticsWantValue(t, "cohort without the flagged member", rows[0]["members"], 13)
		del := httptest.NewRequest(http.MethodDelete, "/v1/admin/analytics/excluded-accounts/"+f.women[5], nil)
		rc := chi.NewRouteContext()
		rc.URLParams.Add("memberID", f.women[5])
		del = del.WithContext(context.WithValue(context.WithValue(del.Context(), chi.RouteCtxKey, rc), securityPrincipalContextKey{}, admin))
		rec = httptest.NewRecorder()
		s.adminAnalyticsIncludeAccount(rec, del)
		if rec.Code != http.StatusOK {
			t.Fatalf("unflag: %d %s", rec.Code, rec.Body.String())
		}
		// An analyst cannot flag accounts even if the route matrix were bypassed.
		req = httptest.NewRequest(http.MethodPost, "/v1/admin/analytics/excluded-accounts", strings.NewReader(`{}`))
		req = req.WithContext(context.WithValue(req.Context(), securityPrincipalContextKey{}, securityPrincipal{UserID: "a", Roles: map[string]bool{"analyst": true}}))
		rec = httptest.NewRecorder()
		s.adminAnalyticsExcludeAccount(rec, req)
		if rec.Code != http.StatusForbidden {
			t.Fatalf("analyst flagged an account: %d", rec.Code)
		}
	})

	t.Run("snapshot status", func(t *testing.T) {
		rec := f.get(t, s.adminAnalyticsSnapshots, "/v1/admin/analytics/snapshots", http.StatusOK)
		var body map[string]any
		_ = json.Unmarshal(rec.Body.Bytes(), &body)
		exclusions, _ := body["exclusions"].(map[string]any)
		for _, reason := range []string{"operator_account", "flagged_test_account", "test_username"} {
			if n, _ := analyticsNumber(exclusions[reason]); n < 1 {
				t.Fatalf("exclusion %s not reported: %v", reason, exclusions)
			}
		}
	})
}

func TestAnalyticsRebuildRunsInBackgroundPostgres(t *testing.T) {
	f := newAnalyticsFixture(t)
	req := httptest.NewRequest(http.MethodPost, "/v1/admin/analytics/snapshots/rebuild",
		strings.NewReader(`{"from":"`+analyticsDayParam(0)+`","to":"`+analyticsDayParam(2)+`"}`))
	req = req.WithContext(context.WithValue(req.Context(), securityPrincipalContextKey{},
		securityPrincipal{UserID: uuid.NewString(), Roles: map[string]bool{"admin": true}}))
	rec := httptest.NewRecorder()
	f.server.adminAnalyticsRebuild(rec, req)
	if rec.Code != http.StatusAccepted {
		t.Fatalf("rebuild: %d %s", rec.Code, rec.Body.String())
	}
	var body map[string]any
	_ = json.Unmarshal(rec.Body.Bytes(), &body)
	deadline := time.Now().Add(60 * time.Second)
	for {
		var status string
		if err := f.db.QueryRow(`SELECT status FROM analytics.snapshot_runs WHERE id = $1`, body["run_id"]).Scan(&status); err != nil {
			t.Fatal(err)
		}
		if status == "succeeded" {
			break
		}
		if status == "failed" || time.Now().After(deadline) {
			t.Fatalf("rebuild ended as %s", status)
		}
		time.Sleep(200 * time.Millisecond)
	}
	var signups int64
	if err := f.db.QueryRow(`SELECT COALESCE(SUM(value), 0) FROM analytics.daily_metrics WHERE day = $1 AND metric = 'signups' AND city = analytics.normalize_city($2)`,
		analyticsDay0, f.city).Scan(&signups); err != nil || signups != 14 {
		t.Fatalf("signups after background rebuild: %d (%v)", signups, err)
	}
	for _, payload := range []string{`{"from":"2001-01-01","to":"2999-01-01"}`, `{"from":"x","to":"2001-01-01"}`, `{"from":"2001-03-05","to":"2001-03-01"}`} {
		req := httptest.NewRequest(http.MethodPost, "/v1/admin/analytics/snapshots/rebuild", strings.NewReader(payload))
		req = req.WithContext(context.WithValue(req.Context(), securityPrincipalContextKey{},
			securityPrincipal{UserID: uuid.NewString(), Roles: map[string]bool{"admin": true}}))
		rec := httptest.NewRecorder()
		f.server.adminAnalyticsRebuild(rec, req)
		if rec.Code != http.StatusBadRequest {
			t.Fatalf("%s: expected 400, got %d", payload, rec.Code)
		}
	}
}

func TestAnalyticsReportAccessByRole(t *testing.T) {
	for _, tc := range []struct {
		role, method, path string
		want               bool
	}{
		{"analyst", http.MethodGet, "/v1/admin/analytics/kpis", true},
		{"analyst", http.MethodGet, "/v1/admin/analytics/retention", true},
		{"analyst", http.MethodGet, "/v1/admin/analytics/snapshots", true},
		{"analyst", http.MethodPost, "/v1/admin/analytics/snapshots/rebuild", false},
		{"analyst", http.MethodGet, "/v1/admin/analytics/excluded-accounts", false},
		{"analyst", http.MethodGet, "/v1/admin/analytics/overview", true},
		{"admin", http.MethodPost, "/v1/admin/analytics/snapshots/rebuild", true},
		{"admin", http.MethodDelete, "/v1/admin/analytics/excluded-accounts/x", true},
		{"trust_safety", http.MethodGet, "/v1/admin/analytics/kpis", false},
		{"trust_safety", http.MethodGet, "/v1/admin/analytics/overview", true},
		{"ops_admin", http.MethodGet, "/v1/admin/analytics/funnel", false},
		{"moderator", http.MethodGet, "/v1/admin/analytics/safety", false},
		{"user", http.MethodGet, "/v1/admin/analytics/kpis", false},
	} {
		got := principalCanAccessAdminRoute(securityPrincipal{Roles: map[string]bool{tc.role: true, "user": true}}, "/v1", tc.method, tc.path)
		if got != tc.want {
			t.Errorf("%s %s %s: got %v want %v", tc.role, tc.method, tc.path, got, tc.want)
		}
	}

	// Through the real middleware: an analyst session reaches the report, a
	// member session is refused before the handler runs.
	s := &Server{cfg: config.Config{APIPrefix: "/v1"}}
	reached := false
	handler := s.securityMiddleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		reached = true
		w.WriteHeader(http.StatusOK)
	}))
	for _, tc := range []struct {
		role string
		want int
	}{{"analyst", http.StatusOK}, {"user", http.StatusForbidden}} {
		roles := map[string]bool{"user": true, tc.role: true}
		testPrincipalResolver = func(r *http.Request) (securityPrincipal, error) {
			return securityPrincipal{SessionID: "s", UserID: "11111111-1111-1111-1111-111111111111", Roles: roles}, nil
		}
		reached = false
		rec := httptest.NewRecorder()
		handler.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/v1/admin/analytics/kpis", nil))
		testPrincipalResolver = nil
		if rec.Code != tc.want || reached != (tc.want == http.StatusOK) {
			t.Fatalf("%s: status %d reached %v", tc.role, rec.Code, reached)
		}
	}

	// The per-member runtime view is for support operators, not members.
	if !pathOwnedByPrincipal("/v1", "/v1/analytics/someone-else", http.MethodGet, "me") {
		t.Fatal("ownership no longer guards /v1/analytics; the handler does")
	}
	req := httptest.NewRequest(http.MethodGet, "/v1/analytics/me", nil)
	rc := chi.NewRouteContext()
	rc.URLParams.Add("userID", "me")
	req = req.WithContext(context.WithValue(context.WithValue(req.Context(), chi.RouteCtxKey, rc), securityPrincipalContextKey{},
		securityPrincipal{UserID: "me", Roles: map[string]bool{"user": true}}))
	rec := httptest.NewRecorder()
	(&Server{}).userAnalytics(rec, req)
	if rec.Code != http.StatusForbidden {
		t.Fatalf("member read the support view: %d", rec.Code)
	}
}

func TestAnalyticsSuppressionAndCSVSafety(t *testing.T) {
	cols := []analyticsColumn{
		{Key: "city", Kind: "dimension"},
		{Key: "n", Kind: "count"},
		{Key: "d", Kind: "count"},
		{Key: "share", Kind: "ratio", Num: "n", Den: "d", Scale: 100},
		{Key: "median", Kind: "median", Support: "n"},
	}
	row := finalizeAnalyticsRow(cols, analyticsRaw{"city": "=HYPERLINK(1)", "n": int64(4), "d": int64(10), "median": 3.0})
	if row["n"] != nil || row["share"] != nil || row["median"] != nil {
		t.Fatalf("small counts leaked: %v", row)
	}
	if got := analyticsCSVCell(row, "n"); got != "<5" {
		t.Fatalf("suppressed cell: %q", got)
	}
	if got := analyticsCSVCell(row, "city"); got != "'=HYPERLINK(1)" {
		t.Fatalf("formula not neutralised: %q", got)
	}
	row = finalizeAnalyticsRow(cols, analyticsRaw{"n": int64(0), "d": int64(0)})
	if row["n"] != int64(0) || row["share"] != nil || len(row["suppressed"].([]string)) != 0 {
		t.Fatalf("zero is not small and 0/0 is empty, not suppressed: %v", row)
	}
	row = finalizeAnalyticsRow(cols, analyticsRaw{"n": int64(5), "d": int64(20), "median": 1.234})
	if row["share"] != 25.0 && row["share"] != int64(25) {
		t.Fatalf("share: %v", row["share"])
	}
	if row["median"] != 1.23 {
		t.Fatalf("median: %v", row["median"])
	}
	if !dayIsFinal(analyticsDay0, analyticsDay0.AddDate(0, 0, 2)) || dayIsFinal(analyticsDay0, analyticsDay0.AddDate(0, 0, 1).Add(23*time.Hour)) {
		t.Fatal("a day is final once a full day has passed after it ended")
	}
}
