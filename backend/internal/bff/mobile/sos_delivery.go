package mobile

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/verified-dating/backend/internal/platform/config"
	"github.com/verified-dating/backend/internal/platform/observability"
	"go.uber.org/zap"
)

type sosDeliveryJob struct {
	ID                 string  `json:"delivery_id"`
	AlertID            string  `json:"alert_id"`
	UserID             string  `json:"user_id"`
	ContactName        string  `json:"contact_name"`
	ContactPhone       string  `json:"contact_phone"`
	Level              string  `json:"level"`
	Message            string  `json:"message,omitempty"`
	Latitude           float64 `json:"latitude"`
	Longitude          float64 `json:"longitude"`
	ResponseDeadlineAt string  `json:"response_deadline_at"`
	AttemptCount       int     `json:"-"`
	MaxAttempts        int     `json:"-"`
}

type sosDeliveryEngine struct {
	repo         *safetyRepository
	log          *zap.Logger
	client       *http.Client
	provider     string
	webhookURL   string
	webhookToken string
	pollInterval time.Duration
	maxAttempts  int
	cancel       context.CancelFunc
	done         sync.WaitGroup
}

func newSOSDeliveryEngine(cfg config.Config, log *zap.Logger, repo *safetyRepository) *sosDeliveryEngine {
	if repo == nil || repo.pg == nil || cfg.SOSDeliveryProvider != "webhook" {
		return nil
	}
	if log == nil {
		log = zap.NewNop()
	}
	poll := time.Duration(cfg.SOSDeliveryPollIntervalMS) * time.Millisecond
	if poll < 100*time.Millisecond || poll > time.Minute {
		poll = 500 * time.Millisecond
	}
	maxAttempts := cfg.SOSDeliveryMaxAttempts
	if maxAttempts < 1 || maxAttempts > 25 {
		maxAttempts = 8
	}
	return &sosDeliveryEngine{
		repo: repo, log: log, client: &http.Client{Timeout: 8 * time.Second},
		provider: cfg.SOSDeliveryProvider, webhookURL: cfg.SOSDeliveryWebhookURL,
		webhookToken: cfg.SOSDeliveryWebhookToken, pollInterval: poll, maxAttempts: maxAttempts,
	}
}

func (e *sosDeliveryEngine) Start(parent context.Context) {
	if e == nil || e.cancel != nil {
		return
	}
	ctx, cancel := context.WithCancel(parent)
	e.cancel = cancel
	e.done.Add(1)
	go e.run(ctx)
}

func (e *sosDeliveryEngine) run(ctx context.Context) {
	defer e.done.Done()
	workerID := "sos-" + uuid.NewString()
	ticker := time.NewTicker(e.pollInterval)
	defer ticker.Stop()
	heartbeat := observability.NewHeartbeat(workerSOSDelivery, e.pollInterval)
	for {
		run := heartbeat.Begin()
		processed, err := e.processBatch(ctx, workerID)
		run.Items("processed", processed)
		run.End(err)
		if err != nil && !errors.Is(err, context.Canceled) {
			e.log.Error("sos_delivery_batch_failed", zap.Error(err))
		}
		if processed > 0 {
			continue
		}
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
		}
	}
}

func (e *sosDeliveryEngine) processBatch(ctx context.Context, workerID string) (int, error) {
	jobs, err := e.repo.claimSOSDeliveries(ctx, workerID, 25, e.maxAttempts)
	if err != nil {
		return 0, err
	}
	for _, job := range jobs {
		deliveryErr := e.send(ctx, job)
		if err := e.repo.finishSOSDelivery(ctx, job, deliveryErr); err != nil {
			e.log.Error("sos_delivery_finalize_failed", zap.String("delivery_id", job.ID), zap.Error(err))
		}
	}
	return len(jobs), nil
}

func (e *sosDeliveryEngine) send(ctx context.Context, job sosDeliveryJob) error {
	payload, err := json.Marshal(job)
	if err != nil {
		return err
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, e.webhookURL, bytes.NewReader(payload))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Idempotency-Key", job.ID)
	if strings.TrimSpace(e.webhookToken) != "" {
		req.Header.Set("Authorization", "Bearer "+strings.TrimSpace(e.webhookToken))
	}
	response, err := e.client.Do(req)
	if err != nil {
		return err
	}
	defer response.Body.Close()
	if response.StatusCode < 200 || response.StatusCode >= 300 {
		body, _ := io.ReadAll(io.LimitReader(response.Body, 1024))
		return fmt.Errorf("emergency provider returned %d: %s", response.StatusCode, strings.TrimSpace(string(body)))
	}
	return nil
}

