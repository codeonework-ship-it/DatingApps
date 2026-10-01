package mobile

import (
	"context"
	"database/sql"
	"errors"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/verified-dating/backend/internal/platform/config"
)

// Behavioural tests for Epic 5 controls that were previously covered only by
// helper-function tests: the feature-flag middleware, expired replay cursors,
// uncertain-outcome recovery, XP award durability, readiness and DAU.

func recoveryTestServer(t *testing.T) *Server {
	t.Helper()
	server := newQuestWorkflowTestServerWithConfig(t, func(cfg *config.Config) {
		cfg.Environment = "test"
		cfg.BFFRequestTimeoutSec = 10
		cfg.BFFWriteTimeoutMS = 10000
		cfg.BFFNormalReadTimeoutMS = 10000
		cfg.BFFFastReadTimeoutMS = 10000
	})
	t.Cleanup(server.Close)
	return server
}

func serve(server *Server, method, path, body string) *httptest.ResponseRecorder {
	req := httptest.NewRequest(method, path, strings.NewReader(body))
	if body != "" {
		req.Header.Set("Content-Type", "application/json")
	}
	rec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, req)
	return rec
}

func TestFeatureFlagMiddlewareDefaultsDeferredModulesOff(t *testing.T) {
	server := recoveryTestServer(t)
	server.store.adminRepo = nil // no flag table: fall back to defaults
	rec := serve(server, http.MethodGet, "/v1/growth/referrals", "")
	if rec.Code != http.StatusForbidden || !strings.Contains(rec.Body.String(), "FEATURE_DISABLED") {
		t.Fatalf("deferred module without a flag row must be off: %d %s", rec.Code, rec.Body.String())
	}
}

func TestFeatureFlagMiddlewareRuntimeResponsesPostgres(t *testing.T) {
	db := trustOpsDB(t)
	server := recoveryTestServer(t)
	server.store.adminRepo = &adminRepository{pg: db}

	if _, err := db.Exec(`INSERT INTO matching.platform_feature_flags(key,value_bool,description,updated_by)
		VALUES ('digital_gestures_enabled',FALSE,'test','correctness_test')
		ON CONFLICT (key) DO UPDATE SET value_bool=FALSE`); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		_, _ = db.Exec(`DELETE FROM matching.platform_feature_flags WHERE key='digital_gestures_enabled' AND updated_by='correctness_test'`)
	})
	rec := serve(server, http.MethodPost, "/v1/matches/"+uuid.NewString()+"/gestures", `{}`)
	if rec.Code != http.StatusForbidden || !strings.Contains(rec.Body.String(), "FEATURE_DISABLED") {
		t.Fatalf("flag off: %d %s", rec.Code, rec.Body.String())
	}

	closed, err := sql.Open("pgx", os.Getenv("PROFILE_TEST_DATABASE_URL"))
	if err != nil {
		t.Fatal(err)
	}
	_ = closed.Close()
	server.store.adminRepo = &adminRepository{pg: closed}
	rec = serve(server, http.MethodPost, "/v1/matches/"+uuid.NewString()+"/gestures", `{}`)
	if rec.Code != http.StatusServiceUnavailable || !strings.Contains(rec.Body.String(), "FEATURE_POLICY_UNAVAILABLE") {
		t.Fatalf("unreadable flag policy must fail closed: %d %s", rec.Code, rec.Body.String())
	}
}

func TestExpiredReplayCursorReturns410Postgres(t *testing.T) {
	db := trustOpsDB(t)
	member, _ := seedTrustMember(t, db)
	server := recoveryTestServer(t)
	server.notifications = newNotificationRepository(db)
	installOperatorPrincipal(t, member)
	if _, err := db.Exec(`INSERT INTO platform.replay_cursor_checkpoints(stream_name,recipient_user_id,pruned_through_sequence)
		VALUES ('notifications',$1,100)
		ON CONFLICT DO NOTHING`, member); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		_, _ = db.Exec(`DELETE FROM platform.replay_cursor_checkpoints WHERE recipient_user_id=$1`, member)
	})
	rec := serve(server, http.MethodGet, "/v1/notifications/"+member+"?after=5", "")
	if rec.Code != http.StatusGone || !strings.Contains(rec.Body.String(), "REPLAY_CURSOR_EXPIRED") ||
		!strings.Contains(rec.Body.String(), "snapshot_url") {
		t.Fatalf("expired cursor: %d %s", rec.Code, rec.Body.String())
	}
	rec = serve(server, http.MethodGet, "/v1/notifications/"+member+"?after=150", "")
	if rec.Code == http.StatusGone {
		t.Fatalf("a cursor past the prune point must resume, got 410")
	}
}

