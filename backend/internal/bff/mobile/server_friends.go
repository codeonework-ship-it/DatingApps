package mobile

import (
	"errors"
	"net/http"
	"strconv"
	"strings"

	"github.com/go-chi/chi/v5"
)

func (s *Server) listFriends(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("user id is required"))
		return
	}
	friends := s.store.listFriends(userID)
	writeJSON(w, http.StatusOK, map[string]any{"friends": friends})
}

func (s *Server) addFriend(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("user id is required"))
		return
	}
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	friendUserID := strings.TrimSpace(toString(payload["friend_user_id"]))
	connection, err := s.store.addFriend(userID, friendUserID)
	if err != nil {
		writeError(w, http.StatusBadRequest, err)
		return
	}

	s.store.recordActivity(activityEvent{
		UserID:   userID,
		Actor:    userID,
		Action:   "friends.add",
		Status:   "success",
		Resource: "/friends/" + userID,
		Details: map[string]any{
			"friend_user_id": friendUserID,
		},
	})

	writeJSON(w, http.StatusOK, map[string]any{"friend": connection})
}

func (s *Server) removeFriend(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	friendUserID := strings.TrimSpace(chi.URLParam(r, "friendUserID"))
	if userID == "" || friendUserID == "" {
		writeError(w, http.StatusBadRequest, errors.New("user id and friend user id are required"))
		return
	}
	s.store.removeFriend(userID, friendUserID)
	writeJSON(w, http.StatusOK, map[string]any{"success": true})
}

func (s *Server) listFriendActivities(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("user id is required"))
		return
	}

	limit := 20
	if raw := strings.TrimSpace(r.URL.Query().Get("limit")); raw != "" {
		if parsed, err := strconv.Atoi(raw); err == nil {
			limit = parsed
		}
	}

	activities := s.store.listFriendActivities(userID, limit)
	writeJSON(w, http.StatusOK, map[string]any{"activities": activities})
}
