# Photo Themes and Book & Film Clubs

Delivered 2026-10-01. Two member activities that give people something to talk about besides themselves.

| Activity | What members do | Built on |
|---|---|---|
| Photo Themes | Share one photo per prompt, such as "My perfect Sunday", and browse everyone else's | Blog photo sanitising and media moderation; blog report, case and appeal queue |
| Book & Film Clubs | Join or start a club, follow a weekly pick, discuss it, review titles and keep personal lists | New club tables; same report, case and appeal queue |

Migration: `backend/scripts/107_photo_themes_and_book_film_clubs.sql`.
Feature flags (default on): `photo_themes_enabled` gates `/v1/themes/*`, `clubs_enabled` gates `/v1/clubs/*`.

## Rules shared by both features

- **Who can take part.** Reading and writing needs an active adult dating account. Sharing a theme photo,
  creating or joining a club, and publishing a review or list beyond "Only me" also need a complete profile
  with two approved profile photos. This is the same bar as posting a blog chapter to the community.
- **Blocks.** A block in either direction hides each member's theme photos, club posts, reviews and lists
  from the other.
- **Reports.** Every item is reportable through the existing endpoint
  `POST /v1/blog/reports/{kind}/{id}` with body `{"reason": "harassment|inappropriate|fraud|fake", "description": "..."}`.
  New kinds: `theme_entry`, `club`, `club_post`, `review`, `list`. Reports land in the existing Open Chapters
  operator queue, keep an immutable snapshot (theme photos are copied as evidence), and the member can appeal
  from their review notices. Reports keep working when either feature flag is off.
- **Privacy lifecycle.** Account export includes all of a member's entries, club activity, reviews and lists.
  Account erasure removes them, hands club ownership to the longest-standing member, and releases stored photos.
- **Errors.** JSON errors use the existing `{"error": "..."}` shape. `409` means "reload and retry" and
  `403` means the account is not eligible or lacks a club role.

## Photo Themes API

A theme:

```json
{"id": "uuid", "slug": "perfect-sunday", "title": "My perfect Sunday",
 "prompt": "Show us what an unhurried Sunday looks like for you.",
 "entry_count": 12, "my_entry_id": "uuid or empty string"}
```

An entry:

```json
{"id": "uuid", "theme_id": "uuid", "author_id": "uuid", "author_name": "Priya",
 "caption": "Pancakes, then nowhere to be.", "alt_text": "A stack of pancakes on a balcony table",
 "created_at": "RFC3339", "mine": true}
```

| Method and path | Body | Response |
|---|---|---|
| `GET /v1/themes` | none | `{"themes": [Theme], "eligible": bool, "eligibility_message": "..."}` |
| `GET /v1/themes/{themeID}/entries?before={entryID}` | none | `{"theme": Theme, "entries": [Entry], "next_cursor": "entryID or empty"}`, 20 per page, newest first |
| `PUT /v1/themes/{themeID}/entries/{entryID}` | multipart: `image` (JPEG or PNG, 10 MB max), `caption` (1–280), `alt_text` (1–160) | `{"entry": Entry}` |
| `DELETE /v1/themes/{themeID}/entries/{entryID}` | none | `{"deleted": true}` |
| `GET /v1/themes/{themeID}/entries/{entryID}/photo` | none | image bytes, private, no-store |

Upload rules: the client generates the entry UUID. A member has at most one live entry per theme; a second
upload returns `409` until the first is removed. Retrying the same UUID with the same image and caption returns
the saved entry. Photos are decoded and re-encoded (EXIF and location stripped) and must pass media moderation;
a rejected photo returns `422` and nothing is stored.

Operators manage prompts with `GET /v1/admin/engagement/photo-themes` and
`POST /v1/admin/engagement/photo-themes` (`{"slug","title","prompt","status":"active|archived","sort_order"}`,
upsert by slug). Six prompts are seeded.

## Book & Film Clubs API

