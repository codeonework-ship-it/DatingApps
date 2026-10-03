"""Gifts in a match chat, driven on the device (journeys.e2e.gifts).

The device member (QA_EXISTING_USERNAME) opens a chat with a brand-new
counterpart match, opens the gift tray ("Send a gift") and sends gifts the way
a member does. Every outcome is asserted twice: on screen, and through the API
(the counterpart's copy of the chat, and the device member's wallet).

The journey is split over three tests because the shared QA account carries
state between runs that no member API can reset:

* one free (price 0) gift per member per UTC day (gift_send_ledger.go);
* the coin balance only goes up through a card checkout and down through
  paid gifts, so the "Add coins" path (a gift the member cannot afford) is
  only reachable while the balance is below the priciest gift.

Each test states the precondition it needs and skips, saying why, when the
shared account does not meet it. Coins are bought only through the local
sandbox payment provider, whose hosted page is pre-filled with the published
sandbox test card; this module never types a card number.

Strings come from app/lib/l10n/app_en.arb; screens from
app/lib/features/messaging/screens/chat_screen.dart and
app/lib/features/payment/screens/wallet_payment_screen.dart.
"""

from __future__ import annotations

import json
import re
import time
from pathlib import Path

import pytest
from appium.webdriver.common.appiumby import AppiumBy

from api_client import extract_items
from tests.test_04_matches_chat import _chat_is_unlocked, _open_first_chat

pytestmark = [pytest.mark.requires_appium, pytest.mark.chat]

CASE = "journeys.e2e.gifts"

# English copy (app_en.arb).
TRAY_BUTTON = "Send a gift"  # chatSendGiftTooltip
TRAY_TITLE = "A little something for them"  # chatGiftTrayTitle
FREE_LABEL = "Free · 1 a day"  # chatFreeGiftDaily
ADD_COINS_LABEL = "Add coins"  # chatAddCoins
SENT_HEADING = "You sent a gift"  # chatGiftYouSentHeading
FREE_USED_SNIPPET = "free gift. A new one is available"  # chatErrorFreeGiftUsed
NOT_NOW = "Not now"  # chatNotNow
WALLET_TITLE = "Wallet & Payments"  # paymentWalletTitle
WALLET_TOP_UPS = "Popular top-ups"  # paymentWalletPopularTopUps

REPO_ROOT = Path(__file__).resolve().parents[3]
EN_ARB = REPO_ROOT / "app" / "lib" / "l10n" / "app_en.arb"
# gift_l10n.dart maps these ids to keys that do not follow the id.
GIFT_KEY_EXCEPTIONS = {
    "exclusive_diamond_ring": "giftNameDiamondRing",
    "exclusive_luxury_date": "giftNameLuxuryDate",
}
_ARB_CACHE: dict[str, str] = {}


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


def _balance(api, user_id: str) -> int:
    body = api.get(f"/wallet/{user_id}/coins").require_status(200).body
    return int(body["wallet"]["coin_balance"])


def _active_gifts(api) -> list[dict]:
    body = api.get("/chat/gifts").require_status(200).body
    return [g for g in extract_items(body, "gifts") if g.get("is_active", True)]


def _price(gift: dict) -> int:
    return int(gift.get("price_coins") or 0)


def _plain_paid(gifts: list[dict]) -> list[dict]:
    """Paid gifts with no seasonal window or per-match cap, in catalog order."""
    out = []
    for gift in gifts:
        tier = str(gift.get("tier") or "")
        if _price(gift) <= 0 or tier in ("seasonal_limited", "exclusive"):
            continue
        if str(gift.get("category") or "") == "seasonal":
            continue
        out.append(gift)
    # Unlimited gifts first; the order is otherwise the catalog's.
    return sorted(out, key=lambda g: bool(g.get("is_limited")))


def _arb() -> dict[str, str]:
    if not _ARB_CACHE and EN_ARB.exists():
        _ARB_CACHE.update(
            {k: v for k, v in json.loads(EN_ARB.read_text(encoding="utf-8")).items() if isinstance(v, str)}
        )
    return _ARB_CACHE


