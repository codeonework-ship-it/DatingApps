package mobile

import (
	"context"
	"database/sql"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"testing"

	"github.com/google/uuid"
)

func TestBillingPaymentMode(t *testing.T) {
	for _, tc := range []struct{ provider, key, want string }{
		{"sandbox", "", "sandbox"}, {"stripe", "sk_test_example", "test"},
		{"stripe", "rk_test_example", "test"}, {"stripe", "sk_live_example", "live"},
		{"stripe", "rk_live_example", "live"}, {"stripe", "", "disabled"},
		{"stripe", "unknown", "disabled"}, {"disabled", "sk_live_example", "disabled"},
	} {
		if got := billingPaymentMode(tc.provider, tc.key); got != tc.want {
			t.Fatalf("provider %s mode=%s want=%s", tc.provider, got, tc.want)
		}
	}
}

func TestBillingAccountFailsClosedWithoutPersistence(t *testing.T) {
	server := newSandboxBillingServer(t)
	defer server.Close()
	installStrictOperatorPrincipal(t, "member-1")
	for _, authorized := range []bool{false, true} {
		req := httptest.NewRequest(http.MethodGet, "/v1/billing/account", nil)
		want := http.StatusUnauthorized
		if authorized {
			req.Header.Set("Authorization", "Bearer "+testOperatorToken)
			want = http.StatusServiceUnavailable
		}
		rec := httptest.NewRecorder()
		server.Handler().ServeHTTP(rec, req)
		if rec.Code != want {
			t.Fatalf("account authorized=%v status=%d want=%d", authorized, rec.Code, want)
		}
	}
}

func TestBillingAccountRecoveryPostgres(t *testing.T) {
	dsn := os.Getenv("PROFILE_TEST_DATABASE_URL")
	if dsn == "" {
		t.Skip("PROFILE_TEST_DATABASE_URL is not set")
	}
	db, err := sql.Open("pgx", dsn)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = db.Close() })
	ctx := context.Background()
	userID, otherID := uuid.NewString(), uuid.NewString()
	for _, id := range []string{userID, otherID} {
		_, err := db.ExecContext(ctx, `INSERT INTO user_management.users
			(id,username,name,date_of_birth,gender,email) VALUES ($1,$2,'Account QA','1990-01-01','female',$3)`,
			id, "acct_"+id[:8], id+"@example.test")
		if err != nil {
			t.Fatal(err)
		}
		t.Cleanup(func() { _, _ = db.ExecContext(ctx, `DELETE FROM user_management.users WHERE id=$1`, id) })
	}
	server := newSandboxBillingServer(t)
	defer server.Close()
	repo := newBillingRepository(db)
	server.store.billingRepo, server.billing.repo = repo, repo
	installStrictOperatorPrincipal(t, userID)
	read := func() map[string]any {
		req := httptest.NewRequest(http.MethodGet, "/v1/billing/account?user_id="+otherID, nil)
		req.Header.Set("Authorization", "Bearer "+testOperatorToken)
		rec := httptest.NewRecorder()
		server.Handler().ServeHTTP(rec, req)
		if rec.Code != http.StatusOK {
			t.Fatalf("account status=%d body=%s", rec.Code, rec.Body.String())
		}
		if rec.Header().Get("Cache-Control") != "no-store" {
			t.Fatal("payment account must not be cached")
		}
		for _, secret := range []string{"provider_customer_id", "provider_session_id", testSandboxSecret, otherID} {
			if strings.Contains(rec.Body.String(), secret) {
				t.Fatalf("account disclosed %s", secret)
			}
		}
		account := toMap(t, decodeJSONMap(t, rec.Body.Bytes())["account"])
		if account["user_id"] != userID || account["email"] != userID+"@example.test" || account["mode"] != "sandbox" {
			t.Fatalf("wrong authenticated account: %+v", account)
		}
		return account
	}
	account := read()
	if account["customer_connected"] != false {
		t.Fatal("GET must not provision a customer")
	}
	create := func(id string) billingCheckoutRow {
		row, _, err := server.billing.createCheckout(ctx, id, "gold", "monthly", uuid.NewString())
		if err != nil {
			t.Fatal(err)
		}
		return row
	}
	open := create(userID)
	expired := create(userID)
	create(otherID)
	_, err = db.ExecContext(ctx, `UPDATE matching.billing_checkout_sessions SET expires_at=NOW()-interval '1 minute' WHERE id=$1`, expired.ID)
	if err != nil {
		t.Fatal(err)
	}
	account = read()
	pending := account["pending_checkouts"].([]any)
	if account["customer_connected"] != true || len(pending) != 1 || toMap(t, pending[0])["id"] != open.ID {
		t.Fatalf("recovery must include only own unexpired session: %+v", account)
	}
	if err := repo.markCheckoutStatus(ctx, open.ID, "completed"); err != nil {
		t.Fatal(err)
	}
	if len(read()["pending_checkouts"].([]any)) != 0 {
		t.Fatal("settled sessions must not be reopened")
	}
	create(userID)
	restarted := newSandboxBillingServer(t)
	defer restarted.Close()
	server.billing.sandbox = restarted.billing.sandbox
	if len(read()["pending_checkouts"].([]any)) != 0 {
		t.Fatal("sandbox restart must not offer lost in-memory sessions")
	}
	server.billing = nil
	req := httptest.NewRequest(http.MethodGet, "/v1/billing/account", nil)
	req.Header.Set("Authorization", "Bearer "+testOperatorToken)
	rec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, req)
	disabled := toMap(t, decodeJSONMap(t, rec.Body.Bytes())["account"])
	if disabled["mode"] != "disabled" || len(disabled["payment_methods"].([]any)) != 0 {
		t.Fatal("disabled provider must not advertise card checkout")
	}
}
