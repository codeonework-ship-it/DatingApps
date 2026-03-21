package mobile

import (
	"context"
	"errors"
	"net/url"
	"strconv"
	"strings"
	"time"

	"github.com/verified-dating/backend/internal/platform/config"
	"github.com/verified-dating/backend/internal/platform/supabase"
)

type roseGiftRepositoryDB interface {
	SelectRead(ctx context.Context, schema, table string, params url.Values) ([]map[string]any, error)
	Insert(ctx context.Context, schema, table string, payload any) ([]map[string]any, error)
	Update(ctx context.Context, schema, table string, payload any, filters url.Values) ([]map[string]any, error)
	Delete(ctx context.Context, schema, table string, filters url.Values) ([]map[string]any, error)
}

type roseGiftRepository struct {
	cfg config.Config
	db  roseGiftRepositoryDB
}

type giftSpendActivityRecord struct {
	MatchID            string
	SenderUserID       string
	ReceiverUserID     string
	GiftID             string
	Action             string
	Status             string
	PriceCoins         int
	WalletBalanceAfter *int
	IdempotencyKey     string
	ErrorCode          string
	ErrorMessage       string
	Details            map[string]any
	CreatedAt          time.Time
}

type walletCoinCreditRequest struct {
	UserID         string
	PackageID      string
	Source         string
	Provider       string
	PurchaseRef    string
	IdempotencyKey string
	Coins          int
	AmountMinor    int
	Currency       string
	Metadata       map[string]any
	Now            time.Time
}

func newRoseGiftRepository(cfg config.Config) *roseGiftRepository {
	apiKey := strings.TrimSpace(cfg.SupabaseServiceRole)
	if apiKey == "" {
		apiKey = strings.TrimSpace(cfg.SupabaseAnonKey)
	}
	if strings.TrimSpace(cfg.SupabaseURL) == "" || apiKey == "" {
		return nil
	}
	client := supabase.NewClient(
		cfg.SupabaseURL,
		cfg.SupabaseAnonKey,
		cfg.SupabaseServiceRole,
		time.Duration(cfg.SupabaseHTTPTimeoutSec)*time.Second,
	)
	client.SetReadBaseURL(cfg.SupabaseReadReplicaURL)
	return &roseGiftRepository{cfg: cfg, db: client}
}

func (r *roseGiftRepository) recordGiftSpendActivity(ctx context.Context, record giftSpendActivityRecord) error {
	if strings.TrimSpace(record.MatchID) == "" {
		return errors.New("match_id is required")
	}
	if strings.TrimSpace(record.SenderUserID) == "" {
		return errors.New("sender_user_id is required")
	}
	if strings.TrimSpace(record.ReceiverUserID) == "" {
		return errors.New("receiver_user_id is required")
	}
	if strings.TrimSpace(record.Action) == "" {
		return errors.New("action is required")
	}
	if strings.TrimSpace(record.Status) == "" {
		return errors.New("status is required")
	}
	if strings.TrimSpace(r.cfg.GiftSpendActivitiesTable) == "" {
		return errors.New("gift spend activities table is not configured")
	}

	createdAt := record.CreatedAt.UTC()
	if createdAt.IsZero() {
		createdAt = time.Now().UTC()
	}

	details := record.Details
	if details == nil {
		details = map[string]any{}
	}

	payload := map[string]any{
		"id":               newGroupUUID(),
		"match_id":         strings.TrimSpace(record.MatchID),
		"sender_user_id":   strings.TrimSpace(record.SenderUserID),
		"receiver_user_id": strings.TrimSpace(record.ReceiverUserID),
		"gift_id":          strings.TrimSpace(record.GiftID),
		"action":           strings.TrimSpace(record.Action),
		"status":           strings.TrimSpace(record.Status),
		"price_coins":      clampMinInt(record.PriceCoins, 0),
		"idempotency_key":  strings.TrimSpace(record.IdempotencyKey),
		"error_code":       strings.TrimSpace(record.ErrorCode),
		"error_message":    strings.TrimSpace(record.ErrorMessage),
		"details":          details,
		"created_at":       createdAt.Format(time.RFC3339),
	}
	if record.WalletBalanceAfter != nil {
		payload["wallet_balance_after"] = clampMinInt(*record.WalletBalanceAfter, 0)
	}

	rows, err := r.db.Insert(ctx, r.cfg.MatchingSchema, r.cfg.GiftSpendActivitiesTable, []map[string]any{payload})
	if err != nil {
		return err
	}
	if len(rows) == 0 {
		return errors.New("gift spend activity persistence returned empty result")
	}
	return nil
}

