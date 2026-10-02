package mobile

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/go-chi/chi/v5"
)

func blockGuardRequest(t *testing.T, method, user, body string, params map[string]string) *http.Request {
	t.Helper()
	r := httptest.NewRequest(method, "/", strings.NewReader(body))
	r.Header.Set("Content-Type", "application/json")
	rc := chi.NewRouteContext()
	for k, v := range params {
		rc.URLParams.Add(k, v)
	}
	ctx := context.WithValue(r.Context(), chi.RouteCtxKey, rc)
	ctx = context.WithValue(ctx, securityPrincipalContextKey{}, securityPrincipal{UserID: user, Roles: map[string]bool{"user": true}})
	return r.WithContext(ctx)
}

func decodeGuardBody(t *testing.T, w *httptest.ResponseRecorder) map[string]any {
	t.Helper()
	out := map[string]any{}
	_ = json.Unmarshal(w.Body.Bytes(), &out)
	return out
}

// API-11: a block did not stop the blocked member messaging or gifting the
// member who blocked them inside an existing match. API-12: two likes across a
// block made a new match. API-13: a self-like reached the database CHECK and
// came back as 502.
func TestBlockedPairCannotMessageGiftOrMatchPostgres(t *testing.T) {
	f := newDatePlanFixture(t)
	s := blogServer(f)
	ctx := context.Background()
	if _, err := f.db.ExecContext(ctx, `INSERT INTO user_management.blocked_users (user_id, blocked_user_id, reason)
		VALUES ($1,$2,'api e2e regression')`, f.proposer, f.invitee); err != nil {
		t.Fatalf("seed block: %v", err)
	}
	t.Cleanup(func() {
		_, _ = f.db.ExecContext(ctx, `DELETE FROM user_management.blocked_users WHERE user_id=$1 AND blocked_user_id=$2`, f.proposer, f.invitee)
	})
	params := map[string]string{"matchID": f.matchID}

	// The blocked member (invitee) cannot write into the match, and neither can the blocker.
	for _, who := range []string{f.invitee, f.proposer} {
		w := httptest.NewRecorder()
		s.sendMessage(w, blockGuardRequest(t, http.MethodPost, who, `{"text":"hello?","sender_id":"`+who+`"}`, params))
		if body := decodeGuardBody(t, w); w.Code != http.StatusForbidden || body["error_code"] != "MATCH_BLOCKED" {
			t.Fatalf("chat send across a block: %d %v, want 403 MATCH_BLOCKED", w.Code, body)
		}
		w = httptest.NewRecorder()
		s.sendRoseGift(w, blockGuardRequest(t, http.MethodPost, who, `{"gift_id":"rose_red_single","sender_user_id":"`+who+`"}`, params))
		if body := decodeGuardBody(t, w); w.Code != http.StatusForbidden || body["error_code"] != "MATCH_BLOCKED" {
			t.Fatalf("gift send across a block: %d %v, want 403 MATCH_BLOCKED", w.Code, body)
		}
	}

	// Neither side can like the other while the block stands.
	for _, pair := range [][2]string{{f.invitee, f.proposer}, {f.proposer, f.invitee}} {
		w := httptest.NewRecorder()
		s.swipe(w, blockGuardRequest(t, http.MethodPost, pair[0],
			`{"user_id":"`+pair[0]+`","target_user_id":"`+pair[1]+`","is_like":true}`, nil))
		if body := decodeGuardBody(t, w); w.Code != http.StatusNotFound || body["error_code"] != "MEMBER_UNAVAILABLE" {
			t.Fatalf("like across a block: %d %v, want 404 MEMBER_UNAVAILABLE", w.Code, body)
		}
	}

	// A self-like is a client error, decided before the database.
	w := httptest.NewRecorder()
	s.swipe(w, blockGuardRequest(t, http.MethodPost, f.stranger,
		`{"user_id":"`+f.stranger+`","target_user_id":"`+f.stranger+`","is_like":true}`, nil))
	if w.Code != http.StatusBadRequest {
		t.Fatalf("self-like: %d %s, want 400", w.Code, w.Body.String())
	}

	// Unblocking restores the conversation.
	if _, err := f.db.ExecContext(ctx, `DELETE FROM user_management.blocked_users WHERE user_id=$1 AND blocked_user_id=$2`, f.proposer, f.invitee); err != nil {
		t.Fatal(err)
	}
	blocked, err := s.store.profileRepo.matchPairBlocked(ctx, f.matchID)
	if err != nil || blocked {
		t.Fatalf("after unblock the match must be writable again: blocked=%v err=%v", blocked, err)
	}
	if pairBlocked, err := s.store.profileRepo.pairBlocked(ctx, f.proposer, f.invitee); err != nil || pairBlocked {
		t.Fatalf("after unblock the pair may like again: blocked=%v err=%v", pairBlocked, err)
	}
}

