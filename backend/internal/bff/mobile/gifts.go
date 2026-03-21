package mobile

import (
	"context"
	"errors"
	"fmt"
	"sort"
	"strings"
	"time"
)

type roseGiftCatalogItem struct {
	ID         string `json:"id"`
	Name       string `json:"name"`
	GifURL     string `json:"-"`
	IconKey    string `json:"icon_key"`
	Tier       string `json:"tier"`
	PriceCoins int    `json:"price_coins"`
	IsLimited  bool   `json:"is_limited"`
	IsActive   bool   `json:"is_active"`
	SortOrder  int    `json:"sort_order"`
}

type userWalletView struct {
	UserID      string `json:"user_id"`
	CoinBalance int    `json:"coin_balance"`
	UpdatedAt   string `json:"updated_at"`
}

type roseGiftSendView struct {
	ID             string `json:"id"`
	MatchID        string `json:"match_id"`
	SenderUserID   string `json:"sender_user_id"`
	ReceiverUserID string `json:"receiver_user_id"`
	GiftID         string `json:"gift_id"`
	GiftName       string `json:"gift_name"`
	GifURL         string `json:"-"`
	IconKey        string `json:"icon_key"`
	PriceCoins     int    `json:"price_coins"`
	CreatedAt      string `json:"created_at"`
	RemainingCoins int    `json:"remaining_coins"`
	MessageID      string `json:"message_id,omitempty"`
}

type walletCoinPurchaseView struct {
	ID                 string         `json:"id"`
	UserID             string         `json:"user_id"`
	PackageID          string         `json:"package_id"`
	Source             string         `json:"source"`
	Provider           string         `json:"provider"`
	PurchaseRef        string         `json:"purchase_ref,omitempty"`
	IdempotencyKey     string         `json:"idempotency_key,omitempty"`
	Coins              int            `json:"coins"`
	AmountMinor        int            `json:"amount_minor"`
	Currency           string         `json:"currency"`
	WalletBalanceAfter int            `json:"wallet_balance_after"`
	Metadata           map[string]any `json:"metadata,omitempty"`
	CreatedAt          string         `json:"created_at"`
}

