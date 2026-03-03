# Epic 5 - Story 5.2 Trust Filter Controls Report

Date: 1 Mar 2026
Story: Epic 5 / Story 5.2 (8 SP)
Status: Completed

## Scope
Implement women trust filter controls for discovery and matches with:
1. Filter settings persisted per user
2. Discovery and match lists honoring trust filters
3. Empty-state UX explaining trust-filter impact

## Implemented
- Added trust filter persistence domain in mobile BFF store with validation and normalization:
  - `enabled`
  - `minimum_active_badges`
  - `required_badge_codes`
- Added trust filter API endpoints:
  - `GET /v1/discovery/{userID}/filters/trust`
  - `PATCH /v1/discovery/{userID}/filters/trust`
- Added response-level trust filtering hooks for:
  - `GET /v1/discovery/{userID}` candidates
  - `GET /v1/matches/{userID}` matches
- Added trust summary metadata in responses (`trust_filter.active`, `trust_filter.filtered_out_count`) to support explanatory empty states.
- Added Flutter trust filter provider and integrated controls into existing filter sheet in Discover.
- Added apply flow that persists trust filters and refreshes discovery + matches data.
- Added trust-aware empty-state copy in Discover and Matches screens when filters remove all available results.

## Files
- `backend/internal/bff/mobile/trust_filters.go`
- `backend/internal/bff/mobile/server_trust_filters.go`
- `backend/internal/bff/mobile/store.go`
- `backend/internal/bff/mobile/server.go`
- `backend/internal/bff/mobile/server_trust_filters_test.go`
- `app/lib/features/matching/providers/trust_filter_provider.dart`
- `app/lib/features/common/screens/main_navigation_screen.dart`
- `app/lib/features/swipe/providers/swipe_provider.dart`
- `app/lib/features/swipe/screens/home_discovery_screen.dart`
- `app/lib/features/matching/providers/match_provider.dart`
- `app/lib/features/matching/screens/matches_list_screen.dart`
- `app/test/features/matching/providers/trust_filter_provider_test.dart`

## Automated Test Evidence
- `runTests` target:
  - `backend/internal/bff/mobile/server_trust_filters_test.go`
  - `backend/internal/bff/mobile/server_trust_badges_test.go`
  - Result: passed 4, failed 0
- `runTests` target:
  - `app/test/features/matching/providers/trust_filter_provider_test.dart`
  - Result: passed 3, failed 0
- Regression sanity target:
  - `app/test/features/matching/providers/activity_session_provider_test.dart`
  - Result: passed 3, failed 0

## Acceptance Criteria Mapping
1. Women trust filters persist per user.
- Implemented via `trustFilterPreference` persistence in BFF store and `GET/PATCH` trust filter APIs.

2. Discovery and match lists honor trust filters.
- Implemented via trust filtering wrappers on BFF discovery/matches payloads using active trust badge evaluation per candidate/match row.

3. Empty-state UX explains filter impact.
- Implemented via response metadata (`trust_filter.filtered_out_count`) and trust-aware empty-state copy in Discover and Matches screens.

## Notes
- Existing age/distance/verified controls remain unchanged and continue to behave as local UI filters.
- Trust filters are persisted server-side and reused across discovery/matches requests.
