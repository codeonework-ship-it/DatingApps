package mobile

import (
	"context"
	"database/sql"
	"net/http"
	"net/http/httptest"
	"os"
	"reflect"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
)

func TestPublicProfileProjectionExcludesPrivateAndStaleData(t *testing.T) {
	user := map[string]any{"id": "member", "name": "Current", "is_verified": false,
		"phone_number": "secret", "email": "secret", "username": "private_login", "location": "precise", "suspended_reason": "private"}
	snapshot := map[string]any{"name": "Old", "is_verified": true, "photoUrls": []string{"quarantine"}, "hobbies": []string{"Reading"}, "phone_number": "secret"}
	got := publicProfileProjection(user, snapshot, []string{"approved"})
	want := map[string]any{"id": "member", "name": "Current", "is_verified": false, "hobbies": []string{"Reading"}, "photoUrls": []string{"approved"}}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("projection = %#v, want %#v", got, want)
	}
}

func TestUsernameContractPostgres(t *testing.T) {
	dsn := os.Getenv("PROFILE_TEST_DATABASE_URL")
	if dsn == "" {
		t.Skip("PROFILE_TEST_DATABASE_URL is not set")
	}
	db, err := sql.Open("pgx", dsn)
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	tx, err := db.Begin()
	if err != nil {
		t.Fatal(err)
	}
	defer tx.Rollback()
	for _, table := range []string{"users", "auth_credentials"} {
		for _, name := range []string{"", "a", "ab", "abc", strings.Repeat("z", 30), strings.Repeat("z", 31), "_abc", "abc_", "Abc"} {
			if _, err := tx.Exec(`SAVEPOINT username_case`); err != nil {
				t.Fatal(err)
			}
			query := `INSERT INTO user_management.auth_credentials(username,password_hash) VALUES($1,'test')`
			if table == "users" {
				query = `INSERT INTO user_management.users(username,name,date_of_birth,gender) VALUES($1,'Test','1998-01-01','female')`
			}
			_, err := tx.Exec(query, name)
			valid := name == "abc" || name == strings.Repeat("z", 30)
			if (err == nil) != valid {
				t.Errorf("%s username=%q valid=%v error=%v", table, name, valid, err)
			}
			if _, err := tx.Exec(`ROLLBACK TO SAVEPOINT username_case`); err != nil {
				t.Fatal(err)
			}
		}
	}
}

func TestPublicProfileRequiresPrincipalEvenWithoutPersistence(t *testing.T) {
	s := newQuestWorkflowTestServer(t)
	defer s.Close()
	rec := httptest.NewRecorder()
	s.Handler().ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/v1/profile/"+uuid.NewString(), nil))
	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("status=%d body=%s", rec.Code, rec.Body.String())
	}
}

func TestProfileUpdateRejectsMemberPrivilegeEscalation(t *testing.T) {
	const member = "11111111-1111-4111-8111-111111111111"
	installStrictOperatorPrincipal(t, member)
	s := newQuestWorkflowTestServer(t)
	defer s.Close()
	for _, field := range []string{"isVerified", "is_verified", "is_banned", "profile_completion", "suspended_until"} {
		req := httptest.NewRequest(http.MethodPut, "/v1/profile/"+member, strings.NewReader(`{"profile":{"`+field+`":true}}`))
		req.Header.Set("Authorization", "Bearer "+testOperatorToken)
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Idempotency-Key", uuid.NewString())
		rec := httptest.NewRecorder()
		s.Handler().ServeHTTP(rec, req)
		if rec.Code != http.StatusBadRequest || !strings.Contains(rec.Body.String(), "cannot be changed") {
			t.Fatalf("field=%s status=%d body=%s", field, rec.Code, rec.Body.String())
		}
	}
}

