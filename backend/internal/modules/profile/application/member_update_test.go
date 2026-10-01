package application

import (
	"errors"
	"testing"
)

func TestMemberProfileCannotWriteServerOwnedFields(t *testing.T) {
	for _, key := range []string{"isVerified", "is_verified", "is_banned", "isActive", "is_active", "suspended_at", "suspended_until", "profileCompletion", "profile_completion", "username", "dateOfBirth", "date_of_birth", "gender", "photos", "photoUrls", "password_hash", "roles", "terms_accepted", "unknown_future_column"} {
		t.Run(key, func(t *testing.T) {
			if err := ValidateMemberProfileUpdate(map[string]any{"id": "member", key: true}); !errors.Is(err, ErrValidation) {
				t.Fatalf("field %s must be rejected: %v", key, err)
			}
		})
	}
	if err := ValidateMemberProfileUpdate(map[string]any{"id": "member", "bio": "A new public biography", "heightCm": 170}); err != nil {
		t.Fatal(err)
	}
}
