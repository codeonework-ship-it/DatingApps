package mobile

import "github.com/verified-dating/backend/internal/platform/config"

// The in-memory constructor is intentionally test-only. Production composition
// uses newRuntimeStore with an injected durable repository client.
type memoryStore = runtimeStore

func init() {
	allowRuntimeMemoryFallback = true
}

func newMemoryStore(cfg config.Config) *memoryStore {
	return newRuntimeStore(cfg)
}
