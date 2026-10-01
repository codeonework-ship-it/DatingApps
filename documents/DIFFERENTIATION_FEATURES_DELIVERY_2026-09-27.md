# Differentiation features delivery

Status: **implemented and verified locally on 2026-09-27**

Scope: date plans with friend and friend-group fan-out, check-ins and private debriefs, the Shows Up badge, graduation with discovery pauses, the curated Today set with fair exposure and reasons, friend vouches and intros, the writing copilot with assisted-message marks and conversation trust, the theme preset rename plus the Calm preset, localisation of the app and website in ten locales, and the member locale setting. The FRD rows are PROF-017, DISC-007, DISC-008, CHAT-006, ENG-009, ENG-010, ENG-011, SAFE-009 and NOTIF-007 in the [consolidated FRD](CONSOLIDATED_FRD.md); the accompanying [pricing and go-to-market strategy](PRICING_AND_GO_TO_MARKET_STRATEGY_2026-09-27.md) is a proposal for founder decision, not shipped behaviour. Open items are PEN-54–58 in the [pending feature backlog](PENDING_FEATURE_BACKLOG.md).

## Product contract

### Date plans (ENG-009)

- A matched pair with an unlocked conversation can hold one open date plan per match. A locked conversation returns 423 `CHAT_LOCKED_REQUIREMENT_PENDING`.
- A plan is a window of at most 12 hours that starts within the next 90 days, a venue category, an optional venue name and area of at most 120 characters each, an optional note of at most 280 characters, and up to ten friend groups per side.
- The invitee accepts or declines. Either member cancels. A proposal nobody answered expires when its window closes.
- **Every plan status a member sets is published to that member's accepted friends list and to the friend groups they chose.** The proposer's circle hears `proposed`; both circles hear `accepted`, a cancellation after acceptance, and `completed`; a member's own circle hears that member's check-in. The other member of the match always receives decisions. Blocked pairs, inactive or banned accounts and the date themselves are never recipients.
- Friends read plan updates on the friends' plans list (`GET /v1/friends/{userID}/plans`); the member's own plans are at `GET /v1/plans/{userID}`.

### Check-in and debrief (SAFE-009)

- After an accepted plan's window closes each member checks in `safe` or `need_help` with an optional note of at most 200 characters.
- A reminder reaches the member one hour after the window. A missed check-in escalates to that member's friends and chosen groups three hours after the window.
- `need_help` and `checkin_missed` are delivered in the `safety` category at priority 9 and 8, so muting friend plans cannot mute them.
- The debrief (`happened`, `would_meet_again`, `felt_safe`, note of at most 280 characters) is private to its author. Both `happened` resolves the plan `completed`; both not, `did_not_happen`; a split, `disputed`. `felt_safe=false` writes an operator-visible security event against the partner without auto-reporting. A debrief reminder follows 24 hours after the window.
- A check-in or a friend notification is not an emergency-services response; the product says so.

### Shows Up badge (DISC-007)

- `shows_up` is awarded at two or more mutually confirmed dates and zero disputed dates in the rolling 180 days, held back while any date in the window is disputed, and removed with the other badges on unsafe behaviour.
- Confirmation comes only from both members' private debriefs. A badge is a signal, not a guarantee of personal safety.

### Graduation (ENG-010)

- Either member of an active, unlocked match proposes graduation with an optional note of at most 200 characters and an optional share-with-friends choice. Only the other member confirms or declines; only the proposer withdraws; one proposal is open per match; a decision is final.
- Confirmation marks the match `graduated` without unmatching, so the chat stays. Both members are paused in discovery: they leave every deck, and a paused viewer sees an explanation instead of an empty deck.
- Each member who opted in has their accepted friends told that they found someone on Connect, without naming the partner.
- A reward row is recorded per member as `pending`; nothing is charged, paused or credited yet (PEN-54).
- Members can also pause and resume discovery manually (`GET/POST /v1/account/{userID}/discovery/pause`, `POST .../discovery/resume`).

### Curated Today set (DISC-008)

- Up to five candidates per member per UTC day (`GET /v1/discovery/{userID}/today`), drawn only from the member's ordinary eligible deck after every block, publication, preference, trust and pause filter. The set is stored, so it is the same on every reload that day.
- Rank: 24-hour reply rate 0.35, active trust badges 0.25, activity recency 0.20, shared intent and language tags 0.20 (`curated_daily_set.v1`). A candidate with more than 30 likes today is down-weighted by 0.6; one served fewer than three times today gains 0.08.
- Fair exposure reorders and never removes. Paid spotlight is not consulted.
- Each candidate carries up to three catalogue reasons and a one-line `why`; the same reasons are attached to the main deck.

