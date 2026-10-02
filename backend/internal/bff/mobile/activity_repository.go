package mobile

import (
	"context"
	"errors"
	"fmt"
	"net"
	"net/http"
	"net/netip"
	"net/url"
	"regexp"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"github.com/go-chi/chi/v5"
	"go.uber.org/zap"

	"github.com/verified-dating/backend/internal/platform/config"
	"github.com/verified-dating/backend/internal/platform/observability"
)

type activityRepository struct {
	cfg config.Config
	db  repositoryDB
}

var uuidPattern = regexp.MustCompile("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$")

func newActivityRepository(cfg config.Config, supplied ...repositoryDB) *activityRepository {
	db := repositoryDBFor(cfg, supplied)
	if db == nil {
		return nil
	}
	return &activityRepository{cfg: cfg, db: db}
}

func isActivityRepoPersistenceUnavailable(err error) bool {
	if err == nil {
		return false
	}
	msg := strings.ToLower(err.Error())
	return strings.Contains(msg, "pgrst106") ||
		strings.Contains(msg, "pgrst205") ||
		strings.Contains(msg, "invalid schema") ||
		strings.Contains(msg, "could not find the table")
}

func (r *activityRepository) startActivitySession(
	ctx context.Context,
	matchID,
	initiatorUserID,
	participantUserID,
	activityType string,
	metadata map[string]any,
) (activitySession, error) {
	trimmedMatchID := strings.TrimSpace(matchID)
	trimmedInitiator := strings.TrimSpace(initiatorUserID)
	trimmedParticipant := strings.TrimSpace(participantUserID)
	trimmedType, typeErr := normalizeActivitySessionType(activityType)
	if trimmedMatchID == "" || trimmedInitiator == "" || trimmedParticipant == "" {
		return activitySession{}, errors.New("match_id, initiator_user_id, and participant_user_id are required")
	}
	if trimmedInitiator == trimmedParticipant {
		return activitySession{}, errors.New("initiator and participant must be different users")
	}
	if typeErr != nil {
		return activitySession{}, typeErr
	}

	now := time.Now().UTC()
	expiresAt := now.Add(activitySessionDuration)

	if trimmedType == "this_or_that" {
		windowStart := now.Add(-activitySessionReplayWindow).Format(time.RFC3339)
		params := url.Values{}
		params.Set("match_id", "eq."+trimmedMatchID)
		params.Set("activity_type", "eq."+trimmedType)
		params.Set("started_at", "gte."+windowStart)
		params.Set("select", "id")
		rows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "activity_sessions", params)
		if err != nil {
			return activitySession{}, err
		}
		if len(rows) >= activitySessionMaxThisOrThatPerWeek {
			return activitySession{}, errors.New("weekly replay limit reached for this_or_that")
		}
	}

	payload := map[string]any{
		"match_id":             trimmedMatchID,
		"activity_type":        trimmedType,
		"status":               activitySessionStatusActive,
		"initiator_user_id":    trimmedInitiator,
		"participant_user_ids": []string{trimmedInitiator, trimmedParticipant},
		"metadata":             mapOrEmpty(metadata),
		"started_at":           now.Format(time.RFC3339),
		"expires_at":           expiresAt.Format(time.RFC3339),
		"updated_at":           now.Format(time.RFC3339),
	}
	rows, err := r.db.Insert(ctx, r.cfg.MatchingSchema, "activity_sessions", []map[string]any{payload})
	if err != nil {
		return activitySession{}, err
	}
	if len(rows) == 0 {
		return activitySession{}, errors.New("activity session persistence returned empty result")
	}
	return mapActivitySessionRow(rows[0]), nil
}

