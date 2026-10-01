package mobile

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/verified-dating/backend/internal/platform/config"
)

// Postgres-backed tests for the Epic 2 controls: retention jobs, legal holds,
// erasure of SOS and audit history, operator removal, stale SOS reclaim and
// operator-assisted account recovery. They skip without a database.

func trustOpsDB(t *testing.T) *sql.DB {
	t.Helper()
	dsn := os.Getenv("PROFILE_TEST_DATABASE_URL")
	if dsn == "" {
		t.Skip("PROFILE_TEST_DATABASE_URL is not set")
	}
	db, err := sql.Open("pgx", dsn)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = db.Close() })
	var ready bool
	if err := db.QueryRow(`SELECT to_regclass('platform.legal_holds') IS NOT NULL
		AND to_regclass('user_management.account_recovery_requests') IS NOT NULL`).Scan(&ready); err != nil || !ready {
		t.Skip("migrations 081/082 are not applied")
	}
	return db
}

// seedTrustMember creates a member with credentials and returns id and username.
func seedTrustMember(t *testing.T, db *sql.DB) (string, string) {
	t.Helper()
	id := uuid.NewString()
	username := "trustqa_" + strings.ReplaceAll(id[:8], "-", "")
	if _, err := db.Exec(`INSERT INTO user_management.users (id, username, name, date_of_birth, gender, email)
		VALUES ($1,$2,'Trust QA','1990-01-01','female',$3)`, id, username, username+"@example.test"); err != nil {
		t.Fatalf("seed member: %v", err)
	}
	if _, err := db.Exec(`INSERT INTO user_management.auth_credentials (user_id, username, password_hash)
		VALUES ($1,$2,'$2a$10$abcdefghijklmnopqrstuuM1TiHvXUBR8Z6nq6nJdA5K1wVbq5G6')`, id, username); err != nil {
		t.Fatalf("seed credentials: %v", err)
	}
	t.Cleanup(func() {
		_, _ = db.Exec(`DELETE FROM platform.legal_holds WHERE user_id=$1`, id)
		_, _ = db.Exec(`DELETE FROM matching.sos_delivery_outbox WHERE user_id=$1`, id)
		_, _ = db.Exec(`DELETE FROM user_management.users WHERE id=$1`, id)
	})
	return id, username
}

func TestTrustRetentionPurgesOldRevokedSessionsAndRespectsLegalHoldPostgres(t *testing.T) {
	db := trustOpsDB(t)
	member, _ := seedTrustMember(t, db)
	held, _ := seedTrustMember(t, db)
	ctx := context.Background()

	insertSession := func(userID string, revokedAgo time.Duration) string {
		id := uuid.NewString()
		if _, err := db.Exec(`INSERT INTO user_management.auth_sessions
			(id,user_id,access_token_hash,refresh_token_hash,access_expires_at,refresh_expires_at,revoked_at)
			VALUES ($1,$2,$3,$4,NOW()-$5::interval,NOW()-$5::interval+INTERVAL '1 day',NOW()-$5::interval)`,
			id, userID, []byte(id+"a"), []byte(id+"r"), revokedAgo.String()); err != nil {
			t.Fatalf("seed session: %v", err)
		}
		return id
	}
	oldSession := insertSession(member, 100*24*time.Hour)
	recentSession := insertSession(member, 10*24*time.Hour)

	// Security events past 24 months: one for an ordinary member, one for a
	// member on legal hold.
	insertEvent := func(subject string) int64 {
		var id int64
		if err := db.QueryRow(`INSERT INTO audit.security_events (occurred_at,event_type,actor_role,subject_user_id,resource_type,resource_id,payload)
			VALUES (NOW()-INTERVAL '25 months','test.retention','system',$1::uuid,'user',$2,'{}') RETURNING id`, subject, subject).Scan(&id); err != nil {
			t.Fatalf("seed security event: %v", err)
		}
		return id
	}
	plainEvent := insertEvent(member)
	heldEvent := insertEvent(held)
	if _, err := db.Exec(`INSERT INTO platform.legal_holds (user_id,reason,placed_by) VALUES ($1,'litigation hold',$2)`,
		held, uuid.NewString()); err != nil {
		t.Fatal(err)
	}

	// Without the retention context, security events remain append-only.
	if _, err := db.Exec(`DELETE FROM audit.security_events WHERE id=$1`, plainEvent); err == nil {
		t.Fatal("security events must stay append-only outside the retention purge")
	}

	worker := newTrustRetentionWorker(db, nil, nil, nil, time.Hour)
	if _, err := worker.RunOnce(ctx); err != nil {
		t.Fatalf("retention run: %v", err)
	}

	exists := func(query string, arg any) bool {
		var found bool
		if err := db.QueryRow(query, arg).Scan(&found); err != nil {
			t.Fatal(err)
		}
		return found
	}
	if exists(`SELECT EXISTS(SELECT 1 FROM user_management.auth_sessions WHERE id=$1)`, oldSession) {
		t.Error("a session revoked 100 days ago should be purged")
	}
	if !exists(`SELECT EXISTS(SELECT 1 FROM user_management.auth_sessions WHERE id=$1)`, recentSession) {
		t.Error("a session revoked 10 days ago must be kept")
	}
	if exists(`SELECT EXISTS(SELECT 1 FROM audit.security_events WHERE id=$1)`, plainEvent) {
		t.Error("a 25-month-old security event should be purged")
	}
	if !exists(`SELECT EXISTS(SELECT 1 FROM audit.security_events WHERE id=$1)`, heldEvent) {
		t.Error("a security event about a member on legal hold must be kept")
	}
	// Tidy the held event (hold released) so the fixture can be removed.
	_, _ = db.Exec(`UPDATE platform.legal_holds SET released_at=NOW(), released_by=$2 WHERE user_id=$1`, held, uuid.NewString())
	_, _ = db.Exec(`UPDATE audit.security_events SET occurred_at=occurred_at WHERE false`)
	_, _ = worker.RunOnce(ctx)
}