func clampMinInt(value, min int) int {
	if value < min {
		return min
	}
	return value
}

func (r *roseGiftRepository) listCatalog(ctx context.Context) ([]roseGiftCatalogItem, error) {
	params := url.Values{}
	params.Set("is_active", "eq.true")
	params.Set("order", "sort_order.asc")
	rows, err := r.selectGiftCatalogRows(ctx, params)
	if err != nil {
		return nil, err
	}
	out := make([]roseGiftCatalogItem, 0, len(rows))
	for _, row := range rows {
		item := mapRoseGiftCatalogRow(row)
		if item.ID == "" {
			continue
		}
		out = append(out, item)
	}
	return out, nil
}

func (r *roseGiftRepository) getCatalogByID(ctx context.Context, giftID string) (roseGiftCatalogItem, bool, error) {
	trimmedGiftID := strings.TrimSpace(giftID)
	if trimmedGiftID == "" {
		return roseGiftCatalogItem{}, false, errors.New("gift_id is required")
	}

	params := url.Values{}
	params.Set("id", "eq."+trimmedGiftID)
	params.Set("is_active", "eq.true")
	params.Set("limit", "1")
	rows, err := r.selectGiftCatalogRows(ctx, params)
	if err != nil {
		return roseGiftCatalogItem{}, false, err
	}
	if len(rows) == 0 {
		return roseGiftCatalogItem{}, false, nil
	}
	item := mapRoseGiftCatalogRow(rows[0])
	if item.ID == "" {
		return roseGiftCatalogItem{}, false, nil
	}
	return item, true, nil
}

func (r *roseGiftRepository) getWallet(ctx context.Context, userID string) (userWalletView, error) {
	trimmedUserID := strings.TrimSpace(userID)
	if trimmedUserID == "" {
		return userWalletView{}, errors.New("user_id is required")
	}

	params := url.Values{}
	params.Set("user_id", "eq."+trimmedUserID)
	params.Set("limit", "1")
	params.Set("select", "user_id,coin_balance,updated_at")
	rows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, r.cfg.UserWalletsTable, params)
	if err != nil {
		return userWalletView{}, err
	}
	if len(rows) == 0 {
		inserted, insertErr := r.db.Insert(ctx, r.cfg.MatchingSchema, r.cfg.UserWalletsTable, []map[string]any{{
			"user_id":      trimmedUserID,
			"coin_balance": 12,
			"updated_at":   time.Now().UTC().Format(time.RFC3339),
		}})
		if insertErr != nil {
			return userWalletView{}, insertErr
		}
		if len(inserted) == 0 {
			return userWalletView{}, errors.New("wallet persistence returned empty result")
		}
		return mapWalletRow(inserted[0]), nil
	}
	return mapWalletRow(rows[0]), nil
}

func (r *roseGiftRepository) topUpWallet(ctx context.Context, userID string, amount int) (userWalletView, error) {
	wallet, _, err := r.creditWalletCoins(ctx, walletCoinCreditRequest{
		UserID:      userID,
		PackageID:   "manual_top_up",
		Source:      "admin_topup",
		Provider:    "internal",
		Coins:       amount,
		AmountMinor: 0,
		Currency:    "coins",
		Metadata:    map[string]any{},
		Now:         time.Now().UTC(),
	})
	if err != nil {
		return userWalletView{}, err
	}
	return wallet, nil
}

