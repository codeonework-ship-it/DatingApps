package rpc

import (
	"context"

	"google.golang.org/grpc"
	"google.golang.org/protobuf/types/known/structpb"
)

const (
	MatchingServiceName      = "matching.v1.MatchingService"
	MatchingMethodCandidates = "/matching.v1.MatchingService/GetCandidates"
	MatchingMethodSwipe      = "/matching.v1.MatchingService/Swipe"
	MatchingMethodList       = "/matching.v1.MatchingService/ListMatches"
	MatchingMethodRead       = "/matching.v1.MatchingService/MarkAsRead"
	MatchingMethodUnmatch    = "/matching.v1.MatchingService/Unmatch"
)

type MatchingServer interface {
	GetCandidates(context.Context, *structpb.Struct) (*structpb.Struct, error)
	Swipe(context.Context, *structpb.Struct) (*structpb.Struct, error)
	ListMatches(context.Context, *structpb.Struct) (*structpb.Struct, error)
	MarkAsRead(context.Context, *structpb.Struct) (*structpb.Struct, error)
	Unmatch(context.Context, *structpb.Struct) (*structpb.Struct, error)
}

func RegisterMatchingServer(s grpc.ServiceRegistrar, srv MatchingServer) {
	s.RegisterService(&grpc.ServiceDesc{
		ServiceName: MatchingServiceName,
		HandlerType: (*MatchingServer)(nil),
		Methods: []grpc.MethodDesc{
			{MethodName: "GetCandidates", Handler: matchingCandidatesHandler},
			{MethodName: "Swipe", Handler: matchingSwipeHandler},
			{MethodName: "ListMatches", Handler: matchingListHandler},
			{MethodName: "MarkAsRead", Handler: matchingReadHandler},
			{MethodName: "Unmatch", Handler: matchingUnmatchHandler},
		},
		Streams:  []grpc.StreamDesc{},
		Metadata: "api/proto/matching.proto",
	}, srv)
}

func matchingCandidatesHandler(
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
		return srv.(MatchingServer).GetCandidates(ctx, in)
	}
	info := &grpc.UnaryServerInfo{
		Server:     srv,
		FullMethod: MatchingMethodCandidates,
	}
	handler := func(ctx context.Context, req any) (any, error) {
		return srv.(MatchingServer).GetCandidates(ctx, req.(*structpb.Struct))
	}
	return interceptor(ctx, in, info, handler)
}

func matchingSwipeHandler(
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
		return srv.(MatchingServer).Swipe(ctx, in)
	}
	info := &grpc.UnaryServerInfo{
		Server:     srv,
		FullMethod: MatchingMethodSwipe,
	}
	handler := func(ctx context.Context, req any) (any, error) {
		return srv.(MatchingServer).Swipe(ctx, req.(*structpb.Struct))
	}
	return interceptor(ctx, in, info, handler)
}

func matchingListHandler(
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
		return srv.(MatchingServer).ListMatches(ctx, in)
	}
	info := &grpc.UnaryServerInfo{
		Server:     srv,
		FullMethod: MatchingMethodList,
	}
	handler := func(ctx context.Context, req any) (any, error) {
		return srv.(MatchingServer).ListMatches(ctx, req.(*structpb.Struct))
	}
	return interceptor(ctx, in, info, handler)
}

func matchingReadHandler(
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
		return srv.(MatchingServer).MarkAsRead(ctx, in)
	}
	info := &grpc.UnaryServerInfo{
		Server:     srv,
		FullMethod: MatchingMethodRead,
	}
	handler := func(ctx context.Context, req any) (any, error) {
		return srv.(MatchingServer).MarkAsRead(ctx, req.(*structpb.Struct))
	}
	return interceptor(ctx, in, info, handler)
}

func matchingUnmatchHandler(
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
		return srv.(MatchingServer).Unmatch(ctx, in)
	}
	info := &grpc.UnaryServerInfo{
		Server:     srv,
		FullMethod: MatchingMethodUnmatch,
	}
	handler := func(ctx context.Context, req any) (any, error) {
		return srv.(MatchingServer).Unmatch(ctx, req.(*structpb.Struct))
	}
	return interceptor(ctx, in, info, handler)
}
