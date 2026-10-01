package mobile

import (
	"context"
	"database/sql"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/verified-dating/backend/internal/platform/payments"
)

// Postgres-backed tests for Epic 4: coin clawback, frozen wallets, lost
// disputes, gift reversal, gift velocity limits and coin liability.

func walletIntegrityDB(t *testing.T) *sql.DB {
	t.Helper()
	db := trustOpsDB(t)
	var ready bool
	if err := db.QueryRow(`SELECT to_regclass('matching.wallet_coin_debits') IS NOT NULL`).Scan(&ready); err != nil || !ready {
		t.Skip("migration 084 is not applied")
	}
	return db
}

type coinPurchaseFixture struct {
	userID, checkoutID, paymentID, intent string
	coins                                 int
	amount                                int64
}

// seedCoinPurchase records a settled coin checkout, its payment and the wallet
// credit, leaving the wallet at `balance` coins.
func seedCoinPurchase(t *testing.T, db *sql.DB, userID string, coins int, amount int64, balance int) coinPurchaseFixture {
	t.Helper()
	var packageID string
	if err := db.QueryRow(`SELECT id::text FROM matching.coin_packages ORDER BY id LIMIT 1`).Scan(&packageID); err != nil {
		t.Skipf("no coin package to reference: %v", err)
	}
	f := coinPurchaseFixture{userID: userID, coins: coins, amount: amount, intent: "pi_" + uuid.NewString()[:12]}
	if err := db.QueryRow(`INSERT INTO matching.billing_checkout_sessions
		(user_id, provider, idempotency_key, status, amount_minor, currency, kind, package_id, coins, completed_at)
		VALUES ($1,'sandbox',$2,'completed',$3,'INR','coin_package',$4,$5,NOW()) RETURNING id::text`,
		userID, "idem-"+uuid.NewString(), amount, packageID, coins).Scan(&f.checkoutID); err != nil {
		t.Fatalf("seed checkout: %v", err)
	}
	if err := db.QueryRow(`INSERT INTO matching.billing_payments_runtime
		(user_id, checkout_id, amount_paise, currency, status, provider, provider_payment_id, billing_reason, paid_at)
		VALUES ($1,$2::uuid,$3,'INR','success','sandbox',$4,'coin_purchase',NOW()) RETURNING id::text`,
		userID, f.checkoutID, amount, f.intent).Scan(&f.paymentID); err != nil {
		t.Fatalf("seed payment: %v", err)
	}
	if _, err := db.Exec(`INSERT INTO matching.user_wallets (user_id, coin_balance) VALUES ($1,$2)
		ON CONFLICT (user_id) DO UPDATE SET coin_balance=EXCLUDED.coin_balance`, userID, balance); err != nil {
		t.Fatal(err)
	}
	if _, err := db.Exec(`INSERT INTO matching.wallet_coin_purchases
		(id,user_id,package_id,source,provider,idempotency_key,coins,amount_minor,currency,wallet_balance_after)
		VALUES (gen_random_uuid(),$1,$2,'buy','sandbox','checkout:'||$3,$4,$5,'INR',$4)`,
		userID, packageID, f.checkoutID, coins, amount); err != nil {
		t.Fatalf("seed credit: %v", err)
	}
	t.Cleanup(func() {
		_, _ = db.Exec(`DELETE FROM matching.wallet_coin_debits WHERE user_id=$1`, userID)
		_, _ = db.Exec(`DELETE FROM matching.billing_payments_runtime WHERE id=$1`, f.paymentID)
		_, _ = db.Exec(`DELETE FROM matching.billing_checkout_sessions WHERE id=$1::uuid`, f.checkoutID)
	})
	return f
}

func walletState(t *testing.T, db *sql.DB, userID string) (balance, debt int, frozen bool) {
	t.Helper()
	if err := db.QueryRow(`SELECT coin_balance, debt_coins, frozen_at IS NOT NULL FROM matching.user_wallets WHERE user_id=$1`,
		userID).Scan(&balance, &debt, &frozen); err != nil {
		t.Fatal(err)
	}
	return
}

func refundEvent(f coinPurchaseFixture, refunded int64, full bool) payments.Event {
	return payments.Event{
		Provider: "sandbox", ID: "evt_" + uuid.NewString(), Type: payments.EventChargeRefunded,
		CreatedAt: time.Now().UTC(),
		Refund: &payments.RefundEvent{PaymentIntentID: f.intent, AmountRefunded: refunded,
			AmountCharged: f.amount, Currency: "INR", FullyRefunded: full},
	}
}

