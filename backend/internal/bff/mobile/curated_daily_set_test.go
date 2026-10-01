package mobile

import (
	"context"
	"database/sql"
	"math"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
)

var curatedTestNow = time.Date(2026, 9, 27, 12, 0, 0, 0, time.UTC)

func approxEqual(a, b float64) bool { return math.Abs(a-b) < 1e-6 }

// ── Pure scoring ─────────────────────────────────────────────────────────────

func TestCuratedScoreWeightsSumToOneForAPerfectCandidate(t *testing.T) {
	if !approxEqual(curatedWeightReplyRate+curatedWeightTrustBadges+curatedWeightRecency+curatedWeightSharedTags, 1) {
		t.Fatal("ranking weights must sum to 1")
	}
	viewer := curatedViewer{IntentTags: []string{"long_term"}, LanguageTags: []string{"English"}}
	perfect := curatedSignals{
		UserID: "perfect", ReplyRate: 1, HasReplyHistory: true,
		ActiveBadges: append([]string{}, curatedBadgeCodes...),
		LastActiveAt: curatedTestNow.Add(-time.Hour),
		IntentTags:   []string{"Long_Term"}, LanguageTags: []string{"english"},
		LikesReceivedToday: 5, ImpressionsToday: fairExposureLowImpressionFloor,
	}
	got := scoreCuratedCandidate(perfect, viewer, 0.4, curatedTestNow)
	if !approxEqual(got.Score, 1) || got.FairExposure != "" {
		t.Fatalf("perfect candidate = %+v, want score 1 with no adjustment", got)
	}
	if got.Reply != 1 || got.Badges != 1 || got.Recency != 1 || got.Shared != 1 {
		t.Fatalf("components = %+v", got)
	}
}

func TestCuratedNewcomerGetsPopulationMedianNotZero(t *testing.T) {
	viewer := curatedViewer{}
	newcomer := curatedSignals{UserID: "new", HasReplyHistory: false, ImpressionsToday: 10}
	got := scoreCuratedCandidate(newcomer, viewer, 0.7, curatedTestNow)
	if !approxEqual(got.Reply, 0.7) {
		t.Fatalf("reply component for newcomer = %v, want the median 0.7", got.Reply)
	}
	if !approxEqual(got.Score, curatedWeightReplyRate*0.7) {
		t.Fatalf("score = %v", got.Score)
	}
	silent := newcomer
	silent.HasReplyHistory = true
	silent.ReplyRate = 0
	if got := scoreCuratedCandidate(silent, viewer, 0.7, curatedTestNow); got.Reply != 0 {
		t.Fatalf("a member who never replies must score 0 on reply, got %v", got.Reply)
	}
}

func TestCuratedRecencyDecays(t *testing.T) {
	base := curatedSignals{UserID: "r"}
	cases := []struct {
		age  time.Duration
		want float64
	}{
		{time.Hour, 1},
		{24 * time.Hour, 1},
		{curatedRecencyHorizon, 0},
		{30 * 24 * time.Hour, 0},
	}
	for _, c := range cases {
		sig := base
		sig.LastActiveAt = curatedTestNow.Add(-c.age)
		if got := curatedRecencyComponent(sig, curatedTestNow); !approxEqual(got, c.want) {
			t.Errorf("age %v: recency=%v want %v", c.age, got, c.want)
		}
	}
	mid := base
	mid.LastActiveAt = curatedTestNow.Add(-(24*time.Hour + (curatedRecencyHorizon-24*time.Hour)/2))
	if got := curatedRecencyComponent(mid, curatedTestNow); !approxEqual(got, 0.5) {
		t.Errorf("halfway through the horizon recency=%v want 0.5", got)
	}
	if got := curatedRecencyComponent(base, curatedTestNow); got != 0 {
		t.Errorf("unknown activity recency=%v want 0", got)
	}
}

