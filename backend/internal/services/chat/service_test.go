package chat

import (
	"context"
	"errors"
	"testing"

	"go.uber.org/zap"
	"google.golang.org/protobuf/types/known/structpb"

	"github.com/verified-dating/backend/internal/platform/config"
)

type fakeChatRepo struct {
	deleteCalled bool
	deleteArgs   struct {
		matchID   string
		messageID string
		requester string
	}
	deleteResult bool
	deleteErr    error
}

func (f *fakeChatRepo) ListMessages(context.Context, string, int) ([]map[string]any, error) {
	return []map[string]any{}, nil
}

func (f *fakeChatRepo) SendMessage(context.Context, string, string, string) (string, error) {
	return "", nil
}

func (f *fakeChatRepo) DeleteMessage(
	_ context.Context,
	matchID,
	messageID,
	requesterUserID string,
) (bool, string, error) {
	f.deleteCalled = true
	f.deleteArgs.matchID = matchID
	f.deleteArgs.messageID = messageID
	f.deleteArgs.requester = requesterUserID
	if f.deleteErr != nil {
		return false, "", f.deleteErr
	}
	if f.deleteResult {
		return true, "DELETED", nil
	}
	return false, "NOT_FOUND_OR_NOT_OWNER", nil
}

func TestServiceDeleteMessageValidation(t *testing.T) {
	repo := &fakeChatRepo{}
	svc := NewService(repo, nil, nil, zap.NewNop(), config.Config{})

	resp, err := svc.DeleteMessage(
		context.Background(),
		&structpb.Struct{Fields: map[string]*structpb.Value{}},
	)
	if err != nil {
		t.Fatalf("DeleteMessage() unexpected error: %v", err)
	}
	payload := resp.AsMap()
	if payload["deleted"] != false {
		t.Fatalf("expected deleted=false payload=%v", payload)
	}
	if repo.deleteCalled {
		t.Fatalf("expected repo not to be called for invalid payload")
	}
}

func TestServiceDeleteMessageSuccess(t *testing.T) {
	repo := &fakeChatRepo{deleteResult: true}
	svc := NewService(repo, nil, nil, zap.NewNop(), config.Config{})

	resp, err := svc.DeleteMessage(
		context.Background(),
		&structpb.Struct{Fields: map[string]*structpb.Value{
			"match_id":          structpb.NewStringValue("match-1"),
			"message_id":        structpb.NewStringValue("msg-1"),
			"requester_user_id": structpb.NewStringValue("user-1"),
		}},
	)
	if err != nil {
		t.Fatalf("DeleteMessage() error = %v", err)
	}
	payload := resp.AsMap()
	if payload["deleted"] != true {
		t.Fatalf("expected deleted=true payload=%v", payload)
	}
	if !repo.deleteCalled {
		t.Fatalf("expected repo to be called")
	}
	if repo.deleteArgs.matchID != "match-1" || repo.deleteArgs.messageID != "msg-1" || repo.deleteArgs.requester != "user-1" {
		t.Fatalf("unexpected repo args: %+v", repo.deleteArgs)
	}
}

func TestServiceDeleteMessageRepositoryError(t *testing.T) {
	repo := &fakeChatRepo{deleteErr: errors.New("db down")}
	svc := NewService(repo, nil, nil, zap.NewNop(), config.Config{})

	_, err := svc.DeleteMessage(
		context.Background(),
		&structpb.Struct{Fields: map[string]*structpb.Value{
			"match_id":          structpb.NewStringValue("match-1"),
			"message_id":        structpb.NewStringValue("msg-1"),
			"requester_user_id": structpb.NewStringValue("user-1"),
		}},
	)
	if err == nil {
		t.Fatalf("expected error")
	}
}