func TestTrustRetentionPurgesIdentityEvidenceAfterDecisionPostgres(t *testing.T) {
	db := trustOpsDB(t)
	member, _ := seedTrustMember(t, db)
	details := `{"id_document":{"storage_path":"private/verification/qa/doc.jpg"},"selfie":{"storage_path":"private/verification/qa/selfie.jpg"},"method":"document"}`
	if _, err := db.Exec(`INSERT INTO matching.verification_states (user_id,status,submitted_at,reviewed_at,details)
		VALUES ($1,'verified',NOW()-INTERVAL '40 days',NOW()-INTERVAL '31 days',$2::jsonb)`, member, details); err != nil {
		t.Fatalf("seed verification: %v", err)
	}
	var deleted []string
	worker := newTrustRetentionWorker(db, nil, nil, func(path string) error {
		deleted = append(deleted, path)
		return nil
	}, time.Hour)
	if _, err := worker.RunOnce(context.Background()); err != nil {
		t.Fatalf("retention run: %v", err)
	}
	if len(deleted) != 2 {
		t.Fatalf("deleted objects = %v, want document and selfie", deleted)
	}
	var remaining string
	if err := db.QueryRow(`SELECT details::text FROM matching.verification_states WHERE user_id=$1`, member).Scan(&remaining); err != nil {
		t.Fatal(err)
	}
	if strings.Contains(remaining, "storage_path") || !strings.Contains(remaining, "evidence_purged_at") ||
		!strings.Contains(remaining, `"method"`) {
		t.Fatalf("details after purge = %s", remaining)
	}
}

func TestErasureMinimisesAuditHistoryAndSOSDataPostgres(t *testing.T) {
	db := trustOpsDB(t)
	member, memberUsername := seedTrustMember(t, db)
	memberEmail := memberUsername + "@example.test"
	ctx := context.Background()
	repo := &profileRepository{pg: db}

	var alertID string
	if err := db.QueryRow(`INSERT INTO matching.sos_alerts (user_id,level,message,latitude,longitude,status)
		VALUES ($1,'high','I need help near the station',12.97,77.59,'resolved') RETURNING id::text`, member).Scan(&alertID); err != nil {
		t.Fatalf("seed sos alert: %v", err)
	}
	if _, err := repo.requestAccountDeletion(ctx, member, member, "qa"); err != nil {
		t.Fatalf("schedule deletion: %v", err)
	}
	if _, err := db.Exec(`UPDATE user_management.users SET deletion_effective_at=NOW()-INTERVAL '1 minute' WHERE id=$1`, member); err != nil {
		t.Fatal(err)
	}

	// A legal hold defers the erasure.
	if _, err := db.Exec(`INSERT INTO platform.legal_holds (user_id,reason,placed_by) VALUES ($1,'regulator request',$2)`,
		member, uuid.NewString()); err != nil {
		t.Fatal(err)
	}
	if _, err := repo.eraseAccount(ctx, member, "", "system"); !errors.Is(err, errAccountOnLegalHold) {
		t.Fatalf("erasure under legal hold: err=%v", err)
	}
	if _, err := db.Exec(`UPDATE platform.legal_holds SET released_at=NOW(), released_by=$2 WHERE user_id=$1`,
		member, uuid.NewString()); err != nil {
		t.Fatal(err)
	}

	summary, err := repo.eraseAccount(ctx, member, "", "system")
	if err != nil {
		t.Fatalf("erase: %v", err)
	}
	if summary.RowsScrubbed["sos_alerts"] != 1 || summary.RowsScrubbed["audit_history_minimised"] == 0 {
		t.Fatalf("summary = %+v", summary.RowsScrubbed)
	}
	var message sql.NullString
	var lat sql.NullFloat64
	if err := db.QueryRow(`SELECT message, latitude FROM matching.sos_alerts WHERE id=$1`, alertID).Scan(&message, &lat); err != nil {
		t.Fatal(err)
	}
	if message.Valid || lat.Valid {
		t.Fatalf("sos alert content survived erasure: message=%v lat=%v", message, lat)
	}

	// No history row may still carry the member's email or SOS text.
	var leaks int
	if err := db.QueryRow(`SELECT COUNT(*) FROM audit.change_log
		WHERE (old_data::text LIKE '%'||$1||'%' OR new_data::text LIKE '%'||$1||'%'
		       OR ((old_data::text LIKE '%near the station%' OR new_data::text LIKE '%near the station%')
		           AND (old_data->>'user_id' = $2 OR new_data->>'user_id' = $2)))`,
		memberEmail, member).Scan(&leaks); err != nil {
		t.Fatal(err)
	}
	if leaks != 0 {
		t.Fatalf("%d audit history rows still carry the erased member's data", leaks)
	}
}

