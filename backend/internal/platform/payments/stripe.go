package payments

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"time"
)

// StripeConfig configures the Stripe adapter. Only the secret key and webhook
// signing secret are mandatory.
type StripeConfig struct {
	SecretKey     string
	WebhookSecret string
	APIBaseURL    string
	HTTPClient    *http.Client
	Tolerance     time.Duration
}

// Stripe sells subscriptions through Stripe Checkout (hosted, card-only) and
// consumes Stripe webhooks. It talks to the REST API directly with form
// encoding, which keeps the dependency surface to the standard library and
// makes every call trivially testable against httptest.
type Stripe struct {
	secretKey     string
	webhookSecret string
	base          string
	client        *http.Client
	tolerance     time.Duration
}

// NewStripe validates the configuration and returns the adapter.
func NewStripe(cfg StripeConfig) (*Stripe, error) {
	if strings.TrimSpace(cfg.SecretKey) == "" {
		return nil, errors.New("stripe secret key is required")
	}
	if strings.TrimSpace(cfg.WebhookSecret) == "" {
		return nil, errors.New("stripe webhook secret is required")
	}
	base := strings.TrimRight(strings.TrimSpace(cfg.APIBaseURL), "/")
	if base == "" {
		base = "https://api.stripe.com"
	}
	client := cfg.HTTPClient
	if client == nil {
		client = &http.Client{Timeout: 20 * time.Second}
	}
	tolerance := cfg.Tolerance
	if tolerance <= 0 {
		tolerance = DefaultSignatureTolerance
	}
	return &Stripe{
		secretKey:     strings.TrimSpace(cfg.SecretKey),
		webhookSecret: strings.TrimSpace(cfg.WebhookSecret),
		base:          base,
		client:        client,
		tolerance:     tolerance,
	}, nil
}

// Name implements Provider.
func (s *Stripe) Name() string { return "stripe" }

type stripeAPIError struct {
	Status  int
	Type    string
	Code    string
	Message string
}

func (e *stripeAPIError) Error() string {
	return fmt.Sprintf("stripe %d %s/%s: %s", e.Status, e.Type, e.Code, e.Message)
}

func (s *Stripe) do(ctx context.Context, method, path string, form url.Values, idempotencyKey string, out any) error {
	var body io.Reader
	if form != nil && (method == http.MethodPost) {
		body = strings.NewReader(form.Encode())
	}
	target := s.base + path
	if form != nil && method != http.MethodPost && len(form) > 0 {
		target += "?" + form.Encode()
	}
	req, err := http.NewRequestWithContext(ctx, method, target, body)
	if err != nil {
		return err
	}
	req.SetBasicAuth(s.secretKey, "")
	if body != nil {
		req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	}
	if idempotencyKey != "" {
		req.Header.Set("Idempotency-Key", idempotencyKey)
	}
	resp, err := s.client.Do(req)
	if err != nil {
		return fmt.Errorf("stripe request: %w", err)
	}
	defer resp.Body.Close()
	raw, err := io.ReadAll(io.LimitReader(resp.Body, 4<<20))
	if err != nil {
		return fmt.Errorf("stripe response: %w", err)
	}
	if resp.StatusCode >= 400 {
		var envelope struct {
			Error struct {
				Type    string `json:"type"`
				Code    string `json:"code"`
				Message string `json:"message"`
			} `json:"error"`
		}
		_ = json.Unmarshal(raw, &envelope)
		if resp.StatusCode == http.StatusNotFound {
			return fmt.Errorf("%w: %s", ErrNotFound, envelope.Error.Message)
		}
		return &stripeAPIError{Status: resp.StatusCode, Type: envelope.Error.Type, Code: envelope.Error.Code, Message: envelope.Error.Message}
	}
	if out != nil {
		if err := json.Unmarshal(raw, out); err != nil {
			return fmt.Errorf("decode stripe response: %w", err)
		}
	}
	return nil
}

