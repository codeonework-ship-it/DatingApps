package mobile

import (
	"context"
	"database/sql"
	"errors"
	"net/http"
	"time"
)

// Today's wall carousel, unique views and Cover of the Week (migration 112).
//
// Ranking everywhere: likes, then approved comments, then unique views, all
// descending, with random tie-breaks. Choices are persisted so the carousel is
// fixed for the day and the cover for the week, and content that was not
// chosen gets priority on a later day (wall) or remains eligible next week
// (cover, which never repeats).

const todayWallSize = 10

type todayWallItem struct {
	Kind     string      `json:"kind"`
	Position int         `json:"position"`
	Post     *blogPost   `json:"post,omitempty"`
	Entry    *themeEntry `json:"entry,omitempty"`
}

// rankColumnsSQL exposes the ranking inputs (likes, comments, views) for alias p.
func (w wallSpec) rankColumnsSQL() string {
	return w.likesSQL("p.id") + ` AS likes,` + w.approvedCommentsSQL("p.id") + ` AS comments,` + w.viewsSQL("p.id") + ` AS views`
}

// recordContentView counts a unique view when the viewer can see the content
// and is not its author. Returns whether a new view was recorded.
func recordContentView(ctx context.Context, db *sql.DB, actor, kind, id string) (bool, error) {
	switch kind {
	case "chapter":
		p, err := readBlog(ctx, db, actor, id)
		if err != nil {
			return false, err
		}
		if p.AuthorID == actor {
			return false, nil
		}
	case "photo":
		var themeID string
		if err := db.QueryRowContext(ctx, `SELECT theme_id::text FROM matching.photo_theme_entries WHERE id=$1`, id).Scan(&themeID); err != nil {
			return false, errDatePlanNotFound
		}
		e, err := readThemeEntry(ctx, db, actor, themeID, id)
		if err != nil {
			return false, err
		}
		if e.AuthorID == actor {
			return false, nil
		}
	default:
		return false, blogInputError("kind must be chapter or photo")
	}
	result, err := db.ExecContext(ctx, `INSERT INTO matching.content_views(kind,content_id,viewer_id) VALUES($1,$2,$3) ON CONFLICT DO NOTHING`, kind, id, actor)
	if err != nil {
		return false, err
	}
	n, _ := result.RowsAffected()
	return n == 1, nil
}

func (s *Server) contentViewsHandler(w http.ResponseWriter, r *http.Request) {
	actor, err := requestPrincipal(r)
	if err != nil {
		writeError(w, 401, err)
		return
	}
	body, ok := readJSON(w, r)
	if !ok {
		return
	}
	id := toString(body["id"])
	if !activityUUID(w, id) {
		return
	}
	db, err := s.growthDB()
	if err != nil {
		writeError(w, 503, err)
		return
	}
	w.Header().Set("Cache-Control", "private, no-store")
	recorded, err := recordContentView(r.Context(), db, actor.UserID, toString(body["kind"]), id)
	if err != nil {
		writeActivityError(w, err, "Views are temporarily unavailable.")
		return
	}
	writeJSON(w, 200, map[string]any{"recorded": recorded})
}

