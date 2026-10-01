package mobile

import (
	"bytes"
	"context"
	"encoding/json"
	"image"
	"image/jpeg"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/verified-dating/backend/internal/platform/config"
)

func TestActivityRoutesUseTheirOwnFlags(t *testing.T) {
	for path, want := range map[string]string{
		"/v1/themes":                        "photo_themes_enabled",
		"/v1/themes/a/entries/b":            "photo_themes_enabled",
		"/v1/clubs":                         "clubs_enabled",
		"/v1/clubs/titles":                  "clubs_enabled",
		"/v1/clubs/a/posts/b/visibility":    "clubs_enabled",
		"/v1/blog/reports/club_post/abc":    "intentional_dating_enabled",
		"/v1/admin/engagement/photo-themes": "",
		"/v1/themes-not-a-real-route/thing": "",
	} {
		if got := featureFlagForRoute("/v1", path); got != want {
			t.Errorf("%s gated by %q, want %q", path, got, want)
		}
	}
	upload := httptest.NewRequest(http.MethodPut, "/v1/themes/a/entries/b", nil)
	s := &Server{cfg: config.Config{APIPrefix: "/v1"}}
	if s.shouldApplyIdempotency(upload) {
		t.Error("multipart theme uploads must stay out of the replay ledger")
	}
}

func TestClubInputHelpers(t *testing.T) {
	if normalizeTitleText("  The   Remains of\tthe DAY ") != "the remains of the day" {
		t.Fatal("title normalization")
	}
	if _, err := clubVersion(map[string]any{"expected_version": 0.0}, false); err == nil {
		t.Fatal("zero version accepted where an edit is required")
	}
	if v, err := clubVersion(map[string]any{"expected_version": 0.0}, true); err != nil || v != 0 {
		t.Fatal("create version rejected")
	}
	if _, err := clubVersion(map[string]any{"expected_version": 1.5}, true); err == nil {
		t.Fatal("fractional version accepted")
	}
}

type activityFixture struct {
	datePlanFixture
	s *Server
}

func newActivityFixture(t *testing.T) activityFixture {
	f := newBlogTrustFixture(t)
	var ready bool
	if err := f.db.QueryRow(`SELECT to_regclass('matching.club_posts') IS NOT NULL`).Scan(&ready); err != nil || !ready {
		t.Skip("migration 107_photo_themes_and_book_film_clubs is not applied")
	}
	members := []string{f.proposer, f.invitee, f.proposerFriend, f.inviteeFriend, f.blockedFriend, f.groupMate, f.stranger}
	t.Cleanup(func() {
		// Runs before the fixture deletes members: titles and selections have
		// no cascade from the member, and cases reference the subject.
		for _, q := range []string{
			`DELETE FROM matching.clubs WHERE owner_id = ANY($1::uuid[])`,
			`DELETE FROM matching.title_reviews WHERE author_id = ANY($1::uuid[])`,
			`DELETE FROM matching.member_lists WHERE owner_id = ANY($1::uuid[])`,
			`DELETE FROM matching.photo_theme_entries WHERE author_id = ANY($1::uuid[])`,
			`DELETE FROM matching.club_titles t WHERE created_by = ANY($1::uuid[]) AND NOT EXISTS(SELECT 1 FROM matching.club_selections s WHERE s.title_id=t.id) AND NOT EXISTS(SELECT 1 FROM matching.title_reviews r WHERE r.title_id=t.id) AND NOT EXISTS(SELECT 1 FROM matching.member_list_items i WHERE i.title_id=t.id)`,
		} {
			_, _ = f.db.Exec(q, "{"+strings.Join(members, ",")+"}")
		}
	})
	s := &Server{cfg: config.Config{MediaUploadsDir: t.TempDir()}, store: &runtimeStore{profileRepo: &profileRepository{pg: f.db}}, mediaModerator: localValidationModerator{}}
	return activityFixture{datePlanFixture: f, s: s}
}

