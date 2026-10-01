package mediastore

import (
	"context"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"errors"
	"io"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"strconv"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/s3"

	"github.com/verified-dating/backend/internal/platform/config"
)

// fakeS3 is a minimal path-style S3 endpoint: PUT/GET/HEAD/DELETE object.
type fakeS3 struct {
	mu       sync.Mutex
	objects  map[string]fakeObject
	requests []string
}

type fakeObject struct {
	body    []byte
	headers http.Header
}

func newFakeS3(t *testing.T) (*fakeS3, *httptest.Server) {
	fake := &fakeS3{objects: map[string]fakeObject{}}
	server := httptest.NewServer(http.HandlerFunc(fake.serve))
	t.Cleanup(server.Close)
	return fake, server
}

func (f *fakeS3) serve(w http.ResponseWriter, r *http.Request) {
	f.mu.Lock()
	defer f.mu.Unlock()
	if !strings.HasPrefix(r.Header.Get("Authorization"), "AWS4-HMAC-SHA256 ") {
		w.WriteHeader(http.StatusForbidden)
		return
	}
	path := strings.TrimPrefix(r.URL.Path, "/")
	f.requests = append(f.requests, r.Method+" "+path)
	switch r.Method {
	case http.MethodPut:
		body, _ := io.ReadAll(r.Body)
		if want := r.Header.Get("X-Amz-Checksum-Sha256"); want != "" {
			sum := sha256.Sum256(body)
			if base64.StdEncoding.EncodeToString(sum[:]) != want {
				w.WriteHeader(http.StatusBadRequest)
				_, _ = io.WriteString(w, `<Error><Code>BadDigest</Code></Error>`)
				return
			}
		}
		headers := http.Header{}
		for key, values := range r.Header {
			lower := strings.ToLower(key)
			if strings.HasPrefix(lower, "x-amz-meta-") || strings.HasPrefix(lower, "x-amz-server-side-encryption") ||
				lower == "content-type" || lower == "cache-control" || lower == "x-amz-checksum-sha256" {
				headers[key] = values
			}
		}
		f.objects[path] = fakeObject{body: body, headers: headers}
		w.Header().Set("ETag", `"etag"`)
		w.WriteHeader(http.StatusOK)
	case http.MethodGet, http.MethodHead:
		object, ok := f.objects[path]
		if !ok {
			w.Header().Set("Content-Type", "application/xml")
			w.WriteHeader(http.StatusNotFound)
			if r.Method == http.MethodGet {
				_, _ = io.WriteString(w, `<?xml version="1.0" encoding="UTF-8"?><Error><Code>NoSuchKey</Code><Message>missing</Message></Error>`)
			}
			return
		}
		for key, values := range object.headers {
			if strings.EqualFold(key, "X-Amz-Checksum-Sha256") && r.Header.Get("X-Amz-Checksum-Mode") != "ENABLED" {
				continue
			}
			w.Header()[key] = values
		}
		w.Header().Set("Last-Modified", time.Now().UTC().Format(http.TimeFormat))
		w.Header().Set("Content-Length", strconv.Itoa(len(object.body)))
		w.WriteHeader(http.StatusOK)
		if r.Method == http.MethodGet {
			_, _ = w.Write(object.body)
		}
	case http.MethodDelete:
		delete(f.objects, path)
		w.WriteHeader(http.StatusNoContent)
	default:
		w.WriteHeader(http.StatusMethodNotAllowed)
	}
}

func (f *fakeS3) object(path string) (fakeObject, bool) {
	f.mu.Lock()
	defer f.mu.Unlock()
	object, ok := f.objects[path]
	return object, ok
}

func testS3Config(endpoint string) config.S3StorageConfig {
	return config.S3StorageConfig{
		Region:         "ap-south-1",
		Bucket:         "connect-media-private",
		PublicBucket:   "connect-media-public",
		Endpoint:       endpoint,
		ForcePathStyle: true,
		KeyPrefix:      "prod",
		Prefixes:       config.DefaultS3KindPrefixes(),
		LegacyPrefix:   "profile-photos",
		SSE:            "AES256",
		SendChecksums:  true,
		PresignTTL:     2 * time.Minute,
		ServeMode:      config.S3ServeProxy,
		PublicBaseURL:  "https://cdn.example.test",
		Auth: config.S3AuthConfig{
			Mode:            config.S3AuthStatic,
			AccessKeyID:     "AKIAEXAMPLEEXAMPLE",
			SecretAccessKey: "example-secret-not-real",
		},
	}
}

