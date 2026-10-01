package mobile

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"
)

func insertSecurityEventTx(ctx context.Context, tx *sql.Tx, eventType, actorID, actorRole, subjectID, resourceType, resourceID string, payload map[string]any) error {
	encoded, err := json.Marshal(payload)
	if err != nil {
		return err
	}
	_, err = tx.ExecContext(ctx, `
		INSERT INTO audit.security_events(event_type,actor_user_id,actor_role,subject_user_id,resource_type,resource_id,payload)
		VALUES($1,NULLIF($2,'')::uuid,$3,NULLIF($4,'')::uuid,$5,NULLIF($6,''),$7::jsonb)`,
		eventType, actorID, actorRole, subjectID, resourceType, resourceID, string(encoded))
	return err
}

func (r *safetyRepository) createReportPostgres(ctx context.Context, reporterID, reportedID, reason, description string) (moderationReport, error) {
	reporterID, reportedID, reason = strings.TrimSpace(reporterID), strings.TrimSpace(reportedID), strings.TrimSpace(reason)
	if reporterID == "" || reportedID == "" || reason == "" {
		return moderationReport{}, errors.New("reporter_user_id, reported_user_id, and reason are required")
	}
	if reporterID == reportedID {
		return moderationReport{}, errors.New("cannot report yourself")
	}
	tx, err := r.pg.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelReadCommitted})
	if err != nil {
		return moderationReport{}, err
	}
	defer func() { _ = tx.Rollback() }()
	var item moderationReport
	var createdAt time.Time
	err = tx.QueryRowContext(ctx, `
		INSERT INTO matching.moderation_reports(reporter_user_id,reported_user_id,reason,description,status)
		VALUES($1,$2,$3,NULLIF($4,''),'pending')
		RETURNING id::text,reporter_user_id::text,reported_user_id::text,reason,COALESCE(description,''),status,created_at`,
		reporterID, reportedID, reason, strings.TrimSpace(description)).Scan(
		&item.ID, &item.ReporterUserID, &item.ReportedUserID, &item.Reason, &item.Description, &item.Status, &createdAt)
	if err != nil {
		return moderationReport{}, err
	}
	item.Status = mapReportStatusFromDB(item.Status)
	item.CreatedAt = createdAt.UTC().Format(time.RFC3339)
	if err = insertSecurityEventTx(ctx, tx, "moderation.report.submitted", reporterID, "user", reportedID, "moderation_report", item.ID, map[string]any{"reason": reason, "status": item.Status}); err != nil {
		return moderationReport{}, err
	}
	if err = tx.Commit(); err != nil {
		return moderationReport{}, err
	}
	return item, nil
}

