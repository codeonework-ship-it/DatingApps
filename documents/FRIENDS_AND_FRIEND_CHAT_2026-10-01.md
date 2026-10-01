# Friends and friend chat (Connect, steps 1 and 2)

Date: 2026-10-01. Migration: `backend/scripts/116_friend_requests.sql`.

Friends is the base of the social layer. Rooms and Groups call into it
(`sendFriendRequest`, `AddFriendButton`), and friend conversations run on the
shared chat engine (`social_channels.go`, migration 115).

## Data model

- `matching.friend_connections`: a request is one `pending` row
  requester → recipient. A friendship is two `accepted` rows. New column
  `source` (`search|match|profile|room|group`, nullable for older clients).
- `matching.friend_request_declines (requester_id, recipient_id, declined_at)`:
  the last decline of a requester by a recipient. Cleared when the two become
  friends.
- `matching.friend_request_sends (requester_id, recipient_id, source, created_at)`:
  one row per request sent. Read for the rolling 24-hour limit.
- Prefix indexes on `lower(username)` and `lower(name)` for member search.
- The migration also repairs pairs that an older build half-downgraded: one
  row `accepted` and the reverse `pending` becomes two `accepted` rows.
- Account erasure (`account_erasure.go`) deletes the member's friend
  connections, declines and send-ledger rows.

## Rules

All of these are enforced in one transaction per call. Each pair is
serialised with an advisory lock, and both members are re-checked
(`friend_requests.go`).

| Rule | Behaviour |
|---|---|
| No downgrade | Sending a request to an accepted friend returns the friendship unchanged. A half-accepted pair is repaired. A repeated request returns the open one; it sends no new notification and does not count again. |
| Mutual auto-accept | If B already asked A, A asking B accepts B's request. Both rows become `accepted`, both get a `friend_connected` activity, and B is told (`friend_request.accepted`). |
| Active members only | Both members must be active adult dating members (`blogActive`). Otherwise the call returns 403 (caller) or 404 (other member). |
| Blocks | A block in either direction makes send and accept return 404 ("isn't available"). Blocked pairs are hidden from the list and from search. |
| Decline cooldown | After a decline, the same requester gets 429 for 7 days. The recipient can still ask the requester, which creates a friendship. Removing an incoming request with DELETE counts as a decline. |
| Daily limit | At most 30 new requests in any 24 hours (429). Cancelling a request does not free a slot. A mutual accept is not a new request and is never limited. |
| Notifications | Recipient: `friend_request.received` "<name> wants to be friends", route `/friends`, deduplicated per pair per UTC day. Requester on accept: `friend_request.accepted` "<name> accepted your friend request". A decline is silent. Category `friend_plan`, the same category vouches use, so it follows the member's "friend plans" notification preference. |
| Source | Stored on the request and kept on both rows when the request is accepted. It also appears in the activity metadata. |
| Ownership | `/friends/{userID}` must be the signed-in member. The security middleware already enforces this, and the Postgres path checks it again (401/403). |

The in-memory store (tests, mock backend) applies the same rules apart from
notifications. The legacy PostgREST repository path (`social_repository.go`,
used only without the native database) handles no-downgrade, mutual accept and
source. It does not apply the cooldown or the daily limit.

## API

| Method | Path | Notes |
|---|---|---|
| GET | `/v1/friends/{me}` | `{friends:[...]}`. Each row has `user_id, friend_user_id, status, direction ('', incoming, outgoing), created_at, updated_at, friend_name` plus new optional fields `friend_username, friend_photo_url, friend_city, source`. |
| POST | `/v1/friends/{me}` | `{friend_user_id, source?}` → `{friend}` (pending, or accepted for a mutual request). Errors: 400 (self, bad source), 403, 404 (unavailable or blocked), 429 (cooldown or daily limit). |
| POST | `/v1/friends/{me}/{requester}/decision` | `{decision: accept\|decline}`. Returns 404 when the request is no longer open or the requester is unavailable. |
| DELETE | `/v1/friends/{me}/{other}` | Unfriend, cancel my request, or decline theirs. |
| GET | `/v1/friends/{me}/search?q=` | New. `q` needs at least 3 letters; a leading `@` is ignored and LIKE wildcards are matched literally. Matches a prefix of the username, of the name, or of any word in the name. Covers active adult dating members only, excluding me and anyone blocked either way. Returns at most 10, with an exact username match first. |
| POST | `/v1/social/friends/{friendID}/channel` | Existing (migration 115). Opens the friend conversation. |

