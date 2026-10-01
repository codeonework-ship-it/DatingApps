package mobile

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/verified-dating/backend/internal/platform/config"
	"github.com/verified-dating/backend/internal/platform/payments"
)

const (
	testSandboxSecret  = "whsec_test_sandbox"
	testPaymentsPublic = "http://device.test/v1"
)

func newSandboxBillingServer(t *testing.T) *Server {
	t.Helper()
	return newQuestWorkflowTestServerWithConfig(t, func(target *config.Config) {
		target.PaymentsProvider = "sandbox"
		target.PaymentsPublicBaseURL = testPaymentsPublic
		target.PaymentsSandboxWebhookSecret = testSandboxSecret
		target.PaymentsCurrency = "INR"
		target.BillingPastDueGraceDays = 7
		target.BFFRequestTimeoutSec = 10
		target.BFFWriteTimeoutMS = 10000
		target.BFFNormalReadTimeoutMS = 10000
		target.BFFFastReadTimeoutMS = 10000
	})
}

// A configured provider closes the door on the legacy "activate locally"
// path: subscriptions must come from a settled card checkout.
func TestBillingSubscribeRefusedWhenProviderConfigured(t *testing.T) {
	server := newSandboxBillingServer(t)
	defer server.Close()
	installOperatorPrincipal(t, "member-1")

	req := httptest.NewRequest(http.MethodPost, "/v1/billing/subscribe", strings.NewReader(`{"user_id":"member-1","plan_id":"gold","billing_cycle":"monthly"}`))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, req)
	if rec.Code != http.StatusConflict {
		t.Fatalf("subscribe with provider configured = %d body=%s", rec.Code, rec.Body.String())
	}
}

func TestBillingCheckoutFailsClosedWithoutPersistence(t *testing.T) {
	server := newSandboxBillingServer(t)
	defer server.Close()
	installOperatorPrincipal(t, "member-1")

	req := httptest.NewRequest(http.MethodPost, "/v1/billing/checkout", strings.NewReader(`{"plan_id":"gold"}`))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, req)
	if rec.Code != http.StatusServiceUnavailable {
		t.Fatalf("checkout without durable billing = %d body=%s", rec.Code, rec.Body.String())
	}
}

func TestBillingCheckoutNotImplementedWhenPaymentsDisabled(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()
	installOperatorPrincipal(t, "member-1")

	req := httptest.NewRequest(http.MethodPost, "/v1/billing/checkout", strings.NewReader(`{"plan_id":"gold"}`))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, req)
	if rec.Code != http.StatusNotImplemented {
		t.Fatalf("checkout with payments disabled = %d body=%s", rec.Code, rec.Body.String())
	}
}

// The webhook route is public (it carries no bearer token) so the signature
// is the only gate. It must reject forged and unsigned deliveries, and it
// must not accept events addressed to a provider that is not configured.
func TestBillingWebhookRejectsBadSignatureAndUnknownProvider(t *testing.T) {
	server := newSandboxBillingServer(t)
	defer server.Close()

	payload := []byte(`{"id":"evt_forged","type":"invoice.paid","created":1,"data":{"object":{}}}`)
	post := func(path, signature string) *httptest.ResponseRecorder {
		req := httptest.NewRequest(http.MethodPost, path, strings.NewReader(string(payload)))
		req.Header.Set("Content-Type", "application/json")
		if signature != "" {
			req.Header.Set("Stripe-Signature", signature)
		}
		rec := httptest.NewRecorder()
		server.Handler().ServeHTTP(rec, req)
		return rec
	}
	if rec := post("/v1/billing/webhooks/sandbox", ""); rec.Code != http.StatusBadRequest {
		t.Fatalf("unsigned webhook = %d body=%s", rec.Code, rec.Body.String())
	}
	if rec := post("/v1/billing/webhooks/sandbox", payments.SignPayload("whsec_wrong", time.Now(), payload)); rec.Code != http.StatusBadRequest {
		t.Fatalf("forged webhook = %d body=%s", rec.Code, rec.Body.String())
	}
	if rec := post("/v1/billing/webhooks/stripe", payments.SignPayload(testSandboxSecret, time.Now(), payload)); rec.Code != http.StatusNotFound {
		t.Fatalf("unknown provider webhook = %d body=%s", rec.Code, rec.Body.String())
	}
}