func defaultRoseGiftCatalogMap() map[string]roseGiftCatalogItem {
	items := []roseGiftCatalogItem{
		{
			ID:         "rose_red_single",
			Name:       "Single Red Rose",
			GifURL:     "https://media.giphy.com/media/26xBwdIuRJiAIqHwA/giphy.gif",
			IconKey:    "rose_red",
			Tier:       "free",
			PriceCoins: 0,
			IsLimited:  false,
			IsActive:   true,
			SortOrder:  10,
		},
		{
			ID:         "rose_pink_soft",
			Name:       "Pink Rose",
			GifURL:     "https://media.giphy.com/media/fVtcfEXWQJQUbsF1sH/giphy.gif",
			IconKey:    "rose_pink",
			Tier:       "free",
			PriceCoins: 0,
			IsLimited:  false,
			IsActive:   true,
			SortOrder:  20,
		},
		{
			ID:         "rose_white_pure",
			Name:       "White Rose",
			GifURL:     "https://media.giphy.com/media/xT1XGzAnABSXy8DPCU/giphy.gif",
			IconKey:    "rose_white",
			Tier:       "free",
			PriceCoins: 0,
			IsLimited:  false,
			IsActive:   true,
			SortOrder:  30,
		},
		{
			ID:         "rose_yellow_friendship",
			Name:       "Yellow Rose",
			GifURL:     "https://media.giphy.com/media/l0Iy5tjhyfU1xL9wQ/giphy.gif",
			IconKey:    "rose_yellow",
			Tier:       "free",
			PriceCoins: 0,
			IsLimited:  false,
			IsActive:   true,
			SortOrder:  40,
		},
		{
			ID:         "rose_lavender_crush",
			Name:       "Lavender Rose",
			GifURL:     "https://media.giphy.com/media/26xBukhL8Y5H9P9VS/giphy.gif",
			IconKey:    "rose_lavender",
			Tier:       "free",
			PriceCoins: 0,
			IsLimited:  false,
			IsActive:   true,
			SortOrder:  50,
		},
		{
			ID:         "rose_blue_rare",
			Name:       "Blue Rose",
			GifURL:     "https://media.giphy.com/media/3oz8xAFtqoOUUrsh7W/giphy.gif",
			IconKey:    "rose_blue",
			Tier:       "premium_common",
			PriceCoins: 1,
			IsLimited:  false,
			IsActive:   true,
			SortOrder:  60,
		},
		{
			ID:         "rose_black_mystery",
			Name:       "Black Rose",
			GifURL:     "https://media.giphy.com/media/l0ExncehJzexFpRHq/giphy.gif",
			IconKey:    "rose_black",
			Tier:       "premium_common",
			PriceCoins: 1,
			IsLimited:  false,
			IsActive:   true,
			SortOrder:  70,
		},
		{
			ID:         "rose_sparkle",
			Name:       "Sparkle Rose",
			GifURL:     "https://media.giphy.com/media/3o7TKz9b9NQwQ2N8hW/giphy.gif",
			IconKey:    "rose_sparkle",
			Tier:       "premium_rare",
			PriceCoins: 3,
			IsLimited:  false,
			IsActive:   true,
			SortOrder:  80,
		},
		{
			ID:         "rose_heart_petal",
			Name:       "Heart-Petal Rose",
			GifURL:     "https://media.giphy.com/media/l41YvpiA9uMWw5AMU/giphy.gif",
			IconKey:    "rose_heart",
			Tier:       "premium_rare",
			PriceCoins: 3,
			IsLimited:  false,
			IsActive:   true,
			SortOrder:  90,
		},
		{
			ID:         "rose_neon_glow",
			Name:       "Neon Rose",
			GifURL:     "https://media.giphy.com/media/l0Ex7d6Q5V3sz9N16/giphy.gif",
			IconKey:    "rose_neon",
			Tier:       "premium_rare",
			PriceCoins: 3,
			IsLimited:  false,
			IsActive:   true,
			SortOrder:  95,
		},
		{
			ID:         "rose_rain",
			Name:       "Rose Rain",
			GifURL:     "https://media.giphy.com/media/l41YB9N3dM2P8xTzG/giphy.gif",
			IconKey:    "rose_rain",
			Tier:       "premium_epic",
			PriceCoins: 5,
			IsLimited:  false,
			IsActive:   true,
			SortOrder:  100,
		},
		{
			ID:         "rose_burning_flame",
			Name:       "Burning Rose",
			GifURL:     "https://media.giphy.com/media/3o6Zt481isNVuQI1l6/giphy.gif",
			IconKey:    "rose_burning",
			Tier:       "premium_epic",
			PriceCoins: 5,
			IsLimited:  false,
			IsActive:   true,
			SortOrder:  105,
		},
		{
			ID:         "rose_golden",
			Name:       "Golden Rose",
			GifURL:     "https://media.giphy.com/media/l0HlBO7eyXzSZkJri/giphy.gif",
			IconKey:    "rose_gold",
			Tier:       "premium_legendary",
			PriceCoins: 8,
			IsLimited:  true,
			IsActive:   true,
			SortOrder:  110,
		},
		{
			ID:         "rose_crystal",
			Name:       "Crystal Rose",
			GifURL:     "https://media.giphy.com/media/3o7aD2saalBwwftBIY/giphy.gif",
			IconKey:    "rose_crystal",
			Tier:       "premium_legendary",
			PriceCoins: 10,
			IsLimited:  true,
			IsActive:   true,
			SortOrder:  120,
		},
		{
			ID:         "rose_bouquet_12",
			Name:       "Rose Bouquet (12)",
			GifURL:     "https://media.giphy.com/media/xTiTnMhJTwNHChdTZS/giphy.gif",
			IconKey:    "rose_bouquet",
			Tier:       "premium_legendary",
			PriceCoins: 8,
			IsLimited:  true,
			IsActive:   true,
			SortOrder:  125,
		},
		{
			ID:         "rose_bouquet_24",
			Name:       "Rose Bouquet (24)",
			GifURL:     "https://media.giphy.com/media/26xBydxfjxsRQggh2/giphy.gif",
			IconKey:    "rose_bouquet",
			Tier:       "premium_legendary",
			PriceCoins: 10,
			IsLimited:  true,
			IsActive:   true,
			SortOrder:  130,
		},
		{
			ID:         "rose_seasonal_weekly",
			Name:       "Seasonal Limited Rose",
			GifURL:     "https://media.giphy.com/media/l0MYAs5E2oIDCq9So/giphy.gif",
			IconKey:    "rose_seasonal",
			Tier:       "seasonal_limited",
			PriceCoins: 6,
			IsLimited:  true,
			IsActive:   true,
			SortOrder:  140,
		},
	}

	out := make(map[string]roseGiftCatalogItem, len(items))
	for _, item := range items {
		out[item.ID] = item
	}
	return out
}

