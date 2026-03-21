package mobile

import (
	"bytes"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/verified-dating/backend/internal/platform/config"
	"go.uber.org/zap"
)

type idempotentResponse struct {
	status      int
	contentType string
	body        []byte
}

type idempotencyEntry struct {
	ready     chan struct{}
	createdAt time.Time
	completed bool
	response  idempotentResponse
}

type idempotencyStore struct {
	ttl     time.Duration
	mu      sync.Mutex
	entries map[string]*idempotencyEntry
}

func newIdempotencyStore(ttl time.Duration) *idempotencyStore {
	if ttl <= 0 {
		ttl = 10 * time.Minute
	}
	return &idempotencyStore{
		ttl:     ttl,
		entries: make(map[string]*idempotencyEntry),
	}
}

func (s *idempotencyStore) getOrCreate(key string) (*idempotencyEntry, bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.purgeExpiredLocked(time.Now().UTC())
	if entry, ok := s.entries[key]; ok {
		return entry, false
	}
	entry := &idempotencyEntry{
		ready:     make(chan struct{}),
		createdAt: time.Now().UTC(),
	}
	s.entries[key] = entry
	return entry, true
}

func (s *idempotencyStore) snapshot(key string) (idempotentResponse, bool, bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	entry, ok := s.entries[key]
	if !ok {
		return idempotentResponse{}, false, false
	}
	if !entry.completed {
		return idempotentResponse{}, true, false
	}
	copyBody := make([]byte, len(entry.response.body))
	copy(copyBody, entry.response.body)
	resp := idempotentResponse{status: entry.response.status, contentType: entry.response.contentType, body: copyBody}
	return resp, true, true
}

func (s *idempotencyStore) finish(key string, resp idempotentResponse, cache bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	entry, ok := s.entries[key]
	if !ok {
		return
	}
	if cache {
		entry.completed = true
		entry.response = resp
		select {
		case <-entry.ready:
		default:
			close(entry.ready)
		}
		return
	}
	delete(s.entries, key)
	select {
	case <-entry.ready:
	default:
		close(entry.ready)
	}
}

func (s *idempotencyStore) purgeExpiredLocked(now time.Time) {
	for key, entry := range s.entries {
		if now.Sub(entry.createdAt) <= s.ttl {
			continue
		}
		delete(s.entries, key)
		select {
		case <-entry.ready:
		default:
			close(entry.ready)
		}
	}
}

func (s *Server) idempotencyMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if s.idempotency == nil || !s.shouldApplyIdempotency(r) {
			next.ServeHTTP(w, r)
			return
		}

		idempotencyKey := strings.TrimSpace(r.Header.Get("Idempotency-Key"))
		if idempotencyKey == "" {
			next.ServeHTTP(w, r)
			return
		}

		cacheKey := s.buildIdempotencyCacheKey(r, idempotencyKey)
		for {
			entry, owner := s.idempotency.getOrCreate(cacheKey)
			if owner {
				recorder := newIdempotencyResponseRecorder(w)
				next.ServeHTTP(recorder, r)

				status := recorder.status
				if status == 0 {
					status = http.StatusOK
				}
				resp := idempotentResponse{
					status:      status,
					contentType: strings.TrimSpace(recorder.Header().Get("Content-Type")),
					body:        recorder.body.Bytes(),
				}
				s.idempotency.finish(cacheKey, resp, status < http.StatusInternalServerError)
				return
			}

			cachedResp, exists, completed := s.idempotency.snapshot(cacheKey)
			if exists && completed {
				writeIdempotentReplay(w, cachedResp)
				return
			}

			select {
			case <-entry.ready:
				cachedResp, exists, completed = s.idempotency.snapshot(cacheKey)
				if exists && completed {
					writeIdempotentReplay(w, cachedResp)
					return
				}
				continue
			case <-r.Context().Done():
				writeError(w, http.StatusRequestTimeout, r.Context().Err())
				return
			}
		}
	})
}

func writeIdempotentReplay(w http.ResponseWriter, resp idempotentResponse) {
	w.Header().Set("X-Idempotent-Replay", "true")
	if strings.TrimSpace(resp.contentType) != "" {
		w.Header().Set("Content-Type", resp.contentType)
	}
	status := resp.status
	if status <= 0 {
		status = http.StatusOK
	}
	w.WriteHeader(status)
	if len(resp.body) > 0 {
		_, _ = w.Write(resp.body)
	}
}

