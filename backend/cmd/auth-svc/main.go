package main

import (
	"os"
	"os/signal"
	"syscall"

	"github.com/prometheus/client_golang/prometheus"
	"go.uber.org/zap"
	"google.golang.org/grpc"

	"github.com/verified-dating/backend/internal/contracts/rpc"
	"github.com/verified-dating/backend/internal/platform/config"
	"github.com/verified-dating/backend/internal/platform/grpcx"
	"github.com/verified-dating/backend/internal/platform/observability"
	"github.com/verified-dating/backend/internal/services/auth"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		panic(err)
	}

	log, err := observability.NewLogger(cfg.Environment, cfg.LogLevel)
	if err != nil {
		panic(err)
	}
	defer func() { _ = log.Sync() }()

	reg := prometheus.DefaultRegisterer
	grpcMetrics := observability.NewGRPCMetrics(reg)
	interceptor := observability.UnaryServerInterceptor(log, grpcMetrics)

	server, err := grpcx.New(cfg.AuthGRPCAddr, log, grpc.UnaryInterceptor(interceptor))
	if err != nil {
		log.Fatal("create_grpc_server_failed", zap.Error(err))
	}

	adminServer := observability.StartAdminServer(cfg.AuthAdminAddr, "auth-svc", log)

	authRepo := auth.NewRepository(cfg, log)
	authService := auth.NewService(authRepo, log)
	rpc.RegisterAuthServer(server.GRPC(), authService)

	go func() {
		if err := server.Start(); err != nil {
			log.Fatal("auth_grpc_server_failed", zap.Error(err))
		}
	}()

	awaitShutdown(log)
	shutdownCtx, cancel := grpcx.GracefulContext(cfg.ShutdownTimeout())
	defer cancel()
	observability.StopAdminServer(shutdownCtx, adminServer)
	server.Shutdown(shutdownCtx)
}

func awaitShutdown(log *zap.Logger) {
	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)
	sig := <-sigCh
	log.Info("shutdown_signal_received", zap.String("signal", sig.String()))
}
