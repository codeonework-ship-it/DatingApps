package mobile

import (
	"bufio"
	"context"
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"

	"go.uber.org/zap"

	"github.com/verified-dating/backend/internal/platform/observability"
)

// XP award durability (PEN-22).
//
// An award used to be attempted after the product action, and only a failure
// enqueued a repair — in a fresh 2-second context. If the database was down
// (exactly when awards fail) or the process died in between, the award was
// lost and only logged. Now:
//
//  1. Write-ahead: before attempting the award, a `pending` intent is written
//     to progression.xp_award_repair_queue, available to the repair worker
//     only after a grace period. A process that dies mid-award leaves the
//     intent behind and the worker completes it.
//  2. The direct award then runs; success or suppression closes the intent.
//  3. If the intent cannot be written (database unreachable), it is spooled
//     to an append-only local file and replayed into the queue once the
//     database is back, including after a restart.
//
// Awards are idempotent on (user, idempotency key), so a replayed or repaired
// intent can never award twice.

const xpAwardIntentGrace = 60 * time.Second

// writeAheadAwardIntent records the award before it is attempted. An existing
// row for the same key is left untouched.
func (r *levelProgressionRepository) writeAheadAwardIntent(ctx context.Context, input xpAwardInput) error {
	payload, err := json.Marshal(newXPAwardRepairPayload(input))
	if err != nil {
		return err
	}
	_, err = r.db.ExecContext(ctx, `
		INSERT INTO progression.xp_award_repair_queue
		  (user_id,source,source_event_id,idempotency_key,input,status,available_at,last_error)
		VALUES ($1,$2,NULLIF($3,''),$4,$5,'pending',NOW()+make_interval(secs=>$6),'write-ahead intent')
		ON CONFLICT (user_id,idempotency_key) DO NOTHING`,
		strings.TrimSpace(input.UserID), strings.TrimSpace(input.Source), strings.TrimSpace(input.SourceEventID),
		strings.TrimSpace(input.IdempotencyKey), payload, int(xpAwardIntentGrace.Seconds()))
	return err
}

// closeAwardIntent marks a still-pending write-ahead intent as done.
func (r *levelProgressionRepository) closeAwardIntent(ctx context.Context, input xpAwardInput, status string, cause error) error {
	lastError := ""
	if cause != nil {
		lastError = cause.Error()
	}
	_, err := r.db.ExecContext(ctx, `
		UPDATE progression.xp_award_repair_queue
		SET status=$3, completed_at=NOW(), last_error=NULLIF($4,''), updated_at=NOW()
		WHERE user_id=$1 AND idempotency_key=$2 AND status='pending'`,
		strings.TrimSpace(input.UserID), strings.TrimSpace(input.IdempotencyKey), status, lastError)
	return err
}

// awardProgressionDurably is the award path used by product actions.
func (s *Server) awardProgressionDurably(ctx context.Context, input xpAwardInput) {
	if s.progression == nil {
		return
	}
	// XP is excluded from the first release in production-like environments.
	if s.cfg.IsReleaseExcluded("level_progression_enabled") {
		return
	}
	intentCtx, cancel := context.WithTimeout(context.WithoutCancel(ctx), 2*time.Second)
	intentErr := s.progression.writeAheadAwardIntent(intentCtx, input)
	cancel()
	if intentErr != nil {
		s.spoolProgressionAward(input, intentErr)
	}

	enabled, err := s.runtimeFeatureEnabled(ctx, "level_progression_enabled", true)
	if err != nil {
		// The intent (or its spooled copy) is still owed; the repair worker
		// re-checks nothing about flags, so leave it pending for review.
		s.enqueueProgressionRepair(input, err)
		return
	}
	closeCtx := context.WithoutCancel(ctx)
	if !enabled {
		_ = s.progression.closeAwardIntent(closeCtx, input, "suppressed", errors.New("level progression disabled"))
		return
	}
	_, err = s.progression.awardXP(ctx, input)
	switch {
	case err == nil:
		_ = s.progression.closeAwardIntent(closeCtx, input, "completed", nil)
	case errors.Is(err, errXPCapReached), errors.Is(err, errProgressionFrozen):
		_ = s.progression.closeAwardIntent(closeCtx, input, "suppressed", err)
	default:
		s.enqueueProgressionRepair(input, err)
	}
}

func (s *Server) spoolProgressionAward(input xpAwardInput, cause error) {
	if s.xpAwardSpool == nil {
		if s.log != nil {
			s.log.Error("progression_award_lost_no_spool", zap.String("source", input.Source), zap.Error(cause))
		}
		return
	}
	if err := s.xpAwardSpool.append(input); err != nil && s.log != nil {
		s.log.Error("progression_award_spool_failed", zap.String("source", input.Source), zap.Error(err))
	}
}

