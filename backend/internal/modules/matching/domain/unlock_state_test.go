package domain

import "testing"

func TestNextUnlockStateHappyPath(t *testing.T) {
	state, err := NextUnlockState(UnlockStateMatched, ActionAssignQuest)
	if err != nil {
		t.Fatalf("assign quest transition failed: %v", err)
	}
	if state != UnlockStateQuestPending {
		t.Fatalf("expected quest_pending, got %s", state)
	}

	state, err = NextUnlockState(state, ActionSubmitQuest)
	if err != nil {
		t.Fatalf("submit quest transition failed: %v", err)
	}
	if state != UnlockStateQuestUnderReview {
		t.Fatalf("expected quest_under_review, got %s", state)
	}

	state, err = NextUnlockState(state, ActionApproveQuest)
	if err != nil {
		t.Fatalf("approve quest transition failed: %v", err)
	}
	if state != UnlockStateConversationUnlocked {
		t.Fatalf("expected conversation_unlocked, got %s", state)
	}
}

func TestNextUnlockStateRejectLoopsBack(t *testing.T) {
	state, err := NextUnlockState(UnlockStateQuestUnderReview, ActionRejectQuest)
	if err != nil {
		t.Fatalf("reject quest transition failed: %v", err)
	}
	if state != UnlockStateQuestPending {
		t.Fatalf("expected quest_pending, got %s", state)
	}
}

func TestNextUnlockStateRestrictAndReset(t *testing.T) {
	state, err := NextUnlockState(UnlockStateMatched, ActionRestrict)
	if err != nil {
		t.Fatalf("restrict transition failed: %v", err)
	}
	if state != UnlockStateRestricted {
		t.Fatalf("expected restricted, got %s", state)
	}

	state, err = NextUnlockState(state, ActionResetToMatched)
	if err != nil {
		t.Fatalf("reset transition failed: %v", err)
	}
	if state != UnlockStateMatched {
		t.Fatalf("expected matched, got %s", state)
	}
}

func TestNextUnlockStateInvalidTransition(t *testing.T) {
	if _, err := NextUnlockState(UnlockStateMatched, ActionApproveQuest); err == nil {
		t.Fatal("expected invalid transition error")
	}
}
