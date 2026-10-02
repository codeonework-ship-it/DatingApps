package mobile

import (
	"bytes"
	"context"
	"crypto/rand"
	"crypto/sha256"
	"database/sql"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strings"

	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
)

type securityPrincipal struct {
	AccountKind   string
	TermsAccepted bool
	SessionID     string
	UserID        string
	Roles         map[string]bool
}

// realtimeSessionAuthorizer rechecks a long-lived connection against durable
// account state. HTTP middleware authenticates the upgrade request, but a
// revoked, suspended, deactivated or deletion-pending session must also stop
// receiving events without waiting for the socket to reconnect.
type realtimeSessionAuthorizer interface {
	authorizeRealtimeSession(context.Context, securityPrincipal) error
}

type securityPrincipalContextKey struct{}

const securityRequestBodyLimit = 1 << 20

func (s *Server) securityMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// X-Admin-User is an audit label, never a credential. Strip whatever the
		// caller sent on every single request; the only value that survives is
		// the one written below from a verified principal.
		r.Header.Del("X-Admin-User")

		if !strings.HasPrefix(r.URL.Path, s.cfg.APIPrefix+"/") || isPublicSecurityPath(s.cfg.APIPrefix, r.URL.Path, r.Method) {
			next.ServeHTTP(w, r)
			return
		}

		isAdminPath := strings.HasPrefix(r.URL.Path, s.cfg.APIPrefix+"/admin/")

		resolvePrincipal := s.principalResolver()
		if resolvePrincipal == nil {
			// No principal store is configured, so no operator can be
			// authenticated. Refuse the administrative surface outright rather
			// than let it through unguarded — that combination is precisely the
			// bypass this middleware exists to prevent. User-scoped routes are
			// left to the handlers, which is the long-standing behaviour for
			// store-less deployments and unit tests.
			if isAdminPath {
				writeError(w, http.StatusServiceUnavailable, errors.New("administrative actions require authentication persistence"))
				return
			}
			next.ServeHTTP(w, r)
			return
		}
		principal, err := resolvePrincipal(r)
		if errors.Is(err, errAuthStoreUnavailable) {
			// A database fault is not a bad credential: a 401 here would sign
			// the member out, so ask the client to retry instead.
			logUnexpectedError(w, err)
			w.Header().Set("Retry-After", "2")
			writeError(w, http.StatusServiceUnavailable, errAuthStoreUnavailable)
			return
		}
		if err != nil {
			writeError(w, http.StatusUnauthorized, errors.New("valid bearer session is required"))
			return
		}
		if principal.AccountKind == "introducer" && !introducerRouteAllowed(s.cfg.APIPrefix, r.Method, r.URL.Path, principal) {
			writeError(w, http.StatusForbidden, errors.New("this action is unavailable for an introducer account"))
			return
		}
		if isAdminPath && !principalCanAccessAdminRoute(principal, s.cfg.APIPrefix, r.Method, r.URL.Path) {
			writeError(w, http.StatusForbidden, errors.New("operator role does not permit this administrative action"))
			return
		}
		if !pathOwnedByPrincipal(s.cfg.APIPrefix, r.URL.Path, r.Method, principal.UserID) {
			writeError(w, http.StatusForbidden, errors.New("resource does not belong to the authenticated user"))
			return
		}
		if err := enforceBodyIdentity(r, principal.UserID); err != nil {
			writeError(w, http.StatusForbidden, err)
			return
		}
		// Match ownership can only be validated against the SQL store. In
		// production a resolver implies that store exists; guarding here keeps
		// the middleware from dereferencing a nil repository when a caller has
		// been authenticated by some other means.
		matchID := requestMatchID(r, s.cfg.APIPrefix, principal.UserID)
		if matchID != "" && s.store != nil && s.store.profileRepo != nil && s.store.profileRepo.pg != nil {
			allowed, err := s.store.profileRepo.userCanAccessMatch(r.Context(), principal.UserID, matchID)
			if err != nil {
				writeError(w, http.StatusServiceUnavailable, errors.New("unable to validate match ownership"))
				return
			}
			if !allowed {
				writeError(w, http.StatusForbidden, errors.New("match does not belong to the authenticated user"))
				return
			}
		}
		r.Header.Set("X-User-ID", principal.UserID)
		if principal.Roles["admin"] {
			r.Header.Set("X-Admin-User", principal.UserID)
		} else {
			r.Header.Del("X-Admin-User")
		}
		next.ServeHTTP(w, r.WithContext(context.WithValue(r.Context(), securityPrincipalContextKey{}, principal)))
	})
}

