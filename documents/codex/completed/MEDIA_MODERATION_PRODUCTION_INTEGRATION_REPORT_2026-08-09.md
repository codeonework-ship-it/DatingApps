# Media moderation production integration — 2026-08-09

## Outcome

The production integration is implemented with Amazon Rekognition as the selected image-moderation provider and Amazon S3 as the production object store. Local development remains fully native PostgreSQL and local filesystem based; it makes no Supabase, PostgREST, Docker, or external moderation connection.

## Runtime architecture

1. The BFF performs byte-signature, size, and dimension validation before moderation.
2. `MEDIA_MODERATION_PROVIDER=aws_rekognition` calls `DetectModerationLabels` for JPEG/PNG outside any database transaction.
3. High-confidence blocked labels are rejected before object persistence.
4. Borderline labels and provider-unsupported WebP/HEIC uploads are stored under a `quarantine/` namespace with `review_required` status.
5. Approved uploads are stored under an `approved/` namespace.
6. Public media delivery and matching queries expose only `approved` photos.
7. Authenticated `admin`, `trust_safety`, or `moderator` operators can list the queue, stream quarantined content, and approve/reject it.
8. Provider and operator decisions are written to the append-only `user_management.media_moderation_events` ledger.

## Default policy

- Provider floor: 50% confidence.
- Manual-review threshold: 70%.
- Automatic-rejection threshold: 90%.
- Reject categories: Explicit Nudity, Violence, Visually Disturbing, Hate Symbols, Drugs & Tobacco.
- Review categories: Suggestive, Weapons, Alcohol, Gambling, Rude Gestures.
- Production/staging fail startup when moderation is required but the provider is disabled.
- Provider errors fail closed with HTTP 503; they never produce silent approval.

All thresholds and category sets are environment-configurable. Changes should go through safety-policy approval and a labelled acceptance corpus.

## Format contract

| Format | Local validation | Rekognition path | Production outcome |
|---|---|---|---|
| JPEG | Accepted | Native provider scan | Approve, review, or reject |
| PNG | Accepted | Native provider scan | Approve, review, or reject |
| WebP | Accepted | Unsupported by provider | Quarantine for operator review |
| HEIC/HEIF | Accepted | Unsupported by provider | Quarantine for operator review |

This routing is deliberate: unsupported formats are never silently approved.

## PostgreSQL migration

Migration `062_media_moderation_production.sql` adds provider/model/label/confidence metadata, review states, partial queue/read indexes, and the immutable event ledger. The complete local migration chain was applied successfully to `127.0.0.1:55432/dating_app`.

The local migration runner separately records and approves digest-less catalog seed fixtures as `local_seed_fixture`. That exception exists only in the loopback local runner so seeded discovery thumbnails remain usable; the production migration continues to quarantine legacy unreviewed rows.

## Verification completed

- Go config, BFF, moderation-policy, OpenAPI contract, and matching tests pass.
- Flutter profile setup tests pass and the UI now labels media awaiting safety review.
- Django control-panel tests cover the authenticated binary media proxy and decision workflow.
- OpenAPI YAML documents the provider failure and operator review contracts.
- Local end-to-end acceptance passed:
  - quarantined public content returned 404;
  - authenticated operator content returned 200;
  - approved public content returned 200;
  - provider plus operator audit events were durable.

## Production activation

Set these secrets/configuration in the deployment environment (never in Git):

```text
FILE_STORAGE_BACKEND=aws_s3
AWS_S3_REGION=<region>
AWS_S3_BUCKET=<private bucket>
MEDIA_MODERATION_PROVIDER=aws_rekognition
MEDIA_MODERATION_REQUIRED=true
MEDIA_MODERATION_TEST_S3_KEY=<jpeg-or-png acceptance object>
```

Use an IAM role with only the required Rekognition and S3 permissions. Keep all four S3 public-access-block settings enabled. Run:

```bash
backend/scripts/media_moderation_production_preflight.sh
```

The preflight performs read-only bucket/object checks and a real `DetectModerationLabels` request, then reports the active moderation model version. It was not run against AWS in this workspace because no production role, bucket, or acceptance object was supplied.

## Policy limitation

Amazon Rekognition is a classification aid, not a complete illegal-content detection system. The manual queue, reporting path, and trained safety operators remain mandatory, and any legally required hash-matching/reporting workflow must be integrated separately with an appropriately authorized provider.
