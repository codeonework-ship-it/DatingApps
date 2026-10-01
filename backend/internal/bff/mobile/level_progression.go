package mobile

import (
	"context"
	"crypto/sha256"
	"database/sql"
	"encoding/hex"
	"encoding/json"
	"errors"
	"math"
	"net/http"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgconn"
	"go.uber.org/zap"

	"github.com/verified-dating/backend/internal/platform/observability"
)

var (
	errProgressionFrozen = errors.New("level progression is frozen by safety controls")
	errXPCapReached      = errors.New("XP cap or cooldown reached")
)

type levelProgressionRepository struct{ db *sql.DB }

type xpAwardInput struct {
	UserID, Source, SourceEventID, IdempotencyKey string
	BaseXPOverride                                int
	ActorType, ActorID                            string
	Metadata                                      map[string]any
}

type xpAwardRepairPayload struct {
	UserID         string         `json:"user_id"`
	Source         string         `json:"source"`
	SourceEventID  string         `json:"source_event_id,omitempty"`
	IdempotencyKey string         `json:"idempotency_key"`
	BaseXPOverride int            `json:"base_xp_override,omitempty"`
	ActorType      string         `json:"actor_type,omitempty"`
	ActorID        string         `json:"actor_id,omitempty"`
	Metadata       map[string]any `json:"metadata,omitempty"`
}

func newXPAwardRepairPayload(input xpAwardInput) xpAwardRepairPayload {
	return xpAwardRepairPayload{
		UserID: input.UserID, Source: input.Source, SourceEventID: input.SourceEventID,
		IdempotencyKey: input.IdempotencyKey, BaseXPOverride: input.BaseXPOverride,
		ActorType: input.ActorType, ActorID: input.ActorID, Metadata: input.Metadata,
	}
}

func (p xpAwardRepairPayload) awardInput() xpAwardInput {
	return xpAwardInput{
		UserID: p.UserID, Source: p.Source, SourceEventID: p.SourceEventID,
		IdempotencyKey: p.IdempotencyKey, BaseXPOverride: p.BaseXPOverride,
		ActorType: p.ActorType, ActorID: p.ActorID, Metadata: p.Metadata,
	}
}

type xpAwardResult struct {
	EventID      string  `json:"event_id"`
	Sequence     int64   `json:"sequence"`
	Source       string  `json:"source"`
	BaseXP       int     `json:"base_xp"`
	Multiplier   float64 `json:"multiplier"`
	AwardedXP    int     `json:"awarded_xp"`
	Projection   string  `json:"projection_status"`
	WasDuplicate bool    `json:"was_duplicate"`
}

func newLevelProgressionRepository(db *sql.DB) *levelProgressionRepository {
	if db == nil {
		return nil
	}
	return &levelProgressionRepository{db: db}
}

func progressionRequestHash(input xpAwardInput) string {
	payload, _ := json.Marshal(map[string]any{
		"user_id": input.UserID, "source": input.Source, "source_event_id": input.SourceEventID,
		"base_xp_override": input.BaseXPOverride, "actor_type": input.ActorType,
		"actor_id": input.ActorID, "metadata": input.Metadata,
	})
	sum := sha256.Sum256(payload)
	return hex.EncodeToString(sum[:])
}

func parseNumericArray(raw string) []float64 {
	raw = strings.Trim(raw, "{}")
	if raw == "" {
		return []float64{1}
	}
	parts := strings.Split(raw, ",")
	values := make([]float64, 0, len(parts))
	for _, part := range parts {
		if value, err := strconv.ParseFloat(strings.TrimSpace(part), 64); err == nil {
			values = append(values, value)
		}
	}
	if len(values) == 0 {
		return []float64{1}
	}
	return values
}

