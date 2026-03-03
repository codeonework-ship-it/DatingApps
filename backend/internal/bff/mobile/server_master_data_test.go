package mobile

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestServer_GetPreferenceMasterData(t *testing.T) {
	server := newQuestWorkflowTestServer(t)

	req := httptest.NewRequest(http.MethodGet, "/v1/master-data/preferences", nil)
	rec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d", rec.Code)
	}

	var payload map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &payload); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}
	master, ok := payload["master_data"].(map[string]any)
	if !ok {
		t.Fatalf("expected master_data payload")
	}

	for _, key := range []string{
		"countries",
		"states_by_country",
		"cities_by_state",
		"religions",
		"mother_tongues",
		"languages",
		"diet_preferences",
		"workout_frequencies",
		"diet_types",
		"sleep_schedules",
		"travel_styles",
		"political_comfort_ranges",
	} {
		if _, exists := master[key]; !exists {
			t.Fatalf("expected key %q in master_data", key)
		}
	}
}
