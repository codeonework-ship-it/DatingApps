package mobile

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"
)

func TestTodayWallPicksViewsAndCoverPostgres(t *testing.T) {
	f := newActivityFixture(t)
	var ready bool
	if err := f.db.QueryRow(`SELECT to_regclass('matching.photo_covers') IS NOT NULL`).Scan(&ready); err != nil || !ready {
		t.Skip("migration 112_today_wall_and_cover is not applied")
	}
	// Any like reaches every eligible wall, so ranking is the only variable.
	t.Setenv("BLOG_WALL_TIERS", "1:0:100000")
	ctx := context.Background()
	for _, u := range []string{f.proposer, f.invitee, f.groupMate} {
		blogEligible(t, f.datePlanFixture, u)
	}

	// Twelve chapters by the proposer; the first gets two likes so it ranks first.
	posts := make([]string, 12)
	for i := range posts {
		p, err := saveBlog(ctx, f.db, f.proposer, uuid.NewString(), blogDraft{Title: "Chapter " + itoa(i), Body: "A short story for the wall.", Audience: "community", AllowFeaturing: true})
		if err != nil {
			t.Fatal(err)
		}
		posts[i] = p.ID
		if _, err = toggleBlogLike(ctx, f.db, f.invitee, p.ID, true, ""); err != nil {
			t.Fatal(err)
		}
	}
	if _, err := toggleBlogLike(ctx, f.db, f.groupMate, posts[0], true, ""); err != nil {
		t.Fatal(err)
	}

	day1 := time.Date(2099, 1, 5, 9, 0, 0, 0, time.UTC)
	ids := func(items []todayWallItem) []string {
		out := []string{}
		for _, item := range items {
			if item.Post != nil {
				out = append(out, item.Post.ID)
			}
		}
		return out
	}
	first, err := todayWall(ctx, f.db, f.groupMate, day1)
	if err != nil {
		t.Fatal(err)
	}
	mine := 0
	for _, id := range ids(first) {
		for _, p := range posts {
			if id == p {
				mine++
			}
		}
	}
	if len(first) != todayWallSize || mine < 1 || first[0].Post == nil || first[0].Post.ID != posts[0] {
		t.Fatal("day 1 carousel", len(first), mine)
	}
	again, err := todayWall(ctx, f.db, f.groupMate, day1.Add(5*time.Hour))
	if err != nil || len(again) != len(first) || again[3].Kind != first[3].Kind {
		t.Fatal("carousel changed within the day", err)
	}
	for i := range first {
		a, b := first[i], again[i]
		if (a.Post == nil) != (b.Post == nil) || (a.Post != nil && a.Post.ID != b.Post.ID) || (a.Entry != nil && a.Entry.ID != b.Entry.ID) {
			t.Fatal("carousel order changed within the day", i)
		}
	}
	// The next day starts with what did not make the first day's ten.
	shown := map[string]bool{}
	for _, id := range ids(first) {
		shown[id] = true
	}
	second, err := todayWall(ctx, f.db, f.groupMate, day1.AddDate(0, 0, 1))
	if err != nil || len(second) == 0 {
		t.Fatal("day 2", err)
	}
	// The fixture member's wall holds exactly the twelve chapters, so day 2 must
	// open with the two that missed day 1.
	if len(second) != todayWallSize {
		t.Fatal("day 2 size", len(second))
	}
	for i := 0; i < 2; i++ {
		if second[i].Post == nil || shown[second[i].Post.ID] {
			t.Fatal("day 2 should lead with items not shown on day 1", i)
		}
	}

	// Unique views: once per member, never for the author.
	if ok, err := recordContentView(ctx, f.db, f.groupMate, "chapter", posts[1]); err != nil || !ok {
		t.Fatal("first view", ok, err)
	}
	if ok, _ := recordContentView(ctx, f.db, f.groupMate, "chapter", posts[1]); ok {
		t.Fatal("view counted twice")
	}
	if ok, _ := recordContentView(ctx, f.db, f.proposer, "chapter", posts[1]); ok {
		t.Fatal("author view counted")
	}
	if p, _ := readBlog(ctx, f.db, f.proposer, posts[1]); p.ViewCount != 1 {
		t.Fatal("view count", p.ViewCount)
	}

	// Cover of the Week: exclude other local photos so this test's two compete.
	var themeID string
	if err = f.db.QueryRow(`SELECT id::text FROM matching.photo_themes WHERE slug='comfort-food'`).Scan(&themeID); err != nil {
		t.Fatal(err)
	}
	placeholder := isoWeekStart(time.Date(1990, 1, 1, 0, 0, 0, 0, time.UTC))
	rows, err := f.db.Query(`SELECT id::text FROM matching.photo_theme_entries e WHERE NOT EXISTS(SELECT 1 FROM matching.photo_covers c WHERE c.entry_id=e.id)`)
	if err != nil {
		t.Fatal(err)
	}
	others := []string{}
	for rows.Next() {
		var id string
		_ = rows.Scan(&id)
		others = append(others, id)
	}
	rows.Close()
	t.Cleanup(func() {
		_, _ = f.db.Exec(`DELETE FROM matching.photo_covers WHERE week_start<'2000-01-01' OR week_start>='2099-01-01'`)
	})
	for i, id := range others {
		if _, err = f.db.Exec(`INSERT INTO matching.photo_covers(week_start,entry_id) VALUES($1,$2)`, placeholder.AddDate(0, 0, 7*i), id); err != nil {
			t.Fatal(err)
		}
	}
	upload := func(author, caption string) string {
		id := uuid.NewString()
		if rec := themeUpload(t, f.s, author, themeID, id, caption); rec.Code != 200 {
			t.Fatal("upload", rec.Code, rec.Body.String())
		}
		if _, err := setPhotoFeaturing(ctx, f.db, author, themeID, id, true); err != nil {
			t.Fatal(err)
		}
		return id
	}
	winner, runnerUp := upload(f.proposer, "Rasam on a rainy day"), upload(f.invitee, "Midnight maggi")
	for _, u := range []string{f.invitee, f.groupMate} {
		if _, err = togglePhotoLike(ctx, f.db, u, themeID, winner, true, ""); err != nil {
			t.Fatal(err)
		}
	}
	if _, err = togglePhotoLike(ctx, f.db, f.groupMate, themeID, runnerUp, true, ""); err != nil {
		t.Fatal(err)
	}
	week := isoWeekStart(time.Date(2099, 1, 7, 0, 0, 0, 0, time.UTC))
	cover, err := coverOfWeek(ctx, f.db, f.groupMate, week)
	if err != nil || cover == nil || cover.ID != winner {
		t.Fatal("cover of the week", err, cover)
	}
	if again, _ := coverOfWeek(ctx, f.db, f.invitee, week); again == nil || again.ID != winner {
		t.Fatal("cover changed within the week")
	}
	var celebrated int
	_ = f.db.QueryRow(`SELECT COUNT(*) FROM matching.wall_celebrations WHERE kind='cover' AND content_id=$1 AND author_id=$2`, winner, f.proposer).Scan(&celebrated)
	if celebrated != 1 {
		t.Fatal("cover celebration", celebrated)
	}
	// A cover never repeats: next week the runner-up gets its turn.
	if next, _ := coverOfWeek(ctx, f.db, f.groupMate, week.AddDate(0, 0, 7)); next == nil || next.ID != runnerUp {
		t.Fatal("next week's cover", next)
	}
}
