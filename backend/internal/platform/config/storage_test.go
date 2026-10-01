package config

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// clearStorageEnv isolates a test from storage variables in the shell.
func clearStorageEnv(t *testing.T) {
	t.Helper()
	for _, entry := range os.Environ() {
		key, _, _ := strings.Cut(entry, "=")
		if strings.HasPrefix(key, "AWS_S3_") || strings.HasPrefix(key, "MEDIA_") ||
			key == "FILE_STORAGE_BACKEND" || key == "USE_AWS_S3_STORAGE" || key == "AWS_PROFILE" || key == "STORAGE_CONFIG_FILE" {
			t.Setenv(key, "")
			_ = os.Unsetenv(key)
		}
	}
}

func s3Env(t *testing.T, values map[string]string) {
	t.Helper()
	clearStorageEnv(t)
	t.Setenv("FILE_STORAGE_BACKEND", "aws_s3")
	t.Setenv("AWS_S3_BUCKET", "connect-media-private")
	t.Setenv("AWS_S3_REGION", "ap-south-1")
	for key, value := range values {
		t.Setenv(key, value)
	}
}

func expectStorageError(t *testing.T, environment, fragment string) {
	t.Helper()
	_, err := LoadMediaStorage(environment)
	if err == nil || !strings.Contains(err.Error(), fragment) {
		t.Fatalf("expected error containing %q, got %v", fragment, err)
	}
}

func TestMediaStorageDevelopmentDefaultsKeepFlatUploadsDir(t *testing.T) {
	clearStorageEnv(t)
	cfg, err := LoadMediaStorage("development")
	if err != nil {
		t.Fatal(err)
	}
	if cfg.Backend != StorageBackendLocalFS || cfg.Local.Layout != LocalLayoutFlat || cfg.Local.Root != "" ||
		cfg.Local.LegacyUploadsDir != DefaultLegacyUploadsDir {
		t.Fatalf("development defaults = %+v", cfg.Local)
	}
	t.Setenv("MEDIA_UPLOADS_DIR", ".run/uploads/profile_photos")
	if cfg, err = LoadMediaStorage("development"); err != nil || cfg.Local.Layout != LocalLayoutFlat {
		t.Fatalf("explicit MEDIA_UPLOADS_DIR = %+v %v", cfg.Local, err)
	}
}

func TestMediaStorageProductionUsesVarLibAndRequiresAbsoluteRoot(t *testing.T) {
	clearStorageEnv(t)
	cfg, err := LoadMediaStorage("production")
	if err != nil {
		t.Fatal(err)
	}
	if cfg.Local.Root != DefaultProductionMediaRoot || cfg.Local.Layout != LocalLayoutKinds || cfg.Local.LegacyUploadsDir != "" {
		t.Fatalf("production defaults = %+v", cfg.Local)
	}
	if cfg.Local.PublicDirMode != 0o750 || cfg.Local.PublicFileMode != 0o640 || cfg.Local.MinFreeBytes != 500<<20 {
		t.Fatalf("production modes = %+v", cfg.Local)
	}
	t.Setenv("MEDIA_STORAGE_ROOT", "relative/media")
	expectStorageError(t, "production", "must be an absolute path")
	t.Setenv("MEDIA_STORAGE_ROOT", "/srv/connect/media")
	t.Setenv("MEDIA_STORAGE_LAYOUT", "flat")
	expectStorageError(t, "production", "MEDIA_STORAGE_LAYOUT must be kinds")
	t.Setenv("MEDIA_STORAGE_LAYOUT", "")
	t.Setenv("MEDIA_UPLOADS_DIR", "/srv/connect/media/public")
	expectStorageError(t, "production", "must not be inside")
	t.Setenv("MEDIA_UPLOADS_DIR", "/opt/connect/legacy_uploads")
	t.Setenv("MEDIA_PUBLIC_DIR_MODE", "0777")
	expectStorageError(t, "production", "world-writable")
	t.Setenv("MEDIA_PUBLIC_DIR_MODE", "rwx")
	expectStorageError(t, "production", "octal permission")
	t.Setenv("MEDIA_PUBLIC_DIR_MODE", "")
	t.Setenv("MEDIA_LOCAL_ACCEL_REDIRECT_PREFIX", "_connect_media")
	expectStorageError(t, "production", "MEDIA_LOCAL_ACCEL_REDIRECT_PREFIX")
	t.Setenv("MEDIA_LOCAL_ACCEL_REDIRECT_PREFIX", "/_connect_media/")
	if cfg, err = LoadMediaStorage("production"); err != nil || cfg.Local.LegacyUploadsDir != "/opt/connect/legacy_uploads" {
		t.Fatalf("valid production local config = %+v %v", cfg.Local, err)
	}
}

