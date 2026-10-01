package mobile

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"strings"
	"time"
)

var (
	errGiftNotFound            = errors.New("gift not found")
	errGiftInsufficientCoins   = errors.New("insufficient wallet coins")
	errGiftExclusiveDailyLimit = errors.New("daily limit reached for this exclusive gift")
	// errFreeGiftDailyLimit enforces GIFT-004: one free-tier gift per member
	// per UTC calendar day. The paid-member exception is not adopted.
	errFreeGiftDailyLimit     = errors.New("free gift daily limit reached: one free gift per UTC day")
	errGiftReceiverMismatch   = errors.New("receiver is not the other member of this match")
	errGiftMatchInactive      = errors.New("gifts can only be sent in an active match")
	errGiftIdempotencyReplay  = errors.New("idempotency key was already used for a different gift")
	errGiftLedgerUnconfigured = errors.New("gift send ledger is not configured")
)

// giftSendLedger performs a gift send as one PostgreSQL transaction: validate
// the match and receiver, lock the sender's wallet, apply the exclusive and
// free-gift limits, debit, record the send and write the chat message. Either
// all of it commits or none of it does, so a failure can never leave a charge
// without a gift or a gift without a charge (GIFT-003).
//
// Every send by one member takes that member's wallet row lock first, which
// serialises their concurrent sends. That is what makes the per-match and
// per-day counts safe against concurrent requests with different keys
// (GIFT-005), and lets a same-key retry find the committed send.
type giftSendLedger struct {
	db     *sql.DB
	limits giftVelocityLimits
}

// giftVelocityLimits are the per-sender fraud and velocity controls for paid
// gifts (PEN-13 / RG-112). They run inside the send transaction under the
// sender's wallet lock, so concurrent sends cannot slip past them. A zero
// value disables that limit.
type giftVelocityLimits struct {
	MaxPaidSendsPerHour     int
	MaxCoinsPerDay          int
	MaxPaidRecipientsPerDay int
}

var defaultGiftVelocityLimits = giftVelocityLimits{
	MaxPaidSendsPerHour:     30,
	MaxCoinsPerDay:          200,
	MaxPaidRecipientsPerDay: 15,
}

func newGiftSendLedger(db *sql.DB) *giftSendLedger {
	if db == nil {
		return nil
	}
	return &giftSendLedger{db: db, limits: defaultGiftVelocityLimits}
}

type giftSendRequest struct {
	MatchID        string
	SenderUserID   string
	ReceiverUserID string // optional; must equal the other participant when set
	GiftID         string
	IdempotencyKey string
	Note           string
	Now            time.Time
}

