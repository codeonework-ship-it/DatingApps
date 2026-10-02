package config

import (
	"os"
	"path/filepath"
	"testing"
)

func TestLoad_RequiresSupabaseConfig(t *testing.T) {
	t.Setenv("SUPABASE_URL", "")
	t.Setenv("SUPABASE_ANON_KEY", "")
	t.Setenv("SUPABASE_SERVICE_ROLE", "")

	_, err := Load()
	if err == nil {
		t.Fatalf("expected error when supabase env is missing")
	}
}

func TestLoad_UsesDefaultsAndNormalizesPrefix(t *testing.T) {
	t.Setenv("SUPABASE_URL", "https://example.supabase.co")
	t.Setenv("SUPABASE_ANON_KEY", "anon-key")
	t.Setenv("API_PREFIX", "v1/")
	t.Setenv("MOCK_DATA_ENABLED", "false")
	t.Setenv("API_GATEWAY_READ_HEADER_TIMEOUT_SEC", "-1")

	cfg, err := Load()
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}

	if cfg.APIPrefix != "/v1" {
		t.Fatalf("expected /v1 prefix, got %q", cfg.APIPrefix)
	}
	if cfg.MockDataEnabled {
		t.Fatalf("expected mock otp disabled")
	}
	if cfg.APIGatewayReadHeaderTimeoutSec != 10 {
		t.Fatalf("expected fallback timeout 10, got %d", cfg.APIGatewayReadHeaderTimeoutSec)
	}
	if cfg.MobileBFFUpstreamURL == "" {
		t.Fatalf("expected upstream url to be populated")
	}
	if cfg.FileStorageBackend != "local_fs" {
		t.Fatalf("expected local_fs storage backend, got %q", cfg.FileStorageBackend)
	}
}

func TestLoad_NormalizesAWSStorageBackend(t *testing.T) {
	t.Setenv("SUPABASE_URL", "https://example.supabase.co")
	t.Setenv("SUPABASE_ANON_KEY", "anon-key")
	t.Setenv("FILE_STORAGE_BACKEND", "s3")
	t.Setenv("AWS_S3_BUCKET", "verified-dating-media")
	t.Setenv("AWS_S3_PROFILE_PHOTOS_PREFIX", "/profile-photos/uploads/")

	cfg, err := Load()
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}

	if cfg.FileStorageBackend != "aws_s3" {
		t.Fatalf("expected aws_s3 storage backend, got %q", cfg.FileStorageBackend)
	}
	if !cfg.UseAWSS3Storage {
		t.Fatalf("expected UseAWSS3Storage to be true when aws backend is selected")
	}
	if cfg.AWSS3ProfilePhotosPrefix != "profile-photos/uploads" {
		t.Fatalf("expected normalized profile photos prefix, got %q", cfg.AWSS3ProfilePhotosPrefix)
	}
}

func TestLoad_RequiresBucketWhenAWSStorageEnabled(t *testing.T) {
	t.Setenv("SUPABASE_URL", "https://example.supabase.co")
	t.Setenv("SUPABASE_ANON_KEY", "anon-key")
	t.Setenv("USE_AWS_S3_STORAGE", "true")
	t.Setenv("AWS_S3_BUCKET", "")

	_, err := Load()
	if err == nil {
		t.Fatalf("expected error when aws storage is enabled without bucket")
	}
}

func TestLoad_RequiresModerationProviderWhenProductionModerationIsRequired(t *testing.T) {
	t.Setenv("SUPABASE_URL", "https://example.supabase.co")
	t.Setenv("SUPABASE_ANON_KEY", "anon-key")
	t.Setenv("ENVIRONMENT", "production")
	t.Setenv("MEDIA_MODERATION_PROVIDER", "disabled")

	_, err := Load()
	if err == nil {
		t.Fatalf("expected production configuration to fail without a moderation provider")
	}
}

