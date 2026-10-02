package mobile

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

// API-04: a missing body reads as {} so the handler names the field it needs,
// and malformed bodies never leak the raw decoder error.
func TestReadJSONEmptyBodiesAndReadableErrors(t *testing.T) {
	for _, body := range []string{"", "   \n", "null"} {
		req := httptest.NewRequest(http.MethodDelete, "/v1/clubs/reviews/x", strings.NewReader(body))
		rec := httptest.NewRecorder()
		payload, ok := readJSON(rec, req)
		if !ok || payload == nil || len(payload) != 0 {
			t.Fatalf("body %q: ok=%v payload=%v code=%d", body, ok, payload, rec.Code)
		}
	}
	noBody := httptest.NewRequest(http.MethodDelete, "/v1/clubs/reviews/x", nil)
	if payload, ok := readJSON(httptest.NewRecorder(), noBody); !ok || payload == nil {
		t.Fatalf("nil body: ok=%v payload=%v", ok, payload)
	}

	cases := map[string]string{
		`{"expected_version":`: "request body is not valid JSON",
		`not json`:             "request body is not valid JSON",
		`[1,2]`:                "request body must be a JSON object",
		`"text"`:               "request body must be a JSON object",
	}
	for body, want := range cases {
		req := httptest.NewRequest(http.MethodPost, "/v1/x", strings.NewReader(body))
		rec := httptest.NewRecorder()
		if _, ok := readJSON(rec, req); ok {
			t.Fatalf("body %q accepted", body)
		}
		if rec.Code != http.StatusBadRequest {
			t.Fatalf("body %q: code=%d", body, rec.Code)
		}
		got := stringValue(decodeJSONMap(t, rec.Body.Bytes())["error"])
		if got != want {
			t.Fatalf("body %q: error=%q want %q", body, got, want)
		}
	}

	ok := httptest.NewRequest(http.MethodPost, "/v1/x", strings.NewReader(`{"expected_version":3}`))
	payload, accepted := readJSON(httptest.NewRecorder(), ok)
	if !accepted || payload["expected_version"] != float64(3) {
		t.Fatalf("valid body: %v %v", accepted, payload)
	}
}
