# Third-party integrations — tracker

Last checked against the code: 2026-09-28 (AWS S3 row: 2026-10-01). Kept separate from the pending-work
backlog (`PENDING_FEATURE_BACKLOG.md`), which tracks our own code. This list
tracks every external service, vendor, SDK or hosted asset the product depends
on, and what each needs before it can be used in production.

**Status legend.** *Built*: adapter code exists and is tested locally.
*Partial*: works but a known piece is missing. *Not built*: named in config or
docs only. **Release** refers to the first release scope in
`contracts/release_contract.v1.json` (Connect Core closed beta).

## 1. Needed for the first release

| Integration | Used for | Code status | Release | What is still needed |
|---|---|---|---|---|
| **AWS S3** (optional; the default is local storage on the VPS under `/var/lib/connect/media`) | Object storage for every media kind (profile photos, chapter and theme photos, voice, ID documents/selfies, group covers) through one storage layer (`internal/platform/mediastore`). Separate config file `/etc/connect/storage.env` (`FILE_STORAGE_BACKEND=aws_s3`, `AWS_S3_*`: private + optional public bucket, per-kind prefixes, SSE-S3/SSE-KMS, presigned or proxied reads, auth by static key / shared profile / instance role / assume-role) | Built (SDK `aws-sdk-go-v2/service/s3` + `credentials/stscreds`); copy tool `mediactl`; tested against a fake S3 endpoint only | Needed only if S3 is chosen | Create bucket(s) with Block Public Access, ownership enforced, encryption, versioning + lifecycle (`deploy/aws/`); IAM user or role with the least-privilege policy; KMS key if SSE-KMS; run `mediactl check -probe`; restore and erasure-propagation evidence. Guide: `MEDIA_STORAGE_VPS_AND_S3_2026-10-01.md` |
| **AWS Rekognition** | Photo moderation (`MEDIA_MODERATION_PROVIDER=aws_rekognition`) | Built; startup fails in production without it | Needed | IAM, threshold tuning on a labelled image set, run `media_moderation_production_preflight.sh`; WebP/HEIC go to manual review |
| **SOS delivery vendor** | Delivering SOS alerts to trusted contacts (`SOS_DELIVERY_PROVIDER=webhook`) | Partial: generic signed webhook only; no direct SMS/voice adapter | Needed (SOS is enabled); production startup fails without a provider | **Choose a vendor** (SMS/voice), build its adapter or a webhook bridge, paging on missed acknowledgement, staffed response |
| **Paging / on-call** (e.g. PagerDuty, Opsgenie) | SOS and incident paging; Alertmanager routes | Not built: Alertmanager routes by severity only | Needed | Choose a tool, route `owner` labels, rehearse paging |
| **Operator identity provider** (SSO + 2-factor) | Control-panel sign-in (PEN-38) | Not built | Needed | Choose a provider, managed secrets, offboarding |

## 2. Built, but excluded from the first release

| Integration | Used for | Code status | What is still needed before enabling |
|---|---|---|---|
| **Stripe** | Card checkout, subscriptions, coin packages, refunds, disputes (`PAYMENTS_PROVIDER=stripe`, `STRIPE_*`) | Built; sandbox provider for local | Stripe account and keys, webhook endpoint, the 11-case test-mode matrix, payout/bank reconciliation, signed INR prices |
| **Apple In-App Purchase / Google Play Billing** | Selling coins inside the mobile apps | Not built (only listed as allowed wallet providers) | **Check store rules before selling coins in the apps**: Apple and Google generally require their own in-app purchase systems for digital goods. Stripe alone may not be acceptable for in-app coin sales |
| **Razorpay** | Alternative Indian payment provider (FUT-005) | Not built (only listed as an allowed wallet provider) | Decide whether it is needed alongside Stripe |
| **Jitsi (private deployment)** | Voice/video call rooms with short-lived JWTs (`CALL_TRANSPORT_PROVIDER=jitsi_jwt`) | Partial: token issuing built; development uses public meet.jit.si, which is blocked in production; calls open in the browser | Private Jitsi with JWT auth, confirm the token `sub` claim works with it, build accept/reject/missed/timeout states, paired-device tests |
| **Identity verification vendor** (eKYC / liveness) | ID document + selfie decisions (`IDENTITY_VERIFICATION_PROVIDER=webhook`) | Built as a generic webhook adapter; falls back to manual review | **Choose a vendor**, reviewer access, retention sign-off, labelled test set |
| **Voice moderation vendor** | Screening voice icebreakers before delivery (`VOICE_MODERATION_PROVIDER=webhook`) | Built as a generic webhook adapter | **Choose a vendor**, labelled test set, device record/playback tests |
| **Firebase Cloud Messaging** | Android push (`NOTIFICATION_PUSH_PROVIDER`, `NOTIFICATION_FCM_*`; Flutter `firebase_core`, `firebase_messaging`) | Built (direct HTTP v1 sender, invalid-token cleanup) | Firebase project, service account, `google-services.json` (not in repo), 12-case device push matrix |
| **Apple Push Notification service** | iOS push | Built (HTTP/2 sender with provider token) | APNs `.p8` key, `GoogleService-Info.plist` (not in repo), device matrix |
| **Giphy (hotlinked media)** | Gift animations (`gift_catalog.gif_url` → media.giphy.com) | Hotlinked URLs only, no API integration | Replace with licensed, self-hosted assets, or use the Giphy API with its terms and attribution |

