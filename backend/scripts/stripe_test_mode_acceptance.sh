#!/usr/bin/env bash
# Stripe test-mode acceptance for PEN-01 (card checkout + auto-renew).
#
# Runs the same lifecycle the sandbox proves locally, against Stripe's test
# environment with real webhooks. Needs:
#   * STRIPE_SECRET_KEY=sk_test_…  STRIPE_WEBHOOK_SECRET=whsec_… (from `stripe listen`)
#   * the Stripe CLI (`stripe login` done once)
#   * the local stack started with PAYMENTS_PROVIDER=stripe and
#     PAYMENTS_PUBLIC_BASE_URL pointing at a host the browser can reach.
#
# Usage:
#   1. In one terminal:  stripe listen --forward-to http://127.0.0.1:18081/v1/billing/webhooks/stripe
#      (copy the whsec_ it prints into STRIPE_WEBHOOK_SECRET, then restart the stack)
#   2. ./stripe_test_mode_acceptance.sh <username> <password>
#      The script creates a checkout, prints the hosted URL for you to pay with
#      4242 4242 4242 4242, then polls until the webhook settles it and walks
#      cancel/resume/change-plan. Dispute and failed-renewal paths are
#      triggered with `stripe trigger` (see the end of the script).
set -euo pipefail

username="${1:?username}"
password="${2:?password}"
gateway="${GATEWAY_URL:-http://127.0.0.1:18080/v1}"
plan="${PLAN:-gold}"
cycle="${CYCLE:-monthly}"

req() { curl -sS -H "Authorization: Bearer $token" -H 'Content-Type: application/json' "$@"; }
step() { printf '\n== %s\n' "$*"; }

step "sign in"
login="$(curl -sS -X POST "$gateway/auth/login" -H 'Content-Type: application/json' -d "{\"username\":\"$username\",\"password\":\"$password\"}")"
token="$(printf '%s' "$login" | python3 -c 'import sys,json;print(json.load(sys.stdin)["access_token"])')"
user_id="$(printf '%s' "$login" | python3 -c 'import sys,json;print(json.load(sys.stdin)["user_id"])')"
echo "user $user_id"

step "provider must be stripe"
req "$gateway/billing/coin-packages" | python3 -c 'import sys,json;d=json.load(sys.stdin);assert d.get("provider")=="stripe", d;print("provider stripe ok")'

step "create subscription checkout ($plan/$cycle)"
checkout="$(req -X POST "$gateway/billing/checkout" -H "Idempotency-Key: acc-$(date +%s)" -d "{\"plan_id\":\"$plan\",\"billing_cycle\":\"$cycle\"}")"
checkout_id="$(printf '%s' "$checkout" | python3 -c 'import sys,json;print(json.load(sys.stdin)["checkout"]["id"])')"
url="$(printf '%s' "$checkout" | python3 -c 'import sys,json;print(json.load(sys.stdin)["checkout"]["checkout_url"])')"
echo "open this URL and pay with 4242 4242 4242 4242 (any future date, any CVC):"
echo "  $url"

step "waiting for checkout.session.completed + invoice.paid via stripe listen"
for _ in $(seq 1 120); do
  status="$(req "$gateway/billing/checkout/$checkout_id" | python3 -c 'import sys,json;print(json.load(sys.stdin)["checkout"]["status"])')"
  [[ "$status" == "completed" ]] && break
  sleep 5
done
[[ "$status" == "completed" ]] || { echo "checkout did not complete"; exit 1; }
req "$gateway/billing/subscription/$user_id" | python3 -c 'import sys,json;s=json.load(sys.stdin)["subscription"];assert s["status"]=="active" and s["is_paid"] and s["auto_renew"], s;print("active", s["plan_id"], s["card_brand"], s["card_last4"], "renews", s["current_period_end"])'
req "$gateway/billing/payments/$user_id?limit=5" | python3 -c 'import sys,json;p=json.load(sys.stdin)["payments"];assert p and p[0]["status"]=="success" and p[0]["billing_reason"]=="subscription_create", p;print("first charge recorded", p[0]["amount"], p[0]["currency"])'

step "auto-renew off / on"
req -X POST "$gateway/billing/subscription/$user_id/cancel" -d '{}' | python3 -c 'import sys,json;s=json.load(sys.stdin)["subscription"];assert s["cancel_at_period_end"] and not s["auto_renew"], s;print("cancel_at_period_end ok")'
req -X POST "$gateway/billing/subscription/$user_id/resume" -d '{}' | python3 -c 'import sys,json;s=json.load(sys.stdin)["subscription"];assert s["auto_renew"], s;print("resumed ok")'

step "upgrade to emerald (prorated invoice expected)"
req -X POST "$gateway/billing/subscription/$user_id/change-plan" -d '{"plan_id":"emerald","billing_cycle":"monthly"}' | python3 -c 'import sys,json;s=json.load(sys.stdin)["subscription"];assert s["plan_id"]=="emerald", s;print("plan now", s["plan_id"])'
sleep 10
req "$gateway/billing/payments/$user_id?limit=5" | python3 -c 'import sys,json;p=json.load(sys.stdin)["payments"];print("latest payment", p[0]["billing_reason"], p[0]["status"], p[0]["amount"])'

step "replayed webhook must be acknowledged without side effects"
echo "  stripe events resend <event id>   → expect HTTP 200 and no new payment row"

cat <<'NEXT'

== manual triggers (each must land in GET /admin/billing/webhook-events as processed)
  stripe trigger invoice.payment_failed          → subscription past_due, entitled inside grace
  stripe trigger customer.subscription.deleted   → subscription cancelled, member on Free
  stripe trigger charge.dispute.created          → matching payment disputed (needs a charge on this account)
  stripe trigger charge.refunded                 → payment refunded / partially_refunded
  Card replacement: POST /billing/checkout {"kind":"card_update"} → open URL → save 4000 0025 0000 3155 (3DS) → card_last4 updates
  Coins:            POST /billing/checkout {"kind":"coin_package","package_id":<from /billing/coin-packages>} → pay → wallet credited once
Record results in documents/codex/completed/PEN01_CARD_SUBSCRIPTION_CHECKOUT_REPORT_2026-09-27.md under "Stripe test-mode acceptance".
NEXT
