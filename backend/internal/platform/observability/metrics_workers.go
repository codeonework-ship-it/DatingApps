package observability

import (
	"context"
	"errors"
	"sync"
	"sync/atomic"
	"time"

	"github.com/prometheus/client_golang/prometheus"
)

// Worker run results recorded on verified_dating_worker_runs_total.
const (
	WorkerResultSuccess = "success"
	WorkerResultError   = "error"
)

// WorkerMetrics are the heartbeat collectors for background workers:
//
//	verified_dating_worker_last_success_timestamp_seconds{worker}
//	verified_dating_worker_last_run_timestamp_seconds{worker}
//	verified_dating_worker_expected_interval_seconds{worker}
//	verified_dating_worker_runs_total{worker,result}
//	verified_dating_worker_run_duration_seconds{worker}
//	verified_dating_worker_items_total{worker,outcome}
//	verified_dating_worker_backlog{worker}
//
// The staleness alert compares time() - last_success with a multiple of
// expected_interval, so every worker carries its own cadence. When a worker
// first runs, last_success is seeded with the process start of that worker
// so a worker that never succeeds goes stale after the same grace period.
type WorkerMetrics struct {
	lastSuccess *prometheus.GaugeVec
	lastRun     *prometheus.GaugeVec
	expected    *prometheus.GaugeVec
	runs        *prometheus.CounterVec
	duration    *prometheus.HistogramVec
	items       *prometheus.CounterVec
	backlog     *prometheus.GaugeVec

	mu     sync.Mutex
	seeded map[string]bool
	now    func() time.Time
}

func NewWorkerMetrics(reg prometheus.Registerer) *WorkerMetrics {
	m := &WorkerMetrics{
		lastSuccess: prometheus.NewGaugeVec(prometheus.GaugeOpts{
			Namespace: "verified_dating", Subsystem: "worker", Name: "last_success_timestamp_seconds",
			Help: "Unix time of the worker's last successful run (seeded with the worker's start time).",
		}, []string{"worker"}),
		lastRun: prometheus.NewGaugeVec(prometheus.GaugeOpts{
			Namespace: "verified_dating", Subsystem: "worker", Name: "last_run_timestamp_seconds",
			Help: "Unix time the worker last finished a run, successful or not.",
		}, []string{"worker"}),
		expected: prometheus.NewGaugeVec(prometheus.GaugeOpts{
			Namespace: "verified_dating", Subsystem: "worker", Name: "expected_interval_seconds",
			Help: "Configured interval between worker runs; staleness alerts use a multiple of it.",
		}, []string{"worker"}),
		runs: prometheus.NewCounterVec(prometheus.CounterOpts{
			Namespace: "verified_dating", Subsystem: "worker", Name: "runs_total",
			Help: "Background worker runs by result (success or error).",
		}, []string{"worker", "result"}),
		duration: prometheus.NewHistogramVec(prometheus.HistogramOpts{
			Namespace: "verified_dating", Subsystem: "worker", Name: "run_duration_seconds",
			Help:    "Background worker run duration.",
			Buckets: []float64{0.005, 0.025, 0.1, 0.5, 1, 5, 15, 60, 300, 900},
		}, []string{"worker"}),
		items: prometheus.NewCounterVec(prometheus.CounterOpts{
			Namespace: "verified_dating", Subsystem: "worker", Name: "items_total",
			Help: "Items handled by background workers by outcome (processed or failed).",
		}, []string{"worker", "outcome"}),
		backlog: prometheus.NewGaugeVec(prometheus.GaugeOpts{
			Namespace: "verified_dating", Subsystem: "worker", Name: "backlog",
			Help: "Work waiting for a background worker, where the worker can measure it.",
		}, []string{"worker"}),
		seeded: map[string]bool{},
		now:    time.Now,
	}
	reg.MustRegister(m.lastSuccess, m.lastRun, m.expected, m.runs, m.duration, m.items, m.backlog)
	return m
}

