package observability

import (
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"net/http"
	"os"
	"regexp"
	"strings"
	"sync"

	"github.com/go-chi/chi/v5"
)

// Central redaction helpers for logs and stored telemetry.
//
// Server logs and request telemetry must not carry personal data: no
// usernames (which are often phone numbers or e-mail addresses), no card
// digits, no client IP addresses, no query strings and no member ids inside
// request paths. These helpers are the one place that rule is implemented so
// every call site redacts the same way. documents/CLIENT_ERROR_REPORTING_AND_PRIVACY_2026-10-01.md
// describes the policy.

// Placeholders written in place of redacted values.
const (
	RedactedEmail  = "<email>"
	RedactedPhone  = "<phone>"
	RedactedToken  = "<token>"
	RedactedID     = "<id>"
	RedactedIP     = "<ip>"
	RedactedNumber = "<number>"
	pathIDSegment  = "{id}"
)

var (
	redactURLPattern   = regexp.MustCompile(`(?i)\b((?:https?|wss?)://[^\s?#"'<>]+)[?#][^\s"'<>]*`)
	redactQueryPattern = regexp.MustCompile(`(/[A-Za-z0-9_\-./{}<>]*)\?[^\s"'<>]+`)
	redactEmailPattern = regexp.MustCompile(`[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}`)
	redactBearer       = regexp.MustCompile(`(?i)\b(bearer|basic)\s+[A-Za-z0-9._~+/\-]+=*`)
	redactSecretPair   = regexp.MustCompile(`(?i)\b(access_token|refresh_token|id_token|token|api[_-]?key|secret|password|passwd|authorization|otp)(["']?\s*[:=]\s*["']?)[^\s"',;&}]+`)
	redactJWT          = regexp.MustCompile(`\beyJ[A-Za-z0-9_\-]{5,}\.[A-Za-z0-9_\-]{5,}\.[A-Za-z0-9_\-]{5,}\b`)
	redactUUID         = regexp.MustCompile(`(?i)\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b`)
	redactIPv4         = regexp.MustCompile(`\b(?:25[0-5]|2[0-4]\d|1?\d?\d)(?:\.(?:25[0-5]|2[0-4]\d|1?\d?\d)){3}\b`)
	redactCard         = regexp.MustCompile(`\b(?:\d[ \-]?){12,18}\d\b`)
	redactPhone        = regexp.MustCompile(`(?:\+\d|\(\d|\b\d)[\d\s.\-()]{5,18}\d\b`)
	redactISODate      = regexp.MustCompile(`\d{4}-\d{2}-\d{2}`)
	redactLongToken    = regexp.MustCompile(`\b[A-Za-z0-9_\-+/]{32,}={0,2}`)
	redactLongHex      = regexp.MustCompile(`(?i)\b[0-9a-f]{24,}\b`)

	pathIDLike = regexp.MustCompile(`(?i)^(?:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}|\+?\d[\d\-]*|[0-9a-f]{16,}|.*@.*)$`)
	// Segments a client or RedactText already replaced collapse to "{id}" too.
	redactedPlaceholders = map[string]bool{RedactedID: true, RedactedToken: true, RedactedEmail: true, RedactedPhone: true, RedactedNumber: true, RedactedIP: true}
	pathOpaqueToken      = regexp.MustCompile(`^[A-Za-z0-9_\-]{20,}$`)
)

