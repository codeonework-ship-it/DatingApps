package mobile

import (
	"strings"
	"testing"
	"time"
)

// TestProfileAgeUsesCalendarBirthday is the PROF-002 evidence.
//
// The requirement is explicit that age comes from a calendar birthday
// comparison and not elapsed days over 365.25, because the two disagree around
// a birthday and around leap years — the difference decides whether a member
// who turns 18 today can complete signup.
func TestProfileAgeUsesCalendarBirthday(t *testing.T) {
	const name, gender = "Valid Name", "F"
	now := time.Date(2026, 6, 15, 12, 0, 0, 0, time.UTC)

	cases := []struct {
		label   string
		dob     string
		allowed bool
	}{
		{"turns 18 tomorrow", "2008-06-16", false},
		{"turns 18 today", "2008-06-15", true},
		{"turned 18 yesterday", "2008-06-14", true},
		{"turns 81 tomorrow, still 80", "1945-06-16", true},
		{"turned 81 today", "1945-06-15", false},
		{"comfortably inside", "1995-01-01", true},
	}

	for _, tc := range cases {
		err := validateProfileBasics(name, tc.dob, gender, now)
		if tc.allowed && err != nil {
			t.Errorf("%s (%s): expected acceptance, got %v", tc.label, tc.dob, err)
		}
		if !tc.allowed && err == nil {
			t.Errorf("%s (%s): expected rejection, got none", tc.label, tc.dob)
		}
	}
}

// TestProfileAgeHandlesLeapDayBirthdays covers the case elapsed-day arithmetic
// gets wrong: a 29 February birthday in a non-leap year.
func TestProfileAgeHandlesLeapDayBirthdays(t *testing.T) {
	const name, gender = "Valid Name", "F"

	// 2026 is not a leap year, so this member's birthday "falls" on 1 March by
	// calendar comparison: on 28 February they are still 17.
	dayBefore := time.Date(2026, 2, 28, 12, 0, 0, 0, time.UTC)
	if err := validateProfileBasics(name, "2008-02-29", gender, dayBefore); err == nil {
		t.Error("a leap-day member is still 17 on 28 February 2026")
	}
	onOrAfter := time.Date(2026, 3, 1, 12, 0, 0, 0, time.UTC)
	if err := validateProfileBasics(name, "2008-02-29", gender, onOrAfter); err != nil {
		t.Errorf("a leap-day member has turned 18 by 1 March 2026: %v", err)
	}
}

// TestProfileDisplayNameBounds covers the trimmed 2–50 character rule.
func TestProfileDisplayNameBounds(t *testing.T) {
	const gender, dob = "F", "1995-01-01"
	now := time.Date(2026, 6, 15, 12, 0, 0, 0, time.UTC)

	cases := []struct {
		label   string
		name    string
		allowed bool
	}{
		{"single character", "A", false},
		{"two characters", "Al", true},
		{"whitespace padded to length", "  A  ", false},
		{"fifty characters", string(make([]byte, 0, 50)) + strings50(), true},
		{"fifty-one characters", strings50() + "x", false},
	}
	for _, tc := range cases {
		err := validateProfileBasics(tc.name, dob, gender, now)
		if tc.allowed && err != nil {
			t.Errorf("%s: expected acceptance, got %v", tc.label, err)
		}
		if !tc.allowed && err == nil {
			t.Errorf("%s: expected rejection, got none", tc.label)
		}
	}
}

func strings50() string {
	out := make([]byte, 50)
	for i := range out {
		out[i] = 'a'
	}
	return string(out)
}

// TestCompletionEnforcesBioBounds is the PROF-004 evidence.
//
// The lower bound was already checked at completion. The upper bound was not,
// and no write path enforced it either: a 600-character bio was accepted on
// the draft and would have completed. Verified live before this guard.
func TestCompletionEnforcesBioBounds(t *testing.T) {
	base := profileDraft{
		Name:           "Valid Name",
		DateOfBirth:    "1995-01-01",
		Gender:         "F",
		Photos:         []profilePhoto{{}, {}},
		SeekingGenders: []string{"M"},
	}

	withBio := func(bio string) profileDraft {
		draft := base
		draft.Bio = bio
		return draft
	}

	if err := validateDraftReadyForCompletion(withBio(strings.Repeat("x", 9))); err == nil {
		t.Error("a 9-character bio is below the documented minimum")
	}
	if err := validateDraftReadyForCompletion(withBio(strings.Repeat("x", 10))); err != nil {
		t.Errorf("a 10-character bio is the documented minimum: %v", err)
	}
	if err := validateDraftReadyForCompletion(withBio(strings.Repeat("x", 500))); err != nil {
		t.Errorf("a 500-character bio is the documented maximum: %v", err)
	}
	if err := validateDraftReadyForCompletion(withBio(strings.Repeat("x", 501))); err == nil {
		t.Error("a 501-character bio exceeds the documented maximum")
	}
}
