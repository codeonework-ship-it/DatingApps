package mobile

import (
	"context"
	"errors"
	"fmt"
	"html/template"
	"io"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/go-chi/chi/v5"
	"go.uber.org/zap"

	"github.com/verified-dating/backend/internal/platform/config"
	"github.com/verified-dating/backend/internal/platform/observability"
	"github.com/verified-dating/backend/internal/platform/payments"
)

// billingCheckoutService sells auto-renewing card subscriptions through a
// payment provider and keeps the local ledger in step with the provider's
// signed webhooks. See PEN-01 / BILL-004.
type billingCheckoutService struct {
	cfg      config.Config
	log      *zap.Logger
	repo     *billingRepository
	provider payments.Provider
	sandbox  *payments.Sandbox
	now      func() time.Time
	// creditWallet credits purchased coins through the wallet ledger, which
	// is idempotent on (user, idempotency key). Installed by the server.
	creditWallet func(ctx context.Context, req walletCoinCreditRequest) error

	sweepCancel context.CancelFunc
	sweepDone   sync.WaitGroup
}

var errBadSimulateEvent = errors.New("event must be renewal_paid, renewal_failed, period_end, refund, dispute_open, dispute_won or dispute_lost")

var (
	errCheckoutRequired  = errors.New("subscriptions are activated through card checkout; call POST /billing/checkout")
	errPaymentsDisabled  = errors.New("card payments are not enabled on this server")
	errBillingNotDurable = errors.New("billing persistence is unavailable")
	errAlreadySubscribed = errors.New("a paid subscription is already live for this member; turn off auto-renew and let the current period end before choosing another plan")
)

func newBillingCheckoutService(cfg config.Config, log *zap.Logger, repo *billingRepository) (*billingCheckoutService, error) {
	if !cfg.PaymentsEnabled() {
		return nil, nil
	}
	svc := &billingCheckoutService{cfg: cfg, log: log, repo: repo, now: func() time.Time { return time.Now().UTC() }}
	switch cfg.PaymentsProvider {
	case "stripe":
		provider, err := payments.NewStripe(payments.StripeConfig{
			SecretKey:     cfg.StripeSecretKey,
			WebhookSecret: cfg.StripeWebhookSecret,
			APIBaseURL:    cfg.StripeAPIBaseURL,
		})
		if err != nil {
			return nil, err
		}
		svc.provider = provider
	case "sandbox":
		sandbox, err := payments.NewSandbox(cfg.PaymentsSandboxWebhookSecret, cfg.PaymentsPublicBaseURL)
		if err != nil {
			return nil, err
		}
		// The sandbox delivers its events straight into the same pipeline a
		// real provider reaches over HTTP: verified, deduplicated, applied.
		sandbox.SetDeliverer(func(payload []byte, signature string) error {
			ctx, cancel := context.WithTimeout(context.Background(), cfg.BFFRequestTimeout())
			defer cancel()
			_, err := svc.processWebhook(ctx, payload, signature)
			return err
		})
		svc.provider = sandbox
		svc.sandbox = sandbox
	default:
		return nil, fmt.Errorf("unsupported payments provider %q", cfg.PaymentsProvider)
	}
	return svc, nil
}

func (b *billingCheckoutService) startSweep(parent context.Context) {
	if b == nil || b.repo == nil || b.sweepCancel != nil {
		return
	}
	interval := b.sweepInterval()
	ctx, cancel := context.WithCancel(parent)
	b.sweepCancel = cancel
	b.sweepDone.Add(1)
	go func() {
		defer b.sweepDone.Done()
		ticker := time.NewTicker(interval)
		defer ticker.Stop()
		for {
			b.sweepOnce(ctx)
			select {
			case <-ctx.Done():
				return
			case <-ticker.C:
			}
		}
	}()
}

func (b *billingCheckoutService) sweepOnce(ctx context.Context) {
	run := observability.NewHeartbeat(workerBillingRenewalSweep, b.sweepInterval()).Begin()
	sweepCtx, cancel := context.WithTimeout(ctx, 30*time.Second)
	defer cancel()
	expired, err := b.repo.expireLapsedSubscriptions(sweepCtx, b.now(), b.graceWindow())
	run.Items("processed", int(expired))
	run.End(err)
	if err != nil {
		b.log.Warn("billing_sweep_failed", zap.Error(err))
		return
	}
	if expired > 0 {
		b.log.Info("billing_subscriptions_expired", zap.Int64("count", expired))
	}
}

func (b *billingCheckoutService) sweepInterval() time.Duration {
	interval := time.Duration(b.cfg.BillingRenewalSweepSeconds) * time.Second
	if interval <= 0 {
		interval = 5 * time.Minute
	}
	return interval
}

func (b *billingCheckoutService) stop() {
	if b == nil || b.sweepCancel == nil {
		return
	}
	b.sweepCancel()
	b.sweepCancel = nil
	b.sweepDone.Wait()
}

func (b *billingCheckoutService) graceWindow() time.Duration {
	days := b.cfg.BillingPastDueGraceDays
	if days <= 0 {
		days = 7
	}
	return time.Duration(days) * 24 * time.Hour
}

func (b *billingCheckoutService) returnURL(checkoutID, outcome string) string {
	u := b.cfg.PaymentsPublicBaseURL + "/billing/checkout/return?checkout_id=" + url.QueryEscape(checkoutID) + "&status=" + outcome
	if b.cfg.PaymentsProvider == "stripe" {
		// Stripe substitutes the placeholder with the real session id.
		u += "&session_id={CHECKOUT_SESSION_ID}"
	}
	return u
}

