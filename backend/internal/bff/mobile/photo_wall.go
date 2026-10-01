package mobile

import (
	"context"
	"database/sql"
	"errors"
	"net/http"

	"github.com/go-chi/chi/v5"
)

// Photo Theme photos on the wall (migration 110): likes, author-approved
// comments and tiered reach to other members' Today walls, with the same
// rules as chapters (see wall_engine.go).

// photoWallAllowedSQL: photo alias p may be on walls right now.
func photoWallAllowedSQL() string {
	return `(p.allow_featuring AND p.moderation_state='active' AND p.deleted_at IS NULL
 AND NOT EXISTS(SELECT 1 FROM matching.blog_cases bc WHERE bc.content_type='theme_entry' AND bc.content_id=p.id AND bc.status='pending'))`
}

var photoWall = wallSpec{
	Noun:        "photo",
	Content:     "matching.photo_theme_entries",
	Likes:       "matching.photo_entry_likes",
	Comments:    "matching.photo_entry_comments",
	Deliveries:  "matching.photo_wall_deliveries",
	FK:          "entry_id",
	OwnerCol:    "owner_id",
	TitleCol:    "caption",
	EventPrefix: "themes.photo",
	Route:       "/themes",
	Allowed:     photoWallAllowedSQL,
}

func fillThemeEngagement(ctx context.Context, q blogQuerier, actor string, e *themeEntry) error {
	g, err := photoWall.engagement(ctx, q, actor, e.ID)
	if err != nil {
		return err
	}
	e.ViewCount, e.LikeCount, e.LikedByMe = g.ViewCount, g.LikeCount, g.LikedByMe
	e.MyReaction, e.Reactions = g.MyReaction, g.Reactions
	e.CommentCount, e.PendingCommentCount = g.CommentCount, g.PendingCommentCount
	e.AllowFeaturing, e.Featured, e.WallReach, e.NextTier = g.AllowFeaturing, g.Featured, g.WallReach, g.NextTier
	return q.QueryRowContext(ctx, `SELECT title FROM matching.photo_themes WHERE id=$1`, e.ThemeID).Scan(&e.ThemeTitle)
}

// readableEngagementEntry loads a photo the actor can see and may react to.
func readableEngagementEntry(ctx context.Context, q blogQuerier, actor, themeID, entryID string) (themeEntry, error) {
	e, err := readThemeEntry(ctx, q, actor, themeID, entryID)
	if err != nil {
		return e, err
	}
	if e.AuthorID == actor {
		return e, activityFail(403, "You cannot like or comment on your own photo.")
	}
	if e.Moderation != "active" {
		return e, errDatePlanNotFound
	}
	return e, nil
}

func (s *Server) photoEntryContext(w http.ResponseWriter, r *http.Request) (string, string, string, *sql.DB, bool) {
	actor, err := requestPrincipal(r)
	if err != nil {
		writeError(w, 401, err)
		return "", "", "", nil, false
	}
	themeID, entryID := chi.URLParam(r, "themeID"), chi.URLParam(r, "entryID")
	if !activityUUID(w, themeID, entryID) {
		return "", "", "", nil, false
	}
	db, err := s.growthDB()
	if err != nil {
		writeError(w, 503, err)
		return "", "", "", nil, false
	}
	w.Header().Set("Cache-Control", "private, no-store")
	return actor.UserID, themeID, entryID, db, true
}

const photoWallUnavailable = "Photo Themes are temporarily unavailable. Please retry."

func (s *Server) photoEntryLikeHandler(w http.ResponseWriter, r *http.Request) {
	actor, themeID, entryID, db, ok := s.photoEntryContext(w, r)
	if !ok {
		return
	}
	reaction, ok := readWallReaction(w, r)
	if !ok {
		return
	}
	e, err := togglePhotoLike(r.Context(), db, actor, themeID, entryID, r.Method == http.MethodPut, reaction)
	if err != nil {
		writeActivityError(w, err, photoWallUnavailable)
		return
	}
	writeJSON(w, 200, map[string]any{"entry": e})
}

