// Package mediastore is the single storage abstraction for every kind of
// uploaded media (profile photos, chapter photos, Photo Theme entries, voice
// recordings, identity evidence, group covers, support ticket attachments). It has a local filesystem
// implementation (Ubuntu VPS layout with a public/private split) and an AWS S3
// implementation, selected by configuration.
//
// Callers work with logical storage keys (the value stored in the database,
// e.g. "approved/<user>/<photo>.png" or "private/voice/<user>/<id>/<f>.webm").
// Keys are backend independent: the same key resolves to a file under the
// local media root or to an object in a bucket, so switching backends needs a
// byte copy (mediactl copy) and no database rewrite.
package mediastore

import (
	"errors"
	"regexp"
	"strings"

	"github.com/verified-dating/backend/internal/platform/config"
)

// Kind is a media category with its own directory/prefix and visibility.
type Kind string

const (
	KindProfilePhoto           Kind = "profile_photos"
	KindProfilePhotoQuarantine Kind = "profile_photos_quarantine"
	KindLegacyProfilePhoto     Kind = "legacy_profile_photos"
	KindChapterPhoto           Kind = "chapter_photos"
	KindThemePhoto             Kind = "theme_photos"
	KindGroupCover             Kind = "group_covers"
	KindVoice                  Kind = "voice"
	KindVerification           Kind = "verification"
	KindSupportAttachment      Kind = "support_attachments"
)

// Visibility decides whether bytes may ever be handed to nginx/a CDN.
// Every read is still authorized by the API; "public" only means the media is
// shown to other members once approved.
type Visibility string

const (
	VisibilityPublic     Visibility = "public"
	VisibilityPrivate    Visibility = "private"
	VisibilityQuarantine Visibility = "quarantine"
)

// KindSpec describes how one kind is addressed.
type KindSpec struct {
	Kind Kind
	// KeyPrefix is the logical key prefix stored in the database. Empty for
	// the legacy profile photo kind, which owns every non-reserved key.
	KeyPrefix string
	// LocalDir is the directory below the media root (kinds layout).
	LocalDir   string
	Visibility Visibility
}

// Specs lists every kind. Order matters for Classify (longest prefix first).
var Specs = []KindSpec{
	{Kind: KindVerification, KeyPrefix: "private/verification", LocalDir: "private/verification", Visibility: VisibilityPrivate},
	// Support ticket screenshots and PDFs (migration 126): readable only by the
	// requesting member and support operators, through the API.
	{Kind: KindSupportAttachment, KeyPrefix: "private/support", LocalDir: "private/support_attachments", Visibility: VisibilityPrivate},
	{Kind: KindVoice, KeyPrefix: "private/voice", LocalDir: "private/voice", Visibility: VisibilityPrivate},
	{Kind: KindChapterPhoto, KeyPrefix: "private/blog", LocalDir: "private/chapter_photos", Visibility: VisibilityPrivate},
	{Kind: KindThemePhoto, KeyPrefix: "private/themes", LocalDir: "private/theme_photos", Visibility: VisibilityPrivate},
	{Kind: KindProfilePhoto, KeyPrefix: "approved", LocalDir: "public/profile_photos", Visibility: VisibilityPublic},
	{Kind: KindProfilePhotoQuarantine, KeyPrefix: "quarantine", LocalDir: "quarantine/profile_photos", Visibility: VisibilityQuarantine},
	{Kind: KindGroupCover, KeyPrefix: "group_covers", LocalDir: "public/group_covers", Visibility: VisibilityPublic},
	{Kind: KindLegacyProfilePhoto, KeyPrefix: "", LocalDir: "public/legacy_profile_photos", Visibility: VisibilityPublic},
}

// reservedRoots may only be used by the kinds above; an unknown key below one
// of them is rejected instead of falling through to a public kind.
var reservedRoots = map[string]bool{"approved": true, "quarantine": true, "private": true, "public": true, "group_covers": true, "tmp": true}

var (
	ErrInvalidKey         = errors.New("mediastore: invalid storage key")
	ErrNotFound           = errors.New("mediastore: object not found")
	ErrPresignUnsupported = errors.New("mediastore: presigned URLs are not supported by this backend")
	ErrInsufficientSpace  = errors.New("mediastore: media storage is full")
)

