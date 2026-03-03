package rpc

import (
	"context"

	"google.golang.org/grpc"
	"google.golang.org/protobuf/types/known/structpb"
)

func InvokeStruct(
	ctx context.Context,
	client grpc.ClientConnInterface,
	method string,
	payload map[string]any,
) (map[string]any, error) {
	in, err := MapToStruct(payload)
	if err != nil {
		return nil, err
	}

	out := &structpb.Struct{}
	if err := client.Invoke(ctx, method, in, out); err != nil {
		return nil, err
	}
	return StructToMap(out), nil
}
