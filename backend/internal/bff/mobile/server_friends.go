package mobile

import (
	"database/sql"
	"errors"
	"net/http"
	"strconv"
	"strings"

	"github.com/go-chi/chi/v5"
)

const friendsUnavailable = "Friends are temporarily unavailable. Please retry."

// friendsDB returns the native database for the friend rules in
// friend_requests.go, and the signed-in member, who must own the path. ok is
// false when the response has been written. db is nil when only the
// in-memory or legacy store is available.
func (s *Server) friendsDB(w http.ResponseWriter, r *http.Request, userID string) (*sql.DB, bool) {
	db, err := s.growthDB()
	if err != nil {
		return nil, true
	}
	principal, err := requestPrincipal(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return nil, false
	}
	if principal.UserID != userID {
		writeError(w, http.StatusForbidden, errors.New("you can only manage your own friends"))
		return nil, false
	}
	w.Header().Set("Cache-Control", "private, no-store")
	return db, true
}

// writeFriendStoreError keeps the store's historical 400 for plain errors
// while letting rule errors (cooldown, daily limit) carry their status.
func writeFriendStoreError(w http.ResponseWriter, err error) {
	var known activityError
	if errors.As(err, &known) {
		writeError(w, known.status, errors.New(known.msg))
		return
	}
	writeError(w, http.StatusBadRequest, err)
}

func (s *Server) listFriends(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("user id is required"))
		return
	}
	db, ok := s.friendsDB(w, r, userID)
	if !ok {
		return
	}
	if db != nil {
		friends, err := listFriendsPG(r.Context(), db, userID)
		if err != nil {
			writeActivityError(w, err, friendsUnavailable)
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{"friends": friends})
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
	source, err := normalizeFriendSource(toString(payload["source"]))
	if err != nil {
		writeFriendStoreError(w, err)
		return
	}
	db, ok := s.friendsDB(w, r, userID)
	if !ok {
		return
	}
	var connection friendConnection
	if db != nil {
		connection, err = sendFriendRequestPG(r.Context(), db, userID, friendUserID, source)
		if err != nil {
			writeActivityError(w, err, friendsUnavailable)
			return
		}
	} else if connection, err = s.store.addFriendFrom(userID, friendUserID, source); err != nil {
		writeFriendStoreError(w, err)
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
			"source":         source,
			"status":         connection.Status,
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
	db, ok := s.friendsDB(w, r, userID)
	if !ok {
		return
	}
	if db != nil {
		if err := removeFriendPG(r.Context(), db, userID, friendUserID); err != nil {
			writeActivityError(w, err, friendsUnavailable)
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{"success": true})
		return
	}
	s.store.removeFriend(userID, friendUserID)
	writeJSON(w, http.StatusOK, map[string]any{"success": true})
}

func (s *Server) decideFriendRequest(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	requesterID := strings.TrimSpace(chi.URLParam(r, "friendUserID"))
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	decision := strings.TrimSpace(toString(payload["decision"]))
	db, ok := s.friendsDB(w, r, userID)
	if !ok {
		return
	}
	if db != nil {
		connection, err := decideFriendRequestPG(r.Context(), db, userID, requesterID, decision)
		if err != nil {
			writeActivityError(w, err, friendsUnavailable)
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{"success": true, "friend": connection})
		return
	}
	connection, err := s.store.decideFriendRequest(userID, requesterID, decision)
	if err != nil {
		writeFriendStoreError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"success": true, "friend": connection})
}

// GET /v1/friends/{userID}/search?q= finds members to add as friends.
func (s *Server) searchFriendCandidates(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("user id is required"))
		return
	}
	db, ok := s.friendsDB(w, r, userID)
	if !ok {
		return
	}
	query := r.URL.Query().Get("q")
	var results []friendCandidate
	var err error
	if db != nil {
		results, err = searchFriendCandidatesPG(r.Context(), db, userID, query)
	} else {
		results, err = s.store.searchFriendCandidates(userID, query)
	}
	if err != nil {
		writeActivityError(w, err, friendsUnavailable)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"results": results})
}

// GET|PUT /v1/friends/{userID}/search-visibility: the member's "Let people
// find me in friend search" setting ({visible: bool}, default true). When it
// is off, the member is left out of everyone's /friends/{me}/search results;
// people who already see them (matches, rooms, groups, profile) can still
// send a request.
func (s *Server) friendSearchVisibilityHandler(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("user id is required"))
		return
	}
	var visible, set bool
	if r.Method == http.MethodPut || r.Method == http.MethodPatch {
		payload, ok := readJSON(w, r)
		if !ok {
			return
		}
		value, isBool := payload["visible"].(bool)
		if !isBool {
			writeError(w, http.StatusBadRequest, errors.New("visible must be true or false"))
			return
		}
		visible, set = value, true
	}
	db, ok := s.friendsDB(w, r, userID)
	if !ok {
		return
	}
	if db == nil {
		w.Header().Set("Cache-Control", "private, no-store")
		if set {
			s.store.setFriendSearchVisible(userID, visible)
		}
		writeJSON(w, http.StatusOK, map[string]any{"visible": s.store.friendSearchVisible(userID)})
		return
	}
	if set {
		if err := setFriendSearchVisiblePG(r.Context(), db, userID, visible); err != nil {
			writeActivityError(w, err, friendsUnavailable)
			return
		}
		s.store.recordActivity(activityEvent{
			UserID: userID, Actor: userID, Action: "friends.search_visibility", Status: "success",
			Resource: "/friends/" + userID + "/search-visibility", Details: map[string]any{"visible": visible},
		})
	}
	current, err := friendSearchVisiblePG(r.Context(), db, userID)
	if err != nil {
		writeActivityError(w, err, friendsUnavailable)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"visible": current})
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
