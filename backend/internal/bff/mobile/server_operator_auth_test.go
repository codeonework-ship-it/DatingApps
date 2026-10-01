package mobile

import (
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

// testOperatorToken is the bearer value installStrictOperatorPrincipal accepts.
const testOperatorToken = "test-operator-token"

// installOperatorPrincipal stands in for an authenticated operator session so
// tests can exercise operator routes without a live Postgres.
//
// Admin authorization now derives solely from the principal: a caller-supplied
// X-Admin-User header is stripped on every request and can no longer grant
// access on its own. Tests that drive admin routes therefore need a principal.
//
// The double mirrors the user addressed by the path when the route is
// self-scoped, so pathOwnedByPrincipal and enforceBodyIdentity behave as they
// would for a real session; admin routes keep the operator's own identity.
func installOperatorPrincipal(t *testing.T, operatorID string, roles ...string) {
	t.Helper()

	roleSet := map[string]bool{"user": true}
	for _, role := range roles {
		roleSet[role] = true
	}

	testPrincipalResolver = func(r *http.Request) (securityPrincipal, error) {
		userID := operatorID
		if !pathOwnedByPrincipal("/v1", r.URL.Path, r.Method, userID) {
			for _, segment := range strings.Split(strings.TrimPrefix(r.URL.Path, "/v1/"), "/") {
				if segment == "" {
					continue
				}
				if pathOwnedByPrincipal("/v1", r.URL.Path, r.Method, segment) {
					userID = segment
					break
				}
			}
		}
		return securityPrincipal{SessionID: "test-session", UserID: userID, Roles: roleSet}, nil
	}
	t.Cleanup(func() { testPrincipalResolver = nil })
}

// installStrictOperatorPrincipal only authenticates requests carrying
// testOperatorToken, so tests can prove that unauthenticated callers are
// refused.
func installStrictOperatorPrincipal(t *testing.T, operatorID string, roles ...string) {
	t.Helper()

	roleSet := map[string]bool{"user": true}
	for _, role := range roles {
		roleSet[role] = true
	}

	testPrincipalResolver = func(r *http.Request) (securityPrincipal, error) {
		authorization := strings.TrimSpace(r.Header.Get("Authorization"))
		token := strings.TrimSpace(strings.TrimPrefix(authorization, "Bearer"))
		if token != testOperatorToken {
			return securityPrincipal{}, errors.New("invalid session")
		}
		return securityPrincipal{SessionID: "test-session", UserID: operatorID, Roles: roleSet}, nil
	}
	t.Cleanup(func() { testPrincipalResolver = nil })
}

func TestSecurity_SpoofedAdminHeaderCannotReachAdminRoutes(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	installStrictOperatorPrincipal(t, "operator-1", "admin")

	// A caller inventing the operator header, with no bearer session at all.
	req := httptest.NewRequest(http.MethodGet, "/v1/admin/gifts/catalog", nil)
	req.Header.Set("X-Admin-User", "attacker")
	rec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, req)

	if rec.Code == http.StatusOK {
		t.Fatalf("spoofed X-Admin-User reached an admin route: %d %s", rec.Code, rec.Body.String())
	}
	if rec.Code != http.StatusUnauthorized && rec.Code != http.StatusForbidden {
		t.Fatalf("expected 401/403 for spoofed operator header, got %d %s", rec.Code, rec.Body.String())
	}
}

func TestSecurity_NonAdminPrincipalCannotReachAdminRoutes(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	// Authenticated, but holds no operator role.
	installStrictOperatorPrincipal(t, "regular-user")

	req := httptest.NewRequest(http.MethodGet, "/v1/admin/gifts/catalog", nil)
	req.Header.Set("Authorization", "Bearer "+testOperatorToken)
	rec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, req)

	if rec.Code != http.StatusForbidden {
		t.Fatalf("expected 403 for non-admin principal, got %d %s", rec.Code, rec.Body.String())
	}
}

func TestRefundAdminRoutesRejectMalformedResourceIDs(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	installOperatorPrincipal(t, "11111111-1111-4111-8111-111111111111", "admin")

	tests := []struct {
		path string
		body string
	}{
		{"/v1/admin/billing/gift-sends/not-a-uuid/reverse", `{"reason":"member requested reversal"}`},
		{"/v1/admin/billing/wallets/not-a-uuid/review", `{"action":"write_off_and_unfreeze","note":"reviewed dispute evidence"}`},
	}
	for _, tc := range tests {
		req := httptest.NewRequest(http.MethodPost, tc.path, strings.NewReader(tc.body))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		server.Handler().ServeHTTP(rec, req)
		if rec.Code != http.StatusBadRequest {
			t.Fatalf("POST %s: got %d %s, want 400", tc.path, rec.Code, rec.Body.String())
		}
	}
}

func TestSecurity_AdminSurfaceRefusedWithoutPrincipalStore(t *testing.T) {
	// No resolver installed: nothing can authenticate an operator.
	server := newQuestWorkflowTestServer(t)

	req := httptest.NewRequest(http.MethodGet, "/v1/admin/gifts/catalog", nil)
	req.Header.Set("X-Admin-User", "attacker")
	rec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, req)

	if rec.Code != http.StatusServiceUnavailable {
		t.Fatalf("expected 503 when no principal store is configured, got %d %s", rec.Code, rec.Body.String())
	}
}

func TestSecurity_CallerSuppliedAdminHeaderIsStripped(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	installStrictOperatorPrincipal(t, "operator-1", "admin")

	var seen string
	var reached bool
	handler := server.securityMiddleware(http.HandlerFunc(func(_ http.ResponseWriter, r *http.Request) {
		seen = r.Header.Get("X-Admin-User")
		reached = true
	}))

	req := httptest.NewRequest(http.MethodGet, "/v1/admin/gifts/catalog", nil)
	req.Header.Set("Authorization", "Bearer "+testOperatorToken)
	req.Header.Set("X-Admin-User", "attacker")
	handler.ServeHTTP(httptest.NewRecorder(), req)

	if !reached {
		t.Fatal("request did not reach the downstream handler")
	}
	if seen == "attacker" {
		t.Fatal("caller-supplied X-Admin-User survived the middleware")
	}
	if seen != "operator-1" {
		t.Fatalf("expected X-Admin-User rewritten from the principal, got %q", seen)
	}
}

func TestSecurity_SuspendedPrincipalRejectedOnNextRequest(t *testing.T) {
	server := newQuestWorkflowTestServer(t)

	// principalForAccessToken rejects banned and suspended sessions by
	// returning an error, which the middleware turns into a 401 on the very
	// next request rather than only at login.
	testPrincipalResolver = func(*http.Request) (securityPrincipal, error) {
		return securityPrincipal{}, errors.New("invalid session")
	}
	t.Cleanup(func() { testPrincipalResolver = nil })

	req := httptest.NewRequest(http.MethodGet, "/v1/admin/gifts/catalog", nil)
	req.Header.Set("Authorization", "Bearer "+testOperatorToken)
	rec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401 for a suspended session, got %d %s", rec.Code, rec.Body.String())
	}
}
