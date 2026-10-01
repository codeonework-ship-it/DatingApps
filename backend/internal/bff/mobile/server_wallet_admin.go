package mobile

import (
	"database/sql"
	"errors"
	"net/http"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)

// operatorRoleFor returns the first of the allowed roles the operator holds.
func operatorRoleFor(r *http.Request, allowed ...string) (securityPrincipal, string, bool) {
	principal, ok := principalFromRequest(r)
	if !ok || strings.TrimSpace(principal.UserID) == "" {
		return securityPrincipal{}, "", false
	}
	for _, role := range allowed {
		if principal.Roles[role] {
			return principal, role, true
		}
	}
	return principal, "", false
}

// adminReverseGiftSend refunds a sent gift. Trust & safety and billing
// operators only; moderators and analysts cannot move coins.
func (s *Server) adminReverseGiftSend(w http.ResponseWriter, r *http.Request) {
	principal, role, ok := operatorRoleFor(r, "admin", "trust_safety", "ops_admin")
	if !ok {
		writeError(w, http.StatusForbidden, errors.New("gift reversal requires the admin, trust_safety or ops_admin role"))
		return
	}
	sendID := strings.TrimSpace(chi.URLParam(r, "sendID"))
	if _, err := uuid.Parse(sendID); err != nil {
		writeError(w, http.StatusBadRequest, errors.New("gift send id must be a UUID"))
		return
	}
	if s.store == nil || s.store.giftLedger == nil {
		writeError(w, http.StatusServiceUnavailable, errGiftLedgerUnconfigured)
		return
	}
	payload, valid := readJSON(w, r)
	if !valid {
		return
	}
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	result, err := s.store.giftLedger.reverse(ctx, sendID,
		principal.UserID, role, toString(payload["reason"]))
	switch {
	case err == nil:
		writeJSON(w, http.StatusOK, map[string]any{
			"gift_send_id":      result.SendID,
			"sender_user_id":    result.SenderUserID,
			"coins_refunded":    result.CoinsRefunded,
			"sender_balance":    result.SenderBalance,
			"message_retracted": result.MessageRetracted,
			"status":            "refunded",
		})
	case errors.Is(err, sql.ErrNoRows):
		writeError(w, http.StatusNotFound, errors.New("gift send not found"))
	case errors.Is(err, errGiftAlreadyReversed):
		writeJSON(w, http.StatusConflict, map[string]any{"success": false, "error": err.Error(), "error_code": "GIFT_ALREADY_REVERSED"})
	case errors.Is(err, errGiftReverseReason):
		writeError(w, http.StatusBadRequest, err)
	default:
		writeError(w, http.StatusBadGateway, err)
	}
}

// adminListFrozenWallets lists wallets frozen after a reversed purchase.
func (s *Server) adminListFrozenWallets(w http.ResponseWriter, r *http.Request) {
	if err := requireAdminUser(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	if s.store == nil || s.store.billingRepo == nil {
		writeError(w, http.StatusServiceUnavailable, errBillingNotDurable)
		return
	}
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	rows, err := s.store.billingRepo.db.QueryContext(ctx, `
		SELECT user_id::text, coin_balance, debt_coins, frozen_at, COALESCE(frozen_reason,'')
		FROM matching.user_wallets WHERE frozen_at IS NOT NULL
		ORDER BY frozen_at LIMIT 200`)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	defer rows.Close()
	wallets := []map[string]any{}
	for rows.Next() {
		var userID, reason string
		var balance, debt int
		var frozenAt time.Time
		if err := rows.Scan(&userID, &balance, &debt, &frozenAt, &reason); err != nil {
			writeError(w, http.StatusBadGateway, err)
			return
		}
		wallets = append(wallets, map[string]any{
			"user_id": userID, "coin_balance": balance, "debt_coins": debt,
			"frozen_at": frozenAt.UTC().Format(time.RFC3339), "frozen_reason": reason,
		})
	}
	writeJSON(w, http.StatusOK, map[string]any{"wallets": wallets, "count": len(wallets)})
}

// adminReviewFrozenWallet lifts a freeze after operator review.
func (s *Server) adminReviewFrozenWallet(w http.ResponseWriter, r *http.Request) {
	principal, role, ok := operatorRoleFor(r, "admin", "ops_admin")
	if !ok {
		writeError(w, http.StatusForbidden, errors.New("wallet review requires the admin or ops_admin role"))
		return
	}
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if _, err := uuid.Parse(userID); err != nil {
		writeError(w, http.StatusBadRequest, errors.New("user id must be a UUID"))
		return
	}
	if s.store == nil || s.store.billingRepo == nil {
		writeError(w, http.StatusServiceUnavailable, errBillingNotDurable)
		return
	}
	payload, valid := readJSON(w, r)
	if !valid {
		return
	}
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	result, err := s.store.billingRepo.reviewFrozenWallet(ctx, userID,
		principal.UserID, role, strings.TrimSpace(toString(payload["action"])), toString(payload["note"]))
	switch {
	case err == nil:
		writeJSON(w, http.StatusOK, map[string]any{
			"user_id": result.UserID, "coin_balance": result.CoinBalance,
			"debt_collected": result.DebtCollected, "debt_written_off": result.DebtWrittenOff,
			"frozen": false,
		})
	case errors.Is(err, sql.ErrNoRows):
		writeError(w, http.StatusNotFound, errors.New("wallet not found"))
	case errors.Is(err, errWalletNotFrozen), errors.Is(err, errWalletDebtOutstanding):
		writeError(w, http.StatusConflict, err)
	case errors.Is(err, errWalletReviewAction), errors.Is(err, errWalletReviewNote):
		writeError(w, http.StatusBadRequest, err)
	default:
		writeError(w, http.StatusBadGateway, err)
	}
}
