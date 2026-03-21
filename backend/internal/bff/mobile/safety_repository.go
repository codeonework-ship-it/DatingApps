package mobile

import (
	"context"
	"errors"
	"net/url"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/verified-dating/backend/internal/platform/config"
	"github.com/verified-dating/backend/internal/platform/supabase"
)

type safetyRepository struct {
	cfg config.Config
	db  *supabase.Client
}

func newSafetyRepository(cfg config.Config) *safetyRepository {
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
	return &safetyRepository{cfg: cfg, db: client}
}

func isSafetyRepoPersistenceUnavailable(err error) bool {
	if err == nil {
		return false
	}
	msg := strings.ToLower(err.Error())
	return strings.Contains(msg, "pgrst106") ||
		strings.Contains(msg, "pgrst205") ||
		strings.Contains(msg, "invalid schema") ||
		strings.Contains(msg, "could not find the table")
}

func (r *safetyRepository) createReport(ctx context.Context, reporterUserID, reportedUserID, reason, description string) (moderationReport, error) {
	reporter := strings.TrimSpace(reporterUserID)
	reported := strings.TrimSpace(reportedUserID)
	trimmedReason := strings.TrimSpace(reason)
	if reported == "" || trimmedReason == "" {
		return moderationReport{}, errors.New("reported_user_id and reason are required")
	}
	if reporter == "" {
		reporter = "00000000-0000-0000-0000-000000000000"
	}
	rows, err := r.db.Insert(ctx, r.cfg.MatchingSchema, "moderation_reports", []map[string]any{{
		"reporter_user_id": reporter,
		"reported_user_id": reported,
		"reason":           trimmedReason,
		"description":      strings.TrimSpace(description),
		"status":           "pending",
		"created_at":       time.Now().UTC().Format(time.RFC3339),
		"updated_at":       time.Now().UTC().Format(time.RFC3339),
	}})
	if err != nil {
		return moderationReport{}, err
	}
	if len(rows) == 0 {
		return moderationReport{}, errors.New("moderation report persistence returned empty result")
	}
	return mapModerationReportRow(rows[0]), nil
}

func (r *safetyRepository) listReports(ctx context.Context, status string, limit int) ([]moderationReport, error) {
	if limit <= 0 || limit > 500 {
		limit = 100
	}
	normalized := strings.ToLower(strings.TrimSpace(status))
	params := url.Values{}
	if normalized != "" {
		params.Set("status", "eq."+mapReportStatusToDB(normalized))
	}
	params.Set("limit", strconv.Itoa(limit))
	params.Set("order", "created_at.desc")
	params.Set("select", "id,reporter_user_id,reported_user_id,reason,description,status,action,reviewed_by,reviewed_at,created_at")
	rows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "moderation_reports", params)
	if err != nil {
		return nil, err
	}
	out := make([]moderationReport, 0, len(rows))
	for _, row := range rows {
		out = append(out, mapModerationReportRow(row))
	}
	sort.Slice(out, func(i, j int) bool { return out[i].CreatedAt > out[j].CreatedAt })
	return out, nil
}

func (r *safetyRepository) actionReport(ctx context.Context, reportID, status, action, reviewedBy string) (moderationReport, error) {
	trimmedReportID := strings.TrimSpace(reportID)
	normalizedStatus := strings.ToLower(strings.TrimSpace(status))
	if trimmedReportID == "" || normalizedStatus == "" {
		return moderationReport{}, errors.New("report_id and status are required")
	}
	filters := url.Values{}
	filters.Set("id", "eq."+trimmedReportID)
	rows, err := r.db.Update(ctx, r.cfg.MatchingSchema, "moderation_reports", map[string]any{
		"status":      mapReportStatusToDB(normalizedStatus),
		"action":      strings.TrimSpace(action),
		"reviewed_by": nullableString(strings.TrimSpace(reviewedBy)),
		"reviewed_at": time.Now().UTC().Format(time.RFC3339),
		"updated_at":  time.Now().UTC().Format(time.RFC3339),
	}, filters)
	if err != nil {
		return moderationReport{}, err
	}
	if len(rows) == 0 {
		return moderationReport{}, errors.New("report not found")
	}
	return mapModerationReportRow(rows[0]), nil
}