func lostDisputeEvent(intent string) payments.Event {
	return payments.Event{
		Provider: "sandbox", ID: "evt_" + uuid.NewString(), Type: payments.EventDisputeUpdated,
		CreatedAt: time.Now().UTC(),
		Dispute: &payments.DisputeEvent{DisputeID: "dp_" + uuid.NewString()[:8], PaymentIntentID: intent,
			Status: "lost", Reason: "fraudulent", Closed: true},
	}
}

func TestCoinRefundTakesCoinsBackOncePostgres(t *testing.T) {
	db := walletIntegrityDB(t)
	member, _ := seedTrustMember(t, db)
	repo := newBillingRepository(db)
	ctx := context.Background()
	f := seedCoinPurchase(t, db, member, 50, 9900, 80)

	// Half refunded: half the coins come back.
	if err := repo.applyEvent(ctx, refundEvent(f, 4950, false), nil); err != nil {
		t.Fatalf("partial refund: %v", err)
	}
	if balance, debt, frozen := walletState(t, db, member); balance != 55 || debt != 0 || frozen {
		t.Fatalf("after partial refund balance=%d debt=%d frozen=%v, want 55/0/false", balance, debt, frozen)
	}
	// Fully refunded: the rest comes back; replaying changes nothing.
	full := refundEvent(f, 9900, true)
	for i := 0; i < 2; i++ {
		if err := repo.applyEvent(ctx, full, nil); err != nil {
			t.Fatalf("full refund: %v", err)
		}
	}
	if balance, _, frozen := walletState(t, db, member); balance != 30 || frozen {
		t.Fatalf("after full refund balance=%d frozen=%v, want 30/false", balance, frozen)
	}
	var debitEvents int
	if err := db.QueryRow(`
		SELECT COUNT(*) FROM platform.domain_event_outbox e
		JOIN matching.wallet_coin_debits d ON d.id::text=e.aggregate_id
		WHERE d.payment_id=$1::uuid AND e.event_name='matching.wallet_coin_debits.created'
		  AND e.aggregate_type='wallet.debit'`, f.paymentID).Scan(&debitEvents); err != nil {
		t.Fatal(err)
	}
	if debitEvents != 2 {
		t.Fatalf("refund debit events=%d, want one partial and one final event", debitEvents)
	}
}

func TestChargebackAfterSpendingFreezesWalletWithDebtPostgres(t *testing.T) {
	db := walletIntegrityDB(t)
	member, _ := seedTrustMember(t, db)
	repo := newBillingRepository(db)
	ctx := context.Background()
	f := seedCoinPurchase(t, db, member, 50, 9900, 10) // 40 coins already spent

	if err := repo.applyEvent(ctx, lostDisputeEvent(f.intent), nil); err != nil {
		t.Fatalf("chargeback: %v", err)
	}
	balance, debt, frozen := walletState(t, db, member)
	if balance != 0 || debt != 40 || !frozen {
		t.Fatalf("balance=%d debt=%d frozen=%v, want 0/40/true", balance, debt, frozen)
	}
	if _, err := repo.reviewFrozenWallet(ctx, member, "", "ops_admin", "collect_and_unfreeze", "Checked the dispute evidence."); !errors.Is(err, errWalletDebtOutstanding) {
		t.Fatalf("collect with unpaid debt: err=%v", err)
	}
	result, err := repo.reviewFrozenWallet(ctx, member, "", "ops_admin", "write_off_and_unfreeze", "Low-value first offence, written off.")
	if err != nil || result.DebtWrittenOff != 40 {
		t.Fatalf("write off: result=%+v err=%v", result, err)
	}
	if _, debt, frozen := walletState(t, db, member); debt != 0 || frozen {
		t.Fatalf("after review debt=%d frozen=%v", debt, frozen)
	}
}

