package mobile

import (
	"bytes"
	"context"
	"errors"
	"io"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/verified-dating/backend/internal/platform/config"
	"github.com/verified-dating/backend/internal/platform/observability"
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

const (
	timeoutTierFastRead   = "fast_read"
	timeoutTierNormalRead = "normal_read"
	timeoutTierWrite      = "write"
)

func (s *Server) timeoutTierMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if strings.EqualFold(strings.TrimSpace(r.Header.Get("Upgrade")), "websocket") {
			next.ServeHTTP(w, r)
			return
		}
		tier, timeout := s.requestTimeoutTier(r)
		if timeout <= 0 {
			next.ServeHTTP(w, r)
			return
		}

		ctx, cancel := context.WithTimeout(r.Context(), timeout)
		defer cancel()
		w.Header().Set("X-Timeout-Tier", tier)
		next.ServeHTTP(w, r.WithContext(ctx))
		if !errors.Is(ctx.Err(), context.DeadlineExceeded) {
			return
		}
		domain := s.routeDomain(r.URL.Path)
		if domain == "" {
			domain = "platform"
		}
		if s.httpMetrics != nil {
			s.httpMetrics.TimeoutCount.WithLabelValues(tier, domain).Inc()
		}
		if s.log != nil {
			s.log.Warn("request_timeout_tier_elapsed",
				zap.String("timeout_tier", tier),
				zap.String("domain", domain),
				zap.Duration("timeout", timeout),
				zap.String("method", r.Method),
				zap.String("path", observability.RedactedRequestPath(r)),
			)
		}
	})
}

