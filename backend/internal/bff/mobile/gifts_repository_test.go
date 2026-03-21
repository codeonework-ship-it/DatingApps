package mobile

import (
	"context"
	"errors"
	"net/url"
	"strings"
	"testing"
	"time"

	"github.com/verified-dating/backend/internal/platform/config"
)

type fakeRoseGiftDB struct {
	selectReadFn func(ctx context.Context, schema, table string, params url.Values) ([]map[string]any, error)
	insertFn     func(ctx context.Context, schema, table string, payload any) ([]map[string]any, error)
	updateFn     func(ctx context.Context, schema, table string, payload any, filters url.Values) ([]map[string]any, error)
	deleteFn     func(ctx context.Context, schema, table string, filters url.Values) ([]map[string]any, error)
}

func (f *fakeRoseGiftDB) SelectRead(ctx context.Context, schema, table string, params url.Values) ([]map[string]any, error) {
	if f.selectReadFn == nil {
		return nil, nil
	}
	return f.selectReadFn(ctx, schema, table, params)
}

func (f *fakeRoseGiftDB) Insert(ctx context.Context, schema, table string, payload any) ([]map[string]any, error) {
	if f.insertFn == nil {
		return nil, nil
	}
	return f.insertFn(ctx, schema, table, payload)
}

func (f *fakeRoseGiftDB) Update(ctx context.Context, schema, table string, payload any, filters url.Values) ([]map[string]any, error) {
	if f.updateFn == nil {
		return nil, nil
	}
	return f.updateFn(ctx, schema, table, payload, filters)
}

func (f *fakeRoseGiftDB) Delete(ctx context.Context, schema, table string, filters url.Values) ([]map[string]any, error) {
	if f.deleteFn == nil {
		return nil, nil
	}
	return f.deleteFn(ctx, schema, table, filters)
}

func TestRoseGiftRepository_SendGiftRollsBackWhenChatInsertFails(t *testing.T) {
	cfg := config.Config{
		MatchingSchema:      "matching",
		GiftCatalogTable:    "gift_catalog",
		UserWalletsTable:    "user_wallets",
		MatchGiftSendsTable: "match_gift_sends",
		MessagesTable:       "messages",
	}

	var (
		walletBalance    = 12
		debitCalled      bool
		rollbackCalled   bool
		deleteSendCalled bool
	)
	db := &fakeRoseGiftDB{
		selectReadFn: func(_ context.Context, _ string, table string, params url.Values) ([]map[string]any, error) {
			switch table {
			case cfg.GiftCatalogTable:
				return []map[string]any{{
					"id":          "rose_blue_rare",
					"name":        "Blue Rose",
					"gif_url":     "https://example.test/blue.gif",
					"icon_key":    "rose_blue",
					"tier":        "premium_common",
					"price_coins": 1,
					"is_limited":  false,
					"is_active":   true,
					"sort_order":  10,
				}}, nil
			case cfg.UserWalletsTable:
				return []map[string]any{{
					"user_id":      "sender-user-1",
					"coin_balance": walletBalance,
					"updated_at":   time.Now().UTC().Format(time.RFC3339),
				}}, nil
			case cfg.MatchGiftSendsTable:
				if params.Get("idempotency_key") != "" {
					return nil, nil
				}
				return nil, nil
			default:
				return nil, nil
			}
		},
		updateFn: func(_ context.Context, _ string, table string, payload any, filters url.Values) ([]map[string]any, error) {
			if table != cfg.UserWalletsTable {
				return nil, nil
			}
			body := payload.(map[string]any)
			nextBalance := body["coin_balance"].(int)
			switch nextBalance {
			case 11:
				debitCalled = true
				if filters.Get("coin_balance") != "eq.12" {
					t.Fatalf("expected optimistic debit filter eq.12, got %q", filters.Get("coin_balance"))
				}
				walletBalance = 11
				return []map[string]any{{
					"user_id":      "sender-user-1",
					"coin_balance": walletBalance,
					"updated_at":   time.Now().UTC().Format(time.RFC3339),
				}}, nil
			case 12:
				rollbackCalled = true
				if filters.Get("coin_balance") != "eq.11" {
					t.Fatalf("expected rollback filter eq.11, got %q", filters.Get("coin_balance"))
				}
				walletBalance = 12
				return []map[string]any{{
					"user_id":      "sender-user-1",
					"coin_balance": walletBalance,
					"updated_at":   time.Now().UTC().Format(time.RFC3339),
				}}, nil
			default:
				t.Fatalf("unexpected wallet balance update: %d", nextBalance)
				return nil, nil
			}
		},
		insertFn: func(_ context.Context, _ string, table string, _ any) ([]map[string]any, error) {
			switch table {
			case cfg.MatchGiftSendsTable:
				return []map[string]any{{
					"id":               "gift-send-1",
					"match_id":         "match-1",
					"sender_user_id":   "sender-user-1",
					"receiver_user_id": "receiver-user-1",
					"gift_id":          "rose_blue_rare",
					"gift_name":        "Blue Rose",
					"gif_url":          "https://example.test/blue.gif",
					"icon_key":         "rose_blue",
					"price_coins":      1,
					"created_at":       time.Now().UTC().Format(time.RFC3339),
				}}, nil
			case cfg.MessagesTable:
				return nil, errors.New("chat insert failed")
			default:
				return nil, nil
			}
		},
		deleteFn: func(_ context.Context, _ string, table string, _ url.Values) ([]map[string]any, error) {
			if table == cfg.MatchGiftSendsTable {
				deleteSendCalled = true
			}
			return []map[string]any{{"id": "gift-send-1"}}, nil
		},
	}
	repo := &roseGiftRepository{cfg: cfg, db: db}

	_, err := repo.sendGift(
		context.Background(),
		"match-1",
		"sender-user-1",
		"receiver-user-1",
		"rose_blue_rare",
		"",
		time.Now().UTC(),
	)
	if err == nil {
		t.Fatalf("expected error when chat insert fails")
	}
	if !strings.Contains(strings.ToLower(err.Error()), "rolled back") {
		t.Fatalf("expected rollback-aware error, got: %v", err)
	}
	if !debitCalled {
		t.Fatalf("expected wallet debit to be attempted")
	}
	if !rollbackCalled {
		t.Fatalf("expected wallet rollback after chat insert failure")
	}
	if !deleteSendCalled {
		t.Fatalf("expected gift send record delete rollback")
	}
	if walletBalance != 12 {
		t.Fatalf("expected wallet balance restored to 12, got %d", walletBalance)
	}
}

