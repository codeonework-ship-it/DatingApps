package mobile

import (
	"bytes"
	"context"
	"encoding/json"
	"image"
	"image/color"
	"image/jpeg"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/google/uuid"
	"go.uber.org/zap"

	"github.com/verified-dating/backend/internal/platform/config"
	"github.com/verified-dating/backend/internal/platform/mediastore"
)

// Group cover photos (migration 121, group_covers.go), stored through a local
// media store in a temp directory.

type stubCoverModerator struct{ status string }

func (m *stubCoverModerator) Moderate(context.Context, validatedPhotoUpload) (mediaModerationResult, error) {
	return mediaModerationResult{Status: m.status, Provider: "test", Reason: "test:" + m.status, Labels: []mediaModerationLabel{}}, nil
}

type coverHarness struct {
	groupsHarness
	root   string
	store  *mediastore.LocalStore
	mod    *stubCoverModerator
	groups *[]string
}

func newCoverHarness(t *testing.T) coverHarness {
	t.Helper()
	h := newGroupsHarness(t)
	var ready bool
	if err := h.f.db.QueryRow(`SELECT to_regclass('matching.community_group_covers') IS NOT NULL`).Scan(&ready); err != nil {
		t.Fatal(err)
	}
	if !ready {
		t.Skip("migration 121_group_cover_photos is not applied")
	}
	root := filepath.Join(t.TempDir(), "media")
	store, err := mediastore.NewLocal(config.LocalStorageConfig{Root: root, Layout: config.LocalLayoutKinds, PublicDirMode: 0o750, PublicFileMode: 0o640})
	if err != nil {
		t.Fatal(err)
	}
	mod := &stubCoverModerator{status: mediaModerationApproved}
	h.s.media = store
	h.s.mediaModerator = mod
	h.s.log = zap.NewNop()
	groups := &[]string{}
	db := h.f.db
	// Runs before the groups harness cleanup (LIFO).
	t.Cleanup(func() {
		for _, id := range *groups {
			_, _ = db.Exec(`DELETE FROM matching.blog_evidence_photos WHERE storage_path LIKE 'group_covers/'||$1||'/%'`, id)
			_, _ = db.Exec(`DELETE FROM matching.community_group_covers WHERE group_id=$1`, id)
		}
	})
	return coverHarness{groupsHarness: h, root: root, store: store, mod: mod, groups: groups}
}

func (h coverHarness) group(owner string, body map[string]any) string {
	h.t.Helper()
	id := toString(h.mustCreate(owner, body)["id"])
	*h.groups = append(*h.groups, id)
	return id
}

// coverJPEG is a w×h JPEG carrying an EXIF segment with marker in it.
func coverJPEG(t *testing.T, w, h int, marker string) []byte {
	t.Helper()
	img := image.NewRGBA(image.Rect(0, 0, w, h))
	for x := 0; x < w; x++ {
		for y := 0; y < h; y++ {
			img.Set(x, y, color.RGBA{uint8(x % 256), uint8(y % 256), 120, 255})
		}
	}
	var buf bytes.Buffer
	if err := jpeg.Encode(&buf, img, &jpeg.Options{Quality: 80}); err != nil {
		t.Fatal(err)
	}
	raw := buf.Bytes()
	payload := append([]byte("Exif\x00\x00"), []byte(marker)...)
	segment := []byte{0xFF, 0xE1, byte((len(payload) + 2) >> 8), byte((len(payload) + 2) & 0xff)}
	out := append([]byte{}, raw[:2]...)
	out = append(out, segment...)
	out = append(out, payload...)
	return append(out, raw[2:]...)
}

func (h coverHarness) upload(user, groupID string, img []byte, coverID string) (int, map[string]any) {
	h.t.Helper()
	var body bytes.Buffer
	mw := multipart.NewWriter(&body)
	if coverID != "" {
		_ = mw.WriteField("cover_id", coverID)
	}
	if img != nil {
		fw, _ := mw.CreateFormFile("image", "cover.jpg")
		_, _ = fw.Write(img)
	}
	_ = mw.Close()
	r := groupRequest(http.MethodPut, user, "", body.String(), map[string]string{"groupID": groupID})
	r.Header.Set("Content-Type", mw.FormDataContentType())
	rec := httptest.NewRecorder()
	h.s.groupCoverHandler(rec, r)
	out := map[string]any{}
	if err := json.Unmarshal(rec.Body.Bytes(), &out); err != nil {
		h.t.Fatalf("decode %d %s: %v", rec.Code, rec.Body.String(), err)
	}
	return rec.Code, out
}

