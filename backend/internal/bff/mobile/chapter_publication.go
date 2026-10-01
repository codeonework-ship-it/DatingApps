package mobile

import (
	"context"
	"database/sql"
	"errors"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)

type chapterPublication struct {
	ID              string `json:"id"`
	Owner           string `json:"-"`
	Partner         string `json:"-"`
	Chapter         string `json:"chapter_id,omitempty"`
	Scene           string `json:"scene"`
	Beginning       string `json:"beginning"`
	Surprise        string `json:"surprise"`
	OwnerApproved   bool   `json:"-"`
	PartnerApproved bool   `json:"-"`
	Revoked         bool   `json:"revoked"`
	Version         int    `json:"version"`
	Published       bool   `json:"published"`
	MyApproval      bool   `json:"my_approval"`
	Joint           bool   `json:"joint"`
}

const publicationSelect = `SELECT id::text,owner_id::text,COALESCE(partner_id::text,''),COALESCE(chapter_id::text,''),scene,beginning,surprise,owner_approved,partner_approved,revoked,version FROM matching.chapter_publications`

func scanPublication(row datePlanScanner) (chapterPublication, error) {
	p := chapterPublication{}
	err := row.Scan(&p.ID, &p.Owner, &p.Partner, &p.Chapter, &p.Scene, &p.Beginning, &p.Surprise, &p.OwnerApproved, &p.PartnerApproved, &p.Revoked, &p.Version)
	return p, err
}
func (p chapterPublication) view(actor string) chapterPublication {
	p.Joint = p.Partner != ""
	p.Published = !p.Revoked && p.OwnerApproved && (!p.Joint || p.PartnerApproved)
	p.MyApproval = (actor == p.Owner && p.OwnerApproved) || (actor == p.Partner && p.PartnerApproved)
	return p
}

type publicationCommand struct {
	ID        string `json:"id"`
	MatchID   string `json:"match_id"`
	Chapter   string `json:"chapter_id"`
	Scene     string `json:"scene"`
	Beginning string `json:"beginning"`
	Action    string `json:"action"`
	Version   int    `json:"version"`
}

