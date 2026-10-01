package mobile

import (
	"context"
	"database/sql"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
)

// TestDailyLimitsFollowThePlanPostgres proves that likes and messages are
// capped by the member's plan, counted from durable rows, reported through
// the entitlements route and enforced with a structured 429.
func TestDailyLimitsFollowThePlanPostgres(t *testing.T) {
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

	userID := uuid.NewString()
	username := "limitqa_" + strings.ReplaceAll(userID[:8], "-", "")
	if _, err := db.ExecContext(ctx, `INSERT INTO user_management.users (id, username, name, date_of_birth, gender, email) VALUES ($1,$2,'Limit QA','1990-01-01','female',$3)`, userID, username, username+"@example.test"); err != nil {
		t.Fatalf("seed member: %v", err)
	}
	t.Cleanup(func() {
		_, _ = db.ExecContext(ctx, `DELETE FROM user_management.users WHERE id=$1`, userID)
	})

	server := newSandboxBillingServer(t)
	defer server.Close()
	repo := newBillingRepository(db)
	server.store.billingRepo = repo
	server.billing.repo = repo
	server.cfg.BillingEnforceDailyLimits = true
	installOperatorPrincipal(t, userID)

	var freeLikes, freeMessages int
	if err := db.QueryRowContext(ctx, `SELECT likes_per_day, messages_per_day FROM matching.billing_plans WHERE code='free'`).Scan(&freeLikes, &freeMessages); err != nil {
		t.Fatalf("free plan: %v", err)
	}
	if freeLikes < 1 || freeMessages < 1 {
		t.Skip("free plan is unlimited in this catalog")
	}

	entitlements := func() map[string]any {
		req := httptest.NewRequest(http.MethodGet, "/v1/billing/entitlements/"+userID, nil)
		rec := httptest.NewRecorder()
		server.Handler().ServeHTTP(rec, req)
		if rec.Code != http.StatusOK {
			t.Fatalf("entitlements = %d body=%s", rec.Code, rec.Body.String())
		}
		var payload map[string]any
		_ = json.Unmarshal(rec.Body.Bytes(), &payload)
		return payload
	}
	ent := entitlements()
	if ent["plan_id"] != "free" || ent["enforced"] != true {
		t.Fatalf("free entitlements: %+v", ent)
	}
	likes := toMap(t, ent["likes"])
	if int(likes["limit"].(float64)) != freeLikes || int(likes["used"].(float64)) != 0 {
		t.Fatalf("fresh like quota: %+v", likes)
	}

	// Spend today's likes on existing members.
	rows, err := db.QueryContext(ctx, `SELECT id::text FROM user_management.users WHERE id<>$1 ORDER BY created_at LIMIT $2`, userID, freeLikes)
	if err != nil {
		t.Fatal(err)
	}
	var targets []string
	for rows.Next() {
		var id string
		if err := rows.Scan(&id); err != nil {
			t.Fatal(err)
		}
		targets = append(targets, id)
	}
	rows.Close()
	if len(targets) < freeLikes {
		t.Skipf("need %d seeded members for like targets", freeLikes)
	}
	for _, target := range targets {
		if _, err := db.ExecContext(ctx, `INSERT INTO matching.swipes (user_id, target_user_id, is_like) VALUES ($1,$2,TRUE)`, userID, target); err != nil {
			t.Fatal(err)
		}
	}
	likes = toMap(t, entitlements()["likes"])
	if int(likes["used"].(float64)) != freeLikes || int(likes["remaining"].(float64)) != 0 {
		t.Fatalf("like quota after spending: %+v", likes)
	}

	// The next like is refused with a structured 429; a pass is not a like.
	body := `{"user_id":"` + userID + `","target_user_id":"` + uuid.NewString() + `","is_like":true}`
	req := httptest.NewRequest(http.MethodPost, "/v1/swipe", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, req)
	if rec.Code != http.StatusTooManyRequests {
		t.Fatalf("like over quota = %d body=%s", rec.Code, rec.Body.String())
	}
	var refusal map[string]any
	_ = json.Unmarshal(rec.Body.Bytes(), &refusal)
	if refusal["error_code"] != "DAILY_LIKE_LIMIT_REACHED" || int(refusal["limit"].(float64)) != freeLikes || refusal["plan_id"] != "free" {
		t.Fatalf("refusal payload: %+v", refusal)
	}
	if _, err := time.Parse(time.RFC3339, stringValue(refusal["resets_at"])); err != nil {
		t.Fatalf("resets_at not RFC3339: %v", refusal["resets_at"])
	}
	req = httptest.NewRequest(http.MethodPost, "/v1/swipe", strings.NewReader(`{"user_id":"`+userID+`","target_user_id":"`+uuid.NewString()+`","is_like":false}`))
	req.Header.Set("Content-Type", "application/json")
	rec = httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, req)
	if rec.Code == http.StatusTooManyRequests {
		t.Fatalf("a pass must never be rate limited by the like quota")
	}

	// Messages: seed a match and today's messages, then the quota bites.
	var matchID string
	// matches stores the pair ordered (user_id_1 < user_id_2).
	if err := db.QueryRowContext(ctx, `INSERT INTO matching.matches (user_id_1, user_id_2)
		VALUES (LEAST($1::uuid,$2::uuid), GREATEST($1::uuid,$2::uuid)) RETURNING id::text`, userID, targets[0]).Scan(&matchID); err != nil {
		t.Fatalf("seed match: %v", err)
	}
	for i := 0; i < freeMessages; i++ {
		if _, err := db.ExecContext(ctx, `INSERT INTO matching.messages (match_id, sender_id, text) VALUES ($1,$2,'hi')`, matchID, userID); err != nil {
			t.Fatal(err)
		}
	}
	messages := toMap(t, entitlements()["messages"])
	if int(messages["used"].(float64)) != freeMessages || int(messages["remaining"].(float64)) != 0 {
		t.Fatalf("message quota after spending: %+v", messages)
	}
	req = httptest.NewRequest(http.MethodPost, "/v1/chat/"+matchID+"/messages", strings.NewReader(`{"sender_id":"`+userID+`","text":"one more"}`))
	req.Header.Set("Content-Type", "application/json")
	rec = httptest.NewRecorder()
	if server.enforceDailyQuota(rec, req, userID, "message") {
		t.Fatalf("message over quota must be refused")
	}
	if rec.Code != http.StatusTooManyRequests || !strings.Contains(rec.Body.String(), "DAILY_MESSAGE_LIMIT_REACHED") {
		t.Fatalf("message refusal = %d body=%s", rec.Code, rec.Body.String())
	}

	// A gift is also inserted into matching.messages and can carry arbitrary
	// note text, so the gift endpoint must enforce the same message quota before
	// it creates a wallet or gift row.
	server.store.giftLedger = newGiftSendLedger(db)
	server.store.cfg.DefaultUnlockPolicyVariant = "allow_without_template"
	giftBody := `{"gift_id":"rose_red_single","sender_user_id":"` + userID + `","receiver_user_id":"` + targets[0] + `","message_text":"A note after the limit"}`
	giftReq := httptest.NewRequest(http.MethodPost, "/v1/chat/"+matchID+"/gifts/send", strings.NewReader(giftBody))
	giftReq.Header.Set("Content-Type", "application/json")
	giftReq.Header.Set("Idempotency-Key", "gift-note-over-quota")
	giftRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(giftRec, giftReq)
	if giftRec.Code != http.StatusTooManyRequests || !strings.Contains(giftRec.Body.String(), "DAILY_MESSAGE_LIMIT_REACHED") {
		t.Fatalf("gift note over message quota = %d body=%s", giftRec.Code, giftRec.Body.String())
	}
	var giftSends int
	if err := db.QueryRowContext(ctx, `SELECT COUNT(*) FROM matching.match_gift_sends WHERE match_id=$1`, matchID).Scan(&giftSends); err != nil {
		t.Fatal(err)
	}
	if giftSends != 0 {
		t.Fatalf("quota-refused gift must not create a send row, got %d", giftSends)
	}
	var walletRows int
	if err := db.QueryRowContext(ctx, `SELECT COUNT(*) FROM matching.user_wallets WHERE user_id=$1`, userID).Scan(&walletRows); err != nil {
		t.Fatal(err)
	}
	if walletRows != 0 {
		t.Fatalf("quota-refused gift must not create or debit a wallet, got %d rows", walletRows)
	}

	// A paid plan lifts the cap: gold is unlimited in the seeded catalog.
	if _, err := db.ExecContext(ctx, `
		INSERT INTO matching.billing_subscriptions_runtime (user_id, plan_code, status, billing_cycle, start_date, next_billing_date, auto_renew, provider, provider_subscription_id, current_period_start, current_period_end, amount_minor, currency)
		VALUES ($1,'gold','active','monthly',NOW(),NOW()+interval '30 days',TRUE,'sandbox',$2,NOW(),NOW()+interval '30 days',1999,'INR')`, userID, "sub_sandbox_"+userID[:8]); err != nil {
		t.Fatal(err)
	}
	ent = entitlements()
	if ent["plan_id"] != "gold" || toMap(t, ent["likes"])["unlimited"] != true || toMap(t, ent["messages"])["unlimited"] != true {
		t.Fatalf("gold entitlements: %+v", ent)
	}
	rec = httptest.NewRecorder()
	if !server.enforceDailyQuota(rec, req, userID, "message") {
		t.Fatalf("gold member must not be capped: %s", rec.Body.String())
	}

	// Gold can send the same noted gift. Its completed idempotent replay must
	// remain successful after the member returns to an exhausted Free plan and
	// must not write a second message or debit again.
	giftReq = httptest.NewRequest(http.MethodPost, "/v1/chat/"+matchID+"/gifts/send", strings.NewReader(giftBody))
	giftReq.Header.Set("Content-Type", "application/json")
	giftReq.Header.Set("Idempotency-Key", "gift-note-gold")
	giftRec = httptest.NewRecorder()
	server.Handler().ServeHTTP(giftRec, giftReq)
	if giftRec.Code != http.StatusOK {
		t.Fatalf("gold gift note = %d body=%s", giftRec.Code, giftRec.Body.String())
	}
	var messageRowsBeforeReplay int
	if err := db.QueryRowContext(ctx, `SELECT COUNT(*) FROM matching.messages WHERE match_id=$1 AND sender_id=$2`, matchID, userID).Scan(&messageRowsBeforeReplay); err != nil {
		t.Fatal(err)
	}

	// Switching enforcement off keeps the report but stops the refusal.
	if _, err := db.ExecContext(ctx, `DELETE FROM matching.billing_subscriptions_runtime WHERE user_id=$1`, userID); err != nil {
		t.Fatal(err)
	}
	giftReq = httptest.NewRequest(http.MethodPost, "/v1/chat/"+matchID+"/gifts/send", strings.NewReader(giftBody))
	giftReq.Header.Set("Content-Type", "application/json")
	giftReq.Header.Set("Idempotency-Key", "gift-note-gold")
	giftRec = httptest.NewRecorder()
	server.Handler().ServeHTTP(giftRec, giftReq)
	if giftRec.Code != http.StatusOK || giftRec.Header().Get("X-Idempotent-Replay") != "true" {
		t.Fatalf("gift retry after quota exhaustion = %d replay=%q body=%s", giftRec.Code, giftRec.Header().Get("X-Idempotent-Replay"), giftRec.Body.String())
	}
	var messageRowsAfterReplay int
	if err := db.QueryRowContext(ctx, `SELECT COUNT(*) FROM matching.messages WHERE match_id=$1 AND sender_id=$2`, matchID, userID).Scan(&messageRowsAfterReplay); err != nil {
		t.Fatal(err)
	}
	if messageRowsAfterReplay != messageRowsBeforeReplay {
		t.Fatalf("gift replay wrote another message: before=%d after=%d", messageRowsBeforeReplay, messageRowsAfterReplay)
	}
	server.cfg.BillingEnforceDailyLimits = false
	rec = httptest.NewRecorder()
	if !server.enforceDailyQuota(rec, req, userID, "message") {
		t.Fatalf("enforcement switch must disable refusals")
	}
	if entitlements()["enforced"] != false {
		t.Fatalf("entitlements must report enforcement off")
	}
}
