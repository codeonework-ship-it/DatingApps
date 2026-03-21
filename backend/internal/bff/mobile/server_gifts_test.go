package mobile

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/verified-dating/backend/internal/platform/config"
)

func TestServer_GiftsCatalogAndWalletTopUp(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	giftsReq := httptest.NewRequest(http.MethodGet, "/v1/chat/gifts", nil)
	giftsRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(giftsRec, giftsReq)
	if giftsRec.Code != http.StatusOK {
		t.Fatalf("list gifts code=%d body=%s", giftsRec.Code, giftsRec.Body.String())
	}
	giftsPayload := decodeJSONMap(t, giftsRec.Body.Bytes())
	gifts, ok := giftsPayload["gifts"].([]any)
	if !ok || len(gifts) == 0 {
		t.Fatalf("expected non-empty gifts catalog")
	}
	firstGift := toMap(t, gifts[0])
	if got := stringValue(firstGift["icon_key"]); got == "" {
		t.Fatalf("expected icon_key in gifts catalog item")
	}

	const userID = "wallet-user-1"
	getWalletReq := httptest.NewRequest(http.MethodGet, "/v1/wallet/"+userID+"/coins", nil)
	getWalletRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(getWalletRec, getWalletReq)
	if getWalletRec.Code != http.StatusOK {
		t.Fatalf("get wallet code=%d body=%s", getWalletRec.Code, getWalletRec.Body.String())
	}
	getWalletPayload := decodeJSONMap(t, getWalletRec.Body.Bytes())
	walletBefore := toMap(t, getWalletPayload["wallet"])
	balanceBefore := int(walletBefore["coin_balance"].(float64))

	topUpReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/wallet/"+userID+"/coins/top-up",
		strings.NewReader(`{"amount":5,"reason":"test_top_up"}`),
	)
	topUpReq.Header.Set("Content-Type", "application/json")
	topUpRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(topUpRec, topUpReq)
	if topUpRec.Code != http.StatusOK {
		t.Fatalf("top up wallet code=%d body=%s", topUpRec.Code, topUpRec.Body.String())
	}
	topUpPayload := decodeJSONMap(t, topUpRec.Body.Bytes())
	walletAfter := toMap(t, topUpPayload["wallet"])
	balanceAfter := int(walletAfter["coin_balance"].(float64))
	if balanceAfter != balanceBefore+5 {
		t.Fatalf("expected top-up to increase balance by 5, before=%d after=%d", balanceBefore, balanceAfter)
	}
	audit := toMap(t, topUpPayload["audit"])
	if got := stringValue(audit["receipt_id"]); got == "" {
		t.Fatalf("expected audit receipt_id")
	}
	if got := stringValue(audit["requested_by"]); got != userID {
		t.Fatalf("expected requested_by=%q, got %q", userID, got)
	}
}

func TestServer_BuyWalletCoinsIncreasesBalanceAndReturnsPurchase(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	const userID = "wallet-buy-user-1"
	beforeReq := httptest.NewRequest(http.MethodGet, "/v1/wallet/"+userID+"/coins", nil)
	beforeRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(beforeRec, beforeReq)
	if beforeRec.Code != http.StatusOK {
		t.Fatalf("get wallet before buy code=%d body=%s", beforeRec.Code, beforeRec.Body.String())
	}
	beforePayload := decodeJSONMap(t, beforeRec.Body.Bytes())
	beforeWallet := toMap(t, beforePayload["wallet"])
	balanceBefore := int(beforeWallet["coin_balance"].(float64))

	buyReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/wallet/"+userID+"/coins/buy",
		strings.NewReader(`{"package_id":"starter_pack","coins":8,"amount_minor":199,"currency":"INR","provider":"razorpay","purchase_ref":"pay_001"}`),
	)
	buyReq.Header.Set("Content-Type", "application/json")
	buyRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(buyRec, buyReq)
	if buyRec.Code != http.StatusOK {
		t.Fatalf("buy wallet coins code=%d body=%s", buyRec.Code, buyRec.Body.String())
	}

	buyPayload := decodeJSONMap(t, buyRec.Body.Bytes())
	afterWallet := toMap(t, buyPayload["wallet"])
	balanceAfter := int(afterWallet["coin_balance"].(float64))
	if balanceAfter != balanceBefore+8 {
		t.Fatalf("expected buy to increase balance by 8, before=%d after=%d", balanceBefore, balanceAfter)
	}

	purchase := toMap(t, buyPayload["purchase"])
	if got := stringValue(purchase["id"]); got == "" {
		t.Fatalf("expected purchase.id")
	}
	if got := stringValue(purchase["package_id"]); got != "starter_pack" {
		t.Fatalf("expected package_id=starter_pack, got %q", got)
	}
	if got := int(purchase["coins"].(float64)); got != 8 {
		t.Fatalf("expected coins=8, got %d", got)
	}
}

