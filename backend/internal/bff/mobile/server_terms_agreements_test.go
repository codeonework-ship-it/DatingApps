package mobile

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestServer_TermsAgreement_Default(t *testing.T) {
	server := newQuestWorkflowTestServer(t)

	req := httptest.NewRequest(http.MethodGet, "/v1/users/mock-user-001/agreements/terms", nil)
	rec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d", rec.Code)
	}

	var payload map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &payload); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}
	agreement, ok := payload["agreement"].(map[string]any)
	if !ok {
		t.Fatalf("expected agreement payload")
	}
	if agreement["accepted"] != false {
		t.Fatalf("expected accepted=false, got %v", agreement["accepted"])
	}
}

func TestServer_TermsAgreement_PatchAccepted(t *testing.T) {
	server := newQuestWorkflowTestServer(t)

	body := `{"accepted":true,"terms_version":"v1"}`
	req := httptest.NewRequest(
		http.MethodPatch,
		"/v1/users/mock-user-001/agreements/terms",
		strings.NewReader(body),
	)
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d body=%s", rec.Code, rec.Body.String())
	}

	verifyReq := httptest.NewRequest(http.MethodGet, "/v1/users/mock-user-001/agreements/terms", nil)
	verifyRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(verifyRec, verifyReq)

	if verifyRec.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d", verifyRec.Code)
	}

	var payload map[string]any
	if err := json.Unmarshal(verifyRec.Body.Bytes(), &payload); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}
	agreement, ok := payload["agreement"].(map[string]any)
	if !ok {
		t.Fatalf("expected agreement payload")
	}
	if agreement["accepted"] != true {
		t.Fatalf("expected accepted=true, got %v", agreement["accepted"])
	}
}
