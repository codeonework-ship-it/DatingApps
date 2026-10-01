package mobile

import (
	"context"
	"encoding/json"
	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/verified-dating/backend/internal/platform/config"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func newBlogTrustFixture(t *testing.T) datePlanFixture {
	f := newDatePlanFixture(t)
	t.Cleanup(func() {
		_, _ = f.db.Exec(`DELETE FROM matching.blog_case_actions WHERE case_id IN(SELECT id FROM matching.blog_cases WHERE subject_id IN($1,$2,$3,$4,$5,$6,$7))`, f.proposer, f.invitee, f.proposerFriend, f.inviteeFriend, f.blockedFriend, f.groupMate, f.stranger)
		_, _ = f.db.Exec(`DELETE FROM matching.blog_cases WHERE subject_id IN($1,$2,$3,$4,$5,$6,$7)`, f.proposer, f.invitee, f.proposerFriend, f.inviteeFriend, f.blockedFriend, f.groupMate, f.stranger)
	})
	return f
}
func blogServer(f datePlanFixture) *Server {
	return &Server{store: &runtimeStore{profileRepo: &profileRepository{pg: f.db}}}
}
func blogRoute(method, user, body string, params map[string]string) *http.Request {
	r := blogRequest(method, "/", user, "", "", strings.NewReader(body))
	rc := chi.NewRouteContext()
	for k, v := range params {
		rc.URLParams.Add(k, v)
	}
	return r.WithContext(context.WithValue(r.Context(), chi.RouteCtxKey, rc))
}
func seededBlog(t *testing.T, f datePlanFixture) blogPost {
	t.Helper()
	blogEligible(t, f, f.proposer)
	blogEligible(t, f, f.invitee)
	p, e := saveBlog(context.Background(), f.db, f.proposer, uuid.NewString(), blogDraft{Title: "A little Sunday", Body: "Coffee, a bookshop and a long walk.", Audience: "community", Invitation: "your_version"})
	if e != nil {
		t.Fatal(e)
	}
	return p
}
func revealedBlog(t *testing.T, f datePlanFixture, p blogPost) blogResponse {
	t.Helper()
	ctx := context.Background()
	v, e := createBlogResponse(ctx, f.db, f.invitee, p.ID, uuid.NewString(), "What book would you choose?")
	if e != nil {
		t.Fatal(e)
	}
	v, e = changeBlogResponse(ctx, f.db, f.proposer, v.ID, "accept", "", v.Version)
	if e != nil {
		t.Fatal(e)
	}
	v, e = changeBlogResponse(ctx, f.db, f.proposer, v.ID, "contribute", "Author secret story", v.Version)
	if e != nil {
		t.Fatal(e)
	}
	v, e = changeBlogResponse(ctx, f.db, f.invitee, v.ID, "contribute", "Sender secret story", v.Version)
	if e != nil {
		t.Fatal(e)
	}
	return v
}
func TestBlogResponseConsentRevealRevocationPostgres(t *testing.T) {
	f := newBlogTrustFixture(t)
	p := seededBlog(t, f)
	ctx := context.Background()
	id := uuid.NewString()
	v, e := createBlogResponse(ctx, f.db, f.invitee, p.ID, id, "Response marker")
	if e != nil {
		t.Fatal(e)
	}
	retry, e := createBlogResponse(ctx, f.db, f.invitee, p.ID, id, "Response marker")
	if e != nil || retry.ID != id {
		t.Fatal("lost-success retry", e)
	}
	if _, e = readBlogResponse(ctx, f.db, f.stranger, id); e == nil {
		t.Fatal("foreign read")
	}
	if _, e = changeBlogResponse(ctx, f.db, f.invitee, id, "accept", "", 1); e == nil {
		t.Fatal("sender accepted own response")
	}
	v, e = changeBlogResponse(ctx, f.db, f.proposer, id, "accept", "", 1)
	if e != nil {
		t.Fatal(e)
	}
	version := v.Version
	v, e = changeBlogResponse(ctx, f.db, f.proposer, id, "contribute", "PRIVATE AUTHOR MARKER", version)
	if e != nil {
		t.Fatal(e)
	}
	sender, e := readBlogResponse(ctx, f.db, f.invitee, id)
	if e != nil {
		t.Fatal(e)
	}
	raw, _ := json.Marshal(sender)
	if strings.Contains(string(raw), "PRIVATE AUTHOR MARKER") || sender.Revealed {
		t.Fatal("blind contribution leaked", string(raw))
	}
	// Same original version is safe when only the other participant's slot changed.
	v, e = changeBlogResponse(ctx, f.db, f.invitee, id, "contribute", "PRIVATE SENDER MARKER", version)
	if e != nil || !v.Revealed || v.PartnerStory != "PRIVATE AUTHOR MARKER" || v.MatchID != f.matchID {
		t.Fatal("mutual reveal", v, e)
	}
	if _, e = changeBlogResponse(ctx, f.db, f.invitee, id, "contribute", "EDIT", v.Version); e == nil {
		t.Fatal("edited revealed story")
	}
	var event string
	if e = f.db.QueryRow(`SELECT COALESCE(string_agg(payload::text,' '),'') FROM platform.domain_event_outbox WHERE aggregate_type='blog.blog_responses' AND aggregate_id=$1`, id).Scan(&event); e != nil {
		t.Fatal(e)
	}
	if strings.Contains(event, "PRIVATE") || strings.Contains(event, "Response marker") {
		t.Fatal("event payload disclosed prose")
	}
	blogExec(t, f, `INSERT INTO user_management.blocked_users(user_id,blocked_user_id) VALUES($1,$2)`, f.proposer, f.invitee)
	if _, e = readBlogResponse(ctx, f.db, f.invitee, id); e == nil {
		t.Fatal("block did not revoke")
	}
	if _, e = changeBlogResponse(ctx, f.db, f.invitee, id, "withdraw", "", 0); e != nil {
		t.Fatal("withdraw after block", e)
	}
}
func TestBlogResponseLimitsAndDeclinePostgres(t *testing.T) {
	f := newBlogTrustFixture(t)
	p := seededBlog(t, f)
	ctx := context.Background()
	v, e := createBlogResponse(ctx, f.db, f.invitee, p.ID, uuid.NewString(), "Hello")
	if e != nil {
		t.Fatal(e)
	}
	if _, e = createBlogResponse(ctx, f.db, f.invitee, p.ID, uuid.NewString(), "Again"); e == nil {
		t.Fatal("repeated response")
	}
	p2, e := saveBlog(ctx, f.db, f.proposer, uuid.NewString(), blogDraft{Title: "Another", Body: "Another story", Audience: "community", Invitation: "what_next"})
	if e != nil {
		t.Fatal(e)
	}
	if _, e = createBlogResponse(ctx, f.db, f.invitee, p2.ID, uuid.NewString(), "Another hello"); e == nil {
		t.Fatal("same author velocity bypass")
	}
	v, e = changeBlogResponse(ctx, f.db, f.proposer, v.ID, "decline", "", v.Version)
	if e != nil {
		t.Fatal(e)
	}
	if _, e = changeBlogResponse(ctx, f.db, f.invitee, v.ID, "contribute", "Unexpected", v.Version); e == nil {
		t.Fatal("declined response contribution")
	}
}
func soloBody(p blogPost) map[string]any {
	return map[string]any{"id": uuid.NewString(), "post_id": p.ID, "expected_version": float64(p.Version), "approved": true, "excerpt": p.Body, "photo_ids": []any{}}
}
func TestBlogPublicCopyConsentAndInvalidationPostgres(t *testing.T) {
	f := newBlogTrustFixture(t)
	p := seededBlog(t, f)
	ctx := context.Background()
	body := soloBody(p)
	body["approved"] = false
	if _, e := createBlogPublication(ctx, f.db, f.proposer, body); e == nil {
		t.Fatal("implicit consent")
	}
	body["approved"] = true
	body["excerpt"] = "Foreign text"
	if _, e := createBlogPublication(ctx, f.db, f.proposer, body); e == nil {
		t.Fatal("unbound excerpt")
	}
	body["excerpt"] = p.Body
	pub, e := createBlogPublication(ctx, f.db, f.proposer, body)
	if e != nil {
		t.Fatal(e)
	}
	if _, e = createBlogPublication(ctx, f.db, f.proposer, body); e != nil {
		t.Fatal("publication retry", e)
	}
	rec := httptest.NewRecorder()
	blogServer(f).blogPublicHandler(rec, blogRoute("GET", "", "", map[string]string{"shareID": pub.ID}))
	if rec.Code != 200 {
		t.Fatal(rec.Body.String())
	}
	var data map[string]any
	json.Unmarshal(rec.Body.Bytes(), &data)
	if len(data) != 4 || data["title"] != p.Title || rec.Header().Get("Cache-Control") != "private, no-store" {
		t.Fatal("public allowlist", data)
	}
	if strings.Contains(rec.Body.String(), f.proposer) || strings.Contains(rec.Body.String(), p.ID) {
		t.Fatal("source identity leaked")
	}
	_, e = saveBlog(ctx, f.db, f.proposer, p.ID, blogDraft{Title: p.Title, Body: p.Body, Audience: "private", Version: p.Version})
	if e != nil {
		t.Fatal(e)
	}
	if _, e = readBlogPublication(ctx, f.db, pub.ID); e == nil {
		t.Fatal("source withdrawal ignored")
	}
	if _, e = changeBlogPublication(ctx, f.db, f.proposer, pub.ID, "revoke", 0); e != nil {
		t.Fatal(e)
	}
}
func TestBlogJointCopyNeedsBothAndDateBridgePostgres(t *testing.T) {
	f := newBlogTrustFixture(t)
	p := seededBlog(t, f)
	v := revealedBlog(t, f, p)
	ctx := context.Background()
	body := soloBody(p)
	body["response_id"] = v.ID
	pub, e := createBlogPublication(ctx, f.db, f.proposer, body)
	if e != nil {
		t.Fatal(e)
	}
	if _, e = readBlogPublication(ctx, f.db, pub.ID); e == nil {
		t.Fatal("one-sided publication")
	}
	if _, e = changeBlogPublication(ctx, f.db, f.stranger, pub.ID, "approve", pub.Version); e == nil {
		t.Fatal("foreign approval")
	}
	if _, e = changeBlogPublication(ctx, f.db, f.invitee, pub.ID, "approve", pub.Version); e != nil {
		t.Fatal(e)
	}
	pub, e = readBlogPublication(ctx, f.db, pub.ID)
	if e != nil || pub.Excerpt != "Author secret story\n\nSender secret story" {
		t.Fatal(pub, e)
	}
	service := newDatePlanService(f.db)
	start := time.Now().UTC().Add(24 * time.Hour)
	plan, e := service.propose(ctx, datePlanProposal{MatchID: f.matchID, ProposerID: f.proposer, WindowStart: start, WindowEnd: start.Add(time.Hour), VenueCategory: "coffee", SourceBlogResponseID: v.ID})
	if e != nil {
		t.Fatal("date bridge", e)
	}
	var source string
	if e = f.db.QueryRow(`SELECT source_blog_response_id::text FROM matching.match_date_plans WHERE id=$1`, plan.ID).Scan(&source); e != nil || source != v.ID {
		t.Fatal("attribution", e)
	}
	if _, e = changeBlogPublication(ctx, f.db, f.invitee, pub.ID, "revoke", 0); e != nil {
		t.Fatal(e)
	}
	if _, e = readBlogPublication(ctx, f.db, pub.ID); e == nil {
		t.Fatal("partner revocation ignored")
	}
}
func TestBlogModerationEvidenceAppealAndRolePostgres(t *testing.T) {
	f := newBlogTrustFixture(t)
	p := seededBlog(t, f)
	ctx := context.Background()
	s := blogServer(f)
	caseID, e := createBlogCase(ctx, f.db, f.invitee, "post", p.ID, "inappropriate", "Snapshot marker")
	if e != nil {
		t.Fatal(e)
	}
	_, e = saveBlog(ctx, f.db, f.proposer, p.ID, blogDraft{Title: p.Title, Body: "Edited story", Audience: "community", Version: p.Version})
	if e != nil {
		t.Fatal(e)
	}
	again, e := createBlogCase(ctx, f.db, f.invitee, "post", p.ID, "fraud", "Changed report")
	if e != nil || again != caseID {
		t.Fatal("report dedupe", e)
	}
	var snapshot, description string
	f.db.QueryRow(`SELECT snapshot::text,description FROM matching.blog_cases WHERE id=$1`, caseID).Scan(&snapshot, &description)
	if !strings.Contains(snapshot, p.Body) || description != "Snapshot marker" {
		t.Fatal("evidence changed", snapshot, description)
	}
	r := httptest.NewRecorder()
	s.blogReviewHandler(r, blogRoute("GET", f.stranger, "", nil))
	if r.Code != 403 {
		t.Fatal("member read evidence", r.Code)
	}
	if e = decideBlogCase(ctx, f.db, f.stranger, caseID, "removed", "Content violates community rules", 1); e != nil {
		t.Fatal(e)
	}
	if _, e = readBlog(ctx, f.db, f.invitee, p.ID); e == nil {
		t.Fatal("removed content visible")
	}
	// No reporter identifiers in the subject's notices.
	r = httptest.NewRecorder()
	s.blogNoticesHandler(r, blogRoute("GET", f.proposer, "", nil))
	if r.Code != 200 || strings.Contains(r.Body.String(), f.invitee) {
		t.Fatal("notice privacy", r.Body.String())
	}
	r = httptest.NewRecorder()
	s.blogNoticesHandler(r, blogRoute("POST", f.invitee, `{"expected_version":2,"text":"Please reconsider this decision"}`, map[string]string{"caseID": caseID}))
	if r.Code == 200 {
		t.Fatal("foreign appeal")
	}
	r = httptest.NewRecorder()
	s.blogNoticesHandler(r, blogRoute("POST", f.proposer, `{"expected_version":2,"text":"Please reconsider this decision"}`, map[string]string{"caseID": caseID}))
	if r.Code != 200 {
		t.Fatal("appeal", r.Code, r.Body.String())
	}
	if _, e = readBlog(ctx, f.db, f.invitee, p.ID); e == nil {
		t.Fatal("appeal restored content before decision")
	}
	if e = decideBlogCase(ctx, f.db, f.stranger, caseID, "restored", "Appeal reviewed and accepted", 3); e != nil {
		t.Fatal(e)
	}
	if _, e = readBlog(ctx, f.db, f.invitee, p.ID); e != nil {
		t.Fatal("not restored", e)
	}
	blogExec(t, f, `UPDATE matching.blog_cases SET resolved_at=NOW()-interval '91 days' WHERE id=$1`, caseID)
	s.cleanupBlogEvidence(ctx)
	f.db.QueryRow(`SELECT snapshot::text FROM matching.blog_cases WHERE id=$1`, caseID).Scan(&snapshot)
	if snapshot != "{}" {
		t.Fatal("retention failed", snapshot)
	}
}

