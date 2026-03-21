# Persistence Table Backlog (21 Mar 2026)

## Objective
Eliminate backend in-memory product state and ensure all functional modules persist to PostgreSQL/Supabase tables.

## Canonical schemas
- `matching`
- `user_management`

> Note: This backlog is based on current BFF `memoryStore` functionality and migration scripts in `backend/scripts` through `034_gift_spend_activities.sql`.

## Already covered by existing migrations (keep, validate, extend as needed)
1. `matching.match_unlock_states`
2. `matching.match_quest_templates`
3. `matching.match_quest_workflows`
4. `matching.match_gestures`
5. `matching.activity_sessions`
6. `matching.activity_session_responses`
7. `matching.user_trust_badges`
8. `matching.user_trust_badge_history`
9. `matching.conversation_rooms`
10. `matching.conversation_room_participants`
11. `matching.conversation_room_moderation_actions`
12. `matching.user_trust_filter_preferences`
13. `matching.friend_connections`
14. `matching.friend_activity_feed`
15. `matching.daily_prompts`
16. `matching.prompt_answers`
17. `matching.user_streaks`
18. `matching.community_groups`
19. `matching.community_group_members`
20. `matching.community_group_invites`
21. `matching.gift_catalog`
22. `matching.user_wallets`
23. `matching.match_gift_sends`
24. `matching.gift_spend_activities`
25. `matching.user_activity_notifications`

## Tables to create (persistence gaps)

### P0: critical user + safety + moderation persistence
1. `user_management.profile_drafts`
   - Durable storage for onboarding/profile draft state currently held in memory.
2. `user_management.user_settings`
   - Notification/privacy/theme settings from BFF state.
3. `user_management.emergency_contacts`
   - User emergency contacts (CRUD + ordering).
4. `user_management.blocked_users`
   - Block graph with metadata + timestamps.
5. `matching.verification_states`
   - Verification submission/review state (or align to an existing canonical safety table if already active in prod).
6. `matching.moderation_reports`
   - Report lifecycle and admin actions.
7. `matching.moderation_appeals`
   - Appeals lifecycle and decisions.
8. `matching.sos_alerts`
   - SOS creation, status, resolution metadata.

### P1: engagement state still memory-backed
9. `matching.conversation_room_blocks`
   - Active room-level blocks/mutes beyond moderation action logs.
10. `matching.match_nudges`
    - Nudge sends/clicks/metadata.
11. `matching.conversation_resumes`
    - Resume events tied to nudges.
12. `matching.circle_memberships`
    - Circle membership records.
13. `matching.circle_challenge_entries`
    - Challenge submissions and status.
14. `matching.voice_icebreakers`
    - Icebreaker lifecycle state.
15. `matching.group_coffee_polls`
    - Poll metadata, deadline, owner, status.
16. `matching.group_coffee_poll_options`
    - Poll options.
17. `matching.group_coffee_poll_votes`
    - User votes by option.
18. `matching.video_call_sessions`
    - Start/end call records and participants.
19. `matching.message_delete_audit`
    - Abuse/audit counters as durable events.

### P2: trust, spotlight, and analytics durability
20. `matching.trust_milestones`
    - Snapshot of computed trust milestones used by trust badges.
21. `matching.spotlight_daily_user_counters`
    - User-level exposure/like/match counters by day.
22. `matching.spotlight_daily_tier_counters`
    - Tier-level aggregates by day.
23. `matching.spotlight_eligibility`
    - Eligibility tier/status with effective windows.
24. `matching.billing_subscriptions_runtime`
    - Runtime subscription state used by BFF billing flow.
25. `matching.billing_payments_runtime`
    - Runtime payment history used by BFF responses.

### P3: reporting/event foundation (required for reliable reports)
26. `matching.activity_events`
    - Append-only normalized event stream for product, moderation, and growth analytics.
27. `matching.reporting_refresh_log`
    - ETL/materialized view refresh audit trail for operational reporting.

## Execution order for new migrations (proposed from current baseline)
> Current ordered baseline ends at `034_gift_spend_activities.sql`. Use the following sequence for new files.

1. `035_profile_and_settings_tables.sql`
    - `user_management.profile_drafts`
    - `user_management.user_settings`
    - `user_management.emergency_contacts`
    - `user_management.blocked_users`
2. `036_safety_moderation_tables.sql`
    - `matching.verification_states`
    - `matching.moderation_reports`
    - `matching.moderation_appeals`
    - `matching.sos_alerts`
3. `037_room_nudge_resume_tables.sql`
    - `matching.conversation_room_blocks`
    - `matching.match_nudges`
    - `matching.conversation_resumes`
    - `matching.message_delete_audit`
