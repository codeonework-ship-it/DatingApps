#!/usr/bin/env bash
set -euo pipefail

provider="${MEDIA_MODERATION_PROVIDER:-}"
required="${MEDIA_MODERATION_REQUIRED:-}"
storage_backend="${FILE_STORAGE_BACKEND:-}"
bucket="${AWS_S3_BUCKET:-}"
region="${AWS_S3_REGION:-}"
test_object="${MEDIA_MODERATION_TEST_S3_KEY:-}"
min_confidence="${MEDIA_MODERATION_MIN_CONFIDENCE:-50}"

[[ "$provider" == "aws_rekognition" ]] || { echo "MEDIA_MODERATION_PROVIDER must be aws_rekognition" >&2; exit 2; }
[[ "$required" == "true" ]] || { echo "MEDIA_MODERATION_REQUIRED must be true" >&2; exit 2; }
[[ "$storage_backend" == "aws_s3" ]] || { echo "FILE_STORAGE_BACKEND must be aws_s3" >&2; exit 2; }
[[ -n "$bucket" ]] || { echo "AWS_S3_BUCKET is required" >&2; exit 2; }
[[ -n "$region" ]] || { echo "AWS_S3_REGION is required" >&2; exit 2; }
[[ -n "$test_object" ]] || { echo "MEDIA_MODERATION_TEST_S3_KEY must reference a JPEG or PNG acceptance fixture" >&2; exit 2; }
command -v aws >/dev/null || { echo "aws CLI is required" >&2; exit 2; }
command -v jq >/dev/null || { echo "jq is required" >&2; exit 2; }

test_object_lower="$(printf '%s' "$test_object" | tr '[:upper:]' '[:lower:]')"
case "$test_object_lower" in
  *.jpg|*.jpeg|*.png) ;;
  *) echo "Rekognition acceptance fixture must be JPEG or PNG" >&2; exit 2 ;;
esac

aws s3api head-bucket --bucket "$bucket" --region "$region" >/dev/null
aws s3api get-public-access-block --bucket "$bucket" --region "$region" \
  | jq -e '.PublicAccessBlockConfiguration | .BlockPublicAcls and .IgnorePublicAcls and .BlockPublicPolicy and .RestrictPublicBuckets' >/dev/null
aws s3api head-object --bucket "$bucket" --key "$test_object" --region "$region" >/dev/null

result="$(aws rekognition detect-moderation-labels \
  --region "$region" \
  --image "S3Object={Bucket=$bucket,Name=$test_object}" \
  --min-confidence "$min_confidence")"
jq -e '.ModerationModelVersion | strings | length > 0' <<<"$result" >/dev/null

jq -n \
  --arg provider "$provider" \
  --arg bucket "$bucket" \
  --arg region "$region" \
  --arg object "$test_object" \
  --arg model_version "$(jq -r '.ModerationModelVersion' <<<"$result")" \
  --argjson returned_labels "$(jq '.ModerationLabels | length' <<<"$result")" \
  '{success:true,provider:$provider,bucket:$bucket,region:$region,test_object:$object,model_version:$model_version,returned_labels:$returned_labels,public_access_blocked:true}'