func TestServer_BuyWalletCoinsIdempotencyReplayDoesNotDoubleCredit(t *testing.T) {
	server := newQuestWorkflowTestServerWithConfig(t, func(target *config.Config) {
		target.RequireDurableEngagementStore = false
	})
	defer server.Close()

	const userID = "wallet-buy-idem-user-1"
	body := `{"package_id":"starter_pack","coins":5,"amount_minor":99,"currency":"INR","provider":"stripe","purchase_ref":"txn-123"}`

	firstReq := httptest.NewRequest(http.MethodPost, "/v1/wallet/"+userID+"/coins/buy", strings.NewReader(body))
	firstReq.Header.Set("Content-Type", "application/json")
	firstReq.Header.Set("Idempotency-Key", "wallet-buy-idem-1")
	firstRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(firstRec, firstReq)
	if firstRec.Code != http.StatusOK {
		t.Fatalf("first buy code=%d body=%s", firstRec.Code, firstRec.Body.String())
	}

	secondReq := httptest.NewRequest(http.MethodPost, "/v1/wallet/"+userID+"/coins/buy", strings.NewReader(body))
	secondReq.Header.Set("Content-Type", "application/json")
	secondReq.Header.Set("Idempotency-Key", "wallet-buy-idem-1")
	secondRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(secondRec, secondReq)
	if secondRec.Code != http.StatusOK {
		t.Fatalf("second buy code=%d body=%s", secondRec.Code, secondRec.Body.String())
	}

	walletReq := httptest.NewRequest(http.MethodGet, "/v1/wallet/"+userID+"/coins", nil)
	walletRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(walletRec, walletReq)
	if walletRec.Code != http.StatusOK {
		t.Fatalf("wallet code=%d body=%s", walletRec.Code, walletRec.Body.String())
	}
	walletPayload := decodeJSONMap(t, walletRec.Body.Bytes())
	wallet := toMap(t, walletPayload["wallet"])
	if got := int(wallet["coin_balance"].(float64)); got != 17 {
		t.Fatalf("expected coin_balance=17 after idempotent replay, got %d", got)
	}
}

func TestServer_TopUpWalletCoins_RequiresAdminInProductionLikeEnv(t *testing.T) {
	server := newQuestWorkflowTestServerWithConfig(t, func(target *config.Config) {
		target.Environment = "production"
	})
	defer server.Close()

	req := httptest.NewRequest(
		http.MethodPost,
		"/v1/wallet/wallet-user-prod-1/coins/top-up",
		strings.NewReader(`{"amount":5,"reason":"test_top_up"}`),
	)
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, req)

	if rec.Code != http.StatusForbidden {
		t.Fatalf("expected status 403, got code=%d body=%s", rec.Code, rec.Body.String())
	}

	reqWithAdmin := httptest.NewRequest(
		http.MethodPost,
		"/v1/wallet/wallet-user-prod-1/coins/top-up",
		strings.NewReader(`{"amount":5,"reason":"test_top_up"}`),
	)
	reqWithAdmin.Header.Set("Content-Type", "application/json")
	reqWithAdmin.Header.Set("X-Admin-User", "qa-admin")
	recWithAdmin := httptest.NewRecorder()
	server.Handler().ServeHTTP(recWithAdmin, reqWithAdmin)

	if recWithAdmin.Code != http.StatusOK {
		t.Fatalf("expected status 200 with admin header, got code=%d body=%s", recWithAdmin.Code, recWithAdmin.Body.String())
	}
}

