package mobile

import (
	"context"
	"database/sql"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/verified-dating/backend/internal/platform/config"
)

// Postgres-backed checks for the paged admin lists: every endpoint's SQL runs
// against the real schema and answers with total, limit and offset, and the
// activity list's filters, search escaping, date range and paging return the
// exact rows. They skip without PROFILE_TEST_DATABASE_URL.

func adminPagingServer(t *testing.T, db *sql.DB) *Server {
	t.Helper()
	cfg := config.Config{
		APIPrefix: "/v1", MatchingSchema: "matching", UserSchema: "user_management",
		GiftCatalogTable: "gift_catalog", BFFRequestTimeoutSec: 10,
	}
	return &Server{
		cfg: cfg,
		store: &runtimeStore{
			cfg:         cfg,
			profileRepo: &profileRepository{cfg: cfg, pg: db},
			adminRepo:   &adminRepository{cfg: cfg, pg: db},
			safetyRepo:  &safetyRepository{cfg: cfg, pg: db},
			billingRepo: newBillingRepository(db),
		},
		progression: &levelProgressionRepository{db: db},
	}
}

func callAdminList(t *testing.T, handler http.HandlerFunc, target string) (int, map[string]any) {
	t.Helper()
	req := httptest.NewRequest(http.MethodGet, target, nil)
	admin := securityPrincipal{UserID: "00000000-0000-4000-8000-000000000001", Roles: map[string]bool{"admin": true}}
	req = req.WithContext(context.WithValue(req.Context(), securityPrincipalContextKey{}, admin))
	rec := httptest.NewRecorder()
	handler(rec, req)
	body := map[string]any{}
	_ = json.Unmarshal(rec.Body.Bytes(), &body)
	return rec.Code, body
}

func TestAdminListEndpointsPagePostgres(t *testing.T) {
	db := trustOpsDB(t)
	s := adminPagingServer(t, db)
	const window = "&from=2020-01-01&to=2099-12-31&q=a&order=asc"
	cases := []struct {
		name    string
		handler http.HandlerFunc
		path    string
		key     string
	}{
		{"activities", s.listAdminActivities, "/v1/admin/activities?exclude_domain=api_request&sort=created_at", "activities"},
		{"verifications", s.listAdminVerifications, "/v1/admin/verifications?sort=updated_at", "verifications"},
		{"reports", s.listAdminReports, "/v1/admin/moderation/reports?category=harassment", "reports"},
		{"appeals", s.listAdminModerationAppeals, "/v1/admin/moderation/appeals?sort=sla_deadline_at", "appeals"},
		{"media", s.listAdminMediaModeration, "/v1/admin/moderation/media?status=review_required", "items"},
		{"sos", s.adminListSOSAlerts, "/v1/admin/safety/sos-alerts?status=active", "alerts"},
		{"recovery", s.adminListAccountRecoveryRequests, "/v1/admin/safety/account-recovery?status=open", "requests"},
		{"audit", s.adminListAuditEvents, "/v1/admin/audit-events?actor_user_id=not-a-uuid", "events"},
		{"domain events", s.adminListDomainEvents, "/v1/admin/events?actor_user_id=00000000-0000-4000-8000-000000000001", "events"},
		{"fraud graph", s.adminListFraudGraph, "/v1/admin/growth/fraud-graph?sort=created_at", "edges"},
		{"economy fraud", s.adminListEconomyFraudCases, "/v1/admin/billing/fraud/cases?status=all&sort=severity", "cases"},
		{"progression fraud", s.adminListProgressionFraud, "/v1/admin/progression/fraud?sort=created_at", "cases"},
		{"gifts", s.adminListCatalogGifts, "/v1/admin/catalog/gifts?active=yes&sort=price_coins", "gifts"},
		{"prompts", s.adminListEngagementPrompts, "/v1/admin/engagement/prompts?active=no", "prompts"},
		{"nudges", s.adminListEngagementNudges, "/v1/admin/engagement/nudges?clicked=no", "nudges"},
		{"transactions", s.adminListBillingTransactions, "/v1/admin/billing/transactions?sort=amount_minor", "transactions"},
		{"subscriptions", s.adminListSubscriptions, "/v1/admin/billing/subscriptions?sort=current_period_end", "subscriptions"},
		{"payments", s.adminListPayments, "/v1/admin/billing/payments?sort=paid_at", "payments"},
		{"webhook events", s.adminListBillingWebhookEvents, "/v1/admin/billing/webhook-events?sort=event_created_at", "events"},
		{"group covers", s.adminGroupCoversHandler, "/v1/admin/moderation/group-covers?status=approved", "items"},
		{"blog cases", s.blogReviewHandler, "/v1/admin/moderation/blog?status=pending&sort=created_at", "cases"},
		{"photo themes", s.adminPhotoThemesHandler, "/v1/admin/engagement/photo-themes?status=active", "themes"},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			for _, query := range []string{"", "&limit=2&offset=1" + window} {
				code, body := callAdminList(t, tc.handler, tc.path+query)
				if code != http.StatusOK {
					t.Fatalf("%s: code=%d body=%v", query, code, body)
				}
				if body["note"] != nil || body["error"] != nil {
					t.Fatalf("%s: query failed: %v", query, body)
				}
				items, ok := body[tc.key].([]any)
				if !ok {
					t.Fatalf("%s: %q missing or not a list: %v", query, tc.key, body)
				}
				total, ok := body["total"].(float64)
				if !ok || int(total) < len(items) {
					t.Fatalf("%s: total=%v items=%d", query, body["total"], len(items))
				}
				if query != "" && (body["limit"] != float64(2) || body["offset"] != float64(1) || len(items) > 2) {
					t.Fatalf("%s: limit=%v offset=%v items=%d", query, body["limit"], body["offset"], len(items))
				}
			}
			if code, _ := callAdminList(t, tc.handler, tc.path+"&from=yesterday"); code != http.StatusBadRequest {
				t.Fatalf("malformed from: code=%d, want 400", code)
			}
		})
	}
}

