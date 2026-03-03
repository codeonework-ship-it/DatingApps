package application

import (
	"context"
	"errors"
	"testing"

	"go.uber.org/zap"
)

type matchingGatewayStub struct {
	questTemplate         map[string]any
	upsertedQuestTemplate map[string]any
	upsertErr             error
	lastMatchID           string
	lastCreatorUserID     string
	lastPrompt            string
	lastMinChars          int
	lastMaxChars          int
}

func (s *matchingGatewayStub) GetCandidates(context.Context, string, int) (map[string]any, error) {
	return map[string]any{}, nil
}

func (s *matchingGatewayStub) Swipe(context.Context, map[string]any) (map[string]any, error) {
	return map[string]any{}, nil
}

func (s *matchingGatewayStub) ListMatches(context.Context, string) (map[string]any, error) {
	return map[string]any{}, nil
}

func (s *matchingGatewayStub) Unmatch(context.Context, string, string) (map[string]any, error) {
	return map[string]any{}, nil
}

func (s *matchingGatewayStub) MarkAsRead(context.Context, map[string]any) (map[string]any, error) {
	return map[string]any{}, nil
}

func (s *matchingGatewayStub) GetQuestTemplate(context.Context, string) (map[string]any, error) {
	if s.questTemplate == nil {
		return map[string]any{}, nil
	}
	return s.questTemplate, nil
}

func (s *matchingGatewayStub) UpsertQuestTemplate(
	_ context.Context,
	matchID, creatorUserID, prompt string,
	minChars, maxChars int,
) (map[string]any, error) {
	if s.upsertErr != nil {
		return nil, s.upsertErr
	}
	s.lastMatchID = matchID
	s.lastCreatorUserID = creatorUserID
	s.lastPrompt = prompt
	s.lastMinChars = minChars
	s.lastMaxChars = maxChars
	if s.upsertedQuestTemplate == nil {
		s.upsertedQuestTemplate = map[string]any{"match_id": matchID}
	}
	return s.upsertedQuestTemplate, nil
}

func (s *matchingGatewayStub) GetQuestWorkflow(context.Context, string) (map[string]any, error) {
	return map[string]any{}, nil
}

func (s *matchingGatewayStub) SubmitQuestResponse(context.Context, string, string, string) (map[string]any, error) {
	return map[string]any{}, nil
}

func (s *matchingGatewayStub) ReviewQuestResponse(context.Context, string, string, string, string) (map[string]any, error) {
	return map[string]any{}, nil
}

func (s *matchingGatewayStub) ListMatchGestures(context.Context, string) ([]map[string]any, error) {
	return []map[string]any{}, nil
}

func (s *matchingGatewayStub) CreateMatchGesture(
	context.Context,
	string,
	string,
	string,
	string,
	string,
	string,
) (map[string]any, error) {
	return map[string]any{}, nil
}

func (s *matchingGatewayStub) DecideMatchGesture(context.Context, string, string, string, string, string) (map[string]any, error) {
	return map[string]any{}, nil
}

func (s *matchingGatewayStub) GetGestureScore(context.Context, string, string) (map[string]any, error) {
	return map[string]any{}, nil
}

func TestHandleUpsertQuestTemplate_SuccessWithDefaults(t *testing.T) {
	gateway := &matchingGatewayStub{
		upsertedQuestTemplate: map[string]any{
			"match_id":        "match-1",
			"prompt_template": "hello",
		},
	}
	service := NewService(gateway, zap.NewNop())

	out, err := service.HandleUpsertQuestTemplate(context.Background(), UpsertQuestTemplateCommand{
		MatchID:       "match-1",
		CreatorUserID: "user-1",
		Prompt:        "Describe how you resolve conflict in healthy ways.",
	})
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	if out["quest_template"] == nil {
		t.Fatalf("expected quest_template payload")
	}
	if gateway.lastMinChars != 60 {
		t.Fatalf("expected default min chars 60, got %d", gateway.lastMinChars)
	}
	if gateway.lastMaxChars != 280 {
		t.Fatalf("expected default max chars 280, got %d", gateway.lastMaxChars)
	}
}

func TestHandleUpsertQuestTemplate_Validation(t *testing.T) {
	service := NewService(&matchingGatewayStub{}, zap.NewNop())

	_, err := service.HandleUpsertQuestTemplate(context.Background(), UpsertQuestTemplateCommand{})
	if err == nil || !errors.Is(err, ErrValidation) {
		t.Fatalf("expected validation error, got %v", err)
	}
}

func TestHandleGetQuestTemplate_Validation(t *testing.T) {
	service := NewService(&matchingGatewayStub{}, zap.NewNop())

	_, err := service.HandleGetQuestTemplate(context.Background(), GetQuestTemplateCommand{})
	if err == nil || !errors.Is(err, ErrValidation) {
		t.Fatalf("expected validation error, got %v", err)
	}
}
