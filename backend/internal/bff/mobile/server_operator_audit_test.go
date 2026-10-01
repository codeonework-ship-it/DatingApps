package mobile

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestOperatorAudit_ResourceDerivedFromRoute(t *testing.T) {
	cases := []struct {
		path         string
		wantType     string
		wantResource string
	}{
		// Action verbs describe what happened, not what was touched.
		{"/v1/admin/users/u-1/ban", "users", "u-1"},
		{"/v1/admin/users/u-1/unsuspend", "users", "u-1"},
		{"/v1/admin/verifications/u-2/approve", "verifications", "u-2"},
		{"/v1/admin/moderation/reports/r-9/action", "moderation/reports", "r-9"},
		{"/v1/admin/safety/sos-alerts/a-3/resolve", "safety/sos-alerts", "a-3"},
		{"/v1/admin/catalog/gifts/g-7/toggle", "catalog/gifts", "g-7"},
		{"/v1/admin/progression/users/u-4/adjust-xp", "progression/users", "u-4"},
		{"/v1/admin/moderation/media/p-8/decision", "moderation/media", "p-8"},
		// Collection endpoints carry no identifier.
		{"/v1/admin/users", "users", ""},
		{"/v1/admin/config/flags", "config/flags", ""},
		{"/v1/admin/billing/coin-packages", "billing/coin-packages", ""},
		{"/v1/admin/billing/grant-coins", "billing", ""},
		// Identified members of a collection.
		{"/v1/admin/config/flags/rose_gifts", "config/flags", "rose_gifts"},
		{"/v1/admin/billing/coin-packages/p-2", "billing/coin-packages", "p-2"},
	}

	for _, tc := range cases {
		gotType, gotResource := operatorResourceFromPath("/v1", tc.path)
		if gotType != tc.wantType || gotResource != tc.wantResource {
			t.Errorf("operatorResourceFromPath(%q) = (%q, %q), want (%q, %q)",
				tc.path, gotType, gotResource, tc.wantType, tc.wantResource)
		}
	}
}

func TestOperatorAudit_OnlyAuditsAdminMutations(t *testing.T) {
	server := newQuestWorkflowTestServer(t)

	cases := []struct {
		method string
		path   string
		want   bool
	}{
		{http.MethodPost, "/v1/admin/users/u-1/ban", true},
		{http.MethodPut, "/v1/admin/config/flags/k", true},
		{http.MethodDelete, "/v1/admin/catalog/gifts/g-1", true},
		// Reads are covered by the request log; auditing them buries the
		// mutations an auditor is looking for.
		{http.MethodGet, "/v1/admin/users", false},
		{http.MethodHead, "/v1/admin/users", false},
		// Non-operator surface.
		{http.MethodPost, "/v1/chat/m-1/messages", false},
		{http.MethodPatch, "/v1/settings/u-1", false},
	}

	for _, tc := range cases {
		req := httptest.NewRequest(tc.method, tc.path, nil)
		if got := server.isOperatorMutation(req); got != tc.want {
			t.Errorf("isOperatorMutation(%s %s) = %v, want %v",
				tc.method, tc.path, got, tc.want)
		}
	}
}

func TestOperatorAudit_RoleReflectsStrongestOperatorRole(t *testing.T) {
	cases := []struct {
		roles map[string]bool
		want  string
	}{
		{map[string]bool{"user": true, "admin": true}, "admin"},
		{map[string]bool{"user": true, "ops_admin": true}, "ops_admin"},
		{map[string]bool{"user": true, "trust_safety": true}, "trust_safety"},
		{map[string]bool{"user": true, "admin": true, "trust_safety": true}, "admin"},
		{map[string]bool{"user": true}, "operator"},
	}

	for _, tc := range cases {
		if got := operatorRoleOf(securityPrincipal{Roles: tc.roles}); got != tc.want {
			t.Errorf("operatorRoleOf(%v) = %q, want %q", tc.roles, got, tc.want)
		}
	}
}

// A failed operator action must not appear in the trail as though it happened.
func TestOperatorAudit_DoesNotRecordRejectedRequests(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	installStrictOperatorPrincipal(t, "operator-1", "admin")

	// No bearer session: securityMiddleware refuses before the handler runs,
	// so there is nothing to audit.
	req := httptest.NewRequest(http.MethodPost, "/v1/admin/users/u-1/ban", nil)
	req.Header.Set("X-Admin-User", "attacker")
	rec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, req)

	if rec.Code >= 200 && rec.Code < 300 {
		t.Fatalf("expected the unauthenticated operator request to be refused, got %d", rec.Code)
	}
}
