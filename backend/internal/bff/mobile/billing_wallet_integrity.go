package mobile

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"math"
	"strings"
	"time"
)

// Billing and wallet integrity (migration 084).
//
// Product decisions (2026-09-27):
//   - A refunded or charged-back coin purchase takes its coins back. What the
//     balance can cover is debited; any shortfall is recorded as debt and the
//     wallet is frozen (no spending) until an operator reviews it. Balances
//     never go negative.
//   - A lost dispute on a subscription payment ends the subscription at once.

var (
	errWalletFrozen          = errors.New("wallet is frozen pending review of a reversed coin purchase")
	errWalletReviewAction    = errors.New("action must be collect_and_unfreeze or write_off_and_unfreeze")
	errWalletReviewNote      = errors.New("note must explain the review (10-1000 characters)")
	errWalletNotFrozen       = errors.New("wallet is not frozen")
	errWalletDebtOutstanding = errors.New("wallet still has unpaid debt after collection; write it off or wait for a top-up")
)

// reverseCoinPurchasePaymentsTx applies coin clawback to every coin-purchase
// payment matching a provider charge. Called inside the webhook transaction.
func reverseCoinPurchasePaymentsTx(ctx context.Context, tx *sql.Tx, provider, paymentIntentID, chargeID, eventID string, now time.Time) error {
	rows, err := tx.QueryContext(ctx, `
		SELECT id::text FROM matching.billing_payments_runtime
		WHERE provider=$1 AND (provider_payment_id=$2 OR provider_charge_id=$3)
		  AND billing_reason='coin_purchase'`, provider, paymentIntentID, chargeID)
	if err != nil {
		return err
	}
	var ids []string
	for rows.Next() {
		var id string
		if err := rows.Scan(&id); err != nil {
			rows.Close()
			return err
		}
		ids = append(ids, id)
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return err
	}
	for _, id := range ids {
		if _, err := reverseCoinPurchaseTx(ctx, tx, id, provider, eventID, now); err != nil {
			return err
		}
	}
	return nil
}

type coinReversal struct {
	Requested int
	Debited   int
	Shortfall int
}

// reverseCoinPurchaseTx brings the coins taken back for one coin payment in
// line with its current refund/chargeback state. It is idempotent: it computes
// the total owed back from what was credited and what has already been
// reversed, and applies only the difference. It is safe in either order with
// the wallet credit, which runs after the webhook transaction commits.
func reverseCoinPurchaseTx(ctx context.Context, tx *sql.Tx, paymentID, provider, eventID string, now time.Time) (coinReversal, error) {
	var (
		userID, status        string
		checkoutID            sql.NullString
		amount, refundedMinor int64
	)
	if err := tx.QueryRowContext(ctx, `
		SELECT user_id::text, checkout_id::text, status, amount_paise, refunded_amount_paise
		FROM matching.billing_payments_runtime WHERE id=$1::uuid FOR UPDATE`, paymentID).Scan(
		&userID, &checkoutID, &status, &amount, &refundedMinor); err != nil {
		return coinReversal{}, err
	}
	if !checkoutID.Valid {
		return coinReversal{}, nil
	}
	var credited int
	if err := tx.QueryRowContext(ctx, `
		SELECT COALESCE(SUM(coins),0) FROM matching.wallet_coin_purchases
		WHERE user_id=$1::uuid AND idempotency_key='checkout:'||$2`, userID, checkoutID.String).Scan(&credited); err != nil {
		return coinReversal{}, err
	}
	target := 0
	switch status {
	case "refunded", "chargeback":
		target = credited
	case "partially_refunded":
		if amount > 0 {
			target = int(math.Round(float64(credited) * float64(refundedMinor) / float64(amount)))
		}
	}
	if target > credited {
		target = credited
	}
	var already int
	if err := tx.QueryRowContext(ctx, `
		SELECT COALESCE(SUM(coins_requested),0) FROM matching.wallet_coin_debits
		WHERE payment_id=$1::uuid AND source IN ('purchase_refund','purchase_chargeback')`, paymentID).Scan(&already); err != nil {
		return coinReversal{}, err
	}
	delta := target - already
	if delta <= 0 {
		return coinReversal{}, nil
	}

	var balance int
	if err := tx.QueryRowContext(ctx, `
		SELECT coin_balance FROM matching.user_wallets WHERE user_id=$1::uuid FOR UPDATE`, userID).Scan(&balance); err != nil {
		return coinReversal{}, err
	}
	debited := delta
	if debited > balance {
		debited = balance
	}
	shortfall := delta - debited
	after := balance - debited
	if _, err := tx.ExecContext(ctx, `
		UPDATE matching.user_wallets
		SET coin_balance=$2, debt_coins=debt_coins+$3,
		    frozen_at=CASE WHEN $3>0 THEN COALESCE(frozen_at,$4) ELSE frozen_at END,
		    frozen_reason=CASE WHEN $3>0 THEN 'coin_purchase_reversed' ELSE frozen_reason END,
		    updated_at=$4
		WHERE user_id=$1::uuid`, userID, after, shortfall, now); err != nil {
		return coinReversal{}, err
	}
	source := "purchase_refund"
	if status == "chargeback" {
		source = "purchase_chargeback"
	}
	// One slot per (event, payment): a replayed event lands once, while a
	// later event for the same payment (partial then full refund) gets its own.
	var eventRef any
	if strings.TrimSpace(eventID) != "" {
		eventRef = eventID + ":" + paymentID
	}
	if _, err := tx.ExecContext(ctx, `
		INSERT INTO matching.wallet_coin_debits
		  (user_id, source, payment_id, checkout_id, coins_requested, coins_debited, coins_shortfall,
		   wallet_balance_after, provider, provider_event_id, created_at)
		VALUES ($1::uuid,$2,$3::uuid,$4::uuid,$5,$6,$7,$8,$9,$10,$11)
		ON CONFLICT DO NOTHING`,
		userID, source, paymentID, checkoutID.String, delta, debited, shortfall, after, provider, eventRef, now); err != nil {
		return coinReversal{}, err
	}
	if shortfall > 0 {
		if err := insertSecurityEventTx(ctx, tx, "billing.wallet_frozen", "", "system", userID,
			"wallet", userID, map[string]any{
				"payment_id": paymentID, "coins_shortfall": shortfall, "reason": source,
			}); err != nil {
			return coinReversal{}, err
		}
	}
	return coinReversal{Requested: delta, Debited: debited, Shortfall: shortfall}, nil
}

