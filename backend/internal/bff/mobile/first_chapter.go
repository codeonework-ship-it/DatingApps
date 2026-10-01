package mobile

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"net/http"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)

// Public content is deliberately assembled from this curated catalogue only.
// Private captions, member identifiers and locations never enter a public card.
type chapterScene struct {
	ID         string   `json:"id"`
	Title      string   `json:"title"`
	Prompt     string   `json:"prompt"`
	Beginnings []string `json:"beginnings"`
	Surprises  []string `json:"surprises"`
	Venue      string   `json:"venue"`
}

var chapterScenes = []chapterScene{
	{"rain", "A little rain, a little wonder", "A rainy afternoon and a small budget. Where does your chapter begin?", []string{"Browse a tiny bookshop", "Find a cosy coffee corner", "Sketch the view from a window"}, []string{"Choose a book by its first line", "Invent a dessert with three ingredients", "Draw a postcard for your future selves"}, "coffee"},
	{"detour", "The beautiful detour", "An unplanned afternoon. Make a small adventure out of an ordinary day.", []string{"Take a slow park walk", "Explore a local market", "Find a free gallery"}, []string{"Pick a colour and follow it", "Find something neither of you has tried", "Make a three-photo story"}, "walk"},
	{"sunday", "A Sunday worth keeping", "A quiet Sunday, no rush and no grand gestures. What would feel like you?", []string{"Share an alcohol-free brunch", "Listen to a favourite album", "Bring a picnic to a public garden"}, []string{"Trade a song and the story behind it", "Write a tiny menu for an imaginary cafe", "Ask a question you have never asked"}, "meal"},
}

func chapterSceneByID(id string) (chapterScene, bool) {
	for _, s := range chapterScenes {
		if s.ID == id {
			return s, true
		}
	}
	return chapterScene{}, false
}
func chapterContains(v []string, s string) bool {
	for _, x := range v {
		if x == s {
			return true
		}
	}
	return false
}

var errChapterInput = errors.New("Choose a current scene option and refresh before saving")
var errChapterLimit = errors.New("This connection has started three chapters in the last day. You can still chat and revisit your shared stories")

type firstChapter struct {
	ID        string `json:"id"`
	MatchID   string `json:"-"`
	Creator   string `json:"-"`
	Scene     string `json:"scene"`
	Beginning string `json:"beginning"`
	Surprise  string `json:"surprise"`
	Closed    bool   `json:"closed"`
	Version   int    `json:"version"`
	MyTurn    bool   `json:"my_turn"`
}

func readChapter(ctx context.Context, q datingQuerier, match string) (*firstChapter, error) {
	c := firstChapter{}
	err := q.QueryRowContext(ctx, `SELECT id::text,match_id::text,creator_id::text,scene,beginning,surprise,closed,version FROM matching.first_chapters WHERE match_id=$1 AND NOT closed ORDER BY created_at DESC LIMIT 1`, match).Scan(&c.ID, &c.MatchID, &c.Creator, &c.Scene, &c.Beginning, &c.Surprise, &c.Closed, &c.Version)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil
	}
	return &c, err
}

type chapterCommand struct {
	ID      string `json:"id"`
	Action  string `json:"action"`
	Scene   string `json:"scene"`
	Choice  string `json:"choice"`
	Version int    `json:"version"`
}

