package mobile

import (
	"context"
	"errors"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
)

var roseGiftTelemetryEventStatusByName = map[string]string{
	"gift_panel_opened":                   "success",
	"gift_preview_opened":                 "success",
	"gift_send_attempted":                 "attempt",
	"gift_send_succeeded":                 "success",
	"gift_send_failed_insufficient_coins": "failed",
	"gift_send_failed_chat_locked":        "failed",
	"gift_send_failed":                    "failed",
}

const (
	maxWalletTopUpAmount = 1000
)

func (s *Server) listRoseGifts(w http.ResponseWriter, _ *http.Request) {
	items := s.store.listRoseGiftCatalog()
	writeJSON(w, http.StatusOK, map[string]any{
		"gifts": items,
		"count": len(items),
	})
}

func (s *Server) getWalletCoins(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("user id is required"))
		return
	}
	wallet := s.store.getWalletCoins(userID)
	if wallet.UserID == "" {
		writeError(w, http.StatusBadGateway, errors.New("wallet unavailable"))
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"wallet": wallet,
	})
}

func (s *Server) topUpWalletCoins(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("user id is required"))
		return
	}
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	amount, _ := toInt(payload["amount"])
	if amount > maxWalletTopUpAmount {
		writeError(w, http.StatusBadRequest, errors.New("amount exceeds max top-up limit"))
		return
	}
	reason := strings.TrimSpace(toString(payload["reason"]))
	if reason == "" {
		reason = "manual_top_up"
	}
	requestedBy := strings.TrimSpace(r.Header.Get("X-Admin-User"))
	if requestedBy == "" {
		requestedBy = strings.TrimSpace(toString(payload["requested_by"]))
	}
	if s.requiresWalletTopUpApprover() && requestedBy == "" {
		writeError(w, http.StatusForbidden, errors.New("wallet top-up requires X-Admin-User in this environment"))
		return
	}
	if requestedBy == "" {
		requestedBy = userID
	}
	wallet, err := s.store.topUpWalletCoins(userID, amount, reason)
	if err != nil {
		writeError(w, http.StatusBadRequest, err)
		return
	}
	auditReceiptID := newGroupUUID()

	s.store.recordActivity(activityEvent{
		UserID:   userID,
		Actor:    requestedBy,
		Action:   "wallet.topup",
		Status:   "success",
		Resource: "/wallet/" + userID + "/coins/top-up",
		Details: map[string]any{
			"amount":             amount,
			"reason":             reason,
			"balance":            wallet.CoinBalance,
			"currency":           "coins",
			"requested_by":       requestedBy,
			"wallet_topup_audit": true,
			"audit_receipt_id":   auditReceiptID,
			"environment":        strings.TrimSpace(s.cfg.Environment),
		},
	})

	writeJSON(w, http.StatusOK, map[string]any{
		"wallet": wallet,
		"audit": map[string]any{
			"receipt_id":   auditReceiptID,
			"requested_by": requestedBy,
			"reason":       reason,
		},
	})
}

func (s *Server) buyWalletCoins(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("user id is required"))
		return
	}

	payload, ok := readJSON(w, r)
	if !ok {
		return
	}

	packageID := strings.TrimSpace(toString(payload["package_id"]))
	if packageID == "" {
		packageID = "coins_pack_custom"
	}

	coins, _ := toInt(payload["coins"])
	if coins <= 0 {
		writeError(w, http.StatusBadRequest, errors.New("coins must be greater than 0"))
		return
	}
	if coins > maxWalletTopUpAmount {
		writeError(w, http.StatusBadRequest, errors.New("coins exceeds max buy limit"))
		return
	}

	amountMinor, _ := toInt(payload["amount_minor"])
	if amountMinor < 0 {
		writeError(w, http.StatusBadRequest, errors.New("amount_minor cannot be negative"))
		return
	}

	provider := strings.TrimSpace(toString(payload["provider"]))
	if provider == "" {
		provider = "internal"
	}
	currency := strings.TrimSpace(toString(payload["currency"]))
	if currency == "" {
		currency = "coins"
	}
	purchaseRef := strings.TrimSpace(toString(payload["purchase_ref"]))
	idempotencyKey := strings.TrimSpace(r.Header.Get("Idempotency-Key"))
	if idempotencyKey == "" {
		idempotencyKey = strings.TrimSpace(toString(payload["idempotency_key"]))
	}

	now := time.Now().UTC()
	wallet, purchase, err := s.store.buyWalletCoins(
		userID,
		packageID,
		provider,
		currency,
		purchaseRef,
		idempotencyKey,
		coins,
		amountMinor,
		now,
	)
	if err != nil {
		writeError(w, http.StatusBadRequest, err)
		return
	}

	s.store.recordActivity(activityEvent{
		UserID:   userID,
		Actor:    userID,
		Action:   "wallet.coins.purchase",
		Status:   "success",
		Resource: "/wallet/" + userID + "/coins/buy",
		Details: map[string]any{
			"package_id":           packageID,
			"provider":             provider,
			"purchase_ref":         purchaseRef,
			"coins":                coins,
			"amount_minor":         amountMinor,
			"currency":             currency,
			"wallet_balance_after": wallet.CoinBalance,
			"idempotency_key":      idempotencyKey,
			"purchase_id":          purchase.ID,
		},
	})

	writeJSON(w, http.StatusOK, map[string]any{
		"wallet":   wallet,
		"purchase": purchase,
	})
}