func TestProfileBasicsCalendarBoundaries(t *testing.T) {
	for _, tc := range []struct {
		dob, now string
		valid    bool
	}{
		{"2008-03-01", "2026-02-28", false},
		{"2008-03-01", "2026-03-01", true},  // leap birth year must not delay March birthdays
		{"2006-03-01", "2024-02-29", false}, // leap current year must not admit a minor early
		{"2008-02-29", "2026-02-28", false},
		{"2008-02-29", "2026-03-01", true},
		{"1945-09-27", "2026-09-26", true},
		{"1945-09-26", "2026-09-26", false},
		{"bad-date", "2026-09-26", false},
	} {
		t.Run(tc.dob+"/"+tc.now, func(t *testing.T) {
			now, _ := time.Parse("2006-01-02", tc.now)
			err := validateProfileBasics("Member", tc.dob, "F", now)
			if (err == nil) != tc.valid {
				t.Fatalf("valid=%v err=%v", tc.valid, err)
			}
		})
	}
}

// Uses a migrated native database but rolls back all fixtures; no existing
// members, photos, credentials or drafts are changed.
func TestPublicProfilePostgresVisibility(t *testing.T) {
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
	viewer, target := uuid.NewString(), uuid.NewString()
	for _, id := range []string{viewer, target} {
		exec(`INSERT INTO user_management.users(id,name,date_of_birth,gender,profile_completion) VALUES($1,'Member','1998-01-01','female',100)`, id)
	}
	exec(`INSERT INTO user_management.profile_snapshots(user_id,profile_payload) VALUES($1,'{"hobbies":["Published"],"phone_number":"private","photos":[{"photo_url":"stale"}]}')`, target)
	exec(`INSERT INTO user_management.profile_drafts(user_id,draft_payload) VALUES($1,'{"hobbies":["Private unsaved edits"]}')`, target)
	for i, status := range []string{"approved", "approved", "review_required", "rejected"} {
		exec(`INSERT INTO user_management.photos(user_id,photo_url,ordering,moderation_status,lifecycle_status) VALUES($1,$2,$3,$4,'active')`, target, status+string(rune('0'+i)), i, status)
	}
	check := func(want bool) map[string]any {
		t.Helper()
		p, found, err := loadPublicProfile(ctx, tx, viewer, target)
		if err != nil || found != want {
			t.Fatalf("found=%v want=%v err=%v", found, want, err)
		}
		response := map[string]any{
			"candidates":         []any{map[string]any{"id": target, "photoUrls": []string{"stale"}, "isVerified": true}, map[string]any{"id": viewer}},
			"spotlight_profiles": []any{map[string]any{"id": target, "photoUrls": []string{"stale"}, "is_spotlight": true}},
		}
		if err := filterPublishedDiscovery(ctx, tx, viewer, response); err != nil {
			t.Fatal(err)
		}
		for _, key := range []string{"candidates", "spotlight_profiles"} {
			rows := response[key].([]any)
			wantCount := 0
			if want {
				wantCount = 1
			}
			if len(rows) != wantCount {
				t.Fatalf("%s count=%d want=%d", key, len(rows), wantCount)
			}
			if want {
				row := rows[0].(map[string]any)
				if !reflect.DeepEqual(row["photoUrls"], p["photoUrls"]) || row["isVerified"] != false {
					t.Fatalf("stale public card: %v", row)
				}
			}
		}
		return p
	}
	p := check(true)
	eligible := map[string]any{"candidates": []any{map[string]any{"id": target}}}
	if err := filterPublishedDiscovery(ctx, tx, viewer, eligible, advancedFilterCriteria{seekingGenders: []string{"F"}, minAgeYears: 18, maxAgeYears: 80}); err != nil {
		t.Fatal(err)
	}
	if len(eligible["candidates"].([]any)) != 1 {
		t.Fatal("published member excluded by incomplete draft")
	}
	ineligible := map[string]any{"candidates": []any{map[string]any{"id": target}}}
	if err := filterPublishedDiscovery(ctx, tx, viewer, ineligible, advancedFilterCriteria{seekingGenders: []string{"M"}}); err != nil {
		t.Fatal(err)
	}
	if len(ineligible["candidates"].([]any)) != 0 {
		t.Fatal("published gender was not enforced")
	}
	if !reflect.DeepEqual(p["photoUrls"], []string{"approved0", "approved1"}) {
		t.Fatalf("photos=%v", p["photoUrls"])
	}
	if !reflect.DeepEqual(p["hobbies"], []any{"Published"}) {
		t.Fatalf("snapshot=%v", p["hobbies"])
	}
	if _, ok := p["phone_number"]; ok {
		t.Fatal("private contact leaked")
	}
	exec(`INSERT INTO user_management.user_settings(user_id,show_age) VALUES($1,FALSE) ON CONFLICT(user_id) DO UPDATE SET show_age=FALSE`, target)
	hidden := check(true)
	if _, ok := hidden["date_of_birth"]; ok {
		t.Fatal("hidden birthday leaked")
	}
	if _, ok := hidden["age"]; ok {
		t.Fatal("hidden age leaked")
	}
	exec(`UPDATE user_management.user_settings SET show_age=TRUE WHERE user_id=$1`, target)
	if check(true)["age"] == nil {
		t.Fatal("visible age missing")
	}
	exec(`DELETE FROM user_management.profile_drafts WHERE user_id=$1`, target)
	check(true) // completed draft retention cannot erase the public profile
	for _, pair := range [][2]string{{viewer, target}, {target, viewer}} {
		exec(`INSERT INTO user_management.blocked_users(user_id,blocked_user_id) VALUES($1,$2)`, pair[0], pair[1])
		check(false)
		exec(`DELETE FROM user_management.blocked_users WHERE user_id=$1 AND blocked_user_id=$2`, pair[0], pair[1])
	}
	for _, mutation := range []string{"is_active=FALSE", "is_banned=TRUE", "profile_completion=25", "suspended_at=NOW(),suspended_until=NULL", "suspended_at=NOW(),suspended_until=NOW()+INTERVAL '1 day'"} {
		exec(`UPDATE user_management.users SET `+mutation+` WHERE id=$1`, target)
		check(false)
		exec(`UPDATE user_management.users SET is_active=TRUE,is_banned=FALSE,profile_completion=100,suspended_at=NULL,suspended_until=NULL WHERE id=$1`, target)
	}
	exec(`UPDATE user_management.users SET deactivated_at=NOW() WHERE id=$1`, target)
	check(false)
	exec(`UPDATE user_management.users SET deactivated_at=NULL WHERE id=$1`, target)
	exec(`UPDATE user_management.users SET erased_at=NOW() WHERE id=$1`, target)
	check(false)
	exec(`UPDATE user_management.users SET erased_at=NULL WHERE id=$1`, target)
	exec(`INSERT INTO user_management.auth_credentials(user_id,username,password_hash,is_disabled) VALUES($1,$2,'test-hash',TRUE)`, target, "qa_"+target[:8])
	check(false)
	exec(`UPDATE user_management.auth_credentials SET is_disabled=FALSE WHERE user_id=$1`, target)
	check(true)
	exec(`UPDATE user_management.users SET suspended_at=NOW()-INTERVAL '2 days',suspended_until=NOW()-INTERVAL '1 day' WHERE id=$1`, target)
	check(true)
	exec(`UPDATE user_management.photos SET deleted_at=NOW() WHERE user_id=$1 AND ordering=0`, target)
	check(false)
	exec(`UPDATE user_management.photos SET deleted_at=NULL,lifecycle_status='quarantined' WHERE user_id=$1 AND ordering=0`, target)
	check(false)
	exec(`UPDATE user_management.photos SET lifecycle_status='active',moderation_status='review_required' WHERE user_id=$1 AND ordering=0`, target)
	check(false)
}