func mutateChapter(ctx context.Context, db *sql.DB, match, actor string, cmd chapterCommand) (*firstChapter, error) {
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback()
	partner, err := activeDatingPair(ctx, tx, match, actor, true)
	if err != nil {
		return nil, err
	}
	current, err := readChapter(ctx, tx, match)
	if err != nil {
		return nil, err
	}
	if cmd.Action == "start" {
		scene, ok := chapterSceneByID(cmd.Scene)
		if !ok || !chapterContains(scene.Beginnings, cmd.Choice) {
			return nil, errChapterInput
		}
		if _, err = uuid.Parse(cmd.ID); err != nil {
			return nil, errChapterInput
		}
		if current != nil {
			if current.ID == cmd.ID && current.Creator == actor && current.Scene == cmd.Scene && current.Beginning == cmd.Choice {
				return current, nil
			}
			return nil, errDatingConflict
		}
		var recent int
		if err = tx.QueryRowContext(ctx, `SELECT COUNT(*) FROM matching.first_chapters WHERE match_id=$1 AND created_at>NOW()-INTERVAL '24 hours'`, match).Scan(&recent); err != nil {
			return nil, err
		}
		if recent >= 3 {
			return nil, errChapterLimit
		}
		_, err = tx.ExecContext(ctx, `INSERT INTO matching.first_chapters(id,match_id,creator_id,scene,beginning) VALUES($1,$2,$3,$4,$5) ON CONFLICT DO NOTHING`, cmd.ID, match, actor, cmd.Scene, cmd.Choice)
		if err != nil {
			return nil, err
		}
		current, err = readChapter(ctx, tx, match)
		if err != nil {
			return nil, err
		}
		if current == nil || current.ID != cmd.ID {
			return nil, errDatingConflict
		}
		err = enqueueNotificationTx(ctx, tx, partner, actor, "chapter.started", "message", current.ID, "chapter:"+current.ID+":start", "Your first chapter has a beginning", "Your match started an optional scene. Add a surprise whenever you like.", "/matches", map[string]any{"match_id": match}, 4)
		if err != nil {
			return nil, err
		}
	} else {
		if current == nil || current.ID != cmd.ID {
			return nil, errDatingConflict
		}
		if cmd.Action == "surprise" {
			scene, ok := chapterSceneByID(current.Scene)
			if !ok || !chapterContains(scene.Surprises, cmd.Choice) || current.Creator == actor {
				return nil, errChapterInput
			}
			if current.Surprise == cmd.Choice {
				return current, nil
			}
			if current.Surprise != "" || current.Version != cmd.Version {
				return nil, errDatingConflict
			}
			_, err = tx.ExecContext(ctx, `UPDATE matching.first_chapters SET surprise=$2,version=version+1,updated_at=NOW() WHERE id=$1`, current.ID, cmd.Choice)
			if err == nil {
				err = enqueueNotificationTx(ctx, tx, partner, actor, "chapter.completed", "message", current.ID, "chapter:"+current.ID+":complete", "Your first chapter is ready", "A beginning and a surprise. See the story you created together.", "/matches", map[string]any{"match_id": match}, 4)
			}
		} else if cmd.Action == "close" {
			if current.Version != cmd.Version {
				return nil, errDatingConflict
			}
			_, err = tx.ExecContext(ctx, `UPDATE matching.first_chapters SET closed=TRUE,version=version+1,updated_at=NOW() WHERE id=$1`, current.ID)
			// Leaving a chapter also withdraws all joint publication permissions.
			if err == nil {
				_, err = tx.ExecContext(ctx, `UPDATE matching.chapter_publications SET revoked=TRUE,version=version+1 WHERE chapter_id=$1 AND NOT revoked`, current.ID)
			}
		} else {
			return nil, errChapterInput
		}
		if err != nil {
			return nil, err
		}
	}
	if err = tx.Commit(); err != nil {
		return nil, err
	}
	return readChapter(ctx, db, match)
}

type greenLight struct {
	Choices   []string   `json:"choices"`
	Version   int        `json:"version"`
	ExpiresAt *time.Time `json:"expires_at"`
}

