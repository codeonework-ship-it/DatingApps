package mobile

import (
	"bytes"
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"net/http"
	"strings"
	"unicode/utf8"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)

type blogPublication struct {
	ID              string   `json:"id"`
	PostID          string   `json:"post_id"`
	ResponseID      string   `json:"response_id"`
	Owner           string   `json:"-"`
	Partner         string   `json:"-"`
	Title           string   `json:"title"`
	Excerpt         string   `json:"excerpt"`
	PhotoIDs        []string `json:"photo_ids"`
	SourceVersion   int      `json:"source_version"`
	Version         int      `json:"version"`
	OwnerApproved   bool     `json:"-"`
	PartnerApproved bool     `json:"-"`
	Revoked         bool     `json:"revoked"`
	Moderation      string   `json:"moderation_state"`
	MyApproval      bool     `json:"my_approval"`
	Joint           bool     `json:"joint"`
	Published       bool     `json:"published"`
}

const blogPublicationSelect = `SELECT id::text,post_id::text,COALESCE(response_id::text,''),owner_id::text,COALESCE(partner_id::text,''),title,excerpt,to_json(photo_ids),source_version,version,owner_approved,partner_approved,revoked,moderation_state FROM matching.blog_publications`

func scanBlogPublication(row datePlanScanner) (blogPublication, error) {
	p := blogPublication{}
	var raw []byte
	err := row.Scan(&p.ID, &p.PostID, &p.ResponseID, &p.Owner, &p.Partner, &p.Title, &p.Excerpt, &raw, &p.SourceVersion, &p.Version, &p.OwnerApproved, &p.PartnerApproved, &p.Revoked, &p.Moderation)
	if errors.Is(err, sql.ErrNoRows) {
		err = errDatePlanNotFound
	}
	if err == nil {
		err = json.Unmarshal(raw, &p.PhotoIDs)
	}
	p.Joint = p.Partner != ""
	return p, err
}
func (p blogPublication) view(actor string) blogPublication {
	p.MyApproval = (actor == p.Owner && p.OwnerApproved) || (actor == p.Partner && p.PartnerApproved)
	return p
}
func blogPublicationSource(ctx context.Context, q blogQuerier, p blogPublication) error {
	post, err := readBlog(ctx, q, p.Owner, p.PostID)
	if err != nil {
		return err
	}
	if post.Version != p.SourceVersion || post.Audience != "community" || post.Moderation != "active" {
		return errDatePlanNotFound
	}
	var eligible bool
	err = q.QueryRowContext(ctx, `SELECT EXISTS(SELECT 1 FROM user_management.users u WHERE u.id=$1 AND `+blogActive+` AND profile_completion=100 AND (SELECT COUNT(*) FROM user_management.photos ph WHERE ph.user_id=u.id AND ph.deleted_at IS NULL AND ph.lifecycle_status='active' AND ph.moderation_status='approved')>=2)`, post.AuthorID).Scan(&eligible)
	if err != nil {
		return err
	}
	if !eligible {
		return errDatePlanNotFound
	}
	if p.Joint {
		response, e := readBlogResponse(ctx, q, p.Owner, p.ResponseID)
		if e != nil || !response.Revealed || response.PartnerID != p.Partner || response.PostID != p.PostID {
			return errDatePlanNotFound
		}
	}
	for _, id := range p.PhotoIDs {
		found := false
		for _, ph := range post.Photos {
			if ph.ID == id {
				found = true
			}
		}
		if !found {
			return errDatePlanNotFound
		}
	}
	return nil
}
func readBlogPublication(ctx context.Context, q blogQuerier, id string) (blogPublication, error) {
	p, err := scanBlogPublication(q.QueryRowContext(ctx, blogPublicationSelect+` WHERE id=$1 AND NOT revoked AND moderation_state='active' AND owner_approved AND (partner_id IS NULL OR partner_approved)`, id))
	if err != nil {
		return p, err
	}
	if err = blogPublicationSource(ctx, q, p); err != nil {
		return p, err
	}
	p.Published = true
	return p, nil
}
func createBlogPublication(ctx context.Context, db *sql.DB, actor string, body map[string]any) (blogPublication, error) {
	p := blogPublication{ID: toString(body["id"]), PostID: toString(body["post_id"]), ResponseID: toString(body["response_id"]), Owner: actor, PhotoIDs: []string{}, OwnerApproved: true, Moderation: "active", Version: 1}
	for _, id := range []string{p.ID, p.PostID} {
		if _, err := uuid.Parse(id); err != nil {
			return p, blogInputError("Use a valid publication and chapter ID")
		}
	}
	if body["approved"] != true {
		return p, blogInputError("Preview the exact copy and explicitly approve public sharing")
	}
	version, err := blogVersion(body)
	if err != nil {
		return p, err
	}
	p.SourceVersion = version
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return p, err
	}
	defer tx.Rollback()
	post, err := readBlog(ctx, tx, actor, p.PostID)
	if err != nil {
		return p, err
	}
	if p.ResponseID != "" {
		if _, err = uuid.Parse(p.ResponseID); err != nil {
			return p, blogInputError("Invalid exchange")
		}
		v, e := readBlogResponse(ctx, tx, actor, p.ResponseID)
		if e != nil {
			return p, e
		}
		if !v.Revealed || v.PostID != post.ID {
			return p, errDatePlanForbidden
		}
		p.Partner = v.PartnerID
		p.Joint = true
		p.Title = post.Title
		p.Excerpt = v.AuthorStory + "\n\n" + v.SenderStory
	} else {
		if post.AuthorID != actor {
			return p, errDatePlanForbidden
		}
		p.Title = post.Title
		p.Excerpt = strings.TrimSpace(toString(body["excerpt"]))
		if utf8.RuneCountInString(p.Excerpt) < 1 || utf8.RuneCountInString(p.Excerpt) > 1500 || !strings.Contains(post.Body, p.Excerpt) {
			return p, blogInputError("Select an exact excerpt from your story, up to 1,500 characters")
		}
		raw, ok := body["photo_ids"].([]any)
		if body["photo_ids"] != nil && !ok {
			return p, blogInputError("Choose photos from this chapter")
		}
		seen := map[string]bool{}
		for _, v := range raw {
			id := toString(v)
			if _, err = uuid.Parse(id); err != nil || seen[id] {
				return p, blogInputError("Choose unique chapter photos")
			}
			seen[id] = true
			p.PhotoIDs = append(p.PhotoIDs, id)
		}
		if len(p.PhotoIDs) > 6 {
			return p, blogInputError("Choose up to six photos")
		}
	}
	members := []string{actor, post.AuthorID}
	if p.Partner != "" {
		members = append(members, p.Partner)
	}
	if err = lockBlogMembers(ctx, tx, members...); err != nil {
		return p, err
	}
	old, e := scanBlogPublication(tx.QueryRowContext(ctx, blogPublicationSelect+` WHERE id=$1`, p.ID))
	if e == nil {
		a, _ := json.Marshal(p.PhotoIDs)
		b, _ := json.Marshal(old.PhotoIDs)
		if old.Owner != actor || old.PostID != p.PostID || old.ResponseID != p.ResponseID || old.Excerpt != p.Excerpt || old.SourceVersion != p.SourceVersion || !bytes.Equal(a, b) || old.Revoked {
			return p, errDatingConflict
		}
		return old.view(actor), nil
	}
	if !errors.Is(e, errDatePlanNotFound) {
		return p, e
	}
	if err = blogPublicationSource(ctx, tx, p); err != nil {
		return p, blogInputError("Sharing requires the current community chapter and a completed exchange for joint stories")
	}
	var count int
	if err = tx.QueryRowContext(ctx, `SELECT COUNT(*) FROM matching.blog_publications WHERE owner_id=$1 AND (NOT revoked OR created_at>NOW()-interval '24 hours')`, actor).Scan(&count); err != nil {
		return p, err
	}
	if count >= 20 {
		return p, blogInputError("You have reached the 20 active or recently created link limit")
	}
	_, err = tx.ExecContext(ctx, `INSERT INTO matching.blog_publications(id,post_id,response_id,owner_id,partner_id,title,excerpt,photo_ids,source_version) VALUES($1,$2,NULLIF($3,'')::uuid,$4,NULLIF($5,'')::uuid,$6,$7,ARRAY(SELECT jsonb_array_elements_text($8::jsonb))::uuid[],$9)`, p.ID, p.PostID, p.ResponseID, p.Owner, p.Partner, p.Title, p.Excerpt, jsonStringList(p.PhotoIDs), p.SourceVersion)
	if err != nil {
		return p, err
	}
	if p.Joint {
		err = enqueueNotificationTx(ctx, tx, p.Partner, actor, "blog.publication.requested", "message", p.ID, "blog-share:"+p.ID, "A shared chapter needs your approval", "Read the exact public preview. Nothing is shared until both people approve.", "/blog", map[string]any{"publication_id": p.ID}, 4)
		if err != nil {
			return p, err
		}
	}
	if err = tx.Commit(); err != nil {
		return p, err
	}
	p.Published = !p.Joint
	return p.view(actor), nil
}
func changeBlogPublication(ctx context.Context, db *sql.DB, actor, id, action string, version int) (blogPublication, error) {
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return blogPublication{}, err
	}
	defer tx.Rollback()
	p, err := scanBlogPublication(tx.QueryRowContext(ctx, blogPublicationSelect+` WHERE id=$1 AND (owner_id=$2 OR partner_id=$2)`, id, actor))
	if err != nil {
		return p, err
	}
	if action == "approve" {
		members := []string{p.Owner}
		if p.Joint {
			members = append(members, p.Partner)
		}
		if err = lockBlogMembers(ctx, tx, members...); err != nil {
			return p, err
		}
	}
	p, err = scanBlogPublication(tx.QueryRowContext(ctx, blogPublicationSelect+` WHERE id=$1 FOR UPDATE`, id))
	if err != nil {
		return p, err
	}
	if action == "revoke" {
		if p.Revoked {
			return p.view(actor), nil
		}
		_, err = tx.ExecContext(ctx, `UPDATE matching.blog_publications SET revoked=TRUE,version=version+1 WHERE id=$1`, id)
		p.Revoked = true
		p.Version++
	} else if action == "approve" {
		if p.Revoked || p.Moderation != "active" {
			return p, errDatingConflict
		}
		if err = blogPublicationSource(ctx, tx, p); err != nil {
			return p, err
		}
		if p.view(actor).MyApproval {
			return p.view(actor), nil
		}
		if p.Version != version {
			return p, errDatingConflict
		}
		_, err = tx.ExecContext(ctx, `UPDATE matching.blog_publications SET owner_approved=owner_approved OR owner_id=$2,partner_approved=partner_approved OR partner_id=$2,version=version+1 WHERE id=$1`, id, actor)
		if actor == p.Owner {
			p.OwnerApproved = true
		} else {
			p.PartnerApproved = true
		}
		p.Version++
	} else {
		return p, blogInputError("Choose approve or revoke")
	}
	if err != nil {
		return p, err
	}
	if err = tx.Commit(); err != nil {
		return p, err
	}
	p.Published = !p.Revoked && p.OwnerApproved && (!p.Joint || p.PartnerApproved)
	return p.view(actor), nil
}
func (s *Server) blogPublicationsHandler(w http.ResponseWriter, r *http.Request) {
	actor, err := requestPrincipal(r)
	if err != nil {
		writeError(w, 401, err)
		return
	}
	db, err := s.growthDB()
	if err != nil {
		writeBlogError(w, err)
		return
	}
	w.Header().Set("Cache-Control", "private, no-store")
	id := chi.URLParam(r, "shareID")
	if r.Method == http.MethodDelete {
		if _, err = uuid.Parse(id); err != nil {
			writeBlogError(w, errDatePlanNotFound)
			return
		}
		p, e := changeBlogPublication(r.Context(), db, actor.UserID, id, "revoke", 0)
		if e != nil {
			writeBlogError(w, e)
			return
		}
		writeJSON(w, 200, map[string]any{"publication": p})
		return
	}
	if r.Method != http.MethodGet {
		body, ok := readJSON(w, r)
		if !ok {
			return
		}
		var p blogPublication
		if id == "" {
			p, err = createBlogPublication(r.Context(), db, actor.UserID, body)
		} else {
			if _, err = uuid.Parse(id); err != nil {
				writeBlogError(w, errDatePlanNotFound)
				return
			}
			version, e := blogVersion(body)
			if e != nil {
				writeBlogError(w, e)
				return
			}
			action := toString(body["action"])
			if action == "approve" && body["approved"] != true {
				writeError(w, 400, blogInputError("Approve the exact public preview"))
				return
			}
			p, err = changeBlogPublication(r.Context(), db, actor.UserID, id, action, version)
		}
		if err != nil {
			writeBlogError(w, err)
			return
		}
		writeJSON(w, 200, map[string]any{"publication": p})
		return
	}
	before := r.URL.Query().Get("before")
	if before != "" {
		if _, err = uuid.Parse(before); err != nil {
			writeError(w, 400, blogInputError("Invalid cursor"))
			return
		}
	}
	rows, err := db.QueryContext(r.Context(), blogPublicationSelect+` WHERE (owner_id=$1 OR partner_id=$1) AND NOT revoked AND ($2='' OR (created_at,id)<(SELECT created_at,id FROM matching.blog_publications WHERE id::text=$2 AND (owner_id=$1 OR partner_id=$1))) ORDER BY created_at DESC,id DESC LIMIT 101`, actor.UserID, before)
	if err != nil {
		writeBlogError(w, err)
		return
	}
	items := []blogPublication{}
	for rows.Next() {
		p, e := scanBlogPublication(rows)
		if e != nil {
			err = e
			break
		}
		items = append(items, p.view(actor.UserID))
	}
	if err == nil {
		err = rows.Err()
	}
	rows.Close()
	if err != nil {
		writeBlogError(w, err)
		return
	}
	next := ""
	if len(items) > 100 {
		items = items[:100]
		next = items[99].ID
	}
	for i := range items {
		p := &items[i]
		if blogPublicationSource(r.Context(), db, *p) != nil {
			p.Title = "Sharing unavailable"
			p.Excerpt = "The source changed or access was withdrawn. Revoke this link."
			p.PhotoIDs = []string{}
			continue
		}
		p.Published = p.Moderation == "active" && p.OwnerApproved && (!p.Joint || p.PartnerApproved)
	}
	writeJSON(w, 200, map[string]any{"publications": items, "next_cursor": next})
}
func (s *Server) blogPublicHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Cache-Control", "private, no-store")
	w.Header().Set("Referrer-Policy", "no-referrer")
	w.Header().Set("X-Robots-Tag", "noindex, nofollow, noarchive")
	id := chi.URLParam(r, "shareID")
	if _, err := uuid.Parse(id); err != nil {
		writeBlogError(w, errDatePlanNotFound)
		return
	}
	db, err := s.growthDB()
	if err != nil {
		writeBlogError(w, err)
		return
	}
	tx, err := db.BeginTx(r.Context(), &sql.TxOptions{Isolation: sql.LevelRepeatableRead, ReadOnly: true})
	if err != nil {
		writeBlogError(w, err)
		return
	}
	defer tx.Rollback()
	p, err := readBlogPublication(r.Context(), tx, id)
	if err != nil {
		writeBlogError(w, errDatePlanNotFound)
		return
	}
	photoID := chi.URLParam(r, "photoID")
	if photoID != "" {
		found := false
		for _, ph := range p.PhotoIDs {
			if ph == photoID {
				found = true
			}
		}
		if !found {
			writeBlogError(w, errDatePlanNotFound)
			return
		}
		var path, mime string
		err = tx.QueryRowContext(r.Context(), `SELECT storage_path,mime_type FROM matching.blog_photos WHERE id::text=$1 AND post_id=$2 AND deleted_at IS NULL AND moderation_status='approved'`, photoID, p.PostID).Scan(&path, &mime)
		if err != nil {
			writeBlogError(w, errDatePlanNotFound)
			return
		}
		var content bytes.Buffer
		if err = s.copyPrivateMedia(r.Context(), &content, path); err != nil {
			writeBlogError(w, errDatePlanNotFound)
			return
		}
		w.Header().Set("Content-Type", mime)
		w.Header().Set("X-Content-Type-Options", "nosniff")
		w.Write(content.Bytes())
		return
	}
	post, err := readBlog(r.Context(), tx, p.Owner, p.PostID)
	if err != nil {
		writeBlogError(w, errDatePlanNotFound)
		return
	}
	photos := []blogPhoto{}
	for _, ph := range post.Photos {
		for _, id := range p.PhotoIDs {
			if ph.ID == id {
				photos = append(photos, ph)
			}
		}
	}
	// Public allowlist: no account, source, relationship, response, or location IDs.
	writeJSON(w, 200, map[string]any{"title": p.Title, "excerpt": p.Excerpt, "joint": p.Joint, "photos": photos})
}
