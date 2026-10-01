# Real life dating — phase 2: profile stories and voice introductions

Status: implemented locally for the shared Android/web app. This continues **Good dates. At your pace.** after Today introductions, the Real life theme and explicit plan sharing. Production rollout is still pending.

## Delivery phases

| Phase | Status | Outcome |
| --- | --- | --- |
| 1. Today and dating at your pace | Delivered locally | Finite introductions, genuine shared interests, dating rhythm, Real life palette and private-by-default plan sharing. |
| 2. Profile stories and accessible voice | Delivered locally in this change | Optional authored story cards, approved gallery photos and private conversational voice with readable transcripts. |
| 3. Better date planning | Delivered locally | Exact shared windows, budget, atmosphere, optional accessibility requests and versioned counterproposals. [Phase 3 evidence](BETTER_DATE_PLANNING_DELIVERY_2026-09-29.md). Verified place suggestions remain a separate integration. |
| 4. Friend introductions without a dating profile | Delivered locally | Separate introducer role, limited permissions, explicit participant approval and revocation. [Delivery evidence](INTRODUCER_EXPERIENCE_DELIVERY_2026-09-29.md). |
| 5. Focused city pilot | Infrastructure delivered locally; launch pending | Opt-in cohorts, 7/28-day conversation and date proxies, operator scorecard and gated hosted tests. City, owners, retention policy and real-world evidence remain pending. [Delivery evidence](CITY_PILOT_DELIVERY_2026-09-30.md). |
| Release acceptance across all phases | Pending | Physical devices, real recording/playback and provider delivery, offline/background/process death, reviewed translations, capacity/soak and operational readiness. |

## What changed

### Optional profile stories

Members can open **Your profile stories** from Settings or the story link on Today. Up to three distinct prompts invite specific everyday details. Each story contains 1–400 characters and can include one currently approved photo from the member's own gallery. A selected photo requires a screen-reader description of 1–160 characters.

Stories start private. Preview does not publish; **Show these stories on my profile** plus save is explicit publication. Turning it off and saving hides all stories. Empty collections remain private. Stories are optional and do not affect completion, scores or chat access. Other members see them on profile details only when the current public-profile visibility rules allow access.

This is member-authored content. The feature does not claim to automatically moderate story text or verify that a photo description accurately describes its image. Existing reporting/safety operations remain necessary. Photos must already be approved and are rechecked when read; removed or quarantined photos disappear from stories.

### A voice, a little closer

The existing voice screen now uses a named conversation picker and a direct chat entry point. Members no longer need to enter internal match or receiver IDs. The screen explains the private audience, offers a guided prompt, records 20–45 seconds through the existing recorder and requires a member-written transcript. Transcription is not automatic.

The new conversation inbox shows the latest 20 approved recordings, with readable transcripts and explicit listen/stop controls. No autoplay or microphone access is triggered when opening it. Changing recipients is disabled while a recording exists; members can discard it first. The audio player and in-memory submission state dispose when the screen is closed, and providers react to account changes.

Voice remains private to the matched conversation; this phase does not turn private recordings into public profile audio. Existing voice send limits, moderation and feature policy continue to apply. Blocking, unmatching, unavailable accounts and enforcement are rechecked before playback grants and when serving a signed media request. A previously issued grant cannot bypass a later block. Audio already delivered to a device cannot be recalled.

## Architecture and data contract

- Migration **100_profile_stories.sql** adds `user_management.profile_stories`, explicit publication, a version and ownership registration. It is applied and registered in the local database.
- `GET/PUT /v1/profile/{userID}/stories`: owner-only writes; public reads use current profile eligibility and block enforcement. Other viewers never receive the owner's gallery selection list. Private collection reads return no story content.
- `PUT` requires an expected version; stale writes return a conflict. The editor retains unsaved edits on failure and offers explicit reload. Existing request idempotency middleware applies.
- Each successful change emits `profile_stories.updated` through the transactional event outbox. The event contains version/count/publication metadata, not text, photo URLs or descriptions.
- Account export includes the owner's story collection. Account erasure deletes it through the existing erasure transaction and legal-hold rules.
- `GET /v1/matches/{matchID}/voice-introductions` checks current active membership and account enforcement, reads approved recordings in a consistent snapshot and returns no storage paths or signed grants. Responses use `private, no-store`.
- Existing `intentional_dating_enabled` and `voice_icebreakers_enabled` flags gate the new APIs. OpenAPI is updated. Billing ownership and payment workflows are unchanged by this phase.

## Verification

- 39 targeted Go tests passed against local PostgreSQL; zero skipped or failed. Coverage includes story input bounds, explicit consent, owner/public separation, version conflicts, foreign/quarantined photo rejection, current media visibility, blocked profiles, metadata-only events, erasure, private voice transcripts, outsider rejection, block/unmatch enforcement and revocation of a pre-issued playback grant. Existing profile, voice, plans, chemistry, feature flag and OpenAPI tests also passed.
- 66 Flutter tests passed across stories, voice, intentional dating, date plans, chat and themes. The ten new tests cover private defaults, preview without publication, publish/hide, stale-save draft preservation, photo descriptions, named conversation selection, transcript reading without autoplay and story layouts at 390/768/1440 pixels with 2× text.
- Scoped analysis reports no errors or warnings. Informational style lints remain.
- Build and live browser/emulator evidence is recorded in `qa/results/profile-stories-voice/acceptance.json` with logs alongside it.

This is local implementation and fixture-backed acceptance, not evidence of successful production moderation, physical microphone fidelity, audio duration verification, translation approval or improved real-world dating outcomes. Those remain release and pilot work.
