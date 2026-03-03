package mobile

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestServer_BillingCoexistenceMatrixEndpoint(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	req := httptest.NewRequest(http.MethodGet, "/v1/billing/coexistence-matrix", nil)
	rec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("coexistence matrix code = %d body=%s", rec.Code, rec.Body.String())
	}

	payload := decodeJSONMap(t, rec.Body.Bytes())
	matrix := toMap(t, payload["coexistence_matrix"])
	if got := stringValue(matrix["matrix_version"]); got == "" {
		t.Fatalf("expected non-empty matrix_version")
	}
	if got := boolValue(matrix["core_progression_non_blocking"]); !got {
		t.Fatalf("expected core_progression_non_blocking=true")
	}
	items, ok := matrix["monetized_features"].([]any)
	if !ok || len(items) == 0 {
		t.Fatalf("expected monetized_features entries")
	}
	for _, item := range items {
		entry, ok := item.(map[string]any)
		if !ok {
			continue
		}
		if blocked := boolValue(entry["blocks_core_progression"]); blocked {
			t.Fatalf("expected monetized feature not to block core progression")
		}
	}
}

func TestServer_BillingPlansIncludeCoexistenceMatrix(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	req := httptest.NewRequest(http.MethodGet, "/v1/billing/plans", nil)
	rec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("billing plans code = %d body=%s", rec.Code, rec.Body.String())
	}

	payload := decodeJSONMap(t, rec.Body.Bytes())
	matrix := toMap(t, payload["coexistence_matrix"])
	if got := boolValue(matrix["core_progression_non_blocking"]); !got {
		t.Fatalf("expected core progression non-blocking matrix in plans response")
	}
}
