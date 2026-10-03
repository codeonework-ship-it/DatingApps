"""Membership upgrade, auto-renew off and a coin purchase, driven on the device
(journeys.e2e.payments).

Everything goes through the local *sandbox* payment provider
(backend/internal/platform/payments/sandbox.go): its hosted checkout page is
served by the BFF at /v1/billing/sandbox/checkout/{id}, labelled "Sandbox · no
real charge", and pre-filled with the published 4242 sandbox test card. The
test only presses the page's Pay button; it never types a card number and it
refuses to run when the stack reports any mode other than "sandbox".

The device member is the shared QA account, which must start on the Free plan
(the catalog seed need for this journey). The paid plan is ended again in a
`finally` through the member API: auto-renew off (cancel at period end), then
the sandbox `period_end` simulation, which honours cancel-at-period-end. The
coins bought in the last step cannot be removed by any member API and stay in
the wallet.

Screens: app/lib/features/payment/screens/subscription_screen.dart (Membership),
wallet_payment_screen.dart, checkout_webview_screen.dart; strings from
app/lib/l10n/app_en.arb.
"""

from __future__ import annotations

import re
import time

import pytest
from appium.webdriver.common.appiumby import AppiumBy

from api_client import extract_items
from tests.test_04_matches_chat import _chat_is_unlocked, _open_first_chat

pytestmark = [pytest.mark.requires_appium]

CASE = "journeys.e2e.payments"

# English copy (app_en.arb).
SETTINGS_ENTRY = "Subscriptions"  # settingsSubscriptionsTitle
MEMBERSHIP_TITLE = "Membership"  # membershipTitle
CHOOSE_PLAN = "Choose your plan"  # membershipChooseYourPlan
SUBSCRIBE_WITH_CARD = "Subscribe with card"  # membershipSubscribeWithCard
CONTINUE_TO_CARD = "Continue to card"  # membershipContinueToCard
TEST_CHECKOUT_NOTE = "Test checkout only — no real charge."  # membershipSubscribeBodyTest*
START_EXPLORING = "Start exploring"  # membershipStartExploring
STATUS_ACTIVE = "Active"  # membershipStatusActive
STATUS_ENDING = "Ending"  # membershipStatusEnding
AUTO_RENEW = "Auto-renew"  # membershipAutoRenew
AUTO_RENEW_OFF_TITLE = "Turn off auto-renew?"  # membershipAutoRenewOffTitle
TURN_OFF = "Turn off"  # membershipTurnOff
AUTO_RENEW_NOW_OFF = "Auto-renew is off. Your benefits continue until the period ends."  # membershipAutoRenewNowOff
ENDS_ON_SUFFIX = "· auto-renew is off"  # membershipEndsOn / membershipEndsSoon
WALLET_TOOLTIP = "Your wallet"  # chatWalletTooltip
WALLET_TITLE = "Wallet & Payments"  # paymentWalletTitle
WALLET_TOP_UPS = "Popular top-ups"  # paymentWalletPopularTopUps
WALLET_TEST_NOTE = "Test payments · no real charge."  # paymentWalletTestNote


# --- API helpers ------------------------------------------------------------------------


def _wait_api(predicate, timeout: float = 20, interval: float = 1.0):
    deadline = time.time() + timeout
    value = None
    while time.time() < deadline:
        value = predicate()
        if value:
            return value
        time.sleep(interval)
    return value


def _require_flags(api, *keys: str) -> None:
    body = api.get("/config/flags").require_status(200).body
    flags = {row.get("key"): row.get("value_bool") for row in (body or {}).get("flags", [])}
    off = [key for key in keys if flags.get(key) is False]
    if off:
        pytest.skip(f"feature flag(s) off on this stack: {off}")


def _subscription(api, user_id: str) -> dict:
    body = api.get(f"/billing/subscription/{user_id}").require_status(200).body
    return body.get("subscription") or {}


