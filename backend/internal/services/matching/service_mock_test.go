package matching

import (
	"testing"
	"time"

	"github.com/verified-dating/backend/internal/platform/config"
)

func TestMockUsers_CountGenderAndAgeRange(t *testing.T) {
	repo := &SupabaseRepository{
		cfg: config.Config{
			MockFemaleUsersCount: 100,
			MockMaleUsersCount:   100,
			MockMinAgeYears:      18,
			MockMaxAgeYears:      45,
		},
	}

	users := repo.mockUsers(250)
	if len(users) != 200 {
		t.Fatalf("expected 200 mock users, got %d", len(users))
	}

	female := 0
	male := 0
	now := time.Now()

	for _, row := range users {
		gender := toString(row["gender"])
		if gender == "F" {
			female++
		}
		if gender == "M" {
			male++
		}

		dobRaw := toString(row["dateOfBirth"])
		dob, err := time.Parse("2006-01-02", dobRaw)
		if err != nil {
			t.Fatalf("invalid dateOfBirth %q: %v", dobRaw, err)
		}
		age := now.Year() - dob.Year()
		if now.Month() < dob.Month() || (now.Month() == dob.Month() && now.Day() < dob.Day()) {
			age--
		}
		if age < 18 || age > 45 {
			t.Fatalf("age out of range for %v: got %d", row["id"], age)
		}
	}

	if female != 100 {
		t.Fatalf("expected 100 female users, got %d", female)
	}
	if male != 100 {
		t.Fatalf("expected 100 male users, got %d", male)
	}
}