func TestBlogResponseCountsTowardMessageQuotaPostgres(t *testing.T) {
	f := newBlogTrustFixture(t)
	p := seededBlog(t, f)
	_ = revealedBlog(t, f, p)
	repo := &billingRepository{db: f.db}
	ctx := context.Background()
	for user, want := range map[string]int{f.invitee: 2, f.proposer: 1} {
		got, e := repo.countMessagesSince(ctx, user, time.Now().Add(-time.Hour))
		if e != nil || got != want {
			t.Fatal("blog message quota", got, want, e)
		}
	}
}
func TestBlogReportEvidenceSurvivesErasureThenExpiresPostgres(t *testing.T) {
	f := newBlogTrustFixture(t)
	p := seededBlog(t, f)
	ctx := context.Background()
	s := blogServer(f)
	s.cfg.MediaUploadsDir = t.TempDir()
	photo := uuid.NewString()
	path := "private/blog/" + photo + ".jpg"
	if e := os.MkdirAll(filepath.Join(s.cfg.MediaUploadsDir, "private/blog"), 0700); e != nil {
		t.Fatal(e)
	}
	if e := os.WriteFile(filepath.Join(s.cfg.MediaUploadsDir, path), []byte("test-jpeg-evidence"), 0600); e != nil {
		t.Fatal(e)
	}
	blogExec(t, f, `INSERT INTO matching.blog_photos(id,post_id,author_id,alt_text,storage_path,mime_type,size_bytes,content_sha256,moderation_status,moderation_provider) VALUES($1,$2,$3,'Photo description',$4,'image/jpeg',18,'digest','approved','test')`, photo, p.ID, f.proposer, path)
	caseID, e := createBlogCase(ctx, f.db, f.invitee, "post", p.ID, "inappropriate", "Review this photo")
	if e != nil {
		t.Fatal(e)
	}
	if e = decideBlogCase(ctx, f.db, f.stranger, caseID, "removed", "Photo review decision", 1); e != nil {
		t.Fatal(e)
	}
	blogExec(t, f, `UPDATE user_management.users SET deletion_requested_at=NOW()-interval '2 days',deletion_effective_at=NOW()-interval '1 day' WHERE id=$1`, f.proposer)
	summary, e := s.store.profileRepo.eraseAccount(ctx, f.proposer, f.proposer, "system")
	if e != nil {
		t.Fatal(e)
	}
	for _, p := range summary.StoragePaths {
		if p == path {
			t.Fatal("erasure attempted to release retained evidence")
		}
	}
	refs, e := s.privateMediaReferences(ctx)
	if e != nil {
		t.Fatal(e)
	}
	if _, ok := refs[path]; !ok {
		t.Fatal("evidence missing from orphan protection")
	}
	r := blogRoute("GET", f.stranger, "", map[string]string{"caseID": caseID, "photoID": photo})
	r = r.WithContext(context.WithValue(r.Context(), securityPrincipalContextKey{}, securityPrincipal{UserID: f.stranger, Roles: map[string]bool{"moderator": true}}))
	rec := httptest.NewRecorder()
	s.blogReviewHandler(rec, r)
	if rec.Code != 200 || rec.Body.String() != "test-jpeg-evidence" {
		t.Fatal("lost retained evidence", rec.Code, rec.Body.String())
	}
	blogExec(t, f, `INSERT INTO platform.legal_holds(user_id,reason,placed_by) VALUES($1,'Evidence QA hold',$2)`, f.proposer, uuid.NewString())
	t.Cleanup(func() { f.db.Exec(`DELETE FROM platform.legal_holds WHERE user_id=$1`, f.proposer) })
	blogExec(t, f, `UPDATE matching.blog_cases SET resolved_at=NOW()-interval '91 days' WHERE id=$1`, caseID)
	s.cleanupBlogEvidence(ctx)
	if _, e = os.Stat(filepath.Join(s.cfg.MediaUploadsDir, path)); e != nil {
		t.Fatal("hold lost evidence", e)
	}
	blogExec(t, f, `UPDATE platform.legal_holds SET released_at=NOW(),released_by=$2 WHERE user_id=$1`, f.proposer, uuid.NewString())
	s.cleanupBlogEvidence(ctx)
	if _, e = os.Stat(filepath.Join(s.cfg.MediaUploadsDir, path)); !os.IsNotExist(e) {
		t.Fatal("expired evidence object remains", e)
	}
}
func TestBlogPublicPhotoAllowlistAndAnonymousReportingPostgres(t *testing.T) {
	f := newBlogTrustFixture(t)
	p := seededBlog(t, f)
	ctx := context.Background()
	s := blogServer(f)
	body := soloBody(p)
	pub, e := createBlogPublication(ctx, f.db, f.proposer, body)
	if e != nil {
		t.Fatal(e)
	}
	rec := httptest.NewRecorder()
	s.blogPublicHandler(rec, blogRoute("GET", "", "", map[string]string{"shareID": pub.ID, "photoID": uuid.NewString()}))
	if rec.Code != 404 {
		t.Fatal("unselected public photo", rec.Code)
	}
	a, e := createBlogCase(ctx, f.db, "", "publication", pub.ID, "inappropriate", "Anonymous concern")
	if e != nil {
		t.Fatal(e)
	}
	b, e := createBlogCase(ctx, f.db, "", "publication", pub.ID, "inappropriate", "Changed description")
	if e != nil || a != b {
		t.Fatal("anonymous duplicate", e)
	}
	if e = decideBlogCase(ctx, f.db, f.stranger, a, "removed", "Review found a problem", 1); e != nil {
		t.Fatal(e)
	}
	if _, e = readBlogPublication(ctx, f.db, pub.ID); e == nil {
		t.Fatal("removed public link works")
	}
	if e = decideBlogCase(ctx, f.db, f.stranger, a, "restored", "Review appeal accepted", 2); e != nil {
		t.Fatal(e)
	}
	if _, e = readBlogPublication(ctx, f.db, pub.ID); e == nil {
		t.Fatal("restoration reused old public consent")
	}
}