def _is_live_paid(sub: dict) -> bool:
    return bool(sub.get("is_paid")) and sub.get("status") in ("active", "past_due")


def _payments(api, user_id: str) -> list[dict]:
    return api.get(f"/billing/payments/{user_id}").require_status(200).body.get("payments", [])


def _balance(api, user_id: str) -> int:
    return int(api.get(f"/wallet/{user_id}/coins").require_status(200).body["wallet"]["coin_balance"])


def _first_paid_plan(api) -> dict:
    """The first paid plan in catalog order: the Membership screen lists paid
    plans in the order /billing/plans returns them."""
    plans = api.get("/billing/plans").require_status(200).body.get("plans", [])
    paid = [p for p in plans if p.get("is_active", True) and float(p.get("monthly_price") or 0) > 0]
    if not paid:
        pytest.skip("no paid plan with a monthly price is on sale on this stack")
    return paid[0]


def _require_sandbox_card_checkout(api) -> list[dict]:
    """Sandbox provider with card checkout available; returns coin packs."""
    packs = api.get("/billing/coin-packages").require_status(200).body
    if packs.get("mode") != "sandbox":
        pytest.skip(f"billing mode is {packs.get('mode')!r}, not the local sandbox; refusing to check out")
    account = api.get("/billing/account").require_status(200).body.get("account") or {}
    if "card" not in (account.get("payment_methods") or []) or account.get("mode") != "sandbox":
        pytest.skip(f"card checkout is not available for the member: {account}")
    return [p for p in packs.get("packages", []) if float(p.get("price") or 0) > 0]


def _restore_free_plan(api, user_id: str) -> str | None:
    """End a sandbox paid plan the test started; returns a problem or None."""
    try:
        sub = _subscription(api, user_id)
        if not _is_live_paid(sub):
            return None
        if sub.get("provider") != "sandbox":
            return f"the member is on a non-sandbox paid plan; not touching it: {sub}"
        if sub.get("auto_renew"):
            api.post(f"/billing/subscription/{user_id}/cancel", {})
        api.post(f"/billing/sandbox/subscriptions/{user_id}/simulate", {"event": "period_end"})
        sub = _subscription(api, user_id)
        if _is_live_paid(sub):
            return f"the shared QA member is still on a paid plan after restore: {sub}"
        return None
    except Exception as exc:  # noqa: BLE001 - restore reports, the caller decides
        return f"restoring the Free plan failed: {exc!r}"


def _chat_match(device_member, counterpart_factory):
    """A chat to reach the wallet from (its header chip is the app's wallet
    entry point): a fresh match when a like is left today, else the first
    existing match whose chat is open."""
    api, uid = device_member.api, device_member.user_id
    ent = api.get(f"/billing/entitlements/{uid}").require_status(200).body
    likes = ent.get("likes") or {}
    if not ent.get("enforced", True) or likes.get("unlimited") or int(likes.get("remaining", 0)) > 0:
        name = f"Wallet Chat {int(time.time()) % 100000}"
        other = counterpart_factory("wc", name)
        other.api.post("/swipe", {"user_id": other.user_id, "target_user_id": uid, "is_like": True}).require_status(200, 201)
        body = api.post("/swipe", {"user_id": uid, "target_user_id": other.user_id, "is_like": True}).require_status(200, 201).body
        match_id = str(body.get("match_id") or "")
        assert body.get("mutual_match") is True and match_id, f"the mutual like did not create a match: {body}"
        counterpart_factory.cleanups.append(
            lambda: api.request("DELETE", f"/matches/{match_id}", query={"user_id": uid})
        )
        return match_id, name
    for match in extract_items(api.get(f"/matches/{uid}").require_status(200).body, "matches"):
        match_id = str(match.get("match_id") or match.get("id") or "")
        if match_id and _chat_is_unlocked(api, match_id)[0]:
            for key in ("userName", "user_name", "name", "display_name"):
                if match.get(key):
                    return match_id, str(match[key])
            return match_id, None
    pytest.skip("no like left today for a fresh match and no open chat to reach the wallet from")


