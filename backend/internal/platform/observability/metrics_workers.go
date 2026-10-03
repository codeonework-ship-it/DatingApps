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
// interval and seeds last_success. The run is recorded on the worker run sink
// (SetWorkerRunSink) even when no Prometheus collectors are installed.
func (h *Heartbeat) Begin() *WorkerRun {
	if h == nil {
		return &WorkerRun{}
	}
	m := h.metrics()
	now := time.Now()
	if m != nil {
		now = m.now()
		m.mu.Lock()
		if !m.seeded[h.worker] {
			m.seeded[h.worker] = true
			m.expected.WithLabelValues(h.worker).Set(h.interval.Seconds())
			m.lastSuccess.WithLabelValues(h.worker).Set(float64(now.UnixNano()) / 1e9)
		}
		m.mu.Unlock()
	}
	registerWorker(h.worker, h.interval, now)
	return &WorkerRun{heartbeat: h, metrics: m, started: now}
}

// SetBacklog publishes the amount of work waiting for this worker. The last
// value is also kept in-process as the backlog_after of the next run record.
func (h *Heartbeat) SetBacklog(value float64) {
	if h == nil {
		return
	}
	workerBacklogs.Store(h.worker, value)
	if m := h.metrics(); m != nil {
		m.backlog.WithLabelValues(h.worker).Set(value)
	}
}

// Worker run statuses carried by WorkerRunRecord.
const (
	WorkerRunSucceeded = "succeeded"
	WorkerRunFailed    = "failed"
	WorkerRunSkipped   = "skipped"
	WorkerRunBusy      = "busy"
)

// WorkerRunRecord describes one finished run for a WorkerRunSink.
type WorkerRunRecord struct {
	Worker     string
	Interval   time.Duration
	StartedAt  time.Time
	FinishedAt time.Time
	// Status is succeeded, failed, skipped (nothing to do / not configured) or
	// busy (another instance holds the work).
	Status string
	// ItemsProcessed sums every outcome except "failed"; Items keeps them all.
	ItemsProcessed int64
	ItemsFailed    int64
	Items          map[string]int64
	// Backlog is the last value published with SetBacklog, when there is one.
	Backlog *float64
	Err     error
	Details map[string]any
}

// Duration is FinishedAt - StartedAt (never negative).
func (r WorkerRunRecord) Duration() time.Duration {
	if d := r.FinishedAt.Sub(r.StartedAt); d > 0 {
		return d
	}
	return 0
}

// WorkerRunSink receives every finished worker run (cancelled runs excluded).
// RecordWorkerRun is called on the worker's goroutine: it must not block and
// must not fail the worker; durable writes belong on another goroutine.
type WorkerRunSink interface {
	RecordWorkerRun(WorkerRunRecord)
}

type workerRunSinkHolder struct{ sink WorkerRunSink }

var defaultWorkerRunSink atomic.Pointer[workerRunSinkHolder]

// SetWorkerRunSink installs the process-wide run sink (nil removes it).
func SetWorkerRunSink(sink WorkerRunSink) {
	if sink == nil {
		defaultWorkerRunSink.Store(nil)
		return
	}
	defaultWorkerRunSink.Store(&workerRunSinkHolder{sink: sink})
}

// CurrentWorkerRunSink returns the installed sink (nil when none).
func CurrentWorkerRunSink() WorkerRunSink { return currentWorkerRunSink() }

func currentWorkerRunSink() WorkerRunSink {
	if holder := defaultWorkerRunSink.Load(); holder != nil {
		return holder.sink
	}
	return nil
}

// WorkerInfo is what this process knows about one heartbeat worker.
type WorkerInfo struct {
	Worker    string
	Interval  time.Duration
	FirstSeen time.Time
}

var (
	workerRegistry sync.Map // worker -> WorkerInfo
	workerBacklogs sync.Map // worker -> float64
)

func registerWorker(worker string, interval time.Duration, now time.Time) {
	if worker == "" {
		return
	}
	if existing, ok := workerRegistry.Load(worker); ok {
		info := existing.(WorkerInfo)
		if interval <= 0 || info.Interval == interval {
			return
		}
		info.Interval = interval
		workerRegistry.Store(worker, info)
		return
	}
	workerRegistry.LoadOrStore(worker, WorkerInfo{Worker: worker, Interval: interval, FirstSeen: now})
}

