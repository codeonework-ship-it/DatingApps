package domain

import "fmt"

type UnlockState string

const (
	UnlockStateMatched              UnlockState = "matched"
	UnlockStateQuestPending         UnlockState = "quest_pending"
	UnlockStateQuestUnderReview     UnlockState = "quest_under_review"
	UnlockStateConversationUnlocked UnlockState = "conversation_unlocked"
	UnlockStateRestricted           UnlockState = "restricted"
)

type UnlockAction string

const (
	ActionAssignQuest    UnlockAction = "assign_quest"
	ActionSubmitQuest    UnlockAction = "submit_quest"
	ActionApproveQuest   UnlockAction = "approve_quest"
	ActionRejectQuest    UnlockAction = "reject_quest"
	ActionRestrict       UnlockAction = "restrict"
	ActionResetToMatched UnlockAction = "reset_to_matched"
)

func IsValidState(state UnlockState) bool {
	switch state {
	case UnlockStateMatched,
		UnlockStateQuestPending,
		UnlockStateQuestUnderReview,
		UnlockStateConversationUnlocked,
		UnlockStateRestricted:
		return true
	default:
		return false
	}
}

func NextUnlockState(current UnlockState, action UnlockAction) (UnlockState, error) {
	if !IsValidState(current) {
		return "", fmt.Errorf("invalid current unlock state: %s", current)
	}

	if action == ActionRestrict {
		return UnlockStateRestricted, nil
	}
	if action == ActionResetToMatched {
		return UnlockStateMatched, nil
	}

	switch current {
	case UnlockStateMatched:
		if action == ActionAssignQuest {
			return UnlockStateQuestPending, nil
		}
	case UnlockStateQuestPending:
		if action == ActionSubmitQuest {
			return UnlockStateQuestUnderReview, nil
		}
	case UnlockStateQuestUnderReview:
		if action == ActionApproveQuest {
			return UnlockStateConversationUnlocked, nil
		}
		if action == ActionRejectQuest {
			return UnlockStateQuestPending, nil
		}
	case UnlockStateConversationUnlocked:
		if action == ActionAssignQuest {
			return UnlockStateQuestPending, nil
		}
	case UnlockStateRestricted:
		if action == ActionResetToMatched {
			return UnlockStateMatched, nil
		}
	}

	return "", fmt.Errorf("invalid unlock transition: %s --(%s)--> ?", current, action)
}
