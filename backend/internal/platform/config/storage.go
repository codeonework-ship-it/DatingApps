package config

// Media storage configuration.
//
// Media storage has its own configuration section so that the storage backend,
// the on-disk layout of a Linux VPS and the AWS S3 bucket + credentials can be
// managed (and rotated) separately from the rest of the runtime configuration:
//
//   - systemd loads it from its own EnvironmentFile (/etc/connect/storage.env),
//   - non-systemd runs can point STORAGE_CONFIG_FILE at the same file.
//
// Templates: backend/config/storage.local.env.example and
// backend/config/storage.s3.env.example. Operator guide:
// documents/MEDIA_STORAGE_VPS_AND_S3_2026-10-01.md.

import (
	"bufio"
	"errors"
	"fmt"
	"net/url"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"time"
)

const (
	StorageBackendLocalFS = "local_fs"
	StorageBackendAWSS3   = "aws_s3"

	// LocalLayoutKinds stores each media kind in its own directory with a
	// public/private split (public/profile_photos, private/voice, ...).
	LocalLayoutKinds = "kinds"
	// LocalLayoutFlat stores objects at <root>/<storage key>. This is the
	// historical layout of MEDIA_UPLOADS_DIR and stays the development default.
	LocalLayoutFlat = "flat"

	S3AuthStatic       = "static"
	S3AuthProfile      = "profile"
	S3AuthDefaultChain = "default_chain"
	S3AuthAssumeRole   = "assume_role"

	S3ServeProxy    = "proxy"
	S3ServeRedirect = "redirect"

	// DefaultProductionMediaRoot is the Ubuntu VPS location of local media.
	DefaultProductionMediaRoot = "/var/lib/connect/media"
	// DefaultLegacyUploadsDir is the historical development upload directory.
	DefaultLegacyUploadsDir = ".run/uploads/profile_photos"
)

// MediaStorageConfig selects and configures the media storage backend.
type MediaStorageConfig struct {
	Backend string
	Local   LocalStorageConfig
	S3      S3StorageConfig
}

// LocalStorageConfig configures the local filesystem backend.
type LocalStorageConfig struct {
	// Root is MEDIA_STORAGE_ROOT. Empty means "flat layout rooted at
	// LegacyUploadsDir" (development default).
	Root string
	// Layout is "kinds" (per-kind directories, production) or "flat".
	Layout string
	// LegacyUploadsDir is MEDIA_UPLOADS_DIR. With the kinds layout it is a
	// read/delete fallback so objects written before the new layout keep
	// working; with the flat layout it is the root itself.
	LegacyUploadsDir string
	// MinFreeBytes refuses new uploads when the filesystem has less free space.
	MinFreeBytes int64
	// PublicDirMode / PublicFileMode apply to public/ (nginx may read it through
	// the group). Private, quarantine and tmp always use 0700 / 0600.
	PublicDirMode  os.FileMode
	PublicFileMode os.FileMode
	// AccelRedirectPrefix, when set (e.g. "/_connect_media/"), makes the API
	// answer authorized requests for public media with an X-Accel-Redirect so
	// nginx sends the bytes from an internal location.
	AccelRedirectPrefix string
}

// S3StorageConfig configures the AWS S3 (or S3-compatible) backend.
type S3StorageConfig struct {
	Region string
	// Bucket holds private, quarantined and (unless PublicBucket is set) public
	// media. Keep it private with Block Public Access on.
	Bucket string
	// PublicBucket optionally holds public kinds (profile photos, group covers)
	// so a CDN can front it. It still does not need public ACLs.
	PublicBucket   string
	Endpoint       string
	ForcePathStyle bool
	// KeyPrefix is an optional global prefix (e.g. "prod") in front of every
	// kind prefix.
	KeyPrefix string
	Prefixes  S3KindPrefixes
	// LegacyPrefix is AWS_S3_PROFILE_PHOTOS_PREFIX. Earlier releases stored the
	// full object key (legacy prefix included) in the database; such keys are
	// still read from Bucket verbatim.
	LegacyPrefix string
	// SSE is "", "AES256" or "aws:kms".
	SSE              string
	SSEKMSKeyID      string
	BucketKeyEnabled bool
	// SendChecksums sends x-amz-checksum-sha256 on upload so S3 verifies the
	// bytes. Disable only for S3-compatible stores that reject it.
	SendChecksums bool
	PresignTTL    time.Duration
	// ServeMode is "proxy" (the API streams bytes) or "redirect" (the API
	// authorizes, then 302-redirects to a short-lived presigned GET).
	ServeMode string
	// PublicBaseURL optionally points at a CDN (CloudFront) in front of the
	// public bucket; used for redirects of public media in redirect mode.
	PublicBaseURL string
	Auth          S3AuthConfig
}