func (s *Server) shouldApplyIdempotency(r *http.Request) bool {
	if r.Method != http.MethodPost && r.Method != http.MethodPatch && r.Method != http.MethodPut && r.Method != http.MethodDelete {
		return false
	}
	if !strings.HasPrefix(r.URL.Path, s.cfg.APIPrefix+"/") {
		return false
	}

	path := strings.TrimPrefix(strings.TrimPrefix(r.URL.Path, s.cfg.APIPrefix), "/")
	if strings.HasPrefix(path, "auth/") || strings.HasPrefix(path, "media/") {
		return false
	}

	if r.Method == http.MethodPost && path == "swipe" {
		return true
	}
	if r.Method == http.MethodPatch && strings.HasPrefix(path, "users/") && strings.HasSuffix(path, "/agreements/terms") {
		return true
	}
	if r.Method == http.MethodPost && strings.HasPrefix(path, "chat/") && strings.HasSuffix(path, "/messages") {
		return true
	}
	if r.Method == http.MethodPost && strings.HasPrefix(path, "chat/") && strings.HasSuffix(path, "/gifts/send") {
		return true
	}
	if r.Method == http.MethodPost && strings.Contains(path, "/quest-workflow/submit") {
		return true
	}
	if r.Method == http.MethodPost && strings.Contains(path, "/quest-workflow/review") {
		return true
	}
	if r.Method == http.MethodPost && strings.Contains(path, "/gestures/") &&
		(strings.HasSuffix(path, "/decision") || strings.HasSuffix(path, "/respond")) {
		return true
	}
	if r.Method == http.MethodPost && strings.HasPrefix(path, "billing/subscribe") {
		return true
	}
	return false
}

func (s *Server) buildIdempotencyCacheKey(r *http.Request, idempotencyKey string) string {
	actor := strings.TrimSpace(r.Header.Get("X-User-ID"))
	if actor == "" {
		actor = strings.TrimSpace(r.Header.Get("X-Admin-User"))
	}
	return strings.Join([]string{r.Method, r.URL.Path, actor, idempotencyKey}, "|")
}

func newBulkheadLimiters(cfg config.Config) map[string]chan struct{} {
	makeLimiter := func(max int) chan struct{} {
		if max <= 0 {
			return nil
		}
		return make(chan struct{}, max)
	}

	return map[string]chan struct{}{
		"auth":       makeLimiter(cfg.BFFBulkheadAuthMaxInFlight),
		"profile":    makeLimiter(cfg.BFFBulkheadProfileMaxInFlight),
		"matching":   makeLimiter(cfg.BFFBulkheadMatchingMaxInFlight),
		"messaging":  makeLimiter(cfg.BFFBulkheadMessagingMaxInFlight),
		"engagement": makeLimiter(cfg.BFFBulkheadEngagementMaxInFlight),
		"admin":      makeLimiter(cfg.BFFBulkheadAdminMaxInFlight),
	}
}

func (s *Server) bulkheadMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		domain := s.routeDomain(r.URL.Path)
		if domain == "" {
			next.ServeHTTP(w, r)
			return
		}

		limiter, ok := s.bulkheads[domain]
		if !ok || limiter == nil {
			next.ServeHTTP(w, r)
			return
		}

		select {
		case limiter <- struct{}{}:
			defer func() { <-limiter }()
			next.ServeHTTP(w, r)
			return
		default:
			w.Header().Set("Retry-After", "1")
			writeJSON(w, http.StatusTooManyRequests, map[string]any{
				"success":         false,
				"error":           "service overloaded, retry later",
				"error_code":      "REQUEST_SHEDDED",
				"retry_after_sec": 1,
				"domain":          domain,
			})
			s.log.Warn("bulkhead_request_shedded",
				zap.String("domain", domain),
				zap.String("method", r.Method),
				zap.String("path", r.URL.Path),
			)
		}
	})
}

func (s *Server) routeDomain(path string) string {
	if !strings.HasPrefix(path, s.cfg.APIPrefix+"/") {
		return ""
	}
	trimmed := strings.TrimPrefix(strings.TrimPrefix(path, s.cfg.APIPrefix), "/")
	if trimmed == "" {
		return ""
	}
	segment := trimmed
	if idx := strings.Index(segment, "/"); idx > 0 {
		segment = segment[:idx]
	}
	switch segment {
	case "auth":
		return "auth"
	case "profile", "settings", "emergency-contacts", "blocked-users", "verification", "users", "master-data":
		return "profile"
	case "discovery", "swipe", "matches":
		return "matching"
	case "chat", "calls":
		return "messaging"
	case "activities", "friends", "rooms", "safety", "billing", "analytics":
		return "engagement"
	case "admin":
		return "admin"
	default:
		return ""
	}
}

type idempotencyResponseRecorder struct {
	http.ResponseWriter
	status int
	body   bytes.Buffer
}

func newIdempotencyResponseRecorder(w http.ResponseWriter) *idempotencyResponseRecorder {
	return &idempotencyResponseRecorder{ResponseWriter: w, status: http.StatusOK}
}

func (r *idempotencyResponseRecorder) WriteHeader(statusCode int) {
	r.status = statusCode
	r.ResponseWriter.WriteHeader(statusCode)
}

func (r *idempotencyResponseRecorder) Write(data []byte) (int, error) {
	if r.status == 0 {
		r.status = http.StatusOK
	}
	r.body.Write(data)
	return r.ResponseWriter.Write(data)
}