// createCheckout validates the plan, refuses a second live paid
// subscription, creates the provider checkout and records it locally. It is
// idempotent on the client's Idempotency-Key.
func (b *billingCheckoutService) createCheckout(ctx context.Context, userID, planCode, billingCycle, idempotencyKey string) (billingCheckoutRow, int, error) {
	if b.repo == nil {
		return billingCheckoutRow{}, http.StatusServiceUnavailable, errBillingNotDurable
	}
	userID = strings.TrimSpace(userID)
	planCode = strings.ToLower(strings.TrimSpace(planCode))
	billingCycle = strings.ToLower(strings.TrimSpace(billingCycle))
	if billingCycle == "" {
		billingCycle = "monthly"
	}
	if userID == "" || planCode == "" {
		return billingCheckoutRow{}, http.StatusBadRequest, errors.New("user_id and plan_id are required")
	}
	if billingCycle != "monthly" && billingCycle != "yearly" {
		return billingCheckoutRow{}, http.StatusBadRequest, errors.New("billing_cycle must be monthly or yearly")
	}
	if existing, found, err := b.repo.checkoutByIdempotency(ctx, userID, idempotencyKey); err != nil {
		return billingCheckoutRow{}, http.StatusBadGateway, err
	} else if found {
		return existing, http.StatusOK, nil
	}
	plan, err := b.repo.planByCode(ctx, planCode)
	if err != nil {
		if errors.Is(err, errPlanNotFound) {
			return billingCheckoutRow{}, http.StatusNotFound, err
		}
		return billingCheckoutRow{}, http.StatusBadGateway, err
	}
	if !plan.IsActive {
		return billingCheckoutRow{}, http.StatusNotFound, errPlanNotFound
	}
	amount := plan.amountMinor(billingCycle)
	if amount <= 0 {
		return billingCheckoutRow{}, http.StatusBadRequest, errors.New("the free plan does not require checkout")
	}
	if live, err := b.repo.liveSubscriptionRow(ctx, nil, userID); err == nil && live.IsPaid {
		return billingCheckoutRow{}, http.StatusConflict, errAlreadySubscribed
	} else if err != nil && !errors.Is(err, errSubscriptionMissing) {
		return billingCheckoutRow{}, http.StatusBadGateway, err
	}

	customerID, err := b.repo.providerCustomer(ctx, userID, b.provider.Name())
	if err != nil {
		return billingCheckoutRow{}, http.StatusBadGateway, err
	}
	if customerID == "" {
		email, name, err := b.repo.memberContact(ctx, userID)
		if err != nil {
			return billingCheckoutRow{}, http.StatusBadRequest, err
		}
		customerID, err = b.provider.EnsureCustomer(ctx, payments.CustomerRequest{UserID: userID, Email: email, Name: name})
		if err != nil {
			return billingCheckoutRow{}, http.StatusBadGateway, fmt.Errorf("payment provider customer: %w", err)
		}
		if err := b.repo.saveProviderCustomer(ctx, userID, b.provider.Name(), customerID); err != nil {
			return billingCheckoutRow{}, http.StatusBadGateway, err
		}
	}

	currency := plan.Currency
	if currency == "" {
		currency = b.cfg.PaymentsCurrency
	}
	checkoutID, err := b.repo.insertCheckout(ctx, userID, plan.Code, billingCycle, b.provider.Name(), idempotencyKey, amount, currency)
	if err != nil {
		return billingCheckoutRow{}, http.StatusBadGateway, err
	}
	session, err := b.provider.CreateSubscriptionCheckout(ctx, payments.CheckoutRequest{
		CheckoutID:     checkoutID,
		UserID:         userID,
		CustomerID:     customerID,
		PlanCode:       plan.Code,
		PlanName:       plan.Name,
		BillingCycle:   billingCycle,
		AmountMinor:    amount,
		Currency:       currency,
		ProviderPrice:  plan.providerPrice(b.provider.Name(), billingCycle),
		SuccessURL:     b.returnURL(checkoutID, "success"),
		CancelURL:      b.returnURL(checkoutID, "cancelled"),
		IdempotencyKey: idempotencyKey,
	})
	if err != nil {
		_ = b.repo.markCheckoutStatus(ctx, checkoutID, "abandoned")
		return billingCheckoutRow{}, http.StatusBadGateway, fmt.Errorf("payment provider checkout: %w", err)
	}
	if err := b.repo.attachCheckoutSession(ctx, checkoutID, session.ProviderSessionID, session.URL, session.ExpiresAt); err != nil {
		return billingCheckoutRow{}, http.StatusBadGateway, err
	}
	row, err := b.repo.checkoutByID(ctx, checkoutID)
	if err != nil {
		return billingCheckoutRow{}, http.StatusBadGateway, err
	}
	b.log.Info("billing_checkout_created",
		zap.String("user_id", userID), zap.String("plan_code", plan.Code), zap.String("billing_cycle", billingCycle),
		zap.Int64("amount_minor", amount), zap.String("provider", b.provider.Name()))
	return row, http.StatusCreated, nil
}

// createCoinCheckout opens a single-charge checkout for a coin package.
// Coins are credited only when the provider reports the charge settled.
const (
	maxCoinCheckoutsPerDay  = 10
	maxCoinsPurchasedPerDay = 10000
)

var errCoinPurchaseLimit = errors.New("daily coin purchase limit reached; try again tomorrow")

func (b *billingCheckoutService) createCoinCheckout(ctx context.Context, userID, packageID, idempotencyKey string) (billingCheckoutRow, int, error) {
	if b.repo == nil {
		return billingCheckoutRow{}, http.StatusServiceUnavailable, errBillingNotDurable
	}
	userID = strings.TrimSpace(userID)
	packageID = strings.TrimSpace(packageID)
	if userID == "" || packageID == "" {
		return billingCheckoutRow{}, http.StatusBadRequest, errors.New("user_id and package_id are required")
	}
	if existing, found, err := b.repo.checkoutByIdempotency(ctx, userID, idempotencyKey); err != nil {
		return billingCheckoutRow{}, http.StatusBadGateway, err
	} else if found {
		return existing, http.StatusOK, nil
	}
	pkg, err := b.repo.coinPackageByID(ctx, packageID)
	if err != nil {
		if errors.Is(err, errPackageNotFound) {
			return billingCheckoutRow{}, http.StatusNotFound, err
		}
		return billingCheckoutRow{}, http.StatusBadGateway, err
	}
	if !pkg.IsActive || pkg.amountMinor() <= 0 || pkg.totalCoins() <= 0 {
		return billingCheckoutRow{}, http.StatusNotFound, errPackageNotFound
	}
	customerID, status, err := b.ensureCustomer(ctx, userID)
	if err != nil {
		return billingCheckoutRow{}, status, err
	}
	currency := strings.ToUpper(pkg.Currency)
	if currency == "" {
		currency = b.cfg.PaymentsCurrency
	}
	checkoutID, err := b.repo.reserveCoinCheckout(ctx, userID, pkg.ID, b.provider.Name(), idempotencyKey, pkg.totalCoins(), pkg.amountMinor(), currency, b.now())
	if err != nil {
		if controlStatus, _, ok := economyControlStatus(err); ok {
			return billingCheckoutRow{}, controlStatus, err
		}
		if errors.Is(err, errCoinPurchaseLimit) {
			return billingCheckoutRow{}, http.StatusTooManyRequests, err
		}
		return billingCheckoutRow{}, http.StatusBadGateway, err
	}
	session, err := b.provider.CreatePaymentCheckout(ctx, payments.PaymentCheckoutRequest{
		CheckoutID:  checkoutID,
		UserID:      userID,
		CustomerID:  customerID,
		Description: fmt.Sprintf("%s · %d coins", pkg.Label, pkg.totalCoins()),
		AmountMinor: pkg.amountMinor(),
		Currency:    currency,
		Metadata: map[string]string{
			"kind":       "coin_package",
			"package_id": pkg.ID,
			"coins":      fmt.Sprint(pkg.totalCoins()),
		},
		SuccessURL:     b.returnURL(checkoutID, "success"),
		CancelURL:      b.returnURL(checkoutID, "cancelled"),
		IdempotencyKey: idempotencyKey,
	})
	if err != nil {
		_ = b.repo.markCheckoutStatus(ctx, checkoutID, "abandoned")
		return billingCheckoutRow{}, http.StatusBadGateway, fmt.Errorf("payment provider checkout: %w", err)
	}
	if err := b.repo.attachCheckoutSession(ctx, checkoutID, session.ProviderSessionID, session.URL, session.ExpiresAt); err != nil {
		return billingCheckoutRow{}, http.StatusBadGateway, err
	}
	row, err := b.repo.checkoutByID(ctx, checkoutID)
	if err != nil {
		return billingCheckoutRow{}, http.StatusBadGateway, err
	}
	b.log.Info("billing_coin_checkout_created", zap.String("user_id", userID), zap.String("package_id", pkg.ID),
		zap.Int("coins", pkg.totalCoins()), zap.Int64("amount_minor", pkg.amountMinor()), zap.String("provider", b.provider.Name()))
	return row, http.StatusCreated, nil
}

