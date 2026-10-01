package mobile

import (
	"context"
	"encoding/json"
	"errors"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)

func TestProfileStoriesValidation(t *testing.T) {
	valid := func() map[string]any {
		return map[string]any{"published": false, "expected_version": float64(0), "stories": []any{map[string]any{"prompt_id": "little_joy", "text": " Coffee and a book. "}}}
	}
	got, err := parseProfileStories(valid())
	if err != nil || got.Published || got.Stories[0].Text != "Coffee and a book." {
		t.Fatalf("valid: %+v %v", got, err)
	}
	for _, name := range []string{"missing consent", "stale format", "duplicate", "empty", "too long", "photo alt", "invalid photo", "too many"} {
		t.Run(name, func(t *testing.T) {
			body := valid()
			row := body["stories"].([]any)[0].(map[string]any)
			switch name {
			case "missing consent":
				delete(body, "published")
			case "stale format":
				body["expected_version"] = 0.5
			case "duplicate":
				body["stories"] = []any{row, row}
			case "empty":
				row["text"] = "  "
			case "too long":
				row["text"] = strings.Repeat("日", 401)
			case "photo alt":
				row["photo_id"] = uuid.NewString()
			case "invalid photo":
				row["photo_id"] = "https://example.com/external.jpg"
				row["photo_description"] = "not owned"
			case "too many":
				body["stories"] = []any{row, row, row, row}
			}
			if _, err := parseProfileStories(body); err == nil {
				t.Fatal("invalid input accepted")
			}
		})
	}
	empty := valid()
	empty["stories"] = []any{}
	empty["published"] = true
	if got, err := parseProfileStories(empty); err != nil || got.Published {
		t.Fatal("empty collection remained published")
	}
}

func TestProfileStoriesConsentVisibilityVersionAndErasePostgres(t *testing.T) {
	f := newDatePlanFixture(t)
	ctx := context.Background()
	exec := func(q string, args ...any) {
		t.Helper()
		if _, err := f.db.Exec(q, args...); err != nil {
			t.Fatal(err)
		}
	}
	exec(`UPDATE user_management.users SET profile_completion=100 WHERE id=$1`, f.proposer)
	exec(`INSERT INTO user_management.profile_snapshots(user_id,profile_payload) VALUES($1,'{}')`, f.proposer)
	photo := uuid.NewString()
	exec(`INSERT INTO user_management.photos(id,user_id,photo_url,ordering,moderation_status,lifecycle_status) VALUES($1,$2,'https://example.test/story.jpg',0,'approved','active')`, photo, f.proposer)
	for i := 1; i <= 2; i++ {
		exec(`INSERT INTO user_management.photos(user_id,photo_url,ordering,moderation_status,lifecycle_status) VALUES($1,'https://example.test/approved.jpg',$2,'approved','active')`, f.proposer, i)
	}
	draft := profileStoriesView{Stories: []profileStory{{PromptID: "little_joy", Text: "Private Sunday reading", PhotoID: photo, PhotoDescription: "Reading in the garden"}}}
	if err := saveProfileStories(ctx, f.db, f.proposer, draft); err != nil {
		t.Fatal(err)
	}
	own, err := readProfileStories(ctx, f.db, f.proposer, f.proposer)
	if err != nil || own.Version != 1 || len(own.Photos) != 3 || len(own.Stories) != 1 {
		t.Fatalf("owner: %+v %v", own, err)
	}
	other, err := readProfileStories(ctx, f.db, f.invitee, f.proposer)
	if err != nil || len(other.Stories) != 0 || len(other.Photos) != 0 {
		t.Fatalf("private exposed: %+v %v", other, err)
	}
	if err = saveProfileStories(ctx, f.db, f.proposer, draft); !errors.Is(err, errDatingConflict) {
		t.Fatalf("stale save: %v", err)
	}
	draft.Version = 1
	draft.Published = true
	if err = saveProfileStories(ctx, f.db, f.proposer, draft); err != nil {
		t.Fatal(err)
	}
	other, err = readProfileStories(ctx, f.db, f.invitee, f.proposer)
	if err != nil || len(other.Stories) != 1 || other.Stories[0].PhotoURL == "" || len(other.Photos) != 0 {
		t.Fatalf("published: %+v %v", other, err)
	}
	var payload string
	if err = f.db.QueryRow(`SELECT payload::text FROM platform.domain_event_outbox WHERE aggregate_type='profile_stories' AND aggregate_id=$1 ORDER BY sequence_id DESC LIMIT 1`, f.proposer).Scan(&payload); err != nil {
		t.Fatal(err)
	}
	if strings.Contains(payload, "Sunday") || strings.Contains(payload, "garden") || strings.Contains(payload, photo) {
		t.Fatal("private story content in event")
	}
	// Gallery changes immediately remove the optional photo, retaining the text.
	exec(`UPDATE user_management.photos SET moderation_status='rejected' WHERE id=$1`, photo)
	other, err = readProfileStories(ctx, f.db, f.invitee, f.proposer)
	if err != nil || len(other.Stories) != 1 || other.Stories[0].PhotoID != "" || other.Stories[0].PhotoURL != "" {
		t.Fatalf("quarantined media: %+v %v", other, err)
	}
	draft.Version = 2
	if err = saveProfileStories(ctx, f.db, f.proposer, draft); !errors.Is(err, errDatePlanForbidden) {
		t.Fatalf("rejected photo accepted: %v", err)
	}
	draft.Stories[0].PhotoID = ""
	draft.Published = false
	if err = saveProfileStories(ctx, f.db, f.proposer, draft); err != nil {
		t.Fatal(err)
	}
	other, err = readProfileStories(ctx, f.db, f.invitee, f.proposer)
	if err != nil || len(other.Stories) != 0 {
		t.Fatal("withdrawal did not hide stories")
	}
	foreign := uuid.NewString()
	exec(`INSERT INTO user_management.photos(id,user_id,photo_url,ordering,moderation_status,lifecycle_status) VALUES($1,$2,'foreign',0,'approved','active')`, foreign, f.invitee)
	draft.Version = 3
	draft.Stories[0].PhotoID = foreign
	if err = saveProfileStories(ctx, f.db, f.proposer, draft); !errors.Is(err, errDatePlanForbidden) {
		t.Fatalf("foreign photo accepted: %v", err)
	}
	exec(`INSERT INTO user_management.blocked_users(user_id,blocked_user_id) VALUES($1,$2)`, f.invitee, f.proposer)
	if _, err = readProfileStories(ctx, f.db, f.invitee, f.proposer); !errors.Is(err, errDatePlanNotFound) {
		t.Fatalf("blocked read: %v", err)
	}
	var found bool
	for _, step := range accountErasureSteps() {
		if step.label == "profile_stories" {
			found = true
			exec(step.query, f.proposer)
		}
	}
	if !found {
		t.Fatal("erasure step missing")
	}
	own, err = readProfileStories(ctx, f.db, f.proposer, f.proposer)
	if err != nil || len(own.Stories) != 0 {
		t.Fatal("erasure retained story")
	}
}

