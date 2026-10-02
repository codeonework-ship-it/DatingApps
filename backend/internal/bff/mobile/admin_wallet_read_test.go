package mobile

import (
	"context"
	"net/http"
	"net/http/httptest"
	"net/url"
	"testing"

	"github.com/go-chi/chi/v5"

	"github.com/verified-dating/backend/internal/platform/config"
)

// GO-02: the admin wallet read must not write anything, and an unknown member
// is a 404 rather than a 200 with an empty wallet.
func TestAdminGetWalletBalance_IsReadOnlyAnd404sUnknownMembers(t *testing.T) {
	const known = "6f1c2b8e-1d2a-4c3b-9e8f-0a1b2c3d4e5f"
	const unknown = "00000000-0000-4000-8000-000000000001"
	cfg := config.Config{
		UserSchema:       "user_management",
		UsersTable:       "users",
		MatchingSchema:   "matching",
		UserWalletsTable: "user_wallets",
	}
	writes := 0
	db := &fakeRoseGiftDB{
		selectReadFn: func(_ context.Context, _ string, table string, params url.Values) ([]map[string]any, error) {
			switch table {
			case cfg.UsersTable:
				if params.Get("id") == "eq."+known {
					return []map[string]any{{"id": known}}, nil
				}
				return nil, nil
			case cfg.UserWalletsTable:
				return nil, nil // the known member has no wallet row yet
			}
			return nil, nil
		},
		insertFn: func(context.Context, string, string, any) ([]map[string]any, error) {
			writes++
			return nil, nil
		},
		updateFn: func(context.Context, string, string, any, url.Values) ([]map[string]any, error) {
			writes++
			return nil, nil
		},
	}
	s := &Server{store: &runtimeStore{
		cfg:               cfg,
		adminRepo:         &adminRepository{cfg: cfg, db: db},
		giftsRepo:         &roseGiftRepository{cfg: cfg, db: db},
		walletCoinsByUser: map[string]int{},
	}}
	admin := securityPrincipal{UserID: "op-1", Roles: map[string]bool{"admin": true}}

	read := func(userID string) *httptest.ResponseRecorder {
		req := httptest.NewRequest(http.MethodGet, "/v1/admin/users/"+userID+"/wallet", nil)
		rc := chi.NewRouteContext()
		rc.URLParams.Add("userID", userID)
		req = req.WithContext(context.WithValue(context.WithValue(req.Context(), chi.RouteCtxKey, rc), securityPrincipalContextKey{}, admin))
		rec := httptest.NewRecorder()
		s.adminGetWalletBalance(rec, req)
		return rec
	}

	if rec := read(unknown); rec.Code != http.StatusNotFound {
		t.Fatalf("unknown member: code=%d body=%s", rec.Code, rec.Body.String())
	}
	if rec := read("not-a-uuid"); rec.Code != http.StatusNotFound {
		t.Fatalf("malformed id: code=%d body=%s", rec.Code, rec.Body.String())
	}
	rec := read(known)
	if rec.Code != http.StatusOK {
		t.Fatalf("known member: code=%d body=%s", rec.Code, rec.Body.String())
	}
	wallet := toMap(t, decodeJSONMap(t, rec.Body.Bytes())["wallet"])
	if wallet["coin_balance"] != float64(0) || wallet["user_id"] != known {
		t.Fatalf("wallet=%v", wallet)
	}
	if writes != 0 {
		t.Fatalf("wallet read wrote %d rows", writes)
	}
}

func TestApiRequestActivityEventDropsUserForNotFound(t *testing.T) {
	s := &Server{store: &runtimeStore{}}
	req := httptest.NewRequest(http.MethodGet, "/v1/admin/users/00000000-0000-4000-8000-000000000001/wallet", nil)
	rc := chi.NewRouteContext()
	rc.URLParams.Add("userID", "00000000-0000-4000-8000-000000000001")
	req = req.WithContext(context.WithValue(req.Context(), chi.RouteCtxKey, rc))
	if got := s.apiRequestActivityEvent(req, http.StatusNotFound, 0).UserID; got != "" {
		t.Fatalf("404 telemetry attributed to %q", got)
	}
	if got := s.apiRequestActivityEvent(req, http.StatusOK, 0).UserID; got == "" {
		t.Fatal("200 telemetry lost its member")
	}
}

func TestApiRequestActivityEventNeverUsesAMatchIDAsTheMember(t *testing.T) {
	s := &Server{store: &runtimeStore{}}
	req := httptest.NewRequest(http.MethodGet, "/v1/matches/e107be36-170b-4fe5-ac8f-edad2046ccff/quest-workflow", nil)
	rc := chi.NewRouteContext()
	rc.URLParams.Add("matchID", "e107be36-170b-4fe5-ac8f-edad2046ccff")
	req = req.WithContext(context.WithValue(req.Context(), chi.RouteCtxKey, rc))
	if got := s.apiRequestActivityEvent(req, http.StatusOK, 0).UserID; got != "" {
		t.Fatalf("match id recorded as the member: %q", got)
	}
}