func togglePhotoLike(ctx context.Context, db *sql.DB, actor, themeID, entryID string, like bool, reaction string) (themeEntry, error) {
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return themeEntry{}, err
	}
	defer tx.Rollback()
	if err = lockBlogAuthor(ctx, tx, actor); err != nil {
		return themeEntry{}, err
	}
	if _, err = readableEngagementEntry(ctx, tx, actor, themeID, entryID); err != nil {
		return themeEntry{}, err
	}
	if err = photoWall.like(ctx, tx, actor, entryID, like, reaction); err != nil {
		return themeEntry{}, err
	}
	e, err := readThemeEntry(ctx, tx, actor, themeID, entryID)
	if err != nil {
		return e, err
	}
	return e, tx.Commit()
}

// photoEntryFeaturingHandler lets the author turn wall reach on or off.
func (s *Server) photoEntryFeaturingHandler(w http.ResponseWriter, r *http.Request) {
	actor, themeID, entryID, db, ok := s.photoEntryContext(w, r)
	if !ok {
		return
	}
	body, ok := readJSON(w, r)
	if !ok {
		return
	}
	allow, isBool := body["allow"].(bool)
	if !isBool {
		writeError(w, 400, errors.New("allow must be true or false"))
		return
	}
	e, err := setPhotoFeaturing(r.Context(), db, actor, themeID, entryID, allow)
	if err != nil {
		writeActivityError(w, err, photoWallUnavailable)
		return
	}
	writeJSON(w, 200, map[string]any{"entry": e})
}

func setPhotoFeaturing(ctx context.Context, db *sql.DB, actor, themeID, entryID string, allow bool) (themeEntry, error) {
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return themeEntry{}, err
	}
	defer tx.Rollback()
	if err = lockBlogAuthor(ctx, tx, actor); err != nil {
		return themeEntry{}, err
	}
	result, err := tx.ExecContext(ctx, `UPDATE matching.photo_theme_entries SET allow_featuring=$4,version=version+1
 WHERE id=$1 AND theme_id=$2 AND author_id=$3 AND deleted_at IS NULL`, entryID, themeID, actor, allow)
	if err != nil {
		return themeEntry{}, err
	}
	if n, _ := result.RowsAffected(); n != 1 {
		return themeEntry{}, errDatePlanNotFound
	}
	if allow {
		// Engagement earned while it was off still counts.
		if err = photoWall.advance(ctx, tx, entryID); err != nil {
			return themeEntry{}, err
		}
	}
	e, err := readThemeEntry(ctx, tx, actor, themeID, entryID)
	if err != nil {
		return e, err
	}
	return e, tx.Commit()
}

func (s *Server) photoEntryCommentsHandler(w http.ResponseWriter, r *http.Request) {
	s.servePhotoComments(w, r, false)
}

func (s *Server) photoEntryCommentDecisionHandler(w http.ResponseWriter, r *http.Request) {
	s.servePhotoComments(w, r, true)
}