def _gift_label(gift: dict) -> str:
    """The gift's English name as the tray shows it (gift_l10n.dart)."""
    gift_id = str(gift.get("id") or "")
    key = GIFT_KEY_EXCEPTIONS.get(gift_id) or "giftName" + "".join(
        part[:1].upper() + part[1:] for part in gift_id.split("_")
    )
    return _arb().get(key) or str(gift.get("name") or gift_id)


def _coin_count(count: int) -> str:
    # chatCoinCount: "{count, plural, =1{1 coin} other{{count} coins}}"
    return "1 coin" if count == 1 else f"{count} coins"


def _messages(api, match_id: str) -> list[dict]:
    response = api.get(f"/chat/{match_id}/messages", query={"limit": 50}).require_status(200)
    return extract_items(response.body, "messages", "items", "data")


def _message_text(item: dict) -> str:
    for key in ("content", "text", "message", "body"):
        value = item.get(key)
        if value:
            return str(value)
    return ""


def _gift_messages(api, match_id: str, gift_id: str, sender_id: str) -> list[dict]:
    """Chat rows carrying this gift's token ([gift:id=<id>|...], gifts.go)."""
    token = f"[gift:id={gift_id}|"
    out = []
    for item in _messages(api, match_id):
        sender = str(item.get("sender_id") or item.get("senderId") or item.get("sender_user_id") or sender_id)
        if token in _message_text(item) and sender == sender_id:
            out.append(item)
    return out


def _fresh_match(device_member, counterpart_factory, role: str, name: str):
    """A new mutual match for the device member, unmatched after the test."""
    uid = device_member.user_id
    ent = device_member.api.get(f"/billing/entitlements/{uid}").require_status(200).body
    likes = ent.get("likes") or {}
    if ent.get("enforced", True) and not likes.get("unlimited") and int(likes.get("remaining", 1)) < 1:
        pytest.skip(
            "the shared QA member has used today's likes "
            f"({likes.get('used')}/{likes.get('limit')}); a fresh match needs one like. "
            f"Resets at {likes.get('resets_at')}"
        )
    other = counterpart_factory(role, name)
    other.api.post(
        "/swipe", {"user_id": other.user_id, "target_user_id": uid, "is_like": True}
    ).require_status(200, 201)
    body = device_member.api.post(
        "/swipe", {"user_id": uid, "target_user_id": other.user_id, "is_like": True}
    ).require_status(200, 201).body
    match_id = str(body.get("match_id") or "")
    assert body.get("mutual_match") is True and match_id, f"the mutual like did not create a match: {body}"
    counterpart_factory.cleanups.append(
        lambda: device_member.api.request("DELETE", f"/matches/{match_id}", query={"user_id": uid})
    )
    unlocked, state = _chat_is_unlocked(device_member.api, match_id)
    assert unlocked, f"a fresh match must be open for chat by default, got {state!r}"
    return match_id, other


def _sandbox_packages(api) -> list[dict]:
    body = api.get("/billing/coin-packages").require_status(200).body
    if body.get("mode") != "sandbox":
        pytest.skip(f"billing mode is {body.get('mode')!r}, not the local sandbox; refusing to buy coins")
    packages = [p for p in body.get("packages", []) if float(p.get("price") or 0) > 0]
    if not packages:
        pytest.skip("no coin packs are on sale on this stack")
    return packages


def _payments(api, user_id: str) -> list[dict]:
    return api.get(f"/billing/payments/{user_id}").require_status(200).body.get("payments", [])


# --- device helpers ---------------------------------------------------------------------


def _open_gift_tray(app) -> None:
    if app.is_text_visible(TRAY_TITLE, timeout=2):
        return
    app.hide_keyboard()
    app.dismiss_snackbars()
    app.tap_text(TRAY_BUTTON, timeout=15)
    app.wait_for_text(TRAY_TITLE, timeout=15)


def _label_of(element) -> str:
    try:
        return " ".join(
            part for part in (element.get_attribute("content-desc"), element.get_attribute("text")) if part
        )
    except Exception:  # noqa: BLE001 - element went stale
        return ""