```json
Title     {"id","kind":"book|film","title","creator","release_year": 2019 or null,
           "average_rating": 4.2 or null,"review_count": 3}
Selection {"id","week_start":"YYYY-MM-DD (a Monday)","note","title": Title,"post_count": 7}
Club      {"id","kind":"book|film","name","description","owner_id","member_count",
           "my_role":"owner|moderator|member|","version","moderation_state":"active|removed",
           "current_selection": Selection or null}
Member    {"user_id","name","role","joined_at"}
ClubPost  {"id","club_id","selection_id","author_id","author_name","body","has_spoilers",
           "created_at","mine","hidden"}
Review    {"id","title_id","author_id","author_name","rating":1-5,"body","has_spoilers",
           "audience":"private|friends|community","version","created_at","updated_at","mine"}
List      {"id","owner_id","owner_name","name","kind":"book|film","audience","version","mine",
           "items":[{"title": Title,"note","position"}]}
```

| Method and path | Body | Response |
|---|---|---|
| `GET /v1/clubs?scope=mine\|discover&kind=book\|film` | none | `{"clubs": [Club], "eligible": bool}` |
| `PUT /v1/clubs/{clubID}` | `{"kind","name" (3–60),"description" (≤500),"expected_version"}`; version `0` creates | `{"club": Club}` |
| `GET /v1/clubs/{clubID}` | none | `{"club": Club, "selections": [Selection]}`, latest 8 picks |
| `POST /v1/clubs/{clubID}/membership` | `{"action":"join\|leave"}` | `{"club": Club}` |
| `GET /v1/clubs/{clubID}/members` | none | `{"members": [Member]}`, members only |
| `POST /v1/clubs/{clubID}/members/{userID}` | `{"action":"make_moderator\|make_member\|remove"}` | `{"members": [Member]}` |
| `PUT /v1/clubs/{clubID}/selections/{weekStart}` | `{"title_id","note" (≤280)}` | `{"selection": Selection}` |
| `GET /v1/clubs/{clubID}/posts?selection_id=&before=` | none | `{"posts": [ClubPost], "next_cursor"}`, 30 per page, oldest first |
| `PUT /v1/clubs/{clubID}/posts/{postID}` | `{"selection_id","body" (1–2000),"has_spoilers"}` | `{"post": ClubPost}` |
| `DELETE /v1/clubs/{clubID}/posts/{postID}` | none | `{"deleted": true}` |
| `POST /v1/clubs/{clubID}/posts/{postID}/visibility` | `{"hidden": bool}` | `{"post": ClubPost}` |
| `GET /v1/clubs/titles?kind=&q=` | none | `{"titles": [Title]}`, `q` needs 2+ characters, 20 results |
| `PUT /v1/clubs/titles/{titleID}` | `{"kind","title" (1–200),"creator" (≤120),"release_year"}` | `{"title": Title}`, may return an existing title with a different ID |
| `GET /v1/clubs/titles/{titleID}` | none | `{"title": Title, "my_review": Review or null, "reviews": [Review]}` |
| `PUT /v1/clubs/titles/{titleID}/reviews/{reviewID}` | `{"rating","body" (≤4000),"has_spoilers","audience","expected_version"}` | `{"review": Review}` |
| `DELETE /v1/clubs/reviews/{reviewID}` | `{"expected_version"}` | `{"deleted": true}` |
| `GET /v1/clubs/lists?owner_id=` | none | `{"lists": [List]}`, own lists when `owner_id` is empty |
| `PUT /v1/clubs/lists/{listID}` | `{"name" (1–60),"kind","audience","expected_version"}` | `{"list": List}` |
| `DELETE /v1/clubs/lists/{listID}` | `{"expected_version"}` | `{"deleted": true}` |
| `PUT /v1/clubs/lists/{listID}/items/{titleID}` | `{"note" (≤280)}` | `{"list": List}` |
| `DELETE /v1/clubs/lists/{listID}/items/{titleID}` | none | `{"list": List}` |

Club rules:

- Anyone eligible can see and join an active club. Only members can read the members list and discussion.
- The owner can promote members to moderator and demote them. The owner and moderators set the weekly pick,
  hide or unhide discussion posts and remove members. A removed member cannot rejoin. The owner cannot leave
  while other members remain.
- A weekly pick is keyed by its Monday and can be set up to four weeks back or ahead. Posts belong to a pick.
- Hidden posts stay visible to their author and to club moderators, marked `"hidden": true`.
- Limits: 5 owned clubs, 20 joined clubs, 60 posts per member per club per day, one review per title,
  20 lists per member and 100 titles per list.
- Titles are a shared catalogue. Adding a title that already exists (same kind, title, creator and year,
  ignoring case and spacing) returns the existing one.

## Where it lives

- Backend: `backend/internal/bff/mobile/photo_themes.go`, `clubs.go`, report and decision hooks in
  `blog_trust.go`, erasure in `account_erasure.go`, export in `account_lifecycle_repository.go`.
  Tests: `photo_themes_clubs_test.go` (run with `PROFILE_TEST_DATABASE_URL`).
- App: `app/lib/features/photo_themes/`, `app/lib/features/clubs/`, shared visuals in
  `app/lib/features/common/widgets/activity_visuals.dart`. Entry tiles sit on the Engage tab after Blog.
- Operators: Control panel → Photo Themes (`/engagement/photo-themes/`) manages prompts. Reports arrive in
  Blog Moderation with content types `theme_entry`, `club`, `club_post`, `review` and `list`.

## Product notes

- Audience is adults only. The app and the server keep the existing 18+ gate; the visual direction aims at the
  youngest adult members and every age above, with 48dp targets, 14sp+ body text and layouts that hold at 1.3x text.
- The app offers this week or next week when setting a pick; the API accepts four weeks either way.
- Lists of other members are readable through the API but not yet browsable in the app, so the app does not
  offer list reports yet.

## Photos on the wall (migration 110)

Photo Theme photos follow the same wall rules as chapters (see `BLOG_LIKES_COMMENTS_FEATURED_2026-10-01.md`):
likes, comments the author approves, and tiered reach to other members' **Today** walls
(by default 50 likes + 5 approved comments reach 50 walls, 100 + 10 reach 100; `BLOG_WALL_TIERS` is shared).
Reach is opt-in per photo and an open report on the photo pauses it everywhere.

Entry JSON gains `theme_title`, `like_count`, `liked_by_me`, `comment_count`, `pending_comment_count`,
`allow_featuring`, `featured`, `wall_reach` and (author only) `next_tier`, shaped exactly like chapters.
Comments carry `entry_id` instead of `post_id`.

| Method and path | Body | Response |
|---|---|---|
| `PUT /v1/themes/{themeID}/entries/{entryID}` | existing multipart plus optional `allow_featuring` = `true` | `{"entry": Entry}` |
| `POST /v1/themes/{themeID}/entries/{entryID}/featuring` | `{"allow": bool}` (author) | `{"entry": Entry}` |
| `PUT` / `DELETE /v1/themes/{themeID}/entries/{entryID}/like` | none | `{"entry": Entry}` |
| `GET /v1/themes/{themeID}/entries/{entryID}/comments` | none | `{"comments": [Comment]}` |
| `PUT /v1/themes/{themeID}/entries/{entryID}/comments/{commentID}` | `{"body"}` | `{"comment": Comment}` |
| `POST /v1/themes/{themeID}/entries/{entryID}/comments/{commentID}/decision` | `{"decision": "approve\|decline"}` | `{"comment": Comment}` |
| `DELETE /v1/themes/{themeID}/entries/{entryID}/comments/{commentID}` | none | `{"deleted": true}` |
| `GET /v1/themes/wall` | none | `{"entries": [Entry]}`: photos on my wall, newest delivery first, up to 20 |
| `POST /v1/blog/reports/photo_comment/{commentID}` | `{"reason","description"}` | existing report response |
