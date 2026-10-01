package mobile

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"
	"go.uber.org/zap"

	"github.com/verified-dating/backend/internal/platform/postgresdata"
)

func progressionLoadDatabase(t *testing.T) *levelProgressionRepository {
	t.Helper()
	dsn := os.Getenv("PROGRESSION_LOAD_DATABASE_URL")
	if dsn == "" {
		t.Skip("PROGRESSION_LOAD_DATABASE_URL is not set")
	}
	db, err := postgresdata.OpenSQL(dsn, postgresdata.Options{
		MaxConns: 32, MinConns: 4, StatementTimeout: 30 * time.Second,
		LockTimeout: 5 * time.Second, IdleTransactionTimeout: 30 * time.Second,
	})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = db.Close() })
	var database string
	if err = db.QueryRow("SELECT current_database()").Scan(&database); err != nil {
		t.Fatal(err)
	}
	if len(database) < len("progression_load_") || !contains(database, "progression_load_") {
		t.Fatalf("refusing progression load test against non-ephemeral database %q", database)
	}
	return newLevelProgressionRepository(db)
}

func contains(value, fragment string) bool {
	for index := 0; index+len(fragment) <= len(value); index++ {
		if value[index:index+len(fragment)] == fragment {
			return true
		}
	}
	return false
}

func TestProgressionProjectionLoadGate(t *testing.T) {
	repo := progressionLoadDatabase(t)
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()
	eventCount := envPositiveInt("PROGRESSION_LOAD_EVENTS", 2000)
	workerCount := envPositiveInt("PROGRESSION_LOAD_WORKERS", 4)
	userCount := min(100, eventCount)
	runID := uuid.NewString()

	_, err := repo.db.ExecContext(ctx, `INSERT INTO user_management.users
		(id,username,name,date_of_birth,gender,email,is_active,is_verified)
		SELECT gen_random_uuid(),'xp_load_'||left($1,8)||'_'||n,'XP Load Member',
		       DATE '1990-01-01','female','xp_load_'||left($1,8)||'_'||n||'@example.test',TRUE,TRUE
		FROM generate_series(1,$2) n`, runID, userCount)
	if err != nil {
		t.Fatalf("seed load members: %v", err)
	}
	_, err = repo.db.ExecContext(ctx, `WITH members AS (
		SELECT id,row_number() OVER (ORDER BY id) AS member_number
		FROM user_management.users WHERE username LIKE 'xp_load_'||left($1,8)||'_%'
	), events AS (SELECT n FROM generate_series(1,$2) n)
	INSERT INTO progression.xp_ledger
		(user_id,source,source_event_id,idempotency_key,request_hash,base_xp,
		 quality_multiplier,experiment_multiplier,awarded_xp,metadata,actor_type)
	SELECT m.id,'admin_adjustment','load:'||$1||':'||e.n,'load:'||$1||':'||e.n,
	       encode(digest('load:'||$1||':'||e.n,'sha256'),'hex'),1,1,1,1,
	       jsonb_build_object('load_test_id',$1),'system'
	FROM events e JOIN members m ON m.member_number=((e.n-1)%$3)+1`, runID, eventCount, userCount)
	if err != nil {
		t.Fatalf("seed load ledger: %v", err)
	}
	_, err = repo.db.ExecContext(ctx, `INSERT INTO progression.projection_outbox(ledger_sequence,user_id)
		SELECT sequence_id,user_id FROM progression.xp_ledger
		WHERE metadata->>'load_test_id'=$1`, runID)
	if err != nil {
		t.Fatalf("seed projection outbox: %v", err)
	}

	engines := make([]*levelProjectionEngine, workerCount)
	for index := range engines {
		engines[index] = newLevelProjectionEngine(repo, zap.NewNop(), nil)
	}
	started := time.Now()
	remaining := int64(eventCount)
	for remaining > 0 && ctx.Err() == nil {
		var group sync.WaitGroup
		for _, engine := range engines {
			group.Add(1)
			go func(worker *levelProjectionEngine) {
				defer group.Done()
				worker.runBatch(ctx)
			}(engine)
		}
		group.Wait()
		if err = repo.db.QueryRowContext(ctx, `SELECT COUNT(*) FROM progression.projection_outbox o
			JOIN progression.xp_ledger l ON l.sequence_id=o.ledger_sequence
			WHERE l.metadata->>'load_test_id'=$1 AND o.status<>'completed'`, runID).Scan(&remaining); err != nil {
			t.Fatal(err)
		}
	}
	duration := time.Since(started)
	if remaining != 0 {
		t.Fatalf("projection did not drain before timeout: remaining=%d", remaining)
	}
	var completed, deadLetters int64
	var completionP95 float64
	err = repo.db.QueryRowContext(ctx, `SELECT
		COUNT(*) FILTER (WHERE o.status='completed'),
		COUNT(*) FILTER (WHERE o.status='dead_letter'),
		COALESCE(percentile_cont(0.95) WITHIN GROUP
		  (ORDER BY EXTRACT(EPOCH FROM o.completed_at-o.created_at))
		  FILTER (WHERE o.status='completed'),0)
		FROM progression.projection_outbox o JOIN progression.xp_ledger l
		ON l.sequence_id=o.ledger_sequence WHERE l.metadata->>'load_test_id'=$1`, runID).
		Scan(&completed, &deadLetters, &completionP95)
	if err != nil {
		t.Fatal(err)
	}
	var projectionMismatches int64
	err = repo.db.QueryRowContext(ctx, `WITH expected AS (
		SELECT user_id,SUM(awarded_xp)::INTEGER total FROM progression.xp_ledger
		WHERE metadata->>'load_test_id'=$1 GROUP BY user_id)
		SELECT COUNT(*) FROM expected e LEFT JOIN progression.user_level_state s USING(user_id)
		WHERE s.user_id IS NULL OR s.total_xp<>e.total`, runID).Scan(&projectionMismatches)
	if err != nil {
		t.Fatal(err)
	}
	throughput := float64(completed) / duration.Seconds()
	minimumThroughput := float64(envPositiveInt("PROGRESSION_LOAD_MIN_EVENTS_PER_SECOND", 100))
	maximumP95 := float64(envPositiveInt("PROGRESSION_LOAD_MAX_P95_SECONDS", 5))
	passed := completed == int64(eventCount) && deadLetters == 0 && projectionMismatches == 0 && throughput >= minimumThroughput && completionP95 <= maximumP95
	report := map[string]any{
		"passed": passed, "run_id": runID, "events": eventCount, "workers": workerCount,
		"duration_seconds": duration.Seconds(), "throughput_events_per_second": throughput,
		"completion_p95_seconds": completionP95, "dead_letters": deadLetters,
		"projection_mismatches": projectionMismatches,
		"thresholds":            map[string]any{"minimum_events_per_second": minimumThroughput, "maximum_p95_seconds": maximumP95},
	}
	writeProgressionLoadReport(t, report)
	if !passed {
		t.Fatalf("progression projection load gate failed: %+v", report)
	}
	t.Logf("projection load passed: %.1f events/s, p95 %.3fs", throughput, completionP95)
}

