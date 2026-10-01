package payments

import (
	"context"
	"errors"
	"io"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"
	"time"
)

func TestVerifySignature(t *testing.T) {
	payload := []byte(`{"id":"evt_1","type":"invoice.paid","created":1,"data":{"object":{}}}`)
	now := time.Unix(1_700_000_000, 0)
	header := SignPayload("whsec_test", now, payload)

	if err := VerifySignature("whsec_test", header, payload, now.Add(time.Minute), 0); err != nil {
		t.Fatalf("valid signature rejected: %v", err)
	}
	if err := VerifySignature("whsec_other", header, payload, now, 0); !errors.Is(err, ErrSignature) {
		t.Fatalf("wrong secret must fail with ErrSignature, got %v", err)
	}
	tampered := append([]byte{}, payload...)
	tampered[len(tampered)-2] = ' '
	if err := VerifySignature("whsec_test", header, tampered, now, 0); !errors.Is(err, ErrSignature) {
		t.Fatalf("tampered payload must fail, got %v", err)
	}
	if err := VerifySignature("whsec_test", header, payload, now.Add(10*time.Minute), 0); !errors.Is(err, ErrSignature) {
		t.Fatalf("stale timestamp must fail, got %v", err)
	}
	if err := VerifySignature("whsec_test", "garbage", payload, now, 0); !errors.Is(err, ErrSignature) {
		t.Fatalf("malformed header must fail, got %v", err)
	}
}

func TestParseStripeEvent_InvoiceAndSubscription(t *testing.T) {
	invoice := []byte(`{"id":"evt_inv","type":"invoice.paid","created":1700000000,"data":{"object":{
		"id":"in_1","customer":"cus_1","subscription":"sub_1","payment_intent":"pi_1","charge":"ch_1",
		"amount_paid":49900,"currency":"inr","paid":true,"billing_reason":"subscription_cycle",
		"lines":{"data":[{"period":{"start":1700000000,"end":1702592000}}]}}}}`)
	event, err := parseStripeEvent("stripe", invoice)
	if err != nil {
		t.Fatalf("parse invoice: %v", err)
	}
	if event.Type != EventInvoicePaid || event.Invoice == nil {
		t.Fatalf("expected invoice.paid event, got %+v", event)
	}
	if event.Invoice.AmountMinor != 49900 || event.Invoice.Currency != "INR" || event.Invoice.SubscriptionID != "sub_1" {
		t.Fatalf("invoice fields wrong: %+v", event.Invoice)
	}
	if event.Invoice.PeriodEnd.Unix() != 1702592000 {
		t.Fatalf("period end not parsed: %v", event.Invoice.PeriodEnd)
	}

	// Newer API shape: subscription reference under parent.subscription_details,
	// period on the item rather than the subscription.
	sub := []byte(`{"id":"evt_sub","type":"customer.subscription.updated","created":1700000001,"data":{"object":{
		"id":"sub_1","customer":{"id":"cus_1"},"status":"past_due","cancel_at_period_end":true,"canceled_at":1700000001,
		"default_payment_method":{"id":"pm_1","card":{"brand":"visa","last4":"4242","exp_month":12,"exp_year":2031}},
		"metadata":{"user_id":"u1"},
		"items":{"data":[{"current_period_start":1700000000,"current_period_end":1702592000,
		  "price":{"id":"price_1","unit_amount":49900,"currency":"inr","recurring":{"interval":"month"}}}]}}}}`)
	event, err = parseStripeEvent("stripe", sub)
	if err != nil {
		t.Fatalf("parse subscription: %v", err)
	}
	snap := event.Subscription
	if event.Type != EventSubscriptionUpdated || snap == nil {
		t.Fatalf("expected subscription.updated, got %+v", event)
	}
	if snap.Status != StatusPastDue || !snap.CancelAtPeriodEnd || snap.CanceledAt == nil {
		t.Fatalf("status/cancel flags wrong: %+v", snap)
	}
	if snap.Card == nil || snap.Card.Last4 != "4242" || snap.Card.Brand != "visa" {
		t.Fatalf("card not parsed: %+v", snap.Card)
	}
	if snap.CurrentPeriodEnd.Unix() != 1702592000 || snap.Interval != "month" || snap.AmountMinor != 49900 {
		t.Fatalf("item-derived fields wrong: %+v", snap)
	}

	deleted := []byte(`{"id":"evt_del","type":"customer.subscription.deleted","created":1700000002,"data":{"object":{"id":"sub_1","customer":"cus_1","status":"canceled"}}}`)
	event, err = parseStripeEvent("stripe", deleted)
	if err != nil || event.Type != EventSubscriptionDeleted || event.Subscription.Status != StatusCancelled {
		t.Fatalf("deleted event wrong: %+v err=%v", event, err)
	}

	unknown := []byte(`{"id":"evt_x","type":"payment_method.attached","created":1,"data":{"object":{}}}`)
	event, err = parseStripeEvent("stripe", unknown)
	if err != nil || event.Type != EventIgnored {
		t.Fatalf("unknown event must be ignored, got %+v err=%v", event, err)
	}
}