func (r *roseGiftRepository) creditWalletCoins(
	ctx context.Context,
	req walletCoinCreditRequest,
) (userWalletView, walletCoinPurchaseView, error) {
	trimmedUserID := strings.TrimSpace(req.UserID)
	trimmedPackageID := strings.TrimSpace(req.PackageID)
	trimmedSource := strings.TrimSpace(req.Source)
	trimmedProvider := strings.TrimSpace(req.Provider)
	trimmedPurchaseRef := strings.TrimSpace(req.PurchaseRef)
	trimmedIdempotencyKey := strings.TrimSpace(req.IdempotencyKey)
	trimmedCurrency := strings.TrimSpace(req.Currency)

	if trimmedUserID == "" {
		return userWalletView{}, walletCoinPurchaseView{}, errors.New("user_id is required")
	}
	if trimmedPackageID == "" {
		return userWalletView{}, walletCoinPurchaseView{}, errors.New("package_id is required")
	}
	if trimmedSource == "" {
		trimmedSource = "buy"
	}
	if trimmedProvider == "" {
		trimmedProvider = "internal"
	}
	if trimmedCurrency == "" {
		trimmedCurrency = "coins"
	}
	if req.Coins <= 0 {
		return userWalletView{}, walletCoinPurchaseView{}, errors.New("coins must be greater than 0")
	}
	if req.AmountMinor < 0 {
		return userWalletView{}, walletCoinPurchaseView{}, errors.New("amount_minor cannot be negative")
	}
	if strings.TrimSpace(r.cfg.WalletCoinPurchasesTable) == "" {
		return userWalletView{}, walletCoinPurchaseView{}, errors.New("wallet coin purchases table is not configured")
	}

	wallet, err := r.getWallet(ctx, trimmedUserID)
	if err != nil {
		return userWalletView{}, walletCoinPurchaseView{}, err
	}

	if trimmedIdempotencyKey != "" {
		existing, found, findErr := r.findWalletCoinPurchaseByIdempotency(ctx, wallet.UserID, trimmedIdempotencyKey)
		if findErr != nil {
			return userWalletView{}, walletCoinPurchaseView{}, findErr
		}
		if found {
			replayWallet, replayErr := r.getWallet(ctx, wallet.UserID)
			if replayErr != nil {
				return userWalletView{}, walletCoinPurchaseView{}, replayErr
			}
			return replayWallet, existing, nil
		}
	}

	now := req.Now.UTC()
	if now.IsZero() {
		now = time.Now().UTC()
	}

	newBalance := wallet.CoinBalance + req.Coins
	walletFilters := url.Values{}
	walletFilters.Set("user_id", "eq."+wallet.UserID)
	walletFilters.Set("coin_balance", "eq."+strconv.Itoa(wallet.CoinBalance))
	updatedWalletRows, err := r.db.Update(ctx, r.cfg.MatchingSchema, r.cfg.UserWalletsTable, map[string]any{
		"coin_balance": newBalance,
		"updated_at":   now.Format(time.RFC3339),
	}, walletFilters)
	if err != nil {
		return userWalletView{}, walletCoinPurchaseView{}, err
	}
	if len(updatedWalletRows) == 0 {
		return userWalletView{}, walletCoinPurchaseView{}, errors.New("wallet update conflict, retry credit")
	}

	metadata := req.Metadata
	if metadata == nil {
		metadata = map[string]any{}
	}

	purchasePayload := map[string]any{
		"id":                   newGroupUUID(),
		"user_id":              wallet.UserID,
		"package_id":           trimmedPackageID,
		"source":               trimmedSource,
		"provider":             trimmedProvider,
		"purchase_ref":         trimmedPurchaseRef,
		"idempotency_key":      trimmedIdempotencyKey,
		"coins":                req.Coins,
		"amount_minor":         req.AmountMinor,
		"currency":             trimmedCurrency,
		"wallet_balance_after": newBalance,
		"metadata":             metadata,
		"created_at":           now.Format(time.RFC3339),
	}

	purchaseRows, err := r.db.Insert(ctx, r.cfg.MatchingSchema, r.cfg.WalletCoinPurchasesTable, []map[string]any{purchasePayload})
	if err != nil {
		rollbackErr := r.rollbackWalletCredit(ctx, wallet.UserID, newBalance, wallet.CoinBalance, now)
		if rollbackErr != nil {
			return userWalletView{}, walletCoinPurchaseView{}, errors.New("wallet coin purchase persistence failed; wallet rollback failed: " + rollbackErr.Error())
		}
		return userWalletView{}, walletCoinPurchaseView{}, err
	}
	if len(purchaseRows) == 0 {
		rollbackErr := r.rollbackWalletCredit(ctx, wallet.UserID, newBalance, wallet.CoinBalance, now)
		if rollbackErr != nil {
			return userWalletView{}, walletCoinPurchaseView{}, errors.New("wallet coin purchase persistence returned empty result; wallet rollback failed: " + rollbackErr.Error())
		}
		return userWalletView{}, walletCoinPurchaseView{}, errors.New("wallet coin purchase persistence returned empty result")
	}

	updatedWallet := mapWalletRow(updatedWalletRows[0])
	purchase := mapWalletCoinPurchaseRow(purchaseRows[0])
	if strings.TrimSpace(purchase.ID) == "" {
		purchase = mapWalletCoinPurchaseRow(purchasePayload)
	}
	if purchase.WalletBalanceAfter == 0 && newBalance > 0 {
		purchase.WalletBalanceAfter = newBalance
	}

	return updatedWallet, purchase, nil
}

