# BA Document — "View More" Profile Details Screen
**Reference:** View More / Profile Details UX Bug  
**Date:** 2026-04-11  
**Author:** Business Analyst (AI Agent)  
**Version:** 1.0  
**Status:** APPROVED FOR IMPLEMENTATION  

---

## 1. Business Context

When a user taps **"View more"** on a discovery card in the swipe/discovery screen, they are navigated to `ProfileDetailsScreen`. This screen is intended to show the complete profile of the candidate — including all photos, bio, lifestyle attributes, and preferences — so the user can make a fully informed swipe or message decision.

**Current reported behaviour:** The user sees only the **Love** and **Message** action buttons. Photos (beyond a fallback placeholder) and profile information (bio, education, profession, height, drinking, smoking, religion, lifestyle preferences) are not visible.

---

## 2. Root Cause Analysis (Technical)

### Cause A — Seed data: rich fields not in `users` table

Seed script `042_seed_100_users_25_25_spec.sql` inserts only basic columns into `user_management.users`:  
`id`, `name`, `phone_number`, `date_of_birth`, `gender`, `is_active`, `is_verified`, `profile_completion`, `created_at`, `updated_at`.

The rich fields (`bio`, `height_cm`, `education`, `profession`, `drinking`, `smoking`, `religion`, `country`, `state`, `city`, etc.) are inserted **only** into `user_management.profile_drafts`, not into `users`.

The gRPC `GetProfile` handler (`profile-svc`) queries **only** `user_management.users`. Since those columns are NULL in `users`, the gRPC response returns no bio, no education, no profession, etc.

### Cause B — Flutter provider reads `education`/`profession` only from gRPC profile

`profile_details_provider.dart` maps:
```dart
education: profile['education']?.toString(),
profession: profile['profession']?.toString(),
drinking: profile['drinking']?.toString(),
smoking: profile['smoking']?.toString(),
```
These read **only from the gRPC profile response** (`profile` map), never falling back to the draft. Unlike `bio` and `religion` which use `_firstString(profile, draft, ...)` and thus check both, `education` and `profession` cannot fall back to draft data even if it exists.

### Cause C — Only 1 photo per seed user

Script 042 inserts exactly 1 photo per user in `user_management.photos`. With only 1 photo, the photo thumbnail carousel is hidden by design (`if (safeGalleryPhotos.length > 1)`), and the user cannot scroll through multiple images.

### Summary Matrix

| Issue | Root Cause | Affected Layer |
|---|---|---|
| Bio / attributes blank | `users` table missing rich fields in seed | DB seed + gRPC service |
| education / profession always null | Flutter provider never checks draft | Flutter (provider) |
| No photo carousel | Only 1 photo per seed user | DB seed |
| Lifestyle / preferences blank | Draft fields not synced to `users` table | DB seed |

---

## 3. Current vs Expected Behaviour

| Element | Current | Expected |
|---|---|---|
| Photo count | 1 (fallback placeholder or single seed photo) | ≥ 3 (swipeable carousel + thumbnail strip) |
| Bio | Empty / blank | Populated text bio |
| Height | Blank | e.g. "175 cm" |
| Education | Blank | e.g. "B.Tech" |
| Profession | Blank | e.g. "Software Engineer" |
| Drinking | Blank | e.g. "Occasionally" |
| Smoking | Blank | e.g. "No" |
| Religion | Blank | e.g. "Hindu" |
| Location | Blank | City, State, Country |
| Hobbies | Empty tags | Populated tag chips |
| Intent Tags | Empty | e.g. "long_term" |
| Lifestyle section | Empty | Pet, Diet, Workout, Sleep, Travel preferences |
| Photo thumbnail strip | Hidden (only shown when > 1 photo) | Visible with multiple thumbnails |

---

## 4. Acceptance Criteria (ACs)

### AC-1: Photos Carousel Fully Functional
**Given** a user opens "View More" for a discovery candidate  
**When** the candidate has 3 or more photos  
**Then** the profile screen shows a swipeable full-height photo at the top, with a photo counter badge (`1/3`), and a horizontal thumbnail strip beneath the main photo where each thumbnail is tappable to jump to that photo.

