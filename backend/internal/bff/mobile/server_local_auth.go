package mobile

import (
	"errors"
	"net/http"
)

// requireLocalSignupUser binds all local signup mutations to the opaque access
// token issued by the native PostgreSQL auth service. Remote deployments keep
// their existing gateway authentication path.
func (s *Server) requireLocalSignupUser(w http.ResponseWriter, r *http.Request, expectedUserID string) bool {
	if !s.cfg.UseLocalDB {
		return true
	}
	if s.store.profileRepo == nil || s.store.profileRepo.pg == nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("local signup persistence is unavailable"))
		return false
	}
	userID, err := s.store.profileRepo.userIDForAccessToken(r.Context(), r.Header.Get("Authorization"))
	if err != nil || userID != expectedUserID {
		writeError(w, http.StatusUnauthorized, errors.New("valid signup session is required"))
		return false
	}
	return true
}