func (r *levelProgressionRepository) awardXP(ctx context.Context, input xpAwardInput) (xpAwardResult, error) {
	input.UserID = strings.TrimSpace(input.UserID)
	input.Source = strings.TrimSpace(input.Source)
	input.SourceEventID = strings.TrimSpace(input.SourceEventID)
	input.IdempotencyKey = strings.TrimSpace(input.IdempotencyKey)
	if input.UserID == "" || input.Source == "" || input.IdempotencyKey == "" {
		return xpAwardResult{}, errors.New("user, source, and idempotency key are required")
	}
	if input.ActorType == "" {
		input.ActorType = "system"
	}
	requestHash := progressionRequestHash(input)
	tx, err := r.db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelReadCommitted})
	if err != nil {
		return xpAwardResult{}, err
	}
	defer func() { _ = tx.Rollback() }()
	if _, err = tx.ExecContext(ctx, `SELECT pg_advisory_xact_lock(hashtext('progression:' || $1))`, input.UserID); err != nil {
		return xpAwardResult{}, err
	}

	var duplicate xpAwardResult
	var storedHash string
	err = tx.QueryRowContext(ctx, `
		SELECT event_id::text,sequence_id,source,base_xp,
		       (quality_multiplier*experiment_multiplier)::DOUBLE PRECISION,awarded_xp,request_hash
		FROM progression.xp_ledger WHERE user_id=$1 AND idempotency_key=$2`,
		input.UserID, input.IdempotencyKey,
	).Scan(&duplicate.EventID, &duplicate.Sequence, &duplicate.Source, &duplicate.BaseXP,
		&duplicate.Multiplier, &duplicate.AwardedXP, &storedHash)
	if err == nil {
		if storedHash != requestHash {
			return xpAwardResult{}, errIdempotencyPayloadConflict
		}
		duplicate.Projection, duplicate.WasDuplicate = "queued", true
		return duplicate, tx.Commit()
	}
	if !errors.Is(err, sql.ErrNoRows) {
		return xpAwardResult{}, err
	}
	if input.SourceEventID != "" {
		err = tx.QueryRowContext(ctx, `
			SELECT event_id::text,sequence_id,source,base_xp,
			       (quality_multiplier*experiment_multiplier)::DOUBLE PRECISION,awarded_xp
			FROM progression.xp_ledger
			WHERE user_id=$1 AND source=$2 AND source_event_id=$3`,
			input.UserID, input.Source, input.SourceEventID,
		).Scan(&duplicate.EventID, &duplicate.Sequence, &duplicate.Source, &duplicate.BaseXP,
			&duplicate.Multiplier, &duplicate.AwardedXP)
		if err == nil {
			duplicate.Projection, duplicate.WasDuplicate = "queued", true
			return duplicate, tx.Commit()
		}
		if !errors.Is(err, sql.ErrNoRows) {
			return xpAwardResult{}, err
		}
	}

	var baseXP, sourceDailyCap, sourceEventCap, cooldown int
	var decayRaw string
	var enabled bool
	err = tx.QueryRowContext(ctx, `
		SELECT base_xp,daily_xp_cap,daily_event_cap,cooldown_seconds,decay_multipliers::TEXT,enabled
		FROM progression.xp_source_policies WHERE source=$1`, input.Source,
	).Scan(&baseXP, &sourceDailyCap, &sourceEventCap, &cooldown, &decayRaw, &enabled)
	if err != nil || !enabled {
		return xpAwardResult{}, errors.New("XP source is disabled or unknown")
	}
	if input.Source == "admin_adjustment" && input.BaseXPOverride != 0 {
		baseXP = input.BaseXPOverride
	}

	var active, banned, suspended, verified bool
	err = tx.QueryRowContext(ctx, `
		SELECT is_active,COALESCE(is_banned,FALSE),
		       COALESCE(suspended_at IS NOT NULL AND (suspended_until IS NULL OR suspended_until>NOW()),FALSE),
		       COALESCE(is_verified,FALSE)
		FROM user_management.users WHERE id=$1`, input.UserID,
	).Scan(&active, &banned, &suspended, &verified)
	if err != nil {
		return xpAwardResult{}, err
	}
	var frozen bool
	var riskMultiplier float64
	err = tx.QueryRowContext(ctx, `
		SELECT COALESCE(progression_frozen,FALSE),COALESCE(risk_multiplier,1)::DOUBLE PRECISION
		FROM progression.account_controls
		WHERE user_id=$1 AND (expires_at IS NULL OR expires_at>NOW())`, input.UserID,
	).Scan(&frozen, &riskMultiplier)
	if errors.Is(err, sql.ErrNoRows) {
		frozen, riskMultiplier, err = false, 1, nil
	}
	if err != nil {
		return xpAwardResult{}, err
	}
	if !active || banned || suspended || frozen {
		_, _ = tx.ExecContext(ctx, `INSERT INTO progression.telemetry_events(user_id,event_name,properties)
			VALUES ($1,'level_progress_blocked_safety',jsonb_build_object('source',$2::TEXT))`, input.UserID, input.Source)
		if err = tx.Commit(); err != nil {
			return xpAwardResult{}, err
		}
		return xpAwardResult{}, errProgressionFrozen
	}

	var sourceCount, sourceXP, totalXP int
	var lastOccurred sql.NullTime
	err = tx.QueryRowContext(ctx, `
		SELECT COUNT(*) FILTER (WHERE source=$2),
		       COALESCE(SUM(awarded_xp) FILTER (WHERE source=$2),0),
		       COALESCE(SUM(awarded_xp) FILTER (WHERE source<>'admin_adjustment'),0),
		       MAX(occurred_at) FILTER (WHERE source=$2)
		FROM progression.xp_ledger WHERE user_id=$1 AND event_date=CURRENT_DATE`,
		input.UserID, input.Source,
	).Scan(&sourceCount, &sourceXP, &totalXP, &lastOccurred)
	if err != nil {
		return xpAwardResult{}, err
	}
	if sourceCount >= sourceEventCap || (input.Source != "admin_adjustment" &&
		(sourceXP >= sourceDailyCap || totalXP >= 300 ||
			(lastOccurred.Valid && cooldown > 0 && time.Since(lastOccurred.Time) < time.Duration(cooldown)*time.Second))) {
		_, _ = tx.ExecContext(ctx, `INSERT INTO progression.telemetry_events(user_id,event_name,properties)
			VALUES ($1,'xp_cap_reached',jsonb_build_object('source',$2::TEXT,'daily_xp',$3::INTEGER))`, input.UserID, input.Source, totalXP)
		threshold, windowSeconds, severity := 4, 86400, "medium"
		policyErr := tx.QueryRowContext(ctx, `SELECT rejected_attempt_threshold,window_seconds,severity
			FROM progression.fraud_rule_policies
			WHERE rule_code='repeated_source_cap' AND enabled`).Scan(&threshold, &windowSeconds, &severity)
		if policyErr != nil && !errors.Is(policyErr, sql.ErrNoRows) {
			return xpAwardResult{}, policyErr
		}
		var rejectedAttempts int
		_ = tx.QueryRowContext(ctx, `SELECT COUNT(*) FROM progression.telemetry_events
			WHERE user_id=$1 AND event_name='xp_cap_reached'
			AND occurred_at>=NOW()-make_interval(secs=>$3)
			AND properties->>'source'=$2`, input.UserID, input.Source, windowSeconds).Scan(&rejectedAttempts)
		if rejectedAttempts >= threshold {
			_, _ = tx.ExecContext(ctx, `INSERT INTO progression.fraud_cases(user_id,rule_code,severity,evidence)
				VALUES ($1,'repeated_source_cap',$4,jsonb_build_object('source',$2::TEXT,'rejected_attempts',$3::INTEGER,'threshold',$5::INTEGER,'window_seconds',$6::INTEGER))
				ON CONFLICT (user_id,rule_code) WHERE status IN ('open','reviewing')
				DO UPDATE SET severity=EXCLUDED.severity,evidence=EXCLUDED.evidence,updated_at=NOW()`, input.UserID, input.Source, rejectedAttempts, severity, threshold, windowSeconds)
		}
		if err = tx.Commit(); err != nil {
			return xpAwardResult{}, err
		}
		return xpAwardResult{}, errXPCapReached
	}

	qualityMultiplier, experimentMultiplier, decayMultiplier := riskMultiplier, 1.0, 1.0
	if input.Source == "admin_adjustment" {
		// Audited operator corrections must be exact and are intentionally not
		// affected by experiments, trust multipliers, decay, or the user cap.
		qualityMultiplier = 1
	} else {
		if verified {
			qualityMultiplier *= 1.10
		}
		qualityMultiplier = math.Max(0.5, math.Min(1.25, qualityMultiplier))
		experimentMultiplier, err = progressionExperimentMultiplier(ctx, tx, input.UserID, input.Source)
		if err != nil {
			return xpAwardResult{}, err
		}
		decay := parseNumericArray(decayRaw)
		decayMultiplier = decay[min(sourceCount, len(decay)-1)]
	}
	awarded := int(math.Round(float64(baseXP) * qualityMultiplier * experimentMultiplier * decayMultiplier))
	if baseXP >= 0 && input.Source != "admin_adjustment" {
		awarded = min(awarded, sourceDailyCap-sourceXP, 300-totalXP)
	}
	if awarded == 0 {
		return xpAwardResult{}, errXPCapReached
	}

	metadata, _ := json.Marshal(input.Metadata)
	var result xpAwardResult
	err = tx.QueryRowContext(ctx, `
		INSERT INTO progression.xp_ledger
		  (user_id,source,source_event_id,idempotency_key,request_hash,base_xp,
		   quality_multiplier,experiment_multiplier,awarded_xp,metadata,actor_type,actor_id)
		VALUES ($1,$2,NULLIF($3,''),$4,$5,$6,$7,$8,$9,$10,$11,NULLIF($12,'')::UUID)
		RETURNING event_id::TEXT,sequence_id,source,base_xp,
		          (quality_multiplier*experiment_multiplier)::DOUBLE PRECISION,awarded_xp`,
		input.UserID, input.Source, input.SourceEventID, input.IdempotencyKey, requestHash,
		baseXP, qualityMultiplier, experimentMultiplier, awarded, metadata, input.ActorType, input.ActorID,
	).Scan(&result.EventID, &result.Sequence, &result.Source, &result.BaseXP, &result.Multiplier, &result.AwardedXP)
	if err != nil {
		return xpAwardResult{}, err
	}
	_, err = tx.ExecContext(ctx, `INSERT INTO progression.projection_outbox(ledger_sequence,user_id)
		VALUES ($1,$2)`, result.Sequence, input.UserID)
	if err != nil {
		return xpAwardResult{}, err
	}
	_, err = tx.ExecContext(ctx, `INSERT INTO progression.telemetry_events(user_id,event_name,properties)
		VALUES ($1,'level_xp_earned',jsonb_build_object('ledger_sequence',$2::BIGINT,'source',$3::TEXT,'awarded_xp',$4::INTEGER))`,
		input.UserID, result.Sequence, input.Source, awarded)
	if err != nil {
		return xpAwardResult{}, err
	}
	result.Projection = "queued"
	return result, tx.Commit()
}

