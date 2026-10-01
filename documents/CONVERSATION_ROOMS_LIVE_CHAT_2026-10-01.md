# Conversation Rooms as live chat rooms (2026-10-01)

The owner's brief: rooms should work "just like random chat rooms like Yahoo
Messenger: if you like that person you can add him as a friend and have a
conversation." Rooms are now places to drop into and talk. Tapping a room joins
it and opens its chat; tapping a name opens that person's card with **Add
friend**, report and block.

## What a member sees

* **Rooms** (Settings → Conversation Rooms, Engage → Conversation Rooms; both
  hidden when `rooms_enabled` is off). Today look: `LIVE CHAT` eyebrow, "Rooms"
  headline, a live summary ("6 people chatting in 2 rooms").
  * **Your rooms**: rooms you are in.
  * **Live now**: rooms with someone here now, busiest first.
  * **Browse / Find your room**: every open always-on room, filtered by topic
    chips (All, Talk, Interests, Out & about, Your city) and a **Friends here**
    chip.
  * **Coming up**: member-hosted rooms that have not started.
  * **Start a room** (floating button): name, optional line, topic, 30 min / 1
    hour / 2 hours.
* **Room chat** (the shared chat screen, `openSocialChat`): title, topic band
  with the description and "N here now · M in the room", messages with
  long-press copy / delete / report, a **People** button and a menu with People
  here, Leave room, and for hosts and moderators **Moderate** (hosts of their
  own room also get **Close room**).
