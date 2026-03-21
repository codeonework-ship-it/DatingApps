package mobile

import (
	"context"
	"math"
	"net/url"
	"sort"
	"strings"
	"time"

	"github.com/verified-dating/backend/internal/platform/config"
	"github.com/verified-dating/backend/internal/platform/supabase"
)

type spotlightRepository struct {
	cfg config.Config
	db  *supabase.Client
}

type spotlightUserCounter struct {
	ExposureCount int
	LikeCount     int
	MatchCount    int
}

type spotlightSignalData struct {
	ProfileCompletion int
	ActiveBadgeCount  int
	PromptAnswerCount int
	GestureScoreCount int
	SubscriptionTier  string
	SubscriptionPaid  bool
}

func newSpotlightRepository(cfg config.Config) *spotlightRepository {
	apiKey := strings.TrimSpace(cfg.SupabaseServiceRole)
	if apiKey == "" {
		apiKey = strings.TrimSpace(cfg.SupabaseAnonKey)
	}
	if strings.TrimSpace(cfg.SupabaseURL) == "" || apiKey == "" {
		return nil
	}
	client := supabase.NewClient(
		cfg.SupabaseURL,
		cfg.SupabaseAnonKey,
		cfg.SupabaseServiceRole,
		time.Duration(cfg.SupabaseHTTPTimeoutSec)*time.Second,
	)
	client.SetReadBaseURL(cfg.SupabaseReadReplicaURL)
	return &spotlightRepository{cfg: cfg, db: client}
}

func isSpotlightRepoPersistenceUnavailable(err error) bool {
	if err == nil {
		return false
	}
	msg := strings.ToLower(err.Error())
	return strings.Contains(msg, "pgrst106") ||
		strings.Contains(msg, "pgrst205") ||
		strings.Contains(msg, "invalid schema") ||
		strings.Contains(msg, "could not find the table")
}