func (l *giftSendLedger) send(ctx context.Context, req giftSendRequest) (roseGiftSendView, error) {
	if l == nil || l.db == nil {
		return roseGiftSendView{}, errGiftLedgerUnconfigured
	}
	now := req.Now.UTC()
	if now.IsZero() {
		now = time.Now().UTC()
	}
	key := strings.TrimSpace(req.IdempotencyKey)
	if key == "" {
		// The column is NOT NULL and unique per (match, sender, key); an empty
		// key would make every keyless send after the first collide.
		key = "server-" + newGroupUUID()
	}
	note := sanitizeRoseGiftNote(req.Note)

	tx, err := l.db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelReadCommitted})
	if err != nil {
		return roseGiftSendView{}, err
	}
	defer func() { _ = tx.Rollback() }()

	receiverID, err := giftReceiverForMatch(ctx, tx, req.MatchID, req.SenderUserID, req.ReceiverUserID)
	if err != nil {
		return roseGiftSendView{}, err
	}

	// Create the wallet on first use, then take the sender-wide lock.
	if err := ensureWalletTx(ctx, tx, req.SenderUserID, now); err != nil {
		return roseGiftSendView{}, err
	}
	var balance int
	var frozen bool
	var riskLockedUntil sql.NullTime
	if err := tx.QueryRowContext(ctx, `
		SELECT coin_balance, frozen_at IS NOT NULL, risk_locked_until FROM matching.user_wallets
		WHERE user_id = $1 FOR UPDATE`, req.SenderUserID).Scan(&balance, &frozen, &riskLockedUntil); err != nil {
		return roseGiftSendView{}, err
	}

	gift, err := giftForSend(ctx, tx, req.GiftID, now)
	if err != nil {
		return roseGiftSendView{}, err
	}

	// Replay: checked under the wallet lock so a concurrent same-key request
	// sees the committed send instead of racing it.
	if replay, found, err := giftSendReplay(ctx, tx, req.MatchID, req.SenderUserID, key); err != nil {
		return roseGiftSendView{}, err
	} else if found {
		if replay.GiftID != gift.ID {
			return roseGiftSendView{}, errGiftIdempotencyReplay
		}
		fillGiftView(&replay, gift)
		replay.RemainingCoins = balance
		replay.MessageText = encodeRoseGiftChatMessageWithNote(replay, replay.MessageText)
		return replay, tx.Commit()
	}

	// A wallet frozen after a reversed coin purchase cannot spend until an
	// operator reviews it; free gifts spend nothing and stay available.
	if frozen && gift.PriceCoins > 0 {
		return roseGiftSendView{}, errWalletFrozen
	}
	if gift.PriceCoins > 0 && riskLockedUntil.Valid && riskLockedUntil.Time.After(now) {
		return roseGiftSendView{}, &errEconomyFraudControl{Action: "temporary_lock", Until: riskLockedUntil.Time}
	}

	dayStart := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, time.UTC)
	riskWarning := false
	if gift.PriceCoins > 0 {
		decisions, err := evaluateEconomyFraudTx(ctx, tx, "gift_send", req.SenderUserID, receiverID, req.MatchID, gift.PriceCoins, now)
		if err != nil {
			return roseGiftSendView{}, err
		}
		if strongest := strongestEconomyDecision(decisions); strongest != nil && strongest.blocks() {
			_ = tx.Rollback()
			control, persistErr := persistEconomyFraudDecisions(ctx, l.db, req.SenderUserID, decisions, now)
			if persistErr != nil {
				return roseGiftSendView{}, persistErr
			}
			return roseGiftSendView{}, control
		}
		if len(decisions) > 0 {
			if _, err := recordEconomyFraudDecisionsTx(ctx, tx, req.SenderUserID, decisions, now); err != nil {
				return roseGiftSendView{}, err
			}
			for _, decision := range decisions {
				if decision.ActionTaken == "warn" {
					riskWarning = true
					break
				}
			}
		}
		if breach, err := l.checkVelocity(ctx, tx, req.SenderUserID, receiverID, gift.PriceCoins, dayStart, now); err != nil {
			return roseGiftSendView{}, err
		} else if breach != nil {
			_ = tx.Rollback()
			l.recordVelocityBreach(ctx, req.SenderUserID, req.MatchID, gift.ID, breach)
			return roseGiftSendView{}, breach
		}
	}
	if gift.MaxPerMatchPerDay > 0 {
		var sentToday int
		if err := tx.QueryRowContext(ctx, `
			SELECT COUNT(*) FROM matching.match_gift_sends
			WHERE match_id = $1 AND sender_user_id = $2 AND gift_id = $3
			  AND status = 'sent' AND created_at >= $4`,
			req.MatchID, req.SenderUserID, gift.ID, dayStart).Scan(&sentToday); err != nil {
			return roseGiftSendView{}, err
		}
		if sentToday >= gift.MaxPerMatchPerDay {
			return roseGiftSendView{}, errGiftExclusiveDailyLimit
		}
	}

	if gift.PriceCoins == 0 {
		var used int
		if err := tx.QueryRowContext(ctx, `
			INSERT INTO matching.gift_daily_entitlements(user_id, used_date, used_count, updated_at)
			VALUES ($1, $2, 1, $3)
			ON CONFLICT (user_id, used_date) DO UPDATE
			  SET used_count = matching.gift_daily_entitlements.used_count + 1,
			      updated_at = EXCLUDED.updated_at
			RETURNING used_count`, req.SenderUserID, dayStart.Format("2006-01-02"), now).Scan(&used); err != nil {
			return roseGiftSendView{}, err
		}
		if used > 1 {
			return roseGiftSendView{}, errFreeGiftDailyLimit
		}
	}

	if balance < gift.PriceCoins {
		return roseGiftSendView{}, errGiftInsufficientCoins
	}
	remaining := balance - gift.PriceCoins
	if gift.PriceCoins > 0 {
		if _, err := tx.ExecContext(ctx, `
			UPDATE matching.user_wallets SET coin_balance = $2, updated_at = $3
			WHERE user_id = $1`, req.SenderUserID, remaining, now); err != nil {
			return roseGiftSendView{}, err
		}
	}

	view := roseGiftSendView{
		MatchID:        req.MatchID,
		SenderUserID:   req.SenderUserID,
		ReceiverUserID: receiverID,
		PriceCoins:     gift.PriceCoins,
		RemainingCoins: remaining,
		CreatedAt:      now.Format(time.RFC3339),
	}
	fillGiftView(&view, gift)
	if riskWarning {
		// A warning is deliberately generic so the client can help the member
		// slow down without revealing thresholds attackers could tune against.
		view.RiskWarning = economyFraudWarning
	}

	if err := tx.QueryRowContext(ctx, `
		INSERT INTO matching.match_gift_sends(
		  match_id, sender_user_id, receiver_user_id, gift_id, quantity,
		  total_cost_coins, idempotency_key, status, icon_key, message, created_at
		) VALUES ($1, $2, $3, $4, 1, $5, $6, 'sent', $7, NULLIF($8, ''), $9)
		RETURNING id`,
		req.MatchID, req.SenderUserID, receiverID, gift.ID, gift.PriceCoins,
		key, gift.IconKey, note, now).Scan(&view.ID); err != nil {
		return roseGiftSendView{}, err
	}

	view.MessageText = encodeRoseGiftChatMessageWithNote(view, note)
	if err := tx.QueryRowContext(ctx, `
		INSERT INTO matching.messages(match_id, sender_id, text, gift_send_id, created_at)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING id`,
		req.MatchID, req.SenderUserID, view.MessageText, view.ID, now).Scan(&view.MessageID); err != nil {
		return roseGiftSendView{}, err
	}

	if err := tx.Commit(); err != nil {
		return roseGiftSendView{}, err
	}
	return view, nil
}