func principalCanAccessAdminRoute(principal securityPrincipal, prefix, method, requestPath string) bool {
	if principal.Roles["admin"] {
		return true
	}
	path := strings.TrimPrefix(requestPath, prefix+"/admin/")
	isRead := method == http.MethodGet || method == http.MethodHead || method == http.MethodOptions
	// Client crash/error reports (client_errors.go): ops admins triage them,
	// analysts may read them. Reports are anonymous app diagnostics.
	if path == "client-errors" || strings.HasPrefix(path, "client-errors/") {
		return principal.Roles["ops_admin"] || (isRead && principal.Roles["analyst"])
	}
	// Support tickets (support_admin.go): support agents, ops admins and the
	// trust & safety roles work the queue; analysts read the SLA dashboard.
	if path == "support" || strings.HasPrefix(path, "support/") {
		if principal.Roles["support"] || principal.Roles["ops_admin"] || principal.Roles["trust_safety"] || principal.Roles["moderator"] {
			return true
		}
		return isRead && principal.Roles["analyst"] && path == "support/dashboard"
	}
	// A support agent can open the console (its login probe reads the
	// overview) and nothing else outside the support area.
	if principal.Roles["support"] && isRead && path == "analytics/overview" {
		return true
	}
	// Product analytics reports (server_admin_analytics_reports.go) are for
	// analysts, read-only. The legacy overview stays readable by every operator
	// role (the console login probes it). Rebuilds and test-account flags are
	// admin-only; flags name individual members.
	if strings.HasPrefix(path, "analytics/") && path != "analytics/overview" {
		return isRead && principal.Roles["analyst"] && !strings.HasPrefix(path, "analytics/excluded-accounts")
	}
	if strings.HasPrefix(path, "growth/city-pilot") && principal.Roles["trust_safety"] {
		return isRead || strings.HasSuffix(path, "/stage") || strings.HasSuffix(path, "/cancel")
	}
	if strings.HasPrefix(path, "growth/city-pilot") && principal.Roles["analyst"] && isRead {
		return true
	}
	if principal.Roles["trust_safety"] &&
		(strings.HasPrefix(path, "billing/fraud/cases") || (isRead && strings.HasPrefix(path, "billing/fraud/rules"))) {
		return true
	}

	if principal.Roles["trust_safety"] || principal.Roles["moderator"] {
		if strings.HasPrefix(path, "moderation/") || strings.HasPrefix(path, "verifications") ||
			strings.HasPrefix(path, "safety/") || strings.HasPrefix(path, "support/") ||
			strings.HasPrefix(path, "growth/fraud-graph") {
			return true
		}
		if isRead && (strings.HasPrefix(path, "users") || strings.HasPrefix(path, "activities") || strings.HasPrefix(path, "audit-events") || strings.HasPrefix(path, "events") || strings.HasPrefix(path, "analytics/")) {
			return true
		}
		if strings.HasPrefix(path, "users/") {
			for _, action := range []string{"/suspend", "/unsuspend", "/ban", "/unban", "/verify"} {
				if strings.HasSuffix(path, action) {
					return true
				}
			}
		}
	}

	// Business reports (documents/BUSINESS_REPORTS_2026-10-01.md): finance,
	// ops_admin and analyst read them; only finance (and admin) record
	// marketing spend; finance and ops_admin maintain launch-market gates.
	if strings.HasPrefix(path, "business/") {
		if isRead {
			return principal.Roles["finance"] || principal.Roles["ops_admin"] || principal.Roles["analyst"]
		}
		if strings.HasPrefix(path, "business/marketing-spend") {
			return principal.Roles["finance"]
		}
		if path == "business/markets" {
			return principal.Roles["finance"] || principal.Roles["ops_admin"]
		}
		return false
	}
	// finance reads money: billing reports and the console's login probe.
	if principal.Roles["finance"] && isRead {
		for _, prefix := range []string{"billing/stats", "billing/transactions", "billing/subscriptions", "billing/payments",
			"billing/webhook-events", "billing/reconciliation", "billing/revenue-analytics", "billing/plans", "billing/coin-packages"} {
			if strings.HasPrefix(path, prefix) {
				return true
			}
		}
		if path == "analytics/overview" {
			return true
		}
	}

	if principal.Roles["ops_admin"] {
		if strings.HasPrefix(path, "catalog/") || strings.HasPrefix(path, "config/") ||
			strings.HasPrefix(path, "engagement/") || strings.HasPrefix(path, "billing/") ||
			strings.HasPrefix(path, "progression") || strings.HasPrefix(path, "support/") ||
			strings.HasPrefix(path, "growth/") {
			return true
		}
		if isRead && (strings.HasPrefix(path, "users") || strings.HasPrefix(path, "activities") || strings.HasPrefix(path, "audit-events") || strings.HasPrefix(path, "events") || strings.HasPrefix(path, "analytics/")) {
			return true
		}
	}

	if principal.Roles["analyst"] && isRead {
		return strings.HasPrefix(path, "analytics/") || strings.HasPrefix(path, "activities") || strings.HasPrefix(path, "audit-events") || strings.HasPrefix(path, "events") ||
			strings.HasPrefix(path, "billing/stats") || strings.HasPrefix(path, "billing/transactions") ||
			strings.HasPrefix(path, "billing/subscriptions") || strings.HasPrefix(path, "billing/payments") ||
			strings.HasPrefix(path, "billing/webhook-events") || strings.HasPrefix(path, "billing/reconciliation") ||
			strings.HasPrefix(path, "billing/revenue-analytics") || strings.HasPrefix(path, "users")
	}
	return false
}

