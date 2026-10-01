package mobile

import (
	"context"
	"crypto/sha256"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/google/uuid"
)

func TestIntroducerRouteBoundary(t *testing.T) {
	p := securityPrincipal{UserID: "me", AccountKind: "introducer", TermsAccepted: true}
	for _, path := range []string{"/discovery/me", "/profile/other", "/profile/me/complete", "/friends/me", "/friends/me/activities", "/friends/me/plans", "/matches/me", "/chat/match/messages", "/auth/signup/bootstrap", "/account/me/dating-preferences", "/admin/users", "/realtime", "/notifications/me", "/friends/me/intros/123/decision"} {
		for _, method := range []string{"GET", "POST", "PATCH", "DELETE"} {
			if introducerRouteAllowed("/v1", method, "/v1"+path, p) {
				t.Fatalf("allowed %s %s", method, path)
			}
		}
	}
	for _, item := range [][2]string{{"GET", "/introducer/connections"}, {"POST", "/introducer/redeem"}, {"DELETE", "/introducer/connections/id"}, {"POST", "/friends/me/intros"}, {"GET", "/friends/me/intros"}, {"POST", "/account/me/export"}, {"POST", "/account/me/deletion"}, {"POST", "/auth/logout"}, {"PATCH", "/users/me/agreements/terms"}} {
		if !introducerRouteAllowed("/v1", item[0], "/v1"+item[1], p) {
			t.Fatalf("denied %v", item)
		}
	}
	p.TermsAccepted = false
	if introducerRouteAllowed("/v1", "POST", "/v1/introducer/redeem", p) {
		t.Fatal("terms bypass")
	}
}

