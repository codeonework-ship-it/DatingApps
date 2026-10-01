package mobile

import (
	"net/url"
	"testing"
	"time"
)

func TestQAEveryAdvancedFilterIncludesMatchAndExcludesMismatch(t *testing.T) {
	str := func(s string) *string { return &s }
	yes := true
	good := profileDraft{UserID: "good", DateOfBirth: "1998-04-12", Country: str("India"), RegionState: str("Karnataka"), City: str("Bengaluru"), Religion: str("Hindu"), RelationshipStatus: str("Single"), Smoking: "Never", Drinking: "Socially", PersonalityType: str("Introvert"), PartyLover: &yes, HookupOnly: true, PetPreference: str("Dogs"), DietPreference: str("Vegetarian"), WorkoutFrequency: str("Daily"), DietType: str("Balanced"), SleepSchedule: str("Early bird"), TravelStyle: str("Adventurous"), PoliticalComfort: str("Moderate"), MotherTongue: str("Kannada"), LanguageTags: []string{"English"}, IntentTags: []string{"long-term"}}
	cases := [][2]string{{"country", "India"}, {"state", "Karnataka"}, {"city", "Bengaluru"}, {"religion", "Hindu"}, {"relationship_status", "Single"}, {"smoking", "Never"}, {"drinking", "Socially"}, {"personality_type", "Introvert"}, {"party_lover", "true"}, {"hookup_only", "true"}, {"pet_preference", "Dogs"}, {"diet_preference", "Vegetarian"}, {"workout_frequency", "Daily"}, {"diet_type", "Balanced"}, {"sleep_schedule", "Early bird"}, {"travel_style", "Adventurous"}, {"political_comfort_range", "Moderate"}, {"mother_tongue", "Kannada"}, {"language_tags", "English"}, {"intent_tags", "long-term"}, {"min_age", "25"}, {"max_age", "35"}}
	s := newQuestWorkflowTestServer(t)
	defer s.Close()
	for _, tc := range cases {
		t.Run(tc[0], func(t *testing.T) {
			query := url.Values{tc[0]: []string{tc[1]}}
			if !hasAdvancedDiscoveryQuery(query) {
				t.Fatal("UI/API filter does not activate filtering")
			}
			c := s.buildAdvancedCriteria("viewer", query)
			if !c.matches(good) {
				t.Fatalf("matching profile excluded by %s=%s", tc[0], tc[1])
			}
			if c.matches(profileDraft{}) {
				t.Fatalf("unknown/mismatched profile accepted by %s", tc[0])
			}
		})
	}
	t.Run("deal breakers exclude overlapping values", func(t *testing.T) {
		c := s.buildAdvancedCriteria("viewer", url.Values{"deal_breaker_tags": []string{"smoking"}})
		if !c.matches(good) {
			t.Fatal("compatible profile excluded")
		}
		bad := good
		bad.DealBreakerTags = []string{"smoking"}
		if c.matches(bad) {
			t.Fatal("deal breaker overlap was accepted")
		}
	})
	t.Run("combined filters use AND", func(t *testing.T) {
		c := s.buildAdvancedCriteria("viewer", url.Values{"country": []string{"India"}, "smoking": []string{"Never"}, "city": []string{"Mumbai"}})
		if c.matches(good) {
			t.Fatal("one matching field must not override a mismatched field")
		}
	})
	t.Run("case and whitespace normalization", func(t *testing.T) {
		c := s.buildAdvancedCriteria("viewer", url.Values{"country": []string{"  INDIA "}, "intent_tags": []string{" LONG-TERM "}})
		if !c.matches(good) {
			t.Fatal("equivalent normalized values did not match")
		}
	})
}

func TestQAVerifiedOnlyFiltersActualVerificationState(t *testing.T) {
	s := newQuestWorkflowTestServer(t)
	defer s.Close()
	s.store.profiles["verified"] = profileDraft{UserID: "verified"}
	s.store.profiles["unverified"] = profileDraft{UserID: "unverified"}
	response := map[string]any{"candidates": []any{map[string]any{"id": "verified", "isVerified": true}, map[string]any{"id": "unverified", "isVerified": false}}}
	s.attachAdvancedFilteredDiscovery(response, "viewer", url.Values{"verified_only": []string{"true"}})
	rows := response["candidates"].([]any)
	if len(rows) != 1 || rows[0].(map[string]any)["id"] != "verified" {
		t.Fatalf("verified-only returned %v", rows)
	}
}

func TestQAAgeFilterCalendarBoundary(t *testing.T) {
	for _, tc := range []struct {
		dob, now string
		want     int
	}{{"2006-03-01", "2024-02-29", 17}, {"2008-03-01", "2026-03-01", 18}, {"2008-02-29", "2026-02-28", 17}, {"2008-02-29", "2026-03-01", 18}} {
		now, _ := time.Parse("2006-01-02", tc.now)
		if got := ageYearsFromDateOfBirth(tc.dob, now); got != tc.want {
			t.Errorf("DOB=%s at %s: age=%d want=%d", tc.dob, tc.now, got, tc.want)
		}
	}
}
