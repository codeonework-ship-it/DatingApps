package mobile

import "testing"

func TestFeatureFlagForRouteCoversCriticalServerActions(t *testing.T) {
	tests := map[string]string{
		"/v1/blog/posts":                            "intentional_dating_enabled",
		"/v1/blog/posts/post/photos/photo":          "intentional_dating_enabled",
		"/v1/profile/user-1/stories":                "intentional_dating_enabled",
		"/v1/matches/match-1/voice-introductions":   "voice_icebreakers_enabled",
		"/v1/chat/gifts":                            "gifts_enabled",
		"/v1/chat/match-1/gifts/send":               "gifts_enabled",
		"/v1/engagement/voice-icebreakers/start":    "voice_icebreakers_enabled",
		"/v1/rooms/room-1/join":                     "rooms_enabled",
		"/v1/calls/start":                           "calls_enabled",
		"/v1/billing/checkout":                      "billing_enabled",
		"/v1/engagement/daily-prompt/user-1/answer": "daily_prompts_enabled",
		"/v1/engagement/circles/circle-1/join":      "circles_enabled",
		"/v1/engagement/match-nudges/send":          "match_nudges_enabled",
		"/v1/engagement/group-coffee-polls":         "group_coffee_polls_enabled",
		"/v1/safety/sos":                            "safety_sos_enabled",
		"/v1/matches/match-1/quest-workflow/submit": "quest_workflow_v2_enabled",
		"/v1/progression/user-1/rewards/claim":      "level_progression_enabled",
		"/v1/admin/config/flags":                    "",
		"/v1/profile/user-1":                        "",
	}
	for path, want := range tests {
		if got := featureFlagForRoute("/v1", path); got != want {
			t.Errorf("featureFlagForRoute(%q)=%q, want %q", path, got, want)
		}
	}
}
