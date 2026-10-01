package mobile

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"net/url"
	"sort"
	"strings"
	"time"

	matchingapp "github.com/verified-dating/backend/internal/modules/matching/application"
)

// Curated daily set (migration 095, DISC-003).
//
// Each member gets up to curatedDailySetSize candidates per UTC day, chosen
// from their ordinary eligible deck — the same mediator command and the same
// block, publication, preference and trust filters getDiscoveryCandidates
// applies — and persisted in matching.daily_candidate_sets so the set is
// stable across reloads. Ranking replaces the deck's newest-first order for
// this set only; the main deck order is untouched, and paid spotlight
// (spotlight.go) is never consulted here.
//
// The scoring functions in this file are pure so the weights, the
// fair-exposure adjustment and the reason catalogue have unit tests.

const (
	// curatedDailySetModelVersion is stored with every generated set so a
	// later change to the weights or the reason catalogue is attributable.
	curatedDailySetModelVersion = "curated_daily_set.v1"
	curatedDailySetSize         = 5
	curatedReasonLimit          = 3
	// curatedPoolLimit is how much of the eligible deck is scored. The
	// mediator caps candidate requests at 300.
	curatedPoolLimit = 300

	// Ranking weights. They sum to 1 so a perfect candidate scores 1.0
	// before fair-exposure adjustment.
	curatedWeightReplyRate   = 0.35
	curatedWeightTrustBadges = 0.25
	curatedWeightRecency     = 0.20
	curatedWeightSharedTags  = 0.20

	// Fair exposure (DISC-003: paid visibility never defeats eligibility;
	// the middle of the distribution must get seen). A member who already
	// received more than fairExposureDailyLikeCap likes today is
	// down-weighted; a member served fewer than fairExposureLowImpressionFloor
	// times today gets a small boost.
	fairExposureDailyLikeCap        = 30
	fairExposureLowImpressionFloor  = 3
	fairExposureOverCapMultiplier   = 0.6
	fairExposureLowImpressionBoost  = 0.08
	curatedReplyRateDefault         = 0.5
	curatedReplyRateReasonThreshold = 0.6
	curatedRecencyHorizon           = 14 * 24 * time.Hour
	curatedActiveThisWeek           = 7 * 24 * time.Hour
	curatedIntentTagShare           = 0.6
	curatedLanguageTagShare         = 0.4
)

// Fixed reason catalogue. The client renders these verbatim as chips, so the
// strings are the contract.
const (
	curatedReasonBothReply         = "Both reply within a day"
	curatedReasonRepliesWithinDay  = "Replies within a day"
	curatedReasonVerifiedActive    = "Verified & active"
	curatedReasonShowsUp           = "Shows up"
	curatedReasonRespectful        = "Respectful communicator"
	curatedReasonSharesIntent      = "Shares your intent"
	curatedReasonSpeaksLanguage    = "Speaks your language"
	curatedReasonActiveThisWeek    = "Active this week"
	curatedReasonConsistentProfile = "Consistent profile"
	curatedReasonPromptCompleter   = "Completes prompts"
)

// curatedBadgeCodes are the trust badges that count towards the badge
// component, in catalogue order (shows_up was added by migration 092).
var curatedBadgeCodes = []string{
	trustBadgeRespectfulCommunicator,
	trustBadgeVerifiedActive,
	trustBadgeShowsUp,
	trustBadgeConsistentProfile,
	trustBadgePromptCompleter,
}

// curatedSignals is everything the ranker knows about one candidate.
type curatedSignals struct {
	Dating             datingPreferences
	UserID             string
	ReplyRate          float64
	HasReplyHistory    bool
	ActiveBadges       []string
	LastActiveAt       time.Time
	IntentTags         []string
	LanguageTags       []string
	LikesReceivedToday int
	ImpressionsToday   int
}

// curatedViewer is what the ranker knows about the member being served.
type curatedViewer struct {
	Dating          datingPreferences
	IntentTags      []string
	LanguageTags    []string
	ReplyRate       float64
	HasReplyHistory bool
}

