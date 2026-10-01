# Friend introductions without a dating profile

Implemented locally for the shared Flutter Android/web app and PostgreSQL-backed Go services. Production deployment and physical-device acceptance are still pending.

## Experience

- The welcome screen offers **Just here to introduce friends**. Signup requires an adult age check, name and credentials, followed by terms acceptance. It collects no gender, dating preferences or photos and creates no dating-profile draft. Login and refresh retain the server-issued `introducer` account kind. Web accounts land at `/app/#/introducer`.
- Introducers get a dedicated **Connect · Friends** workspace, their permission circle, an optional introduction note, private sent receipts, sign-out and account export/deletion controls. There is no discovery, member-profile, chat, feed, wallet or dating navigation.
- Members open **Explore → Friends & Introductions → Invite a friend who isn’t dating**. They choose photo/city preview sharing (both off initially), create a private code, and share it themselves. Codes work once, expire after 48 hours, and replacing or cancelling an unused code invalidates it.
- Redemption requests permission. The member sees the introducer's name and the preview choices before explicitly approving. Approval enables friend introductions and that named person's scoped permission. A request can be declined without becoming a general friendship.
- A friend needs two active permissions to propose an introduction. Publication, compatibility, discovery pauses, blocks and current consent are checked again by the server. Both recipients must accept before a match is created. The friend receives only a constant **Sent** receipt, with no decision or match ID.
- Either party can remove permission. This closes unanswered introductions and removes access to their previews. An existing mutual match remains independent. Members can also pause all friend introductions in Dating rhythm.

## Boundaries and recovery

Migration `102_introducer_accounts.sql` adds the account kind, hashed invitation tokens and scoped consent records. The introducer account has a database constraint preventing profile completion/publication. Middleware resolves account kind from the live session and applies an explicit route allowlist; client flags cannot grant dating access. Terms are required before using the friend workspace's APIs.

Consent is separate from accepted friendship, so it grants no trusted-contact date-plan feed or friend-activity access. Creation, redemption, approval and revocation are transactional. Introduction creation/acceptance and consent withdrawal lock the introducer account; concurrent conflicts roll back rather than approving against withdrawn permission. Same-actor redemption and revocation are repeat-safe. Minted invitation codes bypass HTTP response caches; the invitation table and export never contain plaintext codes. Authenticated commands otherwise use the existing durable idempotency middleware and operation recovery.

Limits: 10 invitation codes per member/day, 20 current permissions per introducer, five introductions per introducer/day, and a 200-character optional note. A pending consent request creates a notification for the member; introductions never notify the introducer of dating outcomes. Revocation and permission reads remain available when the introduction rollout flag is disabled.

Both new aggregates use the existing transactional event backbone, field-names-only event payloads and registered aggregate ownership. Exports include permission metadata and account kind, excluding invitation secrets. Account erasure removes invitation/consent rows and associated introduction content. Live QA also uncovered and fixed an existing export query against a nonexistent terms-acceptance table; exports now read the authoritative terms fields on the user record.

## Verification

- 36 Go tests passed across auth, introduction lifecycle, consent, access restrictions, session refresh, account export/erasure boundaries and OpenAPI contracts (native PostgreSQL integration enabled).
- 33 Flutter tests passed across introducer/member consent, optional-note submission, revocation, restricted signup, session restoration, auth, existing friend introductions and offline handling. Layout checks included 360px and 1280px with 1.7× text.
- Static analysis reported no errors or warnings in the checked surfaces; informational style lints remain.
- Live gateway checks passed for signup, terms gating, login/refresh account kind, forbidden discovery/profile/match/feed routes and complete account export without a dating draft. See `qa/results/introducer-experience/http-acceptance.json`.
- Release web build and debug Android build succeeded. Browser inspection verified the member consent screen and separate introducer workspace; the Android APK was installed and launched on the local emulator.

## Remaining release acceptance

Real-device assistive-technology and process-death testing, production notification delivery, localized copy, launch-cohort/fraud-limit tuning, and production deployment remain release work. No production rollout or real-member introduction was performed for QA. Billing remains separately owned and unchanged by this feature.
