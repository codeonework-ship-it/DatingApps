package infrastructure

import (
	"context"
	"encoding/json"
	"errors"
)

type StoreGateway struct {
	getQuestTemplate    func(string) (any, bool)
	upsertQuestTemplate func(string, string, string, int, int) (any, error)
	getQuestWorkflow    func(string) (any, bool)
	submitQuestResponse func(string, string, string) (any, error)
	reviewQuestResponse func(string, string, string, string) (any, error)
	listMatchGestures   func(string) any
	createMatchGesture  func(string, string, string, string, string, string) (any, error)
	decideMatchGesture  func(string, string, string, string, string) (any, error)
	getGestureScore     func(string, string) (any, error)
}

func NewStoreGateway(
	getQuestTemplate func(string) (any, bool),
	upsertQuestTemplate func(string, string, string, int, int) (any, error),
	getQuestWorkflow func(string) (any, bool),
	submitQuestResponse func(string, string, string) (any, error),
	reviewQuestResponse func(string, string, string, string) (any, error),
	listMatchGestures func(string) any,
	createMatchGesture func(string, string, string, string, string, string) (any, error),
	decideMatchGesture func(string, string, string, string, string) (any, error),
	getGestureScore func(string, string) (any, error),
) *StoreGateway {
	return &StoreGateway{
		getQuestTemplate:    getQuestTemplate,
		upsertQuestTemplate: upsertQuestTemplate,
		getQuestWorkflow:    getQuestWorkflow,
		submitQuestResponse: submitQuestResponse,
		reviewQuestResponse: reviewQuestResponse,
		listMatchGestures:   listMatchGestures,
		createMatchGesture:  createMatchGesture,
		decideMatchGesture:  decideMatchGesture,
		getGestureScore:     getGestureScore,
	}
}

func (g *StoreGateway) GetCandidates(context.Context, string, int) (map[string]any, error) {
	return nil, errors.New("matching grpc method not supported by store gateway")
}

func (g *StoreGateway) Swipe(context.Context, map[string]any) (map[string]any, error) {
	return nil, errors.New("matching grpc method not supported by store gateway")
}

func (g *StoreGateway) ListMatches(context.Context, string) (map[string]any, error) {
	return nil, errors.New("matching grpc method not supported by store gateway")
}

func (g *StoreGateway) Unmatch(context.Context, string, string) (map[string]any, error) {
	return nil, errors.New("matching grpc method not supported by store gateway")
}

func (g *StoreGateway) MarkAsRead(context.Context, map[string]any) (map[string]any, error) {
	return nil, errors.New("matching grpc method not supported by store gateway")
}

func (g *StoreGateway) GetQuestTemplate(_ context.Context, matchID string) (map[string]any, error) {
	out, ok := g.getQuestTemplate(matchID)
	if !ok {
		return map[string]any{}, nil
	}
	return toMap(out)
}

func (g *StoreGateway) UpsertQuestTemplate(
	_ context.Context,
	matchID, creatorUserID, prompt string,
	minChars, maxChars int,
) (map[string]any, error) {
	out, err := g.upsertQuestTemplate(matchID, creatorUserID, prompt, minChars, maxChars)
	if err != nil {
		return nil, err
	}
	return toMap(out)
}

func (g *StoreGateway) GetQuestWorkflow(_ context.Context, matchID string) (map[string]any, error) {
	out, ok := g.getQuestWorkflow(matchID)
	if !ok {
		return map[string]any{}, nil
	}
	return toMap(out)
}

func (g *StoreGateway) SubmitQuestResponse(
	_ context.Context,
	matchID, submitterUserID, responseText string,
) (map[string]any, error) {
	out, err := g.submitQuestResponse(matchID, submitterUserID, responseText)
	if err != nil {
		return nil, err
	}
	return toMap(out)
}

func (g *StoreGateway) ReviewQuestResponse(
	_ context.Context,
	matchID, reviewerUserID, decisionStatus, reviewReason string,
) (map[string]any, error) {
	out, err := g.reviewQuestResponse(matchID, reviewerUserID, decisionStatus, reviewReason)
	if err != nil {
		return nil, err
	}
	return toMap(out)
}

func (g *StoreGateway) ListMatchGestures(_ context.Context, matchID string) ([]map[string]any, error) {
	out := g.listMatchGestures(matchID)
	return toSliceMap(out)
}

func (g *StoreGateway) CreateMatchGesture(
	_ context.Context,
	matchID, senderUserID, receiverUserID, gestureType, contentText, tone string,
) (map[string]any, error) {
	out, err := g.createMatchGesture(matchID, senderUserID, receiverUserID, gestureType, contentText, tone)
	if err != nil {
		return nil, err
	}
	return toMap(out)
}

func (g *StoreGateway) DecideMatchGesture(
	_ context.Context,
	matchID, gestureID, reviewerUserID, decision, reason string,
) (map[string]any, error) {
	out, err := g.decideMatchGesture(matchID, gestureID, reviewerUserID, decision, reason)
	if err != nil {
		return nil, err
	}
	return toMap(out)
}

func (g *StoreGateway) GetGestureScore(_ context.Context, matchID, gestureID string) (map[string]any, error) {
	out, err := g.getGestureScore(matchID, gestureID)
	if err != nil {
		return nil, err
	}
	return toMap(out)
}

func toMap(value any) (map[string]any, error) {
	data, err := json.Marshal(value)
	if err != nil {
		return nil, err
	}
	var out map[string]any
	if err := json.Unmarshal(data, &out); err != nil {
		return nil, err
	}
	if out == nil {
		out = map[string]any{}
	}
	return out, nil
}

func toSliceMap(value any) ([]map[string]any, error) {
	data, err := json.Marshal(value)
	if err != nil {
		return nil, err
	}
	var out []map[string]any
	if err := json.Unmarshal(data, &out); err != nil {
		return nil, err
	}
	if out == nil {
		out = []map[string]any{}
	}
	return out, nil
}
