package mobile

import (
	"math"
	"sort"
	"strings"
	"time"
)

type spotlightTierPolicy struct {
	Tier                 string
	PaidBaselineWeight   int
	ActivityBonusCap     int
	DailyExposureCap     int
	MinProfileCompletion int
	MinActiveBadges      int
}

type spotlightCandidateMeta struct {
	UserID string
	Tier   string
	Score  int
	Reason string
	Paid   bool
	Row    map[string]any
}

func spotlightTierPolicies() map[string]spotlightTierPolicy {
	return map[string]spotlightTierPolicy{
		"bronze": {
			Tier:                 "bronze",
			PaidBaselineWeight:   20,
			ActivityBonusCap:     45,
			DailyExposureCap:     80,
			MinProfileCompletion: 25,
			MinActiveBadges:      0,
		},
		"silver": {
			Tier:                 "silver",
			PaidBaselineWeight:   35,
			ActivityBonusCap:     35,
			DailyExposureCap:     60,
			MinProfileCompletion: 45,
			MinActiveBadges:      1,
		},
		"gold": {
			Tier:                 "gold",
			PaidBaselineWeight:   55,
			ActivityBonusCap:     30,
			DailyExposureCap:     45,
			MinProfileCompletion: 60,
			MinActiveBadges:      1,
		},
		"emerald": {
			Tier:                 "emerald",
			PaidBaselineWeight:   72,
			ActivityBonusCap:     22,
			DailyExposureCap:     32,
			MinProfileCompletion: 70,
			MinActiveBadges:      2,
		},
		"diamond": {
			Tier:                 "diamond",
			PaidBaselineWeight:   88,
			ActivityBonusCap:     15,
			DailyExposureCap:     20,
			MinProfileCompletion: 80,
			MinActiveBadges:      3,
		},
	}
}

var spotlightTierOrder = []string{"bronze", "silver", "gold", "emerald", "diamond"}

func tierRank(tier string) int {
	normalized := strings.ToLower(strings.TrimSpace(tier))
	for index, item := range spotlightTierOrder {
		if item == normalized {
			return index
		}
	}
	return 0
}

func normalizeSpotlightTier(raw string) string {
	normalized := strings.ToLower(strings.TrimSpace(raw))
	switch normalized {
	case "bronze", "silver", "gold", "emerald", "diamond":
		return normalized
	default:
		return "bronze"
	}
}

func (s *Server) attachSpotlightDiscovery(resp map[string]any, viewerUserID string) {
	rows, ok := resp["candidates"].([]any)
	if !ok || len(rows) == 0 {
		resp["spotlight_summary"] = map[string]any{
			"active":           false,
			"injected_count":   0,
			"tier_mix":         map[string]int{},
			"fairness_applied": false,
		}
		resp["spotlight_profiles"] = []any{}
		return
	}

	selected, annotated, summary := s.store.annotateDiscoverySpotlight(rows, viewerUserID)
	resp["candidates"] = annotated
	resp["spotlight_profiles"] = selected
	resp["spotlight_summary"] = summary
}