func (r *roseGiftRepository) findWalletCoinPurchaseByIdempotency(
	ctx context.Context,
	userID,
	idempotencyKey string,
) (walletCoinPurchaseView, bool, error) {
	if strings.TrimSpace(userID) == "" || strings.TrimSpace(idempotencyKey) == "" {
		return walletCoinPurchaseView{}, false, nil
	}

	params := url.Values{}
	params.Set("user_id", "eq."+strings.TrimSpace(userID))
	params.Set("idempotency_key", "eq."+strings.TrimSpace(idempotencyKey))
	params.Set("order", "created_at.desc")
	params.Set("limit", "1")
	params.Set("select", "id,user_id,package_id,source,provider,purchase_ref,idempotency_key,coins,amount_minor,currency,wallet_balance_after,metadata,created_at")

	rows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, r.cfg.WalletCoinPurchasesTable, params)
	if err != nil {
		return walletCoinPurchaseView{}, false, err
	}
	if len(rows) == 0 {
		return walletCoinPurchaseView{}, false, nil
	}

	purchase := mapWalletCoinPurchaseRow(rows[0])
	if strings.TrimSpace(purchase.ID) == "" {
		return walletCoinPurchaseView{}, false, nil
	}
	return purchase, true, nil
}

func (r *roseGiftRepository) rollbackWalletCredit(
	ctx context.Context,
	userID string,
	currentBalance,
	originalBalance int,
	now time.Time,
) error {
	walletFilters := url.Values{}
	walletFilters.Set("user_id", "eq."+strings.TrimSpace(userID))
	walletFilters.Set("coin_balance", "eq."+strconv.Itoa(currentBalance))
	rows, err := r.db.Update(ctx, r.cfg.MatchingSchema, r.cfg.UserWalletsTable, map[string]any{
		"coin_balance": originalBalance,
		"updated_at":   now.UTC().Format(time.RFC3339),
	}, walletFilters)
	if err != nil {
		return err
	}
	if len(rows) == 0 {
		return errors.New("wallet rollback conflict")
	}
	return nil
}

