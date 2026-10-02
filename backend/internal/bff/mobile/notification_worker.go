package mobile

import (
	"context"
	"errors"
	"fmt"
	"sync"
	"sync/atomic"
	"time"

	"github.com/google/uuid"
	"github.com/verified-dating/backend/internal/platform/config"
	"github.com/verified-dating/backend/internal/platform/observability"
	"go.uber.org/zap"
)

type pushDeliveryResult struct {
	MessageID    string
	Permanent    bool
	InvalidToken bool
}

type pushNotificationSender interface {
	Configured() bool
	Send(context.Context, notificationDevice, notificationOutboxJob) (pushDeliveryResult, error)
}

type notificationDeliveryEngine struct {
	repo         *notificationRepository
	sender       pushNotificationSender
	log          *zap.Logger
	workerCount  int
	batchSize    int
	pollInterval time.Duration
	maxAttempts  int
	metrics      *observability.HTTPMetrics
	cancel       context.CancelFunc
	done         sync.WaitGroup
	// metricsNextAt (unix nanos) throttles refreshMetrics across workers.
	metricsNextAt atomic.Int64
}

// notificationMetricsRefreshInterval: the queue gauges come from
// matching.notification_queue_metrics, which counts the whole outbox and a
// 15-minute delivery window. It used to run after every batch on every
// worker of every instance; gauges are scraped every 15s anyway.
const notificationMetricsRefreshInterval = 15 * time.Second

// metricsRefreshDue lets exactly one caller per interval refresh the gauges.
func (e *notificationDeliveryEngine) metricsRefreshDue(now time.Time) bool {
	next := e.metricsNextAt.Load()
	if now.UnixNano() < next {
		return false
	}
	return e.metricsNextAt.CompareAndSwap(next, now.Add(notificationMetricsRefreshInterval).UnixNano())
}

func newNotificationDeliveryEngine(cfg config.Config, log *zap.Logger, repo *notificationRepository, metrics *observability.HTTPMetrics) *notificationDeliveryEngine {
	if repo == nil {
		return nil
	}
	workers := cfg.NotificationWorkerCount
	if workers <= 0 || workers > 32 {
		workers = 2
	}
	batch := cfg.NotificationBatchSize
	if batch <= 0 || batch > 200 {
		batch = 50
	}
	poll := time.Duration(cfg.NotificationPollIntervalMS) * time.Millisecond
	if poll < 100*time.Millisecond || poll > time.Minute {
		poll = 500 * time.Millisecond
	}
	maxAttempts := cfg.NotificationMaxAttempts
	if maxAttempts <= 0 || maxAttempts > 20 {
		maxAttempts = 5
	}
	if log == nil {
		log = zap.NewNop()
	}
	return &notificationDeliveryEngine{
		repo: repo, sender: newPushNotificationSender(cfg), log: log,
		workerCount: workers, batchSize: batch, pollInterval: poll, maxAttempts: maxAttempts,
		metrics: metrics,
	}
}

func (e *notificationDeliveryEngine) Start(parent context.Context) {
	if e == nil || e.repo == nil || e.cancel != nil {
		return
	}
	ctx, cancel := context.WithCancel(parent)
	e.cancel = cancel
	if err := e.repo.recoverStale(ctx); err != nil {
		e.log.Warn("notification_stale_job_recovery_failed", zap.Error(err))
	}
	for worker := 0; worker < e.workerCount; worker++ {
		e.done.Add(1)
		go e.run(ctx, worker)
	}
}

func (e *notificationDeliveryEngine) run(ctx context.Context, worker int) {
	defer e.done.Done()
	workerID := fmt.Sprintf("notification-%d-%s", worker, uuid.NewString())
	ticker := time.NewTicker(e.pollInterval)
	defer ticker.Stop()
	heartbeat := observability.NewHeartbeat(workerNotificationDelivery, e.pollInterval)
	for {
		run := heartbeat.Begin()
		processed, err := e.processBatch(ctx, workerID)
		run.Items("processed", processed)
		run.End(err)
		if err != nil && !errors.Is(err, context.Canceled) {
			if e.metrics != nil {
				e.metrics.NotificationBatchFailures.Inc()
			}
			e.log.Warn("notification_batch_failed", zap.String("worker_id", workerID), zap.Error(err))
		}
		if e.metricsRefreshDue(time.Now()) {
			e.refreshMetrics(ctx)
		}
		if processed > 0 {
			continue
		}
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
		}
	}
}