func (m *memoryStore) annotateDiscoverySpotlight(rows []any, viewerUserID string) ([]any, []any, map[string]any) {
	m.mu.Lock()
	defer m.mu.Unlock()

	m.resetSpotlightCountersIfNeededLocked()
	viewerUserID = strings.TrimSpace(viewerUserID)
	policies := spotlightTierPolicies()

	metas := make([]spotlightCandidateMeta, 0, len(rows))
	annotated := make([]any, 0, len(rows))

	for _, rowAny := range rows {
		row, ok := rowAny.(map[string]any)
		if !ok {
			annotated = append(annotated, rowAny)
			continue
		}

		userID := strings.TrimSpace(toString(row["id"]))
		if userID == "" {
			userID = strings.TrimSpace(toString(row["user_id"]))
		}
		if userID == "" {
			userID = strings.TrimSpace(toString(row["userId"]))
		}
		if userID == "" || userID == viewerUserID {
			row["is_spotlight"] = false
			annotated = append(annotated, row)
			continue
		}

		meta := m.computeSpotlightMetaLocked(userID)
		policy := policies[meta.Tier]
		if policy.DailyExposureCap > 0 && m.spotlightExposureByUser[userID] >= policy.DailyExposureCap {
			row["is_spotlight"] = false
			row["spotlight_tier"] = meta.Tier
			row["spotlight_score"] = meta.Score
			row["spotlight_reason"] = "daily_cap_reached"
			annotated = append(annotated, row)
			continue
		}

		row["is_spotlight"] = false
		row["spotlight_tier"] = meta.Tier
		row["spotlight_score"] = meta.Score
		row["spotlight_reason"] = meta.Reason
		meta.Row = row
		metas = append(metas, meta)
		annotated = append(annotated, row)
	}

	sort.SliceStable(metas, func(i, j int) bool {
		if metas[i].Score == metas[j].Score {
			if tierRank(metas[i].Tier) == tierRank(metas[j].Tier) {
				return metas[i].UserID < metas[j].UserID
			}
			return tierRank(metas[i].Tier) > tierRank(metas[j].Tier)
		}
		return metas[i].Score > metas[j].Score
	})

	limit := 0
	if len(metas) > 0 {
		limit = len(metas) / 4
		if limit < 3 {
			limit = 3
		}
		if limit > 6 {
			limit = 6
		}
		if limit > len(metas) {
			limit = len(metas)
		}
	}

	paid := make([]spotlightCandidateMeta, 0, len(metas))
	nonPaid := make([]spotlightCandidateMeta, 0, len(metas))
	for _, meta := range metas {
		if meta.Paid {
			paid = append(paid, meta)
			continue
		}
		nonPaid = append(nonPaid, meta)
	}

	selected := make([]spotlightCandidateMeta, 0, limit)
	paidTarget := int(math.Round(float64(limit) * 0.7))
	if paidTarget < 1 {
		paidTarget = 1
	}
	if paidTarget > limit {
		paidTarget = limit
	}

	for _, meta := range paid {
		if len(selected) >= paidTarget {
			break
		}
		selected = append(selected, meta)
	}
	for _, meta := range nonPaid {
		if len(selected) >= limit {
			break
		}
		selected = append(selected, meta)
	}
	for _, meta := range paid {
		if len(selected) >= limit {
			break
		}
		alreadySelected := false
		for _, item := range selected {
			if item.UserID == meta.UserID {
				alreadySelected = true
				break
			}
		}
		if alreadySelected {
			continue
		}
		selected = append(selected, meta)
	}

	fairnessApplied := false
	if len(nonPaid) > 0 && len(selected) > 0 {
		hasNonPaid := false
		for _, item := range selected {
			if !item.Paid {
				hasNonPaid = true
				break
			}
		}
		if !hasNonPaid {
			selected[len(selected)-1] = nonPaid[0]
			fairnessApplied = true
		}
	}

	selectedMap := make(map[string]spotlightCandidateMeta, len(selected))
	tierMix := make(map[string]int)
	selectedRows := make([]any, 0, len(selected))
	for _, meta := range selected {
		selectedMap[meta.UserID] = meta
		tierMix[meta.Tier]++
		selectedRows = append(selectedRows, meta.Row)
		meta.Row["is_spotlight"] = true
		m.spotlightExposureByTier[meta.Tier]++
		m.spotlightExposureByUser[meta.UserID]++
		m.spotlightEligibleUsers[meta.UserID] = meta.Tier
	}

	for _, rowAny := range annotated {
		row, ok := rowAny.(map[string]any)
		if !ok {
			continue
		}
		userID := strings.TrimSpace(toString(row["id"]))
		if userID == "" {
			userID = strings.TrimSpace(toString(row["user_id"]))
		}
		if userID == "" {
			userID = strings.TrimSpace(toString(row["userId"]))
		}
		if _, ok := selectedMap[userID]; !ok {
			row["is_spotlight"] = false
		}
	}

	summary := map[string]any{
		"active":           len(selectedRows) > 0,
		"injected_count":   len(selectedRows),
		"tier_mix":         tierMix,
		"fairness_applied": fairnessApplied,
	}
	return selectedRows, annotated, summary
}

func (m *memoryStore) recordSpotlightSwipeOutcome(targetUserID string, isLike bool, isMutualMatch bool) {
	trimmedTarget := strings.TrimSpace(targetUserID)
	if trimmedTarget == "" {
		return
	}

	m.mu.Lock()
	defer m.mu.Unlock()

	m.resetSpotlightCountersIfNeededLocked()
	tier, ok := m.spotlightEligibleUsers[trimmedTarget]
	if !ok || strings.TrimSpace(tier) == "" {
		return
	}
	if isLike {
		m.spotlightLikeByTier[tier]++
	}
	if isMutualMatch {
		m.spotlightMatchByTier[tier]++
	}
}