// curatedScore is the ranker's verdict on one candidate.
type curatedScore struct {
	UserID       string   `json:"user_id"`
	Score        float64  `json:"score"`
	Reply        float64  `json:"reply"`
	Badges       float64  `json:"badges"`
	Recency      float64  `json:"recency"`
	Shared       float64  `json:"shared"`
	FairExposure string   `json:"fair_exposure,omitempty"`
	Reasons      []string `json:"reasons"`
	Why          string   `json:"why"`
}

// curatedExplanation is what is persisted per candidate in the reasons JSONB.
type curatedExplanation struct {
	Reasons      []string `json:"reasons"`
	Why          string   `json:"why"`
	Score        float64  `json:"score"`
	FairExposure string   `json:"fair_exposure,omitempty"`
}

// ── Pure scoring ─────────────────────────────────────────────────────────────

func normalizedTagSet(tags []string) map[string]bool {
	out := make(map[string]bool, len(tags))
	for _, tag := range tags {
		key := strings.ToLower(strings.TrimSpace(tag))
		if key != "" {
			out[key] = true
		}
	}
	return out
}

func sharedTagCount(a, b []string) int {
	left := normalizedTagSet(a)
	n := 0
	for tag := range normalizedTagSet(b) {
		if left[tag] {
			n++
		}
	}
	return n
}

func hasBadge(badges []string, code string) bool {
	for _, badge := range badges {
		if strings.EqualFold(strings.TrimSpace(badge), code) {
			return true
		}
	}
	return false
}

// curatedReplyComponent is the candidate's 24-hour reply rate, or the
// population median when they have no inbound conversations yet. A newcomer
// is scored as typical, never as unresponsive.
func curatedReplyComponent(c curatedSignals, medianReplyRate float64) float64 {
	if !c.HasReplyHistory {
		return clamp01(medianReplyRate)
	}
	return clamp01(c.ReplyRate)
}

// curatedBadgeComponent is the share of the catalogue badges that are active.
func curatedBadgeComponent(c curatedSignals) float64 {
	n := 0
	for _, code := range curatedBadgeCodes {
		if hasBadge(c.ActiveBadges, code) {
			n++
		}
	}
	return float64(n) / float64(len(curatedBadgeCodes))
}

// curatedRecencyComponent is 1 for activity within the last day, decaying
// linearly to 0 at curatedRecencyHorizon. Unknown activity scores 0.
func curatedRecencyComponent(c curatedSignals, now time.Time) float64 {
	if c.LastActiveAt.IsZero() {
		return 0
	}
	age := now.Sub(c.LastActiveAt)
	if age <= 24*time.Hour {
		return 1
	}
	if age >= curatedRecencyHorizon {
		return 0
	}
	return 1 - float64(age-24*time.Hour)/float64(curatedRecencyHorizon-24*time.Hour)
}

// curatedSharedComponent rewards intent overlap more than language overlap;
// any overlap of each kind counts once.
func curatedSharedComponent(c curatedSignals, viewer curatedViewer) float64 {
	score := 0.0
	if sharedTagCount(c.IntentTags, viewer.IntentTags) > 0 {
		score += curatedIntentTagShare
	}
	if sharedTagCount(c.LanguageTags, viewer.LanguageTags) > 0 {
		score += curatedLanguageTagShare
	}
	return clamp01(score)
}

// applyFairExposure adjusts a base score for today's exposure. It never
// removes a candidate — eligibility was settled upstream — it only reorders.
func applyFairExposure(base float64, c curatedSignals) (float64, string) {
	score := base
	adjustment := ""
	if c.LikesReceivedToday > fairExposureDailyLikeCap {
		score *= fairExposureOverCapMultiplier
		adjustment = "down_weighted"
	}
	if c.ImpressionsToday < fairExposureLowImpressionFloor {
		score += fairExposureLowImpressionBoost
		if adjustment == "" {
			adjustment = "boosted"
		} else {
			adjustment = "down_weighted_and_boosted"
		}
	}
	return score, adjustment
}

