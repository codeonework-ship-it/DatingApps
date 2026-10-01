package mobile

import (
	"context"
	"errors"
	"net/http"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"go.uber.org/zap"
)

// Who liked me.
//
// Lists members who liked the viewer and are still waiting on an answer: the
// viewer has neither liked nor passed them back, so there is no match yet.
// Answering through the ordinary /v1/swipe endpoint removes the member from
// this list (a like back creates the match). Seeing who liked you is free on
// every plan (pricing principle: never gate the core loop), so nothing here
// consults entitlements.
//
// Every liker goes through publicProfileQuery, the same publication,
// enforcement and two-way block rule as the public profile and the discovery
// deck, so a like from a banned, blocked, deactivated or unpublished member is
// never shown and never counted.

const (
	likedMeDefaultLimit = 50
	likedMeMaxLimit     = 100
	// likedMeScanLimit bounds how many pending likes are read before the
	// publication filter drops likers the viewer may not see.
	likedMeScanLimit = 300
)

// matches stores each pair once with user_id_1 < user_id_2.
const pendingLikesQuery = `
SELECT sw.user_id::text, sw.created_at
FROM matching.swipes sw
WHERE sw.target_user_id = $1::uuid AND sw.is_like
  AND NOT EXISTS (SELECT 1 FROM matching.swipes mine
                  WHERE mine.user_id = $1::uuid AND mine.target_user_id = sw.user_id)
  AND NOT EXISTS (SELECT 1 FROM matching.matches m
                  WHERE m.user_id_1 = LEAST($1::uuid, sw.user_id)
                    AND m.user_id_2 = GREATEST($1::uuid, sw.user_id))
ORDER BY sw.created_at DESC, sw.user_id
LIMIT $2`

// loadLikedMe returns the visible pending likers, newest like first, each as
// a public profile plus `liked_at`, and how many visible likers were found
// within likedMeScanLimit (which can exceed len(profiles) when limit is lower).
func loadLikedMe(ctx context.Context, db profileRowsReader, viewerID string, limit int) ([]map[string]any, int, error) {
	rows, err := db.QueryContext(ctx, pendingLikesQuery, viewerID, likedMeScanLimit)
	if err != nil {
		return nil, 0, err
	}
	likerIDs := make([]string, 0)
	likedAt := map[string]time.Time{}
	for rows.Next() {
		var id string
		var at time.Time
		if err := rows.Scan(&id, &at); err != nil {
			rows.Close()
			return nil, 0, err
		}
		likerIDs = append(likerIDs, id)
		likedAt[id] = at
	}
	if err := rows.Close(); err != nil {
		return nil, 0, err
	}
	if err := rows.Err(); err != nil {
		return nil, 0, err
	}

	visible, err := loadPublicProfiles(ctx, db, viewerID, likerIDs)
	if err != nil {
		return nil, 0, err
	}
	profiles := make([]map[string]any, 0, min(limit, len(visible)))
	count := 0
	for _, id := range likerIDs {
		profile, ok := visible[id]
		if !ok {
			continue
		}
		count++
		if len(profiles) >= limit {
			continue
		}
		// The deck and the app read the camel-case verification flag.
		profile["isVerified"] = profile["is_verified"] == true
		profile["liked_at"] = likedAt[id].UTC().Format(time.RFC3339)
		profiles = append(profiles, profile)
	}
	return profiles, count, nil
}

func (s *Server) listLikedMe(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if _, err := uuid.Parse(userID); err != nil {
		writeError(w, http.StatusBadRequest, errors.New("valid user id is required"))
		return
	}
	if s.store == nil || s.store.profileRepo == nil || s.store.profileRepo.pg == nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("likes persistence is unavailable"))
		return
	}
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	profiles, count, err := loadLikedMe(ctx, s.store.profileRepo.pg, userID, boundedQueryLimit(r, likedMeDefaultLimit, likedMeMaxLimit))
	if err != nil {
		s.log.Error("liked_me_read_failed", zap.Error(err))
		writeError(w, http.StatusServiceUnavailable, errors.New("likes are temporarily unavailable"))
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"profiles": profiles, "count": count})
}