func (r *safetyRepository) submitModerationAppeal(ctx context.Context, userID, reportID, reason, description string) (moderationAppeal, error) {
	trimmedUserID := strings.TrimSpace(userID)
	trimmedReason := strings.TrimSpace(reason)
	if trimmedUserID == "" || trimmedReason == "" {
		return moderationAppeal{}, errors.New("user_id and reason are required")
	}
	now := time.Now().UTC()
	payload := map[string]any{
		"requester_user_id": trimmedUserID,
		"reason":            trimmedReason,
		"description":       strings.TrimSpace(description),
		"status":            mapAppealStatusToDB(appealStatusSubmitted),
		"created_at":        now.Format(time.RFC3339),
		"updated_at":        now.Format(time.RFC3339),
	}
	if strings.TrimSpace(reportID) != "" {
		payload["report_id"] = strings.TrimSpace(reportID)
	}
	rows, err := r.db.Insert(ctx, r.cfg.MatchingSchema, "moderation_appeals", []map[string]any{payload})
	if err != nil {
		return moderationAppeal{}, err
	}
	if len(rows) == 0 {
		return moderationAppeal{}, errors.New("moderation appeal persistence returned empty result")
	}
	return mapModerationAppealRow(rows[0]), nil
}

func (r *safetyRepository) getModerationAppeal(ctx context.Context, appealID, requesterUserID string, admin bool) (moderationAppeal, error) {
	trimmedAppealID := strings.TrimSpace(appealID)
	if trimmedAppealID == "" {
		return moderationAppeal{}, errors.New("appeal_id is required")
	}
	params := url.Values{}
	params.Set("id", "eq."+trimmedAppealID)
	params.Set("limit", "1")
	params.Set("select", "id,requester_user_id,report_id,reason,description,status,resolution_reason,reviewed_by,reviewed_at,created_at,updated_at")
	rows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "moderation_appeals", params)
	if err != nil {
		return moderationAppeal{}, err
	}
	if len(rows) == 0 {
		return moderationAppeal{}, errors.New("appeal not found")
	}
	item := mapModerationAppealRow(rows[0])
	if !admin {
		requester := strings.TrimSpace(requesterUserID)
		if requester != "" && item.UserID != requester {
			return moderationAppeal{}, errors.New("appeal not found")
		}
	}
	return item, nil
}

func (r *safetyRepository) listModerationAppeals(ctx context.Context, status string, limit int) ([]moderationAppeal, error) {
	if limit <= 0 || limit > 500 {
		limit = 100
	}
	normalized := strings.ToLower(strings.TrimSpace(status))
	params := url.Values{}
	if normalized != "" {
		params.Set("status", "eq."+mapAppealStatusToDB(normalized))
	}
	params.Set("limit", strconv.Itoa(limit))
	params.Set("order", "created_at.desc")
	params.Set("select", "id,requester_user_id,report_id,reason,description,status,resolution_reason,reviewed_by,reviewed_at,created_at,updated_at")
	rows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "moderation_appeals", params)
	if err != nil {
		return nil, err
	}
	out := make([]moderationAppeal, 0, len(rows))
	for _, row := range rows {
		out = append(out, mapModerationAppealRow(row))
	}
	sort.Slice(out, func(i, j int) bool { return out[i].CreatedAt > out[j].CreatedAt })
	return out, nil
}

func (r *safetyRepository) listModerationAppealsForUser(ctx context.Context, userID, status string, limit int) ([]moderationAppeal, error) {
	trimmedUserID := strings.TrimSpace(userID)
	if trimmedUserID == "" {
		return []moderationAppeal{}, nil
	}
	if limit <= 0 || limit > 500 {
		limit = 100
	}
	normalized := strings.ToLower(strings.TrimSpace(status))
	params := url.Values{}
	params.Set("requester_user_id", "eq."+trimmedUserID)
	if normalized != "" {
		params.Set("status", "eq."+mapAppealStatusToDB(normalized))
	}
	params.Set("limit", strconv.Itoa(limit))
	params.Set("order", "created_at.desc")
	params.Set("select", "id,requester_user_id,report_id,reason,description,status,resolution_reason,reviewed_by,reviewed_at,created_at,updated_at")
	rows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "moderation_appeals", params)
	if err != nil {
		return nil, err
	}
	out := make([]moderationAppeal, 0, len(rows))
	for _, row := range rows {
		out = append(out, mapModerationAppealRow(row))
	}
	sort.Slice(out, func(i, j int) bool { return out[i].CreatedAt > out[j].CreatedAt })
	return out, nil
}

func (r *safetyRepository) actionModerationAppeal(ctx context.Context, appealID, status, resolutionReason, reviewedBy string) (moderationAppeal, error) {
	trimmedAppealID := strings.TrimSpace(appealID)
	normalizedStatus := strings.ToLower(strings.TrimSpace(status))
	if trimmedAppealID == "" || normalizedStatus == "" {
		return moderationAppeal{}, errors.New("appeal_id and status are required")
	}

	filters := url.Values{}
	filters.Set("id", "eq."+trimmedAppealID)
	rows, err := r.db.Update(ctx, r.cfg.MatchingSchema, "moderation_appeals", map[string]any{
		"status":            mapAppealStatusToDB(normalizedStatus),
		"resolution_reason": strings.TrimSpace(resolutionReason),
		"reviewed_by":       nullableString(strings.TrimSpace(reviewedBy)),
		"reviewed_at":       time.Now().UTC().Format(time.RFC3339),
		"updated_at":        time.Now().UTC().Format(time.RFC3339),
	}, filters)
	if err != nil {
		return moderationAppeal{}, err
	}
	if len(rows) == 0 {
		return moderationAppeal{}, errors.New("appeal not found")
	}
	return mapModerationAppealRow(rows[0]), nil
}

