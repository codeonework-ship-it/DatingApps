package mobile

import (
	"encoding/base64"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/verified-dating/backend/internal/platform/config"
)

func TestServer_CallRoomAndParticipantBoundary(t *testing.T) {
	server := newQuestWorkflowTestServerWithConfig(t, func(cfg *config.Config) {
		cfg.CallRoomBaseURL = "https://calls.example.test"
	})
	defer server.Close()

	startReq := httptest.NewRequest(http.MethodPost, "/v1/calls/start", strings.NewReader(`{
		"match_id":"match-call-1",
		"initiator_user_id":"call-user-a",
		"recipient_user_id":"call-user-b"
	}`))
	startReq.Header.Set("Content-Type", "application/json")
	startRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(startRec, startReq)
	if startRec.Code != http.StatusOK {
		t.Fatalf("start call code=%d body=%s", startRec.Code, startRec.Body.String())
	}
	startPayload := decodeJSONMap(t, startRec.Body.Bytes())
	session := toMap(t, startPayload["session"])
	callID := stringValue(session["id"])
	if joinURL := stringValue(session["join_url"]); !strings.HasPrefix(joinURL, "https://calls.example.test/") {
		t.Fatalf("expected provider join URL, got %q", joinURL)
	}

	outsiderReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/calls/"+callID+"/end",
		strings.NewReader(`{"ended_by_user_id":"call-user-c"}`),
	)
	outsiderReq.Header.Set("Content-Type", "application/json")
	outsiderRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(outsiderRec, outsiderReq)
	if outsiderRec.Code != http.StatusForbidden {
		t.Fatalf("outsider end code=%d body=%s", outsiderRec.Code, outsiderRec.Body.String())
	}
}

func TestCallRoomJWTIsShortLivedAndBoundToUserAndRoom(t *testing.T) {
	server := &Server{cfg: config.Config{
		CallTransportProvider: "jitsi_jwt",
		CallRoomBaseURL:       "https://calls.example.test",
		CallJWTIssuer:         "connect",
		CallJWTAudience:       "jitsi",
		CallJWTSecret:         "0123456789abcdef0123456789abcdef",
		CallTokenTTLSeconds:   300,
	}}
	token, expiresAt, ok := server.callRoomToken("room-1", "user-1")
	if !ok || token == "" {
		t.Fatal("expected signed room token")
	}
	parts := strings.Split(token, ".")
	if len(parts) != 3 {
		t.Fatalf("expected JWT, got %q", token)
	}
	payload, err := base64.RawURLEncoding.DecodeString(parts[1])
	if err != nil {
		t.Fatal(err)
	}
	var claims map[string]any
	if err := json.Unmarshal(payload, &claims); err != nil {
		t.Fatal(err)
	}
	if claims["room"] != "room-1" || expiresAt.After(time.Now().Add(6*time.Minute)) {
		t.Fatalf("unexpected claims=%v expiry=%s", claims, expiresAt)
	}
	contextClaim := claims["context"].(map[string]any)
	userClaim := contextClaim["user"].(map[string]any)
	if userClaim["id"] != "user-1" {
		t.Fatalf("token not bound to user: %v", claims)
	}
}
