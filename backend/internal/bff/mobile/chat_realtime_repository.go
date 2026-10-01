package mobile

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"strings"
	"time"
)

type chatRealtimeEvent struct {
	Sequence   int64          `json:"sequence"`
	EventID    string         `json:"event_id"`
	Type       string         `json:"type"`
	MatchID    string         `json:"match_id,omitempty"`
	Payload    map[string]any `json:"payload"`
	OccurredAt string         `json:"occurred_at"`
}

type chatRealtimeEventStore interface {
	listEvents(context.Context, string, int64, int) ([]chatRealtimeEvent, error)
	markDelivered(context.Context, string, int64) error
}

type chatRealtimeRepository struct {
	db *sql.DB
}

func newChatRealtimeRepository(db *sql.DB) *chatRealtimeRepository {
	if db == nil {
		return nil
	}
	return &chatRealtimeRepository{db: db}
}

func (r *chatRealtimeRepository) listEvents(
	ctx context.Context,
	userID string,
	after int64,
	limit int,
) ([]chatRealtimeEvent, error) {
	if r == nil || r.db == nil {
		return nil, errors.New("chat realtime repository is unavailable")
	}
	userID = strings.TrimSpace(userID)
	if userID == "" {
		return nil, errors.New("recipient user id is required")
	}
	if after < 0 {
		return nil, errors.New("realtime cursor must not be negative")
	}
	if limit <= 0 || limit > 500 {
		limit = 100
	}

	rows, err := r.db.QueryContext(ctx, `
		SELECT sequence_id, event_id::text, event_type,
		       COALESCE(match_id::text, ''), payload, occurred_at
		FROM matching.realtime_outbox
		WHERE recipient_user_id=$1
		  AND sequence_id>$2
		  AND expires_at>NOW()
		  AND (
		    match_id IS NULL OR EXISTS (
		      SELECT 1
		      FROM matching.matches m
		      WHERE m.id=matching.realtime_outbox.match_id
		        AND (m.user_id_1=$1::uuid OR m.user_id_2=$1::uuid)
		        AND m.user_1_status='active' AND m.user_2_status='active'
		        AND NOT m.user_1_blocked AND NOT m.user_2_blocked
		        AND m.unmatched_at IS NULL
		        AND NOT EXISTS (
		          SELECT 1 FROM user_management.blocked_users b
		          WHERE (b.user_id=m.user_id_1 AND b.blocked_user_id=m.user_id_2)
		             OR (b.user_id=m.user_id_2 AND b.blocked_user_id=m.user_id_1)
		        )
		    )
		  )
		ORDER BY sequence_id
		LIMIT $3`, userID, after, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	events := make([]chatRealtimeEvent, 0, limit)
	for rows.Next() {
		var event chatRealtimeEvent
		var payloadJSON []byte
		var occurredAt time.Time
		if err := rows.Scan(
			&event.Sequence,
			&event.EventID,
			&event.Type,
			&event.MatchID,
			&payloadJSON,
			&occurredAt,
		); err != nil {
			return nil, err
		}
		if err := json.Unmarshal(payloadJSON, &event.Payload); err != nil {
			return nil, err
		}
		if event.Payload == nil {
			event.Payload = map[string]any{}
		}
		event.OccurredAt = occurredAt.UTC().Format(time.RFC3339Nano)
		events = append(events, event)
	}
	return events, rows.Err()
}

func (r *chatRealtimeRepository) markDelivered(ctx context.Context, userID string, sequence int64) error {
	if r == nil || r.db == nil {
		return errors.New("chat realtime repository is unavailable")
	}
	tx, err := r.db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelReadCommitted})
	if err != nil {
		return err
	}
	defer func() { _ = tx.Rollback() }()

	var eventType string
	var payloadJSON []byte
	err = tx.QueryRowContext(ctx, `
		UPDATE matching.realtime_outbox
		SET delivered_at=COALESCE(delivered_at, NOW())
		WHERE sequence_id=$1 AND recipient_user_id=$2
		RETURNING event_type, payload`, sequence, strings.TrimSpace(userID)).Scan(&eventType, &payloadJSON)
	if err != nil {
		return err
	}
	if eventType == "message.created" {
		var payload struct {
			MessageID string `json:"message_id"`
		}
		if err := json.Unmarshal(payloadJSON, &payload); err != nil {
			return err
		}
		if strings.TrimSpace(payload.MessageID) != "" {
			if _, err := tx.ExecContext(ctx, `
				UPDATE matching.messages
				SET delivered_at=COALESCE(delivered_at, NOW())
				WHERE id=$1`, payload.MessageID); err != nil {
				return err
			}
		}
	}
	return tx.Commit()
}
