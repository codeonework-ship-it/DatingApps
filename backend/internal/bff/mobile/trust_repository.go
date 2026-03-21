package mobile

import (
	"context"
	"errors"
	"fmt"
	"net/url"
	"sort"
	"strings"
	"time"

	"github.com/verified-dating/backend/internal/platform/config"
	"github.com/verified-dating/backend/internal/platform/supabase"
)

type trustRepository struct {
	cfg config.Config
	db  *supabase.Client
}

type trustSignalBreakdownDurable struct {
	communicationScore    int
	consistencyScore      int
	promptCompletionScore int
	profileDepthScore     int
	activitySignalCount   int
	reportRiskPenalty     int
	unsafeSignalCount     int
	verificationApproved  bool
	promptCompletions     int
	promptTotal           int
}

func newTrustRepository(cfg config.Config) *trustRepository {
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
	return &trustRepository{cfg: cfg, db: client}
}

func isTrustRepoPersistenceUnavailable(err error) bool {
	if err == nil {
		return false
	}
	msg := strings.ToLower(err.Error())
	return strings.Contains(msg, "pgrst106") ||
		strings.Contains(msg, "pgrst205") ||
		strings.Contains(msg, "invalid schema") ||
		strings.Contains(msg, "could not find the table")
}

func (r *trustRepository) getTrustFilterPreference(ctx context.Context, userID string) (trustFilterPreference, error) {
	trimmedUserID := strings.TrimSpace(userID)
	if trimmedUserID == "" {
		return trustFilterPreference{}, errors.New("user_id is required")
	}
	params := url.Values{}
	params.Set("user_id", "eq."+trimmedUserID)
	params.Set("limit", "1")
	params.Set("select", "user_id,trust_only_mode,required_badge_codes,updated_at")
	rows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "user_trust_filter_preferences", params)
	if err != nil {
		return trustFilterPreference{}, err
	}
	if len(rows) == 0 {
		return trustFilterPreference{
			UserID:              trimmedUserID,
			Enabled:             false,
			MinimumActiveBadges: 0,
			RequiredBadgeCodes:  []string{},
			UpdatedAt:           time.Now().UTC().Format(time.RFC3339),
		}, nil
	}
	row := rows[0]
	required := normalizeTrustBadgeCodes(toStringArray(row["required_badge_codes"]))
	return trustFilterPreference{
		UserID:              strings.TrimSpace(toString(row["user_id"])),
		Enabled:             toBoolValue(row["trust_only_mode"]),
		MinimumActiveBadges: len(required),
		RequiredBadgeCodes:  required,
		UpdatedAt:           strings.TrimSpace(toString(row["updated_at"])),
	}, nil
}

func (r *trustRepository) upsertTrustFilterPreference(
	ctx context.Context,
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
	codes := normalizeTrustBadgeCodes(requiredBadgeCodes)
	if err := validateTrustBadgeCodes(codes); err != nil {
		return trustFilterPreference{}, err
	}
	if len(codes) < minimumActiveBadges {
		minimumActiveBadges = len(codes)
	}

	payload := []map[string]any{{
		"user_id":              trimmedUserID,
		"trust_only_mode":      enabled,
		"required_badge_codes": codes,
		"updated_at":           time.Now().UTC().Format(time.RFC3339),
	}}
	if _, err := r.db.Upsert(ctx, r.cfg.MatchingSchema, "user_trust_filter_preferences", payload, "user_id"); err != nil {
		return trustFilterPreference{}, err
	}

	return trustFilterPreference{
		UserID:              trimmedUserID,
		Enabled:             enabled,
		MinimumActiveBadges: minimumActiveBadges,
		RequiredBadgeCodes:  codes,
		UpdatedAt:           time.Now().UTC().Format(time.RFC3339),
	}, nil
}

