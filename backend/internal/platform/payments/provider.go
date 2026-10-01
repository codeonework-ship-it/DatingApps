// Package payments defines the provider-agnostic contract the mobile BFF uses
// to sell auto-renewing card subscriptions.
//
// The BFF never talks to a payment provider directly. It asks a Provider to
// create a hosted card checkout, and it learns the outcome — first charge,
// every renewal, failures, cancellations and refunds — exclusively from
// signed webhook events that the Provider verifies and normalises. Money
// state is therefore driven by what the provider actually settled, never by
// what the client claimed to have paid.
package payments

import (
	"context"
	"encoding/json"
	"errors"
	"time"
)

// ErrSignature is returned when a webhook payload does not carry a valid
// signature for the configured secret, or when its timestamp is outside the
// replay tolerance.
var ErrSignature = errors.New("webhook signature is invalid")

// ErrNotFound is returned when a provider object does not exist.
var ErrNotFound = errors.New("provider object not found")

// ErrCardDeclined is returned by the sandbox when a test card is declined.
var ErrCardDeclined = errors.New("card declined")

// Provider is the seam between the BFF and one payment processor.
type Provider interface {
	// Name is the stable provider code stored on every billing row
	// ("stripe", "sandbox").
	Name() string
	// EnsureCustomer returns the provider customer id for a member, creating
	// it when it does not exist yet. Callers persist the returned id so the
	// call is made once per member.
	EnsureCustomer(ctx context.Context, req CustomerRequest) (string, error)
	// CreateSubscriptionCheckout opens a hosted, card-only checkout that will
	// start an auto-renewing subscription once the first charge succeeds.
	CreateSubscriptionCheckout(ctx context.Context, req CheckoutRequest) (CheckoutSession, error)
	// CreatePaymentCheckout opens a hosted, card-only checkout for a single
	// charge (coin packages). The outcome arrives as checkout.completed with
	// Mode "payment".
	CreatePaymentCheckout(ctx context.Context, req PaymentCheckoutRequest) (CheckoutSession, error)
	// FetchSubscription returns the provider's current view of a subscription,
	// including the card on file. Used after checkout completes so the local
	// row starts from the settled state rather than from the request.
	FetchSubscription(ctx context.Context, providerSubscriptionID string) (SubscriptionSnapshot, error)
	// SetCancelAtPeriodEnd turns auto-renew off (true) or back on (false)
	// while keeping the current paid period.
	SetCancelAtPeriodEnd(ctx context.Context, providerSubscriptionID string, cancel bool) error
	// ChangeSubscriptionPlan moves a live subscription to another plan or
	// cycle. Upgrades invoice the prorated difference immediately; downgrades
	// credit the unused time against the next invoice.
	ChangeSubscriptionPlan(ctx context.Context, req ChangePlanRequest) error
	// CreateSetupCheckout opens a hosted, card-only page that collects a new
	// card without charging it. The outcome arrives as checkout.completed
	// with Mode "setup" and a SetupIntentID.
	CreateSetupCheckout(ctx context.Context, req SetupCheckoutRequest) (CheckoutSession, error)
	// ApplySetupPaymentMethod makes the card collected by a setup checkout
	// the subscription's (and customer's) default and returns its summary.
	ApplySetupPaymentMethod(ctx context.Context, setupIntentID, providerSubscriptionID string) (*CardSummary, error)
	// ParseWebhook verifies the signature and converts the raw payload into a
	// normalised Event. It must return ErrSignature for a bad signature.
	ParseWebhook(payload []byte, signatureHeader string, now time.Time) (Event, error)
}

// CustomerRequest identifies the member a provider customer is created for.
type CustomerRequest struct {
	UserID string
	Email  string
	Name   string
}

// CheckoutRequest describes one subscription checkout.
type CheckoutRequest struct {
	// CheckoutID is the BFF's own checkout row id; it is echoed back in
	// webhook metadata so the completion event can be tied to the request.
	CheckoutID     string
	UserID         string
	CustomerID     string
	PlanCode       string
	PlanName       string
	BillingCycle   string // "monthly" | "yearly"
	AmountMinor    int64
	Currency       string // ISO-4217 lower or upper case
	ProviderPrice  string // optional pre-created recurring price id
	SuccessURL     string
	CancelURL      string
	IdempotencyKey string
}

// PaymentCheckoutRequest describes one single-charge checkout.
type PaymentCheckoutRequest struct {
	CheckoutID     string
	UserID         string
	CustomerID     string
	Description    string
	AmountMinor    int64
	Currency       string
	Metadata       map[string]string
	SuccessURL     string
	CancelURL      string
	IdempotencyKey string
}