func TestRoseGiftRepository_SendGiftUsesDurableIdempotencyRecord(t *testing.T) {
	cfg := config.Config{
		MatchingSchema:      "matching",
		GiftCatalogTable:    "gift_catalog",
		UserWalletsTable:    "user_wallets",
		MatchGiftSendsTable: "match_gift_sends",
		MessagesTable:       "messages",
	}

	var updateCalls, insertCalls int
	db := &fakeRoseGiftDB{
		selectReadFn: func(_ context.Context, _ string, table string, params url.Values) ([]map[string]any, error) {
			switch table {
			case cfg.GiftCatalogTable:
				return []map[string]any{{
					"id":          "rose_blue_rare",
					"name":        "Blue Rose",
					"gif_url":     "https://example.test/blue.gif",
					"icon_key":    "rose_blue",
					"tier":        "premium_common",
					"price_coins": 1,
					"is_limited":  false,
					"is_active":   true,
					"sort_order":  10,
				}}, nil
			case cfg.UserWalletsTable:
				return []map[string]any{{
					"user_id":      "sender-user-2",
					"coin_balance": 9,
					"updated_at":   time.Now().UTC().Format(time.RFC3339),
				}}, nil
			case cfg.MatchGiftSendsTable:
				if params.Get("idempotency_key") == "eq.idem-42" {
					return []map[string]any{{
						"id":               "gift-send-existing",
						"match_id":         "match-2",
						"sender_user_id":   "sender-user-2",
						"receiver_user_id": "receiver-user-2",
						"gift_id":          "rose_blue_rare",
						"gift_name":        "Blue Rose",
						"gif_url":          "https://example.test/blue.gif",
						"icon_key":         "rose_blue",
						"price_coins":      1,
						"created_at":       time.Now().UTC().Format(time.RFC3339),
					}}, nil
				}
				return nil, nil
			default:
				return nil, nil
			}
		},
		updateFn: func(_ context.Context, _ string, _ string, _ any, _ url.Values) ([]map[string]any, error) {
			updateCalls++
			return nil, nil
		},
		insertFn: func(_ context.Context, _ string, _ string, _ any) ([]map[string]any, error) {
			insertCalls++
			return nil, nil
		},
	}
	repo := &roseGiftRepository{cfg: cfg, db: db}

	view, err := repo.sendGift(
		context.Background(),
		"match-2",
		"sender-user-2",
		"receiver-user-2",
		"rose_blue_rare",
		"idem-42",
		time.Now().UTC(),
	)
	if err != nil {
		t.Fatalf("sendGift with idempotency replay: %v", err)
	}
	if view.ID != "gift-send-existing" {
		t.Fatalf("expected existing send id, got %q", view.ID)
	}
	if view.RemainingCoins != 9 {
		t.Fatalf("expected remaining coins from wallet snapshot 9, got %d", view.RemainingCoins)
	}
	if updateCalls != 0 {
		t.Fatalf("expected no wallet update on idempotent replay, got %d", updateCalls)
	}
	if insertCalls != 0 {
		t.Fatalf("expected no inserts on idempotent replay, got %d", insertCalls)
	}
}

