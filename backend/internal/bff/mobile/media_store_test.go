package mobile

import (
	"bytes"
	"context"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"

	"go.uber.org/zap"

	"github.com/verified-dating/backend/internal/platform/config"
)

func newKindsMediaServer(t *testing.T, accelPrefix string) *Server {
	t.Helper()
	cfg := config.Config{
		APIPrefix: "/v1",
		MediaStorage: config.MediaStorageConfig{
			Backend: config.StorageBackendLocalFS,
			Local: config.LocalStorageConfig{
				Root:                filepath.Join(t.TempDir(), "media"),
				Layout:              config.LocalLayoutKinds,
				PublicDirMode:       0o750,
				PublicFileMode:      0o640,
				AccelRedirectPrefix: accelPrefix,
			},
		},
	}
	s := &Server{cfg: cfg, log: zap.NewNop()}
	if err := s.initMediaStore(context.Background()); err != nil {
		t.Fatalf("initMediaStore: %v", err)
	}
	return s
}

func TestStoreMediaWritesEveryKindThroughTheStore(t *testing.T) {
	s := newKindsMediaServer(t, "")
	ctx := context.Background()
	root := s.cfg.MediaStorage.Local.Root
	cases := map[string][2]string{
		"approved/u1":                {"p.png", "public/profile_photos/u1/p.png"},
		"private/voice/u1/i1":        {"v.webm", "private/voice/u1/i1/v.webm"},
		"private/verification/u1/id": {"d.png", "private/verification/u1/id/d.png"},
		"private/blog/u1/p1":         {"c.jpg", "private/chapter_photos/u1/p1/c.jpg"},
		"private/themes/u1/t1":       {"t.jpg", "private/theme_photos/u1/t1/t.jpg"},
	}
	for namespace, item := range cases {
		key, err := s.storeMedia(ctx, namespace, item[0], "", []byte("x"))
		if err != nil || key != namespace+"/"+item[0] {
			t.Fatalf("storeMedia(%s) = %q %v", namespace, key, err)
		}
		if _, err := os.Stat(filepath.Join(root, filepath.FromSlash(item[1]))); err != nil {
			t.Fatalf("expected %s: %v", item[1], err)
		}
		var buf bytes.Buffer
		if err := s.copyPrivateMedia(ctx, &buf, key); err != nil || buf.String() != "x" {
			t.Fatalf("copyPrivateMedia(%s) = %q %v", key, buf.String(), err)
		}
		if err := s.deleteStoredMedia(key); err != nil {
			t.Fatalf("deleteStoredMedia(%s): %v", key, err)
		}
	}
	if _, err := s.storeMedia(ctx, "private/voice/../../etc", "x", "", []byte("x")); err == nil {
		t.Fatalf("storeMedia accepted a traversal namespace")
	}
	if err := s.deleteStoredMedia("../../etc/passwd"); err == nil {
		t.Fatalf("deleteStoredMedia accepted a traversal path")
	}
}

func TestServeStoredMediaUsesAccelRedirectOnlyForPublicFiles(t *testing.T) {
	s := newKindsMediaServer(t, "/_connect_media/")
	ctx := context.Background()
	if _, err := s.storeMedia(ctx, "approved/u1", "p.png", "image/png", []byte("public-bytes")); err != nil {
		t.Fatal(err)
	}
	if _, err := s.storeMedia(ctx, "quarantine/u1", "q.png", "image/png", []byte("quarantine-bytes")); err != nil {
		t.Fatal(err)
	}
	recorder := httptest.NewRecorder()
	s.serveStoredMedia(recorder, httptest.NewRequest(http.MethodGet, "/v1/media/approved/u1/p.png", nil),
		mediaAccessRecord{PhotoID: "p", StoragePath: "approved/u1/p.png", MimeType: "image/png"})
	if got := recorder.Header().Get("X-Accel-Redirect"); got != "/_connect_media/public/profile_photos/u1/p.png" {
		t.Fatalf("X-Accel-Redirect = %q", got)
	}
	if recorder.Body.Len() != 0 || recorder.Header().Get("Cache-Control") != "private, max-age=300" {
		t.Fatalf("accel response body=%q cache=%q", recorder.Body.String(), recorder.Header().Get("Cache-Control"))
	}
	recorder = httptest.NewRecorder()
	s.serveStoredMedia(recorder, httptest.NewRequest(http.MethodGet, "/admin", nil),
		mediaAccessRecord{PhotoID: "q", StoragePath: "quarantine/u1/q.png", MimeType: "image/png"})
	if recorder.Header().Get("X-Accel-Redirect") != "" || recorder.Body.String() != "quarantine-bytes" {
		t.Fatalf("quarantined media must be streamed by the API: %v %q", recorder.Header(), recorder.Body.String())
	}
	if recorder.Header().Get("Cache-Control") != "private, no-store" || recorder.Header().Get("Content-Type") != "image/png" {
		t.Fatalf("quarantine headers = %v", recorder.Header())
	}
}

