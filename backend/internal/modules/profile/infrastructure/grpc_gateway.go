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

func (g *GRPCGateway) GetProfile(ctx context.Context, userID string) (map[string]any, error) {
	return rpc.InvokeStruct(ctx, g.client, rpc.ProfileMethodGetProfile, map[string]any{"user_id": userID})
}

func (g *GRPCGateway) GetProfileSummary(ctx context.Context, userID string) (map[string]any, error) {
	return rpc.InvokeStruct(ctx, g.client, rpc.ProfileMethodSummary, map[string]any{"user_id": userID})
}

func (g *GRPCGateway) UpsertProfile(ctx context.Context, payload map[string]any) (map[string]any, error) {
	return rpc.InvokeStruct(ctx, g.client, rpc.ProfileMethodUpsert, payload)
}

func (g *GRPCGateway) GetDraft(context.Context, string) (map[string]any, error) {
	return nil, errors.New("profile draft methods not supported by grpc gateway")
}

func (g *GRPCGateway) PatchDraft(context.Context, string, map[string]any) (map[string]any, error) {
	return nil, errors.New("profile draft methods not supported by grpc gateway")
}

func (g *GRPCGateway) AddPhoto(context.Context, string, string) (map[string]any, error) {
	return nil, errors.New("profile photo methods not supported by grpc gateway")
}

func (g *GRPCGateway) DeletePhoto(context.Context, string, string) (map[string]any, error) {
	return nil, errors.New("profile photo methods not supported by grpc gateway")
}

func (g *GRPCGateway) ReorderPhotos(context.Context, string, []string) (map[string]any, error) {
	return nil, errors.New("profile photo methods not supported by grpc gateway")
}

func (g *GRPCGateway) CompleteProfile(context.Context, string) (map[string]any, error) {
	return nil, errors.New("profile complete method not supported by grpc gateway")
}

func (g *GRPCGateway) GetSettings(context.Context, string) (map[string]any, error) {
	return nil, errors.New("profile settings methods not supported by grpc gateway")
}

func (g *GRPCGateway) PatchSettings(context.Context, string, map[string]any) (map[string]any, error) {
	return nil, errors.New("profile settings methods not supported by grpc gateway")
}

func (g *GRPCGateway) ListEmergencyContacts(context.Context, string) ([]map[string]any, error) {
	return nil, errors.New("profile emergency methods not supported by grpc gateway")
}

func (g *GRPCGateway) AddEmergencyContact(context.Context, string, string, string) ([]map[string]any, error) {
	return nil, errors.New("profile emergency methods not supported by grpc gateway")
}

func (g *GRPCGateway) UpdateEmergencyContact(context.Context, string, string, string, string) ([]map[string]any, error) {
	return nil, errors.New("profile emergency methods not supported by grpc gateway")
}

func (g *GRPCGateway) DeleteEmergencyContact(context.Context, string, string) ([]map[string]any, error) {
	return nil, errors.New("profile emergency methods not supported by grpc gateway")
}

func (g *GRPCGateway) ListBlockedUsers(context.Context, string) ([]map[string]any, error) {
	return nil, errors.New("profile blocked methods not supported by grpc gateway")
}