func TestRoseGiftRepository_SendGiftFallsBackToGeneratedIdentifiers(t *testing.T) {
	cfg := config.Config{
		MatchingSchema:      "matching",
		GiftCatalogTable:    "gift_catalog",
		UserWalletsTable:    "user_wallets",
		MatchGiftSendsTable: "match_gift_sends",
		MessagesTable:       "messages",
	}

	db := &fakeRoseGiftDB{
		selectReadFn: func(_ context.Context, _ string, table string, params url.Values) ([]map[string]any, error) {
			switch table {
			case cfg.GiftCatalogTable:
				return []map[string]any{{
					"id":          "rose_blue_rare",
					"name":        "Blue Rose",
					"gif_url":     "https://example.test/blue.gif",
					"icon_key":    "rose_blue",
					"tier":        "premium_common",
					"price_coins": 1,
					"is_limited":  false,
					"is_active":   true,
					"sort_order":  10,
				}}, nil
			case cfg.UserWalletsTable:
				return []map[string]any{{
					"user_id":      "sender-fallback-1",
					"coin_balance": 12,
					"updated_at":   time.Now().UTC().Format(time.RFC3339),
				}}, nil
			case cfg.MatchGiftSendsTable:
				if params.Get("idempotency_key") != "" {
					return nil, nil
				}
				return nil, nil
			default:
				return nil, nil
			}
		},
		updateFn: func(_ context.Context, _ string, table string, payload any, filters url.Values) ([]map[string]any, error) {
			if table != cfg.UserWalletsTable {
				return nil, nil
			}
			if filters.Get("coin_balance") != "eq.12" {
				t.Fatalf("expected optimistic debit filter eq.12, got %q", filters.Get("coin_balance"))
			}
			if got := payload.(map[string]any)["coin_balance"].(int); got != 11 {
				t.Fatalf("expected new coin balance 11, got %d", got)
			}
			return []map[string]any{{
				"user_id":      "sender-fallback-1",
				"coin_balance": 11,
				"updated_at":   time.Now().UTC().Format(time.RFC3339),
			}}, nil
		},
		insertFn: func(_ context.Context, _ string, table string, _ any) ([]map[string]any, error) {
			switch table {
			case cfg.MatchGiftSendsTable:
				return []map[string]any{{
					"match_id":         "match-fallback-1",
					"sender_user_id":   "sender-fallback-1",
					"receiver_user_id": "receiver-fallback-1",
					"price_coins":      1,
					"created_at":       time.Now().UTC().Format(time.RFC3339),
				}}, nil
			case cfg.MessagesTable:
				return []map[string]any{{"id": "msg-1"}}, nil
			default:
				return nil, nil
			}
		},
	}

	repo := &roseGiftRepository{cfg: cfg, db: db}

	view, err := repo.sendGift(
		context.Background(),
		"match-fallback-1",
		"sender-fallback-1",
		"receiver-fallback-1",
		"rose_blue_rare",
		"",
		time.Now().UTC(),
	)
	if err != nil {
		t.Fatalf("sendGift fallback identifiers: %v", err)
	}
	if strings.TrimSpace(view.ID) == "" {
		t.Fatalf("expected generated gift send id")
	}
	if got := view.GiftID; got != "rose_blue_rare" {
		t.Fatalf("expected gift_id rose_blue_rare, got %q", got)
	}
	if got := view.GiftName; got != "Blue Rose" {
		t.Fatalf("expected gift name Blue Rose, got %q", got)
	}
	if got := view.GifURL; got != "https://example.test/blue.gif" {
		t.Fatalf("expected gift gif_url fallback, got %q", got)
	}
	if got := view.IconKey; got != "rose_blue" {
		t.Fatalf("expected icon_key rose_blue, got %q", got)
	}
	if got := view.RemainingCoins; got != 11 {
		t.Fatalf("expected remaining coins 11, got %d", got)
	}
}