func (f activityFixture) call(t *testing.T, h http.HandlerFunc, method, user, body string, params map[string]string, query string) (int, map[string]any) {
	t.Helper()
	r := blogRoute(method, user, body, params)
	if query != "" {
		r.URL.RawQuery = query
	}
	rec := httptest.NewRecorder()
	h(rec, r)
	out := map[string]any{}
	_ = json.Unmarshal(rec.Body.Bytes(), &out)
	return rec.Code, out
}

func themeUpload(t *testing.T, s *Server, user, themeID, entryID, caption string) *httptest.ResponseRecorder {
	t.Helper()
	var img bytes.Buffer
	if err := jpeg.Encode(&img, image.NewRGBA(image.Rect(0, 0, 320, 320)), nil); err != nil {
		t.Fatal(err)
	}
	var b bytes.Buffer
	w := multipart.NewWriter(&b)
	_ = w.WriteField("caption", caption)
	_ = w.WriteField("alt_text", "A sunny balcony with breakfast")
	part, _ := w.CreateFormFile("image", "sunday.jpg")
	_, _ = part.Write(img.Bytes())
	_ = w.Close()
	r := blogRoute(http.MethodPut, user, "", map[string]string{"themeID": themeID, "entryID": entryID})
	r.Body = httpBody(b.Bytes())
	r.Header.Set("Content-Type", w.FormDataContentType())
	rec := httptest.NewRecorder()
	s.photoThemeEntryHandler(rec, r)
	return rec
}

func httpBody(b []byte) *readCloser { return &readCloser{bytes.NewReader(b)} }

type readCloser struct{ *bytes.Reader }

func (readCloser) Close() error { return nil }