func TestVoiceIntroductionsMembershipAndRevocationPostgres(t *testing.T) {
	f := newDatePlanFixture(t)
	ctx := context.Background()
	exec := func(q string, args ...any) {
		t.Helper()
		if _, err := f.db.Exec(q, args...); err != nil {
			t.Fatal(err)
		}
	}
	for _, status := range []string{"approved", "rejected", "pending"} {
		exec(`INSERT INTO matching.voice_icebreakers(id,match_id,sender_user_id,receiver_user_id,prompt_id,prompt_text,transcript,duration_seconds,status,moderation_status,audio_storage_path) VALUES($1,$2,$3,$4,'qa-prompt','A small ritual','Morning coffee',24,'sent',$5,'/private/qa-recording.webm')`, uuid.NewString(), f.matchID, f.proposer, f.invitee, status)
	}
	server := &Server{store: &runtimeStore{profileRepo: &profileRepository{pg: f.db}}}
	request := func(user string) *httptest.ResponseRecorder {
		t.Helper()
		rec := httptest.NewRecorder()
		server.listVoiceIntroductions(rec, datePlanRequest("GET", "/", f.matchID, "", user, ""))
		return rec
	}
	rec := request(f.invitee)
	if rec.Code != 200 {
		t.Fatalf("inbox %d %s", rec.Code, rec.Body.String())
	}
	var body struct {
		Introductions []voiceIcebreaker `json:"introductions"`
	}
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatal(err)
	}
	if len(body.Introductions) != 1 || body.Introductions[0].Transcript != "Morning coffee" || strings.Contains(rec.Body.String(), "/private/") || strings.Contains(rec.Body.String(), "token=") {
		t.Fatalf("unsafe inbox: %s", rec.Body.String())
	}
	if rec = request(f.stranger); rec.Code != 403 {
		t.Fatalf("stranger read %d", rec.Code)
	}
	if _, err := voicePairAvailable(ctx, f.db, f.matchID, f.invitee); err != nil {
		t.Fatal(err)
	}
	item := body.Introductions[0]
	item.AudioStoragePath = "/private/qa-recording.webm"
	item.HasAudio = true
	server.store.voiceIcebreakers = map[string]voiceIcebreaker{item.ID: item}
	server.cfg = configForPlaybackTest()
	grant, _, err := server.signedVoicePlaybackURL(httptest.NewRequest("GET", "http://localhost/v1/media/voice/"+item.ID, nil), item.ID, f.invitee)
	if err != nil {
		t.Fatal(err)
	}
	exec(`INSERT INTO user_management.blocked_users(user_id,blocked_user_id) VALUES($1,$2)`, f.proposer, f.invitee)
	mediaRequest := httptest.NewRequest("GET", grant, nil)
	route := chi.NewRouteContext()
	route.URLParams.Add("icebreakerID", item.ID)
	mediaRequest = mediaRequest.WithContext(context.WithValue(mediaRequest.Context(), chi.RouteCtxKey, route))
	mediaResponse := httptest.NewRecorder()
	server.serveVoicePlayback(mediaResponse, mediaRequest)
	if mediaResponse.Code != 403 {
		t.Fatalf("preissued grant bypassed block: %d", mediaResponse.Code)
	}
	if rec = request(f.invitee); rec.Code != 404 {
		t.Fatalf("blocked read %d", rec.Code)
	}
	if _, err := voicePairAvailable(ctx, f.db, f.matchID, f.invitee); err == nil {
		t.Fatal("blocked playback available")
	}
	exec(`DELETE FROM user_management.blocked_users WHERE user_id=$1 AND blocked_user_id=$2`, f.proposer, f.invitee)
	exec(`UPDATE user_management.users SET is_banned=TRUE WHERE id=$1`, f.proposer)
	if rec = request(f.invitee); rec.Code != 403 {
		t.Fatalf("banned read %d", rec.Code)
	}
	exec(`UPDATE user_management.users SET is_banned=FALSE WHERE id=$1`, f.proposer)
	exec(`UPDATE matching.matches SET unmatched_at=NOW() WHERE id=$1`, f.matchID)
	if _, err := voicePairAvailable(ctx, f.db, f.matchID, f.invitee); err == nil {
		t.Fatal("unmatched playback available")
	}
}