func TestServeStoredMediaStreamsWithoutAccel(t *testing.T) {
	s := newKindsMediaServer(t, "")
	if _, err := s.storeMedia(context.Background(), "approved/u1", "p.png", "image/png", []byte("public-bytes")); err != nil {
		t.Fatal(err)
	}
	recorder := httptest.NewRecorder()
	s.serveStoredMedia(recorder, httptest.NewRequest(http.MethodGet, "/v1/media/approved/u1/p.png", nil),
		mediaAccessRecord{StoragePath: "approved/u1/p.png", MimeType: "image/png"})
	if recorder.Code != http.StatusOK || recorder.Body.String() != "public-bytes" || recorder.Header().Get("Content-Type") != "image/png" {
		t.Fatalf("stream = %d %q %v", recorder.Code, recorder.Body.String(), recorder.Header())
	}
	recorder = httptest.NewRecorder()
	s.serveStoredMedia(recorder, httptest.NewRequest(http.MethodGet, "/", nil), mediaAccessRecord{StoragePath: "approved/u1/missing.png"})
	if recorder.Code != http.StatusNotFound {
		t.Fatalf("missing media = %d", recorder.Code)
	}
}

func TestZeroConfigServerKeepsFlatUploadsDir(t *testing.T) {
	dir := t.TempDir()
	s := &Server{cfg: config.Config{MediaUploadsDir: dir}, log: zap.NewNop()}
	key, err := s.storeMedia(context.Background(), "private/blog/u1/p1", "c.jpg", "image/jpeg", []byte("chapter"))
	if err != nil {
		t.Fatal(err)
	}
	if b, err := os.ReadFile(filepath.Join(dir, key)); err != nil || string(b) != "chapter" {
		t.Fatalf("flat layout write = %q %v", b, err)
	}
}

func TestLegacyS3KeysKeepTheirMediaURLs(t *testing.T) {
	s := &Server{cfg: config.Config{
		APIPrefix:          "/v1",
		MediaPublicBaseURL: "https://api.example.test",
		MediaStorage: config.MediaStorageConfig{
			Backend: config.StorageBackendAWSS3,
			S3:      config.S3StorageConfig{Bucket: "b", LegacyPrefix: "profile-photos"},
		},
	}}
	request := httptest.NewRequest(http.MethodGet, "/", nil)
	if got := s.mediaURLForStoragePath(request, "profile-photos/approved/u1/p.png"); got != "https://api.example.test/v1/media/approved/u1/p.png" {
		t.Fatalf("legacy URL = %s", got)
	}
	if got := s.mediaURLForStoragePath(request, "approved/u1/p.png"); got != "https://api.example.test/v1/media/approved/u1/p.png" {
		t.Fatalf("new URL = %s", got)
	}
	keys := s.profileMediaStorageKeys("approved/u1/p.png")
	if len(keys) != 2 || keys[0] != "approved/u1/p.png" || keys[1] != "profile-photos/approved/u1/p.png" {
		t.Fatalf("lookup keys = %v", keys)
	}
}