func TestOperationStatusReportsUncertainOutcomePostgres(t *testing.T) {
	db := trustOpsDB(t)
	member, _ := seedTrustMember(t, db)
	server := recoveryTestServer(t)
	server.sharedIdempotency = newPostgresIdempotencyStore(db, server.cfg)
	installOperatorPrincipal(t, member)

	insert := func(key, state string, leaseAgo time.Duration) {
		cacheKey := idempotencyDigest(strings.Join([]string{"POST", "/v1/chat/m1/messages", member, key}, "|"))
		if _, err := db.Exec(`INSERT INTO platform.idempotency_records
			(cache_key,method,request_path,actor_id,idempotency_key,request_hash,state,owner_token,
			 response_status,response_content_type,response_body,lease_expires_at,expires_at,completed_at)
			VALUES ($1,'POST','/v1/chat/m1/messages',$2,$3,encode(sha256(convert_to($3,'UTF8')),'hex'),$4,gen_random_uuid(),
			        CASE WHEN $4='completed' THEN 201 END, CASE WHEN $4='completed' THEN 'application/json' END,
			        CASE WHEN $4='completed' THEN convert_to('{"id":"msg-1"}','UTF8') END,
			        NOW()-make_interval(secs=>$5), NOW()+INTERVAL '1 hour',
			        CASE WHEN $4='completed' THEN NOW() END)`,
			cacheKey, member, key, state, int(leaseAgo.Seconds())); err != nil {
			t.Fatalf("seed idempotency record: %v", err)
		}
		t.Cleanup(func() { _, _ = db.Exec(`DELETE FROM platform.idempotency_records WHERE cache_key=$1`, cacheKey) })
	}
	insert("crashed-key", "processing", time.Minute)
	insert("done-key", "completed", time.Minute)

	rec := serve(server, http.MethodGet, "/v1/operations/status?method=POST&path=/v1/chat/m1/messages&idempotency_key=crashed-key", "")
	if rec.Code != http.StatusOK || !strings.Contains(rec.Body.String(), `"state":"recovery_required"`) {
		t.Fatalf("expired lease must report recovery_required: %d %s", rec.Code, rec.Body.String())
	}
	rec = serve(server, http.MethodGet, "/v1/operations/status?method=POST&path=/v1/chat/m1/messages&idempotency_key=done-key", "")
	if rec.Code != http.StatusOK || !strings.Contains(rec.Body.String(), `"http_status":201`) || !strings.Contains(rec.Body.String(), "msg-1") {
		t.Fatalf("completed operation must return its stored result: %d %s", rec.Code, rec.Body.String())
	}
	rec = serve(server, http.MethodGet, "/v1/operations/status?method=POST&path=/v1/chat/m1/messages&idempotency_key=unknown", "")
	if rec.Code != http.StatusNotFound {
		t.Fatalf("unknown operation: %d %s", rec.Code, rec.Body.String())
	}
}

func TestXPAwardWriteAheadIntentPostgres(t *testing.T) {
	db := trustOpsDB(t)
	member, _ := seedTrustMember(t, db)
	repo := newLevelProgressionRepository(db)
	ctx := context.Background()
	input := xpAwardInput{UserID: member, Source: "profile_completed", SourceEventID: "qa-" + member,
		IdempotencyKey: "profile_completed:qa:" + member}
	if err := repo.writeAheadAwardIntent(ctx, input); err != nil {
		t.Fatalf("write-ahead: %v", err)
	}
	var status string
	var delayed bool
	if err := db.QueryRow(`SELECT status, available_at > NOW()+INTERVAL '30 seconds' FROM progression.xp_award_repair_queue
		WHERE user_id=$1 AND idempotency_key=$2`, member, input.IdempotencyKey).Scan(&status, &delayed); err != nil {
		t.Fatal(err)
	}
	if status != "pending" || !delayed {
		t.Fatalf("intent status=%q delayed=%v: the repair worker must wait for the direct award", status, delayed)
	}
	if err := repo.closeAwardIntent(ctx, input, "completed", nil); err != nil {
		t.Fatal(err)
	}
	if err := db.QueryRow(`SELECT status FROM progression.xp_award_repair_queue WHERE user_id=$1 AND idempotency_key=$2`,
		member, input.IdempotencyKey).Scan(&status); err != nil || status != "completed" {
		t.Fatalf("closed intent status=%q err=%v", status, err)
	}
}

