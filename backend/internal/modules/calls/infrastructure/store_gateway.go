package infrastructure

import (
	"context"
	"encoding/json"
)

type StoreGateway struct {
	startCall func(string, string, string) (any, error)
	endCall   func(string, string) (any, error)
	listCalls func(string, int) any
}

func NewStoreGateway(
	startCall func(string, string, string) (any, error),
	endCall func(string, string) (any, error),
	listCalls func(string, int) any,
) *StoreGateway {
	return &StoreGateway{startCall: startCall, endCall: endCall, listCalls: listCalls}
}

func (g *StoreGateway) StartCall(_ context.Context, matchID, initiatorID, recipientID string) (map[string]any, error) {
	result, err := g.startCall(matchID, initiatorID, recipientID)
	if err != nil {
		return nil, err
	}
	return toMap(result)
}

func (g *StoreGateway) EndCall(_ context.Context, callID, endedBy string) (map[string]any, error) {
	result, err := g.endCall(callID, endedBy)
	if err != nil {
		return nil, err
	}
	return toMap(result)
}

func (g *StoreGateway) ListHistory(_ context.Context, userID string, limit int) ([]map[string]any, error) {
	return toMapSlice(g.listCalls(userID, limit))
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
