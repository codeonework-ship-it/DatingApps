package mobile

import (
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
)

// Rose rain (migration 111): a celebration is recorded when a chapter or photo
// reaches a new wall tier. The author's app plays it once, then marks it seen.

type wallCelebration struct {
	ID        string    `json:"id"`
	Kind      string    `json:"kind"`
	ContentID string    `json:"content_id"`
	ThemeID   string    `json:"theme_id,omitempty"`
	Tier      int       `json:"tier"`
	Reach     int       `json:"reach"`
	Title     string    `json:"title"`
	Created   time.Time `json:"created_at"`
}

func (s *Server) wallCelebrationsHandler(w http.ResponseWriter, r *http.Request) {
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
	const unavailable = "Celebrations are temporarily unavailable."
	if r.Method == http.MethodPost {
		id := chi.URLParam(r, "celebrationID")
		if !activityUUID(w, id) {
			return
		}
		// Idempotent: a second acknowledgement is not an error.
		// Seeing a tier also settles every lower tier of the same item.
		result, e := db.ExecContext(r.Context(), `UPDATE matching.wall_celebrations c SET seen_at=COALESCE(c.seen_at,NOW())
 FROM matching.wall_celebrations t WHERE t.id=$1 AND t.author_id=$2 AND c.author_id=t.author_id AND c.kind=t.kind AND c.content_id=t.content_id AND c.tier<=t.tier`, id, actor.UserID)
		if e != nil {
			writeActivityError(w, e, unavailable)
			return
		}
		if n, _ := result.RowsAffected(); n < 1 {
			writeActivityError(w, errDatePlanNotFound, unavailable)
			return
		}
		writeJSON(w, 200, map[string]any{"seen": true})
		return
	}
	// Only the newest unseen tier per item matters; older ones are skipped so
	// a member who was away sees one shower, not a queue of them.
	rows, err := db.QueryContext(r.Context(), `SELECT c.id::text,c.kind,c.content_id::text,COALESCE(e.theme_id::text,''),c.tier,c.reach,c.title,c.created_at
 FROM matching.wall_celebrations c LEFT JOIN matching.photo_theme_entries e ON c.kind IN ('photo','cover') AND e.id=c.content_id
 WHERE c.author_id=$1 AND c.seen_at IS NULL AND c.created_at>NOW()-interval '30 days'
  AND NOT EXISTS(SELECT 1 FROM matching.wall_celebrations n WHERE n.kind=c.kind AND n.content_id=c.content_id AND n.tier>c.tier)
 ORDER BY c.created_at DESC LIMIT 5`, actor.UserID)
	if err != nil {
		writeActivityError(w, err, unavailable)
		return
	}
	defer rows.Close()
	items := []wallCelebration{}
	for rows.Next() {
		var c wallCelebration
		if err = rows.Scan(&c.ID, &c.Kind, &c.ContentID, &c.ThemeID, &c.Tier, &c.Reach, &c.Title, &c.Created); err != nil {
			writeActivityError(w, err, unavailable)
			return
		}
		items = append(items, c)
	}
	if err = rows.Err(); err != nil {
		writeActivityError(w, err, unavailable)
		return
	}
	writeJSON(w, 200, map[string]any{"celebrations": items})
}
