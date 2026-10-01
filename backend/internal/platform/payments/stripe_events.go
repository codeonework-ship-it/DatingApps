package payments

import (
	"encoding/json"
	"fmt"
	"strings"
	"time"
)

// stripeEnvelope is the outer shape of every Stripe webhook payload. The
// sandbox provider emits the same shape so one parser serves both.
type stripeEnvelope struct {
	ID      string `json:"id"`
	Type    string `json:"type"`
	Created int64  `json:"created"`
	Data    struct {
		Object json.RawMessage `json:"object"`
	} `json:"data"`
}

type stripeCard struct {
	Brand    string `json:"brand"`
	Last4    string `json:"last4"`
	ExpMonth int    `json:"exp_month"`
	ExpYear  int    `json:"exp_year"`
}

type stripePaymentMethod struct {
	ID   string      `json:"id"`
	Card *stripeCard `json:"card"`
}

// stripeRef accepts either an id string or an expanded object with an id.
type stripeRef struct {
	ID string
}

func (r *stripeRef) UnmarshalJSON(data []byte) error {
	trimmed := strings.TrimSpace(string(data))
	if trimmed == "null" || trimmed == "" {
		r.ID = ""
		return nil
	}
	var id string
	if err := json.Unmarshal(data, &id); err == nil {
		r.ID = id
		return nil
	}
	var obj struct {
		ID string `json:"id"`
	}
	if err := json.Unmarshal(data, &obj); err != nil {
		return err
	}
	r.ID = obj.ID
	return nil
}

type stripePeriod struct {
	Start int64 `json:"start"`
	End   int64 `json:"end"`
}

type stripeSubscriptionItem struct {
	ID                 string `json:"id"`
	CurrentPeriodStart int64  `json:"current_period_start"`
	CurrentPeriodEnd   int64  `json:"current_period_end"`
	Price              struct {
		ID         string `json:"id"`
		UnitAmount int64  `json:"unit_amount"`
		Currency   string `json:"currency"`
		Recurring  struct {
			Interval string `json:"interval"`
		} `json:"recurring"`
	} `json:"price"`
}

type stripeSubscription struct {
	ID                   string            `json:"id"`
	Customer             stripeRef         `json:"customer"`
	Status               string            `json:"status"`
	CancelAtPeriodEnd    bool              `json:"cancel_at_period_end"`
	CanceledAt           int64             `json:"canceled_at"`
	CurrentPeriodStart   int64             `json:"current_period_start"`
	CurrentPeriodEnd     int64             `json:"current_period_end"`
	DefaultPaymentMethod json.RawMessage   `json:"default_payment_method"`
	Metadata             map[string]string `json:"metadata"`
	Items                struct {
		Data []stripeSubscriptionItem `json:"data"`
	} `json:"items"`
}

type stripeInvoice struct {
	ID            string            `json:"id"`
	Customer      stripeRef         `json:"customer"`
	Subscription  stripeRef         `json:"subscription"`
	PaymentIntent stripeRef         `json:"payment_intent"`
	Charge        stripeRef         `json:"charge"`
	AmountPaid    int64             `json:"amount_paid"`
	AmountDue     int64             `json:"amount_due"`
	Currency      string            `json:"currency"`
	Paid          bool              `json:"paid"`
	Status        string            `json:"status"`
	BillingReason string            `json:"billing_reason"`
	Metadata      map[string]string `json:"metadata"`
	Parent        *struct {
		SubscriptionDetails *struct {
			Subscription stripeRef         `json:"subscription"`
			Metadata     map[string]string `json:"metadata"`
		} `json:"subscription_details"`
	} `json:"parent"`
	SubscriptionDetails *struct {
		Metadata map[string]string `json:"metadata"`
	} `json:"subscription_details"`
	Lines struct {
		Data []struct {
			Period stripePeriod `json:"period"`
		} `json:"data"`
	} `json:"lines"`
	LastFinalizationError *struct {
		Message string `json:"message"`
	} `json:"last_finalization_error"`
	// Sandbox-only enrichment so the local flow can show the card used.
	PaymentMethodDetails *struct {
		Card *stripeCard `json:"card"`
	} `json:"payment_method_details"`
	FailureMessage string `json:"failure_message"`
}