func TestRefundBeforeCreditIsReconciledAfterCreditPostgres(t *testing.T) {
	db := walletIntegrityDB(t)
	member, _ := seedTrustMember(t, db)
	repo := newBillingRepository(db)
	ctx := context.Background()
	f := seedCoinPurchase(t, db, member, 50, 9900, 50)
	// Simulate the refund landing before the credit: remove the credit first.
	if _, err := db.Exec(`DELETE FROM matching.wallet_coin_purchases WHERE idempotency_key='checkout:'||$1`, f.checkoutID); err != nil {
		t.Fatal(err)
	}
	if _, err := db.Exec(`UPDATE matching.user_wallets SET coin_balance=0 WHERE user_id=$1`, member); err != nil {
		t.Fatal(err)
	}
	if err := repo.applyEvent(ctx, refundEvent(f, 9900, true), nil); err != nil {
		t.Fatalf("refund: %v", err)
	}
	// Now the credit arrives.
	if _, err := db.Exec(`UPDATE matching.user_wallets SET coin_balance=50 WHERE user_id=$1`, member); err != nil {
		t.Fatal(err)
	}
	if _, err := db.Exec(`INSERT INTO matching.wallet_coin_purchases
		(id,user_id,package_id,source,provider,idempotency_key,coins,amount_minor,currency,wallet_balance_after)
		SELECT gen_random_uuid(),$1,package_id,'buy','sandbox','checkout:'||$2,50,9900,'INR',50
		FROM matching.billing_checkout_sessions WHERE id=$2::uuid`, member, f.checkoutID); err != nil {
		t.Fatal(err)
	}
	if err := repo.reconcileCoinReversalForCheckout(ctx, f.checkoutID, "sandbox"); err != nil {
		t.Fatalf("reconcile: %v", err)
	}
	if balance, _, _ := walletState(t, db, member); balance != 0 {
		t.Fatalf("refunded coins credited late must be taken back; balance=%d", balance)
	}
}

func TestLostDisputeEndsSubscriptionImmediatelyPostgres(t *testing.T) {
	db := walletIntegrityDB(t)
	member, _ := seedTrustMember(t, db)
	repo := newBillingRepository(db)
	ctx := context.Background()
	var planCode string
	if err := db.QueryRow(`SELECT code FROM matching.billing_plans WHERE code<>'free' ORDER BY code LIMIT 1`).Scan(&planCode); err != nil {
		t.Skipf("no paid plan: %v", err)
	}
	subRef := "sub_" + uuid.NewString()[:10]
	var subID string
	if err := db.QueryRow(`INSERT INTO matching.billing_subscriptions_runtime
		(user_id, plan_code, status, billing_cycle, start_date, auto_renew, provider, provider_subscription_id,
		 current_period_start, current_period_end)
		VALUES ($1,$2,'active','monthly',NOW()-INTERVAL '3 days',TRUE,'sandbox',$3,NOW()-INTERVAL '3 days',NOW()+INTERVAL '27 days')
		RETURNING id::text`, member, planCode, subRef).Scan(&subID); err != nil {
		t.Fatalf("seed subscription: %v", err)
	}
	intent := "pi_" + uuid.NewString()[:12]
	if _, err := db.Exec(`INSERT INTO matching.billing_payments_runtime
		(user_id, subscription_id, amount_paise, currency, status, provider, provider_payment_id, billing_reason, paid_at)
		VALUES ($1,$2::uuid,49900,'INR','success','sandbox',$3,'subscription_create',NOW())`, member, subID, intent); err != nil {
		t.Fatalf("seed payment: %v", err)
	}
	t.Cleanup(func() {
		_, _ = db.Exec(`DELETE FROM matching.billing_payments_runtime WHERE subscription_id=$1::uuid`, subID)
		_, _ = db.Exec(`DELETE FROM matching.billing_subscriptions_runtime WHERE id=$1::uuid`, subID)
	})
	if err := repo.applyEvent(ctx, lostDisputeEvent(intent), nil); err != nil {
		t.Fatalf("lost dispute: %v", err)
	}
	var status, reason string
	if err := db.QueryRow(`SELECT status, COALESCE(metadata->>'ended_reason','') FROM matching.billing_subscriptions_runtime WHERE id=$1::uuid`, subID).Scan(&status, &reason); err != nil {
		t.Fatal(err)
	}
	if status != "cancelled" || reason != "chargeback" {
		t.Fatalf("subscription status=%q reason=%q, want cancelled/chargeback", status, reason)
	}
	ids, err := repo.chargebackProviderSubscriptions(ctx, "sandbox", intent, "")
	if err != nil || len(ids) != 1 || ids[0] != subRef {
		t.Fatalf("renewal stop targets = %v err=%v", ids, err)
	}
}

