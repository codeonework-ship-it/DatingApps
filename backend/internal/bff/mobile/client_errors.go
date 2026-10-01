package mobile

import (
	"context"
	"crypto/sha256"
	"database/sql"
	"encoding/hex"
	"encoding/json"
	"errors"
	"io"
	"net"
	"net/http"
	"regexp"
	"strconv"
	"strings"
	"sync"
	"time"
	"unicode/utf8"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"

	"github.com/verified-dating/backend/internal/platform/observability"
)

// Self-hosted client crash and error reporting (migration 122).
//
// The app posts batches of scrubbed error events to POST /v1/client/errors.
// Reports are anonymous by design: the server never stores an account id.
// A signed-in caller only gets the signed-in rate limits and a signed_in flag
// on the occurrence; anonymous callers (signed-out screens) are limited per IP,
// per install and globally. The random per-install id is stored only as a
// sha256 reporter key, used to count affected installs and to stop a crash
// loop from filling the occurrence table.
//
// The server never trusts the client's scrubbing or grouping: every text
// field is re-redacted (observability.RedactText) and the grouping
// fingerprint is computed here. Operators review issues through
// /v1/admin/client-errors (console page "Client errors").
//
// documents/CLIENT_ERROR_REPORTING_AND_PRIVACY_2026-10-01.md describes what is
// collected, how it is scrubbed, retention (90 days) and the member opt-out.

const (
	clientErrorMaxBodyBytes          = 64 << 10
	clientErrorMaxEvents             = 20
	clientErrorMaxMessageRunes       = 1000
	clientErrorMaxStackRunes         = 8000
	clientErrorMaxStackLines         = 50
	clientErrorMaxBreadcrumbs        = 20
	clientErrorMaxBreadcrumbRunes    = 200
	clientErrorMaxStoredOccurrences  = 50
	clientErrorLoopSuppressionWindow = 5 * time.Minute
	clientErrorMaxEventAge           = 7 * 24 * time.Hour
	clientErrorMaxClockSkew          = time.Hour
)

var (
	clientErrorPlatforms    = map[string]bool{"android": true, "ios": true, "web": true, "macos": true, "windows": true, "linux": true}
	clientErrorDeviceClass  = map[string]bool{"phone": true, "tablet": true, "desktop": true, "web": true, "unknown": true}
	clientErrorSources      = map[string]bool{"flutter": true, "platform": true, "zone": true, "logger": true, "unknown": true}
	clientErrorCrumbKinds   = map[string]bool{"navigation": true, "api": true, "lifecycle": true, "ui": true}
	clientErrorStatuses     = map[string]bool{"open": true, "resolved": true, "ignored": true}
	clientErrorInstallID    = regexp.MustCompile(`^[A-Za-z0-9_\-]{16,64}$`)
	clientErrorAppVersion   = regexp.MustCompile(`^[0-9A-Za-z][0-9A-Za-z.+\-]{0,31}$`)
	clientErrorBuildNumber  = regexp.MustCompile(`^[0-9A-Za-z.\-]{0,16}$`)
	clientErrorLocale       = regexp.MustCompile(`^[A-Za-z]{2,3}(?:[_\-][A-Za-z0-9]{2,8}){0,2}$`)
	clientErrorFrameNumbers = regexp.MustCompile(`:\d+(?::\d+)?`)
	clientErrorFrameIndex   = regexp.MustCompile(`^#\d+\s+`)
	clientErrorHexAddress   = regexp.MustCompile(`(?i)0x[0-9a-f]+`)
	clientErrorDigits       = regexp.MustCompile(`\d+`)
)

var (
	clientErrorsTotal = promauto.NewCounterVec(prometheus.CounterOpts{
		Namespace: "verified_dating",
		Subsystem: "client",
		Name:      "errors_total",
		Help:      "Client crash/error events accepted from the apps, by platform and fatal flag.",
	}, []string{"platform", "fatal"})
	clientErrorsRejected = promauto.NewCounterVec(prometheus.CounterOpts{
		Namespace: "verified_dating",
		Subsystem: "client",
		Name:      "error_reports_rejected_total",
		Help:      "Client error reports or events rejected, by reason.",
	}, []string{"reason"})
)

type clientErrorBreadcrumbInput struct {
	At       string `json:"at"`
	Category string `json:"category"`
	Message  string `json:"message"`
}

type clientErrorEventInput struct {
	Fingerprint string                       `json:"fingerprint"`
	ErrorType   string                       `json:"error_type"`
	Message     string                       `json:"message"`
	Stack       string                       `json:"stack"`
	Fatal       bool                         `json:"fatal"`
	Handled     bool                         `json:"handled"`
	Source      string                       `json:"source"`
	AppVersion  string                       `json:"app_version"`
	BuildNumber string                       `json:"build_number"`
	Platform    string                       `json:"platform"`
	OSVersion   string                       `json:"os_version"`
	DeviceClass string                       `json:"device_class"`
	Locale      string                       `json:"locale"`
	Screen      string                       `json:"screen"`
	Breadcrumbs []clientErrorBreadcrumbInput `json:"breadcrumbs"`
	OccurredAt  string                       `json:"occurred_at"`
}

type clientErrorBatchInput struct {
	InstallID string                  `json:"install_id"`
	Events    []clientErrorEventInput `json:"events"`
}

type clientErrorBreadcrumb struct {
	At       string `json:"at,omitempty"`
	Category string `json:"category"`
	Message  string `json:"message"`
}