func (h coverHarness) fetch(user, groupID, ifNoneMatch string) *httptest.ResponseRecorder {
	h.t.Helper()
	r := groupRequest(http.MethodGet, user, "", "", map[string]string{"groupID": groupID})
	if ifNoneMatch != "" {
		r.Header.Set("If-None-Match", ifNoneMatch)
	}
	rec := httptest.NewRecorder()
	h.s.groupCoverHandler(rec, r)
	return rec
}

func (h coverHarness) remove(user, groupID string) (int, map[string]any) {
	h.t.Helper()
	return h.call(h.s.groupCoverHandler, http.MethodDelete, user, "", "", map[string]string{"groupID": groupID})
}

func (h coverHarness) liveKey(groupID string) string {
	h.t.Helper()
	var key string
	err := h.f.db.QueryRow(`SELECT storage_path FROM matching.community_group_covers WHERE group_id=$1 AND deleted_at IS NULL`, groupID).Scan(&key)
	if err != nil {
		h.t.Fatalf("live cover of %s: %v", groupID, err)
	}
	return key
}

func (h coverHarness) exists(key string) bool {
	h.t.Helper()
	ok, err := h.store.Exists(context.Background(), key)
	if err != nil {
		h.t.Fatal(err)
	}
	return ok
}

func operatorRequest(method, body string, params map[string]string) *http.Request {
	r := groupRequest(method, "", "", body, params)
	ctx := context.WithValue(r.Context(), securityPrincipalContextKey{}, securityPrincipal{UserID: uuid.NewString(), Roles: map[string]bool{"moderator": true}})
	return r.WithContext(ctx)
}

func (h coverHarness) decide(coverID, decision string) (int, map[string]any) {
	h.t.Helper()
	rec := httptest.NewRecorder()
	h.s.adminGroupCoverDecisionHandler(rec, operatorRequest(http.MethodPost, `{"decision":"`+decision+`","reason":"Not a group photo"}`, map[string]string{"coverID": coverID}))
	out := map[string]any{}
	_ = json.Unmarshal(rec.Body.Bytes(), &out)
	return rec.Code, out
}