// EnsureCustomer implements Provider. Stripe customer creation is made
// idempotent on the member id so a retry never creates a duplicate.
func (s *Stripe) EnsureCustomer(ctx context.Context, req CustomerRequest) (string, error) {
	if strings.TrimSpace(req.UserID) == "" {
		return "", errors.New("user id is required")
	}
	form := url.Values{}
	form.Set("metadata[user_id]", req.UserID)
	if req.Email != "" {
		form.Set("email", req.Email)
	}
	if req.Name != "" {
		form.Set("name", req.Name)
	}
	var out struct {
		ID string `json:"id"`
	}
	if err := s.do(ctx, http.MethodPost, "/v1/customers", form, "customer-"+req.UserID, &out); err != nil {
		return "", err
	}
	if out.ID == "" {
		return "", errors.New("stripe returned no customer id")
	}
	return out.ID, nil
}

// CreateSubscriptionCheckout implements Provider using Checkout Sessions in
// subscription mode. When the plan has no pre-created Stripe price the
// recurring price is described inline, so the plan catalog in PostgreSQL
// stays the single source of truth for amounts.
func (s *Stripe) CreateSubscriptionCheckout(ctx context.Context, req CheckoutRequest) (CheckoutSession, error) {
	if req.CustomerID == "" || req.SuccessURL == "" || req.CancelURL == "" {
		return CheckoutSession{}, errors.New("customer id, success url and cancel url are required")
	}
	interval := "month"
	if req.BillingCycle == "yearly" {
		interval = "year"
	}
	form := url.Values{}
	form.Set("mode", "subscription")
	form.Set("customer", req.CustomerID)
	form.Set("payment_method_types[0]", "card")
	form.Set("success_url", req.SuccessURL)
	form.Set("cancel_url", req.CancelURL)
	form.Set("client_reference_id", req.UserID)
	form.Set("line_items[0][quantity]", "1")
	if req.ProviderPrice != "" {
		form.Set("line_items[0][price]", req.ProviderPrice)
	} else {
		if req.AmountMinor <= 0 {
			return CheckoutSession{}, errors.New("a paid plan needs a positive amount")
		}
		form.Set("line_items[0][price_data][currency]", strings.ToLower(req.Currency))
		form.Set("line_items[0][price_data][unit_amount]", strconv.FormatInt(req.AmountMinor, 10))
		form.Set("line_items[0][price_data][recurring][interval]", interval)
		form.Set("line_items[0][price_data][product_data][name]", req.PlanName+" ("+req.BillingCycle+")")
	}
	for key, value := range map[string]string{
		"user_id":       req.UserID,
		"plan_code":     req.PlanCode,
		"billing_cycle": req.BillingCycle,
		"checkout_id":   req.CheckoutID,
	} {
		form.Set("metadata["+key+"]", value)
		form.Set("subscription_data[metadata]["+key+"]", value)
	}
	var out struct {
		ID        string `json:"id"`
		URL       string `json:"url"`
		ExpiresAt int64  `json:"expires_at"`
	}
	if err := s.do(ctx, http.MethodPost, "/v1/checkout/sessions", form, req.IdempotencyKey, &out); err != nil {
		return CheckoutSession{}, err
	}
	if out.ID == "" || out.URL == "" {
		return CheckoutSession{}, errors.New("stripe returned an incomplete checkout session")
	}
	return CheckoutSession{ProviderSessionID: out.ID, URL: out.URL, ExpiresAt: unixTime(out.ExpiresAt)}, nil
}

// CreatePaymentCheckout implements Provider with a Checkout Session in
// payment mode: one card charge, no subscription.
func (s *Stripe) CreatePaymentCheckout(ctx context.Context, req PaymentCheckoutRequest) (CheckoutSession, error) {
	if req.CustomerID == "" || req.SuccessURL == "" || req.CancelURL == "" {
		return CheckoutSession{}, errors.New("customer id, success url and cancel url are required")
	}
	if req.AmountMinor <= 0 {
		return CheckoutSession{}, errors.New("a payment needs a positive amount")
	}
	form := url.Values{}
	form.Set("mode", "payment")
	form.Set("customer", req.CustomerID)
	form.Set("payment_method_types[0]", "card")
	form.Set("success_url", req.SuccessURL)
	form.Set("cancel_url", req.CancelURL)
	form.Set("client_reference_id", req.UserID)
	form.Set("line_items[0][quantity]", "1")
	form.Set("line_items[0][price_data][currency]", strings.ToLower(req.Currency))
	form.Set("line_items[0][price_data][unit_amount]", strconv.FormatInt(req.AmountMinor, 10))
	form.Set("line_items[0][price_data][product_data][name]", req.Description)
	meta := map[string]string{"user_id": req.UserID, "checkout_id": req.CheckoutID}
	for k, v := range req.Metadata {
		meta[k] = v
	}
	for key, value := range meta {
		form.Set("metadata["+key+"]", value)
		form.Set("payment_intent_data[metadata]["+key+"]", value)
	}
	var out struct {
		ID        string `json:"id"`
		URL       string `json:"url"`
		ExpiresAt int64  `json:"expires_at"`
	}
	if err := s.do(ctx, http.MethodPost, "/v1/checkout/sessions", form, req.IdempotencyKey, &out); err != nil {
		return CheckoutSession{}, err
	}
	if out.ID == "" || out.URL == "" {
		return CheckoutSession{}, errors.New("stripe returned an incomplete checkout session")
	}
	return CheckoutSession{ProviderSessionID: out.ID, URL: out.URL, ExpiresAt: unixTime(out.ExpiresAt)}, nil
}

