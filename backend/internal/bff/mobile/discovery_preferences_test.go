package mobile

import (
	"net/url"
	"testing"
)

func TestDiscoverySavedPreferencesAndExplicitOverrides(t *testing.T) {
	s := newQuestWorkflowTestServer(t)
	defer s.Close()
	s.store.profiles["viewer"] = profileDraft{SeekingGenders: []string{"F"}, MinAgeYears: 18, MaxAgeYears: 40, VerifiedOnly: true, SeriousOnly: true, EducationFilter: []string{"MBA"}}
	education := "MBA"
	s.store.profiles["eligible"] = profileDraft{Gender: "female", DateOfBirth: "1998-01-01", IntentTags: []string{"long_term"}, Education: &education}
	base := s.store.profiles["eligible"]
	for _, id := range []string{"wrong_gender", "casual", "wrong_education", "unverified", "too_old"} {
		s.store.profiles[id] = base
	}
	d := base
	d.Gender = "M"
	s.store.profiles["wrong_gender"] = d
	d = base
	d.IntentTags = []string{"casual"}
	s.store.profiles["casual"] = d
	d = base
	d.Education = nil
	s.store.profiles["wrong_education"] = d
	d = base
	d.DateOfBirth = "1960-01-01"
	s.store.profiles["too_old"] = d
	rows := []any{}
	for _, id := range []string{"eligible", "wrong_gender", "casual", "wrong_education", "unverified", "too_old"} {
		rows = append(rows, map[string]any{"id": id, "isVerified": id != "unverified"})
	}
	response := map[string]any{"candidates": rows}
	s.attachAdvancedFilteredDiscovery(response, "viewer", url.Values{})
	got := response["candidates"].([]any)
	if len(got) != 1 || got[0].(map[string]any)["id"] != "eligible" {
		t.Fatalf("saved criteria returned %v", got)
	}
	override := url.Values{"seeking_genders": {""}, "serious_only": {"false"}, "education_filter": {""}, "verified_only": {"false"}, "max_age": {"80"}}
	response = map[string]any{"candidates": rows}
	s.attachAdvancedFilteredDiscovery(response, "viewer", override)
	if len(response["candidates"].([]any)) != 6 {
		t.Fatalf("explicit overrides ignored: %v", response)
	}
	if _, ok := override["min_age"]; ok {
		t.Fatal("mutated caller query")
	}
}

func TestPublicAgeVisibilityAndNoBirthday(t *testing.T) {
	for _, show := range []bool{true, false} {
		profile := publicProfileProjection(map[string]any{"date_of_birth": "1998-01-01", "show_age": show}, map[string]any{"date_of_birth": "1990-01-01"}, nil)
		if _, ok := profile["date_of_birth"]; ok {
			t.Fatal("birthday disclosed")
		}
		if _, ok := profile["age"]; ok != show {
			t.Fatalf("show_age=%v profile=%v", show, profile)
		}
		response := map[string]any{"candidates": []any{map[string]any{"id": "target", "age": 99, "dateOfBirth": "private", "date_of_birth": "private"}}, "spotlight_profiles": []any{map[string]any{"id": "target", "age": 99}}}
		age := 28
		var visibleAge *int
		if show {
			visibleAge = &age
		}
		applyPublishedDiscovery(response, map[string]publishedDiscoveryProfile{"target": {Age: visibleAge}})
		for _, key := range []string{"candidates", "spotlight_profiles"} {
			row := response[key].([]any)[0].(map[string]any)
			for _, privateKey := range []string{"date_of_birth", "dateOfBirth"} {
				if _, ok := row[privateKey]; ok {
					t.Fatalf("leaked %s", privateKey)
				}
			}
			if _, ok := row["age"]; ok != show {
				t.Fatalf("show_age=%v row=%v", show, row)
			}
		}
	}
}

func TestSeriousIntentAliases(t *testing.T) {
	c := advancedFilterCriteria{seriousOnly: true}
	for _, intent := range []string{"long_term", "long-term", "long term", "marriage", "serious", "serious_only", "serious_relationship", "serious relationship"} {
		if !c.matches(profileDraft{IntentTags: []string{intent}}) {
			t.Errorf("serious intent %q excluded", intent)
		}
	}
	for _, intent := range []string{"", "casual", "hookup", "new_friends"} {
		if c.matches(profileDraft{IntentTags: []string{intent}}) {
			t.Errorf("non-serious intent %q included", intent)
		}
	}
}
