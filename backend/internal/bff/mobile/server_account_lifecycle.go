package mobile

import (
	"encoding/json"
	"errors"
	"net/http"
	"strings"

	"github.com/go-chi/chi/v5"
)

// readOptionalJSON decodes a body that callers may legitimately omit.
//
// `readJSON` answers 400 on an empty body, which is right for a payload the
// endpoint depends on. Here the only field is an optional free-text reason, so
// a member deactivating without explaining themselves is not a malformed
// request.
func readOptionalJSON(r *http.Request) (map[string]any, bool) {
	if r.Body == nil {
		return map[string]any{}, false
	}
	defer r.Body.Close()
	var payload map[string]any
	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
		return map[string]any{}, false
	}
	if payload == nil {
		return map[string]any{}, false
	}
	return payload, true
}

// accountLifecycleActor resolves the member the request acts for.
//
// The path id is never trusted on its own. `pathOwnedByPrincipal` already
// rejects a mismatched path for the `account` root, but these endpoints
// deactivate and erase accounts, so the check is repeated here rather than
// relying on a middleware entry staying in place.
func (s *Server) accountLifecycleActor(r *http.Request) (string, error) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" {
		return "", errors.New("user id is required")
	}
	principal, ok := principalFromRequest(r)
	if !ok || strings.TrimSpace(principal.UserID) == "" {
		return "", errors.New("an authenticated session is required")
	}
	if !strings.EqualFold(strings.TrimSpace(principal.UserID), userID) {
		return "", errors.New("account lifecycle actions are limited to the account owner")
	}
	return userID, nil
}

func (s *Server) accountLifecycleRepo(w http.ResponseWriter) (*profileRepository, bool) {
	if s.store == nil || s.store.profileRepo == nil || s.store.profileRepo.pg == nil {
		writeError(w, http.StatusServiceUnavailable,
			errors.New("account lifecycle persistence is unavailable"))
		return nil, false
	}
	return s.store.profileRepo, true
}

func (s *Server) getAccountLifecycle(w http.ResponseWriter, r *http.Request) {
	userID, err := s.accountLifecycleActor(r)
	if err != nil {
		writeError(w, http.StatusForbidden, err)
		return
	}
	repo, ok := s.accountLifecycleRepo(w)
	if !ok {
		return
	}
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	state, err := repo.accountLifecycleState(ctx, userID)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"lifecycle": state})
}

func (s *Server) deactivateAccount(w http.ResponseWriter, r *http.Request) {
	s.changeAccountActivation(w, r, false)
}

func (s *Server) reactivateAccount(w http.ResponseWriter, r *http.Request) {
	s.changeAccountActivation(w, r, true)
}

func (s *Server) changeAccountActivation(
	w http.ResponseWriter,
	r *http.Request,
	active bool,
) {
	userID, err := s.accountLifecycleActor(r)
	if err != nil {
		writeError(w, http.StatusForbidden, err)
		return
	}
	repo, ok := s.accountLifecycleRepo(w)
	if !ok {
		return
	}
	reason := ""
	if payload, read := readOptionalJSON(r); read {
		reason = strings.TrimSpace(toString(payload["reason"]))
	}
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	state, err := repo.setAccountActivation(ctx, userID, userID, reason, active)
	if err != nil {
		writeError(w, http.StatusConflict, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"lifecycle": state})
}

func (s *Server) requestAccountDeletion(w http.ResponseWriter, r *http.Request) {
	userID, err := s.accountLifecycleActor(r)
	if err != nil {
		writeError(w, http.StatusForbidden, err)
		return
	}
	repo, ok := s.accountLifecycleRepo(w)
	if !ok {
		return
	}
	reason := ""
	if payload, read := readOptionalJSON(r); read {
		reason = strings.TrimSpace(toString(payload["reason"]))
	}
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	state, err := repo.requestAccountDeletion(ctx, userID, userID, reason)
	if err != nil {
		writeError(w, http.StatusConflict, err)
		return
	}
	writeJSON(w, http.StatusAccepted, map[string]any{
		"lifecycle":  state,
		"grace_days": accountDeletionGraceDays,
	})
}

func (s *Server) cancelAccountDeletion(w http.ResponseWriter, r *http.Request) {
	userID, err := s.accountLifecycleActor(r)
	if err != nil {
		writeError(w, http.StatusForbidden, err)
		return
	}
	repo, ok := s.accountLifecycleRepo(w)
	if !ok {
		return
	}
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	state, err := repo.cancelAccountDeletion(ctx, userID, userID)
	if err != nil {
		writeError(w, http.StatusConflict, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"lifecycle": state})
}

func (s *Server) createAccountExport(w http.ResponseWriter, r *http.Request) {
	userID, err := s.accountLifecycleActor(r)
	if err != nil {
		writeError(w, http.StatusForbidden, err)
		return
	}
	repo, ok := s.accountLifecycleRepo(w)
	if !ok {
		return
	}
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	export, requestID, err := repo.createAccountExport(ctx, userID, userID)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	writeJSON(w, http.StatusCreated, map[string]any{
		"request_id": requestID,
		"export":     export,
	})
}

func (s *Server) getAccountExport(w http.ResponseWriter, r *http.Request) {
	userID, err := s.accountLifecycleActor(r)
	if err != nil {
		writeError(w, http.StatusForbidden, err)
		return
	}
	repo, ok := s.accountLifecycleRepo(w)
	if !ok {
		return
	}
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	export, err := repo.latestAccountExport(ctx, userID)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	if export == nil {
		writeError(w, http.StatusNotFound,
			errors.New("no export is available; request one first"))
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"export": export})
}