func (r *safetyRepository) listReportsPostgres(ctx context.Context, status string, limit int) ([]moderationReport, error) {
	if limit <= 0 || limit > 500 {
		limit = 100
	}
	dbStatus := ""
	if strings.TrimSpace(status) != "" {
		dbStatus = mapReportStatusToDB(status)
	}
	rows, err := r.pg.QueryContext(ctx, `
		SELECT id::text,reporter_user_id::text,reported_user_id::text,reason,COALESCE(description,''),status,
		       COALESCE(action,''),COALESCE(reviewed_by::text,''),reviewed_at,created_at
		FROM matching.moderation_reports
		WHERE ($1='' OR status=$1)
		ORDER BY created_at DESC LIMIT $2`, dbStatus, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := make([]moderationReport, 0)
	for rows.Next() {
		var item moderationReport
		var reviewedAt sql.NullTime
		var createdAt time.Time
		if err = rows.Scan(&item.ID, &item.ReporterUserID, &item.ReportedUserID, &item.Reason, &item.Description, &item.Status, &item.Action, &item.ReviewedBy, &reviewedAt, &createdAt); err != nil {
			return nil, err
		}
		item.Status = mapReportStatusFromDB(item.Status)
		item.CreatedAt = createdAt.UTC().Format(time.RFC3339)
		if reviewedAt.Valid {
			item.ReviewedAt = reviewedAt.Time.UTC().Format(time.RFC3339)
		}
		out = append(out, item)
	}
	return out, rows.Err()
}

func (r *safetyRepository) actionReportPostgres(ctx context.Context, reportID, status, action, reviewedBy string) (moderationReport, error) {
	reportID, status, reviewedBy = strings.TrimSpace(reportID), strings.ToLower(strings.TrimSpace(status)), strings.TrimSpace(reviewedBy)
	allowed := map[string]bool{"under_review": true, "resolved": true, "rejected": true}
	if reportID == "" || reviewedBy == "" || !allowed[status] {
		return moderationReport{}, errors.New("valid report_id, status, and authenticated reviewer are required")
	}
	tx, err := r.pg.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelReadCommitted})
	if err != nil {
		return moderationReport{}, err
	}
	defer func() { _ = tx.Rollback() }()
	var current string
	if err = tx.QueryRowContext(ctx, `SELECT status FROM matching.moderation_reports WHERE id=$1 FOR UPDATE`, reportID).Scan(&current); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return moderationReport{}, errors.New("report not found")
		}
		return moderationReport{}, err
	}
	if current == "actioned" || current == "dismissed" {
		return moderationReport{}, errors.New("report is already resolved")
	}
	var item moderationReport
	var reviewedAt time.Time
	var createdAt time.Time
	err = tx.QueryRowContext(ctx, `
		UPDATE matching.moderation_reports SET status=$2,action=NULLIF($3,''),reviewed_by=$4,reviewed_at=NOW(),updated_at=NOW()
		WHERE id=$1
		RETURNING id::text,reporter_user_id::text,reported_user_id::text,reason,COALESCE(description,''),status,COALESCE(action,''),reviewed_by::text,reviewed_at,created_at`,
		reportID, mapReportStatusToDB(status), strings.TrimSpace(action), reviewedBy).Scan(&item.ID, &item.ReporterUserID, &item.ReportedUserID, &item.Reason, &item.Description, &item.Status, &item.Action, &item.ReviewedBy, &reviewedAt, &createdAt)
	if err != nil {
		return moderationReport{}, err
	}
	item.Status, item.ReviewedAt = mapReportStatusFromDB(item.Status), reviewedAt.UTC().Format(time.RFC3339)
	item.CreatedAt = createdAt.UTC().Format(time.RFC3339)
	if err = insertSecurityEventTx(ctx, tx, "moderation.report."+status, reviewedBy, "operator", item.ReportedUserID, "moderation_report", item.ID, map[string]any{"previous_status": mapReportStatusFromDB(current), "status": status, "action": item.Action}); err != nil {
		return moderationReport{}, err
	}
	if _, err = tx.ExecContext(ctx, `SELECT matching.enqueue_notification(
		$1::uuid,$2::uuid,'moderation.report.status_changed','safety',$3::uuid,
		$4,'Safety report updated',$5,'/safety/reports',
		jsonb_build_object('report_id',$3::text,'status',$6),9)`,
		item.ReporterUserID, reviewedBy, item.ID, "report-status:"+item.ID+":"+status,
		"Your safety report is now "+strings.ReplaceAll(status, "_", " ")+".", status); err != nil {
		return moderationReport{}, err
	}
	if err = tx.Commit(); err != nil {
		return moderationReport{}, err
	}
	return item, nil
}

func scanAppeal(scanner interface{ Scan(...any) error }) (moderationAppeal, error) {
	var item moderationAppeal
	var reportID, resolution, reviewedBy sql.NullString
	var reviewedAt sql.NullTime
	var createdAt, updatedAt, deadline time.Time
	err := scanner.Scan(&item.ID, &item.UserID, &reportID, &item.Reason, &item.Description, &item.Status, &resolution, &reviewedBy, &reviewedAt, &deadline, &item.NotificationPolicy, &createdAt, &updatedAt)
	if err != nil {
		return moderationAppeal{}, err
	}
	item.ReportID, item.ResolutionReason, item.ReviewedBy = reportID.String, resolution.String, reviewedBy.String
	item.SLADeadlineAt, item.CreatedAt, item.UpdatedAt = deadline.UTC().Format(time.RFC3339), createdAt.UTC().Format(time.RFC3339), updatedAt.UTC().Format(time.RFC3339)
	if reviewedAt.Valid {
		item.ReviewedAt = reviewedAt.Time.UTC().Format(time.RFC3339)
	}
	return item, nil
}