func TestServer_ListWalletCoinAudit(t *testing.T) {
	server := newQuestWorkflowTestServerWithConfig(t, func(target *config.Config) {
		target.DefaultUnlockPolicyVariant = "allow_without_template"
	})
	defer server.Close()

	const userID = "wallet-audit-user-1"
	topUpReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/wallet/"+userID+"/coins/top-up",
		strings.NewReader(`{"amount":4,"reason":"audit_test"}`),
	)
	topUpReq.Header.Set("Content-Type", "application/json")
	topUpRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(topUpRec, topUpReq)
	if topUpRec.Code != http.StatusOK {
		t.Fatalf("top-up code=%d body=%s", topUpRec.Code, topUpRec.Body.String())
	}

	sendReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/chat/match-wallet-audit-1/gifts/send",
		strings.NewReader(`{"gift_id":"rose_blue_rare","sender_user_id":"wallet-audit-user-1","receiver_user_id":"wallet-audit-user-2"}`),
	)
	sendReq.Header.Set("Content-Type", "application/json")
	sendRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(sendRec, sendReq)
	if sendRec.Code != http.StatusOK {
		t.Fatalf("send gift code=%d body=%s", sendRec.Code, sendRec.Body.String())
	}

	auditReq := httptest.NewRequest(http.MethodGet, "/v1/wallet/"+userID+"/coins/audit?limit=10", nil)
	auditRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(auditRec, auditReq)
	if auditRec.Code != http.StatusOK {
		t.Fatalf("audit code=%d body=%s", auditRec.Code, auditRec.Body.String())
	}

	payload := decodeJSONMap(t, auditRec.Body.Bytes())
	if got := stringValue(payload["user_id"]); got != userID {
		t.Fatalf("expected user_id=%q, got %q", userID, got)
	}
	auditEvents, ok := payload["audit"].([]any)
	if !ok || len(auditEvents) == 0 {
		t.Fatalf("expected non-empty audit events")
	}

	foundTopUp := false
	foundGiftSuccess := false
	for _, item := range auditEvents {
		event := toMap(t, item)
		action := stringValue(event["action"])
		if action == "wallet.topup" {
			foundTopUp = true
			details := toMap(t, event["details"])
			if got := stringValue(details["audit_receipt_id"]); got == "" {
				t.Fatalf("expected audit_receipt_id for wallet.topup")
			}
		}
		if action == "gift_send_succeeded" {
			foundGiftSuccess = true
			details := toMap(t, event["details"])
			if got := stringValue(details["gift_tier"]); got == "" {
				t.Fatalf("expected gift_tier on gift_send_succeeded")
			}
		}
	}
	if !foundTopUp {
		t.Fatalf("expected wallet.topup audit event")
	}
	if !foundGiftSuccess {
		t.Fatalf("expected gift_send_succeeded audit event")
	}
}

