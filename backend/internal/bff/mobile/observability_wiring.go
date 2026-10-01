package mobile

import (
	"time"

	"github.com/verified-dating/backend/internal/platform/observability"
)

// Background worker names are Prometheus label values on the
// verified_dating_worker_* series; keep them stable (alerts, dashboards and
// documents/MONITORING_RUNBOOKS_2026-10-01.md reference them).
const (
	workerAccountErasure         = "account_erasure"
	workerMediaCleanup           = "media_cleanup"
	workerBillingRenewalSweep    = "billing_renewal_sweep"
	workerDatePlanSweep          = "date_plan_sweep"
	workerXPAwardSpoolReplay     = "xp_award_spool_replay"
	workerNotificationDelivery   = "notification_delivery"
	workerLevelProjection        = "level_projection"
	workerTrustRetention         = "trust_retention"
	workerSOSGaugeRefresh        = "sos_gauge_refresh"
	workerSOSDelivery            = "sos_delivery"
	workerIdempotencyRetention   = "idempotency_retention"
	queueActivityFanout          = "activity_fanout"
	realtimeStreamChat           = "chat"
	mediaCleanupInterval         = time.Hour
	idempotencyRetentionInterval = 5 * time.Minute
)

// registerObservability publishes in-process state that is only reachable
// through the Server (the async activity fan-out queue).
func (s *Server) registerObservability() {
	if s == nil || s.httpMetrics == nil || s.fanout == nil {
		return
	}
	fanout := s.fanout
	s.httpMetrics.TrackQueue(queueActivityFanout, func() observability.QueueSnapshot {
		snap := fanout.QueueMetrics()
		return observability.QueueSnapshot{
			Depth:     snap.QueueDepth,
			Capacity:  snap.QueueCapacity,
			Enqueued:  snap.EnqueuedTotal,
			Processed: snap.ProcessedTotal,
			Dropped:   snap.DroppedTotal,
			MaxLag:    time.Duration(snap.MaxObservedQueueLag) * time.Millisecond,
		}
	})
}