func newTestS3Store(t *testing.T, mutate func(*config.S3StorageConfig)) (*S3Store, *fakeS3) {
	t.Helper()
	fake, server := newFakeS3(t)
	cfg := testS3Config(server.URL)
	if mutate != nil {
		mutate(&cfg)
	}
	store, err := NewS3(context.Background(), cfg)
	if err != nil {
		t.Fatalf("NewS3: %v", err)
	}
	if err := store.VerifyCredentials(context.Background()); err != nil {
		t.Fatalf("VerifyCredentials: %v", err)
	}
	return store, fake
}

func TestS3StoreRoundTripAndKindMapping(t *testing.T) {
	store, fake := newTestS3Store(t, nil)
	ctx := context.Background()
	cases := map[string]string{
		"approved/u1/p.png":                    "connect-media-public/prod/public/profile_photos/u1/p.png",
		"group_covers/g1/c.jpg":                "connect-media-public/prod/public/group_covers/g1/c.jpg",
		"quarantine/u1/q.png":                  "connect-media-private/prod/quarantine/profile_photos/u1/q.png",
		"private/voice/u1/i1/v.webm":           "connect-media-private/prod/private/voice/u1/i1/v.webm",
		"private/verification/u1/selfie/s.png": "connect-media-private/prod/private/verification/u1/selfie/s.png",
		"private/blog/u1/p1/c.jpg":             "connect-media-private/prod/private/chapter_photos/u1/p1/c.jpg",
		"private/themes/u1/t1/t.jpg":           "connect-media-private/prod/private/theme_photos/u1/t1/t.jpg",
	}
	for key, objectPath := range cases {
		body := []byte("bytes of " + key)
		if err := store.Put(ctx, key, body, PutOptions{ContentType: "image/png"}); err != nil {
			t.Fatalf("Put(%s): %v", key, err)
		}
		stored, ok := fake.object(objectPath)
		if !ok {
			t.Fatalf("Put(%s) did not create %s; requests=%v", key, objectPath, fake.requests)
		}
		if string(stored.body) != string(body) {
			t.Fatalf("stored body for %s = %q", key, stored.body)
		}
		if stored.headers.Get("X-Amz-Server-Side-Encryption") != "AES256" {
			t.Errorf("%s: SSE header missing: %v", key, stored.headers)
		}
		sum := sha256.Sum256(body)
		info, err := store.Stat(ctx, key)
		if err != nil || info.Size != int64(len(body)) || info.SHA256 == "" {
			t.Fatalf("Stat(%s) = %+v, %v", key, info, err)
		}
		if info.SHA256 != hexString(sum[:]) {
			t.Fatalf("Stat(%s) sha = %s", key, info.SHA256)
		}
		object, err := store.Open(ctx, key)
		if err != nil {
			t.Fatalf("Open(%s): %v", key, err)
		}
		read, _ := io.ReadAll(object.Body)
		object.Body.Close()
		if string(read) != string(body) || object.ContentType != "image/png" {
			t.Fatalf("Open(%s) = %q %q", key, read, object.ContentType)
		}
		spec, _, _ := Classify(key)
		wantCache := "private, no-store"
		if spec.Visibility == VisibilityPublic {
			wantCache = "public, max-age=86400, immutable"
		}
		if got := stored.headers.Get("Cache-Control"); got != wantCache {
			t.Errorf("%s cache-control = %q want %q", key, got, wantCache)
		}
	}
	for key := range cases {
		if err := store.Delete(ctx, key); err != nil {
			t.Fatalf("Delete(%s): %v", key, err)
		}
		if exists, err := store.Exists(ctx, key); err != nil || exists {
			t.Fatalf("Exists(%s) after delete = %v %v", key, exists, err)
		}
		if _, err := store.Open(ctx, key); !errors.Is(err, ErrNotFound) {
			t.Fatalf("Open(%s) after delete = %v", key, err)
		}
	}
	if err := store.Delete(ctx, "approved/u1/never.png"); err != nil {
		t.Fatalf("Delete missing = %v", err)
	}
	if err := store.Put(ctx, "../escape", []byte("x"), PutOptions{}); !errors.Is(err, ErrInvalidKey) {
		t.Fatalf("Put traversal = %v", err)
	}
}

