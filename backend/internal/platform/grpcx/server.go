package grpcx

import (
	"context"
	"net"
	"time"

	"go.uber.org/zap"
	"google.golang.org/grpc"
)

type Server struct {
	grpcServer *grpc.Server
	listener   net.Listener
	addr       string
	log        *zap.Logger
}

func New(addr string, log *zap.Logger, opts ...grpc.ServerOption) (*Server, error) {
	listener, err := net.Listen("tcp", addr)
	if err != nil {
		return nil, err
	}

	return &Server{
		grpcServer: grpc.NewServer(opts...),
		listener:   listener,
		addr:       addr,
		log:        log,
	}, nil
}

func (s *Server) GRPC() *grpc.Server {
	return s.grpcServer
}

func (s *Server) Start() error {
	s.log.Info("grpc_server_started", zap.String("addr", s.addr))
	return s.grpcServer.Serve(s.listener)
}

func (s *Server) Shutdown(ctx context.Context) {
	done := make(chan struct{})
	go func() {
		s.grpcServer.GracefulStop()
		close(done)
	}()

	select {
	case <-ctx.Done():
		s.grpcServer.Stop()
	case <-done:
	}

	s.log.Info("grpc_server_stopped", zap.String("addr", s.addr))
}

func GracefulContext(timeout time.Duration) (context.Context, context.CancelFunc) {
	return context.WithTimeout(context.Background(), timeout)
}
