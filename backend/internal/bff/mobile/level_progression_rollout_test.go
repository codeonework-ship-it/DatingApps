package mobile

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"testing"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgconn"
)

// Behavioural tests for the PEN-45 rollout enforcement in migration 086: the
// stage-transition trigger (now also on INSERT), the exposed-cohort promotion
// gate, the append-only stage history, and the API cohort check. The trigger
// tests run inside one transaction per test and roll back, so they leave no
// rows behind (history rows could not be deleted otherwise).

func TestProgressionPromotionRequiresCohort(t *testing.T) {
	t.Parallel()
	tests := []struct {
		from, to string
		want     bool
	}{
		{"draft", "dogfood", false}, // opens the first cohort; nothing can be exposed yet
		{"dogfood", "five_percent", true},
		{"five_percent", "twenty_five_percent", true},
		{"twenty_five_percent", "general_availability", true},
		{"dogfood", "dogfood", false},                           // pause or resume
		{"general_availability", "general_availability", false}, // completion
		{"five_percent", "dogfood", false},                      // backwards; the trigger rejects it
		{"draft", "draft", false},
		{"dogfood", "unknown", false},
	}
	for _, test := range tests {
		if got := progressionPromotionRequiresCohort(test.from, test.to); got != test.want {
			t.Errorf("progressionPromotionRequiresCohort(%q, %q) = %v, want %v", test.from, test.to, got, test.want)
		}
	}
}

func progressionRolloutDB(t *testing.T) *sql.DB {
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
	if err := db.QueryRow(`SELECT EXISTS(SELECT 1 FROM public.schema_migrations
		WHERE version='086_progression_rollout_enforcement')`).Scan(&ready); err != nil || !ready {
		t.Skip("migration 086_progression_rollout_enforcement is not applied")
	}
	return db
}

// rolloutTx runs each statement under a savepoint so an expected trigger
// rejection does not abort the surrounding transaction.
type rolloutTx struct {
	t  *testing.T
	tx *sql.Tx
	n  int
}

func beginRolloutTx(t *testing.T, db *sql.DB) *rolloutTx {
	t.Helper()
	tx, err := db.BeginTx(context.Background(), nil)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = tx.Rollback() })
	return &rolloutTx{t: t, tx: tx}
}

func (r *rolloutTx) exec(query string, args ...any) error {
	r.t.Helper()
	r.n++
	savepoint := fmt.Sprintf("rollout_step_%d", r.n)
	if _, err := r.tx.Exec("SAVEPOINT " + savepoint); err != nil {
		r.t.Fatal(err)
	}
	if _, err := r.tx.Exec(query, args...); err != nil {
		if _, rollbackErr := r.tx.Exec("ROLLBACK TO SAVEPOINT " + savepoint); rollbackErr != nil {
			r.t.Fatal(rollbackErr)
		}
		return err
	}
	if _, err := r.tx.Exec("RELEASE SAVEPOINT " + savepoint); err != nil {
		r.t.Fatal(err)
	}
	return nil
}

func (r *rolloutTx) accept(step, query string, args ...any) {
	r.t.Helper()
	if err := r.exec(query, args...); err != nil {
		r.t.Fatalf("%s: rejected: %v", step, err)
	}
}

func (r *rolloutTx) reject(step, want, query string, args ...any) error {
	r.t.Helper()
	err := r.exec(query, args...)
	if err == nil {
		r.t.Fatalf("%s: accepted, want rejection containing %q", step, want)
	}
	if !strings.Contains(err.Error(), want) {
		r.t.Fatalf("%s: error %q does not contain %q", step, err.Error(), want)
	}
	return err
}

func (r *rolloutTx) member() string {
	r.t.Helper()
	id := uuid.NewString()
	username := "rollqa_" + strings.ReplaceAll(id[:8], "-", "")
	r.accept("seed member", `INSERT INTO user_management.users (id,username,name,date_of_birth,gender,email)
		VALUES ($1,$2,'Rollout QA','1990-01-01','female',$3)`, id, username, username+"@example.test")
	return id
}