func TestGroupCoverUploadValidationAndPermissionsPostgres(t *testing.T) {
	h := newCoverHarness(t)
	f := h.f
	gid := h.group(f.proposer, map[string]any{"kind": "community", "category_slug": "books", "name": "Cover readers", "cover_emoji": "📚"})
	private := h.group(f.proposer, map[string]any{"kind": "private", "name": "Cover friends"})
	if code, _ := h.post(h.s.joinCommunityGroupHandler, f.groupMate, gid, `{}`); code != 200 {
		t.Fatalf("join code=%d", code)
	}
	if code := h.manage(f.proposer, gid, f.groupMate, "make_moderator"); code != 200 {
		t.Fatalf("promote code=%d", code)
	}
	good := coverJPEG(t, 640, 320, "GPS-SECRET-LOCATION")

	// Only the owner changes the cover: moderators get 403, non-members 404.
	if code, _ := h.upload(f.groupMate, gid, good, ""); code != http.StatusForbidden {
		t.Fatalf("moderator upload code=%d", code)
	}
	if code, _ := h.upload(f.stranger, gid, good, ""); code != http.StatusNotFound {
		t.Fatalf("non-member upload code=%d", code)
	}
	if code, _ := h.upload(f.stranger, private, good, ""); code != http.StatusNotFound {
		t.Fatalf("private non-member upload code=%d", code)
	}
	if code, _ := h.remove(f.groupMate, gid); code != http.StatusForbidden {
		t.Fatalf("moderator remove code=%d", code)
	}
	// Real image bytes only, within the size limits.
	for name, tc := range map[string]struct {
		img  []byte
		code int
	}{
		"missing":   {nil, http.StatusBadRequest},
		"not image": {[]byte("<svg onload=alert(1)>hello</svg>"), http.StatusUnsupportedMediaType},
		"too small": {coverJPEG(t, 120, 80, ""), http.StatusUnprocessableEntity},
		"too large": {append([]byte{0xff, 0xd8, 0xff}, bytes.Repeat([]byte{0}, groupCoverMaxBytes)...), http.StatusRequestEntityTooLarge},
	} {
		if code, out := h.upload(f.proposer, gid, tc.img, ""); code != tc.code {
			t.Fatalf("%s: code=%d want %d %v", name, code, tc.code, out)
		}
	}
	if code, _ := h.upload(f.proposer, gid, good, "not-a-uuid"); code != http.StatusBadRequest {
		t.Fatalf("bad cover id code=%d", code)
	}

	coverID := uuid.NewString()
	code, out := h.upload(f.proposer, gid, good, coverID)
	if code != 200 {
		t.Fatalf("owner upload code=%d %v", code, out)
	}
	g := out["group"].(map[string]any)
	if g["cover_photo_status"] != "approved" || g["cover_photo_id"] != coverID ||
		g["cover_photo_url"] != "/v1/engagement/groups/"+gid+"/cover?v="+coverID || g["cover_emoji"] != "📚" {
		t.Fatalf("group after upload %v", g)
	}
	key := h.liveKey(gid)
	if key != "group_covers/"+gid+"/"+coverID+".jpg" {
		t.Fatalf("storage key %s", key)
	}
	absolute, relative, err := h.store.LocalPath(key)
	if err != nil || !strings.HasPrefix(relative, "public/group_covers/") {
		t.Fatalf("local path %s %v", relative, err)
	}
	stored, err := os.ReadFile(absolute)
	if err != nil {
		t.Fatal(err)
	}
	// Metadata (EXIF, location) is stripped by re-encoding.
	if bytes.Contains(stored, []byte("GPS-SECRET-LOCATION")) || bytes.Contains(stored, []byte("Exif")) {
		t.Fatal("stored cover still carries EXIF metadata")
	}
	var width, height int
	var sha, mime string
	if err = f.db.QueryRow(`SELECT width_px,height_px,content_sha256,mime_type FROM matching.community_group_covers WHERE id=$1`, coverID).Scan(&width, &height, &sha, &mime); err != nil {
		t.Fatal(err)
	}
	if width != 640 || height != 320 || len(sha) != 64 || mime != "image/jpeg" {
		t.Fatalf("cover row %d×%d %s %s", width, height, sha, mime)
	}
	// Moderators and members see the photo but not the owner-only status.
	_, mate := h.detail(f.groupMate, gid)
	if mate["cover_photo_url"] == nil || mate["cover_photo_status"] != nil {
		t.Fatalf("moderator view %v", mate)
	}

	// A retried upload with the same cover_id returns the saved cover.
	code, out = h.upload(f.proposer, gid, good, coverID)
	if code != 200 || out["cover"].(map[string]any)["status"] != "approved" {
		t.Fatalf("retry code=%d %v", code, out)
	}
	var rows int
	if err = f.db.QueryRow(`SELECT COUNT(*) FROM matching.community_group_covers WHERE group_id=$1`, gid).Scan(&rows); err != nil {
		t.Fatal(err)
	}
	if rows != 1 {
		t.Fatalf("retry created %d rows", rows)
	}
	// Another group cannot reuse the id.
	if code, _ = h.upload(f.proposer, private, good, coverID); code != http.StatusConflict {
		t.Fatalf("cover id reused on another group code=%d", code)
	}

	// Ten uploads per group per day, rejections included.
	for i := 0; i < groupCoverUploadsPerDay-1; i++ {
		if _, err = f.db.Exec(`INSERT INTO matching.community_group_covers(id,group_id,moderation_status,deleted_at,delete_reason,storage_released_at) VALUES($1,$2,'rejected',NOW(),'rejected_seen',NOW())`, uuid.NewString(), gid); err != nil {
			t.Fatal(err)
		}
	}
	if code, _ = h.upload(f.proposer, gid, good, ""); code != http.StatusTooManyRequests {
		t.Fatalf("eleventh upload code=%d", code)
	}
}