func (r *trustRepository) listActiveTrustBadgeCodes(ctx context.Context, userID string) ([]string, error) {
	trimmedUserID := strings.TrimSpace(userID)
	if trimmedUserID == "" {
		return nil, errors.New("user_id is required")
	}
	params := url.Values{}
	params.Set("user_id", "eq."+trimmedUserID)
	params.Set("status", "eq.active")
	params.Set("select", "badge_code")
	rows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "user_trust_badges", params)
	if err != nil {
		return nil, err
	}
	active := make([]string, 0, len(rows))
	for _, row := range rows {
		code := strings.ToLower(strings.TrimSpace(toString(row["badge_code"])))
		if code != "" {
			active = append(active, code)
		}
	}
	sort.Strings(active)
	return active, nil
}

func (r *trustRepository) recomputeUserTrustBadges(ctx context.Context, userID string) (trustMilestone, []trustBadge, error) {
	trimmedUserID := strings.TrimSpace(userID)
	if trimmedUserID == "" {
		return trustMilestone{}, nil, errors.New("user_id is required")
	}

	now := time.Now().UTC()
	nowISO := now.Format(time.RFC3339)
	breakdown, err := r.computeTrustSignalBreakdown(ctx, trimmedUserID)
	if err != nil {
		return trustMilestone{}, nil, err
	}

	milestone := trustMilestone{
		UserID:                 trimmedUserID,
		ProfileDepthScore:      breakdown.profileDepthScore,
		CommunicationScore:     breakdown.communicationScore,
		ConsistencyScore:       breakdown.consistencyScore,
		PromptCompletionScore:  breakdown.promptCompletionScore,
		ActivitySignalCount:    breakdown.activitySignalCount,
		UnsafeSignalCount:      breakdown.unsafeSignalCount,
		ReportRiskPenalty:      breakdown.reportRiskPenalty,
		VerificationConsistent: breakdown.verificationApproved,
		LastComputedAt:         nowISO,
	}

	if _, err := r.db.Upsert(ctx, r.cfg.MatchingSchema, "trust_milestones", []map[string]any{{
		"user_id":         trimmedUserID,
		"milestone_code":  "trust_signal",
		"milestone_value": milestone.ConsistencyScore,
		"signal_breakdown": map[string]any{
			"profile_depth_score":       milestone.ProfileDepthScore,
			"communication_score":       milestone.CommunicationScore,
			"consistency_score":         milestone.ConsistencyScore,
			"prompt_completion_score":   milestone.PromptCompletionScore,
			"activity_signal_count":     milestone.ActivitySignalCount,
			"unsafe_signal_count":       milestone.UnsafeSignalCount,
			"report_risk_penalty":       milestone.ReportRiskPenalty,
			"verification_consistent":   milestone.VerificationConsistent,
			"prompt_completion_total":   breakdown.promptTotal,
			"prompt_completion_success": breakdown.promptCompletions,
		},
		"computed_at": nowISO,
	}}, "user_id"); err != nil {
		return trustMilestone{}, nil, err
	}

	rules := evaluateBadgeRulesDurable(breakdown)
	existing, err := r.getExistingBadges(ctx, trimmedUserID)
	if err != nil {
		return trustMilestone{}, nil, err
	}

	upserts := make([]map[string]any, 0, len(trustBadgeCatalog()))
	historyEvents := make([]map[string]any, 0)
	for _, badgeDef := range trustBadgeCatalog() {
		rule := rules[badgeDef.BadgeCode]
		item, ok := existing[badgeDef.BadgeCode]
		if !ok {
			item = trustBadge{BadgeCode: badgeDef.BadgeCode, BadgeLabel: badgeDef.BadgeLabel, Status: "not_earned"}
		}

		if rule.active {
			if item.Status != "active" {
				item.Status = "active"
				item.Reason = rule.reason
				item.AwardedAt = nowISO
				item.RevokedAt = ""
				historyEvents = append(historyEvents, map[string]any{
					"user_id":     trimmedUserID,
					"badge_code":  badgeDef.BadgeCode,
					"action":      "awarded",
					"reason":      rule.reason,
					"happened_at": nowISO,
					"metadata":    map[string]any{},
				})
			}
		} else if item.Status == "active" {
			item.Status = "revoked"
			item.Reason = rule.reason
			item.RevokedAt = nowISO
			historyEvents = append(historyEvents, map[string]any{
				"user_id":     trimmedUserID,
				"badge_code":  badgeDef.BadgeCode,
				"action":      "revoked",
				"reason":      rule.reason,
				"happened_at": nowISO,
				"metadata":    map[string]any{},
			})
		} else if item.Status == "revoked" {
			item.Reason = rule.reason
		}

		score := milestone.ConsistencyScore
		if badgeDef.BadgeCode == trustBadgeRespectfulCommunicator {
			score = milestone.CommunicationScore
		}
		if badgeDef.BadgeCode == trustBadgePromptCompleter {
			score = milestone.PromptCompletionScore
		}
		upserts = append(upserts, map[string]any{
			"user_id":    trimmedUserID,
			"badge_code": badgeDef.BadgeCode,
			"status":     item.Status,
			"score":      score,
			"awarded_at": nullableTimestamp(item.AwardedAt),
			"updated_at": nowISO,
		})
	}

	if len(upserts) > 0 {
		if _, err := r.db.Upsert(ctx, r.cfg.MatchingSchema, "user_trust_badges", upserts, "user_id,badge_code"); err != nil {
			return trustMilestone{}, nil, err
		}
	}
	if len(historyEvents) > 0 {
		if _, err := r.db.Insert(ctx, r.cfg.MatchingSchema, "user_trust_badge_history", historyEvents); err != nil {
			return trustMilestone{}, nil, err
		}
	}

	badges, err := r.listUserTrustBadges(ctx, trimmedUserID)
	if err != nil {
		return trustMilestone{}, nil, err
	}
	return milestone, badges, nil
}

