package infrastructure

import (
	"context"
	"errors"

	"google.golang.org/grpc"

	"github.com/verified-dating/backend/internal/contracts/rpc"
)

type GRPCGateway struct {
	client grpc.ClientConnInterface
}

func NewGRPCGateway(client grpc.ClientConnInterface) *GRPCGateway {
	return &GRPCGateway{client: client}
}

func (g *GRPCGateway) GetCandidates(ctx context.Context, userID string, limit int) (map[string]any, error) {
	return rpc.InvokeStruct(ctx, g.client, rpc.MatchingMethodCandidates, map[string]any{"user_id": userID, "limit": limit})
}

func (g *GRPCGateway) Swipe(ctx context.Context, payload map[string]any) (map[string]any, error) {
	return rpc.InvokeStruct(ctx, g.client, rpc.MatchingMethodSwipe, payload)
}

func (g *GRPCGateway) ListMatches(ctx context.Context, userID string) (map[string]any, error) {
	return rpc.InvokeStruct(ctx, g.client, rpc.MatchingMethodList, map[string]any{"user_id": userID})
}

func (g *GRPCGateway) Unmatch(ctx context.Context, matchID, userID string) (map[string]any, error) {
	return rpc.InvokeStruct(ctx, g.client, rpc.MatchingMethodUnmatch, map[string]any{"match_id": matchID, "user_id": userID})
}

func (g *GRPCGateway) MarkAsRead(ctx context.Context, payload map[string]any) (map[string]any, error) {
	return rpc.InvokeStruct(ctx, g.client, rpc.MatchingMethodRead, payload)
}

func (g *GRPCGateway) GetQuestTemplate(context.Context, string) (map[string]any, error) {
	return nil, errors.New("quest template store method not supported by grpc gateway")
}

func (g *GRPCGateway) UpsertQuestTemplate(context.Context, string, string, string, int, int) (map[string]any, error) {
	return nil, errors.New("quest template store method not supported by grpc gateway")
}

func (g *GRPCGateway) GetQuestWorkflow(context.Context, string) (map[string]any, error) {
	return nil, errors.New("quest workflow store method not supported by grpc gateway")
}

func (g *GRPCGateway) SubmitQuestResponse(context.Context, string, string, string) (map[string]any, error) {
	return nil, errors.New("quest workflow store method not supported by grpc gateway")
}

func (g *GRPCGateway) ReviewQuestResponse(context.Context, string, string, string, string) (map[string]any, error) {
	return nil, errors.New("quest workflow store method not supported by grpc gateway")
}

func (g *GRPCGateway) ListMatchGestures(context.Context, string) ([]map[string]any, error) {
	return nil, errors.New("gesture store method not supported by grpc gateway")
}

func (g *GRPCGateway) CreateMatchGesture(
	context.Context,
	string,
	string,
	string,
	string,
	string,
	string,
) (map[string]any, error) {
	return nil, errors.New("gesture store method not supported by grpc gateway")
}

func (g *GRPCGateway) DecideMatchGesture(context.Context, string, string, string, string, string) (map[string]any, error) {
	return nil, errors.New("gesture store method not supported by grpc gateway")
}

func (g *GRPCGateway) GetGestureScore(context.Context, string, string) (map[string]any, error) {
	return nil, errors.New("gesture store method not supported by grpc gateway")
}
