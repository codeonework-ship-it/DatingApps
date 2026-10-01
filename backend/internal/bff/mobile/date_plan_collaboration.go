package mobile

import (
	"context"
	"database/sql"
	"errors"
	"net/http"
	"strconv"
	"strings"

	"github.com/go-chi/chi/v5"
)

func requestPlanVersions(payload map[string]any) []int {
	n, ok := payload["expected_version"].(float64)
	if !ok {
		if _, present := payload["expected_version"]; present {
			return []int{-1}
		}
		return nil
	}
	if n < 0 || n != float64(int(n)) {
		return []int{-1}
	}
	return []int{int(n)}
}
func (s *datePlanService) counter(ctx context.Context, planID string, p datePlanProposal, version int) (datePlanView, error) {
	tx, err := s.db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		return datePlanView{}, err
	}
	defer tx.Rollback()
	partner, err := activeDatingPair(ctx, tx, p.MatchID, p.ProposerID, true)
	if err != nil {
		return datePlanView{}, err
	}
	row, err := scanDatePlanRow(tx.QueryRowContext(ctx, datePlanSelect+` WHERE p.id=$1::uuid AND p.match_id=$2::uuid FOR UPDATE OF p`, planID, p.MatchID))
	if errors.Is(err, sql.ErrNoRows) {
		return datePlanView{}, errDatePlanNotFound
	}
	if err != nil {
		return datePlanView{}, err
	}
	if row.Status != "proposed" || row.LockVersion != version {
		return datePlanView{}, errDatingConflict
	}
	pending := row.PendingProposerID
	if pending == "" {
		pending = row.ProposerID
	}
	if pending == p.ProposerID {
		return datePlanView{}, errDatePlanNotInvitee
	}
	if err = validatePlanSharedWindow(ctx, tx, p, partner, s.now()); err != nil {
		return datePlanView{}, err
	}
	if p.AtmospherePreferences == nil {
		p.AtmospherePreferences = row.AtmospherePreferences
	}
	if p.AccessibilityPreferences == nil {
		p.AccessibilityPreferences = row.AccessibilityPreferences
	}
	// An amendment is a proposal, never an implicit acceptance. Retain the
	// original participants and their sharing choices; only the decision owner changes.
	_, err = tx.ExecContext(ctx, `UPDATE matching.match_date_plans SET window_start=$2,window_end=$3,checkin_due_at=$3::timestamptz+INTERVAL '1 hour',venue_category=$4,venue_name=NULLIF($5,''),venue_area=NULLIF($6,''),note=NULLIF($7,''),budget_preference=$8,pending_proposer_id=$9::uuid,atmosphere_preferences=ARRAY(SELECT jsonb_array_elements_text($10::jsonb)),accessibility_preferences=ARRAY(SELECT jsonb_array_elements_text($11::jsonb)),lock_version=lock_version+1 WHERE id=$1::uuid`, planID, p.WindowStart, p.WindowEnd, p.VenueCategory, p.VenueName, p.VenueArea, p.Note, p.BudgetPreference, p.ProposerID, jsonStringList(p.AtmospherePreferences), jsonStringList(p.AccessibilityPreferences))
	if err != nil {
		return datePlanView{}, err
	}
	if err = s.appendEvent(ctx, tx, planID, p.ProposerID, "counterproposed", "proposed", "proposed", "", map[string]any{"version": version + 1}); err != nil {
		return datePlanView{}, err
	}
	if err = enqueueNotificationTx(ctx, tx, partner, p.ProposerID, "date_plan.counterproposed", "friend_plan", planID, "plan-counter:"+planID+":"+strconv.Itoa(version+1), "A suggestion for your plan", "Your match suggested a change. Review it before accepting.", "/plans", map[string]any{"plan_id": planID, "match_id": p.MatchID}, 5); err != nil {
		return datePlanView{}, err
	}
	updated, err := scanDatePlanRow(tx.QueryRowContext(ctx, datePlanSelect+` WHERE p.id=$1::uuid`, planID))
	if err != nil {
		return datePlanView{}, err
	}
	return s.view(updated, []datePlanCheckin{}, p.ProposerID), tx.Commit()
}
func (s *Server) counterDatePlan(w http.ResponseWriter, r *http.Request) {
	if !s.requireIntentionalDating(w, r) {
		return
	}
	principal, err := requestPrincipal(r)
	if err != nil {
		writeError(w, 401, err)
		return
	}
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	svc, err := s.datePlans()
	if err != nil {
		writeError(w, 503, err)
		return
	}
	versions := requestPlanVersions(payload)
	if len(versions) != 1 || versions[0] < 0 {
		writeError(w, 400, errors.New("Refresh the plan before suggesting a change"))
		return
	}
	match := strings.TrimSpace(chi.URLParam(r, "matchID"))
	p, err := parseDatePlanProposal(payload, match, principal.UserID, svc.now())
	if err != nil {
		writeError(w, 400, err)
		return
	}
	if !p.WindowStart.After(svc.now()) {
		writeError(w, 400, errors.New("Choose a future time"))
		return
	}
	view, err := svc.counter(r.Context(), strings.TrimSpace(chi.URLParam(r, "planID")), p, versions[0])
	if err != nil {
		writeDatePlanError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"plan": view})
}