func TestCuratedSharedTagsAreCaseInsensitive(t *testing.T) {
	viewer := curatedViewer{IntentTags: []string{"Marriage"}, LanguageTags: []string{"Hindi", "English"}}
	both := curatedSignals{IntentTags: []string{"marriage "}, LanguageTags: []string{"ENGLISH"}}
	if got := curatedSharedComponent(both, viewer); !approxEqual(got, 1) {
		t.Fatalf("shared intent and language = %v want 1", got)
	}
	intentOnly := curatedSignals{IntentTags: []string{"marriage"}, LanguageTags: []string{"Tamil"}}
	if got := curatedSharedComponent(intentOnly, viewer); !approxEqual(got, curatedIntentTagShare) {
		t.Fatalf("shared intent only = %v want %v", got, curatedIntentTagShare)
	}
	if got := curatedSharedComponent(curatedSignals{}, viewer); got != 0 {
		t.Fatalf("no tags = %v want 0", got)
	}
}

// ── Fair exposure ────────────────────────────────────────────────────────────

func TestCuratedFairExposureDownWeightsOverCapAndBoostsUnseen(t *testing.T) {
	over := curatedSignals{LikesReceivedToday: fairExposureDailyLikeCap + 1, ImpressionsToday: 10}
	if score, adj := applyFairExposure(1, over); !approxEqual(score, fairExposureOverCapMultiplier) || adj != "down_weighted" {
		t.Fatalf("over cap: score=%v adj=%q", score, adj)
	}
	atCap := curatedSignals{LikesReceivedToday: fairExposureDailyLikeCap, ImpressionsToday: 10}
	if score, adj := applyFairExposure(1, atCap); !approxEqual(score, 1) || adj != "" {
		t.Fatalf("at cap must not be down-weighted: score=%v adj=%q", score, adj)
	}
	unseen := curatedSignals{ImpressionsToday: fairExposureLowImpressionFloor - 1}
	if score, adj := applyFairExposure(0.5, unseen); !approxEqual(score, 0.5+fairExposureLowImpressionBoost) || adj != "boosted" {
		t.Fatalf("unseen: score=%v adj=%q", score, adj)
	}
	seen := curatedSignals{ImpressionsToday: fairExposureLowImpressionFloor}
	if score, adj := applyFairExposure(0.5, seen); !approxEqual(score, 0.5) || adj != "" {
		t.Fatalf("seen enough must not be boosted: score=%v adj=%q", score, adj)
	}
	both := curatedSignals{LikesReceivedToday: 100, ImpressionsToday: 0}
	if score, adj := applyFairExposure(1, both); !approxEqual(score, fairExposureOverCapMultiplier+fairExposureLowImpressionBoost) || adj != "down_weighted_and_boosted" {
		t.Fatalf("both: score=%v adj=%q", score, adj)
	}
}

func TestCuratedRankLetsTheMiddleGetSeen(t *testing.T) {
	viewer := curatedViewer{IntentTags: []string{"long_term"}}
	popular := curatedSignals{
		UserID: "popular", ReplyRate: 0.9, HasReplyHistory: true,
		ActiveBadges: []string{trustBadgeVerifiedActive, trustBadgeShowsUp},
		LastActiveAt: curatedTestNow, IntentTags: []string{"long_term"},
		LikesReceivedToday: 80, ImpressionsToday: 40,
	}
	middle := curatedSignals{
		UserID: "middle", ReplyRate: 0.6, HasReplyHistory: true,
		ActiveBadges: []string{trustBadgeVerifiedActive},
		LastActiveAt: curatedTestNow.Add(-2 * 24 * time.Hour), IntentTags: []string{"long_term"},
		LikesReceivedToday: 3, ImpressionsToday: 0,
	}
	ranked := rankCuratedCandidates([]curatedSignals{popular, middle}, viewer, 0.5, curatedTestNow, curatedDailySetSize)
	if len(ranked) != 2 || ranked[0].UserID != "middle" {
		t.Fatalf("ranking = %+v; the member past the like cap should sit below the unseen mid-distribution member", ranked)
	}
	if ranked[1].FairExposure != "down_weighted" || ranked[0].FairExposure != "boosted" {
		t.Fatalf("adjustments = %q / %q", ranked[0].FairExposure, ranked[1].FairExposure)
	}
}