# --- device helpers ---------------------------------------------------------------------


def _label_of(element) -> str:
    try:
        return " ".join(
            part for part in (element.get_attribute("content-desc"), element.get_attribute("text")) if part
        )
    except Exception:  # noqa: BLE001 - element went stale
        return ""


def _open_membership(app) -> None:
    app.open_settings_entry(SETTINGS_ENTRY)
    app.wait_for_text(MEMBERSHIP_TITLE, timeout=20)
    app.scroll_to_text(CHOOSE_PLAN, timeout=20)


def _tap_subscribe_for(app, plan_name: str) -> None:
    """Every plan card's button reads "Subscribe with card"; take the one
    directly below this plan's name."""
    app.scroll_into_middle(plan_name)
    size = app.driver.get_window_size()
    x = size["width"] // 2
    for _ in range(6):
        names = app.driver.find_elements(*app.ui_text(plan_name)) or app.driver.find_elements(
            *app.ui_desc(plan_name)
        )
        if not names:
            # A card may merge its badge ("MOST POPULAR") into the name's node.
            names = [
                e for e in app.driver.find_elements(*app.ui_desc_contains(plan_name))
                + app.driver.find_elements(*app.ui_text_contains(plan_name))
                if SUBSCRIBE_WITH_CARD not in _label_of(e) and "Subscribe to" not in _label_of(e)
            ]
        buttons = app.driver.find_elements(*app.ui_desc_contains(SUBSCRIBE_WITH_CARD)) or app.driver.find_elements(
            *app.ui_text_contains(SUBSCRIBE_WITH_CARD)
        )
        if names:
            name_y = names[0].rect["y"]
            below = [b for b in buttons if b.rect["y"] > name_y]
            if below:
                app._tap_element_center(min(below, key=lambda b: b.rect["y"]))
                return
        # Small scroll so the plan's name stays on screen.
        app.driver.swipe(x, int(size["height"] * 0.62), x, int(size["height"] * 0.47), 700)
        time.sleep(1.0)
    raise AssertionError(f"no '{SUBSCRIBE_WITH_CARD}' button found under the {plan_name!r} plan card")


def _open_wallet_from_chat(app, balance: int) -> None:
    """The chat header's wallet chip (chat_screen.dart _buildWalletHeaderChip):
    its tooltip reads "Your wallet · N coins", its label is the balance."""
    if app.maybe_tap(WALLET_TOOLTIP, timeout=10):
        return
    label = f"{balance:,}"
    chips = [
        e for e in app.driver.find_elements(*app.ui_desc(label)) + app.driver.find_elements(*app.ui_text(label))
        if e.rect["y"] < app.driver.get_window_size()["height"] * 0.25
    ]
    assert chips, f"the chat header shows no wallet chip (tooltip {WALLET_TOOLTIP!r} or balance {label!r})"
    app._tap_element_center(chips[0])


def _auto_renew_switch(app, timeout: int = 20):
    locators = [
        (AppiumBy.XPATH, f'//*[@checkable="true" and contains(@content-desc, "{AUTO_RENEW}")]'),
        (AppiumBy.XPATH, f'//*[@checkable="true" and contains(@text, "{AUTO_RENEW}")]'),
        (AppiumBy.XPATH, "//android.widget.Switch"),
    ]
    app.scroll_to_text(AUTO_RENEW, timeout=timeout)
    return app._wait_for_first_present(locators, timeout=timeout)