func (r *rolloutTx) experiment() string {
	r.t.Helper()
	key := "qa_rollout_" + strings.ReplaceAll(uuid.NewString()[:8], "-", "")
	r.accept("seed experiment", `INSERT INTO progression.experiments(key,name,variants)
		VALUES ($1,'Rollout enforcement QA','{"control":{"multiplier":1.0},"voice_circle_bonus":{"multiplier":1.0}}')`, key)
	return key
}

// expose records a treatment-variant assignment made now (clock time, so it
// falls after the current stage start even inside one transaction).
func (r *rolloutTx) expose(key, variant string) {
	r.t.Helper()
	r.accept("assign "+variant, `INSERT INTO progression.experiment_assignments(experiment_key,user_id,variant,assigned_at)
		VALUES ($1,$2,$3,clock_timestamp())`, key, r.member(), variant)
}

// setStage mirrors the reviewed API update, including the stage clock.
const rolloutSetStageSQL = `UPDATE progression.experiments SET
	status=$2,rollout_stage=$3,rollout_percent=$4,safety_stop_owner='progression-oncall',
	last_safety_review_at=NOW(),stage_evidence_uri='qa://rollout-enforcement',
	stage_started_at=CASE WHEN rollout_stage<>$3 THEN clock_timestamp() ELSE stage_started_at END,
	updated_at=NOW() WHERE key=$1`

func requireRolloutCohortError(t *testing.T, err error) {
	t.Helper()
	var pgErr *pgconn.PgError
	if !errors.As(err, &pgErr) {
		t.Fatalf("cohort rejection is not a PostgreSQL error: %v", err)
	}
	if pgErr.Code != "23514" || pgErr.ConstraintName != progressionRolloutCohortConstraint {
		t.Fatalf("cohort rejection code=%s constraint=%q, want 23514/%s", pgErr.Code, pgErr.ConstraintName, progressionRolloutCohortConstraint)
	}
}

func TestProgressionRolloutTriggerStageOrderPostgres(t *testing.T) {
	r := beginRolloutTx(t, progressionRolloutDB(t))
	key := r.experiment()

	r.reject("skip draft to five_percent", "cannot skip a cohort stage", rolloutSetStageSQL, key, "active", "five_percent", 5)
	r.reject("skip draft to general_availability", "cannot skip a cohort stage", rolloutSetStageSQL, key, "active", "general_availability", 100)
	r.reject("promote without active status", "requires active status", rolloutSetStageSQL, key, "paused", "dogfood", 1)
	r.accept("promote draft to dogfood without a cohort", rolloutSetStageSQL, key, "active", "dogfood", 1)
	r.reject("complete from dogfood", "may complete only from general availability", rolloutSetStageSQL, key, "completed", "dogfood", 1)

	r.expose(key, "voice_circle_bonus")
	r.accept("promote dogfood to five_percent", rolloutSetStageSQL, key, "active", "five_percent", 5)
	r.reject("backwards five_percent to dogfood", "use paused status", rolloutSetStageSQL, key, "active", "dogfood", 1)
	r.reject("backwards five_percent to draft", "use paused status", rolloutSetStageSQL, key, "draft", "draft", 0)
	r.reject("complete from five_percent", "may complete only from general availability", rolloutSetStageSQL, key, "completed", "five_percent", 5)

	r.expose(key, "voice_circle_bonus")
	r.accept("promote five_percent to twenty_five_percent", rolloutSetStageSQL, key, "active", "twenty_five_percent", 25)
	r.expose(key, "voice_circle_bonus")
	r.accept("promote twenty_five_percent to general_availability", rolloutSetStageSQL, key, "active", "general_availability", 100)
	r.accept("complete from general_availability", rolloutSetStageSQL, key, "completed", "general_availability", 100)
}

