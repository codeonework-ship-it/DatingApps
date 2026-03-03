package mobile

import (
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"github.com/verified-dating/backend/internal/platform/config"
	"go.uber.org/zap"
)

type fanoutJob struct {
	event      activityEvent
	enqueuedAt time.Time
}

type queueMetricsSnapshot struct {
	QueueDepth          int   `json:"queue_depth"`
	QueueCapacity       int   `json:"queue_capacity"`
	EnqueuedTotal       int64 `json:"enqueued_total"`
	ProcessedTotal      int64 `json:"processed_total"`
	DroppedTotal        int64 `json:"dropped_total"`
	MaxObservedQueueLag int64 `json:"max_observed_queue_lag_ms"`
}

type precomputedAggregateSnapshot struct {
	TotalInteractions      int64            `json:"total_interactions"`
	SwipeEvents            int64            `json:"swipe_events"`
	MessageEvents          int64            `json:"message_events"`
	ReportEvents           int64            `json:"report_events"`
	ServerErrorEvents      int64            `json:"server_error_events"`
	ClientErrorEvents      int64            `json:"client_error_events"`
	UnlockAttemptsByPolicy map[string]int64 `json:"unlock_attempts_by_policy"`
	ChatLocksByPolicy      map[string]int64 `json:"chat_locks_by_policy"`
}

type asyncFanout struct {
	log     *zap.Logger
	store   *memoryStore
	jobs    chan fanoutJob
	stopCh  chan struct{}
	wg      sync.WaitGroup
	enabled bool

	enqueuedTotal       atomic.Int64
	processedTotal      atomic.Int64
	droppedTotal        atomic.Int64
	maxObservedQueueLag atomic.Int64

	aggMu sync.RWMutex
	agg   precomputedAggregateSnapshot
}

func newAsyncFanout(cfg config.Config, log *zap.Logger, store *memoryStore) *asyncFanout {
	workers := cfg.FanoutWorkerCount
	queueSize := cfg.FanoutQueueSize
	if workers <= 0 || queueSize <= 0 {
		return &asyncFanout{log: log, store: store, enabled: false}
	}
	if queueSize < workers {
		queueSize = workers
	}

	f := &asyncFanout{
		log:     log,
		store:   store,
		jobs:    make(chan fanoutJob, queueSize),
		stopCh:  make(chan struct{}),
		enabled: true,
	}

	for i := 0; i < workers; i++ {
		f.wg.Add(1)
		go f.worker(i + 1)
	}
	return f
}

func (f *asyncFanout) worker(_ int) {
	defer f.wg.Done()
	for {
		select {
		case <-f.stopCh:
			return
		case job := <-f.jobs:
			f.store.recordActivity(job.event)
			f.updateAggregates(job.event)
			f.processedTotal.Add(1)
			lag := time.Since(job.enqueuedAt).Milliseconds()
			for {
				prev := f.maxObservedQueueLag.Load()
				if lag <= prev {
					break
				}
				if f.maxObservedQueueLag.CompareAndSwap(prev, lag) {
					break
				}
			}
		}
	}
}

func (f *asyncFanout) EnqueueActivity(event activityEvent) {
	if f == nil || f.store == nil {
		return
	}
	if !f.enabled {
		f.store.recordActivity(event)
		f.updateAggregates(event)
		return
	}

	job := fanoutJob{event: event, enqueuedAt: time.Now().UTC()}
	select {
	case f.jobs <- job:
		f.enqueuedTotal.Add(1)
	default:
		f.droppedTotal.Add(1)
		f.log.Warn("fanout_queue_full_drop", zap.String("action", event.Action), zap.String("resource", event.Resource))
	}
}

func (f *asyncFanout) updateAggregates(event activityEvent) {
	f.aggMu.Lock()
	defer f.aggMu.Unlock()

	f.agg.TotalInteractions++
	action := strings.ToLower(strings.TrimSpace(event.Action))
	switch {
	case strings.Contains(action, "/swipe"):
		f.agg.SwipeEvents++
	case strings.Contains(action, "/chat/") && strings.Contains(action, "/messages"):
		f.agg.MessageEvents++
	case strings.Contains(action, "/safety/report"):
		f.agg.ReportEvents++
	}

	status := strings.ToLower(strings.TrimSpace(event.Status))
	switch status {
	case "server_error":
		f.agg.ServerErrorEvents++
	case "client_error":
		f.agg.ClientErrorEvents++
	}

	variant := strings.TrimSpace(toString(event.Details["unlock_policy_variant"]))
	if variant != "" {
		if strings.Contains(strings.ToLower(strings.TrimSpace(event.Resource)), "/quest-workflow/submit") {
			if f.agg.UnlockAttemptsByPolicy == nil {
				f.agg.UnlockAttemptsByPolicy = map[string]int64{}
			}
			f.agg.UnlockAttemptsByPolicy[variant]++
		}
		if action == "chat.locked" {
			if f.agg.ChatLocksByPolicy == nil {
				f.agg.ChatLocksByPolicy = map[string]int64{}
			}
			f.agg.ChatLocksByPolicy[variant]++
		}
	}
}

func (f *asyncFanout) QueueMetrics() queueMetricsSnapshot {
	if f == nil {
		return queueMetricsSnapshot{}
	}
	depth := 0
	capacity := 0
	if f.jobs != nil {
		depth = len(f.jobs)
		capacity = cap(f.jobs)
	}
	return queueMetricsSnapshot{
		QueueDepth:          depth,
		QueueCapacity:       capacity,
		EnqueuedTotal:       f.enqueuedTotal.Load(),
		ProcessedTotal:      f.processedTotal.Load(),
		DroppedTotal:        f.droppedTotal.Load(),
		MaxObservedQueueLag: f.maxObservedQueueLag.Load(),
	}
}

func (f *asyncFanout) AggregateSnapshot() precomputedAggregateSnapshot {
	if f == nil {
		return precomputedAggregateSnapshot{}
	}
	f.aggMu.RLock()
	defer f.aggMu.RUnlock()
	result := f.agg
	if len(f.agg.UnlockAttemptsByPolicy) > 0 {
		result.UnlockAttemptsByPolicy = make(map[string]int64, len(f.agg.UnlockAttemptsByPolicy))
		for key, value := range f.agg.UnlockAttemptsByPolicy {
			result.UnlockAttemptsByPolicy[key] = value
		}
	}
	if len(f.agg.ChatLocksByPolicy) > 0 {
		result.ChatLocksByPolicy = make(map[string]int64, len(f.agg.ChatLocksByPolicy))
		for key, value := range f.agg.ChatLocksByPolicy {
			result.ChatLocksByPolicy[key] = value
		}
	}
	return result
}

func (f *asyncFanout) Close() {
	if f == nil || !f.enabled {
		return
	}
	close(f.stopCh)
	f.wg.Wait()
}

func (s *Server) enqueueNonCriticalActivity(event activityEvent) {
	if s.fanout == nil {
		s.store.recordActivity(event)
		return
	}
	s.fanout.EnqueueActivity(event)
}