func TestLoad_ConfiguresRekognitionModerationPolicy(t *testing.T) {
	t.Setenv("SUPABASE_URL", "https://example.supabase.co")
	t.Setenv("SUPABASE_ANON_KEY", "anon-key")
	t.Setenv("ENVIRONMENT", "production")
	t.Setenv("MEDIA_MODERATION_PROVIDER", "aws_rekognition")
	t.Setenv("MEDIA_MODERATION_REVIEW_CONFIDENCE", "65")
	t.Setenv("MEDIA_MODERATION_REJECT_CONFIDENCE", "92")
	t.Setenv("MEDIA_MODERATION_REJECT_LABELS", "Explicit Nudity,Hate Symbols")
	t.Setenv("IDENTITY_VERIFICATION_REQUIRED", "false")
	t.Setenv("VOICE_MODERATION_REQUIRED", "false")
	t.Setenv("SOS_DELIVERY_REQUIRED", "false")

	cfg, err := Load()
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}
	if cfg.MediaModerationProvider != "aws_rekognition" || !cfg.MediaModerationRequired {
		t.Fatalf("unexpected moderation configuration: provider=%q required=%t", cfg.MediaModerationProvider, cfg.MediaModerationRequired)
	}
	if cfg.MediaModerationReviewConfidence != 65 || cfg.MediaModerationRejectConfidence != 92 {
		t.Fatalf("unexpected moderation thresholds: review=%d reject=%d", cfg.MediaModerationReviewConfidence, cfg.MediaModerationRejectConfidence)
	}
	if len(cfg.MediaModerationRejectLabels) != 2 || cfg.MediaModerationRejectLabels[1] != "hate symbols" {
		t.Fatalf("unexpected rejection labels: %#v", cfg.MediaModerationRejectLabels)
	}
}

func TestLoad_RejectsIncompleteSignedCallTransport(t *testing.T) {
	t.Setenv("SUPABASE_URL", "https://example.supabase.co")
	t.Setenv("SUPABASE_ANON_KEY", "anon-key")
	t.Setenv("CALL_TRANSPORT_PROVIDER", "jitsi_jwt")
	t.Setenv("CALL_ROOM_BASE_URL", "https://meet.example.com")
	t.Setenv("CALL_JWT_ISSUER", "connect")
	t.Setenv("CALL_JWT_AUDIENCE", "meet")
	t.Setenv("CALL_JWT_SECRET", "short")

	if _, err := Load(); err == nil {
		t.Fatal("expected incomplete signed call transport to fail closed")
	}
}

func TestLoad_ForbidsPublicCallRoomsInProduction(t *testing.T) {
	t.Setenv("SUPABASE_URL", "https://example.supabase.co")
	t.Setenv("SUPABASE_ANON_KEY", "anon-key")
	t.Setenv("ENVIRONMENT", "production")
	t.Setenv("MEDIA_MODERATION_PROVIDER", "aws_rekognition")
	t.Setenv("CALL_TRANSPORT_PROVIDER", "public_jitsi")

	if _, err := Load(); err == nil {
		t.Fatal("expected public call rooms to be forbidden in production")
	}
}

func TestLoad_RequiresIdentityWebhookAndActor(t *testing.T) {
	t.Setenv("SUPABASE_URL", "https://example.supabase.co")
	t.Setenv("SUPABASE_ANON_KEY", "anon-key")
	t.Setenv("IDENTITY_VERIFICATION_PROVIDER", "webhook")
	t.Setenv("IDENTITY_VERIFICATION_WEBHOOK_URL", "https://identity.example.test/assess")
	t.Setenv("IDENTITY_VERIFICATION_ACTOR_ID", "")

	if _, err := Load(); err == nil {
		t.Fatal("expected identity webhook without a durable actor to fail closed")
	}
}

