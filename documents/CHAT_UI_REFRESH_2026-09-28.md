# Chat UI refresh — 28 September 2026

The shared Flutter chat experience now adapts to Android, narrow browser windows and desktop web. Colors come from the selected theme, including light and dark presets.

## Delivered

- Conversations inbox with search, unread filtering, readable previews and visible conversation options.
- Responsive chat layout: compact mobile header and a desktop member sidebar with conversation shortcuts.
- Refined message bubbles, local timestamps, read/delivery descriptions and date separators.
- Larger multiline composer with separate gift, emoji and writing-assistance controls. Web supports Enter to send and Shift+Enter for a new line.
- Gift selection cards with category filters and constrained scrolling; focusing the editor closes the gift tray.
- Clear empty, locked, offline and quota states. Online status is no longer inferred without evidence, and local editor activity no longer falsely claims the other member is typing.
- Send confirmation preserves failed drafts and any new draft typed while the previous message is pending. Duplicate sends are disabled during a request.

Existing gift confirmations, receiver hide/report actions, message deletion, date plans and writing assistance remain connected to their existing handlers. Billing implementation was not changed.

## Verification

- 78 targeted Flutter tests pass across messaging, matching and theme suites.
- Layout coverage includes 320, 390, 800 and 1440 pixel widths, light/dark themes, 2× text scaling, keyboard insets and gift-tray behavior.
- Browser acceptance covers 390 and 1440 pixel widths: inbox search, conversation rendering, exact message submission, quota refusal, preserved draft retry and gift selection.
- Browser tests use a local QA login and intercepted conversation APIs. They send no messages to real members and do not establish production delivery guarantees.
- Release web build and Android debug APK build succeed. Android installation targets the local emulator; physical-device acceptance remains outside this check.
- Scoped analysis has no errors or warnings; informational style lints remain. Scoped whitespace validation passes.

## Review

- [Local inbox](http://127.0.0.1:4190/app/#/matches)
- [Desktop chat](../qa/results/chat-redesign/conversation-1440.png)
- [Mobile chat](../qa/results/chat-redesign/conversation-390.png)
- [Mobile gift tray](../qa/results/chat-redesign/gifts-390.png)

This is a local UI update, not a production deployment.
