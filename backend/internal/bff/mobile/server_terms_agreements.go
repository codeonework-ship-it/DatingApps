package mobile

import (
	"errors"
	"net/http"
	"strings"

	"github.com/go-chi/chi/v5"
)

func (s *Server) getTermsAgreement(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("user id is required"))
		return
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	record, err := s.termsAgreements.getAgreement(ctx, userID)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"agreement": record,
	})
}

func (s *Server) patchTermsAgreement(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("user id is required"))
		return
	}

	payload, ok := readJSON(w, r)
	if !ok {
		return
	}

	accepted, acceptedProvided := payload["accepted"].(bool)
	if !acceptedProvided {
		accepted = true
	}
	termsVersion := strings.TrimSpace(toString(payload["terms_version"]))

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	record, err := s.termsAgreements.updateAgreement(ctx, userID, accepted, termsVersion)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}

	s.store.recordActivity(activityEvent{
		UserID:   userID,
		Actor:    userID,
		Action:   "terms.agreement.updated",
		Status:   "success",
		Resource: "/v1/users/" + userID + "/agreements/terms",
		Details: map[string]any{
			"accepted":      record.Accepted,
			"accepted_at":   record.AcceptedAt,
			"terms_version": record.TermsVersion,
		},
	})

	writeJSON(w, http.StatusOK, map[string]any{
		"agreement": record,
	})
}
