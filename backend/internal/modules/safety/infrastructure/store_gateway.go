package infrastructure

import (
	"context"
	"encoding/json"
)

type StoreGateway struct {
	reportUser  func(string, string, string, string) (any, error)
	blockUser   func(string, string) error
	unblockUser func(string, string) error
	triggerSOS  func(string, string, string, string, float64, float64) (any, error)
	listSOS     func(string, int) any
	resolveSOS  func(string, string, string) (any, error)
}

func NewStoreGateway(
	reportUser func(string, string, string, string) (any, error),
	blockUser func(string, string) error,
	unblockUser func(string, string) error,
	triggerSOS func(string, string, string, string, float64, float64) (any, error),
	listSOS func(string, int) any,
	resolveSOS func(string, string, string) (any, error),
) *StoreGateway {
	return &StoreGateway{
		reportUser:  reportUser,
		blockUser:   blockUser,
		unblockUser: unblockUser,
		triggerSOS:  triggerSOS,
		listSOS:     listSOS,
		resolveSOS:  resolveSOS,
	}
}

func (g *StoreGateway) ReportUser(
	_ context.Context,
	reporterUserID, reportedUserID, reason, description string,
) (map[string]any, error) {
	report, err := g.reportUser(reporterUserID, reportedUserID, reason, description)
	if err != nil {
		return nil, err
	}
	return toMap(report)
}

func (g *StoreGateway) BlockUser(_ context.Context, userID, blockedUserID string) error {
	return g.blockUser(userID, blockedUserID)
}

func (g *StoreGateway) UnblockUser(_ context.Context, userID, blockedUserID string) error {
	return g.unblockUser(userID, blockedUserID)
}

func (g *StoreGateway) TriggerSOS(
	_ context.Context,
	userID, matchID, level, message string,
	latitude, longitude float64,
) (map[string]any, error) {
	alert, err := g.triggerSOS(userID, matchID, level, message, latitude, longitude)
	if err != nil {
		return nil, err
	}
	return toMap(alert)
}

func (g *StoreGateway) ListSOS(_ context.Context, userID string, limit int) ([]map[string]any, error) {
	return toMapSlice(g.listSOS(userID, limit))
}

func (g *StoreGateway) ResolveSOS(_ context.Context, alertID, resolvedBy, note string) (map[string]any, error) {
	alert, err := g.resolveSOS(alertID, resolvedBy, note)
	if err != nil {
		return nil, err
	}
	return toMap(alert)
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
