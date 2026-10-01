package observability

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/prometheus/client_golang/prometheus"
)

func TestWorkerHeartbeatRecordsSuccessFailureAndCancellation(t *testing.T) {
	reg := prometheus.NewRegistry()
	workers := NewWorkerMetrics(reg)
	clock := time.Unix(1_700_000_000, 0)
	workers.now = func() time.Time { return clock }
	heartbeat := workers.Heartbeat("media_cleanup", time.Hour)

	// First run seeds last_success with the start time and publishes the interval.
	run := heartbeat.Begin()
	clock = clock.Add(2 * time.Second)
	run.Items("processed", 4)
	run.Items("failed", 1)
	run.End(errors.New("candidate query failed"))

	if got := counterValues(t, reg, "verified_dating_worker_expected_interval_seconds")["worker=media_cleanup"]; got != 3600 {
		t.Fatalf("expected interval = %v", got)
	}
	if got := counterValues(t, reg, "verified_dating_worker_last_success_timestamp_seconds")["worker=media_cleanup"]; got != 1_700_000_000 {
		t.Fatalf("seeded last success = %v, want start time", got)
	}
	if got := counterValues(t, reg, "verified_dating_worker_runs_total")["result=error,worker=media_cleanup"]; got != 1 {
		t.Fatalf("error runs = %v", got)
	}
	items := counterValues(t, reg, "verified_dating_worker_items_total")
	if items["outcome=processed,worker=media_cleanup"] != 4 || items["outcome=failed,worker=media_cleanup"] != 1 {
		t.Fatalf("items = %v", items)
	}

	clock = clock.Add(time.Minute)
	run = heartbeat.Begin()
	clock = clock.Add(time.Second)
	run.End(nil)
	run.End(nil) // idempotent
	if got := counterValues(t, reg, "verified_dating_worker_last_success_timestamp_seconds")["worker=media_cleanup"]; got != float64(clock.Unix()) {
		t.Fatalf("last success = %v, want %v", got, clock.Unix())
	}
	if got := counterValues(t, reg, "verified_dating_worker_runs_total")["result=success,worker=media_cleanup"]; got != 1 {
		t.Fatalf("success runs = %v", got)
	}
	if got := counterValues(t, reg, "verified_dating_worker_run_duration_seconds")["worker=media_cleanup"]; got != 2 {
		t.Fatalf("duration observations = %v", got)
	}

	// Shutdown cancellation is neither a success nor a failure.
	before := counterValues(t, reg, "verified_dating_worker_runs_total")
	run = heartbeat.Begin()
	run.End(context.Canceled)
	after := counterValues(t, reg, "verified_dating_worker_runs_total")
	for key, value := range after {
		if before[key] != value {
			t.Fatalf("cancellation changed %s: %v -> %v", key, before[key], value)
		}
	}

	heartbeat.SetBacklog(17)
	if got := counterValues(t, reg, "verified_dating_worker_backlog")["worker=media_cleanup"]; got != 17 {
		t.Fatalf("backlog = %v", got)
	}
}

func TestDefaultHeartbeatIsNoOpUntilBFFMetricsExist(t *testing.T) {
	previous := DefaultWorkerMetrics()
	defer SetDefaultWorkerMetrics(previous)

	SetDefaultWorkerMetrics(nil)
	heartbeat := NewHeartbeat("billing_renewal_sweep", 5*time.Minute)
	run := heartbeat.Begin()
	run.Items("processed", 3)
	run.End(nil) // must not panic
	heartbeat.SetBacklog(1)

	reg := prometheus.NewRegistry()
	NewBFFMetrics(reg) // installs the default
	heartbeat.Begin().End(nil)
	if got := counterValues(t, reg, "verified_dating_worker_runs_total")["result=success,worker=billing_renewal_sweep"]; got != 1 {
		t.Fatalf("heartbeat created before registration must use the default later, got %v", got)
	}
}
