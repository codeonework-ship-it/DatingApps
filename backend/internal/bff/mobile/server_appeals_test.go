package mobile

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"go.uber.org/zap"

	"github.com/verified-dating/backend/internal/platform/config"
	"github.com/verified-dating/backend/internal/platform/observability"
)

func TestAppealSLADeadlineIsExactlyFortyEightHours(t *testing.T) {
	createdAt := "2026-08-03T10:00:00Z"
	deadline, err := time.Parse(time.RFC3339, calculateAppealSLADeadline(createdAt))
	if err != nil {
		t.Fatal(err)
	}
	created, _ := time.Parse(time.RFC3339, createdAt)
	if got := deadline.Sub(created); got != 48*time.Hour {
		t.Fatalf("appeal SLA = %s, want 48h", got)
	}
	if got := sosDeadline("high"); got != 5*time.Minute {
		t.Fatalf("high-priority SOS SLA = %s, want 5m", got)
	}
}

func TestServer_ModerationAppealFlow_SubmitGetAndAdminResolve(t *testing.T) {
	installOperatorPrincipal(t, "user-appeal-1", "admin")
	server := newAppealsTestServer(t)
	defer server.Close()

	submitBody := `{
		"user_id": "user-appeal-1",
		"report_id": "rep-1",
		"reason": "unfair moderation rejection",
		"description": "context was not abusive"
	}`
	submitReq := httptest.NewRequest(http.MethodPost, "/v1/moderation/appeals", strings.NewReader(submitBody))
	submitReq.Header.Set("Content-Type", "application/json")
	submitRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(submitRec, submitReq)
	if submitRec.Code != http.StatusOK {
		t.Fatalf("submit moderation appeal code=%d body=%s", submitRec.Code, submitRec.Body.String())
	}

	submitPayload := decodeJSONMap(t, submitRec.Body.Bytes())
	appeal := toMap(t, submitPayload["appeal"])
	appealID := stringValue(appeal["id"])
	if appealID == "" {
		t.Fatalf("expected appeal id in submit payload")
	}
	if got := stringValue(appeal["status"]); got != appealStatusSubmitted {
		t.Fatalf("expected appeal status %q, got %q", appealStatusSubmitted, got)
	}
	if got := stringValue(appeal["sla_deadline_at"]); got == "" {
		t.Fatalf("expected sla_deadline_at for submitted appeal")
	}

	listReq := httptest.NewRequest(http.MethodGet, "/v1/moderation/appeals?user_id=user-appeal-1", nil)
	listRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(listRec, listReq)
	if listRec.Code != http.StatusOK {
		t.Fatalf("list moderation appeals code=%d body=%s", listRec.Code, listRec.Body.String())
	}
	listPayload := decodeJSONMap(t, listRec.Body.Bytes())
	listItems, ok := listPayload["appeals"].([]any)
	if !ok || len(listItems) == 0 {
		t.Fatalf("expected non-empty appeals list for user")
	}

	getReq := httptest.NewRequest(http.MethodGet, "/v1/moderation/appeals/"+appealID+"?user_id=user-appeal-1", nil)
	getRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(getRec, getReq)
	if getRec.Code != http.StatusOK {
		t.Fatalf("get moderation appeal code=%d body=%s", getRec.Code, getRec.Body.String())
	}

	actionBody := `{"status":"resolved_reversed","resolution_reason":"appeal accepted after moderator review"}`
	actionReq := httptest.NewRequest(http.MethodPost, "/v1/admin/moderation/appeals/"+appealID+"/action", strings.NewReader(actionBody))
	actionReq.Header.Set("Content-Type", "application/json")
	actionReq.Header.Set("X-Admin-User", "qa-admin")
	actionRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(actionRec, actionReq)
	if actionRec.Code != http.StatusOK {
		t.Fatalf("admin action appeal code=%d body=%s", actionRec.Code, actionRec.Body.String())
	}
	actionPayload := decodeJSONMap(t, actionRec.Body.Bytes())
	actionAppeal := toMap(t, actionPayload["appeal"])
	if got := stringValue(actionAppeal["status"]); got != appealStatusResolvedReverse {
		t.Fatalf("expected resolved status %q, got %q", appealStatusResolvedReverse, got)
	}
	if got := stringValue(actionAppeal["reviewed_by"]); got != "user-appeal-1" {
		t.Fatalf("expected reviewed_by to be the authenticated operator, got %q", got)
	}

	activitiesReq := httptest.NewRequest(http.MethodGet, "/v1/admin/activities?limit=100", nil)
	activitiesRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(activitiesRec, activitiesReq)
	if activitiesRec.Code != http.StatusOK {
		t.Fatalf("admin activities code=%d body=%s", activitiesRec.Code, activitiesRec.Body.String())
	}
	activitiesPayload := decodeJSONMap(t, activitiesRec.Body.Bytes())
	activities, ok := activitiesPayload["activities"].([]any)
	if !ok {
		t.Fatalf("expected activities list in payload")
	}
	foundResolveEvent := false
	for _, item := range activities {
		activity, ok := item.(map[string]any)
		if !ok {
			continue
		}
		if stringValue(activity["action"]) != "appeal.resolved" {
			continue
		}
		details, ok := activity["details"].(map[string]any)
		if !ok {
			continue
		}
		if stringValue(details["appeal_id"]) == appealID {
			foundResolveEvent = true
			break
		}
	}
	if !foundResolveEvent {
		t.Fatalf("expected appeal.resolved activity for appeal %q", appealID)
	}
}

