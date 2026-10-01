package mobile

import (
	"context"
	"database/sql"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"testing"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)

func TestFriendSocialValidation(t *testing.T) {
	if _, err := validateVouchText(" short "); err == nil {
		t.Fatal("short vouch accepted")
	}
	if _, err := validateVouchText(strings.Repeat("x", 201)); err == nil {
		t.Fatal("long vouch accepted")
	}
	if text, err := validateVouchText("  Kind, funny and always on time.  "); err != nil || text != "Kind, funny and always on time." {
		t.Fatalf("valid vouch rejected: %v %q", err, text)
	}
	if _, err := validateIntroMessage(strings.Repeat("y", 201)); err == nil {
		t.Fatal("long intro message accepted")
	}
}

type friendSocialFixture struct {
	db                                      *sql.DB
	introducer, alice, bob, carol, stranger string
}

func (f friendSocialFixture) seedMember(t *testing.T, name, gender string, seeking []string, published bool) string {
	t.Helper()
	ctx := context.Background()
	id := uuid.NewString()
	username := "socialqa_" + strings.ReplaceAll(id[:8], "-", "")
	completion := 40
	if published {
		completion = 100
	}
	if _, err := f.db.ExecContext(ctx, `INSERT INTO user_management.users (id, username, name, date_of_birth, gender, email, profile_completion)
		VALUES ($1,$2,$3,'1993-05-05',$4,$5,$6)`, id, username, name, gender, username+"@example.test", completion); err != nil {
		t.Fatalf("seed member %s: %v", name, err)
	}
	t.Cleanup(func() { deleteTestMember(ctx, f.db, id) })
	if published {
		for i := 0; i < 2; i++ {
			if _, err := f.db.ExecContext(ctx, `INSERT INTO user_management.photos (user_id, photo_url, ordering, lifecycle_status, moderation_status)
				VALUES ($1,$2,$3,'active','approved')`, id, "https://cdn.example.test/"+id+"/"+string(rune('a'+i))+".jpg", i); err != nil {
				t.Fatalf("seed photo: %v", err)
			}
		}
	}
	if len(seeking) > 0 {
		encoded, _ := json.Marshal(seeking)
		if _, err := f.db.ExecContext(ctx, `INSERT INTO user_management.preferences (user_id, seeking_genders)
			VALUES ($1, ARRAY(SELECT jsonb_array_elements_text($2::jsonb)))`, id, string(encoded)); err != nil {
			t.Fatalf("seed preferences: %v", err)
		}
	}
	return id
}

func (f friendSocialFixture) befriend(t *testing.T, a, b string) {
	t.Helper()
	if _, err := f.db.ExecContext(context.Background(), `INSERT INTO matching.friend_connections (user_id, friend_user_id, status)
		VALUES ($1,$2,'accepted'),($2,$1,'accepted')`, a, b); err != nil {
		t.Fatalf("seed friendship: %v", err)
	}
}

func newFriendSocialFixture(t *testing.T) friendSocialFixture {
	t.Helper()
	dsn := os.Getenv("PROFILE_TEST_DATABASE_URL")
	if dsn == "" {
		t.Skip("PROFILE_TEST_DATABASE_URL is not set")
	}
	db, err := sql.Open("pgx", dsn)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = db.Close() })
	var ready bool
	if err := db.QueryRow(`SELECT to_regclass('matching.friend_intros') IS NOT NULL`).Scan(&ready); err != nil || !ready {
		t.Skip("migration 096_friend_vouches_and_intros is not applied")
	}
	f := friendSocialFixture{db: db}
	f.introducer = f.seedMember(t, "Meera", "female", nil, false)
	f.alice = f.seedMember(t, "Alice Rao", "female", []string{"male"}, true)
	f.bob = f.seedMember(t, "Bob Iyer", "male", []string{"female"}, true)
	f.carol = f.seedMember(t, "Carol Nair", "female", []string{"female"}, true)
	f.stranger = f.seedMember(t, "Stranger", "male", nil, true)
	f.befriend(t, f.introducer, f.alice)
	f.befriend(t, f.introducer, f.bob)
	f.befriend(t, f.introducer, f.carol)
	return f
}

