package mobile

import (
	"context"
	"crypto/sha256"
	"database/sql"
	"encoding/hex"
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/verified-dating/backend/internal/platform/config"
	"github.com/verified-dating/backend/internal/platform/observability"
)

var errIdempotencyPayloadConflict = errors.New("idempotency key was already used with a different request")
var errIdempotencyOutcomeUncertain = errors.New("the previous command outcome is uncertain and must be reconciled")

type postgresIdempotencyStore struct {
	db               *sql.DB
	ttl              time.Duration
	lease            time.Duration
	poll             time.Duration
	maxResponseBytes int
}

type postgresIdempotencyClaim struct {
	cacheKey   string
	ownerToken string
	response   idempotentResponse
	owner      bool
	replay     bool
}

type postgresIdempotencyHealth struct {
	processing       int64
	expiredLeases    int64
	retentionBacklog int64
}

func newPostgresIdempotencyStore(db *sql.DB, cfg config.Config) *postgresIdempotencyStore {
	if db == nil {
		return nil
	}
	ttl := cfg.IdempotencyTTL()
	if ttl <= 0 {
		ttl = 10 * time.Minute
	}
	lease := cfg.IdempotencyLease()
	if lease <= 0 {
		lease = 15 * time.Second
	}
	poll := cfg.IdempotencyPollInterval()
	if poll <= 0 {
		poll = 25 * time.Millisecond
	}
	maxResponseBytes := cfg.IdempotencyMaxResponseBytes
	if maxResponseBytes <= 0 {
		maxResponseBytes = 1 << 20
	}
	return &postgresIdempotencyStore{
		db: db, ttl: ttl, lease: lease, poll: poll, maxResponseBytes: maxResponseBytes,
	}
}

func idempotencyDigest(value string) string {
	sum := sha256.Sum256([]byte(value))
	return hex.EncodeToString(sum[:])
}

// claim either becomes the single owner of a request, returns a completed
// response, or waits for the owner in another BFF process. Expired leases can
// be taken over after a crashed process, using a compare-and-swap update.
func (s *postgresIdempotencyStore) claim(
	ctx context.Context,
	cacheNamespace, method, requestPath, actorID, idempotencyKey, requestHash string,
) (postgresIdempotencyClaim, error) {
	cacheKey := idempotencyDigest(cacheNamespace)
	for {
		ownerToken := uuid.NewString()
		result, err := s.db.ExecContext(ctx, `
			INSERT INTO platform.idempotency_records
			  (cache_key,method,request_path,actor_id,idempotency_key,request_hash,state,
			   owner_token,lease_expires_at,expires_at)
			VALUES ($1,$2,$3,$4,$5,$6,'processing',$7,
			        NOW()+make_interval(secs=>$8),NOW()+make_interval(secs=>$9))
			ON CONFLICT (cache_key) DO NOTHING`,
			cacheKey, method, requestPath, actorID, idempotencyKey, requestHash, ownerToken,
			int(s.lease.Seconds()), int(s.ttl.Seconds()),
		)
		if err != nil {
			return postgresIdempotencyClaim{}, err
		}
		if affected, _ := result.RowsAffected(); affected == 1 {
			return postgresIdempotencyClaim{cacheKey: cacheKey, ownerToken: ownerToken, owner: true}, nil
		}

		var (
			storedHash, state, contentType string
			status                         sql.NullInt64
			body                           []byte
			leaseExpired, replayExpired    bool
		)
		err = s.db.QueryRowContext(ctx, `
			SELECT request_hash,state,COALESCE(response_status,0),
			       COALESCE(response_content_type,''),COALESCE(response_body,''::BYTEA),
			       lease_expires_at<=NOW(),expires_at<=NOW()
			FROM platform.idempotency_records WHERE cache_key=$1`, cacheKey,
		).Scan(&storedHash, &state, &status, &contentType, &body, &leaseExpired, &replayExpired)
		if errors.Is(err, sql.ErrNoRows) {
			continue
		}
		if err != nil {
			return postgresIdempotencyClaim{}, err
		}
		if storedHash != requestHash {
			return postgresIdempotencyClaim{}, errIdempotencyPayloadConflict
		}
		if state == "completed" && !replayExpired {
			return postgresIdempotencyClaim{
				cacheKey: cacheKey,
				response: idempotentResponse{status: int(status.Int64), contentType: contentType, body: body},
				replay:   true,
			}, nil
		}
		if state == "completed" && replayExpired {
			_, _ = s.db.ExecContext(ctx,
				`DELETE FROM platform.idempotency_records WHERE cache_key=$1 AND state='completed' AND expires_at<=NOW()`,
				cacheKey,
			)
			continue
		}
		if leaseExpired && replayExpired {
			_, _ = s.db.ExecContext(ctx,
				`DELETE FROM platform.idempotency_records WHERE cache_key=$1 AND state='processing' AND lease_expires_at<=NOW() AND expires_at<=NOW()`,
				cacheKey,
			)
			continue
		}
		if leaseExpired {
			// The handler may have committed its aggregate and crashed before the
			// response was cached. Re-running here could duplicate the command.
			return postgresIdempotencyClaim{}, errIdempotencyOutcomeUncertain
		}

		timer := time.NewTimer(s.poll)
		select {
		case <-ctx.Done():
			timer.Stop()
			return postgresIdempotencyClaim{}, ctx.Err()
		case <-timer.C:
		}
	}
}

type postgresIdempotencyStatus struct {
	OperationID  string
	State        string
	HTTPStatus   int
	ContentType  string
	Body         []byte
	LeaseExpired bool
	UpdatedAt    time.Time
}

