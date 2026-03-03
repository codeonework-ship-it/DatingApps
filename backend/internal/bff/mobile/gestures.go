package mobile

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/verified-dating/backend/internal/platform/config"
)

type matchGesture struct {
	ID                 string `json:"id"`
	MatchID            string `json:"match_id"`
	SenderUserID       string `json:"sender_user_id"`
	ReceiverUserID     string `json:"receiver_user_id"`
	GestureType        string `json:"gesture_type"`
	ContentText        string `json:"content_text"`
	Tone               string `json:"tone"`
	Status             string `json:"status"`
	EffortScore        int    `json:"effort_score"`
	MinimumQualityPass bool   `json:"minimum_quality_pass"`
	OriginalityPass    bool   `json:"originality_pass"`
	ProfanityFlagged   bool   `json:"profanity_flagged"`
	SafetyFlagged      bool   `json:"safety_flagged"`
	DecisionByUserID   string `json:"decision_by_user_id,omitempty"`
	DecisionReason     string `json:"decision_reason,omitempty"`
	DecisionAt         string `json:"decision_at,omitempty"`
	CreatedAt          string `json:"created_at"`
	UpdatedAt          string `json:"updated_at"`
}

type gestureEffortScore struct {
	GestureID          string `json:"gesture_id"`
	MatchID            string `json:"match_id"`
	EffortScore        int    `json:"effort_score"`
	MinimumQualityPass bool   `json:"minimum_quality_pass"`
	OriginalityPass    bool   `json:"originality_pass"`
	ProfanityFlagged   bool   `json:"profanity_flagged"`
	SafetyFlagged      bool   `json:"safety_flagged"`
	Status             string `json:"status"`
}

func (m *memoryStore) listMatchGestures(matchID string) []matchGesture {
	trimmedMatchID := strings.TrimSpace(matchID)
	if trimmedMatchID == "" {
		return []matchGesture{}
	}

	if m.questRepo != nil {
		items, err := m.questRepo.listMatchGestures(context.Background(), trimmedMatchID)
		if err == nil {
			m.mu.Lock()
			m.matchGestures[trimmedMatchID] = copyGestures(items)
			m.mu.Unlock()
			return copyGestures(items)
		}
		if m.durableEngagementRequired() {
			return []matchGesture{}
		}
	}

	if m.durableEngagementRequired() {
		return []matchGesture{}
	}

	m.mu.RLock()
	defer m.mu.RUnlock()
	return copyGestures(m.matchGestures[trimmedMatchID])
}

func (m *memoryStore) createMatchGesture(
	matchID,
	senderUserID,
	receiverUserID,
	gestureType,
	contentText,
	tone string,
) (matchGesture, error) {
	trimmedMatchID := strings.TrimSpace(matchID)
	trimmedSender := strings.TrimSpace(senderUserID)
	trimmedReceiver := strings.TrimSpace(receiverUserID)
	trimmedType := strings.ToLower(strings.TrimSpace(gestureType))
	trimmedContent := strings.TrimSpace(contentText)
	trimmedTone := strings.TrimSpace(tone)

	if trimmedMatchID == "" || trimmedSender == "" || trimmedReceiver == "" {
		return matchGesture{}, errors.New("match id, sender user id, and receiver user id are required")
	}
	if trimmedSender == trimmedReceiver {
		return matchGesture{}, errors.New("sender and receiver must be different users")
	}
	if trimmedType != "thoughtful_opener" && trimmedType != "micro_card" && trimmedType != "challenge_token" {
		return matchGesture{}, errors.New("unsupported gesture type")
	}
	if trimmedContent == "" {
		return matchGesture{}, errors.New("gesture content is required")
	}
	if trimmedTone == "" {
		trimmedTone = "neutral"
	}

	score := evaluateGestureEffort(trimmedContent, m.cfg)
	now := time.Now().UTC().Format(time.RFC3339)
	gesture := matchGesture{
		ID:                 fmt.Sprintf("gesture-%d", time.Now().UnixNano()),
		MatchID:            trimmedMatchID,
		SenderUserID:       trimmedSender,
		ReceiverUserID:     trimmedReceiver,
		GestureType:        trimmedType,
		ContentText:        trimmedContent,
		Tone:               trimmedTone,
		Status:             "sent",
		EffortScore:        score.score,
		MinimumQualityPass: score.minimumQualityPass,
		OriginalityPass:    score.originalityPass,
		ProfanityFlagged:   score.profanityFlagged,
		SafetyFlagged:      score.safetyFlagged,
		CreatedAt:          now,
		UpdatedAt:          now,
	}

	if m.questRepo != nil {
		stored, err := m.questRepo.createMatchGesture(context.Background(), gesture)
		if err != nil {
			if m.durableEngagementRequired() || !isQuestRepoPersistenceUnavailable(err) {
				return matchGesture{}, err
			}
		}
		if err == nil {
			m.mu.Lock()
			m.matchGestures[trimmedMatchID] = append(m.matchGestures[trimmedMatchID], stored)
			m.mu.Unlock()
			return stored, nil
		}
	}

	if m.durableEngagementRequired() {
		return matchGesture{}, errors.New("durable gesture persistence unavailable")
	}

	m.mu.Lock()
	m.matchGestures[trimmedMatchID] = append(m.matchGestures[trimmedMatchID], gesture)
	m.mu.Unlock()
	return gesture, nil
}