func readGreen(ctx context.Context, q datingQuerier, match, user string) (greenLight, error) {
	g := greenLight{Choices: []string{}}
	var raw []byte
	var expires time.Time
	err := q.QueryRowContext(ctx, `SELECT choices,version,expires_at FROM matching.chapter_green_lights WHERE match_id=$1 AND user_id=$2`, match, user).Scan(&raw, &g.Version, &expires)
	if errors.Is(err, sql.ErrNoRows) {
		return g, nil
	}
	if err != nil {
		return g, err
	}
	g.ExpiresAt = &expires
	if expires.After(time.Now()) {
		err = json.Unmarshal(raw, &g.Choices)
	}
	return g, err
}
func saveGreen(ctx context.Context, db *sql.DB, match, actor string, g greenLight) error {
	if len(g.Choices) > 3 || g.Version < 0 {
		return errChapterInput
	}
	seen := map[string]bool{}
	for _, v := range g.Choices {
		if !datingChoice(v, "chat", "call", "date") || seen[v] {
			return errChapterInput
		}
		seen[v] = true
	}
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()
	if _, err = activeDatingPair(ctx, tx, match, actor, true); err != nil {
		return err
	}
	old, err := readGreen(ctx, tx, match, actor)
	if err != nil {
		return err
	}
	if old.Version != g.Version {
		return errDatingConflict
	}
	if g.Choices == nil {
		g.Choices = []string{}
	}
	raw, _ := json.Marshal(g.Choices)
	_, err = tx.ExecContext(ctx, `INSERT INTO matching.chapter_green_lights(match_id,user_id,choices,expires_at) VALUES($1,$2,$3,NOW()+INTERVAL '7 days') ON CONFLICT(match_id,user_id) DO UPDATE SET choices=EXCLUDED.choices,expires_at=EXCLUDED.expires_at,version=matching.chapter_green_lights.version+1`, match, actor, string(raw))
	if err != nil {
		return err
	}
	return tx.Commit()
}
func mutualGreen(a, b greenLight) []string {
	out := []string{}
	for _, v := range a.Choices {
		if chapterContains(b.Choices, v) {
			out = append(out, v)
		}
	}
	return out
}

type comfortCard struct {
	Topic               string `json:"topic"`
	Original            string `json:"original"`
	Language            string `json:"language"`
	Translation         string `json:"translation"`
	TranslationLanguage string `json:"translation_language"`
}
type comfortView struct {
	Cards   []comfortCard `json:"cards"`
	Shared  bool          `json:"shared"`
	Version int           `json:"version"`
}

func readComfort(ctx context.Context, q datingQuerier, user string) (comfortView, error) {
	c := comfortView{Cards: []comfortCard{}}
	var raw []byte
	err := q.QueryRowContext(ctx, `SELECT cards,shared,version FROM matching.comfort_cards WHERE user_id=$1`, user).Scan(&raw, &c.Shared, &c.Version)
	if errors.Is(err, sql.ErrNoRows) {
		return c, nil
	}
	if err != nil {
		return c, err
	}
	err = json.Unmarshal(raw, &c.Cards)
	return c, err
}
func validComfort(c comfortView) bool {
	if len(c.Cards) > 4 || c.Version < 0 {
		return false
	}
	seen := map[string]bool{}
	for _, v := range c.Cards {
		if !datingChoice(v.Topic, "pace", "dates", "language", "family") || seen[v.Topic] || utf8.RuneCountInString(strings.TrimSpace(v.Original)) < 1 || utf8.RuneCountInString(v.Original) > 280 || len(v.Language) < 2 || len(v.Language) > 35 || utf8.RuneCountInString(v.Translation) > 280 {
			return false
		}
		if (v.Translation != "" && (len(v.TranslationLanguage) < 2 || len(v.TranslationLanguage) > 35)) || (v.Translation == "" && v.TranslationLanguage != "") {
			return false
		}
		seen[v.Topic] = true
	}
	return true
}
func saveComfort(ctx context.Context, db *sql.DB, user string, c comfortView) error {
	if !validComfort(c) {
		return errChapterInput
	}
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()
	var id string
	if err = tx.QueryRowContext(ctx, `SELECT id::text FROM user_management.users WHERE id=$1 AND is_active AND deactivated_at IS NULL AND deletion_requested_at IS NULL FOR UPDATE`, user).Scan(&id); err != nil {
		return err
	}
	old, err := readComfort(ctx, tx, user)
	if err != nil {
		return err
	}
	if old.Version != c.Version {
		return errDatingConflict
	}
	if c.Cards == nil {
		c.Cards = []comfortCard{}
	}
	raw, _ := json.Marshal(c.Cards)
	_, err = tx.ExecContext(ctx, `INSERT INTO matching.comfort_cards(user_id,cards,shared) VALUES($1,$2,$3) ON CONFLICT(user_id) DO UPDATE SET cards=EXCLUDED.cards,shared=EXCLUDED.shared,version=matching.comfort_cards.version+1,updated_at=NOW()`, user, string(raw), c.Shared)
	if err != nil {
		return err
	}
	return tx.Commit()
}

