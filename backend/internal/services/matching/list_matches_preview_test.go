package matching

import (
	"context"
	"testing"

	"go.uber.org/zap"
	"google.golang.org/protobuf/types/known/structpb"

	"github.com/verified-dating/backend/internal/platform/config"
)

// previewRepo is a minimal Repository for ListMatches: one match, no messages.
type previewRepo struct{ Repository }

func (previewRepo) ListMatches(context.Context, string) ([]map[string]any, error) {
	return []map[string]any{{"id": "m1", "userId1": "me", "userId2": "them"}}, nil
}
func (previewRepo) GetUsersByIDs(context.Context, []string) (map[string]map[string]any, error) {
	return map[string]map[string]any{"them": {"name": "Them"}}, nil
}
func (previewRepo) GetPrimaryPhotosByUserIDs(context.Context, []string) (map[string]string, error) {
	return map[string]string{}, nil
}
func (previewRepo) GetLatestMessagesByMatchIDs(context.Context, []string) (map[string]map[string]any, error) {
	return map[string]map[string]any{}, nil
}
func (previewRepo) GetUnreadCounts(context.Context, []string, string) (map[string]int, error) {
	return map[string]int{}, nil
}

// Regression (QA 2026-10-01, API-01): a brand-new match with no messages
// returned lastMessage "<nil>" and the apps rendered it as the preview.
func TestListMatchesWithoutMessagesUsesFriendlyPreview(t *testing.T) {
	svc := NewService(previewRepo{}, zap.NewNop(), config.Config{})
	req, _ := structpb.NewStruct(map[string]any{"user_id": "me"})
	out, err := svc.ListMatches(context.Background(), req)
	if err != nil {
		t.Fatalf("ListMatches: %v", err)
	}
	matches := out.AsMap()["matches"].([]any)
	if len(matches) != 1 {
		t.Fatalf("expected one match, got %d", len(matches))
	}
	preview := matches[0].(map[string]any)["lastMessage"]
	if preview != "Say hi 👋" {
		t.Fatalf("lastMessage = %q, want the friendly empty-chat preview", preview)
	}
}

func TestToStringNilIsEmpty(t *testing.T) {
	if got := toString(nil); got != "" {
		t.Fatalf("toString(nil) = %q, want empty", got)
	}
}