func (r *activityRepository) submitActivitySessionResponses(
	ctx context.Context,
	sessionID,
	userID string,
	responses []string,
) (activitySession, error) {
	trimmedSessionID := strings.TrimSpace(sessionID)
	trimmedUserID := strings.TrimSpace(userID)
	if trimmedSessionID == "" || trimmedUserID == "" {
		return activitySession{}, errors.New("session_id and user_id are required")
	}

	trimmedResponses := make([]string, 0, len(responses))
	for _, item := range responses {
		value := strings.TrimSpace(item)
		if value == "" {
			continue
		}
		trimmedResponses = append(trimmedResponses, value)
	}
	if len(trimmedResponses) == 0 {
		return activitySession{}, errors.New("at least one response is required")
	}

	session, err := r.getActivitySession(ctx, trimmedSessionID)
	if err != nil {
		if strings.Contains(strings.ToLower(err.Error()), "not found") {
			return activitySession{}, errors.New("activity session not found")
		}
		return activitySession{}, err
	}

	if !containsString(session.ParticipantIDs, trimmedUserID) {
		return activitySession{}, errors.New("user is not a participant in this activity session")
	}

	now := time.Now().UTC()
	session = finalizeActivityTimeoutIfNeeded(session, now)
	if session.Status == activitySessionStatusTimedOut || session.Status == activitySessionStatusPartialTimeout {
		_, _ = r.updateSessionState(ctx, session)
		return session, errors.New("activity session expired")
	}
	if session.Status == activitySessionStatusCompleted {
		return session, errors.New("activity session already completed")
	}

	if _, err := r.deleteExistingResponses(ctx, trimmedSessionID, trimmedUserID); err != nil {
		return activitySession{}, err
	}
	insertRows := make([]map[string]any, 0, len(trimmedResponses))
	for idx, response := range trimmedResponses {
		insertRows = append(insertRows, map[string]any{
			"session_id":    trimmedSessionID,
			"user_id":       trimmedUserID,
			"question_id":   fmt.Sprintf("q-%d", idx+1),
			"response_text": response,
			"submitted_at":  now.Format(time.RFC3339),
		})
	}
	if _, err := r.db.Insert(ctx, r.cfg.MatchingSchema, "activity_session_responses", insertRows); err != nil {
		return activitySession{}, err
	}

	session.ResponsesByUser[trimmedUserID] = append([]string{}, trimmedResponses...)
	session.LastResponseAt = now.Format(time.RFC3339)
	if len(session.ResponsesByUser) >= len(session.ParticipantIDs) {
		session.Status = activitySessionStatusCompleted
		session.CompletedAt = now.Format(time.RFC3339)
		session.Summary = buildActivitySummary(session, now)
	}

	updated, err := r.updateSessionState(ctx, session)
	if err != nil {
		return activitySession{}, err
	}
	return updated, nil
}

func (r *activityRepository) getActivitySessionSummary(
	ctx context.Context,
	sessionID string,
) (activitySessionSummary, activitySession, error) {
	trimmedSessionID := strings.TrimSpace(sessionID)
	if trimmedSessionID == "" {
		return activitySessionSummary{}, activitySession{}, errors.New("session_id is required")
	}

	session, err := r.getActivitySession(ctx, trimmedSessionID)
	if err != nil {
		return activitySessionSummary{}, activitySession{}, err
	}

	now := time.Now().UTC()
	session = finalizeActivityTimeoutIfNeeded(session, now)
	if strings.TrimSpace(session.Summary.SessionID) == "" {
		session.Summary = buildActivitySummary(session, now)
	}
	updated, err := r.updateSessionState(ctx, session)
	if err != nil {
		return activitySessionSummary{}, activitySession{}, err
	}
	return updated.Summary, updated, nil
}

func (r *activityRepository) getActivitySession(ctx context.Context, sessionID string) (activitySession, error) {
	params := url.Values{}
	params.Set("id", "eq."+strings.TrimSpace(sessionID))
	params.Set("limit", "1")
	params.Set("select", "*")
	rows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "activity_sessions", params)
	if err != nil {
		return activitySession{}, err
	}
	if len(rows) == 0 {
		return activitySession{}, errors.New("activity session not found")
	}
	session := mapActivitySessionRow(rows[0])
	responsesByUser, err := r.loadSessionResponses(ctx, session.ID)
	if err != nil {
		return activitySession{}, err
	}
	session.ResponsesByUser = responsesByUser
	if strings.TrimSpace(session.Summary.SessionID) == "" {
		session.Summary = buildActivitySummary(session, time.Now().UTC())
	}
	return session, nil
}

func (r *activityRepository) loadSessionResponses(ctx context.Context, sessionID string) (map[string][]string, error) {
	params := url.Values{}
	params.Set("session_id", "eq."+strings.TrimSpace(sessionID))
	params.Set("order", "submitted_at.asc")
	params.Set("select", "user_id,response_text")
	rows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "activity_session_responses", params)
	if err != nil {
		return nil, err
	}
	byUser := map[string][]string{}
	for _, row := range rows {
		userID := strings.TrimSpace(toString(row["user_id"]))
		text := strings.TrimSpace(toString(row["response_text"]))
		if userID == "" || text == "" {
			continue
		}
		byUser[userID] = append(byUser[userID], text)
	}
	return byUser, nil
}

