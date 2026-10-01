package mobile

import (
	"encoding/json"
	"testing"
)

func TestDraftPatchCanClearHeightWithoutChangingOtherFields(t *testing.T) {
	draft := applyDraftPatch(defaultDraft("qa-height"), map[string]any{"height_cm": 175, "country": "India"})
	unchanged := applyDraftPatch(draft, map[string]any{"bio": "Only the biography changes"})
	if unchanged.HeightCm == nil || *unchanged.HeightCm != 175 {
		t.Fatal("omitted height was not preserved")
	}
	cleared := applyDraftPatch(draft, map[string]any{"height_cm": nil})
	if cleared.HeightCm != nil || cleared.Country == nil || *cleared.Country != "India" {
		t.Fatal("explicit height clear must preserve unrelated fields")
	}
}

func TestDraftPatchOptionalFieldsDistinguishOmittedFromNull(t *testing.T) {
	keys := []string{
		"education", "profession", "income_range", "country", "state", "city",
		"instagram_handle", "additional_info", "pet_preference", "diet_preference",
		"workout_frequency", "diet_type", "sleep_schedule", "travel_style",
		"political_comfort_range", "religion", "mother_tongue", "relationship_status",
		"personality_type",
	}
	seed := map[string]any{}
	for _, key := range keys {
		seed[key] = "saved " + key
	}
	draft := applyDraftPatch(defaultDraft("qa-presence"), seed)
	for _, changedKey := range keys {
		t.Run(changedKey, func(t *testing.T) {
			for _, operation := range []string{"omitted", "clear", "replace", "blank"} {
				t.Run(operation, func(t *testing.T) {
					patch := map[string]any{"bio": "An unrelated edited biography"}
					switch operation {
					case "clear":
						patch[changedKey] = nil
					case "replace":
						patch[changedKey] = "  replacement  "
					case "blank":
						patch[changedKey] = "  "
					}
					updated := applyDraftPatch(draft, patch)
					encoded, err := json.Marshal(updated)
					if err != nil {
						t.Fatal(err)
					}
					var actual map[string]any
					if err := json.Unmarshal(encoded, &actual); err != nil {
						t.Fatal(err)
					}
					for _, key := range keys {
						var expected any = "saved " + key
						if key == changedKey && (operation == "clear" || operation == "blank") {
							expected = nil
						} else if key == changedKey && operation == "replace" {
							expected = "replacement"
						}
						if actual[key] != expected {
							t.Errorf("%s after %s: got %v, want %v", key, operation, actual[key], expected)
						}
					}
				})
			}
		})
	}
}