// S3KindPrefixes are the key prefixes per media kind.
type S3KindPrefixes struct {
	ProfilePhotos           string
	ProfilePhotosQuarantine string
	LegacyProfilePhotos     string
	ChapterPhotos           string
	ThemePhotos             string
	GroupCovers             string
	Voice                   string
	Verification            string
	SupportAttachments      string
}

// DefaultS3KindPrefixes mirrors the local kinds layout inside the bucket.
func DefaultS3KindPrefixes() S3KindPrefixes {
	return S3KindPrefixes{
		ProfilePhotos:           "public/profile_photos",
		ProfilePhotosQuarantine: "quarantine/profile_photos",
		LegacyProfilePhotos:     "public/legacy_profile_photos",
		ChapterPhotos:           "private/chapter_photos",
		ThemePhotos:             "private/theme_photos",
		GroupCovers:             "public/group_covers",
		Voice:                   "private/voice",
		Verification:            "private/verification",
		SupportAttachments:      "private/support_attachments",
	}
}

// S3AuthConfig holds credentials. Never log it with %v of the raw fields; it
// implements String()/GoString() that redact secrets.
type S3AuthConfig struct {
	Mode                  string
	AccessKeyID           string
	SecretAccessKey       string
	SessionToken          string
	Profile               string
	SharedCredentialsFile string
	SharedConfigFile      string
	RoleARN               string
	ExternalID            string
	SessionName           string
	RoleDuration          time.Duration
}

// String never includes secrets.
func (a S3AuthConfig) String() string {
	parts := []string{"mode=" + a.Mode}
	switch a.Mode {
	case S3AuthStatic:
		parts = append(parts, "access_key_id="+maskAccessKeyID(a.AccessKeyID), "session_token="+strconv.FormatBool(a.SessionToken != ""))
	case S3AuthProfile:
		parts = append(parts, "profile="+a.Profile)
		if a.SharedCredentialsFile != "" {
			parts = append(parts, "credentials_file="+a.SharedCredentialsFile)
		}
	case S3AuthAssumeRole:
		parts = append(parts, "role_arn="+a.RoleARN, "session_name="+a.SessionName, "external_id="+strconv.FormatBool(a.ExternalID != ""))
	}
	return "S3Auth{" + strings.Join(parts, " ") + "}"
}

// GoString keeps %#v from printing secrets.
func (a S3AuthConfig) GoString() string { return a.String() }

// Summary is a log-safe description of the storage configuration.
func (c MediaStorageConfig) Summary() string {
	if c.Backend == StorageBackendAWSS3 {
		s := c.S3
		public := s.PublicBucket
		if public == "" {
			public = s.Bucket
		}
		return fmt.Sprintf("backend=aws_s3 bucket=%s public_bucket=%s region=%s endpoint=%s key_prefix=%q sse=%s serve=%s %s",
			s.Bucket, public, s.Region, emptyAsDash(s.Endpoint), s.KeyPrefix, emptyAsDash(s.SSE), s.ServeMode, s.Auth.String())
	}
	root := c.Local.Root
	if root == "" {
		root = c.Local.LegacyUploadsDir
	}
	return fmt.Sprintf("backend=local_fs root=%s layout=%s legacy_uploads_dir=%s min_free_bytes=%d accel_redirect=%s",
		root, c.Local.Layout, emptyAsDash(c.Local.LegacyUploadsDir), c.Local.MinFreeBytes, emptyAsDash(c.Local.AccelRedirectPrefix))
}

func emptyAsDash(v string) string {
	if strings.TrimSpace(v) == "" {
		return "-"
	}
	return v
}

func maskAccessKeyID(id string) string {
	if len(id) <= 4 {
		return strings.Repeat("*", len(id))
	}
	return strings.Repeat("*", len(id)-4) + id[len(id)-4:]
}

// storageConfigKeys are the only keys STORAGE_CONFIG_FILE may define, so the
// separate storage file cannot silently change unrelated runtime settings.
var storageConfigKeyPattern = regexp.MustCompile(`^(MEDIA_[A-Z0-9_]+|AWS_S3_[A-Z0-9_]+|FILE_STORAGE_BACKEND|USE_AWS_S3_STORAGE)$`)

