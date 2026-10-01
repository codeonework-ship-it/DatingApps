package mobile

import (
	"context"
	"database/sql"
	"errors"
	"os"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"
)

type giftLedgerFixture struct {
	db       *sql.DB
	ledger   *giftSendLedger
	sender   string
	receiver string
	outsider string
	matchID  string
}

func newGiftLedgerFixture(t *testing.T, coins int) giftLedgerFixture {
	t.Helper()
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

	var hasColumn bool
	if err := db.QueryRowContext(ctx, `SELECT EXISTS(SELECT 1 FROM information_schema.columns
		WHERE table_schema='matching' AND table_name='messages' AND column_name='gift_send_id')`).Scan(&hasColumn); err != nil {
		t.Fatal(err)
	}
	if !hasColumn {
		t.Skip("migration 074_gift_send_integrity is not applied")
	}

	f := giftLedgerFixture{db: db, ledger: newGiftSendLedger(db)}
	users := make([]string, 3)
	for i := range users {
		id := uuid.NewString()
		name := "giftqa_" + strings.ReplaceAll(id[:8], "-", "")
		if _, err := db.ExecContext(ctx, `INSERT INTO user_management.users (id, username, name, date_of_birth, gender, email)
			VALUES ($1,$2,'Gift QA','1990-01-01','female',$3)`, id, name, name+"@example.test"); err != nil {
			t.Fatalf("seed member: %v", err)
		}
		users[i] = id
	}
	t.Cleanup(func() {
		for _, id := range users {
			_, _ = db.ExecContext(ctx, `DELETE FROM user_management.users WHERE id=$1`, id)
		}
	})
	f.sender, f.receiver, f.outsider = users[0], users[1], users[2]
	f.matchID = uuid.NewString()
	first, second := f.sender, f.receiver
	if first > second { // matches stores the pair ordered
		first, second = second, first
	}
	if _, err := db.ExecContext(ctx, `INSERT INTO matching.matches (id, user_id_1, user_id_2) VALUES ($1,$2,$3)`,
		f.matchID, first, second); err != nil {
		t.Fatalf("seed match: %v", err)
	}
	if _, err := db.ExecContext(ctx, `INSERT INTO matching.user_wallets (user_id, coin_balance) VALUES ($1,$2)`,
		f.sender, coins); err != nil {
		t.Fatalf("seed wallet: %v", err)
	}
	return f
}

func (f giftLedgerFixture) balance(t *testing.T) int {
	t.Helper()
	var coins int
	if err := f.db.QueryRow(`SELECT coin_balance FROM matching.user_wallets WHERE user_id=$1`, f.sender).Scan(&coins); err != nil {
		t.Fatal(err)
	}
	return coins
}

func (f giftLedgerFixture) sends(t *testing.T) int {
	t.Helper()
	var count int
	if err := f.db.QueryRow(`SELECT COUNT(*) FROM matching.match_gift_sends WHERE match_id=$1`, f.matchID).Scan(&count); err != nil {
		t.Fatal(err)
	}
	return count
}

func (f giftLedgerFixture) send(giftID, key string) (roseGiftSendView, error) {
	return f.ledger.send(context.Background(), giftSendRequest{
		MatchID:        f.matchID,
		SenderUserID:   f.sender,
		GiftID:         giftID,
		IdempotencyKey: key,
		Note:           "For you 🌹",
		Now:            time.Now().UTC(),
	})
}

// TestGiftSendLedgerCommitsDebitSendAndMessageTogetherPostgres covers GIFT-003:
// one debit, one send row, one linked chat message, a gift-aware push, and a
// same-key retry that does not charge twice.
func TestGiftSendLedgerCommitsDebitSendAndMessageTogetherPostgres(t *testing.T) {
	f := newGiftLedgerFixture(t, 10)

	view, err := f.send("rose_sparkle", "key-1")
	if err != nil {
		t.Fatalf("send: %v", err)
	}
	if view.PriceCoins != 3 || view.RemainingCoins != 7 || f.balance(t) != 7 {
		t.Fatalf("debit: view=%+v balance=%d", view, f.balance(t))
	}
	if view.ReceiverUserID != f.receiver {
		t.Fatalf("receiver derived from match = %q, want %q", view.ReceiverUserID, f.receiver)
	}

	var linkedText, note string
	if err := f.db.QueryRow(`SELECT m.text, s.message FROM matching.messages m
		JOIN matching.match_gift_sends s ON s.id = m.gift_send_id WHERE m.id=$1`, view.MessageID).Scan(&linkedText, &note); err != nil {
		t.Fatalf("linked message: %v", err)
	}
	if !strings.Contains(linkedText, "[gift:id=rose_sparkle") || note != "For you 🌹" {
		t.Fatalf("message=%q note=%q", linkedText, note)
	}

	var title, body string
	if err := f.db.QueryRow(`SELECT title, body FROM matching.notification_outbox
		WHERE dedupe_key = 'message:' || $1`, view.MessageID).Scan(&title, &body); err != nil {
		t.Fatalf("notification: %v", err)
	}
	if title != "Gift received" || !strings.Contains(body, "Gift QA sent you Sparkle Rose.") || strings.Contains(body, "[gift:") {
		t.Fatalf("notification title=%q body=%q", title, body)
	}

	replay, err := f.send("rose_sparkle", "key-1")
	if err != nil {
		t.Fatalf("replay: %v", err)
	}
	if replay.ID != view.ID || replay.MessageID != view.MessageID || f.balance(t) != 7 || f.sends(t) != 1 {
		t.Fatalf("replay charged again: replay=%+v balance=%d sends=%d", replay, f.balance(t), f.sends(t))
	}
	if _, err := f.send("rose_golden", "key-1"); !errors.Is(err, errGiftIdempotencyReplay) {
		t.Fatalf("key reused for another gift: err=%v", err)
	}
}