func TestGroupCoverModerationVisibilityPostgres(t *testing.T) {
	h := newCoverHarness(t)
	f := h.f
	gid := h.group(f.proposer, map[string]any{"kind": "community", "category_slug": "music", "name": "Cover choir"})
	if code, _ := h.post(h.s.joinCommunityGroupHandler, f.groupMate, gid, `{}`); code != 200 {
		t.Fatalf("join code=%d", code)
	}
	img := coverJPEG(t, 800, 400, "")

	// The provider asks for a human review: pending, owner only.
	h.mod.status = mediaModerationReviewRequired
	pendingID := uuid.NewString()
	code, out := h.upload(f.proposer, gid, img, pendingID)
	if code != 200 || out["cover"].(map[string]any)["status"] != "pending" {
		t.Fatalf("pending upload code=%d %v", code, out)
	}
	_, owner := h.detail(f.proposer, gid)
	if owner["cover_photo_status"] != "pending" || owner["cover_photo_url"] == nil {
		t.Fatalf("owner view of pending cover %v", owner)
	}
	_, mate := h.detail(f.groupMate, gid)
	if mate["cover_photo_url"] != nil || mate["cover_photo_id"] != nil {
		t.Fatalf("member saw a pending cover %v", mate)
	}
	_, list := h.call(h.s.listCommunityGroups, http.MethodGet, f.stranger, "scope=discover&category=music", "", nil)
	for _, item := range list["groups"].([]any) {
		if m := item.(map[string]any); m["id"] == gid && m["cover_photo_url"] != nil {
			t.Fatal("discover showed a pending cover")
		}
	}
	if rec := h.fetch(f.groupMate, gid, ""); rec.Code != http.StatusNotFound {
		t.Fatalf("member fetched pending cover code=%d", rec.Code)
	}
	rec := h.fetch(f.proposer, gid, "")
	if rec.Code != 200 || rec.Header().Get("Cache-Control") != "private, no-store" || rec.Header().Get("Content-Type") != "image/jpeg" {
		t.Fatalf("owner fetch of pending cover code=%d headers=%v", rec.Code, rec.Header())
	}

	// The operator queue lists it; approval shows it to everyone.
	queue := httptest.NewRecorder()
	h.s.adminGroupCoversHandler(queue, operatorRequest(http.MethodGet, "", nil))
	if queue.Code != 200 || !strings.Contains(queue.Body.String(), pendingID) {
		t.Fatalf("queue code=%d %s", queue.Code, queue.Body.String())
	}
	content := httptest.NewRecorder()
	h.s.adminGroupCoverContentHandler(content, operatorRequest(http.MethodGet, "", map[string]string{"coverID": pendingID}))
	if content.Code != 200 || content.Header().Get("Cache-Control") != "private, no-store" || content.Body.Len() == 0 {
		t.Fatalf("operator content code=%d", content.Code)
	}
	member := httptest.NewRecorder()
	h.s.adminGroupCoversHandler(member, groupRequest(http.MethodGet, f.groupMate, "", "", nil))
	if member.Code != http.StatusForbidden {
		t.Fatalf("member read the operator queue code=%d", member.Code)
	}
	if code, out = h.decide(pendingID, "approved"); code != 200 || out["status"] != "approved" {
		t.Fatalf("approve code=%d %v", code, out)
	}
	if code, _ = h.decide(pendingID, "approved"); code != 200 {
		t.Fatalf("repeat approve code=%d", code)
	}
	if code, _ = h.decide(pendingID, "rejected"); code != http.StatusConflict {
		t.Fatalf("reject after approve code=%d", code)
	}
	_, mate = h.detail(f.groupMate, gid)
	if mate["cover_photo_id"] != pendingID {
		t.Fatalf("approved cover hidden from member %v", mate)
	}
	rec = h.fetch(f.stranger, gid, "")
	etag := rec.Header().Get("ETag")
	if rec.Code != 200 || rec.Header().Get("Cache-Control") != "private, max-age=300" || len(etag) != 66 ||
		rec.Header().Get("X-Content-Type-Options") != "nosniff" || rec.Body.Len() == 0 || rec.Header().Get("Content-Length") == "" {
		t.Fatalf("approved fetch code=%d headers=%v", rec.Code, rec.Header())
	}
	if rec = h.fetch(f.stranger, gid, etag); rec.Code != http.StatusNotModified || rec.Body.Len() != 0 {
		t.Fatalf("conditional fetch code=%d", rec.Code)
	}
	if rec = h.fetch(f.stranger, gid, `"other"`); rec.Code != 200 {
		t.Fatalf("stale etag fetch code=%d", rec.Code)
	}

	// A second pending cover keeps the approved one until it is decided; an
	// operator rejection hides it and tells the owner.
	approvedKey := h.liveKey(gid)
	rejectedID := uuid.NewString()
	if code, _ = h.upload(f.proposer, gid, coverJPEG(t, 900, 450, ""), rejectedID); code != 200 {
		t.Fatalf("second pending upload code=%d", code)
	}
	if h.exists(approvedKey) {
		t.Fatal("replaced cover object was not deleted")
	}
	pendingKey := h.liveKey(gid)
	if code, out = h.decide(rejectedID, "rejected"); code != 200 || out["status"] != "rejected" {
		t.Fatalf("reject code=%d %v", code, out)
	}
	if h.exists(pendingKey) {
		t.Fatal("rejected cover object was not deleted")
	}
	if got := f.notifications(t, f.proposer, "group.cover.rejected"); got != 1 {
		t.Fatalf("owner rejection notices=%d", got)
	}
	_, owner = h.detail(f.proposer, gid)
	if owner["cover_photo_status"] != "rejected" || owner["cover_photo_url"] != nil {
		t.Fatalf("owner view after rejection %v", owner)
	}
	// Removing clears the notice.
	if code, _ = h.remove(f.proposer, gid); code != 200 {
		t.Fatalf("remove code=%d", code)
	}
	_, owner = h.detail(f.proposer, gid)
	if owner["cover_photo_status"] != nil {
		t.Fatalf("rejection notice survived removal %v", owner)
	}

	// A synchronous rejection stores nothing and keeps the current cover.
	h.mod.status = mediaModerationApproved
	if code, _ = h.upload(f.proposer, gid, img, ""); code != 200 {
		t.Fatalf("approved upload code=%d", code)
	}
	current := h.liveKey(gid)
	h.mod.status = mediaModerationRejected
	refusedID := uuid.NewString()
	if code, _ = h.upload(f.proposer, gid, coverJPEG(t, 500, 500, ""), refusedID); code != http.StatusUnprocessableEntity {
		t.Fatalf("rejected upload code=%d", code)
	}
	if code, _ = h.upload(f.proposer, gid, coverJPEG(t, 500, 500, ""), refusedID); code != http.StatusUnprocessableEntity {
		t.Fatalf("retried rejected upload code=%d", code)
	}
	if h.liveKey(gid) != current || !h.exists(current) {
		t.Fatal("a rejected upload replaced the cover")
	}
	entries, _ := os.ReadDir(filepath.Join(h.root, "public", "group_covers", gid))
	if len(entries) != 1 {
		t.Fatalf("group cover directory holds %d files", len(entries))
	}
}