// giftReceiverForMatch returns the other participant of an active match, and
// rejects a client-supplied receiver that is anyone else.
func giftReceiverForMatch(ctx context.Context, tx *sql.Tx, matchID, senderID, claimedReceiver string) (string, error) {
	var user1, user2, status1, status2 string
	err := tx.QueryRowContext(ctx, `
		SELECT user_id_1::text, user_id_2::text, user_1_status, user_2_status
		FROM matching.matches WHERE id = $1`, matchID).Scan(&user1, &user2, &status1, &status2)
	if errors.Is(err, sql.ErrNoRows) {
		return "", errGiftMatchInactive
	}
	if err != nil {
		return "", err
	}
	var receiver string
	switch senderID {
	case user1:
		receiver = user2
	case user2:
		receiver = user1
	default:
		return "", errGiftMatchInactive
	}
	if status1 != "active" || status2 != "active" {
		return "", errGiftMatchInactive
	}
	if claimed := strings.TrimSpace(claimedReceiver); claimed != "" && !strings.EqualFold(claimed, receiver) {
		return "", errGiftReceiverMismatch
	}
	return receiver, nil
}

// giftForSend loads a catalogue item and checks it can be sent right now:
// active, and inside its seasonal window when one is set.
func giftForSend(ctx context.Context, tx *sql.Tx, giftID string, now time.Time) (roseGiftCatalogItem, error) {
	var (
		item      roseGiftCatalogItem
		gifURL    sql.NullString
		iconKey   sql.NullString
		maxPerDay sql.NullInt64
		startAt   sql.NullTime
		endAt     sql.NullTime
	)
	err := tx.QueryRowContext(ctx, `
		SELECT id, name, gif_url, icon_key, tier, category, price_coins,
		       is_limited, is_active, max_per_match_per_day, start_date, end_date
		FROM matching.gift_catalog WHERE id = $1`, strings.TrimSpace(giftID)).Scan(
		&item.ID, &item.Name, &gifURL, &iconKey, &item.Tier, &item.Category,
		&item.PriceCoins, &item.IsLimited, &item.IsActive, &maxPerDay, &startAt, &endAt)
	if errors.Is(err, sql.ErrNoRows) {
		return roseGiftCatalogItem{}, errGiftNotFound
	}
	if err != nil {
		return roseGiftCatalogItem{}, err
	}
	if !item.IsActive ||
		(startAt.Valid && now.Before(startAt.Time)) ||
		(endAt.Valid && !now.Before(endAt.Time)) {
		return roseGiftCatalogItem{}, errGiftUnavailable
	}
	item.GifURL = gifURL.String
	item.IconKey = strings.TrimSpace(iconKey.String)
	if item.IconKey == "" {
		item.IconKey = defaultRoseGiftIconKey(item.ID, item.Name)
	}
	item.MaxPerMatchPerDay = int(maxPerDay.Int64)
	return item, nil
}