func (r *spotlightRepository) annotateDiscoverySpotlight(
	ctx context.Context,
	rows []any,
	viewerUserID string,
) ([]any, []any, map[string]any, error) {
	if len(rows) == 0 {
		summary := map[string]any{
			"active":           false,
			"injected_count":   0,
			"tier_mix":         map[string]int{},
			"fairness_applied": false,
		}
		return []any{}, []any{}, summary, nil
	}

	viewerUserID = strings.TrimSpace(viewerUserID)
	now := time.Now().UTC()
	today := now.Format("2006-01-02")
	policies := spotlightTierPolicies()

	candidateIDs := extractCandidateUserIDs(rows, viewerUserID)
	if len(candidateIDs) == 0 {
		summary := map[string]any{
			"active":           false,
			"injected_count":   0,
			"tier_mix":         map[string]int{},
			"fairness_applied": false,
		}
		return []any{}, rows, summary, nil
	}

	signalsByUser, err := r.loadSpotlightSignals(ctx, candidateIDs)
	if err != nil {
		return nil, nil, nil, err
	}
	userCounters, err := r.loadSpotlightUserCounters(ctx, today, candidateIDs)
	if err != nil {
		return nil, nil, nil, err
	}

	metas := make([]spotlightCandidateMeta, 0, len(rows))
	annotated := make([]any, 0, len(rows))

	for _, rowAny := range rows {
		row, ok := rowAny.(map[string]any)
		if !ok {
			annotated = append(annotated, rowAny)
			continue
		}

		userID := spotlightUserIDFromRow(row)
		if userID == "" || userID == viewerUserID {
			row["is_spotlight"] = false
			annotated = append(annotated, row)
			continue
		}

		meta := buildSpotlightMetaFromSignals(userID, signalsByUser[userID])
		policy := policies[meta.Tier]
		if policy.DailyExposureCap > 0 && userCounters[userID].ExposureCount >= policy.DailyExposureCap {
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
		} else {
			nonPaid = append(nonPaid, meta)
		}
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

	incTier := make(map[string]int)
	incUser := make(map[string]int)
	eligibilityPayload := make([]map[string]any, 0, len(metas))

	for _, meta := range metas {
		eligibilityPayload = append(eligibilityPayload, map[string]any{
			"user_id":        meta.UserID,
			"tier":           meta.Tier,
			"eligible":       true,
			"reason":         meta.Reason,
			"updated_at":     now.Format(time.RFC3339),
			"effective_from": now.Format(time.RFC3339),
		})
	}

	for _, meta := range selected {
		selectedMap[meta.UserID] = meta
		tierMix[meta.Tier]++
		selectedRows = append(selectedRows, meta.Row)
		meta.Row["is_spotlight"] = true
		incTier[meta.Tier]++
		incUser[meta.UserID]++
	}

	for _, rowAny := range annotated {
		row, ok := rowAny.(map[string]any)
		if !ok {
			continue
		}
		userID := spotlightUserIDFromRow(row)
		if _, ok := selectedMap[userID]; !ok {
			row["is_spotlight"] = false
		}
	}

	if len(eligibilityPayload) > 0 {
		if _, err := r.db.Upsert(ctx, r.cfg.MatchingSchema, "spotlight_eligibility", eligibilityPayload, "user_id"); err != nil {
			return nil, nil, nil, err
		}
	}

	if err := r.persistExposureCounters(ctx, today, userCounters, incUser, incTier); err != nil {
		return nil, nil, nil, err
	}

	summary := map[string]any{
		"active":           len(selectedRows) > 0,
		"injected_count":   len(selectedRows),
		"tier_mix":         tierMix,
		"fairness_applied": fairnessApplied,
	}
	return selectedRows, annotated, summary, nil
}

func (r *spotlightRepository) recordSpotlightSwipeOutcome(
	ctx context.Context,
	targetUserID string,
	isLike bool,
	isMutualMatch bool,
) error {
	trimmedTarget := strings.TrimSpace(targetUserID)
	if trimmedTarget == "" || (!isLike && !isMutualMatch) {
		return nil
	}

	today := time.Now().UTC().Format("2006-01-02")

	tier := "bronze"
	params := url.Values{}
	params.Set("user_id", "eq."+trimmedTarget)
	params.Set("limit", "1")
	params.Set("select", "tier")
	rows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "spotlight_eligibility", params)
	if err != nil {
		return err
	}
	if len(rows) > 0 {
		if value := normalizeSpotlightTier(toString(rows[0]["tier"])); strings.TrimSpace(value) != "" {
			tier = value
		}
	}

	userCounters, err := r.loadSpotlightUserCounters(ctx, today, []string{trimmedTarget})
	if err != nil {
		return err
	}
	userCounter := userCounters[trimmedTarget]
	if isLike {
		userCounter.LikeCount++
	}
	if isMutualMatch {
		userCounter.MatchCount++
	}
	if _, err := r.db.Upsert(ctx, r.cfg.MatchingSchema, "spotlight_daily_user_counters", []map[string]any{{
		"counter_date":   today,
		"user_id":        trimmedTarget,
		"exposure_count": userCounter.ExposureCount,
		"like_count":     userCounter.LikeCount,
		"match_count":    userCounter.MatchCount,
		"updated_at":     time.Now().UTC().Format(time.RFC3339),
	}}, "counter_date,user_id"); err != nil {
		return err
	}

	tierCounters, err := r.loadSpotlightTierCounters(ctx, today)
	if err != nil {
		return err
	}
	tierCounter := tierCounters[tier]
	if isLike {
		tierCounter.LikeCount++
	}
	if isMutualMatch {
		tierCounter.MatchCount++
	}
	_, err = r.db.Upsert(ctx, r.cfg.MatchingSchema, "spotlight_daily_tier_counters", []map[string]any{{
		"counter_date":   today,
		"tier":           tier,
		"exposure_count": tierCounter.ExposureCount,
		"like_count":     tierCounter.LikeCount,
		"match_count":    tierCounter.MatchCount,
		"updated_at":     time.Now().UTC().Format(time.RFC3339),
	}}, "counter_date,tier")
	return err
}

