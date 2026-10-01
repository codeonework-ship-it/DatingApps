package mobile

import (
	"context"
	"io"
	"net/http"
	"strings"
	"testing"
)

func TestPathOwnedByPrincipal(t *testing.T) {
	const userID = "11111111-1111-4111-8111-111111111111"
	tests := []struct {
		name   string
		path   string
		method string
		want   bool
	}{
		{name: "public stories use visibility gate", path: "/v1/profile/22222222-2222-4222-8222-222222222222/stories", method: http.MethodGet, want: true},
		{name: "other stories cannot be edited", path: "/v1/profile/22222222-2222-4222-8222-222222222222/stories", method: http.MethodPut, want: false},
		{name: "own settings", path: "/v1/settings/" + userID, method: http.MethodGet, want: true},
		{name: "other settings", path: "/v1/settings/22222222-2222-4222-8222-222222222222", method: http.MethodGet, want: false},
		{name: "own discovery", path: "/v1/discovery/" + userID, method: http.MethodGet, want: true},
		{name: "other discovery", path: "/v1/discovery/22222222-2222-4222-8222-222222222222", method: http.MethodGet, want: false},
		{name: "view another profile", path: "/v1/profile/22222222-2222-4222-8222-222222222222", method: http.MethodGet, want: true},
		{name: "other private draft", path: "/v1/profile/22222222-2222-4222-8222-222222222222/draft", method: http.MethodGet, want: false},
		{name: "other private summary", path: "/v1/profile/22222222-2222-4222-8222-222222222222/summary", method: http.MethodGet, want: false},
		{name: "own private draft", path: "/v1/profile/" + userID + "/draft", method: http.MethodGet, want: true},
		{name: "edit another profile", path: "/v1/profile/22222222-2222-4222-8222-222222222222", method: http.MethodPut, want: false},
		{name: "own signup workflow", path: "/v1/auth/signup/workflow/" + userID, method: http.MethodGet, want: true},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			if got := pathOwnedByPrincipal("/v1", test.path, test.method, userID); got != test.want {
				t.Fatalf("pathOwnedByPrincipal() = %v, want %v", got, test.want)
			}
		})
	}
}

func TestEnforceBodyIdentityRejectsSpoofingAndReplaysBody(t *testing.T) {
	const userID = "11111111-1111-4111-8111-111111111111"
	body := `{"user_id":"22222222-2222-4222-8222-222222222222","target_user_id":"33333333-3333-4333-8333-333333333333"}`
	req, err := http.NewRequest(http.MethodPost, "/v1/swipe", strings.NewReader(body))
	if err != nil {
		t.Fatal(err)
	}
	req.Header.Set("Content-Type", "application/json")
	if err := enforceBodyIdentity(req, userID); err == nil {
		t.Fatal("expected spoofed actor to be rejected")
	}
	replayed, err := io.ReadAll(req.Body)
	if err != nil {
		t.Fatal(err)
	}
	if string(replayed) != body {
		t.Fatalf("request body was not replayable: %q", replayed)
	}
}

func TestEnforceBodyIdentityAllowsAuthenticatedActor(t *testing.T) {
	const userID = "11111111-1111-4111-8111-111111111111"
	req, err := http.NewRequest(http.MethodPost, "/v1/swipe", strings.NewReader(`{"user_id":"`+userID+`","target_user_id":"other"}`))
	if err != nil {
		t.Fatal(err)
	}
	req.Header.Set("Content-Type", "application/json")
	if err := enforceBodyIdentity(req, userID); err != nil {
		t.Fatalf("expected authenticated actor to pass: %v", err)
	}
}

func TestPublicSecurityPaths(t *testing.T) {
	for _, path := range []string{"/v1/auth/login", "/v1/auth/signup", "/v1/auth/refresh", "/v1/auth/password/recover"} {
		if !isPublicSecurityPath("/v1", path, http.MethodPost) {
			t.Fatalf("expected %s to be public", path)
		}
	}
	if isPublicSecurityPath("/v1", "/v1/settings/user-1", http.MethodGet) {
		t.Fatal("settings route must require authentication")
	}
}

func TestAuthenticatedOperatorIDRejectsSpoofedHeaderWithoutBearerPrincipal(t *testing.T) {
	req, err := http.NewRequest(http.MethodPost, "/v1/admin/users/user-1/ban", nil)
	if err != nil {
		t.Fatal(err)
	}
	req.Header.Set("X-Admin-User", "spoofed-admin")
	if _, err := authenticatedOperatorID(req); err == nil {
		t.Fatal("expected spoofed operator header without authenticated principal to be rejected")
	}
}

func TestAuthenticatedOperatorIDUsesBearerPrincipalIdentity(t *testing.T) {
	const operatorID = "11111111-1111-4111-8111-111111111111"
	req, err := http.NewRequest(http.MethodPost, "/v1/admin/users/user-1/ban", nil)
	if err != nil {
		t.Fatal(err)
	}
	principal := securityPrincipal{UserID: operatorID, Roles: map[string]bool{"admin": true}}
	req = req.WithContext(context.WithValue(req.Context(), securityPrincipalContextKey{}, principal))
	got, err := authenticatedOperatorID(req)
	if err != nil {
		t.Fatalf("authenticatedOperatorID() error = %v", err)
	}
	if got != operatorID {
		t.Fatalf("authenticatedOperatorID() = %q, want %q", got, operatorID)
	}
}

func TestPrincipalCanAccessAdminRouteByRole(t *testing.T) {
	tests := []struct {
		name, role, method, path string
		want                     bool
	}{
		{"admin all", "admin", http.MethodDelete, "/v1/admin/users/u1", true},
		{"trust safety reports", "trust_safety", http.MethodPost, "/v1/admin/moderation/reports/r1/action", true},
		{"trust safety ban", "trust_safety", http.MethodPost, "/v1/admin/users/u1/ban", true},
		{"trust safety billing denied", "trust_safety", http.MethodPost, "/v1/admin/billing/grant-coins", false},
		{"trust safety fraud review", "trust_safety", http.MethodPost, "/v1/admin/billing/fraud/cases/c1/resolve", true},
		{"trust safety fraud rules read", "trust_safety", http.MethodGet, "/v1/admin/billing/fraud/rules", true},
		{"trust safety fraud rules mutation denied", "trust_safety", http.MethodPut, "/v1/admin/billing/fraud/rules/r1", false},
		{"ops catalog", "ops_admin", http.MethodPut, "/v1/admin/catalog/gifts/g1", true},
		{"ops moderation denied", "ops_admin", http.MethodPost, "/v1/admin/moderation/reports/r1/action", false},
		{"analyst analytics read", "analyst", http.MethodGet, "/v1/admin/analytics/overview", true},
		{"analyst audit read", "analyst", http.MethodGet, "/v1/admin/audit-events", true},
		{"analyst event stream read", "analyst", http.MethodGet, "/v1/admin/events", true},
		{"analyst event metrics read", "analyst", http.MethodGet, "/v1/admin/events/metrics", true},
		{"analyst mutation denied", "analyst", http.MethodPut, "/v1/admin/config/flags/gifts_enabled", false},
		{"user denied", "user", http.MethodGet, "/v1/admin/users", false},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			principal := securityPrincipal{Roles: map[string]bool{test.role: true}}
			if got := principalCanAccessAdminRoute(principal, "/v1", test.method, test.path); got != test.want {
				t.Fatalf("principalCanAccessAdminRoute()=%v want %v", got, test.want)
			}
		})
	}
}
