package mobile

import (
	"bytes"
	"context"
	"database/sql"
	"errors"
	"io"
	"net/http"
	"path"
	"strings"
	"sync/atomic"
	"time"
	"unicode/utf8"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"go.uber.org/zap"

	"github.com/verified-dating/backend/internal/platform/observability"
)

// Shared SQL for member activities (Photo Themes, Book & Film Clubs).
//
// activityActive mirrors blogActive for an arbitrary member column so every
// activity applies the same adult, active, not-suspended rule.
func activityActive(col string) string {
	return `EXISTS(SELECT 1 FROM user_management.users u WHERE u.id=` + col + ` AND ` + blogActive + `)`
}

// activityCommunity is the community bar used by blog community posts: a
// complete profile with two approved, active profile photos.
func activityCommunity(col string) string {
	return `EXISTS(SELECT 1 FROM user_management.users ce WHERE ce.id=` + col + ` AND ce.profile_completion=100
 AND (SELECT COUNT(*) FROM user_management.photos cp WHERE cp.user_id=ce.id AND cp.deleted_at IS NULL
  AND cp.lifecycle_status='active' AND cp.moderation_status='approved')>=2)`
}

func activityNotBlocked(a, b string) string {
	return `NOT EXISTS(SELECT 1 FROM user_management.blocked_users bl WHERE
 (bl.user_id=` + a + ` AND bl.blocked_user_id=` + b + `) OR (bl.user_id=` + b + ` AND bl.blocked_user_id=` + a + `))`
}

// activityAudience decides whether viewer $1 may read content an author
// published to an audience. Authors always read their own content.
func activityAudience(audience, author string) string {
	return `(` + author + `=$1::uuid OR (` + activityNotBlocked("$1::uuid", author) + ` AND (
 (` + audience + `='community' AND ` + activityCommunity("$1::uuid") + ` AND ` + activityCommunity(author) + `) OR
 (` + audience + `='friends' AND matching.accepted_friends($1::uuid,` + author + `)))))`
}

const activityEligibilityMessage = "Complete your dating profile and have two approved profile photos to take part."

// activityEligible reports whether a member may publish to the community.
func activityEligible(ctx context.Context, q interface {
	QueryRowContext(context.Context, string, ...any) *sql.Row
}, actor string) (bool, error) {
	var ok bool
	err := q.QueryRowContext(ctx, `SELECT `+activityActive("$1::uuid")+` AND `+activityCommunity("$1::uuid"), actor).Scan(&ok)
	return ok, err
}

// activityError carries a client-safe message and status.
type activityError struct {
	status int
	msg    string
}

func (e activityError) Error() string { return e.msg }

func activityFail(status int, msg string) error { return activityError{status: status, msg: msg} }

func writeActivityError(w http.ResponseWriter, err error, unavailable string) {
	var known activityError
	var input blogInputError
	switch {
	case errors.As(err, &known):
		writeError(w, known.status, errors.New(known.msg))
	case errors.As(err, &input):
		writeError(w, 400, err)
	case errors.Is(err, errDatingConflict):
		writeError(w, 409, errors.New("This changed since you loaded it. Reload and try again."))
	case errors.Is(err, errDatePlanNotFound), errors.Is(err, sql.ErrNoRows):
		writeError(w, 404, errors.New("This is unavailable or no longer shared with you."))
	case errors.Is(err, errDatePlanForbidden):
		writeError(w, 403, errors.New("This account cannot do that."))
	default:
		// Members get a generic message; operators need the cause. Without
		// this log line a 503 from these handlers cannot be diagnosed.
		logUnexpectedError(w, err)
		writeError(w, 503, errors.New(unavailable))
	}
}

// unexpectedErrorLog records errors that member-facing handlers turn into a
// generic 503. Set once by NewServer; nil in tests that build a bare Server.
var unexpectedErrorLog atomic.Pointer[zap.Logger]

