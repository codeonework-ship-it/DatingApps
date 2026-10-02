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

// Profile showcase (migration 130): a member's public writing and wall photos
// on their profile. Other members see it only when the member opted in
// (user_settings.profile_showcase_visible, default off), and only what is
// already public: community chapters and wall-featured photos that are active
// and not under review, re-checked for the viewer with the normal rules
// (blocks, account state, community eligibility). Profile stories keep their
// own publish switch and are not part of this.

const (
	profileShowcaseLimit      = 6
	profileShowcaseExcerptLen = 180
)

type profileShowcaseChapter struct {
	ID           string    `json:"id"`
	Title        string    `json:"title"`
	Excerpt      string    `json:"excerpt"`
	PublishedAt  time.Time `json:"published_at"`
	LikeCount    int       `json:"like_count"`
	CommentCount int       `json:"comment_count"`
}

type profileShowcase struct {
	// Enabled is the owner's consent. Other members see it only when they may
	// see the owner at all (no block either way, both accounts active);
	// otherwise false with nothing, so a hidden showcase reveals nothing.
	Enabled  bool                     `json:"enabled"`
	Chapters []profileShowcaseChapter `json:"chapters"`
	Photos   []themeEntry             `json:"photos"`
}

func profileShowcaseVisiblePG(ctx context.Context, q blogQuerier, owner string) (bool, error) {
	var visible bool
	err := q.QueryRowContext(ctx, `SELECT COALESCE((SELECT profile_showcase_visible FROM user_management.user_settings WHERE user_id=$1::uuid),FALSE)`, owner).Scan(&visible)
	return visible, err
}

func setProfileShowcaseVisiblePG(ctx context.Context, db *sql.DB, owner string, visible bool) error {
	_, err := db.ExecContext(ctx, `INSERT INTO user_management.user_settings(user_id,profile_showcase_visible,updated_at) VALUES($1::uuid,$2,NOW())
 ON CONFLICT (user_id) DO UPDATE SET profile_showcase_visible=EXCLUDED.profile_showcase_visible,updated_at=NOW()
 WHERE user_management.user_settings.profile_showcase_visible IS DISTINCT FROM EXCLUDED.profile_showcase_visible`, owner, visible)
	return err
}

// showcaseExcerpt shortens plain chapter text at a word boundary.
func showcaseExcerpt(body string) string {
	text := strings.Join(strings.Fields(body), " ")
	if utf8.RuneCountInString(text) <= profileShowcaseExcerptLen {
		return text
	}
	runes := []rune(text)[:profileShowcaseExcerptLen]
	cut := string(runes)
	if i := strings.LastIndex(cut, " "); i > profileShowcaseExcerptLen/2 {
		cut = cut[:i]
	}
	return strings.TrimRight(cut, " ,.;:-") + "…"
}