def _find_tile(app, name: str, price_label: str):
    """The tray tile: its merged label holds the gift name and the price line."""
    xpath = (
        f'//*[(contains(@content-desc, "{name}") and contains(@content-desc, "{price_label}")) '
        f'or (contains(@text, "{name}") and contains(@text, "{price_label}"))]'
    )
    found = app.driver.find_elements(AppiumBy.XPATH, xpath)
    return found[0] if found else None


def _tile_row_y(app) -> int | None:
    """Vertical centre of the tile row, from any tile's price line."""
    xpath = (
        f'//*[contains(@content-desc, "{FREE_LABEL}") or contains(@content-desc, "{ADD_COINS_LABEL}") '
        'or contains(@content-desc, " coin")]'
    )
    for element in app.driver.find_elements(AppiumBy.XPATH, xpath):
        label = _label_of(element)
        if "Your wallet" in label:  # the header chip's tooltip
            continue
        rect = element.rect
        return int(rect["y"] + rect["height"] / 2)
    return None


def _scroll_tray_to_tile(app, gift: dict, price_label: str, max_swipes: int = 14, settle: float = 8):
    name = _gift_label(gift)
    category = str(gift.get("category") or "").replace("_", " ")
    # Narrow the horizontal list to the gift's collection when chips exist.
    if category:
        app.maybe_tap(category, timeout=2)
        time.sleep(0.6)
    # The price line follows the wallet the chat re-reads (e.g. after a
    # top-up), so give the visible tiles a moment before scrolling away.
    tile = _wait_api(lambda: _find_tile(app, name, price_label), timeout=settle, interval=0.5)
    size = app.driver.get_window_size()
    previous = ""
    for _ in range(max_swipes):
        if tile is not None:
            return tile
        row_y = _tile_row_y(app)
        assert row_y, "the gift tray shows no gift tiles"
        app.shell(
            "input",
            ["swipe", str(int(size["width"] * 0.85)), str(row_y), str(int(size["width"] * 0.15)), str(row_y), "450"],
        )
        time.sleep(0.6)
        tile = _find_tile(app, name, price_label)
        current = app.driver.page_source
        if tile is None and current == previous:
            break
        previous = current
    assert tile is not None, f"gift tile {name!r} labelled {price_label!r} never appeared in the tray"
    return tile


def _wallet_balance_visible(app, coins: int, timeout: int = 30) -> None:
    # paymentWalletBalanceCoins / paymentCoinCount render the plain integer.
    app.wait_for_text(_coin_count(coins), timeout=timeout)


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


