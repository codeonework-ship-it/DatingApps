package observability

import (
	"context"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"go.uber.org/zap"
	"google.golang.org/grpc"
	"google.golang.org/grpc/status"
)

type GRPCMetrics struct {
	RequestCount *prometheus.CounterVec
	Latency      *prometheus.HistogramVec
}

func NewGRPCMetrics(reg prometheus.Registerer) *GRPCMetrics {
	m := &GRPCMetrics{
		RequestCount: prometheus.NewCounterVec(
			prometheus.CounterOpts{
				Namespace: "verified_dating",
				Subsystem: "grpc",
				Name:      "requests_total",
				Help:      "Total gRPC requests.",
			},
			[]string{"method", "code"},
		),
		Latency: prometheus.NewHistogramVec(
			prometheus.HistogramOpts{
				Namespace: "verified_dating",
				Subsystem: "grpc",
				Name:      "request_duration_seconds",
				Help:      "gRPC request latency.",
				Buckets:   prometheus.DefBuckets,
			},
			[]string{"method"},
		),
	}

	reg.MustRegister(m.RequestCount, m.Latency)
	return m
}

func UnaryServerInterceptor(log *zap.Logger, metrics *GRPCMetrics) grpc.UnaryServerInterceptor {
	return func(
		ctx context.Context,
		req any,
		info *grpc.UnaryServerInfo,
		handler grpc.UnaryHandler,
	) (any, error) {
		start := time.Now()
		resp, err := handler(ctx, req)

		duration := time.Since(start).Seconds()
		code := status.Code(err).String()

		metrics.RequestCount.WithLabelValues(info.FullMethod, code).Inc()
		metrics.Latency.WithLabelValues(info.FullMethod).Observe(duration)

		log.Info("grpc_request",
			zap.String("method", info.FullMethod),
			zap.String("code", code),
			zap.Float64("duration_seconds", duration),
		)

		return resp, err
	}
}
