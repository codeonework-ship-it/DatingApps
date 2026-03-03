package config

import "testing"

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
	t.Setenv("MOCK_OTP_ENABLED", "false")
	t.Setenv("API_GATEWAY_READ_HEADER_TIMEOUT_SEC", "-1")

	cfg, err := Load()
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}

	if cfg.APIPrefix != "/v1" {
		t.Fatalf("expected /v1 prefix, got %q", cfg.APIPrefix)
	}
	if cfg.MockOTPEnabled {
		t.Fatalf("expected mock otp disabled")
	}
	if cfg.APIGatewayReadHeaderTimeoutSec != 10 {
		t.Fatalf("expected fallback timeout 10, got %d", cfg.APIGatewayReadHeaderTimeoutSec)
	}
	if cfg.MobileBFFUpstreamURL == "" {
		t.Fatalf("expected upstream url to be populated")
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
	if defaultCfg.DefaultUnlockPolicyVariant != "require_quest_template" {
		t.Fatalf("expected default unlock policy variant require_quest_template, got %q", defaultCfg.DefaultUnlockPolicyVariant)
	}

	t.Setenv("DEFAULT_UNLOCK_POLICY_VARIANT", "allow_without_template")
	overrideCfg, err := Load()
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}
	if overrideCfg.DefaultUnlockPolicyVariant != "allow_without_template" {
		t.Fatalf("expected unlock policy override allow_without_template, got %q", overrideCfg.DefaultUnlockPolicyVariant)
	}

	t.Setenv("DEFAULT_UNLOCK_POLICY_VARIANT", "unknown")
	invalidCfg, err := Load()
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}
	if invalidCfg.DefaultUnlockPolicyVariant != "require_quest_template" {
		t.Fatalf("expected invalid variant to fallback to require_quest_template, got %q", invalidCfg.DefaultUnlockPolicyVariant)
	}
}
