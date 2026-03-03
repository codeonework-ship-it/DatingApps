package mobile

import (
	"errors"
	"fmt"
	"sort"
	"strings"
	"time"
)

const (
	trustBadgePromptCompleter        = "prompt_completer"
	trustBadgeRespectfulCommunicator = "respectful_communicator"
	trustBadgeConsistentProfile      = "consistent_profile"
	trustBadgeVerifiedActive         = "verified_active"
)

type trustMilestone struct {
	UserID                 string `json:"user_id"`
	ProfileDepthScore      int    `json:"profile_depth_score"`
	CommunicationScore     int    `json:"communication_score"`
	ConsistencyScore       int    `json:"consistency_score"`
	PromptCompletionScore  int    `json:"prompt_completion_score"`
	ActivitySignalCount    int    `json:"activity_signal_count"`
	UnsafeSignalCount      int    `json:"unsafe_signal_count"`
	ReportRiskPenalty      int    `json:"report_risk_penalty"`
	VerificationConsistent bool   `json:"verification_consistent"`
	LastComputedAt         string `json:"last_computed_at"`
}

type trustBadge struct {
	BadgeCode  string `json:"badge_code"`
	BadgeLabel string `json:"badge_label"`
	Status     string `json:"status"`
	AwardedAt  string `json:"awarded_at,omitempty"`
	RevokedAt  string `json:"revoked_at,omitempty"`
	Reason     string `json:"reason,omitempty"`
}

type trustBadgeHistoryEvent struct {
	ID         string `json:"id"`
	UserID     string `json:"user_id"`
	BadgeCode  string `json:"badge_code"`
	Action     string `json:"action"`
	Reason     string `json:"reason"`
	OccurredAt string `json:"occurred_at"`
}

type trustBadgeRuleDecision struct {
	active bool
	reason string
}