func TestPhotoThemeEntryLifecyclePostgres(t *testing.T) {
	f := newActivityFixture(t)
	ctx := context.Background()
	var themeID string
	if err := f.db.QueryRow(`SELECT id::text FROM matching.photo_themes WHERE slug='perfect-sunday'`).Scan(&themeID); err != nil {
		t.Fatal("seed theme missing", err)
	}
	entryID := uuid.NewString()

	// Below the community bar: no upload, and the list says why.
	if rec := themeUpload(t, f.s, f.proposer, themeID, entryID, "Pancakes"); rec.Code != 403 {
		t.Fatal("ineligible upload", rec.Code, rec.Body.String())
	}
	code, body := f.call(t, f.s.photoThemesHandler, http.MethodGet, f.proposer, "", nil, "")
	if code != 200 || body["eligible"] != false || body["eligibility_message"] == "" {
		t.Fatal("eligibility report", code, body)
	}
	blogEligible(t, f.datePlanFixture, f.proposer)
	blogEligible(t, f.datePlanFixture, f.invitee)
	blogEligible(t, f.datePlanFixture, f.blockedFriend)

	if rec := themeUpload(t, f.s, f.proposer, themeID, entryID, "Pancakes, then nowhere to be."); rec.Code != 200 {
		t.Fatal("upload", rec.Code, rec.Body.String())
	}
	// Exact retry is a readback; a second entry for the same theme is refused.
	if rec := themeUpload(t, f.s, f.proposer, themeID, entryID, "Pancakes, then nowhere to be."); rec.Code != 200 {
		t.Fatal("retry", rec.Code, rec.Body.String())
	}
	if rec := themeUpload(t, f.s, f.proposer, themeID, uuid.NewString(), "Another one"); rec.Code != 409 {
		t.Fatal("second entry for the same theme", rec.Code)
	}
	if rec := themeUpload(t, f.s, f.invitee, themeID, entryID, "Stolen UUID"); rec.Code != 409 {
		t.Fatal("UUID reuse by another member", rec.Code)
	}

	// The theme is shared with real local data, so count only this test's entries.
	gallery := func(user string) []any {
		code, body := f.call(t, f.s.photoThemeEntriesHandler, http.MethodGet, user, "", map[string]string{"themeID": themeID}, "")
		if code != 200 {
			t.Fatal("gallery", user, code, body)
		}
		mine := []any{}
		for _, e := range body["entries"].([]any) {
			if e.(map[string]any)["author_id"] == f.proposer {
				mine = append(mine, e)
			}
		}
		return mine
	}
	if len(gallery(f.invitee)) != 1 {
		t.Fatal("eligible member cannot see the entry")
	}
	if len(gallery(f.stranger)) != 0 {
		t.Fatal("member below the community bar sees the gallery")
	}
	blogExec(t, f.datePlanFixture, `INSERT INTO user_management.blocked_users(user_id,blocked_user_id,reason) VALUES($1,$2,'test') ON CONFLICT DO NOTHING`, f.invitee, f.proposer)
	if len(gallery(f.invitee)) != 0 {
		t.Fatal("blocked member still sees the entry")
	}
	blogExec(t, f.datePlanFixture, `DELETE FROM user_management.blocked_users WHERE user_id=$1 AND blocked_user_id=$2`, f.invitee, f.proposer)

	// Photo bytes are private and EXIF-free; only visible viewers get them.
	photo := func(user string) int {
		rec := httptest.NewRecorder()
		f.s.photoThemeEntryHandler(rec, blogRoute(http.MethodGet, user, "", map[string]string{"themeID": themeID, "entryID": entryID}))
		return rec.Code
	}
	if photo(f.invitee) != 200 || photo(f.stranger) != 404 {
		t.Fatal("photo access", photo(f.invitee), photo(f.stranger))
	}

	// A report copies the photo as evidence; removal hides it; appeal path intact.
	caseID, err := createBlogCase(ctx, f.db, f.invitee, "theme_entry", entryID, "inappropriate", "Not a Sunday photo")
	if err != nil {
		t.Fatal("report", err)
	}
	var evidence int
	_ = f.db.QueryRow(`SELECT COUNT(*) FROM matching.blog_evidence_photos WHERE case_id=$1`, caseID).Scan(&evidence)
	if evidence != 1 {
		t.Fatal("photo evidence not captured")
	}
	if err = decideBlogCase(ctx, f.db, f.stranger, caseID, "removed", "Removed after review", 1); err != nil {
		t.Fatal(err)
	}
	if len(gallery(f.invitee)) != 0 {
		t.Fatal("removed entry still visible to others")
	}
	if entries := gallery(f.proposer); len(entries) != 1 || entries[0].(map[string]any)["moderation_state"] != "removed" {
		t.Fatal("author lost sight of the removed entry", entries)
	}

	// Deleting releases the bytes, except while evidence still holds them.
	var storage string
	_ = f.db.QueryRow(`SELECT storage_path FROM matching.photo_theme_entries WHERE id=$1`, entryID).Scan(&storage)
	code, _ = f.call(t, f.s.photoThemeEntryHandler, http.MethodDelete, f.invitee, "", map[string]string{"themeID": themeID, "entryID": entryID}, "")
	if code != 404 {
		t.Fatal("foreign delete", code)
	}
	code, _ = f.call(t, f.s.photoThemeEntryHandler, http.MethodDelete, f.proposer, "", map[string]string{"themeID": themeID, "entryID": entryID}, "")
	if code != 200 {
		t.Fatal("delete", code)
	}
	f.s.cleanupDeletedThemeMedia(ctx)
	if _, err = os.Stat(filepath.Join(f.s.cfg.MediaUploadsDir, storage)); err != nil {
		t.Fatal("evidence bytes released while a case holds them", err)
	}
	blogExec(t, f.datePlanFixture, `DELETE FROM matching.blog_evidence_photos WHERE case_id=$1`, caseID)
	f.s.cleanupDeletedThemeMedia(ctx)
	if _, err = os.Stat(filepath.Join(f.s.cfg.MediaUploadsDir, storage)); !os.IsNotExist(err) {
		t.Fatal("deleted entry bytes remain", err)
	}
	// After deletion a fresh entry is allowed again.
	if rec := themeUpload(t, f.s, f.proposer, themeID, uuid.NewString(), "Round two"); rec.Code != 200 {
		t.Fatal("re-share after delete", rec.Code, rec.Body.String())
	}
}