func isPublicSecurityPath(prefix, requestPath, method string) bool {
	if strings.HasPrefix(requestPath, prefix+"/blog/public/") && (method == http.MethodGet || (method == http.MethodPost && strings.HasSuffix(requestPath, "/report"))) {
		return true
	}
	if method == http.MethodGet && (requestPath == prefix+"/chapters/catalogue" || strings.HasPrefix(requestPath, prefix+"/chapters/public/")) {
		return true
	}
	public := map[string]bool{
		prefix + "/auth/login":               true,
		prefix + "/auth/signup":              true,
		prefix + "/auth/refresh":             true,
		prefix + "/auth/password/recover":    true,
		prefix + "/auth/recovery/assistance": true,
		prefix + "/master-data/preferences":  true,
		prefix + "/billing/plans":            true,
	}
	if public[requestPath] {
		return true
	}
	// Crash reports must also arrive from signed-out screens. The handler
	// resolves a bearer session itself when one is sent, never trusts
	// identity headers, and rate-limits anonymous callers per IP, per install
	// and globally (client_errors.go).
	if method == http.MethodPost && requestPath == prefix+"/client/errors" {
		return true
	}
	// The website contact form is for signed-out visitors. The handler never
	// reads identity headers, never creates an account and rate-limits per IP,
	// per address and globally (support_tickets.go).
	if method == http.MethodPost && requestPath == prefix+"/support/contact" {
		return true
	}
	// Provider webhooks authenticate with their own signature, and the
	// hosted checkout / return pages are opened in a browser that carries no
	// bearer token. Each of these handlers verifies its own inputs.
	if method == http.MethodPost && strings.HasPrefix(requestPath, prefix+"/billing/webhooks/") {
		return true
	}
	if strings.HasPrefix(requestPath, prefix+"/billing/sandbox/checkout/") && (method == http.MethodGet || method == http.MethodPost) {
		return true
	}
	if method == http.MethodGet && requestPath == prefix+"/billing/checkout/return" {
		return true
	}
	return method == http.MethodGet && strings.HasPrefix(requestPath, prefix+"/media/")
}

func pathOwnedByPrincipal(prefix, requestPath, method, userID string) bool {
	trimmed := strings.TrimPrefix(requestPath, prefix+"/")
	parts := strings.Split(trimmed, "/")
	if len(parts) < 2 {
		return true
	}
	selfRoots := map[string]bool{
		"settings": true, "emergency-contacts": true, "blocked-users": true,
		// "analytics" is deliberately absent: /v1/analytics/{userID} is an
		// operator support view (it counts reports against the member), so the
		// handler requires an operator role instead of ownership.
		"verification": true, "wallet": true, "friends": true,
		"notifications": true, "progression": true, "plans": true,
		// Deactivation, deletion and export act on the account itself. This
		// function allows unknown roots by default, so omitting "account" here
		// would leave those endpoints callable for any user id.
		"account": true,
	}
	if selfRoots[parts[0]] {
		return parts[1] == userID
	}
	if parts[0] == "discovery" {
		return parts[1] == userID
	}
	if parts[0] == "matches" && method == http.MethodGet && len(parts) == 2 {
		return parts[1] == userID
	}
	if parts[0] == "profile" && method == http.MethodGet && len(parts) == 3 && (parts[2] == "stories" || parts[2] == "showcase") {
		return true
	}
	// WEB-12: POST /profile/views is a collection route, not /profile/{id}.
	// Who may record a view is decided by enforceBodyIdentity: the body's
	// viewer_user_id must be the caller.
	if parts[0] == "profile" && method == http.MethodPost && len(parts) == 2 && parts[1] == "views" {
		return true
	}
	if parts[0] == "profile" && (method != http.MethodGet || len(parts) > 2 || strings.Contains(requestPath, "/draft")) {
		return parts[1] == userID
	}
	if parts[0] == "users" && len(parts) > 2 && parts[2] == "agreements" {
		return parts[1] == userID
	}
	if parts[0] == "auth" && len(parts) > 3 && parts[1] == "signup" && parts[2] == "workflow" {
		return parts[3] == userID
	}
	if parts[0] == "engagement" && len(parts) > 2 && parts[1] == "daily-prompt" {
		return parts[2] == userID
	}
	if parts[0] == "calls" && len(parts) > 2 && parts[1] == "history" {
		return parts[2] == userID
	}
	if parts[0] == "safety" && len(parts) > 2 && parts[1] == "sos" {
		return parts[2] == userID
	}
	if parts[0] == "billing" && len(parts) > 2 && (parts[1] == "subscription" || parts[1] == "payments" || parts[1] == "entitlements") {
		return parts[2] == userID
	}
	if parts[0] == "billing" && len(parts) > 3 && parts[1] == "sandbox" && parts[2] == "subscriptions" {
		return parts[3] == userID
	}
	return true
}

