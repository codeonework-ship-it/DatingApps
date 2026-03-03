package mediatr

import (
	"context"
	"strings"
	"testing"
)

func TestMediatorSendRegisteredHandler(t *testing.T) {
	bus := New()
	bus.Register("echo", func(_ context.Context, request any) (any, error) {
		return request, nil
	})

	response, err := bus.Send(context.Background(), "echo", "hello")
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	value, ok := response.(string)
	if !ok {
		t.Fatalf("expected string response type, got %T", response)
	}
	if value != "hello" {
		t.Fatalf("expected hello, got %s", value)
	}
}

func TestMediatorSendMissingHandler(t *testing.T) {
	bus := New()

	_, err := bus.Send(context.Background(), "missing", nil)
	if err == nil {
		t.Fatal("expected error for missing handler")
	}

	if !strings.Contains(err.Error(), "mediatr handler not found") {
		t.Fatalf("unexpected error: %v", err)
	}
}
