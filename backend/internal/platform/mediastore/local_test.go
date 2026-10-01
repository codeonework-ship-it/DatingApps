package mediastore

import (
	"bytes"
	"context"
	"errors"
	"io"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"testing"
	"time"

	"github.com/verified-dating/backend/internal/platform/config"
)

func newKindsStore(t *testing.T, legacy string) *LocalStore {
	t.Helper()
	root := filepath.Join(t.TempDir(), "media")
	store, err := NewLocal(config.LocalStorageConfig{
		Root:             root,
		Layout:           config.LocalLayoutKinds,
		LegacyUploadsDir: legacy,
		MinFreeBytes:     1 << 20,
		PublicDirMode:    0o750,
		PublicFileMode:   0o640,
	})
	if err != nil {
		t.Fatalf("NewLocal: %v", err)
	}
	store.freeSpace = func(string) (uint64, error) { return 10 << 30, nil }
	return store
}

func readKey(t *testing.T, store Store, key string) string {
	t.Helper()
	object, err := store.Open(context.Background(), key)
	if err != nil {
		t.Fatalf("Open(%s): %v", key, err)
	}
	defer object.Body.Close()
	body, err := io.ReadAll(object.Body)
	if err != nil {
		t.Fatalf("read %s: %v", key, err)
	}
	return string(body)
}

func TestCleanKeyAndClassifyRejectTraversal(t *testing.T) {
	bad := []string{
		"", "/approved/u/p.png", "../etc/passwd", "approved/../../etc/passwd", "approved/./p.png",
		"approved/.hidden", "approved//p.png", `approved\u\p.png`, "approved/u/p png", "private/unknown/x.png",
		"public/profile_photos/x.png", "tmp/x", "approved", "approved/", "quarantine",
	}
	for _, key := range bad {
		if _, _, err := Classify(key); err == nil {
			t.Errorf("Classify(%q) accepted an invalid key", key)
		}
	}
	cases := map[string]Kind{
		"approved/u1/p.png":                    KindProfilePhoto,
		"quarantine/u1/p.png":                  KindProfilePhotoQuarantine,
		"private/verification/u1/selfie/a.png": KindVerification,
		"private/voice/u1/i1/a.webm":           KindVoice,
		"private/blog/u1/post/a.jpg":           KindChapterPhoto,
		"private/themes/u1/theme/a.jpg":        KindThemePhoto,
		"group_covers/g1/a.jpg":                KindGroupCover,
		"u1/p.png":                             KindLegacyProfilePhoto,
		"seed/picsum/2":                        KindLegacyProfilePhoto,
	}
	for key, want := range cases {
		spec, _, err := Classify(key)
		if err != nil || spec.Kind != want {
			t.Errorf("Classify(%q) = %v, %v; want %v", key, spec.Kind, err, want)
		}
	}
}

func TestKeyRejectsUnsafeSegments(t *testing.T) {
	if key, err := Key(KindVoice, "user-1", "ice_1", "a.webm"); err != nil || key != "private/voice/user-1/ice_1/a.webm" {
		t.Fatalf("Key = %q, %v", key, err)
	}
	for _, segments := range [][]string{{"..", "x"}, {"a/b"}, {".hidden"}, {""}, {}} {
		if _, err := Key(KindVoice, segments...); err == nil {
			t.Errorf("Key(%q) accepted unsafe segments", segments)
		}
	}
	if _, err := Key(KindLegacyProfilePhoto, "u", "p.png"); err == nil {
		t.Errorf("legacy kind must not mint new keys")
	}
}