func TestLoad_RejectsNonUUIDIdentityProviderActor(t *testing.T) {
	t.Setenv("SUPABASE_URL", "https://example.supabase.co")
	t.Setenv("SUPABASE_ANON_KEY", "anon-key")
	t.Setenv("IDENTITY_VERIFICATION_PROVIDER", "webhook")
	t.Setenv("IDENTITY_VERIFICATION_WEBHOOK_URL", "https://identity.example.test/assess")
	t.Setenv("IDENTITY_VERIFICATION_ACTOR_ID", "identity-provider")

	if _, err := Load(); err == nil {
		t.Fatal("expected a non-UUID provider actor to fail closed")
	}
}

func TestLoad_RequiresVoiceProviderAndPrivatePlaybackKey(t *testing.T) {
	t.Setenv("SUPABASE_URL", "https://example.supabase.co")
	t.Setenv("SUPABASE_ANON_KEY", "anon-key")
	t.Setenv("VOICE_MODERATION_REQUIRED", "true")
	t.Setenv("VOICE_MODERATION_PROVIDER", "webhook")
	t.Setenv("VOICE_MODERATION_WEBHOOK_URL", "https://voice.example.test/moderate")
	t.Setenv("PRIVATE_MEDIA_SIGNING_KEY", "too-short")

	if _, err := Load(); err == nil {
		t.Fatal("expected required voice moderation without a strong playback key to fail closed")
	}
}

func TestLoad_ProductionRequiresIdentityProviderByDefault(t *testing.T) {
	t.Setenv("SUPABASE_URL", "https://example.supabase.co")
	t.Setenv("SUPABASE_ANON_KEY", "anon-key")
	t.Setenv("ENVIRONMENT", "production")
	t.Setenv("MEDIA_MODERATION_PROVIDER", "aws_rekognition")
	t.Setenv("VOICE_MODERATION_REQUIRED", "false")
	t.Setenv("IDENTITY_VERIFICATION_PROVIDER", "disabled")
	t.Setenv("IDENTITY_VERIFICATION_REQUIRED", "")

	if _, err := Load(); err == nil {
		t.Fatal("expected production to require identity verification by default")
	}
}

func TestLoad_ProductionRequiresVoiceModerationByDefault(t *testing.T) {
	t.Setenv("SUPABASE_URL", "https://example.supabase.co")
	t.Setenv("SUPABASE_ANON_KEY", "anon-key")
	t.Setenv("ENVIRONMENT", "production")
	t.Setenv("MEDIA_MODERATION_PROVIDER", "aws_rekognition")
	t.Setenv("IDENTITY_VERIFICATION_REQUIRED", "false")
	t.Setenv("VOICE_MODERATION_PROVIDER", "disabled")
	t.Setenv("VOICE_MODERATION_REQUIRED", "")

	if _, err := Load(); err == nil {
		t.Fatal("expected production to require voice moderation by default")
	}
}

func TestLoad_DerivesSupabaseURLAndDatabaseURLFromDBHost(t *testing.T) {
	t.Setenv("SUPABASE_URL", "")
	t.Setenv("SUPABASE_ANON_KEY", "anon-key")
	t.Setenv("SUPABASE_SERVICE_ROLE", "")
	t.Setenv("SUPABASE_DB_HOST", "db.ufrmtgriqpyzqaewvtgn.supabase.co")
	t.Setenv("SUPABASE_DB_PORT", "5432")
	t.Setenv("SUPABASE_DB_NAME", "postgres")
	t.Setenv("SUPABASE_DB_USER", "postgres")
	t.Setenv("SUPABASE_DB_PASSWORD", "secret")
	t.Setenv("SUPABASE_DATABASE_URL", "")
	t.Setenv("DATABASE_URL", "")

	cfg, err := Load()
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}

	if cfg.SupabaseURL != "https://ufrmtgriqpyzqaewvtgn.supabase.co" {
		t.Fatalf("unexpected derived SupabaseURL: %q", cfg.SupabaseURL)
	}
	wantDatabaseURL := "postgresql://postgres:secret@db.ufrmtgriqpyzqaewvtgn.supabase.co:5432/postgres?sslmode=require"
	if cfg.DatabaseURL != wantDatabaseURL {
		t.Fatalf("unexpected DatabaseURL: got %q want %q", cfg.DatabaseURL, wantDatabaseURL)
	}
}