func TestCuratedRankIsDeterministicAndBounded(t *testing.T) {
	viewer := curatedViewer{}
	candidates := make([]curatedSignals, 0, 8)
	for _, id := range []string{"h", "c", "a", "f", "b", "g", "e", "d"} {
		candidates = append(candidates, curatedSignals{UserID: id, ImpressionsToday: 10})
	}
	candidates = append(candidates, curatedSignals{UserID: "", ImpressionsToday: 10})
	ranked := rankCuratedCandidates(candidates, viewer, 0.5, curatedTestNow, curatedDailySetSize)
	if len(ranked) != curatedDailySetSize {
		t.Fatalf("len = %d want %d", len(ranked), curatedDailySetSize)
	}
	got := make([]string, 0, len(ranked))
	for _, item := range ranked {
		got = append(got, item.UserID)
	}
	if strings.Join(got, "") != "abcde" {
		t.Fatalf("equal scores must be ordered by user id, got %v", got)
	}
}

// ── Explainability ───────────────────────────────────────────────────────────

func TestCuratedReasonsFollowThePriorityOrderAndCap(t *testing.T) {
	viewer := curatedViewer{IntentTags: []string{"long_term"}, LanguageTags: []string{"English"}, ReplyRate: 0.8, HasReplyHistory: true}
	everything := curatedSignals{
		UserID: "all", ReplyRate: 0.9, HasReplyHistory: true,
		ActiveBadges: append([]string{}, curatedBadgeCodes...),
		LastActiveAt: curatedTestNow, IntentTags: []string{"long_term"}, LanguageTags: []string{"English"},
	}
	got := curatedReasonsFor(everything, viewer, curatedTestNow)
	want := []string{curatedReasonBothReply, curatedReasonSharesIntent, curatedReasonVerifiedActive}
	if strings.Join(got, "|") != strings.Join(want, "|") {
		t.Fatalf("reasons = %v want %v", got, want)
	}
	if why := curatedWhy(got); why != "Picked for you today: "+curatedReasonBothReply+" · "+curatedReasonSharesIntent {
		t.Fatalf("why = %q", why)
	}

	// A viewer without reply history never gets told "both" reply.
	quietViewer := curatedViewer{}
	got = curatedReasonsFor(everything, quietViewer, curatedTestNow)
	if got[0] != curatedReasonRepliesWithinDay {
		t.Fatalf("reasons for a viewer without history = %v", got)
	}

	// Below the reply threshold the reply reason is withheld.
	slow := everything
	slow.ReplyRate = 0.5
	slow.ActiveBadges = nil
	got = curatedReasonsFor(slow, viewer, curatedTestNow)
	if strings.Join(got, "|") != strings.Join([]string{curatedReasonSharesIntent, curatedReasonSpeaksLanguage, curatedReasonActiveThisWeek}, "|") {
		t.Fatalf("reasons for a slow replier = %v", got)
	}

	if got := curatedReasonsFor(curatedSignals{UserID: "blank"}, viewer, curatedTestNow); len(got) != 0 {
		t.Fatalf("no signals must yield no reasons, got %v", got)
	}
	if why := curatedWhy(nil); why != "New to you today." {
		t.Fatalf("why for no reasons = %q", why)
	}
}

func TestAttachDiscoveryReasonsGivesEveryCandidateAList(t *testing.T) {
	resp := map[string]any{"candidates": []any{
		map[string]any{"id": "known"},
		map[string]any{"user_id": "other"},
		"not a row",
	}}
	attachDiscoveryReasons(resp, map[string]curatedExplanation{
		"known": {Reasons: []string{curatedReasonShowsUp}},
	})
	rows := resp["candidates"].([]any)
	if got := rows[0].(map[string]any)["reasons"].([]string); len(got) != 1 || got[0] != curatedReasonShowsUp {
		t.Fatalf("known reasons = %v", got)
	}
	if got := rows[1].(map[string]any)["reasons"].([]string); len(got) != 0 {
		t.Fatalf("unknown candidate must get an empty list, got %v", got)
	}
}