func TestProgressionRolloutTriggerRequiresExposedCohortPostgres(t *testing.T) {
	r := beginRolloutTx(t, progressionRolloutDB(t))
	key := r.experiment()
	r.accept("promote draft to dogfood", rolloutSetStageSQL, key, "active", "dogfood", 1)

	requireRolloutCohortError(t, r.reject("promote with no assignments", "requires a nonempty exposed cohort",
		rolloutSetStageSQL, key, "active", "five_percent", 5))

	r.expose(key, "control")
	r.reject("promote with a control-only cohort", "requires a nonempty exposed cohort",
		rolloutSetStageSQL, key, "active", "five_percent", 5)

	r.accept("assign treatment before the stage started", `INSERT INTO progression.experiment_assignments(experiment_key,user_id,variant,assigned_at)
		SELECT key,$2,'voice_circle_bonus',stage_started_at-INTERVAL '1 hour' FROM progression.experiments WHERE key=$1`, key, r.member())
	r.reject("promote with only an earlier-stage exposure", "requires a nonempty exposed cohort",
		rolloutSetStageSQL, key, "active", "five_percent", 5)

	// A safety stop (pause) and a resume at the current stage are not
	// promotions and must never wait on cohort data.
	r.accept("pause dogfood without a cohort", rolloutSetStageSQL, key, "paused", "dogfood", 1)
	r.reject("promote from paused without a cohort", "requires a nonempty exposed cohort",
		rolloutSetStageSQL, key, "active", "five_percent", 5)
	r.accept("resume dogfood without a cohort", rolloutSetStageSQL, key, "active", "dogfood", 1)

	var exposed int64
	if err := r.tx.QueryRow(`SELECT progression.rollout_exposed_cohort_size(key,stage_started_at)
		FROM progression.experiments WHERE key=$1`, key).Scan(&exposed); err != nil {
		t.Fatal(err)
	}
	if exposed != 0 {
		t.Fatalf("exposed cohort = %d before any current-stage treatment assignment, want 0", exposed)
	}

	r.expose(key, "voice_circle_bonus")
	r.accept("promote with a current-stage exposed member", rolloutSetStageSQL, key, "active", "five_percent", 5)
	r.accept("pause five_percent without a new cohort", rolloutSetStageSQL, key, "paused", "five_percent", 5)
}

func TestProgressionRolloutInsertMustStartAtDraftPostgres(t *testing.T) {
	r := beginRolloutTx(t, progressionRolloutDB(t))
	insert := `INSERT INTO progression.experiments(key,name,status,rollout_stage,rollout_percent,variants,
		safety_stop_owner,last_safety_review_at,stage_evidence_uri,stage_started_at)
		VALUES ($1,'Rollout insert QA',$2,$3,$4,'{"control":{"multiplier":1.0}}',
		'progression-oncall',NOW(),'qa://rollout-insert',NOW())`
	newKey := func() string { return "qa_rollout_" + strings.ReplaceAll(uuid.NewString()[:8], "-", "") }

	cases := []struct {
		status, stage string
		percent       int
	}{
		{"active", "general_availability", 100},
		{"completed", "general_availability", 100},
		{"active", "dogfood", 1},
		{"paused", "twenty_five_percent", 25},
		{"active", "draft", 0},
	}
	for _, c := range cases {
		err := r.reject("insert "+c.status+"/"+c.stage, "must start at the draft stage", insert, newKey(), c.status, c.stage, c.percent)
		var pgErr *pgconn.PgError
		if !errors.As(err, &pgErr) || pgErr.ConstraintName != "progression_rollout_initial_stage" {
			t.Fatalf("insert %s/%s rejected without the initial-stage constraint: %v", c.status, c.stage, err)
		}
	}
	r.accept("insert draft/draft", insert, newKey(), "draft", "draft", 0)
}