func introducerFixture(t *testing.T) friendSocialFixture {
	f := newFriendSocialFixture(t)
	if _, err := f.db.Exec(`UPDATE user_management.users SET account_kind='introducer',gender=NULL,profile_completion=0,terms_accepted=TRUE WHERE id=$1`, f.introducer); err != nil {
		t.Fatal(err)
	}
	if _, err := f.db.Exec(`UPDATE user_management.users SET terms_accepted=TRUE,city='Pune' WHERE id IN($1,$2,$3)`, f.alice, f.bob, f.carol); err != nil {
		t.Fatal(err)
	}
	// No accepted friendship is required or created by friend-only consent.
	if _, err := f.db.Exec(`DELETE FROM matching.friend_connections WHERE user_id=$1 OR friend_user_id=$1`, f.introducer); err != nil {
		t.Fatal(err)
	}
	return f
}
func grantIntroducer(t *testing.T, f friendSocialFixture, member string, photo, city bool) string {
	t.Helper()
	ctx := context.Background()
	s := newFriendSocialService(f.db)
	invite, err := s.createIntroducerInvite(ctx, member, photo, city)
	if err != nil {
		t.Fatal(err)
	}
	if err = s.redeemIntroducerInvite(ctx, f.introducer, invite.Code); err != nil {
		t.Fatal(err)
	}
	var id string
	if err = f.db.QueryRow(`SELECT id::text FROM matching.introducer_consents WHERE introducer_user_id=$1 AND member_user_id=$2`, f.introducer, member).Scan(&id); err != nil {
		t.Fatal(err)
	}
	if err = s.changeIntroducerConsent(ctx, member, id, true); err != nil {
		t.Fatal(err)
	}
	return id
}
func TestIntroducerConsentLifecyclePostgres(t *testing.T) {
	f := introducerFixture(t)
	s := newFriendSocialService(f.db)
	ctx := context.Background()
	invite, err := s.createIntroducerInvite(ctx, f.alice, false, false)
	if err != nil {
		t.Fatal(err)
	}
	if err = s.redeemIntroducerInvite(ctx, f.alice, invite.Code); !errors.Is(err, errIntroducerConsent) {
		t.Fatalf("dating account redeemed: %v", err)
	}
	if err = s.redeemIntroducerInvite(ctx, f.introducer, invite.Code); err != nil {
		t.Fatal(err)
	}
	if err = s.redeemIntroducerInvite(ctx, f.introducer, invite.Code); err != nil {
		t.Fatalf("idempotent replay: %v", err)
	}
	connections, err := s.introducerConnections(ctx, f.introducer)
	if err != nil || len(connections) != 1 || connections[0].Status != "pending" {
		t.Fatalf("pending: %+v %v", connections, err)
	}
	if _, err = s.makeIntro(ctx, f.introducer, f.alice, f.bob, ""); !errors.Is(err, errIntroUnavailable) {
		t.Fatalf("unapproved introduced: %v", err)
	}
	consent := connections[0].ID
	if err = s.changeIntroducerConsent(ctx, f.introducer, consent, true); !errors.Is(err, errIntroducerConsent) {
		t.Fatal("introducer approved own permission")
	}
	if err = s.changeIntroducerConsent(ctx, f.stranger, consent, false); !errors.Is(err, errIntroducerConsent) {
		t.Fatal("outsider revoked")
	}
	if err = s.changeIntroducerConsent(ctx, f.alice, consent, true); err != nil {
		t.Fatal(err)
	}
	grantIntroducer(t, f, f.bob, true, true)
	intro, err := s.makeIntro(ctx, f.introducer, f.alice, f.bob, "You both love books.")
	if err != nil {
		t.Fatal(err)
	}
	received, _, err := s.listIntros(ctx, f.alice)
	if err != nil {
		t.Fatal(err)
	}
	if len(received) != 1 || received[0].Other == nil || len(received[0].Other.PhotoURLs) != 2 || received[0].Other.City != "Pune" {
		t.Fatalf("scoped photo/city missing: %+v", received)
	}
	received, _, err = s.listIntros(ctx, f.bob)
	if err != nil {
		t.Fatal(err)
	}
	if received[0].Other == nil || len(received[0].Other.PhotoURLs) != 0 || received[0].Other.City != "" {
		t.Fatal("unconsented photo/city disclosed")
	}
	if _, err = s.decideIntro(ctx, f.alice, intro.ID, "accept"); err != nil {
		t.Fatal(err)
	}
	if err = s.changeIntroducerConsent(ctx, f.alice, consent, false); err != nil {
		t.Fatal(err)
	}
	if err = s.changeIntroducerConsent(ctx, f.alice, consent, false); err != nil {
		t.Fatal("revoke not idempotent")
	}
	if err = s.redeemIntroducerInvite(ctx, f.introducer, invite.Code); !errors.Is(err, errIntroducerConsent) {
		t.Fatal("replay restored revoked consent")
	}
	if _, err = s.decideIntro(ctx, f.bob, intro.ID, "accept"); !errors.Is(err, errIntroNotOpen) {
		t.Fatalf("accept after revoke: %v", err)
	}
	received, _, err = s.listIntros(ctx, f.bob)
	if err != nil || received[0].Other != nil || received[0].Message != "" {
		t.Fatalf("revoked preview retained: %+v %v", received, err)
	}
	_, made, err := s.listIntros(ctx, f.introducer)
	if err != nil || made[0].Status != "sent" || made[0].MatchID != "" || made[0].MyDecision != "" || made[0].Other != nil {
		t.Fatal("introducer learned outcome")
	}
	var friendships int
	if err = f.db.QueryRow(`SELECT count(*) FROM matching.friend_connections WHERE user_id=$1 OR friend_user_id=$1`, f.introducer).Scan(&friendships); err != nil || friendships != 0 {
		t.Fatal("consent created general friendship")
	}
}
func TestIntroducerMutualMatchAndPrivateReceiptPostgres(t *testing.T) {
	f := introducerFixture(t)
	s := newFriendSocialService(f.db)
	ctx := context.Background()
	a := grantIntroducer(t, f, f.alice, false, false)
	grantIntroducer(t, f, f.bob, false, false)
	intro, err := s.makeIntro(ctx, f.introducer, f.alice, f.bob, "A thoughtful hello.")
	if err != nil {
		t.Fatal(err)
	}
	if _, err = s.decideIntro(ctx, f.alice, intro.ID, "accept"); err != nil {
		t.Fatal(err)
	}
	result, err := s.decideIntro(ctx, f.bob, intro.ID, "accept")
	if err != nil || result.MatchID == "" {
		t.Fatalf("mutual match: %+v %v", result, err)
	}
	if err = s.changeIntroducerConsent(ctx, f.alice, a, false); err != nil {
		t.Fatal(err)
	}
	var active bool
	if err = f.db.QueryRow(`SELECT unmatched_at IS NULL FROM matching.matches WHERE id=$1`, result.MatchID).Scan(&active); err != nil || !active {
		t.Fatal("revocation destroyed mutual match")
	}
	_, made, err := s.listIntros(ctx, f.introducer)
	if err != nil {
		t.Fatal(err)
	}
	raw, _ := json.Marshal(made)
	if strings.Contains(string(raw), result.MatchID) || strings.Contains(string(raw), "matched") || strings.Contains(string(raw), "accepted") {
		t.Fatalf("private decision in receipt: %s", raw)
	}
}
func TestIntroducerExpiryBlocksAndNonDiscoveryPostgres(t *testing.T) {
	f := introducerFixture(t)
	s := newFriendSocialService(f.db)
	ctx := context.Background()
	invite, err := s.createIntroducerInvite(ctx, f.alice, false, false)
	if err != nil {
		t.Fatal(err)
	}
	hash := sha256.Sum256([]byte(invite.Code))
	if _, err = f.db.Exec(`UPDATE matching.introducer_invites SET expires_at=NOW()-INTERVAL '1 second' WHERE token_hash=$1`, hash[:]); err != nil {
		t.Fatal(err)
	}
	if err = s.redeemIntroducerInvite(ctx, f.introducer, invite.Code); !errors.Is(err, errIntroducerConsent) {
		t.Fatal("expired code accepted")
	}
	invite, err = s.createIntroducerInvite(ctx, f.alice, false, false)
	if err != nil {
		t.Fatal(err)
	}
	if _, err = f.db.Exec(`INSERT INTO user_management.blocked_users(user_id,blocked_user_id) VALUES($1,$2)`, f.alice, f.introducer); err != nil {
		t.Fatal(err)
	}
	if err = s.redeemIntroducerInvite(ctx, f.introducer, invite.Code); !errors.Is(err, errIntroducerConsent) {
		t.Fatal("blocked code accepted")
	}
	if _, found, err := loadPublicProfile(ctx, f.db, f.alice, f.introducer); err != nil || found {
		t.Fatalf("introducer published: %v", err)
	}
	if _, err = f.db.Exec(`UPDATE user_management.users SET profile_completion=100 WHERE id=$1`, f.introducer); err == nil {
		t.Fatal("introducer completion bypass")
	}
}
func TestIntroducerPrincipalAndRefreshPostgres(t *testing.T) {
	f := introducerFixture(t)
	ctx := context.Background()
	access, refresh := uuid.NewString(), uuid.NewString()
	ah, rh := sha256.Sum256([]byte(access)), sha256.Sum256([]byte(refresh))
	username := "intro_" + strings.ReplaceAll(uuid.NewString()[:8], "-", "")
	for _, q := range []struct {
		sql  string
		args []any
	}{
		{`INSERT INTO user_management.auth_credentials(user_id,username,password_hash) VALUES($1,$2,'test')`, []any{f.introducer, username}},
		{`INSERT INTO user_management.signup_workflows(user_id,username) VALUES($1,$2)`, []any{f.introducer, username}},
		{`INSERT INTO user_management.auth_sessions(user_id,access_token_hash,refresh_token_hash,access_expires_at,refresh_expires_at) VALUES($1,$2,$3,NOW()+INTERVAL '30 minutes',NOW()+INTERVAL '1 day')`, []any{f.introducer, ah[:], rh[:]}},
	} {
		if _, err := f.db.Exec(q.sql, q.args...); err != nil {
			t.Fatal(err)
		}
	}
	t.Cleanup(func() {
		_, _ = f.db.Exec(`DELETE FROM user_management.auth_credentials WHERE user_id=$1`, f.introducer)
	})
	repo := &profileRepository{pg: f.db}
	p, err := repo.principalForAccessToken(ctx, "Bearer "+access)
	if err != nil || p.AccountKind != "introducer" {
		t.Fatalf("principal: %+v %v", p, err)
	}
	server := &Server{store: &runtimeStore{profileRepo: repo}}
	server.cfg.APIPrefix = "/v1"
	request := httptest.NewRequest(http.MethodGet, "/v1/discovery/"+f.introducer, nil)
	request.Header.Set("Authorization", "Bearer "+access)
	rec := httptest.NewRecorder()
	server.securityMiddleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) { t.Fatal("discovery handler invoked") })).ServeHTTP(rec, request)
	if rec.Code != http.StatusForbidden {
		t.Fatalf("status %d", rec.Code)
	}
	session, err := repo.refreshSession(ctx, refresh)
	if err != nil || session["account_kind"] != "introducer" {
		t.Fatalf("refresh account kind: %v", err)
	}
	if _, err = repo.refreshSession(ctx, refresh); err == nil {
		t.Fatal("refresh reused")
	}
}