// curatedReasonsFor picks up to curatedReasonLimit catalogue reasons in a
// fixed priority order, so the same signals always yield the same chips.
func curatedReasonsFor(c curatedSignals, viewer curatedViewer, now time.Time) []string {
	candidateReplies := c.HasReplyHistory && c.ReplyRate >= curatedReplyRateReasonThreshold
	viewerReplies := viewer.HasReplyHistory && viewer.ReplyRate >= curatedReplyRateReasonThreshold
	candidates := []struct {
		reason string
		ok     bool
	}{
		{curatedReasonBothReply, candidateReplies && viewerReplies},
		{curatedReasonRepliesWithinDay, candidateReplies && !viewerReplies},
		{curatedReasonSharesIntent, sharedTagCount(c.IntentTags, viewer.IntentTags) > 0},
		{curatedReasonVerifiedActive, hasBadge(c.ActiveBadges, trustBadgeVerifiedActive)},
		{curatedReasonShowsUp, hasBadge(c.ActiveBadges, trustBadgeShowsUp)},
		{curatedReasonRespectful, hasBadge(c.ActiveBadges, trustBadgeRespectfulCommunicator)},
		{curatedReasonSpeaksLanguage, sharedTagCount(c.LanguageTags, viewer.LanguageTags) > 0},
		{curatedReasonActiveThisWeek, !c.LastActiveAt.IsZero() && now.Sub(c.LastActiveAt) <= curatedActiveThisWeek},
		{curatedReasonConsistentProfile, hasBadge(c.ActiveBadges, trustBadgeConsistentProfile)},
		{curatedReasonPromptCompleter, hasBadge(c.ActiveBadges, trustBadgePromptCompleter)},
	}
	reasons := make([]string, 0, curatedReasonLimit)
	for _, item := range candidates {
		if item.ok {
			reasons = append(reasons, item.reason)
		}
		if len(reasons) == curatedReasonLimit {
			break
		}
	}
	return reasons
}

// curatedWhy is the one-line explanation shown under the chips.
func curatedWhy(reasons []string) string {
	if len(reasons) == 0 {
		return "New to you today."
	}
	shown := reasons
	if len(shown) > 2 {
		shown = shown[:2]
	}
	return "Picked for you today: " + strings.Join(shown, " · ")
}

// scoreCuratedCandidate is the pure ranker for one candidate.
func scoreCuratedCandidate(c curatedSignals, viewer curatedViewer, medianReplyRate float64, now time.Time) curatedScore {
	reply := curatedReplyComponent(c, medianReplyRate)
	badges := curatedBadgeComponent(c)
	recency := curatedRecencyComponent(c, now)
	shared := curatedSharedComponent(c, viewer)
	base := curatedWeightReplyRate*reply +
		curatedWeightTrustBadges*badges +
		curatedWeightRecency*recency +
		curatedWeightSharedTags*shared
	fit, _ := datingFit(viewer.Dating, c.Dating, now)
	base += float64(len(fit)) * 0.05
	score, adjustment := applyFairExposure(base, c)
	reasons := curatedReasonsFor(c, viewer, now)
	return curatedScore{
		UserID:       c.UserID,
		Score:        math.Round(score*10000) / 10000,
		Reply:        reply,
		Badges:       badges,
		Recency:      recency,
		Shared:       shared,
		FairExposure: adjustment,
		Reasons:      reasons,
		Why:          curatedWhy(reasons),
	}
}

// rankCuratedCandidates scores every candidate and returns the best `size`
// in descending score order, ties broken by user id so the result is
// deterministic.
func rankCuratedCandidates(candidates []curatedSignals, viewer curatedViewer, medianReplyRate float64, now time.Time, size int) []curatedScore {
	scored := make([]curatedScore, 0, len(candidates))
	for _, c := range candidates {
		if strings.TrimSpace(c.UserID) == "" {
			continue
		}
		scored = append(scored, scoreCuratedCandidate(c, viewer, medianReplyRate, now))
	}
	sort.SliceStable(scored, func(i, j int) bool {
		if scored[i].Score != scored[j].Score {
			return scored[i].Score > scored[j].Score
		}
		return scored[i].UserID < scored[j].UserID
	})
	if size > 0 && len(scored) > size {
		scored = scored[:size]
	}
	return scored
}

func clamp01(v float64) float64 {
	if v < 0 || math.IsNaN(v) {
		return 0
	}
	if v > 1 {
		return 1
	}
	return v
}