// replayedBody serves the bytes the security checks already read, then the
// rest of the original stream, so a handler always sees the complete body.
type replayedBody struct {
	io.Reader
	closer io.Closer
}

func (b replayedBody) Close() error { return b.closer.Close() }

// readIdentityBody reads up to securityRequestBodyLimit+1 bytes of the body
// and puts them back in front of the unread remainder. It reports whether the
// body is a JSON object, judged by the bytes and never by Content-Type:
// readJSON and the typed decoders parse JSON whatever the header says, so a
// check gated on "application/json" let a text/plain, multipart-labelled or
// header-less JSON body name any actor (API-06). Multipart uploads start with
// a boundary, never '{', so they are not buffered beyond the first MiB.
func readIdentityBody(r *http.Request) (body []byte, jsonObject, tooLarge bool, err error) {
	if r.Body == nil || r.Body == http.NoBody {
		return nil, false, false, nil
	}
	original := r.Body
	body, err = io.ReadAll(io.LimitReader(original, securityRequestBodyLimit+1))
	r.Body = replayedBody{Reader: io.MultiReader(bytes.NewReader(body), original), closer: original}
	if err != nil {
		return nil, false, false, err
	}
	tooLarge = len(body) > securityRequestBodyLimit
	trimmed := bytes.TrimLeft(body, " \t\r\n")
	// A body that is still only JSON whitespace at the limit may hide an object
	// beyond it, so treat it as JSON (and therefore as too large).
	jsonObject = (len(trimmed) > 0 && trimmed[0] == '{') || (tooLarge && len(trimmed) == 0)
	return body, jsonObject, tooLarge, nil
}

// decodeIdentityPayload decodes the first JSON value exactly as readJSON does.
// json.Unmarshal rejects trailing data, which let `{"user_id":"victim"} x`
// skip the identity check while the handler still read the object.
func decodeIdentityPayload(body []byte) (map[string]any, bool) {
	var payload map[string]any
	if err := json.NewDecoder(bytes.NewReader(body)).Decode(&payload); err != nil || payload == nil {
		return nil, false
	}
	return payload, true
}

func enforceBodyIdentity(r *http.Request, userID string) error {
	body, jsonObject, tooLarge, err := readIdentityBody(r)
	if err != nil {
		return errors.New("unable to validate request identity")
	}
	if !jsonObject {
		return nil
	}
	if tooLarge {
		return errors.New("request body is too large")
	}
	payload, ok := decodeIdentityPayload(body)
	if !ok {
		return nil
	}
	// Every key here is an actor a caller might try to impersonate. The list
	// is the control, so a new actor field is unprotected until it is added:
	// `requested_by` was missing, and a wallet top-up read its approver from
	// exactly that field, so a member could name any approver they liked.
	for _, key := range []string{
		"user_id", "userId", "sender_id", "sender_user_id",
		"initiator_id", "initiator_user_id", "reporter_user_id",
		"submitted_by", "reviewer_user_id", "requested_by", "requestedBy",
		"actor_id", "actorId", "granted_by", "operator_id",
		// Quest actors. Without these a foreign id reached the domain and
		// failed there instead, surfacing as 502 — a server fault for what is
		// really a rejected impersonation.
		"creator_user_id", "submitter_user_id",
		// Community group actors (owner and inviter are the principal).
		"owner_user_id", "inviter_user_id",
		// Conversation Room moderation named its actor here and nothing
		// checked it, so any member could moderate as anyone.
		"moderator_user_id", "moderator_id",
		// Match chat deletion trusted its requester, so either participant
		// could delete the other's messages (API-07). The profile-view,
		// call-end and SOS-resolve actors are the caller as well.
		"requester_user_id", "viewer_user_id", "ended_by_user_id", "resolved_by",
	} {
		// Typed handlers decode keys case-insensitively (encoding/json), so
		// "User_ID" must be policed like "user_id".
		for field, raw := range payload {
			if !strings.EqualFold(field, key) {
				continue
			}
			if value := strings.TrimSpace(toString(raw)); value != "" && value != userID {
				return errors.New("request actor does not match the authenticated user")
			}
		}
	}
	return nil
}