Search opt-out (migration 120): `GET|PUT /v1/friends/{me}/search-visibility`
`{visible: bool}` reads and sets "Let people find me in friend search"
(default on), stored as `user_management.user_settings.friend_search_visible`
(the existing per-member settings row; created with defaults if missing). When
it is off the member is left out of everyone's `/friends/{me}/search` results
(Postgres and in-memory). Nothing else changes: they can still be added from a
match, a room, a group or their profile, where the other person already sees
them, and they can still search for others. Only the member can read or change
it (security middleware path ownership plus a handler check). It is a separate
endpoint rather than a field of `/v1/settings/{userID}` because that API goes
through the profile module's store gateway, which other work owns.

Search privacy: results carry only `user_id, name, username, city, photo_url,
relationship (none|friends|outgoing|incoming)`. They never include age, bio,
gender, email or exact location (`TestFriendSearchPrivacyPostgres` asserts the
key set).

OpenAPI (`backend/internal/platform/docs/openapi.yaml`) documents all of the
above. Every non-GET route references `Idempotency-Key`.

## App

- `app/lib/features/friends/friend_actions.dart`
  - `sendFriendRequest(ref, userId, source:)` keeps the same signature. It now
    goes through `friendsProvider` so every screen updates.
  - `friendRelationProvider(userId)` → `FriendRelation.none|outgoing|incoming|friends`.
  - `AddFriendButton(userId:, source:, name:, style: button|icon|tile)` is
    status-aware: Add friend → Requested (tap to cancel) → Accept friend →
    Message. It is hidden for yourself. Rooms and Groups can drop it into
    member lists.
  - `openFriendChat(context, ref, friendId:, name:)` calls `openFriendChannel`
    and then `openSocialChat`.
- `providers/friends_provider.dart`: richer `FriendConnection` (username,
  photo, city, source; `isIncoming/isOutgoing/isAccepted`). It adds
  `FriendsState.incoming/outgoing/accepted/connectionWith`,
  `FriendsNotifier.request(...)` (throws) and `friendSearchProvider(query)`.
- `screens/friends_screen.dart` is rebuilt in the Today look
  (`ConnectPageHeader`, `ConnectSectionHeader`, `ConnectPanel`,
  `ConnectNavTile`, theme colours only, 4pt spacing, 48pt targets):
  - Header "FRIENDS / Your people" with Add friend and Create a group.
  - **Requests**: incoming requests with Accept and Decline (and a line such as
    "Met in a room"), and outgoing requests with Cancel.
  - **Chats**: friend conversations from `socialChannelsProvider` with unread
    badges and a notifications-off icon for muted chats.
  - Intros and vouches waiting for you (unchanged behaviour, shown when
    `friend_intros_enabled`).
  - **Friends**: avatar, name, @username · city. Message opens the friend chat,
    with an unread badge. The menu offers Vouch, Introduce (intros flag),
    Remove (confirmed) and Block (`blockCommunityMember`).
  - Vouches on your profile, a More section (date plans, introducers,
    introduction settings) and recent activity.
  - The Add friend sheet has a live search (300 ms debounce, at least 3
    letters), and each result has an `AddFriendButton`.
  - Create a group: multi-select friends, then
    `openCreateGroup(context, invitees: ...)`. The callback is injectable as
    `FriendsScreen(createGroup:)` for tests.
- The match options sheet (`matches_list_screen.dart`) has an Add friend tile
  with source `match`. The profile details app bar
  (`profile_details_screen.dart`) has an Add friend icon with source
  `profile`.
- Notifications: push taps and inbox taps on `friend_request.*` open Friends
  (`main_navigation_screen.dart`, `notification_inbox_screen.dart`). Friend
  message notifications already use route `/friends`.

## Search opt-out in the app

- `friendSearchVisibilityProvider` (`providers/friends_provider.dart`) reads and
  saves the setting; the switch moves at once and returns if saving fails.
- Privacy & Safety (`privacy_safety_screen.dart`): switch "Let people find me in
  friend search" with the explanation that people they match or meet in rooms
  and groups can still add them.
- The Add friend sheet shows "You're hidden from friend search, so others
  can't find you here. Change this in Privacy & Safety." when it is off.
