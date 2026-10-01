package mobile

import (
	"context"
	"errors"
	"net/http"
	"strings"

	"github.com/go-chi/chi/v5"
)

// HTTP surface for the copilot and conversation trust (migration 097).
//
//	POST /matches/{matchID}/copilot/draft   {kind: opener|reply|plan_idea, tone?}
//	GET  /matches/{matchID}/trust           verified-human state and partner badges
//
// Messages sent with `assist_draft_id` in the body are marked as assisted;
// the message list carries `composed_with_assist` on every message.

func (s *Server) copilot() (*copilotService, error) {
	db, err := s.growthDB()
	if err != nil {
		return nil, errors.New("copilot persistence is unavailable")
	}
	if s.copilotProvider == nil {
		s.copilotProvider = newCopilotProviderFromEnv()
	}
	return newCopilotService(db, s.copilotProvider), nil
}

func (s *Server) draftWithCopilot(w http.ResponseWriter, r *http.Request) {
	principal, err := requestPrincipal(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	svc, err := s.copilot()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	matchID := strings.TrimSpace(chi.URLParam(r, "matchID"))
	if unlocked, state := s.planUnlockCheck(matchID); !unlocked && toString(payload["kind"]) != "opener" {
		writeJSON(w, http.StatusLocked, map[string]any{
			"success": false, "error": errCopilotUnlocked.Error(),
			"error_code": "CHAT_LOCKED_REQUIREMENT_PENDING", "unlock_state": state,
		})
		return
	}
	view, err := svc.draft(r.Context(), principal.UserID, matchID,
		toString(payload["kind"]), toString(payload["tone"]))
	switch {
	case err == nil:
	case strings.HasPrefix(err.Error(), "kind must") || strings.HasPrefix(err.Error(), "tone must"):
		writeError(w, http.StatusBadRequest, err)
		return
	case errors.Is(err, errDatePlanNotFound):
		writeError(w, http.StatusNotFound, err)
		return
	case errors.Is(err, errDatePlanForbidden):
		writeError(w, http.StatusForbidden, err)
		return
	case errors.Is(err, errCopilotLimit):
		writeJSON(w, http.StatusTooManyRequests, map[string]any{
			"success": false, "error": err.Error(), "error_code": "COPILOT_DAILY_LIMIT_REACHED",
			"daily_limit": copilotDailyDraftLimit,
		})
		return
	case errors.Is(err, errCopilotNoProfile):
		writeJSON(w, http.StatusConflict, map[string]any{
			"success": false, "error": err.Error(), "error_code": "COPILOT_PROFILE_UNAVAILABLE",
		})
		return
	case errors.Is(err, errCopilotProvider):
		writeJSON(w, http.StatusServiceUnavailable, map[string]any{
			"success": false, "error": errCopilotProvider.Error(), "error_code": "COPILOT_UNAVAILABLE",
		})
		return
	default:
		writeError(w, http.StatusServiceUnavailable, errors.New("copilot persistence is unavailable"))
		return
	}
	s.store.recordActivity(activityEvent{
		UserID: principal.UserID, Actor: principal.UserID, Action: "copilot.draft",
		Status: "success", Resource: "/matches/" + matchID + "/copilot/draft",
		Details: map[string]any{"kind": view.Kind, "provider": view.Provider},
	})
	writeJSON(w, http.StatusOK, map[string]any{"draft": view})
}

func (s *Server) getConversationTrust(w http.ResponseWriter, r *http.Request) {
	principal, err := requestPrincipal(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	svc, err := s.copilot()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	view, err := svc.conversationTrust(r.Context(), principal.UserID, strings.TrimSpace(chi.URLParam(r, "matchID")))
	switch {
	case errors.Is(err, errDatePlanNotFound):
		writeError(w, http.StatusNotFound, err)
		return
	case errors.Is(err, errDatePlanForbidden):
		writeError(w, http.StatusForbidden, err)
		return
	case err != nil:
		writeError(w, http.StatusServiceUnavailable, errors.New("conversation trust is unavailable"))
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"trust": view})
}

// markAssistedMessageSend runs after a successful send. Best effort: a
// missing mark never fails the send that already happened.
func (s *Server) markAssistedMessageSend(ctx context.Context, matchID, senderID string, payload, response map[string]any) {
	draftID := strings.TrimSpace(toString(payload["assist_draft_id"]))
	if draftID == "" || response == nil {
		return
	}
	messageID := ""
	if message, ok := response["message"].(map[string]any); ok {
		messageID = strings.TrimSpace(toString(message["id"]))
	}
	if messageID == "" {
		messageID = strings.TrimSpace(toString(response["message_id"]))
	}
	if messageID == "" {
		messageID = strings.TrimSpace(toString(response["id"]))
	}
	if messageID == "" {
		return
	}
	svc, err := s.copilot()
	if err != nil {
		return
	}
	if err := svc.markAssisted(ctx, matchID, messageID, senderID, draftID); err != nil && s.log != nil {
		s.log.Warn("assist_mark_failed")
	}
	response["composed_with_assist"] = true
}

func (s *Server) attachAssistMarks(ctx context.Context, matchID string, response map[string]any) {
	svc, err := s.copilot()
	if err != nil {
		return
	}
	_ = svc.attachAssistMarks(ctx, matchID, response)
}