// giftSendReplay finds a committed send for the same idempotency key. The
// returned view carries the stored note in MessageText for re-encoding.
func giftSendReplay(ctx context.Context, tx *sql.Tx, matchID, senderID, key string) (roseGiftSendView, bool, error) {
	var (
		view      roseGiftSendView
		note      sql.NullString
		messageID sql.NullString
		createdAt time.Time
	)
	err := tx.QueryRowContext(ctx, `
		SELECT s.id::text, s.receiver_user_id::text, s.gift_id, s.total_cost_coins,
		       s.message, s.created_at, m.id::text
		FROM matching.match_gift_sends s
		LEFT JOIN matching.messages m ON m.gift_send_id = s.id
		WHERE s.match_id = $1 AND s.sender_user_id = $2 AND s.idempotency_key = $3`,
		matchID, senderID, key).Scan(
		&view.ID, &view.ReceiverUserID, &view.GiftID, &view.PriceCoins,
		&note, &createdAt, &messageID)
	if errors.Is(err, sql.ErrNoRows) {
		return roseGiftSendView{}, false, nil
	}
	if err != nil {
		return roseGiftSendView{}, false, err
	}
	view.MatchID = matchID
	view.SenderUserID = senderID
	view.MessageID = messageID.String
	view.MessageText = note.String
	view.CreatedAt = createdAt.UTC().Format(time.RFC3339)
	return view, true, nil
}

// fillGiftView copies the catalogue's display fields. The price is left alone:
// a replay reports what was actually charged, not today's price.
func fillGiftView(view *roseGiftSendView, gift roseGiftCatalogItem) {
	view.GiftID = gift.ID
	view.GiftName = gift.Name
	view.GifURL = gift.GifURL
	view.IconKey = gift.IconKey
}

// ensureWalletTx creates an empty wallet on first use. Positive balances are
// created only by an explicit, ledger-backed credit command.
func ensureWalletTx(ctx context.Context, tx *sql.Tx, userID string, now time.Time) error {
	_, err := tx.ExecContext(ctx, `
		INSERT INTO matching.user_wallets(user_id, coin_balance, updated_at)
		VALUES ($1, 0, $2)
		ON CONFLICT (user_id) DO NOTHING`, userID, now)
	return err
}

// errGiftVelocityLimit is a paid-gift fraud/velocity refusal. Limit names the
// rule that tripped.
type errGiftVelocityLimit struct {
	Limit string
	Value int
	Max   int
}