func (r *levelProgressionRepository) enqueueAwardRepair(ctx context.Context, input xpAwardInput, cause error) error {
	payload, err := json.Marshal(newXPAwardRepairPayload(input))
	if err != nil {
		return err
	}
	lastError := "XP award failed"
	if cause != nil {
		lastError = cause.Error()
	}
	_, err = r.db.ExecContext(ctx, `
		INSERT INTO progression.xp_award_repair_queue
		  (user_id,source,source_event_id,idempotency_key,input,last_error)
		VALUES ($1,$2,NULLIF($3,''),$4,$5,$6)
		ON CONFLICT (user_id,idempotency_key) DO UPDATE SET
		  input=EXCLUDED.input,
		  last_error=EXCLUDED.last_error,
		  status=CASE WHEN progression.xp_award_repair_queue.status IN ('completed','suppressed')
		              THEN progression.xp_award_repair_queue.status ELSE 'retry' END,
		  available_at=CASE WHEN progression.xp_award_repair_queue.status IN ('completed','suppressed')
		                    THEN progression.xp_award_repair_queue.available_at ELSE NOW() END,
		  updated_at=NOW()`, input.UserID, input.Source, input.SourceEventID,
		input.IdempotencyKey, payload, lastError)
	return err
}

func progressionExperimentMultiplier(ctx context.Context, tx *sql.Tx, userID, source string) (float64, error) {
	var key string
	var rollout int
	var variants []byte
	err := tx.QueryRowContext(ctx, `SELECT key,rollout_percent,variants FROM progression.experiments
		WHERE status='active' AND (starts_at IS NULL OR starts_at<=NOW()) AND (ends_at IS NULL OR ends_at>NOW())
		ORDER BY key LIMIT 1`).Scan(&key, &rollout, &variants)
	if errors.Is(err, sql.ErrNoRows) {
		return 1, nil
	}
	if err != nil {
		return 1, err
	}
	var variant string
	err = tx.QueryRowContext(ctx, `SELECT variant FROM progression.experiment_assignments
		WHERE experiment_key=$1 AND user_id=$2`, key, userID).Scan(&variant)
	if errors.Is(err, sql.ErrNoRows) {
		variant = "control"
		if rollout > 0 {
			var bucket int
			_ = tx.QueryRowContext(ctx, `SELECT mod(abs(hashtext($1 || $2)),100)`, userID, key).Scan(&bucket)
			if bucket < rollout {
				variant = "voice_circle_bonus"
			}
		}
		_, err = tx.ExecContext(ctx, `INSERT INTO progression.experiment_assignments(experiment_key,user_id,variant)
			VALUES ($1,$2,$3) ON CONFLICT DO NOTHING`, key, userID, variant)
	}
	if err != nil {
		return 1, err
	}
	var decoded map[string]map[string]float64
	if json.Unmarshal(variants, &decoded) != nil {
		return 1, nil
	}
	if config := decoded[variant]; config != nil {
		if value, ok := config[source]; ok {
			return value, nil
		}
		if value, ok := config["multiplier"]; ok {
			return value, nil
		}
	}
	return 1, nil
}

func (r *levelProgressionRepository) projectUser(ctx context.Context, outboxID int64, userID string, sequence int64) error {
	tx, err := r.db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelReadCommitted})
	if err != nil {
		return err
	}
	defer func() { _ = tx.Rollback() }()
	if _, err = tx.ExecContext(ctx, `SELECT pg_advisory_xact_lock(hashtext('level-state:' || $1))`, userID); err != nil {
		return err
	}
	var total, oldLevel int
	_ = tx.QueryRowContext(ctx, `SELECT current_level FROM progression.user_level_state WHERE user_id=$1 FOR UPDATE`, userID).Scan(&oldLevel)
	if oldLevel == 0 {
		oldLevel = 1
	}
	if err = tx.QueryRowContext(ctx, `SELECT GREATEST(COALESCE(SUM(awarded_xp),0),0) FROM progression.xp_ledger WHERE user_id=$1`, userID).Scan(&total); err != nil {
		return err
	}
	var trustOK, progressionFrozen bool
	err = tx.QueryRowContext(ctx, `SELECT COALESCE(u.is_verified,FALSE) AND u.is_active AND NOT COALESCE(u.is_banned,FALSE)
		AND NOT COALESCE(c.progression_frozen,FALSE),COALESCE(c.progression_frozen,FALSE)
		FROM user_management.users u LEFT JOIN progression.account_controls c
		ON c.user_id=u.id AND (c.expires_at IS NULL OR c.expires_at>NOW())
		WHERE u.id=$1`, userID).Scan(&trustOK, &progressionFrozen)
	if err != nil {
		return err
	}
	var level, threshold int
	err = tx.QueryRowContext(ctx, `SELECT level,threshold_xp FROM progression.level_definitions
		WHERE is_active AND threshold_xp<=$1 AND (NOT trust_gate OR $2)
		ORDER BY level DESC LIMIT 1`, total, trustOK).Scan(&level, &threshold)
	if err != nil {
		return err
	}
	var nextThreshold sql.NullInt64
	_ = tx.QueryRowContext(ctx, `SELECT MIN(threshold_xp) FROM progression.level_definitions WHERE is_active AND level>$1`, level).Scan(&nextThreshold)
	currentXP, progress := total-threshold, 100.0
	if nextThreshold.Valid && int(nextThreshold.Int64) > threshold {
		progress = float64(currentXP) * 100 / float64(int(nextThreshold.Int64)-threshold)
	}
	_, err = tx.ExecContext(ctx, `INSERT INTO progression.user_level_state
		(user_id,total_xp,current_level,current_level_xp,next_level_xp,progress_percent,trust_gate_satisfied,progression_frozen,last_ledger_sequence)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
		ON CONFLICT (user_id) DO UPDATE SET total_xp=EXCLUDED.total_xp,current_level=EXCLUDED.current_level,
		current_level_xp=EXCLUDED.current_level_xp,next_level_xp=EXCLUDED.next_level_xp,
		progress_percent=EXCLUDED.progress_percent,trust_gate_satisfied=EXCLUDED.trust_gate_satisfied,
		progression_frozen=EXCLUDED.progression_frozen,
		version=progression.user_level_state.version+1,last_ledger_sequence=GREATEST(progression.user_level_state.last_ledger_sequence,EXCLUDED.last_ledger_sequence),
		projected_at=NOW(),updated_at=NOW()`, userID, total, level, currentXP, nextThreshold, progress, trustOK, progressionFrozen, sequence)
	if err != nil {
		return err
	}
	for reached := oldLevel + 1; reached <= level; reached++ {
		_, err = tx.ExecContext(ctx, `INSERT INTO progression.level_transitions(user_id,from_level,to_level,total_xp,trigger_ledger_sequence)
			VALUES ($1,$2,$3,$4,$5) ON CONFLICT (user_id,to_level) DO NOTHING`, userID, reached-1, reached, total, sequence)
		if err != nil {
			return err
		}
		_, _ = tx.ExecContext(ctx, `INSERT INTO progression.telemetry_events(user_id,event_name,properties)
			VALUES ($1,'level_up',jsonb_build_object('from_level',$2::INTEGER,'to_level',$3::INTEGER,'total_xp',$4::INTEGER))`, userID, reached-1, reached, total)
	}
	if outboxID > 0 {
		_, err = tx.ExecContext(ctx, `UPDATE progression.projection_outbox SET status='completed',completed_at=NOW(),updated_at=NOW()
			WHERE id=$1`, outboxID)
		if err != nil {
			return err
		}
	}
	return tx.Commit()
}

