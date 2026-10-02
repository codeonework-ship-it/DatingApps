package mobile

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"database/sql"
	"encoding/hex"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
)

// Every authenticated request used to UPDATE auth_sessions.last_used_at (a
// WAL record, a dead tuple and a captured domain event per read). The session
// lookup now refreshes it at most once a minute, or on a new UTC day, and
// reads the roles in the same round trip.
func TestPrincipalLookupThrottlesLastUsedAtPostgres(t *testing.T) {
	dsn := os.Getenv("PROFILE_TEST_DATABASE_URL")
	if dsn == "" {
		t.Skip("PROFILE_TEST_DATABASE_URL is not set")
	}
	db, err := sql.Open("pgx", dsn)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = db.Close() })
	ctx := context.Background()

	userID := uuid.NewString()
	username := "captouch" + strings.ReplaceAll(userID[:8], "-", "")
	mustExec := func(query string, args ...any) {
		t.Helper()
		if _, err := db.ExecContext(ctx, query, args...); err != nil {
			t.Fatalf("%s: %v", query, err)
		}
	}
	mustExec(`INSERT INTO user_management.users (id, username, name, date_of_birth, gender, terms_accepted, terms_accepted_at)
		VALUES ($1, $2, 'Capacity Touch', '1990-01-01', 'female', TRUE, NOW())`, userID, username)
	t.Cleanup(func() {
		_, _ = db.Exec(`DELETE FROM user_management.auth_sessions WHERE user_id=$1`, userID)
		_, _ = db.Exec(`DELETE FROM user_management.auth_account_roles WHERE user_id=$1`, userID)
		_, _ = db.Exec(`DELETE FROM user_management.auth_credentials WHERE user_id=$1`, userID)
		deleteTestMember(context.Background(), db, userID)
	})
	mustExec(`INSERT INTO user_management.auth_credentials(user_id, username, password_hash) VALUES ($1, $2, 'not-a-real-hash')`, userID, username)
	mustExec(`INSERT INTO user_management.auth_account_roles(user_id, role) VALUES ($1, 'support')`, userID)

	raw := make([]byte, 32)
	_, _ = rand.Read(raw)
	token := hex.EncodeToString(raw)
	accessHash := sha256.Sum256([]byte(token))
	refresh := make([]byte, 32)
	_, _ = rand.Read(refresh)
	var sessionID string
	if err := db.QueryRowContext(ctx, `INSERT INTO user_management.auth_sessions
		(user_id, access_token_hash, refresh_token_hash, access_expires_at, refresh_expires_at, last_used_at)
		VALUES ($1, $2, $3, NOW() + INTERVAL '30 minutes', NOW() + INTERVAL '1 day', NOW() - INTERVAL '10 seconds')
		RETURNING id::text`, userID, accessHash[:], refresh).Scan(&sessionID); err != nil {
		t.Fatal(err)
	}
	lastUsed := func() time.Time {
		t.Helper()
		var at time.Time
		if err := db.QueryRowContext(ctx, `SELECT last_used_at FROM user_management.auth_sessions WHERE id=$1`, sessionID).Scan(&at); err != nil {
			t.Fatal(err)
		}
		return at
	}

	repo := &profileRepository{pg: db}
	before := lastUsed()
	principal, err := repo.principalForAccessToken(ctx, "Bearer "+token)
	if err != nil {
		t.Fatalf("principalForAccessToken: %v", err)
	}
	if principal.UserID != userID || principal.SessionID != sessionID {
		t.Fatalf("unexpected principal %+v", principal)
	}
	if !principal.Roles["user"] || !principal.Roles["support"] {
		t.Fatalf("roles not loaded with the session: %v", principal.Roles)
	}
	if after := lastUsed(); !after.Equal(before) {
		t.Fatalf("last_used_at rewritten %s after the previous touch; want at most once a minute", after.Sub(before))
	}

	mustExec(`UPDATE user_management.auth_sessions SET last_used_at = NOW() - INTERVAL '5 minutes' WHERE id=$1`, sessionID)
	stale := lastUsed()
	if _, err := repo.principalForAccessToken(ctx, "Bearer "+token); err != nil {
		t.Fatal(err)
	}
	if after := lastUsed(); !after.After(stale.Add(4 * time.Minute)) {
		t.Fatalf("stale last_used_at was not refreshed (was %s, now %s)", stale, after)
	}

	// A session last seen on the previous UTC day is refreshed on its first
	// request of the new day, however recent, so the daily-activity triggers
	// (087/123) count the day. NOW() cannot be pinned here, so check that the
	// predicate carries the day clause and evaluates.
	if !strings.Contains(sessionTouchDueSQL, "AT TIME ZONE 'UTC')::date <") {
		t.Fatal("session touch throttle lost its UTC-day clause")
	}
	mustExec(`UPDATE user_management.auth_sessions
		SET last_used_at = date_trunc('day', NOW() AT TIME ZONE 'UTC') AT TIME ZONE 'UTC' - INTERVAL '1 second'
		WHERE id=$1`, sessionID)
	var dueAcrossMidnight bool
	if err := db.QueryRowContext(ctx, `SELECT `+sessionTouchDueSQL+` FROM user_management.auth_sessions s WHERE s.id=$1`, sessionID).Scan(&dueAcrossMidnight); err != nil {
		t.Fatal(err)
	}
	if !dueAcrossMidnight {
		t.Fatal("a session last used before UTC midnight must be touched on its first request of the new day")
	}

	if _, err := repo.principalForAccessToken(ctx, "Bearer not-a-session"); err == nil {
		t.Fatal("unknown token accepted")
	}
}