### Friend vouches and intros (ENG-011)

- A vouch is 12–200 characters written by an accepted friend. The subject approves or hides it; the voucher may withdraw. At most three approved vouches appear on the public profile with the voucher's first name (`GET /v1/users/{userID}/vouches`), hidden across blocks and while the voucher is inactive or banned.
- An intro joins two of the introducer's accepted friends who are published to each other, not blocked, not already matched and preference-compatible. Each invitee accepts or declines privately. Both accepting creates the ordinary match and tells the introducer; a decline ends the intro without saying who declined. One intro is open per pair; open intros expire after 14 days.

### Writing copilot and conversation trust (CHAT-006)

- `POST /v1/matches/{matchID}/copilot/draft` drafts an opener, a reply or a date idea in a warm, playful or direct tone from the partner's allowlisted public projection and the last six messages. It never sends. Every draft carries the disclosure "Say it in your own words. If you send it as drafted, they will see it was written with help."
- Ten drafts per member per UTC day; the eleventh returns 429 `COPILOT_DAILY_LIMIT_REACHED`.
- A message sent with `assist_draft_id` is marked `composed_with_assist` and both members see "Drafted with help".
- `GET /v1/matches/{matchID}/trust` shows both members' verification state, `human_verified`, and the partner's active badges.

### Friend-plan notifications (NOTIF-007)

- Friends' plan, graduation, vouch and intro updates arrive in the `friend_plan` category, muted by the preference `notify_friend_plans` (default on) independently of `safety`.
- A retry never notifies twice. Until production push is enabled with device evidence these notifications reach the in-app inbox only (PEN-55).

### Language (PROF-017)

- Settings offer en-US, en-GB, Deutsch, Français, Русский, Español, Italiano, Português, Nederlands and Polski, or following the device. The choice is stored on the account and follows the member to a second device like the theme.
- The website is published in the same ten locales, the default at the site root and the others under `/en-gb/`, `/de/`, `/fr/`, `/ru/`, `/es/`, `/it/`, `/pt/`, `/nl/` and `/pl/`.
- Translations have not had native-speaker review (PEN-57).

### Theme presets

- The cinematic looks ship as Forge, Neon Grid, Crimson Alloy, Circuit and Deep Field (formerly transformers, tron, ironman, digitronics and starwars); Love is unchanged. A member who saved an old id keeps their look, and the next save stores the new id.
- Calm is new: a light, still, single-accent preset with a flat backdrop, no atmosphere, no motion and no title card, for members who want low stimulation and high contrast.
- Daylight (light) and Afterdark Ember (dark) remain the classic pair that follows the device switch. The website look is unchanged.

## Architecture and safety

Migrations `091_date_plans_friend_fan_out.sql` to `097_conversation_trust_and_copilot.sql` add the tables, constraints, triggers and functions; each is safe to run repeatedly.