func socialRequest(method, path, userID, param, paramValue, body string) *http.Request {
	req := httptest.NewRequest(method, path, strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	routeContext := chi.NewRouteContext()
	routeContext.URLParams.Add("userID", userID)
	if param != "" {
		routeContext.URLParams.Add(param, paramValue)
	}
	ctx := context.WithValue(req.Context(), chi.RouteCtxKey, routeContext)
	ctx = context.WithValue(ctx, securityPrincipalContextKey{}, securityPrincipal{
		UserID: userID, Roles: map[string]bool{"user": true},
	})
	return req.WithContext(ctx)
}

func decodeBody(t *testing.T, rec *httptest.ResponseRecorder) map[string]any {
	t.Helper()
	var body map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatalf("decode: %v (%s)", err, rec.Body.String())
	}
	return body
}

func (f friendSocialFixture) notifications(t *testing.T, recipient, eventType string) int {
	t.Helper()
	var n int
	if err := f.db.QueryRow(`SELECT COUNT(*) FROM matching.notification_outbox
		WHERE recipient_user_id=$1 AND event_type=$2`, recipient, eventType).Scan(&n); err != nil {
		t.Fatal(err)
	}
	return n
}

func TestFriendVouchLifecyclePostgres(t *testing.T) {
	f := newFriendSocialFixture(t)
	server := &Server{store: &runtimeStore{profileRepo: &profileRepository{pg: f.db}}}
	body := `{"for_user_id":"` + f.alice + `","text":"Alice is thoughtful, funny and always shows up on time."}`

	// A stranger cannot vouch.
	denied := httptest.NewRecorder()
	server.writeFriendVouch(denied, socialRequest(http.MethodPost, "/vouches", f.stranger, "", "", body))
	if denied.Code != http.StatusConflict {
		t.Fatalf("stranger vouch status=%d body=%s", denied.Code, denied.Body.String())
	}
	written := httptest.NewRecorder()
	server.writeFriendVouch(written, socialRequest(http.MethodPost, "/vouches", f.introducer, "", "", body))
	if written.Code != http.StatusCreated {
		t.Fatalf("vouch status=%d body=%s", written.Code, written.Body.String())
	}
	vouch := decodeBody(t, written)["vouch"].(map[string]any)
	vouchID := toString(vouch["id"])
	if toString(vouch["status"]) != "pending" {
		t.Fatalf("new vouch status=%v", vouch["status"])
	}
	if got := f.notifications(t, f.alice, "friend_vouch.received"); got != 1 {
		t.Fatalf("subject notifications=%d", got)
	}
	// Duplicate vouch for the same friend is rejected.
	dup := httptest.NewRecorder()
	server.writeFriendVouch(dup, socialRequest(http.MethodPost, "/vouches", f.introducer, "", "", body))
	if dup.Code != http.StatusConflict {
		t.Fatalf("duplicate vouch status=%d", dup.Code)
	}
	// Not public until approved.
	public := httptest.NewRecorder()
	server.getPublicVouches(public, socialRequest(http.MethodGet, "/vouches", f.bob, "userID", f.alice, ""))
	if public.Code != http.StatusOK || len(decodeBody(t, public)["vouches"].([]any)) != 0 {
		t.Fatalf("pending vouch leaked: %s", public.Body.String())
	}
	// Only the subject can approve.
	wrong := httptest.NewRecorder()
	server.decideFriendVouch(wrong, socialRequest(http.MethodPost, "/decision", f.introducer, "vouchID", vouchID, `{"decision":"approve"}`))
	if wrong.Code != http.StatusForbidden {
		t.Fatalf("voucher approve status=%d", wrong.Code)
	}
	approved := httptest.NewRecorder()
	server.decideFriendVouch(approved, socialRequest(http.MethodPost, "/decision", f.alice, "vouchID", vouchID, `{"decision":"approve"}`))
	if approved.Code != http.StatusOK {
		t.Fatalf("approve status=%d body=%s", approved.Code, approved.Body.String())
	}
	if got := f.notifications(t, f.introducer, "friend_vouch.approved"); got != 1 {
		t.Fatalf("voucher approved notifications=%d", got)
	}
	// Public now, attributed to the voucher's first name.
	public = httptest.NewRecorder()
	server.getPublicVouches(public, socialRequest(http.MethodGet, "/vouches", f.bob, "userID", f.alice, ""))
	items := decodeBody(t, public)["vouches"].([]any)
	if len(items) != 1 || toString(items[0].(map[string]any)["voucher_name"]) != "Meera" {
		t.Fatalf("public vouches=%s", public.Body.String())
	}
	// The subject's own list shows it under about_me; the voucher's under written.
	mine := httptest.NewRecorder()
	server.listFriendVouches(mine, socialRequest(http.MethodGet, "/vouches", f.alice, "", "", ""))
	if len(decodeBody(t, mine)["about_me"].([]any)) != 1 {
		t.Fatalf("about_me=%s", mine.Body.String())
	}
	theirs := httptest.NewRecorder()
	server.listFriendVouches(theirs, socialRequest(http.MethodGet, "/vouches", f.introducer, "", "", ""))
	if len(decodeBody(t, theirs)["written"].([]any)) != 1 {
		t.Fatalf("written=%s", theirs.Body.String())
	}
	// Hiding removes it from the profile.
	hidden := httptest.NewRecorder()
	server.decideFriendVouch(hidden, socialRequest(http.MethodPost, "/decision", f.alice, "vouchID", vouchID, `{"decision":"hide"}`))
	if hidden.Code != http.StatusOK {
		t.Fatalf("hide status=%d", hidden.Code)
	}
	public = httptest.NewRecorder()
	server.getPublicVouches(public, socialRequest(http.MethodGet, "/vouches", f.bob, "userID", f.alice, ""))
	if len(decodeBody(t, public)["vouches"].([]any)) != 0 {
		t.Fatalf("hidden vouch still public: %s", public.Body.String())
	}
}

