package rpc

import (
	"context"

	"google.golang.org/grpc"
	"google.golang.org/protobuf/types/known/structpb"
)

const (
	ProfileServiceName      = "profile.v1.ProfileService"
	ProfileMethodGetProfile = "/profile.v1.ProfileService/GetProfile"
	ProfileMethodUpsert     = "/profile.v1.ProfileService/UpsertProfile"
	ProfileMethodSummary    = "/profile.v1.ProfileService/GetProfileSummary"
)

type ProfileServer interface {
	GetProfile(context.Context, *structpb.Struct) (*structpb.Struct, error)
	UpsertProfile(context.Context, *structpb.Struct) (*structpb.Struct, error)
	GetProfileSummary(context.Context, *structpb.Struct) (*structpb.Struct, error)
}

func RegisterProfileServer(s grpc.ServiceRegistrar, srv ProfileServer) {
	s.RegisterService(&grpc.ServiceDesc{
		ServiceName: ProfileServiceName,
		HandlerType: (*ProfileServer)(nil),
		Methods: []grpc.MethodDesc{
			{MethodName: "GetProfile", Handler: profileGetHandler},
			{MethodName: "UpsertProfile", Handler: profileUpsertHandler},
			{MethodName: "GetProfileSummary", Handler: profileSummaryHandler},
		},
		Streams:  []grpc.StreamDesc{},
		Metadata: "api/proto/profile.proto",
	}, srv)
}

func profileGetHandler(
	srv any,
	ctx context.Context,
	dec func(any) error,
	interceptor grpc.UnaryServerInterceptor,
) (any, error) {
	in := new(structpb.Struct)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return srv.(ProfileServer).GetProfile(ctx, in)
	}
	info := &grpc.UnaryServerInfo{
		Server:     srv,
		FullMethod: ProfileMethodGetProfile,
	}
	handler := func(ctx context.Context, req any) (any, error) {
		return srv.(ProfileServer).GetProfile(ctx, req.(*structpb.Struct))
	}
	return interceptor(ctx, in, info, handler)
}

func profileUpsertHandler(
	srv any,
	ctx context.Context,
	dec func(any) error,
	interceptor grpc.UnaryServerInterceptor,
) (any, error) {
	in := new(structpb.Struct)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return srv.(ProfileServer).UpsertProfile(ctx, in)
	}
	info := &grpc.UnaryServerInfo{
		Server:     srv,
		FullMethod: ProfileMethodUpsert,
	}
	handler := func(ctx context.Context, req any) (any, error) {
		return srv.(ProfileServer).UpsertProfile(ctx, req.(*structpb.Struct))
	}
	return interceptor(ctx, in, info, handler)
}

func profileSummaryHandler(
	srv any,
	ctx context.Context,
	dec func(any) error,
	interceptor grpc.UnaryServerInterceptor,
) (any, error) {
	in := new(structpb.Struct)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return srv.(ProfileServer).GetProfileSummary(ctx, in)
	}
	info := &grpc.UnaryServerInfo{
		Server:     srv,
		FullMethod: ProfileMethodSummary,
	}
	handler := func(ctx context.Context, req any) (any, error) {
		return srv.(ProfileServer).GetProfileSummary(ctx, req.(*structpb.Struct))
	}
	return interceptor(ctx, in, info, handler)
}
