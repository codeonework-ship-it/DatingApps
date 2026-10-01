# First Chapter — working first release

Implemented across the Flutter web/Android app and Go BFF on 30 September 2026.
This is a local release, not a production launch or a claim of proven growth.

## Member experience

| Feature | Delivered behavior |
|---|---|
| First Chapter Studio | Three curated scenes. One matched member chooses a beginning; the other adds a surprise asynchronously. A shared story card opens an editable date proposal with the story and activity category prefilled. Chat does not depend on completing a chapter. |
| Pass the Chapter | Explicit preview before creating a revocable public link. The browser page works without login or installation, lets visitors remix the scene, and offers the browser share menu or copy link. No automatic social posting or contact import. |
| Private green light | Independently select chat, call, or date. The response contains only the viewer's own choices and their intersection with the partner's choices. Choices expire after seven days; clearing and saving withdraws them. No notifications for individual readiness choices. |
| In my words | Up to four optional cards: communication pace, dating comfort, languages and family involvement. Private by default, with explicit sharing to active mutual matches. Original wording remains visible alongside any clearly labelled member-provided translation. RTL display supports Arabic, Hebrew, Urdu and Persian language identifiers. |
| Stories that give back | After a mutually confirmed connection celebration, either member can propose an anonymous completed chapter. Both approve the same immutable card before its public link works. Either can revoke it. Closing the chapter also revokes its joint links. |

Entry points: Today → First Chapter Studio; Your matches → First Chapter; the
conversation's chapter card; web All features → First Chapter Studio. The web
workspace also supports `/app/#/first-chapter`.

The public playground is `/chapter.html`. Member-created links use an opaque
publication identifier. Guest remix URLs contain only catalogue scene/choice
indices. Public payloads never serialize private database rows: they contain the
curated scene, beginning, optional jointly approved surprise and an anonymous
story indicator. Revocation stops subsequent access to the original link; it
cannot erase copies of already-public ideas.

## Architecture and privacy

- Migration `104_first_chapter.sql` adds chapters, green lights, comfort cards
  and publications with user/match foreign keys and deletion cascades.
- All four aggregates register transactional outbox events and ownership.
  Events contain operation/changed field names, not story text, comfort wording
  or readiness values. The existing command center can observe these operations.
- Match locks serialize creation and contribution writes; UUID creation commands
  handle retries; versions protect edits and approvals. Author locks serialize
  active share-link limits across connections.
- Server authorization rechecks active membership, blocking, unmatching and
  account status. Public links fail closed on revocation or author deactivation;
  joint links also require the pair to remain accessible and the chapter open.
- At most one open chapter per pair, three new chapters per pair in 24 hours,
  and 20 active published/pending links per author. Retries do not duplicate
  invitations or completion notifications.
- Readiness uses a consistent snapshot and exposes no partner-only choice,
  submission time, response counter, or public score. Public responses use
  `Cache-Control: no-store`.
- Publication listing and authenticated DELETE revocation remain available when
  `intentional_dating_enabled` is paused. New creation and approval are gated.
- Studio reconciliation polls only while its screen exists, with a 20-second
  interval. The existing conversation reconciliation also reports whose turn
  it is or that the chapter is ready. Durable server state remains authoritative.

## API surface

| Route | Access / action |
|---|---|
| GET `/chapters/catalogue` | Public curated content; runtime gated |
| GET `/chapters/public/{shareID}` | Public anonymous card only after required approvals |
| GET/POST `/chapters/publications` | Authenticated own/joint publication list, creation, approval or revocation |
| DELETE `/chapters/publications/{shareID}` | Authenticated author withdrawal, also available during a feature pause |
| GET/PUT `/chapters/comfort` | Authenticated viewer's own cards |
| GET/POST `/matches/{matchID}/chapter` | Active pair read, start, surprise or close |
| PUT `/matches/{matchID}/chapter/green-light` | Private versioned choice replacement |

All API paths use the existing `/v1` prefix. Dating and payment entitlements are
not changed; these interactions introduce no paid gate or rewards.

## Validation and release limits

Evidence is in `qa/results/first-chapter/`: real PostgreSQL authorization,
concurrency, replay, privacy, expiry, publication-consent and revocation tests;
Flutter interaction/layout tests; and existing discovery, Today, chat and date
planning regressions. Browser acceptance checks the live Studio and anonymous
remix. Build logs cover the web release, Android debug APK and BFF.

Production work remains: configure `CONNECT_PUBLIC_WEB_URL` at Flutter build time
for externally usable mobile share links; deploy the website and API under a
trusted public origin; apply migration 104 before deploying the BFF; and verify
physical-device sharing through the apps chosen by the user. Local links only
work where the local server is reachable.

Curated scenes are English in this release. Member-authored comfort cards support
other languages; there is no automatic translation service or claim of reviewed
multilingual scene localization. Human-reviewed local scenes, culturally specific
product research, physical-device accessibility acceptance and production growth
experiments remain launch work. Public story content is restricted to curated
choices; free-form public stories, voice/drawing contributions and public creator
attribution are not enabled in this version.