func (s *Server) listWalletCoinAudit(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("user id is required"))
		return
	}

	limit := 50
	if rawLimit := strings.TrimSpace(r.URL.Query().Get("limit")); rawLimit != "" {
		parsedLimit, err := strconv.Atoi(rawLimit)
		if err != nil || parsedLimit <= 0 {
			writeError(w, http.StatusBadRequest, errors.New("invalid limit"))
			return
		}
		if parsedLimit > 200 {
			parsedLimit = 200
		}
		limit = parsedLimit
	}

	auditActions := map[string]bool{
		"wallet.topup":                        true,
		"wallet.coins.purchase":               true,
		"gift_send_attempted":                 true,
		"gift_send_succeeded":                 true,
		"gift_send_failed":                    true,
		"gift_send_failed_chat_locked":        true,
		"gift_send_failed_insufficient_coins": true,
	}

	activities := s.store.listActivities(limit * 4)
	audit := make([]activityEvent, 0, limit)
	for _, item := range activities {
		if !auditActions[strings.TrimSpace(item.Action)] {
			continue
		}
		if strings.TrimSpace(item.UserID) != userID {
			continue
		}
		audit = append(audit, item)
		if len(audit) >= limit {
			break
		}
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"user_id": userID,
		"count":   len(audit),
		"audit":   audit,
	})
}

func (s *Server) requiresWalletTopUpApprover() bool {
	env := strings.ToLower(strings.TrimSpace(s.cfg.Environment))
	switch env {
	case "production", "prod", "staging", "preprod":
		return true
	default:
		return false
	}
}

func (s *Server) recordRoseGiftTelemetryEvent(w http.ResponseWriter, r *http.Request) {
	matchID := strings.TrimSpace(chi.URLParam(r, "matchID"))
	if matchID == "" {
		writeError(w, http.StatusBadRequest, errors.New("match id is required"))
		return
	}

	payload, ok := readJSON(w, r)
	if !ok {
		return
	}

	eventName := strings.TrimSpace(toString(payload["event_name"]))
	if eventName == "" {
		writeError(w, http.StatusBadRequest, errors.New("event_name is required"))
		return
	}
	status, supported := roseGiftTelemetryEventStatusByName[eventName]
	if !supported {
		writeError(w, http.StatusBadRequest, errors.New("unsupported gift telemetry event_name"))
		return
	}

	userID := strings.TrimSpace(toString(payload["user_id"]))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("user_id is required"))
		return
	}

	payloadMatchID := strings.TrimSpace(toString(payload["match_id"]))
	if payloadMatchID != "" && payloadMatchID != matchID {
		writeError(w, http.StatusBadRequest, errors.New("match_id mismatch between route and payload"))
		return
	}

	details := map[string]any{
		"match_id":     matchID,
		"event_source": "mobile_client",
	}
	for key, value := range payload {
		if key == "event_name" || key == "user_id" || key == "match_id" || value == nil {
			continue
		}
		if stringValue, ok := value.(string); ok {
			trimmed := strings.TrimSpace(stringValue)
			if trimmed == "" {
				continue
			}
			details[key] = trimmed
			continue
		}
		details[key] = value
	}

	s.store.recordActivity(activityEvent{
		UserID:   userID,
		Actor:    userID,
		Action:   eventName,
		Status:   status,
		Resource: "/chat/" + matchID + "/gifts/events",
		Details:  details,
	})

	writeJSON(w, http.StatusAccepted, map[string]any{
		"accepted": true,
	})
}