func (e *errGiftVelocityLimit) Error() string {
	return fmt.Sprintf("gift velocity limit reached: %s (%d of %d)", e.Limit, e.Value, e.Max)
}

func (l *giftSendLedger) checkVelocity(
	ctx context.Context, tx *sql.Tx, senderID, receiverID string, price int, dayStart, now time.Time,
) (*errGiftVelocityLimit, error) {
	limits := l.limits
	var sendsHour, coinsToday, recipientsToday int
	var receiverSeenToday bool
	if err := tx.QueryRowContext(ctx, `
		SELECT
		  COUNT(*) FILTER (WHERE created_at > $2::timestamptz - INTERVAL '1 hour'),
		  COALESCE(SUM(total_cost_coins) FILTER (WHERE created_at >= $3::timestamptz), 0),
		  COUNT(DISTINCT receiver_user_id) FILTER (WHERE created_at >= $3::timestamptz),
		  COALESCE(BOOL_OR(receiver_user_id = $4::uuid AND created_at >= $3::timestamptz), FALSE)
		FROM matching.match_gift_sends
		WHERE sender_user_id = $1::uuid AND status = 'sent' AND total_cost_coins > 0
		  AND created_at >= LEAST($3::timestamptz, $2::timestamptz - INTERVAL '1 hour')`,
		senderID, now, dayStart, receiverID).Scan(&sendsHour, &coinsToday, &recipientsToday, &receiverSeenToday); err != nil {
		return nil, err
	}
	if limits.MaxPaidSendsPerHour > 0 && sendsHour+1 > limits.MaxPaidSendsPerHour {
		return &errGiftVelocityLimit{Limit: "paid_sends_per_hour", Value: sendsHour + 1, Max: limits.MaxPaidSendsPerHour}, nil
	}
	if limits.MaxCoinsPerDay > 0 && coinsToday+price > limits.MaxCoinsPerDay {
		return &errGiftVelocityLimit{Limit: "coins_per_day", Value: coinsToday + price, Max: limits.MaxCoinsPerDay}, nil
	}
	if limits.MaxPaidRecipientsPerDay > 0 && !receiverSeenToday && recipientsToday+1 > limits.MaxPaidRecipientsPerDay {
		return &errGiftVelocityLimit{Limit: "paid_recipients_per_day", Value: recipientsToday + 1, Max: limits.MaxPaidRecipientsPerDay}, nil
	}
	return nil, nil
}

// recordVelocityBreach leaves a review signal for trust & safety. It runs in
// its own transaction because the refused send rolled back.
func (l *giftSendLedger) recordVelocityBreach(ctx context.Context, senderID, matchID, giftID string, breach *errGiftVelocityLimit) {
	tx, err := l.db.BeginTx(ctx, nil)
	if err != nil {
		return
	}
	defer func() { _ = tx.Rollback() }()
	if err := insertSecurityEventTx(ctx, tx, "fraud.gift_velocity_limit", senderID, "member", senderID,
		"match", matchID, map[string]any{
			"limit": breach.Limit, "value": breach.Value, "max": breach.Max, "gift_id": giftID,
		}); err != nil {
		return
	}
	_ = tx.Commit()
}

var (
	errGiftReverseReason   = errors.New("reason must explain the reversal (3-500 characters)")
	errGiftAlreadyReversed = errors.New("gift has already been reversed")
)

type giftReversal struct {
	SendID           string `json:"gift_send_id"`
	SenderUserID     string `json:"sender_user_id"`
	CoinsRefunded    int    `json:"coins_refunded"`
	SenderBalance    int    `json:"sender_balance"`
	MessageRetracted bool   `json:"message_retracted"`
}

