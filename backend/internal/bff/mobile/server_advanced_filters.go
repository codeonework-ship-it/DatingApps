package mobile

import (
	"net/url"
	"strings"
)

type advancedFilterCriteria struct {
	intentTags       []string
	languageTags     []string
	motherTongue     string
	petPreference    string
	dietPreference   string
	workoutFrequency string
	dietType         string
	sleepSchedule    string
	travelStyle      string
	politicalRange   string
	dealBreakerTags  []string
	country          string
	regionState      string
	city             string
	religion         string
	relationship     string
	smoking          string
	drinking         string
	personalityType  string
	partyLoverOnly   bool
	hookupOnly       bool
}

func (s *Server) attachAdvancedFilteredDiscovery(resp map[string]any, userID string, query url.Values) {
	rows, ok := resp["candidates"].([]any)
	if !ok {
		return
	}
	criteria := s.buildAdvancedCriteria(userID, query)
	filteredRows, summary := s.applyAdvancedFilterToRows(rows, "id", criteria)
	resp["candidates"] = filteredRows
	resp["advanced_filter"] = summary
}

func (s *Server) attachAdvancedFilteredMatches(resp map[string]any, userID string, query url.Values) {
	rows, ok := resp["matches"].([]any)
	if !ok {
		return
	}
	criteria := s.buildAdvancedCriteria(userID, query)
	filteredRows, summary := s.applyAdvancedFilterToRows(rows, "userId", criteria)
	resp["matches"] = filteredRows
	resp["advanced_filter"] = summary
}

func (s *Server) buildAdvancedCriteria(userID string, query url.Values) advancedFilterCriteria {
	viewer := s.store.getDraft(userID)

	criteria := advancedFilterCriteria{
		intentTags:       normalizedList(queryListOrFallback(query, "intent_tags", viewer.IntentTags)),
		languageTags:     normalizedList(queryListOrFallback(query, "language_tags", viewer.LanguageTags)),
		motherTongue:     normalizedString(queryFirstOrFallback(query, "mother_tongue", derefString(viewer.MotherTongue))),
		petPreference:    normalizedString(queryFirstOrFallback(query, "pet_preference", derefString(viewer.PetPreference))),
		dietPreference:   normalizedString(queryFirstOrFallback(query, "diet_preference", derefString(viewer.DietPreference))),
		workoutFrequency: normalizedString(queryFirstOrFallback(query, "workout_frequency", derefString(viewer.WorkoutFrequency))),
		dietType:         normalizedString(queryFirstOrFallback(query, "diet_type", derefString(viewer.DietType))),
		sleepSchedule:    normalizedString(queryFirstOrFallback(query, "sleep_schedule", derefString(viewer.SleepSchedule))),
		travelStyle:      normalizedString(queryFirstOrFallback(query, "travel_style", derefString(viewer.TravelStyle))),
		politicalRange:   normalizedString(queryFirstOrFallback(query, "political_comfort_range", derefString(viewer.PoliticalComfort))),
		dealBreakerTags:  normalizedList(queryListOrFallback(query, "deal_breaker_tags", viewer.DealBreakerTags)),
		country:          normalizedString(queryFirstOrFallback(query, "country", derefString(viewer.Country))),
		regionState:      normalizedString(queryFirstOrFallback(query, "state", derefString(viewer.RegionState))),
		city:             normalizedString(queryFirstOrFallback(query, "city", derefString(viewer.City))),
		religion:         normalizedString(queryFirstOrFallback(query, "religion", derefString(viewer.Religion))),
		relationship:     normalizedString(queryFirstOrFallback(query, "relationship_status", derefString(viewer.RelationshipStatus))),
		smoking:          normalizedString(queryFirstOrFallback(query, "smoking", viewer.Smoking)),
		drinking:         normalizedString(queryFirstOrFallback(query, "drinking", viewer.Drinking)),
		personalityType:  normalizedString(queryFirstOrFallback(query, "personality_type", derefString(viewer.PersonalityType))),
		partyLoverOnly:   queryBool(query, "party_lover"),
		hookupOnly:       queryBoolOrFallback(query, "hookup_only", viewer.HookupOnly),
	}

	return criteria
}