func TestXPAwardSpoolReplaysUntilEnqueued(t *testing.T) {
	path := filepath.Join(t.TempDir(), "spool.jsonl")
	spool := newXPAwardSpool(path, nil)
	for _, key := range []string{"a", "b"} {
		if err := spool.append(xpAwardInput{UserID: "u", Source: "profile_completed", IdempotencyKey: key}); err != nil {
			t.Fatal(err)
		}
	}
	var seen []string
	replayed, err := spool.replay(context.Background(), func(_ context.Context, input xpAwardInput, _ error) error {
		if input.IdempotencyKey == "b" {
			return errors.New("database still down")
		}
		seen = append(seen, input.IdempotencyKey)
		return nil
	})
	if err != nil || replayed != 1 || len(seen) != 1 || seen[0] != "a" {
		t.Fatalf("first replay: replayed=%d seen=%v err=%v", replayed, seen, err)
	}
	replayed, err = spool.replay(context.Background(), func(_ context.Context, input xpAwardInput, _ error) error {
		seen = append(seen, input.IdempotencyKey)
		return nil
	})
	if err != nil || replayed != 1 || seen[len(seen)-1] != "b" {
		t.Fatalf("second replay must deliver the kept intent: replayed=%d seen=%v err=%v", replayed, seen, err)
	}
	data, _ := os.ReadFile(path)
	if strings.TrimSpace(string(data)) != "" {
		t.Fatalf("spool must be empty after delivery, got %q", data)
	}
}

func TestReadinessChecksAggregateOwnershipPostgres(t *testing.T) {
	db := trustOpsDB(t)
	server := recoveryTestServer(t)
	server.store.profileRepo = &profileRepository{pg: db}
	state, ok := server.aggregateOwnershipState(context.Background())
	if !ok || state != "ready" {
		t.Fatalf("aggregate ownership state = %q (%v)", state, ok)
	}
	var unregistered string
	if err := db.QueryRow(`SELECT array_to_string(unregistered_required, ',') FROM platform.aggregate_ownership_health`).Scan(&unregistered); err != nil {
		t.Fatal(err)
	}
	if unregistered != "" {
		t.Fatalf("required aggregates not registered: %s", unregistered)
	}
}

func TestMemberActivityCountsAuthenticatedMembersPostgres(t *testing.T) {
	db := trustOpsDB(t)
	member, _ := seedTrustMember(t, db)
	var before int64
	if err := db.QueryRow(`SELECT dau FROM platform.member_activity_kpis`).Scan(&before); err != nil {
		t.Skipf("migration 087 not applied: %v", err)
	}
	if _, err := db.Exec(`INSERT INTO user_management.auth_sessions
		(user_id,access_token_hash,refresh_token_hash,access_expires_at,refresh_expires_at,last_used_at)
		VALUES ($1,$2,$3,NOW()+INTERVAL '1 hour',NOW()+INTERVAL '1 day',NOW())`,
		member, []byte(member+"dau-a"), []byte(member+"dau-r")); err != nil {
		t.Fatal(err)
	}
	var after int64
	if err := db.QueryRow(`SELECT dau FROM platform.member_activity_kpis`).Scan(&after); err != nil {
		t.Fatal(err)
	}
	if after != before+1 {
		t.Fatalf("DAU %d -> %d, want +1 for a newly active member", before, after)
	}
	server := recoveryTestServer(t)
	server.store.profileRepo = &profileRepository{pg: db}
	kpis := server.memberActivityKPIs(context.Background())
	if kpis["available"] != true || kpis["dau"] != after {
		t.Fatalf("memberActivityKPIs = %v", kpis)
	}
}