func TestLoad_UsesNativePostgresWithoutSupabaseWhenLocalDbEnabled(t *testing.T) {
	t.Setenv("USE_LOCAL_DB", "true")
	t.Setenv("LOCAL_DATABASE_URL", "postgresql://postgres:root%40123@localhost:55432/dating_app?sslmode=disable")
	t.Setenv("LOCAL_POSTGREST_URL", "http://127.0.0.1:54321")
	t.Setenv("LOCAL_POSTGREST_ANON_KEY", "local-dev-key")
	t.Setenv("SUPABASE_URL", "")
	t.Setenv("SUPABASE_ANON_KEY", "")
	t.Setenv("SUPABASE_SERVICE_ROLE", "")
	t.Setenv("DATABASE_URL", "")

	cfg, err := Load()
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}

	if cfg.SupabaseURL != "" {
		t.Fatalf("local mode must not configure SupabaseURL: %q", cfg.SupabaseURL)
	}
	if cfg.SupabaseAnonKey != "" {
		t.Fatalf("local mode must not configure SupabaseAnonKey: %q", cfg.SupabaseAnonKey)
	}
	if cfg.DatabaseURL != "postgresql://postgres:root%40123@localhost:55432/dating_app?sslmode=disable" {
		t.Fatalf("unexpected local DatabaseURL: %q", cfg.DatabaseURL)
	}
	if !cfg.UseLocalDB {
		t.Fatal("expected UseLocalDB=true")
	}
	if cfg.BFFFastReadTimeoutMS != 750 || cfg.BFFNormalReadTimeoutMS != 3000 || cfg.BFFWriteTimeoutMS != 8000 {
		t.Fatalf("unexpected timeout tiers: fast=%d normal=%d write=%d", cfg.BFFFastReadTimeoutMS, cfg.BFFNormalReadTimeoutMS, cfg.BFFWriteTimeoutMS)
	}
	if cfg.PostgresStatementTimeoutMS != 5000 || cfg.PostgresLockTimeoutMS != 1000 {
		t.Fatalf("unexpected postgres timeouts: statement=%d lock=%d", cfg.PostgresStatementTimeoutMS, cfg.PostgresLockTimeoutMS)
	}
	if cfg.IdempotencyTTLSeconds != 600 || cfg.IdempotencyLeaseSeconds != 15 ||
		cfg.IdempotencyPollMilliseconds != 25 || cfg.IdempotencyMaxResponseBytes != 1048576 {
		t.Fatalf("unexpected idempotency defaults: ttl=%d lease=%d poll=%d max=%d",
			cfg.IdempotencyTTLSeconds, cfg.IdempotencyLeaseSeconds,
			cfg.IdempotencyPollMilliseconds, cfg.IdempotencyMaxResponseBytes)
	}
}

func TestLoad_AllowsServiceRoleWithoutAnonKey(t *testing.T) {
	t.Setenv("SUPABASE_URL", "https://example.supabase.co")
	t.Setenv("SUPABASE_ANON_KEY", "")
	t.Setenv("SUPABASE_SERVICE_ROLE", "service-role")

	_, err := Load()
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}
}

