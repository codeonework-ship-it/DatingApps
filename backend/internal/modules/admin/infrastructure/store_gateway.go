package infrastructure

import (
	"context"
	"encoding/json"
)

type StoreGateway struct {
	listActivities func(int) any
	listReports    func(string, int) any
	actionReport   func(string, string, string, string) (any, error)
	overview       func() any
	userAnalytics  func(string) any
}

func NewStoreGateway(
	listActivities func(int) any,
	listReports func(string, int) any,
	actionReport func(string, string, string, string) (any, error),
	overview func() any,
	userAnalytics func(string) any,
) *StoreGateway {
	return &StoreGateway{
		listActivities: listActivities,
		listReports:    listReports,
		actionReport:   actionReport,
		overview:       overview,
		userAnalytics:  userAnalytics,
	}
}

func (g *StoreGateway) ListActivities(_ context.Context, limit int) ([]map[string]any, error) {
	return toMapSlice(g.listActivities(limit))
}

func (g *StoreGateway) ListReports(_ context.Context, status string, limit int) ([]map[string]any, error) {
	return toMapSlice(g.listReports(status, limit))
}

func (g *StoreGateway) ActionReport(
	_ context.Context,
	reportID, status, action, reviewedBy string,
) (map[string]any, error) {
	report, err := g.actionReport(reportID, status, action, reviewedBy)
	if err != nil {
		return nil, err
	}
	return toMap(report)
}

func (g *StoreGateway) AnalyticsOverview(_ context.Context) (map[string]any, error) {
	return toMap(g.overview())
}

func (g *StoreGateway) UserAnalytics(_ context.Context, userID string) (map[string]any, error) {
	return toMap(g.userAnalytics(userID))
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
