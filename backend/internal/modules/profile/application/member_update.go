package application

import "fmt"

// Identity, completion, verification, moderation, credentials and media have
// dedicated workflows. A member's general profile update cannot write them.
func ValidateMemberProfileUpdate(profile map[string]any) error {
	for key := range profile {
		switch key {
		case "id", "name", "bio", "heightCm", "height_cm", "education", "profession",
			"incomeRange", "income_range", "drinking", "smoking", "religion",
			"motherTongue", "mother_tongue", "relationshipStatus", "relationship_status",
			"personalityType", "personality_type", "country", "state", "city":
		default:
			return fmt.Errorf("%w: field %s cannot be changed through profile update", ErrValidation, key)
		}
	}
	return nil
}