type levelProjectionEngine struct {
	repo                 *levelProgressionRepository
	log                  *zap.Logger
	metrics              *observability.HTTPMetrics
	lastMetricsRefreshAt time.Time
	cancel               context.CancelFunc
	done                 chan struct{}
	once                 sync.Once
}

func newLevelProjectionEngine(repo *levelProgressionRepository, log *zap.Logger, metrics *observability.HTTPMetrics) *levelProjectionEngine {
	if repo == nil {
		return nil
	}
	return &levelProjectionEngine{repo: repo, log: log, metrics: metrics}
}

func (e *levelProjectionEngine) Start(parent context.Context) {
	if e == nil {
		return
	}
	ctx, cancel := context.WithCancel(parent)
	e.cancel, e.done = cancel, make(chan struct{})
	go func() {
		defer close(e.done)
		ticker := time.NewTicker(200 * time.Millisecond)
		defer ticker.Stop()
		for {
			e.runBatch(ctx)
			select {
			case <-ctx.Done():
				return
			case <-ticker.C:
			}
		}
	}()
}

func (e *levelProjectionEngine) runBatch(ctx context.Context) {
	run := observability.NewHeartbeat(workerLevelProjection, 200*time.Millisecond).Begin()
	var runErr error
	processed, failed := 0, 0
	defer func() {
		run.Items("processed", processed)
		run.Items("failed", failed)
		run.End(runErr)
	}()
	e.runAwardRepairs(ctx)
	_, _ = e.repo.db.ExecContext(ctx, `UPDATE progression.projection_outbox
		SET status='retry',available_at=NOW(),worker_id=NULL,last_error='stale processing lease recovered',updated_at=NOW()
		WHERE status='processing' AND locked_at<NOW()-INTERVAL '5 minutes'`)
	rows, err := e.repo.db.QueryContext(ctx, `UPDATE progression.projection_outbox o SET status='processing',
		locked_at=NOW(),worker_id=$1,attempt_count=attempt_count+1,updated_at=NOW()
		WHERE id IN (SELECT id FROM progression.projection_outbox WHERE status IN ('pending','retry')
		AND available_at<=NOW() ORDER BY id LIMIT 50 FOR UPDATE SKIP LOCKED)
		RETURNING id,user_id::TEXT,ledger_sequence`, uuid.NewString())
	if err != nil {
		runErr = err
		return
	}
	type job struct {
		id, sequence int64
		user         string
	}
	jobs := []job{}
	for rows.Next() {
		var item job
		if rows.Scan(&item.id, &item.user, &item.sequence) == nil {
			jobs = append(jobs, item)
		}
	}
	rows.Close()
	for _, item := range jobs {
		if err := e.repo.projectUser(ctx, item.id, item.user, item.sequence); err != nil {
			failed++
			_, _ = e.repo.db.ExecContext(ctx, `UPDATE progression.projection_outbox SET status=CASE WHEN attempt_count>=8 THEN 'dead_letter' ELSE 'retry' END,
			available_at=NOW()+make_interval(secs=>LEAST(300,attempt_count*attempt_count)),last_error=$2,updated_at=NOW() WHERE id=$1`, item.id, err.Error())
		}
	}
	processed = len(jobs) - failed
	e.refreshProductionMetrics(ctx, time.Now())
}

func (e *levelProjectionEngine) refreshProductionMetrics(ctx context.Context, now time.Time) {
	if e == nil || e.metrics == nil || (!e.lastMetricsRefreshAt.IsZero() && now.Sub(e.lastMetricsRefreshAt) < 5*time.Second) {
		return
	}
	health, err := e.repo.productionHealth(ctx)
	if err != nil {
		e.log.Warn("progression_metrics_refresh_failed", zap.Error(err))
		return
	}
	e.lastMetricsRefreshAt = now
	e.metrics.ProgressionQueueDepth.Set(numericMetric(health["queue_depth"]))
	observability.NewHeartbeat(workerLevelProjection, 200*time.Millisecond).SetBacklog(numericMetric(health["queue_depth"]))
	e.metrics.ProgressionProcessing.Set(numericMetric(health["processing"]))
	e.metrics.ProgressionDeadLetters.Set(numericMetric(health["dead_letters"]))
	e.metrics.ProgressionOldestPendingAge.Set(numericMetric(health["oldest_pending_age_seconds"]))
	e.metrics.ProgressionCompletionP95.Set(numericMetric(health["completion_p95_seconds"]))
	e.metrics.ProgressionOpenFraudCases.Set(numericMetric(health["open_fraud_cases"]))
	e.metrics.ProgressionCapDenials15m.Set(numericMetric(health["cap_denials_15m"]))
}

func numericMetric(value any) float64 {
	switch typed := value.(type) {
	case float64:
		return typed
	case json.Number:
		parsed, _ := typed.Float64()
		return parsed
	case int64:
		return float64(typed)
	case int:
		return float64(typed)
	default:
		parsed, _ := strconv.ParseFloat(strings.TrimSpace(toString(value)), 64)
		return parsed
	}
}

func (r *levelProgressionRepository) productionHealth(ctx context.Context) (map[string]any, error) {
	var queueDepth, processing, deadLetters, openFraud, capDenials int64
	var oldest, completionP95 float64
	err := r.db.QueryRowContext(ctx, `SELECT queue_depth,processing,dead_letters,
		oldest_pending_age_seconds,completion_p95_seconds FROM progression.production_health`).
		Scan(&queueDepth, &processing, &deadLetters, &oldest, &completionP95)
	if err != nil {
		return nil, err
	}
	if err = r.db.QueryRowContext(ctx, `SELECT
		COUNT(*) FILTER (WHERE status IN ('open','reviewing')),
		(SELECT COUNT(*) FROM progression.telemetry_events
		 WHERE event_name='xp_cap_reached' AND occurred_at>=NOW()-INTERVAL '15 minutes')
		FROM progression.fraud_cases`).Scan(&openFraud, &capDenials); err != nil {
		return nil, err
	}
	return map[string]any{
		"queue_depth": queueDepth, "processing": processing, "dead_letters": deadLetters,
		"oldest_pending_age_seconds": oldest, "completion_p95_seconds": completionP95,
		"open_fraud_cases": openFraud, "cap_denials_15m": capDenials,
	}, nil
}

