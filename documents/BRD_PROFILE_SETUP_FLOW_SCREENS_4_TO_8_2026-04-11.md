# Business Requirements Document (BRD)
## Profile Setup Flow — Screens 4 through 8

| Field | Value |
|---|---|
| **Document ID** | BRD-PSF-001 |
| **Version** | 1.1 |
| **Date** | 11 April 2026 (revised) |
| **Author** | GitHub Copilot (AI BA) |
| **Status** | Updated — Three bugs resolved: navigation (PSF-8.9), button theme (Screen 6), data retention on back (Screen 7) |
| **Change Summary** | v1.1: Fixed PSF-8.9 (direct navigation via `pushAndRemoveUntil`), expanded Screen 6 ACs (button theme), added Screen 7 FR/AC/EC/TC for back-nav auto-save, expanded Screen 8 ACs/TCs for durable completion + route clearing. |
| **Scope** | ProfileSetupEntryScreen (4) → SetupBasicInfoScreen (5) → SetupPhotosScreen (6) → SetupAboutScreen (7) → SetupPreviewScreen (8) |
| **Storage Policy** | Local filesystem only (no cloud storage). All photo assets persisted to server local disk via BFF `/v1/media/*` endpoint. |

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Glossary](#2-glossary)
3. [System Architecture Summary](#3-system-architecture-summary)
4. [Database Design](#4-database-design)
5. [Screen 4 — ProfileSetupEntryScreen](#5-screen-4--profilesetupentryscreen)
6. [Screen 5 — SetupBasicInfoScreen (Step 1 of 4)](#6-screen-5--setupbasicinfoscreen-step-1-of-4)
7. [Screen 6 — SetupPhotosScreen (Step 2 of 4)](#7-screen-6--setupphotosscreen-step-2-of-4)
8. [Screen 7 — SetupAboutScreen (Step 3 of 4)](#8-screen-7--setupaboutscreen-step-3-of-4)
9. [Screen 8 — SetupPreviewScreen (Step 4 of 4)](#9-screen-8--setuppreviewscreen-step-4-of-4)
10. [Cross-Cutting Concerns](#10-cross-cutting-concerns)
11. [Validation Rule Registry](#11-validation-rule-registry)
12. [Non-Functional Requirements](#12-non-functional-requirements)
13. [Open Questions & Decisions](#13-open-questions--decisions)

---

## 1. Executive Summary

### Purpose
This BRD defines the requirements, acceptance criteria, edge cases, and test scenarios for the five-screen profile setup wizard that a newly registered user must complete before accessing the main application (Discover / Swipe / Chat). The setup flow is the single most critical onboarding path — a complete, high-quality profile is a prerequisite for a user to be shown in discovery feeds and to initiate or receive matches.

### Business Objective
- **Completion rate target**: ≥ 75% of users who land on Screen 4 must reach Screen 8 "Complete" within a single session.
- **Photo quality**: 100% of submitted photos must pass server-side format and size validation before being stored.
- **Data integrity**: No partial profile state must be queryable by the matching engine. The `profile_completed_at` timestamp is the gate.
- **Resumability**: A user who drops off mid-flow must be able to resume exactly where they left off (draft persistence).

### Personas
| Persona | Description |
|---|---|
| **New Registrant** | Just verified OTP. Has no prior draft. Arrives at Screen 4 for the first time. |
| **Returning Incomplete** | Previously entered screen 5 or 6 but abandoned. Resumes from saved draft. |
| **Re-completer** | Completed profile before; wants to edit. Goes through setup flow again from settings. |

---

## 2. Glossary

| Term | Definition |
|---|---|
| **Draft** | A durable, partial record of a user's setup progress stored in `user_management.profile_drafts`. Persisted at every step. |
| **Profile Completion** | The state when `CompleteProfile` API call succeeds and `profile_completed_at` is set in `user_management.users`. |
| **Photo** | An image file uploaded by the user, stored on the BFF server's local filesystem. Metadata stored in `user_management.photos`. |
| **Primary Photo** | The photo at `ordering = 0`. Used as the main display photo in cards and discovery. |
| **Step** | One of the 4 wizard steps (Basic Info, Photos, About, Preview). Each step maps to one screen. |
| **BFF** | Mobile Backend-for-Frontend. Go service at `:8081` that the Flutter app communicates with. |
| **Correlation ID** | UUID generated per request by the Flutter `ApiClient`, sent as `X-Correlation-ID` header for end-to-end tracing. |

---

## 3. System Architecture Summary

```
Flutter App (AVD / Device)
    │
    ├─ ProfileSetupEntryScreen       (guards: auth + draft load)
    ├─ SetupBasicInfoScreen          (Step 1: name, DOB, gender)
    ├─ SetupPhotosScreen             (Step 2: photo gallery + camera)
    ├─ SetupAboutScreen              (Step 3: bio, height, lifestyle)
    └─ SetupPreviewScreen            (Step 4: preview + complete)
            │
            │  Dio HTTP  (X-Correlation-ID, X-Client-Platform)
            ▼
    API Gateway (:8080)
    ├─ CorrelationID middleware
    ├─ Exception handler
    ├─ IP rate limiting
    └─ Reverse-proxy to Mobile BFF
            │
            ▼
    Mobile BFF (:8081)
    ├─ CorrelationID middleware
    ├─ Idempotency middleware  (PATCH /profile/:id/draft)
    ├─ Activity middleware    (profile completion event)
    └─ Profile module application service
            │
            ├─ Mediatr → Profile Application Service
            └─ Profile Infrastructure (store_gateway / grpc_gateway)
                    │
                    ▼
        PostgreSQL / Supabase
        └─ user_management schema
           ├─ users
           ├─ profile_drafts         (Migration 043)
           ├─ photos                 (existing + path enrichment)
           └─ user_settings          (Migration 043)

    Local Filesystem (BFF server)
    └─ .run/uploads/profile_photos/{user_id}/{photo_id}.{ext}
```

### Key Architecture Principles
1. **No hardcoded strings**: All table names, endpoints, paths loaded from env/config.
2. **Draft-first persistence**: Every `PATCH /profile/{userId}/draft` call writes to `user_management.profile_drafts` before returning.
3. **Optimistic UI**: State is updated locally first; remote call failure rolls back with error snackbar.
4. **Idempotency**: PATCH draft carries `Idempotency-Key` header (generated per save attempt). Duplicate submission within 60 s returns cached response.
5. **Clean Architecture**: Flutter → Provider (Riverpod) → Repository → BFF API. No direct DB calls from client.
6. **Correlation tracing**: Every API request carries `X-Correlation-ID` for log tracing across gateway → BFF → profile service.

---

## 4. Database Design

> **Storage policy**: All profile photos are stored on the **local filesystem** of the BFF server at the path configured by `MEDIA_UPLOADS_DIR` (default: `.run/uploads/profile_photos`). The BFF generates a public URL (`MEDIA_PUBLIC_BASE_URL/{userId}/{photoId}.{ext}`) which is stored in the `photo_url` column. No cloud bucket (S3/Supabase Storage) is used.

### 4.1 Migration: `043_profile_setup_persistence.sql`

> Append to `backend/scripts_run_order.txt` after `042_seed_100_users_25_25_spec.sql`.

```sql
-- ============================================================
-- Migration 043: Profile setup durable persistence
-- Schemas: user_management
-- Tables: profile_drafts, user_settings
-- ============================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- 1) profile_drafts
--    Durable, per-user accumulator for the setup wizard state.
--    Row is created on first PATCH draft. Overwritten on each step completion.
--    Deleted (or retained indefinitely) after CompleteProfile succeeds.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS user_management.profile_drafts (
    id                      UUID        NOT NULL DEFAULT gen_random_uuid(),
    user_id                 UUID        NOT NULL,

    -- Step 1: Basic Info
    name                    TEXT,
    date_of_birth           DATE,
    gender                  TEXT        CHECK (gender IN ('M', 'F', 'Other')),

    -- Step 3: About
    bio                     TEXT,
    height_cm               INT         CHECK (height_cm IS NULL OR (height_cm >= 100 AND height_cm <= 250)),
    education               TEXT,
    profession              TEXT,
    income_range            TEXT,
    drinking                TEXT        NOT NULL DEFAULT 'Never',
    smoking                 TEXT        NOT NULL DEFAULT 'Never',
    religion                TEXT,
    mother_tongue           TEXT,

    -- Preferences (collected via SetupPreferencesScreen post-step-4)
    seeking_genders         TEXT[]      NOT NULL DEFAULT '{}',
    min_age_years           INT         NOT NULL DEFAULT 18 CHECK (min_age_years >= 18 AND min_age_years <= 80),
    max_age_years           INT         NOT NULL DEFAULT 60 CHECK (max_age_years >= 18 AND max_age_years <= 80),
    max_distance_km         INT         NOT NULL DEFAULT 50 CHECK (max_distance_km >= 1 AND max_distance_km <= 500),
    education_filter        TEXT[]      NOT NULL DEFAULT '{}',
    serious_only            BOOLEAN     NOT NULL DEFAULT TRUE,
    verified_only           BOOLEAN     NOT NULL DEFAULT FALSE,
    hookup_only             BOOLEAN     NOT NULL DEFAULT FALSE,

    -- Location (advanced preferences)
    country                 TEXT,
    region_state            TEXT,
    city                    TEXT,

    -- Lifestyle & identity
    diet_preference         TEXT,
    workout_frequency       TEXT,
    diet_type               TEXT,
    sleep_schedule          TEXT,
    travel_style            TEXT,
    political_comfort_range TEXT,
    pet_preference          TEXT,

    -- Social / interest tags (free text, comma-separated or JSON array)
    instagram_handle        TEXT,
    hobbies                 TEXT[]      NOT NULL DEFAULT '{}',
    favorite_books          TEXT[]      NOT NULL DEFAULT '{}',
    favorite_novels         TEXT[]      NOT NULL DEFAULT '{}',
    favorite_songs          TEXT[]      NOT NULL DEFAULT '{}',
    extra_curriculars       TEXT[]      NOT NULL DEFAULT '{}',
    intent_tags             TEXT[]      NOT NULL DEFAULT '{}',
    language_tags           TEXT[]      NOT NULL DEFAULT '{}',
    deal_breaker_tags       TEXT[]      NOT NULL DEFAULT '{}',
    additional_info         TEXT,

    -- Step tracking
    current_step            INT         NOT NULL DEFAULT 1 CHECK (current_step BETWEEN 1 AND 4),
    last_saved_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Audit
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    correlation_id          TEXT,        -- last X-Correlation-ID that touched this row

    CONSTRAINT profile_drafts_pkey PRIMARY KEY (id),
    CONSTRAINT profile_drafts_user_id_uq UNIQUE (user_id),
    CONSTRAINT profile_drafts_user_id_fk FOREIGN KEY (user_id)
        REFERENCES user_management.users (id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_profile_drafts_user_id
    ON user_management.profile_drafts (user_id);

CREATE INDEX IF NOT EXISTS idx_profile_drafts_last_saved_at
    ON user_management.profile_drafts (last_saved_at DESC);

-- Trigger: auto-update updated_at on every row change
CREATE OR REPLACE FUNCTION user_management.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_profile_drafts_updated_at
    BEFORE UPDATE ON user_management.profile_drafts
    FOR EACH ROW EXECUTE FUNCTION user_management.set_updated_at();


-- ─────────────────────────────────────────────────────────────────────────────
-- 2) user_settings
--    Notification, privacy, and UI preferences set during or after setup.
--    Created with defaults when profile is completed.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS user_management.user_settings (
    user_id                 UUID        NOT NULL,

    -- Privacy
    show_age                BOOLEAN     NOT NULL DEFAULT TRUE,
    show_exact_distance     BOOLEAN     NOT NULL DEFAULT TRUE,
    show_online_status      BOOLEAN     NOT NULL DEFAULT TRUE,

    -- Notifications
    notify_new_match        BOOLEAN     NOT NULL DEFAULT TRUE,
    notify_new_message      BOOLEAN     NOT NULL DEFAULT TRUE,
    notify_likes            BOOLEAN     NOT NULL DEFAULT TRUE,

    -- UI
    theme                   TEXT        NOT NULL DEFAULT 'light'
                                CHECK (theme IN ('light', 'dark', 'system')),

    -- Audit
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT user_settings_pkey PRIMARY KEY (user_id),
    CONSTRAINT user_settings_user_id_fk FOREIGN KEY (user_id)
        REFERENCES user_management.users (id) ON DELETE CASCADE
);

CREATE TRIGGER trg_user_settings_updated_at
    BEFORE UPDATE ON user_management.user_settings
    FOR EACH ROW EXECUTE FUNCTION user_management.set_updated_at();


-- ─────────────────────────────────────────────────────────────────────────────
-- 3) photos — ensure local-storage path columns are present
--    (Table already exists from earlier migrations; this adds missing columns
--     that support the local-filesystem storage policy.)
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE user_management.photos
    ADD COLUMN IF NOT EXISTS storage_backend  TEXT    NOT NULL DEFAULT 'local_fs'
        CHECK (storage_backend IN ('local_fs', 's3', 'supabase')),
    ADD COLUMN IF NOT EXISTS local_fs_path    TEXT,               -- absolute path on BFF server
    ADD COLUMN IF NOT EXISTS original_filename TEXT,              -- original filename from client
    ADD COLUMN IF NOT EXISTS mime_type         TEXT,              -- e.g. 'image/jpeg'
    ADD COLUMN IF NOT EXISTS size_bytes        BIGINT,            -- validated on upload
    ADD COLUMN IF NOT EXISTS width_px          INT,               -- stored after server-side decode
    ADD COLUMN IF NOT EXISTS height_px         INT,               -- stored after server-side decode
    ADD COLUMN IF NOT EXISTS is_primary        BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS correlation_id    TEXT;


-- Partial unique index: only one primary photo per user at a time
CREATE UNIQUE INDEX IF NOT EXISTS idx_photos_primary_per_user
    ON user_management.photos (user_id)
    WHERE is_primary = TRUE;

CREATE INDEX IF NOT EXISTS idx_photos_user_ordering
    ON user_management.photos (user_id, ordering);

COMMENT ON COLUMN user_management.photos.storage_backend  IS 'Where the file is stored: local_fs = BFF local disk.';
COMMENT ON COLUMN user_management.photos.local_fs_path    IS 'Absolute path on the BFF server, e.g. /app/.run/uploads/profile_photos/{user_id}/{photo_id}.jpg';
COMMENT ON COLUMN user_management.photos.photo_url        IS 'Public-accessible URL served by BFF /v1/media/ handler.';
```

### 4.2 Entity Relationship Notes

```
user_management.users  (1)───────────────(1)  user_management.profile_drafts
                       (1)───────────────(*)  user_management.photos
                       (1)───────────────(1)  user_management.user_settings
```

### 4.3 Photo Local Storage Layout

```
BFF Server filesystem
└── {MEDIA_UPLOADS_DIR}/              ← env var, default: .run/uploads/profile_photos
    └── {user_id}/                    ← UUID directory per user
        ├── {photo_id}_orig.jpg       ← original uploaded file
        └── {photo_id}_thumb.jpg      ← server-generated 300x300 thumbnail (future)
```

Public URL served at:
```
{MEDIA_PUBLIC_BASE_URL}/profile_photos/{user_id}/{photo_id}.jpg
```

Config driven — no hardcoded path segments in application code.

### 4.4 Profile Completion State Machine

```
users.profile_completed_at

    NULL ──► photo_count ≥ 2 AND name ≠ '' AND dob ≠ NULL AND bio ≥ 10 chars
              └── POST /profile/{userId}/complete
                    └── users.profile_completed_at = NOW()
                    └── user_settings row created with defaults
                    └── activity_event emitted: profile_completed
```

---

## 5. Screen 4 — ProfileSetupEntryScreen

**File**: `app/lib/features/profile/screens/setup/profile_setup_entry_screen.dart`

### 5.1 Purpose
Gate screen. Checks authentication state and loads profile completion status + existing draft before routing the user into the wizard. Never displays a form itself.

### 5.2 Functional Requirements

| ID | Requirement |
|---|---|
| PSF-4.1 | If the user is **not authenticated** (`auth.isAuthenticated == false`), show nothing (`SizedBox.shrink()`). The auth guard at the navigation layer must redirect to login. |
| PSF-4.2 | If the user **is authenticated**, immediately call `GET /profile/{userId}/summary` and `GET /profile/{userId}/draft` via `profileCompletionProvider`. |
| PSF-4.3 | While loading, display a full-screen centered `CircularProgressIndicator`. |
| PSF-4.4 | If the API returns an error, display a centered **Retry** button. Tapping it invalidates the provider and re-triggers the load. |
| PSF-4.5 | On successful load, navigate to `SetupBasicInfoScreen`. |
| PSF-4.6 | If `profile_completed_at` is already set (user is re-entering setup from settings), the entry screen must still route to `SetupBasicInfoScreen` to allow editing. |

### 5.3 Acceptance Criteria

| AC# | Criterion |
|---|---|
| AC-4.1 | Given unauthenticated user arrives at Screen 4 → the screen renders blank; no API calls are made. |
| AC-4.2 | Given authenticated user with no prior draft → loading spinner appears, API is called, user lands on Screen 5. |
| AC-4.3 | Given API returns 5xx → Retry button appears; tapping it re-fetches. |
| AC-4.4 | Given API returns 401 → auth token is refreshed or user is redirected to login. (Handled by `ApiClient` interceptor.) |
| AC-4.5 | Given network offline → Retry button appears with `ErrorMessages.networkError` message. |
| AC-4.6 | Screen renders within **300 ms** of route push on mid-range device (Pixel 5 equivalent). |

### 5.4 Edge Cases

| Edge Case | Expected Behaviour |
|---|---|
| User taps back hardware button on Screen 4 | Pop back to previous screen (welcome / auth). |
| `userId` is non-null but malformed UUID | API returns 400; retry button shown; no crash. |
| App killed and relaunched mid-setup | Entry screen re-loads draft; user resumes at the last saved step. |
| Draft load succeeds but `auth.userId` becomes null before navigation | Abort navigation silently; auth guard triggers redirect. |

### 5.5 Test Scenarios

| TC# | Scenario | Precondition | Steps | Expected Result |
|---|---|---|---|---|
| TC-4.1 | Happy path — fresh user | User authenticated, no draft | Open app post-OTP | Loading spinner → Screen 5 |
| TC-4.2 | Retry on network fail | No network | Open Screen 4 | Error state + Retry button visible |
| TC-4.3 | Retry recovers | Network restored after error | Tap Retry | Spinner → Screen 5 |
| TC-4.4 | Unauthenticated | Session expired | Navigate to Screen 4 | Blank screen (no crash, no loop) |
| TC-4.5 | Existing draft resumption | User partially completed Step 2 | Open app | Load → Screen 5 (draft pre-filled) |

---

## 6. Screen 5 — SetupBasicInfoScreen (Step 1 of 4)

**File**: `app/lib/features/profile/screens/setup/setup_basic_info_screen.dart`

### 6.1 Purpose
Collects the user's **mandatory identity fields**: display name, date of birth, gender. Optional quick-bio field is also offered here. This is the minimum viable data set required by the matching engine.

### 6.2 Field Specification

| Field | Type | Required | Constraints |
|---|---|---|---|
| Display Name | Text | Yes | Min 2 chars, Max 50 chars. No leading/trailing spaces after trim. |
| Date of Birth | Date (Day / Month / Year dropdowns) | Yes | User age must be ≥ 18 years and ≤ 80 years at time of setup. Leap year validation. |
| Gender | Single-select (M / F / Other) | Yes | Default = 'M'. Must be one of the enum values. |
| Bio (quick) | Multiline text | No | If provided: min 10 chars, max 500 chars. Saved via `saveAbout` if non-empty. |

### 6.3 Functional Requirements

| ID | Requirement |
|---|---|
| PSF-5.1 | On entering the screen, pre-populate all fields from the saved draft (if one exists). |
| PSF-5.2 | Validate name length on "Next" tap before any API call. |
| PSF-5.3 | Validate age is ≥ 18. Show inline error if underage. |
| PSF-5.4 | DOB picker uses three separate dropdowns: Day, Month, Year. Day dropdown must dynamically update its max value when Month or Year changes (e.g., Feb 29 lease year). |
| PSF-5.5 | Gender selector must show three options: Male, Female, Other. Selected option is highlighted. |
| PSF-5.6 | On successful save (`PATCH /profile/{userId}/draft`), navigate to `SetupPhotosScreen`. |
| PSF-5.7 | If save fails (network/server error), show a SnackBar and remain on Screen 5. Do **not** re-reset form values. |
| PSF-5.8 | Step indicator shows "1 of 4" and a back arrow that pops to Screen 4. |
| PSF-5.9 | Keyboard should dismiss on scroll (DismissOnDrag). Bottom padding adjusts dynamically for keyboard offset. |
| PSF-5.10 | The "Next" button shows a loading indicator while save is in progress. Tapping it again while loading does nothing. |

### 6.4 Acceptance Criteria

| AC# | Criterion |
|---|---|
| AC-5.1 | Given no name entered → tap Next → SnackBar "Name must be at least 2 characters." No navigation. |
| AC-5.2 | Given name = 1 character → validation fails with correct message. |
| AC-5.3 | Given name = 2 characters → validation passes. |
| AC-5.4 | Given DOB not selected → tap Next → SnackBar "Please select your date of birth." |
| AC-5.5 | Given DOB = today minus 17 years → tap Next → SnackBar "You must be at least 18 years old." No navigation. |
| AC-5.6 | Given DOB = today minus 18 years (exact) → validation passes. |
| AC-5.7 | Given DOB = 29 Feb (leap year) correctly entered → navigation proceeds. |
| AC-5.8 | Given DOB = 29 Feb (non-leap year) selected → Day dropdown resets to 28 automatically. |
| AC-5.9 | Given valid name + DOB + gender → Next → BFF PATCH called → navigate to Screen 6. |
| AC-5.10 | Given API 500 → SnackBar shown; form values preserved; user can retry. |
| AC-5.11 | Given user navigates back to Screen 5 from Screen 6 → all previously entered values are pre-filled. |
| AC-5.12 | Given bio is empty → save proceeds without error (bio is optional at Step 1). |
| AC-5.13 | Given bio = 5 chars → if user submits bio here, SnackBar "Bio must be at least 10 characters." But navigation is not blocked if bio is left blank. |

### 6.5 Edge Cases

| Edge Case | Expected Behaviour |
|---|---|
| Name contains only spaces | Trimmed to empty string; fails min-length validation. |
| Name = 50 chars exactly | Passes. |
| Name = 51 chars | Input field refuses entry or save fails validation with max-length message. |
| Gender not touched | Default 'M' is submitted. |
| Year picker = current year | Only past dates allowed; days/months constrained. |
| Year = 1900 | Allowed if resulting age ≤ 80. |
| User rotates device mid-form | All field values survive rotation (backed by `ConsumerStatefulWidget` state). |
| User backgrounds app mid-form | On return, draft is re-loaded; if `_didInitialize` flag is false, fields re-populate. |
| BFF unreachable (airplane mode) | SnackBar with `ErrorMessages.networkError`. No crash. |
| Session token expired mid-save | `ApiClient` interceptor attempts refresh; if failed, snack + redirect to login. |
| Special characters in name (e.g., "Ján Dvořák") | Accepted. No ASCII-only restriction. Max 50 chars. |
| Emoji in name | Accepted (emoji is valid Unicode). |

### 6.6 Test Scenarios

| TC# | Scenario | Input | Expected Result |
|---|---|---|---|
| TC-5.1 | Valid submission | Name="John", DOB=01/Jan/1995, Gender=M | Navigate to Screen 6; draft updated |
| TC-5.2 | Empty name | Name="" | SnackBar "Name must be at least 2 characters." |
| TC-5.3 | Underage | DOB = today minus 16 years | SnackBar "You must be at least 18 years old." |
| TC-5.4 | No DOB selected | No dropdowns touched | SnackBar "Please select your date of birth." |
| TC-5.5 | Feb 29 leap year | DOB=29/Feb/2000 (leap) | Valid, proceeds |
| TC-5.6 | Feb 29 non-leap | Month=Feb, Year=2001, Day=29 | Day auto-corrects to 28 |
| TC-5.7 | API failure | Valid form, server returns 500 | SnackBar "Failed to save — please try again." |
| TC-5.8 | Resume draft | Existing draft with name="Jane" | Name field pre-filled with "Jane" |
| TC-5.9 | Name with emoji | Name="Alex 😊" | Accepted, saved |
| TC-5.10 | Gender = Other | Tap "Other" | Proceeding saves gender='Other' |
| TC-5.11 | Double-tap Next | Tap Next twice in quick succession | Only one API call; no duplicate state |
| TC-5.12 | Bio = 9 chars entered here | Bio="Hello!!" | Bio field set but submission of bio blocked with snack; main navigation still allowed if bio is cleared |

---

## 7. Screen 6 — SetupPhotosScreen (Step 2 of 4)

**File**: `app/lib/features/profile/screens/setup/setup_photos_screen.dart`

### 7.1 Purpose
Allows the user to select up to 5 photos from their gallery or camera. Photos are immediately uploaded to the BFF (multipart/form-data) which saves them to the local filesystem. The first photo in the list becomes the primary photo.

### 7.2 Photo Constraints

| Constraint | Value | Source |
|---|---|---|
| Minimum photos to proceed | 2 | `ValidationConstants.minPhotos` |
| Maximum photos allowed | 5 | `ValidationConstants.maxPhotos` |
| Maximum file size per photo | 10 MB | `ValidationConstants.maxPhotoSizeMB` |
| Accepted MIME types | `image/jpeg`, `image/png`, `image/heic` | Server-side validation |
| Minimum dimensions | 300 × 300 px | Server-side validation (to be enforced in migration 043 handler) |
| Maximum dimensions | 4096 × 4096 px | Server-side resize (resize to max on ingest) |

### 7.3 Functional Requirements

| ID | Requirement |
|---|---|
| PSF-6.1 | Display a reorderable grid of current photos. Empty slots show an "Add photo" add-icon tile. |
| PSF-6.2 | Tapping an empty slot shows a bottom sheet with Gallery and Camera options. |
| PSF-6.3 | Only one photo pick/upload operation may run at a time (`_isPickingPhoto` guard). |
| PSF-6.4 | After selection, upload photo via `POST /v1/media/upload` (multipart). On success, refresh the draft's photo list. |
| PSF-6.5 | Each photo displays a delete icon (×). Tapping it calls `DELETE /v1/profile/{userId}/photos/{photoId}` and removes the file from the server filesystem. |
| PSF-6.6 | Photos are **reorderable** via long-press drag. On drop, `PATCH /v1/profile/{userId}/photos/reorder` is called with new ordering. |
| PSF-6.7 | The first photo (ordering = 0) is the primary and is marked with a crown / star badge. |
| PSF-6.8 | Tapping any non-first photo shows a "Set as primary" option which moves it to position 0 via reorder. |
| PSF-6.9 | The "Next" button is disabled until `minPhotos` (2) photos are uploaded. |
| PSF-6.10 | If upload attempt exceeds `maxPhotos` (5), show SnackBar "You can upload up to 5 photos only." and abort without navigating to picker. |
| PSF-6.11 | Upload progress indicator is shown per photo slot during active upload. |
| PSF-6.12 | On upload failure, the slot reverts to empty and an error SnackBar appears. |
| PSF-6.13 | Screen pre-loads existing photos from the draft on entry. |
| PSF-6.14 | Navigating back removes no photos already uploaded (photos are persisted). |
| PSF-6.15 | Step indicator shows "2 of 4". Back arrow navigates to Screen 5. |
| PSF-6.16 | Photo is rendered from `file://` URI immediately after selection (before upload completes) using `Image.file` for optimistic preview. On upload success/failure, the preview is updated. |
| PSF-6.17 | The "Next" button uses the `GlassButton` component with `shinyEffect: true`, `textColor: AppTheme.textDark`, and `fontWeight: FontWeight.w800` — consistent with the welcome screen and other primary CTAs in the app. `ElevatedButton` is **not** used for this CTA. |

### 7.4 Acceptance Criteria

| AC# | Criterion |
|---|---|
| AC-6.1 | Given 0 photos → Next button is disabled (greyed). |
| AC-6.2 | Given 1 photo → Next button still disabled. |
| AC-6.3 | Given 2 photos → Next button becomes active. |
| AC-6.4 | Given 5 photos → Add tile is hidden or tapping it shows "limit reached" snack. |
| AC-6.5 | Given user selects a 15 MB image → BFF rejects with 413; SnackBar "Photo too large (max 10 MB)."; slot remains empty. |
| AC-6.6 | Given user selects a PDF file → BFF rejects with 415; SnackBar "Unsupported format."; slot remains empty. |
| AC-6.7 | Given valid image selected → upload happens → thumbnail appears in slot with primary badge on first slot. |
| AC-6.8 | Given user taps ×  on a photo → confirmation dialog (optional) → photo deleted from server → slot becomes empty. |
| AC-6.9 | Given user drags photo from slot 3 to slot 1 → reorder API called → slot 1 gets primary badge. |
| AC-6.10 | Given network drops mid-upload → photo upload fails → slot reverts → SnackBar "Photo upload failed. Please try again." |
| AC-6.11 | Given user taps "Set as primary" on photo 3 → photo moves to slot 1 → primary badge updates. |
| AC-6.12 | Given user returns to Screen 6 after going to Screen 7 → all previously uploaded photos are visible. |
| AC-6.13 | Given HEIC image selected from iOS device → server converts / validates → accepted. |
| AC-6.14 | The "Next" button renders with the `GlassButton` gold-shiny-gradient style — identical visual weight and treatment to the welcome screen's primary CTA. Not an `ElevatedButton`. |
| AC-6.15 | The Gallery and Camera picker buttons inside the "Choose source" card also use `GlassButton` (without `shinyEffect`) for visual consistency within the screen. |

### 7.5 Edge Cases

| Edge Case | Expected Behaviour |
|---|---|
| User taps add while previous upload in progress | `_isPickingPhoto` guard prevents second picker open. |
| User picks identical photo twice | Second upload creates a separate photo record (different UUID). |
| Delete last remaining photo (1 remaining) | Photo deleted; Next button disables again. |
| Reorder while upload in progress | Reorder queued / disabled until in-flight upload resolves. |
| App backgrounded mid-upload | On return, if upload was completed in background, photo appears. If failed, error is shown. |
| All 5 slots filled; user tries to add via camera | Blocked by counter check before opening camera. |
| Server filesystem full | BFF returns 507; SnackBar "Server storage full. Please contact support." |
| Photo with 0-byte size | Rejected by BFF with 400; SnackBar "Invalid photo file." |
| Photo with special characters in filename | Sanitized by BFF to `{photo_id}.{ext}`; original name stored in `original_filename` column. |
| User deletes then re-uploads same image | Treated as a new upload; new UUID assigned. |
| Device has no camera | Camera option hidden in bottom sheet if `!kIsWeb && Platform.isAndroid && !hasCameraPermission`. |

### 7.6 Test Scenarios

| TC# | Scenario | Input | Expected Result |
|---|---|---|---|
| TC-6.1 | Upload 2 photos | Select 2 JPEGs from gallery | Both appear; Next active |
| TC-6.2 | Upload 5 photos | Select 5 JPEGs | All appear; Add tile hidden |
| TC-6.3 | Try to add 6th | 5 already present, tap add | SnackBar "limit reached" |
| TC-6.4 | Delete a photo | Tap × on photo 2 | Photo removed; slot empty; Next still active (2→1? check if drops below min) |
| TC-6.5 | Oversized photo | Select 12 MB JPEG | Upload rejected; SnackBar 413 error |
| TC-6.6 | Wrong format | Select PNG with wrong header | BFF rejects 415 |
| TC-6.7 | Reorder | Drag slot 3 to slot 1 | Slot 1 gets primary badge; reorder API called |
| TC-6.8 | Set primary | Tap "Set as primary" on slot 2 | Slot 2 moves to position 1 |
| TC-6.9 | Network fail upload | Airplane mode, try upload | SnackBar error; slot reverts |
| TC-6.10 | Resume photos | Navigate back then forward | All photos persist |
| TC-6.11 | Next button theme | Render Screen 6 | Next button uses gold shiny GlassButton, not flat ElevatedButton |

---

## 8. Screen 7 — SetupAboutScreen (Step 3 of 4)

**File**: `app/lib/features/profile/screens/setup/setup_about_screen.dart`

### 8.1 Purpose
Collects extended profile details: bio (required for completion), height, education, profession, income, lifestyle attributes (drinking, smoking), and religion. All data is persisted to draft.

### 8.2 Field Specification

| Field | Type | Required | Constraints |
|---|---|---|---|
| Bio | Multiline text | Yes | Min 10 chars, Max 500 chars. |
| Height | Integer dropdown (cm) | No | Range: 100–250 cm. Null if skipped. |
| Education | Single-select dropdown | No | Options from `PreferenceMasterData.educationLevels`. |
| Profession | Text input | No | Max 100 chars. Free text. |
| Income Range | Single-select dropdown | No | Options from `PreferenceMasterData.incomeRanges`. |
| Drinking | Single-select | Yes (default = 'Never') | Options: Never, Socially, Regularly. |
| Smoking | Single-select | Yes (default = 'Never') | Options: Never, Socially, Regularly. |
| Religion | Single-select dropdown | No | Options from `PreferenceMasterData.religions`. |

> **Note on Master Data**: All dropdown options are loaded from `preferenceMasterDataProvider` which fetches from `GET /v1/profile/master-data`. No option list is hardcoded in UI code. The provider falls back to offline dataset (`india_master_data.dart`) when network is unavailable.

### 8.3 Functional Requirements

| ID | Requirement |
|---|---|
| PSF-7.1 | Pre-populate all fields from the saved draft on entry. `_didInitialize` flag prevents re-overwriting user edits on provider rebuild. |
| PSF-7.2 | Validate bio length on "Next" tap. If bio < 10 chars, show SnackBar with error; do not navigate. |
| PSF-7.3 | Save `bio`, `height_cm`, `education`, `profession`, `income_range` via `saveAbout()` first. |
| PSF-7.4 | Save `drinking`, `smoking`, `religion` via `saveLifestyle()` second. Both calls must succeed for navigation to proceed. |
| PSF-7.5 | If any save call fails, show SnackBar and remain on Screen 7. Form state is preserved. |
| PSF-7.6 | Step indicator shows "3 of 4". Back navigates to Screen 6. |
| PSF-7.7 | Keyboard dismisses on drag. Bottom padding adjusts dynamically. |
| PSF-7.8 | "Next" button shows loading indicator during save and is disabled until save completes. |
| PSF-7.9 | Master data dropdowns must be populated before the form is interactive. While loading, show inline spinner. If offline, use cached data silently. |
| PSF-7.10 | All optional fields are visually marked "(optional)" in their labels. |
| PSF-7.11 | **Auto-save on Back**: when the user presses the back button (hardware or gesture) from Screen 7, the screen wraps navigation in `PopScope.onPopInvokedWithResult` and fires a fire-and-forget `saveAbout` + `saveLifestyle` call using the current form values. This ensures that if the user re-enters Screen 7 (new widget instance), their latest edits are pre-populated from the updated draft. |
| PSF-7.12 | The auto-save on Back is only triggered if `_didInitialize == true` (form was loaded and user may have edited). If the form was never initialised (draft still loading), no auto-save is attempted. |

### 8.4 Acceptance Criteria

| AC# | Criterion |
|---|---|
| AC-7.1 | Given bio = 9 chars → tap Next → SnackBar "Bio must be at least 10 characters." |
| AC-7.2 | Given bio = 10 chars → validation passes; save proceeds. |
| AC-7.3 | Given bio = 500 chars → validation passes. |
| AC-7.4 | Given bio = 501 chars → character counter shows limit reached; additional chars not accepted by text field. |
| AC-7.5 | Given no height selected → save proceeds with `height_cm = null`. |
| AC-7.6 | Given all optional fields blank → only bio is required; save succeeds with nulls for optionals. |
| AC-7.7 | Given drinking = "Regularly" selected → saved correctly. |
| AC-7.8 | Given API error on `saveAbout` → SnackBar shown; `saveLifestyle` NOT called; form values preserved. |
| AC-7.9 | Given master data API fails + offline → dropdown shows cached options from `india_master_data.dart`. |
| AC-7.10 | Given user navigates back to Screen 7 → all previously saved values are pre-filled. |
| AC-7.11 | Given profession = "Software Engineer" (exactly 100 chars) → accepted. |
| AC-7.12 | Given user fills bio and height, then presses Back (without saving) → navigates to Screen 6 → navigates forward to Screen 7 again → all previously entered values (bio, height, education, drinking, smoking, religion, profession, income) are **pre-filled** from the auto-saved draft. |
| AC-7.13 | Given user fills bio = "I love hiking" (13 chars) and presses Back → bio is persisted to draft via auto-save → a new Screen 7 instance loaded from draft shows bio = "I love hiking". |
| AC-7.14 | Given `_didInitialize == false` (draft still loading when Back is pressed) → **no** auto-save call is made (guard prevents writing empty values). |

### 8.5 Edge Cases

| Edge Case | Expected Behaviour |
|---|---|
| User fills multiple fields then presses Back | `PopScope.onPopInvokedWithResult` fires `saveAbout` + `saveLifestyle` with current field values; new Screen 7 instance loads from draft and shows those values. |
| User presses Back before draft loads (`_didInitialize == false`) | Auto-save guard (`if (!_didInitialize) return`) prevents empty writes to draft. |
| Auto-save API call fails (network drop during back-nav) | Fire-and-forget; no user-visible error. On next entry, draft shows last *successfully* saved values. |
| Bio = only whitespace (e.g., 15 spaces) | Trimmed to empty; auto-save does not fire (bio.isEmpty check). On next entry, bio field is blank. |
| Bio contains only emoji | Valid if emoji count reaches effective char count of ≥ 10 Unicode code points. |
| Height = 100 (minimum) | Accepted. |
| Height = 99 | Dropdown maximum enforces 100+; rejected. |
| Height = 250 (maximum) | Accepted. |
| Religion options not loaded yet | Dropdown shows loading spinner; tapping it does nothing until loaded. |
| User clears bio that was previously saved | On submit, validation re-runs; save blocked. |
| `saveAbout` succeeds but `saveLifestyle` fails | Draft has partially new state; user sees SnackBar; can retry. |
| Master data returns empty list for religions | Dropdown shows "(None / prefer not to say)" only. |
| Profession text with line breaks | Stripped to single line by `trim()` and newline removal. |

### 8.6 Test Scenarios

| TC# | Scenario | Input | Expected Result |
|---|---|---|---|
| TC-7.1 | Valid bio only | Bio="I love hiking" | Save succeeds; navigate to Screen 8 |
| TC-7.2 | Short bio | Bio="Hi" | SnackBar "Bio must be at least 10 characters." |
| TC-7.3 | All fields complete | All fields filled | Both save calls succeed; navigate to Screen 8 |
| TC-7.4 | Empty bio submit | Bio="" | SnackBar validation error |
| TC-7.5 | Bio with only spaces | Bio="          " | Trimmed → fails validation |
| TC-7.6 | Offline master data | No network | Dropdowns populated from cached data |
| TC-7.7 | Max bio length | Bio = exactly 500 chars | Accepted |
| TC-7.8 | saveAbout fails | API 500 | SnackBar; saveLifestyle not called |
| TC-7.9 | saveLifestyle fails | saveAbout OK, saveLifestyle 500 | SnackBar; user on Screen 7 |
| TC-7.10 | Resume with data | Draft has height=170 | Height dropdown pre-selected to 170 |
| TC-7.11 | Load indicator on dropdowns | Master data loading | Spinner shown inside dropdown until loaded |
| TC-7.12 | Back nav data retention — bio | Bio="I love hiking", press Back, go forward | Bio="I love hiking" pre-filled on return |
| TC-7.13 | Back nav data retention — dropdowns | Height=170, Drinking=Socially, press Back, go forward | Height=170 and Drinking=Socially pre-filled |
| TC-7.14 | Back nav — profession | Profession="Engineer", press Back, go forward | Profession="Engineer" pre-filled |
| TC-7.15 | Back nav — no crash on fast back | Rapidly press Back before draft loads | No crash; no empty data written to draft |
| TC-7.16 | Back nav — offline | Fill bio, Back, go offline, go forward | Bio still pre-filled (auto-save may have failed but draft was previously saved) |

---

## 9. Screen 8 — SetupPreviewScreen (Step 4 of 4)

**File**: `app/lib/features/profile/screens/setup/setup_preview_screen.dart`

### 9.1 Purpose
Shows the user a read-only preview of their assembled profile exactly as it will appear to other users. Provides a photo carousel (swipeable), name + age, bio, and attribute chips. The "Complete Profile" CTA finalises onboarding.

### 9.2 Functional Requirements

| ID | Requirement |
|---|---|
| PSF-8.1 | Display a full-screen photo carousel at the top. Photos are loaded from `draft.photos` using `file://` URIs for locally-cached photos and HTTP URLs for server-returned URLs. |
| PSF-8.2 | Display page indicator dots below the carousel (one dot per photo, current photo highlighted). |
| PSF-8.3 | Display name, age (computed from DOB), and gender below the carousel. |
| PSF-8.4 | Display bio in a styled card. |
| PSF-8.5 | Display attribute chips for: height, education, profession, drinking, smoking, religion (only chips where value is non-null/non-empty are shown). |
| PSF-8.6 | A "Complete Profile" button at the bottom. Disabled while `_isCompleting` is true. |
| PSF-8.7 | On tap, run client-side validation: check name ≥ 2 chars, DOB not null, photos ≥ 2, bio ≥ 10 chars. If any check fails, show SnackBar with specific error and abort. |
| PSF-8.8 | On validation pass, call `POST /profile/{userId}/complete` via `ProfileSetupNotifier.completeProfile()`. |
| PSF-8.9 | On success: (1) set `mainNavigationIndexProvider = 0`, (2) call `Navigator.pushAndRemoveUntil(MainNavigationScreen, (r) => false)` — this replaces the entire route stack with `MainNavigationScreen` so the user lands directly on the Discover tab without any intermediate bouncing through `ProfileSetupEntryScreen`. |
| PSF-8.10 | The setup wizard routes (Screens 4–7) are **removed** from the Navigator stack on completion. The user cannot press Back to return to the setup wizard from the Discover tab. |
| PSF-8.10a | The BFF `completeProfile` handler persists `ProfileCompletion = 100` to the durable `profile_drafts` repository via `upsertDraft` before returning — ensuring profile completion state survives a BFF restart. |
| PSF-8.11 | On API failure (DioException), extract `message` from error response body and show in SnackBar. |
| PSF-8.12 | On generic exception, show SnackBar "Something went wrong. Please try again." |
| PSF-8.13 | Step indicator shows "4 of 4". Back navigates to Screen 7. |
| PSF-8.14 | Tapping Back from Screen 8 returns to Screen 7 with Screen 7 state intact (draft values preserved). Only pressing the "Complete Profile" CTA triggers the complete API. |
| PSF-8.14a | Going Back and returning to Screen 8 must **not** re-trigger `completeProfile`. The button is only active when tapped by the user. |
| PSF-8.15 | After completion, the `user_management.user_settings` default row is created by the BFF if it does not already exist. |
| PSF-8.16 | After completion, an `activity_event` row is emitted: `{ event_type: "profile_completed", user_id, ... }` to `matching.activity_events` for analytics. |

### 9.3 Acceptance Criteria

| AC# | Criterion |
|---|---|
| AC-8.1 | Given complete valid draft → "Complete Profile" tapped → API called → **navigate directly to `MainNavigationScreen` (Discover tab) without passing through `ProfileSetupEntryScreen`**; route stack is cleared (no back button to setup). |
| AC-8.2 | Given bio missing (length < 10) → "Complete Profile" tapped → SnackBar "Bio must be at least 10 characters." No API call. |
| AC-8.3 | Given fewer than 2 photos → SnackBar "At least 2 photos are required." No API call. |
| AC-8.4 | Given name missing → SnackBar "Name is required." No API call. |
| AC-8.5 | Given DOB null → SnackBar "Date of birth is required." No API call. |
| AC-8.6 | Given API returns 422 with body `{"message":"Age below minimum."}` → SnackBar shows "Age below minimum." |
| AC-8.7 | Given API returns 5xx → SnackBar "Server error. Please try again later." `_isCompleting` resets to false. |
| AC-8.8 | Given no network → SnackBar "Network error. Please check your connection." |
| AC-8.9 | Given `_isCompleting` is true (in-flight) → second tap on "Complete Profile" does nothing. |
| AC-8.10 | Given 1 photo (primary) and bio set → "Complete Profile" disabled / blocked. |
| AC-8.11 | Photo carousel swipes correctly between photos. Page dots update. |
| AC-8.12 | `file://` URI photos render using `Image.file()`. |
| AC-8.13 | HTTP URL photos render using `Image.network()`. |
| AC-8.14 | Photo load error (broken URL) renders placeholder icon. |
| AC-8.15 | Age chip shows computed age: `floor((today - DOB) / 365.25)`. |
| AC-8.16 | Optional fields with null values (e.g., religion = null) are NOT shown as empty chips. |
| AC-8.17 | Given completion succeeds → hardware/gesture Back from Discover tab does **not** return the user to any setup wizard screen. |
| AC-8.18 | Given BFF restarts after a user completes their profile → on next app launch the profile is still recognised as complete (completion persisted to `profile_drafts` via `upsertDraft`). |
| AC-8.19 | Given completion API succeeds → `mainNavigationIndexProvider` is set to 0 (Discover tab) before navigation, ensuring the correct tab is active on launch. |

### 9.4 Edge Cases

| Edge Case | Expected Behaviour |
|---|---|
| User completes profile, then re-enters setup from settings | Flow runs; "Complete Profile" calls upsert (idempotent). |
| User completes profile but BFF restarts before next app launch | `ProfileCompletion = 100` was persisted to `profile_drafts` by `upsertDraft`; `profileCompletionProvider` reads from DB and finds `profileCompletion >= 100`; user routed to Discover. |
| User taps complete while app is backgrounding | Safe — `mounted` check prevents navigation on unmounted widget. |
| Photo URL returns 404 | Placeholder icon shown. No crash. |
| DOB shows user is exactly 18 | Age chip shows "18". Accepted. |
| Draft has photos but they were deleted server-side | Photo URL returns 404; placeholder shown; completion still proceeds (client validation only checks count from draft). |
| User races two simultaneous "Complete" taps | `_isCompleting` guard prevents duplicate API call. |
| API returns `profile_completed_at` already set (double complete) | Idempotent — no error. Navigate to main screen. |
| App crashes during complete API call | On next launch, draft still exists (not deleted). User re-enters Screen 8. |
| Network drops exactly mid-complete call | DioException caught; SnackBar shown; `profile_completed_at` not set; user retries. |

### 9.5 Test Scenarios

| TC# | Scenario | Input | Expected Result |
|---|---|---|---|
| TC-8.1 | Happy path complete | All valid draft | API called; navigate to Discover |
| TC-8.2 | Missing photos | 1 photo only | SnackBar "At least 2 photos are required." |
| TC-8.3 | Missing bio | Bio="" | SnackBar "Bio must be at least 10 characters." |
| TC-8.4 | Missing name | Name="" | SnackBar "Name is required." |
| TC-8.5 | API 422 error | Server returns invalid-age | SnackBar with server message |
| TC-8.6 | API 500 error | Server 500 | SnackBar network/server error |
| TC-8.7 | Double tap | Tap Complete twice fast | Only 1 API call |
| TC-8.8 | Photo carousel | 5 photos in draft | Swipe through all 5; dots update |
| TC-8.9 | Broken photo URL | photo_url returns 404 | Placeholder shown; no crash |
| TC-8.10 | All optional chips null | height=null, religion=null | No empty chips displayed |
| TC-8.11 | Back from Screen 8 | Tap back | Return to Screen 7; draft intact |
| TC-8.12 | Re-complete | Second complete call | Idempotent OK; navigate to Discover |
| TC-8.13 | No back to setup after completion | Complete → Discover → press hardware Back | App exits or goes to home launcher; setup screens not in stack |
| TC-8.14 | BFF restart durability | Complete → restart backend → reopen app | Profile still shown as complete; user goes directly to Discover |
| TC-8.15 | Correct tab on completion | Complete Profile tapped | `mainNavigationIndexProvider == 0`; Discover tab is selected, not Matches/Chat |

---

## 10. Cross-Cutting Concerns

### 10.1 Draft Persistence Strategy

| Event | Action |
|---|---|
| Screen 5 Next tapped | `PATCH /profile/{userId}/draft` with `{name, date_of_birth, gender}` |
| Screen 6 each photo uploaded | `POST /v1/media/upload` + photo record created; draft `current_step` updated to 2 |
| Screen 7 Next tapped | `PATCH /profile/{userId}/draft` with `{bio, height_cm, education, profession, income_range, drinking, smoking, religion}`; `current_step = 3` |
| Screen 8 Complete tapped | `POST /profile/{userId}/complete`; `current_step = 4`; `profile_completed_at` set |

### 10.2 Step Resume Logic (Backend)
`GET /profile/{userId}/draft` returns `current_step`. The entry screen should navigate directly to the step's screen:

```
current_step → Screen
1            → SetupBasicInfoScreen
2            → SetupPhotosScreen
3            → SetupAboutScreen
4 (complete) → MainNavigationScreen (bypass setup)
```

> **Note**: This step-resume routing is a planned improvement. Currently the entry screen always routes to Screen 5. The BRD recommends implementing direct-step routing in the next iteration.

### 10.3 Progress Computation (Client-side)

```dart
int get profileCompletionPercent {
  // Scored out of 6:
  // 1) name ≥ 2 chars
  // 2) dateOfBirth ≠ null
  // 3) photos ≥ 2
  // 4) bio ≥ 10 chars
  // 5) always +1 (gender always provided)
  // 6) drinking + smoking both non-empty
  → returns 0–100 rounded
}
```

Progress bar shown in `SetupHeader` widget.

### 10.4 Error Handling Matrix

| HTTP Status | UI Behaviour |
|---|---|
| 400 Bad Request | SnackBar with server `message` field |
| 401 Unauthorized | Token refresh → if fail, redirect to login |
| 404 Not Found | SnackBar "Resource not found" |
| 409 Conflict | SnackBar "This action has already been completed." (idempotency hit) |
| 413 Payload Too Large | SnackBar "Photo too large (max 10 MB)." |
| 415 Unsupported Media Type | SnackBar "Unsupported photo format." |
| 422 Unprocessable Entity | SnackBar with `message` from response body |
| 429 Too Many Requests | SnackBar "Too many requests. Please wait." |
| 500 / 502 / 503 | SnackBar `ErrorMessages.serverError` |
| Timeout / No network | SnackBar `ErrorMessages.networkError` |

### 10.5 Idempotency

- All `PATCH /profile/{userId}/draft` calls include `Idempotency-Key: {UUID}` generated per save attempt.
- `POST /profile/{userId}/complete` is idempotent server-side: if `profile_completed_at` is already set, return 200 with existing data.
- `POST /v1/media/upload` is **not idempotent** — duplicate uploads create separate photo records.

### 10.6 Accessibility Requirements

- All interactive elements must have a semantic `label` for screen readers.
- Gender selector chips and lifestyle dropdowns must be keyboard-navigable.
- Photo slots must have `Semantics(label: "Photo slot {n}")`.
- Error SnackBars must be announced by screen readers (`assertive` role).
- Minimum tap target size: 44 × 44 dp.

### 10.7 Security Requirements

- Photo uploads: BFF validates MIME type from file header (not just extension). No executable files accepted.
- Photo filenames: Sanitized to `{UUID}.{ext}` on server. Original filename stored in `original_filename` column only.
- Draft PATCH: Authenticated endpoint. `userId` extracted from JWT, not from request body.
- Complete endpoint: Authenticated. BFF verifies `userId` matches the JWT subject.
- Bio content: Length-validated. No server-side HTML/script sanitization in v1 MVP (planned for v2 content moderation pass).

---

## 11. Validation Rule Registry

| Rule ID | Field | Condition | Error Message |
|---|---|---|---|
| VR-01 | Name | `trim().length < 2` | "Name must be at least 2 characters." |
| VR-02 | Name | `trim().length > 50` | "Name must be 50 characters or fewer." |
| VR-03 | Date of Birth | `null` | "Please select your date of birth." |
| VR-04 | Date of Birth | Age < 18 years | "You must be at least 18 years old." |
| VR-05 | Date of Birth | Age > 80 years | "Please enter a valid date of birth." |
| VR-06 | Bio | `trim().length < 10` (if provided) | "Bio must be at least 10 characters." |
| VR-07 | Bio | `trim().length > 500` | "Bio must be 500 characters or fewer." |
| VR-08 | Photos | `photos.length < 2` | "At least 2 photos are required." |
| VR-09 | Photos | `photos.length > 5` | "You can upload up to 5 photos only." |
| VR-10 | Photo size | `sizeBytes > 10 × 1024² ` | "Photo too large (max 10 MB)." |
| VR-11 | Photo MIME | Not jpeg/png/heic | "Unsupported photo format." |
| VR-12 | Height | `heightCm < 100 OR heightCm > 250` | "Please enter a valid height." |
| VR-13 | Profession | `trim().length > 100` | "Profession must be 100 characters or fewer." |
| VR-14 | Gender | Not in ('M','F','Other') | "Please select a gender." |

---

## 12. Non-Functional Requirements

| NFR | Requirement |
|---|---|
| NFR-1 Performance | Each screen must become interactive within 1 second on mid-range Android device (Pixel 5). |
| NFR-2 Photo upload | Photo upload P95 latency ≤ 3 s for a 5 MB JPEG over WiFi. |
| NFR-3 Draft save | Draft PATCH round-trip ≤ 500 ms on local dev; ≤ 1.5 s on 50 Mbps 4G conn. |
| NFR-4 Offline resume | Draft is readable from local provider cache even when network is unavailable. |
| NFR-5 Storage | BFF must reject uploads if available disk space < 500 MB (configurable threshold). |
| NFR-6 Retention | Profile photos stored indefinitely unless user deletes or account is deactivated. |
| NFR-7 Data compliance | DOB is stored as `DATE` (not `TIMESTAMP`). No timezone ambiguity. |
| NFR-8 Observability | Every setup step completion emits a structured log event with `user_id`, `step`, `correlation_id`. |
| NFR-9 Crash-free | Zero crashes on the happy-path setup flow (measured by test suite and device testing). |
| NFR-10 Connectivity | App handles: no network, slow network (< 1 Mbps), network drop mid-request — all produce recoverable UI states. |

---

## 13. Open Questions & Decisions

| OQ# | Question | Owner | Status |
|---|---|---|---|
| OQ-1 | Should the system navigate directly to the saved step on resume, or always start from Step 1? | Product | ⏳ Pending — current implementation always starts from Step 1 (SetupBasicInfoScreen). Direct-step routing is a planned improvement noted in Section 10.2. |
| OQ-2 | Is a confirmation dialog required before deleting a photo? | UX | ⏳ Pending |
| OQ-3 | Should bio be required at Step 1 (basic info) or only at Step 3 (about)? Currently only enforced at Step 3. | Product | ✅ Resolved — bio is optional at Step 1; required (≥ 10 chars) only at Step 3 (SetupAboutScreen) and Step 4 completion validation. |
| OQ-4 | What is the minimum screen resolution / camera quality for acceptable photo dimensions (300×300 px min)? | Product | ⏳ Pending |
| OQ-5 | Should a draft be preserved after `CompleteProfile` succeeds, or deleted? | Engineering | ⏳ Pending — recommendation: preserve for 30 days as safety net |
| OQ-6 | Is HEIC format mandatory support or optional? | Engineering / iOS | ⏳ Pending |
| OQ-7 | Should `activity_events` emit on each step completion (not just final complete)? | Product Analytics | ⏳ Pending |
| OQ-8 | Should the preview screen allow inline editing (tap a chip → go back to that step)? | Product / UX | ⏳ Pending |
| OQ-9 | Disk space limit enforcement: what is the per-user quota for local photos? | Engineering | ⏳ Pending — suggestion: 50 MB per user |

---

*End of BRD-PSF-001 v1.0*