func (s *Server) applyAdvancedFilterToRows(rows []any, idField string, criteria advancedFilterCriteria) ([]any, map[string]any) {
	summary := map[string]any{
		"active":             criteria.hasAny(),
		"filtered_out_count": 0,
		"applied": map[string]any{
			"intent_tags":             criteria.intentTags,
			"language_tags":           criteria.languageTags,
			"mother_tongue":           criteria.motherTongue,
			"pet_preference":          criteria.petPreference,
			"diet_preference":         criteria.dietPreference,
			"workout_frequency":       criteria.workoutFrequency,
			"diet_type":               criteria.dietType,
			"sleep_schedule":          criteria.sleepSchedule,
			"travel_style":            criteria.travelStyle,
			"political_comfort_range": criteria.politicalRange,
			"deal_breaker_tags":       criteria.dealBreakerTags,
			"country":                 criteria.country,
			"state":                   criteria.regionState,
			"city":                    criteria.city,
			"religion":                criteria.religion,
			"relationship_status":     criteria.relationship,
			"smoking":                 criteria.smoking,
			"drinking":                criteria.drinking,
			"personality_type":        criteria.personalityType,
			"party_lover":             criteria.partyLoverOnly,
			"hookup_only":             criteria.hookupOnly,
		},
	}

	if !criteria.hasAny() {
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
		targetID := strings.TrimSpace(toString(row[idField]))
		if targetID == "" {
			filtered = append(filtered, row)
			continue
		}

		targetDraft := s.store.getDraft(targetID)
		if criteria.matches(targetDraft) {
			filtered = append(filtered, row)
			continue
		}
		filteredOut++
	}
	summary["filtered_out_count"] = filteredOut
	return filtered, summary
}

func (c advancedFilterCriteria) hasAny() bool {
	return len(c.intentTags) > 0 ||
		len(c.languageTags) > 0 ||
		c.motherTongue != "" ||
		c.petPreference != "" ||
		c.dietPreference != "" ||
		c.workoutFrequency != "" ||
		c.dietType != "" ||
		c.sleepSchedule != "" ||
		c.travelStyle != "" ||
		c.politicalRange != "" ||
		len(c.dealBreakerTags) > 0 ||
		c.country != "" ||
		c.regionState != "" ||
		c.city != "" ||
		c.religion != "" ||
		c.relationship != "" ||
		c.smoking != "" ||
		c.drinking != "" ||
		c.personalityType != "" ||
		c.partyLoverOnly ||
		c.hookupOnly
}

