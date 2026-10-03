package observability

import (
	"time"

	"github.com/prometheus/client_golang/prometheus"
)

// NewBFFMetrics registers the mobile BFF collectors: the HTTP RED set plus
// the reliability, notification, progression, SOS, queue, realtime-delivery
// and background-worker collectors that only the BFF updates. It also makes
// the worker collectors the process default used by Heartbeat.
func NewBFFMetrics(reg prometheus.Registerer) *HTTPMetrics {
	metrics := newHTTPServerMetrics(reg, ServiceMobileBFF)
	gauge := func(subsystem, name, help string) prometheus.Gauge {
		return prometheus.NewGauge(prometheus.GaugeOpts{
			Namespace: "verified_dating", Subsystem: subsystem, Name: name, Help: help,
		})
	}

	metrics.TimeoutCount = prometheus.NewCounterVec(prometheus.CounterOpts{
		Namespace: "verified_dating", Subsystem: "reliability", Name: "request_timeouts_total",
		Help: "Requests whose configured timeout tier elapsed.",
	}, []string{"tier", "domain"})
	metrics.IdempotencyReplays = prometheus.NewCounterVec(prometheus.CounterOpts{
		Namespace: "verified_dating", Subsystem: "reliability", Name: "idempotency_replays_total",
		Help: "Idempotent retries served from a completed response.",
	}, []string{"domain"})
	metrics.IdempotencyConflicts = prometheus.NewCounterVec(prometheus.CounterOpts{
		Namespace: "verified_dating", Subsystem: "reliability", Name: "idempotency_conflicts_total",
		Help: "Retries rejected because an idempotency key was reused for a different request payload.",
	}, []string{"domain"})
	metrics.IdempotencyProcessing = gauge("reliability", "idempotency_processing",
		"Shared idempotency requests currently processing.")
	metrics.IdempotencyExpiredLeases = gauge("reliability", "idempotency_expired_leases",
		"Shared idempotency processing leases awaiting takeover or retention.")
	metrics.IdempotencyRetentionBacklog = gauge("reliability", "idempotency_retention_backlog",
		"Expired shared idempotency records awaiting archival.")
	metrics.PostgresOpenConnections = gauge("reliability", "postgres_open_connections",
		"Open database/sql PostgreSQL connections in the BFF idempotency pool (see verified_dating_db_pool_* for every pool).")
	metrics.PostgresInUseConnections = gauge("reliability", "postgres_in_use_connections",
		"In-use database/sql PostgreSQL connections in the BFF idempotency pool (see verified_dating_db_pool_* for every pool).")
	metrics.ShedCount = prometheus.NewCounterVec(prometheus.CounterOpts{
		Namespace: "verified_dating", Subsystem: "reliability", Name: "requests_shed_total",
		Help: "Requests rejected by a domain bulkhead (domain label) or by the process-wide in-flight limit (domain=\"inflight\").",
	}, []string{"domain"})

	metrics.NotificationQueueDepth = gauge("notification", "queue_depth", "Pending or retry notification outbox jobs.")
	metrics.NotificationOldestPendingAge = gauge("notification", "oldest_pending_age_seconds",
		"Age in seconds of the oldest pending notification.")
	metrics.NotificationDeadLetters = gauge("notification", "dead_letters", "Notification jobs currently in dead-letter state.")
	metrics.NotificationProcessing = gauge("notification", "processing", "Notification jobs currently leased by workers.")
	metrics.NotificationPushSuccess = gauge("notification", "push_success_percent_15m",
		"Push delivery success percentage over the last 15 minutes (100 when there were no attempts).")
	metrics.NotificationPushAttempts15m = gauge("notification", "push_attempts_15m",
		"Push delivery attempts over the last 15 minutes; gives the success percentage its volume.")
	metrics.NotificationPushP95LatencyMS = gauge("notification", "push_p95_latency_ms_15m",
		"Push outbox-to-provider p95 latency in milliseconds over 15 minutes.")
	metrics.NotificationBatchFailures = prometheus.NewCounter(prometheus.CounterOpts{
		Namespace: "verified_dating", Subsystem: "notification", Name: "batch_failures_total",
		Help: "Notification worker batch failures.",
	})

	metrics.ProgressionQueueDepth = gauge("progression", "projection_queue_depth", "Pending or retry Level/XP projection jobs.")
	metrics.ProgressionProcessing = gauge("progression", "projection_processing", "Level/XP projection jobs currently leased by workers.")
	metrics.ProgressionDeadLetters = gauge("progression", "projection_dead_letters", "Level/XP projection jobs in dead-letter state.")
	metrics.ProgressionOldestPendingAge = gauge("progression", "projection_oldest_pending_age_seconds",
		"Age in seconds of the oldest pending or retry projection job.")
	metrics.ProgressionCompletionP95 = gauge("progression", "projection_completion_p95_seconds",
		"Projection queue-to-completion p95 over the last fifteen minutes.")
	metrics.ProgressionOpenFraudCases = gauge("progression", "open_fraud_cases", "Open or reviewing Level/XP fraud cases.")
	metrics.ProgressionCapDenials15m = gauge("progression", "cap_denials_15m",
		"XP cap or cooldown denials recorded in the last fifteen minutes.")

	metrics.SOSDeliveryQueueDepth = gauge("sos", "delivery_queue_depth", "SOS contact deliveries pending, retrying or processing.")
	metrics.SOSDeliveryOverdue = gauge("sos", "delivery_overdue", "SOS contact deliveries past their response deadline and not delivered.")
	metrics.SOSDeliveryDeadLetters = gauge("sos", "delivery_dead_letters", "SOS contact deliveries that exhausted their attempts.")
	metrics.SOSDeliveryOldestPendingAge = gauge("sos", "delivery_oldest_pending_age_seconds",
		"Age in seconds of the oldest undelivered SOS contact delivery.")
	metrics.TrustRetentionRuns = prometheus.NewCounterVec(prometheus.CounterOpts{
		Namespace: "verified_dating", Subsystem: "trust", Name: "retention_rows_total",
		Help: "Rows purged or redacted by trust retention, by retention class.",
	}, []string{"class"})

	metrics.ActivityCaptureWrites = prometheus.NewCounterVec(prometheus.CounterOpts{
		Namespace: "verified_dating", Subsystem: "activity", Name: "capture_writes_total",
		Help: "Member activity rows written by the request middleware, by domain and result (durable = synchronous insert, fallback_queue = handed to the async activity queue).",
	}, []string{"domain", "result"})

	metrics.RealtimeDeliveryLag = prometheus.NewHistogramVec(prometheus.HistogramOpts{
		Namespace: "verified_dating", Subsystem: "realtime", Name: "delivery_lag_seconds",
		Help:    "Time from a realtime outbox event being written to it being pushed to a connected socket.",
		Buckets: []float64{0.1, 0.25, 0.5, 1, 2, 5, 10, 30, 60, 300},
	}, []string{"stream"})

	metrics.SecurityRefusals = prometheus.NewCounterVec(prometheus.CounterOpts{
		Namespace: "verified_dating", Subsystem: "security", Name: "refusals_total",
		Help: "Requests refused by the BFF security middleware, by reason (unauthenticated, account_state, forbidden_role, forbidden_resource).",
	}, []string{"reason"})

	metrics.queues = newQueueCollector()

	reg.MustRegister(
		metrics.TimeoutCount,
		metrics.IdempotencyReplays,
		metrics.IdempotencyConflicts,
		metrics.IdempotencyProcessing,
		metrics.IdempotencyExpiredLeases,
		metrics.IdempotencyRetentionBacklog,
		metrics.PostgresOpenConnections,
		metrics.PostgresInUseConnections,
		metrics.ShedCount,
		metrics.NotificationQueueDepth,
		metrics.NotificationOldestPendingAge,
		metrics.NotificationDeadLetters,
		metrics.NotificationProcessing,
		metrics.NotificationPushSuccess,
		metrics.NotificationPushAttempts15m,
		metrics.NotificationPushP95LatencyMS,
		metrics.NotificationBatchFailures,
		metrics.ProgressionQueueDepth,
		metrics.ProgressionProcessing,
		metrics.ProgressionDeadLetters,
		metrics.ProgressionOldestPendingAge,
		metrics.ProgressionCompletionP95,
		metrics.ProgressionOpenFraudCases,
		metrics.ProgressionCapDenials15m,
		metrics.SOSDeliveryQueueDepth,
		metrics.SOSDeliveryOverdue,
		metrics.SOSDeliveryDeadLetters,
		metrics.SOSDeliveryOldestPendingAge,
		metrics.TrustRetentionRuns,
		metrics.ActivityCaptureWrites,
		metrics.RealtimeDeliveryLag,
		metrics.SecurityRefusals,
		metrics.queues,
	)
	metrics.Workers = NewWorkerMetrics(reg)
	SetDefaultWorkerMetrics(metrics.Workers)
	return metrics
}

// ObserveRealtimeDelivery records how long a realtime event waited between
// being written and being pushed to a connected client. Nil-safe.
func (m *HTTPMetrics) ObserveRealtimeDelivery(stream string, occurredAt time.Time) {
	if m == nil || m.RealtimeDeliveryLag == nil || occurredAt.IsZero() {
		return
	}
	lag := time.Since(occurredAt).Seconds()
	if lag < 0 {
		lag = 0
	}
	m.RealtimeDeliveryLag.WithLabelValues(stream).Observe(lag)
}

// ObserveSecurityRefusal counts one refusal by the security middleware. Nil-safe.
func (m *HTTPMetrics) ObserveSecurityRefusal(reason string) {
	if m == nil || m.SecurityRefusals == nil || reason == "" {
		return
	}
	m.SecurityRefusals.WithLabelValues(reason).Inc()
}

// ShedDomainInflight is the requests_shed_total domain label used for the
// process-wide in-flight limit (InflightSheddingMiddlewareWithMetrics).
const ShedDomainInflight = "inflight"