func TestProgressionFraudTuningGate(t *testing.T) {
	repo := progressionLoadDatabase(t)
	ctx := context.Background()
	userID := uuid.NewString()
	username := "xp_fraud_" + userID[:8]
	_, err := repo.db.ExecContext(ctx, `INSERT INTO user_management.users
		(id,username,name,date_of_birth,gender,email,is_active,is_verified)
		VALUES ($1,$2,'XP Fraud Gate',DATE '1990-01-01','female',$3,TRUE,TRUE)`, userID, username, username+"@example.test")
	if err != nil {
		t.Fatal(err)
	}
	_, err = repo.db.ExecContext(ctx, `UPDATE progression.fraud_rule_policies
		SET rejected_attempt_threshold=2,window_seconds=3600,severity='high',
		    tuning_note='Ephemeral load gate threshold verification.'
		WHERE rule_code='repeated_source_cap'`)
	if err != nil {
		t.Fatal(err)
	}
	first := xpAwardInput{UserID: userID, Source: "daily_prompt_submitted", SourceEventID: "fraud:accepted", IdempotencyKey: "fraud:accepted"}
	if _, err = repo.awardXP(ctx, first); err != nil {
		t.Fatalf("initial award: %v", err)
	}
	for attempt := 1; attempt <= 2; attempt++ {
		input := xpAwardInput{UserID: userID, Source: "daily_prompt_submitted", SourceEventID: fmt.Sprintf("fraud:rejected:%d", attempt), IdempotencyKey: fmt.Sprintf("fraud:rejected:%d", attempt)}
		if _, err = repo.awardXP(ctx, input); err != errXPCapReached {
			t.Fatalf("rejected attempt %d = %v, want XP cap", attempt, err)
		}
	}
	var severity, responseAction string
	var rejectedAttempts, threshold int
	err = repo.db.QueryRowContext(ctx, `SELECT f.severity,(f.evidence->>'rejected_attempts')::INTEGER,
		(f.evidence->>'threshold')::INTEGER,p.response_action
		FROM progression.fraud_cases f JOIN progression.fraud_rule_policies p USING(rule_code)
		WHERE f.user_id=$1 AND f.rule_code='repeated_source_cap'`, userID).
		Scan(&severity, &rejectedAttempts, &threshold, &responseAction)
	if err != nil {
		t.Fatal(err)
	}
	if severity != "high" || rejectedAttempts != 2 || threshold != 2 || responseAction != "review_only" {
		t.Fatalf("fraud tuning not applied: severity=%s attempts=%d threshold=%d action=%s", severity, rejectedAttempts, threshold, responseAction)
	}
}

func envPositiveInt(key string, fallback int) int {
	value, err := strconv.Atoi(os.Getenv(key))
	if err != nil || value <= 0 {
		return fallback
	}
	return value
}

func writeProgressionLoadReport(t *testing.T, report map[string]any) {
	t.Helper()
	path := os.Getenv("PROGRESSION_LOAD_REPORT")
	if path == "" {
		return
	}
	payload, err := json.MarshalIndent(report, "", "  ")
	if err != nil {
		t.Fatal(err)
	}
	if err = os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatal(err)
	}
	if err = os.WriteFile(path, append(payload, '\n'), 0o644); err != nil {
		t.Fatal(err)
	}
}
