package mobile

import (
	"context"
	"database/sql"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"

	"github.com/google/uuid"
)

func TestLikedMeRejectsInvalidUserID(t *testing.T) {
	s := newQuestWorkflowTestServer(t)
	defer s.Close()
	rec := httptest.NewRecorder()
	s.Handler().ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/v1/discovery/not-a-uuid/liked-me", nil))
	if rec.Code != http.StatusBadRequest {
		t.Fatalf("status=%d body=%s", rec.Code, rec.Body.String())
	}
}

// Uses a migrated native database but rolls back all fixtures.
func TestLikedMePostgresListsOnlyPendingVisibleLikers(t *testing.T) {
	dsn := os.Getenv("PROFILE_TEST_DATABASE_URL")
	if dsn == "" {
		t.Skip("PROFILE_TEST_DATABASE_URL is not set")
	}
	db, err := sql.Open("pgx", dsn)
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	ctx := context.Background()
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		t.Fatal(err)
	}
	defer tx.Rollback()
	exec := func(query string, args ...any) {
		t.Helper()
		if _, err := tx.ExecContext(ctx, query, args...); err != nil {
			t.Fatal(err)
		}
	}
	member := func() string {
		id := uuid.NewString()
		exec(`INSERT INTO user_management.users(id,name,date_of_birth,gender,profile_completion,is_verified) VALUES($1,'Member','1998-01-01','female',100,TRUE)`, id)
		for i := 0; i < 2; i++ {
			exec(`INSERT INTO user_management.photos(user_id,photo_url,ordering,moderation_status,lifecycle_status) VALUES($1,$2,$3,'approved','active')`, id, id+string(rune('0'+i)), i)
		}
		return id
	}
	swipe := func(from, to string, like bool, age string) {
		exec(`INSERT INTO matching.swipes(user_id,target_user_id,is_like,created_at) VALUES($1,$2,$3,NOW()-$4::interval)`, from, to, like, age)
	}
	viewer := member()
	older, newer := member(), member()
	passedBack, likedBack, passedOnMe, blocked, unpublished := member(), member(), member(), member(), member()
	swipe(older, viewer, true, "2 hours")
	swipe(newer, viewer, true, "1 minute")
	swipe(passedBack, viewer, true, "3 hours")
	swipe(viewer, passedBack, false, "1 hour")
	swipe(likedBack, viewer, true, "3 hours")
	swipe(viewer, likedBack, true, "1 hour")
	swipe(passedOnMe, viewer, false, "1 hour")
	swipe(blocked, viewer, true, "1 hour")
	exec(`INSERT INTO user_management.blocked_users(user_id,blocked_user_id) VALUES($1,$2)`, viewer, blocked)
	swipe(unpublished, viewer, true, "1 hour")
	exec(`UPDATE user_management.users SET profile_completion=25 WHERE id=$1`, unpublished)

	profiles, count, err := loadLikedMe(ctx, tx, viewer, 10)
	if err != nil {
		t.Fatal(err)
	}
	if count != 2 || len(profiles) != 2 {
		t.Fatalf("count=%d profiles=%v", count, profiles)
	}
	if profiles[0]["id"] != newer || profiles[1]["id"] != older {
		t.Fatalf("order=%v,%v want newest like first", profiles[0]["id"], profiles[1]["id"])
	}
	for _, p := range profiles {
		if p["isVerified"] != true || p["liked_at"] == "" || len(p["photoUrls"].([]string)) != 2 {
			t.Fatalf("card=%v", p)
		}
		if _, leaked := p["date_of_birth"]; leaked {
			t.Fatal("birthday leaked")
		}
	}

	page, count, err := loadLikedMe(ctx, tx, viewer, 1)
	if err != nil {
		t.Fatal(err)
	}
	if count != 2 || len(page) != 1 || page[0]["id"] != newer {
		t.Fatalf("limited page count=%d page=%v", count, page)
	}

	// Answering removes the liker.
	swipe(viewer, newer, true, "0 seconds")
	profiles, count, err = loadLikedMe(ctx, tx, viewer, 10)
	if err != nil {
		t.Fatal(err)
	}
	if count != 1 || profiles[0]["id"] != older {
		t.Fatalf("after answering count=%d profiles=%v", count, profiles)
	}
}