func (m *memoryStore) decideMatchGesture(
	matchID,
	gestureID,
	reviewerUserID,
	decision,
	reason string,
) (matchGesture, error) {
	trimmedMatchID := strings.TrimSpace(matchID)
	trimmedGestureID := strings.TrimSpace(gestureID)
	trimmedReviewer := strings.TrimSpace(reviewerUserID)
	trimmedDecision := strings.ToLower(strings.TrimSpace(decision))
	trimmedReason := strings.TrimSpace(reason)

	if trimmedMatchID == "" || trimmedGestureID == "" || trimmedReviewer == "" {
		return matchGesture{}, errors.New("match id, gesture id, and reviewer user id are required")
	}
	if trimmedDecision != "appreciate" && trimmedDecision != "decline" && trimmedDecision != "request_better" {
		return matchGesture{}, errors.New("invalid gesture decision")
	}

	if m.questRepo != nil {
		stored, err := m.questRepo.decideMatchGesture(
			context.Background(),
			trimmedMatchID,
			trimmedGestureID,
			trimmedReviewer,
			trimmedDecision,
			trimmedReason,
		)
		if err != nil {
			if m.durableEngagementRequired() || !isQuestRepoPersistenceUnavailable(err) {
				return matchGesture{}, err
			}
		}
		if err == nil {
			m.mu.Lock()
			items := m.matchGestures[trimmedMatchID]
			for i := range items {
				if items[i].ID == trimmedGestureID {
					items[i] = stored
					m.matchGestures[trimmedMatchID] = items
					m.mu.Unlock()
					return stored, nil
				}
			}
			m.matchGestures[trimmedMatchID] = append(items, stored)
			m.mu.Unlock()
			return stored, nil
		}
	}

	if m.durableEngagementRequired() {
		return matchGesture{}, errors.New("durable gesture persistence unavailable")
	}

	m.mu.Lock()
	defer m.mu.Unlock()

	items := m.matchGestures[trimmedMatchID]
	for i := range items {
		if items[i].ID != trimmedGestureID {
			continue
		}
		if items[i].ReceiverUserID != trimmedReviewer {
			return matchGesture{}, errors.New("only receiver can decide gesture")
		}
		items[i].Status = decisionToStatus(trimmedDecision)
		items[i].DecisionByUserID = trimmedReviewer
		items[i].DecisionReason = trimmedReason
		items[i].DecisionAt = time.Now().UTC().Format(time.RFC3339)
		items[i].UpdatedAt = items[i].DecisionAt
		m.matchGestures[trimmedMatchID] = items
		return items[i], nil
	}

	return matchGesture{}, errors.New("gesture not found")
}

