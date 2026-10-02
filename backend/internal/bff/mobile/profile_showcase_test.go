package mobile

import (
	"context"
	"strings"
	"testing"

	"github.com/google/uuid"
)

func TestShowcaseExcerpt(t *testing.T) {
	if got := showcaseExcerpt("  Short   and\nsweet. "); got != "Short and sweet." {
		t.Fatalf("short: %q", got)
	}
	long := strings.Repeat("slow coffee ", 40)
	got := showcaseExcerpt(long)
	if !strings.HasSuffix(got, "…") || len([]rune(got)) > profileShowcaseExcerptLen+1 || strings.HasSuffix(strings.TrimSuffix(got, "…"), " ") {
		t.Fatalf("long: %q", got)
	}
}

// Public chapters and wall photos reach the profile only with the owner's
// consent, and only what is already public and visible to that viewer.
func TestProfileShowcaseConsentAndVisibilityPostgres(t *testing.T) {
	f := newActivityFixture(t)
	var ready bool
	if err := f.db.QueryRow(`SELECT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema='user_management' AND table_name='user_settings' AND column_name='profile_showcase_visible')`).Scan(&ready); err != nil || !ready {
		t.Skip("migration 130_profile_showcase_consent is not applied")
	}
	ctx := context.Background()
	owner, viewer := f.proposer, f.invitee
	for _, u := range []string{owner, viewer, f.groupMate, f.blockedFriend} {
		blogEligible(t, f.datePlanFixture, u)
	}
	chapter := func(title, audience string) string {
		t.Helper()
		p, err := saveBlog(ctx, f.db, owner, uuid.NewString(), blogDraft{Title: title, Body: "A short story about " + title + ".", Audience: audience})
		if err != nil {
			t.Fatal(err)
		}
		return p.ID
	}
	public := chapter("Public chapter", "community")
	chapter("Friends chapter", "friends")
	chapter("Private chapter", "private")
	underReview := chapter("Reported chapter", "community")
	if _, err := f.db.Exec(`INSERT INTO matching.blog_cases(id,content_type,content_id,subject_id,reporter_key,reason,snapshot)
 VALUES($1,'post',$2,$3,'test-reporter','inappropriate','{}')`, uuid.NewString(), underReview, owner); err != nil {
		t.Fatal(err)
	}

	// One photo per theme per member: use two themes.
	themes := []string{}
	rows, err := f.db.Query(`SELECT id::text FROM matching.photo_themes ORDER BY slug='comfort-food' DESC,slug LIMIT 2`)
	if err != nil {
		t.Fatal(err)
	}
	for rows.Next() {
		var id string
		_ = rows.Scan(&id)
		themes = append(themes, id)
	}
	rows.Close()
	if len(themes) < 2 {
		t.Skip("needs two photo themes")
	}
	upload := func(themeID, caption string, featured bool) string {
		t.Helper()
		id := uuid.NewString()
		if rec := themeUpload(t, f.s, owner, themeID, id, caption); rec.Code != 200 {
			t.Fatal("upload", rec.Code, rec.Body.String())
		}
		if featured {
			if _, err := setPhotoFeaturing(ctx, f.db, owner, themeID, id, true); err != nil {
				t.Fatal(err)
			}
		}
		return id
	}
	wallPhoto := upload(themes[0], "Sunday soup", true)
	upload(themes[1], "Not shared to the wall", false)

	read := func(as string) profileShowcase {
		t.Helper()
		out, err := readProfileShowcase(ctx, f.db, as, owner)
		if err != nil {
			t.Fatal(err)
		}
		return out
	}
	chapterIDs := func(s profileShowcase) []string {
		ids := []string{}
		for _, c := range s.Chapters {
			ids = append(ids, c.ID)
		}
		return ids
	}

	// Default: no consent, so other members see nothing at all.
	if got := read(viewer); got.Enabled || len(got.Chapters) != 0 || len(got.Photos) != 0 {
		t.Fatalf("shown without consent: %+v", got)
	}
	// The owner previews what would show, with consent off.
	own := read(owner)
	if own.Enabled || strings.Join(chapterIDs(own), ",") != public || len(own.Photos) != 1 || own.Photos[0].ID != wallPhoto {
		t.Fatalf("owner preview: %+v", own)
	}

	if err := setProfileShowcaseVisiblePG(ctx, f.db, owner, true); err != nil {
		t.Fatal(err)
	}
	got := read(viewer)
	if !got.Enabled || strings.Join(chapterIDs(got), ",") != public {
		t.Fatalf("with consent, only the public active chapter: %+v", got)
	}
	if len(got.Photos) != 1 || got.Photos[0].ID != wallPhoto {
		t.Fatalf("with consent, only the wall photo: %+v", got.Photos)
	}
	if got.Chapters[0].Excerpt != "A short story about Public chapter." {
		t.Fatalf("excerpt: %q", got.Chapters[0].Excerpt)
	}

	// A block either way hides everything from the blocked side.
	if _, err := f.db.Exec(`INSERT INTO user_management.blocked_users(user_id,blocked_user_id) VALUES($1,$2)`, owner, f.groupMate); err != nil {
		t.Fatal(err)
	}
	// The fixture's blockedFriend has blocked the owner (the other direction).
	// Regression: the blocked side must not learn the owner's consent either
	// (enabled stayed true while the owner's profile was already a 404).
	for name, blocked := range map[string]string{"owner blocked viewer": f.groupMate, "viewer blocked owner": f.blockedFriend} {
		if got := read(blocked); got.Enabled || len(got.Chapters) != 0 || len(got.Photos) != 0 {
			t.Fatalf("%s: blocked side saw the showcase or its consent: %+v", name, got)
		}
	}
	if got := read(viewer); !got.Enabled || len(got.Chapters) != 1 {
		t.Fatalf("a block between others changed what the viewer sees: %+v", got)
	}
	if got := read(owner); !got.Enabled || len(got.Chapters) != 1 {
		t.Fatalf("blocks changed the owner's preview: %+v", got)
	}

	// Withdrawing consent hides it again.
	if err := setProfileShowcaseVisiblePG(ctx, f.db, owner, false); err != nil {
		t.Fatal(err)
	}
	if got := read(viewer); got.Enabled || len(got.Chapters) != 0 || len(got.Photos) != 0 {
		t.Fatalf("shown after withdrawal: %+v", got)
	}
}