// clientErrorEvent is a validated, scrubbed event ready to store.
type clientErrorEvent struct {
	Fingerprint string
	ErrorType   string
	Title       string
	Culprit     string
	Message     string
	Stack       string
	Fatal       bool
	Handled     bool
	Source      string
	AppVersion  string
	BuildNumber string
	Platform    string
	OSVersion   string
	DeviceClass string
	Locale      string
	Screen      string
	Breadcrumbs []clientErrorBreadcrumb
	OccurredAt  time.Time
}

var errClientErrorEventInvalid = errors.New("client error event is invalid")

func truncateRunes(value string, limit int) string {
	if limit <= 0 || utf8.RuneCountInString(value) <= limit {
		return value
	}
	runes := []rune(value)
	return string(runes[:limit])
}

// scrubClientText re-applies server-side redaction and strips control
// characters other than newlines and tabs.
func scrubClientText(value string, limit int) string {
	value = strings.Map(func(r rune) rune {
		if r == '\n' || r == '\t' {
			return r
		}
		if r < 0x20 || r == 0x7f {
			return -1
		}
		return r
	}, value)
	return truncateRunes(strings.TrimSpace(observability.RedactText(value)), limit)
}

func scrubClientStack(stack string) string {
	lines := strings.Split(strings.ReplaceAll(stack, "\r\n", "\n"), "\n")
	kept := make([]string, 0, clientErrorMaxStackLines)
	for _, line := range lines {
		if strings.TrimSpace(line) == "" {
			continue
		}
		kept = append(kept, line)
		if len(kept) == clientErrorMaxStackLines {
			break
		}
	}
	return scrubClientText(strings.Join(kept, "\n"), clientErrorMaxStackRunes)
}

// normaliseClientFrame reduces a stack frame to "function (file)" so the
// same fault groups together across builds whose line numbers moved.
func normaliseClientFrame(line string) string {
	line = strings.TrimSpace(line)
	line = clientErrorFrameIndex.ReplaceAllString(line, "")
	line = clientErrorHexAddress.ReplaceAllString(line, "")
	line = clientErrorFrameNumbers.ReplaceAllString(line, "")
	return strings.Join(strings.Fields(line), " ")
}

func isFrameworkFrame(frame string) bool {
	lower := strings.ToLower(frame)
	for _, prefix := range []string{"package:flutter/", "dart:", "package:flutter_test/", "package:riverpod", "package:flutter_riverpod/", "package:go_router/", "package:dio/", "<asynchronous suspension>"} {
		if strings.Contains(lower, prefix) {
			return true
		}
	}
	return false
}

// clientErrorFrames returns up to five normalised frames, preferring the
// app's own code over framework frames, and the culprit (first app frame).
func clientErrorFrames(stack string) ([]string, string) {
	var appFrames, allFrames []string
	for _, line := range strings.Split(stack, "\n") {
		frame := normaliseClientFrame(line)
		if frame == "" {
			continue
		}
		if len(allFrames) < 5 {
			allFrames = append(allFrames, frame)
		}
		if !isFrameworkFrame(frame) && len(appFrames) < 5 {
			appFrames = append(appFrames, frame)
		}
	}
	culprit := ""
	if len(appFrames) > 0 {
		culprit = appFrames[0]
	} else if len(allFrames) > 0 {
		culprit = allFrames[0]
	}
	if len(appFrames) > 0 {
		return appFrames, culprit
	}
	return allFrames, culprit
}

// clientErrorFingerprint groups events by error type, the message with
// numbers normalised, and the top frames without line numbers. Platform and
// app version are deliberately not part of it: the same fault on Android and
// iOS, or across releases, is one issue (tracked per version separately).
func clientErrorFingerprint(errorType, message, stack string) (string, string) {
	frames, culprit := clientErrorFrames(stack)
	firstLine := strings.SplitN(message, "\n", 2)[0]
	normalised := clientErrorDigits.ReplaceAllString(truncateRunes(firstLine, 200), "#")
	digest := sha256.Sum256([]byte(strings.ToLower(errorType) + "\x1f" + normalised + "\x1f" + strings.Join(frames, "\x1e")))
	return hex.EncodeToString(digest[:]), culprit
}