func (r *activityRepository) deleteExistingResponses(ctx context.Context, sessionID, userID string) ([]map[string]any, error) {
	filters := url.Values{}
	filters.Set("session_id", "eq."+strings.TrimSpace(sessionID))
	filters.Set("user_id", "eq."+strings.TrimSpace(userID))
	return r.db.Delete(ctx, r.cfg.MatchingSchema, "activity_session_responses", filters)
}

func (r *activityRepository) updateSessionState(ctx context.Context, session activitySession) (activitySession, error) {
	filters := url.Values{}
	filters.Set("id", "eq."+strings.TrimSpace(session.ID))

	payload := map[string]any{
		"status":            session.Status,
		"completed_at":      nullableTimestamp(session.CompletedAt),
		"updated_at":        time.Now().UTC().Format(time.RFC3339),
		"metadata":          mapOrEmpty(session.Metadata),
		"expires_at":        nullableTimestamp(session.ExpiresAt),
		"started_at":        nullableTimestamp(session.StartedAt),
		"initiator_user_id": session.InitiatorUserID,
	}
	if strings.TrimSpace(session.LastResponseAt) != "" {
		payload["updated_at"] = session.LastResponseAt
	}
	rows, err := r.db.Update(ctx, r.cfg.MatchingSchema, "activity_sessions", payload, filters)
	if err != nil {
		return activitySession{}, err
	}
	if len(rows) == 0 {
		return session, nil
	}
	updated := mapActivitySessionRow(rows[0])
	updated.ResponsesByUser = session.ResponsesByUser
	updated.Summary = buildActivitySummary(updated, time.Now().UTC())
	if updated.Status == activitySessionStatusCompleted {
		updated.Summary = buildActivitySummary(updated, time.Now().UTC())
	}
	return updated, nil
}

func (r *activityRepository) recordActivityEvent(ctx context.Context, event activityEvent) (activityEvent, error) {
	action := strings.TrimSpace(event.Action)
	if action == "" {
		return activityEvent{}, errors.New("activity action is required")
	}
	status := strings.TrimSpace(event.Status)
	if status == "" {
		status = "success"
	}
	createdAt := strings.TrimSpace(event.CreatedAt)
	if createdAt == "" {
		createdAt = time.Now().UTC().Format(time.RFC3339)
	}
	payload := map[string]any{
		"status":   status,
		"resource": strings.TrimSpace(event.Resource),
		"actor":    strings.TrimSpace(event.Actor),
		"details":  mapOrEmpty(event.Details),
	}
	matchID := ""
	if event.Details != nil {
		matchID = strings.TrimSpace(toString(event.Details["match_id"]))
	}

	row := map[string]any{
		"event_name":     action,
		"event_domain":   activityEventDomain(event.Domain),
		"event_version":  1,
		"user_id":        nullableEventUUID(event.UserID),
		"actor_user_id":  nullableEventUUID(event.Actor),
		"match_id":       nullableEventUUID(matchID),
		"source_service": "mobile_bff",
		"payload":        payload,
		"created_at":     createdAt,
	}
	if columns := event.Request; columns != nil {
		// Request context from the activity middleware (requestActivityEvent).
		// ip_address is set only for member actions.
		row["ip_address"] = nullableTrimmedString(columns.IPAddress)
		row["source_device_id"] = nullableTrimmedString(columns.DeviceID)
		row["source_platform"] = nullableTrimmedString(columns.Platform)
		row["request_id"] = nullableTrimmedString(columns.RequestID)
		row["correlation_id"] = nullableTrimmedString(columns.CorrelationID)
		row["idempotency_key"] = nullableTrimmedString(columns.IdempotencyKey)
		row["entity_table"] = nullableTrimmedString(columns.EntityTable)
		row["entity_id"] = nullableTrimmedString(columns.EntityID)
	}

	rows, err := r.db.Insert(ctx, r.cfg.MatchingSchema, "activity_events", []map[string]any{row})
	if err != nil {
		return activityEvent{}, err
	}
	if len(rows) == 0 {
		stored := event
		stored.Status = status
		stored.CreatedAt = createdAt
		stored.Details = mapOrEmpty(event.Details)
		return stored, nil
	}
	return mapActivityEventRow(rows[0]), nil
}