func TestStripeCheckoutRequestShape(t *testing.T) {
	var captured url.Values
	var capturedAuth, capturedIdem string
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		body, _ := io.ReadAll(r.Body)
		captured, _ = url.ParseQuery(string(body))
		capturedAuth = r.Header.Get("Authorization")
		capturedIdem = r.Header.Get("Idempotency-Key")
		switch r.URL.Path {
		case "/v1/customers":
			_, _ = w.Write([]byte(`{"id":"cus_test"}`))
		case "/v1/checkout/sessions":
			_, _ = w.Write([]byte(`{"id":"cs_test","url":"https://checkout.stripe.test/c/cs_test","expires_at":1700003600}`))
		case "/v1/subscriptions/sub_1":
			if r.Method == http.MethodGet {
				_, _ = w.Write([]byte(`{"id":"sub_1","customer":"cus_test","status":"active","current_period_start":1,"current_period_end":2,"items":{"data":[]}}`))
				return
			}
			_, _ = w.Write([]byte(`{"id":"sub_1"}`))
		default:
			w.WriteHeader(http.StatusNotFound)
			_, _ = w.Write([]byte(`{"error":{"message":"nope"}}`))
		}
	}))
	defer server.Close()

	stripe, err := NewStripe(StripeConfig{SecretKey: "sk_test_x", WebhookSecret: "whsec_x", APIBaseURL: server.URL})
	if err != nil {
		t.Fatal(err)
	}
	ctx := context.Background()
	customer, err := stripe.EnsureCustomer(ctx, CustomerRequest{UserID: "user-1"})
	if err != nil || customer != "cus_test" {
		t.Fatalf("EnsureCustomer = %q, %v", customer, err)
	}
	if !strings.HasPrefix(capturedAuth, "Basic ") || capturedIdem != "customer-user-1" {
		t.Fatalf("auth/idempotency headers wrong: %q %q", capturedAuth, capturedIdem)
	}

	session, err := stripe.CreateSubscriptionCheckout(ctx, CheckoutRequest{
		CheckoutID: "chk-1", UserID: "user-1", CustomerID: customer, PlanCode: "gold", PlanName: "Gold",
		BillingCycle: "yearly", AmountMinor: 19999, Currency: "INR",
		SuccessURL: "https://app.test/ok", CancelURL: "https://app.test/cancel", IdempotencyKey: "idem-1",
	})
	if err != nil {
		t.Fatalf("checkout: %v", err)
	}
	if session.ProviderSessionID != "cs_test" || session.URL == "" || session.ExpiresAt.IsZero() {
		t.Fatalf("session wrong: %+v", session)
	}
	for key, want := range map[string]string{
		"mode":                                           "subscription",
		"payment_method_types[0]":                        "card",
		"line_items[0][price_data][currency]":            "inr",
		"line_items[0][price_data][unit_amount]":         "19999",
		"line_items[0][price_data][recurring][interval]": "year",
		"metadata[user_id]":                              "user-1",
		"subscription_data[metadata][checkout_id]":       "chk-1",
	} {
		if got := captured.Get(key); got != want {
			t.Fatalf("form %s = %q, want %q", key, got, want)
		}
	}
	if capturedIdem != "idem-1" {
		t.Fatalf("checkout idempotency key = %q", capturedIdem)
	}

	if err := stripe.SetCancelAtPeriodEnd(ctx, "sub_1", true); err != nil {
		t.Fatalf("cancel: %v", err)
	}
	if captured.Get("cancel_at_period_end") != "true" {
		t.Fatalf("cancel form = %v", captured)
	}
	snap, err := stripe.FetchSubscription(ctx, "sub_1")
	if err != nil || snap.Status != StatusActive {
		t.Fatalf("fetch = %+v, %v", snap, err)
	}
	if _, err := stripe.FetchSubscription(ctx, "missing"); !errors.Is(err, ErrNotFound) {
		t.Fatalf("missing subscription must map to ErrNotFound, got %v", err)
	}
}