func TestProfileShowcaseRoutesOwnership(t *testing.T) {
	me, other := uuid.NewString(), uuid.NewString()
	if !pathOwnedByPrincipal("/v1", "/v1/profile/"+other+"/showcase", "GET", me) {
		t.Fatal("members must be able to read another member's showcase (consent is checked in the handler)")
	}
	for _, method := range []string{"GET", "PUT"} {
		if pathOwnedByPrincipal("/v1", "/v1/profile/"+other+"/showcase/consent", method, me) {
			t.Fatalf("%s of another member's consent was allowed", method)
		}
		if !pathOwnedByPrincipal("/v1", "/v1/profile/"+me+"/showcase/consent", method, me) {
			t.Fatalf("%s of own consent was refused", method)
		}
	}
}

// WEB-12: members can record that they viewed a profile, but only as
// themselves.
func TestProfileViewRecordingIsAllowedOnlyAsYourself(t *testing.T) {
	me, other := uuid.NewString(), uuid.NewString()
	if !pathOwnedByPrincipal("/v1", "/v1/profile/views", "POST", me) {
		t.Fatal("recording a profile view was refused by the path rule")
	}
	if pathOwnedByPrincipal("/v1", "/v1/profile/"+other, "PUT", me) {
		t.Fatal("the exemption must not open other members' profile writes")
	}
}
