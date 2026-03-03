package mobile

import (
	"errors"
	"net/http"
	"sort"
	"strconv"
	"strings"

	"github.com/go-chi/chi/v5"
)

func (s *Server) getDiscoveryTrustFilter(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("user id is required"))
		return
	}

	filter, err := s.store.getTrustFilterPreference(userID)
	if err != nil {
		writeError(w, http.StatusBadRequest, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"trust_filter":     filter,
		"available_badges": trustBadgeCatalog(),
	})
}

func (s *Server) patchDiscoveryTrustFilter(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("user id is required"))
		return
	}

	payload, ok := readJSON(w, r)
	if !ok {
		return
	}

	enabled, _ := payload["enabled"].(bool)
	minimumActiveBadges, _ := toInt(payload["minimum_active_badges"])
	requiredBadgeCodes, _ := toStringSlice(payload["required_badge_codes"])

	filter, err := s.store.upsertTrustFilterPreference(
		userID,
		enabled,
		minimumActiveBadges,
		requiredBadgeCodes,
	)
	if err != nil {
		writeError(w, http.StatusBadRequest, err)
		return
	}

	s.store.recordActivity(activityEvent{
		UserID:   userID,
		Actor:    userID,
		Action:   "trust.filter.update",
		Status:   "success",
		Resource: "/discovery/" + userID + "/filters/trust",
		Details: map[string]any{
			"enabled":               filter.Enabled,
			"minimum_active_badges": filter.MinimumActiveBadges,
			"required_badge_codes":  filter.RequiredBadgeCodes,
		},
	})

	writeJSON(w, http.StatusOK, map[string]any{
		"trust_filter":     filter,
		"available_badges": trustBadgeCatalog(),
	})
}

func (s *Server) attachTrustFilteredDiscovery(resp map[string]any, userID string) {
	rows, ok := resp["candidates"].([]any)
	if !ok {
		return
	}
	filteredRows, summary := s.applyTrustFilterToRows(rows, userID, "id")
	resp["candidates"] = filteredRows
	resp["trust_filter"] = summary
}

func (s *Server) attachTrustFilteredMatches(resp map[string]any, userID string) {
	rows, ok := resp["matches"].([]any)
	if !ok {
		return
	}
	filteredRows, summary := s.applyTrustFilterToRows(rows, userID, "userId")
	resp["matches"] = filteredRows
	resp["trust_filter"] = summary
}

func (s *Server) applyTrustFilterToRows(rows []any, userID, idField string) ([]any, map[string]any) {
	filter, err := s.store.getTrustFilterPreference(userID)
	if err != nil {
		return rows, map[string]any{"active": false}
	}

	summary := map[string]any{
		"active":                filter.Enabled,
		"minimum_active_badges": filter.MinimumActiveBadges,
		"required_badge_codes":  filter.RequiredBadgeCodes,
		"filtered_out_count":    0,
	}

	if !filter.Enabled {
		return rows, summary
	}

	filtered := make([]any, 0, len(rows))
	filteredOut := 0
	for _, rowAny := range rows {
		row, ok := rowAny.(map[string]any)
		if !ok {
			filtered = append(filtered, rowAny)
			continue
		}

		targetUserID := strings.TrimSpace(toString(row[idField]))
		if targetUserID == "" {
			filtered = append(filtered, row)
			continue
		}

		activeBadges, badgeErr := s.store.listActiveTrustBadgeCodes(targetUserID)
		if badgeErr != nil {
			activeBadges = []string{}
		}
		row["trust_badges"] = activeBadges

		if trustFilterMatches(filter, activeBadges) {
			filtered = append(filtered, row)
			continue
		}
		filteredOut++
	}

	summary["filtered_out_count"] = filteredOut
	return filtered, summary
}

func trustFilterMatches(filter trustFilterPreference, activeBadgeCodes []string) bool {
	if !filter.Enabled {
		return true
	}

	activeSet := make(map[string]struct{}, len(activeBadgeCodes))
	for _, code := range activeBadgeCodes {
		activeSet[strings.ToLower(strings.TrimSpace(code))] = struct{}{}
	}

	if len(activeSet) < filter.MinimumActiveBadges {
		return false
	}

	for _, required := range filter.RequiredBadgeCodes {
		if _, ok := activeSet[required]; !ok {
			return false
		}
	}
	return true
}

func parseTrustFilterLimit(raw string, fallback int) int {
	trimmed := strings.TrimSpace(raw)
	if trimmed == "" {
		return fallback
	}
	parsed, err := strconv.Atoi(trimmed)
	if err != nil {
		return fallback
	}
	if parsed <= 0 {
		return fallback
	}
	return parsed
}

func sortedBadgeCodes(items []string) []string {
	out := append([]string{}, items...)
	sort.Strings(out)
	return out
}
