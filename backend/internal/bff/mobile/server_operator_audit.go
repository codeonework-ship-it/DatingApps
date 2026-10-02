package mobile

import (
	"context"
	"database/sql"
	"net/http"
	"strings"

	"go.uber.org/zap"

	"github.com/verified-dating/backend/internal/platform/observability"
)

// operatorAuditMiddleware writes an append-only record of every successful
// operator mutation to audit.security_events.
//
// Domain repositories already emit rich, transactional events for moderation,
// appeals, SOS, verification and account enforcement. They did not cover the
// rest of the operator surface — granting coins, editing coin packages,
// flipping feature flags, editing the gift catalogue, creating and deleting
// admin users — which is precisely the set an auditor would ask about first.
//
// Doing this per handler leaves the trail only as complete as the last person
// to remember. Recording it in middleware means a new admin route is audited
// the moment it is mounted, with no opportunity to forget. The domain events
// remain the detailed record; this is the guaranteed floor beneath them.
func (s *Server) operatorAuditMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if !s.isOperatorMutation(r) {
			next.ServeHTTP(w, r)
			return
		}

		recorder := &responseStatusRecorder{ResponseWriter: w, status: http.StatusOK}
		next.ServeHTTP(recorder, r)

		// Only successful mutations are recorded. A rejected request is
		// already covered by the request log; writing it here would dilute the
		// trail with noise an auditor has to filter out.
		if recorder.status < 200 || recorder.status >= 300 {
			return
		}
		s.recordOperatorEvent(r, recorder.status)
	})
}

// isOperatorMutation reports whether the request changes state on the
// administrative surface.
func (s *Server) isOperatorMutation(r *http.Request) bool {
	switch r.Method {
	case http.MethodGet, http.MethodHead, http.MethodOptions:
		return false
	}
	return strings.HasPrefix(r.URL.Path, s.cfg.APIPrefix+"/admin/")
}

// recordOperatorEvent persists a single audit row.
//
// Failures are logged rather than surfaced: the operator's action has already
// been committed and returned, so failing the response here would report a
// false error for work that actually succeeded. A dropped row is instead an
// alertable log line.
func (s *Server) recordOperatorEvent(r *http.Request, status int) {
	if s.store == nil || s.store.profileRepo == nil || s.store.profileRepo.pg == nil {
		return
	}

	principal, ok := principalFromRequest(r)
	if !ok || strings.TrimSpace(principal.UserID) == "" {
		return
	}

	resourceType, resourceID := operatorResourceFromPath(s.cfg.APIPrefix, r.URL.Path)
	payload := map[string]any{
		"method": r.Method,
		"path":   r.URL.Path,
		"status": status,
	}
	if correlationID := strings.TrimSpace(r.Header.Get("X-Correlation-ID")); correlationID != "" {
		payload["correlation_id"] = correlationID
	}

	// Detached from the request context on purpose: the client may already have
	// disconnected, and the audit row must still be written.
	ctx := context.WithoutCancel(r.Context())
	tx, err := s.store.profileRepo.pg.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelReadCommitted})
	if err != nil {
		s.logAuditFailure(r, err)
		return
	}
	defer func() { _ = tx.Rollback() }()

	if err := insertSecurityEventTx(
		ctx, tx,
		"admin.request",
		principal.UserID,
		operatorRoleOf(principal),
		"", // subject is route-specific; the resource fields carry the target
		resourceType,
		resourceID,
		payload,
	); err != nil {
		s.logAuditFailure(r, err)
		return
	}
	if err := tx.Commit(); err != nil {
		s.logAuditFailure(r, err)
	}
}

func (s *Server) logAuditFailure(r *http.Request, err error) {
	if s.log == nil {
		return
	}
	s.log.Error(
		"operator_audit_write_failed",
		zap.String("method", r.Method),
		zap.String("path", observability.RedactedRequestPath(r)),
		zap.Error(err),
	)
}

// operatorRoleOf reports the strongest operator role the principal holds, so
// the trail distinguishes a trust-and-safety action from a full admin one.
func operatorRoleOf(principal securityPrincipal) string {
	for _, role := range []string{"admin", "ops_admin", "trust_safety", "finance", "support"} {
		if principal.Roles[role] {
			return role
		}
	}
	return "operator"
}

// operatorResourceFromPath derives the audited resource from the route.
//
// "/v1/admin/users/{id}/ban" yields ("users", "{id}"); "/v1/admin/config/flags"
// yields ("config/flags", ""). The identifier is taken as the last segment that
// is not a bare action word, which is what makes the row answer "what was
// changed" rather than only "which endpoint was called".
func operatorResourceFromPath(prefix, path string) (string, string) {
	trimmed := strings.TrimPrefix(path, prefix+"/admin/")
	segments := []string{}
	for _, segment := range strings.Split(trimmed, "/") {
		if strings.TrimSpace(segment) != "" {
			segments = append(segments, segment)
		}
	}
	if len(segments) == 0 {
		return "admin", ""
	}

	// Trailing verbs describe the action, not the target.
	actions := map[string]bool{
		"ban": true, "unban": true, "suspend": true, "unsuspend": true,
		"verify": true, "approve": true, "reject": true, "resolve": true,
		"action": true, "toggle": true, "activate": true, "grant-coins": true,
		"adjust-xp": true, "control": true, "decision": true,
	}
	if len(segments) > 1 && actions[segments[len(segments)-1]] {
		segments = segments[:len(segments)-1]
	}

	if len(segments) == 1 {
		return segments[0], ""
	}

	// A trailing collection name is part of the resource type; anything else is
	// an identifier.
	//
	// Deliberately not keyed on punctuation: identifiers here are frequently
	// hyphenated (UUIDs always are), so treating a hyphen as a sign of a
	// collection name misclassifies every id in the system.
	last := segments[len(segments)-1]
	if isLikelyCollectionSegment(last) {
		return strings.Join(segments, "/"), ""
	}
	return strings.Join(segments[:len(segments)-1], "/"), last
}

func isLikelyCollectionSegment(segment string) bool {
	switch segment {
	case "users", "flags", "gifts", "prompts", "appeals", "reports", "plans",
		"payments", "subscriptions", "transactions", "stats", "activities",
		"verifications", "sos-alerts", "coin-packages":
		return true
	}
	return false
}
