package auth

import (
	"context"
	"strings"
	"testing"

	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
	"go.uber.org/zap/zaptest/observer"
	"google.golang.org/protobuf/types/known/structpb"
)

// Usernames are often phone numbers or e-mail addresses; login and signup
// logs carry a keyed pseudonym instead.
func TestLoginAndSignupLogsDoNotContainUsernames(t *testing.T) {
	core, logs := observer.New(zapcore.DebugLevel)
	repo := &fakeRepository{
		loginOut:  map[string]any{"success": true},
		signupOut: map[string]any{"success": true},
	}
	svc := NewService(repo, zap.New(core))
	for _, call := range []func(context.Context, *structpb.Struct) (*structpb.Struct, error){svc.Login, svc.Signup} {
		req, _ := structpb.NewStruct(map[string]any{"username": "+919876543210", "password": "Password123"})
		if _, err := call(context.Background(), req); err != nil {
			t.Fatal(err)
		}
	}
	if logs.Len() == 0 {
		t.Fatal("expected request logs")
	}
	for _, entry := range logs.All() {
		for key, value := range entry.ContextMap() {
			if key == "username" || strings.Contains(strings.ToLower(toLogString(value)), "9876543210") {
				t.Fatalf("%s logs the username: %v", entry.Message, entry.ContextMap())
			}
		}
		if ref, _ := entry.ContextMap()["username_ref"].(string); !strings.HasPrefix(ref, "id_") {
			t.Fatalf("%s should carry a pseudonym, got %v", entry.Message, entry.ContextMap())
		}
	}
}

func toLogString(value any) string {
	if s, ok := value.(string); ok {
		return s
	}
	return ""
}