func TestClubLifecycleRolesAndDiscussionPostgres(t *testing.T) {
	f := newActivityFixture(t)
	ctx := context.Background()
	for _, u := range []string{f.proposer, f.invitee, f.groupMate, f.blockedFriend, f.inviteeFriend} {
		blogEligible(t, f.datePlanFixture, u)
	}
	clubID := uuid.NewString()
	create := `{"kind":"book","name":"Sunday Novels","description":"One novel a week, no pressure.","expected_version":0}`
	code, body := f.call(t, f.s.clubHandler, http.MethodPut, f.stranger, create, map[string]string{"clubID": uuid.NewString()}, "")
	if code != 403 {
		t.Fatal("ineligible member started a club", code)
	}
	code, body = f.call(t, f.s.clubHandler, http.MethodPut, f.proposer, create, map[string]string{"clubID": clubID}, "")
	if code != 200 || body["club"].(map[string]any)["my_role"] != "owner" {
		t.Fatal("create club", code, body)
	}
	// Exact retry of the create is a readback, not a conflict.
	if code, _ = f.call(t, f.s.clubHandler, http.MethodPut, f.proposer, create, map[string]string{"clubID": clubID}, ""); code != 200 {
		t.Fatal("create retry", code)
	}
	join := func(user, action string) int {
		code, _ := f.call(t, f.s.clubMembershipHandler, http.MethodPost, user, `{"action":"`+action+`"}`, map[string]string{"clubID": clubID}, "")
		return code
	}
	if join(f.invitee, "join") != 200 || join(f.groupMate, "join") != 200 {
		t.Fatal("join")
	}
	if join(f.stranger, "join") != 404 {
		t.Fatal("member below the community bar joined")
	}
	if join(f.proposer, "leave") != 409 {
		t.Fatal("owner left a club with members")
	}

	// Discover hides joined clubs; mine shows them.
	code, body = f.call(t, f.s.clubsHandler, http.MethodGet, f.invitee, "", nil, "scope=mine")
	if code != 200 || len(body["clubs"].([]any)) != 1 {
		t.Fatal("my clubs", code, body)
	}

	// Titles deduplicate ignoring case and spacing.
	// The catalogue is shared and erasure clears created_by, so clean up by ID
	// and use a per-run creator to stay independent of earlier runs.
	titleID := uuid.NewString()
	run := strings.ReplaceAll(titleID[:8], "-", "")
	t.Cleanup(func() {
		for _, q := range []string{
			`DELETE FROM matching.club_selections WHERE title_id=$1`,
			`DELETE FROM matching.title_reviews WHERE title_id=$1`,
			`DELETE FROM matching.member_list_items WHERE title_id=$1`,
			`DELETE FROM matching.club_titles WHERE id=$1`,
		} {
			_, _ = f.db.Exec(q, titleID)
		}
	})
	code, body = f.call(t, f.s.clubTitleHandler, http.MethodPut, f.proposer, `{"kind":"book","title":"The Remains of the Day","creator":"Kazuo Ishiguro `+run+`","release_year":1989}`, map[string]string{"titleID": titleID}, "")
	if code != 200 {
		t.Fatal("add title", code, body)
	}
	code, body = f.call(t, f.s.clubTitleHandler, http.MethodPut, f.invitee, `{"kind":"book","title":"  the remains  of the DAY","creator":"kazuo   ISHIGURO `+run+`","release_year":1989}`, map[string]string{"titleID": uuid.NewString()}, "")
	if code != 200 || body["title"].(map[string]any)["id"] != titleID {
		t.Fatal("duplicate title not merged", code, body)
	}

	monday := time.Now().UTC()
	monday = time.Date(monday.Year(), monday.Month(), monday.Day(), 0, 0, 0, 0, time.UTC).AddDate(0, 0, -((int(monday.Weekday()) + 6) % 7))
	week := monday.Format("2006-01-02")
	pick := `{"title_id":"` + titleID + `","note":"Start with chapter one"}`
	if code, _ = f.call(t, f.s.clubSelectionHandler, http.MethodPut, f.invitee, pick, map[string]string{"clubID": clubID, "weekStart": week}, ""); code != 403 {
		t.Fatal("plain member set the pick", code)
	}
	if code, _ = f.call(t, f.s.clubSelectionHandler, http.MethodPut, f.proposer, pick, map[string]string{"clubID": clubID, "weekStart": monday.AddDate(0, 0, 1).Format("2006-01-02")}, ""); code != 400 {
		t.Fatal("non-Monday accepted", code)
	}
	code, body = f.call(t, f.s.clubSelectionHandler, http.MethodPut, f.proposer, pick, map[string]string{"clubID": clubID, "weekStart": week}, "")
	if code != 200 {
		t.Fatal("set pick", code, body)
	}
	selectionID := body["selection"].(map[string]any)["id"].(string)
	code, body = f.call(t, f.s.clubHandler, http.MethodGet, f.invitee, "", map[string]string{"clubID": clubID}, "")
	if code != 200 || body["club"].(map[string]any)["current_selection"] == nil {
		t.Fatal("current pick missing", code, body)
	}

	// Discussion: post, hide by a moderator, author and moderators still see it.
	postID := uuid.NewString()
	post := `{"selection_id":"` + selectionID + `","body":"Stevens is such an unreliable narrator.","has_spoilers":true}`
	if code, body = f.call(t, f.s.clubPostHandler, http.MethodPut, f.invitee, post, map[string]string{"clubID": clubID, "postID": postID}, ""); code != 200 {
		t.Fatal("post", code, body)
	}
	if code, _ = f.call(t, f.s.clubPostHandler, http.MethodPut, f.stranger, post, map[string]string{"clubID": clubID, "postID": uuid.NewString()}, ""); code == 200 {
		t.Fatal("non-member posted")
	}
	posts := func(user string) []any {
		code, body := f.call(t, f.s.clubPostsHandler, http.MethodGet, user, "", map[string]string{"clubID": clubID}, "selection_id="+selectionID)
		if code != 200 {
			return nil
		}
		return body["posts"].([]any)
	}
	if len(posts(f.groupMate)) != 1 {
		t.Fatal("member cannot read discussion")
	}
	if code, _ = f.call(t, f.s.clubMembersHandler, http.MethodPost, f.invitee, `{"action":"make_moderator"}`, map[string]string{"clubID": clubID, "userID": f.groupMate}, ""); code != 403 {
		t.Fatal("member promoted someone", code)
	}
	if code, _ = f.call(t, f.s.clubMembersHandler, http.MethodPost, f.proposer, `{"action":"make_moderator"}`, map[string]string{"clubID": clubID, "userID": f.groupMate}, ""); code != 200 {
		t.Fatal("owner promotion", code)
	}
	visibility := map[string]string{"clubID": clubID, "postID": postID}
	if code, _ = f.call(t, f.s.clubPostVisibilityHandler, http.MethodPost, f.groupMate, `{"hidden":true}`, visibility, ""); code != 200 {
		t.Fatal("moderator hide", code)
	}
	if len(posts(f.groupMate)) != 1 || len(posts(f.invitee)) != 1 {
		t.Fatal("hidden post vanished for its author or a moderator")
	}
	// A member blocked by the owner cannot see or join the club at all.
	if join(f.blockedFriend, "join") != 404 {
		t.Fatal("member blocked by the owner joined")
	}
	if join(f.inviteeFriend, "join") != 200 {
		t.Fatal("third member join")
	}
	if len(posts(f.inviteeFriend)) != 0 {
		t.Fatal("hidden post shown to an ordinary member")
	}

	// A moderator can remove a member; removed members cannot rejoin.
	if code, _ = f.call(t, f.s.clubMembersHandler, http.MethodPost, f.groupMate, `{"action":"remove"}`, map[string]string{"clubID": clubID, "userID": f.inviteeFriend}, ""); code != 200 {
		t.Fatal("moderator remove", code)
	}
	if join(f.inviteeFriend, "join") != 403 {
		t.Fatal("removed member rejoined")
	}

	// Reviews respect audience; ratings aggregate only shared reviews.
	review := func(user, id, audience string, version int, rating int) (int, map[string]any) {
		return f.call(t, f.s.clubReviewHandler, http.MethodPut, user,
			`{"rating":`+itoa(rating)+`,"body":"Quietly devastating.","has_spoilers":false,"audience":"`+audience+`","expected_version":`+itoa(version)+`}`,
			map[string]string{"titleID": titleID, "reviewID": id}, "")
	}
	reviewID := uuid.NewString()
	if code, body = review(f.proposer, reviewID, "private", 0, 5); code != 200 {
		t.Fatal("private review", code, body)
	}
	if code, _ = review(f.proposer, uuid.NewString(), "community", 0, 4); code != 409 {
		t.Fatal("second review for one title", code)
	}
	code, body = f.call(t, f.s.clubTitleHandler, http.MethodGet, f.invitee, "", map[string]string{"titleID": titleID}, "")
	if code != 200 || len(body["reviews"].([]any)) != 0 || body["title"].(map[string]any)["average_rating"] != nil {
		t.Fatal("private review leaked", body)
	}
	if code, body = review(f.proposer, reviewID, "community", 1, 4); code != 200 {
		t.Fatal("share review", code, body)
	}
	code, body = f.call(t, f.s.clubTitleHandler, http.MethodGet, f.invitee, "", map[string]string{"titleID": titleID}, "")
	if code != 200 || len(body["reviews"].([]any)) != 1 || body["title"].(map[string]any)["average_rating"] != 4.0 {
		t.Fatal("community review missing", body)
	}

	// Lists: kind must match, reports work, erasure hands the club over.
	listID := uuid.NewString()
	if code, _ = f.call(t, f.s.clubListHandler, http.MethodPut, f.proposer, `{"name":"Read next","kind":"film","audience":"private","expected_version":0}`, map[string]string{"listID": listID}, ""); code != 200 {
		t.Fatal("create list", code)
	}
	if code, _ = f.call(t, f.s.clubListItemHandler, http.MethodPut, f.proposer, `{"note":"x"}`, map[string]string{"listID": listID, "titleID": titleID}, ""); code != 400 {
		t.Fatal("book added to a film list", code)
	}
	if _, err := createBlogCase(ctx, f.db, f.invitee, "club_post", postID, "harassment", ""); err == nil {
		t.Fatal("author reported their own post")
	}
	caseID, err := createBlogCase(ctx, f.db, f.groupMate, "club_post", postID, "harassment", "Spoilers on purpose")
	if err != nil {
		t.Fatal("report club post", err)
	}
	if err = decideBlogCase(ctx, f.db, f.stranger, caseID, "removed", "Removed for spoilers", 1); err != nil {
		t.Fatal(err)
	}
	if len(posts(f.groupMate)) != 0 {
		t.Fatal("platform-removed post still visible to moderators")
	}

	tx, err := f.db.BeginTx(ctx, nil)
	if err != nil {
		t.Fatal(err)
	}
	for _, step := range accountErasureSteps() {
		if !strings.HasPrefix(step.label, "club") && step.label != "title_reviews" && step.label != "member_lists" {
			continue
		}
		if _, err = tx.ExecContext(ctx, step.query, f.proposer); err != nil {
			_ = tx.Rollback()
			t.Fatal(step.label, err)
		}
	}
	if err = tx.Commit(); err != nil {
		t.Fatal(err)
	}
	var owner, role string
	_ = f.db.QueryRow(`SELECT c.owner_id::text,m.role FROM matching.clubs c JOIN matching.club_members m ON m.club_id=c.id AND m.user_id=c.owner_id WHERE c.id=$1`, clubID).Scan(&owner, &role)
	if owner != f.groupMate || role != "owner" {
		t.Fatal("club not handed to the moderator", owner, role)
	}
}