func (b *billingCheckoutService) ensureCustomer(ctx context.Context, userID string) (string, int, error) {
	customerID, err := b.repo.providerCustomer(ctx, userID, b.provider.Name())
	if err != nil {
		return "", http.StatusBadGateway, err
	}
	if customerID != "" {
		return customerID, http.StatusOK, nil
	}
	email, name, err := b.repo.memberContact(ctx, userID)
	if err != nil {
		return "", http.StatusBadRequest, err
	}
	customerID, err = b.provider.EnsureCustomer(ctx, payments.CustomerRequest{UserID: userID, Email: email, Name: name})
	if err != nil {
		return "", http.StatusBadGateway, fmt.Errorf("payment provider customer: %w", err)
	}
	if err := b.repo.saveProviderCustomer(ctx, userID, b.provider.Name(), customerID); err != nil {
		return "", http.StatusBadGateway, err
	}
	return customerID, http.StatusOK, nil
}

// settleCoinCheckout credits the wallet for a completed coin checkout. It
// runs after the ledger transaction committed and is idempotent on the
// checkout id, so a retried webhook cannot credit twice.
func (b *billingCheckoutService) settleCoinCheckout(ctx context.Context, ev payments.Event) error {
	if ev.Type != payments.EventCheckoutCompleted || ev.Checkout == nil {
		return nil
	}
	sessionID := ev.Checkout.SessionID
	checkoutID := ev.Checkout.Metadata["checkout_id"]
	var row billingCheckoutRow
	var err error
	if checkoutID != "" {
		row, err = b.repo.checkoutByID(ctx, checkoutID)
	}
	if err != nil || row.ID == "" {
		row, err = b.repo.checkoutByProviderSession(ctx, ev.Provider, sessionID)
	}
	if err != nil {
		return err
	}
	if row.Kind != "coin_package" || row.Status != "completed" || row.Coins <= 0 {
		return nil
	}
	if b.creditWallet == nil {
		return errors.New("wallet credit is not configured")
	}
	purchaseRef := ev.Checkout.PaymentIntentID
	if purchaseRef == "" {
		purchaseRef = sessionID
	}
	err = b.creditWallet(ctx, walletCoinCreditRequest{
		UserID:         row.UserID,
		PackageID:      row.PackageID,
		Source:         "buy",
		Provider:       ev.Provider,
		PurchaseRef:    purchaseRef,
		IdempotencyKey: "checkout:" + row.ID,
		Coins:          row.Coins,
		AmountMinor:    int(row.AmountMinor),
		Currency:       row.Currency,
		Metadata:       map[string]any{"checkout_id": row.ID, "event_id": ev.ID},
		Now:            b.now(),
	})
	if err != nil {
		return fmt.Errorf("credit wallet for checkout %s: %w", row.ID, err)
	}
	// A refund or chargeback recorded before this credit is applied now, so
	// the order in which the provider's events arrive cannot leave coins behind.
	if err := b.repo.reconcileCoinReversalForCheckout(ctx, row.ID, ev.Provider); err != nil {
		return fmt.Errorf("reconcile coin reversal for checkout %s: %w", row.ID, err)
	}
	b.log.Info("billing_coins_credited", zap.String("user_id", row.UserID), zap.String("checkout_id", row.ID), zap.Int("coins", row.Coins))
	return nil
}

// stopRenewalAfterChargeback tells the provider not to renew a subscription
// that a lost dispute ended locally. It is re-run on webhook retry until the
// provider accepts, so a failure cannot leave the member being charged again.
func (b *billingCheckoutService) stopRenewalAfterChargeback(ctx context.Context, ev payments.Event) error {
	if ev.Type != payments.EventDisputeUpdated || ev.Dispute == nil || !ev.Dispute.Closed {
		return nil
	}
	if ev.Dispute.Status != "lost" && ev.Dispute.Status != "charge_refunded" {
		return nil
	}
	ids, err := b.repo.chargebackProviderSubscriptions(ctx, ev.Provider, ev.Dispute.PaymentIntentID, ev.Dispute.ChargeID)
	if err != nil {
		return err
	}
	for _, id := range ids {
		if err := b.provider.SetCancelAtPeriodEnd(ctx, id, true); err != nil {
			return fmt.Errorf("stop renewal of %s: %w", id, err)
		}
	}
	return nil
}