func (r *activityRepository) listActivityEvents(ctx context.Context, limit int) ([]activityEvent, error) {
	if limit <= 0 || limit > 1000 {
		limit = 100
	}
	params := url.Values{}
	params.Set("select", "id,event_name,event_domain,user_id,actor_user_id,payload,created_at")
	params.Set("order", "created_at.desc")
	params.Set("limit", fmt.Sprintf("%d", limit))
	rows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "activity_events", params)
	if err != nil {
		return nil, err
	}
	out := make([]activityEvent, 0, len(rows))
	for _, row := range rows {
		out = append(out, mapActivityEventRow(row))
	}
	return out, nil
}

func mapActivityEventRow(row map[string]any) activityEvent {
	payload, _ := row["payload"].(map[string]any)
	details, _ := payload["details"].(map[string]any)
	status := strings.TrimSpace(toString(payload["status"]))
	if status == "" {
		status = "success"
	}
	actor := strings.TrimSpace(toString(row["actor_user_id"]))
	if actor == "" {
		actor = strings.TrimSpace(toString(payload["actor"]))
	}
	return activityEvent{
		ID:        strings.TrimSpace(toString(row["id"])),
		UserID:    strings.TrimSpace(toString(row["user_id"])),
		Actor:     actor,
		Action:    strings.TrimSpace(toString(row["event_name"])),
		Status:    status,
		Resource:  strings.TrimSpace(toString(payload["resource"])),
		Details:   mapOrEmpty(details),
		CreatedAt: strings.TrimSpace(toString(row["created_at"])),
		Domain:    strings.TrimSpace(toString(row["event_domain"])),
	}
}

// activityDomainAPIRequest marks request telemetry written by the activity
// middleware. These rows have their own 90-day retention class
// (platform.run_client_telemetry_retention, migration 122), are deleted on
// account erasure, and appear in the member export only as daily counts.
const activityDomainAPIRequest = "api_request"

func activityEventDomain(domain string) string {
	if trimmed := strings.TrimSpace(domain); trimmed != "" {
		return trimmed
	}
	return "mobile_bff"
}

// activityDomainMemberAction marks a mutating request by a signed-in member
// (POST/PUT/PATCH/DELETE outside /admin). The activity middleware writes these
// synchronously, with network and device context, and they have their own
// 400-day retention class (migration 132).
const activityDomainMemberAction = "member_action"

// activityRequestColumns are the matching.activity_events columns only the
// request middleware can fill. They are written as columns, never serialised.
type activityRequestColumns struct {
	IPAddress      string
	DeviceID       string
	Platform       string
	RequestID      string
	CorrelationID  string
	IdempotencyKey string
	EntityTable    string
	EntityID       string
}

const (
	activityUserAgentMaxRunes = 300
	activityMaxPathParams     = 8
)

var (
	// A path value is kept when it is a UUID or a short opaque id.
	activityShortIDPattern  = regexp.MustCompile(`^[A-Za-z0-9][A-Za-z0-9_.:-]{0,63}$`)
	activityHeaderToken     = regexp.MustCompile(`^[A-Za-z0-9][A-Za-z0-9_.:/+=-]{0,127}$`)
	activityPlatformPattern = regexp.MustCompile(`^[a-z0-9][a-z0-9_.-]{0,31}$`)
	activityVersionPattern  = regexp.MustCompile(`^[A-Za-z0-9][A-Za-z0-9_.+-]{0,31}$`)
)

// memberActivityNote lets a public handler name the member a request acted
// for once the handler has verified them itself: sign-in and sign-up succeed
// before any session exists, so the security middleware has no principal.
type memberActivityNote struct {
	mu          sync.Mutex
	userID      string
	accountKind string
}

type memberActivityNoteKey struct{}

func withMemberActivityNote(ctx context.Context) context.Context {
	return context.WithValue(ctx, memberActivityNoteKey{}, &memberActivityNote{})
}

// noteActivityMember records the member a public request acted for. Only
// call it after the handler verified the member (a successful credential
// check); the id is never taken from request input.
func noteActivityMember(r *http.Request, userID, accountKind string) {
	if r == nil {
		return
	}
	note, _ := r.Context().Value(memberActivityNoteKey{}).(*memberActivityNote)
	userID = strings.ToLower(strings.TrimSpace(userID))
	if note == nil || !uuidPattern.MatchString(userID) {
		return
	}
	note.mu.Lock()
	note.userID, note.accountKind = userID, strings.TrimSpace(accountKind)
	note.mu.Unlock()
}

func notedActivityMember(r *http.Request) (string, string) {
	note, _ := r.Context().Value(memberActivityNoteKey{}).(*memberActivityNote)
	if note == nil {
		return "", ""
	}
	note.mu.Lock()
	defer note.mu.Unlock()
	return note.userID, note.accountKind
}

