package payments

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"sync"
	"time"
)

// Sandbox is an in-process provider for local development and automated QA.
//
// It behaves like Stripe from the BFF's point of view: checkout is a hosted
// page, nothing becomes active until a signed webhook says the first charge
// settled, renewals arrive as further invoice events, and cancellation flows
// back through subscription events. Every event it emits is a Stripe-shaped
// payload signed with the sandbox webhook secret, so the production parser,
// signature check and deduplication code run unchanged.
//
// It never touches a real card. It is refused in production configuration.
type Sandbox struct {
	secret    string
	publicURL string
	now       func() time.Time
	// deliver hands a signed event to the BFF webhook pipeline. Set by the
	// BFF after construction; synchronous so tests are deterministic.
	deliver func(payload []byte, signature string) error

	mu            sync.Mutex
	customers     map[string]string // user id -> customer id
	sessions      map[string]*SandboxSession
	subscriptions map[string]*sandboxSubscription
	setupIntents  map[string]*sandboxSetupIntent
	disputes      map[string]string // dispute id -> charge id
	invoiceSeq    int
	eventSeq      int
}

// SandboxSession is one hosted checkout page's state.
type SandboxSession struct {
	ID             string
	Mode           string // subscription | payment | setup
	Description    string
	CheckoutID     string
	UserID         string
	CustomerID     string
	PlanCode       string
	PlanName       string
	BillingCycle   string
	AmountMinor    int64
	Currency       string
	SuccessURL     string
	CancelURL      string
	Status         string // open | complete | expired
	SubscriptionID string
	ExpiresAt      time.Time
	LastError      string
	Metadata       map[string]string
}

type sandboxSetupIntent struct {
	id             string
	customerID     string
	subscriptionID string
	card           CardSummary
}

type sandboxSubscription struct {
	id                string
	customerID        string
	userID            string
	status            string
	cancelAtPeriodEnd bool
	canceledAt        time.Time
	periodStart       time.Time
	periodEnd         time.Time
	interval          string
	amountMinor       int64
	currency          string
	card              CardSummary
	metadata          map[string]string
	lastInvoiceID     string
	lastChargeID      string
	lastIntentID      string
	lastChargeAmount  int64
}

// SandboxCard is the card input the sandbox checkout page collects.
type SandboxCard struct {
	Number   string
	ExpMonth int
	ExpYear  int
	CVC      string
	Name     string
}

// NewSandbox creates the provider. publicURL is the externally reachable
// API base (as the device sees it) used to build checkout page URLs.
func NewSandbox(secret, publicURL string) (*Sandbox, error) {
	if strings.TrimSpace(secret) == "" {
		return nil, errors.New("sandbox webhook secret is required")
	}
	if strings.TrimSpace(publicURL) == "" {
		return nil, errors.New("sandbox public base url is required")
	}
	return &Sandbox{
		secret:        strings.TrimSpace(secret),
		publicURL:     strings.TrimRight(strings.TrimSpace(publicURL), "/"),
		now:           func() time.Time { return time.Now().UTC() },
		customers:     map[string]string{},
		sessions:      map[string]*SandboxSession{},
		subscriptions: map[string]*sandboxSubscription{},
		setupIntents:  map[string]*sandboxSetupIntent{},
		disputes:      map[string]string{},
	}, nil
}

// SetClock overrides time for tests.
func (s *Sandbox) SetClock(now func() time.Time) { s.now = now }

// SetDeliverer installs the webhook sink.
func (s *Sandbox) SetDeliverer(deliver func(payload []byte, signature string) error) {
	s.deliver = deliver
}

// Name implements Provider.
func (s *Sandbox) Name() string { return "sandbox" }

func randomToken(n int) string {
	buf := make([]byte, n)
	if _, err := rand.Read(buf); err != nil {
		return fmt.Sprintf("%d", time.Now().UnixNano())
	}
	return hex.EncodeToString(buf)
}