func (m *memoryStore) listRoseGiftCatalog() []roseGiftCatalogItem {
	if m.giftsRepo != nil {
		items, err := m.giftsRepo.listCatalog(context.Background())
		if err == nil {
			return items
		}
		if m.durableEngagementRequired() || !isGiftRepoPersistenceUnavailable(err) {
			return []roseGiftCatalogItem{}
		}
	}

	m.mu.RLock()
	defer m.mu.RUnlock()

	out := make([]roseGiftCatalogItem, 0, len(m.giftCatalog))
	for _, item := range m.giftCatalog {
		if !item.IsActive {
			continue
		}
		out = append(out, item)
	}
	sort.Slice(out, func(i, j int) bool {
		if out[i].SortOrder == out[j].SortOrder {
			return out[i].ID < out[j].ID
		}
		return out[i].SortOrder < out[j].SortOrder
	})
	return out
}

func (m *memoryStore) getWalletCoins(userID string) userWalletView {
	trimmedUserID := strings.TrimSpace(userID)
	if trimmedUserID == "" {
		return userWalletView{}
	}
	if m.giftsRepo != nil {
		wallet, err := m.giftsRepo.getWallet(context.Background(), trimmedUserID)
		if err == nil {
			return wallet
		}
		if m.durableEngagementRequired() || !isGiftRepoPersistenceUnavailable(err) {
			return userWalletView{}
		}
	}

	m.mu.Lock()
	defer m.mu.Unlock()
	balance, ok := m.walletCoinsByUser[trimmedUserID]
	if !ok {
		balance = 12
		m.walletCoinsByUser[trimmedUserID] = balance
	}
	return userWalletView{
		UserID:      trimmedUserID,
		CoinBalance: balance,
		UpdatedAt:   time.Now().UTC().Format(time.RFC3339),
	}
}

func (m *memoryStore) topUpWalletCoins(userID string, amount int, _ string) (userWalletView, error) {
	trimmedUserID := strings.TrimSpace(userID)
	if trimmedUserID == "" {
		return userWalletView{}, errors.New("user_id is required")
	}
	if amount <= 0 {
		return userWalletView{}, errors.New("amount must be greater than 0")
	}

	if m.giftsRepo != nil {
		wallet, _, err := m.giftsRepo.creditWalletCoins(context.Background(), walletCoinCreditRequest{
			UserID:         trimmedUserID,
			PackageID:      "manual_top_up",
			Source:         "admin_topup",
			Provider:       "internal",
			Coins:          amount,
			AmountMinor:    0,
			Currency:       "coins",
			PurchaseRef:    "",
			Metadata:       map[string]any{},
			Now:            time.Now().UTC(),
			IdempotencyKey: "",
		})
		if err == nil {
			return wallet, nil
		}
		if m.durableEngagementRequired() || !isGiftRepoPersistenceUnavailable(err) {
			return userWalletView{}, err
		}
	}

	m.mu.Lock()
	defer m.mu.Unlock()
	balance := m.walletCoinsByUser[trimmedUserID]
	balance += amount
	m.walletCoinsByUser[trimmedUserID] = balance
	return userWalletView{
		UserID:      trimmedUserID,
		CoinBalance: balance,
		UpdatedAt:   time.Now().UTC().Format(time.RFC3339),
	}, nil
}

