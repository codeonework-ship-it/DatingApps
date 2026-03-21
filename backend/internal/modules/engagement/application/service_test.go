package application

import (
	"context"
	"strings"
	"testing"

	"go.uber.org/zap"
)

type stubGateway struct {
	getGroupCoffeePollFn func(context.Context, string) (map[string]any, bool, error)
}

func (s *stubGateway) GetCircleChallenge(context.Context, string, string) (map[string]any, error) {
	return map[string]any{}, nil
}
func (s *stubGateway) JoinCircle(context.Context, string, string) (map[string]any, error) {
	return map[string]any{}, nil
}
func (s *stubGateway) SubmitCircleChallenge(context.Context, string, string, string, string, string) (map[string]any, map[string]any, error) {
	return map[string]any{}, map[string]any{}, nil
}
func (s *stubGateway) GetDailyPrompt(context.Context, string) (map[string]any, error) {
	return map[string]any{}, nil
}
func (s *stubGateway) SubmitDailyPromptAnswer(context.Context, string, string, string) (map[string]any, bool, error) {
	return map[string]any{}, false, nil
}
func (s *stubGateway) ListDailyPromptResponders(context.Context, string, int, int) (map[string]any, error) {
	return map[string]any{}, nil
}
func (s *stubGateway) SendMatchNudge(context.Context, string, string, string, string) (map[string]any, error) {
	return map[string]any{}, nil
}
func (s *stubGateway) ClickMatchNudge(context.Context, string, string) (map[string]any, error) {
	return map[string]any{}, nil
}
func (s *stubGateway) MarkConversationResumed(context.Context, string, string, string) (map[string]any, error) {
	return map[string]any{}, nil
}
func (s *stubGateway) ListVoicePrompts(context.Context) ([]map[string]any, error) {
	return []map[string]any{}, nil
}
func (s *stubGateway) StartVoiceIcebreaker(context.Context, string, string, string, string) (map[string]any, error) {
	return map[string]any{"match_id": "match-1"}, nil
}
func (s *stubGateway) SendVoiceIcebreaker(context.Context, string, string, string, int) (map[string]any, error) {
	return map[string]any{}, nil
}
func (s *stubGateway) PlayVoiceIcebreaker(context.Context, string, string) (map[string]any, error) {
	return map[string]any{}, nil
}
func (s *stubGateway) CreateGroupCoffeePoll(context.Context, string, []string, []GroupCoffeeOptionInput, string) (map[string]any, error) {
	return map[string]any{}, nil
}
func (s *stubGateway) ListGroupCoffeePolls(context.Context, string, string, int) ([]map[string]any, error) {
	return []map[string]any{}, nil
}
func (s *stubGateway) GetGroupCoffeePoll(ctx context.Context, pollID string) (map[string]any, bool, error) {
	if s.getGroupCoffeePollFn == nil {
		return nil, false, nil
	}
	return s.getGroupCoffeePollFn(ctx, pollID)
}
func (s *stubGateway) VoteGroupCoffeePoll(context.Context, string, string, string) (map[string]any, error) {
	return map[string]any{}, nil
}
func (s *stubGateway) FinalizeGroupCoffeePoll(context.Context, string, string) (map[string]any, map[string]any, error) {
	return map[string]any{}, map[string]any{}, nil
}
func (s *stubGateway) CreateCommunityGroup(context.Context, string, string, string, string, string, string, []string) (map[string]any, []map[string]any, error) {
	return map[string]any{}, []map[string]any{}, nil
}
func (s *stubGateway) ListCommunityGroups(context.Context, string, string, string, bool, int) ([]map[string]any, error) {
	return []map[string]any{}, nil
}
func (s *stubGateway) InviteCommunityGroupMembers(context.Context, string, string, []string) ([]map[string]any, error) {
	return []map[string]any{}, nil
}
func (s *stubGateway) RespondCommunityGroupInvite(context.Context, string, string, string) (map[string]any, map[string]any, error) {
	return map[string]any{}, map[string]any{}, nil
}
func (s *stubGateway) ListCommunityGroupInvites(context.Context, string, string, int) ([]map[string]any, error) {
	return []map[string]any{}, nil
}

func TestService_HandleJoinCircleValidation(t *testing.T) {
	svc := NewService(&stubGateway{}, zap.NewNop())
	_, err := svc.HandleJoinCircle(context.Background(), JoinCircleCommand{CircleID: "", UserID: ""})
	if err == nil || !strings.Contains(err.Error(), "validation error") {
		t.Fatalf("expected validation error, got %v", err)
	}
}

func TestService_HandleStartVoiceIcebreakerSuccess(t *testing.T) {
	svc := NewService(&stubGateway{}, zap.NewNop())
	resp, err := svc.HandleStartVoiceIcebreaker(context.Background(), StartVoiceIcebreakerCommand{
		MatchID:        "match-1",
		SenderUserID:   "user-a",
		ReceiverUserID: "user-b",
		PromptID:       "prompt-1",
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	item := resp["voice_icebreaker"].(map[string]any)
	if item["match_id"] != "match-1" {
		t.Fatalf("unexpected match_id: %#v", item["match_id"])
	}
}

func TestService_HandleGetGroupCoffeePollNotFound(t *testing.T) {
	svc := NewService(&stubGateway{getGroupCoffeePollFn: func(context.Context, string) (map[string]any, bool, error) {
		return nil, false, nil
	}}, zap.NewNop())
	_, err := svc.HandleGetGroupCoffeePoll(context.Background(), GetGroupCoffeePollCommand{PollID: "poll-missing"})
	if err == nil || !strings.Contains(strings.ToLower(err.Error()), "not found") {
		t.Fatalf("expected not found error, got %v", err)
	}
}
