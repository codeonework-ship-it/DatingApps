package infrastructure

import (
	"context"

	"google.golang.org/grpc"

	"github.com/verified-dating/backend/internal/contracts/rpc"
)

type GRPCGateway struct {
	client grpc.ClientConnInterface
}

func NewGRPCGateway(client grpc.ClientConnInterface) *GRPCGateway {
	return &GRPCGateway{client: client}
}

func (g *GRPCGateway) ListMessages(ctx context.Context, matchID string, limit int) (map[string]any, error) {
	return rpc.InvokeStruct(ctx, g.client, rpc.ChatMethodListMessages, map[string]any{"match_id": matchID, "limit": limit})
}

func (g *GRPCGateway) SendMessage(ctx context.Context, payload map[string]any) (map[string]any, error) {
	return rpc.InvokeStruct(ctx, g.client, rpc.ChatMethodSendMessage, payload)
}