// ApplyStorageConfigFile loads STORAGE_CONFIG_FILE (if set) into the process
// environment. Variables already present in the environment win, so systemd
// EnvironmentFile= values and explicit overrides are never replaced.
func ApplyStorageConfigFile() error {
	path := strings.TrimSpace(os.Getenv("STORAGE_CONFIG_FILE"))
	if path == "" {
		return nil
	}
	values, err := ReadStorageEnvFile(path)
	if err != nil {
		return err
	}
	for key, value := range values {
		if _, present := os.LookupEnv(key); present {
			continue
		}
		if err := os.Setenv(key, value); err != nil {
			return fmt.Errorf("STORAGE_CONFIG_FILE: set %s: %w", key, err)
		}
	}
	return nil
}

// ReadStorageEnvFile parses a KEY=VALUE env file restricted to storage keys.
// A file that holds secrets must not be readable by other users.
func ReadStorageEnvFile(path string) (map[string]string, error) {
	info, err := os.Stat(path)
	if err != nil {
		return nil, fmt.Errorf("STORAGE_CONFIG_FILE %s: %w", path, err)
	}
	if info.IsDir() {
		return nil, fmt.Errorf("STORAGE_CONFIG_FILE %s is a directory", path)
	}
	file, err := os.Open(path)
	if err != nil {
		return nil, fmt.Errorf("STORAGE_CONFIG_FILE %s: %w", path, err)
	}
	defer file.Close()
	values := map[string]string{}
	scanner := bufio.NewScanner(file)
	line := 0
	for scanner.Scan() {
		line++
		text := strings.TrimSpace(scanner.Text())
		if text == "" || strings.HasPrefix(text, "#") {
			continue
		}
		text = strings.TrimPrefix(text, "export ")
		key, value, ok := strings.Cut(text, "=")
		if !ok {
			return nil, fmt.Errorf("STORAGE_CONFIG_FILE %s:%d: expected KEY=VALUE", path, line)
		}
		key = strings.TrimSpace(key)
		if !storageConfigKeyPattern.MatchString(key) {
			return nil, fmt.Errorf("STORAGE_CONFIG_FILE %s:%d: %s is not a storage setting (allowed: MEDIA_*, AWS_S3_*, FILE_STORAGE_BACKEND, USE_AWS_S3_STORAGE)", path, line, key)
		}
		value = strings.TrimSpace(value)
		if len(value) >= 2 && ((value[0] == '"' && value[len(value)-1] == '"') || (value[0] == '\'' && value[len(value)-1] == '\'')) {
			value = value[1 : len(value)-1]
		}
		values[key] = value
	}
	if err := scanner.Err(); err != nil {
		return nil, fmt.Errorf("STORAGE_CONFIG_FILE %s: %w", path, err)
	}
	if info.Mode().Perm()&0o004 != 0 {
		for _, secret := range []string{"AWS_S3_SECRET_ACCESS_KEY", "AWS_S3_SESSION_TOKEN"} {
			if values[secret] != "" {
				return nil, fmt.Errorf("STORAGE_CONFIG_FILE %s contains %s but is world-readable; run: chmod 0640 %s", path, secret, path)
			}
		}
	}
	return values, nil
}

