package mobile

import (
	"reflect"
	"testing"
)

func TestParseNumericArray(t *testing.T) {
	t.Parallel()
	tests := []struct {
		name string
		raw  string
		want []float64
	}{
		{name: "postgres array", raw: "{1.000,0.750,0.500,0.250}", want: []float64{1, .75, .5, .25}},
		{name: "empty defaults", raw: "{}", want: []float64{1}},
		{name: "invalid defaults", raw: "{bad}", want: []float64{1}},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()
			if got := parseNumericArray(test.raw); !reflect.DeepEqual(got, test.want) {
				t.Fatalf("parseNumericArray(%q) = %#v, want %#v", test.raw, got, test.want)
			}
		})
	}
}

func TestProgressionRequestHashIsStableAndPayloadBound(t *testing.T) {
	t.Parallel()
	input := xpAwardInput{
		UserID:         "14f4914e-48e2-41a0-8430-b2ad82321565",
		Source:         "admin_adjustment",
		SourceEventID:  "admin:key-1",
		IdempotencyKey: "key-1",
		BaseXPOverride: 100,
		ActorType:      "admin",
		Metadata:       map[string]any{"reason": "verified correction"},
	}
	first := progressionRequestHash(input)
	if second := progressionRequestHash(input); second != first {
		t.Fatalf("request hash changed across identical inputs: %q != %q", second, first)
	}
	input.BaseXPOverride = 99
	if changed := progressionRequestHash(input); changed == first {
		t.Fatal("request hash did not bind the XP amount")
	}
	input.BaseXPOverride = 100
	input.ActorID = "ac059b6b-22f6-41d1-881f-8abff78b4515"
	if changed := progressionRequestHash(input); changed == first {
		t.Fatal("request hash did not bind the operator identity")
	}
}

func TestValidateProgressionRolloutChange(t *testing.T) {
	t.Parallel()
	valid := []progressionRolloutChange{
		{Status: "draft", Stage: "draft", RolloutPercent: 0},
		{Status: "active", Stage: "dogfood", RolloutPercent: 1, SafetyStopOwner: "progression-oncall", EvidenceURI: "report://dogfood", DecisionNote: "Dogfood evidence reviewed."},
		{Status: "paused", Stage: "five_percent", RolloutPercent: 5, SafetyStopOwner: "trust-safety-oncall", EvidenceURI: "incident://123", DecisionNote: "Safety threshold breached."},
		{Status: "completed", Stage: "general_availability", RolloutPercent: 100, SafetyStopOwner: "progression-oncall", EvidenceURI: "report://ga", DecisionNote: "General availability approved."},
	}
	for _, change := range valid {
		if err := validateProgressionRolloutChange(change); err != nil {
			t.Fatalf("valid change %+v rejected: %v", change, err)
		}
	}
	invalid := []progressionRolloutChange{
		{Status: "active", Stage: "five_percent", RolloutPercent: 10, SafetyStopOwner: "owner", EvidenceURI: "report://x", DecisionNote: "Reviewed evidence here."},
		{Status: "active", Stage: "dogfood", RolloutPercent: 1},
		{Status: "completed", Stage: "twenty_five_percent", RolloutPercent: 25, SafetyStopOwner: "owner", EvidenceURI: "report://x", DecisionNote: "Reviewed evidence here."},
		{Status: "draft", Stage: "dogfood", RolloutPercent: 1},
	}
	for _, change := range invalid {
		if err := validateProgressionRolloutChange(change); err == nil {
			t.Fatalf("invalid change accepted: %+v", change)
		}
	}
}