// WorkerRegistry lists the workers that have begun at least one run in this
// process, with their configured interval and the time of their first run.
func WorkerRegistry() []WorkerInfo {
	out := []WorkerInfo{}
	workerRegistry.Range(func(_, value any) bool {
		out = append(out, value.(WorkerInfo))
		return true
	})
	return out
}

// WorkerRun is one in-progress run; finish it with End exactly once.
type WorkerRun struct {
	heartbeat *Heartbeat
	metrics   *WorkerMetrics
	started   time.Time
	done      bool

	mu      sync.Mutex
	items   map[string]int64
	details map[string]any
	status  string
}

// Items counts items handled in this run ("processed", "failed", ...).
func (r *WorkerRun) Items(outcome string, n int) {
	if r == nil || r.heartbeat == nil || n <= 0 {
		return
	}
	r.mu.Lock()
	if r.items == nil {
		r.items = map[string]int64{}
	}
	r.items[outcome] += int64(n)
	r.mu.Unlock()
	if r.metrics != nil {
		r.metrics.items.WithLabelValues(r.heartbeat.worker, outcome).Add(float64(n))
	}
}

// Detail attaches a value to the run record (job_runs.details). Values must
// be JSON-encodable and must not carry personal data.
func (r *WorkerRun) Detail(key string, value any) {
	if r == nil || r.heartbeat == nil || key == "" {
		return
	}
	r.mu.Lock()
	if r.details == nil {
		r.details = map[string]any{}
	}
	r.details[key] = value
	r.mu.Unlock()
}

// MarkBusy records a run that found the work held elsewhere (another instance
// holds the lock). End(nil) then records status busy; Prometheus still counts
// it as a success because the worker is alive.
func (r *WorkerRun) MarkBusy() { r.markStatus(WorkerRunBusy) }

// MarkSkipped records a run that had nothing it could do (not configured, a
// recent run already covered it). End(nil) then records status skipped.
func (r *WorkerRun) MarkSkipped() { r.markStatus(WorkerRunSkipped) }

func (r *WorkerRun) markStatus(status string) {
	if r == nil {
		return
	}
	r.mu.Lock()
	r.status = status
	r.mu.Unlock()
}

// End records the run. A nil error is a success; context cancellation (the
// process shutting down) records nothing so it neither refreshes nor fails
// the heartbeat.
func (r *WorkerRun) End(err error) {
	if r == nil || r.heartbeat == nil || r.done {
		return
	}
	r.done = true
	if err != nil && errors.Is(err, context.Canceled) {
		return
	}
	m, worker := r.metrics, r.heartbeat.worker
	now := time.Now()
	if m != nil {
		now = m.now()
		m.duration.WithLabelValues(worker).Observe(now.Sub(r.started).Seconds())
		m.lastRun.WithLabelValues(worker).Set(float64(now.UnixNano()) / 1e9)
		if err != nil {
			m.runs.WithLabelValues(worker, WorkerResultError).Inc()
		} else {
			m.runs.WithLabelValues(worker, WorkerResultSuccess).Inc()
			m.lastSuccess.WithLabelValues(worker).Set(float64(now.UnixNano()) / 1e9)
		}
	}
	sink := currentWorkerRunSink()
	if sink == nil {
		return
	}
	record := WorkerRunRecord{
		Worker: worker, Interval: r.heartbeat.interval,
		StartedAt: r.started, FinishedAt: now, Status: WorkerRunSucceeded, Err: err,
	}
	r.mu.Lock()
	if err != nil {
		record.Status = WorkerRunFailed
	} else if r.status != "" {
		record.Status = r.status
	}
	if len(r.items) > 0 {
		record.Items = make(map[string]int64, len(r.items))
		for outcome, n := range r.items {
			record.Items[outcome] = n
			if outcome == "failed" {
				record.ItemsFailed += n
			} else {
				record.ItemsProcessed += n
			}
		}
	}
	if len(r.details) > 0 {
		record.Details = make(map[string]any, len(r.details))
		for key, value := range r.details {
			record.Details[key] = value
		}
	}
	r.mu.Unlock()
	if value, ok := workerBacklogs.Load(worker); ok {
		backlog := value.(float64)
		record.Backlog = &backlog
	}
	sink.RecordWorkerRun(record)
}
