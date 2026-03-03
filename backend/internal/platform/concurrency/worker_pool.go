package concurrency

import (
	"context"
	"sync"
)

type Task func(context.Context)

type WorkerPool struct {
	workers int
	jobs    chan Task
	wg      sync.WaitGroup
}

func NewWorkerPool(workers, queueSize int) *WorkerPool {
	if workers < 1 {
		workers = 1
	}
	if queueSize < workers {
		queueSize = workers
	}
	return &WorkerPool{
		workers: workers,
		jobs:    make(chan Task, queueSize),
	}
}

func (p *WorkerPool) Start(ctx context.Context) {
	for i := 0; i < p.workers; i++ {
		p.wg.Add(1)
		go func() {
			defer p.wg.Done()
			for {
				select {
				case <-ctx.Done():
					return
				case job, ok := <-p.jobs:
					if !ok {
						return
					}
					job(ctx)
				}
			}
		}()
	}
}

func (p *WorkerPool) Submit(task Task) {
	p.jobs <- task
}

func (p *WorkerPool) Close() {
	close(p.jobs)
	p.wg.Wait()
}
