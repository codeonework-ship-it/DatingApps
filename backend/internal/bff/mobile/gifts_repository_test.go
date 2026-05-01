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
		"",
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

func TestRoseGiftRepository_SendGiftBootstrapsLocalUsersAndPublicMessageWrite(t *testing.T) {
	cfg := config.Config{
		SupabaseURL:         "http://127.0.0.1:54321",
		MatchingSchema:      "matching",
		UserSchema:          "user_management",
		UsersTable:          "users",
		MatchesTable:        "matches",
		GiftCatalogTable:    "gift_catalog",
		UserWalletsTable:    "user_wallets",
		MatchGiftSendsTable: "match_gift_sends",
		MessagesTable:       "messages",
	}

	var (
		userInsertSchemas   []string
		matchShadowInserted bool
		publicMessageInsert bool
		matchingMessageSeen bool
		bootstrappedUsers   = map[string]map[string]struct{}{}
	)

	db := &fakeRoseGiftDB{
		selectReadFn: func(_ context.Context, schema, table string, params url.Values) ([]map[string]any, error) {
			switch table {
			case cfg.UsersTable:
				rows := make([]map[string]any, 0)
				for _, id := range []string{
					"11111111-1111-1111-1111-111111111111",
					"22222222-2222-2222-2222-222222222222",
				} {
					if _, ok := bootstrappedUsers[schema][id]; ok {
						rows = append(rows, map[string]any{"id": id})
					}
				}
				return rows, nil
			case cfg.MatchesTable:
				if schema == cfg.MatchingSchema {
					return nil, nil
				}
				return nil, nil
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
					"user_id":      "11111111-1111-1111-1111-111111111111",
					"coin_balance": 12,
					"updated_at":   time.Now().UTC().Format(time.RFC3339),
				}}, nil
			case cfg.MatchGiftSendsTable:
				return nil, nil
			default:
				return nil, nil
			}
		},
		updateFn: func(_ context.Context, schema, table string, payload any, filters url.Values) ([]map[string]any, error) {
			if schema != cfg.MatchingSchema || table != cfg.UserWalletsTable {
				return nil, nil
			}
			if filters.Get("coin_balance") != "eq.12" {
				t.Fatalf("expected wallet optimistic filter eq.12, got %q", filters.Get("coin_balance"))
			}
			body := payload.(map[string]any)
			if got := body["coin_balance"].(int); got != 11 {
				t.Fatalf("expected updated wallet balance 11, got %d", got)
			}
			return []map[string]any{{
				"user_id":      "11111111-1111-1111-1111-111111111111",
				"coin_balance": 11,
				"updated_at":   time.Now().UTC().Format(time.RFC3339),
			}}, nil
		},
		insertFn: func(_ context.Context, schema, table string, payload any) ([]map[string]any, error) {
			switch table {
			case cfg.UsersTable:
				userInsertSchemas = append(userInsertSchemas, schema)
				rows := payload.([]map[string]any)
				if _, ok := bootstrappedUsers[schema]; !ok {
					bootstrappedUsers[schema] = map[string]struct{}{}
				}
				for _, row := range rows {
					bootstrappedUsers[schema][toString(row["id"])] = struct{}{}
				}
				return rows, nil
			case cfg.MatchesTable:
				if schema == cfg.MatchingSchema {
					matchShadowInserted = true
					rows := payload.([]map[string]any)
					row := rows[0]
					if row["id"] != "1a7e109a-d0db-4576-9eee-5a25c2c12efd" {
						t.Fatalf("expected matching shadow match id to be preserved")
					}
					return rows, nil
				}
				return nil, nil
			case cfg.MatchGiftSendsTable:
				return []map[string]any{{
					"id":               "gift-send-local-1",
					"match_id":         "1a7e109a-d0db-4576-9eee-5a25c2c12efd",
					"sender_user_id":   "11111111-1111-1111-1111-111111111111",
					"receiver_user_id": "22222222-2222-2222-2222-222222222222",
					"gift_id":          "rose_blue_rare",
					"gift_name":        "Blue Rose",
					"gif_url":          "https://example.test/blue.gif",
					"icon_key":         "rose_blue",
					"price_coins":      1,
					"created_at":       time.Now().UTC().Format(time.RFC3339),
				}}, nil
			case cfg.MessagesTable:
				if schema == "public" {
					publicMessageInsert = true
					rows := payload.([]map[string]any)
					row := rows[0]
					if _, ok := row["matchId"]; !ok {
						t.Fatalf("expected public message payload to use matchId")
					}
					if _, ok := row["senderId"]; !ok {
						t.Fatalf("expected public message payload to use senderId")
					}
					return []map[string]any{{"id": "public-msg-1"}}, nil
				}
				if schema == cfg.MatchingSchema {
					matchingMessageSeen = true
				}
				return nil, nil
			default:
				return nil, nil
			}
		},
	}

	repo := &roseGiftRepository{cfg: cfg, db: db}

	view, err := repo.sendGift(
		context.Background(),
		"1a7e109a-d0db-4576-9eee-5a25c2c12efd",
		"11111111-1111-1111-1111-111111111111",
		"22222222-2222-2222-2222-222222222222",
		"rose_blue_rare",
		"idem-local-1",
		"",
		time.Now().UTC(),
	)
	if err != nil {
		t.Fatalf("sendGift local bootstrap flow: %v", err)
	}
	if !containsStringValue(userInsertSchemas, "user_management") {
		t.Fatalf("expected user bootstrap insert in user_management schema, got %v", userInsertSchemas)
	}
	if !containsStringValue(userInsertSchemas, "public") {
		t.Fatalf("expected user bootstrap insert in public schema, got %v", userInsertSchemas)
	}
	if !matchShadowInserted {
		t.Fatalf("expected matching shadow match insert for local gift flow")
	}
	if !publicMessageInsert {
		t.Fatalf("expected public messages insert for local direct PostgREST flow")
	}
	if matchingMessageSeen {
		t.Fatalf("did not expect matching schema messages insert on local direct PostgREST flow")
	}
	if got := view.MessageID; got != "public-msg-1" {
		t.Fatalf("expected message id public-msg-1, got %q", got)
	}
	if got := view.RemainingCoins; got != 11 {
		t.Fatalf("expected remaining coins 11, got %d", got)
	}
}

