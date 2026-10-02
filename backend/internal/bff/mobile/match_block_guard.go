package mobile

import (
	"context"
	"errors"
	"net/http"

	"github.com/google/uuid"
)

// A block ends contact. Blocking only writes user_management.blocked_users;
// it does not change the match, so the match-ownership check still passed and
// the blocked member could keep sending chat messages and gifts to the member
// who blocked them (API-11). Writes into a match are refused while either side
// has blocked the other; unblocking restores them.

// matchPairBlocked reports whether either member of the match blocked the
// other. A malformed id names no match.
func (r *profileRepository) matchPairBlocked(ctx context.Context, matchID string) (bool, error) {
	if _, err := uuid.Parse(matchID); err != nil {
		return false, nil
	}
	var blocked bool
	err := r.pg.QueryRowContext(ctx, `SELECT EXISTS(SELECT 1 FROM matching.matches m
 WHERE m.id=$1 AND NOT `+socialNotBlockedSQL("m.user_id_1", "m.user_id_2")+`)`, matchID).Scan(&blocked)
	return blocked, err
}

// refuseBlockedMatchWrite answers 403 MATCH_BLOCKED (or 503 when the check
// cannot run: fail closed) and reports whether it wrote a response.
func (s *Server) refuseBlockedMatchWrite(w http.ResponseWriter, r *http.Request, matchID string) bool {
	if s == nil || s.store == nil || s.store.profileRepo == nil || s.store.profileRepo.pg == nil {
		return false
	}
	blocked, err := s.store.profileRepo.matchPairBlocked(r.Context(), matchID)
	if err != nil {
		w.Header().Set("Retry-After", "2")
		writeError(w, http.StatusServiceUnavailable, errors.New("unable to check this conversation right now"))
		return true
	}
	if blocked {
		writeJSON(w, http.StatusForbidden, map[string]any{
			"success":    false,
			"error":      "This conversation is no longer available.",
			"error_code": "MATCH_BLOCKED",
			"match_id":   matchID,
		})
		return true
	}
	return false
}

// pairBlocked reports whether either member blocked the other.
func (r *profileRepository) pairBlocked(ctx context.Context, first, second string) (bool, error) {
	if _, err := uuid.Parse(first); err != nil {
		return false, nil
	}
	if _, err := uuid.Parse(second); err != nil {
		return false, nil
	}
	var blocked bool
	err := r.pg.QueryRowContext(ctx, `SELECT NOT `+socialNotBlockedSQL("$1::uuid", "$2::uuid"), first, second).Scan(&blocked)
	return blocked, err
}

// refuseBlockedLike stops a like between two members when either blocked the
// other. Discovery hides blocked members, but a like sent from a stale deck or
// straight to the API was accepted, and two likes made a brand-new match
// between a member and the person they had blocked (API-12).
func (s *Server) refuseBlockedLike(w http.ResponseWriter, r *http.Request, actor, target string) bool {
	if s == nil || s.store == nil || s.store.profileRepo == nil || s.store.profileRepo.pg == nil {
		return false
	}
	blocked, err := s.store.profileRepo.pairBlocked(r.Context(), actor, target)
	if err != nil {
		w.Header().Set("Retry-After", "2")
		writeError(w, http.StatusServiceUnavailable, errors.New("unable to check this member right now"))
		return true
	}
	if blocked {
		writeJSON(w, http.StatusNotFound, map[string]any{
			"success":    false,
			"error":      "This member isn't available.",
			"error_code": "MEMBER_UNAVAILABLE",
		})
		return true
	}
	return false
}
