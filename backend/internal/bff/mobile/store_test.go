package mobile

import (
	"testing"

	"github.com/verified-dating/backend/internal/platform/config"
)

func TestMemoryStore_VerificationWorkflow(t *testing.T) {
	store := newMemoryStore(defaultTestConfig())

	state := store.submitVerification("user-1")
	if state.Status != "pending" {
		t.Fatalf("expected pending status, got %q", state.Status)
	}
	if state.SubmittedAt == "" {
		t.Fatalf("expected submitted timestamp")
	}

	reviewed, err := store.reviewVerification("user-1", "approved", "", "admin-1")
	if err != nil {
		t.Fatalf("reviewVerification error = %v", err)
	}
	if reviewed.Status != "approved" {
		t.Fatalf("expected approved status, got %q", reviewed.Status)
	}
	if reviewed.ReviewedBy != "admin-1" {
		t.Fatalf("expected reviewed by admin-1, got %q", reviewed.ReviewedBy)
	}

	items := store.listVerifications("approved", 10)
	if len(items) != 1 {
		t.Fatalf("expected 1 verification, got %d", len(items))
	}
	if items[0].UserID != "user-1" {
		t.Fatalf("expected user-1 verification")
	}
}

func TestMemoryStore_ActivityFeedLimitAndOrder(t *testing.T) {
	store := newMemoryStore(defaultTestConfig())

	store.recordActivity(activityEvent{
		UserID:   "user-1",
		Actor:    "system",
		Action:   "POST /v1/auth/send-otp",
		Status:   "success",
		Resource: "/v1/auth/send-otp",
	})
	store.recordActivity(activityEvent{
		UserID:   "user-2",
		Actor:    "system",
		Action:   "POST /v1/auth/verify-otp",
		Status:   "success",
		Resource: "/v1/auth/verify-otp",
	})

	items := store.listActivities(1)
	if len(items) != 1 {
		t.Fatalf("expected 1 activity item, got %d", len(items))
	}
	if items[0].Action != "POST /v1/auth/verify-otp" {
		t.Fatalf("expected latest activity first, got %q", items[0].Action)
	}
	if items[0].ID == "" {
		t.Fatalf("expected activity id")
	}
}

func TestMemoryStore_RecordActivityAddsExperimentDimensions(t *testing.T) {
	cfg := defaultTestConfig()
	cfg.FeatureExperimentFramework = true
	cfg.FeatureExperimentMatchNudge = true
	cfg.ExperimentMatchNudgeRolloutPct = 100
	store := newMemoryStore(cfg)

	store.recordActivity(activityEvent{
		UserID: "user-exp-1",
		Actor:  "user-exp-1",
		Action: "POST /v1/engagement/match-nudges",
		Status: "success",
	})

	items := store.listActivities(1)
	if len(items) != 1 {
		t.Fatalf("expected 1 activity item, got %d", len(items))
	}
	variant, _ := items[0].Details["exp_match_nudge_variant"].(string)
	if variant != "treatment" {
		t.Fatalf("expected treatment variant with 100 rollout, got %q", variant)
	}
	bucket, ok := items[0].Details["exp_match_nudge_bucket"].(int)
	if !ok || bucket < 0 || bucket > 99 {
		t.Fatalf("expected bucket in [0,99], got %v", items[0].Details["exp_match_nudge_bucket"])
	}
}

func TestAssignExperimentVariant_Deterministic(t *testing.T) {
	first := assignExperimentVariant("user-exp-deterministic", "match_nudge_timing_v1", 50)
	second := assignExperimentVariant("user-exp-deterministic", "match_nudge_timing_v1", 50)

	if first.Bucket != second.Bucket || first.Variant != second.Variant {
		t.Fatalf("expected deterministic assignment, first=%+v second=%+v", first, second)
	}
}

func defaultTestConfig() config.Config {
	return config.Config{
		MockPhotoSeedURLTemplate: "https://picsum.photos/seed/%s/720/960",
		MockBlockedPhotoTemplate: "https://picsum.photos/seed/%s/200/200",
	}
}