// apiRequestActivityEvent is the activity record of one API request; see
// requestActivityEvent.
func (s *Server) apiRequestActivityEvent(r *http.Request, status int, elapsed time.Duration) activityEvent {
	event, _ := s.requestActivityEvent(r, status, elapsed)
	return event
}

// requestActivityEvent builds the activity record of one API request and
// reports whether it is a member action (durable, domain member_action)
// rather than best-effort request telemetry (domain api_request).
//
// Stored on every row: method, route template (e.g. "/v1/profile/{userID}"),
// status, outcome, duration and content type; the action catalog key, label
// and category; path parameters whose value is an id (path_params) and the
// last of them as the entity; the verified actor (the session principal, not
// a header) with role, account kind and session id; correlation and request
// ids; and the client platform, app version, device id and user agent from
// the request headers. Member actions also keep the client IP address (the
// trusted-proxy-aware address, see activityClientIP); reads never do.
//
// Never stored: the query string (search terms, coordinates, tokens),
// request and response bodies, and the concrete path.
func (s *Server) requestActivityEvent(r *http.Request, status int, elapsed time.Duration) (activityEvent, bool) {
	route := observability.RedactedRequestPath(r)
	prefix := s.cfg.APIPrefix

	principal, authenticated := principalFromRequest(r)
	actorID := ""
	attribution := ""
	accountKind := ""
	if authenticated && uuidPattern.MatchString(strings.TrimSpace(principal.UserID)) {
		actorID = strings.ToLower(strings.TrimSpace(principal.UserID))
		accountKind = strings.TrimSpace(principal.AccountKind)
		attribution = "session"
	} else if status >= 200 && status < 300 {
		if noted, kind := notedActivityMember(r); noted != "" {
			actorID, accountKind, attribution = noted, kind, "credential"
		}
	}
	memberAction := actorID != "" && isMutatingMethod(r.Method) && isMemberRoute(prefix, route)

	// Only a member id goes in user_id. A match id here (the old fallback)
	// failed the users foreign key on every match route, so those rows were
	// lost and the database logged an error per request (GO-02).
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" {
		userID = strings.TrimSpace(r.URL.Query().Get("user_id"))
	}
	// A 404 usually means the id in the path is unknown; attributing the row
	// to it only fails the user_id foreign key (GO-02).
	if status == http.StatusNotFound {
		userID = ""
	}
	if memberAction && !uuidPattern.MatchString(userID) {
		userID = actorID
	}

	actor := actorID
	if actor == "" {
		actor = strings.TrimSpace(r.Header.Get("X-Admin-User"))
	}
	if actor == "" {
		actor = strings.TrimSpace(r.Header.Get("X-User-ID"))
	}
	if actor == "" {
		actor = "system"
	}

	details := map[string]any{
		"method":       r.Method,
		"path":         route,
		"route":        route,
		"status_code":  status,
		"duration_ms":  elapsed.Milliseconds(),
		"content_type": r.Header.Get("Content-Type"),
		"outcome":      activityOutcome(status),
	}
	if def, ok := lookupMemberAction(prefix, r.Method, route); ok {
		details["action_key"] = def.Key
		details["action_label"] = def.Label
		details["action_category"] = def.Category
	}
	if actorID != "" {
		details["actor_role"] = memberActorRole(principal.Roles, accountKind)
		details["attribution"] = attribution
		if accountKind != "" {
			details["account_kind"] = accountKind
		}
		if session := strings.TrimSpace(principal.SessionID); session != "" && attribution == "session" {
			details["session_id"] = session
		}
	}
	params, entityTable, entityID := activityPathParams(r)
	if len(params) > 0 {
		details["path_params"] = params
	}

	columns := &activityRequestColumns{
		CorrelationID:  truncateRunes(strings.TrimSpace(observability.CorrelationIDFromContext(r.Context())), 128),
		RequestID:      activityHeaderValue(r, activityHeaderToken, "X-Request-ID"),
		IdempotencyKey: activityHeaderValue(r, activityHeaderToken, "Idempotency-Key"),
		Platform:       strings.ToLower(activityHeaderValue(r, activityPlatformPattern, "X-Client-Platform", "X-Platform")),
		DeviceID:       activityHeaderValue(r, activityHeaderToken, "X-Device-ID", "X-Install-ID"),
		EntityTable:    entityTable,
		EntityID:       entityID,
	}
	if columns.RequestID == "" {
		// The app sends a fresh X-Correlation-ID per request, so it doubles
		// as the request id when no X-Request-ID is present.
		columns.RequestID = columns.CorrelationID
	}
	if memberAction {
		columns.IPAddress = s.activityClientIP(r)
	}
	if columns.Platform != "" {
		details["platform"] = columns.Platform
	}
	if columns.DeviceID != "" {
		details["device_id"] = columns.DeviceID
	}
	if version := activityHeaderValue(r, activityVersionPattern, "X-App-Version", "X-Client-Version"); version != "" {
		details["app_version"] = version
	}
	if agent := activityUserAgent(r.Header.Get("User-Agent")); agent != "" {
		details["user_agent"] = agent
	}

	// Classification reads the concrete path; only the derived dimensions
	// are stored.
	details = mergeDetails(details, s.engagementTelemetryDetails(r.URL.Path))
	details = mergeDetails(details, s.billingPolicyTelemetryDetails(r.URL.Path))

	domain := activityDomainAPIRequest
	if memberAction {
		domain = activityDomainMemberAction
	}
	return activityEvent{
		UserID:    userID,
		Actor:     actor,
		Action:    r.Method + " " + route,
		Status:    statusLabel(status),
		Resource:  route,
		Details:   details,
		Domain:    domain,
		CreatedAt: time.Now().UTC().Format(time.RFC3339Nano),
		Request:   columns,
	}, memberAction
}