func normaliseClientErrorEvent(in clientErrorEventInput, now time.Time) (clientErrorEvent, string) {
	errorType := scrubClientText(in.ErrorType, 120)
	if errorType == "" {
		return clientErrorEvent{}, "missing_error_type"
	}
	platform := strings.ToLower(strings.TrimSpace(in.Platform))
	if !clientErrorPlatforms[platform] {
		return clientErrorEvent{}, "invalid_platform"
	}
	appVersion := strings.TrimSpace(in.AppVersion)
	if !clientErrorAppVersion.MatchString(appVersion) {
		return clientErrorEvent{}, "invalid_app_version"
	}
	occurredAt, err := time.Parse(time.RFC3339, strings.TrimSpace(in.OccurredAt))
	switch {
	case err != nil:
		occurredAt = now
	case occurredAt.Before(now.Add(-clientErrorMaxEventAge)):
		return clientErrorEvent{}, "stale"
	case occurredAt.After(now.Add(clientErrorMaxClockSkew)):
		occurredAt = now
	}

	event := clientErrorEvent{
		ErrorType:   errorType,
		Message:     scrubClientText(in.Message, clientErrorMaxMessageRunes),
		Stack:       scrubClientStack(in.Stack),
		Fatal:       in.Fatal,
		Handled:     in.Handled,
		Source:      strings.ToLower(strings.TrimSpace(in.Source)),
		AppVersion:  appVersion,
		BuildNumber: strings.TrimSpace(in.BuildNumber),
		Platform:    platform,
		OSVersion:   scrubClientText(in.OSVersion, 64),
		DeviceClass: strings.ToLower(strings.TrimSpace(in.DeviceClass)),
		Locale:      strings.TrimSpace(in.Locale),
		Screen:      truncateRunes(observability.StripPathIDs(scrubClientText(in.Screen, 240)), 120),
		OccurredAt:  occurredAt.UTC(),
	}
	if !clientErrorSources[event.Source] {
		event.Source = "unknown"
	}
	if !clientErrorBuildNumber.MatchString(event.BuildNumber) {
		event.BuildNumber = ""
	}
	if !clientErrorDeviceClass[event.DeviceClass] {
		event.DeviceClass = "unknown"
	}
	if !clientErrorLocale.MatchString(event.Locale) || len(event.Locale) > 16 {
		event.Locale = ""
	}

	crumbs := in.Breadcrumbs
	if len(crumbs) > clientErrorMaxBreadcrumbs {
		crumbs = crumbs[len(crumbs)-clientErrorMaxBreadcrumbs:]
	}
	event.Breadcrumbs = make([]clientErrorBreadcrumb, 0, len(crumbs))
	for _, crumb := range crumbs {
		category := strings.ToLower(strings.TrimSpace(crumb.Category))
		if !clientErrorCrumbKinds[category] {
			category = "ui"
		}
		message := scrubClientText(crumb.Message, clientErrorMaxBreadcrumbRunes*2)
		if category == "navigation" || category == "api" {
			message = stripIDsInText(message)
		}
		message = truncateRunes(message, clientErrorMaxBreadcrumbRunes)
		if message == "" {
			continue
		}
		at := ""
		if parsed, err := time.Parse(time.RFC3339, strings.TrimSpace(crumb.At)); err == nil {
			at = parsed.UTC().Format(time.RFC3339)
		}
		event.Breadcrumbs = append(event.Breadcrumbs, clientErrorBreadcrumb{At: at, Category: category, Message: message})
	}

	event.Fingerprint, event.Culprit = clientErrorFingerprint(event.ErrorType, event.Message, event.Stack)
	event.Culprit = truncateRunes(event.Culprit, 300)
	title := event.ErrorType
	if first := strings.TrimSpace(strings.SplitN(event.Message, "\n", 2)[0]); first != "" {
		title += ": " + first
	}
	event.Title = truncateRunes(title, 300)
	return event, ""
}

// stripIDsInText replaces id-like segments of any path-looking token in a
// breadcrumb ("GET /v1/profile/42 -> 200").
func stripIDsInText(message string) string {
	fields := strings.Fields(message)
	for i, field := range fields {
		if strings.Contains(field, "/") {
			fields[i] = observability.StripPathIDs(field)
		}
	}
	return strings.Join(fields, " ")
}

func clientErrorReporterKey(installID string) string {
	digest := sha256.Sum256([]byte("client-error-install:" + installID))
	return hex.EncodeToString(digest[:])
}

// ── Abuse controls ────────────────────────────────────────────────────────

// clientErrorRateLimiter is a fixed-window counter per key, held in memory.
// Keys are hashed; nothing here is persisted. With several BFF replicas the
// effective limit is per replica, which is acceptable for a telemetry sink.
type clientErrorRateLimiter struct {
	mu        sync.Mutex
	now       func() time.Time
	windows   map[string]*clientErrorWindow
	lastSweep time.Time
}

type clientErrorWindow struct {
	start time.Time
	count int
}

type clientErrorRateRule struct {
	key    string
	limit  int
	window time.Duration
}

// Events per window. A batch counts as its number of events.
const (
	clientErrorSignedInLimit  = 120 // per account per 10 minutes
	clientErrorAnonIPLimit    = 60  // per client IP per 10 minutes (signed out)
	clientErrorInstallLimit   = 60  // per install per 10 minutes
	clientErrorAnonGlobal     = 3000
	clientErrorPerKeyWindow   = 10 * time.Minute
	clientErrorGlobalWindow   = time.Minute
	clientErrorLimiterMaxKeys = 100000
)

func newClientErrorRateLimiter(now func() time.Time) *clientErrorRateLimiter {
	if now == nil {
		now = time.Now
	}
	return &clientErrorRateLimiter{now: now, windows: map[string]*clientErrorWindow{}}
}

// allow admits cost events only if every rule has room; nothing is consumed
// when any rule would be exceeded. It returns the wait before retrying.
func (l *clientErrorRateLimiter) allow(rules []clientErrorRateRule, cost int) (bool, time.Duration) {
	l.mu.Lock()
	defer l.mu.Unlock()
	now := l.now()
	if now.Sub(l.lastSweep) > time.Minute || len(l.windows) > clientErrorLimiterMaxKeys {
		for key, window := range l.windows {
			if now.Sub(window.start) > clientErrorPerKeyWindow {
				delete(l.windows, key)
			}
		}
		l.lastSweep = now
	}
	var wait time.Duration
	for _, rule := range rules {
		window := l.windows[rule.key]
		if window == nil || now.Sub(window.start) >= rule.window {
			continue
		}
		if window.count+cost > rule.limit {
			if remaining := rule.window - now.Sub(window.start); remaining > wait {
				wait = remaining
			}
		}
	}
	if wait > 0 {
		return false, wait
	}
	for _, rule := range rules {
		window := l.windows[rule.key]
		if window == nil || now.Sub(window.start) >= rule.window {
			window = &clientErrorWindow{start: now}
			l.windows[rule.key] = window
		}
		window.count += cost
	}
	return true, 0
}

var clientErrorLimiters sync.Map // *Server -> *clientErrorRateLimiter