func TestServer_SendRoseGiftSuccess(t *testing.T) {
	server := newQuestWorkflowTestServerWithConfig(t, func(target *config.Config) {
		target.DefaultUnlockPolicyVariant = "allow_without_template"
	})
	defer server.Close()

	body := `{
		"gift_id":"rose_blue_rare",
		"sender_user_id":"gift-sender-1",
		"receiver_user_id":"gift-receiver-1"
	}`
	req := httptest.NewRequest(http.MethodPost, "/v1/chat/match-gift-1/gifts/send", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("send gift code=%d body=%s", rec.Code, rec.Body.String())
	}
	payload := decodeJSONMap(t, rec.Body.Bytes())
	giftSend := toMap(t, payload["gift_send"])
	if got := stringValue(giftSend["gift_id"]); got != "rose_blue_rare" {
		t.Fatalf("expected gift_id rose_blue_rare, got %q", got)
	}
	if got := stringValue(giftSend["icon_key"]); got == "" {
		t.Fatalf("expected icon_key in gift_send payload")
	}
	if got := int(giftSend["remaining_coins"].(float64)); got != 11 {
		t.Fatalf("expected remaining_coins=11, got=%d", got)
	}
}

func TestServer_SendRoseGiftInsufficientCoins(t *testing.T) {
	server := newQuestWorkflowTestServerWithConfig(t, func(target *config.Config) {
		target.DefaultUnlockPolicyVariant = "allow_without_template"
	})
	defer server.Close()

	body := `{
		"gift_id":"rose_crystal",
		"sender_user_id":"gift-sender-2",
		"receiver_user_id":"gift-receiver-2"
	}`

	firstReq := httptest.NewRequest(http.MethodPost, "/v1/chat/match-gift-2/gifts/send", strings.NewReader(body))
	firstReq.Header.Set("Content-Type", "application/json")
	firstRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(firstRec, firstReq)
	if firstRec.Code != http.StatusOK {
		t.Fatalf("first send gift code=%d body=%s", firstRec.Code, firstRec.Body.String())
	}

	secondReq := httptest.NewRequest(http.MethodPost, "/v1/chat/match-gift-2/gifts/send", strings.NewReader(body))
	secondReq.Header.Set("Content-Type", "application/json")
	secondRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(secondRec, secondReq)
	if secondRec.Code != http.StatusPaymentRequired {
		t.Fatalf("expected status 402, got code=%d body=%s", secondRec.Code, secondRec.Body.String())
	}
	payload := decodeJSONMap(t, secondRec.Body.Bytes())
	if got := stringValue(payload["error_code"]); got != "INSUFFICIENT_COINS" {
		t.Fatalf("expected INSUFFICIENT_COINS, got %q", got)
	}
}

func TestServer_SendRoseGiftChatLocked(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	body := `{
		"gift_id":"rose_blue_rare",
		"sender_user_id":"gift-sender-3",
		"receiver_user_id":"gift-receiver-3"
	}`
	req := httptest.NewRequest(http.MethodPost, "/v1/chat/match-locked-1/gifts/send", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, req)

	if rec.Code != http.StatusLocked {
		t.Fatalf("expected status 423, got code=%d body=%s", rec.Code, rec.Body.String())
	}
	payload := decodeJSONMap(t, rec.Body.Bytes())
	if got := stringValue(payload["error_code"]); got != "CHAT_LOCKED_REQUIREMENT_PENDING" {
		t.Fatalf("expected CHAT_LOCKED_REQUIREMENT_PENDING, got %q", got)
	}
}