// ── Persistence ──────────────────────────────────────────────────────────────

type curatedDailySetService struct {
	db  *sql.DB
	now func() time.Time
}

func newCuratedDailySetService(db *sql.DB) *curatedDailySetService {
	if db == nil {
		return nil
	}
	return &curatedDailySetService{db: db, now: func() time.Time { return time.Now().UTC() }}
}

// curatedStoredSet mirrors one matching.daily_candidate_sets row.
type curatedStoredSet struct {
	SetDate      string
	CandidateIDs []string
	Explanations map[string]curatedExplanation
	ModelVersion string
	GeneratedAt  time.Time
}

// curatedDailySetResult is what the handler serialises.
type curatedDailySetResult struct {
	SetDate      string
	Candidates   []map[string]any
	ModelVersion string
	GeneratedAt  time.Time
	Generated    bool
}

func curatedSetDate(now time.Time) string {
	return now.UTC().Format("2006-01-02")
}

func (s *curatedDailySetService) loadStoredSet(ctx context.Context, viewerID, setDate string) (*curatedStoredSet, error) {
	var idsJSON, reasonsJSON string
	set := curatedStoredSet{SetDate: setDate, Explanations: map[string]curatedExplanation{}}
	err := s.db.QueryRowContext(ctx, `
		SELECT COALESCE(array_to_json(candidate_user_ids)::text, '[]'), reasons::text, model_version, generated_at
		FROM matching.daily_candidate_sets
		WHERE user_id = $1::uuid AND set_date = $2::date`, viewerID, setDate).
		Scan(&idsJSON, &reasonsJSON, &set.ModelVersion, &set.GeneratedAt)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	set.CandidateIDs = decodeJSONStringList(idsJSON)
	if err := json.Unmarshal([]byte(reasonsJSON), &set.Explanations); err != nil || set.Explanations == nil {
		set.Explanations = map[string]curatedExplanation{}
	}
	return &set, nil
}

// storeSet persists a freshly ranked set. A concurrent first request of the
// day wins by primary key; the caller re-reads so both requests serve the
// same set.
func (s *curatedDailySetService) storeSet(ctx context.Context, viewerID, setDate string, ranked []curatedScore) error {
	ids := make([]string, 0, len(ranked))
	explanations := make(map[string]curatedExplanation, len(ranked))
	for _, item := range ranked {
		ids = append(ids, item.UserID)
		explanations[item.UserID] = curatedExplanation{
			Reasons: item.Reasons, Why: item.Why, Score: item.Score, FairExposure: item.FairExposure,
		}
	}
	reasonsJSON, err := json.Marshal(explanations)
	if err != nil {
		return err
	}
	_, err = s.db.ExecContext(ctx, `
		INSERT INTO matching.daily_candidate_sets (user_id, set_date, candidate_user_ids, reasons, model_version)
		VALUES ($1::uuid, $2::date, ARRAY(SELECT jsonb_array_elements_text($3::jsonb))::uuid[], $4::jsonb, $5)
		ON CONFLICT (user_id, set_date) DO NOTHING`,
		viewerID, setDate, jsonStringList(ids), string(reasonsJSON), curatedDailySetModelVersion)
	return err
}

// populationMedianReplyRate is the median 24-hour reply rate across every
// member with inbound conversations in the last 30 days.
func (s *curatedDailySetService) populationMedianReplyRate(ctx context.Context) (float64, error) {
	var median float64
	err := s.db.QueryRowContext(ctx, `
		SELECT COALESCE(percentile_cont(0.5) WITHIN GROUP (ORDER BY reply_rate::float8), $1::float8)
		FROM matching.member_reply_signals`, curatedReplyRateDefault).Scan(&median)
	return median, err
}