func TestCuratedDailySetRouteIsFlagGated(t *testing.T) {
	if got := featureFlagForRoute("/v1", "/v1/discovery/u1/today"); got != "curated_daily_set_enabled" {
		t.Fatalf("featureFlagForRoute(today)=%q", got)
	}
	if got := featureFlagForRoute("/v1", "/v1/discovery/u1"); got != "" {
		t.Fatalf("the main deck must stay ungated, got %q", got)
	}
	if !pathOwnedByPrincipal("/v1", "/v1/discovery/u1/today", "GET", "u1") ||
		pathOwnedByPrincipal("/v1", "/v1/discovery/u1/today", "GET", "u2") {
		t.Fatal("the curated set must be self-owned")
	}
}

// ── Postgres ─────────────────────────────────────────────────────────────────

func TestCuratedDailySetIsStableWithinADayAndCountsImpressions(t *testing.T) {
	dsn := os.Getenv("PROFILE_TEST_DATABASE_URL")
	if dsn == "" {
		t.Skip("PROFILE_TEST_DATABASE_URL is not set")
	}
	db, err := sql.Open("pgx", dsn)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = db.Close() })
	ctx := context.Background()
	var ready bool
	if err := db.QueryRowContext(ctx, `SELECT to_regclass('matching.daily_candidate_sets') IS NOT NULL AND to_regclass('matching.member_exposure_counters') IS NOT NULL`).Scan(&ready); err != nil {
		t.Fatal(err)
	}
	if !ready {
		t.Skip("migration 095_curated_daily_set is not applied")
	}

	seed := func(name string) string {
		id := uuid.NewString()
		username := "curqa_" + strings.ReplaceAll(id[:8], "-", "")
		if _, err := db.ExecContext(ctx, `INSERT INTO user_management.users (id, username, name, date_of_birth, gender, email)
			VALUES ($1,$2,$3,'1994-05-05','female',$4)`, id, username, name, username+"@example.test"); err != nil {
			t.Fatalf("seed member %s: %v", name, err)
		}
		t.Cleanup(func() { _, _ = db.ExecContext(ctx, `DELETE FROM user_management.users WHERE id=$1`, id) })
		return id
	}
	viewer := seed("Viewer")
	names := []string{"Asha", "Bina", "Chitra", "Devi", "Esha", "Farah", "Gita"}
	pool := make([]map[string]any, 0, len(names))
	ids := make([]string, 0, len(names))
	for _, name := range names {
		id := seed(name)
		ids = append(ids, id)
		pool = append(pool, map[string]any{"id": id, "name": name, "isVerified": true})
	}
	badged := ids[0]
	if _, err := db.ExecContext(ctx, `INSERT INTO matching.user_trust_badges (user_id, badge_code, status, awarded_at)
		VALUES ($1,'verified_active','active',NOW()),($1,'shows_up','active',NOW())`, badged); err != nil {
		t.Fatalf("seed badges: %v", err)
	}
	if _, err := db.ExecContext(ctx, `INSERT INTO user_management.preferences (user_id, intent_tags, language_tags)
		VALUES ($1, ARRAY['long_term'], ARRAY['English']), ($2, ARRAY['long_term'], ARRAY['Tamil'])`, viewer, badged); err != nil {
		t.Fatalf("seed preferences: %v", err)
	}

	svc := newCuratedDailySetService(db)
	svc.now = func() time.Time { return curatedTestNow }
	setDate := curatedSetDate(curatedTestNow)
	t.Cleanup(func() {
		_, _ = db.ExecContext(ctx, `DELETE FROM matching.daily_candidate_sets WHERE user_id=$1`, viewer)
		_, _ = db.ExecContext(ctx, `DELETE FROM matching.member_exposure_counters WHERE user_id = ANY($1::uuid[])`, ids)
	})

	first, err := svc.serve(ctx, viewer, pool)
	if err != nil {
		t.Fatalf("first serve: %v", err)
	}
	if !first.Generated || first.SetDate != setDate || first.ModelVersion != curatedDailySetModelVersion {
		t.Fatalf("first serve = %+v", first)
	}
	if len(first.Candidates) != curatedDailySetSize {
		t.Fatalf("first serve returned %d candidates, want %d", len(first.Candidates), curatedDailySetSize)
	}
	if got := candidateIdentity(first.Candidates[0]); got != badged {
		t.Fatalf("top candidate = %s, want the badged member sharing the viewer's intent (%s)", got, badged)
	}
	reasons, _ := first.Candidates[0]["reasons"].([]string)
	if strings.Join(reasons, "|") != strings.Join([]string{curatedReasonSharesIntent, curatedReasonVerifiedActive, curatedReasonShowsUp}, "|") {
		t.Fatalf("top candidate reasons = %v", reasons)
	}
	if why, _ := first.Candidates[0]["why"].(string); !strings.HasPrefix(why, "Picked for you today: ") {
		t.Fatalf("why = %q", why)
	}
	// The stored row carries every candidate and their explanations.
	stored, err := svc.loadStoredSet(ctx, viewer, setDate)
	if err != nil || stored == nil || len(stored.CandidateIDs) != curatedDailySetSize {
		t.Fatalf("stored set = %+v err=%v", stored, err)
	}

	// Same day, shuffled pool, one candidate since swiped (absent from the
	// pool): the same set comes back minus the swiped member, in the same
	// order, and the stored row is untouched.
	swiped := candidateIdentity(first.Candidates[2])
	reversed := make([]map[string]any, 0, len(pool))
	for i := len(pool) - 1; i >= 0; i-- {
		if candidateIdentity(pool[i]) != swiped {
			reversed = append(reversed, pool[i])
		}
	}
	second, err := svc.serve(ctx, viewer, reversed)
	if err != nil {
		t.Fatalf("second serve: %v", err)
	}
	if second.Generated || !second.GeneratedAt.Equal(first.GeneratedAt) {
		t.Fatalf("second serve regenerated the set: %+v", second)
	}
	wantIDs := make([]string, 0, curatedDailySetSize-1)
	for _, row := range first.Candidates {
		if id := candidateIdentity(row); id != swiped {
			wantIDs = append(wantIDs, id)
		}
	}
	gotIDs := make([]string, 0, len(second.Candidates))
	for _, row := range second.Candidates {
		gotIDs = append(gotIDs, candidateIdentity(row))
	}
	if strings.Join(gotIDs, ",") != strings.Join(wantIDs, ",") {
		t.Fatalf("second serve = %v want %v", gotIDs, wantIDs)
	}
	again, err := svc.loadStoredSet(ctx, viewer, setDate)
	if err != nil || again == nil || strings.Join(again.CandidateIDs, ",") != strings.Join(stored.CandidateIDs, ",") {
		t.Fatalf("stored row changed: %+v err=%v", again, err)
	}

	// Impressions: served twice for the four still-eligible members, once
	// for the swiped one, never for members outside the set.
	var twice, once, never int
	if err := db.QueryRowContext(ctx, `
		SELECT COUNT(*) FILTER (WHERE impressions = 2), COUNT(*) FILTER (WHERE impressions = 1),
		       $3::int - COUNT(*)
		FROM matching.member_exposure_counters
		WHERE counter_date = $1::date AND user_id = ANY($2::uuid[])`, setDate, ids, len(ids)).Scan(&twice, &once, &never); err != nil {
		t.Fatal(err)
	}
	if twice != curatedDailySetSize-1 || once != 1 || never != len(ids)-curatedDailySetSize {
		t.Fatalf("impressions twice=%d once=%d never=%d", twice, once, never)
	}
}
