package mobile

import (
	"testing"
	"time"

	"github.com/verified-dating/backend/internal/platform/config"
)

func TestPrimaryPoolFollowsConfiguredMaximum(t *testing.T) {
	cases := []struct {
		configured int
		want       int32
	}{
		{0, 16},  // unset: the historical default
		{8, 8},   // an operator lowering the cap is still honoured
		{16, 16}, // default
		{48, 48}, // raising it now takes effect on the hot pool
	}
	for _, tc := range cases {
		cfg := config.Config{PostgresPoolMaxConns: tc.configured}
		got := postgresOptions(cfg, primaryPoolMaxConns(cfg), 4).MaxConns
		if got != tc.want {
			t.Fatalf("POSTGRES_POOL_MAX_CONNS=%d: primary pool max=%d, want %d", tc.configured, got, tc.want)
		}
	}
}

func TestNotificationMetricsRefreshIsThrottledAcrossWorkers(t *testing.T) {
	engine := &notificationDeliveryEngine{}
	now := time.Unix(1_800_000_000, 0)
	if !engine.metricsRefreshDue(now) {
		t.Fatal("first refresh must run")
	}
	for i := 0; i < 10; i++ {
		if engine.metricsRefreshDue(now.Add(time.Duration(i) * time.Second)) {
			t.Fatalf("refresh ran again %ds later; the queue-metrics view scans the whole outbox", i)
		}
	}
	if !engine.metricsRefreshDue(now.Add(notificationMetricsRefreshInterval)) {
		t.Fatal("refresh must run again once the interval has passed")
	}
}