func (c advancedFilterCriteria) matches(draft profileDraft) bool {
	if c.country != "" && normalizedString(derefString(draft.Country)) != c.country {
		return false
	}
	if c.regionState != "" && normalizedString(derefString(draft.RegionState)) != c.regionState {
		return false
	}
	if c.city != "" && normalizedString(derefString(draft.City)) != c.city {
		return false
	}
	if c.religion != "" && normalizedString(derefString(draft.Religion)) != c.religion {
		return false
	}
	if c.relationship != "" && normalizedString(derefString(draft.RelationshipStatus)) != c.relationship {
		return false
	}
	if c.smoking != "" && normalizedString(draft.Smoking) != c.smoking {
		return false
	}
	if c.drinking != "" && normalizedString(draft.Drinking) != c.drinking {
		return false
	}
	if c.personalityType != "" && normalizedString(derefString(draft.PersonalityType)) != c.personalityType {
		return false
	}
	if c.partyLoverOnly && !derefBool(draft.PartyLover) {
		return false
	}
	if c.hookupOnly && !hasAnyOverlap([]string{"hookup", "casual"}, draft.IntentTags) {
		return false
	}
	if c.petPreference != "" && normalizedString(derefString(draft.PetPreference)) != c.petPreference {
		return false
	}
	if c.dietPreference != "" && normalizedString(derefString(draft.DietPreference)) != c.dietPreference {
		return false
	}
	if c.workoutFrequency != "" && normalizedString(derefString(draft.WorkoutFrequency)) != c.workoutFrequency {
		return false
	}
	if c.dietType != "" && normalizedString(derefString(draft.DietType)) != c.dietType {
		return false
	}
	if c.sleepSchedule != "" && normalizedString(derefString(draft.SleepSchedule)) != c.sleepSchedule {
		return false
	}
	if c.travelStyle != "" && normalizedString(derefString(draft.TravelStyle)) != c.travelStyle {
		return false
	}
	if c.politicalRange != "" && normalizedString(derefString(draft.PoliticalComfort)) != c.politicalRange {
		return false
	}

	if len(c.intentTags) > 0 && !hasAnyOverlap(c.intentTags, draft.IntentTags) {
		return false
	}
	if len(c.languageTags) > 0 && !hasAnyOverlap(c.languageTags, draft.LanguageTags) {
		return false
	}
	if c.motherTongue != "" {
		if !hasAnyOverlap([]string{c.motherTongue}, draft.LanguageTags) {
			return false
		}
	}
	if len(c.dealBreakerTags) > 0 && hasAnyOverlap(c.dealBreakerTags, draft.DealBreakerTags) {
		return false
	}
	return true
}

func queryBool(query url.Values, key string) bool {
	raw := strings.TrimSpace(strings.ToLower(query.Get(key)))
	return raw == "1" || raw == "true" || raw == "yes"
}

func queryBoolOrFallback(query url.Values, key string, fallback bool) bool {
	raw := strings.TrimSpace(strings.ToLower(query.Get(key)))
	if raw == "" {
		return fallback
	}
	return raw == "1" || raw == "true" || raw == "yes"
}

func derefBool(value *bool) bool {
	if value == nil {
		return false
	}
	return *value
}

func hasAnyOverlap(left []string, right []string) bool {
	if len(left) == 0 || len(right) == 0 {
		return false
	}
	set := make(map[string]struct{}, len(right))
	for _, item := range right {
		normalized := normalizedString(item)
		if normalized == "" {
			continue
		}
		set[normalized] = struct{}{}
	}
	for _, item := range left {
		normalized := normalizedString(item)
		if normalized == "" {
			continue
		}
		if _, ok := set[normalized]; ok {
			return true
		}
	}
	return false
}

func normalizedList(items []string) []string {
	out := make([]string, 0, len(items))
	seen := make(map[string]struct{}, len(items))
	for _, item := range items {
		normalized := normalizedString(item)
		if normalized == "" {
			continue
		}
		if _, ok := seen[normalized]; ok {
			continue
		}
		seen[normalized] = struct{}{}
		out = append(out, normalized)
	}
	return out
}

func normalizedString(value string) string {
	return strings.ToLower(strings.TrimSpace(value))
}

func derefString(value *string) string {
	if value == nil {
		return ""
	}
	return *value
}

func queryListOrFallback(query url.Values, key string, fallback []string) []string {
	raw := strings.TrimSpace(query.Get(key))
	if raw == "" {
		return append([]string{}, fallback...)
	}
	parts := strings.Split(raw, ",")
	out := make([]string, 0, len(parts))
	for _, item := range parts {
		trimmed := strings.TrimSpace(item)
		if trimmed == "" {
			continue
		}
		out = append(out, trimmed)
	}
	return out
}

func queryFirstOrFallback(query url.Values, key string, fallback string) string {
	raw := strings.TrimSpace(query.Get(key))
	if raw == "" {
		return fallback
	}
	return raw
}
