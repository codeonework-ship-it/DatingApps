package mobile

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"net/http"
	"strconv"
	"strings"
	"unicode/utf8"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)

var storyPrompts = map[string]string{
	"little_joy":  "A small thing I always make time for",
	"weekend":     "A weekend worth sharing",
	"first_hello": "A first hello I would love",
	"learning":    "Something I am learning, just for me",
	"care":        "A small way I show I care",
}

type profileStory struct {
	PromptID string `json:"prompt_id"`
	Text     string `json:"text"`
	// Content is the formatted story (rich_text.go); Text is its derived plain text.
	Content          *richDoc `json:"content,omitempty"`
	PhotoID          string   `json:"photo_id,omitempty"`
	PhotoURL         string   `json:"photo_url,omitempty"`
	PhotoDescription string   `json:"photo_description,omitempty"`
}
type storyPhoto struct {
	ID  string `json:"id"`
	URL string `json:"url"`
}
type profileStoriesView struct {
	Stories   []profileStory `json:"stories"`
	Published bool           `json:"published"`
	Version   int            `json:"version"`
	Photos    []storyPhoto   `json:"photos,omitempty"`
}

var errInvalidStory = errors.New("Use up to three different prompts, 1–400 characters per story, and a description for each photo")

func parseProfileStories(body map[string]any) (profileStoriesView, error) {
	out := profileStoriesView{Stories: []profileStory{}}
	raw, ok := body["stories"].([]any)
	if !ok || len(raw) > 3 {
		return out, errInvalidStory
	}
	published, ok := body["published"].(bool)
	if !ok {
		return out, errInvalidStory
	}
	out.Published = published
	version, ok := body["expected_version"].(float64)
	if !ok || version < 0 || version != float64(int(version)) {
		return out, errors.New("expected_version must be a non-negative integer")
	}
	out.Version = int(version)
	seen := map[string]bool{}
	for _, value := range raw {
		row, ok := value.(map[string]any)
		if !ok {
			return out, errInvalidStory
		}
		story := profileStory{PromptID: strings.TrimSpace(toString(row["prompt_id"])), Text: strings.TrimSpace(toString(row["text"])), PhotoID: strings.TrimSpace(toString(row["photo_id"])), PhotoDescription: strings.TrimSpace(toString(row["photo_description"]))}
		content, err := parseRichDoc(row["content"], storyRichLimits)
		if err != nil {
			return out, err
		}
		if content != nil {
			// The plain text is always derived, so profiles and older clients agree.
			story.Content = content
			story.Text = strings.TrimSpace(richPlainText(content))
		}
		if storyPrompts[story.PromptID] == "" || seen[story.PromptID] || utf8.RuneCountInString(story.Text) < 1 || utf8.RuneCountInString(story.Text) > 400 {
			return out, errInvalidStory
		}
		seen[story.PromptID] = true
		if story.PhotoID != "" {
			if _, err := uuid.Parse(story.PhotoID); err != nil {
				return out, errInvalidStory
			}
			if utf8.RuneCountInString(story.PhotoDescription) < 1 || utf8.RuneCountInString(story.PhotoDescription) > 160 {
				return out, errInvalidStory
			}
		} else {
			story.PhotoDescription = ""
		}
		out.Stories = append(out.Stories, story)
	}
	if len(out.Stories) == 0 {
		out.Published = false
	}
	return out, nil
}

