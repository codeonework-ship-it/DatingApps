# Today wall carousel and Cover of the Week

Delivered 2026-10-01. Migration: `backend/scripts/112_today_wall_and_cover.sql`.

## Ranking rule (used by both)

Order by **likes**, then **approved comments**, then **unique views**, all descending. Items tied on all
three are ordered at random. Only content whose author allowed featuring, that is active and has no open
report, is eligible.

Views are unique per member and recorded when a member opens a chapter or photo
(`POST /v1/walls/views`). Authors viewing their own content are not counted.

## Today's wall (carousel, up to 10)

- Draws from the chapters and photos delivered to the member's wall (the tiered reach rules).
- Chosen once per member per day (UTC) and stays fixed for that day.
- Items never shown on an earlier day come first, so content that did not make today's ten is picked up on a
  following day. If fewer than ten fresh items exist, earlier ones fill the remaining places.
- Within each group the ranking rule above applies, with random tie-breaks.

## Cover of the Week

- One photo for everyone, chosen once per week (weeks start Monday, UTC) on the first request of the week, and
  fixed for that week.
- Candidates: photos with featuring allowed, active, no open report, posted in the last 30 days, at least one
  like, and never a cover before (so ties and runners-up get their turn in later weeks).
- The author gets a rose-rain celebration of kind `cover` ("Your photo is Cover of the Week").
- A member who has a block with the author, or who is below the community bar, sees no cover.

## API

Chapter (`post`) and photo (`entry`) JSON gain `"view_count": int`.

| Method and path | Body | Response |
|---|---|---|
| `GET /v1/walls/today` | none | `{"day": "YYYY-MM-DD", "items": [Item]}`, up to 10, in display order |
| `GET /v1/themes/cover` | none | `{"cover": {"week_start": "YYYY-MM-DD", "entry": Entry}}` or `{"cover": null}` |
| `POST /v1/walls/views` | `{"kind": "chapter\|photo", "id": "uuid"}` | `{"recorded": true\|false}` (false when already counted, own content or not visible) |

Item:

```json
{"kind": "chapter", "position": 1, "post": Post}
{"kind": "photo", "position": 2, "entry": Entry}
```

Celebrations (`GET /v1/walls/celebrations`) can now have `"kind": "cover"` with `content_id` = the photo,
`theme_id` set and `reach` = 0. Headline: "Your photo is Cover of the Week".