func TestLoad_FeatureFlagsFromEnvironment(t *testing.T) {
	t.Setenv("SUPABASE_URL", "https://example.supabase.co")
	t.Setenv("SUPABASE_ANON_KEY", "anon-key")
	t.Setenv("FEATURE_ENGAGEMENT_UNLOCK_MVP", "false")
	t.Setenv("FEATURE_DIGITAL_GESTURES", "true")
	t.Setenv("FEATURE_MINI_ACTIVITIES", "false")
	t.Setenv("FEATURE_TRUST_BADGES", "true")
	t.Setenv("FEATURE_CONVERSATION_ROOMS", "false")
	t.Setenv("FEATURE_EXPERIMENT_FRAMEWORK", "true")
	t.Setenv("FEATURE_EXPERIMENT_MATCH_NUDGE", "false")
	t.Setenv("EXPERIMENT_MATCH_NUDGE_ROLLOUT_PCT", "80")
	t.Setenv("FEATURE_ASSISTED_REVIEW_AUTOMATION", "true")
	t.Setenv("ASSISTED_REVIEW_MIN_CHARS", "140")
	t.Setenv("ASSISTED_REVIEW_MIN_WORD_COUNT", "24")

	cfg, err := Load()
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}

	if cfg.FeatureEngagementUnlockMVP {
		t.Fatalf("expected engagement unlock flag disabled")
	}
	if !cfg.FeatureDigitalGestures {
		t.Fatalf("expected digital gestures flag enabled")
	}
	if cfg.FeatureMiniActivities {
		t.Fatalf("expected mini activities flag disabled")
	}
	if !cfg.FeatureTrustBadges {
		t.Fatalf("expected trust badges flag enabled")
	}
	if cfg.FeatureConversationRooms {
		t.Fatalf("expected conversation rooms flag disabled")
	}
	if !cfg.FeatureExperimentFramework {
		t.Fatalf("expected experiment framework flag enabled")
	}
	if cfg.FeatureExperimentMatchNudge {
		t.Fatalf("expected experiment match nudge flag disabled")
	}
	if cfg.ExperimentMatchNudgeRolloutPct != 80 {
		t.Fatalf("expected match nudge rollout pct 80, got %d", cfg.ExperimentMatchNudgeRolloutPct)
	}
	if !cfg.FeatureAssistedReviewAutomation {
		t.Fatalf("expected assisted review automation flag enabled")
	}
	if cfg.AssistedReviewMinChars != 140 {
		t.Fatalf("expected assisted review min chars 140, got %d", cfg.AssistedReviewMinChars)
	}
	if cfg.AssistedReviewMinWordCount != 24 {
		t.Fatalf("expected assisted review min word count 24, got %d", cfg.AssistedReviewMinWordCount)
	}
}

func TestLoad_ExperimentRolloutPercentClamps(t *testing.T) {
	t.Setenv("SUPABASE_URL", "https://example.supabase.co")
	t.Setenv("SUPABASE_ANON_KEY", "anon-key")

	t.Setenv("EXPERIMENT_MATCH_NUDGE_ROLLOUT_PCT", "150")
	highCfg, err := Load()
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}
	if highCfg.ExperimentMatchNudgeRolloutPct != 100 {
		t.Fatalf("expected rollout pct clamped to 100, got %d", highCfg.ExperimentMatchNudgeRolloutPct)
	}

	t.Setenv("EXPERIMENT_MATCH_NUDGE_ROLLOUT_PCT", "-20")
	lowCfg, err := Load()
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}
	if lowCfg.ExperimentMatchNudgeRolloutPct != 0 {
		t.Fatalf("expected rollout pct clamped to 0, got %d", lowCfg.ExperimentMatchNudgeRolloutPct)
	}
}

func TestLoad_DurableEngagementStoreDefaultsByEnvironment(t *testing.T) {
	t.Setenv("SUPABASE_URL", "https://example.supabase.co")
	t.Setenv("SUPABASE_ANON_KEY", "anon-key")
	t.Setenv("REQUIRE_DURABLE_ENGAGEMENT_STORE", "")
	t.Setenv("MEDIA_MODERATION_PROVIDER", "aws_rekognition")
	t.Setenv("IDENTITY_VERIFICATION_REQUIRED", "false")
	t.Setenv("VOICE_MODERATION_REQUIRED", "false")
	t.Setenv("SOS_DELIVERY_REQUIRED", "false")

	t.Setenv("ENVIRONMENT", "production")
	prodCfg, err := Load()
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}
	if !prodCfg.RequireDurableEngagementStore {
		t.Fatalf("expected durable engagement store required in production")
	}

	t.Setenv("ENVIRONMENT", "development")
	devCfg, err := Load()
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}
	if devCfg.RequireDurableEngagementStore {
		t.Fatalf("expected durable engagement store disabled by default in development")
	}
}