const curatedSignalsQuery = `
WITH day AS (
  SELECT ($2::date)::timestamp AT TIME ZONE 'UTC' AS starts_at,
         (($2::date) + 1)::timestamp AT TIME ZONE 'UTC' AS ends_at
),
likes AS (
  SELECT sw.target_user_id AS user_id, COUNT(*)::int AS likes_today
  FROM matching.swipes sw, day
  WHERE sw.is_like AND sw.created_at >= day.starts_at AND sw.created_at < day.ends_at
    AND sw.target_user_id = ANY($1::uuid[])
  GROUP BY sw.target_user_id
)
SELECT u.id::text,
       COALESCE(rs.reply_rate, 0)::float8,
       COALESCE(rs.inbound_conversations, 0)::int,
       COALESCE(badges.codes, '[]'::jsonb)::text,
       COALESCE(mla.last_active_at, u.updated_at),
       COALESCE(array_to_json(p.intent_tags)::text, '[]'),
       COALESCE(array_to_json(p.language_tags)::text, '[]'),
       COALESCE(likes.likes_today, 0),
       COALESCE(ex.impressions, 0)
FROM user_management.users u
LEFT JOIN matching.member_reply_signals rs ON rs.user_id = u.id
LEFT JOIN LATERAL (
  SELECT jsonb_agg(b.badge_code ORDER BY b.badge_code) AS codes
  FROM matching.user_trust_badges b
  WHERE b.user_id = u.id AND b.status = 'active'
) badges ON TRUE
LEFT JOIN platform.member_last_activity mla ON mla.user_id = u.id
LEFT JOIN user_management.preferences p ON p.user_id = u.id
LEFT JOIN likes ON likes.user_id = u.id
LEFT JOIN matching.member_exposure_counters ex ON ex.user_id = u.id AND ex.counter_date = $2::date
WHERE u.id = ANY($1::uuid[])`

// loadSignals reads the ranking inputs for the given members (candidates and
// the viewer) in one query.
func (s *curatedDailySetService) loadSignals(ctx context.Context, userIDs []string, setDate string) (map[string]curatedSignals, error) {
	out := make(map[string]curatedSignals, len(userIDs))
	if len(userIDs) == 0 {
		return out, nil
	}
	rows, err := s.db.QueryContext(ctx, curatedSignalsQuery, userIDs, setDate)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		var (
			sig                                  curatedSignals
			inbound                              int
			badgesJSON, intentJSON, languageJSON string
			lastActive                           sql.NullTime
		)
		if err := rows.Scan(&sig.UserID, &sig.ReplyRate, &inbound, &badgesJSON, &lastActive,
			&intentJSON, &languageJSON, &sig.LikesReceivedToday, &sig.ImpressionsToday); err != nil {
			return nil, err
		}
		sig.HasReplyHistory = inbound > 0
		sig.ActiveBadges = decodeJSONStringList(badgesJSON)
		sig.IntentTags = decodeJSONStringList(intentJSON)
		sig.LanguageTags = decodeJSONStringList(languageJSON)
		if lastActive.Valid {
			sig.LastActiveAt = lastActive.Time
		}
		out[sig.UserID] = sig
	}
	return out, rows.Err()
}

// recordImpressions counts one impression per served candidate for today and
// mirrors today's likes from matching.swipes into the counter row.
func (s *curatedDailySetService) recordImpressions(ctx context.Context, userIDs []string, setDate string) error {
	if len(userIDs) == 0 {
		return nil
	}
	_, err := s.db.ExecContext(ctx, `
		INSERT INTO matching.member_exposure_counters (user_id, counter_date, impressions, likes_received)
		SELECT m.id, $2::date, 1,
		       (SELECT COUNT(*) FROM matching.swipes sw
		         WHERE sw.target_user_id = m.id AND sw.is_like
		           AND sw.created_at >= ($2::date)::timestamp AT TIME ZONE 'UTC'
		           AND sw.created_at < (($2::date) + 1)::timestamp AT TIME ZONE 'UTC')
		FROM unnest($1::uuid[]) AS m(id)
		ON CONFLICT (user_id, counter_date) DO UPDATE
		SET impressions = matching.member_exposure_counters.impressions + 1,
		    likes_received = EXCLUDED.likes_received,
		    updated_at = NOW()`, userIDs, setDate)
	return err
}

