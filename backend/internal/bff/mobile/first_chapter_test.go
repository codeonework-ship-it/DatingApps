package mobile

import (
	"context"
	"encoding/json"
	"errors"
	"github.com/google/uuid"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync"
	"testing"
)

func chapterStart(t *testing.T, f datePlanFixture) *firstChapter {
	t.Helper()
	c, e := mutateChapter(context.Background(), f.db, f.matchID, f.proposer, chapterCommand{ID: uuid.NewString(), Action: "start", Scene: "rain", Choice: chapterScenes[0].Beginnings[0]})
	if e != nil {
		t.Fatal(e)
	}
	return c
}
func chapterPairRead(t *testing.T, f datePlanFixture, actor string) map[string]any {
	t.Helper()
	s := &Server{store: &runtimeStore{profileRepo: &profileRepository{pg: f.db}}}
	rec := httptest.NewRecorder()
	s.chapterPairHandler(rec, datePlanRequest("GET", "/chapter", f.matchID, "", actor, ""))
	if rec.Code != 200 {
		t.Fatal(rec.Body.String())
	}
	var v map[string]any
	json.Unmarshal(rec.Body.Bytes(), &v)
	return v
}
func TestFirstChapterRolesRetryAndConflictPostgres(t *testing.T) {
	f := newDatePlanFixture(t)
	ctx := context.Background()
	c := chapterStart(t, f)
	retry, e := mutateChapter(ctx, f.db, f.matchID, f.proposer, chapterCommand{ID: c.ID, Action: "start", Scene: c.Scene, Choice: c.Beginning})
	if e != nil || retry.ID != c.ID {
		t.Fatal("retry", e)
	}
	if f.notifications(t, f.invitee, "chapter.started") != 1 {
		t.Fatal("invitation retry duplicated notification")
	}
	cmd := chapterCommand{ID: c.ID, Action: "surprise", Choice: chapterScenes[0].Surprises[0], Version: c.Version}
	if _, e = mutateChapter(ctx, f.db, f.matchID, f.stranger, cmd); !errors.Is(e, errDatePlanForbidden) {
		t.Fatal("outsider", e)
	}
	if _, e = mutateChapter(ctx, f.db, f.matchID, f.proposer, cmd); !errors.Is(e, errChapterInput) {
		t.Fatal("starter supplied both halves")
	}
	cmd.Version = 99
	if _, e = mutateChapter(ctx, f.db, f.matchID, f.invitee, cmd); !errors.Is(e, errDatingConflict) {
		t.Fatal("stale answer accepted")
	}
	cmd.Version = c.Version
	done, e := mutateChapter(ctx, f.db, f.matchID, f.invitee, cmd)
	if e != nil || done.Surprise == "" {
		t.Fatal(e)
	}
	if _, e = mutateChapter(ctx, f.db, f.matchID, f.invitee, cmd); e != nil {
		t.Fatal("answer retry", e)
	}
	if f.notifications(t, f.proposer, "chapter.completed") != 1 {
		t.Fatal("completion retry duplicated notification")
	}
	s := &Server{store: &runtimeStore{profileRepo: &profileRepository{pg: f.db}}}
	rec := httptest.NewRecorder()
	s.getDatingConnection(rec, datePlanRequest("GET", "/connection", f.matchID, "", f.proposer, ""))
	if rec.Code != 200 || !strings.Contains(rec.Body.String(), `"chapter_status":"complete"`) {
		t.Fatal("chat did not reconcile chapter status", rec.Body.String())
	}
	cmd.Choice = chapterScenes[0].Surprises[1]
	if _, e = mutateChapter(ctx, f.db, f.matchID, f.invitee, cmd); !errors.Is(e, errDatingConflict) {
		t.Fatal("saved answer overwritten")
	}
	var payload string
	if e = f.db.QueryRow(`SELECT payload::text FROM platform.domain_event_outbox WHERE aggregate_type='chapter.first_chapters' AND aggregate_id=$1 ORDER BY sequence_id DESC LIMIT 1`, c.ID).Scan(&payload); e != nil {
		t.Fatal(e)
	}
	if strings.Contains(payload, c.Beginning) || strings.Contains(payload, done.Surprise) {
		t.Fatal("private content in event")
	}
}
func TestFirstChapterConcurrentStartAndBlockPostgres(t *testing.T) {
	f := newDatePlanFixture(t)
	var wg sync.WaitGroup
	var mu sync.Mutex
	ok := 0
	for _, actor := range []string{f.proposer, f.invitee} {
		wg.Add(1)
		go func(actor string) {
			defer wg.Done()
			_, e := mutateChapter(context.Background(), f.db, f.matchID, actor, chapterCommand{ID: uuid.NewString(), Action: "start", Scene: "rain", Choice: chapterScenes[0].Beginnings[0]})
			if e == nil {
				mu.Lock()
				ok++
				mu.Unlock()
			} else if !errors.Is(e, errDatingConflict) {
				t.Error(e)
			}
		}(actor)
	}
	wg.Wait()
	if ok != 1 {
		t.Fatalf("open chapters: %d", ok)
	}
	if _, e := f.db.Exec(`INSERT INTO user_management.blocked_users(user_id,blocked_user_id) VALUES($1,$2)`, f.proposer, f.invitee); e != nil {
		t.Fatal(e)
	}
	s := &Server{store: &runtimeStore{profileRepo: &profileRepository{pg: f.db}}}
	rec := httptest.NewRecorder()
	s.chapterPairHandler(rec, datePlanRequest("GET", "/chapter", f.matchID, "", f.invitee, ""))
	if rec.Code != 404 {
		t.Fatalf("blocked: %d", rec.Code)
	}
}
func TestFirstChapterGreenPrivacyExpiryWithdrawalPostgres(t *testing.T) {
	f := newDatePlanFixture(t)
	ctx := context.Background()
	if e := saveGreen(ctx, f.db, f.matchID, f.proposer, greenLight{Choices: []string{"call", "date"}}); e != nil {
		t.Fatal(e)
	}
	other := chapterPairRead(t, f, f.invitee)
	if len(other["mutual"].([]any)) != 0 || len(other["mine"].(map[string]any)["choices"].([]any)) != 0 {
		t.Fatal("one-sided readiness exposed")
	}
	if e := saveGreen(ctx, f.db, f.matchID, f.invitee, greenLight{Choices: []string{"call"}}); e != nil {
		t.Fatal(e)
	}
	if v := chapterPairRead(t, f, f.proposer)["mutual"].([]any); len(v) != 1 || v[0] != "call" {
		t.Fatal("wrong mutual", v)
	}
	if e := saveGreen(ctx, f.db, f.matchID, f.invitee, greenLight{Choices: []string{}, Version: 1}); e != nil {
		t.Fatal(e)
	}
	if len(chapterPairRead(t, f, f.proposer)["mutual"].([]any)) != 0 {
		t.Fatal("withdrawal ignored")
	}
	if e := saveGreen(ctx, f.db, f.matchID, f.invitee, greenLight{Choices: []string{"date"}, Version: 1}); !errors.Is(e, errDatingConflict) {
		t.Fatal("stale readiness overwrote withdrawal")
	}
	if _, e := f.db.Exec(`UPDATE matching.chapter_green_lights SET expires_at=NOW()-INTERVAL '1 second' WHERE match_id=$1`, f.matchID); e != nil {
		t.Fatal(e)
	}
	if len(chapterPairRead(t, f, f.proposer)["mine"].(map[string]any)["choices"].([]any)) != 0 {
		t.Fatal("expired choice disclosed")
	}
}
func TestFirstChapterComfortVisibilityPostgres(t *testing.T) {
	f := newDatePlanFixture(t)
	ctx := context.Background()
	c := comfortView{Cards: []comfortCard{{Topic: "pace", Original: "أفضل التحدث ببطء", Language: "Arabic", Translation: "I prefer a slower pace", TranslationLanguage: "English"}}}
	if e := saveComfort(ctx, f.db, f.proposer, c); e != nil {
		t.Fatal(e)
	}
	if len(chapterPairRead(t, f, f.invitee)["comfort"].([]any)) != 0 {
		t.Fatal("private comfort leaked")
	}
	c.Shared = true
	c.Version = 1
	if e := saveComfort(ctx, f.db, f.proposer, c); e != nil {
		t.Fatal(e)
	}
	raw, _ := json.Marshal(chapterPairRead(t, f, f.invitee))
	if !strings.Contains(string(raw), c.Cards[0].Original) || !strings.Contains(string(raw), c.Cards[0].Translation) {
		t.Fatal("original or translation lost")
	}
	c.Shared = false
	c.Version = 2
	if e := saveComfort(ctx, f.db, f.proposer, c); e != nil {
		t.Fatal(e)
	}
	if len(chapterPairRead(t, f, f.invitee)["comfort"].([]any)) != 0 {
		t.Fatal("withdrawn comfort leaked")
	}
	c.Cards[0].Original = ""
	if validComfort(c) {
		t.Fatal("empty card accepted")
	}
}
func TestFirstChapterSoloSharingPublicDTOAndRevocationPostgres(t *testing.T) {
	f := newDatePlanFixture(t)
	ctx := context.Background()
	cmd := publicationCommand{ID: uuid.NewString(), Scene: "rain", Beginning: chapterScenes[0].Beginnings[0]}
	p, e := createPublication(ctx, f.db, f.proposer, cmd)
	if e != nil {
		t.Fatal(e)
	}
	retry, e := createPublication(ctx, f.db, f.proposer, cmd)
	if e != nil || retry.ID != p.ID {
		t.Fatal("publication retry", e)
	}
	value, e := readPublicChapter(ctx, f.db, p.ID)
	if e != nil {
		t.Fatal(e)
	}
	raw, _ := json.Marshal(value)
	for _, private := range []string{f.proposer, f.invitee, f.matchID, "owner_id", "chapter_id", "choices", "email"} {
		if strings.Contains(string(raw), private) {
			t.Fatal("public leak", private)
		}
	}
	if _, e = changePublication(ctx, f.db, f.stranger, publicationCommand{ID: p.ID, Action: "revoke", Version: p.Version}); !errors.Is(e, errDatePlanForbidden) {
		t.Fatal("stranger revoked")
	}
	if _, e = changePublication(ctx, f.db, f.proposer, publicationCommand{ID: p.ID, Action: "revoke", Version: p.Version}); e != nil {
		t.Fatal(e)
	}
	if _, e = readPublicChapter(ctx, f.db, p.ID); e == nil {
		t.Fatal("revoked link works")
	}
	if _, e = createPublication(ctx, f.db, f.proposer, cmd); !errors.Is(e, errDatingConflict) {
		t.Fatal("retry resurrected link")
	}
}
func TestFirstChapterJointApprovalPostgres(t *testing.T) {
	f := newDatePlanFixture(t)
	ctx := context.Background()
	c := chapterStart(t, f)
	_, e := mutateChapter(ctx, f.db, f.matchID, f.invitee, chapterCommand{ID: c.ID, Action: "surprise", Choice: chapterScenes[0].Surprises[0], Version: 1})
	if e != nil {
		t.Fatal(e)
	}
	cmd := publicationCommand{ID: uuid.NewString(), Chapter: c.ID, MatchID: f.matchID}
	if _, e = createPublication(ctx, f.db, f.proposer, cmd); !errors.Is(e, errDatePlanForbidden) {
		t.Fatal("non-alumni", e)
	}
	if _, e = f.db.Exec(`INSERT INTO matching.match_graduations(match_id,proposer_user_id,partner_user_id,status,decided_at) VALUES($1,$2,$3,'confirmed',NOW())`, f.matchID, f.proposer, f.invitee); e != nil {
		t.Fatal(e)
	}
	p, e := createPublication(ctx, f.db, f.proposer, cmd)
	if e != nil {
		t.Fatal(e)
	}
	if _, e = readPublicChapter(ctx, f.db, p.ID); e == nil {
		t.Fatal("one approval published")
	}
	if _, e = changePublication(ctx, f.db, f.stranger, publicationCommand{ID: p.ID, Action: "approve", Version: 1}); !errors.Is(e, errDatePlanForbidden) {
		t.Fatal("outsider approved")
	}
	p, e = changePublication(ctx, f.db, f.invitee, publicationCommand{ID: p.ID, Action: "approve", Version: 1})
	if e != nil {
		t.Fatal(e)
	}
	if _, e = readPublicChapter(ctx, f.db, p.ID); e != nil {
		t.Fatal("both approval", e)
	}
	if _, e = changePublication(ctx, f.db, f.proposer, publicationCommand{ID: p.ID, Action: "revoke", Version: p.Version}); e != nil {
		t.Fatal(e)
	}
	if _, e = readPublicChapter(ctx, f.db, p.ID); e == nil {
		t.Fatal("coauthor revocation failed")
	}
}
func TestFirstChapterRoutePrivacyAndPlanCategories(t *testing.T) {
	for _, path := range []string{"/chapters/comfort", "/chapters/publications", "/matches/x/chapter", "/matches/x/chapter/green-light"} {
		if isPublicSecurityPath("/v1", "/v1"+path, http.MethodGet) {
			t.Fatal("private path exposed", path)
		}
		if featureFlagForRoute("/v1", "/v1"+path) != "intentional_dating_enabled" {
			t.Fatal("ungated route")
		}
	}
	for _, path := range []string{"/chapters/catalogue", "/chapters/public/abc"} {
		if !isPublicSecurityPath("/v1", "/v1"+path, http.MethodGet) || isPublicSecurityPath("/v1", "/v1"+path, http.MethodPost) {
			t.Fatal("public write or blocked read")
		}
	}
	for _, s := range chapterScenes {
		if !allowedDatePlanVenues[s.Venue] {
			t.Fatal("invalid plan venue", s.Venue)
		}
	}
}

