package mobile

import (
	"errors"
	"sort"
	"strings"
	"time"
)

type trustFilterPreference struct {
	UserID              string   `json:"user_id"`
	Enabled             bool     `json:"enabled"`
	MinimumActiveBadges int      `json:"minimum_active_badges"`
	RequiredBadgeCodes  []string `json:"required_badge_codes"`
	UpdatedAt           string   `json:"updated_at"`
}

func (m *memoryStore) getTrustFilterPreference(userID string) (trustFilterPreference, error) {
	trimmedUserID := strings.TrimSpace(userID)
	if trimmedUserID == "" {
		return trustFilterPreference{}, errors.New("user_id is required")
	}

	m.mu.RLock()
	defer m.mu.RUnlock()

	if item, ok := m.trustFilters[trimmedUserID]; ok {
		return copyTrustFilter(item), nil
	}

	return trustFilterPreference{
		UserID:              trimmedUserID,
		Enabled:             false,
		MinimumActiveBadges: 0,
		RequiredBadgeCodes:  []string{},
		UpdatedAt:           time.Now().UTC().Format(time.RFC3339),
	}, nil
}

func (m *memoryStore) upsertTrustFilterPreference(
	userID string,
	enabled bool,
	minimumActiveBadges int,
	requiredBadgeCodes []string,
) (trustFilterPreference, error) {
	trimmedUserID := strings.TrimSpace(userID)
	if trimmedUserID == "" {
		return trustFilterPreference{}, errors.New("user_id is required")
	}

	if minimumActiveBadges < 0 {
		minimumActiveBadges = 0
	}
	if minimumActiveBadges > len(trustBadgeCatalog()) {
		minimumActiveBadges = len(trustBadgeCatalog())
	}

	normalizedCodes := normalizeTrustBadgeCodes(requiredBadgeCodes)
	if err := validateTrustBadgeCodes(normalizedCodes); err != nil {
		return trustFilterPreference{}, err
	}

	item := trustFilterPreference{
		UserID:              trimmedUserID,
		Enabled:             enabled,
		MinimumActiveBadges: minimumActiveBadges,
		RequiredBadgeCodes:  normalizedCodes,
		UpdatedAt:           time.Now().UTC().Format(time.RFC3339),
	}

	m.mu.Lock()
	m.trustFilters[trimmedUserID] = item
	m.mu.Unlock()

	return copyTrustFilter(item), nil
}

func (m *memoryStore) listActiveTrustBadgeCodes(userID string) ([]string, error) {
	trimmedUserID := strings.TrimSpace(userID)
	if trimmedUserID == "" {
		return nil, errors.New("user_id is required")
	}

	m.mu.RLock()
	defer m.mu.RUnlock()

	breakdown := m.computeTrustSignalBreakdownLocked(trimmedUserID)
	rules := m.evaluateBadgeRulesLocked(breakdown)
	active := make([]string, 0, len(rules))
	for badgeCode, decision := range rules {
		if decision.active {
			active = append(active, badgeCode)
		}
	}
	sort.Strings(active)
	return active, nil
}

func validateTrustBadgeCodes(codes []string) error {
	allowed := make(map[string]struct{}, len(trustBadgeCatalog()))
	for _, badge := range trustBadgeCatalog() {
		allowed[badge.BadgeCode] = struct{}{}
	}
	for _, code := range codes {
		if _, ok := allowed[code]; ok {
			continue
		}
		return errors.New("invalid required badge code")
	}
	return nil
}

func normalizeTrustBadgeCodes(codes []string) []string {
	seen := map[string]struct{}{}
	out := make([]string, 0, len(codes))
	for _, item := range codes {
		code := strings.ToLower(strings.TrimSpace(item))
		if code == "" {
			continue
		}
		if _, ok := seen[code]; ok {
			continue
		}
		seen[code] = struct{}{}
		out = append(out, code)
	}
	sort.Strings(out)
	return out
}

func copyTrustFilter(item trustFilterPreference) trustFilterPreference {
	out := item
	out.RequiredBadgeCodes = append([]string{}, item.RequiredBadgeCodes...)
	return out
}