func (s *Server) clientErrorLimiter() *clientErrorRateLimiter {
	value, _ := clientErrorLimiters.LoadOrStore(s, newClientErrorRateLimiter(time.Now))
	return value.(*clientErrorRateLimiter)
}

// clientIPForRateLimit is the address the gateway saw: the right-most
// X-Forwarded-For entry (appended by our gateway's reverse proxy), else the
// connection address. Used only as an in-memory rate-limit key, never stored
// or logged.
func clientIPForRateLimit(r *http.Request) string {
	if forwarded := strings.TrimSpace(r.Header.Get("X-Forwarded-For")); forwarded != "" {
		parts := strings.Split(forwarded, ",")
		if candidate := strings.TrimSpace(parts[len(parts)-1]); candidate != "" {
			return candidate
		}
	}
	host, _, err := net.SplitHostPort(strings.TrimSpace(r.RemoteAddr))
	if err != nil {
		return strings.TrimSpace(r.RemoteAddr)
	}
	return host
}

func hashedLimiterKey(prefix, value string) string {
	digest := sha256.Sum256([]byte(value))
	return prefix + hex.EncodeToString(digest[:12])
}

// ── Ingestion endpoint ────────────────────────────────────────────────────

func (s *Server) clientErrorDB() (*sql.DB, error) {
	if s.store == nil || s.store.profileRepo == nil || s.store.profileRepo.pg == nil {
		return nil, errors.New("client error reporting persistence is unavailable")
	}
	return s.store.profileRepo.pg, nil
}

// optionalClientPrincipal resolves the bearer session when one is sent. An
// expired or invalid token is not an error here: crashes often happen right
// when a session lapses, and the report is anonymous either way.
func (s *Server) optionalClientPrincipal(r *http.Request) (securityPrincipal, bool) {
	if strings.TrimSpace(r.Header.Get("Authorization")) == "" {
		return securityPrincipal{}, false
	}
	resolve := s.principalResolver()
	if resolve == nil {
		return securityPrincipal{}, false
	}
	principal, err := resolve(r)
	if err != nil || strings.TrimSpace(principal.UserID) == "" {
		return securityPrincipal{}, false
	}
	return principal, true
}

func (s *Server) reportClientErrors(w http.ResponseWriter, r *http.Request) {
	// A public route keeps whatever identity headers the caller sent; this
	// handler never reads them, and dropping them keeps the request telemetry
	// from attributing an anonymous report to a member the caller named.
	r.Header.Del("X-User-ID")
	r.Header.Del("X-Admin-User")
	r.Body = http.MaxBytesReader(w, r.Body, clientErrorMaxBodyBytes)
	raw, err := io.ReadAll(r.Body)
	if err != nil {
		var tooLarge *http.MaxBytesError
		if errors.As(err, &tooLarge) {
			clientErrorsRejected.WithLabelValues("too_large").Inc()
			writeError(w, http.StatusRequestEntityTooLarge, errors.New("client error report exceeds 64 KB"))
			return
		}
		writeError(w, http.StatusBadRequest, errors.New("unable to read client error report"))
		return
	}
	var batch clientErrorBatchInput
	if err := json.Unmarshal(raw, &batch); err != nil {
		clientErrorsRejected.WithLabelValues("malformed").Inc()
		writeError(w, http.StatusBadRequest, errors.New("client error report must be a JSON object with install_id and events"))
		return
	}
	installID := strings.TrimSpace(batch.InstallID)
	if !clientErrorInstallID.MatchString(installID) {
		clientErrorsRejected.WithLabelValues("invalid_install_id").Inc()
		writeError(w, http.StatusBadRequest, errors.New("install_id must be 16-64 characters of letters, digits, '-' or '_'"))
		return
	}
	if len(batch.Events) == 0 || len(batch.Events) > clientErrorMaxEvents {
		clientErrorsRejected.WithLabelValues("invalid_batch_size").Inc()
		writeError(w, http.StatusBadRequest, errors.New("a report carries between 1 and 20 events"))
		return
	}

	principal, signedIn := s.optionalClientPrincipal(r)
	rules := []clientErrorRateRule{{key: hashedLimiterKey("install:", installID), limit: clientErrorInstallLimit, window: clientErrorPerKeyWindow}}
	if signedIn {
		rules = append(rules, clientErrorRateRule{key: hashedLimiterKey("user:", principal.UserID), limit: clientErrorSignedInLimit, window: clientErrorPerKeyWindow})
	} else {
		rules = append(rules,
			clientErrorRateRule{key: hashedLimiterKey("ip:", clientIPForRateLimit(r)), limit: clientErrorAnonIPLimit, window: clientErrorPerKeyWindow},
			clientErrorRateRule{key: "anonymous:global", limit: clientErrorAnonGlobal, window: clientErrorGlobalWindow},
		)
	}
	if ok, wait := s.clientErrorLimiter().allow(rules, len(batch.Events)); !ok {
		clientErrorsRejected.WithLabelValues("rate_limited").Inc()
		seconds := int(wait.Seconds() + 0.999)
		if seconds < 1 {
			seconds = 1
		}
		w.Header().Set("Retry-After", strconv.Itoa(seconds))
		writeError(w, http.StatusTooManyRequests, errors.New("too many client error reports; retry later"))
		return
	}

	now := time.Now().UTC()
	events := make([]clientErrorEvent, 0, len(batch.Events))
	dropped := 0
	for _, input := range batch.Events {
		event, reason := normaliseClientErrorEvent(input, now)
		if reason != "" {
			clientErrorsRejected.WithLabelValues(reason).Inc()
			dropped++
			continue
		}
		events = append(events, event)
	}
	if len(events) == 0 {
		writeJSON(w, http.StatusAccepted, map[string]any{"success": true, "accepted": 0, "dropped": dropped})
		return
	}

	db, err := s.clientErrorDB()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	timeout := s.cfg.BFFRequestTimeout()
	if timeout <= 0 {
		timeout = 10 * time.Second
	}
	ctx, cancel := context.WithTimeout(r.Context(), timeout)
	defer cancel()
	if err := ingestClientErrors(ctx, db, events, clientErrorReporterKey(installID), signedIn, now); err != nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("client error reports could not be stored"))
		return
	}
	for _, event := range events {
		clientErrorsTotal.WithLabelValues(event.Platform, strconv.FormatBool(event.Fatal)).Inc()
	}
	writeJSON(w, http.StatusAccepted, map[string]any{"success": true, "accepted": len(events), "dropped": dropped})
}

