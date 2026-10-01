package mobile

import (
	"context"
	"errors"
	"net/http"
	"strings"

	"github.com/go-chi/chi/v5"
)

// HTTP surface for graduation (migration 094).
//
//	GET  /matches/{matchID}/graduation                          current proposal or graduation, history
//	POST /matches/{matchID}/graduation                          propose {note?, share_with_friends}
//	POST /matches/{matchID}/graduation/{graduationID}/decision  partner confirms or declines
//	POST /matches/{matchID}/graduation/{graduationID}/withdraw  proposer withdraws
//	GET  /account/{userID}/discovery/pause                      my discovery pause state
//	POST /account/{userID}/discovery/pause                      pause discovery manually
//	POST /account/{userID}/discovery/resume                     return to discovery

func (s *Server) graduations() (*graduationService, error) {
	db, err := s.growthDB()
	if err != nil {
		return nil, errors.New("graduation persistence is unavailable")
	}
	return newGraduationService(db), nil
}

func writeGraduationError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, errGraduationNotFound), errors.Is(err, errDiscoveryPauseNotFound):
		writeError(w, http.StatusNotFound, err)
	case errors.Is(err, errGraduationForbidden), errors.Is(err, errGraduationNotPartner),
		errors.Is(err, errGraduationNotProposer):
		writeError(w, http.StatusForbidden, err)
	case errors.Is(err, errGraduationAlreadyOpen):
		writeJSON(w, http.StatusConflict, map[string]any{
			"success": false, "error": err.Error(), "error_code": "GRADUATION_ALREADY_OPEN",
		})
	case errors.Is(err, errGraduationStale):
		writeJSON(w, http.StatusConflict, map[string]any{
			"success": false, "error": err.Error(), "error_code": "GRADUATION_NOT_OPEN",
		})
	case errors.Is(err, errGraduationAlreadyDone):
		writeJSON(w, http.StatusConflict, map[string]any{
			"success": false, "error": err.Error(), "error_code": "GRADUATION_ALREADY_CONFIRMED",
		})
	case errors.Is(err, errGraduationMatchInactive):
		writeJSON(w, http.StatusConflict, map[string]any{
			"success": false, "error": err.Error(), "error_code": "GRADUATION_MATCH_INACTIVE",
		})
	default:
		writeError(w, http.StatusServiceUnavailable, errors.New("graduation persistence is unavailable"))
	}
}