const appealSelect = `id::text,requester_user_id::text,report_id::text,reason,COALESCE(description,''),status,resolution_reason,reviewed_by::text,reviewed_at,sla_deadline_at,notification_policy,created_at,updated_at`

func (r *safetyRepository) submitModerationAppealPostgres(ctx context.Context, userID, reportID, reason, description string) (moderationAppeal, error) {
	userID, reportID, reason = strings.TrimSpace(userID), strings.TrimSpace(reportID), strings.TrimSpace(reason)
	if userID == "" || reportID == "" || reason == "" {
		return moderationAppeal{}, errors.New("user_id, report_id, and reason are required")
	}
	tx, err := r.pg.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelReadCommitted})
	if err != nil {
		return moderationAppeal{}, err
	}
	defer func() { _ = tx.Rollback() }()
	var owns bool
	if err = tx.QueryRowContext(ctx, `SELECT EXISTS(SELECT 1 FROM matching.moderation_reports WHERE id=$1 AND reported_user_id=$2)`, reportID, userID).Scan(&owns); err != nil {
		return moderationAppeal{}, err
	}
	if !owns {
		return moderationAppeal{}, errors.New("report not found for authenticated user")
	}
	item, err := scanAppeal(tx.QueryRowContext(ctx, fmt.Sprintf(`INSERT INTO matching.moderation_appeals(report_id,requester_user_id,reason,description,status,sla_deadline_at,notification_policy) VALUES($1,$2,$3,NULLIF($4,''),'submitted',NOW()+INTERVAL '48 hours','status_change_in_app_and_configured_push') RETURNING %s`, appealSelect), reportID, userID, reason, strings.TrimSpace(description)))
	if err != nil {
		return moderationAppeal{}, err
	}
	if err = insertSecurityEventTx(ctx, tx, "moderation.appeal.submitted", userID, "user", userID, "moderation_appeal", item.ID, map[string]any{"report_id": reportID, "status": item.Status, "sla_deadline_at": item.SLADeadlineAt}); err != nil {
		return moderationAppeal{}, err
	}
	if err = tx.Commit(); err != nil {
		return moderationAppeal{}, err
	}
	return item, nil
}

func (r *safetyRepository) getModerationAppealPostgres(ctx context.Context, appealID, requesterID string, admin bool) (moderationAppeal, error) {
	query := fmt.Sprintf(`SELECT %s FROM matching.moderation_appeals WHERE id=$1 AND ($2 OR requester_user_id::text=$3)`, appealSelect)
	item, err := scanAppeal(r.pg.QueryRowContext(ctx, query, strings.TrimSpace(appealID), admin, strings.TrimSpace(requesterID)))
	if errors.Is(err, sql.ErrNoRows) {
		return moderationAppeal{}, errors.New("appeal not found")
	}
	return item, err
}

