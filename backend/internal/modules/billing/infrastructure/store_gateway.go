package infrastructure

import (
	"context"
	"encoding/json"
)

type StoreGateway struct {
	listPlans       func() any
	getSubscription func(string) any
	subscribe       func(string, string, string) (any, any, error)
	listPayments    func(string, int) any
}

func NewStoreGateway(
	listPlans func() any,
	getSubscription func(string) any,
	subscribe func(string, string, string) (any, any, error),
	listPayments func(string, int) any,
) *StoreGateway {
	return &StoreGateway{
		listPlans:       listPlans,
		getSubscription: getSubscription,
		subscribe:       subscribe,
		listPayments:    listPayments,
	}
}

func (g *StoreGateway) ListPlans(_ context.Context) ([]map[string]any, error) {
	return toMapSlice(g.listPlans())
}

func (g *StoreGateway) GetSubscription(_ context.Context, userID string) (map[string]any, error) {
	return toMap(g.getSubscription(userID))
}

func (g *StoreGateway) Subscribe(_ context.Context, userID, planID, billingCycle string) (map[string]any, map[string]any, error) {
	subscription, payment, err := g.subscribe(userID, planID, billingCycle)
	if err != nil {
		return nil, nil, err
	}
	subscriptionMap, err := toMap(subscription)
	if err != nil {
		return nil, nil, err
	}
	paymentMap, err := toMap(payment)
	if err != nil {
		return nil, nil, err
	}
	return subscriptionMap, paymentMap, nil
}

func (g *StoreGateway) ListPayments(_ context.Context, userID string, limit int) ([]map[string]any, error) {
	return toMapSlice(g.listPayments(userID, limit))
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