func (r *safetyRepository) createSOSAlert(
	ctx context.Context,
	userID, matchID, level, message string,
	latitude, longitude float64,
) (sosAlert, error) {
	trimmedUserID := strings.TrimSpace(userID)
	if trimmedUserID == "" {
		return sosAlert{}, errors.New("user_id is required")
	}
	levelNorm := strings.ToLower(strings.TrimSpace(level))
	if levelNorm == "" {
		levelNorm = "high"
	}
	if levelNorm != "low" && levelNorm != "medium" && levelNorm != "high" {
		return sosAlert{}, errors.New("emergency_level must be low, medium, or high")
	}

	rows, err := r.db.Insert(ctx, r.cfg.MatchingSchema, "sos_alerts", []map[string]any{{
		"user_id":    trimmedUserID,
		"match_id":   nullableString(strings.TrimSpace(matchID)),
		"level":      levelNorm,
		"message":    strings.TrimSpace(message),
		"latitude":   latitude,
		"longitude":  longitude,
		"status":     "open",
		"created_at": time.Now().UTC().Format(time.RFC3339),
	}})
	if err != nil {
		return sosAlert{}, err
	}
	if len(rows) == 0 {
		return sosAlert{}, errors.New("sos persistence returned empty result")
	}
	return mapSOSAlertRow(rows[0]), nil
}

func (r *safetyRepository) resolveSOSAlert(ctx context.Context, alertID, resolvedBy, note string) (sosAlert, error) {
	trimmedAlertID := strings.TrimSpace(alertID)
	if trimmedAlertID == "" {
		return sosAlert{}, errors.New("alert_id is required")
	}
	filters := url.Values{}
	filters.Set("id", "eq."+trimmedAlertID)
	rows, err := r.db.Update(ctx, r.cfg.MatchingSchema, "sos_alerts", map[string]any{
		"status":        "resolved",
		"resolved_by":   nullableString(strings.TrimSpace(resolvedBy)),
		"resolved_note": strings.TrimSpace(note),
		"resolved_at":   time.Now().UTC().Format(time.RFC3339),
	}, filters)
	if err != nil {
		return sosAlert{}, err
	}
	if len(rows) == 0 {
		return sosAlert{}, errors.New("sos alert not found")
	}
	return mapSOSAlertRow(rows[0]), nil
}

func (r *safetyRepository) listSOSAlerts(ctx context.Context, userID string, limit int) ([]sosAlert, error) {
	if limit <= 0 || limit > 500 {
		limit = 100
	}
	params := url.Values{}
	trimmedUserID := strings.TrimSpace(userID)
	if trimmedUserID != "" {
		params.Set("user_id", "eq."+trimmedUserID)
	}
	params.Set("limit", strconv.Itoa(limit))
	params.Set("order", "created_at.desc")
	params.Set("select", "id,user_id,match_id,latitude,longitude,message,level,status,created_at,resolved_at,resolved_by,resolved_note")
	rows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "sos_alerts", params)
	if err != nil {
		return nil, err
	}
	out := make([]sosAlert, 0, len(rows))
	for _, row := range rows {
		out = append(out, mapSOSAlertRow(row))
	}
	sort.Slice(out, func(i, j int) bool { return out[i].TriggeredAt > out[j].TriggeredAt })
	return out, nil
}

func (r *safetyRepository) recordMessageDeleteAudit(ctx context.Context, userID string, deleted bool, attempts, success, blocked int, flagged bool) error {
	trimmedUserID := strings.TrimSpace(userID)
	if trimmedUserID == "" {
		return nil
	}
	_, err := r.db.Insert(ctx, r.cfg.MatchingSchema, "message_delete_audit", []map[string]any{{
		"user_id":       trimmedUserID,
		"deleted":       deleted,
		"attempts_24h":  attempts,
		"success_24h":   success,
		"blocked_24h":   blocked,
		"abuse_flagged": flagged,
		"created_at":    time.Now().UTC().Format(time.RFC3339),
	}})
	return err
}