func setUnexpectedErrorLogger(log *zap.Logger) {
	if log != nil {
		unexpectedErrorLog.Store(log)
	}
}

func logUnexpectedError(w http.ResponseWriter, err error) {
	log := unexpectedErrorLog.Load()
	if log == nil || err == nil {
		return
	}
	log.Error("unexpected_handler_error",
		zap.Error(err),
		zap.String("correlation_id", w.Header().Get(observability.CorrelationIDHeader)))
}

func activityUUID(w http.ResponseWriter, ids ...string) bool {
	for _, id := range ids {
		if _, err := uuid.Parse(id); err != nil {
			writeError(w, 404, errors.New("This is unavailable or no longer shared with you."))
			return false
		}
	}
	return true
}

// ---------------------------------------------------------------------------
// Photo Themes
// ---------------------------------------------------------------------------

type photoTheme struct {
	ID         string `json:"id"`
	Slug       string `json:"slug"`
	Title      string `json:"title"`
	Prompt     string `json:"prompt"`
	Status     string `json:"status"`
	SortOrder  int    `json:"sort_order"`
	EntryCount int    `json:"entry_count"`
	MyEntryID  string `json:"my_entry_id"`
}

type themeEntry struct {
	ID         string    `json:"id"`
	ThemeID    string    `json:"theme_id"`
	AuthorID   string    `json:"author_id"`
	AuthorName string    `json:"author_name"`
	Caption    string    `json:"caption"`
	AltText    string    `json:"alt_text"`
	Moderation string    `json:"moderation_state"`
	Created    time.Time `json:"created_at"`
	Mine       bool      `json:"mine"`
	// Likes, author-approved comments and wall reach (migration 110).
	ThemeTitle          string         `json:"theme_title"`
	ViewCount           int            `json:"view_count"`
	LikeCount           int            `json:"like_count"`
	LikedByMe           bool           `json:"liked_by_me"`
	MyReaction          string         `json:"my_reaction"`
	Reactions           map[string]int `json:"reactions"`
	CommentCount        int            `json:"comment_count"`
	PendingCommentCount int            `json:"pending_comment_count"`
	AllowFeaturing      bool           `json:"allow_featuring"`
	Featured            bool           `json:"featured"`
	WallReach           int            `json:"wall_reach"`
	NextTier            *blogNextTier  `json:"next_tier"`
}

// themeEntryVisible: viewer $1, entry alias e. Removed entries stay visible
// only to their author so the review notice has something to refer to.
func themeEntryVisible() string {
	return `e.deleted_at IS NULL AND ` + activityActive("$1::uuid") + ` AND ` + activityActive("e.author_id") + `
 AND (e.author_id=$1::uuid OR (e.moderation_state='active' AND ` + activityNotBlocked("$1::uuid", "e.author_id") + `
  AND ` + activityCommunity("$1::uuid") + ` AND ` + activityCommunity("e.author_id") + `))`
}

func themeEntrySelect() string {
	return `SELECT e.id::text,e.theme_id::text,e.author_id::text,COALESCE(u.name,''),e.caption,e.alt_text,e.moderation_state,e.created_at,e.author_id=$1::uuid
 FROM matching.photo_theme_entries e JOIN user_management.users u ON u.id=e.author_id WHERE ` + themeEntryVisible()
}

func scanThemeEntry(row interface{ Scan(...any) error }) (themeEntry, error) {
	var e themeEntry
	err := row.Scan(&e.ID, &e.ThemeID, &e.AuthorID, &e.AuthorName, &e.Caption, &e.AltText, &e.Moderation, &e.Created, &e.Mine)
	if errors.Is(err, sql.ErrNoRows) {
		return e, errDatePlanNotFound
	}
	return e, err
}