* **People here**: hosts first, then who is here now; each row has the
  status-aware `AddFriendButton` (Add friend / Requested / Accept friend /
  Message). Tapping a person (or a sender's name in the chat) opens their
  card: Add friend, Report, Block, and for hosts/moderators Warn, Mute (10
  minutes, 1 hour, until the room ends / 24 hours for always-on rooms) or
  Unmute, and Remove from room. Hosts and moderators see "Muted until 21:30"
  on muted members. Moderation never appears for ordinary participants.
* **Muted** (a host, moderator or operator muted you): the messages keep
  coming and the composer is closed with "You're muted in this room until
  21:30. You can still read along." It opens again by itself when the mute
  ends, or at once when a host unmutes you (a `social.channel.updated`
  real-time event refreshes the chat). Rooms have no notification bell (they
  never notify).

## Seeded always-on rooms (migration 117)

Late-night talks, First-date stories, Green flags only, Faith & reflection,
Bookworms' corner, Foodies' table, Music on repeat, Movie night, Pets & paws,
Gamers' lounge, Wanderlust, Fitness & runs, Bengaluru hangout, Mumbai locals,
Delhi diaries, Hyderabad nights. Each has a slug, description, category
(`talk`, `interests`, `active`, `city`), `icon_key` (mapped to a Material icon
in the app), an emoji, a sort order and capacity 200. Seeding is keyed on the
slug (`ON CONFLICT (slug) DO NOTHING`), so re-running never duplicates a room
or overwrites an operator's edits.

## Rules

| Topic | Rule |
| --- | --- |
| Member | Active adult dating member (`blogActive`) with a participant row that is `joined`, not left, and seen in the last 24 hours. Someone who disappears for a day lapses quietly; tapping the room rejoins. Capacity counts only current members. |
| Here now | Presence heartbeat under 2 minutes old. The chat screen sends one on open and every 45 s, and `state=away` when the member leaves the screen. Heartbeats closer than 20 s apart are not written (the participants table is audited). |
| Chat | Shared engine, channel kind `room`. Members = current members of an open room; moderators = current hosts/moderators (they can remove messages). Notifications off (rooms are live); real-time events still fan out. Leaving, lapsing, removal or the room closing ends read and post access at once. |
| Open | Always-on rooms until an operator closes them; hosted rooms until `ends_at`. Members may join a hosted room before it starts. Closing ends the chat. Closed rooms are listed for 7 days with `state=closed`. |
| Blocks | A member can still join a **public** room that someone they blocked (or who blocked them) is in. The engine hides each side's messages and real-time events from the other, the member list leaves them out, and `friends_here` excludes them. The "here now" and member **counts** are aggregate and still include them. A room **hosted** by someone either side blocked is hidden from the list and cannot be joined (404), so a host never moderates someone who blocked them. |
| Moderation | Only the room's hosts and moderators (or operators via the admin path) can warn or remove. The moderator is always the authenticated caller: `moderator_user_id`/`moderator_id` were added to the security middleware's actor list and the handler also refuses a mismatched value. Moderators cannot act on moderators; nobody but an operator acts on a host; nobody moderates themselves. |
| Mute (migration 119) | `mute_user` makes the member read-only: they keep reading and receiving real-time events, and posting returns 403 `CHANNEL_READ_ONLY` ("You're muted in this room until 21:30 UTC.", with `read_only_until`). Durations: `10m` (default), `1h`, `session` (the hosted room's end; 24 hours for always-on rooms) or `duration_minutes` 1-1440; never past a hosted room's end. Stored on the participant (`muted_until`, `muted_by_user_id`), so leaving and rejoining does not shake it off; muting again moves the end. It ends by itself at `muted_until`, or with `unmute_user` (a no-op that logs nothing when not muted). Not allowed in a closed room (409 `ROOM_NOT_ACTIVE`) or on someone who left or was removed (409 `ROOM_NOT_JOINED`). Each mute and unmute is logged in `conversation_room_moderation_actions` (`mute` / `unmute`, metadata `muted_until`, `duration`, `operator`), sends the member a `safety` notification (`room.moderation.mute` "You're muted in <room>" / `room.moderation.unmute` "You can post in <room> again") and a `social.channel.updated` real-time event. `muted_until` appears in the member list for hosts, moderators and the muted member only. |
| Removal | Status `removed`, chat access ends, a `conversation_room_blocks` row prevents rejoining until the session ends: the room's `ends_at` for hosted rooms, **24 hours** for always-on rooms. The removed member gets a `safety` notification (`room.moderation.remove`); a warning sends `room.moderation.warn`. |
| Hosting | Any active member may host: one open hosted room at a time, at most 3 started per 24 h, 30-180 minutes, starting now or within 7 days, 2-50 people (default 30). The host may warn, remove and close their room. A host keeps their role if they leave and come back. |
| Operators | `admin`, `moderator` and `trust_safety` roles: list rooms with counts and the last 100 moderation actions, list a room's members (current members, then anyone still muted or removed), warn/mute/unmute/remove anyone (hosts included) in any room, close any room, and appoint or step down room moderators (e.g. community moderators for always-on rooms, which have no host). |
| Reporting | Long-press a message → Report (case type `social_message`, the shared Open Chapters case queue). Report a person from their card (`/safety/report`, noting the room). |
| Erasure / export | Erasure deletes the member's participant rows and removal blocks, and closes any room they were hosting (and drops their name from it). The moderation log is retained as a safety record (declared in `retainedForSafetyAndLedger`). The data export includes `conversation_rooms` (rooms, role, status, times, hosted). |

## API

All under `/v1`, gated by `rooms_enabled`, bearer session required. With the
SQL store the existing routes use the live implementation; without it (unit
tests, store-less deployments) they fall back to the in-memory behaviour, which
now also requires the moderator to be a room host.

| Method | Path | Notes |
| --- | --- | --- |
| GET | `/rooms?state=&category=&friend_only=&limit=` | Rooms with `here_now`, `participant_count`, `friends_here`, `my_role`, `can_moderate`, `is_host`, `channel_id` (members only). No member ids. |
| POST | `/rooms` | Start a hosted room. 201 `{room}`. 409 already hosting, 429 daily limit. |
| GET | `/rooms/{roomID}` | Detail + `guidelines`; `channel_id` for members of an open room. |
| GET | `/rooms/{roomID}/members` | Members only (404 otherwise). `friend_status`: me, friends, requested, incoming, none. `muted_until` for hosts/moderators and the muted member. |
| POST | `/rooms/{roomID}/join` | Body optional. Returns `{room, joined, channel_id}`. 409 `ROOM_CLOSED`, `ROOM_CAPACITY_REACHED`, `ROOM_BLOCKED_ACTIVE_SESSION`. |
| POST | `/rooms/{roomID}/leave` | 409 `ROOM_NOT_JOINED`. |
| POST | `/rooms/{roomID}/presence` | `{state: here|away}` → `{room, here_now, participant_count}`. 409 `ROOM_NOT_JOINED` / `ROOM_BLOCKED_ACTIVE_SESSION` / `ROOM_CLOSED` (the app closes the chat). |
| POST | `/rooms/{roomID}/moderate` | `{target_user_id, action: warn_user|mute_user|unmute_user|remove_user|close_room, reason, duration?: 10m|1h|session, duration_minutes?}` (aliases `warn`, `mute`, `unmute`, `remove`). 403 for non-hosts and spoofed moderators; the entry carries `muted_until` for a mute. |
| GET | `/admin/moderation/rooms` | Operators. |
| GET | `/admin/moderation/rooms/{roomID}/members` | Operators: `{members: [{user_id, name, photo_url, role, status, joined_at, last_seen_at, here_now, in_room, muted_until?, removed_until?}], count}`. Current members first (hosts, moderators, then most recently seen), then anyone still muted or removed. |
| POST | `/admin/moderation/rooms/{roomID}/actions` | Operators: warn/mute/unmute/remove anyone, close any room (same body as `/moderate`). |
| POST | `/admin/moderation/rooms/{roomID}/roles` | Operators: `{member_id, role: moderator|participant}`. |

Chat itself is `/social/channels/{channel_id}/...` (migration 115). A room
channel carries `read_only`, `read_only_until` and `read_only_message` for a
muted member.

## Schema (migration 117)

`backend/scripts/117_conversation_rooms_live_chat.sql`, registered in
`scripts_run_order.txt` and `migrate_local_postgres.sh`. It reconciles the two
historical shapes (020 and 036):

* `conversation_rooms`: `title`, `description`, `capacity` (default 50, 2-500),
  `always_on`, `slug` (unique), `category`, `icon_key`, `emoji`, `sort_order`;
  020's `theme` is copied into `title` and made nullable; a schedule check
  (always-on, or a window that ends after it starts). Deleting a room deletes
  its chat channel (trigger).
* `conversation_room_participants`: `role` (host/moderator/participant),
  `status` accepting both shapes' values, `last_seen_at`; presence index.
* `conversation_room_moderation_actions`: `actor_user_id` in both shapes,
  `metadata`, actions `warn`, `mute`, `remove`, `close`, `set_role`.
* `conversation_room_blocks`: created if missing.

## Schema (migration 119)

`backend/scripts/119_chat_mutes.sql` (registered after 118):
`conversation_room_participants.muted_until` and `muted_by_user_id`; the
moderation log accepts `unmute`; `matching.social_channel_prefs`
(per-conversation notification mutes, see the friends doc); the real-time
event type `social.channel.updated`.

## Operator page (control panel)

`control-panel/control_panel/views_rooms.py`, templates `rooms.html` and
`room_detail.html`, nav link **Conversation Rooms** (Moderation section), URLs
under `/moderation/rooms/`. Everything goes through the Go admin API, which
accepts only operator roles (`admin`, `moderator`, `trust_safety`); the console
adds its usual operator-session middleware and CSRF on every form.

* **List** (`/moderation/rooms/?filter=`): all, live now (open with someone
  here), always-on, member-hosted (not closed), closed; counts per filter;
  title, type/host, state, here now, members, capacity, end time; and the 25
  most recent moderation actions with links to the room and member.
* **Room detail** (`/moderation/rooms/{id}/`): the room's facts, a
  **Members** table from `GET /v1/admin/moderation/rooms/{id}/members` (name
  and id linked to User Management, role, state such as "Here now", "In the
  room · muted until …" or "Removed until …", joined / last seen) with
  per-member actions: Warn / Mute (with a length) / Unmute (only for a muted
  member) / Remove with a reason, through the same action form and flow, and
  Appoint moderator / Step down (not for hosts or removed members); then the
  recent moderation actions. Member ids from the table and the actions are
  offered as suggestions in the room-wide forms. If the member list fails the
  page still loads and says so.
* **Actions** (`POST .../actions/`): Warn, Mute (10 minutes, 1 hour, or until
  the room ends), Unmute, Remove from room, Close room. A 5–280 character
  reason is required (kept in the room's moderation log) and the member id
  must be a UUID except for Close; invalid input never reaches the API.
* **Room moderators** (`POST .../roles/`): appoint (`moderator`) or step down
  (`participant`).
* Success and failure messages name the action and member; the Go side logs
  each action in `conversation_room_moderation_actions` and the activity
  audit.
* Tests: `control_panel/tests/test_rooms.py` (login and CSRF, escaping,
  filters, API errors, detail, the members table with per-member actions and
  role buttons, a failing member list, validation before the API,
  warn/mute/unmute/remove/close payloads, failures, appoint/revoke, client
  paths including `room_members`).

## Code

* Chat engine: `channelSpec.ReadOnlySQL` / `ReadOnlyMessage` in
  `social_channels.go` give any channel kind read-only members; the room spec
  uses it for mutes.
* Backend: `live_rooms.go` (rules, SQL, channel spec), `server_live_rooms.go`
  (HTTP, operator routes), `server_rooms.go` (routes the old handlers to the
  live path), `rooms.go` / `conversation_room_repository.go` (host-only
  moderation in the fallback paths), small edits to `server.go`,
  `server_security.go`, `account_erasure.go`,
  `account_lifecycle_repository.go`, OpenAPI.
* App: `features/engagement/providers/conversation_rooms_provider.dart`
  (models, `RoomsApi`, `roomMembersProvider`), `screens/conversation_rooms_screen.dart`,
  `screens/room_chat.dart` (chat header + heartbeat, people sheet, member card,
  moderation, mute sheet); Settings tile gated by `rooms_enabled`. Every room
  string is in the ARB files (`rooms*` and the shared `chat*` keys, 10
  locales); `social_chat/social_chat_l10n.dart` falls back to English when a
  widget tree has no app localizations.

## Tests

* Go (`live_rooms_test.go`, Postgres): seeded rooms listed, join returns the
  channel, members list for members only with friend hints, engine membership
  (non-members cannot read or post; leaving and lapsing revoke), fan-out,
  reporting, presence here/away, blocked pairs in a public room, hosted-room
  visibility across blocks, capacity, hosting limits, spoofed moderator, host
  warn/remove, removal blocks rejoin (until `ends_at`; 24 h for always-on),
  operator path refused to members, operator removal and role appointment,
  moderator limits, host closes and chat ends. Plus unit tests for the
  identity check and action names, and the existing room tests (in-memory
  moderation now requires a host; a new test covers a non-host).
* Flutter (`test/features/engagement/conversation_rooms_screen_test.dart`):
  list renders seeded rooms with presence and topic filters; tapping joins and
  opens the chat with the presence band and sends `away` on leaving; the people
  sheet shows Add friend (source `room`) and a participant sees no moderation;
  a host moderates with `warn_user`; a host mutes with `mute_user` + `1h`; a
  muted member shows "Muted until" with Unmute for the host; the list, chat
  and menu render in German.
* Go mute tests (`TestLiveRoomMutePostgres`, `TestRoomMuteUntil`,
  `TestAdminRoomMembersPostgres`): the rule set (participants, self, spoofed
  moderator, moderator on moderator/host, operator on host), muted members read
  and get real-time events but cannot post (403 `CHANNEL_READ_ONLY`), the log,
  notifications and `social.channel.updated` event, who sees `muted_until`,
  leave/rejoin keeps the mute, unmute (and a no-op repeat), session mutes end
  with the room (24 hours for always-on), custom minutes, expiry, closed
  rooms; the operator member list (403 for members, 404 for an unknown room,
  muted and removed rows, hosts first).
* Flutter `test/features/social_chat/chat_mutes_test.dart`: a muted member's
  composer is closed with the explanation and reopens when unmuted.

## Not done

* Server-sent text (errors such as "This room is full right now", the
  moderation notifications) is still English; the app shows it as sent.
  `RoomsApi` fallback errors and the "Member" fallback name in
  `conversation_rooms_provider.dart` are English too.
* `kFeatureConversationRooms` (compile-time flag) is still unused dead code;
  its test only checks the type, so it was left in place. Runtime gating uses
  `rooms_enabled`.