func TestBlogSafetyControlsSurviveFeaturePause(t *testing.T) {
	s := &Server{cfg: config.Config{APIPrefix: "/v1"}}
	for _, c := range []struct{ method, path string }{{"DELETE", "/v1/blog/responses/x"}, {"DELETE", "/v1/blog/publications/x"}, {"GET", "/v1/blog/publications"}, {"POST", "/v1/blog/notices/x/appeal"}, {"POST", "/v1/blog/public/x/report"}, {"POST", "/v1/blog/reports/response/x"}} {
		called := false
		r := httptest.NewRecorder()
		s.featureFlagEnforcementMiddleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) { called = true })).ServeHTTP(r, httptest.NewRequest(c.method, c.path, nil))
		if !called {
			t.Fatal("safety control gated", c.path, r.Code)
		}
	}
	if s.shouldApplyIdempotency(httptest.NewRequest("POST", "/v1/blog/public/x/report", nil)) {
		t.Fatal("anonymous reports need no private replay record")
	}
	for _, role := range []string{"user", "analyst", "ops_admin"} {
		r := blogRoute("GET", "member", "", nil)
		r = r.WithContext(context.WithValue(r.Context(), securityPrincipalContextKey{}, securityPrincipal{UserID: "member", Roles: map[string]bool{role: true}}))
		if _, e := blogModerator(r); e == nil {
			t.Fatal("private evidence accessible", role)
		}
	}
}
func TestBlogQuotaReplayRecognitionPostgres(t *testing.T) {
	f := newBlogTrustFixture(t)
	p := seededBlog(t, f)
	v := revealedBlog(t, f, p)
	ctx := context.Background()
	for _, c := range []struct {
		actor, text        string
		contribution, want bool
	}{{f.invitee, "What book would you choose?", false, true}, {f.invitee, "Changed", false, false}, {f.proposer, "Author secret story", true, true}, {f.invitee, "Author secret story", true, false}} {
		got, e := blogResponseReplay(ctx, f.db, c.actor, v.ID, c.text, c.contribution)
		if e != nil || got != c.want {
			t.Fatal("replay", c, got, e)
		}
	}
}
