package mobile

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/verified-dating/backend/internal/platform/config"
)

func TestCoinCheckoutFraudThrottleCreatesDurableCasePostgres(t *testing.T) {
	db := walletIntegrityDB(t)
	var ready bool
	if err := db.QueryRow(`SELECT to_regclass('matching.coin_economy_fraud_cases') IS NOT NULL`).Scan(&ready); err != nil || !ready {
		t.Skip("migration 089 is not applied")
	}
	member, _ := seedTrustMember(t, db)
	ctx := context.Background()
	repo := newBillingRepository(db)
	var packageID string
	if err := db.QueryRow(`SELECT id::text FROM matching.coin_packages WHERE is_active ORDER BY id LIMIT 1`).Scan(&packageID); err != nil {
		t.Skipf("no coin package: %v", err)
	}
	rule := "qa_checkout_" + member[:8]
	if _, err := db.Exec(`INSERT INTO matching.coin_economy_fraud_rules(rule_code,event_type,metric,window_seconds,trigger_value,response_action,severity,description) VALUES($1,'coin_checkout','coin_checkout_count',3600,1,'throttle','high','QA rule')`, rule); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		_, _ = db.Exec(`DELETE FROM matching.coin_economy_fraud_cases WHERE user_id=$1`, member)
		_, _ = db.Exec(`DELETE FROM matching.coin_economy_fraud_rules WHERE rule_code=$1`, rule)
		_, _ = db.Exec(`DELETE FROM matching.billing_checkout_sessions WHERE user_id=$1`, member)
	})
	_, err := repo.reserveCoinCheckout(ctx, member, packageID, "sandbox", "fraud-test", 10, 100, "INR", time.Now().UTC())
	var control *errEconomyFraudControl
	if !errors.As(err, &control) || control.Action != "throttle" {
		t.Fatalf("reserve err=%v, want throttle", err)
	}
	var cases, checkouts int
	if err := db.QueryRow(`SELECT COUNT(*) FROM matching.coin_economy_fraud_cases WHERE user_id=$1 AND rule_code=$2 AND action_taken='throttle'`, member, rule).Scan(&cases); err != nil {
		t.Fatal(err)
	}
	if err := db.QueryRow(`SELECT COUNT(*) FROM matching.billing_checkout_sessions WHERE user_id=$1 AND idempotency_key='fraud-test'`, member).Scan(&checkouts); err != nil {
		t.Fatal(err)
	}
	if cases != 1 || checkouts != 0 {
		t.Fatalf("cases=%d checkouts=%d, want 1/0", cases, checkouts)
	}
}

func TestFraudFalsePositiveResolutionClearsAttributedLockPostgres(t *testing.T) {
	db := walletIntegrityDB(t)
	member, _ := seedTrustMember(t, db)
	now := time.Now().UTC()
	tx, err := db.BeginTx(context.Background(), nil)
	if err != nil {
		t.Fatal(err)
	}
	if err = ensureWalletTx(context.Background(), tx, member, now); err != nil {
		t.Fatal(err)
	}
	decision := economyFraudDecision{RuleCode: "gift_burst_temporary_lock", EventType: "gift_send", Severity: "high", RecommendedAction: "temporary_lock", ActionTaken: "temporary_lock", ObservedValue: 10, TriggerValue: 10, WindowSeconds: 300, LockSeconds: 1800}
	if _, err = recordEconomyFraudDecisionsTx(context.Background(), tx, member, []economyFraudDecision{decision}, now); err != nil {
		t.Fatal(err)
	}
	if err = tx.Commit(); err != nil {
		t.Fatal(err)
	}
	var caseID string
	if err = db.QueryRow(`SELECT id::text FROM matching.coin_economy_fraud_cases WHERE user_id=$1 AND rule_code=$2 AND status='open'`, member, decision.RuleCode).Scan(&caseID); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _, _ = db.Exec(`DELETE FROM matching.coin_economy_fraud_cases WHERE user_id=$1`, member) })

	server := newQuestWorkflowTestServerWithConfig(t, func(cfg *config.Config) { cfg.BFFRequestTimeoutSec = 10 })
	defer server.Close()
	server.store.billingRepo = newBillingRepository(db)
	installOperatorPrincipal(t, member, "admin")
	req := httptest.NewRequest(http.MethodPost, "/v1/admin/billing/fraud/cases/"+caseID+"/resolve", strings.NewReader(`{"resolution":"cleared","note":"Confirmed legitimate member activity."}`))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Idempotency-Key", "clear-"+caseID)
	rec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("resolve=%d body=%s", rec.Code, rec.Body.String())
	}
	var status string
	var locked bool
	if err = db.QueryRow(`SELECT status FROM matching.coin_economy_fraud_cases WHERE id=$1::uuid`, caseID).Scan(&status); err != nil {
		t.Fatal(err)
	}
	if err = db.QueryRow(`SELECT risk_locked_until IS NOT NULL FROM matching.user_wallets WHERE user_id=$1`, member).Scan(&locked); err != nil {
		t.Fatal(err)
	}
	if status != "cleared" || locked {
		t.Fatalf("status=%s locked=%v, want cleared/false", status, locked)
	}
}

func TestFraudResponseFlagDowngradesToReviewOnlyPostgres(t *testing.T) {
	db := walletIntegrityDB(t)
	member, _ := seedTrustMember(t, db)
	ctx := context.Background()
	repo := newBillingRepository(db)
	var packageID string
	if err := db.QueryRow(`SELECT id::text FROM matching.coin_packages WHERE is_active ORDER BY id LIMIT 1`).Scan(&packageID); err != nil {
		t.Skipf("no coin package: %v", err)
	}
	rule := "qa_review_" + member[:8]
	if _, err := db.Exec(`INSERT INTO matching.coin_economy_fraud_rules(rule_code,event_type,metric,window_seconds,trigger_value,response_action,severity,description) VALUES($1,'coin_checkout','coin_checkout_count',3600,1,'throttle','medium','QA review-only rule')`, rule); err != nil {
		t.Skipf("migration 089 unavailable: %v", err)
	}
	if _, err := db.Exec(`UPDATE matching.platform_feature_flags SET value_bool=FALSE WHERE key='coin_economy_fraud_responses_enabled'`); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		_, _ = db.Exec(`UPDATE matching.platform_feature_flags SET value_bool=TRUE WHERE key='coin_economy_fraud_responses_enabled'`)
		_, _ = db.Exec(`DELETE FROM matching.coin_economy_fraud_cases WHERE user_id=$1`, member)
		_, _ = db.Exec(`DELETE FROM matching.coin_economy_fraud_rules WHERE rule_code=$1`, rule)
		_, _ = db.Exec(`DELETE FROM matching.billing_checkout_sessions WHERE user_id=$1`, member)
	})
	id, err := repo.reserveCoinCheckout(ctx, member, packageID, "sandbox", "review-test", 10, 100, "INR", time.Now().UTC())
	if err != nil || id == "" {
		t.Fatalf("review-only reserve id=%q err=%v", id, err)
	}
	var action string
	if err := db.QueryRow(`SELECT action_taken FROM matching.coin_economy_fraud_cases WHERE user_id=$1 AND rule_code=$2`, member, rule).Scan(&action); err != nil {
		t.Fatal(err)
	}
	if action != "review_only" {
		t.Fatalf("action=%q", action)
	}
}