func TestIntroducerInviteReplacementRateLimitAndPrivacyPostgres(t *testing.T) {
	f := introducerFixture(t)
	s := newFriendSocialService(f.db)
	ctx := context.Background()
	old, err := s.createIntroducerInvite(ctx, f.alice, true, false)
	if err != nil {
		t.Fatal(err)
	}
	latest, err := s.createIntroducerInvite(ctx, f.alice, false, false)
	if err != nil {
		t.Fatal(err)
	}
	if err = s.redeemIntroducerInvite(ctx, f.introducer, old.Code); !errors.Is(err, errIntroducerConsent) {
		t.Fatal("replaced invite usable")
	}
	if err = s.redeemIntroducerInvite(ctx, f.introducer, latest.Code); err != nil {
		t.Fatal(err)
	}
	if err = s.redeemIntroducerInvite(ctx, f.introducer, latest.Code); err != nil {
		t.Fatal(err)
	}
	if got := f.notifications(t, f.alice, "introducer.permission_requested"); got != 1 {
		t.Fatalf("notifications=%d", got)
	}
	for n := 0; n < 8; n++ {
		if _, err = s.createIntroducerInvite(ctx, f.alice, false, false); err != nil {
			t.Fatal(err)
		}
	}
	if _, err = s.createIntroducerInvite(ctx, f.alice, false, false); err == nil || !strings.Contains(err.Error(), "limit") {
		t.Fatal("invite rate limit missing")
	}
	for _, section := range accountExportSections() {
		if strings.HasPrefix(section.name, "introducer_") {
			var raw []byte
			if err = f.db.QueryRow(section.query, f.alice).Scan(&raw); err != nil {
				t.Fatal(err)
			}
			if strings.Contains(string(raw), latest.Code) || strings.Contains(string(raw), "token_hash") {
				t.Fatalf("secret exported: %s", section.name)
			}
		}
	}
	server := &Server{}
	server.cfg.APIPrefix = "/v1"
	if server.shouldApplyIdempotency(httptest.NewRequest(http.MethodPost, "/v1/introducer/invites", nil)) {
		t.Fatal("invitation token enters replay cache")
	}
}

func TestIntroducerFullAccountExportPostgres(t *testing.T) {
	f := introducerFixture(t)
	repo := &profileRepository{pg: f.db}
	result, _, err := repo.createAccountExport(context.Background(), f.introducer, f.introducer)
	if err != nil {
		t.Fatal(err)
	}
	if result["account"].(map[string]any)["account_kind"] != "introducer" {
		t.Fatal("account purpose missing")
	}
}
