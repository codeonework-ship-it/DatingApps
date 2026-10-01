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

type notificationRecord struct {
	ID          string         `json:"id"`
	Sequence    int64          `json:"sequence"`
	EventType   string         `json:"event_type"`
	Category    string         `json:"category"`
	ActorUserID string         `json:"actor_user_id,omitempty"`
	ReferenceID string         `json:"reference_id,omitempty"`
	Title       string         `json:"title"`
	Body        string         `json:"body"`
	ActionRoute string         `json:"action_route,omitempty"`
	Payload     map[string]any `json:"payload"`
	IsRead      bool           `json:"is_read"`
	ReadAt      string         `json:"read_at,omitempty"`
	CreatedAt   string         `json:"created_at"`
}

type notificationPreferences struct {
	NotifyNewMatch      bool `json:"notify_new_match"`
	NotifyNewMessage    bool `json:"notify_new_message"`
	NotifyLikes         bool `json:"notify_likes"`
	NotifyMatchNudges   bool `json:"notify_match_nudges"`
	NotifyIncomingCalls bool `json:"notify_incoming_calls"`
	NotifySafety        bool `json:"notify_safety"`
	NotifyFriendPlans   bool `json:"notify_friend_plans"`
	InAppNotifications  bool `json:"in_app_notifications_enabled"`
	PushNotifications   bool `json:"push_notifications_enabled"`
}

type notificationOutboxJob struct {
	ID              string
	Sequence        int64
	RecipientUserID string
	ActorUserID     string
	EventType       string
	Category        string
	ReferenceID     string
	Title           string
	Body            string
	ActionRoute     string
	Payload         map[string]any
	AttemptCount    int
	MaxAttempts     int
}

type notificationDevice struct {
	ID       string
	Provider string
	Platform string
	Token    string
}

type notificationRepository struct {
	db *sql.DB
}

func newNotificationRepository(db *sql.DB) *notificationRepository {
	if db == nil {
		return nil
	}
	return &notificationRepository{db: db}
}