// ChangePlanRequest describes a plan or cycle switch on a live subscription.
type ChangePlanRequest struct {
	SubscriptionID string
	ItemID         string
	PlanCode       string
	PlanName       string
	BillingCycle   string // "monthly" | "yearly"
	AmountMinor    int64
	Currency       string
	ProviderPrice  string // optional pre-created recurring price id
	// Upgrade selects immediate invoicing of the prorated difference.
	Upgrade bool
}

// SetupCheckoutRequest describes a card-replacement checkout.
type SetupCheckoutRequest struct {
	CheckoutID     string
	UserID         string
	CustomerID     string
	SubscriptionID string
	SuccessURL     string
	CancelURL      string
	IdempotencyKey string
}

// CheckoutSession is the hosted page the member must open to pay.
type CheckoutSession struct {
	ProviderSessionID string
	URL               string
	ExpiresAt         time.Time
}

// CardSummary is the non-sensitive card description a provider exposes.
type CardSummary struct {
	Brand    string `json:"brand"`
	Last4    string `json:"last4"`
	ExpMonth int    `json:"exp_month,omitempty"`
	ExpYear  int    `json:"exp_year,omitempty"`
}

// Normalised subscription statuses. Every provider status is mapped onto one
// of these before it reaches the database.
const (
	StatusIncomplete = "incomplete"
	StatusActive     = "active"
	StatusPastDue    = "past_due"
	StatusCancelled  = "cancelled"
	StatusExpired    = "expired"
	StatusPaused     = "paused"
)

// SubscriptionSnapshot is the provider's view of one subscription at a point
// in time. It is produced both by webhooks and by FetchSubscription.
type SubscriptionSnapshot struct {
	SubscriptionID     string
	CustomerID         string
	Status             string
	CancelAtPeriodEnd  bool
	CanceledAt         *time.Time
	CurrentPeriodStart time.Time
	CurrentPeriodEnd   time.Time
	Interval           string // "month" | "year"
	ItemID             string
	AmountMinor        int64
	Currency           string
	Card               *CardSummary
	Metadata           map[string]string
}

// EventType is the normalised webhook event kind.
type EventType string

const (
	EventCheckoutCompleted    EventType = "checkout.completed"
	EventInvoicePaid          EventType = "invoice.paid"
	EventInvoicePaymentFailed EventType = "invoice.payment_failed"
	EventSubscriptionUpdated  EventType = "subscription.updated"
	EventSubscriptionDeleted  EventType = "subscription.deleted"
	EventChargeRefunded       EventType = "charge.refunded"
	EventDisputeUpdated       EventType = "dispute.updated"
	// EventIgnored marks a verified event the BFF has no interest in. It is
	// still recorded for deduplication and audit.
	EventIgnored EventType = "ignored"
)

// Event is one verified, normalised webhook delivery.
type Event struct {
	Provider  string
	ID        string
	Type      EventType
	RawType   string
	CreatedAt time.Time
	Raw       json.RawMessage

	Checkout     *CheckoutEvent
	Invoice      *InvoiceEvent
	Subscription *SubscriptionSnapshot
	Refund       *RefundEvent
	Dispute      *DisputeEvent
}

// DisputeEvent reports a chargeback being opened or resolved.
type DisputeEvent struct {
	DisputeID       string
	ChargeID        string
	PaymentIntentID string
	AmountMinor     int64
	Currency        string
	// Status follows Stripe: warning_needs_response, needs_response,
	// under_review, won, lost, warning_closed, charge_refunded.
	Status string
	Reason string
	Closed bool
}

// CheckoutEvent reports that a hosted checkout finished and a subscription
// exists at the provider.
type CheckoutEvent struct {
	SessionID      string
	CustomerID     string
	SubscriptionID string
	// Mode is "subscription", "payment" or "setup".
	Mode            string
	PaymentIntentID string
	SetupIntentID   string
	AmountMinor     int64
	Currency        string
	PaymentStatus   string
	Card            *CardSummary
	Metadata        map[string]string
}

// InvoiceEvent reports a settled or failed charge for one billing period.
type InvoiceEvent struct {
	InvoiceID       string
	SubscriptionID  string
	CustomerID      string
	PaymentIntentID string
	ChargeID        string
	AmountMinor     int64
	Currency        string
	Paid            bool
	BillingReason   string // "subscription_create" | "subscription_cycle" | ...
	PeriodStart     time.Time
	PeriodEnd       time.Time
	FailureMessage  string
	Card            *CardSummary
	Metadata        map[string]string
}

// RefundEvent reports money returned on an earlier charge.
type RefundEvent struct {
	ChargeID        string
	PaymentIntentID string
	AmountRefunded  int64
	AmountCharged   int64
	Currency        string
	FullyRefunded   bool
}
