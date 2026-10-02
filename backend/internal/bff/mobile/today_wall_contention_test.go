package mobile

import (
	"context"
	"database/sql"
	"os"
	"testing"
	"time"

	"github.com/google/uuid"
)

// TestTodayWallDoesNotBlockOnMemberRowPostgres guards API-03: GET /walls/today
// used to take SELECT … FOR UPDATE on the member's users row, so any write
// holding that row turned the read into a lock-timeout 503. The wall must be
// served while the row is locked and while another request is choosing the
// day's picks, and the day's choice is persisted by a later request.
func TestTodayWallDoesNotBlockOnMemberRowPostgres(t *testing.T) {
	f := newActivityFixture(t)
	var ready bool
	if err := f.db.QueryRow(`SELECT to_regclass('matching.wall_daily_picks') IS NOT NULL`).Scan(&ready); err != nil || !ready {
		t.Skip("migration 112_today_wall_and_cover is not applied")
	}
	t.Setenv("BLOG_WALL_TIERS", "1:0:100000")
	ctx := context.Background()
	for _, u := range []string{f.proposer, f.invitee, f.groupMate} {
		blogEligible(t, f.datePlanFixture, u)
	}
	for i := 0; i < 3; i++ {
		p, err := saveBlog(ctx, f.db, f.proposer, uuid.NewString(), blogDraft{Title: "Contention " + itoa(i), Body: "A short story for the wall.", Audience: "community", AllowFeaturing: true})
		if err != nil {
			t.Fatal(err)
		}
		if _, err = toggleBlogLike(ctx, f.db, f.invitee, p.ID, true, ""); err != nil {
			t.Fatal(err)
		}
	}

	// Production sessions run with a short lock_timeout; mirror that here.
	dsn := os.Getenv("PROFILE_TEST_DATABASE_URL")
	shortLock, err := sql.Open("pgx", dsn+"&lock_timeout=300")
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = shortLock.Close() })

	persisted := func(day time.Time) int {
		var n int
		if err := f.db.QueryRow(`SELECT COUNT(*) FROM matching.wall_daily_picks WHERE recipient_id=$1 AND day=$2::date`,
			f.groupMate, day.Format("2006-01-02")).Scan(&n); err != nil {
			t.Fatal(err)
		}
		return n
	}
	day := time.Date(2098, 3, 9, 9, 0, 0, 0, time.UTC)
	t.Cleanup(func() {
		_, _ = f.db.Exec(`DELETE FROM matching.wall_daily_picks WHERE recipient_id=$1 AND day>='2098-01-01' AND day<'2099-01-01'`, f.groupMate)
	})

	// 1. Another transaction holds the member's users row.
	holder, err := f.db.BeginTx(ctx, nil)
	if err != nil {
		t.Fatal(err)
	}
	if _, err = holder.Exec(`SELECT id FROM user_management.users WHERE id=$1 FOR UPDATE`, f.groupMate); err != nil {
		t.Fatal(err)
	}
	callCtx, cancel := context.WithTimeout(ctx, 10*time.Second)
	items, err := todayWall(callCtx, shortLock, f.groupMate, day)
	cancel()
	_ = holder.Rollback()
	if err != nil {
		t.Fatalf("wall failed while the member row was locked: %v", err)
	}
	if len(items) == 0 {
		t.Fatal("wall served no items while the member row was locked")
	}
	if n := persisted(day); n != 0 {
		t.Fatalf("picks persisted under contention: %d", n)
	}

	// 2. Another request is choosing the same member's day right now.
	conn, err := f.db.Conn(ctx)
	if err != nil {
		t.Fatal(err)
	}
	dayText := day.Format("2006-01-02")
	if _, err = conn.ExecContext(ctx, `SELECT pg_advisory_lock(hashtext('matching.wall_daily_picks'), hashtext($1||':'||$2))`, f.groupMate, dayText); err != nil {
		t.Fatal(err)
	}
	items, err = todayWall(ctx, shortLock, f.groupMate, day)
	_, _ = conn.ExecContext(ctx, `SELECT pg_advisory_unlock(hashtext('matching.wall_daily_picks'), hashtext($1||':'||$2))`, f.groupMate, dayText)
	_ = conn.Close()
	if err != nil || len(items) == 0 {
		t.Fatalf("wall during a concurrent first pick: items=%d err=%v", len(items), err)
	}
	if n := persisted(day); n != 0 {
		t.Fatalf("loser of the first-pick race persisted %d picks", n)
	}

	// 3. Without contention the day's choice is persisted and then stable.
	first, err := todayWall(ctx, shortLock, f.groupMate, day)
	if err != nil || len(first) == 0 {
		t.Fatalf("uncontended wall: items=%d err=%v", len(first), err)
	}
	if n := persisted(day); n == 0 {
		t.Fatal("uncontended wall did not persist the day's picks")
	}
	again, err := todayWall(ctx, shortLock, f.groupMate, day)
	if err != nil || len(again) != len(first) {
		t.Fatalf("wall changed within the day: %d vs %d (%v)", len(again), len(first), err)
	}
	for i := range first {
		if (first[i].Post == nil) != (again[i].Post == nil) || (first[i].Post != nil && first[i].Post.ID != again[i].Post.ID) {
			t.Fatal("wall order changed within the day", i)
		}
	}
}