func (s *Server) sendRoseGift(w http.ResponseWriter, r *http.Request) {
	matchID := strings.TrimSpace(chi.URLParam(r, "matchID"))
	if matchID == "" {
		writeError(w, http.StatusBadRequest, errors.New("match id is required"))
		return
	}

	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	giftID := strings.TrimSpace(toString(payload["gift_id"]))
	senderUserID := strings.TrimSpace(toString(payload["sender_user_id"]))
	receiverUserID := strings.TrimSpace(toString(payload["receiver_user_id"]))
	idempotencyKey := strings.TrimSpace(r.Header.Get("Idempotency-Key"))

	s.store.recordActivity(activityEvent{
		UserID:   senderUserID,
		Actor:    senderUserID,
		Action:   "gift_send_attempted",
		Status:   "attempt",
		Resource: "/chat/" + matchID + "/gifts/send",
		Details: map[string]any{
			"match_id":                 matchID,
			"gift_id":                  giftID,
			"receiver_user_id":         receiverUserID,
			"idempotency_key":          idempotencyKey,
			"idempotency_key_provided": idempotencyKey != "",
		},
	})
	s.recordDurableGiftSpendActivity(giftSpendActivityRecord{
		MatchID:        matchID,
		SenderUserID:   senderUserID,
		ReceiverUserID: receiverUserID,
		GiftID:         giftID,
		Action:         "gift_send_attempted",
		Status:         "attempt",
		IdempotencyKey: idempotencyKey,
		Details: map[string]any{
			"idempotency_key_provided": idempotencyKey != "",
		},
		CreatedAt: time.Now().UTC(),
	})

	chatUnlocked, unlockState, err := s.store.isChatUnlocked(matchID)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	if !chatUnlocked {
		s.store.recordActivity(activityEvent{
			UserID:   senderUserID,
			Actor:    senderUserID,
			Action:   "gift_send_failed_chat_locked",
			Status:   "failed",
			Resource: "/chat/" + matchID + "/gifts/send",
			Details: map[string]any{
				"match_id":              matchID,
				"gift_id":               giftID,
				"unlock_state":          unlockState,
				"error_code":            "CHAT_LOCKED_REQUIREMENT_PENDING",
				"idempotency_key":       idempotencyKey,
				"unlock_policy_variant": s.store.unlockPolicyVariant(),
			},
		})
		s.recordDurableGiftSpendActivity(giftSpendActivityRecord{
			MatchID:        matchID,
			SenderUserID:   senderUserID,
			ReceiverUserID: receiverUserID,
			GiftID:         giftID,
			Action:         "gift_send_failed_chat_locked",
			Status:         "failed",
			IdempotencyKey: idempotencyKey,
			ErrorCode:      "CHAT_LOCKED_REQUIREMENT_PENDING",
			Details: map[string]any{
				"unlock_state":          unlockState,
				"unlock_policy_variant": s.store.unlockPolicyVariant(),
			},
			CreatedAt: time.Now().UTC(),
		})
		writeJSON(w, http.StatusLocked, map[string]any{
			"success":               false,
			"error":                 "chat is locked until quest requirement is completed",
			"error_code":            "CHAT_LOCKED_REQUIREMENT_PENDING",
			"match_id":              matchID,
			"unlock_state":          unlockState,
			"unlock_policy_variant": s.store.unlockPolicyVariant(),
		})
		return
	}

	giftSend, err := s.store.sendRoseGift(
		matchID,
		senderUserID,
		receiverUserID,
		giftID,
		idempotencyKey,
		time.Now().UTC(),
	)
	if err != nil {
		if strings.Contains(strings.ToLower(err.Error()), "insufficient") {
			s.store.recordActivity(activityEvent{
				UserID:   senderUserID,
				Actor:    senderUserID,
				Action:   "gift_send_failed_insufficient_coins",
				Status:   "failed",
				Resource: "/chat/" + matchID + "/gifts/send",
				Details: map[string]any{
					"match_id":        matchID,
					"gift_id":         giftID,
					"error_code":      "INSUFFICIENT_COINS",
					"idempotency_key": idempotencyKey,
				},
			})
			s.recordDurableGiftSpendActivity(giftSpendActivityRecord{
				MatchID:        matchID,
				SenderUserID:   senderUserID,
				ReceiverUserID: receiverUserID,
				GiftID:         giftID,
				Action:         "gift_send_failed_insufficient_coins",
				Status:         "failed",
				IdempotencyKey: idempotencyKey,
				ErrorCode:      "INSUFFICIENT_COINS",
				ErrorMessage:   err.Error(),
				CreatedAt:      time.Now().UTC(),
			})
			writeJSON(w, http.StatusPaymentRequired, map[string]any{
				"success":    false,
				"error":      err.Error(),
				"error_code": "INSUFFICIENT_COINS",
			})
			return
		}
		s.store.recordActivity(activityEvent{
			UserID:   senderUserID,
			Actor:    senderUserID,
			Action:   "gift_send_failed",
			Status:   "failed",
			Resource: "/chat/" + matchID + "/gifts/send",
			Details: map[string]any{
				"match_id":        matchID,
				"gift_id":         giftID,
				"error":           err.Error(),
				"idempotency_key": idempotencyKey,
			},
		})
		s.recordDurableGiftSpendActivity(giftSpendActivityRecord{
			MatchID:        matchID,
			SenderUserID:   senderUserID,
			ReceiverUserID: receiverUserID,
			GiftID:         giftID,
			Action:         "gift_send_failed",
			Status:         "failed",
			IdempotencyKey: idempotencyKey,
			ErrorMessage:   err.Error(),
			CreatedAt:      time.Now().UTC(),
		})
		writeError(w, http.StatusBadRequest, err)
		return
	}

	s.store.recordActivity(activityEvent{
		UserID:   senderUserID,
		Actor:    senderUserID,
		Action:   "chat.gift.send",
		Status:   "success",
		Resource: "/chat/" + matchID + "/gifts/send",
		Details: map[string]any{
			"match_id":        matchID,
			"gift_id":         giftSend.GiftID,
			"gift_tier":       giftTierForEvent(s.store.listRoseGiftCatalog(), giftSend.GiftID),
			"price_coins":     giftSend.PriceCoins,
			"remaining_coins": giftSend.RemainingCoins,
		},
	})
	s.recordDurableGiftSpendActivity(giftSpendActivityRecord{
		MatchID:            matchID,
		SenderUserID:       senderUserID,
		ReceiverUserID:     receiverUserID,
		GiftID:             giftSend.GiftID,
		Action:             "gift_send_succeeded",
		Status:             "success",
		PriceCoins:         giftSend.PriceCoins,
		WalletBalanceAfter: &giftSend.RemainingCoins,
		IdempotencyKey:     idempotencyKey,
		Details: map[string]any{
			"gift_send_id": giftSend.ID,
			"gift_tier":    giftTierForEvent(s.store.listRoseGiftCatalog(), giftSend.GiftID),
			"message_id":   giftSend.MessageID,
		},
		CreatedAt: time.Now().UTC(),
	})
	s.store.recordActivity(activityEvent{
		UserID:   senderUserID,
		Actor:    senderUserID,
		Action:   "gift_send_succeeded",
		Status:   "success",
		Resource: "/chat/" + matchID + "/gifts/send",
		Details: map[string]any{
			"match_id":        matchID,
			"gift_id":         giftSend.GiftID,
			"gift_tier":       giftTierForEvent(s.store.listRoseGiftCatalog(), giftSend.GiftID),
			"price_coins":     giftSend.PriceCoins,
			"remaining_coins": giftSend.RemainingCoins,
			"idempotency_key": idempotencyKey,
		},
	})

	writeJSON(w, http.StatusOK, map[string]any{
		"gift_send": giftSend,
		"wallet": map[string]any{
			"user_id":      senderUserID,
			"coin_balance": giftSend.RemainingCoins,
		},
	})
}