func itoa(n int) string {
	b, _ := json.Marshal(n)
	return string(b)
}

func TestPhotoWallTiersCommentsAndOptOutPostgres(t *testing.T) {
	f := newActivityFixture(t)
	var ready bool
	if err := f.db.QueryRow(`SELECT to_regclass('matching.photo_wall_deliveries') IS NOT NULL`).Scan(&ready); err != nil || !ready {
		t.Skip("migration 110_photo_wall_reach is not applied")
	}
	t.Setenv("BLOG_WALL_TIERS", "2:1:1,3:1:100000")
	ctx := context.Background()
	for _, u := range []string{f.proposer, f.invitee, f.groupMate, f.proposerFriend} {
		blogEligible(t, f.datePlanFixture, u)
	}
	var themeID string
	if err := f.db.QueryRow(`SELECT id::text FROM matching.photo_themes WHERE slug='view-i-love'`).Scan(&themeID); err != nil {
		t.Fatal(err)
	}
	entryID := uuid.NewString()
	if rec := themeUpload(t, f.s, f.proposer, themeID, entryID, "The sea from my window"); rec.Code != 200 {
		t.Fatal("upload", rec.Code, rec.Body.String())
	}
	if _, err := setPhotoFeaturing(ctx, f.db, f.invitee, themeID, entryID, true); err == nil {
		t.Fatal("non-author changed featuring")
	}
	if _, err := setPhotoFeaturing(ctx, f.db, f.proposer, themeID, entryID, true); err != nil {
		t.Fatal(err)
	}
	wall := func(user string) int {
		entries, err := photoWallEntries(ctx, f.db, user)
		if err != nil {
			t.Fatal(err)
		}
		n := 0
		for _, e := range entries {
			if e.ID == entryID {
				n++
			}
		}
		return n
	}
	if _, err := togglePhotoLike(ctx, f.db, f.proposer, themeID, entryID, true, ""); err == nil {
		t.Fatal("author liked their own photo")
	}
	for _, u := range []string{f.invitee, f.groupMate} {
		if _, err := togglePhotoLike(ctx, f.db, u, themeID, entryID, true, ""); err != nil {
			t.Fatal("like", err)
		}
	}
	commentID := uuid.NewString()
	c, err := changePhotoComment(ctx, f.db, f.invitee, themeID, entryID, commentID, http.MethodPut, "", map[string]any{"body": "Which coast is this?"})
	if err != nil || c.Status != "pending" || c.EntryID != entryID {
		t.Fatal("comment", err, c)
	}
	if wall(f.proposerFriend) != 0 {
		t.Fatal("photo reached a wall before the comment was approved")
	}
	if _, err = changePhotoComment(ctx, f.db, f.proposer, themeID, entryID, commentID, http.MethodPost, "approve", nil); err != nil {
		t.Fatal("approve", err)
	}
	if wall(f.proposerFriend) != 1 || wall(f.groupMate) != 0 {
		t.Fatal("tier 1 should reach only the author's friend")
	}
	author, _ := readThemeEntry(ctx, f.db, f.proposer, themeID, entryID)
	if author.WallReach != 1 || author.NextTier == nil || author.NextTier.LikesNeeded != 1 {
		t.Fatal("author progress", author.WallReach, author.NextTier)
	}
	if _, err = togglePhotoLike(ctx, f.db, f.proposerFriend, themeID, entryID, true, ""); err != nil {
		t.Fatal(err)
	}
	if e, err := togglePhotoLike(ctx, f.db, f.proposerFriend, themeID, entryID, true, "me_too"); err != nil || e.MyReaction != "me_too" || e.Reactions["me_too"] != 1 {
		t.Fatal("photo reaction", err, e.MyReaction, e.Reactions)
	}
	if wall(f.groupMate) != 1 {
		t.Fatal("tier 2 did not widen reach")
	}
	// A reported comment can be removed; opting out clears every wall.
	caseID, err := createBlogCase(ctx, f.db, f.groupMate, "photo_comment", commentID, "harassment", "")
	if err != nil {
		t.Fatal("report photo comment", err)
	}
	if err = decideBlogCase(ctx, f.db, f.stranger, caseID, "removed", "Removed after review", 1); err != nil {
		t.Fatal(err)
	}
	if comments, _ := photoWall.listComments(ctx, f.db, f.groupMate, entryID); len(comments) != 0 {
		t.Fatal("removed photo comment still visible")
	}
	if _, err = setPhotoFeaturing(ctx, f.db, f.proposer, themeID, entryID, false); err != nil {
		t.Fatal(err)
	}
	if wall(f.groupMate) != 0 || wall(f.proposerFriend) != 0 {
		t.Fatal("opted-out photo still on walls")
	}
}