func (m *memoryStore) resetSpotlightCountersIfNeededLocked() {
	today := time.Now().UTC().Format("2006-01-02")
	if m.spotlightLastResetDate == today {
		return
	}
	m.spotlightLastResetDate = today
	m.spotlightExposureByTier = make(map[string]int)
	m.spotlightLikeByTier = make(map[string]int)
	m.spotlightMatchByTier = make(map[string]int)
	m.spotlightExposureByUser = make(map[string]int)
	m.spotlightEligibleUsers = make(map[string]string)
}

func (m *memoryStore) computeSpotlightMetaLocked(userID string) spotlightCandidateMeta {
	planID := "free"
	planName := "free"
	if subscription, ok := m.subscriptions[userID]; ok {
		planID = strings.ToLower(strings.TrimSpace(subscription.PlanID))
		planName = strings.ToLower(strings.TrimSpace(subscription.PlanName))
	}

	baselineTier := "bronze"
	switch {
	case planName == "diamond" || planID == "diamond":
		baselineTier = "diamond"
	case planName == "emerald" || planID == "emerald":
		baselineTier = "emerald"
	case planName == "gold" || planID == "gold" || planID == "premium":
		baselineTier = "gold"
	case planName == "silver" || planID == "silver":
		baselineTier = "silver"
	case planName == "bronze" || planID == "bronze":
		baselineTier = "bronze"
	case planID == "vip":
		baselineTier = "diamond"
	}

	paid := planID != "free" || (planName != "" && planName != "free" && planName != "bronze")
	activityScore := m.computeSpotlightActivityScoreLocked(userID)
	uplift := 0
	if activityScore >= 85 {
		uplift = 2
	} else if activityScore >= 65 {
		uplift = 1
	}
	if paid && uplift > 1 {
		uplift = 1
	}

	finalRank := tierRank(baselineTier) + uplift
	maxRank := tierRank("diamond")
	if !paid {
		maxRank = tierRank("emerald")
	}
	if finalRank > maxRank {
		finalRank = maxRank
	}
	if finalRank < 0 {
		finalRank = 0
	}
	finalTier := spotlightTierOrder[finalRank]

	activeBadges := m.activeTrustBadgeCountLocked(userID)
	profileCompletion := m.profileCompletionScoreLocked(userID)
	policies := spotlightTierPolicies()
	for finalRank > 0 {
		policy := policies[finalTier]
		if profileCompletion >= policy.MinProfileCompletion && activeBadges >= policy.MinActiveBadges {
			break
		}
		finalRank--
		finalTier = spotlightTierOrder[finalRank]
	}

	policy := policies[finalTier]
	score := policy.PaidBaselineWeight + minInt(activityScore, policy.ActivityBonusCap)
	score = maxInt(0, minInt(100, score))

	reason := "activity_progression"
	if paid {
		reason = "paid_plus_activity"
	}
	if uplift == 0 {
		reason = "paid_baseline"
		if !paid {
			reason = "activity_only"
		}
	}

	return spotlightCandidateMeta{
		UserID: userID,
		Tier:   normalizeSpotlightTier(finalTier),
		Score:  score,
		Reason: reason,
		Paid:   paid,
	}
}

func (m *memoryStore) computeSpotlightActivityScoreLocked(userID string) int {
	profileCompletion := m.profileCompletionScoreLocked(userID)
	activeBadges := m.activeTrustBadgeCountLocked(userID)
	promptAnswers := len(m.dailyPromptAnswers[userID])

	appreciatedGestures := 0
	for _, gestures := range m.matchGestures {
		for _, gesture := range gestures {
			if strings.TrimSpace(gesture.SenderUserID) != userID {
				continue
			}
			if gesture.Status == "appreciated" {
				appreciatedGestures++
			}
		}
	}

	score := 0
	score += minInt(35, profileCompletion/3)
	score += minInt(25, activeBadges*10)
	score += minInt(20, promptAnswers*4)
	score += minInt(20, appreciatedGestures*5)
	return maxInt(0, minInt(100, score))
}

func (m *memoryStore) activeTrustBadgeCountLocked(userID string) int {
	badges := m.userBadges[userID]
	count := 0
	for _, badge := range badges {
		if strings.EqualFold(strings.TrimSpace(badge.Status), "active") {
			count++
		}
	}
	return count
}

func (m *memoryStore) profileCompletionScoreLocked(userID string) int {
	draft := m.profiles[userID]
	return maxInt(0, minInt(100, draft.ProfileCompletion))
}