func TestGiftSendLedgerRefusalsLeaveNoPartialStatePostgres(t *testing.T) {
	f := newGiftLedgerFixture(t, 2)

	if _, err := f.send("rose_golden", "too-expensive"); !errors.Is(err, errGiftInsufficientCoins) {
		t.Fatalf("insufficient: err=%v", err)
	}
	if f.balance(t) != 2 || f.sends(t) != 0 {
		t.Fatalf("partial state after refusal: balance=%d sends=%d", f.balance(t), f.sends(t))
	}

	_, err := f.ledger.send(context.Background(), giftSendRequest{
		MatchID: f.matchID, SenderUserID: f.sender, ReceiverUserID: f.outsider,
		GiftID: "rose_blue_rare", IdempotencyKey: "wrong-receiver",
	})
	if !errors.Is(err, errGiftReceiverMismatch) {
		t.Fatalf("receiver mismatch: err=%v", err)
	}
	_, err = f.ledger.send(context.Background(), giftSendRequest{
		MatchID: f.matchID, SenderUserID: f.outsider,
		GiftID: "rose_blue_rare", IdempotencyKey: "outsider",
	})
	if !errors.Is(err, errGiftMatchInactive) {
		t.Fatalf("non-participant: err=%v", err)
	}

	expired := "qa_expired_" + strings.ReplaceAll(uuid.NewString()[:8], "-", "")
	if _, err := f.db.Exec(`INSERT INTO matching.gift_catalog (id, name, tier, category, price_coins, end_date)
		VALUES ($1,'Expired QA','seasonal_limited','seasonal',1, NOW() - INTERVAL '1 day')`, expired); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _, _ = f.db.Exec(`DELETE FROM matching.gift_catalog WHERE id=$1`, expired) })
	if _, err := f.send(expired, "expired"); !errors.Is(err, errGiftUnavailable) {
		t.Fatalf("seasonal window: err=%v", err)
	}
	if f.balance(t) != 2 || f.sends(t) != 0 {
		t.Fatalf("partial state after refusals: balance=%d sends=%d", f.balance(t), f.sends(t))
	}
}

// TestGiftSendLedgerFreeGiftOncePerUTCDayPostgres covers GIFT-004.
func TestGiftSendLedgerFreeGiftOncePerUTCDayPostgres(t *testing.T) {
	f := newGiftLedgerFixture(t, 0)

	if _, err := f.send("rose_red_single", "free-1"); err != nil {
		t.Fatalf("first free gift: %v", err)
	}
	if _, err := f.send("chocolate_box", "free-2"); !errors.Is(err, errFreeGiftDailyLimit) {
		t.Fatalf("second free gift: err=%v", err)
	}
	var used int
	if err := f.db.QueryRow(`SELECT used_count FROM matching.gift_daily_entitlements
		WHERE user_id=$1 AND used_date=(NOW() AT TIME ZONE 'UTC')::date`, f.sender).Scan(&used); err != nil {
		t.Fatal(err)
	}
	if used != 1 || f.sends(t) != 1 {
		t.Fatalf("entitlement used=%d sends=%d", used, f.sends(t))
	}
}

// TestGiftSendLedgerExclusiveLimitHoldsUnderConcurrencyPostgres covers
// GIFT-005: concurrent sends with different keys cannot exceed the limit.
func TestGiftSendLedgerExclusiveLimitHoldsUnderConcurrencyPostgres(t *testing.T) {
	f := newGiftLedgerFixture(t, 200)

	const attempts = 6
	var wg sync.WaitGroup
	results := make(chan error, attempts)
	for i := 0; i < attempts; i++ {
		wg.Add(1)
		go func(i int) {
			defer wg.Done()
			_, err := f.send("exclusive_diamond_ring", uuid.NewString())
			results <- err
		}(i)
	}
	wg.Wait()
	close(results)

	succeeded, limited := 0, 0
	for err := range results {
		switch {
		case err == nil:
			succeeded++
		case errors.Is(err, errGiftExclusiveDailyLimit):
			limited++
		default:
			t.Fatalf("unexpected error: %v", err)
		}
	}
	if succeeded != 1 || limited != attempts-1 || f.balance(t) != 180 || f.sends(t) != 1 {
		t.Fatalf("succeeded=%d limited=%d balance=%d sends=%d", succeeded, limited, f.balance(t), f.sends(t))
	}
}