func (r *roseGiftRepository) sendGift(
	ctx context.Context,
	matchID,
	senderUserID,
	receiverUserID,
	giftID string,
	idempotencyKey string,
	now time.Time,
) (roseGiftSendView, error) {
	gift, found, err := r.getCatalogByID(ctx, giftID)
	if err != nil {
		return roseGiftSendView{}, err
	}
	if !found {
		return roseGiftSendView{}, errors.New("gift not found")
	}
	wallet, err := r.getWallet(ctx, senderUserID)
	if err != nil {
		return roseGiftSendView{}, err
	}
	trimmedIdempotencyKey := strings.TrimSpace(idempotencyKey)
	if trimmedIdempotencyKey != "" {
		existing, foundExisting, findErr := r.findGiftSendByIdempotency(
			ctx,
			strings.TrimSpace(matchID),
			wallet.UserID,
			trimmedIdempotencyKey,
		)
		if findErr != nil {
			return roseGiftSendView{}, findErr
		}
		if foundExisting {
			existing.RemainingCoins = wallet.CoinBalance
			return existing, nil
		}
	}
	if wallet.CoinBalance < gift.PriceCoins {
		return roseGiftSendView{}, errors.New("insufficient wallet coins")
	}

	newBalance := wallet.CoinBalance - gift.PriceCoins
	walletFilters := url.Values{}
	walletFilters.Set("user_id", "eq."+wallet.UserID)
	walletFilters.Set("coin_balance", "eq."+strconv.Itoa(wallet.CoinBalance))
	walletRows, err := r.db.Update(ctx, r.cfg.MatchingSchema, r.cfg.UserWalletsTable, map[string]any{
		"coin_balance": newBalance,
		"updated_at":   now.UTC().Format(time.RFC3339),
	}, walletFilters)
	if err != nil {
		return roseGiftSendView{}, err
	}
	if len(walletRows) == 0 {
		return roseGiftSendView{}, errors.New("wallet update conflict, retry send")
	}

	sendID := newGroupUUID()
	sendRows, err := r.insertGiftSendRows(ctx, map[string]any{
		"id":               sendID,
		"match_id":         strings.TrimSpace(matchID),
		"sender_user_id":   strings.TrimSpace(senderUserID),
		"receiver_user_id": strings.TrimSpace(receiverUserID),
		"gift_id":          gift.ID,
		"gift_name":        gift.Name,
		"gif_url":          gift.GifURL,
		"icon_key":         gift.IconKey,
		"price_coins":      gift.PriceCoins,
		"idempotency_key":  trimmedIdempotencyKey,
		"created_at":       now.UTC().Format(time.RFC3339),
	})
	if err != nil {
		rollbackErr := r.rollbackGiftSendMutation(ctx, sendID, wallet.UserID, newBalance, wallet.CoinBalance, now)
		if rollbackErr != nil {
			return roseGiftSendView{}, errors.New("gift send persistence failed; wallet rollback failed: " + rollbackErr.Error())
		}
		return roseGiftSendView{}, errors.New("gift send persistence failed: " + err.Error())
	}
	if len(sendRows) == 0 {
		rollbackErr := r.rollbackGiftSendMutation(ctx, sendID, wallet.UserID, newBalance, wallet.CoinBalance, now)
		if rollbackErr != nil {
			return roseGiftSendView{}, errors.New("gift send persistence returned empty result; wallet rollback failed: " + rollbackErr.Error())
		}
		return roseGiftSendView{}, errors.New("gift send persistence returned empty result")
	}

	chatRows, err := r.db.Insert(ctx, r.cfg.MatchingSchema, r.cfg.MessagesTable, []map[string]any{{
		"matchId":  strings.TrimSpace(matchID),
		"senderId": strings.TrimSpace(senderUserID),
		"text": encodeRoseGiftChatMessage(roseGiftSendView{
			GiftID:     gift.ID,
			GiftName:   gift.Name,
			GifURL:     gift.GifURL,
			IconKey:    gift.IconKey,
			PriceCoins: gift.PriceCoins,
		}),
	}})
	if err != nil {
		rollbackErr := r.rollbackGiftSendMutation(ctx, sendID, wallet.UserID, newBalance, wallet.CoinBalance, now)
		if rollbackErr != nil {
			return roseGiftSendView{}, errors.New("chat message persistence failed; rollback failed: " + rollbackErr.Error())
		}
		return roseGiftSendView{}, errors.New("chat message persistence failed and wallet/send state was rolled back")
	}

	view := mapRoseGiftSendRow(sendRows[0])
	if strings.TrimSpace(view.ID) == "" {
		view.ID = sendID
	}
	if strings.TrimSpace(view.GiftID) == "" {
		view.GiftID = gift.ID
	}
	if strings.TrimSpace(view.GiftName) == "" {
		view.GiftName = gift.Name
	}
	if strings.TrimSpace(view.GifURL) == "" {
		view.GifURL = gift.GifURL
	}
	if strings.TrimSpace(toString(sendRows[0]["icon_key"])) == "" || strings.TrimSpace(view.IconKey) == "" {
		view.IconKey = strings.TrimSpace(gift.IconKey)
	}
	view.RemainingCoins = newBalance
	if len(chatRows) > 0 {
		view.MessageID = strings.TrimSpace(toString(chatRows[0]["id"]))
	}
	return view, nil
}

func (r *roseGiftRepository) findGiftSendByIdempotency(
	ctx context.Context,
	matchID,
	senderUserID,
	idempotencyKey string,
) (roseGiftSendView, bool, error) {
	if strings.TrimSpace(matchID) == "" || strings.TrimSpace(senderUserID) == "" || strings.TrimSpace(idempotencyKey) == "" {
		return roseGiftSendView{}, false, nil
	}

	params := url.Values{}
	params.Set("match_id", "eq."+strings.TrimSpace(matchID))
	params.Set("sender_user_id", "eq."+strings.TrimSpace(senderUserID))
	params.Set("idempotency_key", "eq."+strings.TrimSpace(idempotencyKey))
	params.Set("order", "created_at.desc")
	params.Set("limit", "1")
	rows, err := r.selectGiftSendRows(ctx, params)
	if err != nil {
		return roseGiftSendView{}, false, err
	}
	if len(rows) == 0 {
		return roseGiftSendView{}, false, nil
	}

	view := mapRoseGiftSendRow(rows[0])
	if strings.TrimSpace(view.ID) == "" {
		return roseGiftSendView{}, false, nil
	}
	return view, true, nil
}