func TestOperatorRemovalSchedulesErasureAndCannotBeCancelledByMemberPostgres(t *testing.T) {
	db := trustOpsDB(t)
	member, _ := seedTrustMember(t, db)
	ctx := context.Background()
	repo := &profileRepository{pg: db}
	if _, err := db.Exec(`INSERT INTO user_management.auth_sessions
		(user_id,access_token_hash,refresh_token_hash,access_expires_at,refresh_expires_at)
		VALUES ($1,$2,$3,NOW()+INTERVAL '1 hour',NOW()+INTERVAL '1 day')`,
		member, []byte(member+"a"), []byte(member+"r")); err != nil {
		t.Fatal(err)
	}
	operator, _ := seedTrustMember(t, db)
	state, err := repo.scheduleAccountDeletion(ctx, member, operator, "operator", "abuse")
	if err != nil {
		t.Fatalf("operator removal: %v", err)
	}
	_ = state
	var active int
	if err := db.QueryRow(`SELECT COUNT(*) FROM user_management.auth_sessions WHERE user_id=$1 AND revoked_at IS NULL`, member).Scan(&active); err != nil {
		t.Fatal(err)
	}
	if active != 0 {
		t.Fatalf("%d sessions still active after operator removal", active)
	}
	if _, err := repo.cancelAccountDeletion(ctx, member, member); !errors.Is(err, errOperatorDeletionNotCancellable) {
		t.Fatalf("member cancel of operator removal: err=%v", err)
	}
	var exists bool
	if err := db.QueryRow(`SELECT EXISTS(SELECT 1 FROM user_management.users WHERE id=$1 AND deletion_effective_at IS NOT NULL)`, member).Scan(&exists); err != nil || !exists {
		t.Fatalf("operator removal must keep the member row for erasure: exists=%v err=%v", exists, err)
	}
}

func TestSOSStaleProcessingDeliveryIsReclaimedPostgres(t *testing.T) {
	db := trustOpsDB(t)
	member, _ := seedTrustMember(t, db)
	var alertID string
	if err := db.QueryRow(`INSERT INTO matching.sos_alerts (user_id,level,message,status)
		VALUES ($1,'critical','help','open') RETURNING id::text`, member).Scan(&alertID); err != nil {
		t.Fatalf("seed alert: %v", err)
	}
	var deliveryID string
	if err := db.QueryRow(`INSERT INTO matching.sos_delivery_outbox
		(alert_id,contact_id,user_id,contact_name,contact_phone,level,response_deadline_at,status,locked_at,worker_id,attempt_count)
		VALUES ($1,$2,$3,'Contact','+910000000000','critical',NOW()+INTERVAL '5 minutes','processing',NOW()-INTERVAL '10 minutes','crashed-worker',1)
		RETURNING id::text`, alertID, uuid.NewString(), member).Scan(&deliveryID); err != nil {
		t.Fatalf("seed delivery: %v", err)
	}
	repo := &safetyRepository{pg: db}
	jobs, err := repo.claimSOSDeliveries(context.Background(), "fresh-worker", 25, 8)
	if err != nil {
		t.Fatalf("claim: %v", err)
	}
	claimed := false
	for _, job := range jobs {
		if job.ID == deliveryID {
			claimed = true
			if job.AttemptCount != 2 {
				t.Errorf("attempt count = %d, want 2", job.AttemptCount)
			}
		}
	}
	if !claimed {
		t.Fatal("a delivery stuck in processing after a crash must be reclaimed")
	}
}

