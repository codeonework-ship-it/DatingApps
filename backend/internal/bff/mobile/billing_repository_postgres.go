package mobile

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"strings"
	"time"

	"github.com/verified-dating/backend/internal/platform/payments"
)

// billingRepository is the PostgreSQL persistence for plans, checkout
// sessions, subscriptions, payments and the webhook ledger.
//
// Subscription and payment state is written from two places only: the
// legacy local activation path (subscribe, gated off whenever a provider is
// configured) and applyEvent, which consumes verified provider webhooks.
// Nothing here trusts an amount or status supplied by the mobile client.
type billingRepository struct {
	db *sql.DB
}

var (
	errPlanNotFound        = errors.New("subscription plan not found")
	errCheckoutNotFound    = errors.New("checkout session not found")
	errSubscriptionMissing = errors.New("no active subscription")
	errSubscriptionOrphan  = errors.New("subscription cannot be mapped to a member")
	errPackageNotFound     = errors.New("coin package not found")
)

func newBillingRepository(db *sql.DB) *billingRepository {
	if db == nil {
		return nil
	}
	return &billingRepository{db: db}
}

// ── Plans ────────────────────────────────────────────────────────────────────

type billingPlanRow struct {
	ID               string
	Code             string
	Name             string
	MonthlyPrice     float64
	YearlyPrice      float64
	Currency         string
	IsActive         bool
	ProviderPriceIDs map[string]map[string]string
}

// amountMinor returns the plan price for a cycle in minor units (paise,
// cents). Prices are stored with two decimals so this is exact.
func (p billingPlanRow) amountMinor(billingCycle string) int64 {
	price := p.MonthlyPrice
	if billingCycle == "yearly" {
		price = p.YearlyPrice
	}
	return int64(math.Round(price * 100))
}

func (p billingPlanRow) providerPrice(provider, billingCycle string) string {
	if p.ProviderPriceIDs == nil {
		return ""
	}
	return strings.TrimSpace(p.ProviderPriceIDs[provider][billingCycle])
}

