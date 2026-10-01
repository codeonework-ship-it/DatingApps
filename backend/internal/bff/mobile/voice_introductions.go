package mobile

import (
	"context"
	"database/sql"
	"errors"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)

func voicePairAvailable(ctx context.Context, db datingQuerier, match, viewer string) (string, error) {
	partner, err := activeDatingPair(ctx, db, match, viewer, false)
	if err != nil {
		return "", err
	}
	var safe bool
	err = db.QueryRowContext(ctx, `SELECT COUNT(*)=2 FROM user_management.users u WHERE id IN ($1::uuid,$2::uuid)
 AND is_active AND NOT is_banned AND erased_at IS NULL AND deactivated_at IS NULL AND deletion_requested_at IS NULL
 AND (suspended_at IS NULL OR (suspended_until IS NOT NULL AND suspended_until<=NOW()))
 AND NOT EXISTS(SELECT 1 FROM user_management.auth_credentials c WHERE c.user_id=u.id AND c.is_disabled)`, viewer, partner).Scan(&safe)
	if err != nil {
		return "", err
	}
	if !safe {
		return "", errDatePlanForbidden
	}
	return partner, nil
}

func (s *Server) listVoiceIntroductions(w http.ResponseWriter, r *http.Request) {
	actor, err := requestPrincipal(r)
	if err != nil {
		writeError(w, 401, err)
		return
	}
	db, err := s.growthDB()
	if err != nil {
		writeError(w, 503, errors.New("Voice introductions are unavailable"))
		return
	}
	match := chi.URLParam(r, "matchID")
	if _, err := uuid.Parse(match); err != nil {
		writeError(w, 400, errors.New("invalid conversation"))
		return
	}
	// Read access and approved recordings in one snapshot.
	tx, err := db.BeginTx(r.Context(), &sql.TxOptions{Isolation: sql.LevelRepeatableRead, ReadOnly: true})
	if err != nil {
		writeDatePlanError(w, err)
		return
	}
	defer tx.Rollback()
	partner, err := voicePairAvailable(r.Context(), tx, match, actor.UserID)
	if err != nil {
		writeDatePlanError(w, err)
		return
	}
	rows, err := tx.QueryContext(r.Context(), `SELECT id::text,prompt_text,transcript,duration_seconds,sender_user_id::text,receiver_user_id::text,status,moderation_status,play_count
 FROM matching.voice_icebreakers WHERE match_id=$1::uuid AND sender_user_id IN ($2::uuid,$3::uuid) AND receiver_user_id IN ($2::uuid,$3::uuid)
 AND sender_user_id<>receiver_user_id AND status IN ('sent','played') AND moderation_status='approved' AND NULLIF(audio_storage_path,'') IS NOT NULL
 AND NOT EXISTS(SELECT 1 FROM user_management.users u WHERE u.id IN ($2::uuid,$3::uuid) AND (u.is_banned OR u.erased_at IS NOT NULL OR (u.suspended_at IS NOT NULL AND (u.suspended_until IS NULL OR u.suspended_until>NOW()))))
 ORDER BY created_at DESC,id DESC LIMIT 20`, match, actor.UserID, partner)
	if err != nil {
		writeDatePlanError(w, err)
		return
	}
	defer rows.Close()
	items := []voiceIcebreaker{}
	for rows.Next() {
		var item voiceIcebreaker
		item.MatchID = match
		item.HasAudio = true
		if err = rows.Scan(&item.ID, &item.PromptText, &item.Transcript, &item.DurationSeconds, &item.SenderUserID, &item.ReceiverUserID, &item.Status, &item.ModerationStatus, &item.PlayCount); err != nil {
			writeDatePlanError(w, err)
			return
		}
		items = append(items, item)
	}
	if err = rows.Err(); err != nil {
		writeDatePlanError(w, err)
		return
	}
	w.Header().Set("Cache-Control", "private, no-store")
	writeJSON(w, 200, map[string]any{"introductions": items})
}
