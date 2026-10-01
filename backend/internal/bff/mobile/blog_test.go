package mobile

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"image"
	"image/jpeg"
	"io"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"testing"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/verified-dating/backend/internal/platform/config"
)

func blogRequest(method, path, user, post, photo string, body io.Reader) *http.Request {
	r := httptest.NewRequest(method, path, body)
	r.Header.Set("Content-Type", "application/json")
	route := chi.NewRouteContext()
	route.URLParams.Add("postID", post)
	route.URLParams.Add("photoID", photo)
	ctx := context.WithValue(r.Context(), chi.RouteCtxKey, route)
	if user != "" {
		ctx = context.WithValue(ctx, securityPrincipalContextKey{}, securityPrincipal{UserID: user, Roles: map[string]bool{"user": true}})
	}
	return r.WithContext(ctx)
}
func blogExec(t *testing.T, f datePlanFixture, q string, args ...any) {
	t.Helper()
	if _, err := f.db.Exec(q, args...); err != nil {
		t.Fatal(err)
	}
}
func blogEligible(t *testing.T, f datePlanFixture, user string) {
	blogExec(t, f, `UPDATE user_management.users SET profile_completion=100 WHERE id=$1`, user)
	for i := 0; i < 2; i++ {
		blogExec(t, f, `INSERT INTO user_management.photos(user_id,photo_url,ordering,moderation_status,lifecycle_status) VALUES($1,'https://example.test/blog-qa.jpg',$2,'approved','active')`, user, i)
	}
}
func TestBlogValidation(t *testing.T) {
	valid := func() map[string]any {
		return map[string]any{"expected_version": float64(0), "audience": "private", "title": "", "body": ""}
	}
	if _, err := parseBlogDraft(valid()); err != nil {
		t.Fatal(err)
	}
	for _, c := range []struct {
		name, key string
		value     any
	}{{"fraction", "expected_version", 0.5}, {"overflow", "expected_version", 1e30}, {"missing consent", "audience", nil}, {"public web", "audience", "public"}, {"empty publication", "audience", "friends"}, {"long title", "title", strings.Repeat("日", 101)}, {"long body", "body", strings.Repeat("日", 8001)}, {"invalid prompt", "invitation", "spam"}} {
		t.Run(c.name, func(t *testing.T) {
			v := valid()
			v[c.key] = c.value
			if _, err := parseBlogDraft(v); err == nil {
				t.Fatal("invalid draft accepted")
			}
		})
	}
}
func TestBlogAudienceRevocationAndEventsPostgres(t *testing.T) {
	f := newDatePlanFixture(t)
	ctx := context.Background()
	id := uuid.NewString()
	d := blogDraft{Title: "A private-title-marker", Body: "A private-body-marker", Audience: "private"}
	p, err := saveBlog(ctx, f.db, f.proposer, id, d)
	if err != nil || p.Version != 1 {
		t.Fatalf("create: %+v %v", p, err)
	}
	assertRead := func(user string, allowed bool) {
		t.Helper()
		_, err := readBlog(ctx, f.db, user, id)
		if (err == nil) != allowed {
			t.Fatalf("read by %s allowed=%t err=%v", user, allowed, err)
		}
	}
	assertRead(f.proposer, true)
	assertRead(f.proposerFriend, false)
	assertRead(f.invitee, false)
	assertRead(f.stranger, false)
	d.Version = p.Version
	d.Audience = "friends"
	p, err = saveBlog(ctx, f.db, f.proposer, id, d)
	if err != nil {
		t.Fatal(err)
	}
	assertRead(f.proposerFriend, true)
	assertRead(f.blockedFriend, false)
	assertRead(f.invitee, false)
	assertRead(f.stranger, false)
	blogExec(t, f, `DELETE FROM matching.friend_connections WHERE (user_id=$1 AND friend_user_id=$2) OR (user_id=$2 AND friend_user_id=$1)`, f.proposer, f.proposerFriend)
	assertRead(f.proposerFriend, false)
	d.Version = p.Version
	d.Audience = "community"
	if _, err = saveBlog(ctx, f.db, f.proposer, id, d); err == nil {
		t.Fatal("incomplete author published")
	}
	blogEligible(t, f, f.proposer)
	blogEligible(t, f, f.stranger)
	blogEligible(t, f, f.blockedFriend)
	p, err = saveBlog(ctx, f.db, f.proposer, id, d)
	if err != nil {
		t.Fatal(err)
	}
	assertRead(f.stranger, true)
	assertRead(f.blockedFriend, false)
	assertRead(f.invitee, false)
	blogExec(t, f, `UPDATE user_management.users SET is_active=false WHERE id=$1`, f.stranger)
	assertRead(f.stranger, false)
	blogExec(t, f, `UPDATE user_management.users SET is_active=true WHERE id=$1`, f.stranger)
	blogExec(t, f, `UPDATE user_management.photos SET moderation_status='rejected' WHERE user_id=$1`, f.proposer)
	assertRead(f.stranger, false)
	assertRead(f.proposer, true)
	var payload string
	if err = f.db.QueryRow(`SELECT string_agg(payload::text,' ') FROM platform.domain_event_outbox WHERE aggregate_type='blog.blog_posts' AND aggregate_id=$1`, id).Scan(&payload); err != nil {
		t.Fatal(err)
	}
	if strings.Contains(payload, "private-title-marker") || strings.Contains(payload, "private-body-marker") {
		t.Fatal("private prose leaked to outbox")
	}
}
func TestBlogConcurrentEditsRetriesAndTombstonesPostgres(t *testing.T) {
	f := newDatePlanFixture(t)
	ctx := context.Background()
	id := uuid.NewString()
	d := blogDraft{Title: "One", Body: "Original", Audience: "private"}
	p, err := saveBlog(ctx, f.db, f.proposer, id, d)
	if err != nil {
		t.Fatal(err)
	}
	retry, err := saveBlog(ctx, f.db, f.proposer, id, d)
	if err != nil || retry.Version != p.Version {
		t.Fatal("creation retry duplicated", err)
	}
	if _, err = saveBlog(ctx, f.db, f.stranger, id, d); err == nil {
		t.Fatal("foreign overwrite")
	}
	start := make(chan struct{})
	out := make(chan error, 2)
	var wg sync.WaitGroup
	for _, body := range []string{"Edit A", "Edit B"} {
		wg.Add(1)
		go func(body string) {
			defer wg.Done()
			<-start
			_, e := saveBlog(ctx, f.db, f.proposer, id, blogDraft{Title: "One", Body: body, Audience: "private", Version: 1})
			out <- e
		}(body)
	}
	close(start)
	wg.Wait()
	close(out)
	success, conflicts := 0, 0
	for e := range out {
		if e == nil {
			success++
		} else if errors.Is(e, errDatingConflict) {
			conflicts++
		} else {
			t.Fatal(e)
		}
	}
	if success != 1 || conflicts != 1 {
		t.Fatalf("concurrent outcomes %d/%d", success, conflicts)
	}
	s := &Server{store: &runtimeStore{profileRepo: &profileRepository{pg: f.db}}}
	rec := httptest.NewRecorder()
	s.blogPostsHandler(rec, blogRequest("DELETE", "/", f.proposer, id, "", strings.NewReader(`{"expected_version":2}`)))
	if rec.Code != 200 {
		t.Fatal(rec.Code, rec.Body.String())
	}
	if _, err = readBlog(ctx, f.db, f.proposer, id); err == nil {
		t.Fatal("deleted post readable")
	}
	if _, err = saveBlog(ctx, f.db, f.proposer, id, d); err == nil {
		t.Fatal("deleted UUID resurrected")
	}
	s.cleanupDeletedBlogMedia(ctx)
	var title, body string
	if err = f.db.QueryRow(`SELECT title,body FROM matching.blog_posts WHERE id=$1`, id).Scan(&title, &body); err != nil || title != "" || body != "" {
		t.Fatal("deleted prose retained", err)
	}
}
func TestBlogFeedPaginationAndAnonymousHTTPPostgres(t *testing.T) {
	f := newDatePlanFixture(t)
	s := &Server{store: &runtimeStore{profileRepo: &profileRepository{pg: f.db}}}
	for i := 0; i < 23; i++ {
		if _, err := saveBlog(context.Background(), f.db, f.proposer, uuid.NewString(), blogDraft{Title: fmt.Sprint(i), Audience: "private"}); err != nil {
			t.Fatal(err)
		}
	}
	request := func(user, path string) *httptest.ResponseRecorder {
		r := httptest.NewRecorder()
		s.blogPostsHandler(r, blogRequest("GET", path, user, "", "", nil))
		return r
	}
	if r := request("", "/blog/posts?scope=mine"); r.Code != 401 {
		t.Fatal("anonymous allowed", r.Code)
	}
	var page struct {
		Posts []blogPost `json:"posts"`
		Next  string     `json:"next_cursor"`
	}
	r := request(f.proposer, "/blog/posts?scope=mine")
	if r.Code != 200 {
		t.Fatal(r.Code, r.Body.String())
	}
	json.Unmarshal(r.Body.Bytes(), &page)
	if len(page.Posts) != 20 || page.Next == "" {
		t.Fatal("page 1", len(page.Posts), page.Next)
	}
	seen := map[string]bool{}
	for _, p := range page.Posts {
		seen[p.ID] = true
	}
	r = request(f.proposer, "/blog/posts?scope=mine&before="+page.Next)
	json.Unmarshal(r.Body.Bytes(), &page)
	if len(page.Posts) != 3 || page.Next != "" {
		t.Fatal("page 2", r.Body.String())
	}
	for _, p := range page.Posts {
		if seen[p.ID] {
			t.Fatal("duplicate across pages")
		}
	}
	r = request(f.stranger, "/blog/posts?scope=community&author_id="+f.proposer)
	json.Unmarshal(r.Body.Bytes(), &page)
	if len(page.Posts) != 0 {
		t.Fatal("drafts leaked into feed")
	}
}
func TestBlogPrivatePhotoLifecyclePostgres(t *testing.T) {
	f := newDatePlanFixture(t)
	ctx := context.Background()
	id, photo := uuid.NewString(), uuid.NewString()
	s := &Server{cfg: config.Config{MediaUploadsDir: t.TempDir()}, store: &runtimeStore{profileRepo: &profileRepository{pg: f.db}}, mediaModerator: localValidationModerator{}}
	p, err := saveBlog(ctx, f.db, f.proposer, id, blogDraft{Title: "Photo", Body: "Test", Audience: "private"})
	if err != nil {
		t.Fatal(err)
	}
	var imageBytes bytes.Buffer
	if err = jpeg.Encode(&imageBytes, image.NewRGBA(image.Rect(0, 0, 320, 320)), nil); err != nil {
		t.Fatal(err)
	}
	// Embed an EXIF-like APP1 payload. The normalized stored JPEG must lose it.
	raw := imageBytes.Bytes()
	metadata := []byte("Exif\x00\x00GPS-private-marker")
	content := append([]byte{0xff, 0xd8, 0xff, 0xe1, byte((len(metadata) + 2) >> 8), byte(len(metadata) + 2)}, metadata...)
	content = append(content, raw[2:]...)
	upload := func(user string) *httptest.ResponseRecorder {
		var b bytes.Buffer
		w := multipart.NewWriter(&b)
		w.WriteField("expected_version", "1")
		w.WriteField("alt_text", "An accessible photo description")
		part, _ := w.CreateFormFile("image", "photo.jpg")
		part.Write(content)
		w.Close()
		r := blogRequest("PUT", "/", user, id, photo, &b)
		r.Header.Set("Content-Type", w.FormDataContentType())
		rec := httptest.NewRecorder()
		s.blogPhotoHandler(rec, r)
		return rec
	}
	if rec := upload(f.stranger); rec.Code != 404 {
		t.Fatal("foreign upload", rec.Code)
	}
	s.mediaModerator = nil
	rec := upload(f.proposer)
	if rec.Code != 503 {
		t.Fatal("moderation outage did not fail closed", rec.Code)
	}
	s.mediaModerator = localValidationModerator{}
	rec = upload(f.proposer)
	if rec.Code != 200 {
		t.Fatal("upload", rec.Code, rec.Body.String())
	}
	rec = upload(f.proposer)
	if rec.Code != 200 {
		t.Fatal("lost-success upload retry", rec.Code, rec.Body.String())
	}
	p, err = readBlog(ctx, f.db, f.proposer, id)
	if err != nil || p.Version != 2 || len(p.Photos) != 1 {
		t.Fatal("duplicate upload", p, err)
	}
	get := func(user string) *httptest.ResponseRecorder {
		rec := httptest.NewRecorder()
		s.blogPhotoHandler(rec, blogRequest("GET", "/", user, id, photo, nil))
		return rec
	}
	if rec = get(f.proposerFriend); rec.Code != 404 {
		t.Fatal("private bytes leaked")
	}
	rec = get(f.proposer)
	if rec.Code != 200 || bytes.Contains(rec.Body.Bytes(), metadata) || rec.Header().Get("Cache-Control") != "private, no-store" {
		t.Fatal("unsafe bytes", rec.Code)
	}
	var storage string
	f.db.QueryRow(`SELECT storage_path FROM matching.blog_photos WHERE id=$1`, photo).Scan(&storage)
	if _, err = os.Stat(filepath.Join(s.cfg.MediaUploadsDir, storage)); err != nil {
		t.Fatal("uploaded object missing", err)
	}
	publicRequest := blogRequest("GET", "/media/"+storage, "", "", "", nil)
	chi.RouteContext(publicRequest.Context()).URLParams.Add("*", storage)
	publicResponse := httptest.NewRecorder()
	s.serveUploadedMedia(publicResponse, publicRequest)
	if publicResponse.Code != 404 {
		t.Fatal("private photo accessible on public media route", publicResponse.Code)
	}
	refs, err := s.privateMediaReferences(ctx)
	if err != nil {
		t.Fatal(err)
	}
	if _, ok := refs[storage]; !ok {
		t.Fatal("active photo absent from cleanup references")
	}
	p, err = saveBlog(ctx, f.db, f.proposer, id, blogDraft{Title: p.Title, Body: p.Body, Audience: "friends", Version: 2})
	if err != nil {
		t.Fatal(err)
	}
	if rec = get(f.proposerFriend); rec.Code != 200 {
		t.Fatal("friend cannot read", rec.Code)
	}
	if rec = upload(f.proposer); rec.Code != 409 {
		t.Fatal("published photo mutated")
	}
	blogExec(t, f, `INSERT INTO user_management.blocked_users(user_id,blocked_user_id,reason) VALUES($1,$2,'test')`, f.proposerFriend, f.proposer)
	if rec = get(f.proposerFriend); rec.Code != 404 {
		t.Fatal("blocked friend received image")
	}
	rec = httptest.NewRecorder()
	s.blogPostsHandler(rec, blogRequest("DELETE", "/", f.proposer, id, "", strings.NewReader(`{"expected_version":3}`)))
	if rec.Code != 200 {
		t.Fatal(rec.Code, rec.Body.String())
	}
	if rec = get(f.proposer); rec.Code != 404 {
		t.Fatal("tombstoned photo accessible")
	}
	s.cleanupDeletedBlogMedia(ctx)
	if _, err = os.Stat(filepath.Join(s.cfg.MediaUploadsDir, storage)); !os.IsNotExist(err) {
		t.Fatal("deleted bytes remain", err)
	}
}