func TestGiftReversalRefundsSenderAndRetractsMessagePostgres(t *testing.T) {
	_ = walletIntegrityDB(t)
	f := newGiftLedgerFixture(t, 20)
	view, err := f.send("rose_sparkle", "reverse-1")
	if err != nil {
		t.Fatalf("send: %v", err)
	}
	operator, _ := seedTrustMember(t, f.db)
	result, err := f.ledger.reverse(context.Background(), view.ID, operator, "trust_safety", "Sent by mistake, member asked for help")
	if err != nil {
		t.Fatalf("reverse: %v", err)
	}
	if result.CoinsRefunded != 3 || result.SenderBalance != 20 || !result.MessageRetracted {
		t.Fatalf("reversal = %+v", result)
	}
	var status string
	var deleted bool
	if err := f.db.QueryRow(`SELECT s.status, m.is_deleted FROM matching.match_gift_sends s
		JOIN matching.messages m ON m.gift_send_id=s.id WHERE s.id=$1`, view.ID).Scan(&status, &deleted); err != nil {
		t.Fatal(err)
	}
	if status != "refunded" || !deleted {
		t.Fatalf("status=%q deleted=%v", status, deleted)
	}
	if _, err := f.ledger.reverse(context.Background(), view.ID, operator, "trust_safety", "second try"); !errors.Is(err, errGiftAlreadyReversed) {
		t.Fatalf("second reversal: err=%v", err)
	}
}

func TestGiftVelocityLimitRefusesAndRecordsSignalPostgres(t *testing.T) {
	_ = walletIntegrityDB(t)
	f := newGiftLedgerFixture(t, 100)
	f.ledger.limits = giftVelocityLimits{MaxPaidSendsPerHour: 2}
	for i := 0; i < 2; i++ {
		if _, err := f.send("rose_blue_rare", uuid.NewString()); err != nil {
			t.Fatalf("send %d: %v", i, err)
		}
	}
	_, err := f.send("rose_blue_rare", uuid.NewString())
	var velocity *errGiftVelocityLimit
	if !errors.As(err, &velocity) || velocity.Limit != "paid_sends_per_hour" {
		t.Fatalf("third send: err=%v", err)
	}
	var signals int
	if err := f.db.QueryRow(`SELECT COUNT(*) FROM audit.security_events
		WHERE event_type='fraud.gift_velocity_limit' AND subject_user_id=$1`, f.sender).Scan(&signals); err != nil {
		t.Fatal(err)
	}
	if signals != 1 || f.balance(t) != 98 {
		t.Fatalf("signals=%d balance=%d", signals, f.balance(t))
	}
}

func TestFrozenWalletBlocksPaidGiftsOnlyPostgres(t *testing.T) {
	_ = walletIntegrityDB(t)
	f := newGiftLedgerFixture(t, 20)
	if _, err := f.db.Exec(`UPDATE matching.user_wallets SET frozen_at=NOW(), frozen_reason='test' WHERE user_id=$1`, f.sender); err != nil {
		t.Fatal(err)
	}
	if _, err := f.send("rose_sparkle", uuid.NewString()); !errors.Is(err, errWalletFrozen) {
		t.Fatalf("paid gift from frozen wallet: err=%v", err)
	}
	if _, err := f.send("rose_red_single", uuid.NewString()); err != nil {
		t.Fatalf("free gift from frozen wallet should be allowed: %v", err)
	}
}

func TestCoinLiabilityReconcilesNewWalletsPostgres(t *testing.T) {
	db := walletIntegrityDB(t)
	member, _ := seedTrustMember(t, db)
	match, _ := seedTrustMember(t, db)
	_ = match
	ctx := context.Background()
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		t.Fatal(err)
	}
	if err := ensureWalletTx(ctx, tx, member, time.Now().UTC()); err != nil {
		t.Fatal(err)
	}
	if err := tx.Commit(); err != nil {
		t.Fatal(err)
	}
	_, anomalies, err := newBillingRepository(db).coinLiability(ctx)
	if err != nil {
		t.Fatal(err)
	}
	for _, a := range anomalies {
		if a.ID == member {
			t.Fatalf("a new wallet must reconcile: %s", a.Detail)
		}
	}
	var credits int
	if err := db.QueryRow(`SELECT COUNT(*) FROM matching.wallet_coin_purchases WHERE user_id=$1`, member).Scan(&credits); err != nil {
		t.Fatal(err)
	}
	var balance int
	if err := db.QueryRow(`SELECT coin_balance FROM matching.user_wallets WHERE user_id=$1`, member).Scan(&balance); err != nil {
		t.Fatal(err)
	}
	if balance != 0 || credits != 0 {
		t.Fatalf("new wallet balance=%d credits=%d, want an empty wallet with no synthetic credit", balance, credits)
	}
}