// serve returns today's curated set for the viewer, generating and storing
// it from `pool` on the first request of the day. `pool` is the viewer's
// eligible deck, already filtered; candidates the viewer has since swiped,
// blocked or matched are absent from it and are therefore dropped from the
// response, never from the stored row.
func (s *curatedDailySetService) serve(ctx context.Context, viewerID string, pool []map[string]any) (curatedDailySetResult, error) {
	now := s.now()
	setDate := curatedSetDate(now)
	result := curatedDailySetResult{SetDate: setDate, Candidates: []map[string]any{}, ModelVersion: curatedDailySetModelVersion}

	byID := make(map[string]map[string]any, len(pool))
	poolIDs := make([]string, 0, len(pool))
	for _, row := range pool {
		id := candidateIdentity(row)
		if id == "" || id == viewerID {
			continue
		}
		if _, seen := byID[id]; seen {
			continue
		}
		byID[id] = row
		poolIDs = append(poolIDs, id)
	}

	stored, err := s.loadStoredSet(ctx, viewerID, setDate)
	if err != nil {
		return result, err
	}
	if stored == nil {
		ranked, err := s.rank(ctx, viewerID, poolIDs, setDate, now)
		if err != nil {
			return result, err
		}
		if len(ranked) == 0 {
			// Nothing eligible right now (new member, strict filters). Do not
			// pin an empty set to the day; the next request tries again.
			return result, nil
		}
		if err := s.storeSet(ctx, viewerID, setDate, ranked); err != nil {
			return result, err
		}
		result.Generated = true
		if stored, err = s.loadStoredSet(ctx, viewerID, setDate); err != nil {
			return result, err
		}
		if stored == nil {
			return result, errors.New("curated daily set was not persisted")
		}
	}
	result.ModelVersion = stored.ModelVersion
	result.GeneratedAt = stored.GeneratedAt

	dating, err := loadDatingPreferenceSet(ctx, s.db, append(append([]string{}, stored.CandidateIDs...), viewerID))
	if err != nil {
		return result, err
	}
	served := make([]string, 0, len(stored.CandidateIDs))
	for _, id := range stored.CandidateIDs {
		row, eligible := byID[id]
		if !eligible {
			continue
		}
		out := make(map[string]any, len(row)+2)
		for key, value := range row {
			out[key] = value
		}
		explanation := stored.Explanations[id]
		if explanation.Reasons == nil {
			explanation.Reasons = []string{}
		}
		fit, overlap := datingFit(dating[viewerID], dating[id], now)
		shared := []string{}
		for _, activity := range dating[viewerID].Activities {
			if sharedTagCount([]string{activity}, dating[id].Activities) > 0 {
				shared = append(shared, activity)
			}
		}
		out["shared_activities"] = shared
		out["availability_overlaps"] = len(overlap) > 0
		if len(fit) > 0 {
			explanation.Reasons = append(fit, explanation.Reasons...)
			if len(explanation.Reasons) > curatedReasonLimit {
				explanation.Reasons = explanation.Reasons[:curatedReasonLimit]
			}
			explanation.Why = curatedWhy(explanation.Reasons)
		}
		out["reasons"] = explanation.Reasons
		out["why"] = explanation.Why
		result.Candidates = append(result.Candidates, out)
		served = append(served, id)
	}
	if err := s.recordImpressions(ctx, served, setDate); err != nil {
		return result, err
	}
	return result, nil
}

// rank loads signals for the viewer and the pool and returns the top set.
func (s *curatedDailySetService) rank(ctx context.Context, viewerID string, poolIDs []string, setDate string, now time.Time) ([]curatedScore, error) {
	if len(poolIDs) == 0 {
		return []curatedScore{}, nil
	}
	median, err := s.populationMedianReplyRate(ctx)
	if err != nil {
		return nil, err
	}
	signals, err := s.loadSignals(ctx, append(append([]string{}, poolIDs...), viewerID), setDate)
	if err != nil {
		return nil, err
	}
	dating, err := loadDatingPreferenceSet(ctx, s.db, append(append([]string{}, poolIDs...), viewerID))
	if err != nil {
		return nil, err
	}
	for id, sig := range signals {
		sig.Dating = dating[id]
		signals[id] = sig
	}
	viewerSignals := signals[viewerID]
	viewer := curatedViewer{
		Dating:     viewerSignals.Dating,
		IntentTags: viewerSignals.IntentTags, LanguageTags: viewerSignals.LanguageTags,
		ReplyRate: viewerSignals.ReplyRate, HasReplyHistory: viewerSignals.HasReplyHistory,
	}
	candidates := make([]curatedSignals, 0, len(poolIDs))
	for _, id := range poolIDs {
		sig, ok := signals[id]
		if !ok {
			// Not in user_management.users any more; the deck filters will
			// drop it on the next request, so do not rank it.
			continue
		}
		candidates = append(candidates, sig)
	}
	return rankCuratedCandidates(candidates, viewer, median, now, curatedDailySetSize), nil
}