// changePlan switches a live paid subscription to another plan or cycle.
// The provider applies proration; the local row mirrors the new plan and
// the provider's events confirm amount, period and any prorated charge.
func (b *billingCheckoutService) changePlan(ctx context.Context, userID, planCode, billingCycle string) (userSubscription, int, error) {
	if b.repo == nil {
		return userSubscription{}, http.StatusServiceUnavailable, errBillingNotDurable
	}
	planCode = strings.ToLower(strings.TrimSpace(planCode))
	billingCycle = strings.ToLower(strings.TrimSpace(billingCycle))
	if billingCycle == "" {
		billingCycle = "monthly"
	}
	if planCode == "" || (billingCycle != "monthly" && billingCycle != "yearly") {
		return userSubscription{}, http.StatusBadRequest, errors.New("plan_id and a monthly or yearly billing_cycle are required")
	}
	live, err := b.repo.liveSubscriptionRow(ctx, nil, userID)
	if errors.Is(err, errSubscriptionMissing) || (err == nil && !live.IsPaid) {
		return userSubscription{}, http.StatusNotFound, errors.New("no paid subscription to change; subscribe first")
	}
	if err != nil {
		return userSubscription{}, http.StatusBadGateway, err
	}
	if live.Provider != b.provider.Name() || live.ProviderSubscriptionID == "" {
		return userSubscription{}, http.StatusConflict, fmt.Errorf("this subscription is managed by %q and cannot be changed here", live.Provider)
	}
	if live.Status != payments.StatusActive {
		return userSubscription{}, http.StatusConflict, errors.New("settle the outstanding payment before changing plan")
	}
	if live.PlanID == planCode && live.BillingCycle == billingCycle {
		return userSubscription{}, http.StatusConflict, errors.New("already on this plan and billing cycle")
	}
	plan, err := b.repo.planByCode(ctx, planCode)
	if err != nil {
		if errors.Is(err, errPlanNotFound) {
			return userSubscription{}, http.StatusNotFound, err
		}
		return userSubscription{}, http.StatusBadGateway, err
	}
	amount := plan.amountMinor(billingCycle)
	if !plan.IsActive || amount <= 0 {
		return userSubscription{}, http.StatusBadRequest, errors.New("choose a paid plan; turn off auto-renew to move to Free")
	}
	currency := plan.Currency
	if currency == "" {
		currency = b.cfg.PaymentsCurrency
	}
	snap, err := b.provider.FetchSubscription(ctx, live.ProviderSubscriptionID)
	if errors.Is(err, payments.ErrNotFound) && b.rehydrateSandbox(live) {
		snap, err = b.provider.FetchSubscription(ctx, live.ProviderSubscriptionID)
	}
	if err != nil {
		return userSubscription{}, http.StatusBadGateway, fmt.Errorf("payment provider: %w", err)
	}
	// Upgrade when the member will pay more per day than now.
	perDayNew := float64(amount) / map[string]float64{"monthly": 30, "yearly": 365}[billingCycle]
	perDayOld := float64(live.AmountMinor) / map[string]float64{"monthly": 30, "yearly": 365}[live.BillingCycle]
	req := payments.ChangePlanRequest{
		SubscriptionID: live.ProviderSubscriptionID,
		ItemID:         snap.ItemID,
		PlanCode:       plan.Code,
		PlanName:       plan.Name,
		BillingCycle:   billingCycle,
		AmountMinor:    amount,
		Currency:       currency,
		ProviderPrice:  plan.providerPrice(b.provider.Name(), billingCycle),
		Upgrade:        perDayNew > perDayOld,
	}
	if err := b.provider.ChangeSubscriptionPlan(ctx, req); err != nil {
		return userSubscription{}, http.StatusBadGateway, fmt.Errorf("payment provider: %w", err)
	}
	if err := b.repo.applyPlanChange(ctx, live.ID, plan.Code, billingCycle, amount, currency, b.now()); err != nil {
		return userSubscription{}, http.StatusBadGateway, err
	}
	sub, err := b.repo.getSubscriptionWithGrace(ctx, userID, b.graceWindow())
	if err != nil {
		return userSubscription{}, http.StatusBadGateway, err
	}
	b.log.Info("billing_plan_changed", zap.String("user_id", userID), zap.String("from", live.PlanID+"/"+live.BillingCycle),
		zap.String("to", plan.Code+"/"+billingCycle), zap.Bool("upgrade", req.Upgrade))
	return sub, http.StatusOK, nil
}

// createCardUpdateCheckout opens a setup checkout to replace the card on
// the member's live subscription.
func (b *billingCheckoutService) createCardUpdateCheckout(ctx context.Context, userID, idempotencyKey string) (billingCheckoutRow, int, error) {
	if b.repo == nil {
		return billingCheckoutRow{}, http.StatusServiceUnavailable, errBillingNotDurable
	}
	if existing, found, err := b.repo.checkoutByIdempotency(ctx, userID, idempotencyKey); err != nil {
		return billingCheckoutRow{}, http.StatusBadGateway, err
	} else if found {
		return existing, http.StatusOK, nil
	}
	live, err := b.repo.liveSubscriptionRow(ctx, nil, userID)
	if errors.Is(err, errSubscriptionMissing) || (err == nil && !live.IsPaid) {
		return billingCheckoutRow{}, http.StatusNotFound, errors.New("no paid subscription to update a card for")
	}
	if err != nil {
		return billingCheckoutRow{}, http.StatusBadGateway, err
	}
	if live.Provider != b.provider.Name() {
		return billingCheckoutRow{}, http.StatusConflict, fmt.Errorf("this subscription is managed by %q", live.Provider)
	}
	customerID, status, err := b.ensureCustomer(ctx, userID)
	if err != nil {
		return billingCheckoutRow{}, status, err
	}
	if b.sandbox != nil {
		b.rehydrateSandbox(live)
	}
	checkoutID, err := b.repo.insertCardUpdateCheckout(ctx, userID, live.ProviderSubscriptionID, b.provider.Name(), idempotencyKey)
	if err != nil {
		return billingCheckoutRow{}, http.StatusBadGateway, err
	}
	session, err := b.provider.CreateSetupCheckout(ctx, payments.SetupCheckoutRequest{
		CheckoutID:     checkoutID,
		UserID:         userID,
		CustomerID:     customerID,
		SubscriptionID: live.ProviderSubscriptionID,
		SuccessURL:     b.returnURL(checkoutID, "success"),
		CancelURL:      b.returnURL(checkoutID, "cancelled"),
		IdempotencyKey: idempotencyKey,
	})
	if err != nil {
		_ = b.repo.markCheckoutStatus(ctx, checkoutID, "abandoned")
		return billingCheckoutRow{}, http.StatusBadGateway, fmt.Errorf("payment provider checkout: %w", err)
	}
	if err := b.repo.attachCheckoutSession(ctx, checkoutID, session.ProviderSessionID, session.URL, session.ExpiresAt); err != nil {
		return billingCheckoutRow{}, http.StatusBadGateway, err
	}
	row, err := b.repo.checkoutByID(ctx, checkoutID)
	if err != nil {
		return billingCheckoutRow{}, http.StatusBadGateway, err
	}
	return row, http.StatusCreated, nil
}

// settleCardUpdate applies the card collected by a completed setup checkout
// to the subscription at the provider and records it locally.
func (b *billingCheckoutService) settleCardUpdate(ctx context.Context, ev payments.Event) error {
	if ev.Type != payments.EventCheckoutCompleted || ev.Checkout == nil || ev.Checkout.Mode != "setup" {
		return nil
	}
	var row billingCheckoutRow
	var err error
	if id := ev.Checkout.Metadata["checkout_id"]; id != "" {
		row, err = b.repo.checkoutByID(ctx, id)
	}
	if err != nil || row.ID == "" {
		row, err = b.repo.checkoutByProviderSession(ctx, ev.Provider, ev.Checkout.SessionID)
	}
	if err != nil {
		return err
	}
	if row.Kind != "card_update" {
		return nil
	}
	card, err := b.provider.ApplySetupPaymentMethod(ctx, ev.Checkout.SetupIntentID, row.SubscriptionRef)
	if err != nil {
		return fmt.Errorf("apply new card: %w", err)
	}
	if card == nil {
		return nil
	}
	live, err := b.repo.liveSubscriptionRow(ctx, nil, row.UserID)
	if err != nil {
		return nil
	}
	if err := b.repo.updateSubscriptionCard(ctx, live.ID, *card, b.now()); err != nil {
		return err
	}
	// Card digits never reach the logs; the brand is enough to diagnose a
	// provider-specific failure and the subscription row holds the rest.
	b.log.Info("billing_card_updated", zap.String("user_id", row.UserID), zap.String("brand", card.Brand))
	return nil
}