func TestBlogExportErasureAndLegalHoldPostgres(t *testing.T) {
	f := newDatePlanFixture(t)
	ctx := context.Background()
	repo := &profileRepository{pg: f.db}
	id := uuid.NewString()
	_, err := saveBlog(ctx, f.db, f.proposer, id, blogDraft{Title: "Export my chapter", Body: "My private journal", Audience: "private"})
	if err != nil {
		t.Fatal(err)
	}
	foreign := uuid.NewString()
	if _, err = saveBlog(ctx, f.db, f.stranger, foreign, blogDraft{Title: "Never export this", Audience: "private"}); err != nil {
		t.Fatal(err)
	}
	result, err := repo.buildAccountExport(ctx, f.proposer, f.proposer)
	if err != nil {
		t.Fatal(err)
	}
	raw, _ := json.Marshal(result["blog_posts"])
	if !bytes.Contains(raw, []byte("Export my chapter")) || bytes.Contains(raw, []byte("Never export this")) {
		t.Fatal("export scope", string(raw))
	}
	photo := uuid.NewString()
	blogExec(t, f, `INSERT INTO matching.blog_photos(id,post_id,author_id,alt_text,storage_path,mime_type,size_bytes,content_sha256,moderation_status,moderation_provider) VALUES($1,$2,$3,'Hold image','private/blog/hold.jpg','image/jpeg',100,'digest','approved','test')`, photo, id, f.proposer)
	blogExec(t, f, `INSERT INTO platform.legal_holds(user_id,reason,placed_by) VALUES($1,'QA hold',$2)`, f.proposer, uuid.NewString())
	t.Cleanup(func() { f.db.Exec(`DELETE FROM platform.legal_holds WHERE user_id=$1`, f.proposer) })
	blogExec(t, f, `UPDATE matching.blog_photos SET deleted_at=NOW() WHERE id=$1`, photo)
	s := &Server{cfg: config.Config{MediaUploadsDir: t.TempDir()}, store: &runtimeStore{profileRepo: repo}}
	s.cleanupDeletedBlogMedia(ctx)
	var count int
	f.db.QueryRow(`SELECT COUNT(*) FROM matching.blog_photos WHERE id=$1`, photo).Scan(&count)
	if count != 1 {
		t.Fatal("legal hold lost media reference")
	}
	blogExec(t, f, `UPDATE user_management.users SET deletion_requested_at=NOW()-interval '2 days',deletion_effective_at=NOW()-interval '1 day' WHERE id=$1`, f.proposer)
	if _, err = repo.eraseAccount(ctx, f.proposer, f.proposer, "system"); !errors.Is(err, errAccountOnLegalHold) {
		t.Fatal("hold did not defer erasure", err)
	}
	blogExec(t, f, `UPDATE platform.legal_holds SET released_at=NOW(),released_by=$2 WHERE user_id=$1`, f.proposer, uuid.NewString())
	summary, err := repo.eraseAccount(ctx, f.proposer, f.proposer, "system")
	if err != nil {
		t.Fatal(err)
	}
	if summary.RowsScrubbed["blog_posts"] != 1 {
		t.Fatal("blog not erased", summary.RowsScrubbed)
	}
	found := false
	for _, path := range summary.StoragePaths {
		if path == "private/blog/hold.jpg" {
			found = true
		}
	}
	if !found {
		t.Fatal("media omitted from durable erasure cleanup")
	}
	f.db.QueryRow(`SELECT COUNT(*) FROM matching.blog_photos WHERE id=$1`, photo).Scan(&count)
	if count != 0 {
		t.Fatal("erasure left photo rows")
	}
}
func TestBlogReportUsesAuthorizedAuthorPostgres(t *testing.T) {
	f := newBlogTrustFixture(t)
	id := uuid.NewString()
	if _, err := saveBlog(context.Background(), f.db, f.proposer, id, blogDraft{Title: "A chapter", Body: "Words", Audience: "friends"}); err != nil {
		t.Fatal(err)
	}
	s := blogServer(f)
	for _, c := range []struct {
		user   string
		status int
	}{{f.stranger, 404}, {f.proposer, 400}, {f.proposerFriend, 200}} {
		r := httptest.NewRecorder()
		s.reportBlogPost(r, blogRequest("POST", "/", c.user, id, "", strings.NewReader(`{"reason":"inappropriate","reported_user_id":"forged","reporter_user_id":"forged"}`)))
		if r.Code != c.status {
			t.Fatal(r.Code, r.Body.String())
		}
	}
	var subject, reporter string
	if err := f.db.QueryRow(`SELECT subject_id::text,reporter_id::text FROM matching.blog_cases WHERE content_id=$1`, id).Scan(&subject, &reporter); err != nil {
		t.Fatal(err)
	}
	if subject != f.proposer || reporter != f.proposerFriend {
		t.Fatal("untrusted actor forwarded")
	}
}