// activityOutcome is success (1xx-3xx), client_error (4xx) or server_error.
func activityOutcome(status int) string {
	switch {
	case status >= 500:
		return "server_error"
	case status >= 400:
		return "client_error"
	default:
		return "success"
	}
}

// memberActorRole names the role the actor acted in: an operator role when
// the principal holds one, otherwise introducer or member.
func memberActorRole(roles map[string]bool, accountKind string) string {
	for _, role := range []string{"admin", "ops_admin", "trust_safety", "moderator", "support", "finance", "analyst"} {
		if roles[role] {
			return role
		}
	}
	if strings.EqualFold(accountKind, "introducer") {
		return "introducer"
	}
	return "member"
}

// activityPathParams returns the chi URL parameters whose values are ids
// (UUIDs or short opaque ids), and the last of them as the entity
// ("matchID" -> entity type "match").
func activityPathParams(r *http.Request) (map[string]any, string, string) {
	rctx := chi.RouteContext(r.Context())
	if rctx == nil {
		return nil, "", ""
	}
	params := map[string]any{}
	entityKey, entityID := "", ""
	for i, key := range rctx.URLParams.Keys {
		if key == "" || key == "*" || i >= len(rctx.URLParams.Values) {
			continue
		}
		value := strings.TrimSpace(rctx.URLParams.Values[i])
		switch {
		case uuidPattern.MatchString(value):
			value = strings.ToLower(value)
		case activityShortIDPattern.MatchString(value):
		default:
			continue
		}
		params[key] = value
		entityKey, entityID = key, value
		if len(params) >= activityMaxPathParams {
			break
		}
	}
	if len(params) == 0 {
		return nil, "", ""
	}
	return params, activityEntityType(entityKey), entityID
}

// activityEntityType turns a route parameter name into an entity type:
// "friendUserID" -> "friend_user", "weekStart" -> "week_start".
func activityEntityType(key string) string {
	key = strings.TrimSuffix(strings.TrimSuffix(key, "ID"), "Id")
	var builder strings.Builder
	for i, ch := range key {
		if ch >= 'A' && ch <= 'Z' {
			if i > 0 {
				builder.WriteByte('_')
			}
			builder.WriteRune(ch + ('a' - 'A'))
			continue
		}
		builder.WriteRune(ch)
	}
	return builder.String()
}

// activityHeaderValue is the first named header whose trimmed value matches
// pattern, or "".
func activityHeaderValue(r *http.Request, pattern *regexp.Regexp, names ...string) string {
	for _, name := range names {
		value := strings.TrimSpace(r.Header.Get(name))
		if value != "" && pattern.MatchString(value) {
			return value
		}
	}
	return ""
}

// activityUserAgent is the User-Agent without control characters, at most
// activityUserAgentMaxRunes runes.
func activityUserAgent(raw string) string {
	cleaned := strings.Map(func(ch rune) rune {
		if ch < 0x20 || ch == 0x7f {
			return -1
		}
		return ch
	}, raw)
	return strings.TrimSpace(truncateRunes(strings.TrimSpace(cleaned), activityUserAgentMaxRunes))
}

var activityTrustedProxyCache sync.Map // raw CIDR list -> []netip.Prefix

