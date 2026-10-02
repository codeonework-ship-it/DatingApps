package mobile

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

// API-06: the actor check only ran for Content-Type application/json, but
// readJSON decodes JSON whatever the header says. A member could like, send
// chat messages or act as another member by sending the same JSON as
// text/plain, with no Content-Type, labelled multipart, or followed by trailing
// bytes that json.Unmarshal rejected but the handler's decoder ignored.
func TestEnforceBodyIdentityIgnoresContentTypeAndTrailingData(t *testing.T) {
	const me = "11111111-1111-4111-8111-111111111111"
	const victim = "22222222-2222-4222-8222-222222222222"
	spoof := `{"user_id":"` + victim + `","target_user_id":"33333333-3333-4333-8333-333333333333","is_like":true}`

	cases := []struct {
		name        string
		contentType string
		body        string
	}{
		{"text/plain", "text/plain", spoof},
		{"no content type", "", spoof},
		{"form urlencoded label", "application/x-www-form-urlencoded", spoof},
		{"multipart label on a JSON body", "multipart/form-data; boundary=x", spoof},
		{"json with trailing bytes", "application/json", spoof + " trailing"},
		{"json with a second object", "application/json", spoof + `{"user_id":"` + me + `"}`},
		{"leading whitespace", "text/plain", "\n\t  " + spoof},
		{"case-folded key", "application/json", `{"User_ID":"` + victim + `"}`},
		{"chat requester", "application/json", `{"requester_user_id":"` + victim + `"}`},
		{"profile viewer", "text/plain", `{"viewer_user_id":"` + victim + `","viewed_user_id":"x"}`},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			req, err := http.NewRequest(http.MethodPost, "/v1/swipe", strings.NewReader(tc.body))
			if err != nil {
				t.Fatal(err)
			}
			if tc.contentType != "" {
				req.Header.Set("Content-Type", tc.contentType)
			}
			if err := enforceBodyIdentity(req, me); err == nil {
				t.Fatalf("a foreign actor in a %s body must be rejected", tc.name)
			}
			replayed, err := io.ReadAll(req.Body)
			if err != nil {
				t.Fatal(err)
			}
			if string(replayed) != tc.body {
				t.Fatalf("body was not replayed intact: %q", replayed)
			}
		})
	}
}

func TestEnforceBodyIdentityLeavesMultipartUploadsIntact(t *testing.T) {
	const me = "11111111-1111-4111-8111-111111111111"
	var buf bytes.Buffer
	writer := multipart.NewWriter(&buf)
	part, err := writer.CreateFormFile("image", "photo.png")
	if err != nil {
		t.Fatal(err)
	}
	// Bigger than the identity read limit, so the replay must stitch the
	// buffered prefix back onto the unread remainder.
	payload := bytes.Repeat([]byte{0x89, 'P', 'N', 'G'}, (securityRequestBodyLimit/4)+4096)
	if _, err := part.Write(payload); err != nil {
		t.Fatal(err)
	}
	if err := writer.Close(); err != nil {
		t.Fatal(err)
	}
	original := append([]byte(nil), buf.Bytes()...)

	req, err := http.NewRequest(http.MethodPost, "/v1/profile/"+me+"/photos", bytes.NewReader(original))
	if err != nil {
		t.Fatal(err)
	}
	req.Header.Set("Content-Type", writer.FormDataContentType())
	if err := enforceBodyIdentity(req, me); err != nil {
		t.Fatalf("a multipart upload must pass the identity check: %v", err)
	}
	if got := requestMatchID(req, "/v1", me); got != "" {
		t.Fatalf("a multipart upload has no match id, got %q", got)
	}
	replayed, err := io.ReadAll(req.Body)
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(replayed, original) {
		t.Fatalf("multipart body changed: got %d bytes, want %d", len(replayed), len(original))
	}
}

func TestEnforceBodyIdentityRefusesOversizedOrPaddedJSONWhateverTheHeader(t *testing.T) {
	const me = "11111111-1111-4111-8111-111111111111"
	for name, body := range map[string]string{
		"oversized object": `{"note":"` + strings.Repeat("a", securityRequestBodyLimit) + `"}`,
		"whitespace pad":   strings.Repeat(" ", securityRequestBodyLimit+1) + `{"user_id":"someone-else"}`,
	} {
		t.Run(name, func(t *testing.T) {
			req, err := http.NewRequest(http.MethodPost, "/v1/swipe", strings.NewReader(body))
			if err != nil {
				t.Fatal(err)
			}
			req.Header.Set("Content-Type", "text/plain")
			if err := enforceBodyIdentity(req, me); err == nil {
				t.Fatal("an over-limit JSON body must be refused, not waved through unchecked")
			}
		})
	}
}

func TestRequestMatchIDReadsBodyWhateverTheHeader(t *testing.T) {
	const me = "11111111-1111-4111-8111-111111111111"
	const matchID = "44444444-4444-4444-8444-444444444444"
	for _, contentType := range []string{"application/json", "text/plain", ""} {
		req, err := http.NewRequest(http.MethodPost, "/v1/activities/sessions/start",
			strings.NewReader(`{"match_id":"`+matchID+`","activity_type":"x"} trailing`))
		if err != nil {
			t.Fatal(err)
		}
		if contentType != "" {
			req.Header.Set("Content-Type", contentType)
		}
		if got := requestMatchID(req, "/v1", me); got != matchID {
			t.Fatalf("content type %q: requestMatchID = %q, want %q so ownership is checked", contentType, got, matchID)
		}
	}
}

