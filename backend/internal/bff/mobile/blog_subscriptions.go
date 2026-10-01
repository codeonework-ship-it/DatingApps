package mobile

import (
	"context"
	"database/sql"
	"net/http"

	"github.com/go-chi/chi/v5"
)

// Blog topics and writer subscriptions (migration 113).

type blogTopic struct {
	Slug        string `json:"slug"`
	Title       string `json:"title"`
	Description string `json:"description"`
	PostCount   int    `json:"post_count"`
}

type blogWriter struct {
	AuthorID        string `json:"author_id"`
	Name            string `json:"name"`
	SubscriberCount int    `json:"subscriber_count"`
	LatestTitle     string `json:"latest_title"`
	LatestPostID    string `json:"latest_post_id"`
}

// fillBlogSocial adds the topic and the viewer's subscription to the author.
func fillBlogSocial(ctx context.Context, q blogQuerier, actor string, p *blogPost) error {
	return q.QueryRowContext(ctx, `SELECT COALESCE(p.topic_slug,''),COALESCE(t.title,''),
 EXISTS(SELECT 1 FROM matching.blog_subscriptions s WHERE s.subscriber_id=$1::uuid AND s.author_id=p.author_id),
 (SELECT COUNT(*) FROM matching.blog_subscriptions s JOIN user_management.users u ON u.id=s.subscriber_id WHERE s.author_id=p.author_id AND `+blogActive+`)
 FROM matching.blog_posts p LEFT JOIN matching.blog_topics t ON t.slug=p.topic_slug WHERE p.id=$2::uuid`, actor, p.ID).
		Scan(&p.Topic, &p.TopicTitle, &p.AuthorSubscribed, &p.AuthorSubscribers)
}

// notifyBlogSubscribers tells subscribers who can see a newly shared chapter.
// Community chapters reach subscribers who meet the community bar; friends
// chapters reach subscribers who are accepted friends. Blocks always win.
func notifyBlogSubscribers(ctx context.Context, tx *sql.Tx, author, postID, title string) error {
	if runeLen(title) > 60 {
		title = string([]rune(title)[:57]) + "…"
	}
	_, err := tx.ExecContext(ctx, `SELECT matching.enqueue_notification(s.subscriber_id,$1::uuid,'blog.subscription.new_post','system',$2::uuid,
  'blog-sub:'||$2||':'||s.subscriber_id,'New chapter from a writer you follow',$3,'/blog',jsonb_build_object('post_id',$2),5::smallint)
 FROM matching.blog_subscriptions s JOIN matching.blog_posts p ON p.id=$2::uuid
 WHERE s.author_id=$1::uuid AND `+activityActive("s.subscriber_id")+` AND `+activityNotBlocked("s.subscriber_id", "$1::uuid")+`
  AND ((p.audience='community' AND `+activityCommunity("s.subscriber_id")+`) OR (p.audience='friends' AND matching.accepted_friends(s.subscriber_id,$1::uuid)))
 LIMIT 1000`, author, postID, "“"+title+"”")
	return err
}

func (s *Server) blogTopicsHandler(w http.ResponseWriter, r *http.Request) {
	if _, err := requestPrincipal(r); err != nil {
		writeError(w, 401, err)
		return
	}
	db, err := s.growthDB()
	if err != nil {
		writeError(w, 503, err)
		return
	}
	w.Header().Set("Cache-Control", "private, no-store")
	rows, err := db.QueryContext(r.Context(), `SELECT t.slug,t.title,t.description,
 (SELECT COUNT(*) FROM matching.blog_posts p WHERE p.topic_slug=t.slug AND p.audience='community' AND p.deleted_at IS NULL AND p.moderation_state='active')
 FROM matching.blog_topics t WHERE t.active ORDER BY t.sort_order,t.title`)
	if err != nil {
		writeActivityError(w, err, "Topics are temporarily unavailable.")
		return
	}
	defer rows.Close()
	topics := []blogTopic{}
	for rows.Next() {
		var t blogTopic
		if err = rows.Scan(&t.Slug, &t.Title, &t.Description, &t.PostCount); err != nil {
			writeActivityError(w, err, "Topics are temporarily unavailable.")
			return
		}
		topics = append(topics, t)
	}
	if err = rows.Err(); err != nil {
		writeActivityError(w, err, "Topics are temporarily unavailable.")
		return
	}
	writeJSON(w, 200, map[string]any{"topics": topics})
}

// blogWriterVisible: viewer $1 may follow writer $2 (active adults, no block,
// both meet the community bar or are accepted friends).
func blogWriterVisible() string {
	return activityActive("$1::uuid") + ` AND ` + activityActive("$2::uuid") + ` AND ` + activityNotBlocked("$1::uuid", "$2::uuid") + `
 AND ((` + activityCommunity("$1::uuid") + ` AND ` + activityCommunity("$2::uuid") + `) OR matching.accepted_friends($1::uuid,$2::uuid))`
}

