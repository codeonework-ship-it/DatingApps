package main

import (
	"context"
	"net/http"
	"os"
	"os/signal"
	"syscall"

	"github.com/prometheus/client_golang/prometheus"
	"go.uber.org/zap"

	"github.com/verified-dating/backend/internal/bff/mobile"
	"github.com/verified-dating/backend/internal/platform/config"
	"github.com/verified-dating/backend/internal/platform/observability"
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
	httpMetrics := observability.NewHTTPMetrics(reg)

	server, err := mobile.NewServer(cfg, log, httpMetrics)
	if err != nil {
		log.Fatal("create_mobile_bff_failed", zap.Error(err))
	}
	defer server.Close()

	httpServer := &http.Server{
		Addr:              cfg.MobileBFFAddr,
		Handler:           server.Handler(),
		ReadHeaderTimeout: cfg.MobileBFFReadHeaderTimeout(),
	}

	go func() {
		log.Info("mobile_bff_started", zap.String("addr", cfg.MobileBFFAddr))
		if err := httpServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatal("mobile_bff_failed", zap.Error(err))
		}
	}()

	awaitShutdown(log)
	shutdownCtx, cancel := context.WithTimeout(context.Background(), cfg.ShutdownTimeout())
	defer cancel()
	_ = httpServer.Shutdown(shutdownCtx)
	log.Info("mobile_bff_stopped")
}

func awaitShutdown(log *zap.Logger) {
	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)
	sig := <-sigCh
	log.Info("shutdown_signal_received", zap.String("signal", sig.String()))
}