func TestEnforceBodyIdentityStillAllowsOwnActorAndForeignTargets(t *testing.T) {
	const me = "11111111-1111-4111-8111-111111111111"
	for _, contentType := range []string{"application/json", "text/plain", ""} {
		req, err := http.NewRequest(http.MethodPost, "/v1/swipe",
			strings.NewReader(`{"user_id":"`+me+`","requester_user_id":"`+me+`","target_user_id":"someone-else"}`))
		if err != nil {
			t.Fatal(err)
		}
		if contentType != "" {
			req.Header.Set("Content-Type", contentType)
		}
		if err := enforceBodyIdentity(req, me); err != nil {
			t.Fatalf("content type %q: own actor must pass: %v", contentType, err)
		}
	}
}

// API-08: a malformed match id reached Postgres, failed the uuid cast and came
// back as 503 "temporarily unavailable". It names no match, so it is simply
// not the caller's (403), decided before any query runs.
func TestUserCanAccessMatchRejectsMalformedIDsWithoutQuerying(t *testing.T) {
	repo := &profileRepository{} // no database: a query would panic
	for _, matchID := range []string{"not-a-uuid", "' OR '1'='1", "gifts", "123"} {
		allowed, err := repo.userCanAccessMatch(context.Background(), "11111111-1111-4111-8111-111111111111", matchID)
		if err != nil || allowed {
			t.Fatalf("match id %q: allowed=%v err=%v, want false and no error", matchID, allowed, err)
		}
	}
}

// API-10: the app sends an Idempotency-Key on /auth/recovery-code/rotate, and
// the replay ledger stored the response — the display-once recovery code in
// plaintext — and served it again on replay. The rotation must stay out of the
// ledger while the other session mutations keep replay protection.
func TestRecoveryCodeRotationNeverEntersTheReplayLedger(t *testing.T) {
	s := &Server{}
	s.cfg.APIPrefix = "/v1"
	rotate, err := http.NewRequest(http.MethodPost, "/v1/auth/recovery-code/rotate", nil)
	if err != nil {
		t.Fatal(err)
	}
	if s.shouldApplyIdempotency(rotate) {
		t.Fatal("a display-once recovery code must not be cached for replay")
	}
	for _, path := range []string{"/v1/auth/logout", "/v1/auth/sessions/revoke", "/v1/auth/password/change"} {
		req, err := http.NewRequest(http.MethodPost, path, nil)
		if err != nil {
			t.Fatal(err)
		}
		if !s.shouldApplyIdempotency(req) {
			t.Fatalf("%s keeps replay protection", path)
		}
	}
}

// API-14: GET /v1/moderation/appeals honoured a user_id query naming another
// member, so anyone could list someone else's appeals (report ids, reasons).
func TestListModerationAppealsRefusesAnotherMembersID(t *testing.T) {
	s := &Server{} // the refusal happens before any store access
	req := httptest.NewRequest(http.MethodGet, "/v1/moderation/appeals?user_id=22222222-2222-4222-8222-222222222222", nil)
	req = req.WithContext(context.WithValue(req.Context(), securityPrincipalContextKey{},
		securityPrincipal{UserID: "11111111-1111-4111-8111-111111111111"}))
	w := httptest.NewRecorder()
	s.listModerationAppealsForUser(w, req)
	if w.Code != http.StatusForbidden {
		t.Fatalf("listing another member's appeals: got %d %s, want 403", w.Code, w.Body.String())
	}
}

// API-15: a member-fixable completion problem (bio over 500 characters, too
// few photos, missing basics, terms) came back as 502 "temporarily
// unavailable". It must stay recognisable through the application layer's
// wrapping so completeProfile answers 400.
func TestProfileCompletionProblemsAreTypedClientErrors(t *testing.T) {
	draft := profileDraft{Name: "Asha", DateOfBirth: "1994-08-03", Gender: "F",
		Bio: strings.Repeat("x", 501), Photos: []profilePhoto{{}, {}}, SeekingGenders: []string{"M"}}
	err := validateDraftReadyForCompletion(draft)
	if err == nil {
		t.Fatal("a 501-character bio must not complete")
	}
	wrapped := fmt.Errorf("complete profile failed: %w", err)
	var incomplete *profileCompletionError
	if !errors.As(wrapped, &incomplete) {
		t.Fatalf("completion problem lost its type through wrapping: %T %v", err, err)
	}
	draft.Bio = "Long enough bio for a profile."
	draft.Photos = nil
	if err = validateDraftReadyForCompletion(draft); !errors.As(err, &incomplete) {
		t.Fatalf("missing photos must be a typed completion problem, got %v", err)
	}
	if completionProblem(nil) != nil {
		t.Fatal("no problem must stay nil")
	}
}