func requestMatchID(r *http.Request, prefix, userID string) string {
	parts := strings.Split(strings.TrimPrefix(r.URL.Path, prefix+"/"), "/")
	if len(parts) > 1 {
		switch parts[0] {
		case "chat":
			if parts[1] == "gifts" {
				return ""
			}
			return strings.TrimSpace(parts[1])
		case "matches":
			if parts[1] != userID && !(r.Method == http.MethodGet && len(parts) == 2) {
				return strings.TrimSpace(parts[1])
			}
		}
	}
	body, jsonObject, tooLarge, err := readIdentityBody(r)
	if err != nil || !jsonObject || tooLarge {
		return ""
	}
	payload, ok := decodeIdentityPayload(body)
	if !ok {
		return ""
	}
	for field, raw := range payload {
		if strings.EqualFold(field, "match_id") {
			if matchID := strings.TrimSpace(toString(raw)); matchID != "" {
				return matchID
			}
		}
	}
	return ""
}

// principalResolver returns the function used to turn an Authorization header
// into a verified principal, or nil when no principal store is available.
//
// Production binaries can only ever get the session-backed resolver: the test
// hook is a package var that no non-test file assigns.
func (s *Server) principalResolver() func(*http.Request) (securityPrincipal, error) {
	if testPrincipalResolver != nil {
		return testPrincipalResolver
	}
	if s.store != nil && s.store.profileRepo != nil && s.store.profileRepo.pg != nil {
		return func(r *http.Request) (securityPrincipal, error) {
			authorization := r.Header.Get("Authorization")
			if authorization == "" {
				authorization = browserSocketAuthorization(r, s.cfg.APIPrefix)
			}
			return s.store.profileRepo.principalForAccessToken(r.Context(), authorization)
		}
	}
	return nil
}

func principalFromRequest(r *http.Request) (securityPrincipal, bool) {
	principal, ok := r.Context().Value(securityPrincipalContextKey{}).(securityPrincipal)
	return principal, ok
}

func (r *profileRepository) principalForAccessToken(ctx context.Context, authorization string) (securityPrincipal, error) {
	token, err := bearerToken(authorization)
	if err != nil {
		return securityPrincipal{}, err
	}
	hash := sha256.Sum256([]byte(token))
	var principal securityPrincipal
	var disabled, active, banned, suspended, touchDue bool
	var roles string
	// One round trip per authenticated request: the session, the account
	// state and the roles (chr(31) cannot appear in a role slug) together.
	err = r.pg.QueryRowContext(ctx, `
		SELECT s.id::text, s.user_id::text, c.is_disabled, COALESCE(u.is_active, TRUE), COALESCE(u.account_kind,'dating'), COALESCE(u.terms_accepted,FALSE),
		       COALESCE(u.is_banned,FALSE),
		       COALESCE(u.suspended_at IS NOT NULL AND (u.suspended_until IS NULL OR u.suspended_until>NOW()),FALSE),
		       COALESCE((SELECT string_agg(ar.role, chr(31)) FROM user_management.auth_account_roles ar WHERE ar.user_id=s.user_id),''),
		       `+sessionTouchDueSQL+`
		FROM user_management.auth_sessions s
		JOIN user_management.auth_credentials c ON c.user_id=s.user_id
		LEFT JOIN user_management.users u ON u.id=s.user_id
		WHERE s.access_token_hash=$1 AND s.revoked_at IS NULL AND s.access_expires_at>NOW()`, hash[:],
	).Scan(&principal.SessionID, &principal.UserID, &disabled, &active, &principal.AccountKind, &principal.TermsAccepted, &banned, &suspended, &roles, &touchDue)
	if err != nil && !errors.Is(err, sql.ErrNoRows) {
		return securityPrincipal{}, authStoreUnavailable(err)
	}
	if err != nil || disabled || !active || banned || suspended {
		return securityPrincipal{}, errors.New("invalid session")
	}
	principal.Roles = map[string]bool{"user": true}
	for _, role := range strings.Split(roles, "\x1f") {
		if role != "" {
			principal.Roles[role] = true
		}
	}
	if touchDue {
		// The guard is repeated so concurrent requests on one session do not
		// all rewrite the row (each rewrite is a WAL record, a dead tuple and
		// a captured domain event).
		_, _ = r.pg.ExecContext(ctx, `UPDATE user_management.auth_sessions s SET last_used_at=NOW() WHERE s.id=$1 AND `+sessionTouchDueSQL, principal.SessionID)
	}
	return principal, nil
}