func (r *spotlightRepository) loadSpotlightSignals(ctx context.Context, userIDs []string) (map[string]spotlightSignalData, error) {
	uniq := uniqueStrings(userIDs)
	out := make(map[string]spotlightSignalData, len(uniq))
	if len(uniq) == 0 {
		return out, nil
	}

	for _, userID := range uniq {
		out[userID] = spotlightSignalData{SubscriptionTier: "bronze", SubscriptionPaid: false}
	}

	params := url.Values{}
	params.Set("id", "in."+buildInList(uniq))
	params.Set("select", "id,profile_completion")
	users, err := r.db.SelectRead(ctx, r.cfg.UserSchema, r.cfg.UsersTable, params)
	if err != nil {
		return nil, err
	}
	for _, row := range users {
		userID := strings.TrimSpace(toString(row["id"]))
		if userID == "" {
			continue
		}
		profileCompletion, _ := toInt(row["profile_completion"])
		s := out[userID]
		s.ProfileCompletion = maxInt(0, minInt(100, profileCompletion))
		out[userID] = s
	}

	badgeParams := url.Values{}
	badgeParams.Set("user_id", "in."+buildInList(uniq))
	badgeParams.Set("status", "eq.active")
	badgeParams.Set("select", "user_id")
	badges, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "user_trust_badges", badgeParams)
	if err != nil {
		return nil, err
	}
	for _, row := range badges {
		userID := strings.TrimSpace(toString(row["user_id"]))
		if userID == "" {
			continue
		}
		s := out[userID]
		s.ActiveBadgeCount++
		out[userID] = s
	}

	answerParams := url.Values{}
	answerParams.Set("user_id", "in."+buildInList(uniq))
	answerParams.Set("select", "user_id")
	answers, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "prompt_answers", answerParams)
	if err != nil {
		return nil, err
	}
	for _, row := range answers {
		userID := strings.TrimSpace(toString(row["user_id"]))
		if userID == "" {
			continue
		}
		s := out[userID]
		s.PromptAnswerCount++
		out[userID] = s
	}

	gestureParams := url.Values{}
	gestureParams.Set("sender_user_id", "in."+buildInList(uniq))
	gestureParams.Set("status", "in.(approved,appreciated)")
	gestureParams.Set("select", "sender_user_id")
	gestures, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "match_gestures", gestureParams)
	if err != nil {
		return nil, err
	}
	for _, row := range gestures {
		userID := strings.TrimSpace(toString(row["sender_user_id"]))
		if userID == "" {
			continue
		}
		s := out[userID]
		s.GestureScoreCount++
		out[userID] = s
	}

	subParams := url.Values{}
	subParams.Set("user_id", "in."+buildInList(uniq))
	subParams.Set("status", "eq.active")
	subParams.Set("order", "updated_at.desc")
	subParams.Set("select", "user_id,plan_code")
	subs, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "billing_subscriptions_runtime", subParams)
	if err != nil {
		return nil, err
	}
	seenSub := make(map[string]struct{}, len(uniq))
	for _, row := range subs {
		userID := strings.TrimSpace(toString(row["user_id"]))
		if userID == "" {
			continue
		}
		if _, ok := seenSub[userID]; ok {
			continue
		}
		seenSub[userID] = struct{}{}
		planCode := strings.ToLower(strings.TrimSpace(toString(row["plan_code"])))
		tier, paid := normalizePlanToSpotlightTier(planCode)
		s := out[userID]
		s.SubscriptionTier = tier
		s.SubscriptionPaid = paid
		out[userID] = s
	}

	return out, nil
}

func (r *spotlightRepository) loadSpotlightUserCounters(
	ctx context.Context,
	counterDate string,
	userIDs []string,
) (map[string]spotlightUserCounter, error) {
	out := make(map[string]spotlightUserCounter, len(userIDs))
	uniq := uniqueStrings(userIDs)
	if len(uniq) == 0 {
		return out, nil
	}
	params := url.Values{}
	params.Set("counter_date", "eq."+counterDate)
	params.Set("user_id", "in."+buildInList(uniq))
	params.Set("select", "user_id,exposure_count,like_count,match_count")
	rows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "spotlight_daily_user_counters", params)
	if err != nil {
		return nil, err
	}
	for _, row := range rows {
		userID := strings.TrimSpace(toString(row["user_id"]))
		if userID == "" {
			continue
		}
		exposureCount, _ := toInt(row["exposure_count"])
		likeCount, _ := toInt(row["like_count"])
		matchCount, _ := toInt(row["match_count"])
		out[userID] = spotlightUserCounter{
			ExposureCount: exposureCount,
			LikeCount:     likeCount,
			MatchCount:    matchCount,
		}
	}
	return out, nil
}

func (r *spotlightRepository) loadSpotlightTierCounters(
	ctx context.Context,
	counterDate string,
) (map[string]spotlightUserCounter, error) {
	out := make(map[string]spotlightUserCounter)
	params := url.Values{}
	params.Set("counter_date", "eq."+counterDate)
	params.Set("select", "tier,exposure_count,like_count,match_count")
	rows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "spotlight_daily_tier_counters", params)
	if err != nil {
		return nil, err
	}
	for _, row := range rows {
		tier := normalizeSpotlightTier(toString(row["tier"]))
		exposureCount, _ := toInt(row["exposure_count"])
		likeCount, _ := toInt(row["like_count"])
		matchCount, _ := toInt(row["match_count"])
		out[tier] = spotlightUserCounter{
			ExposureCount: exposureCount,
			LikeCount:     likeCount,
			MatchCount:    matchCount,
		}
	}
	return out, nil
}

