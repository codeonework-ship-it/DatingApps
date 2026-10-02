package mobile

import (
	"errors"
	"net/http"
	"strings"

	"github.com/go-chi/chi/v5"
)

func (s *Server) listAdminMediaModeration(w http.ResponseWriter, r *http.Request) {
	if s.store == nil || s.store.profileRepo == nil || s.store.profileRepo.pg == nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("media moderation persistence is unavailable"))
		return
	}
	page, err := parseAdminListParams(r, adminMediaModerationSpec)
	if err != nil {
		writeAdminListParamError(w, err)
		return
	}
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	items, total, err := s.store.profileRepo.listMediaModerationReviewsPage(
		ctx,
		strings.TrimSpace(r.URL.Query().Get("status")),
		page,
	)
	if err != nil {
		writeError(w, http.StatusBadRequest, err)
		return
	}
	writeJSON(w, http.StatusOK, page.Page(map[string]any{
		"items": items,
		"count": len(items),
	}, total))
}

func (s *Server) decideAdminMediaModeration(w http.ResponseWriter, r *http.Request) {
	if s.store == nil || s.store.profileRepo == nil || s.store.profileRepo.pg == nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("media moderation persistence is unavailable"))
		return
	}
	operatorID, err := authenticatedOperatorID(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	photoID := strings.TrimSpace(chi.URLParam(r, "photoID"))
	decision := strings.ToLower(strings.TrimSpace(toString(payload["decision"])))
	reason := strings.TrimSpace(toString(payload["reason"]))
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	item, err := s.store.profileRepo.decideMediaModerationPostgres(
		ctx,
		photoID,
		decision,
		reason,
		operatorID,
	)
	if err != nil {
		writeError(w, http.StatusBadRequest, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"item": item})
}

func (s *Server) serveAdminMediaModerationContent(w http.ResponseWriter, r *http.Request) {
	if s.store == nil || s.store.profileRepo == nil || s.store.profileRepo.pg == nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("media moderation persistence is unavailable"))
		return
	}
	record, err := s.store.profileRepo.mediaAccessByPhotoIDPostgres(
		r.Context(),
		strings.TrimSpace(chi.URLParam(r, "photoID")),
	)
	if err != nil {
		writeError(w, http.StatusNotFound, errors.New("media not found"))
		return
	}
	if record.ModerationStatus != mediaModerationReviewRequired &&
		record.ModerationStatus != "provider_error" &&
		record.ModerationStatus != mediaModerationApproved {
		writeError(w, http.StatusNotFound, errors.New("media not found"))
		return
	}
	s.serveStoredMedia(w, r, record)
}