func (r *safetyRepository) listModerationAppealsPostgres(ctx context.Context, userID, status string, limit int) ([]moderationAppeal, error) {
	if limit <= 0 || limit > 500 {
		limit = 100
	}
	status = strings.ToLower(strings.TrimSpace(status))
	rows, err := r.pg.QueryContext(ctx, fmt.Sprintf(`SELECT %s FROM matching.moderation_appeals WHERE ($1='' OR requester_user_id::text=$1) AND ($2='' OR status=$2) ORDER BY created_at DESC LIMIT $3`, appealSelect), strings.TrimSpace(userID), status, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := make([]moderationAppeal, 0)
	for rows.Next() {
		item, scanErr := scanAppeal(rows)
		if scanErr != nil {
			return nil, scanErr
		}
		out = append(out, item)
	}
	return out, rows.Err()
}

func (r *safetyRepository) actionModerationAppealPostgres(ctx context.Context, appealID, status, resolutionReason, reviewedBy string) (moderationAppeal, error) {
	appealID, status, reviewedBy = strings.TrimSpace(appealID), strings.ToLower(strings.TrimSpace(status)), strings.TrimSpace(reviewedBy)
	allowed := map[string]bool{appealStatusUnderReview: true, appealStatusResolvedUpheld: true, appealStatusResolvedReverse: true}
	if appealID == "" || reviewedBy == "" || !allowed[status] {
		return moderationAppeal{}, errors.New("valid appeal_id, status, and authenticated reviewer are required")
	}
	tx, err := r.pg.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelReadCommitted})
	if err != nil {
		return moderationAppeal{}, err
	}
	defer func() { _ = tx.Rollback() }()
	var current string
	if err = tx.QueryRowContext(ctx, `SELECT status FROM matching.moderation_appeals WHERE id=$1 FOR UPDATE`, appealID).Scan(&current); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return moderationAppeal{}, errors.New("appeal not found")
		}
		return moderationAppeal{}, err
	}
	if strings.HasPrefix(current, "resolved_") {
		return moderationAppeal{}, errors.New("appeal is already resolved")
	}
	if status == appealStatusUnderReview && current != appealStatusSubmitted {
		return moderationAppeal{}, errors.New("invalid appeal transition")
	}
	if strings.HasPrefix(status, "resolved_") && current != appealStatusSubmitted && current != appealStatusUnderReview {
		return moderationAppeal{}, errors.New("invalid appeal transition")
	}
	item, err := scanAppeal(tx.QueryRowContext(ctx, fmt.Sprintf(`UPDATE matching.moderation_appeals SET status=$2,resolution_reason=NULLIF($3,''),reviewed_by=$4,reviewed_at=NOW(),claimed_at=COALESCE(claimed_at,NOW()),updated_at=NOW() WHERE id=$1 RETURNING %s`, appealSelect), appealID, status, strings.TrimSpace(resolutionReason), reviewedBy))
	if err != nil {
		return moderationAppeal{}, err
	}
	if err = insertSecurityEventTx(ctx, tx, "moderation.appeal."+status, reviewedBy, "operator", item.UserID, "moderation_appeal", item.ID, map[string]any{"previous_status": current, "status": status, "resolution_reason": item.ResolutionReason, "within_sla": time.Now().UTC().Before(mustParseTime(item.SLADeadlineAt))}); err != nil {
		return moderationAppeal{}, err
	}
	if _, err = tx.ExecContext(ctx, `SELECT matching.enqueue_notification(
		$1::uuid,$2::uuid,'moderation.appeal.status_changed','safety',$3::uuid,
		$4,'Appeal updated',$5,'/settings/moderation-appeals',
		jsonb_build_object('appeal_id',$3::text,'status',$6),9)`,
		item.UserID, reviewedBy, item.ID, "appeal-status:"+item.ID+":"+status,
		"Your appeal is now "+strings.ReplaceAll(status, "_", " ")+".", status); err != nil {
		return moderationAppeal{}, err
	}
	if err = tx.Commit(); err != nil {
		return moderationAppeal{}, err
	}
	return item, nil
}

func mustParseTime(value string) time.Time {
	parsed, _ := time.Parse(time.RFC3339, value)
	return parsed
}

func sosDeadline(level string) time.Duration {
	switch level {
	case "critical":
		return 2 * time.Minute
	case "high":
		return 5 * time.Minute
	case "medium":
		return 15 * time.Minute
	default:
		return 30 * time.Minute
	}
}

func scanSOS(scanner interface{ Scan(...any) error }) (sosAlert, error) {
	var item sosAlert
	var matchID, resolvedBy, note sql.NullString
	var resolvedAt sql.NullTime
	var created time.Time
	err := scanner.Scan(&item.ID, &item.UserID, &matchID, &item.Latitude, &item.Longitude, &item.Message, &item.EmergencyLevel, &item.Status, &created, &resolvedAt, &resolvedBy, &note)
	if err != nil {
		return sosAlert{}, err
	}
	item.MatchID, item.ResolvedBy, item.ResolutionNote = matchID.String, resolvedBy.String, note.String
	item.Status = mapSOSStatusFromDB(item.Status)
	item.TriggeredAt = created.UTC().Format(time.RFC3339)
	if resolvedAt.Valid {
		item.ResolvedAt = resolvedAt.Time.UTC().Format(time.RFC3339)
	}
	return item, nil
}

const sosSelect = `id::text,user_id::text,match_id::text,COALESCE(latitude,0),COALESCE(longitude,0),COALESCE(message,''),level,status,created_at,resolved_at,resolved_by::text,resolved_note`

