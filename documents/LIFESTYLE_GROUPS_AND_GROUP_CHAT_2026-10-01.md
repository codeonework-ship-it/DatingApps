# Lifestyle groups and group chat (2026-10-01)

The owner's brief: "we can create a community group of different lifestyle → we
can add multiple friends"; "friends list can lead to a community group or just
groups." This replaces the old free-text Community Groups screen (comma-separated
user ids, no chat) with two kinds of group, a lifestyle catalogue, friend-only
invitations and group chat on the shared chat engine.

## Two kinds of group

| | Community group (`kind=community`) | Private group (`kind=private`) |
|---|---|---|
| Who can find it | Everyone, under its lifestyle category (Discover) | Only members and invitees |
| How people join | Join directly, or accept an invitation | Accept an invitation only |
| Category | Required (one lifestyle) | None |
| Who can invite | Any member (it is open anyway) | Owner and moderators only |
| Member cap | 200 | 50 |

A group never switches kind after creation (a private group's members agreed to
a private group).

## Lifestyle catalogue (migration 118)

`matching.group_categories` (slug, title, emoji, description, sort order,
`is_active`). Seeded with 25 categories: Fitness & running, Foodies, Travel,
Outdoors & hiking, Books, Music, Movies & series, Arts & crafts, Dance, Gaming,
Pets, Wellness & mindfulness, Faith & spirituality, Volunteering, Career &
founders, Learning & languages, Tech & science, Sports fans, Nightlife, Sober &
mindful drinking, Parents & family, LGBTQ+ community, Culture & heritage, New in
town, Friends & socials. Operators can add rows or set `is_active=false`;
existing groups keep their category.

## Schema changes (migration 118, `backend/scripts/118_lifestyle_groups.sql`)

- `matching.community_groups`: `kind` (community/private, default private),
  `category_slug` (FK to categories, required for community), `cover_emoji`,
  `cover_color` (a theme role: primary/secondary/tertiary, so every theme keeps
  its contrast), `member_cap` (2–500). `city` and `topic` now default to `''`
  (topic mirrors the category title for older readers).
- Backfill: existing public groups become community groups in "Friends &
  socials"; private groups stay private. Old rows remain valid.
- Indexes: discover by category, active members per group, pending invites per
  invitee.
- Runtime flag `groups_enabled` (seeded TRUE) gates every
  `/v1/engagement/groups*`, `/v1/engagement/group-invites`,
  `/v1/engagement/group-categories` and `/v1/engagement/group-friends` route.
  The app hides the Engage tile and the web `/groups` destination when it is off.
- Registered in `backend/scripts_run_order.txt` and
  `backend/scripts/migrate_local_postgres.sh`.

## Rules

- **Identity.** Every actor is the authenticated principal. The old handlers
  trusted `owner_user_id`, `inviter_user_id` and `user_id` from the body; those
  keys are now in the identity middleware's actor list (a body naming someone
  else is rejected with 403 before the handler) and the handlers ignore them.
- **Friends only.** Every invitee (at creation or later) must be an accepted
  friend of the inviter in both directions, an active adult member, and on
  neither side of a block. One bad invitee rejects the whole request (403) and
  nothing is created. Up to 50 invitees per request and 200 invitations per
  inviter per day. Existing members and already-pending invitations are skipped;
  a declined invitation can be re-sent.
- **Blocks.** Community groups owned by someone either side has blocked are
  hidden from Discover and detail. Invitations from blocked members are hidden.
  Member lists hide members either side has blocked. Chat hides blocked senders
  (engine rule).
- **Roles.** The owner is `community_groups.created_by_user_id` (single source
  of truth; legacy rows whose owner row says `member` are read as owner). The
  owner edits, deletes, makes and unmakes moderators, and removes anyone;
  moderators remove plain members. Removed members cannot rejoin a community
  group by themselves; the owner or a moderator can re-invite them.
- **Leaving.** When the owner leaves, ownership passes to the longest-standing
  moderator, else the longest-standing member. An owner alone deletes the group,
  its invitations and its chat.
- **Privacy.** Members see `channel_id`, `owner_user_id`, the member preview and
  the full member list. Non-members of a community group see the description and
  member count only; non-members never see private groups (404).
