# PEN-01 delivery: card checkout and auto-renewing subscriptions — 2026-09-27

Backlog item: [PEN-01](../../PENDING_FEATURE_BACKLOG.md) (BILL-004), with the entitlement slice of PEN-02 and the provider-key idempotency requirement of PEN-19.

Before this change `POST /v1/billing/subscribe` wrote an `active` subscription and a `success` payment straight into PostgreSQL with fabricated provider ids. No money moved, nothing could ever change that state, and the Flutter screen said so ("Activate locally"). This change replaces that with a provider-driven lifecycle: a hosted, card-only checkout, and subscription/payment state that is written only from verified provider webhooks.

## What was built

### Payment provider seam — `backend/internal/platform/payments`
- `Provider` interface: ensure customer, create subscription checkout, fetch subscription, set cancel-at-period-end, parse/verify webhook.
- **Stripe adapter** (`stripe.go`): Checkout Sessions in `subscription` mode with `payment_method_types=card`, inline recurring `price_data` from the PostgreSQL plan catalog (or a pre-created price id from `billing_plans.provider_price_ids`), customer creation idempotent on the member id, `cancel_at_period_end` toggling, and `expand[]=default_payment_method` so the card brand/last4 is known. Raw REST with form encoding; no SDK dependency.
- **Webhook signature** (`signature.go`): Stripe-compatible `t=…,v1=…` HMAC-SHA256 over `t.payload`, constant-time compare, 5-minute replay tolerance, multiple `v1` values for secret rotation.
- **Event normalisation** (`stripe_events.go`): `checkout.session.completed`, `invoice.paid|payment_succeeded|payment_failed`, `customer.subscription.created|updated|deleted|paused|resumed`, `charge.refunded` → one normalised `Event`. Handles both the legacy (`current_period_*` on the subscription) and current (`items.data[0].current_period_*`, `parent.subscription_details`) Stripe API shapes.
- **Sandbox provider** (`sandbox.go`): in-process provider for local development and QA. Hosted card form served by the BFF, Luhn validation, Stripe's published test numbers (`4242…` succeeds, `…0002` declined, `…0341` first charge ok / renewals fail), and renewal-clock controls. Every state change is emitted as a **Stripe-shaped, HMAC-signed event** and delivered into the same verify → dedupe → apply pipeline a real provider reaches over HTTP. It never charges a card and is refused by config validation in stage/production.