func giftTierForEvent(catalog []roseGiftCatalogItem, giftID string) string {
	trimmedGiftID := strings.TrimSpace(giftID)
	if trimmedGiftID == "" {
		return "unknown"
	}
	for _, item := range catalog {
		if strings.TrimSpace(item.ID) == trimmedGiftID {
			tier := strings.TrimSpace(item.Tier)
			if tier == "" {
				return "unknown"
			}
			return tier
		}
	}
	return "unknown"
}

func (s *Server) recordDurableGiftSpendActivity(record giftSpendActivityRecord) {
	if s == nil || s.store == nil || s.store.giftsRepo == nil {
		return
	}
	if err := s.store.giftsRepo.recordGiftSpendActivity(context.Background(), record); err != nil {
		if !s.store.durableEngagementRequired() || isGiftRepoPersistenceUnavailable(err) {
			return
		}
		s.store.recordActivity(activityEvent{
			UserID:   strings.TrimSpace(record.SenderUserID),
			Actor:    strings.TrimSpace(record.SenderUserID),
			Action:   "gift_spend_activity_log_failed",
			Status:   "failed",
			Resource: "/chat/" + strings.TrimSpace(record.MatchID) + "/gifts/send",
			Details: map[string]any{
				"gift_id":        strings.TrimSpace(record.GiftID),
				"attempt_action": strings.TrimSpace(record.Action),
				"error":          err.Error(),
			},
		})
	}
}