func TestMediaStorageRejectsUnknownBackend(t *testing.T) {
	clearStorageEnv(t)
	t.Setenv("FILE_STORAGE_BACKEND", "gcs")
	expectStorageError(t, "development", "FILE_STORAGE_BACKEND")
}

func TestS3ConfigRequiresBucket(t *testing.T) {
	s3Env(t, map[string]string{"AWS_S3_BUCKET": ""})
	expectStorageError(t, "development", "AWS_S3_BUCKET is required")
	s3Env(t, map[string]string{"AWS_S3_BUCKET": "Bad_Bucket"})
	expectStorageError(t, "development", "not a valid bucket name")
	s3Env(t, map[string]string{"AWS_S3_PUBLIC_BUCKET": "x"})
	expectStorageError(t, "development", "AWS_S3_PUBLIC_BUCKET")
	s3Env(t, map[string]string{"AWS_S3_REGION": ""})
	expectStorageError(t, "production", "AWS_S3_REGION is required")
}

func TestS3ConfigAuthModes(t *testing.T) {
	s3Env(t, nil)
	cfg, err := LoadMediaStorage("production")
	if err != nil || cfg.S3.Auth.Mode != S3AuthDefaultChain {
		t.Fatalf("default chain inferred: %v %v", cfg.S3.Auth, err)
	}

	s3Env(t, map[string]string{"AWS_S3_ACCESS_KEY_ID": "AKIAEXAMPLEEXAMPLE", "AWS_S3_SECRET_ACCESS_KEY": "not-a-real-secret", "AWS_S3_SESSION_TOKEN": "session-token-value"})
	cfg, err = LoadMediaStorage("production")
	if err != nil || cfg.S3.Auth.Mode != S3AuthStatic || cfg.S3.Auth.SessionToken != "session-token-value" {
		t.Fatalf("static inferred: %v %v", cfg.S3.Auth, err)
	}
	for _, text := range []string{cfg.S3.Auth.String(), cfg.Summary()} {
		if strings.Contains(text, "not-a-real-secret") || strings.Contains(text, "AKIAEXAMPLEEXAMPLE") || strings.Contains(text, "session-token-value") {
			t.Fatalf("log-safe summary leaks credentials: %s", text)
		}
	}

	s3Env(t, map[string]string{"AWS_S3_AUTH_MODE": "static", "AWS_S3_ACCESS_KEY_ID": "AKIAEXAMPLEEXAMPLE"})
	expectStorageError(t, "development", "requires both AWS_S3_ACCESS_KEY_ID and AWS_S3_SECRET_ACCESS_KEY")
	s3Env(t, map[string]string{"AWS_S3_AUTH_MODE": "static", "AWS_S3_ACCESS_KEY_ID": "AKIA", "AWS_S3_SECRET_ACCESS_KEY": "s", "AWS_S3_ROLE_ARN": "arn:aws:iam::111122223333:role/x"})
	expectStorageError(t, "development", "use AWS_S3_AUTH_MODE=assume_role")

	s3Env(t, map[string]string{"AWS_S3_AUTH_MODE": "profile"})
	expectStorageError(t, "development", "requires AWS_S3_PROFILE")
	s3Env(t, map[string]string{"AWS_S3_AUTH_MODE": "profile", "AWS_PROFILE": "connect-media", "AWS_S3_SHARED_CREDENTIALS_FILE": "aws/credentials"})
	expectStorageError(t, "development", "must be an absolute path")
	s3Env(t, map[string]string{"AWS_S3_PROFILE": "connect-media", "AWS_S3_SHARED_CREDENTIALS_FILE": "/etc/connect/aws/credentials"})
	if cfg, err = LoadMediaStorage("production"); err != nil || cfg.S3.Auth.Mode != S3AuthProfile || cfg.S3.Auth.Profile != "connect-media" {
		t.Fatalf("profile inferred: %v %v", cfg.S3.Auth, err)
	}

	s3Env(t, map[string]string{"AWS_S3_AUTH_MODE": "instance_role", "AWS_S3_ACCESS_KEY_ID": "AKIA", "AWS_S3_SECRET_ACCESS_KEY": "s"})
	expectStorageError(t, "development", "default_chain")

	s3Env(t, map[string]string{"AWS_S3_ROLE_ARN": "arn:aws:iam::111122223333:role/connect-media", "AWS_S3_ROLE_EXTERNAL_ID": "connect-external"})
	if cfg, err = LoadMediaStorage("production"); err != nil || cfg.S3.Auth.Mode != S3AuthAssumeRole || cfg.S3.Auth.SessionName != "connect-media" {
		t.Fatalf("assume role inferred: %v %v", cfg.S3.Auth, err)
	}
	s3Env(t, map[string]string{"AWS_S3_AUTH_MODE": "assume_role"})
	expectStorageError(t, "development", "requires AWS_S3_ROLE_ARN")
	s3Env(t, map[string]string{"AWS_S3_ROLE_ARN": "arn:aws:iam::123:role/x"})
	expectStorageError(t, "development", "not an IAM role ARN")
	s3Env(t, map[string]string{"AWS_S3_ROLE_ARN": "arn:aws:iam::111122223333:role/x", "AWS_S3_ROLE_DURATION_SECONDS": "60"})
	expectStorageError(t, "development", "AWS_S3_ROLE_DURATION_SECONDS")
	s3Env(t, map[string]string{"AWS_S3_ROLE_ARN": "arn:aws:iam::111122223333:role/x", "AWS_S3_ROLE_SESSION_NAME": "bad name"})
	expectStorageError(t, "development", "AWS_S3_ROLE_SESSION_NAME")

	s3Env(t, map[string]string{"AWS_S3_AUTH_MODE": "magic"})
	expectStorageError(t, "development", "AWS_S3_AUTH_MODE")
}