// API-13: report/block/unblock mistakes (yourself, a malformed or unknown
// member, unblocking someone never blocked) were 502s.
func TestSafetyCommandMistakesAreClientErrors(t *testing.T) {
	const me = "11111111-1111-4111-8111-111111111111"
	if status, err := safetyPairProblem(me, me, "blocked_user_id"); status != http.StatusBadRequest || err == nil {
		t.Fatalf("self block/report: %d %v", status, err)
	}
	if status, err := safetyPairProblem(me, "not-a-uuid", "reported_user_id"); status != http.StatusBadRequest || err == nil {
		t.Fatalf("malformed target: %d %v", status, err)
	}
	if status, err := safetyPairProblem(me, "22222222-2222-4222-8222-222222222222", "blocked_user_id"); status != 0 || err != nil {
		t.Fatalf("a different member is fine: %d %v", status, err)
	}
	for raw, want := range map[string]int{
		"unblock user failed: block not found": http.StatusNotFound,
		`report user failed: ERROR: insert or update on table "user_reports" violates foreign key constraint "fk" (SQLSTATE 23503)`: http.StatusNotFound,
		"report user failed: cannot report yourself": http.StatusBadRequest,
	} {
		status, clientErr, ok := safetyCommandStatus(errors.New(raw))
		if !ok || status != want {
			t.Fatalf("%q: got %d ok=%v, want %d", raw, status, ok, want)
		}
		if strings.Contains(clientErr.Error(), "SQLSTATE") || strings.Contains(clientErr.Error(), "user_reports") {
			t.Fatalf("client message leaks database detail: %q", clientErr)
		}
	}
	if _, _, ok := safetyCommandStatus(errors.New("connection refused")); ok {
		t.Fatal("infrastructure faults stay 502")
	}
}

// API-16: the fourth emergency contact was refused with 502.
func TestFourthEmergencyContactIsAConflict(t *testing.T) {
	s := newContractTestServer(t)
	const me = "11111111-1111-4111-8111-111111111111"
	params := map[string]string{"userID": me}
	for i := 0; i < 3; i++ {
		w := httptest.NewRecorder()
		s.addEmergencyContact(w, blockGuardRequest(t, http.MethodPost, me, `{"name":"Contact","phone_number":"+447700900123"}`, params))
		if w.Code != http.StatusOK {
			t.Fatalf("contact %d: %d %s", i+1, w.Code, w.Body.String())
		}
	}
	w := httptest.NewRecorder()
	s.addEmergencyContact(w, blockGuardRequest(t, http.MethodPost, me, `{"name":"Fourth","phone_number":"+447700900124"}`, params))
	if w.Code != http.StatusConflict {
		t.Fatalf("fourth contact: %d %s, want 409", w.Code, w.Body.String())
	}
}

// API-20: an unknown trust badge code reached the repository and came back 502.
func TestUnknownTrustBadgeCodeIsABadRequest(t *testing.T) {
	s := newContractTestServer(t)
	const me = "11111111-1111-4111-8111-111111111111"
	w := httptest.NewRecorder()
	s.patchDiscoveryTrustFilter(w, blockGuardRequest(t, http.MethodPatch, me,
		`{"enabled":true,"required_badge_codes":["made_up"]}`, map[string]string{"userID": me}))
	if w.Code != http.StatusBadRequest {
		t.Fatalf("unknown badge code: %d %s, want 400", w.Code, w.Body.String())
	}
	w = httptest.NewRecorder()
	s.patchDiscoveryTrustFilter(w, blockGuardRequest(t, http.MethodPatch, me,
		`{"enabled":true,"required_badge_codes":["SHOWS_UP"]}`, map[string]string{"userID": me}))
	if w.Code != http.StatusOK {
		t.Fatalf("a known code in any case must save: %d %s", w.Code, w.Body.String())
	}
}

// API-21: a photo_ids list that misses or invents a photo was a 502.
func TestPhotoOrderProblemSurvivesWrapping(t *testing.T) {
	err := fmt.Errorf("reorder photos failed: %w", &photoOrderError{msg: "photo_ids must include every active photo"})
	var badOrder *photoOrderError
	if !errors.As(err, &badOrder) {
		t.Fatal("a photo order problem must stay recognisable so the handler answers 400")
	}
}