// setAutoRenew turns renewal off or on at the provider and mirrors the
// intent locally; the provider's webhook then confirms it.
func (b *billingCheckoutService) setAutoRenew(ctx context.Context, userID string, autoRenew bool) (userSubscription, int, error) {
	if b.repo == nil {
		return userSubscription{}, http.StatusServiceUnavailable, errBillingNotDurable
	}
	live, err := b.repo.liveSubscriptionRow(ctx, nil, userID)
	if errors.Is(err, errSubscriptionMissing) || (err == nil && !live.IsPaid) {
		return userSubscription{}, http.StatusNotFound, errors.New("no paid subscription to change")
	}
	if err != nil {
		return userSubscription{}, http.StatusBadGateway, err
	}
	if live.Provider != b.provider.Name() || live.ProviderSubscriptionID == "" {
		return userSubscription{}, http.StatusConflict, fmt.Errorf("this subscription is managed by %q and cannot be changed here", live.Provider)
	}
	err = b.provider.SetCancelAtPeriodEnd(ctx, live.ProviderSubscriptionID, !autoRenew)
	if errors.Is(err, payments.ErrNotFound) && b.rehydrateSandbox(live) {
		err = b.provider.SetCancelAtPeriodEnd(ctx, live.ProviderSubscriptionID, !autoRenew)
	}
	if err != nil {
		return userSubscription{}, http.StatusBadGateway, fmt.Errorf("payment provider: %w", err)
	}
	if err := b.repo.setCancelAtPeriodEnd(ctx, live.ID, !autoRenew, b.now()); err != nil {
		return userSubscription{}, http.StatusBadGateway, err
	}
	sub, err := b.repo.getSubscriptionWithGrace(ctx, userID, b.graceWindow())
	if err != nil {
		return userSubscription{}, http.StatusBadGateway, err
	}
	b.log.Info("billing_auto_renew_changed", zap.String("user_id", userID), zap.Bool("auto_renew", autoRenew))
	return sub, http.StatusOK, nil
}

// rehydrateSandbox restores a subscription the in-process sandbox lost on a
// restart from the durable ledger row. Returns false for a real provider.
func (b *billingCheckoutService) rehydrateSandbox(live userSubscription) bool {
	if b.sandbox == nil || live.ProviderSubscriptionID == "" {
		return false
	}
	snap := payments.SubscriptionSnapshot{
		SubscriptionID:    live.ProviderSubscriptionID,
		Status:            live.Status,
		CancelAtPeriodEnd: live.CancelAtPeriodEnd,
		AmountMinor:       live.AmountMinor,
		Currency:          live.Currency,
		Metadata: map[string]string{
			"user_id":       live.UserID,
			"plan_code":     live.PlanID,
			"billing_cycle": live.BillingCycle,
		},
	}
	if live.BillingCycle == "yearly" {
		snap.Interval = "year"
	} else {
		snap.Interval = "month"
	}
	if t, err := time.Parse(time.RFC3339, live.CurrentPeriodStart); err == nil {
		snap.CurrentPeriodStart = t
	}
	if t, err := time.Parse(time.RFC3339, live.CurrentPeriodEnd); err == nil {
		snap.CurrentPeriodEnd = t
	}
	if t, err := time.Parse(time.RFC3339, live.CancelledAt); err == nil {
		snap.CanceledAt = &t
	}
	if live.CardLast4 != "" {
		snap.Card = &payments.CardSummary{Brand: live.CardBrand, Last4: live.CardLast4}
	}
	b.sandbox.RestoreSubscription(live.UserID, snap)
	b.log.Info("billing_sandbox_rehydrated", zap.String("provider_subscription_id", live.ProviderSubscriptionID))
	return true
}

// processWebhook verifies, deduplicates and applies one delivery. The
// returned status is what the HTTP handler answers the provider with: 2xx
// acknowledges, 400 rejects a bad signature for good, 5xx asks for a retry.
func (b *billingCheckoutService) processWebhook(ctx context.Context, payload []byte, signature string) (int, error) {
	event, err := b.provider.ParseWebhook(payload, signature, b.now())
	if err != nil {
		if errors.Is(err, payments.ErrSignature) {
			b.log.Warn("billing_webhook_rejected", zap.Error(err))
		}
		return http.StatusBadRequest, err
	}
	if b.repo == nil {
		return http.StatusServiceUnavailable, errBillingNotDurable
	}
	inserted, err := b.repo.beginWebhookEvent(ctx, event)
	if err != nil {
		return http.StatusInternalServerError, err
	}
	if !inserted {
		// Seen before. A previous failure is retried; a processed or
		// ignored event is acknowledged without touching anything.
		retry, err := b.repo.retryFailedWebhookEvent(ctx, event.Provider, event.ID)
		if err != nil {
			return http.StatusInternalServerError, err
		}
		if !retry {
			b.log.Info("billing_webhook_duplicate", zap.String("event_id", event.ID), zap.String("type", event.RawType))
			return http.StatusOK, nil
		}
	}
	if event.Type == payments.EventIgnored {
		_ = b.repo.finishWebhookEvent(ctx, event.Provider, event.ID, "ignored", "")
		return http.StatusOK, nil
	}
	if err := b.repo.applyEvent(ctx, event, b.provider.FetchSubscription); err != nil {
		_ = b.repo.finishWebhookEvent(ctx, event.Provider, event.ID, "failed", err.Error())
		b.log.Error("billing_webhook_apply_failed", zap.String("event_id", event.ID), zap.String("type", event.RawType), zap.Error(err))
		return http.StatusInternalServerError, err
	}
	if err := b.stopRenewalAfterChargeback(ctx, event); err != nil {
		_ = b.repo.finishWebhookEvent(ctx, event.Provider, event.ID, "failed", err.Error())
		b.log.Error("billing_webhook_chargeback_cancel_failed", zap.String("event_id", event.ID), zap.Error(err))
		return http.StatusInternalServerError, err
	}
	if err := b.settleCoinCheckout(ctx, event); err != nil {
		_ = b.repo.finishWebhookEvent(ctx, event.Provider, event.ID, "failed", err.Error())
		b.log.Error("billing_webhook_settle_failed", zap.String("event_id", event.ID), zap.Error(err))
		return http.StatusInternalServerError, err
	}
	if err := b.settleCardUpdate(ctx, event); err != nil {
		_ = b.repo.finishWebhookEvent(ctx, event.Provider, event.ID, "failed", err.Error())
		b.log.Error("billing_webhook_card_update_failed", zap.String("event_id", event.ID), zap.Error(err))
		return http.StatusInternalServerError, err
	}
	_ = b.repo.finishWebhookEvent(ctx, event.Provider, event.ID, "processed", "")
	b.log.Info("billing_webhook_processed", zap.String("event_id", event.ID), zap.String("type", event.RawType))
	return http.StatusOK, nil
}