def _pay_on_sandbox_page(app, timeout: int = 45) -> None:
    """Submit the local sandbox checkout (backend sandboxCheckoutTemplate).

    The page is the sandbox provider's own, pre-filled with the published 4242
    sandbox test card; the test only presses its Pay button.
    """
    pay = [
        (AppiumBy.XPATH, '//android.widget.Button[contains(@text, "and subscribe")]'),
        (AppiumBy.XPATH, '//*[contains(@text, "and subscribe") or contains(@content-desc, "and subscribe")]'),
    ]
    # The badge is upper-cased by CSS; the test-card note is not.
    markers = ("Sandbox", "SANDBOX", "no real charge", "NO REAL CHARGE", "Test cards")
    deadline = time.time() + timeout
    size = app.driver.get_window_size()
    while time.time() < deadline:
        if any(
            app.driver.find_elements(*app.ui_text_contains(m)) or app.driver.find_elements(*app.ui_desc_contains(m))
            for m in markers
        ):
            for locator in pay:
                found = app.driver.find_elements(*locator)
                if found:
                    found[0].click()
                    return
            x = size["width"] // 2
            app.shell("input", ["swipe", str(x), str(int(size["height"] * 0.7)),
                                str(x), str(int(size["height"] * 0.4)), "400"])
        time.sleep(1)
    raise AssertionError("the sandbox checkout page (with its Pay button) never loaded in the checkout view")


def _tap_buy_button(app, package: dict) -> None:
    """Coin pack buy buttons are labelled with the pack price, e.g. ₹79.00."""
    amount = f"{float(package['price']):,.2f}"
    app.scroll_to_text(amount, timeout=30)
    time.sleep(0.8)
    xpath = f'//*[contains(@content-desc, "{amount}") or contains(@text, "{amount}")]'
    for element in app.driver.find_elements(AppiumBy.XPATH, xpath):
        amounts = re.findall(r"\d[\d,]*\.\d{2}", _label_of(element))
        if amounts and all(value == amount for value in amounts):
            app._tap_element_center(element)
            return
    raise AssertionError(f"no buy button labelled with {amount} for pack {package.get('id')}")


def _coin_count(count: int) -> str:
    return "1 coin" if count == 1 else f"{count} coins"


# --- test -------------------------------------------------------------------------------


