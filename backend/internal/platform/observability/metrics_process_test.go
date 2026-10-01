package observability

import (
	"strings"
	"testing"
	"time"

	"github.com/prometheus/client_golang/prometheus"
)

func TestDBPoolCollectorAggregatesByNameAndForgetsClosedPools(t *testing.T) {
	collector := newDBPoolCollector()
	reg := prometheus.NewRegistry()
	reg.MustRegister(collector)

	collector.track("mobile/profile_repository", func() (DBPoolStats, bool) {
		return DBPoolStats{MaxConnections: 16, OpenConnections: 5, InUseConnections: 3, IdleConnections: 2, WaitCount: 4, WaitDuration: 2 * time.Second}, true
	})
	untrack := collector.track("mobile/profile_repository", func() (DBPoolStats, bool) {
		return DBPoolStats{MaxConnections: 16, OpenConnections: 1, InUseConnections: 1}, true
	})
	alive := true
	collector.track("dataaccess/runtime_store", func() (DBPoolStats, bool) {
		return DBPoolStats{MaxConnections: 8}, alive
	})

	inUse := counterValues(t, reg, "verified_dating_db_pool_in_use_connections")
	if inUse["pool=mobile/profile_repository"] != 4 {
		t.Fatalf("pools sharing a name must be summed: %v", inUse)
	}
	if got := counterValues(t, reg, "verified_dating_db_pool_max_connections")["pool=mobile/profile_repository"]; got != 32 {
		t.Fatalf("max = %v", got)
	}
	if got := counterValues(t, reg, "verified_dating_db_pool_wait_seconds_total")["pool=mobile/profile_repository"]; got != 2 {
		t.Fatalf("wait seconds = %v", got)
	}

	untrack()
	alive = false
	instances := counterValues(t, reg, "verified_dating_db_pool_instances")
	if instances["pool=mobile/profile_repository"] != 1 {
		t.Fatalf("untracked pool still counted: %v", instances)
	}
	if _, ok := instances["pool=dataaccess/runtime_store"]; ok {
		t.Fatalf("garbage-collected pool still exported: %v", instances)
	}
	if len(collector.entries) != 1 {
		t.Fatalf("dead pools must be pruned, have %d", len(collector.entries))
	}
}

func TestRegisterProcessMetricsExposesBuildInfoOnce(t *testing.T) {
	reg := prometheus.NewRegistry()
	RegisterProcessMetrics(reg, "mobile-bff")
	RegisterProcessMetrics(reg, "mobile-bff") // idempotent
	info := counterValues(t, reg, "verified_dating_build_info")
	if len(info) != 1 {
		t.Fatalf("build info series: %v", info)
	}
	for key, value := range info {
		if value != 1 || !strings.Contains(key, "service=mobile-bff") || !strings.Contains(key, "version=") || !strings.Contains(key, "commit=") {
			t.Fatalf("unexpected build info %s=%v", key, value)
		}
	}
}

func TestQueueCollectorPublishesSnapshots(t *testing.T) {
	reg := prometheus.NewRegistry()
	metrics := NewBFFMetrics(reg)
	metrics.TrackQueue("activity_fanout", func() QueueSnapshot {
		return QueueSnapshot{Depth: 8, Capacity: 10, Enqueued: 100, Processed: 90, Dropped: 2, MaxLag: 1500 * time.Millisecond}
	})
	if got := counterValues(t, reg, "verified_dating_queue_dropped_total")["queue=activity_fanout"]; got != 2 {
		t.Fatalf("dropped = %v", got)
	}
	if got := counterValues(t, reg, "verified_dating_queue_max_lag_seconds")["queue=activity_fanout"]; got != 1.5 {
		t.Fatalf("lag = %v", got)
	}
	var nilMetrics *HTTPMetrics
	nilMetrics.TrackQueue("x", nil) // nil-safe
	nilMetrics.ObserveRealtimeDelivery("chat", time.Now())
}