- **Date plans (091).** `matching.match_date_plans`, `match_date_plan_participants` and append-only `match_date_plan_events` (trigger `trg_date_plan_events_append_only`). `trg_validate_match_date_plan` enforces the window, start and group bounds and derives `checkin_due_at` as one hour after the window. `matching.date_plan_share_recipients` resolves accepted friends plus active members of the chosen groups and drops blocked pairs, inactive or banned accounts and the partner. `matching.notify_date_plan_status` runs inside the status-changing transaction: it writes a `friend_activity_feed` row per recipient, enqueues a notification with dedupe key `date-plan:<plan>:<status>:<member>:<recipient>` in the `friend_plan` category (`safety` for `need_help` and `checkin_missed`), and publishes the `date_plan.<status>` domain event. `matching.date_plan_checkin_sweep` expires unanswered proposals, sends the one-hour check-in reminder and escalates missed check-ins two hours after `checkin_due_at`. The notification category constraint gains `friend_plan`; `user_settings.notify_friend_plans` defaults to true. Flag `date_plans_enabled`. Event sources `match_date_plans` (`date_plan`), `match_date_plan_participants` (`date_plan.participant`) and `match_date_plan_events` (`date_plan.event`).
- **Debriefs and Shows Up (092).** `matching.match_date_plan_debriefs` with `trg_validate_match_date_plan_debrief`; `matching.resolve_date_plan_from_debriefs` resolves the plan once both debriefs exist and fans `completed` out to both circles; view `matching.member_date_plan_signals` counts confirmed, disputed and no-show plans over 180 days; `matching.date_plan_debrief_sweep` sends the 24-hour reminder. The BFF's `showsUpRule` in `trust_badges.go` reads the view; `felt_safe=false` writes `audit.security_events` `date_plan.felt_unsafe`. Event source `match_date_plan_debriefs` (`date_plan.debrief`).
- **Member locale (093).** `user_settings.locale` with `user_settings_locale_check` (`^[a-z]{2}(-[A-Z]{2})?$`); the BFF mirrors the pattern (`settingsLocalePattern`) and stores an empty string as NULL.
- **Graduation (094).** `matching.match_graduations` with `trg_validate_match_graduation`, `matching.graduation_rewards` (`subscription_pause`, `referral_credit`; `pending`, `applied`, `skipped`) and `user_management.discovery_pauses` (`graduated`, `manual`). `matching.notify_graduation` runs in the confirming transaction with the same dedupe discipline. The BFF removes paused members from every deck (`filterPausedDiscovery`). Flag `graduation_enabled`. Event sources `match_graduations` (`graduation`), `graduation_rewards` (`graduation.reward`), `discovery_pauses` (`discovery.pause`); aggregate `graduation` registered and required.
- **Curated Today set (095).** `matching.daily_candidate_sets` (at most five ids, reasons, `model_version`) and `matching.member_exposure_counters`; view `matching.member_reply_signals`. Ranking, fair exposure and reasons live in `curated_daily_set.go` with the weights above as named constants. Flag `curated_daily_set_enabled`. Event sources `daily_candidate_sets` (`discovery.daily_set`) and `member_exposure_counters` (`discovery.exposure`).
- **Vouches and intros (096).** `matching.friend_vouches` and `matching.friend_intros` with validation triggers; `matching.accepted_friends`, `matching.intro_pair_compatible`, `matching.friend_intro_match` (creates the match through the ordinary matches table, so the usual match notifications fire) and `matching.friend_intro_sweep` (14-day expiry, tells the introducer). Flag `friend_intros_enabled`. Event sources `friend_vouches` (`friend_vouch`) and `friend_intros` (`friend_intro`); aggregates `friend_vouch` and `friend_intro` registered and required.
- **Copilot and trust (097).** `matching.copilot_drafts` (kind, tone, draft, provider, model, `context_digest`) and `matching.message_assist_marks` with `trg_validate_message_assist_mark`. The digest is a truncated SHA-256 of partner, kind and turn count; the other member's message bodies are never stored with the draft. Flag `copilot_enabled`. Event sources `copilot_drafts` (`copilot.draft`) and `message_assist_marks` (`message.assist_mark`).

**Workers.** `datePlanSweepWorker` (`server_date_plans.go`) runs every five minutes and calls `date_plan_checkin_sweep`, `date_plan_debrief_sweep` and `friend_intro_sweep`; each function is idempotent per row and uses `FOR UPDATE SKIP LOCKED`, so a second instance cannot double-send.

**Notification category.** `friend_plan` is routed through the existing outbox and preference resolution (`notification_repository.go` maps the category to `notify_friend_plans`, default on). Production push is excluded by the release contract (`production_push_notifications`), so every notification in this delivery reaches the in-app inbox only.

**Copilot provider switch.** `newCopilotProviderFromEnv` (`copilot.go`) selects the Anthropic Claude adapter only when `COPILOT_PROVIDER=claude` and `ANTHROPIC_API_KEY` is set; `COPILOT_MODEL` defaults to `claude-opus-5`. The adapter calls the Beta Messages API with the `server-side-fallback-2026-07-01` beta and default fallbacks, so a policy refusal is re-served by a fallback model in the same call; a remaining `refusal` stop reason, a provider error or an empty draft returns "the copilot is unavailable right now" and no draft is stored. Any other configuration uses the deterministic offline template provider, which is what runs locally and in the tests. The Claude adapter is inactive until configured; key management, a spend cap, prompt review and data-processing terms are listed in the [third-party integrations tracker](THIRD_PARTY_INTEGRATIONS.md).

**Release scope.** All five flags default on and none is in `config.FirstReleaseExcludedFlags` or the release contract's excluded capabilities; `release_contract.v1.json` is unchanged.

**Localisation.** `app/lib/l10n/` holds the ARB source `app_en.arb` and nine translations (`app_en_GB`, `app_de`, `app_fr`, `app_ru`, `app_es`, `app_it`, `app_pt`, `app_nl`, `app_pl`); `app/lib/core/i18n/app_locale_provider.dart` owns the language list, the wire tag and the account/device fallback. `website/generate_pages.py` reads `website/locales/` and refuses to build a locale whose keys or feature list drift from `en`.