func TestS3ConfigEncryptionAndServing(t *testing.T) {
	s3Env(t, map[string]string{"AWS_S3_SSE": "sse-kms", "AWS_S3_SSE_KMS_KEY_ID": "alias/connect-media"})
	cfg, err := LoadMediaStorage("production")
	if err != nil || cfg.S3.SSE != "aws:kms" || !cfg.S3.BucketKeyEnabled {
		t.Fatalf("kms = %+v %v", cfg.S3, err)
	}
	s3Env(t, map[string]string{"AWS_S3_SSE": "AES256", "AWS_S3_SSE_KMS_KEY_ID": "alias/connect-media"})
	expectStorageError(t, "development", "set AWS_S3_SSE=aws:kms")
	s3Env(t, map[string]string{"AWS_S3_SSE": "DES"})
	expectStorageError(t, "development", "AWS_S3_SSE=")
	s3Env(t, map[string]string{"AWS_S3_PRESIGN_TTL_SECONDS": "5"})
	expectStorageError(t, "development", "AWS_S3_PRESIGN_TTL_SECONDS")
	s3Env(t, map[string]string{"AWS_S3_SERVE_MODE": "public"})
	expectStorageError(t, "development", "AWS_S3_SERVE_MODE")
	s3Env(t, map[string]string{"AWS_S3_ENDPOINT": "http://minio.internal:9000"})
	expectStorageError(t, "production", "AWS_S3_ENDPOINT must use https")
	if _, err := LoadMediaStorage("development"); err != nil {
		t.Fatalf("http MinIO endpoint is fine for development: %v", err)
	}
	s3Env(t, map[string]string{"AWS_S3_PUBLIC_BASE_URL": "cdn.example.com"})
	expectStorageError(t, "development", "AWS_S3_PUBLIC_BASE_URL")
}

