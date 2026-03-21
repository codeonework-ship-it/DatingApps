package rpc

import (
	"context"

	"google.golang.org/grpc"
	"google.golang.org/protobuf/types/known/structpb"
)

const (
	ChatServiceName         = "chat.v1.ChatService"
	ChatMethodListMessages  = "/chat.v1.ChatService/ListMessages"
	ChatMethodSendMessage   = "/chat.v1.ChatService/SendMessage"
	ChatMethodDeleteMessage = "/chat.v1.ChatService/DeleteMessage"
)

type ChatServer interface {
	ListMessages(context.Context, *structpb.Struct) (*structpb.Struct, error)
	SendMessage(context.Context, *structpb.Struct) (*structpb.Struct, error)
	DeleteMessage(context.Context, *structpb.Struct) (*structpb.Struct, error)
}

func RegisterChatServer(s grpc.ServiceRegistrar, srv ChatServer) {
	s.RegisterService(&grpc.ServiceDesc{
		ServiceName: ChatServiceName,
		HandlerType: (*ChatServer)(nil),
		Methods: []grpc.MethodDesc{
			{MethodName: "ListMessages", Handler: chatListMessagesHandler},
			{MethodName: "SendMessage", Handler: chatSendMessageHandler},
			{MethodName: "DeleteMessage", Handler: chatDeleteMessageHandler},
		},
		Streams:  []grpc.StreamDesc{},
		Metadata: "api/proto/chat.proto",
	}, srv)
}

func chatListMessagesHandler(
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
		return srv.(ChatServer).ListMessages(ctx, in)
	}
	info := &grpc.UnaryServerInfo{
		Server:     srv,
		FullMethod: ChatMethodListMessages,
	}
	handler := func(ctx context.Context, req any) (any, error) {
		return srv.(ChatServer).ListMessages(ctx, req.(*structpb.Struct))
	}
	return interceptor(ctx, in, info, handler)
}

func chatSendMessageHandler(
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
		return srv.(ChatServer).SendMessage(ctx, in)
	}
	info := &grpc.UnaryServerInfo{
		Server:     srv,
		FullMethod: ChatMethodSendMessage,
	}
	handler := func(ctx context.Context, req any) (any, error) {
		return srv.(ChatServer).SendMessage(ctx, req.(*structpb.Struct))
	}
	return interceptor(ctx, in, info, handler)
}

func chatDeleteMessageHandler(
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
		return srv.(ChatServer).DeleteMessage(ctx, in)
	}
	info := &grpc.UnaryServerInfo{
		Server:     srv,
		FullMethod: ChatMethodDeleteMessage,
	}
	handler := func(ctx context.Context, req any) (any, error) {
		return srv.(ChatServer).DeleteMessage(ctx, req.(*structpb.Struct))
	}
	return interceptor(ctx, in, info, handler)
}