**Theme presets.** `app/lib/core/theme/theme_presets.dart` defines the presets; `AppThemeSelection.fromWire` resolves legacy ids to the renamed looks, so a stored `dark:tron` still opens Neon Grid.

## Acceptance evidence

Go (`backend/internal/bff/mobile/`, Postgres-backed tests run against the local database):

- `date_plans_test.go`: `TestParseDatePlanProposalValidation`, `TestDatePlanNextAction`, `TestDatePlanLifecycleFansOutToFriendsAndGroupsPostgres`, `TestDatePlanSweepRemindsAndEscalatesPostgres`, `TestDatePlanDebriefResolvesAndAwardsShowsUpPostgres`.
- `graduation_test.go`: `TestGraduationValidation`, `TestGraduationNextAction`, `TestGraduationRoutesMapToFlag`, `TestFilterPausedDiscoveryWithoutPersistenceIsANoOp`, `TestGraduationConfirmHidesBothAndTellsOptedInFriendsPostgres`, `TestGraduationDeclineAndWithdrawPostgres`.
- `curated_daily_set_test.go`: `TestCuratedScoreWeightsSumToOneForAPerfectCandidate`, `TestCuratedNewcomerGetsPopulationMedianNotZero`, `TestCuratedRecencyDecays`, `TestCuratedSharedTagsAreCaseInsensitive`, `TestCuratedFairExposureDownWeightsOverCapAndBoostsUnseen`, `TestCuratedRankLetsTheMiddleGetSeen`, `TestCuratedRankIsDeterministicAndBounded`, `TestCuratedReasonsFollowThePriorityOrderAndCap`, `TestAttachDiscoveryReasonsGivesEveryCandidateAList`, `TestCuratedDailySetRouteIsFlagGated`, `TestCuratedDailySetIsStableWithinADayAndCountsImpressions`.
- `friend_social_test.go`: `TestFriendSocialValidation`, `TestFriendVouchLifecyclePostgres`, `TestFriendIntroLifecyclePostgres`.
- `copilot_test.go`: `TestTemplateCopilotDraftsFromProfileFacts`, `TestCopilotDraftsMarksAndTrustPostgres`.

Flutter (`app/test/`):

- `features/plans/date_plan_card_test.dart`: invitee accepts, check-in after the window, propose call to action shown only when allowed and hidden while the chat is locked, debrief after check-in, model parsing.
- `features/graduation/graduation_banner_test.dart`: banner hidden until proposed, propose with note and share, partner confirms through the celebration screen, partner declines, proposer waits and withdraws, model parsing.
- `features/friends/friend_social_test.dart`: incoming intro accepted, pending vouch approved, intro sheet needs two different friends, model parsing.
- `features/messaging/widgets/copilot_sheet_test.dart`: draft in the chosen kind and tone handed back, assisted message shows the honest caption, model parsing.
- `features/swipe/screens/today_rail_test.dart`: Today rail with reason chips, hidden when the flag is off, hidden with no picks.
- `features/theme/theme_presets_test.dart` and `features/theme/calm_preset_test.dart`: every preset builds a readable theme, renamed presets keep their ids and labels, legacy ids resolve, Calm is light, still and single-accent with no atmosphere and no title card.
- `core/i18n/app_localizations_test.dart`: one ARB file per shipped locale, every locale carries exactly the template key set, the settings hub renders in German and Russian, en-US and en-GB both resolve, locale tags round-trip through the settings wire format.

OpenAPI (`backend/internal/platform/docs/openapi.yaml`) documents the plan, graduation, discovery pause, Today, copilot, trust, vouch and intro routes.

Live smoke on the running local stack (2026-09-27): a real member proposed and then cancelled a plan; the partner and one accepted friend each received a delivered in-app notification. This is a manual observation on the local stack, not device evidence, and it makes no production claim.

## Still open

- **Billing pause on graduation (PEN-54).** `graduation_rewards` rows are recorded as `pending` only; no subscription is paused or credited.
- **Out-of-app delivery (PEN-55).** Production push is excluded by the release contract, so friend and plan notifications reach the in-app inbox only; SMS or voice to friends who are not members does not exist and needs a vendor decision.
- **UK age assurance vendor (PEN-56).** No age-assurance provider is chosen; the pricing proposal treats it as a UK launch blocker.
- **Native-speaker review of translations (PEN-57).** The tests prove key completeness and rendering, not wording.
- **`giftqa_*` fixture leftovers (PEN-58).** Pre-existing fixture members from `gift_send_ledger_test.go` can remain in the local database after interrupted runs and make reruns flaky; unrelated to this delivery.
