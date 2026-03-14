package main

import (
	"context"
	"net/http"
	"os"
	"os/signal"
	"syscall"

	"github.com/prometheus/client_golang/prometheus"
	"go.uber.org/zap"

	gatewayhttp "github.com/verified-dating/backend/internal/gateway/http"
	"github.com/verified-dating/backend/internal/platform/config"
	"github.com/verified-dating/backend/internal/platform/observability"
	"github.com/verified-dating/backend/internal/platform/postgres"
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

	if err := postgres.Probe(cfg.DatabaseURL, cfg.DatabaseHost, cfg.DatabasePort, cfg.GatewayReadyProbeTimeout()); err != nil {
		if cfg.GatewaySkipPostgresProbe {
			log.Warn(
				"postgres_probe_skipped",
				zap.Error(err),
				zap.String("host", cfg.DatabaseHost),
				zap.Int("port", cfg.DatabasePort),
			)
		} else {
			log.Fatal("postgres_probe_failed", zap.Error(err))
		}
	} else {
		log.Info(
			"postgres_probe_ok",
			zap.String("host", cfg.DatabaseHost),
			zap.Int("port", cfg.DatabasePort),
		)
	}

	reg := prometheus.DefaultRegisterer
	httpMetrics := observability.NewHTTPMetrics(reg)

	router, err := gatewayhttp.NewRouter(
		log,
		httpMetrics,
		cfg.MobileBFFUpstreamURL,
		cfg.APIPrefix,
		cfg.GatewayRateLimitRequests,
		cfg.GatewayRateLimitWindow(),
		cfg.GatewayMaxInFlight,
		cfg.GatewayRetryAfterSec,
		cfg.GatewayReadyProbeTimeout(),
	)
	if err != nil {
		log.Fatal("create_gateway_router_failed", zap.Error(err))
	}

	httpServer := &http.Server{
		Addr:              cfg.APIGatewayAddr,
		Handler:           router,
		ReadHeaderTimeout: cfg.APIGatewayReadHeaderTimeout(),
	}

	go func() {
		log.Info("api_gateway_started", zap.String("addr", cfg.APIGatewayAddr))
		if err := httpServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatal("api_gateway_failed", zap.Error(err))
		}
	}()

	awaitShutdown(log)
	shutdownCtx, cancel := context.WithTimeout(context.Background(), cfg.ShutdownTimeout())
	defer cancel()
	_ = httpServer.Shutdown(shutdownCtx)
	log.Info("api_gateway_stopped")
}

func awaitShutdown(log *zap.Logger) {
	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)
	sig := <-sigCh
	log.Info("shutdown_signal_received", zap.String("signal", sig.String()))
}