- **Limits.** 10 owned groups, 50 joined groups per member.
- **Notifications** (category `system`, route `/groups`):
  `group.invite.received` — "<name> invited you to <group>"; and
  `group.invite.accepted` — "<name> joined <group>" to the inviter (skipped if
  either side has since blocked the other).
- **Account erasure** hands owned groups to the next moderator/member, deletes
  memberships and invitations, and deletes groups (and chats) nobody else is in.
  The data export gains `group_memberships` and `group_invitations`.

## Group chat

`lifestyle_groups.go` registers channel kind `group` with the shared engine
(`social_channels.go`, migration 115):

- members = active rows in `community_group_members`;
- moderators = the owner plus moderators (they can remove others' messages);
- title = the group name; route `/groups`;
- `Notify: true` — members get at most one "New message" notification per group
  per ten minutes (the engine's bucket), the same as friend chats.

Membership is read live, so leaving or being removed revokes the chat at once.
Joining (create, accept, join) marks the chat read up to now so newcomers are not
greeted with a wall of unread messages. Groups created before 118 get a channel
on first detail view. Reports of group messages use the existing `social_message`
case type.

## Reporting a whole group (migration 120)

`backend/scripts/120_group_reports_friend_search_optout.sql` adds
`community_groups.moderation_state` (`active`/`removed`) and `version`, and
adds `group` to `matching.blog_cases_content_type_check` (the migration keeps
every kind already allowed, so it is safe whatever order 119/120 run in).

- **Who can report.** Anyone who can see the group: any member (community or
  private), an invitee, or anyone who can see a community group (not someone
  either side of a block with the owner). The owner cannot report their own
  group. `POST /v1/blog/reports/group/{groupID}` with the usual
  `{reason, description}` creates a case in the shared moderation queue
  (`createBlogCase` → `readActivityForReport` → `readGroupForReport` in
  `lifestyle_groups.go`). One case per reporter per group.
- **Snapshot.** Name, description, kind, category (slug and title), city, cover
  emoji, owner id and member count, with `title: "Group · <name>"` and
  `body: <description>` so the Blog Moderation page shows it like other
  activity cases. The subject is the owner.
- **Removal decision** (`activityModerationTables["group"] =
  "community_groups"`) sets `moderation_state='removed'` and bumps `version`.
  The group then:
  - leaves Discover, category counts, search and detail for non-members (404);
  - cannot be joined, nor can invitations be accepted (403 "This group was
    removed after a review."); pending invitations are hidden;
  - has no chat: the `group` channel spec only counts members of active groups,
    so reading and posting stop at once and `channel_id` is not returned;
  - cannot be edited or have new invitations sent (403); the owner can still
    delete it, and members can still leave or be managed;
  - stays in members' "Your groups" with `moderation_state: removed`,
    `removed: true`, `can_invite/can_join: false`.
  The owner gets the existing review notice ("A review of something you shared
  has an update", route `/blog`) and can appeal from their review notices.
- **Restore** sets `moderation_state='active'` (unless another removal case
  still holds) and everything comes back, including the chat history.
- **App.** Group detail: non-owners get a "More options" menu with **Report
  group** (`reportCommunityItem(kind: 'group')`); owners keep "Owner tools"
  (Edit is hidden while removed; Delete stays). Members of a removed group see
  "This group was removed after a review" with Members and Leave only (owners
  are pointed to their review notices to appeal). Group cards show "Removed
  after a review". Discover cards have no overflow menu, so reporting is from
  the detail screen.
- **Tests.** Go `TestGroupsReportRemoveRestorePostgres` (who can report,
  snapshot, removal hides/blocks join/accept/invite/edit/chat, owner notice,
  restore). Flutter `groups_test.dart`: report from detail, owner tools vs
  report, removed notice.

## Cover photos (migration 121)

`backend/scripts/121_group_cover_photos.sql` adds
`matching.community_group_covers`: one row per upload attempt (storage key,
MIME type, width/height, size, SHA-256, moderation status/reason/provider,
uploader, reviewer, `created_at`, `deleted_at` + `delete_reason`,
`storage_released_at`). A partial unique index allows one live row
(`deleted_at IS NULL`) per group: the current cover. `group_id` has no foreign
key so a deleted group's rows outlive it until their objects are released.
`cover_emoji`/`cover_color` stay as the fallback wherever no photo is shown.
Code: `backend/internal/bff/mobile/group_covers.go`.

- **Who.** The owner only (the same rule as editing the group). Moderators
  cannot change the cover: the photo speaks for the whole group, and keeping
  it with the owner keeps one accountable person per reviewed item. Not while
  the group is removed after a review (403), so the reviewed content stays as
  reviewed.
- **Upload.** `PUT /v1/engagement/groups/{id}/cover`, multipart `image` plus an
  optional client `cover_id` UUID (a retry with the same id returns the saved
  result; another group or member reusing it gets 409). JPEG or PNG, at most
  10 MB, 300–4096 px a side; the signature is checked, then the image is
  decoded and re-encoded (`sanitizeBlogPhoto`, as Photo Themes) so EXIF and
  other metadata, location included, never reach storage. WebP/HEIC are
  refused because they cannot be re-encoded without new dependencies (the app
  picks with `imageQuality`, so phones send JPEG). 10 uploads per group per day
  (rejections count, 429). Excluded from the idempotency replay ledger like
  theme uploads (`server_resilience.go`); `DELETE` keeps replay protection.
- **Storage.** `s.storeMedia(ctx, "group_covers/<group>", "<cover>.<ext>", …)`:
  kind `group_covers` (local `public/group_covers/`, S3 `public/group_covers/`
  prefix). Every read is still authorized by the API.
- **Moderation.** The shared media moderator. `approved` → shown to everyone
  who can see the group. `review_required` → stored as `pending`: the owner
  sees it with an **Under review** badge, members see the emoji cover, and it
  waits in the operator queue. `rejected` → nothing stored, the current cover
  stays, 422 "This photo could not be approved. Your cover was not changed."
- **Operator queue.** `GET /v1/admin/moderation/group-covers?status=pending|approved`,
  `GET …/{coverID}/content` (no-store bytes), `POST …/{coverID}/decision`
  `{decision: approved|rejected, reason}` (moderator, trust & safety or admin).
  Rejection hides the cover at once, deletes the object and notifies the
  owner (`group.cover.rejected`, category `system`, route `/groups`: "Your
  cover photo for <group> wasn't approved"); the owner then sees
  `cover_photo_status: rejected` (for 14 days, or until they upload or remove)
  with "Your last cover photo wasn't approved. Choose a different one."
  Control panel: **Moderation → Group Covers** (`/moderation/group-covers/`,
  `views_group_covers.py`): pending (oldest first) and approved tabs, the image
  proxied through `/moderation/group-covers/<id>/content/` with the operator's
  session, Approve, and Reject with a required 5–200 character reason.
- **Who sees it** (`groupCoverVisibleSQL`). Only viewers who can see the group
  (private groups stay 404 to non-members); never while the group is removed
  after a review (members included); pending covers to the owner only; a cover
  uploaded by someone either side has blocked is hidden (a member who blocked
  the owner sees the group but the emoji cover).
- **Group JSON.** `cover_photo_url` (`/v1/engagement/groups/{id}/cover?v=<cover id>`,
  so the URL changes with the photo) and `cover_photo_id`, only when the viewer
  may see the photo; `cover_photo_status` (`pending`/`approved`/`rejected`) for
  the owner only.
- **Serving.** `GET /v1/engagement/groups/{id}/cover` streams the bytes with
  `ETag` (content SHA-256, `If-None-Match` → 304), `X-Content-Type-Options:
  nosniff`, `Cache-Control: private, max-age=300` (pending: `private,
  no-store`). Group cover keys are not reachable through `/v1/media/*`.
- **Deleting objects.** Replace, remove, operator rejection and group deletion
  (delete, or the last member leaving) tombstone the row and delete the object
  right after commit (`releaseGroupCoverMedia`); the hourly media worker
  retries failures and purges release records after 30 days. A cover held as
  report evidence, or uploaded by a member on legal hold, is kept until
  released. Live covers are in the orphan sweep's reference set
  (`media_cleanup.go`) and in the evidence-release reference check
  (`blog_trust.go`).
- **Account erasure.** Every cover the member uploaded is removed (a group
  handed to someone else falls back to its emoji), covers of groups erasure
  deletes go too, their keys join the erasure summary's released storage
  paths, and no cover row keeps naming the member.
- **Data export.** `group_covers_uploaded` lists every cover row the member
  uploaded (group id, cover id, status, uploaded_at, mime type, size, and
  `removed_at` for replaced/removed/rejected uploads); never storage keys,
  hashes or bytes.
- **Reports.** A report of a group (case kind `group`) now records
  `cover_photo_id` in the snapshot and copies the cover the reporter saw into
  `matching.blog_evidence_photos`, so operators can view it from the case
  (`/v1/admin/moderation/blog/{caseID}/photos/{photoID}`) even after the owner
  replaces it.
- **App.** Group detail: a 3:1 banner with a bottom gradient scrim (white
  caption over roughly 65–85 % black, about 7:1 even on a white photo), the **Under review** badge
  (solid `secondaryContainer`), and for the owner **Add cover photo / Change
  cover** and **Remove cover** (also in Owner tools). Picking offers your photos
  or the camera (`image_picker`, max 2048 px, quality 88, the same package as
  profile photos), then a banner-cropped preview to confirm (no cropper
  dependency was added); uploads show a progress bar. The create flow has an
  optional cover photo, uploaded right after the group is created (a failed
  upload leaves the group on its emoji). Cards, invitations and the chat header
  show the photo thumbnail with the emoji tile as fallback (while loading, on
  errors, or without a photo). Images load through the authenticated API as
  bytes (`groupCoverPhotoProvider`, like theme photos), cached for five minutes
  per cover id. Strings are hard-coded English like the rest of Groups.
- **Muted chats.** "Your groups" cards show a small notifications-off icon
  (and "notifications muted" in their label) when the member muted that
  group's chat (migration 119, matched by the `group` channel's `ref_id`).

## API (`/v1`, all require a session; OpenAPI tag `groups`)

| Method | Path | Purpose |
|---|---|---|
| GET | `/engagement/group-categories` | Lifestyle catalogue with community group counts |
| GET | `/engagement/group-friends?group_id=` | Friends for the picker; with a group: `available`/`member`/`invited` |
| GET | `/engagement/groups?scope=mine\|discover&category=&q=` | My groups (with unread chat counts) or Discover |
| POST | `/engagement/groups` | Create `{group_id?, kind, category_slug?, name, description?, city?, cover_emoji?, cover_color?, invitee_user_ids[]}`; a repeated `group_id` from the same owner returns the group |
| GET | `/engagement/groups/{id}` | Detail (+ `channel_id`, `members_preview` for members) |
| PATCH | `/engagement/groups/{id}` | Owner edits name, description, city, cover, category |
| DELETE | `/engagement/groups/{id}` | Owner deletes for everyone |
| POST | `/engagement/groups/{id}/join` | Join a community group (idempotent) |
| POST | `/engagement/groups/{id}/leave` | Leave (ownership hand-off / delete when alone) |
| GET | `/engagement/groups/{id}/members` | Members only: names, photos, roles, `is_friend` |
| POST | `/engagement/groups/{id}/members/{userID}` | `{action: make_moderator\|make_member\|remove}` |
| POST | `/engagement/groups/{id}/invites` | Invite friends `{invitee_user_ids[]}` |
| POST | `/engagement/groups/{id}/invites/respond` | `{decision: accept\|decline}` (idempotent) |
| GET | `/engagement/group-invites` | My pending invitations |
| GET | `/engagement/groups/{id}/cover` | Cover photo bytes (viewers who may see it; ETag, 304) |
| PUT | `/engagement/groups/{id}/cover` | Owner uploads/replaces the cover (multipart `image`, `cover_id?`) |
| DELETE | `/engagement/groups/{id}/cover` | Owner removes the cover (idempotent) |
| GET | `/admin/moderation/group-covers` | Operator queue of pending (or live approved) covers |
| GET | `/admin/moderation/group-covers/{coverID}/content` | Operator view of a stored cover |
| POST | `/admin/moderation/group-covers/{coverID}/decision` | Approve or reject a pending cover |

Non-GET routes document the `Idempotency-Key` header (except the multipart
cover upload, which uses `cover_id` for retries). `joined_only=true` and
`visibility` (public/private) are still accepted from older clients.

## App (Flutter, `app/lib/features/groups/`)

- `groups_screen.dart` — **Groups** in the Today look: "Start a group",
  Invitations (accept/decline), Your groups (unread chat badges from the
  server's `unread_count`), Discover by lifestyle (category chips with counts,
  public groups with Join, an empty state offering "Start one" in that
  category).
- `group_detail_screen.dart` — cover emoji in the chosen colour role, name,
  category, description, member strip, **Group chat** (opens
  `openSocialChat` with the description as header; tapping a sender offers
  `AddFriendButton`), Invite friends (picker), Members sheet (roles,
  `AddFriendButton`, owner/moderator actions), Leave; owner tools: Edit, Delete.
  Non-members see Join / Accept-Decline / "Invitation only".
- `create_group_screen.dart` — the create flow: Community vs Private, lifestyle
  grid, name/description/city, cover emoji and colour, and the preselected
  friends (editable via the picker). Friends-first entry defaults to Private.
- `friend_picker.dart` — friend multi-select from `/engagement/group-friends`
  (members and invitees shown but not selectable).
- `group_launch.dart` — `openCreateGroup(context, invitees:, kind:, category:)`
  (signature kept for the Friends screen; `kind`/`category` are new optional
  params), `openGroups`, `openGroup`.
- The Engage hub tile is now "Groups" (behind `groups_enabled`), and the web
  `/groups` destination opens the new screen. The old
  `community_groups_screen.dart` and `community_groups_provider.dart` are removed
  with their comma-separated-id form.

## Tests

- Go (`server_groups_test.go`, Postgres): friend-only invitees with stranger,
  non-friend match and block rejection; identity spoof rejected and owner taken
  from the principal; Discover by category and search; blocked owner hidden;
  public join, private not joinable or visible; member list privacy; invites
  list, accept/decline, retries, notifications; private-group member cannot
  invite until promoted; community members invite their own friends; picker
  statuses; leave with hand-off to moderator then member, delete when alone;
  promote/demote/remove rules, removed member cannot rejoin; edit and delete
  permissions; chat membership through the engine (non-member cannot read or
  post, owner moderates, leaving revokes); categories listed; missing group →
  404; account erasure hand-off. `server_engagement_resilience_test.go` now
  checks an unauthenticated invite is refused.
- Flutter: `test/features/groups/groups_test.dart` (create with preselected
  friends, category required for community groups, discover by category + join,
  detail opens chat, invite picker) and `groups_accessibility_test.dart` (tap
  targets, labels and contrast with data loaded, light and dark). Groups,
  GroupDetail and CreateGroup screens are in the responsive screen matrix.

- Cover photos: Go `group_covers_test.go` (Postgres, local media store in a
  temp dir): validation (missing, non-image, too small, too large, bad
  `cover_id`), owner-only (moderator 403, non-member 404), EXIF stripped,
  retry by `cover_id`, id reuse 409, 10/day limit; pending visible to the
  owner only, operator queue/content/approve/reject (notification, object
  deleted, `rejected` status cleared by remove), synchronous rejection stores
  nothing; private 404, block either side hides the cover, removed group shows
  and accepts none; replace keeps a cover held as report evidence and the
  worker releases it later, remove and group delete delete the object, live
  covers are in the orphan-sweep references; erasure hand-off clears the
  member's covers; `ETag`/304/`Cache-Control`/`nosniff`; PUT skips the replay
  ledger. Flutter `group_covers_test.dart`: owner sees the change-cover
  action (members don't), Under review badge, emoji fallback on cards, pick →
  preview → upload (multipart, progress), remove after confirm, removed
  group offers no cover changes, cover chosen in the create flow is uploaded,
  muted icon on Your groups (and expired mutes ignored).
  `groups_accessibility_test.dart` now loads the owner's detail with a pending
  cover.

## Not done / follow-ups

- Per-group chat mute (members of large community groups may want it).
- Group cover photos: no control-panel page for the operator queue yet (the
  API is there); WebP/HEIC uploads are refused (no re-encoder); the data
  export does not list covers a member uploaded.
- Discover cards have no overflow menu; reporting a group is from its detail
  screen.
- The legacy in-memory engagement gateway functions for groups
  (`groups.go`, `groups_repository.go`) are no longer reached by any route and
  can be deleted in a cleanup.
