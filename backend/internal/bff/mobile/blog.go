package mobile

import (
	"context"
	"database/sql"
	"errors"
	"net/http"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)

type blogPhoto struct {
	ID  string `json:"id"`
	Alt string `json:"alt_text"`
}
type blogPost struct {
	ID         string `json:"id"`
	AuthorID   string `json:"author_id"`
	AuthorName string `json:"author_name"`
	Title      string `json:"title"`
	Body       string `json:"body"`
	// Content is the formatted chapter (rich_text.go), or null for plain-text
	// chapters. Body is always its derived plain text.
	Content    *richDoc    `json:"content"`
	Audience   string      `json:"audience"`
	Invitation string      `json:"invitation"`
	Version    int         `json:"version"`
	Moderation string      `json:"moderation_state"`
	Created    time.Time   `json:"created_at"`
	Updated    time.Time   `json:"updated_at"`
	Photos     []blogPhoto `json:"photos"`
	// Engagement and Featured Stories (migration 108).
	ViewCount           int            `json:"view_count"`
	LikeCount           int            `json:"like_count"`
	LikedByMe           bool           `json:"liked_by_me"`
	MyReaction          string         `json:"my_reaction"`
	Reactions           map[string]int `json:"reactions"`
	CommentCount        int            `json:"comment_count"`
	PendingCommentCount int            `json:"pending_comment_count"`
	AllowFeaturing      bool           `json:"allow_featuring"`
	Topic               string         `json:"topic"`
	TopicTitle          string         `json:"topic_title"`
	AuthorSubscribed    bool           `json:"author_subscribed"`
	AuthorSubscribers   int            `json:"author_subscriber_count"`
	Featured            bool           `json:"featured"`
	WallReach           int            `json:"wall_reach"`
	NextTier            *blogNextTier  `json:"next_tier"`
}
type blogDraft struct {
	Title, Body, Audience, Invitation string
	Version                           int
	AllowFeaturing                    bool
	Topic                             string
	Content                           *richDoc
}

// Shared by list, detail and image reads. Each side must be an active adult
// dating member. Friendship never implies publication of private drafts.
const blogActive = `u.is_active AND NOT u.is_banned AND u.account_kind='dating'
 AND u.deactivated_at IS NULL AND u.erased_at IS NULL AND u.deletion_requested_at IS NULL
 AND (u.suspended_at IS NULL OR (u.suspended_until IS NOT NULL AND u.suspended_until<=NOW()))
 AND u.date_of_birth <= (CURRENT_DATE - interval '18 years')::date
 AND NOT EXISTS(SELECT 1 FROM user_management.auth_credentials ac WHERE ac.user_id=u.id AND ac.is_disabled)`
const blogVisible = `p.deleted_at IS NULL
 AND EXISTS(SELECT 1 FROM user_management.users u WHERE u.id=$1::uuid AND ` + blogActive + `)
 AND EXISTS(SELECT 1 FROM user_management.users u WHERE u.id=p.author_id AND ` + blogActive + `)
 AND (p.author_id=$1::uuid OR (p.moderation_state='active' AND 
  NOT EXISTS(SELECT 1 FROM user_management.blocked_users b WHERE
   (b.user_id=$1::uuid AND b.blocked_user_id=p.author_id) OR (b.user_id=p.author_id AND b.blocked_user_id=$1::uuid))
  AND ((p.audience='friends' AND matching.accepted_friends($1::uuid,p.author_id)) OR
   (p.audience='community' AND EXISTS(SELECT 1 FROM user_management.users u WHERE u.id=p.author_id AND u.profile_completion=100
      AND (SELECT COUNT(*) FROM user_management.photos ph WHERE ph.user_id=u.id AND ph.deleted_at IS NULL AND ph.lifecycle_status='active' AND ph.moderation_status='approved')>=2)
      AND EXISTS(SELECT 1 FROM user_management.users v WHERE v.id=$1::uuid AND v.profile_completion=100 AND (SELECT COUNT(*) FROM user_management.photos vp WHERE vp.user_id=v.id AND vp.deleted_at IS NULL AND vp.lifecycle_status='active' AND vp.moderation_status='approved')>=2)))
 ))`
