package mobile

import (
	"context"
	"database/sql"
	"errors"
	"net/http"
	"sort"
	"strings"
	"unicode/utf8"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)

type blogResponse struct {
	ID            string `json:"id"`
	PostID        string `json:"post_id"`
	Sender        string `json:"sender_id"`
	Author        string `json:"author_id"`
	Text          string `json:"text"`
	Status        string `json:"status"`
	Version       int    `json:"version"`
	SenderStory   string `json:"-"`
	AuthorStory   string `json:"-"`
	Moderation    string `json:"moderation_state"`
	MyStory       string `json:"my_story"`
	PartnerStory  string `json:"partner_story"`
	PartnerName   string `json:"partner_name"`
	PartnerID     string `json:"partner_id"`
	Revealed      bool   `json:"revealed"`
	Incoming      bool   `json:"incoming"`
	MatchID       string `json:"match_id,omitempty"`
	CanPlan       bool   `json:"can_plan"`
	CanJointShare bool   `json:"can_joint_share"`
}

const blogResponseSelect = `SELECT id::text,post_id::text,sender_id::text,author_id::text,text,status,version,sender_story,author_story,moderation_state FROM matching.blog_responses`

func scanBlogResponse(row datePlanScanner) (blogResponse, error) {
	v := blogResponse{}
	err := row.Scan(&v.ID, &v.PostID, &v.Sender, &v.Author, &v.Text, &v.Status, &v.Version, &v.SenderStory, &v.AuthorStory, &v.Moderation)
	if errors.Is(err, sql.ErrNoRows) {
		err = errDatePlanNotFound
	}
	return v, err
}
func lockBlogMembers(ctx context.Context, tx *sql.Tx, ids ...string) error {
	sort.Strings(ids)
	for i, id := range ids {
		if i > 0 && ids[i-1] == id {
			continue
		}
		if err := lockBlogAuthor(ctx, tx, id); err != nil {
			return err
		}
	}
	return nil
}
func readBlogResponse(ctx context.Context, q blogQuerier, actor, id string) (blogResponse, error) {
	v, err := scanBlogResponse(q.QueryRowContext(ctx, blogResponseSelect+` WHERE id=$1 AND (sender_id=$2 OR author_id=$2)`, id, actor))
	if err != nil {
		return v, err
	}
	if v.Status == "withdrawn" || v.Moderation != "active" {
		return blogResponse{}, errDatePlanNotFound
	}
	// Recheck the sender's access, even when the author is the reader.
	post, e := readBlog(ctx, q, v.Sender, v.PostID)
	if e != nil {
		err = e
		return blogResponse{}, err
	}
	v.Incoming = actor == v.Author
	v.PartnerID = v.Author
	v.MyStory = v.SenderStory
	if v.Incoming {
		v.PartnerID = v.Sender
		v.MyStory = v.AuthorStory
	}
	if err = q.QueryRowContext(ctx, `SELECT COALESCE(name,'Member') FROM user_management.users WHERE id=$1`, v.PartnerID).Scan(&v.PartnerName); err != nil {
		return v, err
	}
	v.Revealed = v.Status == "accepted" && v.SenderStory != "" && v.AuthorStory != ""
	v.CanJointShare = v.Revealed && post.Audience == "community"
	if v.Revealed {
		v.PartnerStory = v.AuthorStory
		if v.Incoming {
			v.PartnerStory = v.SenderStory
		}
	}
	if v.Revealed {
		var match string
		err = q.QueryRowContext(ctx, `SELECT id::text FROM matching.matches WHERE ((user_id_1=$1 AND user_id_2=$2) OR (user_id_1=$2 AND user_id_2=$1)) AND unmatched_at IS NULL AND user_1_status='active' AND user_2_status='active' AND NOT user_1_blocked AND NOT user_2_blocked LIMIT 1`, v.Sender, v.Author).Scan(&match)
		if err != nil && !errors.Is(err, sql.ErrNoRows) {
			return v, err
		}
		v.MatchID = match
	}
	return v, nil
}
func createBlogResponse(ctx context.Context, db *sql.DB, actor, postID, id, text string) (blogResponse, error) {
	text = strings.TrimSpace(text)
	if utf8.RuneCountInString(text) < 1 || utf8.RuneCountInString(text) > 600 {
		return blogResponse{}, blogInputError("Write a response in 1–600 characters")
	}
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return blogResponse{}, err
	}
	defer tx.Rollback()
	post, err := readBlog(ctx, tx, actor, postID)
	if err != nil {
		return blogResponse{}, err
	}
	if post.AuthorID == actor || post.Invitation == "" {
		return blogResponse{}, blogInputError("This chapter is not inviting private responses")
	}
	if err = lockBlogMembers(ctx, tx, actor, post.AuthorID); err != nil {
		return blogResponse{}, err
	}
	post, err = readBlog(ctx, tx, actor, postID)
	if err != nil {
		return blogResponse{}, err
	}
	if post.Invitation == "" {
		return blogResponse{}, errDatingConflict
	}
	old, e := scanBlogResponse(tx.QueryRowContext(ctx, blogResponseSelect+` WHERE id=$1 OR (post_id=$2 AND sender_id=$3)`, id, postID, actor))
	if e == nil {
		if old.ID == id && old.Sender == actor && old.PostID == postID && old.Text == text {
			return readBlogResponse(ctx, tx, actor, id)
		}
		return blogResponse{}, blogInputError("You have already responded to this chapter")
	}
	if !errors.Is(e, errDatePlanNotFound) {
		return blogResponse{}, e
	}
	var recent, pair, incoming int
	err = tx.QueryRowContext(ctx, `SELECT COUNT(*),COUNT(*) FILTER(WHERE author_id=$2) FROM matching.blog_responses WHERE sender_id=$1 AND created_at>NOW()-interval '24 hours'`, actor, post.AuthorID).Scan(&recent, &pair)
	if err != nil {
		return blogResponse{}, err
	}
	if recent >= 5 || pair >= 1 {
		return blogResponse{}, blogInputError("At most five new responses in 24 hours, and one to the same author. Give them time to choose.")
	}
	if err = tx.QueryRowContext(ctx, `SELECT COUNT(*) FROM matching.blog_responses WHERE author_id=$1 AND status='pending'`, post.AuthorID).Scan(&incoming); err != nil {
		return blogResponse{}, err
	}
	if incoming >= 100 {
		return blogResponse{}, blogInputError("This author is not taking more responses right now")
	}
	if _, err = tx.ExecContext(ctx, `INSERT INTO matching.blog_responses(id,post_id,sender_id,author_id,text) VALUES($1,$2,$3,$4,$5)`, id, postID, actor, post.AuthorID, text); err != nil {
		return blogResponse{}, err
	}
	err = enqueueNotificationTx(ctx, tx, post.AuthorID, actor, "blog.response.created", "message", id, "blog-response:"+id, "A chapter has a private response", "Read it when you are ready. Accepting is always your choice.", "/blog", map[string]any{"response_id": id}, 4)
	if err != nil {
		return blogResponse{}, err
	}
	if err = tx.Commit(); err != nil {
		return blogResponse{}, err
	}
	return readBlogResponse(ctx, db, actor, id)
}
func changeBlogResponse(ctx context.Context, db *sql.DB, actor, id, action, text string, version int) (blogResponse, error) {
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return blogResponse{}, err
	}
	defer tx.Rollback()
	v, err := scanBlogResponse(tx.QueryRowContext(ctx, blogResponseSelect+` WHERE id=$1 AND (sender_id=$2 OR author_id=$2)`, id, actor))
	if err != nil {
		return v, err
	}
	// Withdrawal must work after a block, unfriend, or audience change.
	if action != "withdraw" {
		if err = lockBlogMembers(ctx, tx, v.Sender, v.Author); err != nil {
			return v, err
		}
	}
	v, err = scanBlogResponse(tx.QueryRowContext(ctx, blogResponseSelect+` WHERE id=$1 FOR UPDATE`, id))
	if err != nil {
		return v, err
	}
	if action == "withdraw" {
		_, err = tx.ExecContext(ctx, `UPDATE matching.blog_responses SET status='withdrawn',version=version+1,updated_at=NOW() WHERE id=$1 AND status<>'withdrawn'`, id)
		if err == nil {
			_, err = tx.ExecContext(ctx, `UPDATE matching.blog_publications SET revoked=TRUE,version=version+1 WHERE response_id=$1 AND NOT revoked`, id)
		}
		if err != nil {
			return v, err
		}
		v.Status = "withdrawn"
		v.Text = ""
		v.MyStory = ""
		v.SenderStory = ""
		v.AuthorStory = ""
		return v, tx.Commit()
	}
	if _, err = readBlogResponse(ctx, tx, actor, id); err != nil {
		return v, err
	}
	text = strings.TrimSpace(text)
	own := v.SenderStory
	if actor == v.Author {
		own = v.AuthorStory
	}
	if (action == "accept" && v.Status == "accepted" && actor == v.Author) || (action == "decline" && v.Status == "declined" && actor == v.Author) || (action == "contribute" && own != "" && own == text) {
		return readBlogResponse(ctx, tx, actor, id)
	}
	// Each contribution is written once to a separate participant slot. A partner
	// submitting concurrently must not make the other person lose their draft.
	concurrentPartner := action == "contribute" && v.Status == "accepted" && own == "" && v.Version == version+1 && (v.SenderStory != "" || v.AuthorStory != "")
	if v.Version != version && !concurrentPartner {
		return v, errDatingConflict
	}
	switch action {
	case "accept", "decline":
		if actor != v.Author || v.Status != "pending" {
			return v, errDatePlanForbidden
		}
		status := "accepted"
		if action == "decline" {
			status = "declined"
		}
		_, err = tx.ExecContext(ctx, `UPDATE matching.blog_responses SET status=$2,version=version+1,updated_at=NOW() WHERE id=$1`, id, status)
		if err == nil && action == "accept" {
			err = enqueueNotificationTx(ctx, tx, v.Sender, v.Author, "blog.response.accepted", "message", id, "blog-accepted:"+id, "A Chapter exchange is ready", "You can each add a small story. Contributions are revealed only when both are ready.", "/blog", map[string]any{"response_id": id}, 4)
		}
	case "contribute":
		if v.Status != "accepted" || own != "" {
			return v, errDatingConflict
		}
		if utf8.RuneCountInString(text) < 1 || utf8.RuneCountInString(text) > 1000 {
			return v, blogInputError("Use 1–1,000 characters for your contribution")
		}
		var contributions int
		if err = tx.QueryRowContext(ctx, `SELECT COUNT(*) FROM matching.blog_responses WHERE (sender_id=$1 AND sender_contributed_at>NOW()-interval '24 hours') OR (author_id=$1 AND author_contributed_at>NOW()-interval '24 hours')`, actor).Scan(&contributions); err != nil {
			return v, err
		}
		if contributions >= 10 {
			return v, blogInputError("You can add up to ten exchange contributions in 24 hours")
		}
		_, err = tx.ExecContext(ctx, `UPDATE matching.blog_responses SET sender_story=CASE WHEN sender_id=$2 THEN $3 ELSE sender_story END,author_story=CASE WHEN author_id=$2 THEN $3 ELSE author_story END,sender_contributed_at=CASE WHEN sender_id=$2 THEN NOW() ELSE sender_contributed_at END,author_contributed_at=CASE WHEN author_id=$2 THEN NOW() ELSE author_contributed_at END,version=version+1,updated_at=NOW() WHERE id=$1`, id, actor, text)
		other := v.AuthorStory
		partner := v.Author
		if actor == v.Author {
			other = v.SenderStory
			partner = v.Sender
		}
		if err == nil && other != "" {
			err = enqueueNotificationTx(ctx, tx, partner, actor, "blog.exchange.revealed", "message", id, "blog-revealed:"+id, "Your shared chapter is ready", "Both contributions are ready to read in your private exchange.", "/blog", map[string]any{"response_id": id}, 4)
		}
	default:
		return v, blogInputError("Choose accept, decline, contribute or withdraw")
	}
	if err != nil {
		return v, err
	}
	if err = tx.Commit(); err != nil {
		return v, err
	}
	return readBlogResponse(ctx, db, actor, id)
}
func blogVersion(body map[string]any) (int, error) {
	v, ok := body["expected_version"].(float64)
	if !ok || v < 1 || v > 2147483646 || float64(int(v)) != v {
		return 0, blogInputError("A current expected_version is required")
	}
	return int(v), nil
}