func (e *levelProjectionEngine) runAwardRepairs(ctx context.Context) {
	_, _ = e.repo.db.ExecContext(ctx, `UPDATE progression.xp_award_repair_queue
		SET status='retry',available_at=NOW(),worker_id=NULL,
		    last_error='stale processing lease recovered',updated_at=NOW()
		WHERE status='processing' AND locked_at<NOW()-INTERVAL '5 minutes'`)
	workerID := uuid.NewString()
	rows, err := e.repo.db.QueryContext(ctx, `
		UPDATE progression.xp_award_repair_queue q
		SET status='processing',locked_at=NOW(),worker_id=$1,
		    attempt_count=attempt_count+1,updated_at=NOW()
		WHERE id IN (
		  SELECT id FROM progression.xp_award_repair_queue
		  WHERE status IN ('pending','retry') AND available_at<=NOW()
		  ORDER BY id LIMIT 25 FOR UPDATE SKIP LOCKED
		)
		RETURNING id,input`, workerID)
	if err != nil {
		return
	}
	type repair struct {
		id      int64
		payload []byte
	}
	items := make([]repair, 0, 25)
	for rows.Next() {
		var item repair
		if rows.Scan(&item.id, &item.payload) == nil {
			items = append(items, item)
		}
	}
	_ = rows.Close()
	for _, item := range items {
		var payload xpAwardRepairPayload
		if err := json.Unmarshal(item.payload, &payload); err != nil {
			e.finishAwardRepair(ctx, item.id, "dead_letter", err)
			continue
		}
		_, err := e.repo.awardXP(ctx, payload.awardInput())
		switch {
		case err == nil:
			e.finishAwardRepair(ctx, item.id, "completed", nil)
		case errors.Is(err, errXPCapReached), errors.Is(err, errProgressionFrozen):
			e.finishAwardRepair(ctx, item.id, "suppressed", err)
		default:
			var attempts int
			_ = e.repo.db.QueryRowContext(ctx,
				`SELECT attempt_count FROM progression.xp_award_repair_queue WHERE id=$1`, item.id,
			).Scan(&attempts)
			status := "retry"
			if attempts >= 8 {
				status = "dead_letter"
			}
			e.finishAwardRepair(ctx, item.id, status, err)
		}
	}
}

func (e *levelProjectionEngine) finishAwardRepair(ctx context.Context, id int64, status string, cause error) {
	lastError := ""
	if cause != nil {
		lastError = cause.Error()
	}
	_, _ = e.repo.db.ExecContext(ctx, `
		UPDATE progression.xp_award_repair_queue
		SET status=$2,last_error=NULLIF($3,''),worker_id=NULL,locked_at=NULL,
		    available_at=CASE WHEN $2='retry'
		      THEN NOW()+make_interval(secs=>LEAST(300,attempt_count*attempt_count))
		      ELSE available_at END,
		    completed_at=CASE WHEN $2 IN ('completed','suppressed') THEN NOW() ELSE completed_at END,
		    updated_at=NOW()
		WHERE id=$1`, id, status, lastError)
}

func (e *levelProjectionEngine) Close() {
	if e == nil {
		return
	}
	e.once.Do(func() {
		if e.cancel != nil {
			e.cancel()
		}
		if e.done != nil {
			<-e.done
		}
	})
}

func (r *levelProgressionRepository) progressionView(ctx context.Context, userID string) (map[string]any, error) {
	var state map[string]any
	row := r.db.QueryRowContext(ctx, `SELECT COALESCE(jsonb_build_object(
		'user_id',s.user_id,'total_xp',s.total_xp,'current_level',s.current_level,'level_name',d.name,
		'current_level_xp',s.current_level_xp,'next_level_xp',s.next_level_xp,'progress_percent',s.progress_percent,
		'trust_gate_satisfied',s.trust_gate_satisfied,'progression_frozen',s.progression_frozen,
		'version',s.version,'projected_at',s.projected_at,
		'projection_lag_seconds',GREATEST(EXTRACT(EPOCH FROM NOW()-s.projected_at),0)), '{}'::JSONB)
		FROM progression.user_level_state s JOIN progression.level_definitions d ON d.level=s.current_level WHERE s.user_id=$1`, userID)
	var raw []byte
	if err := row.Scan(&raw); err != nil && !errors.Is(err, sql.ErrNoRows) {
		return nil, err
	} else if err == nil {
		_ = json.Unmarshal(raw, &state)
	}
	if len(state) == 0 {
		state = map[string]any{"user_id": userID, "total_xp": 0, "current_level": 1, "level_name": "Onboarded", "progress_percent": 0, "projection_lag_seconds": 0}
	}
	levels, err := queryJSONRows(ctx, r.db, `SELECT jsonb_build_object('level',level,'name',name,'threshold_xp',threshold_xp,
		'trust_gate',trust_gate,'reward_summary',reward_summary) FROM progression.level_definitions WHERE is_active ORDER BY level`)
	if err != nil {
		return nil, err
	}
	rewards, err := queryJSONRows(ctx, r.db, `SELECT jsonb_build_object('reward_key',c.reward_key,'level',c.level,'name',c.name,
		'description',c.description,'reward_type',c.reward_type,'payload',c.payload,'trust_required',c.trust_required,
		'claimed',cl.id IS NOT NULL,'claim_id',cl.id) FROM progression.reward_catalog c LEFT JOIN progression.reward_claims cl
		ON cl.reward_key=c.reward_key AND cl.user_id=$1 WHERE c.enabled ORDER BY c.sort_order`, userID)
	if err != nil {
		return nil, err
	}
	state["levels"], state["rewards"] = levels, rewards
	return state, nil
}

type jsonQueryer interface {
	QueryContext(context.Context, string, ...any) (*sql.Rows, error)
}