const blogSelect = `SELECT p.id::text,p.author_id::text,COALESCE(u.name,''),p.title,p.body,p.audience,p.invitation,p.version,p.created_at,p.updated_at,p.moderation_state,p.content
 FROM matching.blog_posts p JOIN user_management.users u ON u.id=p.author_id WHERE ` + blogVisible

func parseBlogDraft(body map[string]any) (blogDraft, error) {
	d := blogDraft{Title: strings.TrimSpace(toString(body["title"])), Body: strings.TrimSpace(toString(body["body"])), Audience: toString(body["audience"]), Invitation: toString(body["invitation"])}
	version, ok := body["expected_version"].(float64)
	if !ok || version < 0 || version > 2147483646 || version != float64(int(version)) {
		return d, errors.New("expected_version must be a non-negative integer")
	}
	d.Version = int(version)
	d.Topic = strings.TrimSpace(toString(body["topic"]))
	// Formatted clients send content; the stored body is always derived from it
	// so search, excerpts and older clients read the same words. Clients that
	// send only body keep working and save a plain-text chapter.
	content, err := parseRichDoc(body["content"], blogRichLimits)
	if err != nil {
		return d, err
	}
	if content != nil {
		d.Content = content
		d.Body = strings.TrimSpace(richPlainText(content))
	}
	// Featuring is opt-in and only meaningful for community chapters.
	if allow, isBool := body["allow_featuring"].(bool); isBool {
		d.AllowFeaturing = allow && d.Audience == "community"
	}
	if utf8.RuneCountInString(d.Title) > 100 || utf8.RuneCountInString(d.Body) > 8000 {
		return d, errors.New("Use up to 100 characters for the title and 8,000 for the story")
	}
	if d.Audience != "private" && d.Audience != "friends" && d.Audience != "community" {
		return d, errors.New("Choose Only me, Friends or Connect community")
	}
	if d.Invitation != "" && d.Invitation != "your_version" && d.Invitation != "teach_me" && d.Invitation != "what_next" {
		return d, errors.New("Choose an available invitation")
	}
	if d.Audience != "private" && (d.Title == "" || d.Body == "") {
		return d, errors.New("Add a title and story before publishing")
	}
	return d, nil
}

func scanBlog(row interface{ Scan(...any) error }) (blogPost, error) {
	p := blogPost{Photos: []blogPhoto{}}
	var content []byte
	err := row.Scan(&p.ID, &p.AuthorID, &p.AuthorName, &p.Title, &p.Body, &p.Audience, &p.Invitation, &p.Version, &p.Created, &p.Updated, &p.Moderation, &content)
	if errors.Is(err, sql.ErrNoRows) {
		return p, errDatePlanNotFound
	}
	p.Content = decodeStoredRichDoc(content)
	return p, err
}

type blogQuerier interface {
	QueryRowContext(context.Context, string, ...any) *sql.Row
	QueryContext(context.Context, string, ...any) (*sql.Rows, error)
}