// activityTrustedProxies parses GATEWAY_TRUSTED_PROXY_CIDRS the way the
// gateway does (empty means loopback). Unparseable entries are ignored.
func activityTrustedProxies(raw string) []netip.Prefix {
	if cached, ok := activityTrustedProxyCache.Load(raw); ok {
		return cached.([]netip.Prefix)
	}
	var out []netip.Prefix
	for _, part := range strings.Split(raw, ",") {
		part = strings.TrimSpace(part)
		if part == "" {
			continue
		}
		if !strings.Contains(part, "/") {
			if addr, err := netip.ParseAddr(part); err == nil {
				out = append(out, netip.PrefixFrom(addr.Unmap(), addr.Unmap().BitLen()))
			}
			continue
		}
		if prefix, err := netip.ParsePrefix(part); err == nil {
			out = append(out, prefix.Masked())
		}
	}
	if len(out) == 0 {
		out = []netip.Prefix{netip.MustParsePrefix("127.0.0.0/8"), netip.MustParsePrefix("::1/128")}
	}
	activityTrustedProxyCache.Store(raw, out)
	return out
}

func parseActivityAddr(raw string) netip.Addr {
	raw = strings.TrimSpace(raw)
	if host, _, err := net.SplitHostPort(raw); err == nil {
		raw = host
	}
	addr, err := netip.ParseAddr(strings.Trim(raw, "[]"))
	if err != nil {
		return netip.Addr{}
	}
	return addr.Unmap().WithZone("")
}

func activityAddrTrusted(trusted []netip.Prefix, addr netip.Addr) bool {
	for _, prefix := range trusted {
		if prefix.Contains(addr) {
			return true
		}
	}
	return false
}

// activityClientIP is the member's address as the edge saw it. The BFF is
// reached through the gateway (which appends its peer to X-Forwarded-For),
// usually behind nginx (which sets X-Real-IP). Forwarding headers are read
// only when the direct peer is a trusted proxy (GATEWAY_TRUSTED_PROXY_CIDRS,
// loopback by default, the gateway's own rule): X-Forwarded-For is walked from
// the right past trusted hops, then X-Real-IP, then the peer itself.
func (s *Server) activityClientIP(r *http.Request) string {
	peer := parseActivityAddr(r.RemoteAddr)
	if !peer.IsValid() {
		return ""
	}
	trusted := activityTrustedProxies(s.cfg.GatewayTrustedProxyCIDRs)
	if !activityAddrTrusted(trusted, peer) {
		return peer.String()
	}
	if forwarded := strings.TrimSpace(r.Header.Get("X-Forwarded-For")); forwarded != "" {
		hops := strings.Split(forwarded, ",")
		for i := len(hops) - 1; i >= 0; i-- {
			addr := parseActivityAddr(hops[i])
			if !addr.IsValid() {
				break
			}
			if !activityAddrTrusted(trusted, addr) {
				return addr.String()
			}
		}
	}
	if real := parseActivityAddr(r.Header.Get("X-Real-IP")); real.IsValid() {
		return real.String()
	}
	return peer.String()
}

// memberActionWriteTimeout bounds the synchronous member action insert.
const memberActionWriteTimeout = 250 * time.Millisecond

// recordMemberAction writes a member action durably: one synchronous insert
// bounded by memberActionWriteTimeout, right after the handler returned. If
// that fails the row goes to the asynchronous activity queue instead (which
// retries the insert once more), and the fallback is counted.
func (s *Server) recordMemberAction(ctx context.Context, event activityEvent) {
	if s.store == nil {
		return
	}
	s.store.applyExperimentDimensions(&event)
	if repo := s.store.activityRepo; repo != nil {
		writeCtx, cancel := context.WithTimeout(context.WithoutCancel(ctx), memberActionWriteTimeout)
		_, err := repo.recordActivityEvent(writeCtx, event)
		if err != nil && isForeignKeyViolation(err) && event.UserID != event.Actor {
			// The subject named in the path is not a member row (or no
			// longer is); keep the action under its actor.
			event.UserID = event.Actor
			_, err = repo.recordActivityEvent(writeCtx, event)
		}
		cancel()
		if err == nil {
			s.countActivityWrite(activityDomainMemberAction, "durable")
			if s.fanout != nil {
				s.fanout.updateAggregates(event)
			}
			return
		}
		if s.log != nil {
			s.log.Warn("member_action_sync_write_failed",
				zap.String("action", event.Action), zap.Error(err))
		}
	}
	s.countActivityWrite(activityDomainMemberAction, "fallback_queue")
	s.enqueueNonCriticalActivity(event)
}

