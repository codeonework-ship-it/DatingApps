# Billing and coin-economy acceptance

Date: 2026-09-27  
Owner: Separate billing owner  
Decision: **Real-money production NO_GO**

## Architecture assessment

The local implementation already covers the core money lifecycle: Stripe and sandbox adapters, hosted subscription and coin checkout, verified/deduplicated webhooks, renewals, plan changes, card replacement, refunds, disputes and chargebacks, once-only wallet credit, daily entitlements, and an operator reconciliation report. Automated billing and payments tests pass.

Three P0 acceptance gaps remain:

1. Run the Stripe test-mode matrix with a real test account and webhook listener. This workspace has no Stripe keys or Stripe CLI, so provider evidence cannot be fabricated locally.
2. Reconcile Stripe balance transactions, provider fees and payout batches to the product ledger and the deposited bank amount. The current reconciliation proves internal ledger consistency; it does not prove that Stripe paid the same amount.
3. Approve and version the INR subscription and coin-package catalogue. Seeded prices are implementation fixtures and are not product approval.

Refund, dispute and chargeback behavior is implemented locally. Its remaining work is Stripe test-mode evidence and financial reconciliation, rather than another application feature.

## Refund integrity delivered locally

- An operator gift reversal is a single transaction: it marks the canonical gift send `refunded`, records who reversed it and why, returns paid coins (or restores the free-gift allowance), retracts the linked chat message, and refuses a second reversal.
- A refunded or charged-back coin purchase now debits the purchased coins idempotently. If the member has already spent them, the available balance is reduced to zero, the shortfall becomes explicit `debt_coins`, and paid spending is frozen. Balances remain non-negative without hiding the liability.
- Admin and operations staff can review frozen wallets from the Django reconciliation console, collect available debt, or record an audited write-off before unfreezing. Gift refunds are available to admin, operations, and trust-and-safety roles from the same console.
- The debit ledger participates in the transactional domain-event outbox. Reconciliation reports both ledger imbalance and reversed payments whose coin clawback is incomplete.

Evidence: migration `084_billing_wallet_integrity.sql`, PostgreSQL suite `billing_wallet_integrity_test.go`, API routes in `server_wallet_admin.go`, and the Django billing reconciliation screen.

New wallets now start with zero coins across the transactional PostgreSQL path,
legacy repository and in-memory fallback. Migration 090 changes the database
default to zero and adds idempotent opening-balance credit/debit provenance for
historical discrepancies without changing member balances. After applying it
locally, every wallet balance reconciles to credits minus gift spends and
debits. In durable mode, positive balances can now arise only from an explicit
ledger-backed credit command.

## Fraud and velocity controls delivered locally

- Paid gift and coin-checkout rules are durable and operator-tunable. Supported actions are member warning, request throttling and a bounded temporary wallet lock; each response has an independent runtime switch and the master response switch degrades enforcement to review-only without suppressing detection.
- The evaluator covers paid-gift bursts, coin spend, distinct and repeated recipients, receiver reports, checkout bursts and requested coin volume. Existing hard ceilings remain non-disableable fail-safes.
- Every triggered rule creates or updates a durable review case and emits an audit/domain event. The Django command center lists cases and rules, permits authorized tuning, and lets Trust & Safety clear a false positive or confirm a case. Clearing removes only the wallet lock attributed to that case.
- Coin checkout evaluation and reservation use a per-member PostgreSQL transaction lock. Concurrent requests therefore cannot all pass the limit before any checkout row exists.

Evidence: migration `089_coin_economy_fraud_controls.sql`, evaluator and transaction path in `coin_economy_fraud.go`, operator routes in `server_coin_economy_fraud.go`, PostgreSQL tests in `coin_economy_fraud_test.go`, OpenAPI contract, and the Django reconciliation console.

Production still requires approved thresholds, false-positive monitoring, named review staffing and an operational drill. Cross-account/device graph analysis is separate future scope under PEN-50.

## Optional rewards

PEN-10–12 remain deferred while optional coin rewards and drops are disabled. PEN-13 is locally complete for paid gifts and coin checkouts, with production threshold acceptance still required. Daily streak coins, active-session rewards and limited drops still need approved economics and once-only award contracts before implementation. They do not block the current release while those mechanics remain inaccessible.

The machine-readable source of truth is [`contracts/billing_acceptance.v1.json`](contracts/billing_acceptance.v1.json). The release governance launch gate requires approved pricing and evidence for all Stripe and financial-reconciliation cases before it can return `GO`.