func (r *trustRepository) listUserTrustBadgeHistory(ctx context.Context, userID string, limit int) ([]trustBadgeHistoryEvent, error) {
	trimmedUserID := strings.TrimSpace(userID)
	if trimmedUserID == "" {
		return nil, errors.New("user_id is required")
	}
	if limit <= 0 || limit > 500 {
		limit = 100
	}
	params := url.Values{}
	params.Set("user_id", "eq."+trimmedUserID)
	params.Set("order", "happened_at.desc")
	params.Set("limit", fmt.Sprintf("%d", limit))
	params.Set("select", "id,user_id,badge_code,action,reason,happened_at")
	rows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "user_trust_badge_history", params)
	if err != nil {
		return nil, err
	}
	history := make([]trustBadgeHistoryEvent, 0, len(rows))
	for _, row := range rows {
		history = append(history, trustBadgeHistoryEvent{
			ID:         strings.TrimSpace(toString(row["id"])),
			UserID:     strings.TrimSpace(toString(row["user_id"])),
			BadgeCode:  strings.TrimSpace(toString(row["badge_code"])),
			Action:     strings.TrimSpace(toString(row["action"])),
			Reason:     strings.TrimSpace(toString(row["reason"])),
			OccurredAt: strings.TrimSpace(toString(row["happened_at"])),
		})
	}
	return history, nil
}

func (r *trustRepository) listUserTrustBadges(ctx context.Context, userID string) ([]trustBadge, error) {
	params := url.Values{}
	params.Set("user_id", "eq."+strings.TrimSpace(userID))
	params.Set("select", "user_id,badge_code,status,awarded_at,updated_at")
	rows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "user_trust_badges", params)
	if err != nil {
		return nil, err
	}
	byCode := map[string]trustBadge{}
	for _, row := range rows {
		code := strings.TrimSpace(toString(row["badge_code"]))
		if code == "" {
			continue
		}
		byCode[code] = trustBadge{
			BadgeCode: code,
			Status:    strings.TrimSpace(toString(row["status"])),
			AwardedAt: strings.TrimSpace(toString(row["awarded_at"])),
		}
	}
	catalog := trustBadgeCatalog()
	out := make([]trustBadge, 0, len(catalog))
	for _, def := range catalog {
		if existing, ok := byCode[def.BadgeCode]; ok {
			existing.BadgeLabel = def.BadgeLabel
			if existing.Status == "" {
				existing.Status = "not_earned"
			}
			out = append(out, existing)
			continue
		}
		out = append(out, def)
	}
	sort.SliceStable(out, func(i, j int) bool { return out[i].BadgeCode < out[j].BadgeCode })
	return out, nil
}