func TestServer_SendRoseGiftIdempotencyReplayDoesNotDoubleDebit(t *testing.T) {
	server := newQuestWorkflowTestServerWithConfig(t, func(target *config.Config) {
		target.DefaultUnlockPolicyVariant = "allow_without_template"
	})
	defer server.Close()

	body := `{
		"gift_id":"rose_blue_rare",
		"sender_user_id":"gift-sender-idem-1",
		"receiver_user_id":"gift-receiver-idem-1"
	}`

	firstReq := httptest.NewRequest(http.MethodPost, "/v1/chat/match-gift-idem-1/gifts/send", strings.NewReader(body))
	firstReq.Header.Set("Content-Type", "application/json")
	firstReq.Header.Set("Idempotency-Key", "idem-gift-001")
	firstReq.Header.Set("X-User-ID", "gift-sender-idem-1")
	firstRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(firstRec, firstReq)
	if firstRec.Code != http.StatusOK {
		t.Fatalf("first send gift code=%d body=%s", firstRec.Code, firstRec.Body.String())
	}
	firstPayload := decodeJSONMap(t, firstRec.Body.Bytes())
	firstSend := toMap(t, firstPayload["gift_send"])
	firstGiftSendID := stringValue(firstSend["id"])
	if firstGiftSendID == "" {
		t.Fatalf("expected first gift_send.id")
	}

	secondReq := httptest.NewRequest(http.MethodPost, "/v1/chat/match-gift-idem-1/gifts/send", strings.NewReader(body))
	secondReq.Header.Set("Content-Type", "application/json")
	secondReq.Header.Set("Idempotency-Key", "idem-gift-001")
	secondReq.Header.Set("X-User-ID", "gift-sender-idem-1")
	secondRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(secondRec, secondReq)
	if secondRec.Code != http.StatusOK {
		t.Fatalf("second send gift code=%d body=%s", secondRec.Code, secondRec.Body.String())
	}
	if got := secondRec.Header().Get("X-Idempotent-Replay"); got != "true" {
		t.Fatalf("expected X-Idempotent-Replay=true, got %q", got)
	}
	secondPayload := decodeJSONMap(t, secondRec.Body.Bytes())
	secondSend := toMap(t, secondPayload["gift_send"])
	if got := stringValue(secondSend["id"]); got != firstGiftSendID {
		t.Fatalf("expected replayed gift_send.id=%q, got %q", firstGiftSendID, got)
	}

	walletReq := httptest.NewRequest(http.MethodGet, "/v1/wallet/gift-sender-idem-1/coins", nil)
	walletRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(walletRec, walletReq)
	if walletRec.Code != http.StatusOK {
		t.Fatalf("wallet code=%d body=%s", walletRec.Code, walletRec.Body.String())
	}
	walletPayload := decodeJSONMap(t, walletRec.Body.Bytes())
	wallet := toMap(t, walletPayload["wallet"])
	if got := int(wallet["coin_balance"].(float64)); got != 11 {
		t.Fatalf("expected coin_balance=11 after idempotent replay, got %d", got)
	}
}

func TestServer_SendRoseGiftTelemetryActions(t *testing.T) {
	server := newQuestWorkflowTestServerWithConfig(t, func(target *config.Config) {
		target.DefaultUnlockPolicyVariant = "allow_without_template"
	})
	defer server.Close()

	successBody := `{
		"gift_id":"rose_blue_rare",
		"sender_user_id":"gift-sender-telemetry-1",
		"receiver_user_id":"gift-receiver-telemetry-1"
	}`
	successReq := httptest.NewRequest(http.MethodPost, "/v1/chat/match-gift-telemetry-1/gifts/send", strings.NewReader(successBody))
	successReq.Header.Set("Content-Type", "application/json")
	successRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(successRec, successReq)
	if successRec.Code != http.StatusOK {
		t.Fatalf("success send gift code=%d body=%s", successRec.Code, successRec.Body.String())
	}

	failBody := `{
		"gift_id":"rose_crystal",
		"sender_user_id":"gift-sender-telemetry-2",
		"receiver_user_id":"gift-receiver-telemetry-2"
	}`
	firstFailReq := httptest.NewRequest(http.MethodPost, "/v1/chat/match-gift-telemetry-2/gifts/send", strings.NewReader(failBody))
	firstFailReq.Header.Set("Content-Type", "application/json")
	firstFailRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(firstFailRec, firstFailReq)
	if firstFailRec.Code != http.StatusOK {
		t.Fatalf("first telemetry send code=%d body=%s", firstFailRec.Code, firstFailRec.Body.String())
	}

	secondFailReq := httptest.NewRequest(http.MethodPost, "/v1/chat/match-gift-telemetry-2/gifts/send", strings.NewReader(failBody))
	secondFailReq.Header.Set("Content-Type", "application/json")
	secondFailRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(secondFailRec, secondFailReq)
	if secondFailRec.Code != http.StatusPaymentRequired {
		t.Fatalf("expected status 402, got code=%d body=%s", secondFailRec.Code, secondFailRec.Body.String())
	}

	activities := server.store.listActivities(100)
	assertActionSeen(t, activities, "gift_send_attempted")
	assertActionSeen(t, activities, "gift_send_succeeded")
	assertActionSeen(t, activities, "gift_send_failed_insufficient_coins")
}