func readBlog(ctx context.Context, q blogQuerier, actor, id string) (blogPost, error) {
	p, err := scanBlog(q.QueryRowContext(ctx, blogSelect+` AND p.id=$2::uuid`, actor, id))
	if err != nil {
		return p, err
	}
	rows, err := q.QueryContext(ctx, `SELECT id::text,alt_text FROM matching.blog_photos WHERE post_id=$1 AND deleted_at IS NULL AND moderation_status='approved' ORDER BY created_at,id`, id)
	if err != nil {
		return p, err
	}
	defer rows.Close()
	for rows.Next() {
		var ph blogPhoto
		if err := rows.Scan(&ph.ID, &ph.Alt); err != nil {
			return p, err
		}
		p.Photos = append(p.Photos, ph)
	}
	if err = rows.Err(); err != nil {
		return p, err
	}
	rows.Close()
	if err = fillBlogEngagement(ctx, q, actor, &p); err != nil {
		return p, err
	}
	return p, fillBlogSocial(ctx, q, actor, &p)
}
// lockBlogAuthor serialises one member's writes and checks they are active.
// FOR NO KEY UPDATE, not FOR UPDATE: it still excludes the member's other
// writes, an account update and a delete, but lets another member's
// transaction insert rows that reference this member (a foreign key check takes
// FOR KEY SHARE). With FOR UPDATE two members friending each other at the same
// moment deadlocked on each other's users row (API-09).
func lockBlogAuthor(ctx context.Context, tx *sql.Tx, actor string) error {
	var id string
	err := tx.QueryRowContext(ctx, `SELECT u.id::text FROM user_management.users u WHERE u.id=$1 AND `+blogActive+` FOR NO KEY UPDATE`, actor).Scan(&id)
	if errors.Is(err, sql.ErrNoRows) {
		return errDatePlanForbidden
	}
	return err
}
func saveBlog(ctx context.Context, db *sql.DB, actor, id string, d blogDraft) (blogPost, error) {
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return blogPost{}, err
	}
	defer tx.Rollback()
	if err = lockBlogAuthor(ctx, tx, actor); err != nil {
		return blogPost{}, err
	}
	created := false
	existing, err := scanBlog(tx.QueryRowContext(ctx, blogSelect+` AND p.id=$2 FOR UPDATE OF p`, actor, id))
	if errors.Is(err, errDatePlanNotFound) {
		if d.Version != 0 {
			return blogPost{}, errDatingConflict
		}
		var count int
		if err = tx.QueryRowContext(ctx, `SELECT COUNT(*) FROM matching.blog_posts WHERE author_id=$1 AND deleted_at IS NULL`, actor).Scan(&count); err != nil {
			return blogPost{}, err
		}
		if count >= 100 {
			return blogPost{}, blogInputError("Your journal has reached its 100-post limit")
		}
		if _, err = tx.ExecContext(ctx, `INSERT INTO matching.blog_posts(id,author_id) VALUES($1,$2) ON CONFLICT DO NOTHING`, id, actor); err != nil {
			return blogPost{}, err
		}
		existing, err = readBlog(ctx, tx, actor, id)
		if err != nil {
			return blogPost{}, err
		}
		// The same UUID can never overwrite an existing or deleted post.
		if existing.AuthorID != actor {
			return blogPost{}, errDatePlanForbidden
		}
		created = true
		d.Version = existing.Version
	} else if err != nil {
		return blogPost{}, err
	} else {
		if existing.AuthorID != actor {
			return blogPost{}, errDatePlanForbidden
		}
		if existing.Version != d.Version {
			if err = tx.QueryRowContext(ctx, `SELECT allow_featuring,COALESCE(topic_slug,'') FROM matching.blog_posts WHERE id=$1`, id).Scan(&existing.AllowFeaturing, &existing.Topic); err != nil {
				return blogPost{}, err
			}
			// Lost-success retry with the exact same representation is a readback.
			if existing.Version == d.Version+1 && existing.Title == d.Title && existing.Body == d.Body && existing.Audience == d.Audience && existing.Invitation == d.Invitation && existing.AllowFeaturing == d.AllowFeaturing && existing.Topic == d.Topic && richDocEqual(existing.Content, d.Content) {
				return readBlog(ctx, tx, actor, id)
			}
			return blogPost{}, errDatingConflict
		}
	}
	if existing.Moderation != "active" && d.Audience != "private" {
		return blogPost{}, blogInputError("This chapter was removed by moderation. Keep edits private and use your review notice to appeal.")
	}
	if d.Audience == "community" {
		_, visible, e := loadPublicProfile(ctx, tx, actor, actor)
		if e != nil {
			return blogPost{}, e
		}
		if !visible {
			return blogPost{}, blogInputError("Complete your dating profile and have two approved profile photos before posting to the community")
		}
	}
	if d.Topic != "" {
		var known bool
		if err = tx.QueryRowContext(ctx, `SELECT EXISTS(SELECT 1 FROM matching.blog_topics WHERE slug=$1 AND active)`, d.Topic).Scan(&known); err != nil {
			return blogPost{}, err
		}
		if !known {
			return blogPost{}, blogInputError("Choose an available topic")
		}
	}
	var publishedBefore bool
	if err = tx.QueryRowContext(ctx, `SELECT published_at IS NOT NULL FROM matching.blog_posts WHERE id=$1`, id).Scan(&publishedBefore); err != nil {
		return blogPost{}, err
	}
	content, err := richDocJSON(d.Content)
	if err != nil {
		return blogPost{}, err
	}
	// A plain-text save (older client) clears formatting so content never
	// disagrees with body.
	_, err = tx.ExecContext(ctx, `UPDATE matching.blog_posts SET title=$2,body=$3,audience=$4,invitation=$5,version=version+CASE WHEN $6 THEN 0 ELSE 1 END,updated_at=NOW(),published_at=CASE WHEN $4<>'private' THEN COALESCE(published_at,NOW()) ELSE published_at END,allow_featuring=$7,topic_slug=NULLIF($8,''),content=$9::jsonb WHERE id=$1`, id, d.Title, d.Body, d.Audience, d.Invitation, created, d.AllowFeaturing, d.Topic, content)
	if err != nil {
		return blogPost{}, err
	}
	if d.Audience != "private" {
		if err = queueReward(ctx, tx, actor, "story_published", id); err != nil {
			return blogPost{}, err
		}
		if !publishedBefore {
			if err = notifyBlogSubscribers(ctx, tx, actor, id, d.Title); err != nil {
				return blogPost{}, err
			}
		}
	}
	p, err := readBlog(ctx, tx, actor, id)
	if err != nil {
		return p, err
	}
	return p, tx.Commit()
}