var defaultWorkerMetrics atomic.Pointer[WorkerMetrics]

// SetDefaultWorkerMetrics installs the collectors used by heartbeats created
// with NewHeartbeat. NewBFFMetrics calls it; processes that never call it get
// no-op heartbeats and expose no worker series.
func SetDefaultWorkerMetrics(m *WorkerMetrics) { defaultWorkerMetrics.Store(m) }

// DefaultWorkerMetrics returns the process default (nil when unset).
func DefaultWorkerMetrics() *WorkerMetrics { return defaultWorkerMetrics.Load() }

// Heartbeat instruments one named background worker. It is safe to create
// before metrics are registered and safe to use from several goroutines.
type Heartbeat struct {
	worker   string
	interval time.Duration
	fixed    *WorkerMetrics
}

// NewHeartbeat returns a heartbeat bound to the process default worker
// metrics (resolved on every use, so construction order does not matter).
// worker must be a fixed, code-defined name: it becomes a label value.
func NewHeartbeat(worker string, interval time.Duration) *Heartbeat {
	return &Heartbeat{worker: worker, interval: interval}
}

// Heartbeat returns a heartbeat bound to these specific collectors.
func (m *WorkerMetrics) Heartbeat(worker string, interval time.Duration) *Heartbeat {
	return &Heartbeat{worker: worker, interval: interval, fixed: m}
}

func (h *Heartbeat) metrics() *WorkerMetrics {
	if h == nil {
		return nil
	}
	if h.fixed != nil {
		return h.fixed
	}
	return DefaultWorkerMetrics()
}

// Begin marks the start of one run. The first Begin publishes the expected
// interval and seeds last_success.
func (h *Heartbeat) Begin() *WorkerRun {
	m := h.metrics()
	if m == nil {
		return &WorkerRun{}
	}
	now := m.now()
	m.mu.Lock()
	if !m.seeded[h.worker] {
		m.seeded[h.worker] = true
		m.expected.WithLabelValues(h.worker).Set(h.interval.Seconds())
		m.lastSuccess.WithLabelValues(h.worker).Set(float64(now.UnixNano()) / 1e9)
	}
	m.mu.Unlock()
	return &WorkerRun{heartbeat: h, metrics: m, started: now}
}

// SetBacklog publishes the amount of work waiting for this worker.
func (h *Heartbeat) SetBacklog(value float64) {
	if m := h.metrics(); m != nil {
		m.backlog.WithLabelValues(h.worker).Set(value)
	}
}

// WorkerRun is one in-progress run; finish it with End exactly once.
type WorkerRun struct {
	heartbeat *Heartbeat
	metrics   *WorkerMetrics
	started   time.Time
	done      bool
}

// Items counts items handled in this run ("processed", "failed", ...).
func (r *WorkerRun) Items(outcome string, n int) {
	if r == nil || r.metrics == nil || n <= 0 {
		return
	}
	r.metrics.items.WithLabelValues(r.heartbeat.worker, outcome).Add(float64(n))
}

// End records the run. A nil error is a success; context cancellation (the
// process shutting down) records nothing so it neither refreshes nor fails
// the heartbeat.
func (r *WorkerRun) End(err error) {
	if r == nil || r.metrics == nil || r.done {
		return
	}
	r.done = true
	if err != nil && errors.Is(err, context.Canceled) {
		return
	}
	m, worker := r.metrics, r.heartbeat.worker
	now := m.now()
	m.duration.WithLabelValues(worker).Observe(now.Sub(r.started).Seconds())
	m.lastRun.WithLabelValues(worker).Set(float64(now.UnixNano()) / 1e9)
	if err != nil {
		m.runs.WithLabelValues(worker, WorkerResultError).Inc()
		return
	}
	m.runs.WithLabelValues(worker, WorkerResultSuccess).Inc()
	m.lastSuccess.WithLabelValues(worker).Set(float64(now.UnixNano()) / 1e9)
}
