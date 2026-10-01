package mobile

import (
	"context"
	"database/sql"
	"errors"
	"net/http"

	"github.com/go-chi/chi/v5"
)

// Chapter likes, author-approved comments and wall reach (migrations 108,
// 109). The rules live in wall_engine.go; this file binds them to chapters.

// blogWallAllowedSQL: chapter alias p may be on walls right now.
func blogWallAllowedSQL() string {
	return `(p.audience='community' AND p.allow_featuring AND p.moderation_state='active' AND p.deleted_at IS NULL
 AND NOT EXISTS(SELECT 1 FROM matching.blog_cases bc WHERE bc.content_type='post' AND bc.content_id=p.id AND bc.status='pending'))`
}

var blogWall = wallSpec{
	Noun:        "chapter",
	Content:     "matching.blog_posts",
	Likes:       "matching.blog_likes",
	Comments:    "matching.blog_comments",
	Deliveries:  "matching.blog_wall_deliveries",
	FK:          "post_id",
	OwnerCol:    "post_author_id",
	TitleCol:    "title",
	EventPrefix: "blog.post",
	Route:       "/blog",
	Allowed:     blogWallAllowedSQL,
}

type blogComment = wallComment

func blogLikesSQL(post string) string            { return blogWall.likesSQL(post) }
func blogApprovedCommentsSQL(post string) string { return blogWall.approvedCommentsSQL(post) }
func blogFeaturedSQL() string                    { return blogWall.featuredSQL() }
func blogCommentSelect() string                  { return blogWall.commentSelect() }

// fillBlogEngagement adds counts, reach and the author's next tier.
func fillBlogEngagement(ctx context.Context, q blogQuerier, actor string, p *blogPost) error {
	e, err := blogWall.engagement(ctx, q, actor, p.ID)
	if err != nil {
		return err
	}
	p.ViewCount, p.LikeCount, p.LikedByMe = e.ViewCount, e.LikeCount, e.LikedByMe
	p.MyReaction, p.Reactions = e.MyReaction, e.Reactions
	p.CommentCount, p.PendingCommentCount = e.CommentCount, e.PendingCommentCount
	p.AllowFeaturing, p.Featured, p.WallReach, p.NextTier = e.AllowFeaturing, e.Featured, e.WallReach, e.NextTier
	return nil
}

func maybeFeature(ctx context.Context, tx *sql.Tx, postID string) error {
	return blogWall.advance(ctx, tx, postID)
}

// readableEngagementPost loads a post the actor can see and may react to.
func readableEngagementPost(ctx context.Context, q blogQuerier, actor, postID string) (blogPost, error) {
	p, err := readBlog(ctx, q, actor, postID)
	if err != nil {
		return p, err
	}
	if p.AuthorID == actor {
		return p, activityFail(403, "You cannot like or comment on your own chapter.")
	}
	if p.Audience == "private" || p.Moderation != "active" {
		return p, errDatePlanNotFound
	}
	return p, nil
}

func (s *Server) blogLikeHandler(w http.ResponseWriter, r *http.Request) {
	actor, err := requestPrincipal(r)
	if err != nil {
		writeError(w, 401, err)
		return
	}
	postID := chi.URLParam(r, "postID")
	if !activityUUID(w, postID) {
		return
	}
	db, err := s.growthDB()
	if err != nil {
		writeError(w, 503, err)
		return
	}
	reaction, ok := readWallReaction(w, r)
	if !ok {
		return
	}
	w.Header().Set("Cache-Control", "private, no-store")
	p, err := toggleBlogLike(r.Context(), db, actor.UserID, postID, r.Method == http.MethodPut, reaction)
	if err != nil {
		writeActivityError(w, err, "Chapters are temporarily unavailable. Please retry.")
		return
	}
	writeJSON(w, 200, map[string]any{"post": p})
}

func toggleBlogLike(ctx context.Context, db *sql.DB, actor, postID string, like bool, reaction string) (blogPost, error) {
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return blogPost{}, err
	}
	defer tx.Rollback()
	if err = lockBlogAuthor(ctx, tx, actor); err != nil {
		return blogPost{}, err
	}
	if _, err = readableEngagementPost(ctx, tx, actor, postID); err != nil {
		return blogPost{}, err
	}
	if err = blogWall.like(ctx, tx, actor, postID, like, reaction); err != nil {
		return blogPost{}, err
	}
	p, err := readBlog(ctx, tx, actor, postID)
	if err != nil {
		return p, err
	}
	return p, tx.Commit()
}

func readBlogComment(ctx context.Context, q blogQuerier, actor, postID, commentID string) (blogComment, error) {
	return blogWall.readComment(ctx, q, actor, postID, commentID)
}

func (s *Server) blogCommentsHandler(w http.ResponseWriter, r *http.Request) {
	s.serveBlogComments(w, r, false)
}

func (s *Server) blogCommentDecisionHandler(w http.ResponseWriter, r *http.Request) {
	s.serveBlogComments(w, r, true)
}

