package rpc

import (
	"context"

	"google.golang.org/grpc"
	"google.golang.org/protobuf/types/known/structpb"
)

const (
	AuthServiceName   = "auth.v1.AuthService"
	AuthMethodSendOTP = "/auth.v1.AuthService/SendOtp"
	AuthMethodVerify  = "/auth.v1.AuthService/VerifyOtp"
)

type AuthServer interface {
	SendOtp(context.Context, *structpb.Struct) (*structpb.Struct, error)
	VerifyOtp(context.Context, *structpb.Struct) (*structpb.Struct, error)
}

func RegisterAuthServer(s grpc.ServiceRegistrar, srv AuthServer) {
	s.RegisterService(&grpc.ServiceDesc{
		ServiceName: AuthServiceName,
		HandlerType: (*AuthServer)(nil),
		Methods: []grpc.MethodDesc{
			{MethodName: "SendOtp", Handler: authSendOTPHandler},
			{MethodName: "VerifyOtp", Handler: authVerifyOTPHandler},
		},
		Streams:  []grpc.StreamDesc{},
		Metadata: "api/proto/auth.proto",
	}, srv)
}

func authSendOTPHandler(
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
		return srv.(AuthServer).SendOtp(ctx, in)
	}
	info := &grpc.UnaryServerInfo{
		Server:     srv,
		FullMethod: AuthMethodSendOTP,
	}
	handler := func(ctx context.Context, req any) (any, error) {
		return srv.(AuthServer).SendOtp(ctx, req.(*structpb.Struct))
	}
	return interceptor(ctx, in, info, handler)
}

func authVerifyOTPHandler(
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
		return srv.(AuthServer).VerifyOtp(ctx, in)
	}
	info := &grpc.UnaryServerInfo{
		Server:     srv,
		FullMethod: AuthMethodVerify,
	}
	handler := func(ctx context.Context, req any) (any, error) {
		return srv.(AuthServer).VerifyOtp(ctx, req.(*structpb.Struct))
	}
	return interceptor(ctx, in, info, handler)
}