func TestS3ConfigPrefixes(t *testing.T) {
	s3Env(t, map[string]string{"AWS_S3_PREFIX_VOICE": "private/verification"})
	expectStorageError(t, "development", "overlap")
	s3Env(t, map[string]string{"AWS_S3_PREFIX_VOICE": "private/verification/voice"})
	expectStorageError(t, "development", "overlap")
	s3Env(t, map[string]string{"AWS_S3_PROFILE_PHOTOS_PREFIX": "approved"})
	expectStorageError(t, "development", "reserved storage key root")
	s3Env(t, map[string]string{"AWS_S3_KEY_PREFIX": "/prod/", "AWS_S3_PREFIX_VOICE": "/audio/voice/"})
	cfg, err := LoadMediaStorage("development")
	if err != nil || cfg.S3.KeyPrefix != "prod" || cfg.S3.Prefixes.Voice != "audio/voice" || cfg.S3.Prefixes.ProfilePhotos != "public/profile_photos" {
		t.Fatalf("prefixes = %+v %v", cfg.S3, err)
	}
	s3Env(t, map[string]string{"AWS_S3_KEY_PREFIX": "pro d"})
	expectStorageError(t, "development", "AWS_S3_KEY_PREFIX")
}

func TestStorageConfigFile(t *testing.T) {
	clearStorageEnv(t)
	dir := t.TempDir()
	file := filepath.Join(dir, "storage.env")
	content := "# separate storage file\nFILE_STORAGE_BACKEND=aws_s3\nexport AWS_S3_BUCKET=\"connect-media-private\"\nAWS_S3_REGION=ap-south-1\nAWS_S3_SECRET_ACCESS_KEY=not-a-real-secret\nAWS_S3_ACCESS_KEY_ID=AKIAEXAMPLEEXAMPLE\n"
	if err := os.WriteFile(file, []byte(content), 0o640); err != nil {
		t.Fatal(err)
	}
	t.Setenv("STORAGE_CONFIG_FILE", file)
	t.Setenv("AWS_S3_REGION", "eu-west-1") // process env wins
	if err := ApplyStorageConfigFile(); err != nil {
		t.Fatal(err)
	}
	cfg, err := LoadMediaStorage("production")
	if err != nil {
		t.Fatal(err)
	}
	if cfg.Backend != StorageBackendAWSS3 || cfg.S3.Bucket != "connect-media-private" || cfg.S3.Region != "eu-west-1" || cfg.S3.Auth.Mode != S3AuthStatic {
		t.Fatalf("storage file not applied: %+v", cfg.S3)
	}

	if err := os.Chmod(file, 0o644); err != nil {
		t.Fatal(err)
	}
	if _, err := ReadStorageEnvFile(file); err == nil || !strings.Contains(err.Error(), "world-readable") {
		t.Fatalf("world-readable secret file = %v", err)
	}
	other := filepath.Join(dir, "other.env")
	if err := os.WriteFile(other, []byte("DATABASE_URL=postgres://x\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	if _, err := ReadStorageEnvFile(other); err == nil || !strings.Contains(err.Error(), "not a storage setting") {
		t.Fatalf("non-storage key = %v", err)
	}
	t.Setenv("STORAGE_CONFIG_FILE", filepath.Join(dir, "missing.env"))
	if err := ApplyStorageConfigFile(); err == nil {
		t.Fatalf("missing STORAGE_CONFIG_FILE must fail")
	}
}