@pytest.mark.case(CASE)
def test_upgrade_by_sandbox_checkout_turn_off_auto_renew_and_buy_coins(app, device_member, counterpart_factory):
    api, uid = device_member.api, device_member.user_id
    _require_flags(api, "billing_enabled")
    packages = _require_sandbox_card_checkout(api)
    start = _subscription(api, uid)
    if _is_live_paid(start):
        pytest.skip(
            "the shared QA member must start on the Free plan (seed need 'free member') but is on "
            f"{start.get('plan_id')!r} ({start.get('provider')}); end it with POST "
            "/billing/subscription/{id}/cancel then the sandbox period_end simulation"
        )
    if not packages:
        pytest.skip("no coin packs are on sale on this stack, so the wallet purchase step cannot run")
    plan = _first_paid_plan(api)
    plan_id, plan_name = str(plan["id"]), str(plan.get("name") or "").strip()
    assert plan_name, f"plan {plan_id} has no name to find on screen: {plan}"
    payments_before = len(_payments(api, uid))

    body_failed = True
    try:
        # 1. Upgrade: Settings → Subscriptions → plan card → test checkout.
        _open_membership(app)
        app.save_artifact("membership_free_before_upgrade")
        _tap_subscribe_for(app, plan_name)
        app.wait_for_text(f"Subscribe to {plan_name}", timeout=15)  # membershipSubscribeTitle
        app.wait_for_text_contains(TEST_CHECKOUT_NOTE, timeout=5)
        app.tap_text(CONTINUE_TO_CARD, timeout=10)
        app.wait_for_text(f"Pay for {plan_name}", timeout=30)  # paymentCheckoutPayFor
        _pay_on_sandbox_page(app)

        # The app confirms through the API before celebrating.
        app.wait_for_text_contains(f"{plan_name} now", timeout=60)  # membershipCelebrateTitle "You're {plan} now"
        app.save_artifact("membership_upgrade_celebration")
        app.tap_text(START_EXPLORING, timeout=10)

        sub = _wait_api(lambda: (lambda s: s if _is_live_paid(s) else None)(_subscription(api, uid)), timeout=30)
        assert sub, f"no live paid subscription after checkout: {_subscription(api, uid)}"
        assert sub.get("plan_id") == plan_id, sub
        assert sub.get("provider") == "sandbox", sub
        assert sub.get("auto_renew") is True and not sub.get("cancel_at_period_end"), sub
        payments = _payments(api, uid)
        assert len(payments) > payments_before, f"the first charge is missing from payment history: {payments}"

        # The Membership screen shows the new plan, active and renewing.
        app.scroll_to_text(plan_name, timeout=15)
        app.wait_for_text(STATUS_ACTIVE, timeout=15)
        switch = _auto_renew_switch(app)
        assert (switch.get_attribute("checked") or "").lower() == "true", "auto-renew should be on after checkout"

        # 2. Auto-renew off, with its confirmation.
        app._tap_element_center(switch)
        app.wait_for_text(AUTO_RENEW_OFF_TITLE, timeout=10)
        app.tap_text(TURN_OFF, timeout=10)
        app.wait_for_text_contains(AUTO_RENEW_NOW_OFF, timeout=20)
        off = _wait_api(
            lambda: (lambda s: s if s.get("auto_renew") is False else None)(_subscription(api, uid)), timeout=20
        )
        assert off, f"auto-renew still on server-side: {_subscription(api, uid)}"
        assert off.get("cancel_at_period_end") is True and _is_live_paid(off), (
            f"turning auto-renew off must keep the plan until the period ends: {off}"
        )
        app.wait_for_text(STATUS_ENDING, timeout=15)
        app.wait_for_text_contains(ENDS_ON_SUFFIX, timeout=10)
        switch = _auto_renew_switch(app)
        assert (switch.get_attribute("checked") or "").lower() == "false", "the switch must show auto-renew off"
        app.save_artifact("membership_auto_renew_off")

        # 3. Wallet coin purchase from a chat's wallet chip.
        package = min(packages, key=lambda p: int(p.get("total_coins") or 0))
        credit = int(package["total_coins"])
        balance = _balance(api, uid)
        payments_before_coins = len(_payments(api, uid))
        match_id, match_name = _chat_match(device_member, counterpart_factory)
        app.press_back(settle=1.5)  # leave Membership
        _open_first_chat(app, match_name, match_id)
        _open_wallet_from_chat(app, balance)
        app.wait_for_text(WALLET_TITLE, timeout=20)
        app.wait_for_text_contains(WALLET_TEST_NOTE, timeout=15)
        app.wait_for_text(WALLET_TOP_UPS, timeout=15)
        _tap_buy_button(app, package)
        app.wait_for_text(f"Pay for {_coin_count(credit)}", timeout=30)
        _pay_on_sandbox_page(app)
        added = f"{credit} coins added to your wallet." if credit != 1 else "1 coin added to your wallet."
        app.wait_for_text_contains(added, timeout=60)  # paymentCoinsAdded
        credited = _wait_api(lambda: _balance(api, uid) == balance + credit, timeout=30)
        assert credited, f"wallet not credited: expected {balance + credit}, got {_balance(api, uid)}"
        coin_payments = _payments(api, uid)
        assert len(coin_payments) > payments_before_coins, f"the coin purchase is missing from payment history: {coin_payments}"
        app.wait_for_text(_coin_count(balance + credit), timeout=20)
        app.scroll_to_text(f"+{credit:,}", timeout=20)  # the credit row in Wallet activity
        app.save_artifact("wallet_coins_bought")
        body_failed = False
    finally:
        problem = _restore_free_plan(api, uid)
        if problem and not body_failed:
            raise AssertionError(problem)
        if problem:
            print(f"[billing restore] {problem}")
