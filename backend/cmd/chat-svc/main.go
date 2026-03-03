package main

import (
	"context"
	"os"
	"os/signal"
	"syscall"

	"github.com/prometheus/client_golang/prometheus"
	"go.uber.org/zap"
	"google.golang.org/grpc"

	"github.com/verified-dating/backend/internal/contracts/rpc"
	"github.com/verified-dating/backend/internal/platform/concurrency"
	"github.com/verified-dating/backend/internal/platform/config"
	"github.com/verified-dating/backend/internal/platform/grpcx"
	"github.com/verified-dating/backend/internal/platform/observability"
	"github.com/verified-dating/backend/internal/platform/supabase"
	"github.com/verified-dating/backend/internal/services/chat"
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

	runtimeCtx, runtimeCancel := context.WithCancel(context.Background())
	defer runtimeCancel()

	workers := concurrency.NewWorkerPool(cfg.ChatWorkerCount, cfg.ChatWorkerQueueSize)
	workers.Start(runtimeCtx)
	defer workers.Close()

	db := supabase.NewClient(
		cfg.SupabaseURL,
		cfg.SupabaseAnonKey,
		cfg.SupabaseServiceRole,
		cfg.SupabaseHTTPTimeout(),
	)
	realtime := supabase.NewRealtimeClient(
		cfg.SupabaseURL,
		cfg.SupabaseAnonKey,
		log,
		cfg.ChatRealtimeLogLevel,
		cfg.ChatRealtimeHeartbeat(),
	)
	chatRepo := chat.NewRepository(db, cfg)
	chatService := chat.NewService(chatRepo, realtime, workers, log, cfg)
	if err := chatService.StartRealtime(runtimeCtx); err != nil {
		log.Warn("chat_realtime_start_failed", zap.Error(err))
	}
	defer func() { _ = realtime.Close() }()

	server, err := grpcx.New(cfg.ChatGRPCAddr, log, grpc.UnaryInterceptor(interceptor))
	if err != nil {
		log.Fatal("create_grpc_server_failed", zap.Error(err))
	}

	adminServer := observability.StartAdminServer(cfg.ChatAdminAddr, "chat-svc", log)

	rpc.RegisterChatServer(server.GRPC(), chatService)

	go func() {
		if err := server.Start(); err != nil {
			log.Fatal("chat_grpc_server_failed", zap.Error(err))
		}
	}()

	awaitShutdown(log)
	runtimeCancel()

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
