package domain

import (
	"strings"
	"testing"
)

func TestNewUsernameNormalizesAndValidates(t *testing.T) {
	username, err := NewUsername(" Person.One ")
	if err != nil {
		t.Fatalf("NewUsername() error = %v", err)
	}
	if username.Value() != "person.one" {
		t.Fatalf("expected normalized username, got %q", username.Value())
	}

	for _, invalid := range []string{"", "a", "ab", strings.Repeat("a", 31), "bad name", "_leading", "trailing_", "éab"} {
		if _, err := NewUsername(invalid); err == nil {
			t.Fatalf("expected %q to be rejected", invalid)
		}
	}
	for _, valid := range []string{"abc", "a_b", "a.b", strings.Repeat("a", 30)} {
		if _, err := NewUsername(valid); err != nil {
			t.Fatalf("valid username %q: %v", valid, err)
		}
	}
}

func TestValidatePasswordRequiresLengthLettersAndNumbers(t *testing.T) {
	for _, invalid := range []string{"short1", "allletters", "12345678", strings.Repeat("a", 72) + "1"} {
		if err := ValidatePassword(invalid); err == nil {
			t.Fatalf("expected password policy rejection")
		}
	}
	for _, valid := range []string{"Password123", strings.Repeat("a", 71) + "1"} {
		if err := ValidatePassword(valid); err != nil {
			t.Fatalf("expected strong password to pass: %v", err)
		}
	}
}