// A lost-success replay consumes no new message allowance. Domain reads still
// recheck current access before returning any private content.
func blogResponseReplay(ctx context.Context, db *sql.DB, actor, id, text string, contribution bool) (bool, error) {
	var exists bool
	query := `SELECT EXISTS(SELECT 1 FROM matching.blog_responses WHERE id=$1 AND sender_id=$2 AND text=$3)`
	if contribution {
		query = `SELECT EXISTS(SELECT 1 FROM matching.blog_responses WHERE id=$1 AND status='accepted' AND ((sender_id=$2 AND sender_story=$3 AND sender_story<>'') OR (author_id=$2 AND author_story=$3 AND author_story<>'')))`
	}
	err := db.QueryRowContext(ctx, query, id, actor, strings.TrimSpace(text)).Scan(&exists)
	return exists, err
}
func (s *Server) blogResponsesHandler(w http.ResponseWriter, r *http.Request) {
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
	id := chi.URLParam(r, "responseID")
	if id != "" {
		if _, err = uuid.Parse(id); err != nil {
			writeBlogError(w, errDatePlanNotFound)
			return
		}
	}
	if r.Method == http.MethodDelete {
		v, e := changeBlogResponse(r.Context(), db, actor.UserID, id, "withdraw", "", 0)
		if e != nil {
			writeBlogError(w, e)
			return
		}
		writeJSON(w, 200, map[string]any{"response": v})
		return
	}
	if r.Method == http.MethodPost {
		body, ok := readJSON(w, r)
		if !ok {
			return
		}
		var result blogResponse
		if id == "" {
			id = toString(body["id"])
			post := toString(body["post_id"])
			for _, x := range []string{id, post} {
				if _, err = uuid.Parse(x); err != nil {
					writeError(w, 400, blogInputError("Use a valid chapter and response ID"))
					return
				}
			}
			replay, e := blogResponseReplay(r.Context(), db, actor.UserID, id, toString(body["text"]), false)
			if e != nil {
				writeBlogError(w, e)
				return
			}
			if !replay && !s.enforceDailyQuota(w, r, actor.UserID, "message") {
				return
			}
			result, err = createBlogResponse(r.Context(), db, actor.UserID, post, id, toString(body["text"]))
		} else {
			action := toString(body["action"])
			version, e := blogVersion(body)
			if e != nil {
				writeBlogError(w, e)
				return
			}
			if action == "contribute" {
				replay, e := blogResponseReplay(r.Context(), db, actor.UserID, id, toString(body["text"]), true)
				if e != nil {
					writeBlogError(w, e)
					return
				}
				if !replay && !s.enforceDailyQuota(w, r, actor.UserID, "message") {
					return
				}
			}
			result, err = changeBlogResponse(r.Context(), db, actor.UserID, id, action, toString(body["text"]), version)
		}
		if err != nil {
			writeBlogError(w, err)
			return
		}
		writeJSON(w, 200, map[string]any{"response": result})
		return
	}
	if id != "" {
		v, e := readBlogResponse(r.Context(), db, actor.UserID, id)
		if e != nil {
			writeBlogError(w, e)
			return
		}
		if v.MatchID != "" {
			v.CanPlan, _ = s.chatUnlockedForPlan(v.MatchID)
		}
		writeJSON(w, 200, map[string]any{"response": v})
		return
	}
	before := r.URL.Query().Get("before")
	if before != "" {
		if _, err = uuid.Parse(before); err != nil {
			writeError(w, 400, blogInputError("Invalid cursor"))
			return
		}
	}
	rows, err := db.QueryContext(r.Context(), `SELECT id::text FROM matching.blog_responses WHERE (sender_id=$1 OR author_id=$1) AND status<>'withdrawn' AND ($2='' OR (created_at,id)<(SELECT created_at,id FROM matching.blog_responses WHERE id::text=$2)) ORDER BY created_at DESC,id DESC LIMIT 51`, actor.UserID, before)
	if err != nil {
		writeBlogError(w, err)
		return
	}
	ids := []string{}
	for rows.Next() {
		var x string
		if err = rows.Scan(&x); err != nil {
			break
		}
		ids = append(ids, x)
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
	if len(ids) > 50 {
		ids = ids[:50]
		next = ids[49]
	}
	items := []blogResponse{}
	for _, x := range ids {
		v, e := readBlogResponse(r.Context(), db, actor.UserID, x)
		if errors.Is(e, errDatePlanNotFound) || errors.Is(e, errDatePlanForbidden) {
			continue
		}
		if e != nil {
			writeBlogError(w, e)
			return
		}
		items = append(items, v)
	}
	writeJSON(w, 200, map[string]any{"responses": items, "next_cursor": next})
}