func TestFirstChapterWithdrawalSurvivesFeaturePause(t *testing.T) {
	s := &Server{}
	called := false
	handler := s.featureFlagEnforcementMiddleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) { called = true; w.WriteHeader(204) }))
	request := httptest.NewRequest(http.MethodDelete, "/chapters/publications/"+uuid.NewString(), nil)
	rec := httptest.NewRecorder()
	handler.ServeHTTP(rec, request)
	if !called || rec.Code != 204 {
		t.Fatal("withdrawal required feature policy")
	}
	if isPublicSecurityPath("", request.URL.Path, request.Method) {
		t.Fatal("withdrawal bypassed authentication")
	}
}
func TestFirstChapterPublicLinkClosesOnOwnerDeactivationPostgres(t *testing.T) {
	f := newDatePlanFixture(t)
	ctx := context.Background()
	p, e := createPublication(ctx, f.db, f.proposer, publicationCommand{ID: uuid.NewString(), Scene: "rain", Beginning: chapterScenes[0].Beginnings[0]})
	if e != nil {
		t.Fatal(e)
	}
	if _, e = f.db.Exec(`UPDATE user_management.users SET is_active=FALSE WHERE id=$1`, f.proposer); e != nil {
		t.Fatal(e)
	}
	if _, e = readPublicChapter(ctx, f.db, p.ID); e == nil {
		t.Fatal("inactive owner public link remains")
	}
}

func TestFirstChapterInvitationVelocityPostgres(t *testing.T) {
	f := newDatePlanFixture(t)
	ctx := context.Background()
	for i := 0; i < 3; i++ {
		c := chapterStart(t, f)
		if _, e := mutateChapter(ctx, f.db, f.matchID, f.proposer, chapterCommand{ID: c.ID, Action: "close", Version: c.Version}); e != nil {
			t.Fatal(e)
		}
	}
	if _, e := mutateChapter(ctx, f.db, f.matchID, f.proposer, chapterCommand{ID: uuid.NewString(), Action: "start", Scene: "rain", Choice: chapterScenes[0].Beginnings[0]}); !errors.Is(e, errChapterLimit) {
		t.Fatal("invitation velocity not enforced", e)
	}
	if f.notifications(t, f.invitee, "chapter.started") != 3 {
		t.Fatal("unexpected notifications")
	}
}