func (r *safetyRepository) createSOSAlertPostgres(ctx context.Context, userID, matchID, level, message string, latitude, longitude float64) (sosAlert, error) {
	userID, level = strings.TrimSpace(userID), strings.ToLower(strings.TrimSpace(level))
	if level == "" {
		level = "high"
	}
	if userID == "" {
		return sosAlert{}, errors.New("user_id is required")
	}
	if level != "low" && level != "medium" && level != "high" && level != "critical" {
		return sosAlert{}, errors.New("invalid emergency_level")
	}
	tx, err := r.pg.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelReadCommitted})
	if err != nil {
		return sosAlert{}, err
	}
	defer func() { _ = tx.Rollback() }()
	item, err := scanSOS(tx.QueryRowContext(ctx, fmt.Sprintf(`INSERT INTO matching.sos_alerts(user_id,match_id,level,message,latitude,longitude,status,response_deadline_at) VALUES($1,NULLIF($2,'')::uuid,$3,NULLIF($4,''),$5,$6,'open',$7) RETURNING %s`, sosSelect), userID, strings.TrimSpace(matchID), level, strings.TrimSpace(message), latitude, longitude, time.Now().UTC().Add(sosDeadline(level))))
	if err != nil {
		return sosAlert{}, err
	}
	if err = insertSecurityEventTx(ctx, tx, "safety.sos.triggered", userID, "user", userID, "sos_alert", item.ID, map[string]any{"level": level}); err != nil {
		return sosAlert{}, err
	}
	// Snapshot trusted contacts in the same transaction as the alert. Contact
	// edits after the emergency must not make a committed alert silently lose
	// every delivery target.
	if _, err = tx.ExecContext(ctx, `
		INSERT INTO matching.sos_delivery_outbox(
		  alert_id,contact_id,user_id,contact_name,contact_phone,level,message,
		  latitude,longitude,response_deadline_at,status,available_at,expires_at)
		SELECT $1::uuid,c.id,c.user_id,c.name,c.phone_number,$2,NULLIF($3,''),$4,$5,$6,
		       'pending',NOW(),NOW()+INTERVAL '30 days'
		FROM user_management.emergency_contacts c
		WHERE c.user_id=$7::uuid
		ON CONFLICT(alert_id,contact_id) DO NOTHING`, item.ID, level,
		strings.TrimSpace(message), latitude, longitude,
		time.Now().UTC().Add(sosDeadline(level)), userID); err != nil {
		return sosAlert{}, err
	}
	if err = tx.Commit(); err != nil {
		return sosAlert{}, err
	}
	return item, nil
}

func (r *safetyRepository) resolveSOSAlertPostgres(ctx context.Context, alertID, resolvedBy, note string) (sosAlert, error) {
	alertID, resolvedBy = strings.TrimSpace(alertID), strings.TrimSpace(resolvedBy)
	if alertID == "" || resolvedBy == "" {
		return sosAlert{}, errors.New("alert_id and authenticated resolver are required")
	}
	tx, err := r.pg.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelReadCommitted})
	if err != nil {
		return sosAlert{}, err
	}
	defer func() { _ = tx.Rollback() }()
	var current string
	if err = tx.QueryRowContext(ctx, `SELECT status FROM matching.sos_alerts WHERE id=$1 FOR UPDATE`, alertID).Scan(&current); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return sosAlert{}, errors.New("sos alert not found")
		}
		return sosAlert{}, err
	}
	if current == "resolved" {
		return sosAlert{}, errors.New("sos alert is already resolved")
	}
	item, err := scanSOS(tx.QueryRowContext(ctx, fmt.Sprintf(`UPDATE matching.sos_alerts SET status='resolved',resolved_by=$2,resolved_note=NULLIF($3,''),resolved_at=NOW() WHERE id=$1 RETURNING %s`, sosSelect), alertID, resolvedBy, strings.TrimSpace(note)))
	if err != nil {
		return sosAlert{}, err
	}
	if err = insertSecurityEventTx(ctx, tx, "safety.sos.resolved", resolvedBy, "operator", item.UserID, "sos_alert", item.ID, map[string]any{"previous_status": current, "resolution_note": item.ResolutionNote}); err != nil {
		return sosAlert{}, err
	}
	if _, err = tx.ExecContext(ctx, `
		UPDATE matching.sos_delivery_outbox
		SET status='cancelled',last_error='alert resolved before delivery',updated_at=NOW()
		WHERE alert_id=$1::uuid AND status IN ('pending','retry')`, alertID); err != nil {
		return sosAlert{}, err
	}
	if err = tx.Commit(); err != nil {
		return sosAlert{}, err
	}
	return item, nil
}

