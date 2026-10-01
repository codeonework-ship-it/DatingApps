package mobile

import (
	"context"
	"errors"
	"net/http"
	"net/url"
	"strings"
)

type replayCursorState struct {
	PrunedThrough int64
	Latest        int64
}

type replayCursorStateReader interface {
	replayCursorState(context.Context, string) (replayCursorState, error)
}

func cursorNeedsSnapshot(after int64, state replayCursorState) bool {
	return after > 0 && after < state.PrunedThrough
}

func (s *Server) rejectExpiredReplayCursor(
	w http.ResponseWriter,
	r *http.Request,
	stream string,
	userID string,
	after int64,
	reader replayCursorStateReader,
) bool {
	if after == 0 || reader == nil {
		return false
	}
	state, err := reader.replayCursorState(r.Context(), userID)
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("replay cursor state is unavailable"))
		return true
	}
	if !cursorNeedsSnapshot(after, state) {
		return false
	}
	userPath := url.PathEscape(strings.TrimSpace(userID))
	snapshotURL := s.cfg.APIPrefix + "/notifications/" + userPath + "?after=0&limit=200"
	if stream == "chat" {
		snapshotURL = s.cfg.APIPrefix + "/matches/" + userPath
	}
	writeJSON(w, http.StatusGone, map[string]any{
		"success":    false,
		"error":      "replay cursor expired; refresh authoritative state before reconnecting",
		"error_code": "REPLAY_CURSOR_EXPIRED",
		"recovery": map[string]any{
			"stream":         stream,
			"snapshot_url":   snapshotURL,
			"resume_after":   state.Latest,
			"pruned_through": state.PrunedThrough,
		},
	})
	return true
}

func (r *chatRealtimeRepository) replayCursorState(ctx context.Context, userID string) (replayCursorState, error) {
	var state replayCursorState
	err := r.db.QueryRowContext(ctx, `
		SELECT COALESCE(c.pruned_through_sequence,0),
		       GREATEST(COALESCE(c.pruned_through_sequence,0),COALESCE(MAX(o.sequence_id),0))
		FROM (SELECT $1::UUID AS recipient_user_id) u
		LEFT JOIN platform.replay_cursor_checkpoints c
		  ON c.stream_name='chat' AND c.recipient_user_id=u.recipient_user_id
		LEFT JOIN matching.realtime_outbox o
		  ON o.recipient_user_id=u.recipient_user_id AND o.expires_at>NOW()
		GROUP BY c.pruned_through_sequence`, strings.TrimSpace(userID)).Scan(&state.PrunedThrough, &state.Latest)
	return state, err
}

func (r *notificationRepository) replayCursorState(ctx context.Context, userID string) (replayCursorState, error) {
	var state replayCursorState
	err := r.db.QueryRowContext(ctx, `
		SELECT COALESCE(c.pruned_through_sequence,0),
		       GREATEST(COALESCE(c.pruned_through_sequence,0),COALESCE(MAX(n.sequence_id),0))
		FROM (SELECT $1::UUID AS recipient_user_id) u
		LEFT JOIN platform.replay_cursor_checkpoints c
		  ON c.stream_name='notifications' AND c.recipient_user_id=u.recipient_user_id
		LEFT JOIN matching.user_notifications n
		  ON n.recipient_user_id=u.recipient_user_id
		GROUP BY c.pruned_through_sequence`, strings.TrimSpace(userID)).Scan(&state.PrunedThrough, &state.Latest)
	return state, err
}
