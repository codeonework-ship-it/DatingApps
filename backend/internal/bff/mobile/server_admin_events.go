package mobile

import (
	"database/sql"
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

	page, err := parseAdminListParams(r, adminDomainEventsSpec)
	if err != nil {
		writeAdminListParamError(w, err)
		return
	}
	whereSQL, args := eventFilterSQL(r.URL.Query())
	filter := &sqlFilter{clauses: []string{whereSQL}, args: args}
	filter.UUIDEq("actor_user_id", r.URL.Query().Get("actor_user_id"))
	filter.Search(page.Q, "event_name", "aggregate_type", "producer")
	filter.TimeRange("occurred_at", page)
	// after_sequence is the consumer cursor: ascending, no offset and no
	// count, exactly as before. Other callers page with offset and total.
	cursor := strings.TrimSpace(r.URL.Query().Get("after_sequence")) != ""

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	events := make([]map[string]any, 0, page.Limit)
	scan := func(rows *sql.Rows) error {
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
			return err
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
		return nil
	}
	const columns = `sequence_id,event_id::text,event_name,event_version,aggregate_type,
		       aggregate_id,producer,COALESCE(subject_user_id::text,''),
		       COALESCE(actor_user_id::text,''),COALESCE(correlation_id,''),
		       COALESCE(causation_id::text,''),payload,metadata,occurred_at`
	const from = ` FROM platform.domain_event_outbox`
	response := map[string]any{
		"source": "platform.domain_event_outbox", "append_only": true,
		"delivery": "at_least_once",
	}
	if cursor {
		rows, queryErr := s.store.adminRepo.pg.QueryContext(ctx, `SELECT `+columns+from+filter.SQL()+
			fmt.Sprintf(` ORDER BY sequence_id ASC LIMIT %d`, page.Limit), filter.Args()...)
		if queryErr != nil {
			writeError(w, http.StatusBadGateway, queryErr)
			return
		}
		defer rows.Close()
		for rows.Next() {
			if err := scan(rows); err != nil {
				writeError(w, http.StatusBadGateway, err)
				return
			}
		}
		if err := rows.Err(); err != nil {
			writeError(w, http.StatusBadGateway, err)
			return
		}
		response["limit"] = page.Limit
	} else {
		total, queryErr := queryAdminPage(ctx, s.store.adminRepo.pg, columns, from, filter, page, scan)
		if queryErr != nil {
			writeError(w, http.StatusBadGateway, queryErr)
			return
		}
		page.Page(response, total)
	}
	response["events"] = events
	response["count"] = len(events)
	response["as_of"] = time.Now().UTC()
	writeJSON(w, http.StatusOK, response)
}

var adminDomainEventsSpec = adminListSpec{
	DefaultLimit: 100, MaxLimit: 500,
	Sorts:       map[string]string{"sequence_id": "sequence_id", "occurred_at": "sequence_id"},
	DefaultSort: "sequence_id",
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