// ── Eligible pool ────────────────────────────────────────────────────────────

// curatedEligiblePool runs the same candidate pipeline as
// getDiscoveryCandidates (server.go) up to, but not including, trimming and
// paid spotlight: mediator command, symmetric block filter, publication and
// saved-preference filter, advanced filter and trust filter. It is the only
// source of candidates for the curated set, so nothing here can be seen that
// the deck would not show.
func (s *Server) curatedEligiblePool(ctx context.Context, userID string, filters ...url.Values) ([]map[string]any, error) {
	query := url.Values{}
	if len(filters) > 0 {
		query = filters[0]
	}
	respAny, err := s.mediator.Send(
		ctx,
		matchingapp.GetCandidatesCommandName,
		matchingapp.GetCandidatesCommand{UserID: userID, Limit: curatedPoolLimit},
	)
	if err != nil {
		return nil, err
	}
	resp, ok := respAny.(map[string]any)
	if !ok {
		return nil, errors.New("unexpected discovery candidates response payload")
	}
	s.attachBlockedFilteredDiscovery(ctx, resp, userID)
	if s.cfg.UseLocalDB || (s.store != nil && s.store.profileRepo != nil && s.store.profileRepo.pg != nil) {
		if s.store == nil || s.store.profileRepo == nil || s.store.profileRepo.pg == nil {
			return nil, errors.New("discovery publication persistence is unavailable")
		}
		if err := filterPublishedDiscovery(ctx, s.store.profileRepo.pg, userID, resp, s.buildAdvancedCriteria(userID, s.discoveryPreferenceQuery(userID, query))); err != nil {
			return nil, fmt.Errorf("discovery publication filter: %w", err)
		}
	}
	if _, filtered := resp["advanced_filter"]; !filtered {
		s.attachAdvancedFilteredDiscovery(resp, userID, query)
	}
	s.attachTrustFilteredDiscovery(resp, userID)

	rows, _ := resp["candidates"].([]any)
	pool := make([]map[string]any, 0, len(rows))
	for _, raw := range rows {
		if row, ok := raw.(map[string]any); ok {
			pool = append(pool, row)
		}
	}
	return pool, nil
}

// curatedReasonsForDeck returns today's stored reasons for the viewer, keyed
// by candidate id, so the main deck can show the same chips. Missing
// persistence or a missing set yields an empty map; the deck never fails
// because of explainability.
func (s *Server) curatedReasonsForDeck(ctx context.Context, viewerID string) map[string]curatedExplanation {
	db, err := s.growthDB()
	if err != nil {
		return map[string]curatedExplanation{}
	}
	svc := newCuratedDailySetService(db)
	stored, err := svc.loadStoredSet(ctx, viewerID, curatedSetDate(svc.now()))
	if err != nil || stored == nil {
		return map[string]curatedExplanation{}
	}
	return stored.Explanations
}

// attachDiscoveryReasons gives every candidate row a `reasons` list (possibly
// empty) so the deck can render chips without a shape check.
func attachDiscoveryReasons(resp map[string]any, explanations map[string]curatedExplanation) {
	rows, ok := resp["candidates"].([]any)
	if !ok {
		return
	}
	for _, raw := range rows {
		row, ok := raw.(map[string]any)
		if !ok {
			continue
		}
		reasons := []string{}
		if explanation, found := explanations[candidateIdentity(row)]; found && explanation.Reasons != nil {
			reasons = explanation.Reasons
		}
		row["reasons"] = reasons
	}
}
