package mobile

import (
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"testing"
)

// TestWalletTopUpRefusesUnprivilegedMember guards BILL-002: an unprivileged
// member must not be able to grant themselves coins.
//
// Measured before this guard existed: a live account holding only the `user`
// role posted to its own top-up endpoint and granted itself 500 coins with no
// payment and no operator involved. Three things combined — the approver could
// be supplied in the caller's own body, the check only tested that the string
// was non-empty rather than that it belonged to an operator, and the whole gate
// applied only when the environment string matched a known production name.
func TestWalletTopUpRefusesUnprivilegedMember(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	const userID = "topup-guard-user-1"
	installOperatorPrincipal(t, userID) // authenticated, no operator role

	req := httptest.NewRequest(
		http.MethodPost,
		"/v1/wallet/"+userID+"/coins/top-up",
		strings.NewReader(`{"amount":1000,"reason":"self grant"}`),
	)
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, req)

	if rec.Code != http.StatusForbidden {
		t.Fatalf(
			"a member without an operator role must not top up a wallet; "+
				"got code=%d body=%s",
			rec.Code, rec.Body.String(),
		)
	}
}

// TestWalletTopUpIgnoresCallerSuppliedApprover pins the impersonation half.
//
// The approver used to be read from `requested_by` in the request body, a
// field `enforceBodyIdentity` did not police, so naming any approver satisfied
// the gate. Authorization now comes from the session, and the body field is
// additionally rejected as a foreign actor.
func TestWalletTopUpIgnoresCallerSuppliedApprover(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	const userID = "topup-guard-user-2"
	installOperatorPrincipal(t, userID) // still not an operator

	req := httptest.NewRequest(
		http.MethodPost,
		"/v1/wallet/"+userID+"/coins/top-up",
		strings.NewReader(`{"amount":1000,"requested_by":"some-admin"}`),
	)
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, req)

	if rec.Code == http.StatusOK {
		t.Fatalf(
			"naming an approver in the request body must not authorize a "+
				"top-up; got code=%d body=%s",
			rec.Code, rec.Body.String(),
		)
	}
}

// TestBodyIdentityCoversApproverFields keeps the actor list honest.
//
// The list is the control: a new actor field is unprotected until it appears
// here, which is exactly how `requested_by` was missed.
func TestBodyIdentityCoversApproverFields(t *testing.T) {
	raw, err := os.ReadFile("server_security.go")
	if err != nil {
		t.Fatalf("read server_security.go: %v", err)
	}
	source := string(raw)
	for _, field := range []string{
		"requested_by", "actor_id", "granted_by", "operator_id",
	} {
		if !strings.Contains(source, `"`+field+`"`) {
			t.Errorf(
				"enforceBodyIdentity must reject a foreign %q: it names an "+
					"actor a caller could otherwise impersonate",
				field,
			)
		}
	}
}