func TestRoseGiftRepository_RecordGiftSpendActivityPersistsRow(t *testing.T) {
	cfg := config.Config{
		MatchingSchema:           "matching",
		GiftSpendActivitiesTable: "gift_spend_activities",
	}

	insertCalls := 0
	var insertedPayload map[string]any
	db := &fakeRoseGiftDB{
		insertFn: func(_ context.Context, schema, table string, payload any) ([]map[string]any, error) {
			insertCalls++
			if schema != cfg.MatchingSchema {
				t.Fatalf("expected schema %q, got %q", cfg.MatchingSchema, schema)
			}
			if table != cfg.GiftSpendActivitiesTable {
				t.Fatalf("expected table %q, got %q", cfg.GiftSpendActivitiesTable, table)
			}
			rows, ok := payload.([]map[string]any)
			if !ok || len(rows) != 1 {
				t.Fatalf("expected one-row payload, got %#v", payload)
			}
			insertedPayload = rows[0]
			return []map[string]any{{"id": insertedPayload["id"]}}, nil
		},
	}
	repo := &roseGiftRepository{cfg: cfg, db: db}

	walletAfter := 11
	err := repo.recordGiftSpendActivity(context.Background(), giftSpendActivityRecord{
		MatchID:            "11111111-1111-1111-1111-111111111111",
		SenderUserID:       "22222222-2222-2222-2222-222222222222",
		ReceiverUserID:     "33333333-3333-3333-3333-333333333333",
		GiftID:             "rose_blue_rare",
		Action:             "gift_send_succeeded",
		Status:             "success",
		PriceCoins:         1,
		WalletBalanceAfter: &walletAfter,
		IdempotencyKey:     "idem-1001",
		Details: map[string]any{
			"gift_tier": "premium_common",
		},
		CreatedAt: time.Date(2026, time.March, 21, 15, 0, 0, 0, time.UTC),
	})
	if err != nil {
		t.Fatalf("recordGiftSpendActivity: %v", err)
	}
	if insertCalls != 1 {
		t.Fatalf("expected 1 insert call, got %d", insertCalls)
	}
	if got := strings.TrimSpace(toString(insertedPayload["action"])); got != "gift_send_succeeded" {
		t.Fatalf("expected action gift_send_succeeded, got %q", got)
	}
	if got := toIntOrZero(insertedPayload["price_coins"]); got != 1 {
		t.Fatalf("expected price_coins=1, got %d", got)
	}
	if got := toIntOrZero(insertedPayload["wallet_balance_after"]); got != 11 {
		t.Fatalf("expected wallet_balance_after=11, got %d", got)
	}
}

func TestRoseGiftRepository_CreditWalletCoinsUsesDurableIdempotencyRecord(t *testing.T) {
	cfg := config.Config{
		MatchingSchema:           "matching",
		UserWalletsTable:         "user_wallets",
		WalletCoinPurchasesTable: "wallet_coin_purchases",
	}

	var updateCalls, insertCalls int
	db := &fakeRoseGiftDB{
		selectReadFn: func(_ context.Context, _ string, table string, params url.Values) ([]map[string]any, error) {
			switch table {
			case cfg.UserWalletsTable:
				return []map[string]any{{
					"user_id":      "wallet-user-42",
					"coin_balance": 12,
					"updated_at":   time.Now().UTC().Format(time.RFC3339),
				}}, nil
			case cfg.WalletCoinPurchasesTable:
				if params.Get("idempotency_key") == "eq.wallet-buy-idem-42" {
					return []map[string]any{{
						"id":                   "purchase-existing-42",
						"user_id":              "wallet-user-42",
						"package_id":           "starter_pack",
						"source":               "buy",
						"provider":             "stripe",
						"purchase_ref":         "pi_42",
						"idempotency_key":      "wallet-buy-idem-42",
						"coins":                5,
						"amount_minor":         99,
						"currency":             "INR",
						"wallet_balance_after": 17,
						"metadata":             map[string]any{},
						"created_at":           time.Now().UTC().Format(time.RFC3339),
					}}, nil
				}
				return nil, nil
			default:
				return nil, nil
			}
		},
		updateFn: func(_ context.Context, _ string, _ string, _ any, _ url.Values) ([]map[string]any, error) {
			updateCalls++
			return nil, nil
		},
		insertFn: func(_ context.Context, _ string, _ string, _ any) ([]map[string]any, error) {
			insertCalls++
			return nil, nil
		},
	}
	repo := &roseGiftRepository{cfg: cfg, db: db}

	wallet, purchase, err := repo.creditWalletCoins(context.Background(), walletCoinCreditRequest{
		UserID:         "wallet-user-42",
		PackageID:      "starter_pack",
		Source:         "buy",
		Provider:       "stripe",
		PurchaseRef:    "pi_42",
		IdempotencyKey: "wallet-buy-idem-42",
		Coins:          5,
		AmountMinor:    99,
		Currency:       "INR",
		Now:            time.Now().UTC(),
	})
	if err != nil {
		t.Fatalf("creditWalletCoins idempotent replay: %v", err)
	}
	if got := wallet.CoinBalance; got != 12 {
		t.Fatalf("expected wallet balance 12 on replay, got %d", got)
	}
	if got := purchase.ID; got != "purchase-existing-42" {
		t.Fatalf("expected existing purchase id, got %q", got)
	}
	if updateCalls != 0 {
		t.Fatalf("expected no wallet update on idempotent replay, got %d", updateCalls)
	}
	if insertCalls != 0 {
		t.Fatalf("expected no purchase insert on idempotent replay, got %d", insertCalls)
	}
}