func (e *notificationDeliveryEngine) refreshMetrics(ctx context.Context) {
	if e == nil || e.repo == nil || e.metrics == nil {
		return
	}
	metrics, err := e.repo.queueMetrics(ctx)
	if err != nil {
		return
	}
	e.metrics.NotificationQueueDepth.Set(notificationMetricValue(metrics["queue_depth"]))
	observability.NewHeartbeat(workerNotificationDelivery, e.pollInterval).SetBacklog(notificationMetricValue(metrics["queue_depth"]))
	if e.metrics.NotificationPushAttempts15m != nil {
		e.metrics.NotificationPushAttempts15m.Set(notificationMetricValue(metrics["push_attempts_15m"]))
	}
	e.metrics.NotificationProcessing.Set(notificationMetricValue(metrics["processing"]))
	e.metrics.NotificationDeadLetters.Set(notificationMetricValue(metrics["dead_letter"]))
	e.metrics.NotificationOldestPendingAge.Set(notificationMetricValue(metrics["oldest_pending_age_seconds"]))
	e.metrics.NotificationPushSuccess.Set(notificationMetricValue(metrics["push_success_percent_15m"]))
	e.metrics.NotificationPushP95LatencyMS.Set(notificationMetricValue(metrics["push_p95_latency_ms_15m"]))
}

func notificationMetricValue(value any) float64 {
	switch typed := value.(type) {
	case int:
		return float64(typed)
	case int32:
		return float64(typed)
	case int64:
		return float64(typed)
	case float64:
		return typed
	default:
		return 0
	}
}

func (e *notificationDeliveryEngine) processBatch(ctx context.Context, workerID string) (int, error) {
	jobs, err := e.repo.claim(ctx, workerID, e.batchSize, e.maxAttempts)
	if err != nil {
		return 0, err
	}
	for _, job := range jobs {
		if err := e.process(ctx, job); err != nil && !errors.Is(err, context.Canceled) {
			e.log.Warn("notification_job_finalize_failed", zap.String("outbox_id", job.ID), zap.Error(err))
		}
	}
	return len(jobs), nil
}

func (e *notificationDeliveryEngine) process(ctx context.Context, job notificationOutboxJob) error {
	allowed, err := e.repo.planSharingAllowed(ctx, job)
	if err != nil {
		return e.repo.finish(ctx, job, false, err)
	}
	if !allowed {
		return e.repo.finish(ctx, job, false, nil)
	}
	inApp, push, err := e.repo.recipientPolicy(ctx, job.RecipientUserID, job.Category)
	if err != nil {
		return e.repo.finish(ctx, job, false, err)
	}
	delivered := false
	if inApp {
		if err := e.repo.createInApp(ctx, job); err != nil {
			if errors.Is(err, errPlanSharingRevoked) {
				return e.repo.finish(ctx, job, false, nil)
			}
			return e.repo.finish(ctx, job, false, err)
		}
		delivered = true
	}
	if !push || !e.sender.Configured() {
		return e.repo.finish(ctx, job, delivered, nil)
	}
	devices, err := e.repo.devices(ctx, job.RecipientUserID)
	if err != nil {
		return e.repo.finish(ctx, job, delivered, err)
	}
	var retryErr error
	for _, device := range devices {
		allowed, err := e.repo.planSharingAllowed(ctx, job)
		if err != nil {
			return e.repo.finish(ctx, job, delivered, err)
		}
		if !allowed {
			return e.repo.finish(ctx, job, delivered, nil)
		}
		result, sendErr := e.sender.Send(ctx, device, job)
		if sendErr == nil {
			delivered = true
			if err := e.repo.recordPush(ctx, job.ID, device, "delivered", result.MessageID, ""); err != nil {
				retryErr = errors.Join(retryErr, err)
			}
			continue
		}
		status := "failed"
		if result.Permanent {
			status = "dead_letter"
		}
		if result.InvalidToken {
			_ = e.repo.disableDevice(ctx, device.ID, sendErr.Error())
		}
		if !result.Permanent {
			retryErr = errors.Join(retryErr, sendErr)
		}
		if err := e.repo.recordPush(ctx, job.ID, device, status, "", sendErr.Error()); err != nil {
			retryErr = errors.Join(retryErr, err)
		}
	}
	return e.repo.finish(ctx, job, delivered, retryErr)
}

func (e *notificationDeliveryEngine) Close() {
	if e == nil || e.cancel == nil {
		return
	}
	e.cancel()
	e.done.Wait()
}
