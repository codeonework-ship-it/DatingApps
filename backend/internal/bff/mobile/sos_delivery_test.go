package mobile

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

func TestSOSDeliveryWebhookCarriesIdempotencyAndTrustedContact(t *testing.T) {
	var received sosDeliveryJob
	var idempotency, authorization string
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		idempotency = r.Header.Get("Idempotency-Key")
		authorization = r.Header.Get("Authorization")
		if err := json.NewDecoder(r.Body).Decode(&received); err != nil {
			t.Errorf("decode request: %v", err)
			http.Error(w, "bad payload", http.StatusBadRequest)
			return
		}
		w.WriteHeader(http.StatusAccepted)
	}))
	defer server.Close()

	engine := &sosDeliveryEngine{
		client: &http.Client{Timeout: time.Second}, webhookURL: server.URL,
		webhookToken: "secret",
	}
	job := sosDeliveryJob{
		ID: "delivery-1", AlertID: "alert-1", UserID: "user-1",
		ContactName: "Trusted person", ContactPhone: "+15550001111", Level: "critical",
	}
	if err := engine.send(context.Background(), job); err != nil {
		t.Fatal(err)
	}
	if idempotency != job.ID || authorization != "Bearer secret" {
		t.Fatalf("headers idempotency=%q authorization=%q", idempotency, authorization)
	}
	if received.AlertID != job.AlertID || received.ContactPhone != job.ContactPhone {
		t.Fatalf("unexpected delivery payload: %#v", received)
	}
}

func TestSOSDeliveryWebhookRetriesNonSuccessResponse(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		http.Error(w, "provider unavailable", http.StatusServiceUnavailable)
	}))
	defer server.Close()
	engine := &sosDeliveryEngine{client: server.Client(), webhookURL: server.URL}
	if err := engine.send(context.Background(), sosDeliveryJob{ID: "delivery-1"}); err == nil {
		t.Fatal("expected non-2xx provider response to remain retryable")
	}
}