// reconcileCoinReversalForCheckout re-applies clawback after the wallet
// credit, covering a refund that was recorded before the coins were credited.
func (r *billingRepository) reconcileCoinReversalForCheckout(ctx context.Context, checkoutID, provider string) error {
	tx, err := r.db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelReadCommitted})
	if err != nil {
		return err
	}
	defer func() { _ = tx.Rollback() }()
	var paymentID string
	err = tx.QueryRowContext(ctx, `
		SELECT id::text FROM matching.billing_payments_runtime
		WHERE checkout_id=$1::uuid AND billing_reason='coin_purchase'
		  AND status IN ('refunded','partially_refunded','chargeback')
		LIMIT 1`, checkoutID).Scan(&paymentID)
	if errors.Is(err, sql.ErrNoRows) {
		return nil
	}
	if err != nil {
		return err
	}
	if _, err := reverseCoinPurchaseTx(ctx, tx, paymentID, provider, "late-credit:"+checkoutID, time.Now().UTC()); err != nil {
		return err
	}
	return tx.Commit()
}

// endSubscriptionsForChargebackTx ends, at once, the subscription a lost
// dispute belongs to. The row is marked so a straggling renewal invoice cannot
// reactivate it; returns the provider subscription ids so the caller can stop
// renewal at the provider after commit.
func endSubscriptionsForChargebackTx(ctx context.Context, tx *sql.Tx, provider, paymentIntentID, chargeID string, now time.Time) ([]string, error) {
	rows, err := tx.QueryContext(ctx, `
		UPDATE matching.billing_subscriptions_runtime s
		SET status='cancelled', end_date=$4, cancelled_at=COALESCE(cancelled_at,$4),
		    auto_renew=FALSE, cancel_at_period_end=TRUE,
		    metadata=COALESCE(s.metadata,'{}'::jsonb) || jsonb_build_object('ended_reason','chargeback','ended_at',$4::text),
		    updated_at=$4, lock_version=s.lock_version+1
		FROM matching.billing_payments_runtime p
		WHERE p.subscription_id=s.id AND p.provider=$1
		  AND (p.provider_payment_id=$2 OR p.provider_charge_id=$3)
		  AND p.status='chargeback'
		  AND s.status IN ('incomplete','active','past_due','paused')
		RETURNING COALESCE(s.provider_subscription_id,'')`, provider, paymentIntentID, chargeID, now)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var ids []string
	for rows.Next() {
		var id string
		if err := rows.Scan(&id); err != nil {
			return nil, err
		}
		if id != "" {
			ids = append(ids, id)
		}
	}
	return ids, rows.Err()
}