// ── HTTP handlers ────────────────────────────────────────────────────────────

func (s *Server) requestUserID(r *http.Request, fallback string) string {
	if principal, ok := principalFromRequest(r); ok && principal.UserID != "" {
		return principal.UserID
	}
	return strings.TrimSpace(fallback)
}

func (s *Server) createBillingCheckout(w http.ResponseWriter, r *http.Request) {
	if s.billing == nil {
		writeError(w, http.StatusNotImplemented, errPaymentsDisabled)
		return
	}
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	userID := s.requestUserID(r, toString(payload["user_id"]))
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	idempotencyKey := strings.TrimSpace(r.Header.Get("Idempotency-Key"))
	var row billingCheckoutRow
	var status int
	var err error
	switch strings.ToLower(strings.TrimSpace(toString(payload["kind"]))) {
	case "coin_package", "coins":
		row, status, err = s.billing.createCoinCheckout(ctx, userID, toString(payload["package_id"]), idempotencyKey)
	case "card_update", "setup":
		row, status, err = s.billing.createCardUpdateCheckout(ctx, userID, idempotencyKey)
	default:
		row, status, err = s.billing.createCheckout(ctx, userID, toString(payload["plan_id"]), toString(payload["billing_cycle"]), idempotencyKey)
	}
	if err != nil {
		writeError(w, status, err)
		return
	}
	writeJSON(w, status, map[string]any{
		"success":    true,
		"checkout":   row,
		"return_url": s.cfg.PaymentsPublicBaseURL + "/billing/checkout/return",
	})
}