// RedactText removes personal data and secrets from free text such as an
// error message, a stack trace or a breadcrumb. The order matters: URLs lose
// their query strings before tokens inside them are matched, and e-mail
// addresses are replaced before the phone pattern could match their digits.
func RedactText(value string) string {
	if value == "" {
		return value
	}
	out := redactURLPattern.ReplaceAllString(value, "$1")
	out = redactQueryPattern.ReplaceAllString(out, "$1")
	out = redactEmailPattern.ReplaceAllString(out, RedactedEmail)
	out = redactJWT.ReplaceAllString(out, RedactedToken)
	out = redactBearer.ReplaceAllString(out, "$1 "+RedactedToken)
	out = redactSecretPair.ReplaceAllString(out, "$1$2"+RedactedToken)
	out = redactUUID.ReplaceAllString(out, RedactedID)
	out = redactIPv4.ReplaceAllString(out, RedactedIP)
	out = redactLongHex.ReplaceAllString(out, RedactedToken)
	out = redactLongToken.ReplaceAllStringFunc(out, func(match string) string {
		// Dotted Dart/Java package paths and file paths are long but are not
		// secrets; only collapse runs that look like opaque tokens.
		if strings.Count(match, "/") > 1 || !hasMixedTokenAlphabet(match) {
			return match
		}
		return RedactedToken
	})
	out = redactCard.ReplaceAllString(out, RedactedNumber)
	out = redactPhone.ReplaceAllStringFunc(out, func(match string) string {
		digits := 0
		for _, r := range match {
			if r >= '0' && r <= '9' {
				digits++
			}
		}
		if digits < 7 || digits > 15 || redactISODate.MatchString(match) {
			return match
		}
		return RedactedPhone
	})
	return out
}

func hasMixedTokenAlphabet(value string) bool {
	var upper, lower, digit bool
	for _, r := range value {
		switch {
		case r >= 'A' && r <= 'Z':
			upper = true
		case r >= 'a' && r <= 'z':
			lower = true
		case r >= '0' && r <= '9':
			digit = true
		}
	}
	return digit && (upper || lower)
}

// StripPathIDs replaces id-like path segments (uuids, numbers, long hex or
// opaque tokens, e-mail addresses, phone numbers) with "{id}" and drops any
// query string or fragment.
func StripPathIDs(path string) string {
	if cut := strings.IndexAny(path, "?#"); cut >= 0 {
		path = path[:cut]
	}
	if path == "" {
		return path
	}
	segments := strings.Split(path, "/")
	for i, segment := range segments {
		if segment == "" {
			continue
		}
		if pathIDLike.MatchString(segment) || (pathOpaqueToken.MatchString(segment) && hasMixedTokenAlphabet(segment)) ||
			redactedPlaceholders[segment] {
			segments[i] = pathIDSegment
		}
	}
	return strings.Join(segments, "/")
}

// RedactedRequestPath is the path to log for a request: the matched chi route
// template ("/v1/profile/{userID}") when routing has happened, otherwise the
// raw path with id-like segments replaced. Never includes the query string.
func RedactedRequestPath(r *http.Request) string {
	if r == nil {
		return ""
	}
	if ctx := chi.RouteContext(r.Context()); ctx != nil {
		if pattern := strings.TrimSpace(ctx.RoutePattern()); pattern != "" && pattern != "/*" {
			return pattern
		}
	}
	if r.URL == nil {
		return ""
	}
	return StripPathIDs(r.URL.Path)
}

var (
	pseudonymKeyOnce sync.Once
	pseudonymKey     []byte
)

// pseudonymSecret is LOG_PSEUDONYM_KEY when set (so pseudonyms are stable
// across instances and restarts), otherwise a random per-process key: logs
// from one process can still be correlated, but a pseudonym cannot be
// reversed by hashing guessed phone numbers.
func pseudonymSecret() []byte {
	pseudonymKeyOnce.Do(func() {
		if configured := strings.TrimSpace(os.Getenv("LOG_PSEUDONYM_KEY")); configured != "" {
			pseudonymKey = []byte(configured)
			return
		}
		pseudonymKey = make([]byte, 32)
		if _, err := rand.Read(pseudonymKey); err != nil {
			pseudonymKey = []byte("verified-dating-log-pseudonym")
		}
	})
	return pseudonymKey
}

// PseudonymizeIdentifier returns a short keyed hash ("id_3fa4…") of an
// identifier such as a username, so log lines about the same login can be
// correlated without the identifier itself appearing in logs. Empty input
// stays empty. The value is case- and whitespace-normalised first.
func PseudonymizeIdentifier(value string) string {
	normalised := strings.ToLower(strings.TrimSpace(value))
	if normalised == "" {
		return ""
	}
	mac := hmac.New(sha256.New, pseudonymSecret())
	_, _ = mac.Write([]byte(normalised))
	return "id_" + hex.EncodeToString(mac.Sum(nil))[:16]
}
