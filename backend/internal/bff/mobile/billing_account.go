package mobile

import (
	"errors"
	"net/http"
	"strings"
)

// getBillingAccount is an authenticated, read-only view of the current member's
// payment account. It never provisions a customer, starts a charge or exposes
// provider credentials/customer IDs. The billing release/feature gate applies.
func (s *Server) getBillingAccount(w http.ResponseWriter, r *http.Request) {
	principal, ok := principalFromRequest(r)
	if !ok || principal.UserID == "" {
		writeError(w, http.StatusUnauthorized, errors.New("sign in to view your payment account"))
		return
	}
	w.Header().Set("Cache-Control", "no-store")
	repo := s.store.billingRepo
	if repo == nil || repo.db == nil {
		writeError(w, http.StatusServiceUnavailable, errBillingNotDurable)
		return
	}
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	email, name, err := repo.memberContact(ctx, principal.UserID)
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("payment account is unavailable"))
		return
	}
	mode, provider := "disabled", ""
	connected := false
	pending := make([]map[string]any, 0)
	if s.billing != nil && s.billing.provider != nil {
		provider = s.billing.provider.Name()
		mode = billingPaymentMode(provider, s.cfg.StripeSecretKey)
		customerID, err := repo.providerCustomer(ctx, principal.UserID, provider)
		if err != nil {
			writeError(w, http.StatusServiceUnavailable, errBillingNotDurable)
			return
		}
		connected = customerID != ""
		// Recover durable sessions after closing a tab or restarting the app.
		// Only this member's unexpired subscription/card setup sessions qualify.
		rows, err := repo.db.QueryContext(ctx, `SELECT `+checkoutSelectColumns+`
			FROM matching.billing_checkout_sessions c
			WHERE user_id=$1 AND provider=$2 AND status='open'
			AND expires_at > NOW() AND checkout_url IS NOT NULL AND checkout_url <> ''
			AND (kind='subscription' AND NOT EXISTS (
				SELECT 1 FROM matching.billing_subscriptions_runtime s
				WHERE s.user_id=c.user_id AND s.status IN ('active','past_due') AND s.provider <> 'local'
			) OR kind='card_update' AND EXISTS (
				SELECT 1 FROM matching.billing_subscriptions_runtime s
				WHERE s.provider_subscription_id=c.subscription_ref AND s.provider=c.provider
				AND s.user_id=c.user_id AND s.status IN ('active','past_due')
			)) ORDER BY created_at DESC LIMIT 5`, principal.UserID, provider)
		if err != nil {
			writeError(w, http.StatusServiceUnavailable, errBillingNotDurable)
			return
		}
		defer rows.Close()
		for rows.Next() {
			row, err := scanCheckout(rows)
			if err != nil {
				writeError(w, http.StatusServiceUnavailable, errBillingNotDurable)
				return
			}
			// Local sandbox sessions live in memory; don't offer dead links
			// after the development server restarts.
			if s.billing.sandbox != nil {
				if _, exists := s.billing.sandbox.Session(row.ProviderSessionID); !exists {
					continue
				}
			}
			pending = append(pending, map[string]any{
				"id": row.ID, "kind": row.Kind, "status": row.Status,
				"plan_code": row.PlanCode, "billing_cycle": row.BillingCycle,
				"amount_minor": row.AmountMinor, "currency": row.Currency,
				"checkout_url": row.CheckoutURL, "expires_at": row.ExpiresAt,
				"return_url": s.cfg.PaymentsPublicBaseURL + "/billing/checkout/return",
			})
		}
		if err := rows.Err(); err != nil {
			writeError(w, http.StatusServiceUnavailable, errBillingNotDurable)
			return
		}
	}
	methods := make([]string, 0)
	if mode != "disabled" {
		methods = append(methods, "card")
	}
	writeJSON(w, http.StatusOK, map[string]any{"account": map[string]any{
		"user_id": principal.UserID, "name": name, "email": email,
		"provider": provider, "mode": mode, "customer_connected": connected,
		"payment_methods": methods, "pending_checkouts": pending,
	}})
}

func billingPaymentMode(provider, key string) string {
	if provider == "sandbox" {
		return "sandbox"
	}
	if provider == "stripe" {
		if strings.HasPrefix(key, "sk_test_") || strings.HasPrefix(key, "rk_test_") {
			return "test"
		}
		if strings.HasPrefix(key, "sk_live_") || strings.HasPrefix(key, "rk_live_") {
			return "live"
		}
	}
	return "disabled"
}