// sessionTouchDueSQL decides when an authenticated request refreshes
// auth_sessions.last_used_at: at most once a minute per session, plus the
// first request of each UTC day so the DAU triggers (migrations 087/123,
// which already throttle to five minutes or a new UTC day) never miss a day.
// Writing it on every request made every read a write.
const sessionTouchDueSQL = `(s.last_used_at IS NULL OR s.last_used_at < NOW() - INTERVAL '60 seconds' OR (s.last_used_at AT TIME ZONE 'UTC')::date < (NOW() AT TIME ZONE 'UTC')::date)`

// errAuthStoreUnavailable marks a session lookup that failed for an
// infrastructure reason rather than because the credential is invalid.
var errAuthStoreUnavailable = errors.New("sign-in is temporarily unavailable, please try again")

var errInvalidRefreshToken = errors.New("invalid or expired refresh token")

func authStoreUnavailable(cause error) error {
	return fmt.Errorf("%w: %v", errAuthStoreUnavailable, cause)
}

func (r *profileRepository) authorizeRealtimeSession(ctx context.Context, principal securityPrincipal) error {
	if r == nil || r.pg == nil || strings.TrimSpace(principal.SessionID) == "" || strings.TrimSpace(principal.UserID) == "" {
		return errors.New("invalid realtime session")
	}
	var allowed bool
	err := r.pg.QueryRowContext(ctx, `
		SELECT EXISTS(
		  SELECT 1
		  FROM user_management.auth_sessions s
		  JOIN user_management.auth_credentials c ON c.user_id=s.user_id
		  JOIN user_management.users u ON u.id=s.user_id
		  WHERE s.id=$1 AND s.user_id=$2
		    AND s.revoked_at IS NULL AND s.access_expires_at>NOW()
		    AND NOT c.is_disabled AND u.is_active AND NOT u.is_banned
		    AND NOT (u.suspended_at IS NOT NULL AND (u.suspended_until IS NULL OR u.suspended_until>NOW()))
		    AND u.deactivated_at IS NULL AND u.deletion_requested_at IS NULL AND u.erased_at IS NULL
		)`, principal.SessionID, principal.UserID).Scan(&allowed)
	if err != nil {
		return err
	}
	if !allowed {
		return errors.New("realtime session is no longer active")
	}
	return nil
}

func (r *profileRepository) userCanAccessMatch(ctx context.Context, userID, matchID string) (bool, error) {
	// A malformed id names no match. Sent to Postgres it fails the uuid cast,
	// which surfaced as a 503 "temporarily unavailable" (API-08) and told
	// clients to retry a request that can never succeed.
	if _, err := uuid.Parse(matchID); err != nil {
		return false, nil
	}
	var allowed bool
	err := r.pg.QueryRowContext(ctx, `
		SELECT EXISTS(
		  SELECT 1 FROM matching.matches
		  WHERE id=$1 AND (
		    (user_id_1=$2 AND user_1_status='active' AND user_2_status='active') OR
		    (user_id_2=$2 AND user_1_status='active' AND user_2_status='active')
		  )
		)`, matchID, userID).Scan(&allowed)
	return allowed, err
}

func bearerToken(authorization string) (string, error) {
	parts := strings.Fields(strings.TrimSpace(authorization))
	if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") || parts[1] == "" {
		return "", errors.New("bearer token is required")
	}
	return parts[1], nil
}

func secureRandomToken() (string, error) {
	raw := make([]byte, 32)
	if _, err := rand.Read(raw); err != nil {
		return "", err
	}
	return base64.RawURLEncoding.EncodeToString(raw), nil
}

func strongPassword(password string) bool {
	if len(password) < 8 || len(password) > 72 {
		return false
	}
	hasLetter, hasDigit := false, false
	for _, char := range password {
		hasLetter = hasLetter || (char >= 'a' && char <= 'z') || (char >= 'A' && char <= 'Z')
		hasDigit = hasDigit || (char >= '0' && char <= '9')
	}
	return hasLetter && hasDigit
}