type stripeCheckoutSession struct {
	ID                string            `json:"id"`
	Mode              string            `json:"mode"`
	Customer          stripeRef         `json:"customer"`
	Subscription      stripeRef         `json:"subscription"`
	PaymentIntent     stripeRef         `json:"payment_intent"`
	SetupIntent       stripeRef         `json:"setup_intent"`
	AmountTotal       int64             `json:"amount_total"`
	Currency          string            `json:"currency"`
	ClientReferenceID string            `json:"client_reference_id"`
	Metadata          map[string]string `json:"metadata"`
	PaymentStatus     string            `json:"payment_status"`
	Status            string            `json:"status"`
	// Sandbox-only enrichment.
	PaymentMethodDetails *struct {
		Card *stripeCard `json:"card"`
	} `json:"payment_method_details"`
}

type stripeCharge struct {
	ID             string    `json:"id"`
	PaymentIntent  stripeRef `json:"payment_intent"`
	Amount         int64     `json:"amount"`
	AmountRefunded int64     `json:"amount_refunded"`
	Currency       string    `json:"currency"`
	Refunded       bool      `json:"refunded"`
}

func unixTime(v int64) time.Time {
	if v <= 0 {
		return time.Time{}
	}
	return time.Unix(v, 0).UTC()
}

// normalizeStripeStatus maps Stripe subscription statuses onto the BFF's
// vocabulary.
func normalizeStripeStatus(status string) string {
	switch strings.ToLower(strings.TrimSpace(status)) {
	case "active", "trialing":
		return StatusActive
	case "past_due", "unpaid":
		return StatusPastDue
	case "canceled", "cancelled":
		return StatusCancelled
	case "incomplete":
		return StatusIncomplete
	case "incomplete_expired":
		return StatusExpired
	case "paused":
		return StatusPaused
	default:
		return StatusIncomplete
	}
}

func cardFromRaw(raw json.RawMessage) *CardSummary {
	if len(raw) == 0 {
		return nil
	}
	var pm stripePaymentMethod
	if err := json.Unmarshal(raw, &pm); err != nil || pm.Card == nil {
		return nil
	}
	return &CardSummary{Brand: pm.Card.Brand, Last4: pm.Card.Last4, ExpMonth: pm.Card.ExpMonth, ExpYear: pm.Card.ExpYear}
}

func snapshotFromStripeSubscription(sub stripeSubscription) SubscriptionSnapshot {
	snap := SubscriptionSnapshot{
		SubscriptionID:     sub.ID,
		CustomerID:         sub.Customer.ID,
		Status:             normalizeStripeStatus(sub.Status),
		CancelAtPeriodEnd:  sub.CancelAtPeriodEnd,
		CurrentPeriodStart: unixTime(sub.CurrentPeriodStart),
		CurrentPeriodEnd:   unixTime(sub.CurrentPeriodEnd),
		Metadata:           sub.Metadata,
		Card:               cardFromRaw(sub.DefaultPaymentMethod),
	}
	if sub.CanceledAt > 0 {
		at := unixTime(sub.CanceledAt)
		snap.CanceledAt = &at
	}
	if len(sub.Items.Data) > 0 {
		item := sub.Items.Data[0]
		// Newer Stripe API versions moved the period onto the item.
		if snap.CurrentPeriodStart.IsZero() {
			snap.CurrentPeriodStart = unixTime(item.CurrentPeriodStart)
		}
		if snap.CurrentPeriodEnd.IsZero() {
			snap.CurrentPeriodEnd = unixTime(item.CurrentPeriodEnd)
		}
		snap.ItemID = item.ID
		snap.Interval = item.Price.Recurring.Interval
		snap.AmountMinor = item.Price.UnitAmount
		snap.Currency = strings.ToUpper(item.Price.Currency)
	}
	return snap
}