// FetchSubscription implements Provider, expanding the default payment
// method so the card brand and last four digits are available.
func (s *Stripe) FetchSubscription(ctx context.Context, providerSubscriptionID string) (SubscriptionSnapshot, error) {
	if strings.TrimSpace(providerSubscriptionID) == "" {
		return SubscriptionSnapshot{}, errors.New("subscription id is required")
	}
	form := url.Values{}
	form.Set("expand[0]", "default_payment_method")
	var sub stripeSubscription
	if err := s.do(ctx, http.MethodGet, "/v1/subscriptions/"+url.PathEscape(providerSubscriptionID), form, "", &sub); err != nil {
		return SubscriptionSnapshot{}, err
	}
	return snapshotFromStripeSubscription(sub), nil
}

// SetCancelAtPeriodEnd implements Provider.
func (s *Stripe) SetCancelAtPeriodEnd(ctx context.Context, providerSubscriptionID string, cancel bool) error {
	if strings.TrimSpace(providerSubscriptionID) == "" {
		return errors.New("subscription id is required")
	}
	form := url.Values{}
	form.Set("cancel_at_period_end", strconv.FormatBool(cancel))
	return s.do(ctx, http.MethodPost, "/v1/subscriptions/"+url.PathEscape(providerSubscriptionID), form, "", nil)
}

// ensureProduct returns a Stripe product for a plan, created idempotently on
// the plan code. Subscription item updates need a product id even when the
// recurring price is described inline.
func (s *Stripe) ensureProduct(ctx context.Context, planCode, planName string) (string, error) {
	form := url.Values{}
	form.Set("name", planName)
	form.Set("metadata[plan_code]", planCode)
	var out struct {
		ID string `json:"id"`
	}
	if err := s.do(ctx, http.MethodPost, "/v1/products", form, "plan-product-"+planCode, &out); err != nil {
		return "", err
	}
	if out.ID == "" {
		return "", errors.New("stripe returned no product id")
	}
	return out.ID, nil
}

// ChangeSubscriptionPlan implements Provider. Upgrades use
// proration_behavior=always_invoice so the difference is charged now; the
// resulting invoice.paid drives the local ledger. Downgrades create a
// proration credit consumed by the next invoice.
func (s *Stripe) ChangeSubscriptionPlan(ctx context.Context, req ChangePlanRequest) error {
	if req.SubscriptionID == "" || req.ItemID == "" {
		return errors.New("subscription id and item id are required")
	}
	interval := "month"
	if req.BillingCycle == "yearly" {
		interval = "year"
	}
	form := url.Values{}
	form.Set("items[0][id]", req.ItemID)
	if req.ProviderPrice != "" {
		form.Set("items[0][price]", req.ProviderPrice)
	} else {
		if req.AmountMinor <= 0 {
			return errors.New("a paid plan needs a positive amount")
		}
		product, err := s.ensureProduct(ctx, req.PlanCode, req.PlanName)
		if err != nil {
			return err
		}
		form.Set("items[0][price_data][currency]", strings.ToLower(req.Currency))
		form.Set("items[0][price_data][unit_amount]", strconv.FormatInt(req.AmountMinor, 10))
		form.Set("items[0][price_data][recurring][interval]", interval)
		form.Set("items[0][price_data][product]", product)
	}
	if req.Upgrade {
		form.Set("proration_behavior", "always_invoice")
	} else {
		form.Set("proration_behavior", "create_prorations")
	}
	form.Set("metadata[plan_code]", req.PlanCode)
	form.Set("metadata[billing_cycle]", req.BillingCycle)
	form.Set("payment_behavior", "error_if_incomplete")
	return s.do(ctx, http.MethodPost, "/v1/subscriptions/"+url.PathEscape(req.SubscriptionID), form, "", nil)
}