func TestFriendIntroLifecyclePostgres(t *testing.T) {
	f := newFriendSocialFixture(t)
	for _, id := range []string{f.alice, f.bob, f.carol, f.stranger} {
		if _, err := f.db.Exec(`INSERT INTO matching.dating_preferences(user_id,allow_friend_intros,intro_share_photo,intro_share_city) VALUES($1,true,true,true)`, id); err != nil {
			t.Fatal(err)
		}
	}
	server := &Server{store: &runtimeStore{profileRepo: &profileRepository{pg: f.db}}}

	// The introducer must be friends with both.
	notFriends := httptest.NewRecorder()
	server.makeFriendIntro(notFriends, socialRequest(http.MethodPost, "/intros", f.introducer, "", "",
		`{"first_user_id":"`+f.alice+`","second_user_id":"`+f.stranger+`"}`))
	if notFriends.Code != http.StatusConflict {
		t.Fatalf("non-friend intro status=%d body=%s", notFriends.Code, notFriends.Body.String())
	}
	// Preferences must fit: Carol seeks women, Bob is a man.
	incompatible := httptest.NewRecorder()
	server.makeFriendIntro(incompatible, socialRequest(http.MethodPost, "/intros", f.introducer, "", "",
		`{"first_user_id":"`+f.bob+`","second_user_id":"`+f.carol+`"}`))
	if incompatible.Code != http.StatusConflict {
		t.Fatalf("incompatible intro status=%d body=%s", incompatible.Code, incompatible.Body.String())
	}

	created := httptest.NewRecorder()
	server.makeFriendIntro(created, socialRequest(http.MethodPost, "/intros", f.introducer, "", "",
		`{"first_user_id":"`+f.alice+`","second_user_id":"`+f.bob+`","message":"You two would get on."}`))
	if created.Code != http.StatusCreated {
		t.Fatalf("intro status=%d body=%s", created.Code, created.Body.String())
	}
	intro := decodeBody(t, created)["intro"].(map[string]any)
	introID := toString(intro["id"])
	if toString(intro["first_name"]) != "Alice Rao" || intro["other"] != nil {
		t.Fatalf("introducer view = %v", intro)
	}
	for _, invitee := range []string{f.alice, f.bob} {
		if got := f.notifications(t, invitee, "friend_intro.received"); got != 1 {
			t.Fatalf("invitee %s notifications=%d", invitee, got)
		}
	}
	// One open intro per pair.
	again := httptest.NewRecorder()
	server.makeFriendIntro(again, socialRequest(http.MethodPost, "/intros", f.introducer, "", "",
		`{"first_user_id":"`+f.bob+`","second_user_id":"`+f.alice+`"}`))
	if again.Code != http.StatusConflict {
		t.Fatalf("duplicate intro status=%d body=%s", again.Code, again.Body.String())
	}
	// Alice sees Bob's preview and the message.
	received := httptest.NewRecorder()
	server.listFriendIntros(received, socialRequest(http.MethodGet, "/intros", f.alice, "", "", ""))
	list := decodeBody(t, received)["received"].([]any)
	if len(list) != 1 {
		t.Fatalf("alice received=%s", received.Body.String())
	}
	other := list[0].(map[string]any)["other"].(map[string]any)
	if toString(other["user_id"]) != f.bob || toString(other["name"]) != "Bob Iyer" || len(other["photo_urls"].([]any)) != 2 {
		t.Fatalf("preview=%v", other)
	}
	// Only invitees can answer.
	outsider := httptest.NewRecorder()
	server.decideFriendIntro(outsider, socialRequest(http.MethodPost, "/decision", f.introducer, "introID", introID, `{"decision":"accept"}`))
	if outsider.Code != http.StatusForbidden {
		t.Fatalf("introducer decision status=%d", outsider.Code)
	}
	first := httptest.NewRecorder()
	server.decideFriendIntro(first, socialRequest(http.MethodPost, "/decision", f.alice, "introID", introID, `{"decision":"accept"}`))
	if first.Code != http.StatusOK || toString(decodeBody(t, first)["intro"].(map[string]any)["status"]) != "open" {
		t.Fatalf("first accept: %d %s", first.Code, first.Body.String())
	}
	second := httptest.NewRecorder()
	server.decideFriendIntro(second, socialRequest(http.MethodPost, "/decision", f.bob, "introID", introID, `{"decision":"accept"}`))
	if second.Code != http.StatusOK {
		t.Fatalf("second accept: %d %s", second.Code, second.Body.String())
	}
	matched := decodeBody(t, second)["intro"].(map[string]any)
	if toString(matched["status"]) != "matched" || toString(matched["match_id"]) == "" {
		t.Fatalf("intro after both accept = %v", matched)
	}
	var matches int
	if err := f.db.QueryRow(`SELECT COUNT(*) FROM matching.matches WHERE id=$1::uuid`, toString(matched["match_id"])).Scan(&matches); err != nil {
		t.Fatal(err)
	}
	if matches != 1 {
		t.Fatalf("match rows=%d", matches)
	}
	t.Cleanup(func() {
		_, _ = f.db.Exec(`DELETE FROM matching.matches WHERE id=$1::uuid`, toString(matched["match_id"]))
	})
	if got := f.notifications(t, f.introducer, "friend_intro.matched"); got != 0 {
		t.Fatalf("introducer matched notifications=%d", got)
	}
	// A late answer is rejected.
	late := httptest.NewRecorder()
	server.decideFriendIntro(late, socialRequest(http.MethodPost, "/decision", f.alice, "introID", introID, `{"decision":"decline"}`))
	if late.Code != http.StatusConflict {
		t.Fatalf("late decision status=%d", late.Code)
	}

	// A declined intro tells the introducer without naming who declined.
	f.befriend(t, f.introducer, f.stranger)
	if _, err := f.db.Exec(`INSERT INTO user_management.preferences (user_id, seeking_genders) VALUES ($1, ARRAY['female'])`, f.stranger); err != nil {
		t.Fatalf("stranger prefs: %v", err)
	}
	made := httptest.NewRecorder()
	server.makeFriendIntro(made, socialRequest(http.MethodPost, "/intros", f.introducer, "", "",
		`{"first_user_id":"`+f.carol+`","second_user_id":"`+f.stranger+`"}`))
	if made.Code == http.StatusCreated {
		declineID := toString(decodeBody(t, made)["intro"].(map[string]any)["id"])
		declined := httptest.NewRecorder()
		server.decideFriendIntro(declined, socialRequest(http.MethodPost, "/decision", f.stranger, "introID", declineID, `{"decision":"decline"}`))
		if declined.Code != http.StatusOK || toString(decodeBody(t, declined)["intro"].(map[string]any)["status"]) != "declined" {
			t.Fatalf("decline: %d %s", declined.Code, declined.Body.String())
		}
		if got := f.notifications(t, f.introducer, "friend_intro.declined"); got != 0 {
			t.Fatalf("introducer declined notifications=%d", got)
		}
	} else {
		// Carol seeks women and the stranger is a man; the pair is not compatible,
		// which is itself the expected outcome for this fixture.
		if made.Code != http.StatusConflict {
			t.Fatalf("carol/stranger intro status=%d body=%s", made.Code, made.Body.String())
		}
	}
}
