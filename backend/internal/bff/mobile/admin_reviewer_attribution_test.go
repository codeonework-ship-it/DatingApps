package mobile

import (
	"context"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestOperatorReviewerIDPrefersVerifiedPrincipal(t *testing.T) {
	withPrincipal := func(r *http.Request, id string, roles ...string) *http.Request {
		set := map[string]bool{}
		for _, role := range roles {
			set[role] = true
		}
		return r.WithContext(context.WithValue(r.Context(), securityPrincipalContextKey{}, securityPrincipal{UserID: id, Roles: set}))
	}
	cases := []struct {
		name      string
		principal string
		roles     []string
		header    string
		fallback  string
		want      string
	}{
		{name: "trust_safety principal wins over header", principal: "ts-1", roles: []string{"trust_safety"}, header: "spoofed", want: "ts-1"},
		{name: "moderator principal", principal: "mod-1", roles: []string{"moderator"}, fallback: "payload-label", want: "mod-1"},
		{name: "admin principal", principal: "admin-1", roles: []string{"admin"}, header: "admin-1", want: "admin-1"},
		{name: "non-operator principal falls back to header", principal: "member-1", roles: []string{"user"}, header: "admin-hdr", want: "admin-hdr"},
		{name: "no principal uses header", header: "admin-hdr", fallback: "payload-label", want: "admin-hdr"},
		{name: "no principal or header uses fallback", fallback: "  payload-label ", want: "payload-label"},
		{name: "nothing at all", want: "control-panel"},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			r := httptest.NewRequest(http.MethodPost, "/v1/admin/moderation/appeals/a/action", nil)
			if tc.principal != "" {
				r = withPrincipal(r, tc.principal, tc.roles...)
			}
			if tc.header != "" {
				r.Header.Set("X-Admin-User", tc.header)
			}
			if got := operatorReviewerID(r, tc.fallback); got != tc.want {
				t.Fatalf("operatorReviewerID=%q, want %q", got, tc.want)
			}
		})
	}
}

// The security middleware sets X-Admin-User only for admins, so non-admin
// reviewers used to be recorded as "control-panel". Their own id must be.
func TestNonAdminReviewersAreAttributedToTheirOwnID(t *testing.T) {
	t.Run("moderator approves a verification", func(t *testing.T) {
		installOperatorPrincipal(t, "mod-reviewer", "moderator")
		server := newAppealsTestServer(t)
		defer server.Close()

		submit := httptest.NewRecorder()
		server.Handler().ServeHTTP(submit, verificationEvidenceRequest(t, "/v1/verification/user-mod-1/submit"))
		if submit.Code != http.StatusOK {
			t.Fatalf("submit code=%d body=%s", submit.Code, submit.Body.String())
		}
		approve := httptest.NewRequest(http.MethodPost, "/v1/admin/verifications/user-mod-1/approve", strings.NewReader("{}"))
		approve.Header.Set("Content-Type", "application/json")
		approve.Header.Set("X-Admin-User", "spoofed-admin")
		rec := httptest.NewRecorder()
		server.Handler().ServeHTTP(rec, approve)
		if rec.Code != http.StatusOK {
			t.Fatalf("approve code=%d body=%s", rec.Code, rec.Body.String())
		}
		verification := toMap(t, decodeJSONMap(t, rec.Body.Bytes())["verification"])
		if got := stringValue(verification["reviewed_by"]); got != "mod-reviewer" {
			t.Fatalf("reviewed_by=%q, want the moderator's id", got)
		}
	})

	t.Run("trust_safety resolves an appeal", func(t *testing.T) {
		installOperatorPrincipal(t, "user-ts-1", "trust_safety")
		server := newAppealsTestServer(t)
		defer server.Close()

		submit := httptest.NewRequest(http.MethodPost, "/v1/moderation/appeals", strings.NewReader(
			`{"user_id":"user-ts-1","report_id":"rep-ts","reason":"unfair moderation rejection","description":"context"}`))
		submit.Header.Set("Content-Type", "application/json")
		submitRec := httptest.NewRecorder()
		server.Handler().ServeHTTP(submitRec, submit)
		if submitRec.Code != http.StatusOK {
			t.Fatalf("submit code=%d body=%s", submitRec.Code, submitRec.Body.String())
		}
		appealID := stringValue(toMap(t, decodeJSONMap(t, submitRec.Body.Bytes())["appeal"])["id"])

		action := httptest.NewRequest(http.MethodPost, "/v1/admin/moderation/appeals/"+appealID+"/action",
			strings.NewReader(`{"status":"resolved_upheld","resolution_reason":"decision stands after review","reviewed_by":"payload-label"}`))
		action.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		server.Handler().ServeHTTP(rec, action)
		if rec.Code != http.StatusOK {
			t.Fatalf("action code=%d body=%s", rec.Code, rec.Body.String())
		}
		appeal := toMap(t, decodeJSONMap(t, rec.Body.Bytes())["appeal"])
		if got := stringValue(appeal["reviewed_by"]); got != "user-ts-1" {
			t.Fatalf("reviewed_by=%q, want the trust_safety operator's id", got)
		}
	})
}