### AC-2: Bio Displayed
**Given** a candidate has a bio stored in the database  
**When** the "View More" screen opens  
**Then** the bio appears truncated at 3 lines with a "Read more" toggle. Tapping "Read more" expands, tapping "Read less" collapses.

### AC-3: Core Profile Attributes Displayed
**Given** a "View More" screen is open  
**Then** each of the following is shown when the value is non-null and non-empty:
- Height (cm)
- Education
- Profession  
- Drinking
- Smoking
- Religion
- Mother Tongue
- Relationship Status
- Personality Type
- Country / State / City
- Instagram Handle

### AC-4: Lifestyle & Preferences Section Displayed
**Given** a "View More" screen is open  
**Then** the "Lifestyle & Preferences" section shows tag/value rows for:
- Pet Preference, Diet Preference, Diet Type, Workout Frequency, Sleep Schedule, Travel Style, Political Comfort Range, Open to Casual

### AC-5: Tag Sections Displayed
**Given** a "View More" screen is open  
**Then** tag chip sections appear (non-empty only) for:
- Hobbies, Favourite Songs, Favourite Books, Favourite Novels, Activities, Intent Tags, Languages, Deal Breakers

### AC-6: NULL / Missing Fields Are Silently Omitted
**Given** a candidate has no value stored for a field (e.g., Instagram Handle is NULL)  
**Then** that row/section is completely hidden — no blank rows, no "N/A" labels.

### AC-7: Education / Profession Resolved from Draft Fallback
**Given** a candidate's `education` and `profession` fields are not present in the gRPC profile response  
**But** they are available in the draft payload  
**Then** those values are displayed correctly (draft fallback is used).

### AC-8: Love / Message Buttons Always Visible
**Given** any "View More" screen for a candidate  
**Then** the Love button and Message button are always pinned at the bottom of the screen, visible regardless of scroll position.

### AC-9: Network Error Handled Gracefully
**Given** the device loses connectivity before the profile detail API call completes  
**Then** a "Retry" button is shown. Internet restored → Retry fetches the profile and renders it fully.

### AC-10: Spotlight Badge Visible
**Given** a candidate is marked as a spotlight profile  
**Then** a spotlight tier badge is shown beside the name in the profile screen.

---

## 5. Edge Cases (ECs)

| EC-ID | Scenario | Expected Behaviour |
|---|---|---|
| EC-01 | Candidate has 0 photos in DB | Placeholder profile image shown; no thumbnail strip; no page counter badge |
| EC-02 | Candidate has exactly 1 photo | Single photo shown; thumbnail strip hidden; page counter shows "1/1" |
| EC-03 | Candidate has > 10 photos | All photos swipeable; thumbnail strip scrolls horizontally; counter shows "n/N" |
| EC-04 | Photo URL returns 404 / fails to load | Individual photo slot shows grey placeholder with image icon |
| EC-05 | Bio is very long (> 500 chars) | Truncated at 3 lines; "Read more" expands full text |
| EC-06 | All profile fields are null | No attribute rows shown; only photo, name/age, and action buttons visible |
| EC-07 | Network times out on `/profile/{id}` | Retry button shown; no crash |
| EC-08 | Network times out on `/profile/{id}/draft` | Main profile data shown from gRPC; draft data silently omitted (no crash) |
| EC-09 | User is blocked by the viewer | Profile detail screen should not be reachable (previous gate in swipe logic should prevent this) |
| EC-10 | Candidate profile has been deleted between swipe and View More tap | Screen shows "User not found" state with a Back button |
| EC-11 | User taps "Message" → already have a conversation | Opens existing chat thread (not a new one) |
| EC-12 | User taps "Love" → already liked this person | Triggers super-like flow or no-op depending on product rules |
| EC-13 | Profile details provider is loading (async) | Full-screen loading spinner shown; Love/Message buttons hidden during load |
| EC-14 | Very low bandwidth (< 1 Mbps) | Images load progressively; no UI freeze; user can still scroll text content |
| EC-15 | Candidate is a spotlight user with a tier label | Spotlight tier badge displays; spotlight badge text correctly capitalised |
| EC-16 | Candidate name contains special characters | Name rendered correctly; no overflow or crash |
| EC-17 | heightCm is stored as string in API response | Provider coerces safely; no cast crash |
| EC-18 | Photos array has duplicate URLs | Duplicate URLs de-duplicated in `_resolvePhotoUrls`; each photo shown once |
| EC-19 | Draft photos array is null or missing | Photo list resolved from gRPC profile only; no crash |
| EC-20 | Party lover field is true | "Party Lover: Yes" displayed |

