package mobile

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestRuntimeConfigFlags_DefaultProjection(t *testing.T) {
	server := newContractTestServer(t)
	req := httptest.NewRequest(http.MethodGet, "/v1/config/flags", nil)
	rec := httptest.NewRecorder()

	server.runtimeConfigFlags(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("runtime flags status=%d body=%s", rec.Code, rec.Body.String())
	}
	payload := decodeJSONMap(t, rec.Body.Bytes())
	flags, ok := payload["flags"].([]any)
	if !ok || len(flags) < 8 {
		t.Fatalf("runtime flags payload missing defaults: %#v", payload)
	}
	for _, row := range flags {
		item, _ := row.(map[string]any)
		if item["key"] == "gifts_enabled" && item["value_bool"] == true {
			return
		}
	}
	t.Fatal("gifts_enabled default was not projected")
}