4. `038_circle_voice_poll_tables.sql`
    - `matching.circle_memberships`
    - `matching.circle_challenge_entries`
    - `matching.voice_icebreakers`
    - `matching.group_coffee_polls`
    - `matching.group_coffee_poll_options`
    - `matching.group_coffee_poll_votes`
5. `039_calls_spotlight_tables.sql`
    - `matching.video_call_sessions`
    - `matching.trust_milestones`
    - `matching.spotlight_daily_user_counters`
    - `matching.spotlight_daily_tier_counters`
    - `matching.spotlight_eligibility`
6. `040_billing_runtime_and_events.sql`
    - `matching.billing_subscriptions_runtime`
    - `matching.billing_payments_runtime`
    - `matching.activity_events`
    - `matching.reporting_refresh_log`

## Required per-table design checklist
- Primary key + business uniqueness constraints for idempotency.
- `created_at`, `updated_at` (and `deleted_at` where soft-delete is needed).
- Actor fields (`created_by`, `updated_by`) where workflows include admin/system actors.
- Correlation and traceability fields (`correlation_id`, `request_id`) for cross-service diagnostics.
- Reporting dimensions needed by dashboards (variant, feature flag, country/city, platform, policy state).
- Indexes for read paths used by BFF and admin/reporting endpoints.
- Foreign keys to canonical entities (`user_id`, `match_id`, `group_id`, etc.) with explicit cascade strategy.

## Module-to-table mapping (from current in-memory functionalities)
1. Profile draft + completion → `user_management.profile_drafts`
2. Profile photos add/delete/reorder → use existing profile photo store; if BFF-managed ordering differs, add ordering columns or bridge table
3. Settings/preferences → `user_management.user_settings`
4. Emergency contacts → `user_management.emergency_contacts`
5. Blocked users → `user_management.blocked_users`
6. Friends graph → existing `matching.friend_connections`
7. Friend activity feed → existing `matching.friend_activity_feed`
8. Verification + admin review → `matching.verification_states`
9. Admin activity stream → `matching.activity_events` (plus filtered read models)
10. Message-delete abuse counters → `matching.message_delete_audit`
11. Quest template/workflow/unlock → existing quest/unlock tables
12. Match gestures → existing `matching.match_gestures`
13. Gifts wallet/send/idempotency/spend → existing gift tables
14. Trust filters → existing `matching.user_trust_filter_preferences`
15. Trust badges/history/milestones → existing badge tables + `matching.trust_milestones`
16. Conversation rooms/moderation/participants/blocks → existing room tables + `matching.conversation_room_blocks`
17. Mini activities → existing activity session tables
18. Daily prompt answers/responders/streaks → existing prompt tables
19. Match nudges → `matching.match_nudges`
20. Conversation resumes → `matching.conversation_resumes`
21. Circle challenge memberships/entries → `matching.circle_memberships`, `matching.circle_challenge_entries`
22. Voice icebreakers → `matching.voice_icebreakers`
23. Group coffee polls/votes → `matching.group_coffee_polls`, `matching.group_coffee_poll_options`, `matching.group_coffee_poll_votes`
24. Community groups/members/invites → existing community group tables
25. Spotlight counters/eligibility → spotlight tables listed above
26. Video call sessions/history → `matching.video_call_sessions`
27. SOS alerts/resolution → `matching.sos_alerts`
28. Moderation reports/appeals → `matching.moderation_reports`, `matching.moderation_appeals`
29. Billing runtime state → `matching.billing_subscriptions_runtime`, `matching.billing_payments_runtime`
30. Analytics aggregates → derive from `matching.activity_events` and domain tables

## Report generation usage (mandatory)
- Write all key user/system actions as immutable rows to `matching.activity_events`.
- Build report queries/materialized views from durable tables, never from process memory.
- Track report refresh/ETL operations in `matching.reporting_refresh_log`.
- Minimum report domains:
  1. Engagement funnel (quest, gestures, prompts, activity sessions)
  2. Safety/moderation (blocks, reports, appeals, SOS)
  3. Social graph (friend growth, room participation, community groups)
  4. Monetization (wallet, gift sends, subscription/payment runtime)

## Implementation policy for new modules
1. Create migration SQL table(s) first.
2. Add repository in infrastructure layer.
3. Add application service/use-case orchestration.
4. Wire BFF handler to repository-backed service.
5. Keep memory path disabled in durable mode (`RequireDurableEngagementStore=true`).
6. Add tests for persistence, idempotency, and recovery behavior.
