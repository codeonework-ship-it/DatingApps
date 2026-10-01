package mobile

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"
)

const economyFraudWarning = "Unusual coin activity detected. Slow down to keep your account secure."

type economyFraudDecision struct {
	RuleCode, EventType, Severity, RecommendedAction, ActionTaken string
	ObservedValue, TriggerValue, WindowSeconds, LockSeconds       int
	MatchID, ReceiverID                                           string
}

func (d economyFraudDecision) blocks() bool {
	return d.ActionTaken == "throttle" || d.ActionTaken == "temporary_lock"
}

type errEconomyFraudControl struct {
	Action string
	Until  time.Time
}

func (e *errEconomyFraudControl) Error() string {
	if e.Action == "temporary_lock" && !e.Until.IsZero() {
		return "paid coin activity is temporarily locked until " + e.Until.UTC().Format(time.RFC3339)
	}
	return "coin activity is temporarily limited; try again later"
}

func economyActionRank(action string) int {
	switch action {
	case "temporary_lock":
		return 3
	case "throttle":
		return 2
	case "warn":
		return 1
	}
	return 0
}

// evaluateEconomyFraudTx evaluates every enabled rule against durable ledgers.
// Candidate values are included before a command is committed. It returns the
// strongest response plus all triggered decisions so every signal is reviewable.
func evaluateEconomyFraudTx(ctx context.Context, tx *sql.Tx, eventType, userID, receiverID, matchID string, candidate int, now time.Time) ([]economyFraudDecision, error) {
	rows, err := tx.QueryContext(ctx, `
		SELECT rule_code,metric,window_seconds,trigger_value,response_action,lock_seconds,severity
		FROM matching.coin_economy_fraud_rules WHERE event_type=$1 AND enabled ORDER BY rule_code`, eventType)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	type rule struct {
		code, metric, action, severity string
		window, trigger, lock          int
	}
	var rules []rule
	for rows.Next() {
		var r rule
		if err := rows.Scan(&r.code, &r.metric, &r.window, &r.trigger, &r.action, &r.lock, &r.severity); err != nil {
			return nil, err
		}
		rules = append(rules, r)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	flags := map[string]bool{}
	flagRows, err := tx.QueryContext(ctx, `SELECT key,value_bool FROM matching.platform_feature_flags WHERE key LIKE 'coin_economy_fraud_%_enabled' OR key='coin_economy_fraud_responses_enabled'`)
	if err != nil {
		return nil, err
	}
	for flagRows.Next() {
		var k string
		var v bool
		if err := flagRows.Scan(&k, &v); err != nil {
			flagRows.Close()
			return nil, err
		}
		flags[k] = v
	}
	flagRows.Close()
	master := flags["coin_economy_fraud_responses_enabled"]
	var out []economyFraudDecision
	for _, r := range rules {
		var observed int
		since := now.Add(-time.Duration(r.window) * time.Second)
		switch r.metric {
		case "paid_gift_sends":
			err = tx.QueryRowContext(ctx, `SELECT COUNT(*)+1 FROM matching.match_gift_sends WHERE sender_user_id=$1::uuid AND status='sent' AND total_cost_coins>0 AND created_at >= $2`, userID, since).Scan(&observed)
		case "paid_gift_coins":
			err = tx.QueryRowContext(ctx, `SELECT COALESCE(SUM(total_cost_coins),0)+$3 FROM matching.match_gift_sends WHERE sender_user_id=$1::uuid AND status='sent' AND total_cost_coins>0 AND created_at >= $2`, userID, since, candidate).Scan(&observed)
		case "distinct_gift_recipients":
			err = tx.QueryRowContext(ctx, `SELECT COUNT(DISTINCT receiver_user_id) + CASE WHEN EXISTS(SELECT 1 FROM matching.match_gift_sends WHERE sender_user_id=$1::uuid AND receiver_user_id=$3::uuid AND status='sent' AND total_cost_coins>0 AND created_at >= $2) THEN 0 ELSE 1 END FROM matching.match_gift_sends WHERE sender_user_id=$1::uuid AND status='sent' AND total_cost_coins>0 AND created_at >= $2`, userID, since, receiverID).Scan(&observed)
		case "same_recipient_paid_gifts":
			err = tx.QueryRowContext(ctx, `SELECT COUNT(*)+1 FROM matching.match_gift_sends WHERE sender_user_id=$1::uuid AND receiver_user_id=$3::uuid AND status='sent' AND total_cost_coins>0 AND created_at >= $2`, userID, since, receiverID).Scan(&observed)
		case "received_gift_reports":
			err = tx.QueryRowContext(ctx, `SELECT COUNT(*) FROM matching.gift_receiver_actions a JOIN matching.match_gift_sends s ON s.id=a.gift_send_id WHERE s.sender_user_id=$1::uuid AND a.reported_at >= $2`, userID, since).Scan(&observed)
		case "coin_checkout_count":
			err = tx.QueryRowContext(ctx, `SELECT COUNT(*)+1 FROM matching.billing_checkout_sessions WHERE user_id=$1::uuid AND kind='coin_package' AND created_at >= $2`, userID, since).Scan(&observed)
		case "coin_checkout_coins":
			err = tx.QueryRowContext(ctx, `SELECT COALESCE(SUM(coins),0)+$3 FROM matching.billing_checkout_sessions WHERE user_id=$1::uuid AND kind='coin_package' AND created_at >= $2`, userID, since, candidate).Scan(&observed)
		default:
			continue
		}
		if err != nil {
			return nil, err
		}
		if observed < r.trigger {
			continue
		}
		taken := "review_only"
		if master && flags["coin_economy_fraud_"+r.action+"_enabled"] {
			taken = r.action
		}
		out = append(out, economyFraudDecision{r.code, eventType, r.severity, r.action, taken, observed, r.trigger, r.window, r.lock, matchID, receiverID})
	}
	return out, nil
}

func strongestEconomyDecision(ds []economyFraudDecision) *economyFraudDecision {
	var best *economyFraudDecision
	for i := range ds {
		if best == nil || economyActionRank(ds[i].ActionTaken) > economyActionRank(best.ActionTaken) {
			best = &ds[i]
		}
	}
	return best
}

func recordEconomyFraudDecisionsTx(ctx context.Context, tx *sql.Tx, userID string, ds []economyFraudDecision, now time.Time) (*errEconomyFraudControl, error) {
	var control *errEconomyFraudControl
	for _, d := range ds {
		evidence, _ := json.Marshal(map[string]any{"event_type": d.EventType, "observed_value": d.ObservedValue, "trigger_value": d.TriggerValue, "window_seconds": d.WindowSeconds})
		var caseID string
		var lockUntil sql.NullTime
		if d.ActionTaken == "temporary_lock" {
			lockUntil = sql.NullTime{Time: now.Add(time.Duration(d.LockSeconds) * time.Second), Valid: true}
		}
		err := tx.QueryRowContext(ctx, `
			INSERT INTO matching.coin_economy_fraud_cases(user_id,rule_code,event_type,severity,recommended_action,action_taken,observed_value,trigger_value,window_seconds,match_id,receiver_user_id,evidence,first_detected_at,last_detected_at,lock_until,created_at,updated_at)
			VALUES($1::uuid,$2,$3,$4,$5,$6,$7,$8,$9,NULLIF($10,'')::uuid,NULLIF($11,'')::uuid,$12::jsonb,$13,$13,$14,$13,$13)
			ON CONFLICT(user_id,rule_code) WHERE status IN ('open','reviewing') DO UPDATE SET
			 occurrence_count=matching.coin_economy_fraud_cases.occurrence_count+1,last_detected_at=EXCLUDED.last_detected_at,
			 observed_value=GREATEST(matching.coin_economy_fraud_cases.observed_value,EXCLUDED.observed_value),
			 action_taken=CASE WHEN matching.coin_economy_fraud_cases.action_taken='temporary_lock' THEN matching.coin_economy_fraud_cases.action_taken ELSE EXCLUDED.action_taken END,
			 lock_until=GREATEST(matching.coin_economy_fraud_cases.lock_until,EXCLUDED.lock_until),evidence=EXCLUDED.evidence,updated_at=EXCLUDED.updated_at
			RETURNING id::text,lock_until`, userID, d.RuleCode, d.EventType, d.Severity, d.RecommendedAction, d.ActionTaken, d.ObservedValue, d.TriggerValue, d.WindowSeconds, d.MatchID, d.ReceiverID, string(evidence), now, lockUntil).Scan(&caseID, &lockUntil)
		if err != nil {
			return nil, err
		}
		if d.ActionTaken == "temporary_lock" {
			if _, err = tx.ExecContext(ctx, `UPDATE matching.user_wallets SET risk_locked_until=GREATEST(COALESCE(risk_locked_until,'-infinity'::timestamptz),$2),risk_lock_reason=$3,risk_lock_case_id=$4::uuid,updated_at=$1 WHERE user_id=$5::uuid`, now, lockUntil.Time, d.RuleCode, caseID, userID); err != nil {
				return nil, err
			}
		}
		if err = insertSecurityEventTx(ctx, tx, "fraud.coin_economy."+d.ActionTaken, userID, "member", userID, "fraud_case", caseID, map[string]any{"rule_code": d.RuleCode, "observed_value": d.ObservedValue, "trigger_value": d.TriggerValue, "action": d.ActionTaken}); err != nil {
			return nil, err
		}
		if d.blocks() && (control == nil || economyActionRank(d.ActionTaken) > economyActionRank(control.Action)) {
			control = &errEconomyFraudControl{Action: d.ActionTaken}
			if lockUntil.Valid {
				control.Until = lockUntil.Time
			}
		}
	}
	return control, nil
}

func persistEconomyFraudDecisions(ctx context.Context, db *sql.DB, userID string, ds []economyFraudDecision, now time.Time) (*errEconomyFraudControl, error) {
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback()
	control, err := recordEconomyFraudDecisionsTx(ctx, tx, userID, ds, now)
	if err != nil {
		return nil, err
	}
	return control, tx.Commit()
}

func activeWalletRiskLock(ctx context.Context, tx *sql.Tx, userID string, now time.Time) (time.Time, error) {
	var until sql.NullTime
	err := tx.QueryRowContext(ctx, `SELECT risk_locked_until FROM matching.user_wallets WHERE user_id=$1::uuid FOR UPDATE`, userID).Scan(&until)
	if err != nil {
		return time.Time{}, err
	}
	if until.Valid && until.Time.After(now) {
		return until.Time, nil
	}
	return time.Time{}, nil
}

var errFraudCaseNotOpen = errors.New("fraud case is not open")
var errFraudResolution = errors.New("resolution must be cleared or confirmed and note must be 10-1000 characters")

func economyControlStatus(err error) (int, string, bool) {
	var c *errEconomyFraudControl
	if !errors.As(err, &c) {
		return 0, "", false
	}
	if c.Action == "temporary_lock" {
		return 423, "WALLET_RISK_LOCKED", true
	}
	return 429, "COIN_ECONOMY_THROTTLED", true
}

func validateEconomyRuleAction(action string) error {
	if action != "warn" && action != "throttle" && action != "temporary_lock" {
		return fmt.Errorf("invalid response_action %q", action)
	}
	return nil
}

func trimEconomyStatus(v string) string { return strings.ToLower(strings.TrimSpace(v)) }

// reserveCoinCheckout serialises the limit check and checkout insert for one
// member. This closes the check-then-insert race that could previously let
// concurrent requests exceed a daily cap.
func (r *billingRepository) reserveCoinCheckout(ctx context.Context, userID, packageID, provider, key string, coins int, amountMinor int64, currency string, now time.Time) (string, error) {
	tx, err := r.db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelReadCommitted})
	if err != nil {
		return "", err
	}
	defer tx.Rollback()
	if _, err = tx.ExecContext(ctx, `SELECT pg_advisory_xact_lock(hashtextextended('coin-checkout:'||$1,0))`, userID); err != nil {
		return "", err
	}
	var riskUntil sql.NullTime
	err = tx.QueryRowContext(ctx, `SELECT risk_locked_until FROM matching.user_wallets WHERE user_id=$1::uuid FOR UPDATE`, userID).Scan(&riskUntil)
	if err != nil && !errors.Is(err, sql.ErrNoRows) {
		return "", err
	}
	if riskUntil.Valid && riskUntil.Time.After(now) {
		return "", &errEconomyFraudControl{Action: "temporary_lock", Until: riskUntil.Time}
	}
	dayStart := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, time.UTC)
	var count, total int
	if err = tx.QueryRowContext(ctx, `SELECT COUNT(*),COALESCE(SUM(coins),0) FROM matching.billing_checkout_sessions WHERE user_id=$1::uuid AND kind='coin_package' AND created_at >= $2`, userID, dayStart).Scan(&count, &total); err != nil {
		return "", err
	}
	ds, err := evaluateEconomyFraudTx(ctx, tx, "coin_checkout", userID, "", "", coins, now)
	if err != nil {
		return "", err
	}
	if strongest := strongestEconomyDecision(ds); strongest != nil && strongest.blocks() {
		if err := ensureWalletTx(ctx, tx, userID, now); err != nil {
			return "", err
		}
		control, err := recordEconomyFraudDecisionsTx(ctx, tx, userID, ds, now)
		if err != nil {
			return "", err
		}
		if err = tx.Commit(); err != nil {
			return "", err
		}
		return "", control
	}
	if count+1 > maxCoinCheckoutsPerDay || total+coins > maxCoinsPurchasedPerDay {
		return "", errCoinPurchaseLimit
	}
	if len(ds) > 0 {
		if err := ensureWalletTx(ctx, tx, userID, now); err != nil {
			return "", err
		}
		if _, err = recordEconomyFraudDecisionsTx(ctx, tx, userID, ds, now); err != nil {
			return "", err
		}
	}
	var nullableKey any
	if strings.TrimSpace(key) != "" {
		nullableKey = key
	}
	var id string
	err = tx.QueryRowContext(ctx, `INSERT INTO matching.billing_checkout_sessions(user_id,kind,package_id,coins,provider,idempotency_key,status,amount_minor,currency,created_at) VALUES($1,'coin_package',$2,$3,$4,$5,'open',$6,$7,$8) RETURNING id::text`, userID, packageID, coins, provider, nullableKey, amountMinor, currency, now).Scan(&id)
	if err != nil {
		return "", err
	}
	return id, tx.Commit()
}
