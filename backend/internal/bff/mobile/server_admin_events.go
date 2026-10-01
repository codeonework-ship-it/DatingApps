package mobile

import (
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"time"
)

func eventFilterSQL(queryValues map[string][]string) (string, []any) {
	clauses := []string{"TRUE"}
	args := make([]any, 0, 7)
	add := func(column, key string) {
		value := strings.TrimSpace(firstQueryValue(queryValues, key))
		if value == "" {
			return
		}
		args = append(args, value)
		clauses = append(clauses, fmt.Sprintf("%s = $%d", column, len(args)))
	}
	add("event_name", "event_name")
	add("aggregate_type", "aggregate_type")
	add("aggregate_id", "aggregate_id")
	add("producer", "producer")
	add("correlation_id", "correlation_id")
	add("subject_user_id::text", "subject_user_id")
	if raw := strings.TrimSpace(firstQueryValue(queryValues, "after_sequence")); raw != "" {
		if sequence, err := strconv.ParseInt(raw, 10, 64); err == nil && sequence >= 0 {
			args = append(args, sequence)
			clauses = append(clauses, fmt.Sprintf("sequence_id > $%d", len(args)))
		}
	}
	return strings.Join(clauses, " AND "), args
}

func firstQueryValue(values map[string][]string, key string) string {
	items := values[key]
	if len(items) == 0 {
		return ""
	}
	return items[0]
}

// adminListDomainEvents exposes the canonical, privacy-safe event envelope.
// It is intentionally read-only: replay is performed by named consumers via
// the database claim/ack contract, not by mutating event facts through HTTP.
func (s *Server) adminListDomainEvents(w http.ResponseWriter, r *http.Request) {
	if err := requireAdminUser(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	if s.store == nil || s.store.adminRepo == nil || s.store.adminRepo.pg == nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("domain event store unavailable"))
		return
	}

	limit := 100
	if raw := strings.TrimSpace(r.URL.Query().Get("limit")); raw != "" {
		if parsed, err := strconv.Atoi(raw); err == nil && parsed > 0 && parsed <= 500 {
			limit = parsed
		}
	}
	whereSQL, args := eventFilterSQL(r.URL.Query())
	args = append(args, limit)
	order := "DESC"
	if strings.TrimSpace(r.URL.Query().Get("after_sequence")) != "" {
		order = "ASC"
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	rows, err := s.store.adminRepo.pg.QueryContext(ctx, fmt.Sprintf(`
		SELECT sequence_id,event_id::text,event_name,event_version,aggregate_type,
		       aggregate_id,producer,COALESCE(subject_user_id::text,''),
		       COALESCE(actor_user_id::text,''),COALESCE(correlation_id,''),
		       COALESCE(causation_id::text,''),payload,metadata,occurred_at
		FROM platform.domain_event_outbox
		WHERE %s
		ORDER BY sequence_id %s
		LIMIT $%d`, whereSQL, order, len(args)), args...)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	defer rows.Close()

	events := make([]map[string]any, 0, limit)
	for rows.Next() {
		var sequence int64
		var version int
		var eventID, eventName, aggregateType, aggregateID, producer string
		var subjectID, actorID, correlationID, causationID string
		var rawPayload, rawMetadata []byte
		var occurredAt time.Time
		if err := rows.Scan(
			&sequence, &eventID, &eventName, &version, &aggregateType, &aggregateID,
			&producer, &subjectID, &actorID, &correlationID, &causationID,
			&rawPayload, &rawMetadata, &occurredAt,
		); err != nil {
			writeError(w, http.StatusBadGateway, err)
			return
		}
		payload, metadata := map[string]any{}, map[string]any{}
		_ = json.Unmarshal(rawPayload, &payload)
		_ = json.Unmarshal(rawMetadata, &metadata)
		events = append(events, map[string]any{
			"sequence_id": sequence, "event_id": eventID, "event_name": eventName,
			"event_version": version, "aggregate_type": aggregateType, "aggregate_id": aggregateID,
			"producer": producer, "subject_user_id": subjectID, "actor_user_id": actorID,
			"correlation_id": correlationID, "causation_id": causationID,
			"payload": payload, "metadata": metadata, "occurred_at": occurredAt.UTC(),
		})
	}
	if err := rows.Err(); err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"events": events, "count": len(events), "limit": limit,
		"source": "platform.domain_event_outbox", "append_only": true,
		"delivery": "at_least_once", "as_of": time.Now().UTC(),
	})
}

func (s *Server) adminDomainEventMetrics(w http.ResponseWriter, r *http.Request) {
	if err := requireAdminUser(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	if s.store == nil || s.store.adminRepo == nil || s.store.adminRepo.pg == nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("domain event store unavailable"))
		return
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	var total, recent, pending, processing, deadLetters, oldest int64
	err := s.store.adminRepo.pg.QueryRowContext(ctx, `
		SELECT total_events,events_15m,pending_deliveries,processing_deliveries,
		       dead_letters,oldest_pending_age_seconds
		FROM platform.domain_event_pipeline_metrics
	`).Scan(&total, &recent, &pending, &processing, &deadLetters, &oldest)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	var registered, unregistered int64
	err = s.store.adminRepo.pg.QueryRowContext(ctx, `
		SELECT
		  (SELECT COUNT(*) FROM platform.event_source_registry WHERE enabled),
		  COUNT(*)
		FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
		WHERE n.nspname IN ('user_management','matching','progression','audit')
		  AND c.relkind IN ('r','p') AND NOT c.relispartition
		  AND NOT EXISTS (
		    SELECT 1 FROM platform.event_source_registry r
		    WHERE r.source_schema=n.nspname AND r.source_table=c.relname AND r.enabled
		  )
	`).Scan(&registered, &unregistered)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"total_events": total, "events_15m": recent,
		"pending_deliveries": pending, "processing_deliveries": processing,
		"dead_letters": deadLetters, "oldest_pending_age_seconds": oldest,
		"registered_sources": registered, "unregistered_sources": unregistered,
		"coverage_complete": unregistered == 0, "delivery": "at_least_once",
		"as_of": time.Now().UTC(),
	})
}