// compareAppVersions orders dotted versions numerically ("1.10.0" > "1.9.3").
// Build metadata after '+' is ignored; non-numeric parts compare as text.
func compareAppVersions(a, b string) int {
	split := func(value string) []string {
		value = strings.SplitN(strings.TrimSpace(value), "+", 2)[0]
		return strings.FieldsFunc(value, func(r rune) bool { return r == '.' || r == '-' })
	}
	left, right := split(a), split(b)
	for i := 0; i < len(left) || i < len(right); i++ {
		var l, r string
		if i < len(left) {
			l = left[i]
		}
		if i < len(right) {
			r = right[i]
		}
		ln, lErr := strconv.Atoi(l)
		rn, rErr := strconv.Atoi(r)
		switch {
		case l == r:
			continue
		case lErr == nil && rErr == nil:
			if ln < rn {
				return -1
			}
			if ln > rn {
				return 1
			}
		case l == "":
			return -1
		case r == "":
			return 1
		default:
			if l < r {
				return -1
			}
			return 1
		}
	}
	return 0
}

// ingestClientErrors stores one batch in a single transaction.
func ingestClientErrors(ctx context.Context, db *sql.DB, events []clientErrorEvent, reporterKey string, signedIn bool, now time.Time) error {
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer func() { _ = tx.Rollback() }()
	for _, event := range events {
		if err := ingestClientErrorEvent(ctx, tx, event, reporterKey, signedIn, now); err != nil {
			return err
		}
	}
	return tx.Commit()
}

func ingestClientErrorEvent(ctx context.Context, tx *sql.Tx, event clientErrorEvent, reporterKey string, signedIn bool, now time.Time) error {
	var (
		issueID           string
		status            string
		resolvedAt        sql.NullTime
		resolvedInVersion sql.NullString
	)
	if err := tx.QueryRowContext(ctx, `
		INSERT INTO platform.client_error_issues
		  (fingerprint,error_type,title,culprit,fatal,platforms,first_seen_at,last_seen_at,occurrence_count)
		VALUES ($1,$2,$3,$4,$5,ARRAY[$6]::text[],$7,$7,1)
		ON CONFLICT (fingerprint) DO UPDATE SET
		  occurrence_count = platform.client_error_issues.occurrence_count + 1,
		  last_seen_at = GREATEST(platform.client_error_issues.last_seen_at, EXCLUDED.last_seen_at),
		  fatal = platform.client_error_issues.fatal OR EXCLUDED.fatal,
		  platforms = CASE WHEN $6 = ANY(platform.client_error_issues.platforms)
		                   THEN platform.client_error_issues.platforms
		                   ELSE array_append(platform.client_error_issues.platforms, $6) END
		RETURNING id::text, status, resolved_at, resolved_in_version`,
		event.Fingerprint, event.ErrorType, event.Title, event.Culprit, event.Fatal, event.Platform, now,
	).Scan(&issueID, &status, &resolvedAt, &resolvedInVersion); err != nil {
		return err
	}

	// Regression: a resolved issue reported again by a version that should
	// contain the fix (>= resolved_in_version), or — when no fix version was
	// given — by a version that had not reported it before it was resolved.
	if status == "resolved" {
		var versionFirstSeen sql.NullTime
		err := tx.QueryRowContext(ctx, `
			SELECT first_seen_at FROM platform.client_error_issue_versions
			WHERE issue_id=$1::uuid AND app_version=$2 AND platform=$3`,
			issueID, event.AppVersion, event.Platform).Scan(&versionFirstSeen)
		if err != nil && !errors.Is(err, sql.ErrNoRows) {
			return err
		}
		regressed := false
		if resolvedInVersion.Valid && strings.TrimSpace(resolvedInVersion.String) != "" {
			regressed = compareAppVersions(event.AppVersion, resolvedInVersion.String) >= 0
		} else {
			regressed = !versionFirstSeen.Valid || (resolvedAt.Valid && versionFirstSeen.Time.After(resolvedAt.Time))
		}
		if regressed {
			if _, err := tx.ExecContext(ctx, `
				UPDATE platform.client_error_issues
				SET status='open', regressed=TRUE, regression_count=regression_count+1,
				    reopened_at=$2, resolved_at=NULL, resolved_in_version=NULL,
				    status_changed_at=$2, status_changed_by=NULL,
				    status_note=$3
				WHERE id=$1::uuid`,
				issueID, now, truncateRunes("Regression: reported again by "+event.Platform+" "+event.AppVersion+" after it was resolved.", 500)); err != nil {
				return err
			}
			status = "open"
		}
	}

	if _, err := tx.ExecContext(ctx, `
		INSERT INTO platform.client_error_issue_versions (issue_id,app_version,platform,occurrences,first_seen_at,last_seen_at)
		VALUES ($1::uuid,$2,$3,1,$4,$4)
		ON CONFLICT (issue_id,app_version,platform) DO UPDATE SET
		  occurrences = platform.client_error_issue_versions.occurrences + 1,
		  last_seen_at = GREATEST(platform.client_error_issue_versions.last_seen_at, EXCLUDED.last_seen_at)`,
		issueID, event.AppVersion, event.Platform, now); err != nil {
		return err
	}

	var newReporter bool
	if err := tx.QueryRowContext(ctx, `
		INSERT INTO platform.client_error_issue_reporters (issue_id,reporter_key,first_seen_at,last_seen_at)
		VALUES ($1::uuid,$2,$3,$3)
		ON CONFLICT (issue_id,reporter_key) DO UPDATE SET last_seen_at=EXCLUDED.last_seen_at
		RETURNING (xmax = 0)`, issueID, reporterKey, now).Scan(&newReporter); err != nil {
		return err
	}
	if newReporter {
		if _, err := tx.ExecContext(ctx, `UPDATE platform.client_error_issues SET affected_users=affected_users+1 WHERE id=$1::uuid`, issueID); err != nil {
			return err
		}
	}

	// Ignored issues keep counting but store no new occurrences, and one
	// install's crash loop stores at most one occurrence per window.
	if status == "ignored" {
		return nil
	}
	var recent bool
	if err := tx.QueryRowContext(ctx, `
		SELECT EXISTS(SELECT 1 FROM platform.client_error_occurrences
		              WHERE issue_id=$1::uuid AND reporter_key=$2 AND received_at > $3)`,
		issueID, reporterKey, now.Add(-clientErrorLoopSuppressionWindow)).Scan(&recent); err != nil {
		return err
	}
	if recent {
		return nil
	}
	breadcrumbs, err := json.Marshal(event.Breadcrumbs)
	if err != nil {
		return err
	}
	if _, err := tx.ExecContext(ctx, `
		INSERT INTO platform.client_error_occurrences
		  (issue_id,occurred_at,received_at,app_version,build_number,platform,os_version,device_class,
		   locale,screen,source,message,stack,breadcrumbs,fatal,handled,signed_in,reporter_key)
		VALUES ($1::uuid,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14::jsonb,$15,$16,$17,$18)`,
		issueID, event.OccurredAt, now, event.AppVersion, event.BuildNumber, event.Platform, event.OSVersion,
		event.DeviceClass, event.Locale, event.Screen, event.Source, event.Message, event.Stack,
		string(breadcrumbs), event.Fatal, event.Handled, signedIn, reporterKey); err != nil {
		return err
	}
	_, err = tx.ExecContext(ctx, `
		DELETE FROM platform.client_error_occurrences
		WHERE id IN (SELECT id FROM platform.client_error_occurrences
		             WHERE issue_id=$1::uuid ORDER BY received_at DESC, id DESC OFFSET $2)`,
		issueID, clientErrorMaxStoredOccurrences)
	return err
}