func TestS3StoreLegacyKeysAndKMS(t *testing.T) {
	store, fake := newTestS3Store(t, func(c *config.S3StorageConfig) {
		c.PublicBucket = ""
		c.KeyPrefix = ""
		c.SSE = "aws:kms"
		c.SSEKMSKeyID = "arn:aws:kms:ap-south-1:111122223333:key/example"
		c.BucketKeyEnabled = true
	})
	ctx := context.Background()
	// A key written by an earlier release stores the full object key.
	legacyKey := "profile-photos/approved/u1/old.png"
	if err := store.Put(ctx, legacyKey, []byte("old"), PutOptions{}); err != nil {
		t.Fatal(err)
	}
	stored, ok := fake.object("connect-media-private/profile-photos/approved/u1/old.png")
	if !ok {
		t.Fatalf("legacy key not addressed verbatim: %v", fake.requests)
	}
	if stored.headers.Get("X-Amz-Server-Side-Encryption") != "aws:kms" ||
		stored.headers.Get("X-Amz-Server-Side-Encryption-Aws-Kms-Key-Id") == "" ||
		stored.headers.Get("X-Amz-Server-Side-Encryption-Bucket-Key-Enabled") != "true" {
		t.Fatalf("KMS headers missing: %v", stored.headers)
	}
	if err := store.Put(ctx, "approved/u1/new.png", []byte("new"), PutOptions{}); err != nil {
		t.Fatal(err)
	}
	if _, ok := fake.object("connect-media-private/public/profile_photos/u1/new.png"); !ok {
		t.Fatalf("public kind without PublicBucket must use the main bucket: %v", fake.requests)
	}
}

func TestS3StorePresignAndPublicURL(t *testing.T) {
	store, _ := newTestS3Store(t, nil)
	ctx := context.Background()
	signed, err := store.Presign(ctx, "private/voice/u1/i1/v.webm", time.Minute)
	if err != nil {
		t.Fatal(err)
	}
	parsed, err := url.Parse(signed)
	if err != nil {
		t.Fatal(err)
	}
	if !strings.HasSuffix(parsed.Path, "/connect-media-private/prod/private/voice/u1/i1/v.webm") ||
		parsed.Query().Get("X-Amz-Signature") == "" || parsed.Query().Get("X-Amz-Expires") != "60" {
		t.Fatalf("presigned URL = %s", signed)
	}
	if strings.Contains(signed, "example-secret-not-real") {
		t.Fatalf("presigned URL leaks the secret")
	}
	public, ok := store.PublicURL("approved/u1/p.png")
	if !ok || public != "https://cdn.example.test/prod/public/profile_photos/u1/p.png" {
		t.Fatalf("PublicURL = %q %v", public, ok)
	}
	if _, ok := store.PublicURL("private/voice/u1/i1/v.webm"); ok {
		t.Fatalf("private media must never get a CDN URL")
	}
}

func TestS3StoreRejectsCorruptedUpload(t *testing.T) {
	store, _ := newTestS3Store(t, nil)
	// Simulate corruption in transit: the checksum describes other bytes.
	bad := *store
	api := &corruptingAPI{S3API: store.api}
	bad.api = api
	if err := bad.Put(context.Background(), "approved/u1/p.png", []byte("good"), PutOptions{}); err == nil {
		t.Fatalf("expected S3 to reject a body that does not match x-amz-checksum-sha256")
	}
}

func TestCopyLocalToS3IsIdempotentAndVerified(t *testing.T) {
	ctx := context.Background()
	source := newKindsStore(t, "")
	for key, body := range map[string]string{
		"approved/u1/a.png":          "photo",
		"private/voice/u1/i1/v.webm": "voice",
		"private/themes/u1/t1/t.jpg": "theme",
		"legacy_user/old_photo.png":  "legacy",
	} {
		if err := source.Put(ctx, key, []byte(body), PutOptions{}); err != nil {
			t.Fatal(err)
		}
	}
	destination, fake := newTestS3Store(t, nil)
	report, err := Copy(ctx, source, destination, CopyOptions{})
	if err != nil || report.WouldCopy != 4 || len(fake.objects) != 0 {
		t.Fatalf("dry run = %+v %v objects=%d", report, err, len(fake.objects))
	}
	report, err = Copy(ctx, source, destination, CopyOptions{Apply: true, Verify: "checksum"})
	if err != nil || report.Copied != 4 || report.Failed != 0 {
		t.Fatalf("apply = %+v %v", report, err)
	}
	report, err = Copy(ctx, source, destination, CopyOptions{Apply: true})
	if err != nil || report.Identical != 4 || report.Copied != 0 {
		t.Fatalf("rerun = %+v %v", report, err)
	}
	if _, ok := fake.object("connect-media-public/prod/public/legacy_profile_photos/legacy_user/old_photo.png"); !ok {
		t.Fatalf("legacy profile photo not mapped: %v", fake.requests)
	}
}

