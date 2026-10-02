package mobile

import (
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

// A database fault while looking up a session must not sign the member out:
// only a credential that is actually invalid earns a 401.
func TestSecurityMiddlewareSessionLookupFaultIsRetryable(t *testing.T) {
	var lookupErr error
	testPrincipalResolver = func(r *http.Request) (securityPrincipal, error) {
		return securityPrincipal{}, lookupErr
	}
	t.Cleanup(func() { testPrincipalResolver = nil })
	s := &Server{}
	s.cfg.APIPrefix = "/v1"
	reached := false
	h := s.securityMiddleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) { reached = true }))
	call := func() *httptest.ResponseRecorder {
		rec := httptest.NewRecorder()
		req := httptest.NewRequest(http.MethodGet, "/v1/users/11111111-1111-4111-8111-111111111111/friends", nil)
		req.Header.Set("Authorization", "Bearer token")
		h.ServeHTTP(rec, req)
		return rec
	}

	lookupErr = authStoreUnavailable(errors.New(`could not open file "base/16384/1": Interrupted system call`))
	rec := call()
	if rec.Code != http.StatusServiceUnavailable || rec.Header().Get("Retry-After") == "" {
		t.Fatalf("lookup fault: status %d, Retry-After %q", rec.Code, rec.Header().Get("Retry-After"))
	}
	if body := rec.Body.String(); strings.Contains(body, "Interrupted") {
		t.Fatalf("database detail leaked to the client: %s", body)
	}

	lookupErr = errors.New("invalid session")
	if rec := call(); rec.Code != http.StatusUnauthorized {
		t.Fatalf("invalid session: status %d", rec.Code)
	}
	if reached {
		t.Fatal("handler ran without a principal")
	}
}