### Configuration — `internal/platform/config`
`PAYMENTS_PROVIDER` (`stripe|sandbox|disabled`; default `sandbox` outside prod-like environments, `disabled` inside them), `PAYMENTS_PUBLIC_BASE_URL`, `PAYMENTS_CURRENCY`, `PAYMENTS_SANDBOX_WEBHOOK_SECRET`, `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `STRIPE_API_BASE_URL`, `BILLING_PAST_DUE_GRACE_DAYS` (7), `BILLING_RENEWAL_SWEEP_SECONDS` (300), `BILLING_LOCAL_ACTIVATION_ENABLED` (false). Validation fails startup for sandbox in production, Stripe without secrets, or a `sk_test_` key in production. Documented in both `backend/config/.env*.example` files.

### Schema — `backend/scripts/070_billing_card_subscriptions.sql` (additive)
- `billing_plans`: `code` (unique, = lower(name); the API plan id), `currency`, `provider_price_ids`.
- `billing_subscriptions_runtime`: statuses `incomplete|active|past_due|cancelled|expired|paused`; `provider`, `provider_customer_id`, `cancel_at_period_end`, `cancelled_at`, `current_period_start/end`, `amount_minor`, `currency`, card brand/last4, `last_provider_event_at`, `metadata`. Partial unique indexes: **one live subscription per member** and **one row per `(provider, provider_subscription_id)`**. Pre-existing duplicate live rows are superseded, not deleted.
- `billing_payments_runtime`: statuses add `pending`, `partially_refunded`; `provider`, `provider_invoice_id`, `provider_charge_id`, `provider_event_id`, `billing_reason`, period, refunded amount, card summary, failure reason. Unique `(provider, provider_invoice_id)` and `(provider, provider_payment_id)`.
- New: `billing_provider_customers`, `billing_checkout_sessions` (unique provider session id, unique `(user_id, idempotency_key)`), `billing_webhook_events` (unique `(provider, event_id)`, status `received|processed|ignored|failed`, error, payload).
- Registered in `migrate_local_postgres.sh` (069 and 070 appended) and applied to the local database on port 55433.

### Mobile BFF — `internal/bff/mobile`
- `billing_checkout.go`: `billingCheckoutService` (create checkout, auto-renew on/off, process webhook, expiry sweep), handlers, sandbox pages, return page.
- `billing_repository_postgres.go`: checkout, customer, webhook-ledger and `applyEvent` persistence. One serialisable transaction per event. Ordering guard: a subscription ignores an event older than its `last_provider_event_at`; a settled invoice cannot reactivate a subscription the provider has since ended. Invoice-before-subscription is handled by fetching the provider snapshot.
- Routes (all documented in `openapi.yaml`, coverage tests pass):
  - `POST /v1/billing/checkout` — creates the hosted checkout (idempotent on `Idempotency-Key`; 409 while a paid subscription is live; 400 for the free plan).
  - `GET /v1/billing/checkout/{checkoutID}` — status polling; carries the subscription once completed.
  - `POST /v1/billing/subscription/{userID}/cancel|resume` — auto-renew off/on via the provider, mirrored locally.
  - `POST /v1/billing/webhooks/{provider}` — public, signature-verified, deduplicated; 400 bad signature, 404 wrong provider, 5xx asks for retry.
  - `GET /v1/billing/checkout/return` — public return page the app intercepts.
  - Sandbox only: `GET|POST /v1/billing/sandbox/checkout/{sessionID}`, `POST /v1/billing/sandbox/subscriptions/{userID}/simulate` (`renewal_paid|renewal_failed|period_end|refund`, owner-only).
  - `GET /v1/admin/billing/webhook-events` (admin, ops_admin, analyst read).
- `POST /v1/billing/subscribe` now returns **409** whenever a provider is configured unless `BILLING_LOCAL_ACTIVATION_ENABLED=true`.
- `GET /v1/billing/subscription/{userID}` and `/payments` return the richer contract (`is_paid`, `entitled`, `auto_renew`, `cancel_at_period_end`, `current_period_end`, card summary, `billing_reason`, `refunded_amount`, `failure_reason`, …). Entitlement: `active`, or `past_due` inside the grace window.
- Security: webhook/sandbox/return paths added to the public allowlist; sandbox simulate path is owner-scoped; webhook and sandbox form POSTs excluded from the client idempotency middleware (they are deduplicated on the provider event id instead).
- Housekeeping sweep (every `BILLING_RENEWAL_SWEEP_SECONDS`): `past_due` beyond grace → `expired`; cancel-at-period-end a day past period end → `expired` (safety net if the provider's deletion event never arrives); open checkouts past `expires_at` → `expired`.

### Flutter — `app/lib/features/payment`
- `subscription_provider.dart`: `startCheckout` → `CheckoutWebViewScreen` → `awaitCheckout` (polls until the webhook settles), `setAutoRenew`, sandbox `simulateSandbox` (debug builds only). The app never marks a plan active itself.
- `checkout_webview_screen.dart` (`webview_flutter`): hosts the provider page; intercepts the backend return URL and pops with the reported outcome, which the app then **confirms through the API** rather than trusting the redirect.
- `subscription_screen.dart` ("Membership", Afterdark Ember): gradient-ringed hero with plan, price, `Visa •••• 4242`, "Renews on …"/"Ends on …", status chip (Active / Ending / Payment due / Free) and the **Auto-renew switch** (confirm dialog on turning off); monthly/yearly toggle with "Save N%"; plan cards ("MOST POPULAR", "YOUR PLAN", `Subscribe with card`); payment history with Paid/Failed/Refunded chips, card and reason; sandbox renewal controls in debug builds.

### Control panel
- Subscriptions page: period end, auto-renew/ending, card, provider columns; `past_due`/`incomplete` filters.
- New **Payment webhooks** page (`/billing/webhooks/`) backed by `GET /v1/admin/billing/webhook-events`.
- Payments admin endpoint now returns provider, invoice, reason, card and refund columns.

## Validation

| Check | Result |
|---|---|
| `go test ./internal/platform/payments` — signature, Stripe request shapes (httptest), event parsing incl. new API shapes, sandbox lifecycle | pass |
| `go test ./internal/bff/mobile` with `PROFILE_TEST_DATABASE_URL` (local PostgreSQL) | pass, including `TestBillingCardSubscriptionLifecyclePostgres` |
| Lifecycle test covers | checkout idempotency; declined card leaves free tier and no payment; successful card → `completed` checkout, `active` gold, card on file, one `subscription_create` payment; second checkout refused (409); renewal advances period and adds a `subscription_cycle` payment with still one live row; **replayed webhook** acknowledged, no duplicate payment, one ledger row; **stale `canceled` event** ignored; cancel → `cancel_at_period_end`, still entitled; resume; refund recorded; failed renewal → `past_due` still entitled, failure reason stored; recovery; cancel + period end → `cancelled`, free tier; **grace sweep** expires a backdated `past_due` |
| `go test ./internal/platform/... ./internal/modules/billing/...`, `check_backend_compliance.sh` | pass |
| OpenAPI route-coverage and Idempotency-Key documentation tests | pass |
| Flutter: `flutter analyze` on the payment feature and its tests | no issues |
| Flutter tests: `test/features/payment` (provider + screen), `backend_journeys` (checkout idempotency, polling, cancel), `spacing_grid_test` | pass |
| Django control-panel tests | 21 pass |
| Live local stack (sandbox provider) | login → `POST /billing/checkout` → sandbox card page served through the gateway (HTTP 200) |

### Emulator evidence (Android, `emulator-5556`, sandbox provider, member `theme_qa_01`)

Screenshots in `documents/codex/artifacts/pen01_card_checkout/`:

1. `01_membership_free.png` — Free tier hero and the live plan catalog.
2. `02_plan_catalog_gold.png` — Gold flagged "MOST POPULAR", ₹19.99/month.
3. `03_confirm_card_subscription.png` — confirmation dialog stating card charge and auto-renew.
4. `04_hosted_card_checkout.png` — sandbox card page inside the in-app checkout view ("SANDBOX · NO REAL CHARGE").
5. `05_payment_settled.png` — after the webhooks settled: "You're Gold now", Gold marked "YOUR PLAN", other plans locked.
6. `06_active_auto_renew.png` — hero: Active, Visa •••• 4242, "Renews on 27 Oct 2026", auto-renew switch on.
7. `07_auto_renew_off_ending.png` — after turning auto-renew off: "Ending", "Ends on 27 Oct 2026 · auto-renew is off".
8. `08_payment_history_sandbox_controls.png` — payment history ("First charge · Visa •••• 4242 · Paid") and the debug-only sandbox renewal controls.

Database after the run (same member): one `active` gold row, provider `sandbox`, `auto_renew=true` (switched back on), card `visa 4242`, `current_period_end` 2026-10-27; one `success` payment of 1999 paise with reason `subscription_create`; webhook ledger rows `checkout.session.completed`, `customer.subscription.created`, `invoice.paid` and two `customer.subscription.updated`, all `processed`; checkout session `completed`. The member was left subscribed to Gold with auto-renew on for further QA.

## Follow-up delivered the same day: coin packages and browser checkout

- **Coin packages through the same pipeline.** `POST /v1/billing/checkout` accepts `kind=coin_package` with a `package_id` from the new member catalog `GET /v1/billing/coin-packages` (price, currency, bonus, total coins). The provider opens a payment-mode (single charge) card checkout; the wallet is credited only when the signed `checkout.session.completed` event settles, idempotently on the checkout id, with a `coin_purchase` payment row and a `wallet.coins.purchase` audit entry. Replayed events do not credit twice. The legacy client-asserted `POST /wallet/{id}/coins/buy` returns 409 whenever a provider is configured. Migration `071_billing_coin_checkout.sql` (checkout `kind/package_id/coins`, package `currency`, `sandbox` allowed as a wallet purchase provider) is applied locally and registered in the manifest. Stripe adapter, parser and sandbox gained payment-mode sessions; `TestBillingCardSubscriptionLifecyclePostgres` now also covers the coin purchase, replay and legacy-route refusal.
- **Wallet screen** (`wallet_payment_screen.dart`) now loads the real balance, packages and wallet activity from the API, buys a pack through the hosted checkout, and refreshes the chat header chip when the member returns. Card payments disabled on the server is shown honestly.
- **Browser checkout.** `features/payment/platform/checkout_launcher.dart` is a conditional import: native builds host the provider page in the in-app web view; the web build opens it in a new tab (`window.open`, falling back to same-tab navigation when popups are blocked) and shows a "finish paying in the new tab" sheet, after which the app polls the checkout exactly as on the phone. `flutter build web --release` succeeds and the web bundle was served locally through a proxy that mirrors the production nginx layout (`/v1` → gateway). Signing in on the web as the phone's member shows the same Gold membership, confirming both surfaces read one backend.
- **Coordination.** A separate session owns `lib/features/web`, `lib/main.dart` and `lib/core/platform`; its Settings → Subscriptions route on the web still opens a read-only membership preview. That session was told the checkout screens are now web-safe so it can route `/membership` to `SubscriptionScreen`; no file under those paths was changed here.
- **Sandbox survives backend restarts.** Found while testing from the browser: after the BFF was rebuilt, the in-memory sandbox no longer knew the phone-bought subscription and answered "provider object not found". The service now rehydrates the sandbox from the ledger row on a miss (`Sandbox.RestoreSubscription`), a refund after a restart uses the last settled payment from the ledger, and sandbox event/invoice ids are random rather than counters (a restarted counter produced ids the ledger had already seen, so the events were silently deduplicated). `TestBillingCardSubscriptionLifecyclePostgres` swaps in a fresh sandbox mid-lifecycle to cover this. Verified live: auto-renew off/on from the web after a restart.
- Coin package prices are stored in USD (`price_usd`, new `currency` column defaults to USD) while plans are INR; BILL-003's single-currency decision is still open.

## Second follow-up: the remaining real-money gates

Requested after the first delivery: close the open items rather than list them.

- **One currency (BILL-003 / DEC-007).** `PAYMENTS_CURRENCY` is the contract for everything a member can be charged. Migration `072_billing_single_currency_disputes.sql` adds a `price` column to coin packages, reprices the five packs in INR (₹79 / ₹329 / ₹649 / ₹1,499 / ₹3,299 — placeholders derived from the old USD list at ≈×83 and rounded to marketing prices; product still owns the final list) and defaults new packs to INR. The BFF refuses to start if any active plan or pack is priced in a different currency, so a mixed catalog cannot be sold by accident. The member catalog now reports `price` + `currency`, and the wallet screen shows ₹.
- **Disputes and 3DS.** `charge.dispute.created|updated|closed|funds_*` mark the matching payment `disputed` (amount held "at risk" in reconciliation) and, when closed, `chargeback` (lost) or back to `success` (won); a charged-back row can no longer be refunded. `invoice.payment_action_required` (bank authentication on a renewal) is treated as a failed renewal with an explanatory message, so the subscription goes `past_due` with grace. Sandbox: `dispute_open`, `dispute_won`, `dispute_lost` simulate events.
- **Plan changes with proration.** `POST /v1/billing/subscription/{userID}/change-plan` switches the live subscription at the provider. Upgrades (higher daily price) use `proration_behavior=always_invoice` so the difference is charged now and arrives as an `invoice.paid` with reason `subscription_update`; downgrades use `create_prorations` (credit at the next invoice). Refused while past due, for the same plan/cycle, and for Free (turn auto-renew off instead). Stripe subscription-item updates need a product, so the adapter creates one per plan code idempotently. The Membership screen offers "Switch to …" on other paid plans with a dialog that says what is charged when.
- **Card replacement.** `POST /v1/billing/checkout` with `kind=card_update` opens a Stripe Checkout in `setup` mode (no charge). On `checkout.session.completed` the BFF fetches the setup intent's payment method, makes it the subscription and customer default, and records brand/last4. In the sandbox a replacement card on a past-due subscription also retries the failed renewal, as Stripe does. "Update card" sits in the Membership hero.
- **Reconciliation (PEN-02 first slice).** `GET /v1/admin/billing/reconciliation?since&until` and the control-panel page **Billing → Reconciliation**: gross, refunded, chargebacks, disputed-at-risk and net revenue (settled provider payments minus refunds; local activations, admin grants and promotions are never revenue), payments by provider/status, wallet purchases versus settled coin payments, admin grants and promotions separately, subscriptions by status, webhook outcomes, checkout hygiene, and an anomaly list: coin payments without a wallet credit, wallet credits without a settled payment, reversed coin purchases needing a manual wallet review, active subscriptions without a settled payment for the period, chargebacks on live subscriptions, failed webhooks, completed checkouts without a subscription. Analysts can read it.
- **Stripe test-mode acceptance harness.** `backend/scripts/stripe_test_mode_acceptance.sh` drives the lifecycle against Stripe's test environment with `stripe listen` forwarding to `/v1/billing/webhooks/stripe`: sign in, create checkout (pay with 4242…), wait for the webhook to settle, cancel/resume, upgrade, then the `stripe trigger` matrix for failed renewal, deletion, dispute and refund, plus the card-replacement and coin flows. **Not run here: no Stripe account or keys are available in this workspace.** It is the runbook for that acceptance and its results should be recorded in this report.

Validation for this slice: `go test ./...` with the local PostgreSQL (the lifecycle test now also covers upgrade with a prorated `subscription_update` payment, refused same-plan and Free changes, downgrade without charge, card replacement via setup checkout, dispute open/lost → `chargeback`, reconciliation flagging the chargeback and summing net revenue, and the admin route's role gate), payments and config packages, backend compliance, 21 Django tests, Flutter analyzer clean on the payment feature and 18 Flutter tests. Live on the local stack: upgrade gold→emerald recorded a prorated `subscription_update` payment, downgrade back to gold charged nothing.

## Third follow-up: per-plan daily limits, chat surface, themes

- **Per-plan daily like and message limits (BILL-002 entitlements).** The plan catalog's `likes_per_day` / `messages_per_day` now apply. The member's entitlement is the plan of their live paid subscription (active, or past due inside grace), otherwise Free. Usage is counted from the durable `swipes` (likes only) and `messages` tables over the current UTC day, so it is identical on every device. `POST /v1/swipe` with `is_like=true`, `POST /v1/chat/{matchID}/messages`, and gift sends (which create a chat message and may carry a note) answer **429** with `DAILY_LIKE_LIMIT_REACHED` / `DAILY_MESSAGE_LIMIT_REACHED`, `plan_id`, `limit`, `used`, `resets_at`. The gift check happens before any wallet debit or gift write, while completed idempotent retries replay their original response. `GET /v1/billing/entitlements/{userID}` reports both quotas. `BILLING_ENFORCE_DAILY_LIMITS` (default on) switches enforcement off while keeping the report; without durable billing persistence nothing is enforced. Flutter: Discover shows a "You've used today's likes" sheet with reset time and "See plans"; chat shows a banner with the same and a "N of M messages left today" hint under the composer; both route to Membership. Test `TestDailyLimitsFollowThePlanPostgres` covers Free caps for likes and messages, gift-note refusal without partial state, idempotent gift replay, passes never being capped, unlimited on Gold and the enforcement switch.
- **Chat screen.** The screen hard-coded cream backgrounds and a black back arrow, so in dark mode (and on the wide web layout) the header and empty state were unreadable. It now uses the post-login backdrop, theme surfaces and outline colours, and inherits the content max-width on desktop.
- **Themes.** The user prefers the website's light editorial look and asked for several looks. Added `ThemePreset` / `ThemePresets` (`app/lib/core/theme/theme_presets.dart`): **Daylight** (the website: cream ground, ink type, raspberry accent) and **Afterdark Ember** as the classic pair that follows Light / Dark / Match device, plus fixed-brightness cinematic presets **Transformers**, **Tron**, **Iron Man**, **Digitronics** and **Love**, each a full palette with its own display face (Orbitron for Transformers/Tron/Digitronics). `ThemePresets.themeFor` builds a complete `ThemeData` on top of the base theme and installs a `ConnectPalette` extension; `PostLoginBackdrop` paints a per-preset atmosphere behind every screen (Tron light-grid and horizon, Transformers chrome streaks and energon blooms, Iron Man arc-reactor rings, Digitronics circuit traces, Love bokeh and gold sparkle), and choosing a look plays a short title card in the preset's own type. Selection lives in Settings → Appearance ("Looks" chips) and persists in `settings.theme` as `mode` or `mode:preset`, so it follows the account across the phone and the web. The app now defaults to light (Daylight). Tests assert every preset builds, keeps ≥7:1 ink contrast on ground and paper and ≥3:1 on buttons, and that wire values round-trip. Widgets that still use the static `AppTheme` accent constants keep their ember colour under a preset; migrating them to `Theme.of(context)` is incremental work.

## Decisions and assumptions

- **Provider: Stripe** for production card checkout, with the sandbox for local/QA. No approved provider existed (FRD FUT-005 lists Razorpay only as a historical assumption). The `Provider` seam keeps a Razorpay adapter possible without touching the ledger.
- **Card only**, per the request; `payment_method_types=card` on the Stripe session.
- **Auto-renew is the default**; members turn it off (cancel at period end) or back on from the app. Access always runs to the end of the paid period.
- **Plan changes while a paid plan is live are refused** (409) rather than silently creating a second provider subscription. Upgrade/downgrade with proration and card replacement need a provider portal or dedicated flow — listed below.
- **Catalog and pricing (DEC-007) remain a product decision.** The seeded Free→Diamond catalog and its two-decimal amounts are used as-is with currency `INR` (matching the payments table default and the app's ₹ display). Nothing in this change asserts those prices are approved.
- Hosted checkout is shown in an in-app WebView. Stripe recommends an external browser or Custom Tab for Checkout in production; the return-URL interception is provider-agnostic, so switching the host is contained to `checkout_webview_screen.dart`.

## Remaining work before real-money launch

1. **Run** `backend/scripts/stripe_test_mode_acceptance.sh` with a Stripe test account and record the results here. Everything the script exercises is implemented; only the account is missing.
2. Payout/settlement matching against the provider's balance transactions (the reconciliation report covers the ledger side; matching to Stripe payouts needs the `balance_transaction`/payout API and a bank statement).
4. Production `PAYMENTS_PUBLIC_BASE_URL` over HTTPS; sweep interval and grace window tuned with ops.
5. Product sign-off on the INR price list now in the catalog (plans and coin packs); the unused freezed `payment_models.dart` should be deleted or aligned.

## Payment-account follow-up — 30 September 2026

- Added authenticated `GET /v1/billing/account`: the signed-in member's name/email,
  configured payment mode, supported card method and recoverable membership/card
  replacement checkouts. Reads create no customer or charge and expose no provider
  credentials or customer identifiers. Billing release and runtime gates still apply.
- Membership now shows the member payment account and a clear local-test,
  Stripe-test, live or unavailable label. Test screens and confirmations explicitly
  say that no real charge occurs; the wallet also labels test payments.
- Unfinished, unexpired checkouts can be checked or resumed after reloading or
  restarting the app. Recovery rechecks account state before opening the same
  session, excludes other members and settled sessions, and omits local sandbox
  sessions lost when the development server restarts. Coin checkout recovery is
  not included in this membership recovery list.
- Network uncertainty and leaving a hosted page no longer claim that nothing was
  charged. Redirect matching requires the expected origin/path and checkout ID;
  the backend remains the source of payment confirmation. Changing signed-in
  accounts clears billing state and prevents an old in-flight checkout opening.
- Fixed website publication: build into Flutter's normal output, then publish an
  isolated copy without environment files. Android builds previously removed the
  served web font assets because they were Flutter-owned build outputs.
- Evidence: `qa/results/payment-account/`. 25 Flutter payment/journey tests and
  14 backend billing/quota/API-contract tests passed, plus the payments/config
  packages. The changed Flutter source has no analyzer issues. Real PostgreSQL
  tests cover account isolation, session recovery and card replacement. Web and
  Android debug builds succeeded; the Android APK was installed and launched.

This remains a local sandbox implementation. No merchant or bank account was
opened, no live credentials were configured, and no real card was charged.
Real merchant activation, provider acceptance and approved pricing remain with
the billing owner. Test values follow the official
[Stripe testing documentation](https://docs.stripe.com/testing).
