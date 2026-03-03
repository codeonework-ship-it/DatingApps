package observability

import (
	"context"
	"net/http"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"go.uber.org/zap"
)

func StartAdminServer(addr, service string, log *zap.Logger) *http.Server {
	if strings.TrimSpace(addr) == "" {
		return nil
	}

	router := chi.NewRouter()
	router.Use(middleware.Recoverer)
	router.Get("/healthz", func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(`{"service":"` + service + `","status":"ok"}`))
	})
	router.Get("/readyz", func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(`{"service":"` + service + `","status":"ready"}`))
	})
	router.Handle("/metrics", promhttp.Handler())
	router.Mount("/debug", middleware.Profiler())

	server := &http.Server{
		Addr:              addr,
		Handler:           router,
		ReadHeaderTimeout: 5 * time.Second,
	}

	go func() {
		log.Info("admin_server_started", zap.String("service", service), zap.String("addr", addr))
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatal("admin_server_failed", zap.String("service", service), zap.Error(err))
		}
	}()

	return server
}

func StopAdminServer(ctx context.Context, server *http.Server) {
	if server == nil {
		return
	}
	_ = server.Shutdown(ctx)
}