func containsStringValue(values []string, target string) bool {
	for _, value := range values {
		if value == target {
			return true
		}
	}
	return false
}

// ─── Category field mapping tests ────────────────────────────────────────────

func TestMapRoseGiftCatalogRow_ReturnsCategoryFromDB(t *testing.T) {
	row := map[string]any{
		"id":          "chocolate_box",
		"name":        "Chocolate Box",
		"gif_url":     "https://example.test/choc.gif",
		"icon_key":    "chocolate_box",
		"tier":        "free",
		"category":    "themed_pack",
		"price_coins": 0,
		"is_limited":  false,
		"is_active":   true,
		"sort_order":  200,
	}
	item := mapRoseGiftCatalogRow(row)
	if item.Category != "themed_pack" {
		t.Fatalf("expected category 'themed_pack', got %q", item.Category)
	}
}

func TestMapRoseGiftCatalogRow_DefaultsCategoryToRosesWhenMissing(t *testing.T) {
	row := map[string]any{
		"id":          "rose_red_single",
		"name":        "Single Red Rose",
		"gif_url":     "https://example.test/rose.gif",
		"icon_key":    "rose_red",
		"tier":        "free",
		"price_coins": 0,
		"is_limited":  false,
		"is_active":   true,
		"sort_order":  10,
	}
	item := mapRoseGiftCatalogRow(row)
	if item.Category != "roses" {
		t.Fatalf("expected default category 'roses', got %q", item.Category)
	}
}

func TestMapRoseGiftCatalogRow_ReadsMaxPerMatchPerDay(t *testing.T) {
	row := map[string]any{
		"id":                    "exclusive_diamond_ring",
		"name":                  "Diamond Ring",
		"gif_url":               "https://example.test/ring.gif",
		"icon_key":              "diamond_ring",
		"tier":                  "exclusive",
		"category":              "themed_pack",
		"price_coins":           float64(20),
		"is_limited":            true,
		"is_active":             true,
		"sort_order":            float64(600),
		"max_per_match_per_day": float64(1),
	}
	item := mapRoseGiftCatalogRow(row)
	if item.MaxPerMatchPerDay != 1 {
		t.Fatalf("expected max_per_match_per_day 1, got %d", item.MaxPerMatchPerDay)
	}
}

// ─── Exclusive daily limit tests ─────────────────────────────────────────────

func TestCheckExclusiveDailyLimit_AllowsWhenUnderLimit(t *testing.T) {
	cfg := config.Config{
		MatchingSchema:      "matching",
		MatchGiftSendsTable: "match_gift_sends",
	}
	db := &fakeRoseGiftDB{
		selectReadFn: func(_ context.Context, _ string, table string, _ url.Values) ([]map[string]any, error) {
			// Return 0 rows — no sends today
			return nil, nil
		},
	}
	repo := &roseGiftRepository{db: db, cfg: cfg}
	err := repo.checkExclusiveDailyLimit(context.Background(), "match-1", "user-1", "exclusive_diamond_ring", 1, time.Now())
	if err != nil {
		t.Fatalf("expected no error when under limit, got: %v", err)
	}
}

func TestCheckExclusiveDailyLimit_BlocksWhenAtLimit(t *testing.T) {
	cfg := config.Config{
		MatchingSchema:      "matching",
		MatchGiftSendsTable: "match_gift_sends",
	}
	db := &fakeRoseGiftDB{
		selectReadFn: func(_ context.Context, _ string, table string, _ url.Values) ([]map[string]any, error) {
			// Return 1 row — already sent once today
			return []map[string]any{{"id": "send-1"}}, nil
		},
	}
	repo := &roseGiftRepository{db: db, cfg: cfg}
	err := repo.checkExclusiveDailyLimit(context.Background(), "match-1", "user-1", "exclusive_diamond_ring", 1, time.Now())
	if err == nil {
		t.Fatal("expected error when at daily limit, got nil")
	}
	if !strings.Contains(err.Error(), "daily limit") {
		t.Fatalf("expected 'daily limit' in error, got: %v", err)
	}
}

func TestCheckExclusiveDailyLimit_SkipsCheckWhenZero(t *testing.T) {
	cfg := config.Config{
		MatchingSchema:      "matching",
		MatchGiftSendsTable: "match_gift_sends",
	}
	db := &fakeRoseGiftDB{
		selectReadFn: func(_ context.Context, _ string, _ string, _ url.Values) ([]map[string]any, error) {
			t.Fatal("selectRead should not be called when maxPerDay=0")
			return nil, nil
		},
	}
	repo := &roseGiftRepository{db: db, cfg: cfg}
	err := repo.checkExclusiveDailyLimit(context.Background(), "match-1", "user-1", "rose_red_single", 0, time.Now())
	if err != nil {
		t.Fatalf("expected no error for zero limit, got: %v", err)
	}
}