// xpAwardSpool is an append-only JSON-lines file of award intents that could
// not reach the database. A background loop replays it into the repair queue.
type xpAwardSpool struct {
	path   string
	log    *zap.Logger
	mu     sync.Mutex
	cancel context.CancelFunc
	done   sync.WaitGroup
}

func newXPAwardSpool(path string, log *zap.Logger) *xpAwardSpool {
	if strings.TrimSpace(path) == "" {
		return nil
	}
	if log == nil {
		log = zap.NewNop()
	}
	return &xpAwardSpool{path: path, log: log}
}

func defaultXPAwardSpoolPath() string {
	if value := strings.TrimSpace(os.Getenv("PROGRESSION_AWARD_SPOOL_PATH")); value != "" {
		return value
	}
	dir, err := os.UserCacheDir()
	if err != nil || dir == "" {
		dir = os.TempDir()
	}
	return filepath.Join(dir, "verified-dating", "xp-award-spool.jsonl")
}

func (sp *xpAwardSpool) append(input xpAwardInput) error {
	line, err := json.Marshal(newXPAwardRepairPayload(input))
	if err != nil {
		return err
	}
	sp.mu.Lock()
	defer sp.mu.Unlock()
	if err := os.MkdirAll(filepath.Dir(sp.path), 0o700); err != nil {
		return err
	}
	file, err := os.OpenFile(sp.path, os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0o600)
	if err != nil {
		return err
	}
	if _, err := file.Write(append(line, '\n')); err != nil {
		_ = file.Close()
		return err
	}
	if err := file.Sync(); err != nil {
		_ = file.Close()
		return err
	}
	return file.Close()
}

// replay moves spooled intents into the repair queue. Lines that still fail
// are kept for the next pass; the file is rewritten atomically.
func (sp *xpAwardSpool) replay(ctx context.Context, enqueue func(context.Context, xpAwardInput, error) error) (int, error) {
	sp.mu.Lock()
	defer sp.mu.Unlock()
	file, err := os.Open(sp.path)
	if errors.Is(err, os.ErrNotExist) {
		return 0, nil
	}
	if err != nil {
		return 0, err
	}
	var kept [][]byte
	replayed := 0
	scanner := bufio.NewScanner(file)
	scanner.Buffer(make([]byte, 0, 64*1024), 1024*1024)
	for scanner.Scan() {
		line := append([]byte(nil), scanner.Bytes()...)
		if len(strings.TrimSpace(string(line))) == 0 {
			continue
		}
		var payload xpAwardRepairPayload
		if err := json.Unmarshal(line, &payload); err != nil {
			sp.log.Error("progression_award_spool_corrupt_line", zap.Error(err))
			continue
		}
		if err := enqueue(ctx, payload.awardInput(), errors.New("replayed from local award spool")); err != nil {
			kept = append(kept, line)
			continue
		}
		replayed++
	}
	_ = file.Close()
	if err := scanner.Err(); err != nil {
		return replayed, err
	}
	tmp := sp.path + ".tmp"
	var buf []byte
	for _, line := range kept {
		buf = append(buf, line...)
		buf = append(buf, '\n')
	}
	if err := os.WriteFile(tmp, buf, 0o600); err != nil {
		return replayed, err
	}
	return replayed, os.Rename(tmp, sp.path)
}

func (sp *xpAwardSpool) Start(parent context.Context, enqueue func(context.Context, xpAwardInput, error) error) {
	if sp == nil || sp.cancel != nil || enqueue == nil {
		return
	}
	ctx, cancel := context.WithCancel(parent)
	sp.cancel = cancel
	sp.done.Add(1)
	go func() {
		defer sp.done.Done()
		ticker := time.NewTicker(30 * time.Second)
		defer ticker.Stop()
		heartbeat := observability.NewHeartbeat(workerXPAwardSpoolReplay, 30*time.Second)
		for {
			run := heartbeat.Begin()
			n, err := sp.replay(ctx, enqueue)
			run.Items("processed", n)
			run.End(err)
			if err != nil {
				sp.log.Warn("progression_award_spool_replay_failed", zap.Error(err))
			} else if n > 0 {
				sp.log.Info("progression_award_spool_replayed", zap.Int("intents", n))
			}
			select {
			case <-ctx.Done():
				return
			case <-ticker.C:
			}
		}
	}()
}

func (sp *xpAwardSpool) Stop() {
	if sp == nil || sp.cancel == nil {
		return
	}
	sp.cancel()
	sp.done.Wait()
}