// walletFrozenTx reports whether spending from a wallet is blocked.
func walletFrozenTx(ctx context.Context, tx *sql.Tx, userID string) (bool, error) {
	var frozen bool
	err := tx.QueryRowContext(ctx, `
		SELECT frozen_at IS NOT NULL FROM matching.user_wallets WHERE user_id=$1::uuid`, userID).Scan(&frozen)
	if errors.Is(err, sql.ErrNoRows) {
		return false, nil
	}
	return frozen, err
}

type walletReviewResult struct {
	UserID         string `json:"user_id"`
	CoinBalance    int    `json:"coin_balance"`
	DebtCollected  int    `json:"debt_collected"`
	DebtWrittenOff int    `json:"debt_written_off"`
	Frozen         bool   `json:"frozen"`
}

// reviewFrozenWallet is the operator review that lifts a freeze: either
// collect the debt from the current balance, or write the remaining debt off.
func (r *billingRepository) reviewFrozenWallet(ctx context.Context, userID, operatorID, operatorRole, action, note string) (walletReviewResult, error) {
	note = strings.TrimSpace(note)
	if n := len([]rune(note)); n < 10 || n > 1000 {
		return walletReviewResult{}, errWalletReviewNote
	}
	if action != "collect_and_unfreeze" && action != "write_off_and_unfreeze" {
		return walletReviewResult{}, errWalletReviewAction
	}
	tx, err := r.db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelReadCommitted})
	if err != nil {
		return walletReviewResult{}, err
	}
	defer func() { _ = tx.Rollback() }()
	var balance, debt int
	var frozen sql.NullTime
	if err := tx.QueryRowContext(ctx, `
		SELECT coin_balance, debt_coins, frozen_at FROM matching.user_wallets
		WHERE user_id=$1::uuid FOR UPDATE`, userID).Scan(&balance, &debt, &frozen); err != nil {
		return walletReviewResult{}, err
	}
	if !frozen.Valid {
		return walletReviewResult{}, errWalletNotFrozen
	}
	collect := debt
	if collect > balance {
		collect = balance
	}
	remaining := debt - collect
	result := walletReviewResult{UserID: userID, DebtCollected: collect}
	if action == "collect_and_unfreeze" && remaining > 0 {
		return walletReviewResult{}, errWalletDebtOutstanding
	}
	result.DebtWrittenOff = remaining
	now := time.Now().UTC()
	if collect > 0 {
		if _, err := tx.ExecContext(ctx, `
			INSERT INTO matching.wallet_coin_debits
			  (user_id, source, coins_requested, coins_debited, coins_shortfall, wallet_balance_after,
			   actor_user_id, note, created_at)
			VALUES ($1::uuid,'debt_collection',$2,$2,0,$3,NULLIF($4,'')::uuid,$5,$6)`,
			userID, collect, balance-collect, operatorID, note, now); err != nil {
			return walletReviewResult{}, err
		}
	}
	if _, err := tx.ExecContext(ctx, `
		UPDATE matching.user_wallets
		SET coin_balance=coin_balance-$2, debt_coins=0, frozen_at=NULL, frozen_reason=NULL, updated_at=$3
		WHERE user_id=$1::uuid`, userID, collect, now); err != nil {
		return walletReviewResult{}, err
	}
	if err := insertSecurityEventTx(ctx, tx, "billing.wallet_review", operatorID, operatorRole, userID,
		"wallet", userID, map[string]any{
			"action": action, "debt_collected": collect, "debt_written_off": remaining,
		}); err != nil {
		return walletReviewResult{}, err
	}
	if err := tx.Commit(); err != nil {
		return walletReviewResult{}, err
	}
	result.CoinBalance = balance - collect
	return result, nil
}

