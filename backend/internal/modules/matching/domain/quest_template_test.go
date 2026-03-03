package domain

import (
	"strings"
	"testing"
	"time"
)

func TestValidateQuestPromptTemplate_Success(t *testing.T) {
	prompt := "Share one value you care about and one action you took this week to live it."

	normalized, err := ValidateQuestPromptTemplate(prompt)
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}
	if normalized != prompt {
		t.Fatalf("expected prompt unchanged, got %q", normalized)
	}
}

func TestValidateQuestPromptTemplate_RejectsUnsafePatterns(t *testing.T) {
	_, err := ValidateQuestPromptTemplate("Tell me why this matters <script>alert('x')</script>")
	if err == nil {
		t.Fatalf("expected unsafe pattern error")
	}
}

func TestValidateQuestPromptTemplate_RejectsShortAndLong(t *testing.T) {
	_, shortErr := ValidateQuestPromptTemplate("too short")
	if shortErr == nil {
		t.Fatalf("expected short prompt error")
	}

	longPrompt := strings.Repeat("a", MaxQuestPromptLength+1)
	_, longErr := ValidateQuestPromptTemplate(longPrompt)
	if longErr == nil {
		t.Fatalf("expected long prompt error")
	}
}

func TestNewQuestTemplate_ValidatesBoundaries(t *testing.T) {
	now := time.Now()
	_, err := NewQuestTemplate(
		"tpl-1",
		"user-1",
		"Describe a meaningful local place and explain why it matters to you.",
		120,
		80,
		now,
	)
	if err == nil {
		t.Fatalf("expected min/max validation error")
	}
}

func TestNewQuestTemplate_Success(t *testing.T) {
	now := time.Now()
	template, err := NewQuestTemplate(
		"tpl-1",
		"user-1",
		"Share a real story where you handled conflict respectfully.",
		60,
		280,
		now,
	)
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}
	if template.ID != "tpl-1" {
		t.Fatalf("unexpected template id: %q", template.ID)
	}
	if template.CreatorID != "user-1" {
		t.Fatalf("unexpected creator id: %q", template.CreatorID)
	}
	if template.UpdatedAt.IsZero() {
		t.Fatalf("expected non-zero updated at")
	}
}