func (s *Server) requestTimeoutTier(r *http.Request) (string, time.Duration) {
	if r.Method != http.MethodGet && r.Method != http.MethodHead && r.Method != http.MethodOptions {
		return timeoutTierWrite, s.cfg.BFFWriteTimeout()
	}
	path := strings.TrimPrefix(strings.TrimPrefix(r.URL.Path, s.cfg.APIPrefix), "/")
	if r.URL.Path == "/healthz" || r.URL.Path == "/readyz" ||
		strings.HasPrefix(path, "master-data/") ||
		strings.HasSuffix(path, "/unread-count") {
		return timeoutTierFastRead, s.cfg.BFFFastReadTimeout()
	}
	return timeoutTierNormalRead, s.cfg.BFFNormalReadTimeout()
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
		if (s.idempotency == nil && s.sharedIdempotency == nil) || !s.shouldApplyIdempotency(r) {
			next.ServeHTTP(w, r)
			return
		}

		idempotencyKey := strings.TrimSpace(r.Header.Get("Idempotency-Key"))
		if idempotencyKey == "" {
			next.ServeHTTP(w, r)
			return
		}
		if s.sharedIdempotency != nil {
			s.serveSharedIdempotent(next, w, r, idempotencyKey)
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
				s.recordIdempotencyReplay(r)
				writeIdempotentReplay(w, cachedResp)
				return
			}

			select {
			case <-entry.ready:
				cachedResp, exists, completed = s.idempotency.snapshot(cacheKey)
				if exists && completed {
					s.recordIdempotencyReplay(r)
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

func (s *Server) serveSharedIdempotent(next http.Handler, w http.ResponseWriter, r *http.Request, idempotencyKey string) {
	body := []byte(nil)
	if r.Body != nil {
		var err error
		body, err = io.ReadAll(r.Body)
		if err != nil {
			writeError(w, http.StatusBadRequest, errors.New("unable to read idempotent request"))
			return
		}
		r.Body = io.NopCloser(bytes.NewReader(body))
	}
	actor := strings.TrimSpace(r.Header.Get("X-User-ID"))
	if actor == "" {
		actor = strings.TrimSpace(r.Header.Get("X-Admin-User"))
	}
	cacheNamespace := s.buildIdempotencyCacheKey(r, idempotencyKey)
	requestHash := idempotencyDigest(r.URL.RawQuery + "\x00" + string(body))
	claim, err := s.sharedIdempotency.claim(
		r.Context(), cacheNamespace, r.Method, r.URL.Path, actor, idempotencyKey, requestHash,
	)
	if errors.Is(err, errIdempotencyPayloadConflict) {
		s.recordIdempotencyConflict(r)
		writeJSON(w, http.StatusConflict, map[string]any{
			"success": false, "error": err.Error(), "error_code": "IDEMPOTENCY_KEY_CONFLICT",
		})
		return
	}
	if errors.Is(err, errIdempotencyOutcomeUncertain) {
		writeJSON(w, http.StatusConflict, map[string]any{
			"success": false, "error": err.Error(), "error_code": "COMMAND_OUTCOME_UNCERTAIN",
			"recovery": map[string]any{
				"status_url":      s.cfg.APIPrefix + "/operations/status",
				"idempotency_key": idempotencyKey,
				"method":          r.Method, "path": r.URL.Path,
			},
		})
		return
	}
	if err != nil {
		if errors.Is(err, context.Canceled) || errors.Is(err, context.DeadlineExceeded) {
			writeError(w, http.StatusRequestTimeout, err)
			return
		}
		writeError(w, http.StatusServiceUnavailable, errors.New("idempotency persistence is unavailable"))
		return
	}
	if claim.replay {
		s.recordIdempotencyReplay(r)
		writeIdempotentReplay(w, claim.response)
		return
	}
	w.Header().Set("X-Operation-ID", claim.cacheKey)

	recorder := newIdempotencyResponseRecorder(w)
	next.ServeHTTP(recorder, r)
	status := recorder.status
	if status == 0 {
		status = http.StatusOK
	}
	response := idempotentResponse{
		status: status, contentType: strings.TrimSpace(recorder.Header().Get("Content-Type")),
		body: append([]byte(nil), recorder.body.Bytes()...),
	}
	finishCtx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	err = s.sharedIdempotency.finish(finishCtx, claim, response, status < http.StatusInternalServerError)
	cancel()
	if err != nil && s.log != nil {
		s.log.Warn("idempotency response persistence failed", zap.Error(err))
	}
}

func (s *Server) recordIdempotencyReplay(r *http.Request) {
	if s.httpMetrics == nil {
		return
	}
	domain := s.routeDomain(r.URL.Path)
	if domain == "" {
		domain = "platform"
	}
	s.httpMetrics.IdempotencyReplays.WithLabelValues(domain).Inc()
}

func (s *Server) recordIdempotencyConflict(r *http.Request) {
	if s.httpMetrics == nil {
		return
	}
	domain := s.routeDomain(r.URL.Path)
	if domain == "" {
		domain = "platform"
	}
	s.httpMetrics.IdempotencyConflicts.WithLabelValues(domain).Inc()
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
	if strings.HasPrefix(path, "blog/public/") {
		return false
	}
	// Invitation tokens, like credentials, must not enter cached response ledgers.
	if (path == "introducer/invites" && r.Method == http.MethodPost) || strings.HasPrefix(path, "media/") {
		return false
	}

	// Credential issuance and recovery have dedicated brute-force and token
	// rotation semantics; a cached HTTP response could replay live credentials.
	// Protected session mutations remain covered after securityMiddleware binds
	// the actor to the verified session.
	if strings.HasPrefix(path, "auth/") {
		switch path {
		case "auth/logout", "auth/sessions/revoke", "auth/password/change", "auth/recovery-code/rotate", "auth/signup/bootstrap":
			return true
		default:
			return false
		}
	}

	// Provider webhooks are deduplicated on the provider's own event id in
	// the billing ledger, and the sandbox card form is a browser POST with no
	// client key. Neither is a client command to replay.
	if strings.HasPrefix(path, "billing/webhooks/") || strings.HasPrefix(path, "billing/sandbox/checkout/") {
		return false
	}

	// Crash reports are telemetry, deduplicated and capped server-side, and
	// mostly anonymous: there is no principal to namespace a replay ledger by.
	if path == "client/errors" {
		return false
	}

	// Multipart uploads can exceed the bounded replay response/body budget and
	// already carry durable content-digest semantics in the media repository.
	if r.Method == http.MethodPost && strings.HasPrefix(path, "profile/") && strings.HasSuffix(path, "/photos") {
		return false
	}

	// Blog photos use a stable photo UUID + digest and post version. Do not
	// buffer multipart bodies or cache private-photo responses in the ledger.
	if r.Method == http.MethodPut && strings.HasPrefix(path, "blog/posts/") && strings.Contains(path, "/photos/") {
		return false
	}

	// Photo Theme uploads use a stable entry UUID + content digest, like blog
	// photos, and must not buffer multipart bodies in the replay ledger.
	// Only the upload itself (themes/{id}/entries/{id}); likes and comments
	// below it are ordinary JSON commands that keep replay protection.
	if r.Method == http.MethodPut && strings.HasPrefix(path, "themes/") && strings.Contains(path, "/entries/") && strings.Count(strings.Trim(path, "/"), "/") == 3 {
		return false
	}

	// Group cover uploads (engagement/groups/{id}/cover) are multipart like
	// theme photos; an optional client cover_id makes retries safe. Removing
	// the cover (DELETE) keeps replay protection.
	if r.Method == http.MethodPut && strings.HasPrefix(path, "engagement/groups/") && strings.HasSuffix(path, "/cover") && strings.Count(strings.Trim(path, "/"), "/") == 3 {
		return false
	}

	// Every remaining authenticated command is a critical write. Keeping this
	// rule broad makes newly registered commands repeat-safe by default; the
	// OpenAPI contract test prevents an undocumented addition.
	return true
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
		if strings.EqualFold(strings.TrimSpace(r.Header.Get("Upgrade")), "websocket") {
			next.ServeHTTP(w, r)
			return
		}
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
			if s.httpMetrics != nil {
				s.httpMetrics.ShedCount.WithLabelValues(domain).Inc()
			}
			w.Header().Set("Retry-After", "1")
			writeJSON(w, http.StatusTooManyRequests, map[string]any{
				"success":         false,
				"error":           "service overloaded, retry later",
				"error_code":      "REQUEST_SHEDDED",
				"retry_after_sec": 1,
				"domain":          domain,
			})
			if s.log != nil {
				s.log.Warn("bulkhead_request_shedded",
					zap.String("domain", domain),
					zap.String("method", r.Method),
					zap.String("path", observability.RedactedRequestPath(r)),
				)
			}
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
	case "chat", "calls", "realtime":
		return "messaging"
	case "activities", "friends", "rooms", "safety", "billing", "analytics", "progression":
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