def _pay_on_sandbox_page(app, timeout: int = 45) -> None:
    """Submit the local sandbox checkout (backend sandboxCheckoutTemplate).

    The page belongs to the sandbox provider, is labelled "Sandbox · no real
    charge" and is pre-filled with the published 4242 sandbox test card; the
    test only presses its Pay button.
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


# --- tests ------------------------------------------------------------------------------


@pytest.mark.case(CASE)
def test_free_daily_gift_from_tray_reaches_partner_once_a_day(app, device_member, counterpart_factory):
    """Free gift: one tap sends it (no confirmation, no coins); a second free
    gift the same UTC day is refused and nothing is stored."""
    api, uid = device_member.api, device_member.user_id
    _require_flags(api, "gifts_enabled")
    free = next((g for g in _active_gifts(api) if _price(g) == 0), None)
    if free is None:
        pytest.skip("the gift catalog has no active free gift")
    name = _gift_label(free)
    match_id, partner = _fresh_match(device_member, counterpart_factory, "gf", f"Gift Free {int(time.time()) % 100000}")
    balance_before = _balance(api, uid)

    _open_first_chat(app, partner.name, match_id)
    _open_gift_tray(app)
    app._tap_element_center(_scroll_tray_to_tile(app, free, FREE_LABEL))
    outcome = app.assert_any_text_visible(SENT_HEADING, FREE_USED_SNIPPET, timeout=30)
    app.save_artifact("gift_free_after_tap")

    if outcome == FREE_USED_SNIPPET:
        # The shared member already used today's free gift (an earlier run).
        # The refusal is real and must not have stored or charged anything.
        assert not _gift_messages(partner.api, match_id, free["id"], uid), "a refused free gift reached the chat"
        assert _balance(api, uid) == balance_before, "a refused free gift changed the wallet"
        pytest.skip(
            "the shared QA member already sent today's free gift (1 per UTC day); the refusal was "
            "verified, the free send itself is not proven this run"
        )

    # The counterpart's copy of the chat holds the gift; it cost nothing.
    sent = _wait_api(lambda: _gift_messages(partner.api, match_id, free["id"], uid))
    assert sent and len(sent) == 1, f"free gift not delivered exactly once: {sent}"
    assert _balance(api, uid) == balance_before, "a free gift must not debit the wallet"
    app.wait_for_text(name, timeout=10)
    app.wait_for_text("Free gift", timeout=10)  # chatFreeGift on the bubble

    # One a day: the same free gift again is refused with the daily-limit copy.
    _open_gift_tray(app)
    app._tap_element_center(_scroll_tray_to_tile(app, free, FREE_LABEL))
    app.wait_for_text_contains(FREE_USED_SNIPPET, timeout=25)
    app.save_artifact("gift_free_second_refused")
    time.sleep(2)
    assert len(_gift_messages(partner.api, match_id, free["id"], uid)) == 1, "a second free gift was stored"
    assert _balance(api, uid) == balance_before
    app.dismiss_snackbars()


@pytest.mark.case(CASE)
def test_unaffordable_gift_opens_wallet_top_up_then_coin_gift_sends(app, device_member, counterpart_factory):
    """Insufficient coins → "Add coins" opens the wallet → sandbox card top-up
    → the same gift is now affordable, confirmed and sent."""
    api, uid = device_member.api, device_member.user_id
    _require_flags(api, "gifts_enabled", "billing_enabled")
    packages = _sandbox_packages(api)
    balance = _balance(api, uid)
    paid = _plain_paid(_active_gifts(api))
    if not paid:
        pytest.skip("the gift catalog has no plain paid gift")
    unaffordable = [g for g in paid if _price(g) > balance]
    if not unaffordable:
        pytest.skip(
            f"the shared QA member holds {balance} coins, more than the priciest plain gift "
            f"({max(_price(g) for g in paid)}); the 'Add coins' path only exists for a gift the member "
            "cannot afford, and no member API lowers a balance. Run with a QA member below that balance."
        )
    gift = unaffordable[0]
    price, name = _price(gift), _gift_label(gift)
    package = min(packages, key=lambda p: int(p.get("total_coins") or 0))
    credit = int(package["total_coins"])
    assert balance + credit >= price, f"the smallest pack ({credit}) cannot cover {name} ({price})"
    payments_before = len(_payments(api, uid))
    match_id, partner = _fresh_match(device_member, counterpart_factory, "gc", f"Gift Coin {int(time.time()) % 100000}")

    _open_first_chat(app, partner.name, match_id)
    _open_gift_tray(app)
    # The tile itself says the member cannot afford it.
    app._tap_element_center(_scroll_tray_to_tile(app, gift, ADD_COINS_LABEL))

    # The wallet opens instead of a send; nothing reached the chat.
    app.wait_for_text(WALLET_TITLE, timeout=20)
    app.wait_for_text(WALLET_TOP_UPS, timeout=20)
    _wallet_balance_visible(app, balance)
    assert not _gift_messages(partner.api, match_id, gift["id"], uid), "an unaffordable gift was sent"
    assert _balance(api, uid) == balance
    app.save_artifact("gift_wallet_from_add_coins")

    # Top up with the smallest pack through the sandbox card checkout.
    _tap_buy_button(app, package)
    app.wait_for_text(f"Pay for {_coin_count(credit)}", timeout=30)  # paymentCheckoutPayFor
    _pay_on_sandbox_page(app)
    added = f"{credit} coins added to your wallet." if credit != 1 else "1 coin added to your wallet."
    app.wait_for_text_contains(added, timeout=60)  # paymentCoinsAdded

    topped = _wait_api(lambda: _balance(api, uid) == balance + credit, timeout=30)
    assert topped, f"wallet not credited: expected {balance + credit}, got {_balance(api, uid)}"
    assert len(_payments(api, uid)) > payments_before, "the coin purchase is missing from payment history"
    _wallet_balance_visible(app, balance + credit)
    app.save_artifact("gift_wallet_topped_up")
    new_balance = balance + credit

    # Back in the chat the same gift is affordable and asks for confirmation.
    app.press_back(settle=2)
    _open_gift_tray(app)
    app._tap_element_center(_scroll_tray_to_tile(app, gift, _coin_count(price)))
    app.wait_for_text(f"Send {name} to {partner.name}?", timeout=15)  # chatGiftConfirmTitle
    app.wait_for_text_contains(f"→ {new_balance - price} left", timeout=5)  # chatGiftBalanceAfter
    app.tap_text(f"Send for {_coin_count(price)}", timeout=10)  # chatGiftSendFor

    app.wait_for_text(SENT_HEADING, timeout=30)
    app.wait_for_text(name, timeout=10)
    delivered = _wait_api(lambda: _gift_messages(partner.api, match_id, gift["id"], uid))
    assert delivered and len(delivered) == 1, f"coin gift not delivered exactly once: {delivered}"
    debited = _wait_api(lambda: _balance(api, uid) == new_balance - price)
    assert debited, f"wallet not debited by {price}: {_balance(api, uid)} (expected {new_balance - price})"
    app.save_artifact("gift_coin_sent_after_top_up")


@pytest.mark.case(CASE)
def test_coin_gift_needs_confirmation_and_debits_wallet(app, device_member, counterpart_factory):
    """Coin gift: the confirm sheet shows price and balance; "Not now" sends
    and charges nothing; "Send for N coins" sends once and debits exactly N."""
    api, uid = device_member.api, device_member.user_id
    _require_flags(api, "gifts_enabled")
    balance = _balance(api, uid)
    affordable = [g for g in _plain_paid(_active_gifts(api)) if _price(g) <= balance]
    if not affordable:
        pytest.skip(
            f"the shared QA member holds {balance} coins and cannot afford any paid gift; "
            "test_unaffordable_gift_opens_wallet_top_up_then_coin_gift_sends covers that state"
        )
    gift = min(affordable, key=_price)
    price, name = _price(gift), _gift_label(gift)
    match_id, partner = _fresh_match(device_member, counterpart_factory, "gp", f"Gift Paid {int(time.time()) % 100000}")

    _open_first_chat(app, partner.name, match_id)
    _open_gift_tray(app)
    app._tap_element_center(_scroll_tray_to_tile(app, gift, _coin_count(price)))
    title = f"Send {name} to {partner.name}?"
    app.wait_for_text(title, timeout=15)
    app.wait_for_text_contains(f"{balance} → {balance - price} left", timeout=5)
    app.wait_for_text_contains("never an obligation", timeout=5)  # chatGiftNoObligation
    app.save_artifact("gift_paid_confirm_sheet")

    # Not now: nothing sent, nothing charged.
    app.tap_text(NOT_NOW, timeout=10)
    app.wait_for_text_gone(title, timeout=10)
    time.sleep(2)
    assert not _gift_messages(partner.api, match_id, gift["id"], uid), "'Not now' still sent the gift"
    assert _balance(api, uid) == balance, "'Not now' still charged the wallet"

    # Confirm: sent once, debited exactly the price.
    _open_gift_tray(app)
    app._tap_element_center(_scroll_tray_to_tile(app, gift, _coin_count(price)))
    app.wait_for_text(title, timeout=15)
    app.tap_text(f"Send for {_coin_count(price)}", timeout=10)
    app.wait_for_text(SENT_HEADING, timeout=30)
    app.wait_for_text(name, timeout=10)
    delivered = _wait_api(lambda: _gift_messages(partner.api, match_id, gift["id"], uid))
    assert delivered and len(delivered) == 1, f"coin gift not delivered exactly once: {delivered}"
    debited = _wait_api(lambda: _balance(api, uid) == balance - price)
    assert debited, f"wallet not debited by {price}: {_balance(api, uid)} (expected {balance - price})"
    app.save_artifact("gift_paid_sent")