## 3. Built, optional, inactive unless configured

| Integration | Used for | Code status | Release | What is still needed |
|---|---|---|---|---|
| **Anthropic Claude API** | Writing copilot drafts (`COPILOT_PROVIDER=claude`, `ANTHROPIC_API_KEY`, `COPILOT_MODEL` with default `claude-opus-5`) | Built (Go module `github.com/anthropics/anthropic-sdk-go` v1.75.0): adapter present, inactive unless configured; otherwise the copilot runs on the offline template provider, which is what local runs and tests use | Not release-excluded; the copilot ships on the template provider and Claude stays off until configured | Key management, spend cap, prompt review, data-processing terms. When switched on the adapter sends the partner's allowlisted public profile fields and the last six messages to the provider, so the privacy notice must say so first |

## 4. Supporting services and assets to clean up

| Item | Where | Issue | Action |
|---|---|---|---|
| **Supabase (hosted PostgREST mode)** | `repositoryDBFor`, `SUPABASE_*` config | Legacy data path still in code alongside native PostgreSQL | Decide: retire it, or keep and test it as a supported mode |
| **Unsplash placeholder photos** | `app_runtime_config.dart`, mock match/profile providers | Hotlinked stock photos; devices call a third party | Replace with bundled assets before release |
| **jsDelivr CDN + Google Fonts** | Control panel `base.html` (Bootstrap, icons, Chart.js, Inter font) | Operator console loads third-party scripts | Self-host, or add subresource integrity and a security review |
| **unpkg CDN** | API docs page (Swagger UI) | Third-party script on an internal page | Self-host, or restrict the docs page to internal use |
| **`google_fonts` Flutter package** | `app/pubspec.yaml` | Declared but unused | Remove the dependency |
| **Crash and error reporting — none (self-hosted)** | `POST /v1/client/errors`, `platform.client_error_*` (migration 122), app `lib/core/telemetry/`, console page "Client errors" | No crash-reporting vendor or SDK. Firebase Crashlytics, Sentry and similar are deliberately not used; the unused `ENABLE_CRASHLYTICS` / `ENABLE_ANALYTICS` app constants were removed (2026-10-01). Product analytics is computed server-side from our own tables | Keep it that way unless a vendor is reviewed and added here. Details: `CLIENT_ERROR_REPORTING_AND_PRIVACY_2026-10-01.md` |
| **Prometheus / Grafana / Alertmanager** | `backend/observability/` | Open-source, self-hosted; rules and dashboards exist but nothing is deployed | Deploy, connect paging, test alerts |

## Decisions needed

1. SOS delivery vendor (SMS/voice) and paging tool — **needed for the first release**.
2. Operator SSO/2-factor provider — **needed for the first release**.
3. Identity-verification vendor and voice-moderation vendor.
4. Mobile coin sales: store in-app purchase vs. Stripe.
5. Whether Razorpay is needed; whether Supabase mode is retired.
6. Gift animation source (licensed assets vs. Giphy API).
7. Whether to switch the writing copilot from the offline template provider to the Anthropic Claude API (key management, spend cap, prompt review, data-processing terms).