// todayWall returns the member's carousel for day, choosing it on the first
// request of the day. Chosen items that later stop qualifying (opt-out,
// report, block) are skipped rather than replaced, so the day stays stable.
func todayWall(ctx context.Context, db *sql.DB, actor string, day time.Time) ([]todayWallItem, error) {
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback()
	if err = lockBlogAuthor(ctx, tx, actor); err != nil {
		return nil, err
	}
	dayText := day.Format("2006-01-02")
	var picked int
	if err = tx.QueryRowContext(ctx, `SELECT COUNT(*) FROM matching.wall_daily_picks WHERE recipient_id=$1 AND day=$2::date`, actor, dayText).Scan(&picked); err != nil {
		return nil, err
	}
	if picked == 0 {
		// Fresh items (never on an earlier day's wall) first, then the shared
		// ranking, then random among exact ties.
		_, err = tx.ExecContext(ctx, `INSERT INTO matching.wall_daily_picks(recipient_id,day,kind,content_id,position)
 SELECT $1::uuid,$2::date,r.kind,r.id,r.pos FROM (
  SELECT c.kind,c.id,ROW_NUMBER() OVER (ORDER BY c.shown_before,c.likes DESC,c.comments DESC,c.views DESC,c.tiebreak) AS pos FROM (
   SELECT u.*,random() AS tiebreak,
    EXISTS(SELECT 1 FROM matching.wall_daily_picks h WHERE h.recipient_id=$1::uuid AND h.kind=u.kind AND h.content_id=u.id AND h.day<$2::date) AS shown_before
   FROM (
    SELECT 'chapter'::text AS kind,p.id,`+blogWall.rankColumnsSQL()+` FROM matching.blog_posts p
     WHERE `+blogWall.featuredSQL()+` AND `+blogWall.deliveredToSQL()+`
    UNION ALL
    SELECT 'photo'::text,p.id,`+photoWall.rankColumnsSQL()+` FROM matching.photo_theme_entries p
     WHERE `+photoWall.featuredSQL()+` AND `+photoWall.deliveredToSQL()+`
   ) u
  ) c
 ) r WHERE r.pos<=$3 ON CONFLICT DO NOTHING`, actor, dayText, todayWallSize)
		if err != nil {
			return nil, err
		}
	}
	rows, err := tx.QueryContext(ctx, `SELECT kind,content_id::text,position FROM matching.wall_daily_picks WHERE recipient_id=$1 AND day=$2::date ORDER BY position`, actor, dayText)
	if err != nil {
		return nil, err
	}
	type pick struct {
		kind, id string
		position int
	}
	picks := []pick{}
	for rows.Next() {
		var p pick
		if err = rows.Scan(&p.kind, &p.id, &p.position); err != nil {
			rows.Close()
			return nil, err
		}
		picks = append(picks, p)
	}
	err = rows.Err()
	rows.Close()
	if err != nil {
		return nil, err
	}
	items := []todayWallItem{}
	for _, p := range picks {
		item := todayWallItem{Kind: p.kind, Position: len(items) + 1}
		switch p.kind {
		case "chapter":
			post, readErr := readBlog(ctx, tx, actor, p.id)
			if errors.Is(readErr, errDatePlanNotFound) || (readErr == nil && !post.Featured) {
				continue
			}
			if readErr != nil {
				return nil, readErr
			}
			item.Post = &post
		case "photo":
			var themeID string
			if e := tx.QueryRowContext(ctx, `SELECT theme_id::text FROM matching.photo_theme_entries WHERE id=$1`, p.id).Scan(&themeID); e != nil {
				continue
			}
			entry, readErr := readThemeEntry(ctx, tx, actor, themeID, p.id)
			if errors.Is(readErr, errDatePlanNotFound) || (readErr == nil && !entry.Featured) {
				continue
			}
			if readErr != nil {
				return nil, readErr
			}
			item.Entry = &entry
		}
		items = append(items, item)
	}
	return items, tx.Commit()
}

func (s *Server) todayWallHandler(w http.ResponseWriter, r *http.Request) {
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
	day := time.Now().UTC()
	items, err := todayWall(r.Context(), db, actor.UserID, day)
	if err != nil {
		writeActivityError(w, err, "Your wall is temporarily unavailable. Please retry.")
		return
	}
	writeJSON(w, 200, map[string]any{"day": day.Format("2006-01-02"), "items": items})
}

func isoWeekStart(t time.Time) time.Time {
	t = t.UTC()
	day := time.Date(t.Year(), t.Month(), t.Day(), 0, 0, 0, 0, time.UTC)
	return day.AddDate(0, 0, -((int(day.Weekday()) + 6) % 7))
}