func (s *Server) serveBlogComments(w http.ResponseWriter, r *http.Request, decisionRoute bool) {
	actor, err := requestPrincipal(r)
	if err != nil {
		writeError(w, 401, err)
		return
	}
	postID, commentID := chi.URLParam(r, "postID"), chi.URLParam(r, "commentID")
	if !activityUUID(w, postID) || (commentID != "" && !activityUUID(w, commentID)) {
		return
	}
	db, err := s.growthDB()
	if err != nil {
		writeError(w, 503, err)
		return
	}
	w.Header().Set("Cache-Control", "private, no-store")
	const unavailable = "Comments are temporarily unavailable. Please retry."
	if r.Method == http.MethodGet && commentID == "" {
		if _, err = readBlog(r.Context(), db, actor.UserID, postID); err != nil {
			writeActivityError(w, err, unavailable)
			return
		}
		comments, e := blogWall.listComments(r.Context(), db, actor.UserID, postID)
		if e != nil {
			writeActivityError(w, e, unavailable)
			return
		}
		writeJSON(w, 200, map[string]any{"comments": comments})
		return
	}
	var body map[string]any
	if r.Method != http.MethodDelete {
		var ok bool
		if body, ok = readJSON(w, r); !ok {
			return
		}
	}
	decision := ""
	if decisionRoute {
		if decision = toString(body["decision"]); decision == "" {
			writeError(w, 400, errors.New("Choose approve or decline"))
			return
		}
	}
	c, err := changeBlogComment(r.Context(), db, actor.UserID, postID, commentID, r.Method, decision, body)
	if err != nil {
		writeActivityError(w, err, unavailable)
		return
	}
	if r.Method == http.MethodDelete {
		writeJSON(w, 200, map[string]any{"deleted": true})
		return
	}
	writeJSON(w, 200, map[string]any{"comment": c})
}

func changeBlogComment(ctx context.Context, db *sql.DB, actor, postID, commentID, method, decision string, body map[string]any) (blogComment, error) {
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return blogComment{}, err
	}
	defer tx.Rollback()
	if err = lockBlogAuthor(ctx, tx, actor); err != nil {
		return blogComment{}, err
	}
	post, err := readBlog(ctx, tx, actor, postID)
	if err != nil {
		return blogComment{}, err
	}
	c, err := blogWall.changeComment(ctx, tx, actor, postID, commentID, method, decision, body, post.AuthorID, post.Title, func() error {
		_, e := readableEngagementPost(ctx, tx, actor, postID)
		return e
	})
	if err != nil {
		return c, err
	}
	return c, tx.Commit()
}

func (s *Server) blogFeaturedHandler(w http.ResponseWriter, r *http.Request) {
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
	posts, err := blogWallPosts(r.Context(), db, actor.UserID)
	if err != nil {
		writeActivityError(w, err, "Your wall is temporarily unavailable. Please retry.")
		return
	}
	writeJSON(w, 200, map[string]any{"posts": posts})
}

// blogWallPosts lists chapters delivered to the member's wall, newest first.
func blogWallPosts(ctx context.Context, db *sql.DB, actor string) ([]blogPost, error) {
	tx, err := db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelRepeatableRead, ReadOnly: true})
	if err != nil {
		return nil, err
	}
	defer tx.Rollback()
	rows, err := tx.QueryContext(ctx, blogSelect+` AND `+blogWall.featuredSQL()+` AND `+blogWall.deliveredToSQL()+`
 ORDER BY `+blogWall.deliveredAtSQL()+` DESC,p.id LIMIT 20`, actor)
	if err != nil {
		return nil, err
	}
	ids := []string{}
	for rows.Next() {
		p, scanErr := scanBlog(rows)
		if scanErr != nil {
			rows.Close()
			return nil, scanErr
		}
		ids = append(ids, p.ID)
	}
	err = rows.Err()
	rows.Close()
	if err != nil {
		return nil, err
	}
	posts := make([]blogPost, 0, len(ids))
	for _, id := range ids {
		p, readErr := readBlog(ctx, tx, actor, id)
		if readErr != nil {
			return nil, readErr
		}
		posts = append(posts, p)
	}
	return posts, nil
}

// readCommentForReport captures a chapter comment the reporter can see.
func readCommentForReport(ctx context.Context, q blogQuerier, actor, commentID string) (string, any, error) {
	var postID string
	if err := q.QueryRowContext(ctx, `SELECT post_id::text FROM matching.blog_comments WHERE id=$1`, commentID).Scan(&postID); err != nil {
		return "", nil, errDatePlanNotFound
	}
	post, err := readBlog(ctx, q, actor, postID)
	if err != nil {
		return "", nil, err
	}
	c, err := readBlogComment(ctx, q, actor, postID, commentID)
	if err != nil {
		return "", nil, err
	}
	return c.AuthorID, map[string]any{"title": "Comment on · " + post.Title, "text": c.Body}, nil
}
