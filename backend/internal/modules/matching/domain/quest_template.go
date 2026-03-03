package domain

import (
	"fmt"
	"strings"
	"time"
)

const (
	MinQuestPromptLength = 20
	MaxQuestPromptLength = 300
)

var blockedPromptPatterns = []string{
	"<script",
	"</script>",
	"javascript:",
	"drop table",
	"--",
	"/*",
	"*/",
}

type QuestTemplate struct {
	ID        string
	CreatorID string
	Prompt    string
	MinChars  int
	MaxChars  int
	UpdatedAt time.Time
}

func NewQuestTemplate(
	templateID string,
	creatorID string,
	prompt string,
	minChars int,
	maxChars int,
	now time.Time,
) (QuestTemplate, error) {
	normalizedPrompt, err := ValidateQuestPromptTemplate(prompt)
	if err != nil {
		return QuestTemplate{}, err
	}
	if strings.TrimSpace(templateID) == "" {
		return QuestTemplate{}, fmt.Errorf("template id is required")
	}
	if strings.TrimSpace(creatorID) == "" {
		return QuestTemplate{}, fmt.Errorf("creator id is required")
	}
	if minChars < 0 {
		return QuestTemplate{}, fmt.Errorf("min chars cannot be negative")
	}
	if maxChars <= 0 {
		return QuestTemplate{}, fmt.Errorf("max chars must be positive")
	}
	if minChars > maxChars {
		return QuestTemplate{}, fmt.Errorf("min chars cannot exceed max chars")
	}

	return QuestTemplate{
		ID:        strings.TrimSpace(templateID),
		CreatorID: strings.TrimSpace(creatorID),
		Prompt:    normalizedPrompt,
		MinChars:  minChars,
		MaxChars:  maxChars,
		UpdatedAt: now.UTC(),
	}, nil
}

func ValidateQuestPromptTemplate(prompt string) (string, error) {
	normalized := strings.TrimSpace(prompt)
	if normalized == "" {
		return "", fmt.Errorf("prompt template is required")
	}
	if len(normalized) < MinQuestPromptLength {
		return "", fmt.Errorf("prompt template must be at least %d characters", MinQuestPromptLength)
	}
	if len(normalized) > MaxQuestPromptLength {
		return "", fmt.Errorf("prompt template must be at most %d characters", MaxQuestPromptLength)
	}

	lower := strings.ToLower(normalized)
	for _, blocked := range blockedPromptPatterns {
		if strings.Contains(lower, blocked) {
			return "", fmt.Errorf("prompt template contains unsafe content")
		}
	}

	return normalized, nil
}
