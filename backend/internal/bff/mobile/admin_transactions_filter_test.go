package mobile

import (
	"context"
	"net/http"
	"net/http/httptest"
	"net/url"
	"testing"

	"github.com/verified-dating/backend/internal/platform/config"
)

// CON-04: GET /v1/admin/billing/transactions?user_id= filters by member.
func TestAdminListBillingTransactionsFiltersByMember(t *testing.T) {
	const member = "6f1c2b8e-1d2a-4c3b-9e8f-0a1b2c3d4e5f"
	cfg := config.Config{MatchingSchema: "matching"}
	var seen url.Values
	db := &fakeRoseGiftDB{
		selectReadFn: func(_ context.Context, _ string, _ string, params url.Values) ([]map[string]any, error) {
			seen = params
			return []map[string]any{{"id": "t1", "user_id": member}}, nil
		},
	}
	s := &Server{store: &runtimeStore{cfg: cfg, adminRepo: &adminRepository{cfg: cfg, db: db}}}
	admin := securityPrincipal{UserID: "op-1", Roles: map[string]bool{"admin": true}}
	call := func(query string) *httptest.ResponseRecorder {
		req := httptest.NewRequest(http.MethodGet, "/v1/admin/billing/transactions?"+query, nil)
		req = req.WithContext(context.WithValue(req.Context(), securityPrincipalContextKey{}, admin))
		rec := httptest.NewRecorder()
		s.adminListBillingTransactions(rec, req)
		return rec
	}

	if rec := call("user_id=" + member + "&limit=20"); rec.Code != http.StatusOK {
		t.Fatalf("code=%d body=%s", rec.Code, rec.Body.String())
	}
	if got := seen.Get("user_id"); got != "eq."+member {
		t.Fatalf("user_id filter=%q", got)
	}
	seen = nil
	if rec := call("user_id=not-a-uuid"); rec.Code != http.StatusBadRequest || seen != nil {
		t.Fatalf("malformed user_id: code=%d queried=%v", rec.Code, seen != nil)
	}
	if rec := call("limit=20"); rec.Code != http.StatusOK || seen.Get("user_id") != "" {
		t.Fatalf("unfiltered list: code=%d filter=%q", rec.Code, seen.Get("user_id"))
	}
}