func TestLoad_RejectsIncompleteDirectPushProvider(t *testing.T) {
	t.Setenv("USE_LOCAL_DB", "true")
	t.Setenv("LOCAL_DATABASE_URL", "postgresql://dating_app@localhost:55432/dating_app")
	t.Setenv("NOTIFICATION_PUSH_PROVIDER", "direct")
	t.Setenv("NOTIFICATION_FCM_PROJECT_ID", "")
	t.Setenv("NOTIFICATION_FCM_CREDENTIALS_FILE", "")
	t.Setenv("GOOGLE_APPLICATION_CREDENTIALS", "")
	t.Setenv("NOTIFICATION_APNS_TEAM_ID", "")

	if _, err := Load(); err == nil {
		t.Fatal("expected incomplete direct push configuration to fail")
	}
}

func TestLoad_AcceptsFCMDirectPushProvider(t *testing.T) {
	credentialsFile := filepath.Join(t.TempDir(), "firebase.json")
	if err := os.WriteFile(credentialsFile, []byte(`{}`), 0o600); err != nil {
		t.Fatalf("write credentials fixture: %v", err)
	}
	t.Setenv("USE_LOCAL_DB", "true")
	t.Setenv("LOCAL_DATABASE_URL", "postgresql://dating_app@localhost:55432/dating_app")
	t.Setenv("NOTIFICATION_PUSH_PROVIDER", "direct")
	t.Setenv("NOTIFICATION_FCM_PROJECT_ID", "project-1")
	t.Setenv("GOOGLE_APPLICATION_CREDENTIALS", credentialsFile)

	cfg, err := Load()
	if err != nil {
		t.Fatalf("Load: %v", err)
	}
	if cfg.NotificationPushProvider != "direct" || cfg.NotificationFCMCredentialsFile == "" {
		t.Fatalf("cfg=%+v", cfg)
	}
}

func TestLoad_DurableEngagementStoreExplicitOverride(t *testing.T) {
	t.Setenv("SUPABASE_URL", "https://example.supabase.co")
	t.Setenv("SUPABASE_ANON_KEY", "anon-key")
	t.Setenv("ENVIRONMENT", "development")
	t.Setenv("REQUIRE_DURABLE_ENGAGEMENT_STORE", "true")

	cfg, err := Load()
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}
	if !cfg.RequireDurableEngagementStore {
		t.Fatalf("expected durable engagement store to honor explicit override")
	}
}

func TestLoad_DefaultUnlockPolicyVariant_DefaultsAndOverride(t *testing.T) {
	t.Setenv("SUPABASE_URL", "https://example.supabase.co")
	t.Setenv("SUPABASE_ANON_KEY", "anon-key")
	t.Setenv("DEFAULT_UNLOCK_POLICY_VARIANT", "")

	defaultCfg, err := Load()
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}
	if defaultCfg.DefaultUnlockPolicyVariant != "allow_without_template" {
		t.Fatalf("expected default unlock policy variant allow_without_template, got %q", defaultCfg.DefaultUnlockPolicyVariant)
	}

	t.Setenv("DEFAULT_UNLOCK_POLICY_VARIANT", "require_quest_template")
	overrideCfg, err := Load()
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}
	if overrideCfg.DefaultUnlockPolicyVariant != "require_quest_template" {
		t.Fatalf("expected unlock policy override require_quest_template, got %q", overrideCfg.DefaultUnlockPolicyVariant)
	}

	t.Setenv("DEFAULT_UNLOCK_POLICY_VARIANT", "unknown")
	invalidCfg, err := Load()
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}
	if invalidCfg.DefaultUnlockPolicyVariant != "allow_without_template" {
		t.Fatalf("expected invalid variant to fallback to allow_without_template, got %q", invalidCfg.DefaultUnlockPolicyVariant)
	}
}