func TestGroupCoverPrivacyBlocksAndRemovalPostgres(t *testing.T) {
	h := newCoverHarness(t)
	f := h.f
	img := coverJPEG(t, 600, 300, "")
	private := h.group(f.proposer, map[string]any{"kind": "private", "name": "Hidden cover", "invitee_user_ids": []string{f.proposerFriend}})
	if code, _ := h.upload(f.proposer, private, img, ""); code != 200 {
		t.Fatalf("private upload code=%d", code)
	}
	// Private groups: 404 to non-members; an invitee sees the cover.
	if rec := h.fetch(f.stranger, private, ""); rec.Code != http.StatusNotFound {
		t.Fatalf("stranger fetched a private cover code=%d", rec.Code)
	}
	if rec := h.fetch(f.proposerFriend, private, ""); rec.Code != 200 {
		t.Fatalf("invitee fetch code=%d", rec.Code)
	}

	community := h.group(f.proposer, map[string]any{"kind": "community", "category_slug": "pets", "name": "Cover dogs"})
	if code, _ := h.upload(f.proposer, community, img, ""); code != 200 {
		t.Fatalf("community upload code=%d", code)
	}
	if rec := h.fetch(f.stranger, community, ""); rec.Code != 200 {
		t.Fatalf("stranger fetch of a community cover code=%d", rec.Code)
	}
	// The blocked friend (who blocked the owner) cannot see the group or its
	// cover; as a member they still see the group but not the owner's photo.
	if rec := h.fetch(f.blockedFriend, community, ""); rec.Code != http.StatusNotFound {
		t.Fatalf("blocked member fetched the cover code=%d", rec.Code)
	}
	if _, err := f.db.Exec(`INSERT INTO matching.community_group_members(group_id,user_id,status,role) VALUES($1,$2,'active','member')`, community, f.blockedFriend); err != nil {
		t.Fatal(err)
	}
	code, g := h.detail(f.blockedFriend, community)
	if code != 200 || g["cover_photo_url"] != nil {
		t.Fatalf("blocked member view code=%d %v", code, g)
	}
	if rec := h.fetch(f.blockedFriend, community, ""); rec.Code != http.StatusNotFound {
		t.Fatalf("blocked member fetched the cover code=%d", rec.Code)
	}

	// Removed after a review: no cover for anyone, no changes.
	if code, _ := h.post(h.s.joinCommunityGroupHandler, f.groupMate, community, `{}`); code != 200 {
		t.Fatalf("join code=%d", code)
	}
	if _, err := f.db.Exec(`UPDATE matching.community_groups SET moderation_state='removed' WHERE id=$1`, community); err != nil {
		t.Fatal(err)
	}
	_, g = h.detail(f.groupMate, community)
	if g["cover_photo_url"] != nil {
		t.Fatalf("member saw the cover of a removed group %v", g)
	}
	if rec := h.fetch(f.groupMate, community, ""); rec.Code != http.StatusNotFound {
		t.Fatalf("cover of a removed group served code=%d", rec.Code)
	}
	if rec := h.fetch(f.stranger, community, ""); rec.Code != http.StatusNotFound {
		t.Fatalf("stranger fetched a removed group's cover code=%d", rec.Code)
	}
	if code, _ := h.upload(f.proposer, community, img, ""); code != http.StatusForbidden {
		t.Fatalf("upload to a removed group code=%d", code)
	}
	if code, _ := h.remove(f.proposer, community); code != http.StatusForbidden {
		t.Fatalf("remove on a removed group code=%d", code)
	}
}