func TestSandboxLifecycleEmitsSignedStripeShapedEvents(t *testing.T) {
	sandbox, err := NewSandbox("whsec_sandbox", "http://device.test/v1")
	if err != nil {
		t.Fatal(err)
	}
	clock := time.Date(2026, 9, 27, 10, 0, 0, 0, time.UTC)
	sandbox.SetClock(func() time.Time { return clock })

	var events []Event
	sandbox.SetDeliverer(func(payload []byte, signature string) error {
		event, err := sandbox.ParseWebhook(payload, signature, clock)
		if err != nil {
			return err
		}
		events = append(events, event)
		return nil
	})

	ctx := context.Background()
	customer, _ := sandbox.EnsureCustomer(ctx, CustomerRequest{UserID: "user-1"})
	again, _ := sandbox.EnsureCustomer(ctx, CustomerRequest{UserID: "user-1"})
	if customer == "" || customer != again {
		t.Fatalf("customer must be stable: %q %q", customer, again)
	}
	session, err := sandbox.CreateSubscriptionCheckout(ctx, CheckoutRequest{
		CheckoutID: "chk-1", UserID: "user-1", CustomerID: customer, PlanCode: "gold", PlanName: "Gold",
		BillingCycle: "monthly", AmountMinor: 1999, Currency: "inr", SuccessURL: "http://device.test/v1/billing/checkout/return?ok=1", CancelURL: "http://device.test/v1/billing/checkout/return?ok=0",
	})
	if err != nil {
		t.Fatal(err)
	}
	if !strings.HasPrefix(session.URL, "http://device.test/v1/billing/sandbox/checkout/") {
		t.Fatalf("checkout url = %q", session.URL)
	}

	card := SandboxCard{Number: SandboxCardDeclined, ExpMonth: 12, ExpYear: 2031, CVC: "123"}
	if _, err := sandbox.CompleteCheckout(session.ProviderSessionID, card); !errors.Is(err, ErrCardDeclined) {
		t.Fatalf("declined card must fail, got %v", err)
	}
	if len(events) != 0 {
		t.Fatalf("a declined checkout must not emit events, got %d", len(events))
	}

	card.Number = "4242 4242 4242 4242"
	redirect, err := sandbox.CompleteCheckout(session.ProviderSessionID, card)
	if err != nil {
		t.Fatalf("complete checkout: %v", err)
	}
	if redirect != "http://device.test/v1/billing/checkout/return?ok=1" {
		t.Fatalf("redirect = %q", redirect)
	}
	if len(events) != 3 || events[0].Type != EventCheckoutCompleted || events[1].Type != EventSubscriptionUpdated || events[2].Type != EventInvoicePaid {
		t.Fatalf("unexpected event sequence: %+v", eventTypes(events))
	}
	subID := events[0].Checkout.SubscriptionID
	if subID == "" || events[2].Invoice.SubscriptionID != subID || events[2].Invoice.AmountMinor != 1999 {
		t.Fatalf("events disagree on subscription: %+v", events)
	}
	if events[1].Subscription.Card == nil || events[1].Subscription.Card.Last4 != "4242" {
		t.Fatalf("card missing from subscription event: %+v", events[1].Subscription)
	}
	if events[2].Invoice.BillingReason != "subscription_create" {
		t.Fatalf("first invoice reason = %q", events[2].Invoice.BillingReason)
	}

	// Renewal: the clock reaches the period end and the card is charged again.
	events = nil
	clock = clock.AddDate(0, 1, 0)
	if err := sandbox.AdvancePeriod(subID, false); err != nil {
		t.Fatal(err)
	}
	if len(events) != 2 || events[0].Type != EventInvoicePaid || events[0].Invoice.BillingReason != "subscription_cycle" {
		t.Fatalf("renewal events wrong: %+v", eventTypes(events))
	}
	if !events[1].Subscription.CurrentPeriodEnd.After(clock) {
		t.Fatalf("renewal must advance the period end: %v <= %v", events[1].Subscription.CurrentPeriodEnd, clock)
	}

	// Failed renewal moves the subscription to past_due.
	events = nil
	if err := sandbox.AdvancePeriod(subID, true); err != nil {
		t.Fatal(err)
	}
	if len(events) != 2 || events[0].Type != EventInvoicePaymentFailed || events[1].Subscription.Status != StatusPastDue {
		t.Fatalf("failed renewal events wrong: %+v", eventTypes(events))
	}

	// Turning auto-renew off keeps the period and flags cancel_at_period_end;
	// the next period boundary then ends the subscription.
	events = nil
	if err := sandbox.SetCancelAtPeriodEnd(ctx, subID, true); err != nil {
		t.Fatal(err)
	}
	if len(events) != 1 || !events[0].Subscription.CancelAtPeriodEnd {
		t.Fatalf("cancel event wrong: %+v", events)
	}
	events = nil
	if err := sandbox.AdvancePeriod(subID, false); err != nil {
		t.Fatal(err)
	}
	if len(events) != 1 || events[0].Type != EventSubscriptionDeleted {
		t.Fatalf("period end after cancel must delete: %+v", eventTypes(events))
	}

	// Signature check really runs: a foreign secret is rejected.
	other, _ := NewSandbox("whsec_other", "http://device.test/v1")
	payload := []byte(`{"id":"evt_forged","type":"invoice.paid","created":1,"data":{"object":{}}}`)
	if _, err := sandbox.ParseWebhook(payload, SignPayload("whsec_other", clock, payload), clock); !errors.Is(err, ErrSignature) {
		t.Fatalf("forged signature accepted: %v", err)
	}
	_ = other
}

