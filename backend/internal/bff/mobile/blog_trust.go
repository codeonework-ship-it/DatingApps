package mobile

import (
	"bytes"
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"net/http"
	"strconv"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)

func validBlogReason(s string) bool {
	return s == "harassment" || s == "inappropriate" || s == "fraud" || s == "fake"
}
func createBlogCase(ctx context.Context, db *sql.DB, actor, kind, id, reason, description string) (string, error) {
	if !validBlogReason(reason) || utf8.RuneCountInString(description) > 1000 {
		return "", blogInputError("Choose a report reason and use up to 1,000 characters")
	}
	if _, err := uuid.Parse(id); err != nil {
		return "", errDatePlanNotFound
	}
	tx, err := db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelRepeatableRead})
	if err != nil {
		return "", err
	}
	defer tx.Rollback()
	var snapshot any
	subject := ""
	photos := []string{}
	switch kind {
	case "post":
		if actor == "" {
			return "", errDatePlanForbidden
		}
		p, e := readBlog(ctx, tx, actor, id)
		if e != nil {
			return "", e
		}
		subject = p.AuthorID
		snapshot = p
		for _, ph := range p.Photos {
			photos = append(photos, ph.ID)
		}
	case "response":
		if actor == "" {
			return "", errDatePlanForbidden
		}
		v, e := readBlogResponse(ctx, tx, actor, id)
		if e != nil {
			return "", e
		}
		if !v.Incoming && !v.Revealed {
			return "", blogInputError("There is no revealed partner contribution to report")
		}
		subject = v.PartnerID
		partnerText := ""
		if v.Incoming {
			partnerText = v.Text
		}
		snapshot = map[string]any{"text": partnerText, "partner_story": v.PartnerStory, "version": v.Version, "status": v.Status}
	case "publication":
		p, e := readBlogPublication(ctx, tx, id)
		if e != nil {
			return "", e
		}
		subject = p.Owner
		snapshot = map[string]any{"title": p.Title, "excerpt": p.Excerpt, "joint": p.Joint}
		photos = p.PhotoIDs
	default:
		if activityModerationTables[kind] == "" {
			return "", blogInputError("Unknown report content")
		}
		if actor == "" {
			return "", errDatePlanForbidden
		}
		subject, snapshot, photos, err = readActivityForReport(ctx, tx, actor, kind, id)
		if err != nil {
			return "", err
		}
	}
	if subject == actor {
		return "", blogInputError("You can edit or remove your own content")
	}
	// Serialize evidence capture with account erasure and author edits.
	if err = lockBlogAuthor(ctx, tx, subject); err != nil {
		return "", err
	}
	key := "member:" + actor
	// No visitor fingerprint or private identity is collected. Duplicate public
	// reports of the same category/day are acknowledged without queue flooding.
	if actor == "" {
		key = "visitor:" + time.Now().UTC().Format("2006-01-02") + ":" + reason
	}
	caseID := uuid.NewString()
	newID := caseID
	raw, err := json.Marshal(snapshot)
	if err != nil {
		return "", err
	}
	err = tx.QueryRowContext(ctx, `INSERT INTO matching.blog_cases(id,content_type,content_id,subject_id,reporter_id,reporter_key,reason,description,snapshot,photo_ids) VALUES($1,$2,$3,$4,NULLIF($5,'')::uuid,$6,$7,$8,$9::jsonb,ARRAY(SELECT jsonb_array_elements_text($10::jsonb))::uuid[]) ON CONFLICT(content_type,content_id,reporter_key) DO UPDATE SET reporter_key=EXCLUDED.reporter_key RETURNING id::text`, caseID, kind, id, subject, actor, key, reason, description, string(raw), jsonStringList(photos)).Scan(&caseID)
	if err != nil {
		return "", err
	}
	if caseID != newID {
		return caseID, nil
	}
	// A first report's snapshot is immutable through all member/operator APIs.
	evidenceSource := "matching.blog_photos"
	if kind == "theme_entry" {
		evidenceSource = "matching.photo_theme_entries"
	}
	if kind == "group" {
		// The group's cover photo (migration 121).
		evidenceSource = "matching.community_group_covers"
	}
	for _, photo := range photos {
		_, err = tx.ExecContext(ctx, `INSERT INTO matching.blog_evidence_photos(case_id,photo_id,storage_path,alt_text,mime_type) SELECT $1,id,storage_path,alt_text,mime_type FROM `+evidenceSource+` WHERE id=$2 AND deleted_at IS NULL AND moderation_status='approved' ON CONFLICT DO NOTHING`, caseID, photo)
		if err != nil {
			return "", err
		}
	}
	return caseID, tx.Commit()
}
func (s *Server) blogReportHandler(w http.ResponseWriter, r *http.Request) {
	actor := ""
	if principal, ok := principalFromRequest(r); ok {
		actor = principal.UserID
	}
	kind := chi.URLParam(r, "kind")
	id := chi.URLParam(r, "contentID")
	if chi.URLParam(r, "postID") != "" {
		kind = "post"
		id = chi.URLParam(r, "postID")
	}
	if chi.URLParam(r, "shareID") != "" {
		kind = "publication"
		id = chi.URLParam(r, "shareID")
	}
	if actor == "" && kind != "publication" {
		writeError(w, 401, errors.New("Sign in to report this content"))
		return
	}
	body, ok := readJSON(w, r)
	if !ok {
		return
	}
	db, err := s.growthDB()
	if err != nil {
		writeBlogError(w, err)
		return
	}
	caseID, err := createBlogCase(r.Context(), db, actor, kind, id, toString(body["reason"]), strings.TrimSpace(toString(body["description"])))
	if err != nil {
		writeBlogError(w, err)
		return
	}
	w.Header().Set("Cache-Control", "no-store")
	result := map[string]any{"accepted": true}
	if actor != "" {
		result["report"] = map[string]any{"id": caseID}
	}
	writeJSON(w, 200, result)
}
func blogModerator(r *http.Request) (string, error) {
	p, ok := principalFromRequest(r)
	if !ok || (!p.Roles["admin"] && !p.Roles["moderator"] && !p.Roles["trust_safety"]) {
		return "", errDatePlanForbidden
	}
	return p.UserID, nil
}
func (s *Server) blogReviewHandler(w http.ResponseWriter, r *http.Request) {
	actor, err := blogModerator(r)
	if err != nil {
		writeError(w, 403, err)
		return
	}
	db, err := s.growthDB()
	if err != nil {
		writeBlogError(w, err)
		return
	}
	w.Header().Set("Cache-Control", "private, no-store")
	id := chi.URLParam(r, "caseID")
	if id != "" {
		if _, err = uuid.Parse(id); err != nil {
			writeBlogError(w, errDatePlanNotFound)
			return
		}
	}
	if r.Method == http.MethodPost {
		body, ok := readJSON(w, r)
		if !ok {
			return
		}
		version, e := blogVersion(body)
		if e != nil {
			writeBlogError(w, e)
			return
		}
		err = decideBlogCase(r.Context(), db, actor, id, toString(body["decision"]), strings.TrimSpace(toString(body["note"])), version)
		if err != nil {
			writeBlogError(w, err)
			return
		}
		writeJSON(w, 200, map[string]any{"reviewed": true})
		return
	}
	if photo := chi.URLParam(r, "photoID"); photo != "" {
		var path, mime string
		err = db.QueryRowContext(r.Context(), `SELECT e.storage_path,e.mime_type FROM matching.blog_evidence_photos e JOIN matching.blog_cases c ON c.id=e.case_id WHERE e.case_id=$1 AND e.photo_id::text=$2 AND c.evidence_purged_at IS NULL`, id, photo).Scan(&path, &mime)
		if err != nil {
			writeBlogError(w, errDatePlanNotFound)
			return
		}
		var b bytes.Buffer
		if err = s.copyPrivateMedia(r.Context(), &b, path); err != nil {
			writeBlogError(w, errDatePlanNotFound)
			return
		}
		w.Header().Set("Content-Type", mime)
		w.Header().Set("X-Content-Type-Options", "nosniff")
		w.Write(b.Bytes())
		return
	}
	status := r.URL.Query().Get("status")
	if status == "" {
		status = "pending"
	}
	if status != "pending" && status != "removed" && status != "dismissed" && status != "restored" {
		writeError(w, 400, blogInputError("Unknown queue status"))
		return
	}
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	if offset < 0 || offset > 100000 {
		writeError(w, 400, blogInputError("Invalid queue page"))
		return
	}
	rows, err := db.QueryContext(r.Context(), `SELECT jsonb_build_object('id',id,'content_type',content_type,'content_id',content_id,'subject_id',subject_id,'reason',reason,'description',description,'snapshot',snapshot,'photo_ids',photo_ids,'status',status,'decision_note',decision_note,'appeal',appeal,'version',version,'created_at',created_at,'review_due_at',review_due_at,'overdue',status='pending' AND review_due_at<NOW(),'evidence_purged',evidence_purged_at IS NOT NULL) FROM matching.blog_cases WHERE status=$1 ORDER BY review_due_at,id LIMIT 100 OFFSET $2`, status, offset)
	if err != nil {
		writeBlogError(w, err)
		return
	}
	items := []json.RawMessage{}
	for rows.Next() {
		var raw json.RawMessage
		if err = rows.Scan(&raw); err != nil {
			break
		}
		items = append(items, raw)
	}
	if err == nil {
		err = rows.Err()
	}
	rows.Close()
	if err != nil {
		writeBlogError(w, err)
		return
	}
	metrics := map[string]int{}
	queries := map[string]string{
		"published_chapters": `SELECT COUNT(*) FROM matching.blog_posts WHERE deleted_at IS NULL AND audience<>'private' AND moderation_state='active'`,
		"responses":          `SELECT COUNT(*) FROM matching.blog_responses`, "accepted_responses": `SELECT COUNT(*) FROM matching.blog_responses WHERE status='accepted'`,
		"revealed_exchanges":  `SELECT COUNT(*) FROM matching.blog_responses WHERE status='accepted' AND sender_story<>'' AND author_story<>'' AND moderation_state='active'`,
		"date_plans":          `SELECT COUNT(*) FROM matching.match_date_plans WHERE source_blog_response_id IS NOT NULL`,
		"accepted_date_plans": `SELECT COUNT(*) FROM matching.match_date_plans WHERE source_blog_response_id IS NOT NULL AND status='accepted'`,
		"theme_photos":        `SELECT COUNT(*) FROM matching.photo_theme_entries WHERE deleted_at IS NULL AND moderation_state='active'`,
		"active_clubs":        `SELECT COUNT(*) FROM matching.clubs WHERE deleted_at IS NULL AND moderation_state='active'`,
		"club_posts":          `SELECT COUNT(*) FROM matching.club_posts WHERE deleted_at IS NULL AND moderation_state='active'`,
		"title_reviews":       `SELECT COUNT(*) FROM matching.title_reviews WHERE deleted_at IS NULL AND moderation_state='active' AND audience<>'private'`,
		"pending_reviews":     `SELECT COUNT(*) FROM matching.blog_cases WHERE status='pending'`,
		"overdue_reviews":     `SELECT COUNT(*) FROM matching.blog_cases WHERE status='pending' AND review_due_at<NOW()`,
	}
	for key, q := range queries {
		var n int
		if err = db.QueryRowContext(r.Context(), q).Scan(&n); err != nil {
			writeBlogError(w, err)
			return
		}
		metrics[key] = n
	}
	writeJSON(w, 200, map[string]any{"cases": items, "metrics": metrics, "limit": 100, "offset": offset, "has_more": len(items) == 100})
}
func decideBlogCase(ctx context.Context, db *sql.DB, actor, id, decision, note string, version int) error {
	if decision != "removed" && decision != "dismissed" && decision != "restored" {
		return blogInputError("Choose remove, dismiss or restore")
	}
	if utf8.RuneCountInString(note) < 5 || utf8.RuneCountInString(note) > 1000 {
		return blogInputError("Record a decision reason in 5–1,000 characters")
	}
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()
	var kind, content, subject, status, appeal string
	var current int
	if err = tx.QueryRowContext(ctx, `SELECT content_type,content_id::text,subject_id::text,status,version,appeal FROM matching.blog_cases WHERE id=$1 FOR UPDATE`, id).Scan(&kind, &content, &subject, &status, &current, &appeal); err != nil {
		return err
	}
	if current != version {
		return errDatingConflict
	}
	if decision == "dismissed" && (appeal != "" || status == "removed") {
		return blogInputError("Choose restore content or uphold removal when reviewing an appeal")
	}
	otherRemoval := false
	if decision == "restored" {
		var other bool
		if err = tx.QueryRowContext(ctx, `SELECT EXISTS(SELECT 1 FROM matching.blog_cases WHERE content_type=$1 AND content_id=$2 AND id<>$3 AND (status='removed' OR (status='pending' AND appeal<>'')))`, kind, content, id).Scan(&other); err != nil {
			return err
		}
		otherRemoval = other
		if other {
			note = string([]rune(note)[:min(len([]rune(note)), 900)]) + " (Another removal case still restricts this content.)"
		}
	}
	if decision != "dismissed" {
		state := "removed"
		if decision == "restored" && !otherRemoval {
			state = "active"
		}
		table := map[string]string{"post": "blog_posts", "response": "blog_responses", "publication": "blog_publications"}[kind]
		if table == "" {
			table = activityModerationTables[kind]
		}
		if table == "" {
			return errDatePlanNotFound
		}
		extra := ""
		if kind == "publication" {
			extra = ",revoked=TRUE"
		} // Restoration never reuses consent for a removed public copy.
		result, e := tx.ExecContext(ctx, `UPDATE matching.`+table+` SET moderation_state=$2,version=version+1`+extra+` WHERE id=$1`, content, state)
		if e != nil {
			return e
		}
		affected, e := result.RowsAffected()
		if e != nil {
			return e
		}
		if decision == "restored" && affected == 0 {
			return blogInputError("The source was deleted and cannot be restored")
		}
	}
	if _, err = tx.ExecContext(ctx, `UPDATE matching.blog_cases SET status=$2,decision_note=$3,version=version+1,resolved_at=NOW() WHERE id=$1`, id, decision, note); err != nil {
		return err
	}
	if _, err = tx.ExecContext(ctx, `INSERT INTO matching.blog_case_actions(case_id,actor_id,action,note) VALUES($1,$2,$3,$4)`, id, actor, decision, note); err != nil {
		return err
	}
	noticeTitle := "A chapter review has an update"
	if activityModerationTables[kind] != "" {
		noticeTitle = "A review of something you shared has an update"
	}
	err = enqueueNotificationTx(ctx, tx, subject, actor, "blog.review.completed", "system", id, "blog-review:"+id+":"+decision+":"+toString(version), noticeTitle, "Open your private review notices for the decision and appeal options.", "/blog", map[string]any{"case_id": id, "content_type": kind}, 4)
	if err != nil {
		return err
	}
	return tx.Commit()
}
func (s *Server) blogNoticesHandler(w http.ResponseWriter, r *http.Request) {
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
	if r.Method == http.MethodPost {
		id := chi.URLParam(r, "caseID")
		if _, err = uuid.Parse(id); err != nil {
			writeBlogError(w, errDatePlanNotFound)
			return
		}
		body, ok := readJSON(w, r)
		if !ok {
			return
		}
		version, e := blogVersion(body)
		text := strings.TrimSpace(toString(body["text"]))
		if e != nil || utf8.RuneCountInString(text) < 5 || utf8.RuneCountInString(text) > 1000 {
			writeError(w, 400, blogInputError("Use a current version and an appeal of 5–1,000 characters"))
			return
		}
		tx, e := db.BeginTx(r.Context(), nil)
		if e != nil {
			writeBlogError(w, e)
			return
		}
		defer tx.Rollback()
		result, e := tx.ExecContext(r.Context(), `UPDATE matching.blog_cases SET appeal=$3,status='pending',resolved_at=NULL,review_due_at=NOW()+interval '24 hours',version=version+1 WHERE id=$1 AND subject_id=$2 AND status='removed' AND appeal='' AND version=$4 AND evidence_purged_at IS NULL`, id, actor.UserID, text, version)
		if e != nil {
			writeBlogError(w, e)
			return
		}
		n, _ := result.RowsAffected()
		if n != 1 {
			writeBlogError(w, errDatingConflict)
			return
		}
		if _, e = tx.ExecContext(r.Context(), `INSERT INTO matching.blog_case_actions(case_id,actor_id,action,note) VALUES($1,$2,'appealed',$3)`, id, actor.UserID, text); e != nil {
			writeBlogError(w, e)
			return
		}
		if e = tx.Commit(); e != nil {
			writeBlogError(w, e)
			return
		}
		writeJSON(w, 200, map[string]any{"appealed": true})
		return
	}
	before := r.URL.Query().Get("before")
	if before != "" {
		if _, err = uuid.Parse(before); err != nil {
			writeError(w, 400, blogInputError("Invalid cursor"))
			return
		}
	}
	rows, err := db.QueryContext(r.Context(), `SELECT jsonb_build_object('id',id,'content_type',content_type,'content_id',content_id,'status',status,'decision_note',decision_note,'appeal',appeal,'version',version,'can_appeal',status='removed' AND appeal='' AND evidence_purged_at IS NULL) FROM matching.blog_cases WHERE subject_id=$1 AND (status<>'pending' OR appeal<>'') AND ($2='' OR (created_at,id)<(SELECT created_at,id FROM matching.blog_cases WHERE id::text=$2 AND subject_id=$1)) ORDER BY created_at DESC,id DESC LIMIT 101`, actor.UserID, before)
	if err != nil {
		writeBlogError(w, err)
		return
	}
	defer rows.Close()
	items := []json.RawMessage{}
	for rows.Next() {
		var raw json.RawMessage
		if err = rows.Scan(&raw); err != nil {
			writeBlogError(w, err)
			return
		}
		items = append(items, raw)
	}
	if err = rows.Err(); err != nil {
		writeBlogError(w, err)
		return
	}
	next := ""
	if len(items) > 100 {
		items = items[:100]
		var tail struct {
			ID string `json:"id"`
		}
		if json.Unmarshal(items[99], &tail) != nil {
			writeError(w, 500, errors.New("Unable to read page"))
			return
		}
		next = tail.ID
	}
	writeJSON(w, 200, map[string]any{"notices": items, "next_cursor": next})
}

