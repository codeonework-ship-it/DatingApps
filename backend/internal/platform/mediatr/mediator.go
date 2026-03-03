package mediatr

import (
	"context"
	"fmt"
	"sync"
)

type HandlerFunc func(context.Context, any) (any, error)

type Mediator struct {
	mu       sync.RWMutex
	handlers map[string]HandlerFunc
}

func New() *Mediator {
	return &Mediator{handlers: map[string]HandlerFunc{}}
}

func (m *Mediator) Register(requestName string, handler HandlerFunc) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.handlers[requestName] = handler
}

func (m *Mediator) Send(ctx context.Context, requestName string, request any) (any, error) {
	m.mu.RLock()
	handler, found := m.handlers[requestName]
	m.mu.RUnlock()
	if !found {
		return nil, fmt.Errorf("mediatr handler not found: %s", requestName)
	}
	return handler(ctx, request)
}