func isForeignKeyViolation(err error) bool {
	if err == nil {
		return false
	}
	msg := strings.ToLower(err.Error())
	return strings.Contains(msg, "23503") || strings.Contains(msg, "foreign key")
}

func (s *Server) countActivityWrite(domain, result string) {
	switch result {
	case "durable":
		memberActionDurableWrites.Add(1)
	case "fallback_queue":
		memberActionFallbackWrites.Add(1)
	}
	if s.httpMetrics != nil && s.httpMetrics.ActivityCaptureWrites != nil {
		s.httpMetrics.ActivityCaptureWrites.WithLabelValues(domain, result).Inc()
	}
}

// Process-wide member action write counters, reported by
// /admin/activity/catalog next to the Prometheus series.
var memberActionDurableWrites, memberActionFallbackWrites atomic.Int64

func nullableEventUUID(value string) any {
	trimmed := strings.TrimSpace(value)
	if trimmed == "" {
		return nil
	}
	if !uuidPattern.MatchString(trimmed) {
		return nil
	}
	return strings.ToLower(trimmed)
}

func mapActivitySessionRow(row map[string]any) activitySession {
	participantIDs := toStringArray(row["participant_user_ids"])
	metadata, _ := row["metadata"].(map[string]any)
	status := strings.TrimSpace(toString(row["status"]))
	if status == "" {
		status = activitySessionStatusActive
	}
	return activitySession{
		ID:              strings.TrimSpace(toString(row["id"])),
		MatchID:         strings.TrimSpace(toString(row["match_id"])),
		ActivityType:    strings.TrimSpace(toString(row["activity_type"])),
		Status:          status,
		InitiatorUserID: strings.TrimSpace(toString(row["initiator_user_id"])),
		ParticipantIDs:  participantIDs,
		ResponsesByUser: map[string][]string{},
		StartedAt:       strings.TrimSpace(toString(row["started_at"])),
		ExpiresAt:       strings.TrimSpace(toString(row["expires_at"])),
		CompletedAt:     strings.TrimSpace(toString(row["completed_at"])),
		Metadata:        mapOrEmpty(metadata),
	}
}

func toStringArray(value any) []string {
	raw, ok := value.([]any)
	if !ok {
		return []string{}
	}
	out := make([]string, 0, len(raw))
	for _, item := range raw {
		candidate := strings.TrimSpace(toString(item))
		if candidate == "" {
			continue
		}
		out = append(out, candidate)
	}
	return out
}

func finalizeActivityTimeoutIfNeeded(session activitySession, now time.Time) activitySession {
	if session.Status != activitySessionStatusActive {
		return session
	}
	expiresAt := parseRFC3339OrZero(session.ExpiresAt)
	if expiresAt.IsZero() || !now.After(expiresAt) {
		return session
	}
	if len(session.ResponsesByUser) > 0 {
		session.Status = activitySessionStatusPartialTimeout
	} else {
		session.Status = activitySessionStatusTimedOut
	}
	session.TimedOutAt = now.Format(time.RFC3339)
	session.Summary = buildActivitySummary(session, now)
	return session
}

func buildActivitySummary(session activitySession, now time.Time) activitySessionSummary {
	completed := make([]string, 0, len(session.ResponsesByUser))
	pending := make([]string, 0, len(session.ParticipantIDs))
	for _, userID := range session.ParticipantIDs {
		if len(session.ResponsesByUser[userID]) > 0 {
			completed = append(completed, userID)
			continue
		}
		pending = append(pending, userID)
	}

	insight := "No responses were submitted."
	if len(completed) == len(session.ParticipantIDs) && len(completed) > 0 {
		insight = "Both participants completed the activity session."
	} else if len(completed) > 0 {
		insight = "Partial completion captured before the session closed."
	}

	return activitySessionSummary{
		SessionID:             session.ID,
		MatchID:               session.MatchID,
		Status:                session.Status,
		TotalParticipants:     len(session.ParticipantIDs),
		ResponsesSubmitted:    len(session.ResponsesByUser),
		ParticipantsCompleted: completed,
		ParticipantsPending:   pending,
		Insight:               insight,
		GeneratedAt:           now.Format(time.RFC3339),
	}
}

func mapOrEmpty(in map[string]any) map[string]any {
	if len(in) == 0 {
		return map[string]any{}
	}
	out := make(map[string]any, len(in))
	for key, value := range in {
		out[key] = value
	}
	return out
}