var segmentPattern = regexp.MustCompile(`^[A-Za-z0-9_.-]+$`)

// CleanKey normalizes and validates a logical key. It rejects traversal,
// absolute paths, empty or hidden segments and unexpected characters.
func CleanKey(key string) (string, error) {
	trimmed := strings.TrimSpace(key)
	if trimmed == "" || strings.Contains(trimmed, "\\") || strings.HasPrefix(trimmed, "/") || strings.ContainsRune(trimmed, 0) {
		return "", ErrInvalidKey
	}
	trimmed = strings.TrimRight(trimmed, "/")
	for _, segment := range strings.Split(trimmed, "/") {
		if segment == "" || segment == "." || segment == ".." || strings.HasPrefix(segment, ".") || !segmentPattern.MatchString(segment) {
			return "", ErrInvalidKey
		}
	}
	return trimmed, nil
}

// Classify returns the kind of a logical key and the remainder below the kind
// prefix.
func Classify(key string) (KindSpec, string, error) {
	cleaned, err := CleanKey(key)
	if err != nil {
		return KindSpec{}, "", err
	}
	for _, spec := range Specs {
		if spec.KeyPrefix == "" {
			continue
		}
		if strings.HasPrefix(cleaned, spec.KeyPrefix+"/") {
			rest := strings.TrimPrefix(cleaned, spec.KeyPrefix+"/")
			if rest == "" {
				return KindSpec{}, "", ErrInvalidKey
			}
			return spec, rest, nil
		}
	}
	first, _, _ := strings.Cut(cleaned, "/")
	if reservedRoots[first] {
		return KindSpec{}, "", ErrInvalidKey
	}
	return SpecFor(KindLegacyProfilePhoto), cleaned, nil
}

// SpecFor returns the spec of a kind.
func SpecFor(kind Kind) KindSpec {
	for _, spec := range Specs {
		if spec.Kind == kind {
			return spec
		}
	}
	return KindSpec{}
}

// Key builds a logical key for kind from path segments. Segments are
// sanitized the same way upload handlers always did, so new keys keep the
// historical format (e.g. Key(KindVoice, user, icebreaker, file)).
func Key(kind Kind, segments ...string) (string, error) {
	spec := SpecFor(kind)
	if spec.Kind == "" || spec.KeyPrefix == "" {
		return "", ErrInvalidKey
	}
	if len(segments) == 0 {
		return "", ErrInvalidKey
	}
	for _, segment := range segments {
		// Each segment must be a single safe path element: no "/", "..",
		// hidden names or unexpected characters (path.Join would otherwise
		// resolve "../" into another kind).
		if strings.Contains(segment, "/") {
			return "", ErrInvalidKey
		}
		if _, err := CleanKey(segment); err != nil {
			return "", err
		}
	}
	return CleanKey(spec.KeyPrefix + "/" + strings.Join(segments, "/"))
}

// s3Prefix returns the configured S3 prefix of a kind.
func s3Prefix(kind Kind, p config.S3KindPrefixes) string {
	switch kind {
	case KindProfilePhoto:
		return p.ProfilePhotos
	case KindProfilePhotoQuarantine:
		return p.ProfilePhotosQuarantine
	case KindLegacyProfilePhoto:
		return p.LegacyProfilePhotos
	case KindChapterPhoto:
		return p.ChapterPhotos
	case KindThemePhoto:
		return p.ThemePhotos
	case KindGroupCover:
		return p.GroupCovers
	case KindVoice:
		return p.Voice
	case KindVerification:
		return p.Verification
	case KindSupportAttachment:
		return p.SupportAttachments
	}
	return ""
}

// ResponseCacheControl is the Cache-Control the API sends after authorizing a
// read. Even public media stays out of shared caches: a photo that is deleted
// or re-quarantined must disappear within minutes.
func ResponseCacheControl(v Visibility) string {
	if v == VisibilityPublic {
		return "private, max-age=300"
	}
	return "private, no-store"
}

// ObjectCacheControl is stored with S3 objects; it only matters when a CDN
// serves a public object after a redirect (keys are random and immutable).
func ObjectCacheControl(v Visibility) string {
	if v == VisibilityPublic {
		return "public, max-age=86400, immutable"
	}
	return "private, no-store"
}