// parseStripeEvent converts an already-verified Stripe-shaped payload into a
// normalised Event.
func parseStripeEvent(provider string, payload []byte) (Event, error) {
	var env stripeEnvelope
	if err := json.Unmarshal(payload, &env); err != nil {
		return Event{}, fmt.Errorf("decode webhook envelope: %w", err)
	}
	if strings.TrimSpace(env.ID) == "" || strings.TrimSpace(env.Type) == "" {
		return Event{}, fmt.Errorf("webhook envelope is missing id or type")
	}
	event := Event{
		Provider:  provider,
		ID:        env.ID,
		RawType:   env.Type,
		CreatedAt: unixTime(env.Created),
		Raw:       json.RawMessage(payload),
		Type:      EventIgnored,
	}
	if event.CreatedAt.IsZero() {
		event.CreatedAt = time.Now().UTC()
	}
	switch env.Type {
	case "checkout.session.completed":
		var session stripeCheckoutSession
		if err := json.Unmarshal(env.Data.Object, &session); err != nil {
			return Event{}, fmt.Errorf("decode checkout session: %w", err)
		}
		event.Type = EventCheckoutCompleted
		mode := session.Mode
		if mode == "" {
			switch {
			case session.Subscription.ID != "":
				mode = "subscription"
			case session.SetupIntent.ID != "":
				mode = "setup"
			default:
				mode = "payment"
			}
		}
		event.Checkout = &CheckoutEvent{
			SessionID:       session.ID,
			Mode:            mode,
			CustomerID:      session.Customer.ID,
			SubscriptionID:  session.Subscription.ID,
			PaymentIntentID: session.PaymentIntent.ID,
			SetupIntentID:   session.SetupIntent.ID,
			AmountMinor:     session.AmountTotal,
			Currency:        strings.ToUpper(session.Currency),
			PaymentStatus:   session.PaymentStatus,
			Metadata:        session.Metadata,
		}
		if session.PaymentMethodDetails != nil && session.PaymentMethodDetails.Card != nil {
			c := session.PaymentMethodDetails.Card
			event.Checkout.Card = &CardSummary{Brand: c.Brand, Last4: c.Last4, ExpMonth: c.ExpMonth, ExpYear: c.ExpYear}
		}
	case "invoice.paid", "invoice.payment_succeeded", "invoice.payment_failed", "invoice.payment_action_required":
		var invoice stripeInvoice
		if err := json.Unmarshal(env.Data.Object, &invoice); err != nil {
			return Event{}, fmt.Errorf("decode invoice: %w", err)
		}
		inv := &InvoiceEvent{
			InvoiceID:       invoice.ID,
			SubscriptionID:  invoice.Subscription.ID,
			CustomerID:      invoice.Customer.ID,
			PaymentIntentID: invoice.PaymentIntent.ID,
			ChargeID:        invoice.Charge.ID,
			AmountMinor:     invoice.AmountPaid,
			Currency:        strings.ToUpper(invoice.Currency),
			Paid:            invoice.Paid,
			BillingReason:   invoice.BillingReason,
			Metadata:        invoice.Metadata,
			FailureMessage:  invoice.FailureMessage,
		}
		if invoice.Parent != nil && invoice.Parent.SubscriptionDetails != nil {
			if inv.SubscriptionID == "" {
				inv.SubscriptionID = invoice.Parent.SubscriptionDetails.Subscription.ID
			}
			if len(inv.Metadata) == 0 {
				inv.Metadata = invoice.Parent.SubscriptionDetails.Metadata
			}
		}
		if invoice.SubscriptionDetails != nil && len(inv.Metadata) == 0 {
			inv.Metadata = invoice.SubscriptionDetails.Metadata
		}
		if len(invoice.Lines.Data) > 0 {
			inv.PeriodStart = unixTime(invoice.Lines.Data[0].Period.Start)
			inv.PeriodEnd = unixTime(invoice.Lines.Data[0].Period.End)
		}
		if invoice.PaymentMethodDetails != nil && invoice.PaymentMethodDetails.Card != nil {
			c := invoice.PaymentMethodDetails.Card
			inv.Card = &CardSummary{Brand: c.Brand, Last4: c.Last4, ExpMonth: c.ExpMonth, ExpYear: c.ExpYear}
		}
		if env.Type == "invoice.payment_failed" || env.Type == "invoice.payment_action_required" {
			event.Type = EventInvoicePaymentFailed
			inv.Paid = false
			if inv.AmountMinor == 0 {
				inv.AmountMinor = invoice.AmountDue
			}
			if inv.FailureMessage == "" && invoice.LastFinalizationError != nil {
				inv.FailureMessage = invoice.LastFinalizationError.Message
			}
			if env.Type == "invoice.payment_action_required" && inv.FailureMessage == "" {
				inv.FailureMessage = "Your bank asked for additional authentication. Open the payment link from your provider email to confirm the renewal."
			}
		} else {
			event.Type = EventInvoicePaid
			inv.Paid = true
		}
		event.Invoice = inv
	case "customer.subscription.created", "customer.subscription.updated",
		"customer.subscription.deleted", "customer.subscription.paused", "customer.subscription.resumed":
		var sub stripeSubscription
		if err := json.Unmarshal(env.Data.Object, &sub); err != nil {
			return Event{}, fmt.Errorf("decode subscription: %w", err)
		}
		snap := snapshotFromStripeSubscription(sub)
		if env.Type == "customer.subscription.deleted" {
			event.Type = EventSubscriptionDeleted
			snap.Status = StatusCancelled
		} else {
			event.Type = EventSubscriptionUpdated
		}
		event.Subscription = &snap
	case "charge.dispute.created", "charge.dispute.updated", "charge.dispute.closed", "charge.dispute.funds_withdrawn", "charge.dispute.funds_reinstated":
		var dispute struct {
			ID            string    `json:"id"`
			Charge        stripeRef `json:"charge"`
			PaymentIntent stripeRef `json:"payment_intent"`
			Amount        int64     `json:"amount"`
			Currency      string    `json:"currency"`
			Status        string    `json:"status"`
			Reason        string    `json:"reason"`
		}
		if err := json.Unmarshal(env.Data.Object, &dispute); err != nil {
			return Event{}, fmt.Errorf("decode dispute: %w", err)
		}
		event.Type = EventDisputeUpdated
		event.Dispute = &DisputeEvent{
			DisputeID:       dispute.ID,
			ChargeID:        dispute.Charge.ID,
			PaymentIntentID: dispute.PaymentIntent.ID,
			AmountMinor:     dispute.Amount,
			Currency:        strings.ToUpper(dispute.Currency),
			Status:          dispute.Status,
			Reason:          dispute.Reason,
			Closed:          env.Type == "charge.dispute.closed" || dispute.Status == "won" || dispute.Status == "lost" || dispute.Status == "warning_closed" || dispute.Status == "charge_refunded",
		}
	case "charge.refunded":
		var charge stripeCharge
		if err := json.Unmarshal(env.Data.Object, &charge); err != nil {
			return Event{}, fmt.Errorf("decode charge: %w", err)
		}
		event.Type = EventChargeRefunded
		event.Refund = &RefundEvent{
			ChargeID:        charge.ID,
			PaymentIntentID: charge.PaymentIntent.ID,
			AmountRefunded:  charge.AmountRefunded,
			AmountCharged:   charge.Amount,
			Currency:        strings.ToUpper(charge.Currency),
			FullyRefunded:   charge.Refunded || (charge.Amount > 0 && charge.AmountRefunded >= charge.Amount),
		}
	}
	return event, nil
}