func TestLocalKindsLayoutPutOpenDelete(t *testing.T) {
	store := newKindsStore(t, "")
	ctx := context.Background()
	if _, err := store.SelfCheck(); err != nil {
		t.Fatalf("SelfCheck: %v", err)
	}
	cases := map[string]string{
		"approved/u1/p.png":                    "public/profile_photos/u1/p.png",
		"quarantine/u1/q.png":                  "quarantine/profile_photos/u1/q.png",
		"private/blog/u1/post/c.jpg":           "private/chapter_photos/u1/post/c.jpg",
		"private/themes/u1/theme/t.jpg":        "private/theme_photos/u1/theme/t.jpg",
		"private/voice/u1/ice/v.webm":          "private/voice/u1/ice/v.webm",
		"private/verification/u1/selfie/s.png": "private/verification/u1/selfie/s.png",
		"group_covers/g1/cover.jpg":            "public/group_covers/g1/cover.jpg",
		"legacyuser/old.png":                   "public/legacy_profile_photos/legacyuser/old.png",
	}
	for key, rel := range cases {
		if err := store.Put(ctx, key, []byte("bytes:"+key), PutOptions{}); err != nil {
			t.Fatalf("Put(%s): %v", key, err)
		}
		absolute := filepath.Join(store.Root(), filepath.FromSlash(rel))
		info, err := os.Stat(absolute)
		if err != nil {
			t.Fatalf("expected %s on disk: %v", absolute, err)
		}
		spec, _, _ := Classify(key)
		wantFile, wantDir := os.FileMode(0o600), os.FileMode(0o700)
		if spec.Visibility == VisibilityPublic {
			wantFile, wantDir = 0o640, 0o750
		}
		if info.Mode().Perm() != wantFile {
			t.Errorf("%s file mode %#o, want %#o", key, info.Mode().Perm(), wantFile)
		}
		dirInfo, _ := os.Stat(filepath.Dir(absolute))
		if dirInfo.Mode().Perm() != wantDir {
			t.Errorf("%s dir mode %#o, want %#o", key, dirInfo.Mode().Perm(), wantDir)
		}
		if got := readKey(t, store, key); got != "bytes:"+key {
			t.Errorf("Open(%s) = %q", key, got)
		}
		gotAbs, gotRel, err := store.LocalPath(key)
		if err != nil || gotAbs != absolute || gotRel != rel {
			t.Errorf("LocalPath(%s) = %s, %s, %v", key, gotAbs, gotRel, err)
		}
	}
	var walked []string
	if err := store.Walk(ctx, func(info ObjectInfo) error { walked = append(walked, info.Key); return nil }); err != nil {
		t.Fatalf("Walk: %v", err)
	}
	sort.Strings(walked)
	var want []string
	for key := range cases {
		want = append(want, key)
	}
	sort.Strings(want)
	if strings.Join(walked, ",") != strings.Join(want, ",") {
		t.Fatalf("Walk keys = %v, want %v", walked, want)
	}
	for key := range cases {
		if err := store.Delete(ctx, key); err != nil {
			t.Fatalf("Delete(%s): %v", key, err)
		}
		if exists, err := store.Exists(ctx, key); err != nil || exists {
			t.Fatalf("Exists(%s) after delete = %v, %v", key, exists, err)
		}
	}
	if err := store.Delete(ctx, "approved/u1/missing.png"); err != nil {
		t.Fatalf("deleting a missing object must succeed: %v", err)
	}
	if _, err := store.Open(ctx, "approved/u1/missing.png"); !errors.Is(err, ErrNotFound) {
		t.Fatalf("Open(missing) = %v, want ErrNotFound", err)
	}
}