func TestRoseGiftRepository_CreditWalletCoinsRollsBackWhenPurchaseInsertFails(t *testing.T) {
	cfg := config.Config{
		MatchingSchema:           "matching",
		UserWalletsTable:         "user_wallets",
		WalletCoinPurchasesTable: "wallet_coin_purchases",
	}

	walletBalance := 12
	debitCalled := false
	rollbackCalled := false
	db := &fakeRoseGiftDB{
		selectReadFn: func(_ context.Context, _ string, table string, _ url.Values) ([]map[string]any, error) {
			switch table {
			case cfg.UserWalletsTable:
				return []map[string]any{{
					"user_id":      "wallet-user-rollback",
					"coin_balance": walletBalance,
					"updated_at":   time.Now().UTC().Format(time.RFC3339),
				}}, nil
			case cfg.WalletCoinPurchasesTable:
				return nil, nil
			default:
				return nil, nil
			}
		},
		updateFn: func(_ context.Context, _ string, table string, payload any, filters url.Values) ([]map[string]any, error) {
			if table != cfg.UserWalletsTable {
				return nil, nil
			}
			next := payload.(map[string]any)["coin_balance"].(int)
			switch next {
			case 19:
				debitCalled = true
				if filters.Get("coin_balance") != "eq.12" {
					t.Fatalf("expected optimistic credit filter eq.12, got %q", filters.Get("coin_balance"))
				}
				walletBalance = 19
				return []map[string]any{{
					"user_id":      "wallet-user-rollback",
					"coin_balance": walletBalance,
					"updated_at":   time.Now().UTC().Format(time.RFC3339),
				}}, nil
			case 12:
				rollbackCalled = true
				if filters.Get("coin_balance") != "eq.19" {
					t.Fatalf("expected rollback filter eq.19, got %q", filters.Get("coin_balance"))
				}
				walletBalance = 12
				return []map[string]any{{
					"user_id":      "wallet-user-rollback",
					"coin_balance": walletBalance,
					"updated_at":   time.Now().UTC().Format(time.RFC3339),
				}}, nil
			default:
				t.Fatalf("unexpected wallet update balance: %d", next)
				return nil, nil
			}
		},
		insertFn: func(_ context.Context, _ string, table string, _ any) ([]map[string]any, error) {
			if table == cfg.WalletCoinPurchasesTable {
				return nil, errors.New("purchase insert failed")
			}
			return nil, nil
		},
	}

	repo := &roseGiftRepository{cfg: cfg, db: db}

	_, _, err := repo.creditWalletCoins(context.Background(), walletCoinCreditRequest{
		UserID:      "wallet-user-rollback",
		PackageID:   "big_pack",
		Source:      "buy",
		Provider:    "stripe",
		Coins:       7,
		AmountMinor: 199,
		Currency:    "INR",
		Now:         time.Now().UTC(),
	})
	if err == nil {
		t.Fatalf("expected error when purchase insert fails")
	}
	if !debitCalled {
		t.Fatalf("expected wallet credit update to be attempted")
	}
	if !rollbackCalled {
		t.Fatalf("expected wallet rollback after purchase insert failure")
	}
	if walletBalance != 12 {
		t.Fatalf("expected wallet balance restored to 12, got %d", walletBalance)
	}
}
