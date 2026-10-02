package matching

import (
	"context"
	"encoding/json"
	"fmt"
	"strconv"
	"strings"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

// rowQuerier is implemented by the native PostgreSQL client
// (postgresdata.Client.QueryRows). Hosted PostgREST mode does not implement
// it and keeps the filter-based queries.
type rowQuerier interface {
	QueryRows(ctx context.Context, query string, args ...any) ([]map[string]any, error)
}

// latestMessagesNative returns each match's newest message with one indexed
// probe per match (idx_messages_match_time). The filter-based fallback asked
// for EVERY message of EVERY match ordered by time and kept the first per
// match in Go, so the match list transferred whole chat histories (thousands
// of rows for an active member) on every refresh. ok=false means "not
// available here, use the fallback".
func (r *DataRepository) latestMessagesNative(ctx context.Context, matchIDs []string) (map[string]map[string]any, bool, error) {
	querier, table, ok := r.nativeMessages()
	if !ok {
		return nil, false, nil
	}
	ids := uuidStrings(matchIDs)
	out := map[string]map[string]any{}
	if len(ids) == 0 {
		return out, true, nil
	}
	rows, err := querier.QueryRows(ctx, `
		SELECT m.match_id::text AS match_id, m.text, m.created_at
		FROM unnest($1::uuid[]) AS ids(id)
		CROSS JOIN LATERAL (
		  SELECT match_id, text, created_at
		  FROM `+table+`
		  WHERE match_id = ids.id
		  ORDER BY created_at DESC
		  LIMIT 1
		) m`, ids)
	if err != nil {
		return nil, true, err
	}
	for _, row := range normalizeRowsForSchema(r.cfg.MatchingSchema, rows) {
		if matchID := toString(row["matchId"]); matchID != "" {
			out[matchID] = row
		}
	}
	return out, true, nil
}

// unreadCountsNative counts unread messages per match in the database instead
// of returning one row per unread message.
func (r *DataRepository) unreadCountsNative(ctx context.Context, matchIDs []string, currentUserID string) (map[string]int, bool, error) {
	querier, table, ok := r.nativeMessages()
	if !ok {
		return nil, false, nil
	}
	if _, err := uuid.Parse(strings.TrimSpace(currentUserID)); err != nil {
		return nil, false, nil
	}
	ids := uuidStrings(matchIDs)
	out := map[string]int{}
	if len(ids) == 0 {
		return out, true, nil
	}
	rows, err := querier.QueryRows(ctx, `
		SELECT match_id::text AS match_id, COUNT(*) AS unread
		FROM `+table+`
		WHERE match_id = ANY($1::uuid[]) AND read_at IS NULL AND sender_id <> $2::uuid
		GROUP BY match_id`, ids, strings.TrimSpace(currentUserID))
	if err != nil {
		return nil, true, err
	}
	for _, row := range rows {
		matchID := toString(row["match_id"])
		if matchID == "" {
			continue
		}
		out[matchID] = countValue(row["unread"])
	}
	return out, true, nil
}

func (r *DataRepository) nativeMessages() (rowQuerier, string, bool) {
	querier, ok := r.db.(rowQuerier)
	if !ok || r.cfg.MockDataEnabled {
		return nil, "", false
	}
	schema := r.effectiveSchemaForTable(r.cfg.MatchingSchema, r.cfg.MessagesTable)
	if !usesSnakeCaseSchema(schema) || strings.TrimSpace(r.cfg.MessagesTable) == "" {
		return nil, "", false
	}
	return querier, pgx.Identifier{schema, r.cfg.MessagesTable}.Sanitize(), true
}

// uuidStrings keeps distinct, well-formed ids: a malformed id cannot match a
// uuid column, and casting it would fail the whole query.
func uuidStrings(values []string) []string {
	out := make([]string, 0, len(values))
	seen := map[string]bool{}
	for _, value := range values {
		parsed, err := uuid.Parse(strings.TrimSpace(value))
		if err != nil {
			continue
		}
		id := parsed.String()
		if !seen[id] {
			seen[id] = true
			out = append(out, id)
		}
	}
	return out
}

func countValue(value any) int {
	switch typed := value.(type) {
	case int:
		return typed
	case int32:
		return int(typed)
	case int64:
		return int(typed)
	case float64:
		return int(typed)
	case json.Number:
		n, _ := typed.Int64()
		return int(n)
	case string:
		n, _ := strconv.Atoi(typed)
		return n
	default:
		n, _ := strconv.Atoi(fmt.Sprint(typed))
		return n
	}
}
