package mobile

import (
	"errors"
	"net/http"
	"strconv"
	"strings"

	"github.com/go-chi/chi/v5"
)

func (s *Server) requireNotificationRepository(w http.ResponseWriter) (*notificationRepository, bool) {
	if s.notifications == nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("notification persistence is unavailable"))
		return nil, false
	}
	return s.notifications, true
}

func notificationCursor(r *http.Request) (int64, int, error) {
	after := int64(0)
	if raw := strings.TrimSpace(r.URL.Query().Get("after")); raw != "" {
		parsed, err := strconv.ParseInt(raw, 10, 64)
		if err != nil || parsed < 0 {
			return 0, 0, errors.New("after must be a non-negative notification sequence")
		}
		after = parsed
	}
	limit := 50
	if raw := strings.TrimSpace(r.URL.Query().Get("limit")); raw != "" {
		parsed, err := strconv.Atoi(raw)
		if err != nil || parsed < 1 || parsed > 200 {
			return 0, 0, errors.New("limit must be between 1 and 200")
		}
		limit = parsed
	}
	return after, limit, nil
}

func (s *Server) listNotifications(w http.ResponseWriter, r *http.Request) {
	repo, ok := s.requireNotificationRepository(w)
	if !ok {
		return
	}
	after, limit, err := notificationCursor(r)
	if err != nil {
		writeError(w, http.StatusBadRequest, err)
		return
	}
	if s.rejectExpiredReplayCursor(w, r, "notifications", chi.URLParam(r, "userID"), after, repo) {
		return
	}
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	items, err := repo.list(ctx, chi.URLParam(r, "userID"), after, limit)
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	next := after
	if len(items) > 0 {
		next = items[len(items)-1].Sequence
	}
	writeJSON(w, http.StatusOK, map[string]any{"notifications": items, "next_after": next})
}

func (s *Server) getNotificationUnreadCount(w http.ResponseWriter, r *http.Request) {
	repo, ok := s.requireNotificationRepository(w)
	if !ok {
		return
	}
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	count, err := repo.unreadCount(ctx, chi.URLParam(r, "userID"))
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"unread_count": count})
}

func (s *Server) markNotificationRead(w http.ResponseWriter, r *http.Request) {
	repo, ok := s.requireNotificationRepository(w)
	if !ok {
		return
	}
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	updated, err := repo.markRead(ctx, chi.URLParam(r, "userID"), chi.URLParam(r, "notificationID"))
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	if !updated {
		writeError(w, http.StatusNotFound, errors.New("notification not found"))
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"success": true})
}

func (s *Server) markAllNotificationsRead(w http.ResponseWriter, r *http.Request) {
	repo, ok := s.requireNotificationRepository(w)
	if !ok {
		return
	}
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	count, err := repo.markAllRead(ctx, chi.URLParam(r, "userID"))
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"success": true, "updated_count": count})
}

func (s *Server) dismissNotification(w http.ResponseWriter, r *http.Request) {
	repo, ok := s.requireNotificationRepository(w)
	if !ok {
		return
	}
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	updated, err := repo.dismiss(ctx, chi.URLParam(r, "userID"), chi.URLParam(r, "notificationID"))
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	if !updated {
		writeError(w, http.StatusNotFound, errors.New("notification not found"))
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"success": true})
}

func (s *Server) getNotificationPreferences(w http.ResponseWriter, r *http.Request) {
	repo, ok := s.requireNotificationRepository(w)
	if !ok {
		return
	}
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	prefs, err := repo.getPreferences(ctx, chi.URLParam(r, "userID"))
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"preferences": prefs})
}

func (s *Server) patchNotificationPreferences(w http.ResponseWriter, r *http.Request) {
	repo, ok := s.requireNotificationRepository(w)
	if !ok {
		return
	}
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	prefs, err := repo.updatePreferences(ctx, chi.URLParam(r, "userID"), payload)
	if err != nil {
		writeError(w, http.StatusBadRequest, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"preferences": prefs})
}

func (s *Server) registerNotificationDevice(w http.ResponseWriter, r *http.Request) {
	repo, ok := s.requireNotificationRepository(w)
	if !ok {
		return
	}
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	id, err := repo.registerDevice(ctx, chi.URLParam(r, "userID"), toString(payload["provider"]), toString(payload["platform"]), toString(payload["token"]))
	if err != nil {
		writeError(w, http.StatusBadRequest, err)
		return
	}
	writeJSON(w, http.StatusCreated, map[string]any{"device_id": id, "registered": true})
}

func (s *Server) unregisterNotificationDevice(w http.ResponseWriter, r *http.Request) {
	repo, ok := s.requireNotificationRepository(w)
	if !ok {
		return
	}
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	updated, err := repo.unregisterDevice(ctx, chi.URLParam(r, "userID"), chi.URLParam(r, "deviceID"))
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	if !updated {
		writeError(w, http.StatusNotFound, errors.New("notification device not found"))
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"success": true})
}

func (s *Server) adminNotificationQueueMetrics(w http.ResponseWriter, r *http.Request) {
	repo, ok := s.requireNotificationRepository(w)
	if !ok {
		return
	}
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	metrics, err := repo.queueMetrics(ctx)
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	depth, _ := metrics["queue_depth"].(int64)
	age, _ := metrics["oldest_pending_age_seconds"].(int64)
	success, _ := metrics["push_success_percent_15m"].(float64)
	slo := map[string]any{
		"met": depth <= int64(s.cfg.NotificationSLOMaxQueueDepth) &&
			age <= int64(s.cfg.NotificationSLOMaxOldestAgeSec) &&
			success >= float64(s.cfg.NotificationSLOMinSuccessPct),
		"max_queue_depth":                s.cfg.NotificationSLOMaxQueueDepth,
		"max_oldest_pending_age_seconds": s.cfg.NotificationSLOMaxOldestAgeSec,
		"min_push_success_percent_15m":   s.cfg.NotificationSLOMinSuccessPct,
	}
	writeJSON(w, http.StatusOK, map[string]any{"metrics": metrics, "slo": slo})
}
