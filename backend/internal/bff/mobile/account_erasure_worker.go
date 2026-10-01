package mobile

import (
	"context"
	"sync"
	"time"

	"go.uber.org/zap"

	"github.com/verified-dating/backend/internal/platform/observability"
)

// accountErasureWorker completes scheduled deletions once their grace period
// has elapsed, and prunes expired export payloads.
//
// A separate worker rather than work done on the request: the grace period
// means the erasure happens days after anyone is holding the connection, so
// something has to come back for it. Without this the deletion journey stops at
// "scheduled" and the member's data stays indefinitely — a deletion promise the
// product never keeps.
type accountErasureWorker struct {
	repo         *profileRepository
	log          *zap.Logger
	pollInterval time.Duration
	batchSize    int
	// deleteObject releases one stored object. Injected because the storage
	// backend lives on the Server, and because erasure must drive the deletion
	// itself rather than hope an orphan sweep notices: that sweep reads the
	// referenced-path set from the photo rows erasure has already deleted, and
	// on S3 it does not run at all.
	deleteObject func(storagePath string) error

	cancel context.CancelFunc
	done   sync.WaitGroup
}

func newAccountErasureWorker(
	repo *profileRepository,
	log *zap.Logger,
	pollInterval time.Duration,
	batchSize int,
	deleteObject func(storagePath string) error,
) *accountErasureWorker {
	if pollInterval <= 0 {
		pollInterval = time.Hour
	}
	if batchSize <= 0 {
		batchSize = 25
	}
	return &accountErasureWorker{
		repo:         repo,
		log:          log,
		pollInterval: pollInterval,
		batchSize:    batchSize,
		deleteObject: deleteObject,
	}
}

func (w *accountErasureWorker) Start(parent context.Context) {
	// Requires the native PostgreSQL path: erasure is a multi-table
	// transaction and must not run against a degraded store.
	if w == nil || w.repo == nil || w.repo.pg == nil || w.cancel != nil {
		return
	}
	ctx, cancel := context.WithCancel(parent)
	w.cancel = cancel
	w.done.Add(1)
	go w.run(ctx)
}

func (w *accountErasureWorker) Stop() {
	if w == nil || w.cancel == nil {
		return
	}
	w.cancel()
	w.cancel = nil
	w.done.Wait()
}

func (w *accountErasureWorker) run(ctx context.Context) {
	defer w.done.Done()
	ticker := time.NewTicker(w.pollInterval)
	defer ticker.Stop()
	for {
		w.RunOnce(ctx)
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
		}
	}
}

// RunOnce performs a single sweep. Exported so a script or test can drive the
// worker deterministically instead of waiting on the ticker.
func (w *accountErasureWorker) RunOnce(ctx context.Context) (erased int, pruned int) {
	if w == nil || w.repo == nil || w.repo.pg == nil {
		return 0, 0
	}
	run := observability.NewHeartbeat(workerAccountErasure, w.pollInterval).Begin()
	var runErr error
	failed := 0
	defer func() {
		run.Items("processed", erased)
		run.Items("failed", failed)
		run.End(runErr)
	}()
	due, err := w.repo.dueAccountErasures(ctx, w.batchSize)
	if err != nil {
		runErr = err
		w.logWarn("account_erasure_scan_failed", zap.Error(err))
		return 0, 0
	}
	for _, userID := range due {
		summary, eraseErr := w.repo.eraseAccount(ctx, userID, "", "system")
		if eraseErr != nil {
			// One member's failure must not stop the sweep: a row that cannot
			// be erased today is retried on the next pass, and stopping here
			// would let a single bad record block every other deletion.
			failed++
			w.logWarn("account_erasure_failed",
				zap.String("user_id", userID), zap.Error(eraseErr))
			continue
		}
		erased++
		w.logInfo("account_erased",
			zap.String("user_id", userID),
			zap.Int("sessions_revoked", summary.SessionsRevoked),
			zap.Int("storage_paths_released", len(summary.StoragePaths)))
	}

	w.releasePendingStorage(ctx)

	pruned, err = w.repo.pruneExpiredExports(ctx)
	if err != nil {
		runErr = err
		w.logWarn("account_export_prune_failed", zap.Error(err))
	} else if pruned > 0 {
		w.logInfo("account_exports_pruned", zap.Int("count", pruned))
	}
	return erased, pruned
}

func (w *accountErasureWorker) logWarn(message string, fields ...zap.Field) {
	if w.log != nil {
		w.log.Warn(message, fields...)
	}
}

func (w *accountErasureWorker) logInfo(message string, fields ...zap.Field) {
	if w.log != nil {
		w.log.Info(message, fields...)
	}
}

// releasePendingStorage deletes the objects belonging to erased accounts.
//
// Runs as its own pass rather than inline with the erasure so a storage backend
// that is briefly unreachable does not roll back an otherwise complete erasure,
// and so a failure is retried on the next sweep instead of being lost with the
// photo rows.
func (w *accountErasureWorker) releasePendingStorage(ctx context.Context) {
	if w.deleteObject == nil {
		// Without a deleter the objects would be silently abandoned, which is
		// the defect this pass exists to fix. Say so rather than no-op quietly.
		w.logWarn("account_storage_release_skipped_no_deleter")
		return
	}
	pending, err := w.repo.pendingStorageReleases(ctx, w.batchSize)
	if err != nil {
		w.logWarn("account_storage_release_scan_failed", zap.Error(err))
		return
	}
	for _, item := range pending {
		failed := w.releaseObjects(item.UserID, item.Paths)
		if failed > 0 {
			// Leave the marker unset so the remaining objects are retried.
			continue
		}
		if markErr := w.repo.markStorageReleased(ctx, item.RequestID); markErr != nil {
			w.logWarn("account_storage_release_mark_failed",
				zap.String("user_id", item.UserID), zap.Error(markErr))
			continue
		}
		w.logInfo("account_storage_released",
			zap.String("user_id", item.UserID),
			zap.Int("objects", len(item.Paths)))
	}
}

// releaseObjects deletes each stored object and returns how many failed.
//
// Split out so the retry rule is testable without a database: any failure must
// leave the release unmarked, because marking it would strand the remaining
// objects with nothing left pointing at them.
func (w *accountErasureWorker) releaseObjects(userID string, paths []string) int {
	failed := 0
	for _, path := range paths {
		if path == "" {
			continue
		}
		if err := w.deleteObject(path); err != nil {
			failed++
			w.logWarn("account_storage_object_delete_failed",
				zap.String("user_id", userID), zap.Error(err))
		}
	}
	return failed
}