func createPublication(ctx context.Context, db *sql.DB, actor string, cmd publicationCommand) (chapterPublication, error) {
	p := chapterPublication{ID: cmd.ID, Owner: actor, Scene: cmd.Scene, Beginning: cmd.Beginning, OwnerApproved: true, Version: 1}
	if _, err := uuid.Parse(cmd.ID); err != nil {
		return p, errChapterInput
	}
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return p, err
	}
	defer tx.Rollback()
	// Serializes the per-author link limit across different matches too.
	var user string
	if err = tx.QueryRowContext(ctx, `SELECT id::text FROM user_management.users WHERE id=$1 AND is_active AND deactivated_at IS NULL AND deletion_requested_at IS NULL FOR UPDATE`, actor).Scan(&user); err != nil {
		return p, err
	}
	if cmd.Chapter != "" {
		partner, e := activeDatingPair(ctx, tx, cmd.MatchID, actor, true)
		if e != nil {
			return p, e
		}
		c, e := readChapter(ctx, tx, cmd.MatchID)
		if e != nil {
			return p, e
		}
		if c == nil || c.ID != cmd.Chapter || c.Surprise == "" {
			return p, errChapterInput
		}
		var eligible bool
		e = tx.QueryRowContext(ctx, `SELECT EXISTS(SELECT 1 FROM matching.match_graduations WHERE match_id=$1 AND status='confirmed')`, cmd.MatchID).Scan(&eligible)
		if e != nil {
			return p, e
		}
		if !eligible {
			return p, errDatePlanForbidden
		}
		p.Partner = partner
		p.Chapter = c.ID
		p.Scene = c.Scene
		p.Beginning = c.Beginning
		p.Surprise = c.Surprise
	} else {
		var user string
		err = tx.QueryRowContext(ctx, `SELECT id::text FROM user_management.users WHERE id=$1 AND is_active AND deactivated_at IS NULL AND deletion_requested_at IS NULL FOR UPDATE`, actor).Scan(&user)
		if err != nil {
			return p, err
		}
		scene, ok := chapterSceneByID(p.Scene)
		if !ok || !chapterContains(scene.Beginnings, p.Beginning) {
			return p, errChapterInput
		}
	}
	// Bound active links per member; serialized above, including first publication.
	var count int
	if err = tx.QueryRowContext(ctx, `SELECT count(*) FROM matching.chapter_publications WHERE owner_id=$1 AND NOT revoked AND id<>$2`, actor, p.ID).Scan(&count); err != nil {
		return p, err
	}
	if count >= 20 {
		return p, errChapterInput
	}
	_, err = tx.ExecContext(ctx, `INSERT INTO matching.chapter_publications(id,owner_id,partner_id,chapter_id,scene,beginning,surprise) VALUES($1,$2,NULLIF($3,'')::uuid,NULLIF($4,'')::uuid,$5,$6,$7) ON CONFLICT(id) DO NOTHING`, p.ID, p.Owner, p.Partner, p.Chapter, p.Scene, p.Beginning, p.Surprise)
	if err != nil {
		return p, err
	}
	saved, err := scanPublication(tx.QueryRowContext(ctx, publicationSelect+` WHERE id=$1`, p.ID))
	if err != nil {
		return p, err
	}
	if saved.Owner != actor || saved.Scene != p.Scene || saved.Beginning != p.Beginning || saved.Chapter != p.Chapter || saved.Revoked {
		return p, errDatingConflict
	}
	if err = tx.Commit(); err != nil {
		return p, err
	}
	return saved.view(actor), nil
}
func changePublication(ctx context.Context, db *sql.DB, actor string, cmd publicationCommand) (chapterPublication, error) {
	p := chapterPublication{}
	if _, err := uuid.Parse(cmd.ID); err != nil {
		return p, errChapterInput
	}
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return p, err
	}
	defer tx.Rollback()
	p, err = scanPublication(tx.QueryRowContext(ctx, publicationSelect+` WHERE id=$1`, cmd.ID))
	if err != nil {
		return p, err
	}
	if actor != p.Owner && actor != p.Partner {
		return p, errDatePlanForbidden
	}
	// Revocation always remains possible, even after an unmatch or block.
	if cmd.Action == "approve" && p.Partner != "" {
		var match string
		if err = tx.QueryRowContext(ctx, `SELECT match_id::text FROM matching.first_chapters WHERE id=$1 AND NOT closed`, p.Chapter).Scan(&match); err != nil {
			return p, err
		}
		if _, err = activeDatingPair(ctx, tx, match, actor, true); err != nil {
			return p, err
		}
	}
	p, err = scanPublication(tx.QueryRowContext(ctx, publicationSelect+` WHERE id=$1 FOR UPDATE`, cmd.ID))
	if err != nil {
		return p, err
	}
	if p.Revoked && cmd.Action == "revoke" {
		return p.view(actor), nil
	}
	if p.Revoked || (cmd.Action != "revoke" && cmd.Version != p.Version) {
		return p, errDatingConflict
	}
	switch cmd.Action {
	case "approve":
		if actor == p.Owner {
			p.OwnerApproved = true
		} else {
			p.PartnerApproved = true
		}
	case "revoke":
		p.Revoked = true
	default:
		return p, errChapterInput
	}
	_, err = tx.ExecContext(ctx, `UPDATE matching.chapter_publications SET owner_approved=$2,partner_approved=$3,revoked=$4,version=version+1 WHERE id=$1`, p.ID, p.OwnerApproved, p.PartnerApproved, p.Revoked)
	if err != nil {
		return p, err
	}
	if err = tx.Commit(); err != nil {
		return p, err
	}
	p.Version++
	return p.view(actor), nil
}
func readPublicChapter(ctx context.Context, db *sql.DB, id string) (map[string]any, error) {
	if _, err := uuid.Parse(id); err != nil {
		return nil, errDatePlanNotFound
	}
	tx, err := db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelRepeatableRead, ReadOnly: true})
	if err != nil {
		return nil, err
	}
	defer tx.Rollback()
	p, err := scanPublication(tx.QueryRowContext(ctx, publicationSelect+` WHERE id=$1 AND NOT revoked AND owner_approved AND (partner_id IS NULL OR partner_approved)`, id))
	if err != nil {
		return nil, errDatePlanNotFound
	}
	var active bool
	err = tx.QueryRowContext(ctx, `SELECT NOT EXISTS(SELECT 1 FROM user_management.users WHERE id IN ($1::uuid,NULLIF($2,'')::uuid) AND (NOT is_active OR deactivated_at IS NOT NULL OR deletion_requested_at IS NOT NULL))`, p.Owner, p.Partner).Scan(&active)
	if err != nil {
		return nil, err
	}
	if !active {
		return nil, errDatePlanNotFound
	}
	if p.Chapter != "" {
		var match string
		if err = tx.QueryRowContext(ctx, `SELECT match_id::text FROM matching.first_chapters WHERE id=$1 AND NOT closed`, p.Chapter).Scan(&match); err != nil {
			return nil, errDatePlanNotFound
		}
		if _, err = activeDatingPair(ctx, tx, match, p.Owner, false); err != nil {
			return nil, errDatePlanNotFound
		}
	}
	scene, ok := chapterSceneByID(p.Scene)
	if !ok {
		return nil, errDatePlanNotFound
	}
	// Explicit public DTO. Never serialize a private row here.
	return map[string]any{"scene": scene, "beginning": p.Beginning, "surprise": p.Surprise, "joint_story": p.Partner != ""}, nil
}
func (s *Server) chapterPublicHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Cache-Control", "no-store")
	w.Header().Set("Referrer-Policy", "no-referrer")
	db, err := s.growthDB()
	if err != nil {
		chapterError(w, err)
		return
	}
	value, err := readPublicChapter(r.Context(), db, chi.URLParam(r, "shareID"))
	if err != nil {
		writeError(w, 404, errors.New("This chapter is no longer shared"))
		return
	}
	writeJSON(w, 200, value)
}
func (s *Server) chapterPublicationHandler(w http.ResponseWriter, r *http.Request) {
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
	if r.Method == http.MethodDelete {
		result, e := changePublication(r.Context(), db, p.UserID, publicationCommand{ID: chi.URLParam(r, "shareID"), Action: "revoke"})
		if e != nil {
			chapterError(w, e)
			return
		}
		writeJSON(w, 200, map[string]any{"publication": result})
		return
	}
	if r.Method == http.MethodPost {
		var cmd publicationCommand
		if !pilotBody(w, r, &cmd) {
			return
		}
		var result chapterPublication
		if cmd.Action == "create" {
			result, err = createPublication(r.Context(), db, p.UserID, cmd)
		} else {
			result, err = changePublication(r.Context(), db, p.UserID, cmd)
		}
		if err != nil {
			chapterError(w, err)
			return
		}
		writeJSON(w, 200, map[string]any{"publication": result})
		return
	}
	rows, err := db.QueryContext(r.Context(), publicationSelect+` WHERE owner_id=$1 OR partner_id=$1 ORDER BY created_at DESC LIMIT 100`, p.UserID)
	if err != nil {
		chapterError(w, err)
		return
	}
	defer rows.Close()
	result := []chapterPublication{}
	for rows.Next() {
		v, e := scanPublication(rows)
		if e != nil {
			chapterError(w, e)
			return
		}
		result = append(result, v.view(p.UserID))
	}
	if err = rows.Err(); err != nil {
		chapterError(w, err)
		return
	}
	writeJSON(w, 200, map[string]any{"publications": result, "server_time": time.Now().UTC()})
}