func mapModerationReportRow(row map[string]any) moderationReport {
	return moderationReport{
		ID:             strings.TrimSpace(toString(row["id"])),
		ReporterUserID: strings.TrimSpace(toString(row["reporter_user_id"])),
		ReportedUserID: strings.TrimSpace(toString(row["reported_user_id"])),
		Reason:         strings.TrimSpace(toString(row["reason"])),
		Description:    strings.TrimSpace(toString(row["description"])),
		Status:         mapReportStatusFromDB(strings.TrimSpace(toString(row["status"]))),
		Action:         strings.TrimSpace(toString(row["action"])),
		ReviewedBy:     strings.TrimSpace(toString(row["reviewed_by"])),
		ReviewedAt:     normalizeTimestampString(row["reviewed_at"]),
		CreatedAt:      normalizeTimestampString(row["created_at"]),
	}
}

func mapModerationAppealRow(row map[string]any) moderationAppeal {
	createdAt := normalizeTimestampString(row["created_at"])
	return moderationAppeal{
		ID:                 strings.TrimSpace(toString(row["id"])),
		UserID:             strings.TrimSpace(toString(row["requester_user_id"])),
		ReportID:           strings.TrimSpace(toString(row["report_id"])),
		Reason:             strings.TrimSpace(toString(row["reason"])),
		Description:        strings.TrimSpace(toString(row["description"])),
		Status:             mapAppealStatusFromDB(strings.TrimSpace(toString(row["status"]))),
		ResolutionReason:   strings.TrimSpace(toString(row["resolution_reason"])),
		ReviewedBy:         strings.TrimSpace(toString(row["reviewed_by"])),
		ReviewedAt:         normalizeTimestampString(row["reviewed_at"]),
		SLADeadlineAt:      calculateAppealSLADeadline(createdAt),
		NotificationPolicy: "status_change_email_and_inbox",
		CreatedAt:          createdAt,
		UpdatedAt:          normalizeTimestampString(row["updated_at"]),
	}
}

func mapSOSAlertRow(row map[string]any) sosAlert {
	return sosAlert{
		ID:             strings.TrimSpace(toString(row["id"])),
		UserID:         strings.TrimSpace(toString(row["user_id"])),
		MatchID:        strings.TrimSpace(toString(row["match_id"])),
		Latitude:       toFloat64Value(row["latitude"]),
		Longitude:      toFloat64Value(row["longitude"]),
		Message:        strings.TrimSpace(toString(row["message"])),
		EmergencyLevel: strings.TrimSpace(toString(row["level"])),
		Status:         mapSOSStatusFromDB(strings.TrimSpace(toString(row["status"]))),
		TriggeredAt:    normalizeTimestampString(row["created_at"]),
		ResolvedAt:     normalizeTimestampString(row["resolved_at"]),
		ResolvedBy:     strings.TrimSpace(toString(row["resolved_by"])),
		ResolutionNote: strings.TrimSpace(toString(row["resolved_note"])),
	}
}

func mapReportStatusToDB(status string) string {
	switch strings.ToLower(strings.TrimSpace(status)) {
	case "under_review":
		return "reviewed"
	case "resolved":
		return "actioned"
	case "rejected":
		return "dismissed"
	default:
		return "pending"
	}
}

func mapReportStatusFromDB(status string) string {
	switch strings.ToLower(strings.TrimSpace(status)) {
	case "reviewed":
		return "under_review"
	case "actioned":
		return "resolved"
	case "dismissed":
		return "rejected"
	default:
		return "pending"
	}
}

func mapAppealStatusToDB(status string) string {
	switch strings.ToLower(strings.TrimSpace(status)) {
	case appealStatusUnderReview:
		return "pending"
	case appealStatusResolvedUpheld:
		return "approved"
	case appealStatusResolvedReverse:
		return "rejected"
	default:
		return "pending"
	}
}

func mapAppealStatusFromDB(status string) string {
	switch strings.ToLower(strings.TrimSpace(status)) {
	case "approved":
		return appealStatusResolvedUpheld
	case "rejected":
		return appealStatusResolvedReverse
	default:
		return appealStatusSubmitted
	}
}

func mapSOSStatusFromDB(status string) string {
	switch strings.ToLower(strings.TrimSpace(status)) {
	case "open", "acknowledged":
		return "active"
	default:
		return "resolved"
	}
}

func calculateAppealSLADeadline(createdAt string) string {
	parsed, err := time.Parse(time.RFC3339, strings.TrimSpace(createdAt))
	if err != nil {
		return time.Now().UTC().Add(appealSLADuration).Format(time.RFC3339)
	}
	return parsed.Add(appealSLADuration).UTC().Format(time.RFC3339)
}

func toFloat64Value(value any) float64 {
	switch typed := value.(type) {
	case float64:
		return typed
	case float32:
		return float64(typed)
	case int:
		return float64(typed)
	case int64:
		return float64(typed)
	case string:
		parsed, err := strconv.ParseFloat(strings.TrimSpace(typed), 64)
		if err == nil {
			return parsed
		}
	}
	return 0
}
