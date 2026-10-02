package mobile

import (
	"context"
	"database/sql"
	"errors"
	"strconv"
	"sync"
	"time"

	"go.uber.org/zap"

	"github.com/verified-dating/backend/internal/platform/observability"
)

// The support SLA worker (heartbeat "support_sla") runs every few minutes:
//   - latches first-response and resolution breaches (and records them in
//     each ticket's trail),
//   - auto-closes tickets resolved for 7 days without a member reply,
//   - releases attachment bytes marked for deletion and uploads never
//     attached to a message (24 h),
//   - purges tickets past retention: member tickets 24 months after closing,
//     website (contact form) tickets 12 months after closing, skipping
//     members on a legal hold,
//   - refreshes the verified_dating_support_* gauges.

const (
	workerSupportSLA            = "support_sla"
	supportSLAWorkerInterval    = 5 * time.Minute
	supportMemberRetention      = 730 * 24 * time.Hour
	supportContactRetention     = 365 * 24 * time.Hour
	supportWorkerBatch          = 200
	supportAttachmentReleaseMax = 500
)

type supportSLAWorker struct {
	server   *Server
	db       *sql.DB
	log      *zap.Logger
	interval time.Duration
	cancel   context.CancelFunc
	done     sync.WaitGroup
}

func newSupportSLAWorker(server *Server, db *sql.DB, log *zap.Logger, interval time.Duration) *supportSLAWorker {
	if server == nil || db == nil {
		return nil
	}
	if log == nil {
		log = zap.NewNop()
	}
	if interval <= 0 {
		interval = supportSLAWorkerInterval
	}
	return &supportSLAWorker{server: server, db: db, log: log, interval: interval}
}

func (w *supportSLAWorker) Start(parent context.Context) {
	if w == nil || w.cancel != nil {
		return
	}
	ctx, cancel := context.WithCancel(parent)
	w.cancel = cancel
	w.done.Add(1)
	go func() {
		defer w.done.Done()
		ticker := time.NewTicker(w.interval)
		defer ticker.Stop()
		w.cycle(ctx)
		for {
			select {
			case <-ctx.Done():
				return
			case <-ticker.C:
				w.cycle(ctx)
			}
		}
	}()
}

func (w *supportSLAWorker) Stop() {
	if w == nil || w.cancel == nil {
		return
	}
	w.cancel()
	w.done.Wait()
}

func (w *supportSLAWorker) cycle(ctx context.Context) {
	beat := observability.NewHeartbeat(workerSupportSLA, w.interval).Begin()
	result, err := w.server.runSupportMaintenance(ctx, w.db, time.Now().UTC())
	beat.Items("processed", result.Breaches+result.AutoClosed+result.AttachmentsReleased+result.TicketsPurged)
	beat.End(err)
	if err != nil && !errors.Is(err, context.Canceled) {
		w.log.Error("support_sla_cycle_failed", zap.Error(err))
		return
	}
	if result.Breaches+result.AutoClosed+result.AttachmentsReleased+result.TicketsPurged > 0 {
		w.log.Info("support_sla_cycle", zap.Int("breaches", result.Breaches), zap.Int("auto_closed", result.AutoClosed),
			zap.Int("attachments_released", result.AttachmentsReleased), zap.Int("tickets_purged", result.TicketsPurged))
	}
}

type supportMaintenanceResult struct {
	Breaches            int
	AutoClosed          int
	AttachmentsReleased int
	TicketsPurged       int
}

// runSupportMaintenance performs one worker pass; exported to tests.
func (s *Server) runSupportMaintenance(ctx context.Context, db *sql.DB, now time.Time) (supportMaintenanceResult, error) {
	var result supportMaintenanceResult
	var err error
	if result.Breaches, err = supportLatchBreaches(ctx, db, now); err != nil {
		return result, err
	}
	if result.AutoClosed, err = supportAutoClose(ctx, db, now); err != nil {
		return result, err
	}
	if err = supportMarkExpiredTickets(ctx, db, now); err != nil {
		return result, err
	}
	if result.AttachmentsReleased, err = s.releaseSupportAttachments(ctx, db, now, supportAttachmentReleaseMax); err != nil {
		return result, err
	}
	if result.TicketsPurged, err = supportPurgeExpiredTickets(ctx, db, now); err != nil {
		return result, err
	}
	return result, supportRefreshGauges(ctx, db)
}

// supportLatchBreaches sets the breach flags of active tickets past a target
// and records an sla_breached event for each newly latched target.
func supportLatchBreaches(ctx context.Context, db *sql.DB, now time.Time) (int, error) {
	total := 0
	for _, target := range []struct{ name, set, condition string }{
		{"first_response", "first_response_breached=TRUE", `NOT t.first_response_breached AND t.first_responded_at IS NULL AND t.first_response_due_at < $1`},
		{"resolution", "resolution_breached=TRUE", `NOT t.resolution_breached AND t.status <> 'pending_member' AND t.resolution_due_at < $1`},
	} {
		tx, err := db.BeginTx(ctx, nil)
		if err != nil {
			return total, err
		}
		rows, err := tx.QueryContext(ctx, `UPDATE support.tickets t SET `+target.set+`, updated_at=NOW()
			WHERE t.id IN (SELECT t.id FROM support.tickets t WHERE `+supportActiveSQL+` AND `+target.condition+`
			               ORDER BY t.created_at LIMIT `+strconv.Itoa(supportWorkerBatch)+` FOR UPDATE SKIP LOCKED)
			RETURNING t.id::text`, now)
		if err != nil {
			_ = tx.Rollback()
			return total, err
		}
		ids := []string{}
		for rows.Next() {
			var id string
			if err := rows.Scan(&id); err != nil {
				rows.Close()
				_ = tx.Rollback()
				return total, err
			}
			ids = append(ids, id)
		}
		rows.Close()
		for _, id := range ids {
			if err := insertSupportEventTx(ctx, tx, id, supportActor{Kind: "system"}, "sla_breached", "", target.name, nil); err != nil {
				_ = tx.Rollback()
				return total, err
			}
		}
		if err := tx.Commit(); err != nil {
			return total, err
		}
		total += len(ids)
	}
	return total, nil
}