func (m *memoryStore) buyWalletCoins(
	userID,
	packageID,
	provider,
	currency,
	purchaseRef,
	idempotencyKey string,
	coins,
	amountMinor int,
	now time.Time,
) (userWalletView, walletCoinPurchaseView, error) {
	trimmedUserID := strings.TrimSpace(userID)
	trimmedPackageID := strings.TrimSpace(packageID)
	trimmedProvider := strings.TrimSpace(provider)
	trimmedCurrency := strings.TrimSpace(currency)
	trimmedPurchaseRef := strings.TrimSpace(purchaseRef)
	trimmedIdempotencyKey := strings.TrimSpace(idempotencyKey)

	if trimmedUserID == "" {
		return userWalletView{}, walletCoinPurchaseView{}, errors.New("user_id is required")
	}
	if trimmedPackageID == "" {
		return userWalletView{}, walletCoinPurchaseView{}, errors.New("package_id is required")
	}
	if trimmedProvider == "" {
		trimmedProvider = "internal"
	}
	if trimmedCurrency == "" {
		trimmedCurrency = "coins"
	}
	if coins <= 0 {
		return userWalletView{}, walletCoinPurchaseView{}, errors.New("coins must be greater than 0")
	}
	if amountMinor < 0 {
		return userWalletView{}, walletCoinPurchaseView{}, errors.New("amount_minor cannot be negative")
	}

	if m.giftsRepo != nil {
		wallet, purchase, err := m.giftsRepo.creditWalletCoins(context.Background(), walletCoinCreditRequest{
			UserID:         trimmedUserID,
			PackageID:      trimmedPackageID,
			Source:         "buy",
			Provider:       trimmedProvider,
			Coins:          coins,
			AmountMinor:    amountMinor,
			Currency:       trimmedCurrency,
			PurchaseRef:    trimmedPurchaseRef,
			IdempotencyKey: trimmedIdempotencyKey,
			Metadata:       map[string]any{},
			Now:            now,
		})
		if err == nil {
			return wallet, purchase, nil
		}
		if m.durableEngagementRequired() || !isGiftRepoPersistenceUnavailable(err) {
			return userWalletView{}, walletCoinPurchaseView{}, err
		}
	}

	wallet, err := m.topUpWalletCoins(trimmedUserID, coins, "coin_buy_fallback")
	if err != nil {
		return userWalletView{}, walletCoinPurchaseView{}, err
	}

	return wallet, walletCoinPurchaseView{
		ID:                 fmt.Sprintf("wallet-purchase-%d", time.Now().UTC().UnixNano()),
		UserID:             trimmedUserID,
		PackageID:          trimmedPackageID,
		Source:             "buy",
		Provider:           trimmedProvider,
		PurchaseRef:        trimmedPurchaseRef,
		IdempotencyKey:     trimmedIdempotencyKey,
		Coins:              coins,
		AmountMinor:        amountMinor,
		Currency:           trimmedCurrency,
		WalletBalanceAfter: wallet.CoinBalance,
		Metadata:           map[string]any{},
		CreatedAt:          now.UTC().Format(time.RFC3339),
	}, nil
}