func (r *roseGiftRepository) selectGiftSendRows(ctx context.Context, base url.Values) ([]map[string]any, error) {
	withOptional := cloneValues(base)
	withOptional.Set("select", "id,match_id,sender_user_id,receiver_user_id,gift_id,gift_name,gif_url,icon_key,price_coins,created_at,idempotency_key")
	rows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, r.cfg.MatchGiftSendsTable, withOptional)
	if err == nil {
		return rows, nil
	}
	if !isMissingColumnErr(err, "icon_key") && !isMissingColumnErr(err, "idempotency_key") {
		return nil, err
	}

	withoutOptional := cloneValues(base)
	withoutOptional.Set("select", "id,match_id,sender_user_id,receiver_user_id,gift_id,gift_name,gif_url,price_coins,created_at")
	return r.db.SelectRead(ctx, r.cfg.MatchingSchema, r.cfg.MatchGiftSendsTable, withoutOptional)
}

func (r *roseGiftRepository) insertGiftSendRows(ctx context.Context, payload map[string]any) ([]map[string]any, error) {
	rows, err := r.db.Insert(ctx, r.cfg.MatchingSchema, r.cfg.MatchGiftSendsTable, []map[string]any{payload})
	if err == nil {
		return rows, nil
	}
	if !isMissingColumnErr(err, "icon_key") && !isMissingColumnErr(err, "idempotency_key") {
		return nil, err
	}

	legacyPayload := map[string]any{}
	for key, value := range payload {
		if key == "icon_key" || key == "idempotency_key" {
			continue
		}
		legacyPayload[key] = value
	}
	return r.db.Insert(ctx, r.cfg.MatchingSchema, r.cfg.MatchGiftSendsTable, []map[string]any{legacyPayload})
}

func (r *roseGiftRepository) rollbackGiftSendMutation(
	ctx context.Context,
	sendID,
	walletUserID string,
	currentBalance,
	originalBalance int,
	now time.Time,
) error {
	var rollbackIssues []string

	if trimmedSendID := strings.TrimSpace(sendID); trimmedSendID != "" {
		sendFilters := url.Values{}
		sendFilters.Set("id", "eq."+trimmedSendID)
		if _, err := r.db.Delete(ctx, r.cfg.MatchingSchema, r.cfg.MatchGiftSendsTable, sendFilters); err != nil {
			rollbackIssues = append(rollbackIssues, "delete gift send rollback failed: "+err.Error())
		}
	}

	walletFilters := url.Values{}
	walletFilters.Set("user_id", "eq."+strings.TrimSpace(walletUserID))
	walletFilters.Set("coin_balance", "eq."+strconv.Itoa(currentBalance))
	rows, err := r.db.Update(ctx, r.cfg.MatchingSchema, r.cfg.UserWalletsTable, map[string]any{
		"coin_balance": originalBalance,
		"updated_at":   now.UTC().Format(time.RFC3339),
	}, walletFilters)
	if err != nil {
		rollbackIssues = append(rollbackIssues, "wallet rollback failed: "+err.Error())
	} else if len(rows) == 0 {
		rollbackIssues = append(rollbackIssues, "wallet rollback conflict")
	}

	if len(rollbackIssues) == 0 {
		return nil
	}
	return errors.New(strings.Join(rollbackIssues, "; "))
}

func (r *roseGiftRepository) selectGiftCatalogRows(ctx context.Context, base url.Values) ([]map[string]any, error) {
	withIcon := cloneValues(base)
	withIcon.Set("select", "id,name,gif_url,icon_key,tier,price_coins,is_limited,is_active,sort_order")
	rows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, r.cfg.GiftCatalogTable, withIcon)
	if err == nil {
		return rows, nil
	}
	if !isMissingColumnErr(err, "icon_key") {
		return nil, err
	}

	withoutIcon := cloneValues(base)
	withoutIcon.Set("select", "id,name,gif_url,tier,price_coins,is_limited,is_active,sort_order")
	return r.db.SelectRead(ctx, r.cfg.MatchingSchema, r.cfg.GiftCatalogTable, withoutIcon)
}