func TestServer_RecordRoseGiftTelemetryEvent(t *testing.T) {
	server := newQuestWorkflowTestServerWithConfig(t, func(target *config.Config) {
		target.DefaultUnlockPolicyVariant = "allow_without_template"
	})
	defer server.Close()

	body := `{
		"event_name":"gift_panel_opened",
		"user_id":"gift-telemetry-user-1",
		"wallet_coins":12,
		"catalog_count":8
	}`
	req := httptest.NewRequest(http.MethodPost, "/v1/chat/match-gift-panel-1/gifts/events", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, req)
	if rec.Code != http.StatusAccepted {
		t.Fatalf("record gift telemetry code=%d body=%s", rec.Code, rec.Body.String())
	}

	payload := decodeJSONMap(t, rec.Body.Bytes())
	if accepted, ok := payload["accepted"].(bool); !ok || !accepted {
		t.Fatalf("expected accepted=true payload, got %#v", payload)
	}

	activities := server.store.listActivities(20)
	assertActionSeen(t, activities, "gift_panel_opened")
}

func TestServer_TopUpWalletCoinsRequiresAdminUserInProduction(t *testing.T) {
	server := newQuestWorkflowTestServerWithConfig(t, func(target *config.Config) {
		target.Environment = "production"
	})
	defer server.Close()

	req := httptest.NewRequest(
		http.MethodPost,
		"/v1/wallet/prod-wallet-user-1/coins/top-up",
		strings.NewReader(`{"amount":5,"reason":"qa_seed"}`),
	)
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, req)

	if rec.Code != http.StatusForbidden {
		t.Fatalf("expected status 403, got code=%d body=%s", rec.Code, rec.Body.String())
	}
}

func TestServer_TopUpWalletCoinsWithAdminUserReturnsAuditReceipt(t *testing.T) {
	server := newQuestWorkflowTestServerWithConfig(t, func(target *config.Config) {
		target.Environment = "staging"
	})
	defer server.Close()

	req := httptest.NewRequest(
		http.MethodPost,
		"/v1/wallet/stage-wallet-user-1/coins/top-up",
		strings.NewReader(`{"amount":7,"reason":"qa_seed"}`),
	)
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Admin-User", "qa-admin")
	rec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status 200, got code=%d body=%s", rec.Code, rec.Body.String())
	}
	payload := decodeJSONMap(t, rec.Body.Bytes())
	audit := toMap(t, payload["audit"])
	if got := stringValue(audit["receipt_id"]); got == "" {
		t.Fatalf("expected non-empty audit receipt id")
	}
	if got := stringValue(audit["requested_by"]); got != "qa-admin" {
		t.Fatalf("expected requested_by qa-admin, got %q", got)
	}

	activities := server.store.listActivities(20)
	foundWalletTopUp := false
	for _, item := range activities {
		if item.Action != "wallet.topup" {
			continue
		}
		if strings.TrimSpace(item.UserID) != "stage-wallet-user-1" {
			continue
		}
		if strings.TrimSpace(toString(item.Details["audit_receipt_id"])) == "" {
			t.Fatalf("expected wallet.topup activity to include audit_receipt_id")
		}
		if strings.TrimSpace(toString(item.Details["requested_by"])) != "qa-admin" {
			t.Fatalf("expected wallet.topup requested_by qa-admin")
		}
		foundWalletTopUp = true
		break
	}
	if !foundWalletTopUp {
		t.Fatalf("expected wallet.topup activity event")
	}
}