func TestAdminActivitiesFiltersSearchAndPagePostgres(t *testing.T) {
	db := trustOpsDB(t)
	member, _ := seedTrustMember(t, db)
	other, _ := seedTrustMember(t, db)
	t.Cleanup(func() {
		_, _ = db.Exec(`DELETE FROM matching.activity_events WHERE user_id IN ($1,$2) OR actor_user_id IN ($1,$2)`, member, other)
	})
	insert := func(name, domain, userID, actorID, at string) {
		t.Helper()
		if _, err := db.Exec(`INSERT INTO matching.activity_events(event_name,event_domain,event_version,user_id,actor_user_id,source_service,payload,created_at)
			VALUES($1,$2,1,$3,NULLIF($4,'')::uuid,'test','{}'::jsonb,$5::timestamptz)`, name, domain, userID, actorID, at); err != nil {
			t.Fatalf("seed activity: %v", err)
		}
	}
	insert("qa.paging.100%_done", "qa_paging", member, "", "2026-09-01T08:00:00Z")
	insert("qa.paging.100x_done", "qa_paging", member, "", "2026-09-02T08:00:00Z")
	insert("GET /v1/qa", "api_request", member, "", "2026-09-03T08:00:00Z")
	insert("qa.paging.acted", "qa_paging", other, member, "2026-09-04T08:00:00Z")

	s := adminPagingServer(t, db)
	names := func(body map[string]any) string {
		out := []string{}
		for _, item := range body["activities"].([]any) {
			out = append(out, item.(map[string]any)["action"].(string))
		}
		return strings.Join(out, "|")
	}
	cases := []struct {
		name      string
		query     string
		want      string
		wantTotal float64
	}{
		{"member covers user and actor", "member=" + member, "qa.paging.acted|GET /v1/qa|qa.paging.100x_done|qa.paging.100%_done", 4},
		{"actor only", "actor_user_id=" + member, "qa.paging.acted", 1},
		{"exclude request telemetry", "member=" + member + "&exclude_domain=api_request", "qa.paging.acted|qa.paging.100x_done|qa.paging.100%_done", 3},
		{"percent and underscore match literally", "member=" + member + "&q=100%25_", "qa.paging.100%_done", 1},
		{"date range is inclusive UTC days", "member=" + member + "&from=2026-09-02&to=2026-09-03", "GET /v1/qa|qa.paging.100x_done", 2},
		{"ascending page", "member=" + member + "&order=asc&limit=2&offset=1", "qa.paging.100x_done|GET /v1/qa", 4},
		{"domain filter", "user_id=" + member + "&event_domain=qa_paging", "qa.paging.100x_done|qa.paging.100%_done", 2},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			code, body := callAdminList(t, s.listAdminActivities, "/v1/admin/activities?"+tc.query)
			if code != http.StatusOK {
				t.Fatalf("code=%d body=%v", code, body)
			}
			if got := names(body); got != tc.want || body["total"] != tc.wantTotal {
				t.Fatalf("got %q total=%v, want %q total=%v", got, body["total"], tc.want, tc.wantTotal)
			}
		})
	}
	if code, _ := callAdminList(t, s.listAdminActivities, "/v1/admin/activities?member=nope"); code != http.StatusBadRequest {
		t.Fatalf("malformed member: code=%d, want 400", code)
	}
}