// EnsureCustomer implements Provider.
func (s *Sandbox) EnsureCustomer(_ context.Context, req CustomerRequest) (string, error) {
	if strings.TrimSpace(req.UserID) == "" {
		return "", errors.New("user id is required")
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	if id, ok := s.customers[req.UserID]; ok {
		return id, nil
	}
	id := "cus_sandbox_" + randomToken(8)
	s.customers[req.UserID] = id
	return id, nil
}

// CreateSubscriptionCheckout implements Provider.
func (s *Sandbox) CreateSubscriptionCheckout(_ context.Context, req CheckoutRequest) (CheckoutSession, error) {
	if req.CustomerID == "" || req.UserID == "" {
		return CheckoutSession{}, errors.New("customer id and user id are required")
	}
	if req.AmountMinor <= 0 {
		return CheckoutSession{}, errors.New("a paid plan needs a positive amount")
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	id := "cs_sandbox_" + randomToken(12)
	session := &SandboxSession{
		ID:           id,
		Mode:         "subscription",
		CheckoutID:   req.CheckoutID,
		UserID:       req.UserID,
		CustomerID:   req.CustomerID,
		PlanCode:     req.PlanCode,
		PlanName:     req.PlanName,
		BillingCycle: req.BillingCycle,
		AmountMinor:  req.AmountMinor,
		Currency:     strings.ToUpper(req.Currency),
		SuccessURL:   req.SuccessURL,
		CancelURL:    req.CancelURL,
		Status:       "open",
		ExpiresAt:    s.now().Add(30 * time.Minute),
		Metadata: map[string]string{
			"user_id":       req.UserID,
			"plan_code":     req.PlanCode,
			"billing_cycle": req.BillingCycle,
			"checkout_id":   req.CheckoutID,
		},
	}
	s.sessions[id] = session
	return CheckoutSession{
		ProviderSessionID: id,
		URL:               s.publicURL + "/billing/sandbox/checkout/" + id,
		ExpiresAt:         session.ExpiresAt,
	}, nil
}

// CreatePaymentCheckout implements Provider for a single card charge.
func (s *Sandbox) CreatePaymentCheckout(_ context.Context, req PaymentCheckoutRequest) (CheckoutSession, error) {
	if req.CustomerID == "" || req.UserID == "" {
		return CheckoutSession{}, errors.New("customer id and user id are required")
	}
	if req.AmountMinor <= 0 {
		return CheckoutSession{}, errors.New("a payment needs a positive amount")
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	id := "cs_sandbox_" + randomToken(12)
	meta := map[string]string{"user_id": req.UserID, "checkout_id": req.CheckoutID}
	for k, v := range req.Metadata {
		meta[k] = v
	}
	session := &SandboxSession{
		ID:          id,
		Mode:        "payment",
		Description: req.Description,
		CheckoutID:  req.CheckoutID,
		UserID:      req.UserID,
		CustomerID:  req.CustomerID,
		PlanName:    req.Description,
		AmountMinor: req.AmountMinor,
		Currency:    strings.ToUpper(req.Currency),
		SuccessURL:  req.SuccessURL,
		CancelURL:   req.CancelURL,
		Status:      "open",
		ExpiresAt:   s.now().Add(30 * time.Minute),
		Metadata:    meta,
	}
	s.sessions[id] = session
	return CheckoutSession{
		ProviderSessionID: id,
		URL:               s.publicURL + "/billing/sandbox/checkout/" + id,
		ExpiresAt:         session.ExpiresAt,
	}, nil
}

// CreateSetupCheckout implements Provider: collect a replacement card.
func (s *Sandbox) CreateSetupCheckout(_ context.Context, req SetupCheckoutRequest) (CheckoutSession, error) {
	if req.CustomerID == "" || req.UserID == "" {
		return CheckoutSession{}, errors.New("customer id and user id are required")
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	id := "cs_sandbox_" + randomToken(12)
	session := &SandboxSession{
		ID:             id,
		Mode:           "setup",
		Description:    "Update card",
		CheckoutID:     req.CheckoutID,
		UserID:         req.UserID,
		CustomerID:     req.CustomerID,
		PlanName:       "Update your card",
		SubscriptionID: req.SubscriptionID,
		Currency:       "",
		SuccessURL:     req.SuccessURL,
		CancelURL:      req.CancelURL,
		Status:         "open",
		ExpiresAt:      s.now().Add(30 * time.Minute),
		Metadata: map[string]string{
			"user_id": req.UserID, "checkout_id": req.CheckoutID,
			"subscription_id": req.SubscriptionID, "kind": "card_update",
		},
	}
	s.sessions[id] = session
	return CheckoutSession{
		ProviderSessionID: id,
		URL:               s.publicURL + "/billing/sandbox/checkout/" + id,
		ExpiresAt:         session.ExpiresAt,
	}, nil
}

// ApplySetupPaymentMethod implements Provider: the saved card becomes the
// subscription's card and a subscription.updated event carries it.
func (s *Sandbox) ApplySetupPaymentMethod(_ context.Context, setupIntentID, providerSubscriptionID string) (*CardSummary, error) {
	now := s.now()
	s.mu.Lock()
	intent, ok := s.setupIntents[setupIntentID]
	if !ok {
		s.mu.Unlock()
		return nil, ErrNotFound
	}
	card := intent.card
	var events [][]byte
	if providerSubscriptionID != "" {
		sub, ok := s.subscriptions[providerSubscriptionID]
		if !ok {
			s.mu.Unlock()
			return nil, ErrNotFound
		}
		sub.card = card
		delete(sub.metadata, "sandbox_renewals_fail")
		if sub.status == "past_due" {
			// A new card retries the failed renewal, as Stripe does when a
			// default payment method is replaced on a past-due subscription.
			sub.status = "active"
			events = append(events, s.envelopeLocked("invoice.paid", now, s.invoiceObjectLocked(sub, "subscription_cycle", true, "")))
		}
		events = append(events, s.envelopeLocked("customer.subscription.updated", now, s.subscriptionObjectLocked(sub)))
	}
	s.mu.Unlock()
	if err := s.emit(now, events); err != nil {
		return nil, err
	}
	return &card, nil
}

// ChangeSubscriptionPlan implements Provider. An upgrade charges the
// prorated difference for the rest of the period now; a downgrade takes
// effect immediately with no charge.
func (s *Sandbox) ChangeSubscriptionPlan(_ context.Context, req ChangePlanRequest) error {
	now := s.now()
	s.mu.Lock()
	sub, ok := s.subscriptions[req.SubscriptionID]
	if !ok {
		s.mu.Unlock()
		return ErrNotFound
	}
	if sub.status == "canceled" {
		s.mu.Unlock()
		return errors.New("subscription is already cancelled")
	}
	oldAmount := sub.amountMinor
	sub.amountMinor = req.AmountMinor
	sub.currency = strings.ToUpper(req.Currency)
	sub.interval = "month"
	if req.BillingCycle == "yearly" {
		sub.interval = "year"
	}
	sub.metadata["plan_code"] = req.PlanCode
	sub.metadata["billing_cycle"] = req.BillingCycle
	var events [][]byte
	if req.Upgrade {
		remaining := 1.0
		if total := sub.periodEnd.Sub(sub.periodStart); total > 0 {
			remaining = float64(sub.periodEnd.Sub(now)) / float64(total)
			if remaining < 0 {
				remaining = 0
			}
			if remaining > 1 {
				remaining = 1
			}
		}
		prorated := int64(float64(req.AmountMinor-oldAmount)*remaining + 0.5)
		if prorated > 0 {
			inv := s.invoiceObjectLocked(sub, "subscription_update", true, "")
			inv["amount_paid"] = prorated
			inv["amount_due"] = prorated
			sub.lastChargeAmount = prorated
			events = append(events, s.envelopeLocked("invoice.paid", now, inv))
		}
		sub.status = "active"
	}
	events = append(events, s.envelopeLocked("customer.subscription.updated", now, s.subscriptionObjectLocked(sub)))
	s.mu.Unlock()
	return s.emit(now, events)
}

// OpenDispute simulates a chargeback on the last settled charge.
func (s *Sandbox) OpenDispute(providerSubscriptionID, chargeID, intentID string, amountMinor int64) error {
	now := s.now()
	s.mu.Lock()
	sub, ok := s.subscriptions[providerSubscriptionID]
	if !ok {
		s.mu.Unlock()
		return ErrNotFound
	}
	if chargeID == "" && intentID == "" {
		chargeID, intentID = sub.lastChargeID, sub.lastIntentID
	}
	if chargeID == "" && intentID == "" {
		s.mu.Unlock()
		return ErrNotFound
	}
	if chargeID == "" {
		chargeID = "ch_for_" + intentID
	}
	if amountMinor <= 0 {
		amountMinor = sub.amountMinor
	}
	disputeID := "dp_sandbox_" + randomToken(6)
	s.disputes[disputeID] = chargeID
	sub.metadata["sandbox_open_dispute"] = disputeID + "|" + chargeID + "|" + intentID + "|" + fmt.Sprint(amountMinor)
	events := [][]byte{s.envelopeLocked("charge.dispute.created", now, map[string]any{
		"id": disputeID, "object": "dispute", "charge": chargeID, "payment_intent": intentID,
		"amount": amountMinor, "currency": strings.ToLower(sub.currency), "status": "needs_response", "reason": "fraudulent",
	})}
	s.mu.Unlock()
	return s.emit(now, events)
}

// CloseDispute resolves the open dispute as won or lost.
func (s *Sandbox) CloseDispute(providerSubscriptionID string, won bool) error {
	now := s.now()
	s.mu.Lock()
	sub, ok := s.subscriptions[providerSubscriptionID]
	if !ok {
		s.mu.Unlock()
		return ErrNotFound
	}
	raw := sub.metadata["sandbox_open_dispute"]
	if raw == "" {
		s.mu.Unlock()
		return errors.New("no open dispute")
	}
	parts := strings.SplitN(raw, "|", 4)
	delete(sub.metadata, "sandbox_open_dispute")
	status := "lost"
	if won {
		status = "won"
	}
	var amount int64
	if len(parts) == 4 {
		fmt.Sscan(parts[3], &amount)
	}
	events := [][]byte{s.envelopeLocked("charge.dispute.closed", now, map[string]any{
		"id": parts[0], "object": "dispute", "charge": parts[1], "payment_intent": parts[2],
		"amount": amount, "currency": strings.ToLower(sub.currency), "status": status, "reason": "fraudulent",
	})}
	s.mu.Unlock()
	return s.emit(now, events)
}

// Session returns a copy of a checkout session for rendering.
func (s *Sandbox) Session(id string) (SandboxSession, bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	session, ok := s.sessions[id]
	if !ok {
		return SandboxSession{}, false
	}
	return *session, true
}

// luhnValid is the standard card number checksum.
func luhnValid(number string) bool {
	digits := strings.ReplaceAll(strings.TrimSpace(number), " ", "")
	if len(digits) < 12 || len(digits) > 19 {
		return false
	}
	sum := 0
	double := false
	for i := len(digits) - 1; i >= 0; i-- {
		c := digits[i]
		if c < '0' || c > '9' {
			return false
		}
		d := int(c - '0')
		if double {
			d *= 2
			if d > 9 {
				d -= 9
			}
		}
		sum += d
		double = !double
	}
	return sum%10 == 0
}

func cardBrand(number string) string {
	switch {
	case strings.HasPrefix(number, "4"):
		return "visa"
	case strings.HasPrefix(number, "5"), strings.HasPrefix(number, "2"):
		return "mastercard"
	case strings.HasPrefix(number, "34"), strings.HasPrefix(number, "37"):
		return "amex"
	case strings.HasPrefix(number, "6"):
		return "discover"
	default:
		return "card"
	}
}

// Well-known test numbers, matching Stripe's published test cards so QA
// scripts written for one provider work against the other.
const (
	SandboxCardSuccess      = "4242424242424242"
	SandboxCardDeclined     = "4000000000000002"
	SandboxCardRenewalFails = "4000000000000341" // first charge ok, renewals fail
)

// CompleteCheckout is what the hosted page calls when the member submits
// the card form. On success it emits, in order, checkout.session.completed,
// customer.subscription.created and invoice.paid.
func (s *Sandbox) CompleteCheckout(sessionID string, card SandboxCard) (redirectURL string, err error) {
	number := strings.ReplaceAll(strings.TrimSpace(card.Number), " ", "")
	now := s.now()

	s.mu.Lock()
	session, ok := s.sessions[sessionID]
	if !ok {
		s.mu.Unlock()
		return "", ErrNotFound
	}
	if session.Status == "complete" {
		url := session.SuccessURL
		s.mu.Unlock()
		return url, nil
	}
	if now.After(session.ExpiresAt) {
		session.Status = "expired"
		s.mu.Unlock()
		return "", errors.New("this checkout has expired; start again from the app")
	}
	if !luhnValid(number) {
		session.LastError = "Enter a valid card number."
		s.mu.Unlock()
		return "", ErrCardDeclined
	}
	if card.ExpYear < now.Year() || (card.ExpYear == now.Year() && card.ExpMonth < int(now.Month())) || card.ExpMonth < 1 || card.ExpMonth > 12 {
		session.LastError = "The card has expired."
		s.mu.Unlock()
		return "", ErrCardDeclined
	}
	if len(strings.TrimSpace(card.CVC)) < 3 {
		session.LastError = "Enter the security code."
		s.mu.Unlock()
		return "", ErrCardDeclined
	}
	if number == SandboxCardDeclined {
		session.LastError = "Your card was declined."
		s.mu.Unlock()
		return "", ErrCardDeclined
	}

	if session.Mode == "setup" {
		card := CardSummary{Brand: cardBrand(number), Last4: number[len(number)-4:], ExpMonth: card.ExpMonth, ExpYear: card.ExpYear}
		intentID := "seti_sandbox_" + randomToken(8)
		s.setupIntents[intentID] = &sandboxSetupIntent{id: intentID, customerID: session.CustomerID, subscriptionID: session.SubscriptionID, card: card}
		session.Status = "complete"
		session.LastError = ""
		successURL := session.SuccessURL
		events := [][]byte{
			s.envelopeLocked("checkout.session.completed", now, map[string]any{
				"id":                  session.ID,
				"object":              "checkout.session",
				"mode":                "setup",
				"customer":            session.CustomerID,
				"setup_intent":        intentID,
				"client_reference_id": session.UserID,
				"metadata":            session.Metadata,
				"payment_status":      "no_payment_required",
				"status":              "complete",
				"payment_method_details": map[string]any{
					"card": map[string]any{"brand": card.Brand, "last4": card.Last4, "exp_month": card.ExpMonth, "exp_year": card.ExpYear},
				},
			}),
		}
		s.mu.Unlock()
		if err := s.emit(now, events); err != nil {
			return successURL, err
		}
		return successURL, nil
	}

	if session.Mode == "payment" {
		card := CardSummary{Brand: cardBrand(number), Last4: number[len(number)-4:], ExpMonth: card.ExpMonth, ExpYear: card.ExpYear}
		session.Status = "complete"
		session.LastError = ""
		successURL := session.SuccessURL
		events := [][]byte{
			s.envelopeLocked("checkout.session.completed", now, map[string]any{
				"id":                  session.ID,
				"object":              "checkout.session",
				"mode":                "payment",
				"customer":            session.CustomerID,
				"payment_intent":      "pi_sandbox_" + randomToken(6),
				"amount_total":        session.AmountMinor,
				"currency":            strings.ToLower(session.Currency),
				"client_reference_id": session.UserID,
				"metadata":            session.Metadata,
				"payment_status":      "paid",
				"status":              "complete",
				"payment_method_details": map[string]any{
					"card": map[string]any{"brand": card.Brand, "last4": card.Last4, "exp_month": card.ExpMonth, "exp_year": card.ExpYear},
				},
			}),
		}
		s.mu.Unlock()
		if err := s.emit(now, events); err != nil {
			return successURL, err
		}
		return successURL, nil
	}

	interval := "month"
	periodEnd := now.AddDate(0, 1, 0)
	if session.BillingCycle == "yearly" {
		interval = "year"
		periodEnd = now.AddDate(1, 0, 0)
	}
	sub := &sandboxSubscription{
		id:          "sub_sandbox_" + randomToken(10),
		customerID:  session.CustomerID,
		userID:      session.UserID,
		status:      "active",
		periodStart: now,
		periodEnd:   periodEnd,
		interval:    interval,
		amountMinor: session.AmountMinor,
		currency:    session.Currency,
		card: CardSummary{
			Brand:    cardBrand(number),
			Last4:    number[len(number)-4:],
			ExpMonth: card.ExpMonth,
			ExpYear:  card.ExpYear,
		},
		metadata: copyMap(session.Metadata),
	}
	if number == SandboxCardRenewalFails {
		sub.metadata["sandbox_renewals_fail"] = "true"
	}
	s.subscriptions[sub.id] = sub
	session.Status = "complete"
	session.SubscriptionID = sub.id
	session.LastError = ""
	successURL := session.SuccessURL
	sessionCopy := *session

	events := [][]byte{
		s.envelopeLocked("checkout.session.completed", now, map[string]any{
			"id":                  sessionCopy.ID,
			"object":              "checkout.session",
			"mode":                "subscription",
			"customer":            sessionCopy.CustomerID,
			"subscription":        sub.id,
			"client_reference_id": sessionCopy.UserID,
			"metadata":            sessionCopy.Metadata,
			"payment_status":      "paid",
			"status":              "complete",
		}),
		s.envelopeLocked("customer.subscription.created", now, s.subscriptionObjectLocked(sub)),
		s.envelopeLocked("invoice.paid", now, s.invoiceObjectLocked(sub, "subscription_create", true, "")),
	}
	s.mu.Unlock()

	if err := s.emit(now, events); err != nil {
		return successURL, err
	}
	return successURL, nil
}

func copyMap(in map[string]string) map[string]string {
	out := make(map[string]string, len(in))
	for k, v := range in {
		out[k] = v
	}
	return out
}

// RestoreSubscription rebuilds an in-memory subscription from the BFF's
// durable ledger. The sandbox has no storage of its own, so after a process
// restart a subscription the member bought earlier would be unknown to it
// (a real provider keeps that state itself). The ledger row is the source of
// truth for the local stand-in.
func (s *Sandbox) RestoreSubscription(userID string, snap SubscriptionSnapshot) {
	if strings.TrimSpace(snap.SubscriptionID) == "" || strings.TrimSpace(userID) == "" {
		return
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	if _, exists := s.subscriptions[snap.SubscriptionID]; exists {
		return
	}
	status := "active"
	switch snap.Status {
	case StatusPastDue:
		status = "past_due"
	case StatusCancelled, StatusExpired:
		status = "canceled"
	case StatusIncomplete:
		status = "incomplete"
	case StatusPaused:
		status = "paused"
	}
	customerID := snap.CustomerID
	if customerID == "" {
		customerID = s.customers[userID]
	}
	if customerID == "" {
		customerID = "cus_sandbox_" + randomToken(8)
	}
	s.customers[userID] = customerID
	interval := "month"
	if snap.Interval == "year" {
		interval = "year"
	}
	meta := copyMap(snap.Metadata)
	if meta == nil {
		meta = map[string]string{}
	}
	meta["user_id"] = userID
	sub := &sandboxSubscription{
		id:                snap.SubscriptionID,
		customerID:        customerID,
		userID:            userID,
		status:            status,
		cancelAtPeriodEnd: snap.CancelAtPeriodEnd,
		periodStart:       snap.CurrentPeriodStart,
		periodEnd:         snap.CurrentPeriodEnd,
		interval:          interval,
		amountMinor:       snap.AmountMinor,
		currency:          strings.ToUpper(snap.Currency),
		metadata:          meta,
	}
	if snap.CanceledAt != nil {
		sub.canceledAt = *snap.CanceledAt
	}
	if snap.Card != nil {
		sub.card = *snap.Card
	} else {
		sub.card = CardSummary{Brand: "card", Last4: "0000"}
	}
	if sub.periodStart.IsZero() {
		sub.periodStart = s.now()
	}
	if sub.periodEnd.IsZero() {
		if interval == "year" {
			sub.periodEnd = sub.periodStart.AddDate(1, 0, 0)
		} else {
			sub.periodEnd = sub.periodStart.AddDate(0, 1, 0)
		}
	}
	s.subscriptions[sub.id] = sub
}

// FetchSubscription implements Provider.
func (s *Sandbox) FetchSubscription(_ context.Context, providerSubscriptionID string) (SubscriptionSnapshot, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	sub, ok := s.subscriptions[providerSubscriptionID]
	if !ok {
		return SubscriptionSnapshot{}, ErrNotFound
	}
	raw, _ := json.Marshal(s.subscriptionObjectLocked(sub))
	var parsed stripeSubscription
	if err := json.Unmarshal(raw, &parsed); err != nil {
		return SubscriptionSnapshot{}, err
	}
	return snapshotFromStripeSubscription(parsed), nil
}

// SetCancelAtPeriodEnd implements Provider and emits
// customer.subscription.updated so the local row converges through the
// same path a real provider would use.
func (s *Sandbox) SetCancelAtPeriodEnd(_ context.Context, providerSubscriptionID string, cancel bool) error {
	now := s.now()
	s.mu.Lock()
	sub, ok := s.subscriptions[providerSubscriptionID]
	if !ok {
		s.mu.Unlock()
		return ErrNotFound
	}
	if sub.status == "canceled" {
		s.mu.Unlock()
		return errors.New("subscription is already cancelled")
	}
	sub.cancelAtPeriodEnd = cancel
	if cancel {
		sub.canceledAt = now
	} else {
		sub.canceledAt = time.Time{}
	}
	events := [][]byte{s.envelopeLocked("customer.subscription.updated", now, s.subscriptionObjectLocked(sub))}
	s.mu.Unlock()
	return s.emit(now, events)
}

// AdvancePeriod simulates the renewal clock reaching the end of the current
// period. A subscription flagged cancel-at-period-end ends; otherwise the
// card is charged again and either invoice.paid or invoice.payment_failed is
// emitted. forceFail makes the renewal charge fail regardless of the card.
func (s *Sandbox) AdvancePeriod(providerSubscriptionID string, forceFail bool) error {
	now := s.now()
	s.mu.Lock()
	sub, ok := s.subscriptions[providerSubscriptionID]
	if !ok {
		s.mu.Unlock()
		return ErrNotFound
	}
	if sub.status == "canceled" {
		s.mu.Unlock()
		return errors.New("subscription is already cancelled")
	}
	var events [][]byte
	if sub.cancelAtPeriodEnd {
		sub.status = "canceled"
		sub.canceledAt = now
		events = append(events, s.envelopeLocked("customer.subscription.deleted", now, s.subscriptionObjectLocked(sub)))
	} else {
		sub.periodStart = sub.periodEnd
		if sub.interval == "year" {
			sub.periodEnd = sub.periodStart.AddDate(1, 0, 0)
		} else {
			sub.periodEnd = sub.periodStart.AddDate(0, 1, 0)
		}
		fails := forceFail || sub.metadata["sandbox_renewals_fail"] == "true"
		if fails {
			sub.status = "past_due"
			events = append(events,
				s.envelopeLocked("invoice.payment_failed", now, s.invoiceObjectLocked(sub, "subscription_cycle", false, "Your card was declined.")),
				s.envelopeLocked("customer.subscription.updated", now, s.subscriptionObjectLocked(sub)),
			)
		} else {
			sub.status = "active"
			events = append(events,
				s.envelopeLocked("invoice.paid", now, s.invoiceObjectLocked(sub, "subscription_cycle", true, "")),
				s.envelopeLocked("customer.subscription.updated", now, s.subscriptionObjectLocked(sub)),
			)
		}
	}
	s.mu.Unlock()
	return s.emit(now, events)
}

// RefundLastCharge emits charge.refunded for the most recent paid invoice.
func (s *Sandbox) RefundLastCharge(providerSubscriptionID string) error {
	return s.RefundCharge(providerSubscriptionID, "", "", 0)
}

// RefundCharge emits charge.refunded. When chargeID/intentID are empty the
// most recent charge the sandbox remembers is used; callers that restored a
// subscription after a restart pass the ids from their own ledger instead.
func (s *Sandbox) RefundCharge(providerSubscriptionID, chargeID, intentID string, amountMinor int64) error {
	now := s.now()
	s.mu.Lock()
	sub, ok := s.subscriptions[providerSubscriptionID]
	if !ok {
		s.mu.Unlock()
		return ErrNotFound
	}
	if chargeID == "" && intentID == "" {
		chargeID, intentID = sub.lastChargeID, sub.lastIntentID
		if amountMinor <= 0 {
			amountMinor = sub.lastChargeAmount
		}
	}
	if chargeID == "" && intentID == "" {
		s.mu.Unlock()
		return ErrNotFound
	}
	if chargeID == "" {
		chargeID = "ch_for_" + intentID
	}
	if amountMinor <= 0 {
		amountMinor = sub.amountMinor
	}
	events := [][]byte{s.envelopeLocked("charge.refunded", now, map[string]any{
		"id":              chargeID,
		"object":          "charge",
		"payment_intent":  intentID,
		"amount":          amountMinor,
		"amount_refunded": amountMinor,
		"currency":        strings.ToLower(sub.currency),
		"refunded":        true,
	})}
	s.mu.Unlock()
	return s.emit(now, events)
}

func (s *Sandbox) subscriptionObjectLocked(sub *sandboxSubscription) map[string]any {
	var canceledAt any
	if !sub.canceledAt.IsZero() {
		canceledAt = sub.canceledAt.Unix()
	}
	return map[string]any{
		"id":                   sub.id,
		"object":               "subscription",
		"customer":             sub.customerID,
		"status":               sub.status,
		"cancel_at_period_end": sub.cancelAtPeriodEnd,
		"canceled_at":          canceledAt,
		"current_period_start": sub.periodStart.Unix(),
		"current_period_end":   sub.periodEnd.Unix(),
		"metadata":             sub.metadata,
		"default_payment_method": map[string]any{
			"id":   "pm_sandbox_" + sub.card.Last4,
			"card": map[string]any{"brand": sub.card.Brand, "last4": sub.card.Last4, "exp_month": sub.card.ExpMonth, "exp_year": sub.card.ExpYear},
		},
		"items": map[string]any{
			"data": []map[string]any{{
				"id":                   "si_" + sub.id,
				"current_period_start": sub.periodStart.Unix(),
				"current_period_end":   sub.periodEnd.Unix(),
				"price": map[string]any{
					"id":          "price_sandbox_" + sub.metadata["plan_code"] + "_" + sub.interval,
					"unit_amount": sub.amountMinor,
					"currency":    strings.ToLower(sub.currency),
					"recurring":   map[string]any{"interval": sub.interval},
				},
			}},
		},
	}
}

func (s *Sandbox) invoiceObjectLocked(sub *sandboxSubscription, reason string, paid bool, failure string) map[string]any {
	s.invoiceSeq++
	invoiceID := fmt.Sprintf("in_sandbox_%03d_%s", s.invoiceSeq, randomToken(8))
	intentID := "pi_sandbox_" + randomToken(6)
	chargeID := "ch_sandbox_" + randomToken(6)
	amountPaid := sub.amountMinor
	if !paid {
		amountPaid = 0
	} else {
		sub.lastInvoiceID = invoiceID
		sub.lastChargeID = chargeID
		sub.lastIntentID = intentID
		sub.lastChargeAmount = amountPaid
	}
	return map[string]any{
		"id":              invoiceID,
		"object":          "invoice",
		"customer":        sub.customerID,
		"subscription":    sub.id,
		"payment_intent":  intentID,
		"charge":          chargeID,
		"amount_paid":     amountPaid,
		"amount_due":      sub.amountMinor,
		"currency":        strings.ToLower(sub.currency),
		"paid":            paid,
		"status":          map[bool]string{true: "paid", false: "open"}[paid],
		"billing_reason":  reason,
		"metadata":        sub.metadata,
		"failure_message": failure,
		"payment_method_details": map[string]any{
			"card": map[string]any{"brand": sub.card.Brand, "last4": sub.card.Last4, "exp_month": sub.card.ExpMonth, "exp_year": sub.card.ExpYear},
		},
		"lines": map[string]any{
			"data": []map[string]any{{
				"period": map[string]any{"start": sub.periodStart.Unix(), "end": sub.periodEnd.Unix()},
			}},
		},
	}
}

func (s *Sandbox) envelopeLocked(eventType string, at time.Time, object map[string]any) []byte {
	// Random ids, never a counter: a restarted sandbox would otherwise reuse
	// ids from the previous process and its events would be deduplicated
	// away by the ledger as replays.
	s.eventSeq++
	payload, _ := json.Marshal(map[string]any{
		"id":      fmt.Sprintf("evt_sandbox_%d_%s", s.eventSeq, randomToken(10)),
		"object":  "event",
		"type":    eventType,
		"created": at.Unix(),
		"data":    map[string]any{"object": object},
	})
	return payload
}

func (s *Sandbox) emit(at time.Time, payloads [][]byte) error {
	if s.deliver == nil {
		return errors.New("sandbox webhook deliverer is not installed")
	}
	for _, payload := range payloads {
		if err := s.deliver(payload, SignPayload(s.secret, at, payload)); err != nil {
			return err
		}
	}
	return nil
}

// ParseWebhook implements Provider.
func (s *Sandbox) ParseWebhook(payload []byte, signatureHeader string, now time.Time) (Event, error) {
	if err := VerifySignature(s.secret, signatureHeader, payload, now, DefaultSignatureTolerance); err != nil {
		return Event{}, err
	}
	return parseStripeEvent(s.Name(), payload)
}