func (s *Server) blogPostsHandler(w http.ResponseWriter, r *http.Request) {
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
	id := chi.URLParam(r, "postID")
	if id != "" {
		if _, err = uuid.Parse(id); err != nil {
			writeError(w, 404, errDatePlanNotFound)
			return
		}
		switch r.Method {
		case http.MethodPut:
			body, ok := readJSON(w, r)
			if !ok {
				return
			}
			draft, err := parseBlogDraft(body)
			if err != nil {
				writeError(w, 400, err)
				return
			}
			p, err := saveBlog(r.Context(), db, actor.UserID, id, draft)
			if err != nil {
				writeBlogError(w, err)
				return
			}
			writeJSON(w, 200, map[string]any{"post": p})
			return
		case http.MethodDelete:
			body, ok := readJSON(w, r)
			if !ok {
				return
			}
			v, ok := body["expected_version"].(float64)
			if !ok || v < 1 || v > 2147483646 || v != float64(int(v)) {
				writeError(w, 400, errors.New("expected_version is required"))
				return
			}
			tx, err := db.BeginTx(r.Context(), nil)
			if err != nil {
				writeError(w, 503, err)
				return
			}
			defer tx.Rollback()
			if err = lockBlogAuthor(r.Context(), tx, actor.UserID); err != nil {
				writeBlogError(w, err)
				return
			}
			result, err := tx.ExecContext(r.Context(), `UPDATE matching.blog_posts SET audience='private',deleted_at=NOW(),version=version+1,updated_at=NOW() WHERE id=$1 AND author_id=$2 AND deleted_at IS NULL AND version=$3`, id, actor.UserID, int(v))
			if err != nil {
				writeError(w, 503, err)
				return
			}
			n, _ := result.RowsAffected()
			if n != 1 {
				writeBlogError(w, errDatingConflict)
				return
			}
			if _, err = tx.ExecContext(r.Context(), `UPDATE matching.blog_photos SET deleted_at=NOW() WHERE post_id=$1 AND deleted_at IS NULL`, id); err != nil {
				writeError(w, 503, err)
				return
			}
			if err = tx.Commit(); err != nil {
				writeError(w, 503, err)
				return
			}
			writeJSON(w, 200, map[string]any{"deleted": true})
			return
		}
		p, err := readBlog(r.Context(), db, actor.UserID, id)
		if err != nil {
			writeBlogError(w, err)
			return
		}
		writeJSON(w, 200, map[string]any{"post": p})
		return
	}
	scope := r.URL.Query().Get("scope")
	if scope == "" {
		scope = "community"
	}
	if scope != "mine" && scope != "friends" && scope != "community" && scope != "top" && scope != "subscriptions" {
		writeError(w, 400, errors.New("invalid journal collection"))
		return
	}
	owner := r.URL.Query().Get("author_id")
	if owner != "" {
		if _, err = uuid.Parse(owner); err != nil {
			writeError(w, 400, errors.New("invalid author"))
			return
		}
	}
	before := r.URL.Query().Get("before")
	if before != "" {
		if _, err = uuid.Parse(before); err != nil {
			writeError(w, 400, errors.New("invalid page cursor"))
			return
		}
	}
	topic := r.URL.Query().Get("topic")
	if len(topic) > 32 {
		writeError(w, 400, errors.New("Choose an available topic"))
		return
	}
	if scope == "top" {
		// Ranked, not paged: the top twenty of the last thirty days.
		before = ""
	}
	query := blogSelect + ` AND ($2='' OR p.author_id::text=$2) AND
 (($3='mine' AND p.author_id=$1::uuid) OR ($3='friends' AND p.audience<>'private' AND matching.accepted_friends($1::uuid,p.author_id)) OR ($3='community' AND p.audience='community')
  OR ($3='top' AND p.audience='community' AND p.published_at>NOW()-interval '30 days')
  OR ($3='subscriptions' AND p.audience<>'private' AND EXISTS(SELECT 1 FROM matching.blog_subscriptions bs WHERE bs.subscriber_id=$1::uuid AND bs.author_id=p.author_id)))
 AND ($5='' OR p.topic_slug=$5)
 AND ($4='' OR (p.created_at,p.id) < (SELECT created_at,id FROM matching.blog_posts WHERE id::text=$4))
 ORDER BY CASE WHEN $3='top' THEN ` + blogWall.likesSQL("p.id") + ` END DESC NULLS LAST,
  CASE WHEN $3='top' THEN ` + blogWall.approvedCommentsSQL("p.id") + ` END DESC NULLS LAST,
  CASE WHEN $3='top' THEN ` + blogWall.viewsSQL("p.id") + ` END DESC NULLS LAST,
  p.created_at DESC,p.id DESC LIMIT 21`
	tx, err := db.BeginTx(r.Context(), &sql.TxOptions{Isolation: sql.LevelRepeatableRead, ReadOnly: true})
	if err != nil {
		writeError(w, 503, err)
		return
	}
	defer tx.Rollback()
	rows, err := tx.QueryContext(r.Context(), query, actor.UserID, owner, scope, before, topic)
	if err != nil {
		writeError(w, 503, err)
		return
	}
	posts := []blogPost{}
	for rows.Next() {
		p, e := scanBlog(rows)
		if e != nil {
			rows.Close()
			writeError(w, 503, e)
			return
		}
		posts = append(posts, p)
	}
	err = rows.Err()
	rows.Close()
	if err != nil {
		writeError(w, 503, err)
		return
	}
	next := ""
	if len(posts) > 20 {
		posts = posts[:20]
		if scope != "top" {
			next = posts[19].ID
		}
	}
	for i := range posts {
		posts[i], err = readBlog(r.Context(), tx, actor.UserID, posts[i].ID)
		if err != nil {
			writeError(w, 503, err)
			return
		}
	}
	writeJSON(w, 200, map[string]any{"posts": posts, "next_cursor": next})
}

func (s *Server) reportBlogPost(w http.ResponseWriter, r *http.Request) { s.blogReportHandler(w, r) }

// Keep storage failures opaque while returning actionable validation errors.
type blogInputError string

func (e blogInputError) Error() string { return string(e) }
func writeBlogError(w http.ResponseWriter, err error) {
	var input blogInputError
	switch {
	case errors.As(err, &input):
		writeError(w, 400, err)
	case errors.Is(err, errDatingConflict):
		writeError(w, 409, errors.New("This chapter changed. Reload the saved version before editing."))
	case errors.Is(err, errDatePlanNotFound):
		writeError(w, 404, errors.New("This chapter is unavailable or its audience has changed."))
	case errors.Is(err, errDatePlanForbidden):
		writeError(w, 403, errors.New("This account cannot change this chapter."))
	default:
		writeError(w, 503, errors.New("Chapters are temporarily unavailable. Please retry."))
	}
}