// reverse refunds a sent gift (operators only): the sender's coins come back
// through the credit ledger, a free gift's daily allowance is restored, the
// gift is marked refunded with who and why, and its chat message is retracted
// for both members. One transaction; a reversed gift cannot be reversed again.
func (l *giftSendLedger) reverse(ctx context.Context, sendID, operatorID, operatorRole, reason string) (giftReversal, error) {
	if l == nil || l.db == nil {
		return giftReversal{}, errGiftLedgerUnconfigured
	}
	reason = strings.TrimSpace(reason)
	if n := len([]rune(reason)); n < 3 || n > 500 {
		return giftReversal{}, errGiftReverseReason
	}
	now := time.Now().UTC()
	tx, err := l.db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelReadCommitted})
	if err != nil {
		return giftReversal{}, err
	}
	defer func() { _ = tx.Rollback() }()

	var senderID, status string
	var coins int
	var sentAt time.Time
	if err := tx.QueryRowContext(ctx, `
		SELECT sender_user_id::text, status, total_cost_coins, created_at
		FROM matching.match_gift_sends WHERE id = $1::uuid FOR UPDATE`, sendID).Scan(
		&senderID, &status, &coins, &sentAt); err != nil {
		return giftReversal{}, err
	}
	if status != "sent" {
		return giftReversal{}, errGiftAlreadyReversed
	}
	if err := ensureWalletTx(ctx, tx, senderID, now); err != nil {
		return giftReversal{}, err
	}
	var balance int
	if err := tx.QueryRowContext(ctx, `
		SELECT coin_balance FROM matching.user_wallets WHERE user_id = $1::uuid FOR UPDATE`, senderID).Scan(&balance); err != nil {
		return giftReversal{}, err
	}
	result := giftReversal{SendID: sendID, SenderUserID: senderID, CoinsRefunded: coins, SenderBalance: balance}
	if coins > 0 {
		result.SenderBalance = balance + coins
		if _, err := tx.ExecContext(ctx, `
			UPDATE matching.user_wallets SET coin_balance = $2, updated_at = $3 WHERE user_id = $1::uuid`,
			senderID, result.SenderBalance, now); err != nil {
			return giftReversal{}, err
		}
		if _, err := tx.ExecContext(ctx, `
			INSERT INTO matching.wallet_coin_purchases
			  (id, user_id, package_id, source, provider, idempotency_key, coins, amount_minor,
			   currency, wallet_balance_after, metadata, created_at)
			VALUES (gen_random_uuid(), $1::uuid, 'gift_refund', 'gift_refund', 'internal', $6,
			        $3, 0, 'coins', $4, jsonb_build_object('gift_send_id', $2::text), $5)`,
			senderID, sendID, coins, result.SenderBalance, now, "gift_refund:"+sendID); err != nil {
			return giftReversal{}, err
		}
	} else {
		// A reversed free gift gives back that day's allowance.
		if _, err := tx.ExecContext(ctx, `
			UPDATE matching.gift_daily_entitlements
			SET used_count = GREATEST(used_count - 1, 0), updated_at = $3
			WHERE user_id = $1::uuid AND used_date = ($2::timestamptz AT TIME ZONE 'UTC')::date`,
			senderID, sentAt, now); err != nil {
			return giftReversal{}, err
		}
	}
	if _, err := tx.ExecContext(ctx, `
		UPDATE matching.match_gift_sends
		SET status = 'refunded', refunded_at = $2, refunded_by = $3::uuid, refund_reason = $4
		WHERE id = $1::uuid`, sendID, now, operatorID, reason); err != nil {
		return giftReversal{}, err
	}
	res, err := tx.ExecContext(ctx, `
		UPDATE matching.messages SET is_deleted = TRUE, deleted_at = $2
		WHERE gift_send_id = $1::uuid AND NOT is_deleted`, sendID, now)
	if err != nil {
		return giftReversal{}, err
	}
	if n, _ := res.RowsAffected(); n > 0 {
		result.MessageRetracted = true
	}
	if err := insertSecurityEventTx(ctx, tx, "gift.reversed", operatorID, operatorRole, senderID,
		"gift_send", sendID, map[string]any{"coins_refunded": coins, "reason": reason}); err != nil {
		return giftReversal{}, err
	}
	if err := tx.Commit(); err != nil {
		return giftReversal{}, err
	}
	return result, nil
}