---

## 6. Test Case Scenarios (TCs)

### Unit / Widget Tests (Flutter)

| TC-ID | Type | Description | Pass Criteria |
|---|---|---|---|
| TC-U01 | Unit | `profileDetailsProvider` maps `education` from `draft` when absent in `profile` | `ProfileDetails.education` == draft value |
| TC-U02 | Unit | `profileDetailsProvider` maps `profession` from `draft` when absent in `profile` | `ProfileDetails.profession` == draft value |
| TC-U03 | Unit | `_resolvePhotoUrls` deduplicates identical URLs | Returned list has no duplicates |
| TC-U04 | Unit | `_resolvePhotoUrls` returns empty list when both profile and draft have no photos | Empty list returned |
| TC-U05 | Unit | `_resolvePhotoUrls` sorts draft photos by `ordering` ascending | Photos in correct order |
| TC-U06 | Unit | `ProfileDetails.age` computes correctly for birthday today | age == current year − birth year |
| TC-W01 | Widget | `ProfileDetailsScreen` renders photo carousel when `photoUrls` has 3 items | PageView renders; thumbnail strip visible |
| TC-W02 | Widget | `ProfileDetailsScreen` renders loading spinner when provider is loading | CircularProgressIndicator shown; no Love/Message buttons |
| TC-W03 | Widget | `ProfileDetailsScreen` renders retry button on provider error | TextButton "Retry" shown; tapping invalidates provider |
| TC-W04 | Widget | `ProfileDetailsScreen` hides thumbnail strip when only 1 photo | No thumbnail strip rendered |
| TC-W05 | Widget | bio "Read more" / "Read less" toggle works | State toggles; text expands/collapses |
| TC-W06 | Widget | `_kv` helper returns `SizedBox.shrink()` for null value | No row rendered for null field |
| TC-W07 | Widget | `_tagSection` returns `SizedBox.shrink()` for empty list | No section rendered |
| TC-W08 | Widget | Love button pops with `ProfileDetailsAction.love` | Navigator.pop called with love action |
| TC-W09 | Widget | Message button pops with `ProfileDetailsAction.message` | Navigator.pop called with message action |

### Integration / API Tests (Backend)

| TC-ID | Type | Description | Pass Criteria |
|---|---|---|---|
| TC-I01 | Integration | `GET /v1/profile/{seedUserId}` returns `photoUrls` array with ≥ 3 items for 044 seed users | Response `profile.photoUrls` length ≥ 3 |
| TC-I02 | Integration | `GET /v1/profile/{seedUserId}` returns `education`, `profession`, `bio` non-null | Response `profile.education` is non-empty string |
| TC-I03 | Integration | `GET /v1/profile/{seedUserId}/draft` returns `photos` array with `photo_url` and `ordering` | Draft `photos[0].photo_url` non-empty; `photos[0].ordering` == 1 |
| TC-I04 | Integration | `GET /v1/profile/{nonExistentId}` returns `found: false` | Status 200 with `found: false` |
| TC-I05 | Integration | Profile gRPC `GetProfile` call includes `photoUrls` from `user_management.photos` | `user.photoUrls` in response |

### End-to-End Smoke Tests