func (r *profileRepository) refreshSession(ctx context.Context, refreshToken string) (map[string]any, error) {
	hash := sha256.Sum256([]byte(strings.TrimSpace(refreshToken)))
	tx, err := r.pg.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		return nil, err
	}
	defer func() { _ = tx.Rollback() }()
	var sessionID, userID, state, activity, accountKind string
	err = tx.QueryRowContext(ctx, `
		SELECT s.id::text,s.user_id::text,w.state,w.current_activity,u.account_kind
		FROM user_management.auth_sessions s
		JOIN user_management.auth_credentials c ON c.user_id=s.user_id AND c.is_disabled=FALSE
		JOIN user_management.users u ON u.id=s.user_id AND u.is_active=TRUE AND u.is_banned=FALSE
		  AND (u.suspended_at IS NULL OR (u.suspended_until IS NOT NULL AND u.suspended_until<=NOW()))
		JOIN user_management.signup_workflows w ON w.user_id=s.user_id
		WHERE s.refresh_token_hash=$1 AND s.revoked_at IS NULL AND s.refresh_expires_at>NOW()
		FOR UPDATE OF s`, hash[:]).Scan(&sessionID, &userID, &state, &activity, &accountKind)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, errInvalidRefreshToken
	}
	if err != nil {
		return nil, err
	}
	if _, err = tx.ExecContext(ctx, `UPDATE user_management.auth_sessions SET revoked_at=NOW(),revoked_reason='refresh_rotation' WHERE id=$1`, sessionID); err != nil {
		return nil, err
	}
	access, err := secureRandomToken()
	if err != nil {
		return nil, err
	}
	refresh, err := secureRandomToken()
	if err != nil {
		return nil, err
	}
	accessHash, refreshHash := sha256.Sum256([]byte(access)), sha256.Sum256([]byte(refresh))
	if _, err = tx.ExecContext(ctx, `INSERT INTO user_management.auth_sessions
		(user_id,access_token_hash,refresh_token_hash,access_expires_at,refresh_expires_at)
		VALUES($1,$2,$3,NOW()+INTERVAL '30 minutes',NOW()+INTERVAL '30 days')`, userID, accessHash[:], refreshHash[:]); err != nil {
		return nil, err
	}
	if err = tx.Commit(); err != nil {
		return nil, err
	}
	return map[string]any{"success": true, "account_kind": accountKind, "user_id": userID, "access_token": access, "refresh_token": refresh, "expires_in": 1800, "workflow_state": state, "current_activity": activity, "signup_required": state != "completed"}, nil
}

func (r *profileRepository) revokeSessions(ctx context.Context, principal securityPrincipal, all bool, reason string) error {
	if all {
		_, err := r.pg.ExecContext(ctx, `UPDATE user_management.auth_sessions SET revoked_at=COALESCE(revoked_at,NOW()),revoked_reason=$2 WHERE user_id=$1 AND revoked_at IS NULL`, principal.UserID, reason)
		return err
	}
	_, err := r.pg.ExecContext(ctx, `UPDATE user_management.auth_sessions SET revoked_at=COALESCE(revoked_at,NOW()),revoked_reason=$2 WHERE id=$1`, principal.SessionID, reason)
	return err
}

func (r *profileRepository) changePassword(ctx context.Context, principal securityPrincipal, currentPassword, newPassword string) error {
	if !strongPassword(newPassword) {
		return errors.New("new password must be 8-72 UTF-8 bytes with letters and numbers")
	}
	tx, err := r.pg.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		return err
	}
	defer func() { _ = tx.Rollback() }()
	var currentHash string
	if err = tx.QueryRowContext(ctx, `SELECT password_hash FROM user_management.auth_credentials WHERE user_id=$1 FOR UPDATE`, principal.UserID).Scan(&currentHash); err != nil {
		return err
	}
	if bcrypt.CompareHashAndPassword([]byte(currentHash), []byte(currentPassword)) != nil {
		return errors.New("current password is incorrect")
	}
	newHash, err := bcrypt.GenerateFromPassword([]byte(newPassword), bcrypt.DefaultCost)
	if err != nil {
		return err
	}
	if _, err = tx.ExecContext(ctx, `UPDATE user_management.auth_credentials SET password_hash=$2,password_changed_at=NOW(),updated_at=NOW() WHERE user_id=$1`, principal.UserID, string(newHash)); err != nil {
		return err
	}
	if _, err = tx.ExecContext(ctx, `UPDATE user_management.auth_sessions SET revoked_at=COALESCE(revoked_at,NOW()),revoked_reason='password_change' WHERE user_id=$1`, principal.UserID); err != nil {
		return err
	}
	return tx.Commit()
}

func (r *profileRepository) rotateRecoveryCode(ctx context.Context, principal securityPrincipal) (string, error) {
	code, err := secureRandomToken()
	if err != nil {
		return "", err
	}
	hash := sha256.Sum256([]byte(code))
	tx, err := r.pg.BeginTx(ctx, nil)
	if err != nil {
		return "", err
	}
	defer func() { _ = tx.Rollback() }()
	if _, err = tx.ExecContext(ctx, `UPDATE user_management.auth_recovery_codes SET used_at=COALESCE(used_at,NOW()) WHERE user_id=$1 AND used_at IS NULL`, principal.UserID); err != nil {
		return "", err
	}
	if _, err = tx.ExecContext(ctx, `INSERT INTO user_management.auth_recovery_codes(user_id,code_hash,expires_at) VALUES($1,$2,NOW()+INTERVAL '365 days')`, principal.UserID, hash[:]); err != nil {
		return "", err
	}
	return code, tx.Commit()
}

