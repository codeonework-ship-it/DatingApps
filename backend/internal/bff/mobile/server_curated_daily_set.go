package mobile

import (
	"errors"
	"net/http"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"go.uber.org/zap"

	matchingapp "github.com/verified-dating/backend/internal/modules/matching/application"
)

// HTTP surface for the curated daily set (migration 095, DISC-003).
//
//	GET /discovery/{userID}/today    today's curated set with reasons
//
// The discovery root is self-owned (server_security.go pathOwnedByPrincipal),
// so {userID} is always the caller. The route is gated by the
// curated_daily_set_enabled runtime flag (server_feature_flags.go).

func (s *Server) curatedDailySet() (*curatedDailySetService, error) {
	db, err := s.growthDB()
	if err != nil {
		return nil, errors.New("curated daily set persistence is unavailable")
	}
	return newCuratedDailySetService(db), nil
}

func (s *Server) getCuratedDailySet(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("user id is required"))
		return
	}
	// Belt and braces: the ownership middleware already pins the path to the
	// principal, but a curated set is private to the member it was built for.
	if principal, ok := principalFromRequest(r); ok && strings.TrimSpace(principal.UserID) != "" && principal.UserID != userID {
		writeError(w, http.StatusForbidden, errors.New("curated set belongs to another member"))
		return
	}
	svc, err := s.curatedDailySet()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	pool, err := s.curatedEligiblePool(ctx, userID, r.URL.Query())
	if err != nil {
		if errors.Is(err, matchingapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		s.log.Error("curated_daily_set_pool_failed", zap.String("user_id", userID), zap.Error(err))
		writeError(w, http.StatusServiceUnavailable, errors.New("discovery is temporarily unavailable"))
		return
	}
	result, err := svc.serve(ctx, userID, pool)
	if err != nil {
		s.log.Error("curated_daily_set_failed", zap.String("user_id", userID), zap.Error(err))
		writeError(w, http.StatusServiceUnavailable, errors.New("curated daily set is temporarily unavailable"))
		return
	}
	candidates := make([]any, 0, len(result.Candidates))
	for _, row := range result.Candidates {
		candidates = append(candidates, row)
	}
	refreshedAt := ""
	if !result.GeneratedAt.IsZero() {
		refreshedAt = result.GeneratedAt.UTC().Format(time.RFC3339)
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"set_date":      result.SetDate,
		"candidates":    candidates,
		"refreshed_at":  refreshedAt,
		"model_version": result.ModelVersion,
		"generated":     result.Generated,
	})
}
