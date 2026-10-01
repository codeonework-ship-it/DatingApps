# Gift receiver controls

Status: **implemented and verified locally on 2026-09-27**

## Product contract

- An incoming gift is labelled `Gift received from <member>` in chat.
- The notification title is `Gift received`; its body names the sender and gift and never exposes the encoded chat token.
- Only the recorded receiver can act on the gift.
- `Hide gift` removes the gift from that receiver's chat. It does not delete the sender's message or alter the gift or wallet ledger.
- `Report and hide` immediately hides the gift and opens one pending moderation case with a required reason and up to 500 characters of optional detail.
- Repeated hide and report requests are safe. A repeated report returns the existing moderation case rather than creating a duplicate.

## Architecture and safety

Migration `083_gift_receiver_controls.sql` stores receiver actions against the canonical gift send and enforces receiver ownership in PostgreSQL. The BFF verifies the authenticated principal against the recorded receiver and filters hidden gift messages only for that member.

Both actions write an immutable security audit record and a transactional semantic domain event (`gift.receiver_hidden` or `gift.receiver_reported`). The action table is also registered with the generic event backbone. Reporting links the action to `matching.moderation_reports`, so the existing command-center moderation queue receives the case without a separate store.

The implementation does not change gift prices, wallet debits, checkout, settlement or any other billing-owned behavior.

## Acceptance evidence

- PostgreSQL integration: sender access denied, receiver hide accepted, receiver-only filtering, one moderation case under replay, semantic events emitted.
- Notification integration: receiver-facing title/body and no encoded gift token.
- Flutter widget: received wording and visible `Gift options` control.
- Flutter provider: receiver-scoped hide/report routes, reason payload and stable idempotency keys.
- OpenAPI route coverage and idempotency semantics pass.

Production activation of the wider gift economy remains governed by the release and billing gates in the pending feature backlog.
