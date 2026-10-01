package infrastructure

import (
	"context"
	"encoding/json"
)

type StoreGateway struct {
	getVerification    func(string) (any, error)
	submitVerification func(string) (any, error)
	listVerifications  func(string, int) (any, error)
	reviewVerification func(string, string, string, string) (any, error)
}

func NewStoreGateway(
	getVerification func(string) (any, error),
	submitVerification func(string) (any, error),
	listVerifications func(string, int) (any, error),
	reviewVerification func(string, string, string, string) (any, error),
) *StoreGateway {
	return &StoreGateway{
		getVerification:    getVerification,
		submitVerification: submitVerification,
		listVerifications:  listVerifications,
		reviewVerification: reviewVerification,
	}
}

func (g *StoreGateway) GetVerification(_ context.Context, userID string) (map[string]any, error) {
	state, err := g.getVerification(userID)
	if err != nil {
		return nil, err
	}
	return toMap(state)
}

func (g *StoreGateway) SubmitVerification(_ context.Context, userID string) (map[string]any, error) {
	state, err := g.submitVerification(userID)
	if err != nil {
		return nil, err
	}
	return toMap(state)
}

func (g *StoreGateway) ListVerifications(_ context.Context, status string, limit int) ([]map[string]any, error) {
	states, err := g.listVerifications(status, limit)
	if err != nil {
		return nil, err
	}
	return toMapSlice(states)
}

func (g *StoreGateway) ReviewVerification(
	_ context.Context,
	userID, status, rejectionReason, reviewedBy string,
) (map[string]any, error) {
	state, err := g.reviewVerification(userID, status, rejectionReason, reviewedBy)
	if err != nil {
		return nil, err
	}
	return toMap(state)
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

func toMapSlice(value any) ([]map[string]any, error) {
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