// LoadMediaStorage reads and validates the media storage section from the
// environment. environment is the ENVIRONMENT value (production rules apply to
// production/staging).
func LoadMediaStorage(environment string) (MediaStorageConfig, error) {
	prodLike := isProdLikeEnvironment(environment)
	var problems []string
	add := func(format string, args ...any) { problems = append(problems, fmt.Sprintf(format, args...)) }

	cfg := MediaStorageConfig{}

	rawBackend := strings.ToLower(strings.TrimSpace(os.Getenv("FILE_STORAGE_BACKEND")))
	useS3, err := strictBool("USE_AWS_S3_STORAGE", false)
	if err != nil {
		add("%v", err)
	}
	switch rawBackend {
	case "", "local", "local_fs", "filesystem":
		cfg.Backend = StorageBackendLocalFS
	case "aws", "aws_s3", "s3":
		cfg.Backend = StorageBackendAWSS3
	default:
		add("FILE_STORAGE_BACKEND=%q is not supported (use local_fs or aws_s3)", rawBackend)
		cfg.Backend = StorageBackendLocalFS
	}
	if useS3 {
		cfg.Backend = StorageBackendAWSS3
	}

	// ── Local filesystem ────────────────────────────────────────────────────
	local := LocalStorageConfig{}
	local.Root = strings.TrimSpace(os.Getenv("MEDIA_STORAGE_ROOT"))
	legacy, legacySet := os.LookupEnv("MEDIA_UPLOADS_DIR")
	legacy = strings.TrimSpace(legacy)
	if legacy == "" {
		legacySet = false
	}
	if local.Root == "" && prodLike {
		local.Root = DefaultProductionMediaRoot
	}
	if legacySet {
		local.LegacyUploadsDir = filepath.Clean(legacy)
	} else if local.Root == "" {
		local.LegacyUploadsDir = DefaultLegacyUploadsDir
	}
	if local.Root != "" {
		local.Root = filepath.Clean(local.Root)
	}
	local.Layout = strings.ToLower(strings.TrimSpace(os.Getenv("MEDIA_STORAGE_LAYOUT")))
	if local.Layout == "" {
		local.Layout = LocalLayoutKinds
		if local.Root == "" {
			local.Layout = LocalLayoutFlat
		}
	}
	if local.Layout != LocalLayoutKinds && local.Layout != LocalLayoutFlat {
		add("MEDIA_STORAGE_LAYOUT=%q is not supported (use kinds or flat)", local.Layout)
	}
	minFreeMB, err := strictInt("MEDIA_MIN_FREE_MB", 500)
	if err != nil || minFreeMB < 0 {
		add("MEDIA_MIN_FREE_MB must be a non-negative integer")
	}
	local.MinFreeBytes = int64(minFreeMB) << 20
	if local.PublicDirMode, err = strictMode("MEDIA_PUBLIC_DIR_MODE", 0o750); err != nil {
		add("%v", err)
	}
	if local.PublicFileMode, err = strictMode("MEDIA_PUBLIC_FILE_MODE", 0o640); err != nil {
		add("%v", err)
	}
	local.AccelRedirectPrefix = strings.TrimSpace(os.Getenv("MEDIA_LOCAL_ACCEL_REDIRECT_PREFIX"))
	cfg.Local = local

	// ── AWS S3 ──────────────────────────────────────────────────────────────
	s3 := S3StorageConfig{}
	s3.Region = strings.TrimSpace(os.Getenv("AWS_S3_REGION"))
	s3.Bucket = strings.TrimSpace(os.Getenv("AWS_S3_BUCKET"))
	s3.PublicBucket = strings.TrimSpace(os.Getenv("AWS_S3_PUBLIC_BUCKET"))
	s3.Endpoint = strings.TrimRight(strings.TrimSpace(os.Getenv("AWS_S3_ENDPOINT")), "/")
	if s3.ForcePathStyle, err = strictBool("AWS_S3_FORCE_PATH_STYLE", false); err != nil {
		add("%v", err)
	}
	s3.KeyPrefix = normalizeStoragePrefix(os.Getenv("AWS_S3_KEY_PREFIX"))
	s3.LegacyPrefix = normalizeStoragePrefix(getOrDefault("AWS_S3_PROFILE_PHOTOS_PREFIX", "profile-photos"))
	defaults := DefaultS3KindPrefixes()
	s3.Prefixes = S3KindPrefixes{
		ProfilePhotos:           prefixOrDefault("AWS_S3_PREFIX_PROFILE_PHOTOS", defaults.ProfilePhotos),
		ProfilePhotosQuarantine: prefixOrDefault("AWS_S3_PREFIX_PROFILE_PHOTOS_QUARANTINE", defaults.ProfilePhotosQuarantine),
		LegacyProfilePhotos:     prefixOrDefault("AWS_S3_PREFIX_LEGACY_PROFILE_PHOTOS", defaults.LegacyProfilePhotos),
		ChapterPhotos:           prefixOrDefault("AWS_S3_PREFIX_CHAPTER_PHOTOS", defaults.ChapterPhotos),
		ThemePhotos:             prefixOrDefault("AWS_S3_PREFIX_THEME_PHOTOS", defaults.ThemePhotos),
		GroupCovers:             prefixOrDefault("AWS_S3_PREFIX_GROUP_COVERS", defaults.GroupCovers),
		Voice:                   prefixOrDefault("AWS_S3_PREFIX_VOICE", defaults.Voice),
		Verification:            prefixOrDefault("AWS_S3_PREFIX_VERIFICATION", defaults.Verification),
		SupportAttachments:      prefixOrDefault("AWS_S3_PREFIX_SUPPORT_ATTACHMENTS", defaults.SupportAttachments),
	}
	s3.SSE = strings.TrimSpace(os.Getenv("AWS_S3_SSE"))
	switch strings.ToLower(s3.SSE) {
	case "", "none":
		s3.SSE = ""
	case "aes256", "sse-s3":
		s3.SSE = "AES256"
	case "aws:kms", "kms", "sse-kms":
		s3.SSE = "aws:kms"
	}
	s3.SSEKMSKeyID = strings.TrimSpace(os.Getenv("AWS_S3_SSE_KMS_KEY_ID"))
	if s3.BucketKeyEnabled, err = strictBool("AWS_S3_BUCKET_KEY_ENABLED", s3.SSE == "aws:kms"); err != nil {
		add("%v", err)
	}
	if s3.SendChecksums, err = strictBool("AWS_S3_SEND_CHECKSUMS", true); err != nil {
		add("%v", err)
	}
	presignSeconds, err := strictInt("AWS_S3_PRESIGN_TTL_SECONDS", 300)
	if err != nil {
		add("%v", err)
	}
	s3.PresignTTL = time.Duration(presignSeconds) * time.Second
	s3.ServeMode = strings.ToLower(strings.TrimSpace(getOrDefault("AWS_S3_SERVE_MODE", S3ServeProxy)))
	s3.PublicBaseURL = strings.TrimRight(strings.TrimSpace(os.Getenv("AWS_S3_PUBLIC_BASE_URL")), "/")

	auth := S3AuthConfig{}
	auth.Mode = strings.ToLower(strings.TrimSpace(os.Getenv("AWS_S3_AUTH_MODE")))
	auth.AccessKeyID = strings.TrimSpace(os.Getenv("AWS_S3_ACCESS_KEY_ID"))
	auth.SecretAccessKey = strings.TrimSpace(os.Getenv("AWS_S3_SECRET_ACCESS_KEY"))
	auth.SessionToken = strings.TrimSpace(os.Getenv("AWS_S3_SESSION_TOKEN"))
	auth.Profile = strings.TrimSpace(getOrDefault("AWS_S3_PROFILE", os.Getenv("AWS_PROFILE")))
	auth.SharedCredentialsFile = strings.TrimSpace(os.Getenv("AWS_S3_SHARED_CREDENTIALS_FILE"))
	auth.SharedConfigFile = strings.TrimSpace(os.Getenv("AWS_S3_SHARED_CONFIG_FILE"))
	auth.RoleARN = strings.TrimSpace(os.Getenv("AWS_S3_ROLE_ARN"))
	auth.ExternalID = strings.TrimSpace(os.Getenv("AWS_S3_ROLE_EXTERNAL_ID"))
	auth.SessionName = strings.TrimSpace(getOrDefault("AWS_S3_ROLE_SESSION_NAME", "connect-media"))
	roleSeconds, err := strictInt("AWS_S3_ROLE_DURATION_SECONDS", 3600)
	if err != nil {
		add("%v", err)
	}
	auth.RoleDuration = time.Duration(roleSeconds) * time.Second
	switch auth.Mode {
	case "":
		switch {
		case auth.RoleARN != "":
			auth.Mode = S3AuthAssumeRole
		case auth.AccessKeyID != "" || auth.SecretAccessKey != "":
			auth.Mode = S3AuthStatic
		case strings.TrimSpace(os.Getenv("AWS_S3_PROFILE")) != "":
			auth.Mode = S3AuthProfile
		default:
			auth.Mode = S3AuthDefaultChain
		}
	case "static", "access_key", "keys":
		auth.Mode = S3AuthStatic
	case "profile", "shared_profile":
		auth.Mode = S3AuthProfile
	case "default_chain", "default", "instance_role", "iam_role", "instance_profile":
		auth.Mode = S3AuthDefaultChain
	case "assume_role", "role":
		auth.Mode = S3AuthAssumeRole
	}
	s3.Auth = auth
	cfg.S3 = s3

	problems = append(problems, cfg.validate(prodLike)...)
	if len(problems) > 0 {
		return cfg, errors.New("media storage configuration is invalid:\n  - " + strings.Join(problems, "\n  - "))
	}
	return cfg, nil
}