func (s *Server) servePhotoComments(w http.ResponseWriter, r *http.Request, decisionRoute bool) {
	actor, themeID, entryID, db, ok := s.photoEntryContext(w, r)
	if !ok {
		return
	}
	commentID := chi.URLParam(r, "commentID")
	if commentID != "" && !activityUUID(w, commentID) {
		return
	}
	const unavailable = "Comments are temporarily unavailable. Please retry."
	if r.Method == http.MethodGet && commentID == "" {
		if _, err := readThemeEntry(r.Context(), db, actor, themeID, entryID); err != nil {
			writeActivityError(w, err, unavailable)
			return
		}
		comments, err := photoWall.listComments(r.Context(), db, actor, entryID)
		if err != nil {
			writeActivityError(w, err, unavailable)
			return
		}
		writeJSON(w, 200, map[string]any{"comments": comments})
		return
	}
	var body map[string]any
	if r.Method != http.MethodDelete {
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
	c, err := changePhotoComment(r.Context(), db, actor, themeID, entryID, commentID, r.Method, decision, body)
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

func changePhotoComment(ctx context.Context, db *sql.DB, actor, themeID, entryID, commentID, method, decision string, body map[string]any) (wallComment, error) {
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return wallComment{}, err
	}
	defer tx.Rollback()
	if err = lockBlogAuthor(ctx, tx, actor); err != nil {
		return wallComment{}, err
	}
	e, err := readThemeEntry(ctx, tx, actor, themeID, entryID)
	if err != nil {
		return wallComment{}, err
	}
	c, err := photoWall.changeComment(ctx, tx, actor, entryID, commentID, method, decision, body, e.AuthorID, e.Caption, func() error {
		_, readErr := readableEngagementEntry(ctx, tx, actor, themeID, entryID)
		return readErr
	})
	if err != nil {
		return c, err
	}
	return c, tx.Commit()
}

// photoWallHandler lists photos delivered to the member's wall, newest first.
func (s *Server) photoWallHandler(w http.ResponseWriter, r *http.Request) {
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
	entries, err := photoWallEntries(r.Context(), db, actor.UserID)
	if err != nil {
		writeActivityError(w, err, "Your wall is temporarily unavailable. Please retry.")
		return
	}
	writeJSON(w, 200, map[string]any{"entries": entries})
}

func photoWallEntries(ctx context.Context, db *sql.DB, actor string) ([]themeEntry, error) {
	tx, err := db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelRepeatableRead, ReadOnly: true})
	if err != nil {
		return nil, err
	}
	defer tx.Rollback()
	// themeEntryVisible uses alias e; the wall fragments use alias p.
	rows, err := tx.QueryContext(ctx, `SELECT x.theme_id::text,x.id::text FROM (
 SELECT p.id,p.theme_id,`+photoWall.deliveredAtSQL()+` AS delivered_at FROM matching.photo_theme_entries p
 WHERE `+photoWall.featuredSQL()+` AND `+photoWall.deliveredToSQL()+`) x
 ORDER BY x.delivered_at DESC,x.id LIMIT 20`, actor)
	if err != nil {
		return nil, err
	}
	type ref struct{ theme, id string }
	refs := []ref{}
	for rows.Next() {
		var item ref
		if err = rows.Scan(&item.theme, &item.id); err != nil {
			rows.Close()
			return nil, err
		}
		refs = append(refs, item)
	}
	err = rows.Err()
	rows.Close()
	if err != nil {
		return nil, err
	}
	entries := make([]themeEntry, 0, len(refs))
	for _, item := range refs {
		// Re-check normal visibility (blocks, account state) for this reader.
		e, readErr := readThemeEntry(ctx, tx, actor, item.theme, item.id)
		if errors.Is(readErr, errDatePlanNotFound) {
			continue
		}
		if readErr != nil {
			return nil, readErr
		}
		entries = append(entries, e)
	}
	return entries, nil
}

// readPhotoCommentForReport captures a photo comment the reporter can see.
func readPhotoCommentForReport(ctx context.Context, q blogQuerier, actor, commentID string) (string, any, error) {
	var entryID, themeID string
	if err := q.QueryRowContext(ctx, `SELECT c.entry_id::text,e.theme_id::text FROM matching.photo_entry_comments c
 JOIN matching.photo_theme_entries e ON e.id=c.entry_id WHERE c.id=$1`, commentID).Scan(&entryID, &themeID); err != nil {
		return "", nil, errDatePlanNotFound
	}
	e, err := readThemeEntry(ctx, q, actor, themeID, entryID)
	if err != nil {
		return "", nil, err
	}
	c, err := photoWall.readComment(ctx, q, actor, entryID, commentID)
	if err != nil {
		return "", nil, err
	}
	return c.AuthorID, map[string]any{"title": "Comment on photo · " + e.Caption, "text": c.Body}, nil
}