func (r *notificationRepository) list(ctx context.Context, userID string, after int64, limit int) ([]notificationRecord, error) {
	if r == nil || r.db == nil {
		return nil, errors.New("notification persistence is unavailable")
	}
	if limit <= 0 || limit > 200 {
		limit = 50
	}
	rows, err := r.db.QueryContext(ctx, `
		SELECT id::text, sequence_id, event_type, category,
		       COALESCE(actor_user_id::text, ''), COALESCE(reference_id::text, ''),
		       title, body, COALESCE(action_route, ''), payload, is_read, read_at, created_at
		FROM matching.user_notifications
		WHERE recipient_user_id=$1 AND sequence_id>$2 AND dismissed_at IS NULL
		ORDER BY sequence_id
		LIMIT $3`, strings.TrimSpace(userID), after, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	records := make([]notificationRecord, 0, limit)
	for rows.Next() {
		var item notificationRecord
		var payload []byte
		var readAt sql.NullTime
		var createdAt time.Time
		if err := rows.Scan(&item.ID, &item.Sequence, &item.EventType, &item.Category,
			&item.ActorUserID, &item.ReferenceID, &item.Title, &item.Body,
			&item.ActionRoute, &payload, &item.IsRead, &readAt, &createdAt); err != nil {
			return nil, err
		}
		if err := json.Unmarshal(payload, &item.Payload); err != nil {
			return nil, err
		}
		if item.Payload == nil {
			item.Payload = map[string]any{}
		}
		if readAt.Valid {
			item.ReadAt = readAt.Time.UTC().Format(time.RFC3339Nano)
		}
		item.CreatedAt = createdAt.UTC().Format(time.RFC3339Nano)
		records = append(records, item)
	}
	return records, rows.Err()
}

func (r *notificationRepository) unreadCount(ctx context.Context, userID string) (int, error) {
	var count int
	err := r.db.QueryRowContext(ctx, `
		SELECT COUNT(*) FROM matching.user_notifications
		WHERE recipient_user_id=$1 AND NOT is_read AND dismissed_at IS NULL`, strings.TrimSpace(userID)).Scan(&count)
	return count, err
}

func (r *notificationRepository) markRead(ctx context.Context, userID, notificationID string) (bool, error) {
	result, err := r.db.ExecContext(ctx, `
		UPDATE matching.user_notifications SET is_read=TRUE, read_at=COALESCE(read_at, NOW())
		WHERE id=$1 AND recipient_user_id=$2 AND dismissed_at IS NULL`, notificationID, strings.TrimSpace(userID))
	if err != nil {
		return false, err
	}
	affected, err := result.RowsAffected()
	return affected > 0, err
}

func (r *notificationRepository) markAllRead(ctx context.Context, userID string) (int64, error) {
	result, err := r.db.ExecContext(ctx, `
		UPDATE matching.user_notifications SET is_read=TRUE, read_at=COALESCE(read_at, NOW())
		WHERE recipient_user_id=$1 AND NOT is_read AND dismissed_at IS NULL`, strings.TrimSpace(userID))
	if err != nil {
		return 0, err
	}
	return result.RowsAffected()
}

func (r *notificationRepository) dismiss(ctx context.Context, userID, notificationID string) (bool, error) {
	result, err := r.db.ExecContext(ctx, `
		UPDATE matching.user_notifications SET dismissed_at=COALESCE(dismissed_at, NOW())
		WHERE id=$1 AND recipient_user_id=$2`, notificationID, strings.TrimSpace(userID))
	if err != nil {
		return false, err
	}
	affected, err := result.RowsAffected()
	return affected > 0, err
}

func (r *notificationRepository) getPreferences(ctx context.Context, userID string) (notificationPreferences, error) {
	if _, err := r.db.ExecContext(ctx, `
		INSERT INTO user_management.user_settings (user_id) VALUES ($1)
		ON CONFLICT (user_id) DO NOTHING`, strings.TrimSpace(userID)); err != nil {
		return notificationPreferences{}, err
	}
	var prefs notificationPreferences
	err := r.db.QueryRowContext(ctx, `
		SELECT notify_new_match, notify_new_message, notify_likes, notify_match_nudges,
		       notify_incoming_calls, notify_safety, COALESCE(notify_friend_plans, TRUE), in_app_notifications_enabled,
		       push_notifications_enabled
		FROM user_management.user_settings WHERE user_id=$1`, strings.TrimSpace(userID)).Scan(
		&prefs.NotifyNewMatch, &prefs.NotifyNewMessage, &prefs.NotifyLikes, &prefs.NotifyMatchNudges,
		&prefs.NotifyIncomingCalls, &prefs.NotifySafety, &prefs.NotifyFriendPlans, &prefs.InAppNotifications, &prefs.PushNotifications,
	)
	return prefs, err
}

func (r *notificationRepository) updatePreferences(ctx context.Context, userID string, patch map[string]any) (notificationPreferences, error) {
	allowed := map[string]bool{
		"notify_new_match": true, "notify_new_message": true, "notify_likes": true,
		"notify_match_nudges": true, "notify_incoming_calls": true, "notify_safety": true,
		"notify_friend_plans":          true,
		"in_app_notifications_enabled": true, "push_notifications_enabled": true,
	}
	sets := make([]string, 0, len(patch))
	args := []any{strings.TrimSpace(userID)}
	for _, key := range []string{"notify_new_match", "notify_new_message", "notify_likes", "notify_match_nudges", "notify_incoming_calls", "notify_safety", "notify_friend_plans", "in_app_notifications_enabled", "push_notifications_enabled"} {
		value, exists := patch[key]
		if !exists {
			continue
		}
		if !allowed[key] {
			continue
		}
		boolean, ok := value.(bool)
		if !ok {
			return notificationPreferences{}, fmt.Errorf("%s must be a boolean", key)
		}
		args = append(args, boolean)
		sets = append(sets, fmt.Sprintf("%s=$%d", key, len(args)))
	}
	if len(sets) == 0 {
		return r.getPreferences(ctx, userID)
	}
	if _, err := r.db.ExecContext(ctx, `INSERT INTO user_management.user_settings (user_id) VALUES ($1) ON CONFLICT (user_id) DO NOTHING`, args[0]); err != nil {
		return notificationPreferences{}, err
	}
	query := `UPDATE user_management.user_settings SET ` + strings.Join(sets, ", ") + `, lock_version=lock_version+1, updated_at=NOW() WHERE user_id=$1`
	if _, err := r.db.ExecContext(ctx, query, args...); err != nil {
		return notificationPreferences{}, err
	}
	return r.getPreferences(ctx, userID)
}

func (r *notificationRepository) registerDevice(ctx context.Context, userID, provider, platform, token string) (string, error) {
	provider = strings.ToLower(strings.TrimSpace(provider))
	platform = strings.ToLower(strings.TrimSpace(platform))
	token = strings.TrimSpace(token)
	if token == "" || len(token) > 4096 || !map[string]bool{"fcm": true, "apns": true, "webhook": true}[provider] || !map[string]bool{"android": true, "ios": true, "web": true}[platform] {
		return "", errors.New("valid provider, platform and token are required")
	}
	if provider == "apns" && platform != "ios" {
		return "", errors.New("APNs tokens require the iOS platform")
	}
	var id string
	err := r.db.QueryRowContext(ctx, `
		INSERT INTO user_management.device_push_tokens (user_id, provider, platform, token)
		VALUES ($1,$2,$3,$4)
		ON CONFLICT (provider, token) DO UPDATE SET
		  user_id=EXCLUDED.user_id, platform=EXCLUDED.platform, enabled=TRUE,
		  failure_count=0, disabled_reason=NULL, last_seen_at=NOW(), updated_at=NOW()
		RETURNING id::text`, strings.TrimSpace(userID), provider, platform, token).Scan(&id)
	return id, err
}

func (r *notificationRepository) unregisterDevice(ctx context.Context, userID, deviceID string) (bool, error) {
	result, err := r.db.ExecContext(ctx, `
		UPDATE user_management.device_push_tokens
		SET enabled=FALSE, disabled_reason='user_unregistered', updated_at=NOW()
		WHERE id=$1 AND user_id=$2`, strings.TrimSpace(deviceID), strings.TrimSpace(userID))
	if err != nil {
		return false, err
	}
	affected, err := result.RowsAffected()
	return affected > 0, err
}

func (r *notificationRepository) claim(ctx context.Context, workerID string, limit, maxAttempts int) ([]notificationOutboxJob, error) {
	if limit <= 0 || limit > 200 {
		limit = 50
	}
	if maxAttempts <= 0 || maxAttempts > 20 {
		maxAttempts = 5
	}
	if _, err := r.db.ExecContext(ctx, `
		UPDATE matching.notification_outbox
		SET status='suppressed', processed_at=NOW(), last_error='notification expired', updated_at=NOW()
		WHERE status IN ('pending','retry') AND expires_at<=NOW()`); err != nil {
		return nil, err
	}
	rows, err := r.db.QueryContext(ctx, `
		WITH candidates AS (
		  SELECT id FROM matching.notification_outbox
		  WHERE status IN ('pending','retry') AND available_at<=NOW() AND expires_at>NOW()
		  ORDER BY priority DESC, available_at, sequence_id
		  FOR UPDATE SKIP LOCKED LIMIT $1
		)
		UPDATE matching.notification_outbox o
		SET status='processing', locked_at=NOW(), worker_id=$2,
		    attempt_count=o.attempt_count+1, max_attempts=$3, updated_at=NOW()
		FROM candidates c WHERE o.id=c.id
		RETURNING o.id::text, o.sequence_id, o.recipient_user_id::text,
		  COALESCE(o.actor_user_id::text,''), o.event_type, o.category,
		  COALESCE(o.reference_id::text,''), o.title, o.body, COALESCE(o.action_route,''),
		  o.payload, o.attempt_count, o.max_attempts`, limit, workerID, maxAttempts)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	jobs := make([]notificationOutboxJob, 0, limit)
	for rows.Next() {
		var job notificationOutboxJob
		var payload []byte
		if err := rows.Scan(&job.ID, &job.Sequence, &job.RecipientUserID, &job.ActorUserID,
			&job.EventType, &job.Category, &job.ReferenceID, &job.Title, &job.Body,
			&job.ActionRoute, &payload, &job.AttemptCount, &job.MaxAttempts); err != nil {
			return nil, err
		}
		if err := json.Unmarshal(payload, &job.Payload); err != nil {
			return nil, err
		}
		jobs = append(jobs, job)
	}
	return jobs, rows.Err()
}

func (r *notificationRepository) recoverStale(ctx context.Context) error {
	_, err := r.db.ExecContext(ctx, `
		UPDATE matching.notification_outbox
		SET status='retry', available_at=NOW(), locked_at=NULL, worker_id=NULL,
		    last_error='recovered stale processing lease', updated_at=NOW()
		WHERE status='processing' AND locked_at < NOW()-INTERVAL '2 minutes'`)
	return err
}

func (r *notificationRepository) recipientPolicy(ctx context.Context, userID, category string) (bool, bool, error) {
	var active, inApp, push bool
	var categoryEnabled bool
	err := r.db.QueryRowContext(ctx, `
		SELECT u.is_active AND NOT u.is_banned
		       AND (u.suspended_at IS NULL OR (u.suspended_until IS NOT NULL AND u.suspended_until<=NOW())),
		       COALESCE(s.in_app_notifications_enabled, TRUE),
		       COALESCE(s.push_notifications_enabled, TRUE),
		       CASE $2
		         WHEN 'match' THEN COALESCE(s.notify_new_match, TRUE)
		         WHEN 'message' THEN COALESCE(s.notify_new_message, TRUE)
		         WHEN 'like' THEN COALESCE(s.notify_likes, TRUE)
		         WHEN 'nudge' THEN COALESCE(s.notify_match_nudges, TRUE)
		         WHEN 'call' THEN COALESCE(s.notify_incoming_calls, TRUE)
		         WHEN 'safety' THEN COALESCE(s.notify_safety, TRUE)
		         WHEN 'friend_plan' THEN COALESCE(s.notify_friend_plans, TRUE)
		         ELSE TRUE END
		FROM user_management.users u
		LEFT JOIN user_management.user_settings s ON s.user_id=u.id
		WHERE u.id=$1`, userID, category).Scan(&active, &inApp, &push, &categoryEnabled)
	if err != nil {
		return false, false, err
	}
	if !active || !categoryEnabled {
		return false, false, nil
	}
	return inApp, push, nil
}

func (r *notificationRepository) createInApp(ctx context.Context, job notificationOutboxJob) error {
	payload, err := json.Marshal(job.Payload)
	if err != nil {
		return err
	}
	tx, err := r.db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelReadCommitted})
	if err != nil {
		return err
	}
	defer func() { _ = tx.Rollback() }()
	if strings.HasPrefix(job.EventType, "date_plan.") {
		if actor, shared := job.Payload["friend_user_id"]; shared {
			// Serialize in-app creation with consent withdrawal, so a claimed job
			// cannot recreate a notification after the sharing transaction deletes it.
			var id string
			if err := tx.QueryRowContext(ctx, `SELECT id::text FROM matching.match_date_plans WHERE id=$1::uuid FOR SHARE`, job.ReferenceID).Scan(&id); err != nil {
				return err
			}
			var allowed bool
			if err := tx.QueryRowContext(ctx, `SELECT EXISTS(SELECT 1 FROM matching.match_date_plans p CROSS JOIN LATERAL
          matching.date_plan_trusted_recipients(p.id,$2::uuid,CASE WHEN p.proposer_user_id=$2::uuid THEN p.invitee_user_id ELSE p.proposer_user_id END) r
          WHERE p.id=$1::uuid AND r.recipient_user_id=$3::uuid)`, job.ReferenceID, actor, job.RecipientUserID).Scan(&allowed); err != nil {
				return err
			}
			if !allowed {
				return errPlanSharingRevoked
			}
		}
	}
	_, err = tx.ExecContext(ctx, `
		INSERT INTO matching.user_notifications (
		  outbox_id, sequence_id, recipient_user_id, actor_user_id, event_type, category,
		  reference_id, title, body, action_route, payload, created_at
		) VALUES ($1,$2,$3,NULLIF($4,'')::uuid,$5,$6,NULLIF($7,'')::uuid,$8,$9,NULLIF($10,''),$11::jsonb,NOW())
		ON CONFLICT (outbox_id) DO NOTHING`, job.ID, job.Sequence, job.RecipientUserID,
		job.ActorUserID, job.EventType, job.Category, job.ReferenceID, job.Title, job.Body,
		job.ActionRoute, payload)
	if err != nil {
		return err
	}
	_, err = tx.ExecContext(ctx, `
		INSERT INTO matching.notification_deliveries (outbox_id, channel, status, delivered_at)
		VALUES ($1,'in_app','delivered',NOW())
		ON CONFLICT (outbox_id, channel) WHERE channel='in_app'
		DO UPDATE SET status='delivered', delivered_at=COALESCE(matching.notification_deliveries.delivered_at,NOW()), updated_at=NOW()`, job.ID)
	if err != nil {
		return err
	}
	return tx.Commit()
}