func TestServer_ModerationAppealStatusRejectsDifferentUser(t *testing.T) {
	server := newAppealsTestServer(t)
	defer server.Close()

	submitReq := httptest.NewRequest(http.MethodPost, "/v1/moderation/appeals", strings.NewReader(`{"user_id":"u-1","reason":"wrongful decision"}`))
	submitReq.Header.Set("Content-Type", "application/json")
	submitRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(submitRec, submitReq)
	if submitRec.Code != http.StatusOK {
		t.Fatalf("submit appeal code=%d body=%s", submitRec.Code, submitRec.Body.String())
	}
	payload := decodeJSONMap(t, submitRec.Body.Bytes())
	appeal := toMap(t, payload["appeal"])
	appealID := stringValue(appeal["id"])

	getReq := httptest.NewRequest(http.MethodGet, "/v1/moderation/appeals/"+appealID+"?user_id=u-2", nil)
	getRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(getRec, getReq)
	if getRec.Code != http.StatusNotFound {
		t.Fatalf("expected 404 for mismatched user, got %d body=%s", getRec.Code, getRec.Body.String())
	}
}

func TestServer_AdminAnalyticsIncludesAppealAndTaxonomyDimensions(t *testing.T) {
	// The appeal body names its own actor, so the principal must be that user;
	// the operator role covers the admin analytics call later in the flow.
	installOperatorPrincipal(t, "u-analytics", "admin")
	server := newAppealsTestServer(t)
	defer server.Close()

	submitReq := httptest.NewRequest(http.MethodPost, "/v1/moderation/appeals", strings.NewReader(`{"user_id":"u-analytics","reason":"appeal reason"}`))
	submitReq.Header.Set("Content-Type", "application/json")
	submitRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(submitRec, submitReq)
	if submitRec.Code != http.StatusOK {
		t.Fatalf("submit appeal code=%d body=%s", submitRec.Code, submitRec.Body.String())
	}

	analyticsReq := httptest.NewRequest(http.MethodGet, "/v1/admin/analytics/overview", nil)
	analyticsRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(analyticsRec, analyticsReq)
	if analyticsRec.Code != http.StatusOK {
		t.Fatalf("analytics overview code=%d body=%s", analyticsRec.Code, analyticsRec.Body.String())
	}

	var payload map[string]any
	if err := json.Unmarshal(analyticsRec.Body.Bytes(), &payload); err != nil {
		t.Fatalf("decode analytics payload: %v", err)
	}
	metrics := toMap(t, payload["metrics"])
	if got := int(metrics["pending_appeals"].(float64)); got != 1 {
		t.Fatalf("expected pending_appeals=1, got %d", got)
	}
	if _, ok := metrics["dashboard_panels"].([]any); !ok {
		t.Fatalf("expected dashboard_panels in analytics payload")
	}
	eventTaxonomy := toMap(t, metrics["event_taxonomy"])
	if got := stringValue(eventTaxonomy["version"]); got == "" {
		t.Fatalf("expected event taxonomy version")
	}
}

func newAppealsTestServer(t *testing.T) *Server {
	t.Helper()
	cfg := config.Config{
		APIPrefix:        "/v1",
		AuthGRPCAddr:     "127.0.0.1:19091",
		ProfileGRPCAddr:  "127.0.0.1:19092",
		MatchingGRPCAddr: "127.0.0.1:19093",
		ChatGRPCAddr:     "127.0.0.1:19094",
	}
	reg := prometheus.NewRegistry()
	metrics := observability.NewHTTPMetrics(reg)
	server, err := NewServer(cfg, zap.NewNop(), metrics)
	if err != nil {
		t.Fatalf("NewServer() error = %v", err)
	}
	return server
}