// coinLiability compares every wallet balance with what its ledger explains:
// credits (purchases, grants, promos, bootstrap, gift refunds, opening
// balances) minus gift spends minus coin debits.
func (r *billingRepository) coinLiability(ctx context.Context) (map[string]any, []reconciliationAnomaly, error) {
	var wallets, frozen, mismatched int64
	var balances, debt, ledgerTotal int64
	if err := r.db.QueryRowContext(ctx, `
		WITH ledger AS (
		  SELECT w.user_id, w.coin_balance, w.debt_coins, w.frozen_at,
		         COALESCE((SELECT SUM(p.coins) FROM matching.wallet_coin_purchases p WHERE p.user_id=w.user_id),0)
		       - COALESCE((SELECT SUM(s.total_cost_coins) FROM matching.match_gift_sends s WHERE s.sender_user_id=w.user_id),0)
		       - COALESCE((SELECT SUM(d.coins_debited) FROM matching.wallet_coin_debits d WHERE d.user_id=w.user_id),0)
		         AS ledger_balance
		  FROM matching.user_wallets w
		)
		SELECT COUNT(*), COUNT(*) FILTER (WHERE frozen_at IS NOT NULL),
		       COUNT(*) FILTER (WHERE coin_balance <> ledger_balance),
		       COALESCE(SUM(coin_balance),0), COALESCE(SUM(debt_coins),0), COALESCE(SUM(ledger_balance),0)
		FROM ledger`).Scan(&wallets, &frozen, &mismatched, &balances, &debt, &ledgerTotal); err != nil {
		return nil, nil, err
	}
	summary := map[string]any{
		"wallets":             wallets,
		"frozen_wallets":      frozen,
		"outstanding_balance": balances,
		"ledger_balance":      ledgerTotal,
		"debt_coins":          debt,
		"mismatched_wallets":  mismatched,
		"note":                "balance must equal credits minus gift spends minus debits; debt is coins owed after a reversed purchase",
	}
	var anomalies []reconciliationAnomaly
	rows, err := r.db.QueryContext(ctx, `
		WITH ledger AS (
		  SELECT w.user_id, w.coin_balance,
		         COALESCE((SELECT SUM(p.coins) FROM matching.wallet_coin_purchases p WHERE p.user_id=w.user_id),0)
		       - COALESCE((SELECT SUM(s.total_cost_coins) FROM matching.match_gift_sends s WHERE s.sender_user_id=w.user_id),0)
		       - COALESCE((SELECT SUM(d.coins_debited) FROM matching.wallet_coin_debits d WHERE d.user_id=w.user_id),0)
		         AS ledger_balance
		  FROM matching.user_wallets w
		)
		SELECT user_id::text, coin_balance, ledger_balance FROM ledger
		WHERE coin_balance <> ledger_balance ORDER BY user_id LIMIT 100`)
	if err != nil {
		return nil, nil, err
	}
	defer rows.Close()
	for rows.Next() {
		var id string
		var balance, ledger int64
		if err := rows.Scan(&id, &balance, &ledger); err != nil {
			return nil, nil, err
		}
		anomalies = append(anomalies, reconciliationAnomaly{
			Type: "wallet_balance_mismatch", ID: id,
			Detail: fmt.Sprintf("balance %d but ledger explains %d", balance, ledger),
		})
	}
	return summary, anomalies, rows.Err()
}

// chargebackProviderSubscriptions lists provider subscription ids ended by a
// lost dispute on the given charge.
func (r *billingRepository) chargebackProviderSubscriptions(ctx context.Context, provider, paymentIntentID, chargeID string) ([]string, error) {
	rows, err := r.db.QueryContext(ctx, `
		SELECT DISTINCT s.provider_subscription_id
		FROM matching.billing_subscriptions_runtime s
		JOIN matching.billing_payments_runtime p ON p.subscription_id=s.id
		WHERE p.provider=$1 AND (p.provider_payment_id=$2 OR p.provider_charge_id=$3)
		  AND p.status='chargeback' AND s.metadata->>'ended_reason'='chargeback'
		  AND COALESCE(s.provider_subscription_id,'')<>''`, provider, paymentIntentID, chargeID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var ids []string
	for rows.Next() {
		var id string
		if err := rows.Scan(&id); err != nil {
			return nil, err
		}
		ids = append(ids, id)
	}
	return ids, rows.Err()
}

// coinCheckoutVolumeToday counts a member's coin checkouts started today (UTC)
// and the coins they cover, whatever their outcome.
func (r *billingRepository) coinCheckoutVolumeToday(ctx context.Context, userID string) (int, int, error) {
	var count, coins int
	err := r.db.QueryRowContext(ctx, `
		SELECT COUNT(*), COALESCE(SUM(coins),0) FROM matching.billing_checkout_sessions
		WHERE user_id=$1::uuid AND kind='coin_package'
		  AND created_at >= date_trunc('day', NOW() AT TIME ZONE 'UTC') AT TIME ZONE 'UTC'`, userID).Scan(&count, &coins)
	return count, coins, err
}