// ── Operator API ──────────────────────────────────────────────────────────

const clientErrorIssueColumns = `
	i.id::text, i.fingerprint, i.error_type, i.title, i.culprit, i.status, i.fatal, i.regressed,
	i.regression_count, i.occurrence_count, i.affected_users, COALESCE(array_to_json(i.platforms)::text,'[]'),
	i.first_seen_at, i.last_seen_at, i.resolved_at, i.resolved_in_version,
	i.status_changed_at, i.status_changed_by::text, i.status_note, i.reopened_at,
	COALESCE(array_to_json(ARRAY(SELECT v.app_version FROM platform.client_error_issue_versions v
	      WHERE v.issue_id=i.id GROUP BY v.app_version
	      ORDER BY MAX(v.last_seen_at) DESC, v.app_version DESC LIMIT 10))::text,'[]')`

type clientErrorRowScanner interface {
	Scan(dest ...any) error
}

func scanClientErrorIssue(row clientErrorRowScanner, extra ...any) (map[string]any, error) {
	var (
		id, fingerprint, errorType, title, culprit, status string
		fatal, regressed                                   bool
		regressionCount                                    int
		occurrences, affected                              int64
		platformsJSON, versionsJSON                        string
		firstSeen, lastSeen                                time.Time
		resolvedAt, statusChangedAt, reopenedAt            sql.NullTime
		resolvedIn, statusChangedBy, statusNote            sql.NullString
	)
	dest := []any{&id, &fingerprint, &errorType, &title, &culprit, &status, &fatal, &regressed,
		&regressionCount, &occurrences, &affected, &platformsJSON,
		&firstSeen, &lastSeen, &resolvedAt, &resolvedIn,
		&statusChangedAt, &statusChangedBy, &statusNote, &reopenedAt, &versionsJSON}
	if err := row.Scan(append(dest, extra...)...); err != nil {
		return nil, err
	}
	platforms, versions := []string{}, []string{}
	_ = json.Unmarshal([]byte(platformsJSON), &platforms)
	_ = json.Unmarshal([]byte(versionsJSON), &versions)
	return map[string]any{
		"id": id, "fingerprint": fingerprint, "error_type": errorType, "title": title, "culprit": culprit,
		"status": status, "fatal": fatal, "regressed": regressed, "regression_count": regressionCount,
		"occurrence_count": occurrences, "affected_users": affected, "platforms": platforms, "versions": versions,
		"first_seen_at": firstSeen.UTC().Format(time.RFC3339), "last_seen_at": lastSeen.UTC().Format(time.RFC3339),
		"resolved_at": nullableTimeText(resolvedAt), "resolved_in_version": nullableText(resolvedIn),
		"status_changed_at": nullableTimeText(statusChangedAt), "status_changed_by": nullableText(statusChangedBy),
		"status_note": nullableText(statusNote), "reopened_at": nullableTimeText(reopenedAt),
	}, nil
}

