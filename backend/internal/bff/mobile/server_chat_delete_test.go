package mobile

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestServer_DeleteMessageRequiresRequesterUserID(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	req := httptest.NewRequest(
		http.MethodDelete,
		"/v1/chat/match-delete-1/messages/msg-1",
		strings.NewReader(`{}`),
	)
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected status 400, got code=%d body=%s", rec.Code, rec.Body.String())
	}
}
