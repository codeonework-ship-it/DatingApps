package config

import (
	"encoding/json"
	"os"
	"path/filepath"
	"testing"
)

func TestReleaseExcludedFlagsDefaultByEnvironment(t *testing.T) {
	t.Setenv("RELEASE_EXCLUDED_FLAGS", "")
	if got := releaseExcludedFlags("production"); len(got) != 0 {
		t.Fatalf("explicit empty override = %v, want none", got)
	}
}

func TestReleaseExcludedFlagsFollowEnvironmentWhenUnset(t *testing.T) {
	if got := len(releaseExcludedFlags("production")); got != len(FirstReleaseExcludedFlags) {
		t.Fatalf("production excluded %d flags, want %d", got, len(FirstReleaseExcludedFlags))
	}
	if got := releaseExcludedFlags("staging"); len(got) == 0 {
		t.Fatal("staging must exclude the first-release capabilities")
	}
	if got := releaseExcludedFlags("development"); len(got) != 0 {
		t.Fatalf("development excluded %v, want none", got)
	}
	cfg := Config{ReleaseExcludedFlags: FirstReleaseExcludedFlags}
	if !cfg.IsReleaseExcluded("gifts_enabled") || cfg.IsReleaseExcluded("safety_sos_enabled") {
		t.Fatal("IsReleaseExcluded mismatch")
	}
}

func TestReleaseExcludedFlagsOverride(t *testing.T) {
	t.Setenv("RELEASE_EXCLUDED_FLAGS", "none")
	if got := releaseExcludedFlags("production"); len(got) != 0 {
		t.Fatalf("none override = %v", got)
	}
	t.Setenv("RELEASE_EXCLUDED_FLAGS", " gifts_enabled , calls_enabled ")
	got := releaseExcludedFlags("development")
	if len(got) != 2 || got[0] != "gifts_enabled" || got[1] != "calls_enabled" {
		t.Fatalf("list override = %v", got)
	}
}

func TestIsLocalEnvironmentFailsClosed(t *testing.T) {
	for env, want := range map[string]bool{"development": true, "test": true, "Local": true, "": false, "qa": false, "production": false} {
		if IsLocalEnvironment(env) != want {
			t.Errorf("IsLocalEnvironment(%q) != %v", env, want)
		}
	}
}

// The excluded-flag list must cover every capability the release contract
// excludes, so the contract and runtime enforcement cannot drift apart.
func TestFirstReleaseExcludedFlagsCoverTheReleaseContract(t *testing.T) {
	raw, err := os.ReadFile(filepath.Join("..", "..", "..", "..", "documents", "contracts", "release_contract.v1.json"))
	if err != nil {
		t.Skipf("release contract not available: %v", err)
	}
	var contract struct {
		ReleaseScope struct {
			Excluded []string `json:"excluded_capabilities"`
		} `json:"release_scope"`
	}
	if err := json.Unmarshal(raw, &contract); err != nil {
		t.Fatal(err)
	}
	flagFor := map[string]string{
		"real_money_billing":      "billing_enabled",
		"coin_purchases":          "billing_enabled",
		"digital_gifts":           "gifts_enabled",
		"quest_unlock_workflow":   "quest_workflow_v2_enabled",
		"live_audio_video_calls":  "calls_enabled",
		"voice_icebreakers":       "voice_icebreakers_enabled",
		"identity_verified_badge": "identity_verification_enabled",
		"xp_progression":          "level_progression_enabled",
		// Production push is held off by PUSH provider defaulting to disabled.
		"production_push_notifications": "",
	}
	cfg := Config{ReleaseExcludedFlags: FirstReleaseExcludedFlags}
	for _, capability := range contract.ReleaseScope.Excluded {
		flag, known := flagFor[capability]
		if !known {
			t.Errorf("excluded capability %q has no runtime enforcement mapping", capability)
			continue
		}
		if flag != "" && !cfg.IsReleaseExcluded(flag) {
			t.Errorf("capability %q maps to %q, which FirstReleaseExcludedFlags does not hold off", capability, flag)
		}
	}
}