var (
	bucketNamePattern  = regexp.MustCompile(`^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$`)
	storagePrefixChars = regexp.MustCompile(`^[A-Za-z0-9._/-]*$`)
	roleARNPattern     = regexp.MustCompile(`^arn:aws[a-zA-Z-]*:iam::\d{12}:role/[\w+=,.@/-]{1,512}$`)
	sessionNamePattern = regexp.MustCompile(`^[\w+=,.@-]{2,64}$`)
)

// reservedLogicalRoots are first segments of storage keys owned by a media
// kind; the legacy S3 prefix must not shadow them.
var reservedLogicalRoots = []string{"approved", "quarantine", "private", "public", "group_covers", "tmp"}

func (c MediaStorageConfig) validate(prodLike bool) []string {
	var problems []string
	add := func(format string, args ...any) { problems = append(problems, fmt.Sprintf(format, args...)) }

	l := c.Local
	if c.Backend == StorageBackendLocalFS {
		root := l.Root
		if root == "" {
			root = l.LegacyUploadsDir
		}
		if root == "" {
			add("MEDIA_STORAGE_ROOT is required for local_fs storage")
		}
		if prodLike {
			if !filepath.IsAbs(l.Root) {
				add("MEDIA_STORAGE_ROOT must be an absolute path in production/staging (got %q; recommended %s)", l.Root, DefaultProductionMediaRoot)
			}
			if l.Layout != LocalLayoutKinds {
				add("MEDIA_STORAGE_LAYOUT must be kinds in production/staging")
			}
		}
		if l.Layout == LocalLayoutFlat && l.Root != "" && l.LegacyUploadsDir != "" && l.Root != l.LegacyUploadsDir {
			add("MEDIA_STORAGE_LAYOUT=flat uses a single directory; set either MEDIA_STORAGE_ROOT or MEDIA_UPLOADS_DIR, not both with different values")
		}
		if l.Layout == LocalLayoutKinds && l.Root == "" {
			add("MEDIA_STORAGE_LAYOUT=kinds requires MEDIA_STORAGE_ROOT")
		}
		if l.Layout == LocalLayoutKinds && l.Root != "" && l.LegacyUploadsDir != "" && pathsOverlap(l.Root, l.LegacyUploadsDir) {
			add("MEDIA_UPLOADS_DIR (%s) must not be inside, equal to, or contain MEDIA_STORAGE_ROOT (%s); move legacy files with `mediactl copy --from legacy --to local` first", l.LegacyUploadsDir, l.Root)
		}
		if l.PublicDirMode&0o002 != 0 || l.PublicFileMode&0o002 != 0 {
			add("MEDIA_PUBLIC_DIR_MODE/MEDIA_PUBLIC_FILE_MODE must not be world-writable")
		}
		if l.PublicDirMode&0o700 != 0o700 || l.PublicFileMode&0o600 != 0o600 {
			add("MEDIA_PUBLIC_DIR_MODE needs owner rwx and MEDIA_PUBLIC_FILE_MODE owner rw")
		}
		if l.AccelRedirectPrefix != "" && (!strings.HasPrefix(l.AccelRedirectPrefix, "/") || !strings.HasSuffix(l.AccelRedirectPrefix, "/") || strings.Contains(l.AccelRedirectPrefix, "..")) {
			add("MEDIA_LOCAL_ACCEL_REDIRECT_PREFIX must start and end with '/' (e.g. /_connect_media/)")
		}
	}

	if c.Backend != StorageBackendAWSS3 {
		return problems
	}
	s := c.S3
	if s.Bucket == "" {
		add("AWS_S3_BUCKET is required when aws_s3 storage backend is enabled")
	} else if !bucketNamePattern.MatchString(s.Bucket) || strings.Contains(s.Bucket, "..") {
		add("AWS_S3_BUCKET=%q is not a valid bucket name", s.Bucket)
	}
	if s.PublicBucket != "" && (!bucketNamePattern.MatchString(s.PublicBucket) || strings.Contains(s.PublicBucket, "..")) {
		add("AWS_S3_PUBLIC_BUCKET=%q is not a valid bucket name", s.PublicBucket)
	}
	if s.Region == "" && s.Endpoint == "" && prodLike {
		add("AWS_S3_REGION is required in production/staging")
	}
	if s.Endpoint != "" {
		parsed, err := url.Parse(s.Endpoint)
		if err != nil || parsed.Host == "" || (parsed.Scheme != "https" && parsed.Scheme != "http") {
			add("AWS_S3_ENDPOINT=%q must be an http(s) URL", s.Endpoint)
		} else if prodLike && parsed.Scheme != "https" {
			add("AWS_S3_ENDPOINT must use https in production/staging")
		}
	}
	if s.PublicBaseURL != "" {
		parsed, err := url.Parse(s.PublicBaseURL)
		if err != nil || parsed.Host == "" || (parsed.Scheme != "https" && parsed.Scheme != "http") {
			add("AWS_S3_PUBLIC_BASE_URL=%q must be an http(s) URL", s.PublicBaseURL)
		} else if prodLike && parsed.Scheme != "https" {
			add("AWS_S3_PUBLIC_BASE_URL must use https in production/staging")
		}
	}
	switch s.SSE {
	case "", "AES256":
		if s.SSEKMSKeyID != "" {
			add("AWS_S3_SSE_KMS_KEY_ID is set but AWS_S3_SSE is %q; set AWS_S3_SSE=aws:kms", emptyAsDash(s.SSE))
		}
	case "aws:kms":
	default:
		add("AWS_S3_SSE=%q is not supported (use AES256 or aws:kms, or leave empty for the bucket default)", s.SSE)
	}
	if s.PresignTTL < 30*time.Second || s.PresignTTL > time.Hour {
		add("AWS_S3_PRESIGN_TTL_SECONDS must be between 30 and 3600")
	}
	if s.ServeMode != S3ServeProxy && s.ServeMode != S3ServeRedirect {
		add("AWS_S3_SERVE_MODE=%q is not supported (use proxy or redirect)", s.ServeMode)
	}
	for _, p := range []struct{ name, value string }{{"AWS_S3_KEY_PREFIX", s.KeyPrefix}, {"AWS_S3_PROFILE_PHOTOS_PREFIX", s.LegacyPrefix}} {
		if !storagePrefixChars.MatchString(p.value) || strings.Contains(p.value, "..") {
			add("%s=%q may only contain letters, digits, '.', '_', '-' and '/'", p.name, p.value)
		}
	}
	for _, reserved := range reservedLogicalRoots {
		if s.LegacyPrefix == reserved || strings.HasPrefix(s.LegacyPrefix, reserved+"/") {
			add("AWS_S3_PROFILE_PHOTOS_PREFIX=%q collides with the reserved storage key root %q", s.LegacyPrefix, reserved)
		}
	}
	kindPrefixes := []struct{ name, value string }{
		{"AWS_S3_PREFIX_PROFILE_PHOTOS", s.Prefixes.ProfilePhotos},
		{"AWS_S3_PREFIX_PROFILE_PHOTOS_QUARANTINE", s.Prefixes.ProfilePhotosQuarantine},
		{"AWS_S3_PREFIX_LEGACY_PROFILE_PHOTOS", s.Prefixes.LegacyProfilePhotos},
		{"AWS_S3_PREFIX_CHAPTER_PHOTOS", s.Prefixes.ChapterPhotos},
		{"AWS_S3_PREFIX_THEME_PHOTOS", s.Prefixes.ThemePhotos},
		{"AWS_S3_PREFIX_GROUP_COVERS", s.Prefixes.GroupCovers},
		{"AWS_S3_PREFIX_VOICE", s.Prefixes.Voice},
		{"AWS_S3_PREFIX_VERIFICATION", s.Prefixes.Verification},
		{"AWS_S3_PREFIX_SUPPORT_ATTACHMENTS", s.Prefixes.SupportAttachments},
	}
	for i, a := range kindPrefixes {
		if a.value == "" {
			add("%s must not be empty", a.name)
			continue
		}
		if !storagePrefixChars.MatchString(a.value) || strings.Contains(a.value, "..") {
			add("%s=%q may only contain letters, digits, '.', '_', '-' and '/'", a.name, a.value)
		}
		for _, b := range kindPrefixes[i+1:] {
			if b.value != "" && pathsOverlap(a.value, b.value) {
				add("%s (%q) and %s (%q) overlap; every media kind needs its own prefix", a.name, a.value, b.name, b.value)
			}
		}
		if s.LegacyPrefix != "" && s.KeyPrefix == "" && pathsOverlap(a.value, s.LegacyPrefix) {
			add("%s (%q) overlaps the legacy AWS_S3_PROFILE_PHOTOS_PREFIX (%q)", a.name, a.value, s.LegacyPrefix)
		}
	}

	a := s.Auth
	switch a.Mode {
	case S3AuthStatic:
		if a.AccessKeyID == "" || a.SecretAccessKey == "" {
			add("AWS_S3_AUTH_MODE=static requires both AWS_S3_ACCESS_KEY_ID and AWS_S3_SECRET_ACCESS_KEY")
		}
		if a.RoleARN != "" {
			add("AWS_S3_ROLE_ARN is set but AWS_S3_AUTH_MODE=static; use AWS_S3_AUTH_MODE=assume_role (static keys then act as the source credentials)")
		}
	case S3AuthProfile:
		if a.Profile == "" {
			add("AWS_S3_AUTH_MODE=profile requires AWS_S3_PROFILE (or AWS_PROFILE)")
		}
		if a.AccessKeyID != "" || a.SecretAccessKey != "" {
			add("AWS_S3_ACCESS_KEY_ID/AWS_S3_SECRET_ACCESS_KEY are set but AWS_S3_AUTH_MODE=profile; remove the keys or use static")
		}
		for _, f := range []struct{ name, value string }{{"AWS_S3_SHARED_CREDENTIALS_FILE", a.SharedCredentialsFile}, {"AWS_S3_SHARED_CONFIG_FILE", a.SharedConfigFile}} {
			if f.value != "" && !filepath.IsAbs(f.value) {
				add("%s must be an absolute path", f.name)
			}
		}
	case S3AuthDefaultChain:
		if a.AccessKeyID != "" || a.SecretAccessKey != "" {
			add("AWS_S3_ACCESS_KEY_ID/AWS_S3_SECRET_ACCESS_KEY are set but AWS_S3_AUTH_MODE=default_chain; remove the keys or use static")
		}
	case S3AuthAssumeRole:
		if a.RoleARN == "" {
			add("AWS_S3_AUTH_MODE=assume_role requires AWS_S3_ROLE_ARN")
		} else if !roleARNPattern.MatchString(a.RoleARN) {
			add("AWS_S3_ROLE_ARN=%q is not an IAM role ARN (arn:aws:iam::<12-digit account>:role/<name>)", a.RoleARN)
		}
		if !sessionNamePattern.MatchString(a.SessionName) {
			add("AWS_S3_ROLE_SESSION_NAME must be 2-64 characters of [A-Za-z0-9+=,.@_-]")
		}
		if a.ExternalID != "" && (len(a.ExternalID) < 2 || len(a.ExternalID) > 1224) {
			add("AWS_S3_ROLE_EXTERNAL_ID must be 2-1224 characters")
		}
		if a.RoleDuration < 15*time.Minute || a.RoleDuration > 12*time.Hour {
			add("AWS_S3_ROLE_DURATION_SECONDS must be between 900 and 43200")
		}
		if (a.AccessKeyID == "") != (a.SecretAccessKey == "") {
			add("assume_role source keys need both AWS_S3_ACCESS_KEY_ID and AWS_S3_SECRET_ACCESS_KEY (or neither)")
		}
	default:
		add("AWS_S3_AUTH_MODE=%q is not supported (use static, profile, default_chain or assume_role)", a.Mode)
	}
	if a.SessionToken != "" && a.AccessKeyID == "" {
		add("AWS_S3_SESSION_TOKEN requires AWS_S3_ACCESS_KEY_ID and AWS_S3_SECRET_ACCESS_KEY")
	}
	return problems
}