func TestServer_ListWalletCoinAuditReturnsWalletAndGiftActions(t *testing.T) {
	server := newQuestWorkflowTestServerWithConfig(t, func(target *config.Config) {
		target.DefaultUnlockPolicyVariant = "allow_without_template"
	})
	defer server.Close()

	topUpReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/wallet/audit-wallet-user-1/coins/top-up",
		strings.NewReader(`{"amount":4,"reason":"qa_seed"}`),
	)
	topUpReq.Header.Set("Content-Type", "application/json")
	topUpRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(topUpRec, topUpReq)
	if topUpRec.Code != http.StatusOK {
		t.Fatalf("top-up code=%d body=%s", topUpRec.Code, topUpRec.Body.String())
	}

	sendBody := `{
		"gift_id":"rose_blue_rare",
		"sender_user_id":"audit-wallet-user-1",
		"receiver_user_id":"audit-wallet-user-2"
	}`
	sendReq := httptest.NewRequest(http.MethodPost, "/v1/chat/match-wallet-audit-1/gifts/send", strings.NewReader(sendBody))
	sendReq.Header.Set("Content-Type", "application/json")
	sendRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(sendRec, sendReq)
	if sendRec.Code != http.StatusOK {
		t.Fatalf("send gift code=%d body=%s", sendRec.Code, sendRec.Body.String())
	}

	auditReq := httptest.NewRequest(http.MethodGet, "/v1/wallet/audit-wallet-user-1/coins/audit?limit=10", nil)
	auditRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(auditRec, auditReq)
	if auditRec.Code != http.StatusOK {
		t.Fatalf("wallet audit code=%d body=%s", auditRec.Code, auditRec.Body.String())
	}
	payload := decodeJSONMap(t, auditRec.Body.Bytes())
	if got := int(payload["count"].(float64)); got < 2 {
		t.Fatalf("expected at least 2 audit events, got %d", got)
	}
	events, ok := payload["audit"].([]any)
	if !ok || len(events) == 0 {
		t.Fatalf("expected non-empty audit events")
	}

	foundTopUp := false
	foundGiftSuccess := false
	for _, raw := range events {
		eventMap := toMap(t, raw)
		action := stringValue(eventMap["action"])
		if action == "wallet.topup" {
			foundTopUp = true
		}
		if action == "gift_send_succeeded" {
			foundGiftSuccess = true
		}
	}
	if !foundTopUp {
		t.Fatalf("expected wallet.topup in audit list")
	}
	if !foundGiftSuccess {
		t.Fatalf("expected gift_send_succeeded in audit list")
	}
}

func TestMapRoseGiftCatalogRow_UsesDBIconKeyWhenPresent(t *testing.T) {
	row := map[string]any{
		"id":          "mystery_rose",
		"name":        "Mystery Rose",
		"gif_url":     "https://example.test/rose.gif",
		"icon_key":    "rose_custom_ab",
		"tier":        "premium_common",
		"price_coins": 1,
		"is_limited":  false,
		"is_active":   true,
		"sort_order":  10,
	}

	item := mapRoseGiftCatalogRow(row)
	if item.IconKey != "rose_custom_ab" {
		t.Fatalf("expected DB icon_key to be preserved, got %q", item.IconKey)
	}
}

func TestMapRoseGiftCatalogRow_DefaultsUnknownIconKeyToRoseRed(t *testing.T) {
	row := map[string]any{
		"id":          "gift_unknown",
		"name":        "Mystery Bloom",
		"gif_url":     "https://example.test/unknown.gif",
		"icon_key":    "",
		"tier":        "free",
		"price_coins": 0,
		"is_limited":  false,
		"is_active":   true,
		"sort_order":  99,
	}

	item := mapRoseGiftCatalogRow(row)
	if item.IconKey != "rose_red" {
		t.Fatalf("expected fallback icon_key rose_red, got %q", item.IconKey)
	}
}