func readProfileStories(ctx context.Context, db *sql.DB, viewer, owner string) (profileStoriesView, error) {
	out := profileStoriesView{Stories: []profileStory{}, Photos: []storyPhoto{}}
	tx, err := db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelRepeatableRead, ReadOnly: true})
	if err != nil {
		return out, err
	}
	defer tx.Rollback()
	if viewer != owner {
		_, found, err := loadPublicProfile(ctx, tx, viewer, owner)
		if err != nil {
			return out, err
		}
		if !found {
			return out, errDatePlanNotFound
		}
	}
	var raw []byte
	err = tx.QueryRowContext(ctx, `SELECT stories,published,version FROM user_management.profile_stories WHERE user_id=$1::uuid`, owner).Scan(&raw, &out.Published, &out.Version)
	if err != nil && !errors.Is(err, sql.ErrNoRows) {
		return out, err
	}
	if len(raw) > 0 {
		if err = json.Unmarshal(raw, &out.Stories); err != nil {
			return out, err
		}
	}
	if viewer != owner && !out.Published {
		out.Stories = []profileStory{}
		out.Version = 0
		return out, nil
	}
	rows, err := tx.QueryContext(ctx, `SELECT id::text,photo_url FROM user_management.photos WHERE user_id=$1::uuid AND deleted_at IS NULL AND lifecycle_status='active' AND moderation_status='approved' ORDER BY ordering,id`, owner)
	if err != nil {
		return out, err
	}
	photos := map[string]string{}
	for rows.Next() {
		var p storyPhoto
		if err = rows.Scan(&p.ID, &p.URL); err != nil {
			rows.Close()
			return out, err
		}
		photos[p.ID] = p.URL
		if viewer == owner {
			out.Photos = append(out.Photos, p)
		}
	}
	err = rows.Err()
	rows.Close()
	if err != nil {
		return out, err
	}
	for i := range out.Stories {
		// Recheck current media state; deleted/quarantined photos disappear immediately.
		out.Stories[i].PhotoURL = photos[out.Stories[i].PhotoID]
		if out.Stories[i].PhotoURL == "" {
			out.Stories[i].PhotoID = ""
			out.Stories[i].PhotoDescription = ""
		}
	}
	return out, nil
}
func saveProfileStories(ctx context.Context, db *sql.DB, owner string, draft profileStoriesView) error {
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()
	var id string
	if err = tx.QueryRowContext(ctx, `SELECT id::text FROM user_management.users WHERE id=$1::uuid FOR UPDATE`, owner).Scan(&id); err != nil {
		return err
	}
	_, err = tx.ExecContext(ctx, `INSERT INTO user_management.profile_stories(user_id) VALUES($1::uuid) ON CONFLICT DO NOTHING`, owner)
	if err != nil {
		return err
	}
	for _, story := range draft.Stories {
		if story.PhotoID == "" {
			continue
		}
		var valid bool
		if err = tx.QueryRowContext(ctx, `SELECT EXISTS(SELECT 1 FROM user_management.photos WHERE id=$1::uuid AND user_id=$2::uuid AND deleted_at IS NULL AND lifecycle_status='active' AND moderation_status='approved')`, story.PhotoID, owner).Scan(&valid); err != nil {
			return err
		}
		if !valid {
			return errDatePlanForbidden
		}
	}
	raw, err := json.Marshal(draft.Stories)
	if err != nil {
		return err
	}
	result, err := tx.ExecContext(ctx, `UPDATE user_management.profile_stories SET stories=$2::jsonb,published=$3,version=version+1,updated_at=NOW() WHERE user_id=$1::uuid AND version=$4`, owner, raw, draft.Published, draft.Version)
	if err != nil {
		return err
	}
	n, _ := result.RowsAffected()
	if n != 1 {
		return errDatingConflict
	}
	_, err = tx.ExecContext(ctx, `SELECT platform.publish_domain_event('profile_stories.updated',1,'profile_stories',$1::text,'mobile-bff.profile-stories',$1::text::uuid,$1::text::uuid,NULL,NULL,$2,jsonb_build_object('version',$3::int,'story_count',$4::int,'published',$5::boolean))`, owner, "profile-stories:"+owner+":"+strconv.Itoa(draft.Version+1), draft.Version+1, len(draft.Stories), draft.Published)
	if err != nil {
		return err
	}
	return tx.Commit()
}
func (s *Server) profileStoriesHandler(w http.ResponseWriter, r *http.Request) {
	actor, err := requestPrincipal(r)
	if err != nil {
		writeError(w, 401, err)
		return
	}
	owner := chi.URLParam(r, "userID")
	if _, err = uuid.Parse(owner); err != nil {
		writeError(w, 400, errors.New("invalid profile"))
		return
	}
	db, err := s.growthDB()
	if err != nil {
		writeError(w, 503, errors.New("Stories are unavailable"))
		return
	}
	if r.Method == http.MethodPut {
		if actor.UserID != owner {
			writeError(w, 403, errDatePlanForbidden)
			return
		}
		body, ok := readJSON(w, r)
		if !ok {
			return
		}
		draft, err := parseProfileStories(body)
		if err != nil {
			writeError(w, 400, err)
			return
		}
		if err = saveProfileStories(r.Context(), db, owner, draft); err != nil {
			writeDatePlanError(w, err)
			return
		}
	}
	out, err := readProfileStories(r.Context(), db, actor.UserID, owner)
	if err != nil {
		writeDatePlanError(w, err)
		return
	}
	w.Header().Set("Cache-Control", "private, no-store")
	writeJSON(w, 200, map[string]any{"stories": out.Stories, "published": out.Published, "version": out.Version, "photos": out.Photos, "prompts": storyPrompts})
}
