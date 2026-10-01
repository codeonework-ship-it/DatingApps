package mobile

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/google/uuid"
)

func TestBlogLikesCommentsAndFeaturingPostgres(t *testing.T) {
	f := newBlogTrustFixture(t)
	var ready bool
	if err := f.db.QueryRow(`SELECT to_regclass('matching.blog_comments') IS NOT NULL`).Scan(&ready); err != nil || !ready {
		t.Skip("migration 108_blog_likes_comments_featuring is not applied")
	}
	// Tier 1 reaches one wall (the author's friend comes first); tier 2
	// reaches every eligible member.
	t.Setenv("BLOG_WALL_TIERS", "2:1:1,3:1:100000")
	ctx := context.Background()
	s := blogServer(f)
	blogEligible(t, f, f.proposer)
	blogEligible(t, f, f.invitee)
	blogEligible(t, f, f.groupMate)
	blogEligible(t, f, f.proposerFriend)
	post, err := saveBlog(ctx, f.db, f.proposer, uuid.NewString(), blogDraft{Title: "Sunday bookshop", Body: "A long walk and an old bookshop.", Audience: "community", AllowFeaturing: true})
	if err != nil || !post.AllowFeaturing {
		t.Fatal("save with featuring", err, post.AllowFeaturing)
	}
	featured := func(user string) []any {
		rec := httptest.NewRecorder()
		s.blogFeaturedHandler(rec, blogRoute(http.MethodGet, user, "", nil))
		if rec.Code != 200 {
			t.Fatal("featured", rec.Code, rec.Body.String())
		}
		var out map[string]any
		_ = json.Unmarshal(rec.Body.Bytes(), &out)
		return out["posts"].([]any)
	}

	if _, err = toggleBlogLike(ctx, f.db, f.proposer, post.ID, true, ""); err == nil {
		t.Fatal("author liked their own chapter")
	}
	p, err := toggleBlogLike(ctx, f.db, f.invitee, post.ID, true, "")
	if err != nil || p.LikeCount != 1 || !p.LikedByMe {
		t.Fatal("like", err, p.LikeCount, p.LikedByMe)
	}
	if p, err = toggleBlogLike(ctx, f.db, f.invitee, post.ID, true, ""); err != nil || p.LikeCount != 1 {
		t.Fatal("repeat like not idempotent", err, p.LikeCount)
	}
	if p.MyReaction != "love" || p.Reactions["love"] != 1 {
		t.Fatal("a plain like is the love reaction", p.MyReaction, p.Reactions)
	}
	// Empathetic reactions: changing how you reacted stays one like.
	if p, err = toggleBlogLike(ctx, f.db, f.invitee, post.ID, true, "hear_you"); err != nil ||
		p.LikeCount != 1 || p.MyReaction != "hear_you" || p.Reactions["hear_you"] != 1 || p.Reactions["love"] != 0 {
		t.Fatal("change reaction", err, p.LikeCount, p.MyReaction, p.Reactions)
	}
	// A plain like (no reaction) keeps the reaction the member chose.
	if p, err = toggleBlogLike(ctx, f.db, f.invitee, post.ID, true, ""); err != nil || p.MyReaction != "hear_you" {
		t.Fatal("plain re-like replaced the reaction", err, p.MyReaction)
	}
	bad := httptest.NewRecorder()
	s.blogLikeHandler(bad, blogRoute(http.MethodPut, f.invitee, `{"reaction":"meh"}`, map[string]string{"postID": post.ID}))
	if bad.Code != 400 {
		t.Fatal("unknown reaction accepted", bad.Code, bad.Body.String())
	}
	good := httptest.NewRecorder()
	s.blogLikeHandler(good, blogRoute(http.MethodPut, f.invitee, `{"reaction":"with_you"}`, map[string]string{"postID": post.ID}))
	if good.Code != 200 || !strings.Contains(good.Body.String(), `"my_reaction":"with_you"`) {
		t.Fatal("reaction over HTTP", good.Code, good.Body.String())
	}
	if p, err = readBlog(ctx, f.db, f.proposer, post.ID); err != nil || p.Reactions["with_you"] != 1 || p.MyReaction != "" || p.LikeCount != 1 {
		t.Fatal("author sees the reaction summary", err, p.Reactions, p.MyReaction, p.LikeCount)
	}
	if _, err = toggleBlogLike(ctx, f.db, f.stranger, post.ID, true, ""); err == nil {
		t.Fatal("member below the community bar liked")
	}
	if p, err = toggleBlogLike(ctx, f.db, f.groupMate, post.ID, true, ""); err != nil || p.LikeCount != 2 || p.Featured {
		t.Fatal("second like", err, p.LikeCount, p.Featured)
	}

	// Comments wait for the author.
	commentID := uuid.NewString()
	c, err := changeBlogComment(ctx, f.db, f.invitee, post.ID, commentID, http.MethodPut, "", map[string]any{"body": "Which bookshop? I want to go."})
	if err != nil || c.Status != "pending" || !c.Mine {
		t.Fatal("comment", err, c)
	}
	if again, retryErr := changeBlogComment(ctx, f.db, f.invitee, post.ID, commentID, http.MethodPut, "", map[string]any{"body": "Which bookshop? I want to go."}); retryErr != nil || again.ID != commentID {
		t.Fatal("comment retry", retryErr)
	}
	visibleComments := func(user string) int {
		rows, qErr := f.db.Query(blogCommentSelect(), user, post.ID)
		if qErr != nil {
			t.Fatal(qErr)
		}
		defer rows.Close()
		n := 0
		for rows.Next() {
			n++
		}
		return n
	}
	if visibleComments(f.groupMate) != 0 || visibleComments(f.proposer) != 1 {
		t.Fatal("pending comment visibility")
	}
	if p, _ = readBlog(ctx, f.db, f.proposer, post.ID); p.PendingCommentCount != 1 {
		t.Fatal("author pending count", p.PendingCommentCount)
	}
	if _, err = changeBlogComment(ctx, f.db, f.groupMate, post.ID, commentID, http.MethodPost, "approve", nil); err == nil {
		t.Fatal("non-author approved a comment")
	}
	if _, err = changeBlogComment(ctx, f.db, f.proposer, post.ID, commentID, http.MethodPost, "approve", nil); err != nil {
		t.Fatal("approve", err)
	}
	if visibleComments(f.groupMate) != 1 {
		t.Fatal("approved comment hidden from readers")
	}

	// Two likes and one approved comment reach tier 1: one wall, a friend first.
	if len(featured(f.proposerFriend)) != 1 || len(featured(f.groupMate)) != 0 {
		t.Fatal("tier 1 reach should go to the author's friend only")
	}
	author, _ := readBlog(ctx, f.db, f.proposer, post.ID)
	if author.WallReach != 1 || author.NextTier == nil || author.NextTier.LikesNeeded != 1 || author.NextTier.Reach != 100000 {
		t.Fatal("author progress", author.WallReach, author.NextTier)
	}
	if reader, _ := readBlog(ctx, f.db, f.groupMate, post.ID); reader.NextTier != nil {
		t.Fatal("next tier leaked to a reader")
	}
	// A third like reaches tier 2: every eligible member.
	if _, err = toggleBlogLike(ctx, f.db, f.proposerFriend, post.ID, true, ""); err != nil {
		t.Fatal(err)
	}
	if len(featured(f.groupMate)) != 1 {
		t.Fatal("tier 2 did not widen reach")
	}
	if author, _ = readBlog(ctx, f.db, f.proposer, post.ID); author.WallReach < 3 || author.NextTier != nil {
		t.Fatal("tier 2 reach", author.WallReach, author.NextTier)
	}
	var notified int
	_ = f.db.QueryRow(`SELECT COUNT(*) FROM matching.notification_outbox WHERE recipient_user_id=$1 AND event_type='blog.post.featured'`, f.proposer).Scan(&notified)
	if notified != 2 {
		t.Fatal("author should hear about each tier once", notified)
	}
	// Rose rain: both tiers were recorded, only the highest unseen one plays.
	celebrations := func(user string) []any {
		rec := httptest.NewRecorder()
		s.wallCelebrationsHandler(rec, blogRoute(http.MethodGet, user, "", nil))
		var out map[string]any
		_ = json.Unmarshal(rec.Body.Bytes(), &out)
		items, _ := out["celebrations"].([]any)
		return items
	}
	var recorded int
	_ = f.db.QueryRow(`SELECT COUNT(*) FROM matching.wall_celebrations WHERE content_id=$1`, post.ID).Scan(&recorded)
	pending := celebrations(f.proposer)
	if recorded != 2 || len(pending) != 1 || pending[0].(map[string]any)["tier"] != 2.0 || pending[0].(map[string]any)["kind"] != "chapter" {
		t.Fatal("celebrations", recorded, pending)
	}
	if len(celebrations(f.groupMate)) != 0 {
		t.Fatal("celebration leaked to a reader")
	}
	celebrationID := pending[0].(map[string]any)["id"].(string)
	for _, user := range []string{f.groupMate, f.proposer, f.proposer} {
		rec := httptest.NewRecorder()
		s.wallCelebrationsHandler(rec, blogRoute(http.MethodPost, user, "", map[string]string{"celebrationID": celebrationID}))
		if want := map[bool]int{true: 200, false: 404}[user == f.proposer]; rec.Code != want {
			t.Fatal("seen", user == f.proposer, rec.Code)
		}
	}
	if len(celebrations(f.proposer)) != 0 {
		t.Fatal("seen celebration played again")
	}

	// An open report pauses featuring; dismissing it brings the chapter back.
	caseID, err := createBlogCase(ctx, f.db, f.groupMate, "post", post.ID, "inappropriate", "")
	if err != nil {
		t.Fatal(err)
	}
	if len(featured(f.groupMate)) != 0 {
		t.Fatal("reported chapter stayed featured")
	}
	if err = decideBlogCase(ctx, f.db, f.stranger, caseID, "dismissed", "No violation found", 1); err != nil {
		t.Fatal(err)
	}
	if len(featured(f.groupMate)) != 1 {
		t.Fatal("dismissed report did not restore featuring")
	}

	// Opting out removes it at once.
	current, _ := readBlog(ctx, f.db, f.proposer, post.ID)
	if _, err = saveBlog(ctx, f.db, f.proposer, post.ID, blogDraft{Title: current.Title, Body: current.Body, Audience: "community", Version: current.Version, AllowFeaturing: false}); err != nil {
		t.Fatal(err)
	}
	if len(featured(f.groupMate)) != 0 {
		t.Fatal("opted-out chapter still featured")
	}

	// A reported comment can be removed by moderators.
	commentCase, err := createBlogCase(ctx, f.db, f.groupMate, "comment", commentID, "harassment", "")
	if err != nil {
		t.Fatal("report comment", err)
	}
	if err = decideBlogCase(ctx, f.db, f.stranger, commentCase, "removed", "Removed after review", 1); err != nil {
		t.Fatal(err)
	}
	if visibleComments(f.groupMate) != 0 || visibleComments(f.invitee) != 1 {
		t.Fatal("removed comment visibility")
	}

	if p, err = toggleBlogLike(ctx, f.db, f.invitee, post.ID, false, ""); err != nil || p.LikeCount != 2 || p.LikedByMe {
		t.Fatal("unlike", err, p.LikeCount)
	}
}