func (s *postgresIdempotencyStore) status(
	ctx context.Context, method, requestPath, actorID, idempotencyKey string,
) (postgresIdempotencyStatus, error) {
	cacheNamespace := strings.Join([]string{
		strings.ToUpper(strings.TrimSpace(method)), strings.TrimSpace(requestPath),
		strings.TrimSpace(actorID), strings.TrimSpace(idempotencyKey),
	}, "|")
	status := postgresIdempotencyStatus{OperationID: idempotencyDigest(cacheNamespace)}
	err := s.db.QueryRowContext(ctx, `
		SELECT state,COALESCE(response_status,0),COALESCE(response_content_type,''),
		       COALESCE(response_body,''::BYTEA),lease_expires_at<=NOW(),updated_at
		FROM platform.idempotency_records
		WHERE cache_key=$1 AND actor_id=$2`, status.OperationID, strings.TrimSpace(actorID),
	).Scan(&status.State, &status.HTTPStatus, &status.ContentType, &status.Body,
		&status.LeaseExpired, &status.UpdatedAt)
	return status, err
}

func (s *postgresIdempotencyStore) finish(ctx context.Context, claim postgresIdempotencyClaim, response idempotentResponse, cache bool) error {
	if !claim.owner {
		return nil
	}
	if !cache || len(response.body) > s.maxResponseBytes {
		_, err := s.db.ExecContext(ctx,
			`DELETE FROM platform.idempotency_records WHERE cache_key=$1 AND owner_token=$2 AND state='processing'`,
			claim.cacheKey, claim.ownerToken,
		)
		return err
	}
	_, err := s.db.ExecContext(ctx, `
		UPDATE platform.idempotency_records
		SET state='completed',response_status=$3,response_content_type=$4,response_body=$5,
		    completed_at=NOW(),updated_at=NOW(),lease_expires_at=NOW()
		WHERE cache_key=$1 AND owner_token=$2 AND state='processing'`,
		claim.cacheKey, claim.ownerToken, response.status, response.contentType, response.body,
	)
	return err
}

// archiveExpired archives expired idempotency records and runs the runtime
// retention classes, returning the rows each removed.
func (s *postgresIdempotencyStore) archiveExpired(ctx context.Context, batchSize int) (map[string]int, error) {
	if batchSize <= 0 {
		batchSize = 1000
	}
	purged := map[string]int{}
	var archived sql.NullInt64
	if err := s.db.QueryRowContext(ctx, `SELECT platform.archive_expired_idempotency($1)`, batchSize).Scan(&archived); err != nil {
		return purged, err
	}
	purged["idempotency_archive"] = int(archived.Int64)
	var notifications, realtime sql.NullInt64
	err := s.db.QueryRowContext(ctx, `SELECT * FROM platform.run_runtime_retention($1)`, batchSize).Scan(&notifications, &realtime)
	purged["notification_delivery_history"] = int(notifications.Int64)
	purged["realtime_delivery_history"] = int(realtime.Int64)
	return purged, err
}

func (s *postgresIdempotencyStore) health(ctx context.Context) (postgresIdempotencyHealth, error) {
	var health postgresIdempotencyHealth
	err := s.db.QueryRowContext(ctx, `
		SELECT processing,expired_leases,retention_backlog
		FROM platform.idempotency_health`,
	).Scan(&health.processing, &health.expiredLeases, &health.retentionBacklog)
	return health, err
}

func (s *Server) startIdempotencyCleanup() {
	if s.sharedIdempotency == nil {
		return
	}
	ctx, cancel := context.WithCancel(context.Background())
	s.idempotencyCleanupCancel = cancel
	s.idempotencyCleanupDone = make(chan struct{})
	go func() {
		defer close(s.idempotencyCleanupDone)
		s.runIdempotencyMaintenance(ctx)
		ticker := time.NewTicker(idempotencyRetentionInterval)
		defer ticker.Stop()
		for {
			select {
			case <-ctx.Done():
				return
			case <-ticker.C:
				s.runIdempotencyMaintenance(ctx)
			}
		}
	}()
}

func (s *Server) runIdempotencyMaintenance(parent context.Context) {
	heartbeat := observability.NewHeartbeat(workerIdempotencyRetention, idempotencyRetentionInterval)
	run := heartbeat.Begin()
	ctx, cancel := context.WithTimeout(parent, 5*time.Second)
	defer cancel()
	purged, err := s.sharedIdempotency.archiveExpired(ctx, 1000)
	total := 0
	for _, n := range purged {
		total += n
	}
	run.Items("processed", total)
	run.Detail("purged", purged)
	run.End(err)
	if err != nil {
		if s.log != nil {
			s.log.Warn("idempotency retention batch failed")
		}
		return
	}
	health, err := s.sharedIdempotency.health(ctx)
	if err != nil || s.httpMetrics == nil {
		return
	}
	s.httpMetrics.IdempotencyProcessing.Set(float64(health.processing))
	s.httpMetrics.IdempotencyExpiredLeases.Set(float64(health.expiredLeases))
	s.httpMetrics.IdempotencyRetentionBacklog.Set(float64(health.retentionBacklog))
	heartbeat.SetBacklog(float64(health.retentionBacklog))
	stats := s.sharedIdempotency.db.Stats()
	s.httpMetrics.PostgresOpenConnections.Set(float64(stats.OpenConnections))
	s.httpMetrics.PostgresInUseConnections.Set(float64(stats.InUse))
}