func TestAccountRecoveryAssistanceJourneyPostgres(t *testing.T) {
	db := trustOpsDB(t)
	member, username := seedTrustMember(t, db)
	ctx := context.Background()

	server := newQuestWorkflowTestServerWithConfig(t, func(cfg *config.Config) {
		cfg.Environment = "test"
		cfg.BFFRequestTimeoutSec = 10
		cfg.BFFWriteTimeoutMS = 10000
		cfg.BFFNormalReadTimeoutMS = 10000
		cfg.BFFFastReadTimeoutMS = 10000
	})
	defer server.Close()
	server.store.profileRepo = &profileRepository{pg: db}

	ask := func(name string) (int, string) {
		req := httptest.NewRequest(http.MethodPost, "/v1/auth/recovery/assistance",
			strings.NewReader(`{"username":"`+name+`","message":"Lost my phone and code"}`))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		server.Handler().ServeHTTP(rec, req)
		return rec.Code, rec.Body.String()
	}
	stripCorrelation := func(body string) string {
		var payload map[string]any
		_ = json.Unmarshal([]byte(body), &payload)
		delete(payload, "correlation_id")
		out, _ := json.Marshal(payload)
		return string(out)
	}
	knownCode, knownBody := ask(username)
	unknownCode, unknownBody := ask("nobody_" + uuid.NewString()[:8])
	knownBody, unknownBody = stripCorrelation(knownBody), stripCorrelation(unknownBody)
	if knownCode != http.StatusAccepted || knownCode != unknownCode || knownBody != unknownBody {
		t.Fatalf("known and unknown usernames must look identical: %d %s / %d %s",
			knownCode, knownBody, unknownCode, unknownBody)
	}

	// A live session exists before recovery.
	if _, err := db.Exec(`INSERT INTO user_management.auth_sessions
		(user_id,access_token_hash,refresh_token_hash,access_expires_at,refresh_expires_at)
		VALUES ($1,$2,$3,NOW()+INTERVAL '1 hour',NOW()+INTERVAL '1 day')`,
		member, []byte(member+"a2"), []byte(member+"r2")); err != nil {
		t.Fatal(err)
	}

	repo := server.store.profileRepo
	requests, err := repo.listRecoveryRequests(ctx, "open", 200)
	if err != nil {
		t.Fatal(err)
	}
	requestID := ""
	for _, item := range requests {
		if item.UserID == member {
			requestID = item.ID
		}
	}
	if requestID == "" {
		t.Fatal("the member's request should be queued for operators")
	}
	operator, _ := seedTrustMember(t, db)
	if _, err := repo.resolveRecoveryRequest(ctx, requestID, operator, "trust_safety",
		"issue_recovery_code", "", "checked"); err == nil {
		t.Fatal("issuing a code must require an identity check and a real note")
	}
	result, err := repo.resolveRecoveryRequest(ctx, requestID, operator, "trust_safety",
		"issue_recovery_code", "verified_identity_match", "Selfie on file matched a live video call.")
	if err != nil || result.RecoveryCode == "" {
		t.Fatalf("issue code: result=%+v err=%v", result, err)
	}
	var active int
	if err := db.QueryRow(`SELECT COUNT(*) FROM user_management.auth_sessions WHERE user_id=$1 AND revoked_at IS NULL`, member).Scan(&active); err != nil {
		t.Fatal(err)
	}
	if active != 0 {
		t.Fatalf("recovery must revoke every session; %d still active", active)
	}
	if _, err := repo.resolveRecoveryRequest(ctx, requestID, operator, "trust_safety",
		"issue_recovery_code", "verified_identity_match", "Second attempt on a closed request."); !errors.Is(err, errRecoveryRequestNotOpen) {
		t.Fatalf("a resolved request must not issue a second code: %v", err)
	}

	if err := repo.recoverPassword(ctx, username, result.RecoveryCode, "NewPassw0rd!"); err != nil {
		t.Fatalf("recover with issued code: %v", err)
	}
	if err := repo.recoverPassword(ctx, username, result.RecoveryCode, "OtherPassw0rd!"); err == nil {
		t.Fatal("an issued recovery code must be single-use")
	}
	var events int
	if err := db.QueryRow(`SELECT COUNT(*) FROM audit.security_events
		WHERE event_type='auth.recovery_code_issued_by_operator' AND subject_user_id=$1`, member).Scan(&events); err != nil {
		t.Fatal(err)
	}
	if events != 1 {
		t.Fatalf("issuing a code must be audited once; found %d", events)
	}
	var payload json.RawMessage
	_ = db.QueryRow(`SELECT payload FROM audit.security_events WHERE subject_user_id=$1 AND event_type='auth.recovery_code_issued_by_operator'`, member).Scan(&payload)
	if strings.Contains(string(payload), result.RecoveryCode) {
		t.Fatal("the recovery code must never be written to the audit log")
	}
}