// readProfileShowcase returns what viewer may see on owner's profile. The
// owner always sees their own public items (a preview) with their consent.
func readProfileShowcase(ctx context.Context, db *sql.DB, viewer, owner string) (profileShowcase, error) {
	out := profileShowcase{Chapters: []profileShowcaseChapter{}, Photos: []themeEntry{}}
	tx, err := db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelRepeatableRead, ReadOnly: true})
	if err != nil {
		return out, err
	}
	defer tx.Rollback()
	if out.Enabled, err = profileShowcaseVisiblePG(ctx, tx, owner); err != nil {
		return out, err
	}
	if !out.Enabled && viewer != owner {
		return out, nil
	}
	if viewer != owner {
		// Blocked either way, or either account inactive: answer exactly like
		// a hidden showcase, so the blocked side cannot read the owner's
		// consent (the profile itself is a 404 for them).
		var reachable bool
		if err = tx.QueryRowContext(ctx, `SELECT `+activityNotBlocked("$1::uuid", "$2::uuid")+` AND `+activityActive("$1::uuid")+` AND `+activityActive("$2::uuid"), viewer, owner).Scan(&reachable); err != nil {
			return out, err
		}
		if !reachable {
			out.Enabled = false
			return out, nil
		}
	}
	rows, err := tx.QueryContext(ctx, `SELECT p.id::text,p.title,p.body,COALESCE(p.published_at,p.created_at),
 `+blogWall.likesSQL("p.id")+`,`+blogWall.approvedCommentsSQL("p.id")+`
 FROM matching.blog_posts p WHERE `+blogVisible+`
 AND p.author_id=$2::uuid AND p.audience='community' AND p.moderation_state='active'
 AND NOT EXISTS(SELECT 1 FROM matching.blog_cases bc WHERE bc.content_type='post' AND bc.content_id=p.id AND bc.status='pending')
 ORDER BY COALESCE(p.published_at,p.created_at) DESC,p.id DESC LIMIT $3`, viewer, owner, profileShowcaseLimit)
	if err != nil {
		return out, err
	}
	for rows.Next() {
		var c profileShowcaseChapter
		var body string
		if err = rows.Scan(&c.ID, &c.Title, &body, &c.PublishedAt, &c.LikeCount, &c.CommentCount); err != nil {
			rows.Close()
			return out, err
		}
		c.Excerpt = showcaseExcerpt(body)
		out.Chapters = append(out.Chapters, c)
	}
	err = rows.Err()
	rows.Close()
	if err != nil {
		return out, err
	}
	type ref struct{ theme, id string }
	refs := []ref{}
	rows, err = tx.QueryContext(ctx, `SELECT p.theme_id::text,p.id::text FROM matching.photo_theme_entries p
 WHERE p.author_id=$1::uuid AND `+photoWallAllowedSQL()+`
 ORDER BY p.created_at DESC,p.id DESC LIMIT $2`, owner, profileShowcaseLimit)
	if err != nil {
		return out, err
	}
	for rows.Next() {
		var item ref
		if err = rows.Scan(&item.theme, &item.id); err != nil {
			rows.Close()
			return out, err
		}
		refs = append(refs, item)
	}
	err = rows.Err()
	rows.Close()
	if err != nil {
		return out, err
	}
	for _, item := range refs {
		// Normal visibility for this reader (blocks, account state).
		e, readErr := readThemeEntry(ctx, tx, viewer, item.theme, item.id)
		if errors.Is(readErr, sql.ErrNoRows) || errors.Is(readErr, errDatePlanNotFound) {
			continue
		}
		if readErr != nil {
			return out, readErr
		}
		out.Photos = append(out.Photos, e)
	}
	return out, nil
}

func (s *Server) profileShowcaseHandler(w http.ResponseWriter, r *http.Request) {
	actor, err := requestPrincipal(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	owner := chi.URLParam(r, "userID")
	if _, err = uuid.Parse(owner); err != nil {
		writeError(w, http.StatusBadRequest, errors.New("invalid profile"))
		return
	}
	db, err := s.growthDB()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("Profile highlights are unavailable"))
		return
	}
	out, err := readProfileShowcase(r.Context(), db, actor.UserID, owner)
	if err != nil {
		writeActivityError(w, err, "Profile highlights are unavailable")
		return
	}
	w.Header().Set("Cache-Control", "private, no-store")
	writeJSON(w, http.StatusOK, map[string]any{"enabled": out.Enabled, "chapters": out.Chapters, "photos": out.Photos})
}

// profileShowcaseConsentHandler reads or changes the owner's "Show my public
// chapters and wall photos on my profile" choice.
func (s *Server) profileShowcaseConsentHandler(w http.ResponseWriter, r *http.Request) {
	actor, err := requestPrincipal(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	owner := chi.URLParam(r, "userID")
	if _, err = uuid.Parse(owner); err != nil {
		writeError(w, http.StatusBadRequest, errors.New("invalid profile"))
		return
	}
	if actor.UserID != owner {
		writeError(w, http.StatusForbidden, errors.New("only the owner can change this"))
		return
	}
	var visible, set bool
	if r.Method == http.MethodPut {
		payload, ok := readJSON(w, r)
		if !ok {
			return
		}
		value, isBool := payload["visible"].(bool)
		if !isBool {
			writeError(w, http.StatusBadRequest, errors.New("visible must be true or false"))
			return
		}
		visible, set = value, true
	}
	db, err := s.growthDB()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("Profile highlights are unavailable"))
		return
	}
	if set {
		if err = setProfileShowcaseVisiblePG(r.Context(), db, owner, visible); err != nil {
			writeActivityError(w, err, "Profile highlights are unavailable")
			return
		}
		s.store.recordActivity(activityEvent{
			UserID: owner, Actor: owner, Action: "profile.showcase_visibility", Status: "success",
			Resource: "/profile/" + owner + "/showcase/consent", Details: map[string]any{"visible": visible},
		})
	}
	if visible, err = profileShowcaseVisiblePG(r.Context(), db, owner); err != nil {
		writeActivityError(w, err, "Profile highlights are unavailable")
		return
	}
	w.Header().Set("Cache-Control", "private, no-store")
	writeJSON(w, http.StatusOK, map[string]any{"visible": visible})
}
