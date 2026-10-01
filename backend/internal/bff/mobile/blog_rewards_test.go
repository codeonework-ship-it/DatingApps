package mobile

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/google/uuid"
)

func init() {
	// A progression worker may share the test database; never let it grant
	// real XP for test members (the XP ledger is append-only).
	rewardAvailableAfter = time.Hour
}

func TestBlogTopicsTopFollowingAndRewardsPostgres(t *testing.T) {
	f := newBlogTrustFixture(t)
	var ready bool
	if err := f.db.QueryRow(`SELECT to_regclass('matching.blog_subscriptions') IS NOT NULL`).Scan(&ready); err != nil || !ready {
		t.Skip("migration 113_blog_topics_subscriptions_rewards is not applied")
	}
	t.Setenv("BLOG_WALL_TIERS", "50:5:50")
	ctx := context.Background()
	s := blogServer(f)
	for _, u := range []string{f.proposer, f.invitee, f.groupMate} {
		blogEligible(t, f, u)
	}
	rewards := func(user, source string) int {
		var n int
		_ = f.db.QueryRow(`SELECT COUNT(*) FROM progression.xp_award_repair_queue WHERE user_id=$1 AND source=$2`, user, source).Scan(&n)
		return n
	}

	// Following: not yourself, not when invisible, rewarded once per follower.
	if _, _, err := changeBlogSubscription(ctx, f.db, f.proposer, f.proposer, true); err == nil {
		t.Fatal("followed self")
	}
	if _, _, err := changeBlogSubscription(ctx, f.db, f.stranger, f.proposer, true); err == nil {
		t.Fatal("member below the community bar followed")
	}
	for i := 0; i < 2; i++ {
		if ok, count, err := changeBlogSubscription(ctx, f.db, f.invitee, f.proposer, true); err != nil || !ok || count != 1 {
			t.Fatal("follow", ok, count, err)
		}
	}
	if rewards(f.proposer, "subscriber_gained") != 1 {
		t.Fatal("follower reward should be queued exactly once")
	}

	// Topics validate, and publishing rewards the author and tells followers.
	if _, err := saveBlog(ctx, f.db, f.proposer, uuid.NewString(), blogDraft{Title: "x", Body: "y", Audience: "community", Topic: "astrology"}); err == nil {
		t.Fatal("unknown topic accepted")
	}
	first, err := saveBlog(ctx, f.db, f.proposer, uuid.NewString(), blogDraft{Title: "What grief taught me", Body: "Slowly, and then all at once.", Audience: "community", Topic: "feelings"})
	if err != nil || first.Topic != "feelings" || first.TopicTitle != "Feelings & healing" || first.AuthorSubscribers != 1 {
		t.Fatal("publish with topic", err, first.Topic, first.TopicTitle, first.AuthorSubscribers)
	}
	second, err := saveBlog(ctx, f.db, f.proposer, uuid.NewString(), blogDraft{Title: "Letters I never sent", Body: "Some words are for you only.", Audience: "community", Topic: "feelings"})
	if err != nil {
		t.Fatal(err)
	}
	if rewards(f.proposer, "story_published") != 2 {
		t.Fatal("publish rewards", rewards(f.proposer, "story_published"))
	}
	var notified int
	_ = f.db.QueryRow(`SELECT COUNT(*) FROM matching.notification_outbox WHERE recipient_user_id=$1 AND event_type='blog.subscription.new_post'`, f.invitee).Scan(&notified)
	if notified != 2 {
		t.Fatal("followers should hear about each new chapter", notified)
	}
	if viewer, _ := readBlog(ctx, f.db, f.invitee, first.ID); !viewer.AuthorSubscribed {
		t.Fatal("reader should see they follow the author")
	}

	// Likes reward the author once per member; Top ranks by likes.
	for _, u := range []string{f.invitee, f.groupMate} {
		if _, err = toggleBlogLike(ctx, f.db, u, second.ID, true, ""); err != nil {
			t.Fatal(err)
		}
	}
	_, _ = toggleBlogLike(ctx, f.db, f.invitee, second.ID, false, "")
	_, _ = toggleBlogLike(ctx, f.db, f.invitee, second.ID, true, "")
	// Changing a reaction is not a new like and earns nothing.
	_, _ = toggleBlogLike(ctx, f.db, f.groupMate, second.ID, true, "proud")
	_, _ = toggleBlogLike(ctx, f.db, f.groupMate, second.ID, true, "hug")
	if _, err = toggleBlogLike(ctx, f.db, f.groupMate, first.ID, true, ""); err != nil {
		t.Fatal(err)
	}
	if rewards(f.proposer, "like_received") != 3 {
		t.Fatal("like rewards must not repeat on re-like", rewards(f.proposer, "like_received"))
	}
	feed := func(user, query string) []any {
		r := blogRoute(http.MethodGet, user, "", nil)
		r.URL.RawQuery = query
		rec := httptest.NewRecorder()
		s.blogPostsHandler(rec, r)
		if rec.Code != 200 {
			t.Fatal("feed", query, rec.Code, rec.Body.String())
		}
		var out map[string]any
		_ = json.Unmarshal(rec.Body.Bytes(), &out)
		return out["posts"].([]any)
	}
	// Other members' chapters (local demo data) may share the topic; rank
	// only this author's.
	top := []any{}
	for _, p := range feed(f.groupMate, "scope=top&topic=feelings") {
		if p.(map[string]any)["author_id"] == f.proposer {
			top = append(top, p)
		}
	}
	if len(top) != 2 || top[0].(map[string]any)["id"] != second.ID {
		t.Fatal("top rated order", top)
	}
	if following := feed(f.invitee, "scope=subscriptions"); len(following) != 2 {
		t.Fatal("following feed", len(following))
	}
	if following := feed(f.groupMate, "scope=subscriptions"); len(following) != 0 {
		t.Fatal("following feed for a non-follower", len(following))
	}

	// Approving a comment rewards both sides once.
	commentID := uuid.NewString()
	if _, err = changeBlogComment(ctx, f.db, f.groupMate, first.ID, commentID, http.MethodPut, "", map[string]any{"body": "Thank you for writing this."}); err != nil {
		t.Fatal(err)
	}
	if _, err = changeBlogComment(ctx, f.db, f.proposer, first.ID, commentID, http.MethodPost, "approve", nil); err != nil {
		t.Fatal(err)
	}
	if rewards(f.groupMate, "comment_approved") != 1 || rewards(f.proposer, "comment_received") != 1 {
		t.Fatal("comment rewards")
	}

	// Unfollow stops the feed.
	if ok, count, err := changeBlogSubscription(ctx, f.db, f.invitee, f.proposer, false); err != nil || ok || count != 0 {
		t.Fatal("unfollow", ok, count, err)
	}
	if following := feed(f.invitee, "scope=subscriptions"); len(following) != 0 {
		t.Fatal("feed after unfollow", len(following))
	}
}