func (e *sosDeliveryEngine) Close() {
	if e == nil || e.cancel == nil {
		return
	}
	e.cancel()
	e.done.Wait()
}

// sosDeliveryLease is how long a claimed delivery may stay in "processing"
// before another worker may take it over. A send times out after 8 seconds, so
// a row still processing after this long belongs to a worker that crashed or
// lost its connection mid-send. Without the reclaim that emergency delivery
// would sit in "processing" until its 30-day retention expired.
const sosDeliveryLease = 2 * time.Minute

// Retention redaction of expired snapshots runs in the trust retention worker
// (platform.run_trust_retention), so it happens even when no SOS provider is
// configured and this engine never starts.
func (r *safetyRepository) claimSOSDeliveries(ctx context.Context, workerID string, limit, maxAttempts int) ([]sosDeliveryJob, error) {
	if _, err := r.pg.ExecContext(ctx, `
		UPDATE matching.sos_delivery_outbox
		SET status=CASE WHEN attempt_count>=max_attempts THEN 'dead_letter' ELSE 'retry' END,
		    locked_at=NULL,worker_id=NULL,available_at=NOW(),
		    last_error='worker lease expired before the send completed',updated_at=NOW()
		WHERE status='processing' AND locked_at < NOW() - make_interval(secs => $1)`,
		int(sosDeliveryLease.Seconds())); err != nil {
		return nil, err
	}
	rows, err := r.pg.QueryContext(ctx, `
		WITH candidates AS (
		  SELECT id FROM matching.sos_delivery_outbox
		  WHERE status IN ('pending','retry') AND available_at<=NOW() AND expires_at>NOW()
		  ORDER BY response_deadline_at,created_at FOR UPDATE SKIP LOCKED LIMIT $1
		)
		UPDATE matching.sos_delivery_outbox o
		SET status='processing',locked_at=NOW(),worker_id=$2,
		    attempt_count=attempt_count+1,max_attempts=$3,updated_at=NOW()
		FROM candidates c WHERE o.id=c.id
		RETURNING o.id::text,o.alert_id::text,o.user_id::text,o.contact_name,o.contact_phone,
		          o.level,COALESCE(o.message,''),COALESCE(o.latitude,0),COALESCE(o.longitude,0),
		          o.response_deadline_at,o.attempt_count,o.max_attempts`, limit, workerID, maxAttempts)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var jobs []sosDeliveryJob
	for rows.Next() {
		var job sosDeliveryJob
		var deadline time.Time
		if err := rows.Scan(&job.ID, &job.AlertID, &job.UserID, &job.ContactName, &job.ContactPhone,
			&job.Level, &job.Message, &job.Latitude, &job.Longitude, &deadline, &job.AttemptCount,
			&job.MaxAttempts); err != nil {
			return nil, err
		}
		job.ResponseDeadlineAt = deadline.UTC().Format(time.RFC3339)
		jobs = append(jobs, job)
	}
	return jobs, rows.Err()
}

func (r *safetyRepository) finishSOSDelivery(ctx context.Context, job sosDeliveryJob, deliveryErr error) error {
	status := "delivered"
	availableAt := time.Now().UTC()
	lastError := ""
	if deliveryErr != nil {
		lastError = deliveryErr.Error()
		if job.AttemptCount >= job.MaxAttempts {
			status = "dead_letter"
		} else {
			status = "retry"
			delay := time.Duration(job.AttemptCount*job.AttemptCount) * time.Second
			if delay > 5*time.Minute {
				delay = 5 * time.Minute
			}
			availableAt = time.Now().UTC().Add(delay)
		}
	}
	_, err := r.pg.ExecContext(ctx, `
		UPDATE matching.sos_delivery_outbox
		SET status=$2,available_at=$3,locked_at=NULL,worker_id=NULL,
		    last_error=NULLIF($4,''),delivered_at=CASE WHEN $2='delivered' THEN NOW() ELSE delivered_at END,
		    updated_at=NOW()
		WHERE id=$1::uuid AND status='processing'`, job.ID, status, availableAt, lastError)
	return err
}