func nullableTimeText(value sql.NullTime) any {
	if !value.Valid {
		return nil
	}
	return value.Time.UTC().Format(time.RFC3339)
}

func nullableText(value sql.NullString) any {
	if !value.Valid {
		return nil
	}
	return value.String
}

func (s *Server) adminListClientErrors(w http.ResponseWriter, r *http.Request) {
	if _, err := requestPrincipal(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	db, err := s.clientErrorDB()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	query := r.URL.Query()
	status := strings.ToLower(strings.TrimSpace(query.Get("status")))
	switch {
	case status == "":
		status = "open"
	case status == "all":
		status = ""
	case !clientErrorStatuses[status]:
		writeError(w, http.StatusBadRequest, errors.New("status must be open, resolved, ignored or all"))
		return
	}
	platform := strings.ToLower(strings.TrimSpace(query.Get("platform")))
	if platform != "" && !clientErrorPlatforms[platform] {
		writeError(w, http.StatusBadRequest, errors.New("unknown platform"))
		return
	}
	version := strings.TrimSpace(query.Get("version"))
	if version != "" && !clientErrorAppVersion.MatchString(version) {
		writeError(w, http.StatusBadRequest, errors.New("invalid app version"))
		return
	}
	fatal := strings.ToLower(strings.TrimSpace(query.Get("fatal")))
	if fatal != "" && fatal != "true" && fatal != "false" {
		writeError(w, http.StatusBadRequest, errors.New("fatal must be true or false"))
		return
	}
	order := "i.last_seen_at DESC, i.id"
	switch strings.ToLower(strings.TrimSpace(query.Get("sort"))) {
	case "", "last_seen":
	case "count":
		order = "i.occurrence_count DESC, i.last_seen_at DESC, i.id"
	case "users":
		order = "i.affected_users DESC, i.last_seen_at DESC, i.id"
	default:
		writeError(w, http.StatusBadRequest, errors.New("sort must be last_seen, count or users"))
		return
	}
	limit := boundedQueryLimit(r, 50, 200)
	offset, _ := strconv.Atoi(strings.TrimSpace(query.Get("offset")))
	if offset < 0 {
		offset = 0
	}

	rows, err := db.QueryContext(r.Context(), `
		SELECT `+clientErrorIssueColumns+`, COUNT(*) OVER()
		FROM platform.client_error_issues i
		WHERE ($1='' OR i.status=$1)
		  AND ($2='' OR $2 = ANY(i.platforms))
		  AND ($3='' OR EXISTS(SELECT 1 FROM platform.client_error_issue_versions v
		                       WHERE v.issue_id=i.id AND v.app_version=$3 AND ($2='' OR v.platform=$2)))
		  AND ($4='' OR i.fatal=($4='true'))
		ORDER BY `+order+`
		LIMIT $5 OFFSET $6`, status, platform, version, fatal, limit, offset)
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	defer rows.Close()
	issues := make([]map[string]any, 0)
	total := int64(0)
	for rows.Next() {
		var count int64
		item, err := scanClientErrorIssue(rows, &count)
		if err != nil {
			writeError(w, http.StatusServiceUnavailable, err)
			return
		}
		total = count
		issues = append(issues, item)
	}
	if err := rows.Err(); err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	if len(issues) == 0 && offset > 0 {
		_ = db.QueryRowContext(r.Context(), `
			SELECT COUNT(*) FROM platform.client_error_issues i
			WHERE ($1='' OR i.status=$1) AND ($2='' OR $2 = ANY(i.platforms))
			  AND ($3='' OR EXISTS(SELECT 1 FROM platform.client_error_issue_versions v
			                       WHERE v.issue_id=i.id AND v.app_version=$3 AND ($2='' OR v.platform=$2)))
			  AND ($4='' OR i.fatal=($4='true'))`, status, platform, version, fatal).Scan(&total)
	}
	var open, resolved, ignored, fatalOpen int64
	if err := db.QueryRowContext(r.Context(), `
		SELECT COUNT(*) FILTER (WHERE status='open'), COUNT(*) FILTER (WHERE status='resolved'),
		       COUNT(*) FILTER (WHERE status='ignored'), COUNT(*) FILTER (WHERE status='open' AND fatal)
		FROM platform.client_error_issues`).Scan(&open, &resolved, &ignored, &fatalOpen); err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"success": true, "issues": issues, "total": total, "limit": limit, "offset": offset,
		"summary": map[string]any{"open": open, "resolved": resolved, "ignored": ignored, "fatal_open": fatalOpen},
	})
}

func loadClientErrorIssue(ctx context.Context, db *sql.DB, issueID string) (map[string]any, error) {
	row := db.QueryRowContext(ctx, `SELECT `+clientErrorIssueColumns+` FROM platform.client_error_issues i WHERE i.id=$1::uuid`, issueID)
	return scanClientErrorIssue(row)
}