// Resolved evidence has a bounded retention period; legal holds defer purging.
func (s *Server) cleanupBlogEvidence(ctx context.Context) {
	db, err := s.growthDB()
	if err != nil {
		return
	}
	// Keep command tombstones and quota timestamps, but remove withdrawn prose.
	if _, err = db.ExecContext(ctx, `UPDATE matching.blog_responses SET text='[withdrawn]',sender_story='',author_story='' WHERE status='withdrawn' AND (text<>'[withdrawn]' OR sender_story<>'' OR author_story<>'') AND NOT platform.member_on_legal_hold(sender_id) AND NOT platform.member_on_legal_hold(author_id)`); err != nil {
		return
	}
	if _, err = db.ExecContext(ctx, `UPDATE matching.blog_publications SET title='[withdrawn]',excerpt='[withdrawn]',photo_ids='{}' WHERE revoked AND excerpt<>'[withdrawn]' AND NOT platform.member_on_legal_hold(owner_id) AND (partner_id IS NULL OR NOT platform.member_on_legal_hold(partner_id))`); err != nil {
		return
	}
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return
	}
	defer tx.Rollback()
	rows, err := tx.QueryContext(ctx, `UPDATE matching.blog_cases SET snapshot='{}',description='',appeal='',decision_note='Evidence retention period ended',photo_ids='{}',evidence_purged_at=NOW() WHERE id IN(SELECT id FROM matching.blog_cases WHERE status<>'pending' AND resolved_at<NOW()-interval '90 days' AND evidence_purged_at IS NULL AND NOT platform.member_on_legal_hold(subject_id) ORDER BY resolved_at LIMIT 100 FOR UPDATE SKIP LOCKED) RETURNING id::text`)
	if err != nil {
		return
	}
	ids := []string{}
	for rows.Next() {
		var id string
		if rows.Scan(&id) != nil {
			rows.Close()
			return
		}
		ids = append(ids, id)
	}
	err = rows.Err()
	rows.Close()
	if err != nil {
		return
	}
	paths := []string{}
	for _, id := range ids {
		if _, err = tx.ExecContext(ctx, `UPDATE matching.blog_case_actions SET note='Evidence retention period ended' WHERE case_id=$1`, id); err != nil {
			return
		}
		rows, err = tx.QueryContext(ctx, `DELETE FROM matching.blog_evidence_photos WHERE case_id=$1 RETURNING storage_path`, id)
		if err != nil {
			return
		}
		for rows.Next() {
			var p string
			if rows.Scan(&p) != nil {
				rows.Close()
				return
			}
			paths = append(paths, p)
		}
		err = rows.Err()
		rows.Close()
		if err != nil {
			return
		}
	}
	for _, p := range paths {
		if _, err = tx.ExecContext(ctx, `INSERT INTO matching.blog_media_deletions(storage_path) VALUES($1) ON CONFLICT DO NOTHING`, p); err != nil {
			return
		}
	}
	if err = tx.Commit(); err != nil {
		return
	}
	pending, e := db.QueryContext(ctx, `SELECT storage_path FROM matching.blog_media_deletions ORDER BY created_at LIMIT 100`)
	if e != nil {
		return
	}
	paths = nil
	for pending.Next() {
		var p string
		if pending.Scan(&p) != nil {
			pending.Close()
			return
		}
		paths = append(paths, p)
	}
	e = pending.Err()
	pending.Close()
	if e != nil {
		return
	}
	for _, p := range paths {
		var referenced bool
		err = db.QueryRowContext(ctx, `SELECT EXISTS(SELECT 1 FROM matching.blog_photos WHERE storage_path=$1 UNION ALL SELECT 1 FROM matching.photo_theme_entries WHERE storage_path=$1 UNION ALL SELECT 1 FROM matching.blog_evidence_photos WHERE storage_path=$1 UNION ALL SELECT 1 FROM matching.community_group_covers WHERE storage_path=$1 AND storage_released_at IS NULL)`, p).Scan(&referenced)
		if err == nil && !referenced {
			if s.deleteStoredMedia(p) == nil {
				_, _ = db.ExecContext(ctx, `DELETE FROM matching.blog_media_deletions WHERE storage_path=$1`, p)
			}
		}
	}
}