func readThemes(ctx context.Context, q blogQuerier, actor, themeID string) ([]photoTheme, error) {
	rows, err := q.QueryContext(ctx, `SELECT t.id::text,t.slug,t.title,t.prompt,t.status,t.sort_order,
 (SELECT COUNT(*) FROM matching.photo_theme_entries e WHERE e.theme_id=t.id AND `+themeEntryVisible()+`),
 COALESCE((SELECT e.id::text FROM matching.photo_theme_entries e WHERE e.theme_id=t.id AND e.author_id=$1::uuid AND e.deleted_at IS NULL),'')
 FROM matching.photo_themes t WHERE ($2='' AND t.status='active') OR t.id::text=$2 ORDER BY t.sort_order,t.title`, actor, themeID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	themes := []photoTheme{}
	for rows.Next() {
		var t photoTheme
		if err = rows.Scan(&t.ID, &t.Slug, &t.Title, &t.Prompt, &t.Status, &t.SortOrder, &t.EntryCount, &t.MyEntryID); err != nil {
			return nil, err
		}
		themes = append(themes, t)
	}
	return themes, rows.Err()
}

func (s *Server) photoThemesHandler(w http.ResponseWriter, r *http.Request) {
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
	themes, err := readThemes(r.Context(), db, actor.UserID, "")
	if err != nil {
		writeActivityError(w, err, "Photo Themes are temporarily unavailable. Please retry.")
		return
	}
	eligible, err := activityEligible(r.Context(), db, actor.UserID)
	if err != nil {
		writeActivityError(w, err, "Photo Themes are temporarily unavailable. Please retry.")
		return
	}
	message := ""
	if !eligible {
		message = activityEligibilityMessage
	}
	writeJSON(w, 200, map[string]any{"themes": themes, "eligible": eligible, "eligibility_message": message})
}

func (s *Server) photoThemeEntriesHandler(w http.ResponseWriter, r *http.Request) {
	actor, err := requestPrincipal(r)
	if err != nil {
		writeError(w, 401, err)
		return
	}
	themeID := chi.URLParam(r, "themeID")
	if !activityUUID(w, themeID) {
		return
	}
	db, err := s.growthDB()
	if err != nil {
		writeError(w, 503, err)
		return
	}
	w.Header().Set("Cache-Control", "private, no-store")
	before := r.URL.Query().Get("before")
	if before != "" {
		if _, err = uuid.Parse(before); err != nil {
			writeError(w, 400, errors.New("invalid page cursor"))
			return
		}
	}
	tx, err := db.BeginTx(r.Context(), &sql.TxOptions{Isolation: sql.LevelRepeatableRead, ReadOnly: true})
	if err != nil {
		writeError(w, 503, err)
		return
	}
	defer tx.Rollback()
	themes, err := readThemes(r.Context(), tx, actor.UserID, themeID)
	if err == nil && len(themes) == 0 {
		err = errDatePlanNotFound
	}
	if err != nil {
		writeActivityError(w, err, "Photo Themes are temporarily unavailable. Please retry.")
		return
	}
	rows, err := tx.QueryContext(r.Context(), themeEntrySelect()+` AND e.theme_id=$2::uuid
 AND ($3='' OR (e.created_at,e.id) < (SELECT created_at,id FROM matching.photo_theme_entries WHERE id::text=$3))
 ORDER BY e.created_at DESC,e.id DESC LIMIT 21`, actor.UserID, themeID, before)
	if err != nil {
		writeActivityError(w, err, "Photo Themes are temporarily unavailable. Please retry.")
		return
	}
	entries := []themeEntry{}
	for rows.Next() {
		e, scanErr := scanThemeEntry(rows)
		if scanErr != nil {
			rows.Close()
			writeActivityError(w, scanErr, "Photo Themes are temporarily unavailable. Please retry.")
			return
		}
		entries = append(entries, e)
	}
	err = rows.Err()
	rows.Close()
	if err != nil {
		writeActivityError(w, err, "Photo Themes are temporarily unavailable. Please retry.")
		return
	}
	next := ""
	if len(entries) > 20 {
		entries = entries[:20]
		next = entries[19].ID
	}
	for i := range entries {
		if err = fillThemeEngagement(r.Context(), tx, actor.UserID, &entries[i]); err != nil {
			writeActivityError(w, err, "Photo Themes are temporarily unavailable. Please retry.")
			return
		}
	}
	writeJSON(w, 200, map[string]any{"theme": themes[0], "entries": entries, "next_cursor": next})
}

func readThemeEntry(ctx context.Context, q blogQuerier, actor, themeID, entryID string) (themeEntry, error) {
	e, err := scanThemeEntry(q.QueryRowContext(ctx, themeEntrySelect()+` AND e.theme_id=$2::uuid AND e.id=$3::uuid`, actor, themeID, entryID))
	if err != nil {
		return e, err
	}
	return e, fillThemeEngagement(ctx, q, actor, &e)
}

func (s *Server) photoThemeEntryHandler(w http.ResponseWriter, r *http.Request) {
	actor, err := requestPrincipal(r)
	if err != nil {
		writeError(w, 401, err)
		return
	}
	themeID, entryID := chi.URLParam(r, "themeID"), chi.URLParam(r, "entryID")
	if !activityUUID(w, themeID, entryID) {
		return
	}
	db, err := s.growthDB()
	if err != nil {
		writeError(w, 503, err)
		return
	}
	w.Header().Set("Cache-Control", "private, no-store")
	const unavailable = "Photo Themes are temporarily unavailable. Please retry."
	switch r.Method {
	case http.MethodGet:
		var storage, mime string
		err = db.QueryRowContext(r.Context(), `SELECT e.storage_path,e.mime_type FROM matching.photo_theme_entries e WHERE `+themeEntryVisible()+` AND e.theme_id=$2::uuid AND e.id=$3::uuid`, actor.UserID, themeID, entryID).Scan(&storage, &mime)
		if err != nil {
			writeActivityError(w, errDatePlanNotFound, unavailable)
			return
		}
		var content bytes.Buffer
		if err = s.copyPrivateMedia(r.Context(), &content, storage); err != nil {
			writeActivityError(w, errDatePlanNotFound, unavailable)
			return
		}
		w.Header().Set("Content-Type", mime)
		w.Header().Set("X-Content-Type-Options", "nosniff")
		w.Header().Set("Content-Disposition", "inline; filename=theme-photo")
		_, _ = w.Write(content.Bytes())
	case http.MethodDelete:
		tx, e := db.BeginTx(r.Context(), nil)
		if e != nil {
			writeActivityError(w, e, unavailable)
			return
		}
		defer tx.Rollback()
		if e = lockBlogAuthor(r.Context(), tx, actor.UserID); e != nil {
			writeActivityError(w, e, unavailable)
			return
		}
		result, e := tx.ExecContext(r.Context(), `UPDATE matching.photo_theme_entries SET deleted_at=NOW(),version=version+1 WHERE id=$1 AND theme_id=$2 AND author_id=$3 AND deleted_at IS NULL`, entryID, themeID, actor.UserID)
		if e != nil {
			writeActivityError(w, e, unavailable)
			return
		}
		if n, _ := result.RowsAffected(); n != 1 {
			writeActivityError(w, errDatePlanNotFound, unavailable)
			return
		}
		if e = tx.Commit(); e != nil {
			writeActivityError(w, e, unavailable)
			return
		}
		writeJSON(w, 200, map[string]any{"deleted": true})
	case http.MethodPut:
		s.putThemeEntry(w, r, db, actor.UserID, themeID, entryID)
	default:
		writeError(w, 405, errors.New("method not allowed"))
	}
}

// putThemeEntry stores one moderated photo. Authorization and the
// one-live-entry rule are checked before any untrusted bytes are decoded or
// sent to moderation, then rechecked under the author lock.
func (s *Server) putThemeEntry(w http.ResponseWriter, r *http.Request, db *sql.DB, actor, themeID, entryID string) {
	const unavailable = "Photo Themes are temporarily unavailable. Please retry."
	r.Body = http.MaxBytesReader(w, r.Body, 11<<20)
	if err := r.ParseMultipartForm(1 << 20); err != nil {
		writeError(w, 400, errors.New("Invalid image upload (maximum 10 MB)"))
		return
	}
	defer r.MultipartForm.RemoveAll()
	caption := strings.TrimSpace(r.FormValue("caption"))
	alt := strings.TrimSpace(r.FormValue("alt_text"))
	if n := utf8.RuneCountInString(caption); n < 1 || n > 280 {
		writeError(w, 400, errors.New("Write a caption of 1–280 characters"))
		return
	}
	if n := utf8.RuneCountInString(alt); n < 1 || n > 160 {
		writeError(w, 400, errors.New("Describe the image in 1–160 characters"))
		return
	}
	precheck := func(q blogQuerier) (themeEntry, bool, error) {
		var status string
		if err := q.QueryRowContext(r.Context(), `SELECT status FROM matching.photo_themes WHERE id=$1`, themeID).Scan(&status); err != nil {
			return themeEntry{}, false, errDatePlanNotFound
		}
		if status != "active" {
			return themeEntry{}, false, activityFail(404, "This theme is closed for new photos.")
		}
		var owner, existingTheme, existingCaption, existingAlt, digest string
		err := q.QueryRowContext(r.Context(), `SELECT author_id::text,theme_id::text,caption,alt_text,content_sha256 FROM matching.photo_theme_entries WHERE id=$1`, entryID).Scan(&owner, &existingTheme, &existingCaption, &existingAlt, &digest)
		if err == nil {
			if owner == actor && existingTheme == themeID && existingCaption == caption && existingAlt == alt {
				entry, readErr := readThemeEntry(r.Context(), q, actor, themeID, entryID)
				return entry, true, readErr
			}
			return themeEntry{}, false, errDatingConflict
		}
		if !errors.Is(err, sql.ErrNoRows) {
			return themeEntry{}, false, err
		}
		var other bool
		if err = q.QueryRowContext(r.Context(), `SELECT EXISTS(SELECT 1 FROM matching.photo_theme_entries WHERE theme_id=$1 AND author_id=$2 AND deleted_at IS NULL)`, themeID, actor).Scan(&other); err != nil {
			return themeEntry{}, false, err
		}
		if other {
			return themeEntry{}, false, activityFail(409, "You already shared a photo for this theme. Remove it to share a different one.")
		}
		return themeEntry{}, false, nil
	}
	eligible, err := activityEligible(r.Context(), db, actor)
	if err != nil {
		writeActivityError(w, err, unavailable)
		return
	}
	if !eligible {
		writeError(w, 403, errors.New(activityEligibilityMessage))
		return
	}
	if replay, done, e := precheck(db); e != nil || done {
		if e != nil {
			writeActivityError(w, e, unavailable)
			return
		}
		writeJSON(w, 200, map[string]any{"entry": replay})
		return
	}
	file, _, err := r.FormFile("image")
	if err != nil {
		writeError(w, 400, errors.New("Choose a JPEG or PNG photo"))
		return
	}
	defer file.Close()
	content, err := io.ReadAll(io.LimitReader(file, maxProfilePhotoBytes+1))
	if err != nil {
		writeError(w, 400, err)
		return
	}
	upload, err := sanitizeBlogPhoto(content)
	if err != nil {
		writeError(w, mediaUploadHTTPStatus(err), err)
		return
	}
	if s.mediaModerator == nil {
		writeError(w, 503, errors.New("Photo moderation is unavailable"))
		return
	}
	upload.Moderation, err = s.mediaModerator.Moderate(r.Context(), upload)
	if err != nil {
		writeError(w, 503, errors.New("Photo moderation is unavailable; please retry"))
		return
	}
	if upload.Moderation.Status != mediaModerationApproved {
		writeError(w, 422, errors.New("This photo could not be approved. It has not been shared."))
		return
	}
	tx, err := db.BeginTx(r.Context(), nil)
	if err != nil {
		writeActivityError(w, err, unavailable)
		return
	}
	defer tx.Rollback()
	if err = lockBlogAuthor(r.Context(), tx, actor); err != nil {
		writeActivityError(w, err, unavailable)
		return
	}
	if replay, done, e := precheck(tx); e != nil || done {
		if e != nil {
			writeActivityError(w, e, unavailable)
			return
		}
		writeJSON(w, 200, map[string]any{"entry": replay})
		return
	}
	namespace := path.Join("private", "themes", actor, themeID)
	filename := uuid.NewString() + upload.Extension
	var stored string
	stored, err = s.storeMedia(r.Context(), namespace, filename, upload.MimeType, upload.Content)
	if err != nil {
		writeError(w, 503, errors.New("Photo storage is unavailable"))
		return
	}
	committed := false
	defer func() {
		if !committed {
			_ = s.deleteStoredMedia(stored)
		}
	}()
	allowFeaturing := strings.EqualFold(strings.TrimSpace(r.FormValue("allow_featuring")), "true")
	if _, err = tx.ExecContext(r.Context(), `INSERT INTO matching.photo_theme_entries(id,theme_id,author_id,caption,alt_text,storage_path,mime_type,size_bytes,content_sha256,moderation_status,moderation_provider,allow_featuring)
 VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,'approved',$10,$11)`, entryID, themeID, actor, caption, alt, stored, upload.MimeType, upload.SizeBytes, upload.ContentSHA256, upload.Moderation.Provider, allowFeaturing); err != nil {
		writeActivityError(w, errDatingConflict, unavailable)
		return
	}
	if err = queueReward(r.Context(), tx, actor, "photo_shared", entryID); err != nil {
		writeActivityError(w, err, unavailable)
		return
	}
	entry, err := readThemeEntry(r.Context(), tx, actor, themeID, entryID)
	if err != nil {
		writeActivityError(w, err, unavailable)
		return
	}
	if err = tx.Commit(); err != nil {
		// The outcome is uncertain; keep the object for reconciliation.
		committed = true
		writeError(w, 503, errors.New("Upload confirmation is pending; reload the theme"))
		return
	}
	committed = true
	writeJSON(w, 200, map[string]any{"entry": entry})
}

// cleanupDeletedThemeMedia releases photos of deleted entries unless a report
// still holds them as evidence or the author is on legal hold.
func (s *Server) cleanupDeletedThemeMedia(ctx context.Context) {
	db, err := s.growthDB()
	if err != nil {
		return
	}
	rows, err := db.QueryContext(ctx, `SELECT id::text,storage_path FROM matching.photo_theme_entries e WHERE deleted_at IS NOT NULL
 AND NOT platform.member_on_legal_hold(author_id)
 AND NOT EXISTS(SELECT 1 FROM matching.blog_evidence_photos ev WHERE ev.storage_path=e.storage_path) LIMIT 100`)
	if err != nil {
		return
	}
	type candidate struct{ id, path string }
	items := []candidate{}
	for rows.Next() {
		var item candidate
		if rows.Scan(&item.id, &item.path) != nil {
			rows.Close()
			return
		}
		items = append(items, item)
	}
	err = rows.Err()
	rows.Close()
	if err != nil {
		return
	}
	for _, item := range items {
		if s.deleteStoredMedia(item.path) == nil {
			_, _ = db.ExecContext(ctx, `DELETE FROM matching.photo_theme_entries WHERE id=$1 AND deleted_at IS NOT NULL`, item.id)
		}
	}
}

// adminPhotoThemesHandler lets operators list and upsert prompts by slug.
func (s *Server) adminPhotoThemesHandler(w http.ResponseWriter, r *http.Request) {
	db, err := s.growthDB()
	if err != nil {
		writeError(w, 503, err)
		return
	}
	w.Header().Set("Cache-Control", "private, no-store")
	page, err := parseAdminListParams(r, adminPhotoThemesSpec)
	if err != nil {
		writeAdminListParamError(w, err)
		return
	}
	if r.Method == http.MethodPost {
		body, ok := readJSON(w, r)
		if !ok {
			return
		}
		slug := strings.TrimSpace(toString(body["slug"]))
		title := strings.TrimSpace(toString(body["title"]))
		prompt := strings.TrimSpace(toString(body["prompt"]))
		status := strings.TrimSpace(toString(body["status"]))
		if status == "" {
			status = "active"
		}
		order := 0
		if raw, present := body["sort_order"]; present {
			v, isNum := raw.(float64)
			if !isNum || v != float64(int(v)) || v < -10000 || v > 10000 {
				writeError(w, 400, errors.New("sort_order must be a whole number"))
				return
			}
			order = int(v)
		}
		if status != "active" && status != "archived" {
			writeError(w, 400, errors.New("status must be active or archived"))
			return
		}
		if n := utf8.RuneCountInString(title); n < 3 || n > 60 {
			writeError(w, 400, errors.New("Use a title of 3–60 characters"))
			return
		}
		if n := utf8.RuneCountInString(prompt); n < 3 || n > 200 {
			writeError(w, 400, errors.New("Use a prompt of 3–200 characters"))
			return
		}
		operator := "operator"
		if p, found := principalFromRequest(r); found && p.UserID != "" {
			operator = p.UserID
		}
		_, err = db.ExecContext(r.Context(), `INSERT INTO matching.photo_themes(slug,title,prompt,status,sort_order,updated_by)
 VALUES($1,$2,$3,$4,$5,$6) ON CONFLICT(slug) DO UPDATE SET title=EXCLUDED.title,prompt=EXCLUDED.prompt,status=EXCLUDED.status,
 sort_order=EXCLUDED.sort_order,updated_by=EXCLUDED.updated_by,updated_at=NOW()`, slug, title, prompt, status, order, operator)
		if err != nil {
			writeError(w, 400, errors.New("Use a slug of 3–48 lowercase letters, numbers or hyphens"))
			return
		}
	}
	filter := newSQLFilter()
	filter.Eq("t.status", r.URL.Query().Get("status"))
	filter.Search(page.Q, "t.slug", "t.title", "t.prompt")
	filter.TimeRange("t.created_at", page)
	themes := []photoTheme{}
	total, err := queryAdminPage(r.Context(), db, `t.id::text,t.slug,t.title,t.prompt,t.status,t.sort_order,
 (SELECT COUNT(*) FROM matching.photo_theme_entries e WHERE e.theme_id=t.id AND e.deleted_at IS NULL AND e.moderation_state='active')`,
		` FROM matching.photo_themes t`, filter, page, func(rows *sql.Rows) error {
			var t photoTheme
			if err := rows.Scan(&t.ID, &t.Slug, &t.Title, &t.Prompt, &t.Status, &t.SortOrder, &t.EntryCount); err != nil {
				return err
			}
			themes = append(themes, t)
			return nil
		})
	if err != nil {
		writeError(w, 503, err)
		return
	}
	writeJSON(w, 200, page.Page(map[string]any{"themes": themes}, total))
}

// This list used to be unbounded; the default page (500) still covers every
// theme an operator manages today.
var adminPhotoThemesSpec = adminListSpec{
	DefaultLimit: 500, MaxLimit: 500,
	Sorts: map[string]string{
		"sort_order": "t.status ASC, t.sort_order {dir}, t.title {dir}",
		"title":      "t.title",
		"created_at": "t.created_at",
	},
	DefaultSort: "sort_order", DefaultOrder: "asc", TieBreak: "t.id {dir}",
}
