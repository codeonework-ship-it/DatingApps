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

	if rec.Code != http.StatusServiceUnavailable {
		t.Fatalf("expected status 503, got %d", rec.Code)
	}

	var payload map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &payload); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}
	if success, _ := payload["success"].(bool); success {
		t.Fatalf("expected success=false in error payload")
	}
	if _, ok := payload["error"]; !ok {
		t.Fatalf("expected error message in payload")
	}
}
