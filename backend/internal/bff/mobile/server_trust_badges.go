package mobile

import (
	"errors"
	"net/http"
	"strconv"
	"strings"

	"github.com/go-chi/chi/v5"
)

func (s *Server) getUserTrustBadges(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("user id is required"))
		return
	}

	milestone, badges, err := s.store.recomputeUserTrustBadges(userID)
	if err != nil {
		writeError(w, http.StatusBadRequest, err)
		return
	}

	history, err := s.store.listUserTrustBadgeHistory(userID, 20)
	if err != nil {
		writeError(w, http.StatusBadRequest, err)
		return
	}

	s.store.recordActivity(activityEvent{
		UserID:   userID,
		Actor:    userID,
		Action:   "trust.badges.compute",
		Status:   "success",
		Resource: "/users/" + userID + "/trust-badges",
		Details: map[string]any{
			"active_badges": countActiveBadges(badges),
		},
	})

	writeJSON(w, http.StatusOK, map[string]any{
		"user_id":    userID,
		"milestones": milestone,
		"badges":     badges,
		"history":    history,
	})
}

func (s *Server) listUserTrustBadgeHistory(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("user id is required"))
		return
	}

	limit := 100
	if raw := strings.TrimSpace(r.URL.Query().Get("limit")); raw != "" {
		if parsed, err := strconv.Atoi(raw); err == nil {
			limit = parsed
		}
	}

	history, err := s.store.listUserTrustBadgeHistory(userID, limit)
	if err != nil {
		writeError(w, http.StatusBadRequest, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"user_id": userID,
		"history": history,
	})
}

func countActiveBadges(badges []trustBadge) int {
	count := 0
	for _, badge := range badges {
		if strings.EqualFold(strings.TrimSpace(badge.Status), "active") {
			count++
		}
	}
	return count
}