// TestBillingCardSubscriptionLifecyclePostgres drives the whole PEN-01
// journey over HTTP against the real schema: checkout → declined card →
// successful card → active subscription with card on file → renewal →
// duplicate and out-of-order webhooks → auto-renew off/on → refund → failed
// renewal (past_due, still entitled) → recovery → cancellation at period end
// → back to the free tier → grace expiry sweep.
func TestBillingCardSubscriptionLifecyclePostgres(t *testing.T) {
	dsn := os.Getenv("PROFILE_TEST_DATABASE_URL")
	if dsn == "" {
		t.Skip("PROFILE_TEST_DATABASE_URL is not set")
	}
	db, err := sql.Open("pgx", dsn)
	if err != nil {
		t.Fatal(err)
	}
	// Registered first so it runs last: cleanups run in reverse order and
	// the member delete below needs the pool open.
	t.Cleanup(func() { _ = db.Close() })
	ctx := context.Background()

	userID := uuid.NewString()
	username := "billqa_" + strings.ReplaceAll(userID[:8], "-", "")
	if _, err := db.ExecContext(ctx, `INSERT INTO user_management.users (id, username, name, date_of_birth, gender, email) VALUES ($1,$2,'Billing QA','1990-01-01','female',$3)`, userID, username, username+"@example.test"); err != nil {
		t.Fatalf("seed member: %v", err)
	}
	started := time.Now().UTC()
	t.Cleanup(func() {
		if _, err := db.ExecContext(ctx, `DELETE FROM user_management.users WHERE id=$1`, userID); err != nil {
			t.Logf("cleanup member: %v", err)
		}
		_, _ = db.ExecContext(ctx, `DELETE FROM matching.billing_webhook_events WHERE provider='sandbox' AND received_at >= $1`, started)
	})

	server := newSandboxBillingServer(t)
	defer server.Close()
	repo := newBillingRepository(db)
	server.store.billingRepo = repo
	server.billing.repo = repo
	installOperatorPrincipal(t, userID)

	do := func(method, path, body string, headers map[string]string) (*httptest.ResponseRecorder, map[string]any) {
		var reader *strings.Reader
		if body != "" {
			reader = strings.NewReader(body)
		} else {
			reader = strings.NewReader("")
		}
		req := httptest.NewRequest(method, path, reader)
		if body != "" && !strings.HasPrefix(body, "card_number") && !strings.HasPrefix(body, "action") {
			req.Header.Set("Content-Type", "application/json")
		}
		for k, v := range headers {
			req.Header.Set(k, v)
		}
		rec := httptest.NewRecorder()
		server.Handler().ServeHTTP(rec, req)
		var payload map[string]any
		if strings.Contains(rec.Header().Get("Content-Type"), "application/json") {
			_ = json.Unmarshal(rec.Body.Bytes(), &payload)
		}
		return rec, payload
	}
	subscription := func() map[string]any {
		rec, payload := do(http.MethodGet, "/v1/billing/subscription/"+userID, "", nil)
		if rec.Code != http.StatusOK {
			t.Fatalf("get subscription = %d body=%s", rec.Code, rec.Body.String())
		}
		return toMap(t, payload["subscription"])
	}
	paymentsList := func() []map[string]any {
		rec, payload := do(http.MethodGet, "/v1/billing/payments/"+userID+"?limit=50", "", nil)
		if rec.Code != http.StatusOK {
			t.Fatalf("list payments = %d body=%s", rec.Code, rec.Body.String())
		}
		items, _ := payload["payments"].([]any)
		out := make([]map[string]any, 0, len(items))
		for _, item := range items {
			out = append(out, toMap(t, item))
		}
		return out
	}
	simulate := func(event string) map[string]any {
		rec, payload := do(http.MethodPost, "/v1/billing/sandbox/subscriptions/"+userID+"/simulate", `{"event":"`+event+`"}`, nil)
		if rec.Code != http.StatusOK {
			t.Fatalf("simulate %s = %d body=%s", event, rec.Code, rec.Body.String())
		}
		return toMap(t, payload["subscription"])
	}

	// 1. Free tier before anything happens.
	if sub := subscription(); sub["plan_id"] != "free" || sub["is_paid"] != false || sub["entitled"] != true {
		t.Fatalf("expected free tier, got %+v", sub)
	}

	// 2. Create a checkout; the same Idempotency-Key returns the same checkout.
	rec, payload := do(http.MethodPost, "/v1/billing/checkout", `{"plan_id":"gold","billing_cycle":"monthly"}`, map[string]string{"Idempotency-Key": "chk-" + userID})
	if rec.Code != http.StatusCreated {
		t.Fatalf("create checkout = %d body=%s", rec.Code, rec.Body.String())
	}
	checkout := toMap(t, payload["checkout"])
	checkoutID := stringValue(checkout["id"])
	checkoutURL := stringValue(checkout["checkout_url"])
	if checkout["status"] != "open" || !strings.HasPrefix(checkoutURL, testPaymentsPublic+"/billing/sandbox/checkout/") {
		t.Fatalf("unexpected checkout row: %+v", checkout)
	}
	if amount, _ := checkout["amount_minor"].(float64); amount != 1999 {
		t.Fatalf("gold monthly should be 1999 minor units, got %v", checkout["amount_minor"])
	}
	rec, payload = do(http.MethodPost, "/v1/billing/checkout", `{"plan_id":"gold","billing_cycle":"monthly"}`, map[string]string{"Idempotency-Key": "chk-" + userID})
	if rec.Code != http.StatusOK && rec.Code != http.StatusCreated {
		t.Fatalf("repeat checkout = %d body=%s", rec.Code, rec.Body.String())
	}
	if repeat := toMap(t, payload["checkout"]); stringValue(repeat["id"]) != checkoutID {
		t.Fatalf("idempotent checkout returned a different row: %s vs %s", repeat["id"], checkoutID)
	}
	// Still nothing active: creating a checkout never grants anything.
	if sub := subscription(); sub["plan_id"] != "free" {
		t.Fatalf("checkout must not activate a plan, got %+v", sub)
	}

	// 3. Hosted card page renders publicly; a declined card changes nothing.
	sandboxPath := strings.TrimPrefix(checkoutURL, testPaymentsPublic)
	rec, _ = do(http.MethodGet, "/v1"+sandboxPath, "", nil)
	if rec.Code != http.StatusOK || !strings.Contains(rec.Body.String(), "Gold") {
		t.Fatalf("sandbox page = %d body=%.200s", rec.Code, rec.Body.String())
	}
	form := func(number string) string {
		v := url.Values{}
		v.Set("card_number", number)
		v.Set("exp_month", "12")
		v.Set("exp_year", fmt.Sprint(time.Now().Year()+3))
		v.Set("cvc", "123")
		v.Set("name", "Billing QA")
		v.Set("action", "pay")
		return v.Encode()
	}
	rec, _ = do(http.MethodPost, "/v1"+sandboxPath, form(payments.SandboxCardDeclined), map[string]string{"Content-Type": "application/x-www-form-urlencoded"})
	if rec.Code != http.StatusOK || !strings.Contains(rec.Body.String(), "declined") {
		t.Fatalf("declined card page = %d body=%.200s", rec.Code, rec.Body.String())
	}
	if sub := subscription(); sub["plan_id"] != "free" {
		t.Fatalf("declined card must not activate, got %+v", sub)
	}
	if len(paymentsList()) != 0 {
		t.Fatalf("declined card must not record a payment")
	}

	// 4. Successful card: redirect to the return page; webhooks settle it.
	rec, _ = do(http.MethodPost, "/v1"+sandboxPath, form(payments.SandboxCardSuccess), map[string]string{"Content-Type": "application/x-www-form-urlencoded"})
	if rec.Code != http.StatusSeeOther {
		t.Fatalf("successful card = %d body=%.300s", rec.Code, rec.Body.String())
	}
	location := rec.Header().Get("Location")
	if !strings.Contains(location, "/billing/checkout/return") || !strings.Contains(location, "status=success") || !strings.Contains(location, "checkout_id="+checkoutID) {
		t.Fatalf("return redirect = %q", location)
	}
	rec, payload = do(http.MethodGet, "/v1/billing/checkout/"+checkoutID, "", nil)
	if rec.Code != http.StatusOK {
		t.Fatalf("get checkout = %d body=%s", rec.Code, rec.Body.String())
	}
	if status := toMap(t, payload["checkout"])["status"]; status != "completed" {
		t.Fatalf("checkout status after payment = %v", status)
	}
	sub := toMap(t, payload["subscription"])
	if sub["plan_id"] != "gold" || sub["status"] != "active" || sub["is_paid"] != true || sub["entitled"] != true ||
		sub["auto_renew"] != true || sub["cancel_at_period_end"] != false || sub["card_last4"] != "4242" || sub["card_brand"] != "visa" ||
		sub["provider"] != "sandbox" || sub["billing_cycle"] != "monthly" {
		t.Fatalf("subscription after checkout wrong: %+v", sub)
	}
	firstPeriodEnd, err := time.Parse(time.RFC3339, stringValue(sub["current_period_end"]))
	if err != nil || !firstPeriodEnd.After(time.Now()) {
		t.Fatalf("current_period_end must be in the future: %v %v", sub["current_period_end"], err)
	}
	providerSubID := stringValue(sub["provider_subscription_id"])
	pays := paymentsList()
	if len(pays) != 1 || pays[0]["status"] != "success" || pays[0]["billing_reason"] != "subscription_create" || pays[0]["card_last4"] != "4242" || pays[0]["payment_method"] != "card" {
		t.Fatalf("first payment wrong: %+v", pays)
	}
	if amount, _ := pays[0]["amount"].(float64); amount != 19.99 {
		t.Fatalf("first payment amount = %v", pays[0]["amount"])
	}

	// 5. A second paid checkout is refused while one is live.
	rec, _ = do(http.MethodPost, "/v1/billing/checkout", `{"plan_id":"silver","billing_cycle":"yearly"}`, nil)
	if rec.Code != http.StatusConflict {
		t.Fatalf("second checkout while live = %d body=%s", rec.Code, rec.Body.String())
	}

	// 6. Renewal: another settled invoice, period advanced, still one live row.
	sub = simulate("renewal_paid")
	secondPeriodEnd, _ := time.Parse(time.RFC3339, stringValue(sub["current_period_end"]))
	if !secondPeriodEnd.After(firstPeriodEnd) || sub["status"] != "active" {
		t.Fatalf("renewal must advance the period: %v -> %v status=%v", firstPeriodEnd, secondPeriodEnd, sub["status"])
	}
	if pays = paymentsList(); len(pays) != 2 || pays[0]["billing_reason"] != "subscription_cycle" {
		t.Fatalf("renewal payment missing: %+v", pays)
	}
	var liveRows int
	if err := db.QueryRowContext(ctx, `SELECT COUNT(*) FROM matching.billing_subscriptions_runtime WHERE user_id=$1 AND status IN ('incomplete','active','past_due')`, userID).Scan(&liveRows); err != nil || liveRows != 1 {
		t.Fatalf("live subscription rows = %d err=%v", liveRows, err)
	}

	// 7. Replayed webhook: acknowledged, nothing applied twice.
	var lastEventID string
	var lastPayload []byte
	if err := db.QueryRowContext(ctx, `SELECT event_id, payload FROM matching.billing_webhook_events WHERE provider='sandbox' AND event_type='invoice.paid' ORDER BY received_at DESC LIMIT 1`).Scan(&lastEventID, &lastPayload); err != nil {
		t.Fatalf("read last invoice event: %v", err)
	}
	rec, _ = do(http.MethodPost, "/v1/billing/webhooks/sandbox", string(lastPayload), map[string]string{"Stripe-Signature": payments.SignPayload(testSandboxSecret, time.Now(), lastPayload)})
	if rec.Code != http.StatusOK {
		t.Fatalf("replayed webhook = %d body=%s", rec.Code, rec.Body.String())
	}
	if pays = paymentsList(); len(pays) != 2 {
		t.Fatalf("replayed invoice must not create a payment: %d", len(pays))
	}
	var eventRows int
	if err := db.QueryRowContext(ctx, `SELECT COUNT(*) FROM matching.billing_webhook_events WHERE provider='sandbox' AND event_id=$1`, lastEventID).Scan(&eventRows); err != nil || eventRows != 1 {
		t.Fatalf("event ledger rows for replay = %d err=%v", eventRows, err)
	}

	// 8. Out-of-order: a stale "canceled" snapshot from an hour ago must not
	// roll the active subscription backwards.
	stale, _ := json.Marshal(map[string]any{
		"id": "evt_stale_" + userID[:8], "type": "customer.subscription.updated", "created": time.Now().Add(-time.Hour).Unix(),
		"data": map[string]any{"object": map[string]any{
			"id": providerSubID, "customer": "cus_x", "status": "canceled", "canceled_at": time.Now().Add(-time.Hour).Unix(),
			"metadata": map[string]string{"user_id": userID}, "items": map[string]any{"data": []any{}},
		}},
	})
	rec, _ = do(http.MethodPost, "/v1/billing/webhooks/sandbox", string(stale), map[string]string{"Stripe-Signature": payments.SignPayload(testSandboxSecret, time.Now(), stale)})
	if rec.Code != http.StatusOK {
		t.Fatalf("stale webhook = %d body=%s", rec.Code, rec.Body.String())
	}
	if sub = subscription(); sub["status"] != "active" || sub["plan_id"] != "gold" {
		t.Fatalf("stale event rolled state back: %+v", sub)
	}

	// 8b. Process restart: the in-memory sandbox forgets the subscription; the
	// service must rehydrate it from the ledger rather than fail the member.
	freshSandbox, err := payments.NewSandbox(testSandboxSecret, testPaymentsPublic)
	if err != nil {
		t.Fatal(err)
	}
	freshSandbox.SetDeliverer(func(payload []byte, signature string) error {
		_, err := server.billing.processWebhook(ctx, payload, signature)
		return err
	})
	server.billing.provider = freshSandbox
	server.billing.sandbox = freshSandbox

	// 9. Auto-renew off keeps access to period end; on restores renewal.
	rec, payload = do(http.MethodPost, "/v1/billing/subscription/"+userID+"/cancel", "", nil)
	if rec.Code != http.StatusOK {
		t.Fatalf("cancel = %d body=%s", rec.Code, rec.Body.String())
	}
	sub = toMap(t, payload["subscription"])
	if sub["status"] != "active" || sub["auto_renew"] != false || sub["cancel_at_period_end"] != true || sub["entitled"] != true {
		t.Fatalf("after cancel: %+v", sub)
	}
	rec, payload = do(http.MethodPost, "/v1/billing/subscription/"+userID+"/resume", "", nil)
	if rec.Code != http.StatusOK {
		t.Fatalf("resume = %d body=%s", rec.Code, rec.Body.String())
	}
	if sub = toMap(t, payload["subscription"]); sub["auto_renew"] != true || sub["cancel_at_period_end"] != false {
		t.Fatalf("after resume: %+v", sub)
	}

	// 9b. Plan change: upgrade charges the prorated difference now, the
	// subscription reports the new plan; downgrade changes nothing but the
	// plan; same plan is refused; a card replacement through a setup
	// checkout updates the card on file; a dispute marks the payment.
	rec, payload = do(http.MethodPost, "/v1/billing/subscription/"+userID+"/change-plan", `{"plan_id":"emerald","billing_cycle":"monthly"}`, nil)
	if rec.Code != http.StatusOK {
		t.Fatalf("upgrade = %d body=%s", rec.Code, rec.Body.String())
	}
	sub = toMap(t, payload["subscription"])
	if sub["plan_id"] != "emerald" || sub["status"] != "active" || int(sub["amount_minor"].(float64)) != 2999 {
		t.Fatalf("after upgrade: %+v", sub)
	}
	pays = paymentsList()
	// The prorated charge is at most the full monthly difference (₹10.00);
	// with the sandbox period already renewed into the future it is exactly
	// that, on a live period it is a fraction.
	if pays[0]["billing_reason"] != "subscription_update" || pays[0]["status"] != "success" || pays[0]["amount"].(float64) <= 0 || pays[0]["amount"].(float64) > 10 {
		t.Fatalf("prorated upgrade payment wrong: %+v", pays[0])
	}
	if rec, _ = do(http.MethodPost, "/v1/billing/subscription/"+userID+"/change-plan", `{"plan_id":"emerald","billing_cycle":"monthly"}`, nil); rec.Code != http.StatusConflict {
		t.Fatalf("same plan change = %d", rec.Code)
	}
	if rec, _ = do(http.MethodPost, "/v1/billing/subscription/"+userID+"/change-plan", `{"plan_id":"free"}`, nil); rec.Code != http.StatusBadRequest {
		t.Fatalf("change to free = %d", rec.Code)
	}
	paymentsBefore := len(pays)
	rec, payload = do(http.MethodPost, "/v1/billing/subscription/"+userID+"/change-plan", `{"plan_id":"gold","billing_cycle":"monthly"}`, nil)
	if rec.Code != http.StatusOK || toMap(t, payload["subscription"])["plan_id"] != "gold" {
		t.Fatalf("downgrade = %d body=%s", rec.Code, rec.Body.String())
	}
	if len(paymentsList()) != paymentsBefore {
		t.Fatalf("downgrade must not charge")
	}
	// Card replacement.
	rec, payload = do(http.MethodPost, "/v1/billing/checkout", `{"kind":"card_update"}`, map[string]string{"Idempotency-Key": "card-" + userID})
	if rec.Code != http.StatusCreated {
		t.Fatalf("card update checkout = %d body=%s", rec.Code, rec.Body.String())
	}
	cardCheckout := toMap(t, payload["checkout"])
	if cardCheckout["kind"] != "card_update" {
		t.Fatalf("card checkout row: %+v", cardCheckout)
	}
	rec, payload = do(http.MethodGet, "/v1/billing/account", "", nil)
	if rec.Code != http.StatusOK {
		t.Fatalf("payment account before card replacement = %d", rec.Code)
	}
	pendingCards := toMap(t, payload["account"])["pending_checkouts"].([]any)
	if len(pendingCards) != 1 || toMap(t, pendingCards[0])["id"] != cardCheckout["id"] {
		t.Fatalf("active subscription must recover its own card update: %+v", pendingCards)
	}
	cardPath := strings.TrimPrefix(stringValue(cardCheckout["checkout_url"]), testPaymentsPublic)
	if rec, _ = do(http.MethodPost, "/v1"+cardPath, form("5555555555554444"), map[string]string{"Content-Type": "application/x-www-form-urlencoded"}); rec.Code != http.StatusSeeOther {
		t.Fatalf("card update form = %d body=%.200s", rec.Code, rec.Body.String())
	}
	rec, payload = do(http.MethodGet, "/v1/billing/checkout/"+stringValue(cardCheckout["id"]), "", nil)
	if rec.Code != http.StatusOK || toMap(t, payload["checkout"])["status"] != "completed" {
		t.Fatalf("card checkout after form = %d body=%s", rec.Code, rec.Body.String())
	}
	if sub = subscription(); sub["card_last4"] != "4444" || sub["card_brand"] != "mastercard" {
		t.Fatalf("card not replaced: %+v", sub)
	}
	// 10. Refund of the last settled charge: the renewal.
	simulate("refund")
	pays = paymentsList()
	var refunded map[string]any
	for _, p := range pays {
		if p["status"] == "refunded" {
			refunded = p
		}
	}
	if refunded == nil || refunded["refunded_amount"] != refunded["amount"] {
		t.Fatalf("refund not recorded: %+v", pays)
	}

	// 11. Failed renewal: past_due, still entitled inside the grace window.
	sub = simulate("renewal_failed")
	if sub["status"] != "past_due" || sub["entitled"] != true {
		t.Fatalf("after failed renewal: %+v", sub)
	}
	pays = paymentsList()
	if pays[0]["status"] != "failed" || stringValue(pays[0]["failure_reason"]) == "" {
		t.Fatalf("failed renewal payment: %+v", pays[0])
	}

	// 12. Recovery: next successful charge returns to active.
	if sub = simulate("renewal_paid"); sub["status"] != "active" {
		t.Fatalf("after recovery: %+v", sub)
	}

	// 13. Dispute on the last settled charge: at risk, then lost → chargeback.
	sub = simulate("dispute_open")
	pays = paymentsList()
	var disputed map[string]any
	for _, p := range pays {
		if p["status"] == "disputed" {
			disputed = p
		}
	}
	if disputed == nil || disputed["dispute_status"] != "needs_response" {
		t.Fatalf("dispute not recorded: %+v", pays)
	}
	simulate("dispute_lost")
	pays = paymentsList()
	var chargeback bool
	for _, p := range pays {
		if p["status"] == "chargeback" {
			chargeback = true
		}
	}
	if !chargeback {
		t.Fatalf("lost dispute must mark the payment as chargeback: %+v", pays)
	}
	// Product decision (2026-09-27): a lost dispute ends the subscription at
	// once, so reconciliation must no longer find it live, and revenue
	// excludes the chargeback.
	report, err := repo.reconcile(ctx, time.Now().Add(-time.Hour), time.Now().Add(time.Hour))
	if err != nil {
		t.Fatalf("reconcile: %v", err)
	}
	anomalies, _ := report["anomalies"].([]reconciliationAnomaly)
	var subRowID string
	if err := db.QueryRowContext(ctx, `SELECT id::text FROM matching.billing_subscriptions_runtime WHERE provider_subscription_id=$1`, providerSubID).Scan(&subRowID); err != nil {
		t.Fatalf("subscription row: %v", err)
	}
	for _, a := range anomalies {
		// Reconciliation spans the whole database; only this member's
		// subscription is under test here.
		if a.Type == "chargeback_on_live_subscription" && strings.Contains(a.Detail, subRowID) {
			t.Fatalf("a lost dispute must end the subscription, not leave it live: %+v", a)
		}
	}
	for _, p := range pays {
		if p["status"] == "chargeback" && p["refunded_amount"].(float64) > 0 {
			t.Fatalf("a charged-back payment must not also be marked refunded: %+v", p)
		}
	}
	if sub = subscription(); sub["plan_id"] != "free" || sub["is_paid"] != false {
		t.Fatalf("after a lost dispute expected the free tier, got %+v", sub)
	}
	var endedStatus string
	if err := db.QueryRowContext(ctx, `SELECT status FROM matching.billing_subscriptions_runtime WHERE provider_subscription_id=$1`, providerSubID).Scan(&endedStatus); err != nil || endedStatus != "cancelled" {
		t.Fatalf("charged-back subscription status = %q err=%v", endedStatus, err)
	}
	revenue := report["revenue"].(map[string]any)
	if revenue["chargeback_minor"].(int64) <= 0 || revenue["net_minor"].(int64) <= 0 {
		t.Fatalf("revenue summary wrong: %+v", revenue)
	}

	// Cancel with nothing live is refused.
	if rec, _ = do(http.MethodPost, "/v1/billing/subscription/"+userID+"/cancel", "", nil); rec.Code != http.StatusNotFound {
		t.Fatalf("cancel without paid subscription = %d", rec.Code)
	}

	// 13b. Coin packages: bought through payment-mode checkout, credited
	// only by the settled webhook, idempotent on replay; the legacy
	// client-asserted buy route is refused.
	rec, _ = do(http.MethodPost, "/v1/wallet/"+userID+"/coins/buy", `{"coins":500,"amount_minor":0}`, nil)
	if rec.Code != http.StatusConflict {
		t.Fatalf("legacy coin buy with provider configured = %d body=%s", rec.Code, rec.Body.String())
	}
	rec, payload = do(http.MethodGet, "/v1/billing/coin-packages", "", nil)
	if rec.Code != http.StatusOK {
		t.Fatalf("coin packages = %d body=%s", rec.Code, rec.Body.String())
	}
	pkgs, _ := payload["packages"].([]any)
	if len(pkgs) == 0 {
		t.Fatalf("no coin packages listed")
	}
	pkg := toMap(t, pkgs[0])
	pkgID := stringValue(pkg["id"])
	pkgCoins := int(pkg["total_coins"].(float64))
	rec, payload = do(http.MethodGet, "/v1/wallet/"+userID+"/coins", "", nil)
	if rec.Code != http.StatusOK {
		t.Fatalf("wallet before purchase = %d body=%s", rec.Code, rec.Body.String())
	}
	balanceBefore := int(toMap(t, payload["wallet"])["coin_balance"].(float64))
	rec, payload = do(http.MethodPost, "/v1/billing/checkout", `{"kind":"coin_package","package_id":"`+pkgID+`"}`, map[string]string{"Idempotency-Key": "coins-" + userID})
	if rec.Code != http.StatusCreated {
		t.Fatalf("coin checkout = %d body=%s", rec.Code, rec.Body.String())
	}
	coinCheckout := toMap(t, payload["checkout"])
	if coinCheckout["kind"] != "coin_package" || int(coinCheckout["coins"].(float64)) != pkgCoins {
		t.Fatalf("coin checkout row wrong: %+v", coinCheckout)
	}
	coinCheckoutID := stringValue(coinCheckout["id"])
	coinPath := strings.TrimPrefix(stringValue(coinCheckout["checkout_url"]), testPaymentsPublic)
	if rec, _ = do(http.MethodPost, "/v1"+coinPath, form(payments.SandboxCardSuccess), map[string]string{"Content-Type": "application/x-www-form-urlencoded"}); rec.Code != http.StatusSeeOther {
		t.Fatalf("coin card = %d body=%.200s", rec.Code, rec.Body.String())
	}
	rec, payload = do(http.MethodGet, "/v1/billing/checkout/"+coinCheckoutID, "", nil)
	if rec.Code != http.StatusOK || toMap(t, payload["checkout"])["status"] != "completed" {
		t.Fatalf("coin checkout after payment = %d body=%s", rec.Code, rec.Body.String())
	}
	wallet := toMap(t, payload["wallet"])
	if got := int(wallet["coin_balance"].(float64)); got != balanceBefore+pkgCoins {
		t.Fatalf("wallet after coin purchase = %d, want %d", got, balanceBefore+pkgCoins)
	}
	pays = paymentsList()
	if pays[0]["billing_reason"] != "coin_purchase" || pays[0]["status"] != "success" {
		t.Fatalf("coin payment row wrong: %+v", pays[0])
	}
	// Replay the settled event: no second credit, no second payment.
	var coinEventID string
	var coinPayload []byte
	if err := db.QueryRowContext(ctx, `SELECT event_id, payload FROM matching.billing_webhook_events WHERE provider='sandbox' AND event_type='checkout.session.completed' ORDER BY received_at DESC LIMIT 1`).Scan(&coinEventID, &coinPayload); err != nil {
		t.Fatal(err)
	}
	if rec, _ = do(http.MethodPost, "/v1/billing/webhooks/sandbox", string(coinPayload), map[string]string{"Stripe-Signature": payments.SignPayload(testSandboxSecret, time.Now(), coinPayload)}); rec.Code != http.StatusOK {
		t.Fatalf("coin webhook replay = %d", rec.Code)
	}
	rec, payload = do(http.MethodGet, "/v1/wallet/"+userID+"/coins", "", nil)
	if rec.Code != http.StatusOK {
		t.Fatalf("wallet after replay = %d", rec.Code)
	}
	if got := int(toMap(t, payload["wallet"])["coin_balance"].(float64)); got != balanceBefore+pkgCoins {
		t.Fatalf("replay credited twice: balance=%d want %d", got, balanceBefore+pkgCoins)
	}
	if len(paymentsList()) != len(pays) {
		t.Fatalf("replay created a payment row")
	}
	var coinEventRows int
	if err := db.QueryRowContext(ctx, `SELECT COUNT(*) FROM matching.billing_webhook_events WHERE provider='sandbox' AND event_id=$1`, coinEventID).Scan(&coinEventRows); err != nil || coinEventRows != 1 {
		t.Fatalf("coin event ledger rows = %d err=%v", coinEventRows, err)
	}
	rec, payload = do(http.MethodGet, "/v1/wallet/"+userID+"/coins/audit?limit=5", "", nil)
	if rec.Code != http.StatusOK {
		t.Fatalf("wallet audit = %d body=%s", rec.Code, rec.Body.String())
	}
	if audit, _ := payload["audit"].([]any); len(audit) == 0 || toMap(t, audit[0])["action"] != "wallet.coins.purchase" {
		t.Fatalf("wallet audit missing the settled purchase: %v", payload["audit"])
	}

	// 14. Grace expiry sweep: a past_due subscription beyond the grace window
	// expires even if the provider never says so.
	rec, payload = do(http.MethodPost, "/v1/billing/checkout", `{"plan_id":"silver","billing_cycle":"yearly"}`, nil)
	if rec.Code != http.StatusCreated {
		t.Fatalf("second checkout = %d body=%s", rec.Code, rec.Body.String())
	}
	sandboxPath = strings.TrimPrefix(stringValue(toMap(t, payload["checkout"])["checkout_url"]), testPaymentsPublic)
	if rec, _ = do(http.MethodPost, "/v1"+sandboxPath, form(payments.SandboxCardRenewalFails), map[string]string{"Content-Type": "application/x-www-form-urlencoded"}); rec.Code != http.StatusSeeOther {
		t.Fatalf("second card = %d body=%.200s", rec.Code, rec.Body.String())
	}
	if sub = subscription(); sub["plan_id"] != "silver" || sub["billing_cycle"] != "yearly" {
		t.Fatalf("second subscription: %+v", sub)
	}
	if amount, _ := sub["amount_minor"].(float64); amount != 9999 {
		t.Fatalf("silver yearly amount_minor = %v", sub["amount_minor"])
	}
	if sub = simulate("renewal_paid"); sub["status"] != "past_due" {
		t.Fatalf("the renewal-fails test card must go past_due, got %+v", sub)
	}
	if _, err := db.ExecContext(ctx, `UPDATE matching.billing_subscriptions_runtime SET current_period_end = NOW() - interval '8 days' WHERE user_id=$1 AND status='past_due'`, userID); err != nil {
		t.Fatal(err)
	}
	server.billing.sweepOnce(ctx)
	if sub = subscription(); sub["plan_id"] != "free" {
		t.Fatalf("grace expiry must drop to free tier, got %+v", sub)
	}
	var expiredCount int
	if err := db.QueryRowContext(ctx, `SELECT COUNT(*) FROM matching.billing_subscriptions_runtime WHERE user_id=$1 AND status='expired'`, userID).Scan(&expiredCount); err != nil || expiredCount != 1 {
		t.Fatalf("expired rows = %d err=%v", expiredCount, err)
	}

	// 15. Operators read the reconciliation report; members cannot.
	rec, _ = do(http.MethodGet, "/v1/admin/billing/reconciliation", "", nil)
	if rec.Code != http.StatusForbidden {
		t.Fatalf("member reconciliation access = %d", rec.Code)
	}
	installOperatorPrincipal(t, "ops-1", "admin")
	rec, payload = do(http.MethodGet, "/v1/admin/billing/reconciliation?since="+time.Now().Add(-time.Hour).UTC().Format(time.RFC3339), "", nil)
	if rec.Code != http.StatusOK {
		t.Fatalf("admin reconciliation = %d body=%s", rec.Code, rec.Body.String())
	}
	if payload["currency"] != "INR" || payload["anomaly_count"] == nil || toMap(t, payload["revenue"])["net_minor"] == nil {
		t.Fatalf("reconciliation payload wrong: %+v", payload)
	}
}