func (r *spotlightRepository) persistExposureCounters(
	ctx context.Context,
	counterDate string,
	existingUsers map[string]spotlightUserCounter,
	incUser map[string]int,
	incTier map[string]int,
) error {
	if len(incUser) > 0 {
		userPayload := make([]map[string]any, 0, len(incUser))
		for userID, inc := range incUser {
			current := existingUsers[userID]
			userPayload = append(userPayload, map[string]any{
				"counter_date":   counterDate,
				"user_id":        userID,
				"exposure_count": current.ExposureCount + inc,
				"like_count":     current.LikeCount,
				"match_count":    current.MatchCount,
				"updated_at":     time.Now().UTC().Format(time.RFC3339),
			})
		}
		if _, err := r.db.Upsert(ctx, r.cfg.MatchingSchema, "spotlight_daily_user_counters", userPayload, "counter_date,user_id"); err != nil {
			return err
		}
	}

	if len(incTier) > 0 {
		existingTier, err := r.loadSpotlightTierCounters(ctx, counterDate)
		if err != nil {
			return err
		}
		tierPayload := make([]map[string]any, 0, len(incTier))
		for tier, inc := range incTier {
			current := existingTier[tier]
			tierPayload = append(tierPayload, map[string]any{
				"counter_date":   counterDate,
				"tier":           tier,
				"exposure_count": current.ExposureCount + inc,
				"like_count":     current.LikeCount,
				"match_count":    current.MatchCount,
				"updated_at":     time.Now().UTC().Format(time.RFC3339),
			})
		}
		if _, err := r.db.Upsert(ctx, r.cfg.MatchingSchema, "spotlight_daily_tier_counters", tierPayload, "counter_date,tier"); err != nil {
			return err
		}
	}

	return nil
}

func buildSpotlightMetaFromSignals(userID string, signal spotlightSignalData) spotlightCandidateMeta {
	baselineTier := normalizeSpotlightTier(signal.SubscriptionTier)
	if baselineTier == "" {
		baselineTier = "bronze"
	}

	activityScore := 0
	activityScore += minInt(35, signal.ProfileCompletion/3)
	activityScore += minInt(25, signal.ActiveBadgeCount*10)
	activityScore += minInt(20, signal.PromptAnswerCount*4)
	activityScore += minInt(20, signal.GestureScoreCount*5)
	activityScore = maxInt(0, minInt(100, activityScore))

	uplift := 0
	if activityScore >= 85 {
		uplift = 2
	} else if activityScore >= 65 {
		uplift = 1
	}
	if signal.SubscriptionPaid && uplift > 1 {
		uplift = 1
	}

	finalRank := tierRank(baselineTier) + uplift
	maxRank := tierRank("diamond")
	if !signal.SubscriptionPaid {
		maxRank = tierRank("emerald")
	}
	if finalRank > maxRank {
		finalRank = maxRank
	}
	if finalRank < 0 {
		finalRank = 0
	}
	finalTier := spotlightTierOrder[finalRank]

	policies := spotlightTierPolicies()
	for finalRank > 0 {
		policy := policies[finalTier]
		if signal.ProfileCompletion >= policy.MinProfileCompletion && signal.ActiveBadgeCount >= policy.MinActiveBadges {
			break
		}
		finalRank--
		finalTier = spotlightTierOrder[finalRank]
	}

	policy := policies[finalTier]
	score := policy.PaidBaselineWeight + minInt(activityScore, policy.ActivityBonusCap)
	score = maxInt(0, minInt(100, score))

	reason := "activity_progression"
	if signal.SubscriptionPaid {
		reason = "paid_plus_activity"
	}
	if uplift == 0 {
		reason = "paid_baseline"
		if !signal.SubscriptionPaid {
			reason = "activity_only"
		}
	}

	return spotlightCandidateMeta{
		UserID: userID,
		Tier:   normalizeSpotlightTier(finalTier),
		Score:  score,
		Reason: reason,
		Paid:   signal.SubscriptionPaid,
	}
}

func extractCandidateUserIDs(rows []any, viewerUserID string) []string {
	out := make([]string, 0, len(rows))
	for _, rowAny := range rows {
		row, ok := rowAny.(map[string]any)
		if !ok {
			continue
		}
		userID := spotlightUserIDFromRow(row)
		if userID == "" || userID == viewerUserID {
			continue
		}
		out = append(out, userID)
	}
	return uniqueStrings(out)
}

func spotlightUserIDFromRow(row map[string]any) string {
	userID := strings.TrimSpace(toString(row["id"]))
	if userID == "" {
		userID = strings.TrimSpace(toString(row["user_id"]))
	}
	if userID == "" {
		userID = strings.TrimSpace(toString(row["userId"]))
	}
	return userID
}

func normalizePlanToSpotlightTier(planCode string) (string, bool) {
	plan := strings.ToLower(strings.TrimSpace(planCode))
	switch plan {
	case "diamond", "vip":
		return "diamond", true
	case "emerald":
		return "emerald", true
	case "gold", "premium":
		return "gold", true
	case "silver":
		return "silver", true
	case "bronze":
		return "bronze", true
	default:
		return "bronze", false
	}
}