func (s *Server) getBillingCheckout(w http.ResponseWriter, r *http.Request) {
	if s.billing == nil || s.billing.repo == nil {
		writeError(w, http.StatusNotImplemented, errPaymentsDisabled)
		return
	}
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	row, err := s.billing.repo.checkoutByID(ctx, chi.URLParam(r, "checkoutID"))
	if err != nil {
		if errors.Is(err, errCheckoutNotFound) {
			writeError(w, http.StatusNotFound, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}
	if owner := s.requestUserID(r, row.UserID); owner != row.UserID {
		writeError(w, http.StatusForbidden, errors.New("checkout does not belong to the authenticated user"))
		return
	}
	resp := map[string]any{"checkout": row}
	if row.Status == "completed" {
		if row.Kind == "coin_package" {
			resp["wallet"] = s.store.getWalletCoins(row.UserID)
		}
		if sub, err := s.billing.repo.getSubscriptionWithGrace(ctx, row.UserID, s.billing.graceWindow()); err == nil {
			resp["subscription"] = sub
		}
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) changeBillingPlan(w http.ResponseWriter, r *http.Request) {
	if s.billing == nil {
		writeError(w, http.StatusNotImplemented, errPaymentsDisabled)
		return
	}
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	userID := s.requestUserID(r, chi.URLParam(r, "userID"))
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	sub, status, err := s.billing.changePlan(ctx, userID, toString(payload["plan_id"]), toString(payload["billing_cycle"]))
	if err != nil {
		writeError(w, status, err)
		return
	}
	writeJSON(w, status, map[string]any{"success": true, "subscription": sub})
}

// adminBillingReconciliation is the operator's settlement view (PEN-02).
func (s *Server) adminBillingReconciliation(w http.ResponseWriter, r *http.Request) {
	if err := requireAdminUser(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	if s.billing == nil || s.billing.repo == nil {
		writeError(w, http.StatusServiceUnavailable, errBillingNotDurable)
		return
	}
	until := time.Now().UTC()
	since := until.AddDate(0, 0, -30)
	if raw := strings.TrimSpace(r.URL.Query().Get("since")); raw != "" {
		if t, err := time.Parse(time.RFC3339, raw); err == nil {
			since = t
		} else if t, err := time.Parse("2006-01-02", raw); err == nil {
			since = t
		}
	}
	if raw := strings.TrimSpace(r.URL.Query().Get("until")); raw != "" {
		if t, err := time.Parse(time.RFC3339, raw); err == nil {
			until = t
		} else if t, err := time.Parse("2006-01-02", raw); err == nil {
			until = t.AddDate(0, 0, 1)
		}
	}
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	report, err := s.billing.repo.reconcile(ctx, since, until)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	report["currency"] = s.cfg.PaymentsCurrency
	report["provider"] = s.billing.provider.Name()
	writeJSON(w, http.StatusOK, report)
}

func (s *Server) cancelBillingSubscription(w http.ResponseWriter, r *http.Request) {
	s.changeAutoRenew(w, r, false)
}

func (s *Server) resumeBillingSubscription(w http.ResponseWriter, r *http.Request) {
	s.changeAutoRenew(w, r, true)
}

func (s *Server) changeAutoRenew(w http.ResponseWriter, r *http.Request, autoRenew bool) {
	if s.billing == nil {
		writeError(w, http.StatusNotImplemented, errPaymentsDisabled)
		return
	}
	userID := s.requestUserID(r, chi.URLParam(r, "userID"))
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	sub, status, err := s.billing.setAutoRenew(ctx, userID, autoRenew)
	if err != nil {
		writeError(w, status, err)
		return
	}
	writeJSON(w, status, map[string]any{"success": true, "subscription": sub})
}

// listCoinPackages is the member-facing catalog of purchasable coin packs.
func (s *Server) listCoinPackages(w http.ResponseWriter, r *http.Request) {
	if s.billing == nil || s.billing.repo == nil {
		writeError(w, http.StatusNotImplemented, errPaymentsDisabled)
		return
	}
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	packages, err := s.billing.repo.listCoinPackages(ctx)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	out := make([]map[string]any, 0, len(packages))
	for _, p := range packages {
		out = append(out, map[string]any{
			"id": p.ID, "label": p.Label, "coin_amount": p.CoinAmount, "bonus_percent": p.BonusPercent,
			"total_coins": p.totalCoins(), "price": p.Price, "amount_minor": p.amountMinor(), "currency": strings.ToUpper(p.Currency),
			"description": p.Description, "sort_order": p.SortOrder,
		})
	}
	writeJSON(w, http.StatusOK, map[string]any{"packages": out, "provider": s.billing.provider.Name(),
		"mode": billingPaymentMode(s.billing.provider.Name(), s.cfg.StripeSecretKey)})
}

const webhookBodyLimit = 1 << 20

func (s *Server) billingWebhook(w http.ResponseWriter, r *http.Request) {
	if s.billing == nil || chi.URLParam(r, "provider") != s.billing.provider.Name() {
		writeError(w, http.StatusNotFound, errors.New("unknown payment provider"))
		return
	}
	body, err := io.ReadAll(io.LimitReader(r.Body, webhookBodyLimit+1))
	if err != nil || len(body) > webhookBodyLimit {
		writeError(w, http.StatusRequestEntityTooLarge, errors.New("webhook payload too large"))
		return
	}
	signature := r.Header.Get("Stripe-Signature")
	if signature == "" {
		signature = r.Header.Get("X-Webhook-Signature")
	}
	ctx, cancel := context.WithTimeout(r.Context(), s.cfg.BFFRequestTimeout())
	defer cancel()
	status, err := s.billing.processWebhook(ctx, body, signature)
	if err != nil {
		writeError(w, status, err)
		return
	}
	writeJSON(w, status, map[string]any{"received": true})
}

// billingCheckoutReturn is the page the hosted checkout redirects to. The
// app intercepts this URL inside its checkout view and polls the checkout
// status; a member who lands here in a plain browser gets a short message.
func (s *Server) billingCheckoutReturn(w http.ResponseWriter, r *http.Request) {
	outcome := r.URL.Query().Get("status")
	title, body := "Payment complete", "Your subscription is being activated. You can return to the app."
	if outcome != "success" {
		title, body = "Checkout cancelled", "No payment was taken. You can return to the app."
	}
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.Header().Set("Cache-Control", "no-store")
	_ = returnPageTemplate.Execute(w, map[string]any{"Title": title, "Body": body, "Success": outcome == "success"})
}

// ── Sandbox hosted checkout ──────────────────────────────────────────────────

func (s *Server) sandboxActive() bool {
	return s.billing != nil && s.billing.sandbox != nil
}

func (s *Server) sandboxCheckoutPage(w http.ResponseWriter, r *http.Request) {
	if !s.sandboxActive() {
		http.NotFound(w, r)
		return
	}
	session, ok := s.billing.sandbox.Session(chi.URLParam(r, "sessionID"))
	if !ok {
		http.NotFound(w, r)
		return
	}
	if session.Status == "complete" {
		http.Redirect(w, r, session.SuccessURL, http.StatusSeeOther)
		return
	}
	s.renderSandboxCheckout(w, session, "")
}

func (s *Server) sandboxCheckoutSubmit(w http.ResponseWriter, r *http.Request) {
	if !s.sandboxActive() {
		http.NotFound(w, r)
		return
	}
	sessionID := chi.URLParam(r, "sessionID")
	session, ok := s.billing.sandbox.Session(sessionID)
	if !ok {
		http.NotFound(w, r)
		return
	}
	if err := r.ParseForm(); err != nil {
		s.renderSandboxCheckout(w, session, "The form could not be read.")
		return
	}
	if r.PostForm.Get("action") == "cancel" {
		http.Redirect(w, r, session.CancelURL, http.StatusSeeOther)
		return
	}
	month, _ := strconv.Atoi(strings.TrimSpace(r.PostForm.Get("exp_month")))
	year, _ := strconv.Atoi(strings.TrimSpace(r.PostForm.Get("exp_year")))
	if year > 0 && year < 100 {
		year += 2000
	}
	redirect, err := s.billing.sandbox.CompleteCheckout(sessionID, payments.SandboxCard{
		Number:   r.PostForm.Get("card_number"),
		ExpMonth: month,
		ExpYear:  year,
		CVC:      r.PostForm.Get("cvc"),
		Name:     r.PostForm.Get("name"),
	})
	if err != nil {
		session, _ = s.billing.sandbox.Session(sessionID)
		message := session.LastError
		if message == "" {
			message = err.Error()
		}
		if !errors.Is(err, payments.ErrCardDeclined) && redirect != "" {
			// The charge settled but a downstream write failed; the webhook
			// ledger keeps the event and the app will see it on retry.
			s.log.Error("sandbox_checkout_apply_failed", zap.Error(err))
			http.Redirect(w, r, redirect, http.StatusSeeOther)
			return
		}
		s.renderSandboxCheckout(w, session, message)
		return
	}
	http.Redirect(w, r, redirect, http.StatusSeeOther)
}

func (s *Server) renderSandboxCheckout(w http.ResponseWriter, session payments.SandboxSession, message string) {
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.Header().Set("Cache-Control", "no-store")
	_ = sandboxCheckoutTemplate.Execute(w, map[string]any{
		"Session":  session,
		"Amount":   fmt.Sprintf("%s %.2f", session.Currency, float64(session.AmountMinor)/100),
		"Interval": map[string]string{"monthly": "month", "yearly": "year"}[session.BillingCycle],
		"Error":    message,
		"Year":     time.Now().Year() + 4,
	})
}

// sandboxSimulate lets QA move the renewal clock: `renewal_paid`,
// `renewal_failed`, `period_end` (honours cancel-at-period-end) and `refund`.
// Owner-only and never available with a real provider.
func (s *Server) sandboxSimulate(w http.ResponseWriter, r *http.Request) {
	if !s.sandboxActive() || s.billing.repo == nil {
		http.NotFound(w, r)
		return
	}
	userID := s.requestUserID(r, chi.URLParam(r, "userID"))
	if userID != strings.TrimSpace(chi.URLParam(r, "userID")) {
		writeError(w, http.StatusForbidden, errors.New("resource does not belong to the authenticated user"))
		return
	}
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	live, err := s.billing.repo.liveSubscriptionRow(ctx, nil, userID)
	if err != nil || live.Provider != "sandbox" {
		writeError(w, http.StatusNotFound, errors.New("no sandbox subscription to simulate"))
		return
	}
	run := func() error {
		switch strings.ToLower(toString(payload["event"])) {
		case "renewal_paid", "period_end":
			return s.billing.sandbox.AdvancePeriod(live.ProviderSubscriptionID, false)
		case "renewal_failed":
			return s.billing.sandbox.AdvancePeriod(live.ProviderSubscriptionID, true)
		case "dispute_open":
			err := s.billing.sandbox.OpenDispute(live.ProviderSubscriptionID, "", "", 0)
			if errors.Is(err, payments.ErrNotFound) {
				if pays, lerr := s.billing.repo.listPayments(ctx, userID, 50); lerr == nil {
					for _, p := range pays {
						if p.Status == "success" && p.Provider == "sandbox" && p.ProviderPaymentID != "" {
							return s.billing.sandbox.OpenDispute(live.ProviderSubscriptionID, "", p.ProviderPaymentID, p.AmountMinor)
						}
					}
				}
			}
			return err
		case "dispute_won":
			return s.billing.sandbox.CloseDispute(live.ProviderSubscriptionID, true)
		case "dispute_lost":
			return s.billing.sandbox.CloseDispute(live.ProviderSubscriptionID, false)
		case "refund":
			// Refund the newest settled payment in the ledger, as an operator
			// would in the provider dashboard; disputed or charged-back
			// payments cannot be refunded.
			pays, lerr := s.billing.repo.listPayments(ctx, userID, 50)
			if lerr != nil {
				return lerr
			}
			for _, p := range pays {
				if p.Status == "success" && p.Provider == "sandbox" && p.ProviderPaymentID != "" {
					return s.billing.sandbox.RefundCharge(live.ProviderSubscriptionID, "", p.ProviderPaymentID, p.AmountMinor)
				}
			}
			return errors.New("no settled payment to refund")
		default:
			return errBadSimulateEvent
		}
	}
	err = run()
	if errors.Is(err, payments.ErrNotFound) && s.billing.rehydrateSandbox(live) {
		err = run()
	}
	if errors.Is(err, errBadSimulateEvent) {
		writeError(w, http.StatusBadRequest, errBadSimulateEvent)
		return
	}
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	sub, err := s.billing.repo.getSubscriptionWithGrace(ctx, userID, s.billing.graceWindow())
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	payments, _ := s.billing.repo.listPayments(ctx, userID, 20)
	writeJSON(w, http.StatusOK, map[string]any{"success": true, "subscription": sub, "payments": payments})
}

var returnPageTemplate = template.Must(template.New("return").Parse(`<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>{{.Title}}</title>
<style>
body{margin:0;min-height:100vh;display:flex;align-items:center;justify-content:center;background:radial-gradient(circle at 50% 120%,#3a1626 0%,#0e0a14 60%);color:#fbf4f7;font-family:-apple-system,Segoe UI,Roboto,sans-serif}
.card{max-width:360px;margin:24px;padding:32px 28px;border-radius:24px;background:rgba(28,20,38,.92);box-shadow:0 24px 60px rgba(184,20,63,.25);text-align:center}
.mark{width:64px;height:64px;border-radius:50%;margin:0 auto 20px;display:flex;align-items:center;justify-content:center;font-size:32px;background:{{if .Success}}linear-gradient(135deg,#b8143f,#ff5c7a){{else}}#34263f{{end}}}
h1{font-family:Georgia,'Bodoni Moda',serif;font-weight:600;font-size:28px;margin:0 0 12px}
p{color:#cdbfd3;line-height:1.5;margin:0}
</style></head><body><div class="card"><div class="mark">{{if .Success}}✓{{else}}↩{{end}}</div><h1>{{.Title}}</h1><p>{{.Body}}</p></div></body></html>`))

var sandboxCheckoutTemplate = template.Must(template.New("sandbox").Parse(`<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Sandbox checkout · {{.Session.PlanName}}</title>
<style>
:root{--ember:#b8143f;--ember-bright:#ff5c7a;--violet:#6d3fd6;--gold:#f5a623;--ink:#fbf4f7;--muted:#cdbfd3;--paper:#1c1426}
*{box-sizing:border-box}
body{margin:0;min-height:100vh;background:radial-gradient(circle at 20% -10%,#2a1d45 0%,transparent 45%),radial-gradient(circle at 80% 110%,#3a1626 0%,#0e0a14 55%);color:var(--ink);font-family:-apple-system,Segoe UI,Roboto,sans-serif}
.wrap{max-width:420px;margin:0 auto;padding:24px 16px 40px}
.badge{display:inline-block;padding:4px 10px;border-radius:999px;background:rgba(245,166,35,.16);color:var(--gold);font-size:12px;letter-spacing:.08em;text-transform:uppercase;font-weight:700}
h1{font-family:Georgia,'Bodoni Moda',serif;font-weight:600;font-size:30px;margin:12px 0 4px}
.price{font-size:22px;font-weight:800;color:var(--ember-bright)}
.price small{font-size:13px;color:var(--muted);font-weight:500}
.card{margin-top:20px;padding:20px;border-radius:22px;background:rgba(28,20,38,.94);border:1px solid rgba(255,255,255,.06);box-shadow:0 24px 60px rgba(184,20,63,.22)}
label{display:block;font-size:12px;color:var(--muted);margin:14px 0 6px;letter-spacing:.04em}
input{width:100%;padding:14px;border-radius:14px;border:1px solid #34263f;background:#150e1e;color:var(--ink);font-size:16px}
input:focus{outline:2px solid var(--violet);border-color:transparent}
.row{display:flex;gap:10px}.row>div{flex:1}
button{width:100%;margin-top:22px;padding:16px;border:0;border-radius:16px;font-size:16px;font-weight:800;color:#fff;background:linear-gradient(90deg,var(--ember),var(--ember-bright));box-shadow:0 12px 30px rgba(184,20,63,.35)}
button.secondary{background:transparent;color:var(--muted);box-shadow:none;margin-top:8px;font-weight:600}
.error{margin-top:14px;padding:12px 14px;border-radius:12px;background:rgba(212,56,28,.16);color:#ff7a5c;font-size:14px}
.note{margin-top:18px;font-size:12px;color:var(--muted);line-height:1.5}
.note code{color:var(--gold)}
</style></head><body><div class="wrap">
<span class="badge">Sandbox · no real charge</span>
<h1>{{.Session.PlanName}}</h1>
<div class="price">{{.Amount}} <small>/ {{.Interval}}, renews automatically</small></div>
<form class="card" method="post" autocomplete="off">
  <label for="name">Name on card</label>
  <input id="name" name="name" placeholder="Priya Sharma" value="Test Member">
  <label for="card_number">Card number</label>
  <input id="card_number" name="card_number" inputmode="numeric" placeholder="4242 4242 4242 4242" value="4242 4242 4242 4242">
  <div class="row">
    <div><label for="exp_month">Month</label><input id="exp_month" name="exp_month" inputmode="numeric" placeholder="MM" value="12"></div>
    <div><label for="exp_year">Year</label><input id="exp_year" name="exp_year" inputmode="numeric" placeholder="YYYY" value="{{.Year}}"></div>
    <div><label for="cvc">CVC</label><input id="cvc" name="cvc" inputmode="numeric" placeholder="123" value="123"></div>
  </div>
  {{if .Error}}<div class="error">{{.Error}}</div>{{end}}
  <button type="submit" name="action" value="pay">Pay {{.Amount}} and subscribe</button>
  <button type="submit" name="action" value="cancel" class="secondary" formnovalidate>Cancel</button>
  <p class="note">Test cards: <code>4242 4242 4242 4242</code> succeeds, <code>4000 0000 0000 0002</code> is declined, <code>4000 0000 0000 0341</code> succeeds now but fails at renewal.</p>
</form>
</div></body></html>`))