func (r *billingRepository) listPlans(ctx context.Context) ([]subscriptionPlan, error) {
	rows, err := r.db.QueryContext(ctx, `
		SELECT code, name, monthly_price::double precision, yearly_price::double precision,
		       likes_per_day, messages_per_day, features, is_active
		FROM matching.billing_plans
		WHERE is_active=TRUE
		ORDER BY sort_order, name`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	plans := make([]subscriptionPlan, 0)
	for rows.Next() {
		var plan subscriptionPlan
		var featuresJSON []byte
		if err := rows.Scan(
			&plan.ID,
			&plan.Name,
			&plan.MonthlyPrice,
			&plan.YearlyPrice,
			&plan.LikesPerDay,
			&plan.MessagesPerDay,
			&featuresJSON,
			&plan.IsActive,
		); err != nil {
			return nil, err
		}
		_ = json.Unmarshal(featuresJSON, &plan.Features)
		if plan.Features == nil {
			plan.Features = []string{}
		}
		plans = append(plans, plan)
	}
	return plans, rows.Err()
}

func (r *billingRepository) planByCode(ctx context.Context, code string) (billingPlanRow, error) {
	code = strings.ToLower(strings.TrimSpace(code))
	if code == "" {
		return billingPlanRow{}, errPlanNotFound
	}
	var plan billingPlanRow
	var priceIDs []byte
	err := r.db.QueryRowContext(ctx, `
		SELECT id::text, code, name, monthly_price::double precision, yearly_price::double precision,
		       currency, is_active, provider_price_ids
		FROM matching.billing_plans
		WHERE code=$1 OR id::text=$1
		LIMIT 1`, code).Scan(&plan.ID, &plan.Code, &plan.Name, &plan.MonthlyPrice, &plan.YearlyPrice, &plan.Currency, &plan.IsActive, &priceIDs)
	if errors.Is(err, sql.ErrNoRows) {
		return billingPlanRow{}, errPlanNotFound
	}
	if err != nil {
		return billingPlanRow{}, err
	}
	_ = json.Unmarshal(priceIDs, &plan.ProviderPriceIDs)
	return plan, nil
}

// ── Coin packages ────────────────────────────────────────────────────────────

type coinPackageRow struct {
	ID           string  `json:"id"`
	Label        string  `json:"label"`
	CoinAmount   int     `json:"coin_amount"`
	Price        float64 `json:"price"`
	Currency     string  `json:"currency"`
	BonusPercent float64 `json:"bonus_percent"`
	Description  string  `json:"description"`
	IsActive     bool    `json:"is_active"`
	SortOrder    int     `json:"sort_order"`
}

func (p coinPackageRow) amountMinor() int64 { return int64(math.Round(p.Price * 100)) }

// totalCoins is the package amount plus its bonus.
func (p coinPackageRow) totalCoins() int {
	return p.CoinAmount + int(math.Round(float64(p.CoinAmount)*p.BonusPercent/100))
}

const coinPackageSelect = `SELECT id::text, label, coin_amount, price::double precision, currency,
	bonus_percent::double precision, COALESCE(description,''), is_active, sort_order FROM matching.coin_packages`

func scanCoinPackage(row interface{ Scan(...any) error }) (coinPackageRow, error) {
	var p coinPackageRow
	err := row.Scan(&p.ID, &p.Label, &p.CoinAmount, &p.Price, &p.Currency, &p.BonusPercent, &p.Description, &p.IsActive, &p.SortOrder)
	return p, err
}

func (r *billingRepository) listCoinPackages(ctx context.Context) ([]coinPackageRow, error) {
	rows, err := r.db.QueryContext(ctx, coinPackageSelect+` WHERE is_active=TRUE ORDER BY sort_order, coin_amount`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := make([]coinPackageRow, 0)
	for rows.Next() {
		p, err := scanCoinPackage(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, p)
	}
	return out, rows.Err()
}

func (r *billingRepository) coinPackageByID(ctx context.Context, id string) (coinPackageRow, error) {
	p, err := scanCoinPackage(r.db.QueryRowContext(ctx, coinPackageSelect+` WHERE id::text=$1`, strings.TrimSpace(id)))
	if errors.Is(err, sql.ErrNoRows) {
		return coinPackageRow{}, errPackageNotFound
	}
	return p, err
}

// ── Member views ─────────────────────────────────────────────────────────────

func freeSubscription(userID string, now time.Time) userSubscription {
	stamp := now.UTC().Format(time.RFC3339)
	return userSubscription{
		ID:              "sub-free-" + userID,
		UserID:          userID,
		PlanID:          "free",
		PlanName:        "Free",
		Status:          "active",
		BillingCycle:    "monthly",
		StartDate:       stamp,
		NextBillingDate: stamp,
		UpdatedAt:       stamp,
		Entitled:        true,
		Currency:        "INR",
	}
}

const subscriptionSelectColumns = `
	s.id::text, s.user_id::text, s.plan_code, COALESCE(p.name, ''), s.status, s.billing_cycle,
	s.start_date, s.end_date, s.next_billing_date, s.updated_at,
	s.provider, COALESCE(s.provider_subscription_id,''), s.auto_renew, s.cancel_at_period_end,
	s.cancelled_at, s.current_period_start, s.current_period_end,
	COALESCE(s.amount_minor,0), s.currency, COALESCE(s.payment_method_brand,''), COALESCE(s.payment_method_last4,'')`

func scanSubscription(row interface{ Scan(...any) error }) (userSubscription, error) {
	var sub userSubscription
	var startDate, updatedAt time.Time
	var endDate, nextBilling, cancelledAt, periodStart, periodEnd sql.NullTime
	if err := row.Scan(
		&sub.ID, &sub.UserID, &sub.PlanID, &sub.PlanName, &sub.Status, &sub.BillingCycle,
		&startDate, &endDate, &nextBilling, &updatedAt,
		&sub.Provider, &sub.ProviderSubscriptionID, &sub.AutoRenew, &sub.CancelAtPeriodEnd,
		&cancelledAt, &periodStart, &periodEnd,
		&sub.AmountMinor, &sub.Currency, &sub.CardBrand, &sub.CardLast4,
	); err != nil {
		return userSubscription{}, err
	}
	if sub.PlanName == "" {
		sub.PlanName = titlePlanName(sub.PlanID)
	}
	sub.StartDate = startDate.UTC().Format(time.RFC3339)
	sub.UpdatedAt = updatedAt.UTC().Format(time.RFC3339)
	sub.EndDate = nullTimeString(endDate)
	sub.NextBillingDate = nullTimeString(nextBilling)
	sub.CancelledAt = nullTimeString(cancelledAt)
	sub.CurrentPeriodStart = nullTimeString(periodStart)
	sub.CurrentPeriodEnd = nullTimeString(periodEnd)
	sub.IsPaid = sub.PlanID != "free" && sub.AmountMinor > 0
	return sub, nil
}

func nullTimeString(v sql.NullTime) string {
	if !v.Valid {
		return ""
	}
	return v.Time.UTC().Format(time.RFC3339)
}

// getSubscription returns the member's live subscription or the synthetic
// free tier. Entitlement follows the settled provider state: active is
// entitled; past_due stays entitled during the grace window so a failed
// renewal does not cut access before the card can be retried.
func (r *billingRepository) getSubscription(ctx context.Context, userID string) (userSubscription, error) {
	return r.getSubscriptionWithGrace(ctx, userID, 7*24*time.Hour)
}

func (r *billingRepository) getSubscriptionWithGrace(ctx context.Context, userID string, grace time.Duration) (userSubscription, error) {
	userID = strings.TrimSpace(userID)
	if userID == "" {
		return userSubscription{}, errors.New("user_id is required")
	}
	sub, err := scanSubscription(r.db.QueryRowContext(ctx, `
		SELECT `+subscriptionSelectColumns+`
		FROM matching.billing_subscriptions_runtime s
		LEFT JOIN matching.billing_plans p ON p.code = s.plan_code
		WHERE s.user_id=$1 AND s.status IN ('incomplete','active','past_due')
		ORDER BY s.updated_at DESC
		LIMIT 1`, userID))
	if errors.Is(err, sql.ErrNoRows) {
		return freeSubscription(userID, time.Now()), nil
	}
	if err != nil {
		return userSubscription{}, err
	}
	now := time.Now().UTC()
	switch sub.Status {
	case payments.StatusActive:
		sub.Entitled = true
	case payments.StatusPastDue:
		if end, err := time.Parse(time.RFC3339, sub.CurrentPeriodEnd); err == nil {
			sub.Entitled = end.Add(grace).After(now)
		}
	}
	return sub, nil
}

func (r *billingRepository) liveSubscriptionRow(ctx context.Context, tx *sql.Tx, userID string) (userSubscription, error) {
	query := `
		SELECT ` + subscriptionSelectColumns + `
		FROM matching.billing_subscriptions_runtime s
		LEFT JOIN matching.billing_plans p ON p.code = s.plan_code
		WHERE s.user_id=$1 AND s.status IN ('incomplete','active','past_due')
		ORDER BY s.updated_at DESC
		LIMIT 1`
	var row interface{ Scan(...any) error }
	if tx != nil {
		row = tx.QueryRowContext(ctx, query, userID)
	} else {
		row = r.db.QueryRowContext(ctx, query, userID)
	}
	sub, err := scanSubscription(row)
	if errors.Is(err, sql.ErrNoRows) {
		return userSubscription{}, errSubscriptionMissing
	}
	return sub, err
}

// subscribe is the legacy local activation. It records an active
// subscription and a "success" payment without any provider. It stays only
// for environments with no payment provider and is refused by the handler
// whenever one is configured.
func (r *billingRepository) subscribe(ctx context.Context, userID, planID, billingCycle string) (userSubscription, paymentRecord, error) {
	userID = strings.TrimSpace(userID)
	planID = strings.ToLower(strings.TrimSpace(planID))
	billingCycle = strings.ToLower(strings.TrimSpace(billingCycle))
	if userID == "" || planID == "" {
		return userSubscription{}, paymentRecord{}, errors.New("user_id and plan_id are required")
	}
	if billingCycle == "" {
		billingCycle = "monthly"
	}
	if billingCycle != "monthly" && billingCycle != "yearly" {
		return userSubscription{}, paymentRecord{}, errors.New("billing_cycle must be monthly or yearly")
	}
	plan, err := r.planByCode(ctx, planID)
	if err != nil {
		return userSubscription{}, paymentRecord{}, err
	}
	if !plan.IsActive {
		return userSubscription{}, paymentRecord{}, errPlanNotFound
	}

	tx, err := r.db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		return userSubscription{}, paymentRecord{}, err
	}
	defer func() { _ = tx.Rollback() }()

	now := time.Now().UTC()
	next := now.AddDate(0, 1, 0)
	if billingCycle == "yearly" {
		next = now.AddDate(1, 0, 0)
	}
	amountMinor := plan.amountMinor(billingCycle)
	if err := supersedeLiveSubscriptions(ctx, tx, userID, now); err != nil {
		return userSubscription{}, paymentRecord{}, err
	}

	var subID string
	err = tx.QueryRowContext(ctx, `
		INSERT INTO matching.billing_subscriptions_runtime
		  (user_id, plan_code, status, billing_cycle, start_date, next_billing_date,
		   auto_renew, provider, provider_subscription_id, current_period_start, current_period_end,
		   amount_minor, currency, created_at, updated_at)
		VALUES ($1,$2,'active',$3,$4,$5,TRUE,'local',$6,$4,$5,$7,$8,$4,$4)
		RETURNING id::text`, userID, plan.Code, billingCycle, now, next, "local-pgx-"+newGroupUUID(), amountMinor, plan.Currency).Scan(&subID)
	if err != nil {
		return userSubscription{}, paymentRecord{}, err
	}

	var paymentID string
	err = tx.QueryRowContext(ctx, `
		INSERT INTO matching.billing_payments_runtime
		  (user_id, subscription_id, amount_paise, currency, status, provider,
		   provider_payment_id, paid_at, created_at, updated_at, billing_reason, period_start, period_end, metadata)
		VALUES ($1,$2,$3,$4,'success','local',$5,$6,$6,$6,'local_activation',$6,$7,$8::jsonb)
		RETURNING id::text`, userID, subID, amountMinor, plan.Currency, "local-pgx-"+newGroupUUID(), now, next,
		fmt.Sprintf(`{"plan_code":%q,"billing_cycle":%q}`, plan.Code, billingCycle),
	).Scan(&paymentID)
	if err != nil {
		return userSubscription{}, paymentRecord{}, err
	}
	if err := tx.Commit(); err != nil {
		return userSubscription{}, paymentRecord{}, err
	}

	sub := userSubscription{
		ID: subID, UserID: userID, PlanID: plan.Code, PlanName: plan.Name, Status: "active",
		BillingCycle: billingCycle, StartDate: now.Format(time.RFC3339), NextBillingDate: next.Format(time.RFC3339),
		UpdatedAt: now.Format(time.RFC3339), Provider: "local", IsPaid: amountMinor > 0, Entitled: true, AutoRenew: true,
		CurrentPeriodStart: now.Format(time.RFC3339), CurrentPeriodEnd: next.Format(time.RFC3339),
		AmountMinor: amountMinor, Currency: plan.Currency,
	}
	payment := paymentRecord{
		ID: paymentID, UserID: userID, PlanID: plan.Code, Amount: float64(amountMinor) / 100, AmountMinor: amountMinor,
		Currency: plan.Currency, Status: "success", PaymentMethod: "local_postgres", Provider: "local",
		CreatedAt: now.Format(time.RFC3339), PaidAt: now.Format(time.RFC3339), BillingReason: "local_activation",
	}
	return sub, payment, nil
}

func (r *billingRepository) listPayments(ctx context.Context, userID string, limit int) ([]paymentRecord, error) {
	userID = strings.TrimSpace(userID)
	if userID == "" {
		return nil, errors.New("user_id is required")
	}
	if limit <= 0 || limit > 500 {
		limit = 100
	}
	rows, err := r.db.QueryContext(ctx, `
		SELECT p.id::text, p.user_id::text, COALESCE(s.plan_code,'unknown'),
		       p.amount_paise, p.currency, p.status, p.provider,
		       COALESCE(p.provider_payment_id,''), COALESCE(p.billing_reason,''),
		       p.period_start, p.period_end, COALESCE(p.payment_method_brand,''), COALESCE(p.payment_method_last4,''),
		       p.refunded_amount_paise, COALESCE(p.failure_reason,''), p.paid_at, p.created_at,
		       COALESCE(p.dispute_status,''), COALESCE(p.dispute_reason,'')
		FROM matching.billing_payments_runtime p
		LEFT JOIN matching.billing_subscriptions_runtime s ON s.id=p.subscription_id
		WHERE p.user_id=$1
		ORDER BY p.created_at DESC
		LIMIT $2`, userID, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := make([]paymentRecord, 0)
	for rows.Next() {
		var p paymentRecord
		var createdAt time.Time
		var periodStart, periodEnd, paidAt sql.NullTime
		var refunded int64
		if err := rows.Scan(
			&p.ID, &p.UserID, &p.PlanID, &p.AmountMinor, &p.Currency, &p.Status, &p.Provider,
			&p.ProviderPaymentID, &p.BillingReason, &periodStart, &periodEnd, &p.CardBrand, &p.CardLast4,
			&refunded, &p.FailureReason, &paidAt, &createdAt, &p.DisputeStatus, &p.DisputeReason,
		); err != nil {
			return nil, err
		}
		p.Amount = float64(p.AmountMinor) / 100
		p.RefundedAmount = float64(refunded) / 100
		p.PeriodStart = nullTimeString(periodStart)
		p.PeriodEnd = nullTimeString(periodEnd)
		p.PaidAt = nullTimeString(paidAt)
		p.CreatedAt = createdAt.UTC().Format(time.RFC3339)
		switch {
		case p.CardBrand != "":
			p.PaymentMethod = "card"
		case p.Provider == "local":
			p.PaymentMethod = "local_postgres"
		default:
			p.PaymentMethod = p.Provider
		}
		out = append(out, p)
	}
	return out, rows.Err()
}

// ── Provider customers ───────────────────────────────────────────────────────

func (r *billingRepository) providerCustomer(ctx context.Context, userID, provider string) (string, error) {
	var id string
	err := r.db.QueryRowContext(ctx, `
		SELECT provider_customer_id FROM matching.billing_provider_customers
		WHERE user_id=$1 AND provider=$2`, userID, provider).Scan(&id)
	if errors.Is(err, sql.ErrNoRows) {
		return "", nil
	}
	return id, err
}

func (r *billingRepository) saveProviderCustomer(ctx context.Context, userID, provider, customerID string) error {
	_, err := r.db.ExecContext(ctx, `
		INSERT INTO matching.billing_provider_customers (user_id, provider, provider_customer_id)
		VALUES ($1,$2,$3)
		ON CONFLICT (user_id, provider) DO UPDATE SET provider_customer_id=EXCLUDED.provider_customer_id`,
		userID, provider, customerID)
	return err
}

func (r *billingRepository) memberContact(ctx context.Context, userID string) (email, name string, err error) {
	var e, n sql.NullString
	err = r.db.QueryRowContext(ctx, `SELECT email, name FROM user_management.users WHERE id=$1`, userID).Scan(&e, &n)
	if errors.Is(err, sql.ErrNoRows) {
		return "", "", errors.New("member not found")
	}
	return e.String, n.String, err
}

// ── Checkout sessions ────────────────────────────────────────────────────────

type billingCheckoutRow struct {
	ID                string    `json:"id"`
	UserID            string    `json:"user_id"`
	Kind              string    `json:"kind"`
	PlanCode          string    `json:"plan_code,omitempty"`
	BillingCycle      string    `json:"billing_cycle,omitempty"`
	PackageID         string    `json:"package_id,omitempty"`
	Coins             int       `json:"coins,omitempty"`
	SubscriptionRef   string    `json:"subscription_ref,omitempty"`
	Provider          string    `json:"provider"`
	ProviderSessionID string    `json:"provider_session_id,omitempty"`
	Status            string    `json:"status"`
	AmountMinor       int64     `json:"amount_minor"`
	Currency          string    `json:"currency"`
	CheckoutURL       string    `json:"checkout_url,omitempty"`
	SubscriptionID    string    `json:"subscription_id,omitempty"`
	CreatedAt         time.Time `json:"created_at"`
	ExpiresAt         string    `json:"expires_at,omitempty"`
	CompletedAt       string    `json:"completed_at,omitempty"`
}

const checkoutSelectColumns = `
	id::text, user_id::text, kind, COALESCE(plan_code,''), COALESCE(billing_cycle,''), COALESCE(package_id,''), COALESCE(coins,0),
	COALESCE(subscription_ref,''), provider, COALESCE(provider_session_id,''),
	status, amount_minor, currency, COALESCE(checkout_url,''), COALESCE(subscription_id::text,''),
	created_at, expires_at, completed_at`

func scanCheckout(row interface{ Scan(...any) error }) (billingCheckoutRow, error) {
	var c billingCheckoutRow
	var expires, completed sql.NullTime
	if err := row.Scan(&c.ID, &c.UserID, &c.Kind, &c.PlanCode, &c.BillingCycle, &c.PackageID, &c.Coins, &c.SubscriptionRef, &c.Provider, &c.ProviderSessionID,
		&c.Status, &c.AmountMinor, &c.Currency, &c.CheckoutURL, &c.SubscriptionID, &c.CreatedAt, &expires, &completed); err != nil {
		return billingCheckoutRow{}, err
	}
	c.CreatedAt = c.CreatedAt.UTC()
	c.ExpiresAt = nullTimeString(expires)
	c.CompletedAt = nullTimeString(completed)
	return c, nil
}

func (r *billingRepository) checkoutByIdempotency(ctx context.Context, userID, key string) (billingCheckoutRow, bool, error) {
	if strings.TrimSpace(key) == "" {
		return billingCheckoutRow{}, false, nil
	}
	c, err := scanCheckout(r.db.QueryRowContext(ctx, `
		SELECT `+checkoutSelectColumns+` FROM matching.billing_checkout_sessions
		WHERE user_id=$1 AND idempotency_key=$2`, userID, key))
	if errors.Is(err, sql.ErrNoRows) {
		return billingCheckoutRow{}, false, nil
	}
	return c, err == nil, err
}

func (r *billingRepository) checkoutByProviderSession(ctx context.Context, provider, sessionID string) (billingCheckoutRow, error) {
	c, err := scanCheckout(r.db.QueryRowContext(ctx, `
		SELECT `+checkoutSelectColumns+` FROM matching.billing_checkout_sessions WHERE provider=$1 AND provider_session_id=$2`, provider, strings.TrimSpace(sessionID)))
	if errors.Is(err, sql.ErrNoRows) {
		return billingCheckoutRow{}, errCheckoutNotFound
	}
	return c, err
}

func (r *billingRepository) checkoutByID(ctx context.Context, id string) (billingCheckoutRow, error) {
	c, err := scanCheckout(r.db.QueryRowContext(ctx, `
		SELECT `+checkoutSelectColumns+` FROM matching.billing_checkout_sessions WHERE id::text=$1`, strings.TrimSpace(id)))
	if errors.Is(err, sql.ErrNoRows) {
		return billingCheckoutRow{}, errCheckoutNotFound
	}
	return c, err
}

func (r *billingRepository) insertCheckout(ctx context.Context, userID, planCode, billingCycle, provider, idempotencyKey string, amountMinor int64, currency string) (string, error) {
	var key any
	if strings.TrimSpace(idempotencyKey) != "" {
		key = idempotencyKey
	}
	var id string
	err := r.db.QueryRowContext(ctx, `
		INSERT INTO matching.billing_checkout_sessions
		  (user_id, kind, plan_code, billing_cycle, provider, idempotency_key, status, amount_minor, currency)
		VALUES ($1,'subscription',$2,$3,$4,$5,'open',$6,$7)
		RETURNING id::text`, userID, planCode, billingCycle, provider, key, amountMinor, currency).Scan(&id)
	return id, err
}

func (r *billingRepository) insertCoinCheckout(ctx context.Context, userID, packageID, provider, idempotencyKey string, coins int, amountMinor int64, currency string) (string, error) {
	var key any
	if strings.TrimSpace(idempotencyKey) != "" {
		key = idempotencyKey
	}
	var id string
	err := r.db.QueryRowContext(ctx, `
		INSERT INTO matching.billing_checkout_sessions
		  (user_id, kind, package_id, coins, provider, idempotency_key, status, amount_minor, currency)
		VALUES ($1,'coin_package',$2,$3,$4,$5,'open',$6,$7)
		RETURNING id::text`, userID, packageID, coins, provider, key, amountMinor, currency).Scan(&id)
	return id, err
}

func (r *billingRepository) attachCheckoutSession(ctx context.Context, id, providerSessionID, url string, expiresAt time.Time) error {
	var expires any
	if !expiresAt.IsZero() {
		expires = expiresAt.UTC()
	}
	_, err := r.db.ExecContext(ctx, `
		UPDATE matching.billing_checkout_sessions
		SET provider_session_id=$2, checkout_url=$3, expires_at=$4
		WHERE id::text=$1`, id, providerSessionID, url, expires)
	return err
}

func (r *billingRepository) markCheckoutStatus(ctx context.Context, id, status string) error {
	_, err := r.db.ExecContext(ctx, `
		UPDATE matching.billing_checkout_sessions SET status=$2 WHERE id::text=$1 AND status='open'`, id, status)
	return err
}

func (r *billingRepository) insertCardUpdateCheckout(ctx context.Context, userID, subscriptionRef, provider, idempotencyKey string) (string, error) {
	var key any
	if strings.TrimSpace(idempotencyKey) != "" {
		key = idempotencyKey
	}
	var id string
	err := r.db.QueryRowContext(ctx, `
		INSERT INTO matching.billing_checkout_sessions
		  (user_id, kind, subscription_ref, provider, idempotency_key, status, amount_minor, currency)
		VALUES ($1,'card_update',$2,$3,$4,'open',0,'')
		RETURNING id::text`, userID, subscriptionRef, provider, key).Scan(&id)
	return id, err
}

// updateSubscriptionCard records a replacement card and clears any
// renewal failure the old card caused.
func (r *billingRepository) updateSubscriptionCard(ctx context.Context, subRowID string, card payments.CardSummary, now time.Time) error {
	_, err := r.db.ExecContext(ctx, `
		UPDATE matching.billing_subscriptions_runtime
		SET payment_method_brand=$2, payment_method_last4=$3, updated_at=$4, lock_version=lock_version+1
		WHERE id::text=$1`, subRowID, card.Brand, card.Last4, now)
	return err
}

// applyPlanChange mirrors an accepted plan switch locally; the provider's
// subscription.updated event confirms amount and period.
func (r *billingRepository) applyPlanChange(ctx context.Context, subRowID, planCode, billingCycle string, amountMinor int64, currency string, now time.Time) error {
	_, err := r.db.ExecContext(ctx, `
		UPDATE matching.billing_subscriptions_runtime
		SET previous_plan_code=plan_code, plan_code=$2, billing_cycle=$3, amount_minor=$4, currency=$5,
		    plan_changed_at=$6, updated_at=$6, lock_version=lock_version+1,
		    metadata = metadata || jsonb_build_object('plan_code',$2::text,'billing_cycle',$3::text)
		WHERE id::text=$1`, subRowID, planCode, billingCycle, amountMinor, currency, now)
	return err
}

// catalogCurrencyMismatch returns the plan and package rows priced in a
// currency other than the server's, so startup can refuse a mixed catalog.
func (r *billingRepository) catalogCurrencyMismatch(ctx context.Context, currency string) ([]string, error) {
	rows, err := r.db.QueryContext(ctx, `
		SELECT 'plan '||code||' ('||currency||')' FROM matching.billing_plans WHERE is_active AND UPPER(currency)<>$1
		UNION ALL
		SELECT 'coin package '||label||' ('||currency||')' FROM matching.coin_packages WHERE is_active AND UPPER(currency)<>$1`, strings.ToUpper(currency))
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []string
	for rows.Next() {
		var v string
		if err := rows.Scan(&v); err != nil {
			return nil, err
		}
		out = append(out, v)
	}
	return out, rows.Err()
}

// ── Webhook ledger ───────────────────────────────────────────────────────────

// beginWebhookEvent records a verified event. It returns false when the
// (provider, event_id) pair was already recorded, which is how retried and
// duplicated deliveries are made harmless.
func (r *billingRepository) beginWebhookEvent(ctx context.Context, ev payments.Event) (bool, error) {
	var created any
	if !ev.CreatedAt.IsZero() {
		created = ev.CreatedAt.UTC()
	}
	payload := ev.Raw
	if len(payload) == 0 {
		payload = json.RawMessage(`{}`)
	}
	res, err := r.db.ExecContext(ctx, `
		INSERT INTO matching.billing_webhook_events (provider, event_id, event_type, event_created_at, payload)
		VALUES ($1,$2,$3,$4,$5::jsonb)
		ON CONFLICT (provider, event_id) DO NOTHING`, ev.Provider, ev.ID, ev.RawType, created, []byte(payload))
	if err != nil {
		return false, err
	}
	n, err := res.RowsAffected()
	if err != nil {
		return false, err
	}
	return n == 1, nil
}

func (r *billingRepository) finishWebhookEvent(ctx context.Context, provider, eventID, status, errMsg string) error {
	var msg any
	if errMsg != "" {
		msg = errMsg
	}
	_, err := r.db.ExecContext(ctx, `
		UPDATE matching.billing_webhook_events
		SET status=$3, error=$4, processed_at=NOW()
		WHERE provider=$1 AND event_id=$2`, provider, eventID, status, msg)
	return err
}

// retryFailedWebhookEvent reopens a failed event so a later delivery of the
// same event id can be processed again.
func (r *billingRepository) retryFailedWebhookEvent(ctx context.Context, provider, eventID string) (bool, error) {
	res, err := r.db.ExecContext(ctx, `
		UPDATE matching.billing_webhook_events SET status='received', error=NULL
		WHERE provider=$1 AND event_id=$2 AND status='failed'`, provider, eventID)
	if err != nil {
		return false, err
	}
	n, _ := res.RowsAffected()
	return n == 1, nil
}

// ── Applying provider events ─────────────────────────────────────────────────

// applyEvent moves local billing state to what the provider reports. It is a
// single transaction per event so a crash between two writes cannot leave a
// paid invoice without its subscription. Ordering is guarded per
// subscription by last_provider_event_at: an older event arriving after a
// newer one cannot roll state backwards.
func (r *billingRepository) applyEvent(ctx context.Context, ev payments.Event, fetch func(context.Context, string) (payments.SubscriptionSnapshot, error)) error {
	tx, err := r.db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		return err
	}
	defer func() { _ = tx.Rollback() }()
	now := time.Now().UTC()

	switch ev.Type {
	case payments.EventCheckoutCompleted:
		if ev.Checkout == nil {
			return errors.New("checkout event has no payload")
		}
		checkout, found, err := checkoutForEvent(ctx, tx, ev.Provider, ev.Checkout.SessionID, ev.Checkout.Metadata["checkout_id"])
		if err != nil {
			return err
		}
		if ev.Checkout.Mode == "setup" || (found && checkout.Kind == "card_update") {
			if found {
				if _, err := tx.ExecContext(ctx, `
					UPDATE matching.billing_checkout_sessions
					SET status='completed', completed_at=COALESCE(completed_at,$2), provider_session_id=COALESCE(provider_session_id,$3),
					    metadata = metadata || jsonb_build_object('setup_intent_id',$4::text)
					WHERE id::text=$1`, checkout.ID, now, ev.Checkout.SessionID, ev.Checkout.SetupIntentID); err != nil {
					return err
				}
			}
			return tx.Commit()
		}
		if ev.Checkout.Mode == "payment" || (found && checkout.Kind == "coin_package") {
			if !found {
				return fmt.Errorf("payment checkout %s has no local session", ev.Checkout.SessionID)
			}
			if ev.Checkout.PaymentStatus != "" && ev.Checkout.PaymentStatus != "paid" && ev.Checkout.PaymentStatus != "no_payment_required" {
				// Not settled yet (e.g. delayed payment method); leave it open.
				return tx.Commit()
			}
			if err := recordCoinCheckoutPayment(ctx, tx, ev, checkout, now); err != nil {
				return err
			}
			return tx.Commit()
		}
		if ev.Checkout.SubscriptionID == "" {
			return errors.New("checkout completed without a subscription id")
		}
		snap, err := fetch(ctx, ev.Checkout.SubscriptionID)
		if err != nil {
			// Fall back to what the event carries; a later
			// customer.subscription.* event will complete the picture.
			snap = payments.SubscriptionSnapshot{
				SubscriptionID: ev.Checkout.SubscriptionID,
				CustomerID:     ev.Checkout.CustomerID,
				Status:         payments.StatusIncomplete,
				Metadata:       ev.Checkout.Metadata,
			}
		}
		if snap.Metadata == nil {
			snap.Metadata = map[string]string{}
		}
		if found {
			snap.Metadata["user_id"] = checkout.UserID
			if snap.Metadata["plan_code"] == "" {
				snap.Metadata["plan_code"] = checkout.PlanCode
			}
			if snap.Metadata["billing_cycle"] == "" {
				snap.Metadata["billing_cycle"] = checkout.BillingCycle
			}
			if snap.AmountMinor == 0 {
				snap.AmountMinor = checkout.AmountMinor
				snap.Currency = checkout.Currency
			}
		}
		if ev.Checkout.CustomerID != "" && snap.Metadata["user_id"] != "" {
			if _, err := tx.ExecContext(ctx, `
				INSERT INTO matching.billing_provider_customers (user_id, provider, provider_customer_id)
				VALUES ($1,$2,$3) ON CONFLICT (user_id, provider) DO UPDATE SET provider_customer_id=EXCLUDED.provider_customer_id`,
				snap.Metadata["user_id"], ev.Provider, ev.Checkout.CustomerID); err != nil {
				return err
			}
		}
		subID, err := upsertSubscription(ctx, tx, ev.Provider, snap, ev.CreatedAt, now)
		if err != nil {
			return err
		}
		if found {
			if _, err := tx.ExecContext(ctx, `
				UPDATE matching.billing_checkout_sessions
				SET status='completed', completed_at=COALESCE(completed_at,$3), subscription_id=$2::uuid,
				    provider_session_id=COALESCE(provider_session_id,$4)
				WHERE id::text=$1`, checkout.ID, subID, now, ev.Checkout.SessionID); err != nil {
				return err
			}
		}

	case payments.EventSubscriptionUpdated, payments.EventSubscriptionDeleted:
		if ev.Subscription == nil {
			return errors.New("subscription event has no payload")
		}
		if _, err := upsertSubscription(ctx, tx, ev.Provider, *ev.Subscription, ev.CreatedAt, now); err != nil {
			return err
		}

	case payments.EventInvoicePaid, payments.EventInvoicePaymentFailed:
		if ev.Invoice == nil {
			return errors.New("invoice event has no payload")
		}
		inv := ev.Invoice
		subRowID, userID, err := subscriptionRowByProviderID(ctx, tx, ev.Provider, inv.SubscriptionID)
		if errors.Is(err, sql.ErrNoRows) && inv.SubscriptionID != "" {
			// Invoice arrived before the subscription: create it from the
			// provider's current view so the payment has a home.
			snap, ferr := fetch(ctx, inv.SubscriptionID)
			if ferr != nil {
				snap = payments.SubscriptionSnapshot{SubscriptionID: inv.SubscriptionID, CustomerID: inv.CustomerID, Status: payments.StatusIncomplete, Metadata: inv.Metadata, CurrentPeriodStart: inv.PeriodStart, CurrentPeriodEnd: inv.PeriodEnd, AmountMinor: inv.AmountMinor, Currency: inv.Currency}
			}
			if snap.Metadata == nil {
				snap.Metadata = inv.Metadata
			}
			if _, err := upsertSubscription(ctx, tx, ev.Provider, snap, ev.CreatedAt, now); err != nil {
				return err
			}
			subRowID, userID, err = subscriptionRowByProviderID(ctx, tx, ev.Provider, inv.SubscriptionID)
		}
		if err != nil {
			if errors.Is(err, sql.ErrNoRows) {
				return fmt.Errorf("%w: invoice %s", errSubscriptionOrphan, inv.InvoiceID)
			}
			return err
		}
		if err := upsertInvoicePayment(ctx, tx, ev, subRowID, userID, now); err != nil {
			return err
		}
		if err := applyInvoiceToSubscription(ctx, tx, ev, subRowID, now); err != nil {
			return err
		}

	case payments.EventChargeRefunded:
		if ev.Refund == nil {
			return errors.New("refund event has no payload")
		}
		ref := ev.Refund
		status := "partially_refunded"
		if ref.FullyRefunded {
			status = "refunded"
		}
		res, err := tx.ExecContext(ctx, `
			UPDATE matching.billing_payments_runtime
			SET status=$3, refunded_amount_paise=LEAST(amount_paise, GREATEST(refunded_amount_paise,$4)), updated_at=$5,
			    provider_event_id=$6
			WHERE provider=$1 AND (provider_payment_id=$2 OR provider_charge_id=$7) AND status<>'chargeback'`,
			ev.Provider, ref.PaymentIntentID, status, ref.AmountRefunded, now, ev.ID, ref.ChargeID)
		if err != nil {
			return err
		}
		if n, _ := res.RowsAffected(); n == 0 {
			return fmt.Errorf("refund for unknown charge %s/%s", ref.PaymentIntentID, ref.ChargeID)
		}
		// A refunded coin purchase takes its coins back (migration 084).
		if err := reverseCoinPurchasePaymentsTx(ctx, tx, ev.Provider, ref.PaymentIntentID, ref.ChargeID, ev.ID, now); err != nil {
			return fmt.Errorf("reverse refunded coins: %w", err)
		}

	case payments.EventDisputeUpdated:
		if ev.Dispute == nil {
			return errors.New("dispute event has no payload")
		}
		d := ev.Dispute
		status := "disputed"
		var closedAt any
		if d.Closed {
			closedAt = now
			switch d.Status {
			case "lost", "charge_refunded":
				status = "chargeback"
			default:
				// won / warning_closed: the charge stands.
				status = "success"
			}
		}
		res, err := tx.ExecContext(ctx, `
			UPDATE matching.billing_payments_runtime
			SET status=CASE WHEN status IN ('refunded','partially_refunded') AND $3<>'chargeback' THEN status ELSE $3 END,
			    dispute_id=$4, dispute_status=$5, dispute_reason=$6,
			    disputed_at=COALESCE(disputed_at,$7), dispute_closed_at=$8, provider_event_id=$9, updated_at=$7
			WHERE provider=$1 AND (provider_payment_id=$2 OR provider_charge_id=$10)`,
			ev.Provider, d.PaymentIntentID, status, d.DisputeID, d.Status, d.Reason, now, closedAt, ev.ID, d.ChargeID)
		if err != nil {
			return err
		}
		if n, _ := res.RowsAffected(); n == 0 {
			return fmt.Errorf("dispute for unknown charge %s/%s", d.PaymentIntentID, d.ChargeID)
		}
		if status == "chargeback" {
			// A lost dispute takes coins back and ends the subscription it
			// paid for at once; renewal is stopped at the provider after commit.
			if err := reverseCoinPurchasePaymentsTx(ctx, tx, ev.Provider, d.PaymentIntentID, d.ChargeID, ev.ID, now); err != nil {
				return fmt.Errorf("reverse charged-back coins: %w", err)
			}
			if _, err := endSubscriptionsForChargebackTx(ctx, tx, ev.Provider, d.PaymentIntentID, d.ChargeID, now); err != nil {
				return fmt.Errorf("end charged-back subscription: %w", err)
			}
		}
	default:
		// Ignored event types are recorded by the ledger but change nothing.
	}
	return tx.Commit()
}

// recordCoinCheckoutPayment settles a coin-package checkout: a payment row
// keyed on the checkout session (so a replay lands once) and the checkout
// marked completed. The wallet credit itself happens after commit through
// the wallet ledger's own idempotency, see billingCheckoutService.
func recordCoinCheckoutPayment(ctx context.Context, tx *sql.Tx, ev payments.Event, checkout billingCheckoutRow, now time.Time) error {
	amount := ev.Checkout.AmountMinor
	if amount <= 0 {
		amount = checkout.AmountMinor
	}
	currency := strings.ToUpper(ev.Checkout.Currency)
	if currency == "" {
		currency = checkout.Currency
	}
	var brand, last4, intent any
	if ev.Checkout.Card != nil {
		brand, last4 = ev.Checkout.Card.Brand, ev.Checkout.Card.Last4
	}
	if ev.Checkout.PaymentIntentID != "" {
		intent = ev.Checkout.PaymentIntentID
	}
	metadata, _ := json.Marshal(map[string]any{"package_id": checkout.PackageID, "coins": checkout.Coins, "event_type": ev.RawType})
	if _, err := tx.ExecContext(ctx, `
		INSERT INTO matching.billing_payments_runtime
		  (user_id, checkout_id, amount_paise, currency, status, provider, provider_payment_id, provider_invoice_id,
		   provider_event_id, billing_reason, payment_method_brand, payment_method_last4, paid_at, created_at, updated_at, metadata)
		VALUES ($1,$2::uuid,$3,$4,'success',$5,$6,$7,$8,'coin_purchase',$9,$10,$11,$12,$12,$13::jsonb)
		ON CONFLICT (provider, provider_invoice_id) WHERE provider_invoice_id IS NOT NULL DO UPDATE
		SET provider_payment_id=COALESCE(EXCLUDED.provider_payment_id, matching.billing_payments_runtime.provider_payment_id),
		    provider_event_id=EXCLUDED.provider_event_id, updated_at=EXCLUDED.updated_at`,
		checkout.UserID, checkout.ID, amount, currency, ev.Provider, intent, "cs:"+ev.Checkout.SessionID,
		ev.ID, brand, last4, ev.CreatedAt.UTC(), now, metadata); err != nil {
		return err
	}
	_, err := tx.ExecContext(ctx, `
		UPDATE matching.billing_checkout_sessions
		SET status='completed', completed_at=COALESCE(completed_at,$2), provider_payment_id=COALESCE($3, provider_payment_id),
		    provider_session_id=COALESCE(provider_session_id,$4)
		WHERE id::text=$1`, checkout.ID, now, intent, ev.Checkout.SessionID)
	return err
}

func checkoutForEvent(ctx context.Context, tx *sql.Tx, provider, providerSessionID, checkoutID string) (billingCheckoutRow, bool, error) {
	if providerSessionID != "" {
		c, err := scanCheckout(tx.QueryRowContext(ctx, `
			SELECT `+checkoutSelectColumns+` FROM matching.billing_checkout_sessions
			WHERE provider=$1 AND provider_session_id=$2`, provider, providerSessionID))
		if err == nil {
			return c, true, nil
		}
		if !errors.Is(err, sql.ErrNoRows) {
			return billingCheckoutRow{}, false, err
		}
	}
	if checkoutID != "" {
		c, err := scanCheckout(tx.QueryRowContext(ctx, `
			SELECT `+checkoutSelectColumns+` FROM matching.billing_checkout_sessions WHERE id::text=$1`, checkoutID))
		if err == nil {
			return c, true, nil
		}
		if !errors.Is(err, sql.ErrNoRows) {
			return billingCheckoutRow{}, false, err
		}
	}
	return billingCheckoutRow{}, false, nil
}

func subscriptionRowByProviderID(ctx context.Context, tx *sql.Tx, provider, providerSubscriptionID string) (rowID, userID string, err error) {
	if strings.TrimSpace(providerSubscriptionID) == "" {
		return "", "", sql.ErrNoRows
	}
	err = tx.QueryRowContext(ctx, `
		SELECT id::text, user_id::text FROM matching.billing_subscriptions_runtime
		WHERE provider=$1 AND provider_subscription_id=$2`, provider, providerSubscriptionID).Scan(&rowID, &userID)
	return rowID, userID, err
}

func supersedeLiveSubscriptions(ctx context.Context, tx *sql.Tx, userID string, now time.Time) error {
	_, err := tx.ExecContext(ctx, `
		UPDATE matching.billing_subscriptions_runtime
		SET status='cancelled', end_date=COALESCE(end_date,$2), cancelled_at=COALESCE(cancelled_at,$2),
		    auto_renew=FALSE, updated_at=$2, lock_version=lock_version+1
		WHERE user_id=$1 AND status IN ('incomplete','active','past_due')`, userID, now)
	return err
}

func metadataCycle(snap payments.SubscriptionSnapshot) string {
	if cycle := strings.ToLower(snap.Metadata["billing_cycle"]); cycle == "monthly" || cycle == "yearly" {
		return cycle
	}
	return ""
}

func cycleFromSnapshot(snap payments.SubscriptionSnapshot) string {
	if cycle := strings.ToLower(snap.Metadata["billing_cycle"]); cycle == "monthly" || cycle == "yearly" {
		return cycle
	}
	if snap.Interval == "year" {
		return "yearly"
	}
	return "monthly"
}

// upsertSubscription creates or updates the local row for one provider
// subscription and returns the row id.
func upsertSubscription(ctx context.Context, tx *sql.Tx, provider string, snap payments.SubscriptionSnapshot, eventAt, now time.Time) (string, error) {
	if strings.TrimSpace(snap.SubscriptionID) == "" {
		return "", errors.New("subscription snapshot has no provider id")
	}
	if eventAt.IsZero() {
		eventAt = now
	}
	status := snap.Status
	if status == "" {
		status = payments.StatusIncomplete
	}
	live := status == payments.StatusActive || status == payments.StatusPastDue || status == payments.StatusIncomplete
	autoRenew := live && !snap.CancelAtPeriodEnd
	var cancelledAt, endDate, periodStart, periodEnd, nextBilling any
	if snap.CanceledAt != nil {
		cancelledAt = snap.CanceledAt.UTC()
	}
	if !snap.CurrentPeriodStart.IsZero() {
		periodStart = snap.CurrentPeriodStart.UTC()
	}
	if !snap.CurrentPeriodEnd.IsZero() {
		periodEnd = snap.CurrentPeriodEnd.UTC()
		nextBilling = snap.CurrentPeriodEnd.UTC()
	}
	if !live {
		if snap.CanceledAt != nil {
			endDate = snap.CanceledAt.UTC()
		} else {
			endDate = now
		}
	}
	var brand, last4 any
	if snap.Card != nil {
		brand, last4 = snap.Card.Brand, snap.Card.Last4
	}
	var amount any
	if snap.AmountMinor > 0 {
		amount = snap.AmountMinor
	}
	currency := strings.ToUpper(strings.TrimSpace(snap.Currency))
	metadata, _ := json.Marshal(snap.Metadata)

	var rowID, userID, endedReason string
	var lastEvent sql.NullTime
	err := tx.QueryRowContext(ctx, `
		SELECT id::text, user_id::text, last_provider_event_at, COALESCE(metadata->>'ended_reason','')
		FROM matching.billing_subscriptions_runtime
		WHERE provider=$1 AND provider_subscription_id=$2 FOR UPDATE`, provider, snap.SubscriptionID).Scan(&rowID, &userID, &lastEvent, &endedReason)
	switch {
	case err == nil:
		if lastEvent.Valid && lastEvent.Time.After(eventAt) {
			// Stale delivery: a newer event has already been applied.
			return rowID, nil
		}
		if endedReason == "chargeback" {
			// Ended locally by a lost dispute. The provider still reports it
			// live until the period ends (renewal is only switched off), so
			// its snapshots must not reactivate it.
			_, err = tx.ExecContext(ctx, `
				UPDATE matching.billing_subscriptions_runtime
				SET last_provider_event_at=GREATEST(COALESCE(last_provider_event_at,'epoch'::timestamptz),$2),
				    updated_at=$3
				WHERE id::text=$1`, rowID, eventAt.UTC(), now)
			return rowID, err
		}
		_, err = tx.ExecContext(ctx, `
			UPDATE matching.billing_subscriptions_runtime
			SET status=$2, auto_renew=$3, cancel_at_period_end=$4, cancelled_at=COALESCE($5, CASE WHEN $4 THEN cancelled_at ELSE NULL END),
			    end_date=CASE WHEN $6::timestamptz IS NULL THEN CASE WHEN $2 IN ('incomplete','active','past_due') THEN NULL ELSE end_date END ELSE $6::timestamptz END,
			    current_period_start=COALESCE($7, current_period_start), current_period_end=COALESCE($8, current_period_end),
			    next_billing_date=COALESCE($9, next_billing_date),
			    payment_method_brand=COALESCE($10, payment_method_brand), payment_method_last4=COALESCE($11, payment_method_last4),
			    amount_minor=COALESCE($12, amount_minor), currency=CASE WHEN $13='' THEN currency ELSE $13 END,
			    provider_customer_id=COALESCE(NULLIF($14,''), provider_customer_id),
			    last_provider_event_at=$15, updated_at=$16, lock_version=lock_version+1,
			    metadata=metadata || $17::jsonb,
			    plan_code=COALESCE(NULLIF($18,''), plan_code), billing_cycle=COALESCE(NULLIF($19,''), billing_cycle)
			WHERE id::text=$1`,
			rowID, status, autoRenew, snap.CancelAtPeriodEnd, cancelledAt, endDate, periodStart, periodEnd, nextBilling,
			brand, last4, amount, currency, snap.CustomerID, eventAt.UTC(), now, metadata,
			strings.ToLower(strings.TrimSpace(snap.Metadata["plan_code"])), metadataCycle(snap))
		return rowID, err
	case errors.Is(err, sql.ErrNoRows):
		// New subscription: find its member.
		userID = strings.TrimSpace(snap.Metadata["user_id"])
		if userID == "" && snap.CustomerID != "" {
			if err := tx.QueryRowContext(ctx, `
				SELECT user_id::text FROM matching.billing_provider_customers WHERE provider=$1 AND provider_customer_id=$2`,
				provider, snap.CustomerID).Scan(&userID); err != nil && !errors.Is(err, sql.ErrNoRows) {
				return "", err
			}
		}
		if userID == "" {
			return "", fmt.Errorf("%w: %s", errSubscriptionOrphan, snap.SubscriptionID)
		}
		planCode := strings.ToLower(strings.TrimSpace(snap.Metadata["plan_code"]))
		if planCode == "" {
			planCode = "unknown"
		}
		if live {
			if err := supersedeLiveSubscriptions(ctx, tx, userID, now); err != nil {
				return "", err
			}
		}
		start := snap.CurrentPeriodStart
		if start.IsZero() {
			start = now
		}
		if currency == "" {
			currency = "INR"
		}
		err = tx.QueryRowContext(ctx, `
			INSERT INTO matching.billing_subscriptions_runtime
			  (user_id, plan_code, status, billing_cycle, start_date, end_date, next_billing_date, auto_renew,
			   provider, provider_subscription_id, provider_customer_id, cancel_at_period_end, cancelled_at,
			   current_period_start, current_period_end, amount_minor, currency,
			   payment_method_brand, payment_method_last4, last_provider_event_at, metadata, created_at, updated_at)
			VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,NULLIF($11,''),$12,$13,$14,$15,$16,$17,$18,$19,$20,$21::jsonb,$22,$22)
			RETURNING id::text`,
			userID, planCode, status, cycleFromSnapshot(snap), start.UTC(), endDate, nextBilling, autoRenew,
			provider, snap.SubscriptionID, snap.CustomerID, snap.CancelAtPeriodEnd, cancelledAt,
			periodStart, periodEnd, amount, currency, brand, last4, eventAt.UTC(), metadata, now).Scan(&rowID)
		return rowID, err
	default:
		return "", err
	}
}

func upsertInvoicePayment(ctx context.Context, tx *sql.Tx, ev payments.Event, subRowID, userID string, now time.Time) error {
	inv := ev.Invoice
	status := "failed"
	var paidAt any
	if inv.Paid {
		status = "success"
		paidAt = ev.CreatedAt.UTC()
	}
	var brand, last4, failure, intent, charge, invoiceID, periodStart, periodEnd any
	if inv.Card != nil {
		brand, last4 = inv.Card.Brand, inv.Card.Last4
	}
	if inv.FailureMessage != "" {
		failure = inv.FailureMessage
	}
	if inv.PaymentIntentID != "" {
		intent = inv.PaymentIntentID
	}
	if inv.ChargeID != "" {
		charge = inv.ChargeID
	}
	if inv.InvoiceID != "" {
		invoiceID = inv.InvoiceID
	}
	if !inv.PeriodStart.IsZero() {
		periodStart = inv.PeriodStart.UTC()
	}
	if !inv.PeriodEnd.IsZero() {
		periodEnd = inv.PeriodEnd.UTC()
	}
	currency := strings.ToUpper(inv.Currency)
	if currency == "" {
		currency = "INR"
	}
	metadata, _ := json.Marshal(map[string]any{"billing_reason": inv.BillingReason, "event_type": ev.RawType})
	if invoiceID == nil {
		// Without an invoice id there is nothing to deduplicate on; use the
		// event id so a retried delivery still lands once.
		invoiceID = "evt:" + ev.ID
	}
	_, err := tx.ExecContext(ctx, `
		INSERT INTO matching.billing_payments_runtime
		  (user_id, subscription_id, amount_paise, currency, status, provider, provider_payment_id, provider_charge_id,
		   provider_invoice_id, provider_event_id, billing_reason, period_start, period_end,
		   payment_method_brand, payment_method_last4, failure_reason, paid_at, created_at, updated_at, metadata)
		VALUES ($1,$2::uuid,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$18,$19::jsonb)
		ON CONFLICT (provider, provider_invoice_id) WHERE provider_invoice_id IS NOT NULL DO UPDATE
		SET status=CASE WHEN matching.billing_payments_runtime.status IN ('refunded','partially_refunded') THEN matching.billing_payments_runtime.status
		               WHEN EXCLUDED.status='success' THEN 'success'
		               WHEN matching.billing_payments_runtime.status='success' THEN 'success'
		               ELSE EXCLUDED.status END,
		    amount_paise=CASE WHEN EXCLUDED.status='success' THEN EXCLUDED.amount_paise ELSE matching.billing_payments_runtime.amount_paise END,
		    provider_payment_id=COALESCE(EXCLUDED.provider_payment_id, matching.billing_payments_runtime.provider_payment_id),
		    provider_charge_id=COALESCE(EXCLUDED.provider_charge_id, matching.billing_payments_runtime.provider_charge_id),
		    paid_at=COALESCE(EXCLUDED.paid_at, matching.billing_payments_runtime.paid_at),
		    failure_reason=CASE WHEN EXCLUDED.status='success' THEN NULL ELSE COALESCE(EXCLUDED.failure_reason, matching.billing_payments_runtime.failure_reason) END,
		    payment_method_brand=COALESCE(EXCLUDED.payment_method_brand, matching.billing_payments_runtime.payment_method_brand),
		    payment_method_last4=COALESCE(EXCLUDED.payment_method_last4, matching.billing_payments_runtime.payment_method_last4),
		    provider_event_id=EXCLUDED.provider_event_id, updated_at=EXCLUDED.updated_at`,
		userID, subRowID, inv.AmountMinor, currency, status, ev.Provider, intent, charge,
		invoiceID, ev.ID, inv.BillingReason, periodStart, periodEnd, brand, last4, failure, paidAt, now, metadata)
	return err
}

func applyInvoiceToSubscription(ctx context.Context, tx *sql.Tx, ev payments.Event, subRowID string, now time.Time) error {
	inv := ev.Invoice
	var brand, last4, periodStart, periodEnd any
	if inv.Card != nil {
		brand, last4 = inv.Card.Brand, inv.Card.Last4
	}
	if !inv.PeriodStart.IsZero() {
		periodStart = inv.PeriodStart.UTC()
	}
	if !inv.PeriodEnd.IsZero() {
		periodEnd = inv.PeriodEnd.UTC()
	}
	if inv.Paid {
		// A settled invoice makes the subscription active for the invoiced
		// period, unless the provider already reported a later terminal
		// state (a cancellation delivered before a straggling invoice).
		_, err := tx.ExecContext(ctx, `
			UPDATE matching.billing_subscriptions_runtime
			SET status=CASE WHEN status IN ('cancelled','expired') AND (last_provider_event_at > $2 OR metadata->>'ended_reason'='chargeback') THEN status ELSE 'active' END,
			    current_period_start=COALESCE($3, current_period_start),
			    current_period_end=CASE WHEN $4::timestamptz IS NULL THEN current_period_end
			                            WHEN current_period_end IS NULL OR $4::timestamptz > current_period_end THEN $4::timestamptz
			                            ELSE current_period_end END,
			    next_billing_date=CASE WHEN $4::timestamptz IS NULL THEN next_billing_date
			                           WHEN next_billing_date IS NULL OR $4::timestamptz > next_billing_date THEN $4::timestamptz
			                           ELSE next_billing_date END,
			    end_date=CASE WHEN status IN ('cancelled','expired') AND (last_provider_event_at > $2 OR metadata->>'ended_reason'='chargeback') THEN end_date ELSE NULL END,
			    payment_method_brand=COALESCE($5, payment_method_brand), payment_method_last4=COALESCE($6, payment_method_last4),
			    amount_minor=CASE WHEN $7 > 0 THEN $7 ELSE amount_minor END,
			    last_provider_event_at=GREATEST(COALESCE(last_provider_event_at,'epoch'::timestamptz), $2),
			    updated_at=$8, lock_version=lock_version+1
			WHERE id::text=$1`, subRowID, ev.CreatedAt.UTC(), periodStart, periodEnd, brand, last4, inv.AmountMinor, now)
		return err
	}
	_, err := tx.ExecContext(ctx, `
		UPDATE matching.billing_subscriptions_runtime
		SET status=CASE WHEN status IN ('active','incomplete') THEN 'past_due' ELSE status END,
		    last_provider_event_at=GREATEST(COALESCE(last_provider_event_at,'epoch'::timestamptz), $2),
		    updated_at=$3, lock_version=lock_version+1
		WHERE id::text=$1`, subRowID, ev.CreatedAt.UTC(), now)
	return err
}

// ── Member actions ───────────────────────────────────────────────────────────

// setCancelAtPeriodEnd records the member's intent locally. The provider is
// the source of truth; its subscription.updated event confirms the change.
func (r *billingRepository) setCancelAtPeriodEnd(ctx context.Context, subRowID string, cancel bool, now time.Time) error {
	var cancelledAt any
	if cancel {
		cancelledAt = now
	}
	_, err := r.db.ExecContext(ctx, `
		UPDATE matching.billing_subscriptions_runtime
		SET cancel_at_period_end=$2, auto_renew=NOT $2, cancelled_at=$3, updated_at=$4, lock_version=lock_version+1
		WHERE id::text=$1`, subRowID, cancel, cancelledAt, now)
	return err
}

// ── Housekeeping ─────────────────────────────────────────────────────────────

// expireLapsedSubscriptions is the safety net behind provider events:
//   - past_due subscriptions whose grace window has elapsed expire;
//   - cancel-at-period-end subscriptions a day past their period end expire
//     even if the provider's deletion event never arrived;
//   - open checkout sessions past their expiry are closed.
func (r *billingRepository) expireLapsedSubscriptions(ctx context.Context, now time.Time, grace time.Duration) (expired int64, err error) {
	res, err := r.db.ExecContext(ctx, `
		UPDATE matching.billing_subscriptions_runtime
		SET status='expired', end_date=COALESCE(end_date,$1), auto_renew=FALSE, updated_at=$1, lock_version=lock_version+1
		WHERE (status='past_due' AND current_period_end IS NOT NULL AND current_period_end + $2::interval <= $1)
		   OR (status='active' AND cancel_at_period_end AND current_period_end IS NOT NULL AND current_period_end + interval '1 day' <= $1)`,
		now.UTC(), fmt.Sprintf("%d seconds", int64(grace.Seconds())))
	if err != nil {
		return 0, err
	}
	expired, _ = res.RowsAffected()
	if _, err := r.db.ExecContext(ctx, `
		UPDATE matching.billing_checkout_sessions SET status='expired'
		WHERE status='open' AND expires_at IS NOT NULL AND expires_at <= $1`, now.UTC()); err != nil {
		return expired, err
	}
	return expired, nil
}

func titlePlanName(planCode string) string {
	planCode = strings.TrimSpace(planCode)
	if planCode == "" {
		return "Free"
	}
	return strings.ToUpper(planCode[:1]) + planCode[1:]
}

// ── Reconciliation (PEN-02) ──────────────────────────────────────────────────

type reconciliationAnomaly struct {
	Type   string `json:"type"`
	ID     string `json:"id"`
	Detail string `json:"detail"`
}

// reconcile compares what the provider settled (payments driven by webhooks)
// with what the product granted (subscriptions, wallet credits), separates
// administrative grants from revenue, and lists rows that disagree.
func (r *billingRepository) reconcile(ctx context.Context, since, until time.Time) (map[string]any, error) {
	out := map[string]any{
		"window": map[string]any{"since": since.UTC().Format(time.RFC3339), "until": until.UTC().Format(time.RFC3339)},
	}
	anomalies := []reconciliationAnomaly{}

	// Payments by status; net revenue counts settled money minus refunds and
	// excludes provider "local" (no money moved) and chargebacks.
	rows, err := r.db.QueryContext(ctx, `
		SELECT status, provider, COUNT(*), COALESCE(SUM(amount_paise),0), COALESCE(SUM(refunded_amount_paise),0)
		FROM matching.billing_payments_runtime
		WHERE created_at >= $1 AND created_at < $2
		GROUP BY status, provider ORDER BY provider, status`, since, until)
	if err != nil {
		return nil, err
	}
	byStatus := []map[string]any{}
	var gross, refunded, netRevenue, atRisk, chargebacks, localOnly int64
	for rows.Next() {
		var status, provider string
		var count int
		var amount, ref int64
		if err := rows.Scan(&status, &provider, &count, &amount, &ref); err != nil {
			rows.Close()
			return nil, err
		}
		byStatus = append(byStatus, map[string]any{"status": status, "provider": provider, "count": count, "amount_minor": amount, "refunded_minor": ref})
		if provider == "local" {
			localOnly += amount
			continue
		}
		switch status {
		case "success":
			gross += amount
			netRevenue += amount
		case "partially_refunded":
			gross += amount
			refunded += ref
			netRevenue += amount - ref
		case "refunded":
			gross += amount
			refunded += amount
		case "disputed":
			gross += amount
			atRisk += amount
		case "chargeback":
			gross += amount
			chargebacks += amount
		}
	}
	rows.Close()
	out["payments_by_status"] = byStatus
	out["revenue"] = map[string]any{
		"gross_minor":            gross,
		"refunded_minor":         refunded,
		"chargeback_minor":       chargebacks,
		"disputed_at_risk_minor": atRisk,
		"net_minor":              netRevenue,
		"local_activation_minor": localOnly,
		"note":                   "net = settled provider payments minus refunds; local activations, admin grants and promos are never revenue",
	}

	// Wallet: buys must match a settled coin payment; grants are not revenue.
	wallet := map[string]any{}
	var buyCount, buyCoins, buyAmount, grantCount, grantCoins, promoCount, promoCoins int64
	if err := r.db.QueryRowContext(ctx, `
		SELECT
		  COALESCE(SUM(CASE WHEN source='buy' THEN 1 END),0), COALESCE(SUM(CASE WHEN source='buy' THEN coins END),0), COALESCE(SUM(CASE WHEN source='buy' THEN amount_minor END),0),
		  COALESCE(SUM(CASE WHEN source='admin_topup' THEN 1 END),0), COALESCE(SUM(CASE WHEN source='admin_topup' THEN coins END),0),
		  COALESCE(SUM(CASE WHEN source='promo' THEN 1 END),0), COALESCE(SUM(CASE WHEN source='promo' THEN coins END),0)
		FROM matching.wallet_coin_purchases WHERE created_at >= $1 AND created_at < $2`, since, until).Scan(
		&buyCount, &buyCoins, &buyAmount, &grantCount, &grantCoins, &promoCount, &promoCoins); err != nil {
		return nil, err
	}
	var coinPayCount, coinPayAmount int64
	if err := r.db.QueryRowContext(ctx, `
		SELECT COUNT(*), COALESCE(SUM(amount_paise),0) FROM matching.billing_payments_runtime
		WHERE billing_reason='coin_purchase' AND status IN ('success','partially_refunded','disputed') AND created_at >= $1 AND created_at < $2`, since, until).Scan(&coinPayCount, &coinPayAmount); err != nil {
		return nil, err
	}
	wallet["purchases"] = map[string]any{"count": buyCount, "coins": buyCoins, "amount_minor": buyAmount}
	wallet["settled_coin_payments"] = map[string]any{"count": coinPayCount, "amount_minor": coinPayAmount}
	wallet["admin_grants"] = map[string]any{"count": grantCount, "coins": grantCoins, "revenue": false}
	wallet["promotions"] = map[string]any{"count": promoCount, "coins": promoCoins, "revenue": false}
	out["wallet"] = wallet

	// Coin payments settled without a wallet credit.
	rows, err = r.db.QueryContext(ctx, `
		SELECT p.id::text, COALESCE(p.checkout_id::text,'(none)') FROM matching.billing_payments_runtime p
		WHERE p.billing_reason='coin_purchase' AND p.status='success' AND p.created_at >= $1 AND p.created_at < $2
		  AND NOT EXISTS (SELECT 1 FROM matching.wallet_coin_purchases w WHERE w.idempotency_key = 'checkout:'||p.checkout_id::text)`, since, until)
	if err != nil {
		return nil, err
	}
	for rows.Next() {
		var id, checkout string
		if err := rows.Scan(&id, &checkout); err != nil {
			rows.Close()
			return nil, err
		}
		anomalies = append(anomalies, reconciliationAnomaly{Type: "coin_payment_without_wallet_credit", ID: id, Detail: "checkout " + checkout + " settled but no wallet credit recorded"})
	}
	rows.Close()
	// Wallet buys that claim a provider but have no settled payment.
	rows, err = r.db.QueryContext(ctx, `
		SELECT w.id::text, w.provider, w.coins FROM matching.wallet_coin_purchases w
		WHERE w.source='buy' AND w.created_at >= $1 AND w.created_at < $2 AND w.provider NOT IN ('internal','promo')
		  AND NOT EXISTS (SELECT 1 FROM matching.billing_payments_runtime p WHERE 'checkout:'||p.checkout_id::text = w.idempotency_key AND p.status IN ('success','partially_refunded','disputed','chargeback','refunded'))`, since, until)
	if err != nil {
		return nil, err
	}
	for rows.Next() {
		var id, provider string
		var coins int
		if err := rows.Scan(&id, &provider, &coins); err != nil {
			rows.Close()
			return nil, err
		}
		anomalies = append(anomalies, reconciliationAnomaly{Type: "wallet_credit_without_payment", ID: id, Detail: fmt.Sprintf("%d coins credited via %s with no settled payment", coins, provider)})
	}
	rows.Close()
	// Refunded or charged-back coin payments whose coins were not fully taken
	// back (clawback is automatic since migration 084; this catches gaps).
	rows, err = r.db.QueryContext(ctx, `
		SELECT p.id::text, p.status FROM matching.billing_payments_runtime p
		WHERE p.billing_reason='coin_purchase' AND p.status IN ('refunded','chargeback')
		  AND p.created_at >= $1 AND p.created_at < $2
		  AND COALESCE((SELECT SUM(d.coins_requested) FROM matching.wallet_coin_debits d
		                WHERE d.payment_id=p.id AND d.source IN ('purchase_refund','purchase_chargeback')),0)
		    < COALESCE((SELECT SUM(c.coins) FROM matching.wallet_coin_purchases c
		                WHERE c.user_id=p.user_id AND c.idempotency_key='checkout:'||p.checkout_id::text),0)`, since, until)
	if err != nil {
		return nil, err
	}
	for rows.Next() {
		var id, status string
		if err := rows.Scan(&id, &status); err != nil {
			rows.Close()
			return nil, err
		}
		anomalies = append(anomalies, reconciliationAnomaly{Type: "coin_payment_reversed", ID: id, Detail: "coin purchase " + status + " but its coins were not fully taken back"})
	}
	rows.Close()

	// Subscriptions.
	subs := map[string]any{}
	rows, err = r.db.QueryContext(ctx, `
		SELECT status, COUNT(*), COALESCE(SUM(CASE WHEN cancel_at_period_end THEN 1 ELSE 0 END),0)
		FROM matching.billing_subscriptions_runtime WHERE provider<>'local' GROUP BY status`)
	if err != nil {
		return nil, err
	}
	statusCounts := map[string]any{}
	for rows.Next() {
		var status string
		var count, ending int
		if err := rows.Scan(&status, &count, &ending); err != nil {
			rows.Close()
			return nil, err
		}
		statusCounts[status] = map[string]any{"count": count, "cancel_at_period_end": ending}
	}
	rows.Close()
	subs["by_status"] = statusCounts
	rows, err = r.db.QueryContext(ctx, `
		SELECT s.id::text, s.plan_code FROM matching.billing_subscriptions_runtime s
		WHERE s.status='active' AND s.provider<>'local'
		  AND NOT EXISTS (SELECT 1 FROM matching.billing_payments_runtime p WHERE p.subscription_id=s.id AND p.status IN ('success','partially_refunded','disputed')
		                  AND (s.current_period_start IS NULL OR p.paid_at >= s.current_period_start - interval '1 day'))`)
	if err != nil {
		return nil, err
	}
	for rows.Next() {
		var id, plan string
		if err := rows.Scan(&id, &plan); err != nil {
			rows.Close()
			return nil, err
		}
		anomalies = append(anomalies, reconciliationAnomaly{Type: "active_subscription_without_settled_payment", ID: id, Detail: "plan " + plan + " active with no settled payment for the current period"})
	}
	rows.Close()
	rows, err = r.db.QueryContext(ctx, `
		SELECT p.id::text, p.subscription_id::text FROM matching.billing_payments_runtime p
		JOIN matching.billing_subscriptions_runtime s ON s.id=p.subscription_id
		WHERE p.status='chargeback' AND s.status IN ('active','past_due')`)
	if err != nil {
		return nil, err
	}
	for rows.Next() {
		var id, sub string
		if err := rows.Scan(&id, &sub); err != nil {
			rows.Close()
			return nil, err
		}
		anomalies = append(anomalies, reconciliationAnomaly{Type: "chargeback_on_live_subscription", ID: id, Detail: "subscription " + sub + " still live after a lost dispute"})
	}
	rows.Close()
	out["subscriptions"] = subs

	// Webhooks and checkouts.
	rows, err = r.db.QueryContext(ctx, `SELECT status, COUNT(*) FROM matching.billing_webhook_events WHERE received_at >= $1 AND received_at < $2 GROUP BY status`, since, until)
	if err != nil {
		return nil, err
	}
	webhooks := map[string]any{}
	for rows.Next() {
		var status string
		var count int
		if err := rows.Scan(&status, &count); err != nil {
			rows.Close()
			return nil, err
		}
		webhooks[status] = count
	}
	rows.Close()
	rows, err = r.db.QueryContext(ctx, `SELECT event_id, event_type, COALESCE(error,'') FROM matching.billing_webhook_events WHERE status='failed' ORDER BY received_at DESC LIMIT 20`)
	if err != nil {
		return nil, err
	}
	for rows.Next() {
		var id, typ, msg string
		if err := rows.Scan(&id, &typ, &msg); err != nil {
			rows.Close()
			return nil, err
		}
		anomalies = append(anomalies, reconciliationAnomaly{Type: "webhook_failed", ID: id, Detail: typ + ": " + msg})
	}
	rows.Close()
	out["webhooks"] = webhooks
	var openExpired, completedNoSub int
	if err := r.db.QueryRowContext(ctx, `
		SELECT
		  (SELECT COUNT(*) FROM matching.billing_checkout_sessions WHERE status='open' AND expires_at IS NOT NULL AND expires_at < NOW()),
		  (SELECT COUNT(*) FROM matching.billing_checkout_sessions WHERE status='completed' AND kind='subscription' AND subscription_id IS NULL)`).Scan(&openExpired, &completedNoSub); err != nil {
		return nil, err
	}
	out["checkouts"] = map[string]any{"open_past_expiry": openExpired, "completed_without_subscription": completedNoSub}
	if completedNoSub > 0 {
		anomalies = append(anomalies, reconciliationAnomaly{Type: "checkout_completed_without_subscription", ID: "-", Detail: fmt.Sprintf("%d subscription checkouts completed without a linked subscription", completedNoSub)})
	}
	liability, liabilityAnomalies, err := r.coinLiability(ctx)
	if err != nil {
		return nil, err
	}
	out["coin_liability"] = liability
	anomalies = append(anomalies, liabilityAnomalies...)
	out["anomalies"] = anomalies
	out["anomaly_count"] = len(anomalies)
	return out, nil
}
