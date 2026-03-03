package concurrency

import (
	"context"
	"sync/atomic"
	"testing"
	"time"
)

func TestWorkerPoolRunsTasks(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	pool := NewWorkerPool(4, 16)
	pool.Start(ctx)
	defer pool.Close()

	var processed int64
	for i := 0; i < 10; i++ {
		pool.Submit(func(context.Context) {
			atomic.AddInt64(&processed, 1)
		})
	}

	deadline := time.Now().Add(2 * time.Second)
	for atomic.LoadInt64(&processed) < 10 && time.Now().Before(deadline) {
		time.Sleep(10 * time.Millisecond)
	}

	if got := atomic.LoadInt64(&processed); got != 10 {
		t.Fatalf("expected 10 processed tasks, got %d", got)
	}
}