func (r *trustRepository) getExistingBadges(ctx context.Context, userID string) (map[string]trustBadge, error) {
	rows, err := r.listUserTrustBadges(ctx, userID)
	if err != nil {
		return nil, err
	}
	out := make(map[string]trustBadge, len(rows))
	for _, item := range rows {
		out[item.BadgeCode] = item
	}
	return out, nil
}

func (r *trustRepository) computeTrustSignalBreakdown(ctx context.Context, userID string) (trustSignalBreakdownDurable, error) {
	breakdown := trustSignalBreakdownDurable{}

	userParams := url.Values{}
	userParams.Set("id", "eq."+userID)
	userParams.Set("limit", "1")
	userParams.Set("select", "profile_completion,is_verified")
	users, err := r.db.SelectRead(ctx, r.cfg.UserSchema, r.cfg.UsersTable, userParams)
	if err != nil {
		return breakdown, err
	}
	if len(users) > 0 {
		profileCompletion, _ := toInt(users[0]["profile_completion"])
		breakdown.profileDepthScore = clampInt(profileCompletion, 0, 100)
	}

	verificationParams := url.Values{}
	verificationParams.Set("user_id", "eq."+userID)
	verificationParams.Set("status", "eq.verified")
	verificationParams.Set("limit", "1")
	verificationParams.Set("select", "user_id")
	verifications, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "verification_states", verificationParams)
	if err != nil {
		return breakdown, err
	}
	breakdown.verificationApproved = len(verifications) > 0

	gestureParams := url.Values{}
	gestureParams.Set("sender_user_id", "eq."+userID)
	gestureParams.Set("select", "status")
	gestures, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "match_gestures", gestureParams)
	if err != nil {
		return breakdown, err
	}
	totalGestures := 0
	appreciated := 0
	for _, row := range gestures {
		totalGestures++
		status := strings.ToLower(strings.TrimSpace(toString(row["status"])))
		if status == "approved" || status == "appreciated" {
			appreciated++
		}
	}
	if totalGestures == 0 {
		breakdown.communicationScore = 50
	} else {
		breakdown.communicationScore = clampInt(50+int((float64(appreciated)/float64(totalGestures))*40), 0, 100)
	}

	workflowParams := url.Values{}
	workflowParams.Set("submitter_user_id", "eq."+userID)
	workflowParams.Set("select", "status")
	workflows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "match_quest_workflows", workflowParams)
	if err != nil {
		return breakdown, err
	}
	for _, row := range workflows {
		breakdown.promptTotal++
		if strings.EqualFold(strings.TrimSpace(toString(row["status"])), questWorkflowStatusApproved) {
			breakdown.promptCompletions++
		}
	}

	activityParams := url.Values{}
	activityParams.Set("participant_user_ids", "cs.{"+userID+"}")
	activityParams.Set("select", "id")
	sessions, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "activity_sessions", activityParams)
	if err != nil {
		return breakdown, err
	}
	for _, row := range sessions {
		sessionID := strings.TrimSpace(toString(row["id"]))
		if sessionID == "" {
			continue
		}
		breakdown.promptTotal++
		responseParams := url.Values{}
		responseParams.Set("session_id", "eq."+sessionID)
		responseParams.Set("user_id", "eq."+userID)
		responseParams.Set("limit", "1")
		responseParams.Set("select", "id")
		responses, responseErr := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "activity_session_responses", responseParams)
		if responseErr != nil {
			return breakdown, responseErr
		}
		if len(responses) > 0 {
			breakdown.promptCompletions++
		}
	}

	if breakdown.promptTotal > 0 {
		breakdown.promptCompletionScore = clampInt((breakdown.promptCompletions*100)/breakdown.promptTotal, 0, 100)
	}

	activityEventsParams := url.Values{}
	activityEventsParams.Set("user_id", "eq."+userID)
	activityEventsParams.Set("select", "event_name")
	activityEvents, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "activity_events", activityEventsParams)
	if err == nil {
		for _, row := range activityEvents {
			eventName := strings.ToLower(strings.TrimSpace(toString(row["event_name"])))
			if strings.Contains(eventName, "gesture") ||
				strings.Contains(eventName, "quest") ||
				strings.Contains(eventName, "activity") ||
				strings.Contains(eventName, "chat") {
				breakdown.activitySignalCount++
			}
		}
	}

	reportParams := url.Values{}
	reportParams.Set("reported_user_id", "eq."+userID)
	reportParams.Set("select", "status,action")
	reports, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "moderation_reports", reportParams)
	if err != nil {
		return breakdown, err
	}
	reportsAgainst := 0
	pendingOrReview := 0
	severeActions := 0
	for _, row := range reports {
		reportsAgainst++
		status := strings.ToLower(strings.TrimSpace(toString(row["status"])))
		action := strings.ToLower(strings.TrimSpace(toString(row["action"])))
		if status == "pending" || status == "reviewed" {
			pendingOrReview++
		}
		if status == "actioned" &&
			(strings.Contains(action, "ban") ||
				strings.Contains(action, "suspend") ||
				strings.Contains(action, "unsafe") ||
				strings.Contains(action, "abuse") ||
				strings.Contains(action, "harass")) {
			severeActions++
		}
	}
	breakdown.unsafeSignalCount = severeActions
	if pendingOrReview >= 2 {
		breakdown.unsafeSignalCount += pendingOrReview
	}
	breakdown.reportRiskPenalty = clampInt(reportsAgainst*10+pendingOrReview*8+severeActions*20, 0, 100)

	breakdown.consistencyScore = breakdown.profileDepthScore
	if breakdown.verificationApproved {
		breakdown.consistencyScore = clampInt(breakdown.consistencyScore+10, 0, 100)
	}

	return breakdown, nil
}