// coverOfWeek chooses the week's cover on the first request of the week and
// returns it as the viewer may see it (nil when hidden from this viewer or
// no longer allowed).
func coverOfWeek(ctx context.Context, db *sql.DB, actor string, week time.Time) (*themeEntry, error) {
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback()
	weekText := week.Format("2006-01-02")
	// Serialise the once-a-week choice across concurrent first requests.
	if _, err = tx.ExecContext(ctx, `SELECT pg_advisory_xact_lock(hashtext('matching.photo_covers'))`); err != nil {
		return nil, err
	}
	var entryID string
	err = tx.QueryRowContext(ctx, `SELECT entry_id::text FROM matching.photo_covers WHERE week_start=$1::date`, weekText).Scan(&entryID)
	if errors.Is(err, sql.ErrNoRows) {
		var author, caption string
		err = tx.QueryRowContext(ctx, `SELECT c.id::text,c.author_id::text,c.caption FROM (
 SELECT p.id,p.author_id,p.caption,`+photoWall.rankColumnsSQL()+` FROM matching.photo_theme_entries p
 WHERE `+photoWall.Allowed()+` AND p.created_at>NOW()-interval '30 days' AND `+activityActive("p.author_id")+`
  AND NOT EXISTS(SELECT 1 FROM matching.photo_covers pc WHERE pc.entry_id=p.id)) c
 WHERE c.likes>=1 ORDER BY c.likes DESC,c.comments DESC,c.views DESC,random() LIMIT 1`).Scan(&entryID, &author, &caption)
		if errors.Is(err, sql.ErrNoRows) {
			return nil, tx.Commit()
		}
		if err != nil {
			return nil, err
		}
		if _, err = tx.ExecContext(ctx, `INSERT INTO matching.photo_covers(week_start,entry_id) VALUES($1::date,$2)`, weekText, entryID); err != nil {
			return nil, err
		}
		if runeLen(caption) > 60 {
			caption = string([]rune(caption)[:57]) + "…"
		}
		if _, err = tx.ExecContext(ctx, `INSERT INTO matching.wall_celebrations(author_id,kind,content_id,tier,reach,title) VALUES($1,'cover',$2,1,0,$3) ON CONFLICT DO NOTHING`, author, entryID, caption); err != nil {
			return nil, err
		}
		if err = queueReward(ctx, tx, author, "cover_of_week", entryID); err != nil {
			return nil, err
		}
		if err = enqueueNotificationTx(ctx, tx, author, "", "themes.photo.cover", "system", entryID, "photo-cover:"+entryID,
			"Your photo is Cover of the Week", "“"+caption+"” is on every member’s Today screen this week.", "/themes",
			map[string]any{"entry_id": entryID, "week_start": weekText}, 3); err != nil {
			return nil, err
		}
	} else if err != nil {
		return nil, err
	}
	var themeID string
	var allowed bool
	if err = tx.QueryRowContext(ctx, `SELECT p.theme_id::text,`+photoWall.Allowed()+` FROM matching.photo_theme_entries p WHERE p.id=$1`, entryID).Scan(&themeID, &allowed); err != nil || !allowed {
		return nil, tx.Commit()
	}
	entry, err := readThemeEntry(ctx, tx, actor, themeID, entryID)
	if errors.Is(err, errDatePlanNotFound) {
		return nil, tx.Commit()
	}
	if err != nil {
		return nil, err
	}
	return &entry, tx.Commit()
}

func (s *Server) coverOfWeekHandler(w http.ResponseWriter, r *http.Request) {
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
	week := isoWeekStart(time.Now())
	entry, err := coverOfWeek(r.Context(), db, actor.UserID, week)
	if err != nil {
		writeActivityError(w, err, "The cover is temporarily unavailable.")
		return
	}
	if entry == nil {
		writeJSON(w, 200, map[string]any{"cover": nil})
		return
	}
	writeJSON(w, 200, map[string]any{"cover": map[string]any{"week_start": week.Format("2006-01-02"), "entry": entry}})
}