func (s *Server) adminGetClientError(w http.ResponseWriter, r *http.Request) {
	if _, err := requestPrincipal(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	issueID := strings.TrimSpace(chi.URLParam(r, "issueID"))
	if _, err := uuid.Parse(issueID); err != nil {
		writeError(w, http.StatusNotFound, errors.New("client error issue not found"))
		return
	}
	db, err := s.clientErrorDB()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	issue, err := loadClientErrorIssue(r.Context(), db, issueID)
	if errors.Is(err, sql.ErrNoRows) {
		writeError(w, http.StatusNotFound, errors.New("client error issue not found"))
		return
	}
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}

	versions := make([]map[string]any, 0)
	versionRows, err := db.QueryContext(r.Context(), `
		SELECT app_version, platform, occurrences, first_seen_at, last_seen_at
		FROM platform.client_error_issue_versions WHERE issue_id=$1::uuid
		ORDER BY last_seen_at DESC, app_version DESC LIMIT 50`, issueID)
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	for versionRows.Next() {
		var appVersion, platform string
		var count int64
		var first, last time.Time
		if err := versionRows.Scan(&appVersion, &platform, &count, &first, &last); err != nil {
			versionRows.Close()
			writeError(w, http.StatusServiceUnavailable, err)
			return
		}
		versions = append(versions, map[string]any{
			"app_version": appVersion, "platform": platform, "occurrences": count,
			"first_seen_at": first.UTC().Format(time.RFC3339), "last_seen_at": last.UTC().Format(time.RFC3339),
		})
	}
	versionRows.Close()

	occurrences := make([]map[string]any, 0)
	occurrenceRows, err := db.QueryContext(r.Context(), `
		SELECT id::text, occurred_at, received_at, app_version, build_number, platform, os_version,
		       device_class, locale, screen, source, message, stack, breadcrumbs, fatal, handled, signed_in
		FROM platform.client_error_occurrences WHERE issue_id=$1::uuid
		ORDER BY received_at DESC, id DESC LIMIT 20`, issueID)
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	defer occurrenceRows.Close()
	for occurrenceRows.Next() {
		var (
			id, appVersion, build, platform, osVersion, deviceClass, locale, screen, source, message, stack string
			crumbsRaw                                                                                       []byte
			occurredAt, receivedAt                                                                          time.Time
			fatal, handled, signedIn                                                                        bool
		)
		if err := occurrenceRows.Scan(&id, &occurredAt, &receivedAt, &appVersion, &build, &platform, &osVersion,
			&deviceClass, &locale, &screen, &source, &message, &stack, &crumbsRaw, &fatal, &handled, &signedIn); err != nil {
			writeError(w, http.StatusServiceUnavailable, err)
			return
		}
		crumbs := []any{}
		_ = json.Unmarshal(crumbsRaw, &crumbs)
		occurrences = append(occurrences, map[string]any{
			"id": id, "occurred_at": occurredAt.UTC().Format(time.RFC3339), "received_at": receivedAt.UTC().Format(time.RFC3339),
			"app_version": appVersion, "build_number": build, "platform": platform, "os_version": osVersion,
			"device_class": deviceClass, "locale": locale, "screen": screen, "source": source,
			"message": message, "stack": stack, "breadcrumbs": crumbs,
			"fatal": fatal, "handled": handled, "signed_in": signedIn,
		})
	}
	if err := occurrenceRows.Err(); err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"success": true, "issue": issue, "versions": versions, "occurrences": occurrences})
}

func (s *Server) adminSetClientErrorStatus(w http.ResponseWriter, r *http.Request) {
	operator, err := authenticatedOperatorID(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	issueID := strings.TrimSpace(chi.URLParam(r, "issueID"))
	if _, err := uuid.Parse(issueID); err != nil {
		writeError(w, http.StatusNotFound, errors.New("client error issue not found"))
		return
	}
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	status := strings.ToLower(strings.TrimSpace(toString(payload["status"])))
	if !clientErrorStatuses[status] {
		writeError(w, http.StatusBadRequest, errors.New("status must be open, resolved or ignored"))
		return
	}
	resolvedIn := strings.TrimSpace(toString(payload["resolved_in_version"]))
	if resolvedIn != "" && (status != "resolved" || !clientErrorAppVersion.MatchString(resolvedIn)) {
		writeError(w, http.StatusBadRequest, errors.New("resolved_in_version must be a valid app version and only accompanies status resolved"))
		return
	}
	note := strings.TrimSpace(toString(payload["note"]))
	if utf8.RuneCountInString(note) > 500 {
		writeError(w, http.StatusBadRequest, errors.New("note is limited to 500 characters"))
		return
	}
	db, err := s.clientErrorDB()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	operatorID := any(nil)
	if _, parseErr := uuid.Parse(operator); parseErr == nil {
		operatorID = operator
	}
	result, err := db.ExecContext(r.Context(), `
		UPDATE platform.client_error_issues SET
		  status=$2,
		  resolved_at=CASE WHEN $2='resolved' THEN NOW() ELSE NULL END,
		  resolved_in_version=CASE WHEN $2='resolved' THEN NULLIF($3,'') ELSE NULL END,
		  regressed=CASE WHEN $2='open' THEN regressed ELSE FALSE END,
		  status_changed_at=NOW(), status_changed_by=$4::uuid, status_note=NULLIF($5,'')
		WHERE id=$1::uuid`, issueID, status, resolvedIn, operatorID, note)
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	if affected, _ := result.RowsAffected(); affected == 0 {
		writeError(w, http.StatusNotFound, errors.New("client error issue not found"))
		return
	}
	issue, err := loadClientErrorIssue(r.Context(), db, issueID)
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"success": true, "issue": issue})
}

// runClientTelemetryRetention applies the 90-day classes of migration 122.
func runClientTelemetryRetention(ctx context.Context, db *sql.DB, batch int) (apiRequests, occurrences, issues int, err error) {
	err = db.QueryRowContext(ctx, `SELECT * FROM platform.run_client_telemetry_retention($1)`, batch).
		Scan(&apiRequests, &occurrences, &issues)
	return
}