func queryJSONRows(ctx context.Context, db jsonQueryer, query string, args ...any) ([]map[string]any, error) {
	rows, err := db.QueryContext(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	items := []map[string]any{}
	for rows.Next() {
		var raw []byte
		if err = rows.Scan(&raw); err != nil {
			return nil, err
		}
		var item map[string]any
		if err = json.Unmarshal(raw, &item); err != nil {
			return nil, err
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func (r *levelProgressionRepository) claimReward(ctx context.Context, userID, rewardKey, idempotencyKey string) (map[string]any, error) {
	tx, err := r.db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		return nil, err
	}
	defer func() { _ = tx.Rollback() }()
	if _, err = tx.ExecContext(ctx, `SELECT pg_advisory_xact_lock(hashtext('progression-reward:' || $1 || ':' || $2))`, userID, rewardKey); err != nil {
		return nil, err
	}
	var existingID, existingReward, existingKey string
	var existingLevel int
	var existingClaimed time.Time
	err = tx.QueryRowContext(ctx, `SELECT id::TEXT,reward_key,level,idempotency_key,claimed_at
		FROM progression.reward_claims WHERE user_id=$1 AND (reward_key=$2 OR idempotency_key=$3)
		ORDER BY (reward_key=$2) DESC LIMIT 1`, userID, rewardKey, idempotencyKey).
		Scan(&existingID, &existingReward, &existingLevel, &existingKey, &existingClaimed)
	if err == nil {
		if existingReward != rewardKey && existingKey == idempotencyKey {
			return nil, errIdempotencyPayloadConflict
		}
		return map[string]any{"id": existingID, "reward_key": existingReward, "level": existingLevel,
			"claimed_at": existingClaimed.UTC().Format(time.RFC3339Nano), "was_duplicate": true}, tx.Commit()
	}
	if !errors.Is(err, sql.ErrNoRows) {
		return nil, err
	}
	var level int
	var trustRequired, trustOK, frozen bool
	var payload []byte
	err = tx.QueryRowContext(ctx, `SELECT c.level,c.trust_required,c.payload,s.trust_gate_satisfied,s.progression_frozen
		FROM progression.reward_catalog c JOIN progression.user_level_state s ON s.user_id=$1
		WHERE c.reward_key=$2 AND c.enabled AND s.current_level>=c.level FOR UPDATE OF s`, userID, rewardKey).Scan(&level, &trustRequired, &payload, &trustOK, &frozen)
	if err != nil {
		return nil, errors.New("reward is unavailable at the current level")
	}
	if frozen || (trustRequired && !trustOK) {
		return nil, errProgressionFrozen
	}
	var id string
	var claimed time.Time
	err = tx.QueryRowContext(ctx, `INSERT INTO progression.reward_claims(user_id,reward_key,level,idempotency_key,claim_payload)
		VALUES($1,$2,$3,$4,$5)
		RETURNING id::TEXT,claimed_at`, userID, rewardKey, level, idempotencyKey, payload).Scan(&id, &claimed)
	if err != nil {
		return nil, err
	}
	_, err = tx.ExecContext(ctx, `INSERT INTO progression.telemetry_events(user_id,event_name,properties)
		VALUES($1,'level_reward_claimed',jsonb_build_object('reward_key',$2::TEXT,'level',$3::INTEGER))`, userID, rewardKey, level)
	if err != nil {
		return nil, err
	}
	return map[string]any{"id": id, "reward_key": rewardKey, "level": level, "claimed_at": claimed.UTC().Format(time.RFC3339Nano), "was_duplicate": false}, tx.Commit()
}

// awardProgression awards XP for a completed product action. The durable path
// (progression_award_durability.go) writes the intent ahead of the award so a
// crash or database outage cannot silently lose it.
func (s *Server) awardProgression(ctx context.Context, input xpAwardInput) {
	s.awardProgressionDurably(ctx, input)
}

func (s *Server) enqueueProgressionRepair(input xpAwardInput, cause error) {
	repairCtx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	repairErr := s.progression.enqueueAwardRepair(repairCtx, input, cause)
	cancel()
	if s.log != nil {
		s.log.Warn("progression XP award queued for repair", zap.String("source", input.Source),
			zap.Error(cause), zap.Error(repairErr))
	}
}

func (s *Server) getProgression(w http.ResponseWriter, r *http.Request) {
	userID := chi.URLParam(r, "userID")
	view, err := s.progression.progressionView(r.Context(), userID)
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"progression": view})
}
func (s *Server) listProgressionLedger(w http.ResponseWriter, r *http.Request) {
	userID := chi.URLParam(r, "userID")
	limit := 50
	if v, _ := strconv.Atoi(r.URL.Query().Get("limit")); v > 0 && v <= 100 {
		limit = v
	}
	after, _ := strconv.ParseInt(r.URL.Query().Get("after"), 10, 64)
	items, err := queryJSONRows(r.Context(), s.progression.db, `SELECT jsonb_build_object('sequence',sequence_id,'event_id',event_id,'source',source,'awarded_xp',awarded_xp,'multiplier',quality_multiplier*experiment_multiplier,'occurred_at',occurred_at,'metadata',metadata) FROM progression.xp_ledger WHERE user_id=$1 AND ($2=0 OR sequence_id<$2) ORDER BY sequence_id DESC LIMIT $3`, userID, after, limit)
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"entries": items, "count": len(items)})
}
func (s *Server) claimProgressionReward(w http.ResponseWriter, r *http.Request) {
	userID := chi.URLParam(r, "userID")
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	key := strings.TrimSpace(toString(payload["reward_key"]))
	idem := strings.TrimSpace(r.Header.Get("Idempotency-Key"))
	claim, err := s.progression.claimReward(r.Context(), userID, key, idem)
	if err != nil {
		writeError(w, http.StatusConflict, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"claim": claim})
}

func (s *Server) adminProgressionOverview(w http.ResponseWriter, r *http.Request) {
	if err := requireAdminUser(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	policies, err := queryJSONRows(r.Context(), s.progression.db, `SELECT jsonb_build_object('source',source,'display_name',display_name,'base_xp',base_xp,'daily_xp_cap',daily_xp_cap,'daily_event_cap',daily_event_cap,'cooldown_seconds',cooldown_seconds,'decay_multipliers',decay_multipliers,'enabled',enabled,'updated_at',updated_at) FROM progression.xp_source_policies ORDER BY source`)
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	experiments, _ := queryJSONRows(r.Context(), s.progression.db, `SELECT jsonb_build_object(
		'key',key,'name',name,'status',status,'rollout_stage',rollout_stage,
		'rollout_percent',rollout_percent,'variants',variants,
		'safety_stop_owner',safety_stop_owner,'incident_response_minutes',incident_response_minutes,
		'last_safety_review_at',last_safety_review_at,'stage_evidence_uri',stage_evidence_uri,
		'stage_started_at',stage_started_at,'updated_at',updated_at)
		FROM progression.experiments ORDER BY key`)
	fraudRules, _ := queryJSONRows(r.Context(), s.progression.db, `SELECT jsonb_build_object(
		'rule_code',rule_code,'rejected_attempt_threshold',rejected_attempt_threshold,
		'window_seconds',window_seconds,'severity',severity,'response_action',response_action,
		'enabled',enabled,'review_sla_minutes',review_sla_minutes,'tuning_note',tuning_note,
		'updated_at',updated_at) FROM progression.fraud_rule_policies ORDER BY rule_code`)
	var metrics map[string]any
	raw := []byte{}
	_ = s.progression.db.QueryRowContext(r.Context(), `SELECT jsonb_build_object('users',COUNT(*),'total_xp',COALESCE(SUM(total_xp),0),'avg_level',COALESCE(ROUND(AVG(current_level),2),0)) FROM progression.user_level_state`).Scan(&raw)
	_ = json.Unmarshal(raw, &metrics)
	if metrics == nil {
		metrics = map[string]any{}
	}
	if productionHealth, healthErr := s.progression.productionHealth(r.Context()); healthErr == nil {
		for key, value := range productionHealth {
			metrics[key] = value
		}
		// Retain the response field used by existing clients, with a correct
		// queue-lag definition rather than time since an idle user's projection.
		metrics["projection_lag_seconds"] = productionHealth["oldest_pending_age_seconds"]
	}
	var repairMetrics map[string]any
	raw = []byte{}
	_ = s.progression.db.QueryRowContext(r.Context(), `SELECT jsonb_build_object(
		'pending',COUNT(*) FILTER (WHERE status IN ('pending','retry')),
		'processing',COUNT(*) FILTER (WHERE status='processing'),
		'dead_letter',COUNT(*) FILTER (WHERE status='dead_letter'),
		'oldest_pending_age_seconds',COALESCE(EXTRACT(EPOCH FROM NOW()-MIN(created_at)
		  FILTER (WHERE status IN ('pending','retry'))),0))
		FROM progression.xp_award_repair_queue`).Scan(&raw)
	_ = json.Unmarshal(raw, &repairMetrics)
	metrics["award_repair"] = repairMetrics
	writeJSON(w, http.StatusOK, map[string]any{"policies": policies, "experiments": experiments, "fraud_rules": fraudRules, "metrics": metrics})
}

func (s *Server) adminUpdateProgressionPolicy(w http.ResponseWriter, r *http.Request) {
	operator, err := authenticatedOperatorID(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	source := chi.URLParam(r, "source")
	result, err := s.progression.db.ExecContext(r.Context(), `UPDATE progression.xp_source_policies SET base_xp=COALESCE($2,base_xp),daily_xp_cap=COALESCE($3,daily_xp_cap),daily_event_cap=COALESCE($4,daily_event_cap),cooldown_seconds=COALESCE($5,cooldown_seconds),enabled=COALESCE($6,enabled),updated_by=$7,updated_at=NOW() WHERE source=$1`, source, nullableInt(payload["base_xp"]), nullableInt(payload["daily_xp_cap"]), nullableInt(payload["daily_event_cap"]), nullableInt(payload["cooldown_seconds"]), nullableBool(payload["enabled"]), operator)
	if err != nil {
		writeError(w, http.StatusBadRequest, err)
		return
	}
	count, _ := result.RowsAffected()
	if count == 0 {
		writeError(w, http.StatusNotFound, errors.New("XP policy not found"))
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"success": true})
}
func nullableInt(value any) any {
	if value == nil {
		return nil
	}
	return int(numericValue(value))
}
func nullableBool(value any) any {
	if value == nil {
		return nil
	}
	v, ok := value.(bool)
	if !ok {
		return nil
	}
	return v
}

func (s *Server) adminListProgressionFraud(w http.ResponseWriter, r *http.Request) {
	if err := requireAdminUser(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	items, err := queryJSONRows(r.Context(), s.progression.db, `SELECT jsonb_build_object('id',f.id,'user_id',f.user_id,'username',u.username,'rule_code',f.rule_code,'severity',f.severity,'status',f.status,'evidence',f.evidence,'created_at',f.created_at) FROM progression.fraud_cases f JOIN user_management.users u ON u.id=f.user_id WHERE ($1='' OR f.status=$1) ORDER BY f.created_at DESC LIMIT 200`, r.URL.Query().Get("status"))
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"cases": items, "count": len(items)})
}