func eventTypes(events []Event) []string {
	out := make([]string, 0, len(events))
	for _, e := range events {
		out = append(out, string(e.Type))
	}
	return out
}

func TestSandboxRestoreSubscriptionAfterRestart(t *testing.T) {
	sandbox, _ := NewSandbox("whsec_sandbox", "http://device.test/v1")
	var events []Event
	sandbox.SetDeliverer(func(payload []byte, signature string) error {
		event, err := sandbox.ParseWebhook(payload, signature, time.Now())
		if err != nil {
			return err
		}
		events = append(events, event)
		return nil
	})
	if err := sandbox.SetCancelAtPeriodEnd(context.Background(), "sub_lost", true); !errors.Is(err, ErrNotFound) {
		t.Fatalf("unknown subscription must be ErrNotFound, got %v", err)
	}
	end := time.Now().Add(20 * 24 * time.Hour)
	sandbox.RestoreSubscription("user-1", SubscriptionSnapshot{
		SubscriptionID: "sub_lost", Status: StatusActive, Interval: "month", AmountMinor: 1999, Currency: "INR",
		CurrentPeriodStart: time.Now(), CurrentPeriodEnd: end, Card: &CardSummary{Brand: "visa", Last4: "4242"},
		Metadata: map[string]string{"plan_code": "gold"},
	})
	if err := sandbox.SetCancelAtPeriodEnd(context.Background(), "sub_lost", true); err != nil {
		t.Fatalf("restored subscription: %v", err)
	}
	if len(events) != 1 || !events[0].Subscription.CancelAtPeriodEnd || events[0].Subscription.Metadata["user_id"] != "user-1" || events[0].Subscription.Card.Last4 != "4242" {
		t.Fatalf("restored state wrong: %+v", events)
	}
	if err := sandbox.AdvancePeriod("sub_lost", false); err != nil {
		t.Fatal(err)
	}
	if last := events[len(events)-1]; last.Type != EventSubscriptionDeleted {
		t.Fatalf("period end after restore must end the subscription, got %v", last.Type)
	}
}