func (r *profileRepository) recoverPassword(ctx context.Context, username, code, newPassword string) error {
	if !strongPassword(newPassword) {
		return errors.New("new password must be 8-72 UTF-8 bytes with letters and numbers")
	}
	hash := sha256.Sum256([]byte(strings.TrimSpace(code)))
	newHash, err := bcrypt.GenerateFromPassword([]byte(newPassword), bcrypt.DefaultCost)
	if err != nil {
		return err
	}
	tx, err := r.pg.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		return err
	}
	defer func() { _ = tx.Rollback() }()
	var recoveryID, userID string
	err = tx.QueryRowContext(ctx, `SELECT rc.id::text,rc.user_id::text FROM user_management.auth_recovery_codes rc
		JOIN user_management.auth_credentials c ON c.user_id=rc.user_id
		WHERE LOWER(c.username)=LOWER($1) AND rc.code_hash=$2 AND rc.used_at IS NULL AND rc.expires_at>NOW() FOR UPDATE OF rc`, strings.TrimSpace(username), hash[:]).Scan(&recoveryID, &userID)
	if err != nil {
		return errors.New("invalid or expired recovery code")
	}
	if _, err = tx.ExecContext(ctx, `UPDATE user_management.auth_recovery_codes SET used_at=NOW() WHERE id=$1`, recoveryID); err != nil {
		return err
	}
	if _, err = tx.ExecContext(ctx, `UPDATE user_management.auth_credentials SET password_hash=$2,password_changed_at=NOW(),failed_login_count=0,locked_until=NULL,updated_at=NOW() WHERE user_id=$1`, userID, string(newHash)); err != nil {
		return err
	}
	if _, err = tx.ExecContext(ctx, `UPDATE user_management.auth_sessions SET revoked_at=COALESCE(revoked_at,NOW()),revoked_reason='password_recovery' WHERE user_id=$1`, userID); err != nil {
		return err
	}
	return tx.Commit()
}

func (s *Server) refreshAuthSession(w http.ResponseWriter, r *http.Request) {
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	result, err := s.store.profileRepo.refreshSession(r.Context(), toString(payload["refresh_token"]))
	if errors.Is(err, errInvalidRefreshToken) {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	if err != nil {
		// Only a rejected token ends the session. Anything else (a database
		// fault, or losing a race with a concurrent refresh of the same
		// token) is retryable; the retry then sees the token as rotated.
		logUnexpectedError(w, err)
		w.Header().Set("Retry-After", "2")
		writeError(w, http.StatusServiceUnavailable, errAuthStoreUnavailable)
		return
	}
	writeJSON(w, http.StatusOK, result)
}

func (s *Server) logout(w http.ResponseWriter, r *http.Request) {
	principal, ok := principalFromRequest(r)
	if !ok {
		writeError(w, http.StatusUnauthorized, errors.New("valid bearer session is required"))
		return
	}
	if err := s.store.profileRepo.revokeSessions(r.Context(), principal, false, "logout"); err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"success": true})
}

func (s *Server) revokeAuthSessions(w http.ResponseWriter, r *http.Request) {
	principal, ok := principalFromRequest(r)
	if !ok {
		writeError(w, http.StatusUnauthorized, errors.New("valid bearer session is required"))
		return
	}
	payload, valid := readJSON(w, r)
	if !valid {
		return
	}
	all, _ := payload["all_sessions"].(bool)
	if err := s.store.profileRepo.revokeSessions(r.Context(), principal, all, "user_revoke"); err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"success": true, "all_sessions": all})
}

func (s *Server) changeAuthPassword(w http.ResponseWriter, r *http.Request) {
	principal, ok := principalFromRequest(r)
	if !ok {
		writeError(w, http.StatusUnauthorized, errors.New("valid bearer session is required"))
		return
	}
	payload, valid := readJSON(w, r)
	if !valid {
		return
	}
	if err := s.store.profileRepo.changePassword(r.Context(), principal, toString(payload["current_password"]), toString(payload["new_password"])); err != nil {
		writeError(w, http.StatusBadRequest, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"success": true, "reauthentication_required": true})
}

func (s *Server) rotateAuthRecoveryCode(w http.ResponseWriter, r *http.Request) {
	principal, ok := principalFromRequest(r)
	if !ok {
		writeError(w, http.StatusUnauthorized, errors.New("valid bearer session is required"))
		return
	}
	code, err := s.store.profileRepo.rotateRecoveryCode(r.Context(), principal)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"success": true, "recovery_code": code, "display_once": true})
}

func (s *Server) recoverAuthPassword(w http.ResponseWriter, r *http.Request) {
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	if err := s.store.profileRepo.recoverPassword(r.Context(), toString(payload["username"]), toString(payload["recovery_code"]), toString(payload["new_password"])); err != nil {
		writeError(w, http.StatusBadRequest, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"success": true, "reauthentication_required": true})
}
