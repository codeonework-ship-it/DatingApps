package rpc

import (
	"context"

	"google.golang.org/grpc"
	"google.golang.org/protobuf/types/known/structpb"
)

const (
	AuthServiceName  = "auth.v1.AuthService"
	AuthMethodLogin  = "/auth.v1.AuthService/Login"
	AuthMethodSignup = "/auth.v1.AuthService/Signup"
)

type AuthServer interface {
	Login(context.Context, *structpb.Struct) (*structpb.Struct, error)
	Signup(context.Context, *structpb.Struct) (*structpb.Struct, error)
}

func RegisterAuthServer(s grpc.ServiceRegistrar, srv AuthServer) {
	s.RegisterService(&grpc.ServiceDesc{
		ServiceName: AuthServiceName,
		HandlerType: (*AuthServer)(nil),
		Methods: []grpc.MethodDesc{
			{MethodName: "Login", Handler: authLoginHandler},
			{MethodName: "Signup", Handler: authSignupHandler},
		},
		Streams:  []grpc.StreamDesc{},
		Metadata: "api/proto/auth.proto",
	}, srv)
}

func authLoginHandler(srv any, ctx context.Context, dec func(any) error, interceptor grpc.UnaryServerInterceptor) (any, error) {
	return authUnaryHandler(srv, ctx, dec, interceptor, AuthMethodLogin, func(server AuthServer, ctx context.Context, req *structpb.Struct) (*structpb.Struct, error) {
		return server.Login(ctx, req)
	})
}

func authSignupHandler(srv any, ctx context.Context, dec func(any) error, interceptor grpc.UnaryServerInterceptor) (any, error) {
	return authUnaryHandler(srv, ctx, dec, interceptor, AuthMethodSignup, func(server AuthServer, ctx context.Context, req *structpb.Struct) (*structpb.Struct, error) {
		return server.Signup(ctx, req)
	})
}

func authUnaryHandler(
	srv any,
	ctx context.Context,
	dec func(any) error,
	interceptor grpc.UnaryServerInterceptor,
	method string,
	invoke func(AuthServer, context.Context, *structpb.Struct) (*structpb.Struct, error),
) (any, error) {
	in := new(structpb.Struct)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return invoke(srv.(AuthServer), ctx, in)
	}
	info := &grpc.UnaryServerInfo{Server: srv, FullMethod: method}
	handler := func(ctx context.Context, req any) (any, error) {
		return invoke(srv.(AuthServer), ctx, req.(*structpb.Struct))
	}
	return interceptor(ctx, in, info, handler)
}