func TestSandboxPlanChangeCardUpdateAndDispute(t *testing.T) {
	sandbox, _ := NewSandbox("whsec_sandbox", "http://device.test/v1")
	clock := time.Date(2026, 9, 27, 10, 0, 0, 0, time.UTC)
	sandbox.SetClock(func() time.Time { return clock })
	var events []Event
	sandbox.SetDeliverer(func(payload []byte, signature string) error {
		event, err := sandbox.ParseWebhook(payload, signature, clock)
		if err != nil {
			return err
		}
		events = append(events, event)
		return nil
	})
	ctx := context.Background()
	customer, _ := sandbox.EnsureCustomer(ctx, CustomerRequest{UserID: "user-1"})
	session, _ := sandbox.CreateSubscriptionCheckout(ctx, CheckoutRequest{CheckoutID: "chk", UserID: "user-1", CustomerID: customer, PlanCode: "silver", PlanName: "Silver", BillingCycle: "monthly", AmountMinor: 999, Currency: "INR", SuccessURL: "http://x/ok", CancelURL: "http://x/no"})
	if _, err := sandbox.CompleteCheckout(session.ProviderSessionID, SandboxCard{Number: SandboxCardSuccess, ExpMonth: 1, ExpYear: 2031, CVC: "123"}); err != nil {
		t.Fatal(err)
	}
	subID := events[0].Checkout.SubscriptionID
	if events[1].Subscription.ItemID == "" {
		t.Fatalf("subscription snapshot must carry an item id")
	}

	// Upgrade halfway through the period: prorated half of the difference.
	events = nil
	clock = clock.AddDate(0, 0, 15)
	if err := sandbox.ChangeSubscriptionPlan(ctx, ChangePlanRequest{SubscriptionID: subID, ItemID: "si_" + subID, PlanCode: "gold", PlanName: "Gold", BillingCycle: "monthly", AmountMinor: 1999, Currency: "INR", Upgrade: true}); err != nil {
		t.Fatal(err)
	}
	if len(events) != 2 || events[0].Type != EventInvoicePaid || events[0].Invoice.BillingReason != "subscription_update" {
		t.Fatalf("upgrade events: %v", eventTypes(events))
	}
	if got := events[0].Invoice.AmountMinor; got < 450 || got > 550 {
		t.Fatalf("prorated upgrade amount = %d, want about 500", got)
	}
	if events[1].Subscription.AmountMinor != 1999 || events[1].Subscription.Metadata["plan_code"] != "gold" {
		t.Fatalf("subscription after upgrade: %+v", events[1].Subscription)
	}

	// Downgrade: no charge, amount changes.
	events = nil
	if err := sandbox.ChangeSubscriptionPlan(ctx, ChangePlanRequest{SubscriptionID: subID, ItemID: "si_" + subID, PlanCode: "bronze", PlanName: "Bronze", BillingCycle: "monthly", AmountMinor: 499, Currency: "INR"}); err != nil {
		t.Fatal(err)
	}
	if len(events) != 1 || events[0].Subscription.AmountMinor != 499 {
		t.Fatalf("downgrade events: %v", eventTypes(events))
	}

	// Card replacement through a setup checkout.
	events = nil
	setup, err := sandbox.CreateSetupCheckout(ctx, SetupCheckoutRequest{CheckoutID: "chk-card", UserID: "user-1", CustomerID: customer, SubscriptionID: subID, SuccessURL: "http://x/ok", CancelURL: "http://x/no"})
	if err != nil {
		t.Fatal(err)
	}
	if _, err := sandbox.CompleteCheckout(setup.ProviderSessionID, SandboxCard{Number: "5555555555554444", ExpMonth: 2, ExpYear: 2032, CVC: "321"}); err != nil {
		t.Fatal(err)
	}
	if len(events) != 1 || events[0].Checkout.Mode != "setup" || events[0].Checkout.SetupIntentID == "" {
		t.Fatalf("setup completion events: %+v", events)
	}
	card, err := sandbox.ApplySetupPaymentMethod(ctx, events[0].Checkout.SetupIntentID, subID)
	if err != nil || card.Last4 != "4444" || card.Brand != "mastercard" {
		t.Fatalf("apply setup card = %+v err=%v", card, err)
	}
	if last := events[len(events)-1]; last.Type != EventSubscriptionUpdated || last.Subscription.Card.Last4 != "4444" {
		t.Fatalf("card update must be reported on the subscription: %+v", last)
	}

	// Dispute lifecycle on the last charge.
	events = nil
	if err := sandbox.OpenDispute(subID, "", "", 0); err != nil {
		t.Fatal(err)
	}
	if err := sandbox.CloseDispute(subID, false); err != nil {
		t.Fatal(err)
	}
	if len(events) != 2 || events[0].Type != EventDisputeUpdated || events[0].Dispute.Closed || !events[1].Dispute.Closed || events[1].Dispute.Status != "lost" {
		t.Fatalf("dispute events: %+v", events)
	}
}

func TestParseStripeDisputeAndActionRequired(t *testing.T) {
	payload := []byte(`{"id":"evt_d","type":"charge.dispute.created","created":1,"data":{"object":{"id":"dp_1","charge":"ch_1","payment_intent":"pi_1","amount":1999,"currency":"inr","status":"needs_response","reason":"fraudulent"}}}`)
	event, err := parseStripeEvent("stripe", payload)
	if err != nil || event.Type != EventDisputeUpdated || event.Dispute.PaymentIntentID != "pi_1" || event.Dispute.Closed {
		t.Fatalf("dispute parse: %+v err=%v", event, err)
	}
	payload = []byte(`{"id":"evt_a","type":"invoice.payment_action_required","created":1,"data":{"object":{"id":"in_1","subscription":"sub_1","amount_due":1999,"currency":"inr","paid":false}}}`)
	event, err = parseStripeEvent("stripe", payload)
	if err != nil || event.Type != EventInvoicePaymentFailed || event.Invoice.FailureMessage == "" || event.Invoice.AmountMinor != 1999 {
		t.Fatalf("action required parse: %+v err=%v", event, err)
	}
}