func TestLocalPutIsAtomicAndCleansTemp(t *testing.T) {
	store := newKindsStore(t, "")
	ctx := context.Background()
	key := "approved/u1/p.png"
	if err := store.Put(ctx, key, []byte("first"), PutOptions{}); err != nil {
		t.Fatal(err)
	}
	if err := store.Put(ctx, key, []byte("second"), PutOptions{}); err != nil {
		t.Fatal(err)
	}
	if got := readKey(t, store, key); got != "second" {
		t.Fatalf("replace = %q", got)
	}
	entries, _ := os.ReadDir(filepath.Join(store.Root(), "tmp"))
	if len(entries) != 0 {
		t.Fatalf("tmp/ should be empty after successful puts, found %d entries", len(entries))
	}
	// A failed publish (destination directory not writable) leaves neither a
	// partial destination file nor a temp file behind.
	if os.Geteuid() == 0 {
		t.Skip("running as root: permission failure cannot be simulated")
	}
	lockedDir := filepath.Join(store.Root(), "private", "voice", "u2")
	if err := os.MkdirAll(lockedDir, 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.Chmod(lockedDir, 0o500); err != nil {
		t.Fatal(err)
	}
	defer os.Chmod(lockedDir, 0o700)
	if err := store.Put(ctx, "private/voice/u2/v.webm", []byte("voice"), PutOptions{}); err == nil {
		t.Fatalf("expected failure writing into a read-only directory")
	}
	if _, err := os.Stat(filepath.Join(lockedDir, "v.webm")); !os.IsNotExist(err) {
		t.Fatalf("partial destination file exists: %v", err)
	}
	entries, _ = os.ReadDir(filepath.Join(store.Root(), "tmp"))
	if len(entries) != 0 {
		t.Fatalf("temp file left behind after failed put")
	}
}

func TestLocalRefusesUploadsWhenDiskIsFull(t *testing.T) {
	store := newKindsStore(t, "")
	store.freeSpace = func(string) (uint64, error) { return 512 << 10, nil }
	err := store.Put(context.Background(), "approved/u1/p.png", []byte("x"), PutOptions{})
	if !errors.Is(err, ErrInsufficientSpace) {
		t.Fatalf("Put = %v, want ErrInsufficientSpace", err)
	}
}

func TestLocalRejectsTraversalAndSymlinks(t *testing.T) {
	store := newKindsStore(t, "")
	ctx := context.Background()
	for _, key := range []string{"../escape.png", "approved/../../escape.png", "private/../../../etc/passwd", "/etc/passwd"} {
		if err := store.Put(ctx, key, []byte("x"), PutOptions{}); !errors.Is(err, ErrInvalidKey) {
			t.Errorf("Put(%q) = %v, want ErrInvalidKey", key, err)
		}
		if _, err := store.Open(ctx, key); !errors.Is(err, ErrInvalidKey) {
			t.Errorf("Open(%q) = %v, want ErrInvalidKey", key, err)
		}
		if err := store.Delete(ctx, key); !errors.Is(err, ErrInvalidKey) {
			t.Errorf("Delete(%q) = %v, want ErrInvalidKey", key, err)
		}
	}
	secret := filepath.Join(t.TempDir(), "secret.txt")
	if err := os.WriteFile(secret, []byte("secret"), 0o600); err != nil {
		t.Fatal(err)
	}
	linkDir := filepath.Join(store.Root(), "public", "profile_photos", "u1")
	if err := os.MkdirAll(linkDir, 0o750); err != nil {
		t.Fatal(err)
	}
	if err := os.Symlink(secret, filepath.Join(linkDir, "link.png")); err != nil {
		t.Fatal(err)
	}
	if _, err := store.Open(ctx, "approved/u1/link.png"); err == nil {
		t.Fatalf("Open followed a symlink out of the media root")
	}
	if _, _, err := store.LocalPath("approved/u1/link.png"); err == nil {
		t.Fatalf("LocalPath resolved a symlink")
	}
}

func TestLocalLegacyDirectoryFallback(t *testing.T) {
	legacy := filepath.Join(t.TempDir(), "uploads", "profile_photos")
	store := newKindsStore(t, legacy)
	ctx := context.Background()
	old := filepath.Join(legacy, "approved", "u1", "old.png")
	oldVoice := filepath.Join(legacy, "private", "voice", "u1", "i1", "old.webm")
	for path, body := range map[string]string{old: "old-photo", oldVoice: "old-voice"} {
		if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(path, []byte(body), 0o600); err != nil {
			t.Fatal(err)
		}
	}
	if got := readKey(t, store, "approved/u1/old.png"); got != "old-photo" {
		t.Fatalf("legacy read = %q", got)
	}
	if got := readKey(t, store, "private/voice/u1/i1/old.webm"); got != "old-voice" {
		t.Fatalf("legacy voice read = %q", got)
	}
	absolute, relative, err := store.LocalPath("approved/u1/old.png")
	if err != nil || absolute != old || relative != "" {
		t.Fatalf("LocalPath legacy = %s %q %v (relative must be empty: not servable by nginx)", absolute, relative, err)
	}
	var walked []string
	_ = store.Walk(ctx, func(info ObjectInfo) error { walked = append(walked, info.Key); return nil })
	sort.Strings(walked)
	if strings.Join(walked, ",") != "approved/u1/old.png,private/voice/u1/i1/old.webm" {
		t.Fatalf("Walk legacy = %v", walked)
	}
	if err := store.Delete(ctx, "approved/u1/old.png"); err != nil {
		t.Fatal(err)
	}
	if _, err := os.Stat(old); !os.IsNotExist(err) {
		t.Fatalf("legacy copy not deleted")
	}
	if _, err := NewLocal(config.LocalStorageConfig{Root: legacy, Layout: config.LocalLayoutKinds, LegacyUploadsDir: filepath.Dir(legacy)}); err == nil {
		t.Fatalf("overlapping legacy and root directories must be refused")
	}
}

func TestLocalFlatLayoutKeepsHistoricalPaths(t *testing.T) {
	root := filepath.Join(t.TempDir(), ".run", "uploads", "profile_photos")
	store, err := NewLocal(config.LocalStorageConfig{LegacyUploadsDir: root})
	if err != nil {
		t.Fatal(err)
	}
	if store.Layout() != config.LocalLayoutFlat {
		t.Fatalf("layout = %s", store.Layout())
	}
	ctx := context.Background()
	if err := store.Put(ctx, "private/blog/u1/p1/c.jpg", []byte("chapter"), PutOptions{}); err != nil {
		t.Fatal(err)
	}
	if b, err := os.ReadFile(filepath.Join(root, "private", "blog", "u1", "p1", "c.jpg")); err != nil || string(b) != "chapter" {
		t.Fatalf("flat layout path: %q %v", b, err)
	}
	if _, err := store.SelfCheck(); err != nil {
		t.Fatalf("SelfCheck flat: %v", err)
	}
	var walked []string
	_ = store.Walk(ctx, func(info ObjectInfo) error { walked = append(walked, info.Key); return nil })
	if len(walked) != 1 || walked[0] != "private/blog/u1/p1/c.jpg" {
		t.Fatalf("Walk flat = %v", walked)
	}
}

func TestLocalSelfCheckCreatesLayoutAndTightensPrivate(t *testing.T) {
	store := newKindsStore(t, "")
	if _, err := store.SelfCheck(); err != nil {
		t.Fatal(err)
	}
	for _, spec := range Specs {
		info, err := os.Stat(filepath.Join(store.Root(), filepath.FromSlash(spec.LocalDir)))
		if err != nil || !info.IsDir() {
			t.Fatalf("missing %s: %v", spec.LocalDir, err)
		}
	}
	for _, dir := range []string{"tmp", "private", "quarantine", "public"} {
		if _, err := os.Stat(filepath.Join(store.Root(), dir)); err != nil {
			t.Fatalf("missing %s", dir)
		}
	}
	voice := filepath.Join(store.Root(), "private", "voice")
	if err := os.Chmod(voice, 0o755); err != nil {
		t.Fatal(err)
	}
	warnings, err := store.SelfCheck()
	if err != nil {
		t.Fatal(err)
	}
	info, _ := os.Stat(voice)
	if info.Mode().Perm() != 0o700 || len(warnings) == 0 {
		t.Fatalf("private dir not tightened: %#o warnings=%v", info.Mode().Perm(), warnings)
	}
	if os.Geteuid() == 0 {
		return
	}
	if err := os.Chmod(filepath.Join(store.Root(), "tmp"), 0o500); err != nil {
		t.Fatal(err)
	}
	defer os.Chmod(filepath.Join(store.Root(), "tmp"), 0o700)
	if _, err := store.SelfCheck(); err == nil || !strings.Contains(err.Error(), "not writable") {
		t.Fatalf("SelfCheck on read-only tmp = %v", err)
	}
}

func TestLocalSweepTempRemovesStaleUploads(t *testing.T) {
	store := newKindsStore(t, "")
	if _, err := store.SelfCheck(); err != nil {
		t.Fatal(err)
	}
	stale := filepath.Join(store.Root(), "tmp", ".upload-stale")
	fresh := filepath.Join(store.Root(), "tmp", ".upload-fresh")
	for _, f := range []string{stale, fresh} {
		if err := os.WriteFile(f, []byte("x"), 0o600); err != nil {
			t.Fatal(err)
		}
	}
	old := time.Now().Add(-2 * time.Hour)
	_ = os.Chtimes(stale, old, old)
	if removed := store.SweepTemp(time.Hour); removed != 1 {
		t.Fatalf("SweepTemp removed %d", removed)
	}
	if _, err := os.Stat(fresh); err != nil {
		t.Fatalf("fresh temp removed")
	}
}

func TestProbeAndCopyBetweenLocalStores(t *testing.T) {
	legacyDir := filepath.Join(t.TempDir(), "legacy")
	legacy, err := NewLocal(config.LocalStorageConfig{LegacyUploadsDir: legacyDir})
	if err != nil {
		t.Fatal(err)
	}
	ctx := context.Background()
	files := map[string][]byte{
		"approved/u1/a.png":              bytes.Repeat([]byte("a"), 10),
		"private/voice/u1/i1/v.webm":     []byte("voice"),
		"private/verification/u1/id.png": []byte("id"),
	}
	for key, body := range files {
		if err := legacy.Put(ctx, key, body, PutOptions{}); err != nil {
			t.Fatal(err)
		}
	}
	destination := newKindsStore(t, "")
	if err := Probe(ctx, destination); err != nil {
		t.Fatalf("Probe: %v", err)
	}
	report, err := Copy(ctx, legacy, destination, CopyOptions{})
	if err != nil || report.WouldCopy != 3 || report.Copied != 0 {
		t.Fatalf("dry run = %+v %v", report, err)
	}
	if exists, _ := destination.Exists(ctx, "approved/u1/a.png"); exists {
		t.Fatalf("dry run wrote data")
	}
	report, err = Copy(ctx, legacy, destination, CopyOptions{Apply: true, Verify: "download"})
	if err != nil || report.Copied != 3 || report.Failed != 0 {
		t.Fatalf("apply = %+v %v", report, err)
	}
	report, err = Copy(ctx, legacy, destination, CopyOptions{Apply: true})
	if err != nil || report.Identical != 3 || report.Copied != 0 {
		t.Fatalf("rerun must be idempotent: %+v %v", report, err)
	}
	if err := destination.Put(ctx, "approved/u1/a.png", []byte("changed"), PutOptions{}); err != nil {
		t.Fatal(err)
	}
	report, _ = Copy(ctx, legacy, destination, CopyOptions{Apply: true, Kinds: []Kind{KindProfilePhoto}})
	if report.Conflicts != 1 || report.Scanned != 1 {
		t.Fatalf("conflict detection / kind filter = %+v", report)
	}
}