// CreateSetupCheckout implements Provider with a Checkout Session in setup
// mode: the card is saved, nothing is charged.
func (s *Stripe) CreateSetupCheckout(ctx context.Context, req SetupCheckoutRequest) (CheckoutSession, error) {
	if req.CustomerID == "" || req.SuccessURL == "" || req.CancelURL == "" {
		return CheckoutSession{}, errors.New("customer id, success url and cancel url are required")
	}
	form := url.Values{}
	form.Set("mode", "setup")
	form.Set("customer", req.CustomerID)
	form.Set("payment_method_types[0]", "card")
	form.Set("success_url", req.SuccessURL)
	form.Set("cancel_url", req.CancelURL)
	form.Set("client_reference_id", req.UserID)
	for key, value := range map[string]string{"user_id": req.UserID, "checkout_id": req.CheckoutID, "subscription_id": req.SubscriptionID, "kind": "card_update"} {
		form.Set("metadata["+key+"]", value)
		form.Set("setup_intent_data[metadata]["+key+"]", value)
	}
	var out struct {
		ID        string `json:"id"`
		URL       string `json:"url"`
		ExpiresAt int64  `json:"expires_at"`
	}
	if err := s.do(ctx, http.MethodPost, "/v1/checkout/sessions", form, req.IdempotencyKey, &out); err != nil {
		return CheckoutSession{}, err
	}
	if out.ID == "" || out.URL == "" {
		return CheckoutSession{}, errors.New("stripe returned an incomplete checkout session")
	}
	return CheckoutSession{ProviderSessionID: out.ID, URL: out.URL, ExpiresAt: unixTime(out.ExpiresAt)}, nil
}

// ApplySetupPaymentMethod implements Provider.
func (s *Stripe) ApplySetupPaymentMethod(ctx context.Context, setupIntentID, providerSubscriptionID string) (*CardSummary, error) {
	if setupIntentID == "" {
		return nil, errors.New("setup intent id is required")
	}
	form := url.Values{}
	form.Set("expand[0]", "payment_method")
	var intent struct {
		Customer      stripeRef           `json:"customer"`
		PaymentMethod stripePaymentMethod `json:"payment_method"`
	}
	if err := s.do(ctx, http.MethodGet, "/v1/setup_intents/"+url.PathEscape(setupIntentID), form, "", &intent); err != nil {
		return nil, err
	}
	if intent.PaymentMethod.ID == "" {
		return nil, errors.New("setup intent has no payment method")
	}
	if providerSubscriptionID != "" {
		update := url.Values{}
		update.Set("default_payment_method", intent.PaymentMethod.ID)
		if err := s.do(ctx, http.MethodPost, "/v1/subscriptions/"+url.PathEscape(providerSubscriptionID), update, "", nil); err != nil {
			return nil, err
		}
	}
	if intent.Customer.ID != "" {
		update := url.Values{}
		update.Set("invoice_settings[default_payment_method]", intent.PaymentMethod.ID)
		if err := s.do(ctx, http.MethodPost, "/v1/customers/"+url.PathEscape(intent.Customer.ID), update, "", nil); err != nil {
			return nil, err
		}
	}
	if intent.PaymentMethod.Card == nil {
		return &CardSummary{Brand: "card"}, nil
	}
	c := intent.PaymentMethod.Card
	return &CardSummary{Brand: c.Brand, Last4: c.Last4, ExpMonth: c.ExpMonth, ExpYear: c.ExpYear}, nil
}

// ParseWebhook implements Provider.
func (s *Stripe) ParseWebhook(payload []byte, signatureHeader string, now time.Time) (Event, error) {
	if err := VerifySignature(s.webhookSecret, signatureHeader, payload, now, s.tolerance); err != nil {
		return Event{}, err
	}
	return parseStripeEvent(s.Name(), payload)
}
