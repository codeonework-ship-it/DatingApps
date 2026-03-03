package infrastructure

import (
	"context"

	"google.golang.org/grpc"

	"github.com/verified-dating/backend/internal/contracts/rpc"
	"github.com/verified-dating/backend/internal/platform/observability"
)

type GRPCGateway struct {
	client grpc.ClientConnInterface
}

func NewGRPCGateway(client grpc.ClientConnInterface) *GRPCGateway {
	return &GRPCGateway{client: client}
}

func (g *GRPCGateway) SendOTP(ctx context.Context, email string) (map[string]any, error) {
	payload := map[string]any{"email": email}
	if correlationID := observability.CorrelationIDFromContext(ctx); correlationID != "" {
		payload["correlation_id"] = correlationID
	}
	return rpc.InvokeStruct(ctx, g.client, rpc.AuthMethodSendOTP, payload)
}

func (g *GRPCGateway) VerifyOTP(ctx context.Context, email string, otp string) (map[string]any, error) {
	payload := map[string]any{"email": email, "otp": otp}
	if correlationID := observability.CorrelationIDFromContext(ctx); correlationID != "" {
		payload["correlation_id"] = correlationID
	}
	return rpc.InvokeStruct(ctx, g.client, rpc.AuthMethodVerify, payload)
}