func TestGroupCoverStorageLifecyclePostgres(t *testing.T) {
	h := newCoverHarness(t)
	f := h.f
	ctx := context.Background()
	gid := h.group(f.proposer, map[string]any{"kind": "community", "category_slug": "travel", "name": "Cover trips"})
	if code, _ := h.upload(f.proposer, gid, coverJPEG(t, 600, 300, ""), ""); code != 200 {
		t.Fatal("upload")
	}
	first := h.liveKey(gid)

	// A report keeps the cover the reporter saw as evidence, even after the
	// owner replaces it.
	caseID, err := createBlogCase(ctx, f.db, f.stranger, "group", gid, "inappropriate", "")
	if err != nil {
		t.Fatal(err)
	}
	var evidence int
	if err = f.db.QueryRow(`SELECT COUNT(*) FROM matching.blog_evidence_photos WHERE case_id=$1 AND storage_path=$2`, caseID, first).Scan(&evidence); err != nil {
		t.Fatal(err)
	}
	var snapshot string
	if err = f.db.QueryRow(`SELECT snapshot::text FROM matching.blog_cases WHERE id=$1`, caseID).Scan(&snapshot); err != nil {
		t.Fatal(err)
	}
	if evidence != 1 || !strings.Contains(snapshot, "cover_photo_id") {
		t.Fatalf("evidence=%d snapshot=%s", evidence, snapshot)
	}
	if code, _ := h.upload(f.proposer, gid, coverJPEG(t, 700, 350, ""), ""); code != 200 {
		t.Fatal("replace")
	}
	second := h.liveKey(gid)
	if !h.exists(first) {
		t.Fatal("cover held as report evidence was deleted")
	}
	// Once the evidence is gone, the worker releases it.
	if _, err = f.db.Exec(`DELETE FROM matching.blog_evidence_photos WHERE case_id=$1`, caseID); err != nil {
		t.Fatal(err)
	}
	h.s.releaseGroupCoverMedia(ctx, "")
	if h.exists(first) {
		t.Fatal("released cover object still stored")
	}

	// Remove deletes the object; the group falls back to its emoji.
	code, out := h.remove(f.proposer, gid)
	if code != 200 || out["removed"] != true || out["group"].(map[string]any)["cover_photo_url"] != nil {
		t.Fatalf("remove code=%d %v", code, out)
	}
	if h.exists(second) {
		t.Fatal("removed cover object still stored")
	}
	if code, out = h.remove(f.proposer, gid); code != 200 || out["removed"] != false {
		t.Fatalf("repeat remove code=%d %v", code, out)
	}

	// Deleting the group deletes its cover.
	if code, _ := h.upload(f.proposer, gid, coverJPEG(t, 600, 300, ""), ""); code != 200 {
		t.Fatal("upload again")
	}
	third := h.liveKey(gid)
	if code, _ := h.call(h.s.communityGroupHandler, http.MethodDelete, f.proposer, "", "", map[string]string{"groupID": gid}); code != 200 {
		t.Fatalf("delete group code=%d", code)
	}
	if h.exists(third) {
		t.Fatal("deleted group's cover still stored")
	}
	var unreleased int
	if err = f.db.QueryRow(`SELECT COUNT(*) FROM matching.community_group_covers WHERE group_id=$1 AND storage_released_at IS NULL`, gid).Scan(&unreleased); err != nil {
		t.Fatal(err)
	}
	if unreleased != 0 {
		t.Fatalf("%d cover rows not released", unreleased)
	}

	// The orphan sweep never treats a live cover as unreferenced.
	keep := h.group(f.proposer, map[string]any{"kind": "private", "name": "Cover keepers"})
	if code, _ := h.upload(f.proposer, keep, coverJPEG(t, 600, 300, ""), ""); code != 200 {
		t.Fatal("upload keep")
	}
	refs, err := h.s.privateMediaReferences(ctx)
	if err != nil {
		t.Fatal(err)
	}
	if _, ok := refs[h.liveKey(keep)]; !ok {
		t.Fatal("live cover missing from the media reference set")
	}
}