// supportAutoClose closes tickets resolved for supportAutoCloseAfter with no
// member reply since. A later member reply inside the reopen window still
// reopens them.
func supportAutoClose(ctx context.Context, db *sql.DB, now time.Time) (int, error) {
	rows, err := db.QueryContext(ctx, `SELECT t.id::text FROM support.tickets t
		WHERE t.status='resolved' AND t.resolved_at < $1
		  AND (t.last_member_message_at IS NULL OR t.last_member_message_at <= t.resolved_at)
		ORDER BY t.resolved_at LIMIT `+strconv.Itoa(supportWorkerBatch), now.Add(-supportAutoCloseAfter))
	if err != nil {
		return 0, err
	}
	ids := []string{}
	for rows.Next() {
		var id string
		if err := rows.Scan(&id); err != nil {
			rows.Close()
			return 0, err
		}
		ids = append(ids, id)
	}
	rows.Close()
	closed := 0
	for _, id := range ids {
		err := func() error {
			tx, err := db.BeginTx(ctx, nil)
			if err != nil {
				return err
			}
			defer func() { _ = tx.Rollback() }()
			t, err := loadSupportTicket(ctx, tx, id, true)
			if err != nil {
				return err
			}
			if t.Status != "resolved" || t.ResolvedAt == nil || t.ResolvedAt.After(now.Add(-supportAutoCloseAfter)) {
				return nil
			}
			t.setStatus("closed", now)
			if err = saveSupportTicketTx(ctx, tx, t, now); err != nil {
				return err
			}
			if err = insertSupportEventTx(ctx, tx, t.ID, supportActor{Kind: "system"}, "auto_closed", "resolved", "closed", nil); err != nil {
				return err
			}
			closed++
			return tx.Commit()
		}()
		if err != nil {
			return closed, err
		}
	}
	return closed, nil
}

// supportExpiredTicketsSQL selects tickets past retention.
const supportExpiredTicketsSQL = `t.status='closed' AND (
	  (t.requester_member_id IS NULL AND t.closed_at < $1) OR
	  (t.requester_member_id IS NOT NULL AND t.closed_at < $2 AND NOT platform.member_on_legal_hold(t.requester_member_id)))`

// supportMarkExpiredTickets queues the attachments of expired tickets for
// release; the tickets go once no attachment is left.
func supportMarkExpiredTickets(ctx context.Context, db *sql.DB, now time.Time) error {
	_, err := db.ExecContext(ctx, `UPDATE support.ticket_attachments a SET deleted_at=$3
		WHERE a.deleted_at IS NULL AND a.ticket_id IN (SELECT t.id FROM support.tickets t WHERE `+supportExpiredTicketsSQL+`)`,
		now.Add(-supportContactRetention), now.Add(-supportMemberRetention), now)
	return err
}

func supportPurgeExpiredTickets(ctx context.Context, db *sql.DB, now time.Time) (int, error) {
	// Merged sources point at their target; clear those links first.
	result, err := db.ExecContext(ctx, `DELETE FROM support.tickets t WHERE t.id IN (
		  SELECT t.id FROM support.tickets t WHERE `+supportExpiredTicketsSQL+`
		    AND NOT EXISTS (SELECT 1 FROM support.ticket_attachments a WHERE a.ticket_id=t.id)
		  ORDER BY t.closed_at LIMIT `+strconv.Itoa(supportWorkerBatch)+`)`,
		now.Add(-supportContactRetention), now.Add(-supportMemberRetention))
	if err != nil {
		return 0, err
	}
	n, _ := result.RowsAffected()
	return int(n), nil
}

func supportRefreshGauges(ctx context.Context, db *sql.DB) error {
	for _, priority := range []string{"low", "normal", "high", "urgent"} {
		supportOpenTickets.WithLabelValues(priority).Set(0)
	}
	rows, err := db.QueryContext(ctx, `SELECT t.priority, COUNT(*) FROM support.tickets t WHERE `+supportActiveSQL+` GROUP BY 1`)
	if err != nil {
		return err
	}
	for rows.Next() {
		var priority string
		var n float64
		if err := rows.Scan(&priority, &n); err != nil {
			rows.Close()
			return err
		}
		supportOpenTickets.WithLabelValues(priority).Set(n)
	}
	rows.Close()
	var first, resolution float64
	if err := db.QueryRowContext(ctx, `SELECT
		  COUNT(*) FILTER (WHERE t.first_responded_at IS NULL AND t.first_response_due_at < NOW()),
		  COUNT(*) FILTER (WHERE t.status <> 'pending_member' AND t.resolution_due_at < NOW())
		FROM support.tickets t WHERE `+supportActiveSQL).Scan(&first, &resolution); err != nil {
		return err
	}
	supportSLABreaches.WithLabelValues("first_response").Set(first)
	supportSLABreaches.WithLabelValues("resolution").Set(resolution)
	return nil
}