func (r *safetyRepository) listSOSAlertsPostgres(ctx context.Context, userID string, limit int) ([]sosAlert, error) {
	if limit <= 0 || limit > 500 {
		limit = 100
	}
	rows, err := r.pg.QueryContext(ctx, fmt.Sprintf(`SELECT %s FROM matching.sos_alerts WHERE ($1='' OR user_id::text=$1) ORDER BY created_at DESC LIMIT $2`, sosSelect), strings.TrimSpace(userID), limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := make([]sosAlert, 0)
	for rows.Next() {
		item, e := scanSOS(rows)
		if e != nil {
			return nil, e
		}
		out = append(out, item)
	}
	return out, rows.Err()
}

func (r *safetyRepository) sosDeliveryMetrics(ctx context.Context) (map[string]any, error) {
	var queueDepth, processing, deadLetters, delivered, overdue, oldest int64
	err := r.pg.QueryRowContext(ctx, `
		SELECT queue_depth,processing,dead_letters,delivered,overdue,oldest_pending_age_seconds
		FROM matching.sos_delivery_metrics`).Scan(
		&queueDepth, &processing, &deadLetters, &delivered, &overdue, &oldest)
	if err != nil {
		return nil, err
	}
	return map[string]any{
		"queue_depth": queueDepth, "processing": processing, "dead_letters": deadLetters,
		"delivered": delivered, "overdue": overdue, "oldest_pending_age_seconds": oldest,
	}, nil
}

func (r *safetyRepository) blockUserPostgres(ctx context.Context, userID, blockedID, reason string) error {
	userID, blockedID = strings.TrimSpace(userID), strings.TrimSpace(blockedID)
	if userID == "" || blockedID == "" || userID == blockedID {
		return errors.New("valid distinct user_id and blocked_user_id are required")
	}
	tx, err := r.pg.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelReadCommitted})
	if err != nil {
		return err
	}
	defer func() { _ = tx.Rollback() }()
	_, err = tx.ExecContext(ctx, `INSERT INTO user_management.blocked_users(user_id,blocked_user_id,reason) VALUES($1,$2,NULLIF($3,'')) ON CONFLICT(user_id,blocked_user_id) DO UPDATE SET reason=EXCLUDED.reason,created_at=NOW()`, userID, blockedID, strings.TrimSpace(reason))
	if err != nil {
		return err
	}
	if err = insertSecurityEventTx(ctx, tx, "safety.user.blocked", userID, "user", blockedID, "blocked_user", blockedID, map[string]any{"reason": strings.TrimSpace(reason)}); err != nil {
		return err
	}
	return tx.Commit()
}

func (r *safetyRepository) unblockUserPostgres(ctx context.Context, userID, blockedID string) error {
	userID, blockedID = strings.TrimSpace(userID), strings.TrimSpace(blockedID)
	if userID == "" || blockedID == "" {
		return errors.New("user_id and blocked_user_id are required")
	}
	tx, err := r.pg.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelReadCommitted})
	if err != nil {
		return err
	}
	defer func() { _ = tx.Rollback() }()
	result, err := tx.ExecContext(ctx, `DELETE FROM user_management.blocked_users WHERE user_id=$1 AND blocked_user_id=$2`, userID, blockedID)
	if err != nil {
		return err
	}
	affected, _ := result.RowsAffected()
	if affected == 0 {
		return errors.New("block not found")
	}
	if err = insertSecurityEventTx(ctx, tx, "safety.user.unblocked", userID, "user", blockedID, "blocked_user", blockedID, map[string]any{}); err != nil {
		return err
	}
	return tx.Commit()
}