func chapterError(w http.ResponseWriter, err error) {
	if errors.Is(err, errChapterLimit) {
		writeError(w, http.StatusTooManyRequests, err)
	} else if errors.Is(err, errChapterInput) {
		writeError(w, 400, err)
	} else {
		writeDatePlanError(w, err)
	}
}
func (s *Server) chapterPairHandler(w http.ResponseWriter, r *http.Request) {
	p, err := requestPrincipal(r)
	if err != nil {
		writeError(w, 401, err)
		return
	}
	db, err := s.growthDB()
	if err != nil {
		chapterError(w, err)
		return
	}
	match := chi.URLParam(r, "matchID")
	if r.Method == http.MethodPost {
		var cmd chapterCommand
		if !pilotBody(w, r, &cmd) {
			return
		}
		if _, err = mutateChapter(r.Context(), db, match, p.UserID, cmd); err != nil {
			chapterError(w, err)
			return
		}
	} else if r.Method == http.MethodPut {
		var g greenLight
		if !pilotBody(w, r, &g) {
			return
		}
		if err = saveGreen(r.Context(), db, match, p.UserID, g); err != nil {
			chapterError(w, err)
			return
		}
	}
	// A single consistent snapshot avoids revealing a stale mutual choice during withdrawal.
	tx, err := db.BeginTx(r.Context(), &sql.TxOptions{Isolation: sql.LevelRepeatableRead, ReadOnly: true})
	if err != nil {
		chapterError(w, err)
		return
	}
	defer tx.Rollback()
	partner, err := activeDatingPair(r.Context(), tx, match, p.UserID, false)
	if err != nil {
		chapterError(w, err)
		return
	}
	c, err := readChapter(r.Context(), tx, match)
	if err != nil {
		chapterError(w, err)
		return
	}
	if c != nil {
		c.MyTurn = c.Creator != p.UserID && c.Surprise == ""
	}
	mine, err := readGreen(r.Context(), tx, match, p.UserID)
	if err != nil {
		chapterError(w, err)
		return
	}
	theirs, err := readGreen(r.Context(), tx, match, partner)
	if err != nil {
		chapterError(w, err)
		return
	}
	comfort, err := readComfort(r.Context(), tx, partner)
	if err != nil {
		chapterError(w, err)
		return
	}
	if !comfort.Shared {
		comfort = comfortView{Cards: []comfortCard{}}
	}
	var alumni bool
	err = tx.QueryRowContext(r.Context(), `SELECT EXISTS(SELECT 1 FROM matching.match_graduations WHERE match_id=$1 AND status='confirmed')`, match).Scan(&alumni)
	if err != nil {
		chapterError(w, err)
		return
	}
	writeJSON(w, 200, map[string]any{"chapter": c, "scenes": chapterScenes, "mine": mine, "mutual": mutualGreen(mine, theirs), "comfort": comfort.Cards, "can_give_back": alumni})
}
func (s *Server) comfortHandler(w http.ResponseWriter, r *http.Request) {
	p, err := requestPrincipal(r)
	if err != nil {
		writeError(w, 401, err)
		return
	}
	db, err := s.growthDB()
	if err != nil {
		chapterError(w, err)
		return
	}
	if r.Method == http.MethodPut {
		var c comfortView
		if !pilotBody(w, r, &c) {
			return
		}
		if err = saveComfort(r.Context(), db, p.UserID, c); err != nil {
			chapterError(w, err)
			return
		}
	}
	c, err := readComfort(r.Context(), db, p.UserID)
	if err != nil {
		chapterError(w, err)
		return
	}
	writeJSON(w, 200, map[string]any{"cards": c.Cards, "shared": c.Shared, "version": c.Version})
}
func (s *Server) chapterCatalogue(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, 200, map[string]any{"scenes": chapterScenes})
}