func (r *notificationRepository) devices(ctx context.Context, userID string) ([]notificationDevice, error) {
	rows, err := r.db.QueryContext(ctx, `
		SELECT id::text, provider, platform, token FROM user_management.device_push_tokens
		WHERE user_id=$1 AND enabled ORDER BY created_at`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var devices []notificationDevice
	for rows.Next() {
		var device notificationDevice
		if err := rows.Scan(&device.ID, &device.Provider, &device.Platform, &device.Token); err != nil {
			return nil, err
		}
		devices = append(devices, device)
	}
	return devices, rows.Err()
}

func (r *notificationRepository) recordPush(ctx context.Context, jobID string, device notificationDevice, status, messageID, detail string) error {
	deliveredAt := "NULL"
	if status == "delivered" {
		deliveredAt = "NOW()"
	}
	query := `INSERT INTO matching.notification_deliveries
		(outbox_id, channel, device_token_id, status, provider_message_id, last_error, delivered_at)
		VALUES ($1,'push',$2,$3,NULLIF($4,''),NULLIF($5,''),` + deliveredAt + `)
		ON CONFLICT (outbox_id, channel, device_token_id) WHERE channel='push'
		DO UPDATE SET status=EXCLUDED.status, provider_message_id=EXCLUDED.provider_message_id,
		  last_error=EXCLUDED.last_error, delivered_at=EXCLUDED.delivered_at,
		  attempt_count=matching.notification_deliveries.attempt_count+1, updated_at=NOW()`
	_, err := r.db.ExecContext(ctx, query, jobID, device.ID, status, messageID, detail)
	return err
}

func (r *notificationRepository) disableDevice(ctx context.Context, deviceID, reason string) error {
	_, err := r.db.ExecContext(ctx, `
		UPDATE user_management.device_push_tokens SET enabled=FALSE,
		failure_count=failure_count+1, disabled_reason=$2, updated_at=NOW() WHERE id=$1`, deviceID, reason)
	return err
}

func (r *notificationRepository) finish(ctx context.Context, job notificationOutboxJob, delivered bool, retryErr error) error {
	status := "suppressed"
	processed := true
	availableAt := time.Now().UTC()
	lastError := ""
	if delivered {
		status = "delivered"
	}
	if retryErr != nil {
		lastError = retryErr.Error()
		if job.AttemptCount >= job.MaxAttempts {
			status = "dead_letter"
		} else {
			status = "retry"
			processed = false
			delay := time.Duration(job.AttemptCount*job.AttemptCount) * time.Second
			if delay > 5*time.Minute {
				delay = 5 * time.Minute
			}
			availableAt = time.Now().UTC().Add(delay)
		}
	}
	_, err := r.db.ExecContext(ctx, `
		UPDATE matching.notification_outbox SET status=$2, available_at=$3,
		  locked_at=NULL, worker_id=NULL, last_error=NULLIF($4,''),
		  processed_at=CASE WHEN $5 THEN NOW() ELSE NULL END, updated_at=NOW()
		WHERE id=$1`, job.ID, status, availableAt, lastError, processed)
	return err
}

func (r *notificationRepository) queueMetrics(ctx context.Context) (map[string]any, error) {
	metrics := map[string]any{}
	var depth, processing, deadLetter, delivered, oldest int64
	var pushAttempts, pushDelivered, pushDeadLetter int64
	var pushSuccessPercent, pushP95LatencyMS float64
	err := r.db.QueryRowContext(ctx, `
		SELECT queue_depth, processing, dead_letter, delivered, oldest_pending_age_seconds,
		       push_attempts_15m, push_delivered_15m, push_dead_letter_15m,
		       push_success_percent_15m, push_p95_latency_ms_15m
		FROM matching.notification_queue_metrics`).Scan(
		&depth, &processing, &deadLetter, &delivered, &oldest,
		&pushAttempts, &pushDelivered, &pushDeadLetter, &pushSuccessPercent, &pushP95LatencyMS,
	)
	if err != nil {
		return nil, err
	}
	metrics["queue_depth"] = depth
	metrics["processing"] = processing
	metrics["dead_letter"] = deadLetter
	metrics["delivered"] = delivered
	metrics["oldest_pending_age_seconds"] = oldest
	metrics["push_attempts_15m"] = pushAttempts
	metrics["push_delivered_15m"] = pushDelivered
	metrics["push_dead_letter_15m"] = pushDeadLetter
	metrics["push_success_percent_15m"] = pushSuccessPercent
	metrics["push_p95_latency_ms_15m"] = pushP95LatencyMS
	return metrics, nil
}

// Recheck per-plan consent after claiming work, including retries and device delivery.
func (r *notificationRepository) planSharingAllowed(ctx context.Context, job notificationOutboxJob) (bool, error) {
	if !strings.HasPrefix(job.EventType, "date_plan.") {
		return true, nil
	}
	actor, shared := job.Payload["friend_user_id"]
	if !shared {
		return true, nil
	}
	var allowed bool
	err := r.db.QueryRowContext(ctx, `SELECT EXISTS(SELECT 1 FROM matching.match_date_plans p
 CROSS JOIN LATERAL matching.date_plan_trusted_recipients(p.id,$2::uuid,
 CASE WHEN p.proposer_user_id=$2::uuid THEN p.invitee_user_id ELSE p.proposer_user_id END) r
 WHERE p.id=$1::uuid AND r.recipient_user_id=$3::uuid)`, job.ReferenceID, actor, job.RecipientUserID).Scan(&allowed)
	return allowed, err
}

var errPlanSharingRevoked = errors.New("date plan contact consent was withdrawn")