func (s *Server) adminUpdateProgressionFraudPolicy(w http.ResponseWriter, r *http.Request) {
	operator, err := authenticatedOperatorID(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	threshold := int(numericValue(payload["rejected_attempt_threshold"]))
	windowSeconds := int(numericValue(payload["window_seconds"]))
	reviewSLA := int(numericValue(payload["review_sla_minutes"]))
	severity := strings.TrimSpace(toString(payload["severity"]))
	note := strings.TrimSpace(toString(payload["tuning_note"]))
	enabled, enabledOK := payload["enabled"].(bool)
	if !enabledOK || threshold < 2 || threshold > 20 || windowSeconds < 60 || windowSeconds > 86400 ||
		reviewSLA < 5 || reviewSLA > 10080 || (severity != "low" && severity != "medium" && severity != "high" && severity != "critical") || len(note) < 10 {
		writeError(w, http.StatusBadRequest, errors.New("invalid bounded fraud policy or tuning note"))
		return
	}
	result, err := s.progression.db.ExecContext(r.Context(), `UPDATE progression.fraud_rule_policies
		SET rejected_attempt_threshold=$2,window_seconds=$3,severity=$4,enabled=$5,
		    review_sla_minutes=$6,tuning_note=$7,updated_by=$8,updated_at=NOW()
		WHERE rule_code=$1`, chi.URLParam(r, "ruleCode"), threshold, windowSeconds,
		severity, enabled, reviewSLA, note, operator)
	if err != nil {
		writeError(w, http.StatusBadRequest, err)
		return
	}
	if count, _ := result.RowsAffected(); count == 0 {
		writeError(w, http.StatusNotFound, errors.New("fraud rule not found"))
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"success": true, "response_action": "review_only"})
}

func (s *Server) adminResolveProgressionFraud(w http.ResponseWriter, r *http.Request) {
	operator, err := authenticatedOperatorID(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	status := strings.TrimSpace(toString(payload["status"]))
	if status != "dismissed" && status != "confirmed" {
		writeError(w, http.StatusBadRequest, errors.New("status must be dismissed or confirmed"))
		return
	}
	result, err := s.progression.db.ExecContext(r.Context(), `UPDATE progression.fraud_cases SET status=$2,resolution=$3,reviewed_by=$4,reviewed_at=NOW(),updated_at=NOW() WHERE id=$1`, chi.URLParam(r, "caseID"), status, toString(payload["resolution"]), operator)
	if err != nil {
		writeError(w, http.StatusBadRequest, err)
		return
	}
	if count, _ := result.RowsAffected(); count == 0 {
		writeError(w, http.StatusNotFound, errors.New("fraud case not found"))
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"success": true})
}