| TC-ID | Type | Description | Pass Criteria |
|---|---|---|---|
| TC-E01 | E2E | Open discovery screen → tap "View more" on a 044 seed user card | Profile detail screen opens; 3 photos visible; bio visible; attributes visible |
| TC-E02 | E2E | Swipe through photos in profile detail screen | Active photo advances; counter badge updates; thumbnail strip highlights correct thumb |
| TC-E03 | E2E | Tap "Love" in profile detail screen | Navigates back with `love` action; original screen triggers super-like animation |
| TC-E04 | E2E | Tap "Message" in profile detail screen | Navigates back with `message` action; conversation opened |
| TC-E05 | E2E | Tap "Report" in profile detail screen | Report sheet opens; submit sends report; snackbar with appeal option shown |

---

## 7. Implementation Plan

### Phase 1 — Data Layer (Backend Seed)

**File:** `backend/scripts/044_seed_100_users_rich_matches_spotlight.sql`

- Groups A–D (100 users total):
  - Group A (i=1..25): 25 males — regular discovery candidates (no spotlight)
  - Group B (i=26..50): 25 females — regular discovery candidates
  - Group C (i=51..75): 25 males — spotlight candidates
  - Group D (i=76..100): 25 females — spotlight candidates
- Insert into `user_management.users` with ALL rich columns populated:
  - `bio`, `height_cm`, `education`, `profession`, `drinking`, `smoking`, `religion`, `mother_tongue`, `relationship_status`, `personality_type`, `country`, `state`, `city`, `profile_completion = 100`
- Insert 3 photos per user into `user_management.photos` with distinct picsum seeds
- Insert preferences, user_settings, wallet
- Insert 25 regular match pairs (A↔B) + 25 spotlight match pairs (C↔D)
- Insert `match_unlock_states` for all 50 pairs
- Insert `activity_events` for seeded matches
- Append to `backend/scripts_run_order.txt`

**Design choices:**
- Use prefix `seed44-user-{i}` for deterministic UUIDs
- Use `seed44-photo-{i}-{j}` for photo UUIDs (j=1,2,3)
- Spotlight match pairs: check `matching.matches` for `is_spotlight` column; if absent, add to spotlight via a separate mechanism

### Phase 2 — Flutter Provider Fix

**File:** `app/lib/features/swipe/providers/profile_details_provider.dart`

Change `education`, `profession`, `drinking`, `smoking` to use `_firstString(profile, draft, ...)` so draft is a fallback source:

```dart
// Before
education: profile['education']?.toString(),
profession: profile['profession']?.toString(),
drinking: profile['drinking']?.toString(),
smoking: profile['smoking']?.toString(),

// After
education: _firstString(profile, draft, const ['education']),
profession: _firstString(profile, draft, const ['profession']),
drinking: _firstString(profile, draft, const ['drinking']),
smoking: _firstString(profile, draft, const ['smoking']),
```

Also add draft fallback for `heightCm`:
```dart
// Before
heightCm: (profile['heightCm'] as num?)?.toInt(),

// After
heightCm: _firstIntFromSources(profile, draft, const ['heightCm', 'height_cm']),
```
(requires a new `_firstIntFromSources` helper)

### Phase 3 — Validation

1. Run `cd backend && go test ./...`
2. Run `make backend-compliance-check`
3. Apply migration `044_seed_100_users_rich_matches_spotlight.sql` to local Supabase
4. Run `cd app && flutter test --no-pub`
5. Run app on `emulator-5554` → tap "View more" on discovery card → verify full profile renders

---

## 8. Definition of Done

- [ ] 044 seed script applied; 100 users discoverable in swipe screen
- [ ] Each of 100 seed users has ≥ 3 photos visible in profile detail screen
- [ ] Bio, education, profession, drinking, smoking, religion, location all visible
- [ ] Lifestyle section and tag sections visible for all seed users
- [ ] Photo thumbnail carousel renders and is tappable
- [ ] Love and Message buttons functional
- [ ] All TC-W01 through TC-W09 pass
- [ ] `flutter analyze` passes with no new warnings
- [ ] `go test ./...` passes
- [ ] `make backend-compliance-check` passes

---

## 9. Out of Scope

- Edit profile from the View More screen (read-only view)
- Video profiles
- Profile view analytics (tracked separately via existing `activity_events`)
- i18n / localisation of field labels
