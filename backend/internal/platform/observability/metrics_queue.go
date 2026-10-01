package observability

import (
	"sort"
	"sync"
	"time"

	"github.com/prometheus/client_golang/prometheus"
)

// QueueSnapshot is a point-in-time view of an in-process work queue (for
// example the BFF's async activity fan-out). Totals are monotonic counters.
type QueueSnapshot struct {
	Depth     int
	Capacity  int
	Enqueued  int64
	Processed int64
	Dropped   int64
	MaxLag    time.Duration
}

// TrackQueue publishes an in-process queue as verified_dating_queue_* series
// labelled queue=<name>. The snapshot function is called at scrape time and
// must be cheap and goroutine-safe. Registering a name again replaces it.
func (m *HTTPMetrics) TrackQueue(name string, snapshot func() QueueSnapshot) {
	if m == nil || m.queues == nil || snapshot == nil || name == "" {
		return
	}
	m.queues.track(name, snapshot)
}

type queueCollector struct {
	mu        sync.RWMutex
	snapshots map[string]func() QueueSnapshot

	depth, capacity, enqueued, processed, dropped, maxLag *prometheus.Desc
}

func newQueueCollector() *queueCollector {
	desc := func(name, help string) *prometheus.Desc {
		return prometheus.NewDesc("verified_dating_queue_"+name, help, []string{"queue"}, nil)
	}
	return &queueCollector{
		snapshots: map[string]func() QueueSnapshot{},
		depth:     desc("depth", "Jobs waiting in an in-process queue."),
		capacity:  desc("capacity", "Capacity of an in-process queue; enqueue beyond it drops work."),
		enqueued:  desc("enqueued_total", "Jobs accepted by an in-process queue."),
		processed: desc("processed_total", "Jobs completed by an in-process queue's workers."),
		dropped:   desc("dropped_total", "Jobs dropped because an in-process queue was full or disabled."),
		maxLag:    desc("max_lag_seconds", "Largest enqueue-to-start lag observed since process start."),
	}
}

func (c *queueCollector) track(name string, snapshot func() QueueSnapshot) {
	c.mu.Lock()
	c.snapshots[name] = snapshot
	c.mu.Unlock()
}

func (c *queueCollector) Describe(ch chan<- *prometheus.Desc) {
	for _, d := range []*prometheus.Desc{c.depth, c.capacity, c.enqueued, c.processed, c.dropped, c.maxLag} {
		ch <- d
	}
}

func (c *queueCollector) Collect(ch chan<- prometheus.Metric) {
	c.mu.RLock()
	names := make([]string, 0, len(c.snapshots))
	for name := range c.snapshots {
		names = append(names, name)
	}
	sort.Strings(names)
	fns := make([]func() QueueSnapshot, len(names))
	for i, name := range names {
		fns[i] = c.snapshots[name]
	}
	c.mu.RUnlock()
	for i, name := range names {
		s := fns[i]()
		ch <- prometheus.MustNewConstMetric(c.depth, prometheus.GaugeValue, float64(s.Depth), name)
		ch <- prometheus.MustNewConstMetric(c.capacity, prometheus.GaugeValue, float64(s.Capacity), name)
		ch <- prometheus.MustNewConstMetric(c.enqueued, prometheus.CounterValue, float64(s.Enqueued), name)
		ch <- prometheus.MustNewConstMetric(c.processed, prometheus.CounterValue, float64(s.Processed), name)
		ch <- prometheus.MustNewConstMetric(c.dropped, prometheus.CounterValue, float64(s.Dropped), name)
		ch <- prometheus.MustNewConstMetric(c.maxLag, prometheus.GaugeValue, s.MaxLag.Seconds(), name)
	}
}