func (s *Server) adminAdjustProgressionXP(w http.ResponseWriter, r *http.Request) {
	operator, err := authenticatedOperatorID(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	amount := int(numericValue(payload["amount"]))
	if amount == 0 || amount < -10000 || amount > 300 {
		writeError(w, http.StatusBadRequest, errors.New("amount must be between -10000 and 300 and non-zero"))
		return
	}
	reason := strings.TrimSpace(toString(payload["reason"]))
	if len(reason) < 10 {
		writeError(w, http.StatusBadRequest, errors.New("audited adjustment reason must be at least 10 characters"))
		return
	}
	idempotencyKey := strings.TrimSpace(r.Header.Get("Idempotency-Key"))
	result, err := s.progression.awardXP(r.Context(), xpAwardInput{UserID: chi.URLParam(r, "userID"), Source: "admin_adjustment", SourceEventID: "admin:" + operator + ":" + idempotencyKey, IdempotencyKey: idempotencyKey, BaseXPOverride: amount, ActorType: "admin", ActorID: operator, Metadata: map[string]any{"reason": reason}})
	if err != nil {
		writeError(w, http.StatusConflict, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"award": result})
}

type progressionRolloutChange struct {
	Status          string
	Stage           string
	RolloutPercent  int
	SafetyStopOwner string
	EvidenceURI     string
	DecisionNote    string
}

var progressionStagePercent = map[string]int{
	"draft": 0, "dogfood": 1, "five_percent": 5,
	"twenty_five_percent": 25, "general_availability": 100,
}

func validateProgressionRolloutChange(change progressionRolloutChange) error {
	if change.Status != "draft" && change.Status != "active" && change.Status != "paused" && change.Status != "completed" {
		return errors.New("status must be draft, active, paused, or completed")
	}
	expected, ok := progressionStagePercent[change.Stage]
	if !ok || expected != change.RolloutPercent {
		return errors.New("rollout stage and percentage must be draft/0, dogfood/1, five_percent/5, twenty_five_percent/25, or general_availability/100")
	}
	if change.Status == "active" || change.Status == "paused" || change.Status == "completed" {
		if len(strings.TrimSpace(change.SafetyStopOwner)) < 3 || len(strings.TrimSpace(change.EvidenceURI)) < 3 || len(strings.TrimSpace(change.DecisionNote)) < 10 {
			return errors.New("reviewed rollout requires a safety-stop owner, evidence URI, and decision note")
		}
	}
	if change.Status == "draft" && change.Stage != "draft" {
		return errors.New("draft status requires the draft stage")
	}
	if change.Status == "completed" && change.Stage != "general_availability" {
		return errors.New("completed status requires general availability")
	}
	return nil
}

// progressionRolloutCohortConstraint is the constraint name raised by the
// migration 086 transition trigger when a promotion has no exposed cohort.
const progressionRolloutCohortConstraint = "progression_rollout_promotion_cohort"

// progressionPromotionRequiresCohort reports whether moving from one stage to
// the next is a promotion out of an exposed stage. draft -> dogfood opens the
// first cohort and cannot have exposure yet; pause, resume and completion keep
// the stage and never wait on cohort data, so a safety stop is always allowed.
func progressionPromotionRequiresCohort(fromStage, toStage string) bool {
	from, fromOK := progressionStagePercent[fromStage]
	to, toOK := progressionStagePercent[toStage]
	return fromOK && toOK && from > 0 && to > from
}

func writeProgressionCohortRequired(w http.ResponseWriter, fromStage, toStage string) {
	writeJSON(w, http.StatusConflict, map[string]any{
		"success":         false,
		"error":           "progression rollout promotion from " + fromStage + " to " + toStage + " requires a nonempty exposed cohort for the current stage; pause instead of promoting",
		"error_code":      "PROGRESSION_ROLLOUT_COHORT_REQUIRED",
		"from_stage":      fromStage,
		"to_stage":        toStage,
		"exposed_members": 0,
	})
}

func (s *Server) adminUpdateProgressionExperiment(w http.ResponseWriter, r *http.Request) {
	operator, err := authenticatedOperatorID(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	change := progressionRolloutChange{
		Status:          strings.TrimSpace(toString(payload["status"])),
		Stage:           strings.TrimSpace(toString(payload["rollout_stage"])),
		RolloutPercent:  int(numericValue(payload["rollout_percent"])),
		SafetyStopOwner: strings.TrimSpace(toString(payload["safety_stop_owner"])),
		EvidenceURI:     strings.TrimSpace(toString(payload["evidence_uri"])),
		DecisionNote:    strings.TrimSpace(toString(payload["decision_note"])),
	}
	if change.Status == "draft" {
		if change.SafetyStopOwner == "" {
			change.SafetyStopOwner = operator
		}
		if change.EvidenceURI == "" {
			change.EvidenceURI = "operator://draft"
		}
		if change.DecisionNote == "" {
			change.DecisionNote = "Draft progression rollout configuration updated."
		}
	}
	if err = validateProgressionRolloutChange(change); err != nil {
		writeError(w, http.StatusBadRequest, err)
		return
	}
	tx, err := s.progression.db.BeginTx(r.Context(), &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		writeError(w, http.StatusBadRequest, err)
		return
	}
	defer func() { _ = tx.Rollback() }()
	key := chi.URLParam(r, "key")
	var oldStage, oldStatus string
	var stageStartedAt sql.NullTime
	if err = tx.QueryRowContext(r.Context(), `SELECT rollout_stage,status,stage_started_at FROM progression.experiments WHERE key=$1 FOR UPDATE`, key).Scan(&oldStage, &oldStatus, &stageStartedAt); errors.Is(err, sql.ErrNoRows) {
		writeError(w, http.StatusNotFound, errors.New("experiment not found"))
		return
	} else if err != nil {
		writeError(w, http.StatusBadRequest, err)
		return
	}
	// Every promotion out of an exposed stage needs a nonempty exposed cohort
	// for that stage. The count uses the same database function as the
	// migration 086 trigger; if it cannot be read the promotion fails closed.
	if progressionPromotionRequiresCohort(oldStage, change.Stage) {
		var exposed int64
		if err = tx.QueryRowContext(r.Context(), `SELECT progression.rollout_exposed_cohort_size($1,$2::timestamptz)`, key, stageStartedAt).Scan(&exposed); err != nil {
			writeError(w, http.StatusServiceUnavailable, errors.New("exposed cohort evidence is unavailable; promotion refused"))
			return
		}
		if exposed == 0 {
			writeProgressionCohortRequired(w, oldStage, change.Stage)
			return
		}
	}
	_, err = tx.ExecContext(r.Context(), `UPDATE progression.experiments SET
		status=$2,rollout_stage=$3,rollout_percent=$4,safety_stop_owner=$5,
		last_safety_review_at=NOW(),last_safety_review_by=$6,stage_evidence_uri=$7,
		stage_started_at=CASE WHEN rollout_stage<>$3 THEN NOW() ELSE stage_started_at END,
		updated_by=$6,updated_at=NOW() WHERE key=$1`, key, change.Status, change.Stage,
		change.RolloutPercent, change.SafetyStopOwner, operator, change.EvidenceURI)
	if err == nil {
		_, err = tx.ExecContext(r.Context(), `INSERT INTO progression.rollout_stage_history
			(experiment_key,from_stage,to_stage,from_status,to_status,rollout_percent,
			 safety_stop_owner,evidence_uri,decision_note,actor_id)
			VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)`, key, oldStage, change.Stage,
			oldStatus, change.Status, change.RolloutPercent, change.SafetyStopOwner,
			change.EvidenceURI, change.DecisionNote, operator)
	}
	if err == nil {
		err = tx.Commit()
	}
	var pgErr *pgconn.PgError
	if errors.As(err, &pgErr) && pgErr.ConstraintName == progressionRolloutCohortConstraint {
		writeProgressionCohortRequired(w, oldStage, change.Stage)
		return
	}
	if err != nil {
		writeError(w, http.StatusConflict, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"success": true, "stage": change.Stage, "rollout_percent": change.RolloutPercent})
}

func (s *Server) adminSetProgressionControl(w http.ResponseWriter, r *http.Request) {
	operator, err := authenticatedOperatorID(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	frozen, _ := payload["progression_frozen"].(bool)
	risk := 1.0
	if raw, exists := payload["risk_multiplier"]; exists {
		switch value := raw.(type) {
		case float64:
			risk = value
		case json.Number:
			risk, _ = value.Float64()
		default:
			risk, _ = strconv.ParseFloat(strings.TrimSpace(toString(raw)), 64)
		}
	}
	if risk == 0 {
		risk = 1
	}
	if risk < 0.5 || risk > 1 {
		writeError(w, http.StatusBadRequest, errors.New("risk multiplier must be 0.5..1.0"))
		return
	}
	_, err = s.progression.db.ExecContext(r.Context(), `INSERT INTO progression.account_controls(user_id,progression_frozen,risk_multiplier,reason,updated_by) VALUES($1,$2,$3,$4,$5) ON CONFLICT(user_id) DO UPDATE SET progression_frozen=EXCLUDED.progression_frozen,risk_multiplier=EXCLUDED.risk_multiplier,reason=EXCLUDED.reason,updated_by=EXCLUDED.updated_by,updated_at=NOW()`, chi.URLParam(r, "userID"), frozen, risk, toString(payload["reason"]), operator)
	if err != nil {
		writeError(w, http.StatusBadRequest, err)
		return
	}
	var sequence int64
	_ = s.progression.db.QueryRowContext(r.Context(), `SELECT COALESCE(MAX(sequence_id),0) FROM progression.xp_ledger WHERE user_id=$1`, chi.URLParam(r, "userID")).Scan(&sequence)
	if err = s.progression.projectUser(r.Context(), 0, chi.URLParam(r, "userID"), sequence); err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"success": true})
}