type trustSignalBreakdown struct {
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

func trustBadgeCatalog() []trustBadge {
	return []trustBadge{
		{BadgeCode: trustBadgePromptCompleter, BadgeLabel: "Prompt Completer", Status: "not_earned"},
		{BadgeCode: trustBadgeRespectfulCommunicator, BadgeLabel: "Respectful Communicator", Status: "not_earned"},
		{BadgeCode: trustBadgeConsistentProfile, BadgeLabel: "Consistent Profile", Status: "not_earned"},
		{BadgeCode: trustBadgeVerifiedActive, BadgeLabel: "Verified & Active", Status: "not_earned"},
	}
}

func (m *memoryStore) recomputeUserTrustBadges(userID string) (trustMilestone, []trustBadge, error) {
	trimmedUserID := strings.TrimSpace(userID)
	if trimmedUserID == "" {
		return trustMilestone{}, nil, errors.New("user_id is required")
	}

	m.mu.Lock()
	defer m.mu.Unlock()

	now := time.Now().UTC()
	nowISO := now.Format(time.RFC3339)
	breakdown := m.computeTrustSignalBreakdownLocked(trimmedUserID)

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
	m.trustMilestones[trimmedUserID] = milestone

	rules := m.evaluateBadgeRulesLocked(breakdown)
	if _, ok := m.userBadges[trimmedUserID]; !ok {
		m.userBadges[trimmedUserID] = make(map[string]trustBadge)
	}

	current := m.userBadges[trimmedUserID]
	for _, badgeDef := range trustBadgeCatalog() {
		rule := rules[badgeDef.BadgeCode]
		item, exists := current[badgeDef.BadgeCode]
		if !exists {
			item = trustBadge{
				BadgeCode:  badgeDef.BadgeCode,
				BadgeLabel: badgeDef.BadgeLabel,
				Status:     "not_earned",
			}
		}

		if rule.active {
			if item.Status != "active" {
				item.Status = "active"
				item.Reason = rule.reason
				item.AwardedAt = nowISO
				item.RevokedAt = ""
				m.appendBadgeHistoryLocked(trimmedUserID, badgeDef.BadgeCode, "awarded", rule.reason, nowISO)
			}
			current[badgeDef.BadgeCode] = item
			continue
		}

		if item.Status == "active" {
			item.Status = "revoked"
			item.Reason = rule.reason
			item.RevokedAt = nowISO
			m.appendBadgeHistoryLocked(trimmedUserID, badgeDef.BadgeCode, "revoked", rule.reason, nowISO)
			current[badgeDef.BadgeCode] = item
			continue
		}

		if item.Status == "revoked" {
			item.Reason = rule.reason
			current[badgeDef.BadgeCode] = item
		}
	}

	badges := m.snapshotBadgesLocked(trimmedUserID)
	return milestone, badges, nil
}

func (m *memoryStore) listUserTrustBadgeHistory(userID string, limit int) ([]trustBadgeHistoryEvent, error) {
	trimmedUserID := strings.TrimSpace(userID)
	if trimmedUserID == "" {
		return nil, errors.New("user_id is required")
	}
	if limit <= 0 || limit > 500 {
		limit = 100
	}

	m.mu.RLock()
	defer m.mu.RUnlock()

	history := m.badgeHistory[trimmedUserID]
	if len(history) == 0 {
		return []trustBadgeHistoryEvent{}, nil
	}
	out := make([]trustBadgeHistoryEvent, 0, minInt(limit, len(history)))
	for i := len(history) - 1; i >= 0 && len(out) < limit; i-- {
		out = append(out, history[i])
	}
	return out, nil
}

func (m *memoryStore) computeTrustSignalBreakdownLocked(userID string) trustSignalBreakdown {
	profileDepthScore := 0
	if draft, ok := m.profiles[userID]; ok {
		profileDepthScore = clampInt(draft.ProfileCompletion, 0, 100)
	}

	verificationApproved := false
	if verification, ok := m.verification[userID]; ok {
		verificationApproved = strings.EqualFold(strings.TrimSpace(verification.Status), "approved")
	}

	activitySignalCount := 0
	for _, item := range m.activities {
		if strings.TrimSpace(item.Actor) != userID {
			continue
		}
		if strings.Contains(item.Action, "gesture.") ||
			strings.Contains(item.Action, "quest.") ||
			strings.Contains(item.Action, "activity.session.") ||
			strings.Contains(item.Resource, "/chat/") {
			activitySignalCount++
		}
	}

	communicationScore, flaggedGestures := m.computeCommunicationScoreLocked(userID)
	promptCompletionScore, promptCompletions, promptTotal := m.computePromptCompletionScoreLocked(userID)
	reportRiskPenalty, unsafeReports := m.computeReportRiskPenaltyLocked(userID)

	unsafeSignalCount := flaggedGestures + unsafeReports
	consistencyScore := profileDepthScore
	if verificationApproved {
		consistencyScore = clampInt(consistencyScore+10, 0, 100)
	}

	return trustSignalBreakdown{
		communicationScore:    communicationScore,
		consistencyScore:      consistencyScore,
		promptCompletionScore: promptCompletionScore,
		profileDepthScore:     profileDepthScore,
		activitySignalCount:   activitySignalCount,
		reportRiskPenalty:     reportRiskPenalty,
		unsafeSignalCount:     unsafeSignalCount,
		verificationApproved:  verificationApproved,
		promptCompletions:     promptCompletions,
		promptTotal:           promptTotal,
	}
}

func (m *memoryStore) evaluateBadgeRulesLocked(b trustSignalBreakdown) map[string]trustBadgeRuleDecision {
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

func (m *memoryStore) computeCommunicationScoreLocked(userID string) (score int, flaggedCount int) {
	total := 0
	appreciated := 0
	for _, gestures := range m.matchGestures {
		for _, gesture := range gestures {
			if strings.TrimSpace(gesture.SenderUserID) != userID {
				continue
			}
			total++
			if strings.EqualFold(strings.TrimSpace(gesture.Status), "appreciated") {
				appreciated++
			}
			if gesture.SafetyFlagged || gesture.ProfanityFlagged {
				flaggedCount++
			}
		}
	}

	if total == 0 {
		return 50, flaggedCount
	}

	score = 50 + int((float64(appreciated)/float64(total))*40)
	score -= flaggedCount * 25
	return clampInt(score, 0, 100), flaggedCount
}

func (m *memoryStore) computePromptCompletionScoreLocked(userID string) (score int, completions int, total int) {
	for _, workflow := range m.questWorkflows {
		if strings.TrimSpace(workflow.SubmitterUserID) != userID {
			continue
		}
		total++
		if strings.EqualFold(strings.TrimSpace(workflow.Status), questWorkflowStatusApproved) {
			completions++
		}
	}

	for _, session := range m.activitySessions {
		if !containsString(session.ParticipantIDs, userID) {
			continue
		}
		total++
		if len(session.ResponsesByUser[userID]) > 0 {
			completions++
		}
	}

	if total == 0 {
		return 0, 0, 0
	}
	return clampInt((completions*100)/total, 0, 100), completions, total
}

func (m *memoryStore) computeReportRiskPenaltyLocked(userID string) (penalty int, unsafeReports int) {
	reportsAgainst := 0
	pendingOrReview := 0
	severeActions := 0

	for _, report := range m.reports {
		if strings.TrimSpace(report.ReportedUserID) != userID {
			continue
		}
		reportsAgainst++
		status := strings.ToLower(strings.TrimSpace(report.Status))
		action := strings.ToLower(strings.TrimSpace(report.Action))

		if status == "pending" || status == "under_review" {
			pendingOrReview++
		}
		if status == "resolved" &&
			(strings.Contains(action, "ban") ||
				strings.Contains(action, "suspend") ||
				strings.Contains(action, "unsafe") ||
				strings.Contains(action, "abuse") ||
				strings.Contains(action, "harass")) {
			severeActions++
		}
	}

	unsafeReports = severeActions
	if pendingOrReview >= 2 {
		unsafeReports += pendingOrReview
	}

	penalty = reportsAgainst*10 + pendingOrReview*8 + severeActions*20
	return clampInt(penalty, 0, 100), unsafeReports
}

func (m *memoryStore) appendBadgeHistoryLocked(userID, badgeCode, action, reason, occurredAt string) {
	m.activitySeq++
	event := trustBadgeHistoryEvent{
		ID:         fmt.Sprintf("badge-hist-%d", m.activitySeq),
		UserID:     userID,
		BadgeCode:  badgeCode,
		Action:     action,
		Reason:     reason,
		OccurredAt: occurredAt,
	}
	m.badgeHistory[userID] = append(m.badgeHistory[userID], event)
}

func (m *memoryStore) snapshotBadgesLocked(userID string) []trustBadge {
	items := m.userBadges[userID]
	catalog := trustBadgeCatalog()
	out := make([]trustBadge, 0, len(catalog))
	for _, badgeDef := range catalog {
		if current, ok := items[badgeDef.BadgeCode]; ok {
			out = append(out, current)
			continue
		}
		out = append(out, badgeDef)
	}

	sort.SliceStable(out, func(i, j int) bool {
		return out[i].BadgeCode < out[j].BadgeCode
	})
	return out
}

func clampInt(value, minValue, maxValue int) int {
	if value < minValue {
		return minValue
	}
	if value > maxValue {
		return maxValue
	}
	return value
}

func minInt(a, b int) int {
	if a < b {
		return a
	}
	return b
}

func maxInt(a, b int) int {
	if a > b {
		return a
	}
	return b
}