func TestNewS3ClientAuthModes(t *testing.T) {
	_, server := newFakeS3(t)
	t.Setenv("AWS_EC2_METADATA_DISABLED", "true")
	t.Setenv("AWS_ACCESS_KEY_ID", "")
	t.Setenv("AWS_SECRET_ACCESS_KEY", "")
	dir := t.TempDir()
	credentialsFile := dir + "/credentials"
	if err := writeFile(credentialsFile, "[connect-media]\naws_access_key_id = AKIAPROFILEEXAMPLE\naws_secret_access_key = profile-secret-not-real\n"); err != nil {
		t.Fatal(err)
	}
	configFile := dir + "/config"
	if err := writeFile(configFile, "[profile connect-media]\nregion = ap-south-1\n"); err != nil {
		t.Fatal(err)
	}
	t.Setenv("AWS_SHARED_CREDENTIALS_FILE", dir+"/none")
	t.Setenv("AWS_CONFIG_FILE", dir+"/none-config")

	profileCfg := testS3Config(server.URL)
	profileCfg.Auth = config.S3AuthConfig{Mode: config.S3AuthProfile, Profile: "connect-media", SharedCredentialsFile: credentialsFile, SharedConfigFile: configFile}
	store, err := NewS3(context.Background(), profileCfg)
	if err != nil {
		t.Fatalf("profile mode: %v", err)
	}
	if err := store.VerifyCredentials(context.Background()); err != nil {
		t.Fatalf("profile credentials: %v", err)
	}
	if err := store.Put(context.Background(), "approved/u/p.png", []byte("x"), PutOptions{}); err != nil {
		t.Fatalf("profile put: %v", err)
	}

	missingProfile := profileCfg
	missingProfile.Auth.Profile = "does-not-exist"
	if _, err := NewS3(context.Background(), missingProfile); err == nil {
		t.Fatalf("unknown profile must fail at startup")
	}

	chainCfg := testS3Config(server.URL)
	chainCfg.Auth = config.S3AuthConfig{Mode: config.S3AuthDefaultChain}
	t.Setenv("AWS_ACCESS_KEY_ID", "AKIAENVEXAMPLE")
	t.Setenv("AWS_SECRET_ACCESS_KEY", "env-secret-not-real")
	store, err = NewS3(context.Background(), chainCfg)
	if err != nil {
		t.Fatalf("default chain: %v", err)
	}
	if err := store.VerifyCredentials(context.Background()); err != nil {
		t.Fatalf("default chain credentials from env: %v", err)
	}

	roleCfg := testS3Config(server.URL)
	roleCfg.Auth = config.S3AuthConfig{
		Mode: config.S3AuthAssumeRole, AccessKeyID: "AKIASOURCEEXAMPLE", SecretAccessKey: "source-secret-not-real",
		RoleARN: "arn:aws:iam::111122223333:role/connect-media", ExternalID: "connect-external", SessionName: "connect-media", RoleDuration: time.Hour,
	}
	store, err = NewS3(context.Background(), roleCfg)
	if err != nil {
		t.Fatalf("assume role construction: %v", err)
	}
	if store.credentials == nil {
		t.Fatalf("assume role must install an STS credentials provider")
	}
	if text := roleCfg.Auth.String(); strings.Contains(text, "source-secret-not-real") || !strings.Contains(text, "role_arn=") {
		t.Fatalf("auth summary = %s", text)
	}
}

type corruptingAPI struct{ S3API }

func (c *corruptingAPI) PutObject(ctx context.Context, in *s3.PutObjectInput, opts ...func(*s3.Options)) (*s3.PutObjectOutput, error) {
	sum := sha256.Sum256([]byte("other bytes"))
	copyInput := *in
	copyInput.ChecksumSHA256 = aws.String(base64.StdEncoding.EncodeToString(sum[:]))
	return c.S3API.PutObject(ctx, &copyInput, opts...)
}

func hexString(b []byte) string { return hex.EncodeToString(b) }

func writeFile(path, content string) error { return os.WriteFile(path, []byte(content), 0o600) }