- Tests: Go `TestFriendSearchOptOutPostgres` (default on, ownership, bad input,
  opted-out member hidden, other settings untouched, request from a match still
  works, the member can still search, opt back in) and
  `TestFriendSearchOptOutInMemory`; Flutter
  `test/features/friends/friend_search_visibility_test.dart`.

## Muting a conversation's notifications (migration 119)

Any member can silence notifications from one friend chat or group chat
without leaving it; nothing else changes and the other person is not told.

- Stored per member and conversation in `matching.social_channel_prefs
  (channel_id, user_id, muted_until)`; `'infinity'` means "until I turn it
  back on", NULL means not muted. A mute ends by itself at `muted_until`.
- The chat engine (`notifySocialRecipients` in `social_channels.go`) skips
  members with a running mute when it sends `social.message.new` (still at
  most once per conversation every ten minutes for everyone else). Real-time
  events (`social.message.created` / `deleted`) still reach them, so an open
  chat updates as usual.
- API: `PUT /v1/social/channels/{id}/mute` `{duration: 1h|8h|1w|forever}` (or
  `{minutes: 1-43200}`) and `DELETE /v1/social/channels/{id}/mute`; both are
  idempotent, members only (404 otherwise), and return `{channel, muted,
  muted_until}`. Every channel from `GET /v1/social/channels` and
  `GET /v1/social/channels/{id}` carries `muted` and `muted_until` (null while
  muted forever) for the caller only.
- Account erasure deletes the member's rows.
- App: a bell in the chat app bar (friend and group chats; rooms never notify
  so they have none) opens a sheet: For 1 hour, For 8 hours, For 1 week,
  Until I turn it back on, and Turn notifications back on when muted; the
  bell shows notifications-off while muted. `SocialChannel.muted` /
  `mutedUntil` are parsed in `social_chat_data.dart`; the Friends screen's
  **Chats** rows show a notifications-off icon for muted chats
  (`qa.friends.muted.<channel>`). The groups lists read group rows, not
  channels, so they do not show it yet.
- Not to be confused with a room mute (a host stops someone posting): that is
  read-only membership in the engine (`channelSpec.ReadOnlySQL`, channel
  fields `read_only`, `read_only_until`), described in the rooms doc.
- Tests: Go `TestSocialNotificationMutePostgres` (validation, non-members,
  muted conversation sends no notification but the real-time event arrives,
  list and channel carry the mute for the member only, expiry, forever,
  unmute twice, custom minutes) and `TestParseSocialMute`; Flutter
  `test/features/social_chat/chat_mutes_test.dart` (the bell sheet calls PUT
  with `8h`, DELETE, then `forever`; German strings).

## Tests

- Go (`backend/internal/bff/mobile/friend_requests_test.go`, needs
  `PROFILE_TEST_DATABASE_URL`):
  - No downgrade and half-pair repair; mutual auto-accept with source,
    activity and notifications; idempotent repeat (`...NoDowngradeMutual...`).
  - Silent decline; 7-day cooldown; accept clears declines; DELETE of an
    incoming request counts as a decline; unfriend (`...AcceptAndDeclineCooldown...`).
  - 30/24h limit; mutual accept works at the limit (`...DailyLimit...`).
  - Blocks both ways on send and accept; blocked pairs hidden from lists;
    friend card fields; path ownership 401/403; source validation
    (`...BlocksAndOwnership...`).
  - Search key set, blocked and self hidden, relationships, inactive members
    hidden, short query 400, literal wildcards, limit
    (`TestFriendSearchPrivacyPostgres`).
  - In-memory rules and search (`TestFriendRequestRulesInMemory`,
    `TestFriendSearchInMemory`). `TestServer_FriendRequestDeclineAndBlockPreventConnection`
    was updated for the cooldown.
- Flutter:
  - `app/test/features/friends/friends_screen_test.dart`: sections with names,
    not ids; accept, decline and cancel; search and add; Message opens the
    chat; Create a group passes the selected friends.
  - `app/test/features/friends/add_friend_match_sheet_test.dart`: Add friend
    from the match sheet sends `source: match` and then shows Requested.

## Not done / follow-ups

- There is no separate per-member rate limit on search beyond the API's
  general limits.
- The search opt-out is not part of `GET /v1/settings/{userID}`; the app reads
  it from `/friends/{me}/search-visibility`.
- Friend notifications use the `friend_plan` category. A dedicated `friend`
  category would need a notification-preference change.
- The legacy PostgREST path has no cooldown or daily limit.