// pathsOverlap reports whether a equals b or one is a parent of the other.
func pathsOverlap(a, b string) bool {
	a = strings.TrimRight(filepath.ToSlash(filepath.Clean(a)), "/")
	b = strings.TrimRight(filepath.ToSlash(filepath.Clean(b)), "/")
	if a == b {
		return true
	}
	return strings.HasPrefix(a, b+"/") || strings.HasPrefix(b, a+"/")
}

func prefixOrDefault(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok && strings.TrimSpace(value) != "" {
		return normalizeStoragePrefix(value)
	}
	return fallback
}

func strictBool(key string, fallback bool) (bool, error) {
	value := strings.TrimSpace(os.Getenv(key))
	if value == "" {
		return fallback, nil
	}
	parsed, err := strconv.ParseBool(value)
	if err != nil {
		return fallback, fmt.Errorf("%s=%q must be true or false", key, value)
	}
	return parsed, nil
}

func strictInt(key string, fallback int) (int, error) {
	value := strings.TrimSpace(os.Getenv(key))
	if value == "" {
		return fallback, nil
	}
	parsed, err := strconv.Atoi(value)
	if err != nil {
		return fallback, fmt.Errorf("%s=%q must be an integer", key, value)
	}
	return parsed, nil
}

func strictMode(key string, fallback os.FileMode) (os.FileMode, error) {
	value := strings.TrimSpace(os.Getenv(key))
	if value == "" {
		return fallback, nil
	}
	parsed, err := strconv.ParseUint(value, 8, 32)
	if err != nil || parsed > 0o777 {
		return fallback, fmt.Errorf("%s=%q must be an octal permission such as 0750", key, value)
	}
	return os.FileMode(parsed), nil
}