func (s *Server) getMatchGraduation(w http.ResponseWriter, r *http.Request) {
	principal, err := requestPrincipal(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	svc, err := s.graduations()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	matchID := strings.TrimSpace(chi.URLParam(r, "matchID"))
	current, history, active, graduated, err := svc.matchGraduation(r.Context(), matchID, principal.UserID)
	if err != nil {
		writeGraduationError(w, err)
		return
	}
	unlocked, state := s.planUnlockCheck(matchID)
	paused, pause, err := svc.pauseState(r.Context(), principal.UserID)
	if err != nil {
		writeGraduationError(w, err)
		return
	}
	response := map[string]any{
		"match_id": matchID, "graduation": nil, "history": history,
		"graduated":    graduated,
		"can_propose":  current == nil && active && !graduated && unlocked,
		"unlock_state": state, "discovery_paused": paused,
	}
	if current != nil {
		response["graduation"] = current
	}
	if pause != nil {
		response["discovery_pause"] = pause
	}
	writeJSON(w, http.StatusOK, response)
}

func (s *Server) proposeMatchGraduation(w http.ResponseWriter, r *http.Request) {
	principal, err := requestPrincipal(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	note, err := parseGraduationNote(payload["note"])
	if err != nil {
		writeError(w, http.StatusBadRequest, err)
		return
	}
	share, _ := payload["share_with_friends"].(bool)
	svc, err := s.graduations()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	matchID := strings.TrimSpace(chi.URLParam(r, "matchID"))
	// Membership before the unlock gate, so a non-member never learns a
	// match's unlock state from this endpoint.
	if err = svc.assertMember(r.Context(), matchID, principal.UserID); err != nil {
		writeGraduationError(w, err)
		return
	}
	if unlocked, state := s.planUnlockCheck(matchID); !unlocked {
		writeJSON(w, http.StatusLocked, map[string]any{
			"success": false, "error": "unlock the conversation before graduating together",
			"error_code": "CHAT_LOCKED_REQUIREMENT_PENDING", "unlock_state": state,
		})
		return
	}
	view, err := svc.propose(r.Context(), matchID, principal.UserID, note, share)
	if err != nil {
		writeGraduationError(w, err)
		return
	}
	if s.store != nil {
		s.store.recordActivity(activityEvent{
			UserID: principal.UserID, Actor: principal.UserID, Action: "graduation.propose",
			Status: "success", Resource: "/matches/" + matchID + "/graduation",
			Details: map[string]any{"graduation_id": view.ID, "share_with_friends": share},
		})
	}
	writeJSON(w, http.StatusCreated, map[string]any{"graduation": view})
}

func (s *Server) decideMatchGraduation(w http.ResponseWriter, r *http.Request) {
	principal, err := requestPrincipal(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	decision, err := parseGraduationDecision(payload["decision"])
	if err != nil {
		writeError(w, http.StatusBadRequest, err)
		return
	}
	share, _ := payload["share_with_friends"].(bool)
	svc, err := s.graduations()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	view, err := svc.decide(r.Context(), strings.TrimSpace(chi.URLParam(r, "matchID")),
		strings.TrimSpace(chi.URLParam(r, "graduationID")), principal.UserID, decision, share)
	if err != nil {
		writeGraduationError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"graduation": view})
}

func (s *Server) withdrawMatchGraduation(w http.ResponseWriter, r *http.Request) {
	principal, err := requestPrincipal(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	svc, err := s.graduations()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	view, err := svc.withdraw(r.Context(), strings.TrimSpace(chi.URLParam(r, "matchID")),
		strings.TrimSpace(chi.URLParam(r, "graduationID")), principal.UserID)
	if err != nil {
		writeGraduationError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"graduation": view})
}

// ── Discovery pause (self-owned account routes) ──────────────────────────────

func discoveryPauseResponse(paused bool, view *discoveryPauseView) map[string]any {
	response := map[string]any{"paused": paused, "pause": nil}
	if view != nil {
		response["pause"] = view
	}
	return response
}

func (s *Server) getDiscoveryPause(w http.ResponseWriter, r *http.Request) {
	principal, err := requestPrincipal(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	svc, err := s.graduations()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	paused, view, err := svc.pauseState(r.Context(), principal.UserID)
	if err != nil {
		writeGraduationError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, discoveryPauseResponse(paused, view))
}

func (s *Server) pauseDiscovery(w http.ResponseWriter, r *http.Request) {
	principal, err := requestPrincipal(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	payload := map[string]any{}
	if r.ContentLength != 0 {
		body, ok := readJSON(w, r)
		if !ok {
			return
		}
		payload = body
	}
	reason, err := parseDiscoveryPauseReason(payload["reason"])
	if err != nil {
		writeError(w, http.StatusBadRequest, err)
		return
	}
	svc, err := s.graduations()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	view, err := svc.pause(r.Context(), principal.UserID, reason)
	if err != nil {
		writeGraduationError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, discoveryPauseResponse(true, view))
}

func (s *Server) resumeDiscovery(w http.ResponseWriter, r *http.Request) {
	principal, err := requestPrincipal(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	svc, err := s.graduations()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	view, err := svc.resume(r.Context(), principal.UserID)
	if err != nil {
		writeGraduationError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, discoveryPauseResponse(false, view))
}

// attachPausedFilteredDiscovery removes paused members from the deck and
// explains an empty deck to a member who is paused themselves. Like the block
// filter it fails closed: a deck that cannot be checked is not served.
func (s *Server) attachPausedFilteredDiscovery(ctx context.Context, resp map[string]any, userID string) {
	if s.store == nil || s.store.profileRepo == nil || s.store.profileRepo.pg == nil {
		return
	}
	if err := filterPausedDiscovery(ctx, s.store.profileRepo.pg, userID, resp); err != nil {
		rows, _ := resp["candidates"].([]any)
		resp["candidates"] = []any{}
		resp["pause_filter"] = map[string]any{
			"applied": false, "error": "discovery pause state unavailable", "filtered": len(rows),
		}
	}
}