func (m *memoryStore) getGestureScore(matchID, gestureID string) (gestureEffortScore, error) {
	trimmedMatchID := strings.TrimSpace(matchID)
	trimmedGestureID := strings.TrimSpace(gestureID)
	if trimmedMatchID == "" || trimmedGestureID == "" {
		return gestureEffortScore{}, errors.New("match id and gesture id are required")
	}

	if m.questRepo != nil {
		gesture, err := m.questRepo.getMatchGesture(context.Background(), trimmedMatchID, trimmedGestureID)
		if err == nil {
			return gestureEffortScore{
				GestureID:          gesture.ID,
				MatchID:            gesture.MatchID,
				EffortScore:        gesture.EffortScore,
				MinimumQualityPass: gesture.MinimumQualityPass,
				OriginalityPass:    gesture.OriginalityPass,
				ProfanityFlagged:   gesture.ProfanityFlagged,
				SafetyFlagged:      gesture.SafetyFlagged,
				Status:             gesture.Status,
			}, nil
		}
		if m.durableEngagementRequired() {
			return gestureEffortScore{}, err
		}
	}

	if m.durableEngagementRequired() {
		return gestureEffortScore{}, errors.New("durable gesture persistence unavailable")
	}

	m.mu.RLock()
	defer m.mu.RUnlock()
	items := m.matchGestures[trimmedMatchID]
	for _, gesture := range items {
		if gesture.ID != trimmedGestureID {
			continue
		}
		return gestureEffortScore{
			GestureID:          gesture.ID,
			MatchID:            gesture.MatchID,
			EffortScore:        gesture.EffortScore,
			MinimumQualityPass: gesture.MinimumQualityPass,
			OriginalityPass:    gesture.OriginalityPass,
			ProfanityFlagged:   gesture.ProfanityFlagged,
			SafetyFlagged:      gesture.SafetyFlagged,
			Status:             gesture.Status,
		}, nil
	}
	return gestureEffortScore{}, errors.New("gesture not found")
}

type gestureScoreBreakdown struct {
	score              int
	minimumQualityPass bool
	originalityPass    bool
	profanityFlagged   bool
	safetyFlagged      bool
}

func evaluateGestureEffort(content string, cfg config.Config) gestureScoreBreakdown {
	policy := resolveGesturePolicy(cfg)
	trimmed := strings.TrimSpace(content)
	words := strings.Fields(strings.ToLower(trimmed))
	minQualityPass := len(trimmed) >= policy.minContentChars && len(words) >= policy.minWordCount

	uniqWords := map[string]struct{}{}
	for _, word := range words {
		normalized := strings.Trim(word, " .,!?:;\"'()[]{}")
		if normalized == "" {
			continue
		}
		uniqWords[normalized] = struct{}{}
	}
	originalityPass := false
	if len(words) > 0 {
		uniqueRatio := float64(len(uniqWords)) / float64(len(words))
		originalityPass = uniqueRatio >= policy.originalityThreshold
	}

	profanityFlagged := containsProfanity(trimmed, policy.profanityTokens)
	safetyFlagged := profanityFlagged

	score := 0
	if minQualityPass {
		score += 40
	}
	if originalityPass {
		score += 35
	}
	if !profanityFlagged {
		score += 25
	}

	return gestureScoreBreakdown{
		score:              score,
		minimumQualityPass: minQualityPass,
		originalityPass:    originalityPass,
		profanityFlagged:   profanityFlagged,
		safetyFlagged:      safetyFlagged,
	}
}

func containsProfanity(content string, tokens []string) bool {
	lower := strings.ToLower(content)
	for _, token := range tokens {
		if strings.Contains(lower, token) {
			return true
		}
	}
	return false
}

func decisionToStatus(decision string) string {
	switch decision {
	case "appreciate":
		return "appreciated"
	case "decline":
		return "declined"
	case "request_better":
		return "improve_requested"
	default:
		return "sent"
	}
}

func copyGestures(in []matchGesture) []matchGesture {
	out := make([]matchGesture, len(in))
	copy(out, in)
	return out
}

type gestureScoringPolicy struct {
	minContentChars      int
	minWordCount         int
	originalityThreshold float64
	profanityTokens      []string
}

func resolveGesturePolicy(cfg config.Config) gestureScoringPolicy {
	minContentChars := cfg.GestureMinContentChars
	if minContentChars <= 0 {
		minContentChars = 40
	}
	minWordCount := cfg.GestureMinWordCount
	if minWordCount <= 0 {
		minWordCount = 8
	}
	originalityPercent := cfg.GestureOriginalityPercent
	if originalityPercent <= 0 || originalityPercent > 100 {
		originalityPercent = 65
	}
	tokens := cfg.GestureProfanityTokens
	if len(tokens) == 0 {
		tokens = []string{"fuck", "shit", "bitch", "asshole", "bastard", "slut"}
	}
	copyTokens := make([]string, len(tokens))
	copy(copyTokens, tokens)

	return gestureScoringPolicy{
		minContentChars:      minContentChars,
		minWordCount:         minWordCount,
		originalityThreshold: float64(originalityPercent) / 100.0,
		profanityTokens:      copyTokens,
	}
}
