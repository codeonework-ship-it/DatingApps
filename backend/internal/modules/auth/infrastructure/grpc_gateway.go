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

func (g *GRPCGateway) Login(ctx context.Context, username, password string) (map[string]any, error) {
	return g.invokeCredentials(ctx, rpc.AuthMethodLogin, username, password)
}

func (g *GRPCGateway) Signup(ctx context.Context, username, password string) (map[string]any, error) {
	return g.invokeCredentials(ctx, rpc.AuthMethodSignup, username, password)
}

func (g *GRPCGateway) invokeCredentials(ctx context.Context, method, username, password string) (map[string]any, error) {
	payload := map[string]any{"username": username, "password": password}
	if correlationID := observability.CorrelationIDFromContext(ctx); correlationID != "" {
		payload["correlation_id"] = correlationID
	}
	return rpc.InvokeStruct(ctx, g.client, method, payload)
}

func (g *GRPCGateway) SignupIntroducer(ctx context.Context, username, password, name, dob string) (map[string]any, error) {
	return rpc.InvokeStruct(ctx, g.client, rpc.AuthMethodSignup, map[string]any{"username": username, "password": password, "account_kind": "introducer", "name": name, "date_of_birth": dob})
}
