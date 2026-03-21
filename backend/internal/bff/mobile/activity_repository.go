package mobile

import (
	"context"
	"errors"
	"fmt"
	"net/url"
	"regexp"
	"strings"
	"time"

	"github.com/verified-dating/backend/internal/platform/config"
	"github.com/verified-dating/backend/internal/platform/supabase"
)

type activityRepository struct {
	cfg config.Config
	db  *supabase.Client
}

var uuidPattern = regexp.MustCompile("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$")

func newActivityRepository(cfg config.Config) *activityRepository {
	apiKey := strings.TrimSpace(cfg.SupabaseServiceRole)
	if apiKey == "" {
		apiKey = strings.TrimSpace(cfg.SupabaseAnonKey)
	}
	if strings.TrimSpace(cfg.SupabaseURL) == "" || apiKey == "" {
		return nil
	}
	client := supabase.NewClient(
		cfg.SupabaseURL,
		cfg.SupabaseAnonKey,
		cfg.SupabaseServiceRole,
		time.Duration(cfg.SupabaseHTTPTimeoutSec)*time.Second,
	)
	client.SetReadBaseURL(cfg.SupabaseReadReplicaURL)
	return &activityRepository{cfg: cfg, db: client}
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
	trimmedType := strings.TrimSpace(activityType)
	if trimmedMatchID == "" || trimmedInitiator == "" || trimmedParticipant == "" {
		return activitySession{}, errors.New("match_id, initiator_user_id, and participant_user_id are required")
	}
	if trimmedInitiator == trimmedParticipant {
		return activitySession{}, errors.New("initiator and participant must be different users")
	}
	if trimmedType == "" {
		trimmedType = "co_op_prompt"
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

	rows, err := r.db.Insert(ctx, r.cfg.MatchingSchema, "activity_events", []map[string]any{{
		"event_name":     action,
		"event_domain":   "mobile_bff",
		"event_version":  1,
		"user_id":        nullableEventUUID(event.UserID),
		"actor_user_id":  nullableEventUUID(event.Actor),
		"match_id":       nullableEventUUID(matchID),
		"source_service": "mobile_bff",
		"payload":        payload,
		"created_at":     createdAt,
	}})
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
	params.Set("select", "id,event_name,user_id,actor_user_id,payload,created_at")
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
	}
}

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