func cloneValues(input url.Values) url.Values {
	cloned := url.Values{}
	for key, values := range input {
		copied := make([]string, len(values))
		copy(copied, values)
		cloned[key] = copied
	}
	return cloned
}

func isMissingColumnErr(err error, column string) bool {
	if err == nil {
		return false
	}
	msg := strings.ToLower(err.Error())
	return strings.Contains(msg, strings.ToLower(column)) &&
		(strings.Contains(msg, "does not exist") ||
			strings.Contains(msg, "unknown column") ||
			strings.Contains(msg, "undefined column") ||
			strings.Contains(msg, "42703"))
}

func mapRoseGiftCatalogRow(row map[string]any) roseGiftCatalogItem {
	giftID := strings.TrimSpace(toString(row["id"]))
	giftName := strings.TrimSpace(toString(row["name"]))
	iconKey := strings.TrimSpace(toString(row["icon_key"]))
	if iconKey == "" {
		iconKey = defaultRoseGiftIconKey(giftID, giftName)
	}

	return roseGiftCatalogItem{
		ID:         giftID,
		Name:       giftName,
		GifURL:     strings.TrimSpace(toString(row["gif_url"])),
		IconKey:    iconKey,
		Tier:       strings.TrimSpace(toString(row["tier"])),
		PriceCoins: toIntOrZero(row["price_coins"]),
		IsLimited:  row["is_limited"] == true,
		IsActive:   row["is_active"] == true,
		SortOrder:  toIntOrZero(row["sort_order"]),
	}
}

func mapWalletRow(row map[string]any) userWalletView {
	return userWalletView{
		UserID:      strings.TrimSpace(toString(row["user_id"])),
		CoinBalance: toIntOrZero(row["coin_balance"]),
		UpdatedAt:   strings.TrimSpace(toString(row["updated_at"])),
	}
}

func mapRoseGiftSendRow(row map[string]any) roseGiftSendView {
	giftID := strings.TrimSpace(toString(row["gift_id"]))
	giftName := strings.TrimSpace(toString(row["gift_name"]))
	iconKey := strings.TrimSpace(toString(row["icon_key"]))
	if iconKey == "" {
		iconKey = defaultRoseGiftIconKey(giftID, giftName)
	}

	return roseGiftSendView{
		ID:             strings.TrimSpace(toString(row["id"])),
		MatchID:        strings.TrimSpace(toString(row["match_id"])),
		SenderUserID:   strings.TrimSpace(toString(row["sender_user_id"])),
		ReceiverUserID: strings.TrimSpace(toString(row["receiver_user_id"])),
		GiftID:         giftID,
		GiftName:       giftName,
		GifURL:         strings.TrimSpace(toString(row["gif_url"])),
		IconKey:        iconKey,
		PriceCoins:     toIntOrZero(row["price_coins"]),
		CreatedAt:      strings.TrimSpace(toString(row["created_at"])),
	}
}

func mapWalletCoinPurchaseRow(row map[string]any) walletCoinPurchaseView {
	metadata := map[string]any{}
	if details, ok := row["metadata"].(map[string]any); ok {
		metadata = details
	}

	return walletCoinPurchaseView{
		ID:                 strings.TrimSpace(toString(row["id"])),
		UserID:             strings.TrimSpace(toString(row["user_id"])),
		PackageID:          strings.TrimSpace(toString(row["package_id"])),
		Source:             strings.TrimSpace(toString(row["source"])),
		Provider:           strings.TrimSpace(toString(row["provider"])),
		PurchaseRef:        strings.TrimSpace(toString(row["purchase_ref"])),
		IdempotencyKey:     strings.TrimSpace(toString(row["idempotency_key"])),
		Coins:              toIntOrZero(row["coins"]),
		AmountMinor:        toIntOrZero(row["amount_minor"]),
		Currency:           strings.TrimSpace(toString(row["currency"])),
		WalletBalanceAfter: toIntOrZero(row["wallet_balance_after"]),
		Metadata:           metadata,
		CreatedAt:          strings.TrimSpace(toString(row["created_at"])),
	}
}

func toIntOrZero(value any) int {
	if parsed, ok := toInt(value); ok {
		return parsed
	}
	return 0
}
