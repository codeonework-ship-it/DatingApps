package mobile

import (
	"net/url"
	"strconv"
	"strings"
	"time"
)

type advancedFilterCriteria struct {
	seekingGenders   []string
	educationFilter  []string
	seriousOnly      bool
	verifiedOnly     bool
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
	minAgeYears      int
	maxAgeYears      int
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
	query = s.discoveryPreferenceQuery(userID, query)
	if !hasAdvancedDiscoveryQuery(query) {
		resp["advanced_filter"] = inactiveAdvancedFilterSummary()
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
	if !hasAdvancedDiscoveryQuery(query) {
		resp["advanced_filter"] = inactiveAdvancedFilterSummary()
		return
	}
	criteria := s.buildAdvancedCriteria(userID, query)
	filteredRows, summary := s.applyAdvancedFilterToRows(rows, "userId", criteria)
	resp["matches"] = filteredRows
	resp["advanced_filter"] = summary
}

func inactiveAdvancedFilterSummary() map[string]any {
	return map[string]any{
		"active":             false,
		"filtered_out_count": 0,
		"applied":            map[string]any{},
	}
}

func hasAdvancedDiscoveryQuery(query url.Values) bool {
	for _, key := range []string{
		"seeking_genders", "education_filter", "serious_only",
		"verified_only",
		"intent_tags",
		"language_tags",
		"mother_tongue",
		"pet_preference",
		"diet_preference",
		"workout_frequency",
		"diet_type",
		"sleep_schedule",
		"travel_style",
		"political_comfort_range",
		"deal_breaker_tags",
		"country",
		"state",
		"city",
		"min_age",
		"max_age",
		"religion",
		"relationship_status",
		"smoking",
		"drinking",
		"personality_type",
		"party_lover",
		"hookup_only",
	} {
		if strings.TrimSpace(query.Get(key)) != "" {
			return true
		}
	}
	return false
}

func trimDiscoveryCandidates(resp map[string]any, limit int) {
	if limit <= 0 {
		return
	}
	rows, ok := resp["candidates"].([]any)
	if !ok || len(rows) <= limit {
		return
	}
	resp["candidates"] = rows[:limit]
}

func (s *Server) buildAdvancedCriteria(userID string, query url.Values) advancedFilterCriteria {
	criteria := advancedFilterCriteria{
		seekingGenders:   normalizedList(queryListOrFallback(query, "seeking_genders", nil)),
		educationFilter:  normalizedList(queryListOrFallback(query, "education_filter", nil)),
		seriousOnly:      queryBool(query, "serious_only"),
		verifiedOnly:     queryBool(query, "verified_only"),
		intentTags:       normalizedList(queryListOrFallback(query, "intent_tags", nil)),
		languageTags:     normalizedList(queryListOrFallback(query, "language_tags", nil)),
		motherTongue:     normalizedString(queryFirstOrFallback(query, "mother_tongue", "")),
		petPreference:    normalizedString(queryFirstOrFallback(query, "pet_preference", "")),
		dietPreference:   normalizedString(queryFirstOrFallback(query, "diet_preference", "")),
		workoutFrequency: normalizedString(queryFirstOrFallback(query, "workout_frequency", "")),
		dietType:         normalizedString(queryFirstOrFallback(query, "diet_type", "")),
		sleepSchedule:    normalizedString(queryFirstOrFallback(query, "sleep_schedule", "")),
		travelStyle:      normalizedString(queryFirstOrFallback(query, "travel_style", "")),
		politicalRange:   normalizedString(queryFirstOrFallback(query, "political_comfort_range", "")),
		dealBreakerTags:  normalizedList(queryListOrFallback(query, "deal_breaker_tags", nil)),
		country:          normalizedString(queryFirstOrFallback(query, "country", "")),
		regionState:      normalizedString(queryFirstOrFallback(query, "state", "")),
		city:             normalizedString(queryFirstOrFallback(query, "city", "")),
		minAgeYears:      queryIntOrFallback(query, "min_age", 0),
		maxAgeYears:      queryIntOrFallback(query, "max_age", 0),
		religion:         normalizedString(queryFirstOrFallback(query, "religion", "")),
		relationship:     normalizedString(queryFirstOrFallback(query, "relationship_status", "")),
		smoking:          normalizedString(queryFirstOrFallback(query, "smoking", "")),
		drinking:         normalizedString(queryFirstOrFallback(query, "drinking", "")),
		personalityType:  normalizedString(queryFirstOrFallback(query, "personality_type", "")),
		partyLoverOnly:   queryBool(query, "party_lover"),
		hookupOnly:       queryBoolOrFallback(query, "hookup_only", false),
	}

	return criteria
}

func (s *Server) applyAdvancedFilterToRows(rows []any, idField string, criteria advancedFilterCriteria) ([]any, map[string]any) {
	return applyAdvancedFilterRows(rows, idField, criteria, s.store.getDraft)
}

func applyAdvancedFilterRows(rows []any, idField string, criteria advancedFilterCriteria, load func(string) profileDraft) ([]any, map[string]any) {
	summary := map[string]any{
		"active":             criteria.hasAny(),
		"filtered_out_count": 0,
		"applied": map[string]any{
			"seeking_genders":         criteria.seekingGenders,
			"education_filter":        criteria.educationFilter,
			"serious_only":            criteria.seriousOnly,
			"verified_only":           criteria.verifiedOnly,
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
			"min_age":                 criteria.minAgeYears,
			"max_age":                 criteria.maxAgeYears,
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

		if criteria.verifiedOnly && row["isVerified"] != true && row["is_verified"] != true {
			filteredOut++
			continue
		}
		targetDraft := load(targetID)
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
	return len(c.seekingGenders) > 0 || len(c.educationFilter) > 0 || c.seriousOnly || c.verifiedOnly || len(c.intentTags) > 0 ||
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
		c.minAgeYears > 0 ||
		c.maxAgeYears > 0 ||
		c.religion != "" ||
		c.relationship != "" ||
		c.smoking != "" ||
		c.drinking != "" ||
		c.personalityType != "" ||
		c.partyLoverOnly ||
		c.hookupOnly
}

func (c advancedFilterCriteria) matches(draft profileDraft) bool {
	if len(c.seekingGenders) > 0 {
		matched := false
		for _, gender := range c.seekingGenders {
			if canonicalGender(gender) == canonicalGender(draft.Gender) {
				matched = true
			}
		}
		if !matched {
			return false
		}
	}
	if len(c.educationFilter) > 0 && !hasAnyOverlap(c.educationFilter, []string{derefString(draft.Education)}) {
		return false
	}
	if c.seriousOnly && !hasAnyOverlap([]string{"long_term", "long-term", "long term", "marriage", "serious", "serious_only", "serious_relationship", "serious relationship"}, draft.IntentTags) {
		return false
	}

	if c.country != "" && normalizedString(derefString(draft.Country)) != c.country {
		return false
	}
	if c.regionState != "" && normalizedString(derefString(draft.RegionState)) != c.regionState {
		return false
	}
	if c.city != "" && normalizedString(derefString(draft.City)) != c.city {
		return false
	}
	age := ageYearsFromDateOfBirth(draft.DateOfBirth, time.Now().UTC())
	if c.minAgeYears > 0 && (age == 0 || age < c.minAgeYears) {
		return false
	}
	if c.maxAgeYears > 0 && (age == 0 || age > c.maxAgeYears) {
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
	if c.hookupOnly && !draft.HookupOnly && !hasAnyOverlap([]string{"hookup", "casual"}, draft.IntentTags) {
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
		if normalizedString(derefString(draft.MotherTongue)) != c.motherTongue {
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

func queryIntOrFallback(query url.Values, key string, fallback int) int {
	raw := strings.TrimSpace(query.Get(key))
	if raw == "" {
		return fallback
	}
	value, err := strconv.Atoi(raw)
	if err != nil || value < 0 {
		return fallback
	}
	return value
}

func ageYearsFromDateOfBirth(raw string, now time.Time) int {
	dob, err := time.Parse("2006-01-02", strings.TrimSpace(raw))
	if err != nil {
		return 0
	}
	age := now.Year() - dob.Year()
	if now.Month() < dob.Month() || (now.Month() == dob.Month() && now.Day() < dob.Day()) {
		age--
	}
	if age < 0 {
		return 0
	}
	return age
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

// Saved partner criteria apply on the first request. Query key presence is an
// explicit override, including false/empty; personal lifestyle is not a partner filter.
func (s *Server) discoveryPreferenceQuery(userID string, query url.Values) url.Values {
	out := make(url.Values, len(query)+6)
	for key, values := range query {
		out[key] = append([]string(nil), values...)
	}
	if s.store.profileRepo == nil {
		s.store.mu.Lock()
		_, saved := s.store.profiles[userID]
		s.store.mu.Unlock()
		if !saved {
			return out
		}
	}
	draft := s.store.getDraft(userID)
	defaults := map[string]string{
		"seeking_genders":  strings.Join(draft.SeekingGenders, ","),
		"education_filter": strings.Join(draft.EducationFilter, ","),
		"min_age":          strconv.Itoa(draft.MinAgeYears), "max_age": strconv.Itoa(draft.MaxAgeYears),
		"verified_only": strconv.FormatBool(draft.VerifiedOnly),
		"serious_only":  strconv.FormatBool(draft.SeriousOnly),
	}
	for key, value := range defaults {
		if _, exists := out[key]; !exists {
			out.Set(key, value)
		}
	}
	return out
}

func canonicalGender(value string) string {
	switch normalizedString(value) {
	case "m", "male", "man":
		return "m"
	case "f", "female", "woman":
		return "f"
	default:
		return normalizedString(value)
	}
}