func TestGroupCoverAccountErasurePostgres(t *testing.T) {
	h := newCoverHarness(t)
	f := h.f
	ctx := context.Background()
	shared := h.group(f.proposer, map[string]any{"kind": "community", "category_slug": "pets", "name": "Cover handoff"})
	if code, _ := h.post(h.s.joinCommunityGroupHandler, f.groupMate, shared, `{}`); code != 200 {
		t.Fatal("join")
	}
	alone := h.group(f.proposer, map[string]any{"kind": "private", "name": "Cover alone"})
	for _, id := range []string{shared, alone} {
		if code, _ := h.upload(f.proposer, id, coverJPEG(t, 600, 300, ""), ""); code != 200 {
			t.Fatal("upload")
		}
	}
	sharedKey, aloneKey := h.liveKey(shared), h.liveKey(alone)
	tx, err := f.db.BeginTx(ctx, nil)
	if err != nil {
		t.Fatal(err)
	}
	for _, step := range accountErasureSteps() {
		if !strings.HasPrefix(step.label, "group") {
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
	// The handed-over group falls back to its emoji; nothing names the
	// erased member; the worker releases both objects.
	_, g := h.detail(f.groupMate, shared)
	if g["cover_photo_url"] != nil || h.owner(shared) != f.groupMate {
		t.Fatalf("handed-over group %v", g)
	}
	var named int
	if err = f.db.QueryRow(`SELECT COUNT(*) FROM matching.community_group_covers WHERE uploaded_by=$1`, f.proposer).Scan(&named); err != nil {
		t.Fatal(err)
	}
	if named != 0 {
		t.Fatalf("%d cover rows still name the erased member", named)
	}
	h.s.releaseGroupCoverMedia(ctx, "")
	if h.exists(sharedKey) || h.exists(aloneKey) {
		t.Fatal("erased member's covers still stored")
	}
}

func TestGroupCoverUploadSkipsReplayLedger(t *testing.T) {
	s := newContractTestServer(t)
	id := uuid.NewString()
	put := httptest.NewRequest(http.MethodPut, "/v1/engagement/groups/"+id+"/cover", nil)
	del := httptest.NewRequest(http.MethodDelete, "/v1/engagement/groups/"+id+"/cover", nil)
	patch := httptest.NewRequest(http.MethodPatch, "/v1/engagement/groups/"+id, nil)
	if s.shouldApplyIdempotency(put) {
		t.Fatal("multipart cover uploads must not be buffered in the replay ledger")
	}
	if !s.shouldApplyIdempotency(del) || !s.shouldApplyIdempotency(patch) {
		t.Fatal("removing the cover and editing the group keep replay protection")
	}
	// The route is registered for all three methods.
	routes := registeredAPIRoutes(t, s)
	methods := strings.Join(routes["/v1/engagement/groups/{}/cover"], ",")
	for _, m := range []string{"GET", "PUT", "DELETE"} {
		if !strings.Contains(methods, m) {
			t.Fatalf("cover route methods %s", methods)
		}
	}
}

// The member export lists the covers a member uploaded as metadata only.
func TestGroupCoverExportSectionIsMetadataOnly(t *testing.T) {
	var query string
	for _, section := range accountExportSections() {
		if section.name == "group_covers_uploaded" {
			query = strings.ToLower(section.query)
		}
	}
	if query == "" {
		t.Fatal("account export has no group_covers_uploaded section")
	}
	for _, forbidden := range []string{"storage_path", "content_sha256", "reviewed_by", "moderation_reason"} {
		if strings.Contains(query, forbidden) {
			t.Errorf("group cover export must not read %q", forbidden)
		}
	}
}

func TestGroupCoverAccountExportPostgres(t *testing.T) {
	h := newCoverHarness(t)
	f := h.f
	gid := h.group(f.proposer, map[string]any{"kind": "private", "name": "Cover export"})
	for i := 0; i < 2; i++ { // the second upload replaces the first
		if code, out := h.upload(f.proposer, gid, coverJPEG(t, 600, 300, ""), ""); code != 200 {
			t.Fatalf("upload %d: %v", code, out)
		}
	}
	repo := &profileRepository{pg: f.db}
	export, err := repo.buildAccountExport(context.Background(), f.proposer, f.proposer)
	if err != nil {
		t.Fatal(err)
	}
	raw, _ := json.Marshal(export["group_covers_uploaded"])
	if strings.Contains(string(raw), "group_covers/") {
		t.Fatalf("export leaks a storage key: %s", raw)
	}
	var mine []map[string]any
	for _, item := range export["group_covers_uploaded"].([]any) {
		if row := item.(map[string]any); row["group_id"] == gid {
			mine = append(mine, row)
		}
	}
	if len(mine) != 2 {
		t.Fatalf("want 2 uploaded covers for the group, got %s", raw)
	}
	for _, key := range []string{"cover_id", "status", "uploaded_at", "mime_type", "size_bytes", "removed_at"} {
		if _, ok := mine[0][key]; !ok {
			t.Fatalf("export row missing %q: %v", key, mine[0])
		}
	}
	if mine[0]["removed_at"] == nil || mine[1]["removed_at"] != nil || mine[1]["status"] != "approved" || mine[1]["mime_type"] != "image/jpeg" {
		t.Fatalf("replaced then current cover expected: %s", raw)
	}
	if size, _ := mine[1]["size_bytes"].(float64); size <= 0 {
		t.Fatalf("size_bytes missing: %v", mine[1])
	}
	// Another member's export does not list them.
	other, err := repo.buildAccountExport(context.Background(), f.groupMate, f.groupMate)
	if err != nil {
		t.Fatal(err)
	}
	if otherRaw, _ := json.Marshal(other["group_covers_uploaded"]); strings.Contains(string(otherRaw), gid) {
		t.Fatalf("other member's export lists these covers: %s", otherRaw)
	}
}
