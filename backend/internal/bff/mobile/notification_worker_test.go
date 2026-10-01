package mobile

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/verified-dating/backend/internal/platform/config"
)

type staticPushTokenSource string

func (s staticPushTokenSource) Token(context.Context) (string, error) {
	return string(s), nil
}

func TestWebhookPushSenderDeliversIdempotentProviderRequest(t *testing.T) {
	var received map[string]any
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if got := r.Header.Get("Authorization"); got != "Bearer provider-token" {
			t.Fatalf("Authorization=%q", got)
		}
		if got := r.Header.Get("Idempotency-Key"); got != "outbox-1:device-1" {
			t.Fatalf("Idempotency-Key=%q", got)
		}
		if err := json.NewDecoder(r.Body).Decode(&received); err != nil {
			t.Fatalf("decode request: %v", err)
		}
		w.Header().Set("X-Provider-Message-ID", "provider-message-1")
		w.WriteHeader(http.StatusAccepted)
	}))
	defer server.Close()

	sender := newWebhookPushSender(config.Config{
		NotificationPushWebhookURL:   server.URL,
		NotificationPushWebhookToken: "provider-token",
	})
	result, err := sender.Send(context.Background(), notificationDevice{
		ID: "device-1", Provider: "fcm", Platform: "android", Token: "opaque-device-token",
	}, notificationOutboxJob{
		ID: "outbox-1", Sequence: 19, EventType: "call.incoming", Category: "call",
		Title: "Incoming call", Body: "A match is calling you.", Payload: map[string]any{"call_id": "call-1"},
	})
	if err != nil {
		t.Fatalf("Send: %v", err)
	}
	if result.MessageID != "provider-message-1" || result.Permanent {
		t.Fatalf("result=%+v", result)
	}
	device, ok := received["device"].(map[string]any)
	if !ok || device["token"] != "opaque-device-token" {
		t.Fatalf("device payload=%#v", received["device"])
	}
}

func TestWebhookPushSenderClassifiesGoneTokenAsPermanent(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		http.Error(w, "token expired", http.StatusGone)
	}))
	defer server.Close()
	sender := newWebhookPushSender(config.Config{NotificationPushWebhookURL: server.URL})
	result, err := sender.Send(context.Background(), notificationDevice{ID: "device-1"}, notificationOutboxJob{ID: "outbox-1"})
	if err == nil {
		t.Fatal("expected provider error")
	}
	if !result.Permanent {
		t.Fatalf("expected permanent error, got %+v", result)
	}
}

func TestFCMPushSenderBuildsHighPriorityCallPayload(t *testing.T) {
	var payload map[string]any
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/v1/projects/project-1/messages:send" {
			t.Fatalf("path=%q", r.URL.Path)
		}
		if got := r.Header.Get("Authorization"); got != "Bearer access-token" {
			t.Fatalf("Authorization=%q", got)
		}
		if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
			t.Fatalf("decode: %v", err)
		}
		_ = json.NewEncoder(w).Encode(map[string]any{"name": "provider-message-1"})
	}))
	defer server.Close()

	sender := &fcmPushSender{
		projectID: "project-1", endpoint: server.URL,
		tokens: staticPushTokenSource("access-token"), client: server.Client(),
	}
	result, err := sender.Send(context.Background(), notificationDevice{Token: "device-token"}, notificationOutboxJob{
		ID: "outbox-1", Sequence: 2, EventType: "call.incoming", Category: "call",
		Title: "Incoming call", Body: "A match is calling you.", Payload: map[string]any{"call_id": "call-1"},
	})
	if err != nil {
		t.Fatalf("Send: %v", err)
	}
	if result.MessageID != "provider-message-1" {
		t.Fatalf("result=%+v", result)
	}
	message := payload["message"].(map[string]any)
	android := message["android"].(map[string]any)
	if android["priority"] != "HIGH" || android["ttl"] != "45s" {
		t.Fatalf("android=%#v", android)
	}
	data := message["data"].(map[string]any)
	if data["call_id"] != "call-1" || data["event_type"] != "call.incoming" {
		t.Fatalf("data=%#v", data)
	}
}

func TestFCMPushSenderDisablesOnlyInvalidRegistration(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusNotFound)
		_ = json.NewEncoder(w).Encode(map[string]any{"error": map[string]any{
			"status": "NOT_FOUND", "details": []map[string]any{{"errorCode": "UNREGISTERED"}},
		}})
	}))
	defer server.Close()
	sender := &fcmPushSender{projectID: "p", endpoint: server.URL, tokens: staticPushTokenSource("token"), client: server.Client()}
	result, err := sender.Send(context.Background(), notificationDevice{Token: "expired"}, notificationOutboxJob{ID: "job"})
	if err == nil || !result.Permanent || !result.InvalidToken {
		t.Fatalf("result=%+v err=%v", result, err)
	}
}

func TestAPNSPushSenderUsesRequiredHeadersAndClassifiesBadToken(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Header.Get("apns-push-type") != "alert" || r.Header.Get("apns-topic") != "com.example.app" {
			t.Fatalf("headers=%v", r.Header)
		}
		w.WriteHeader(http.StatusBadRequest)
		_ = json.NewEncoder(w).Encode(map[string]string{"reason": "BadDeviceToken"})
	}))
	defer server.Close()
	sender := &apnsPushSender{
		teamID: "team", keyID: "key", bundleID: "com.example.app", endpoint: server.URL,
		client: server.Client(), authToken: "provider-token", tokenAt: time.Now(),
	}
	result, err := sender.Send(context.Background(), notificationDevice{Token: "bad-token"}, notificationOutboxJob{ID: "job", Category: "nudge"})
	if err == nil || !result.Permanent || !result.InvalidToken {
		t.Fatalf("result=%+v err=%v", result, err)
	}
}