func TestProgressionRolloutHistoryIsAppendOnlyPostgres(t *testing.T) {
	r := beginRolloutTx(t, progressionRolloutDB(t))
	key := r.experiment()
	actor := r.member()
	var id int64
	if err := r.tx.QueryRow(`INSERT INTO progression.rollout_stage_history
		(experiment_key,from_stage,to_stage,from_status,to_status,rollout_percent,
		 safety_stop_owner,evidence_uri,decision_note,actor_id)
		VALUES ($1,'draft','dogfood','draft','active',1,'progression-oncall','qa://history',
		 'Append-only history verification.',$2) RETURNING id`, key, actor).Scan(&id); err != nil {
		t.Fatalf("append history row: %v", err)
	}

	r.reject("update history", "append-only", `UPDATE progression.rollout_stage_history SET decision_note='Rewritten decision note.' WHERE id=$1`, id)
	r.reject("delete history", "append-only", `DELETE FROM progression.rollout_stage_history WHERE id=$1`, id)
	r.reject("truncate history", "append-only", `TRUNCATE progression.rollout_stage_history`)

	var note string
	if err := r.tx.QueryRow(`SELECT decision_note FROM progression.rollout_stage_history WHERE id=$1`, id).Scan(&note); err != nil {
		t.Fatalf("history row missing after rejected mutations: %v", err)
	}
	if note != "Append-only history verification." {
		t.Fatalf("history row changed: %q", note)
	}
}

// The API refuses a promotion without an exposed cohort before writing
// anything. The seed is committed (the handler uses its own transaction) and
// parked at paused/dogfood so runtime XP assignment never selects it.
func TestAdminUpdateProgressionExperimentRejectsPromotionWithoutCohortPostgres(t *testing.T) {
	db := progressionRolloutDB(t)
	ctx := context.Background()
	key := "qa_rollout_" + strings.ReplaceAll(uuid.NewString()[:8], "-", "")
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		t.Fatal(err)
	}
	_, err = tx.Exec(`INSERT INTO progression.experiments(key,name,variants)
		VALUES ($1,'Rollout API QA','{"control":{"multiplier":1.0}}')`, key)
	if err == nil {
		_, err = tx.Exec(rolloutSetStageSQL, key, "active", "dogfood", 1)
	}
	if err == nil {
		_, err = tx.Exec(rolloutSetStageSQL, key, "paused", "dogfood", 1)
	}
	if err == nil {
		err = tx.Commit()
	}
	if err != nil {
		_ = tx.Rollback()
		t.Fatalf("seed experiment: %v", err)
	}
	t.Cleanup(func() {
		if _, err := db.Exec(`DELETE FROM progression.experiments WHERE key=$1`, key); err != nil {
			t.Logf("cleanup experiment %s: %v", key, err)
		}
	})

	body := `{"status":"active","rollout_stage":"five_percent","rollout_percent":5,
		"safety_stop_owner":"progression-oncall","evidence_uri":"qa://rollout-api",
		"decision_note":"Promotion attempted without an exposed cohort."}`
	req := httptest.NewRequest(http.MethodPut, "/v1/admin/progression/experiments/"+key, strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	routeContext := chi.NewRouteContext()
	routeContext.URLParams.Add("key", key)
	reqCtx := context.WithValue(req.Context(), chi.RouteCtxKey, routeContext)
	reqCtx = context.WithValue(reqCtx, securityPrincipalContextKey{}, securityPrincipal{
		UserID: uuid.NewString(), Roles: map[string]bool{"admin": true},
	})
	recorder := httptest.NewRecorder()
	(&Server{progression: newLevelProgressionRepository(db)}).adminUpdateProgressionExperiment(recorder, req.WithContext(reqCtx))

	if recorder.Code != http.StatusConflict {
		t.Fatalf("status = %d, want 409; body %s", recorder.Code, recorder.Body.String())
	}
	var response map[string]any
	if err := json.Unmarshal(recorder.Body.Bytes(), &response); err != nil {
		t.Fatal(err)
	}
	if response["error_code"] != "PROGRESSION_ROLLOUT_COHORT_REQUIRED" || response["from_stage"] != "dogfood" || response["to_stage"] != "five_percent" {
		t.Fatalf("unexpected rejection payload: %v", response)
	}

	var stage, status string
	var history int
	if err := db.QueryRow(`SELECT e.rollout_stage,e.status,
		(SELECT COUNT(*) FROM progression.rollout_stage_history h WHERE h.experiment_key=e.key)
		FROM progression.experiments e WHERE e.key=$1`, key).Scan(&stage, &status, &history); err != nil {
		t.Fatal(err)
	}
	if stage != "dogfood" || status != "paused" || history != 0 {
		t.Fatalf("rejected promotion changed state: stage=%s status=%s history=%d", stage, status, history)
	}
}