func evaluateBadgeRulesDurable(b trustSignalBreakdownDurable) map[string]trustBadgeRuleDecision {
	unsafeDetected := b.unsafeSignalCount > 0 || b.reportRiskPenalty >= 40
	unsafeReason := "unsafe behavior detected"

	rules := map[string]trustBadgeRuleDecision{
		trustBadgePromptCompleter: {
			active: b.promptCompletionScore >= 70 && b.promptCompletions >= 2,
			reason: fmt.Sprintf(
				"prompt completion reliability %d%% (%d/%d)",
				b.promptCompletionScore,
				b.promptCompletions,
				maxInt(1, b.promptTotal),
			),
		},
		trustBadgeRespectfulCommunicator: {
			active: b.communicationScore >= 75,
			reason: fmt.Sprintf("communication score %d", b.communicationScore),
		},
		trustBadgeConsistentProfile: {
			active: b.profileDepthScore >= 90 && b.consistencyScore >= 90,
			reason: fmt.Sprintf("profile consistency score %d", b.consistencyScore),
		},
		trustBadgeVerifiedActive: {
			active: b.verificationApproved && b.activitySignalCount >= 3,
			reason: fmt.Sprintf("verified with %d activity signals", b.activitySignalCount),
		},
	}

	if !unsafeDetected {
		return rules
	}
	for code, decision := range rules {
		decision.active = false
		decision.reason = unsafeReason
		rules[code] = decision
	}
	return rules
}