func (m *memoryStore) sendRoseGift(
	matchID,
	senderUserID,
	receiverUserID,
	giftID string,
	idempotencyKey string,
	now time.Time,
) (roseGiftSendView, error) {
	trimmedMatchID := strings.TrimSpace(matchID)
	trimmedSenderID := strings.TrimSpace(senderUserID)
	trimmedReceiverID := strings.TrimSpace(receiverUserID)
	trimmedGiftID := strings.TrimSpace(giftID)
	trimmedIdempotencyKey := strings.TrimSpace(idempotencyKey)
	if trimmedMatchID == "" || trimmedSenderID == "" || trimmedReceiverID == "" || trimmedGiftID == "" {
		return roseGiftSendView{}, errors.New("match_id, sender_user_id, receiver_user_id, and gift_id are required")
	}
	if trimmedSenderID == trimmedReceiverID {
		return roseGiftSendView{}, errors.New("sender and receiver cannot be the same")
	}

	if m.giftsRepo != nil {
		view, err := m.giftsRepo.sendGift(
			context.Background(),
			trimmedMatchID,
			trimmedSenderID,
			trimmedReceiverID,
			trimmedGiftID,
			trimmedIdempotencyKey,
			now,
		)
		if err == nil {
			return view, nil
		}
		if m.durableEngagementRequired() || !isGiftRepoPersistenceUnavailable(err) {
			return roseGiftSendView{}, err
		}
	}

	m.mu.Lock()
	defer m.mu.Unlock()

	if trimmedIdempotencyKey != "" {
		if existing, ok := m.giftSendByIdempotency[memoryGiftIdempotencyKey(trimmedMatchID, trimmedSenderID, trimmedIdempotencyKey)]; ok {
			return existing, nil
		}
	}

	gift, exists := m.giftCatalog[trimmedGiftID]
	if !exists || !gift.IsActive {
		return roseGiftSendView{}, errors.New("gift not found")
	}

	balance := m.walletCoinsByUser[trimmedSenderID]
	if balance == 0 {
		balance = 12
	}
	if gift.PriceCoins > 0 && balance < gift.PriceCoins {
		return roseGiftSendView{}, errors.New("insufficient wallet coins")
	}

	balance -= gift.PriceCoins
	if balance < 0 {
		balance = 0
	}
	m.walletCoinsByUser[trimmedSenderID] = balance

	m.activitySeq++
	view := roseGiftSendView{
		ID:             fmt.Sprintf("rose-gift-%d", m.activitySeq),
		MatchID:        trimmedMatchID,
		SenderUserID:   trimmedSenderID,
		ReceiverUserID: trimmedReceiverID,
		GiftID:         gift.ID,
		GiftName:       gift.Name,
		GifURL:         gift.GifURL,
		IconKey:        gift.IconKey,
		PriceCoins:     gift.PriceCoins,
		CreatedAt:      now.UTC().Format(time.RFC3339),
		RemainingCoins: balance,
		MessageID:      fmt.Sprintf("rose-gift-msg-%d", m.activitySeq),
	}

	history := m.giftSendEventsByMatch[trimmedMatchID]
	history = append([]roseGiftSendView{view}, history...)
	if len(history) > 200 {
		history = history[:200]
	}
	m.giftSendEventsByMatch[trimmedMatchID] = history
	if trimmedIdempotencyKey != "" {
		m.giftSendByIdempotency[memoryGiftIdempotencyKey(trimmedMatchID, trimmedSenderID, trimmedIdempotencyKey)] = view
	}
	return view, nil
}

func memoryGiftIdempotencyKey(matchID, senderUserID, idempotencyKey string) string {
	return strings.Join([]string{
		strings.TrimSpace(matchID),
		strings.TrimSpace(senderUserID),
		strings.TrimSpace(idempotencyKey),
	}, "|")
}

func encodeRoseGiftChatMessage(gift roseGiftSendView) string {
	safeName := strings.ReplaceAll(strings.TrimSpace(gift.GiftName), "|", "/")
	safeIconKey := strings.ReplaceAll(strings.TrimSpace(gift.IconKey), "|", "")
	if safeIconKey == "" {
		safeIconKey = defaultRoseGiftIconKey(gift.GiftID, gift.GiftName)
	}
	return fmt.Sprintf(
		"[gift:id=%s|icon=%s|name=%s|price=%d]",
		gift.GiftID,
		safeIconKey,
		safeName,
		gift.PriceCoins,
	)
}

func defaultRoseGiftIconKey(giftID, giftName string) string {
	key := strings.ToLower(strings.TrimSpace(giftID) + "|" + strings.TrimSpace(giftName))
	switch {
	case strings.Contains(key, "gold"):
		return "rose_gold"
	case strings.Contains(key, "crystal"):
		return "rose_crystal"
	case strings.Contains(key, "black"):
		return "rose_black"
	case strings.Contains(key, "blue"):
		return "rose_blue"
	case strings.Contains(key, "white"):
		return "rose_white"
	case strings.Contains(key, "yellow"):
		return "rose_yellow"
	case strings.Contains(key, "pink"):
		return "rose_pink"
	case strings.Contains(key, "lavender"):
		return "rose_lavender"
	case strings.Contains(key, "sparkle"):
		return "rose_sparkle"
	case strings.Contains(key, "heart"):
		return "rose_heart"
	case strings.Contains(key, "rain"):
		return "rose_rain"
	default:
		return "rose_red"
	}
}