func (s *Server) blogSubscriptionHandler(w http.ResponseWriter, r *http.Request) {
	actor, err := requestPrincipal(r)
	if err != nil {
		writeError(w, 401, err)
		return
	}
	authorID := chi.URLParam(r, "authorID")
	if !activityUUID(w, authorID) {
		return
	}
	db, err := s.growthDB()
	if err != nil {
		writeError(w, 503, err)
		return
	}
	w.Header().Set("Cache-Control", "private, no-store")
	subscribed, count, err := changeBlogSubscription(r.Context(), db, actor.UserID, authorID, r.Method == http.MethodPut)
	if err != nil {
		writeActivityError(w, err, "Following is temporarily unavailable.")
		return
	}
	writeJSON(w, 200, map[string]any{"subscribed": subscribed, "subscriber_count": count})
}

func changeBlogSubscription(ctx context.Context, db *sql.DB, actor, authorID string, subscribe bool) (bool, int, error) {
	if actor == authorID {
		return false, 0, activityFail(403, "You cannot follow your own chapters.")
	}
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return false, 0, err
	}
	defer tx.Rollback()
	if err = lockBlogAuthor(ctx, tx, actor); err != nil {
		return false, 0, err
	}
	if subscribe {
		var visible bool
		if err = tx.QueryRowContext(ctx, `SELECT `+blogWriterVisible(), actor, authorID).Scan(&visible); err != nil {
			return false, 0, err
		}
		if !visible {
			return false, 0, errDatePlanNotFound
		}
		result, e := tx.ExecContext(ctx, `INSERT INTO matching.blog_subscriptions(subscriber_id,author_id) VALUES($1,$2) ON CONFLICT DO NOTHING`, actor, authorID)
		if e != nil {
			return false, 0, e
		}
		if n, _ := result.RowsAffected(); n == 1 {
			if e = queueReward(ctx, tx, authorID, "subscriber_gained", authorID+":"+actor); e != nil {
				return false, 0, e
			}
			// The writer learns that someone followed, not who.
			if e = enqueueNotificationTx(ctx, tx, authorID, "", "blog.subscription.gained", "system", authorID,
				"blog-follow:"+authorID+":"+actor, "A member followed your chapters",
				"Someone wants to read what you write next.", "/blog", map[string]any{}, 6); e != nil {
				return false, 0, e
			}
		}
	} else if _, err = tx.ExecContext(ctx, `DELETE FROM matching.blog_subscriptions WHERE subscriber_id=$1 AND author_id=$2`, actor, authorID); err != nil {
		return false, 0, err
	}
	var count int
	if err = tx.QueryRowContext(ctx, `SELECT COUNT(*) FROM matching.blog_subscriptions s JOIN user_management.users u ON u.id=s.subscriber_id WHERE s.author_id=$1 AND `+blogActive, authorID).Scan(&count); err != nil {
		return false, 0, err
	}
	return subscribe, count, tx.Commit()
}

func (s *Server) blogWritersHandler(w http.ResponseWriter, r *http.Request) {
	actor, err := requestPrincipal(r)
	if err != nil {
		writeError(w, 401, err)
		return
	}
	db, err := s.growthDB()
	if err != nil {
		writeError(w, 503, err)
		return
	}
	w.Header().Set("Cache-Control", "private, no-store")
	rows, err := db.QueryContext(r.Context(), `SELECT s.author_id::text,COALESCE(u.name,''),
 (SELECT COUNT(*) FROM matching.blog_subscriptions x WHERE x.author_id=s.author_id),
 COALESCE(lp.title,''),COALESCE(lp.id::text,'')
 FROM matching.blog_subscriptions s JOIN user_management.users u ON u.id=s.author_id
 LEFT JOIN LATERAL (SELECT p.id,p.title FROM matching.blog_posts p WHERE p.author_id=s.author_id AND p.deleted_at IS NULL
   AND p.moderation_state='active' AND p.audience<>'private' ORDER BY p.published_at DESC NULLS LAST LIMIT 1) lp ON TRUE
 WHERE s.subscriber_id=$1 AND `+blogActive+` AND `+activityNotBlocked("$1::uuid", "s.author_id")+`
 ORDER BY s.created_at DESC LIMIT 200`, actor.UserID)
	if err != nil {
		writeActivityError(w, err, "Following is temporarily unavailable.")
		return
	}
	defer rows.Close()
	writers := []blogWriter{}
	for rows.Next() {
		var item blogWriter
		if err = rows.Scan(&item.AuthorID, &item.Name, &item.SubscriberCount, &item.LatestTitle, &item.LatestPostID); err != nil {
			writeActivityError(w, err, "Following is temporarily unavailable.")
			return
		}
		writers = append(writers, item)
	}
	if err = rows.Err(); err != nil {
		writeActivityError(w, err, "Following is temporarily unavailable.")
		return
	}
	writeJSON(w, 200, map[string]any{"writers": writers})
}
