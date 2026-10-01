package mobile

import (
	"context"
	"database/sql"
	"errors"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/go-chi/chi/v5"
	"go.uber.org/zap"

	"github.com/verified-dating/backend/internal/platform/observability"
)

// HTTP surface for date plans (migration 091).
//
//	GET  /matches/{matchID}/plans                       open plan, history, share groups
//	POST /matches/{matchID}/plans                       propose
//	POST /matches/{matchID}/plans/{planID}/decision     invitee accepts or declines
//	POST /matches/{matchID}/plans/{planID}/cancel       either member withdraws
//	POST /matches/{matchID}/plans/{planID}/checkin      safe / need_help after the date
//	GET  /plans/{userID}                                my plans across matches
//	GET  /friends/{userID}/plans                        plans my friends shared with me

func (s *Server) datePlans() (*datePlanService, error) {
	db, err := s.growthDB()
	if err != nil {
		return nil, errors.New("date plan persistence is unavailable")
	}
	return newDatePlanService(db), nil
}

func writeDatePlanError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, errDatePlanAvailabilityChanged):
		writeJSON(w, http.StatusConflict, map[string]any{"success": false, "error": err.Error(), "error_code": "SHARED_AVAILABILITY_CHANGED"})
	case errors.Is(err, errDatingConflict):
		writeError(w, http.StatusConflict, err)
	case errors.Is(err, errDatePlanNotFound):
		writeError(w, http.StatusNotFound, err)
	case errors.Is(err, errDatePlanForbidden), errors.Is(err, errDatePlanNotInvitee):
		writeError(w, http.StatusForbidden, err)
	case errors.Is(err, errDatePlanAlreadyOpen):
		writeJSON(w, http.StatusConflict, map[string]any{
			"success": false, "error": err.Error(), "error_code": "DATE_PLAN_ALREADY_OPEN",
		})
	case errors.Is(err, errDatePlanStale):
		writeJSON(w, http.StatusConflict, map[string]any{
			"success": false, "error": err.Error(), "error_code": "DATE_PLAN_NOT_OPEN",
		})
	case errors.Is(err, errDatePlanMatchInactive):
		writeJSON(w, http.StatusConflict, map[string]any{
			"success": false, "error": err.Error(), "error_code": "DATE_PLAN_MATCH_INACTIVE",
		})
	case errors.Is(err, errDatePlanDebriefEarly):
		writeJSON(w, http.StatusConflict, map[string]any{
			"success": false, "error": err.Error(), "error_code": "DATE_PLAN_DEBRIEF_TOO_EARLY",
		})
	case errors.Is(err, errDatePlanTooEarly):
		writeJSON(w, http.StatusConflict, map[string]any{
			"success": false, "error": err.Error(), "error_code": "DATE_PLAN_CHECKIN_TOO_EARLY",
		})
	default:
		writeError(w, http.StatusServiceUnavailable, errors.New("date plan persistence is unavailable"))
	}
}

// chatUnlockedForPlan mirrors the chat gate: a pair that cannot talk yet
// cannot plan yet either. Persistence errors fail closed.
func (s *Server) chatUnlockedForPlan(matchID string) (bool, string) {
	if s.store == nil {
		return true, ""
	}
	unlocked, state, err := s.store.isChatUnlocked(matchID)
	if err != nil {
		return false, state
	}
	return unlocked, state
}

// planUnlockCheck lets tests substitute the unlock gate; production always
// uses the chat gate.
func (s *Server) planUnlockCheck(matchID string) (bool, string) {
	if s.datePlanUnlockOverride != nil {
		return s.datePlanUnlockOverride(matchID)
	}
	return s.chatUnlockedForPlan(matchID)
}

func (s *Server) getMatchDatePlans(w http.ResponseWriter, r *http.Request) {
	principal, err := requestPrincipal(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	svc, err := s.datePlans()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	matchID := strings.TrimSpace(chi.URLParam(r, "matchID"))
	open, history, groups, err := svc.matchPlans(r.Context(), matchID, principal.UserID)
	if err != nil {
		writeDatePlanError(w, err)
		return
	}
	unlocked, state := s.planUnlockCheck(matchID)
	response := map[string]any{
		"match_id": matchID, "plan": nil, "history": history, "share_groups": groups,
		"can_propose": open == nil && unlocked, "unlock_state": state,
	}
	if open != nil {
		response["plan"] = open
	}
	writeJSON(w, http.StatusOK, response)
}

func (s *Server) proposeMatchDatePlan(w http.ResponseWriter, r *http.Request) {
	principal, err := requestPrincipal(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	svc, err := s.datePlans()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	matchID := strings.TrimSpace(chi.URLParam(r, "matchID"))
	proposal, err := parseDatePlanProposal(payload, matchID, principal.UserID, svc.now())
	if err != nil {
		writeError(w, http.StatusBadRequest, err)
		return
	}
	if proposal.SharedWindow != nil && !s.requireIntentionalDating(w, r) {
		return
	}
	// Membership before the unlock gate, so a non-member never learns a
	// match's unlock state from this endpoint.
	if err = svc.assertMember(r.Context(), matchID, principal.UserID); err != nil {
		writeDatePlanError(w, err)
		return
	}
	if unlocked, state := s.planUnlockCheck(matchID); !unlocked {
		writeJSON(w, http.StatusLocked, map[string]any{
			"success": false, "error": "unlock the conversation before planning a date",
			"error_code": "CHAT_LOCKED_REQUIREMENT_PENDING", "unlock_state": state,
		})
		return
	}
	view, err := svc.propose(r.Context(), proposal)
	if err != nil {
		writeDatePlanError(w, err)
		return
	}
	s.store.recordActivity(activityEvent{
		UserID: principal.UserID, Actor: principal.UserID, Action: "date_plan.propose",
		Status: "success", Resource: "/matches/" + matchID + "/plans",
		Details: map[string]any{"plan_id": view.ID, "friend_recipients": view.FriendRecipients},
	})
	writeJSON(w, http.StatusCreated, map[string]any{"plan": view})
}

func (s *Server) decideMatchDatePlan(w http.ResponseWriter, r *http.Request) {
	principal, err := requestPrincipal(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	decision := strings.ToLower(strings.TrimSpace(toString(payload["decision"])))
	groupIDs, err := parseDatePlanGroupIDs(payload["group_ids"])
	if err != nil {
		writeError(w, http.StatusBadRequest, err)
		return
	}
	svc, err := s.datePlans()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	view, err := svc.decide(r.Context(), strings.TrimSpace(chi.URLParam(r, "matchID")),
		strings.TrimSpace(chi.URLParam(r, "planID")), principal.UserID, decision, groupIDs, requestPlanVersions(payload)...)
	if err != nil {
		if err.Error() == "decision must be accept or decline" {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeDatePlanError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"plan": view})
}

func (s *Server) cancelMatchDatePlan(w http.ResponseWriter, r *http.Request) {
	principal, err := requestPrincipal(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	svc, err := s.datePlans()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	view, err := svc.cancel(r.Context(), strings.TrimSpace(chi.URLParam(r, "matchID")),
		strings.TrimSpace(chi.URLParam(r, "planID")), principal.UserID,
		strings.TrimSpace(toString(payload["reason"])))
	if err != nil {
		if strings.HasPrefix(err.Error(), "reason must be") {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeDatePlanError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"plan": view})
}

func (s *Server) checkinMatchDatePlan(w http.ResponseWriter, r *http.Request) {
	principal, err := requestPrincipal(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	svc, err := s.datePlans()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	status := strings.ToLower(strings.TrimSpace(toString(payload["status"])))
	view, err := svc.checkin(r.Context(), strings.TrimSpace(chi.URLParam(r, "matchID")),
		strings.TrimSpace(chi.URLParam(r, "planID")), principal.UserID, status,
		strings.TrimSpace(toString(payload["note"])))
	if err != nil {
		if strings.HasPrefix(err.Error(), "status must be") || strings.HasPrefix(err.Error(), "note must be") {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeDatePlanError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"plan": view})
}

func optionalBool(value any) *bool {
	if b, ok := value.(bool); ok {
		return &b
	}
	return nil
}

func (s *Server) debriefMatchDatePlan(w http.ResponseWriter, r *http.Request) {
	principal, err := requestPrincipal(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	happened, ok := payload["happened"].(bool)
	if !ok {
		writeError(w, http.StatusBadRequest, errors.New("happened must be true or false"))
		return
	}
	svc, err := s.datePlans()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	if payload["share_mutual_interest"] == true && !s.requireIntentionalDating(w, r) {
		return
	}
	view, err := svc.debrief(r.Context(), strings.TrimSpace(chi.URLParam(r, "matchID")),
		strings.TrimSpace(chi.URLParam(r, "planID")), principal.UserID, happened,
		optionalBool(payload["would_meet_again"]), optionalBool(payload["felt_safe"]),
		strings.TrimSpace(toString(payload["note"])), payload["share_mutual_interest"] == true)
	if err != nil {
		if strings.HasPrefix(err.Error(), "note must be") {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeDatePlanError(w, err)
		return
	}
	if view.ResolvedStatus == "completed" {
		// Both members confirmed the date: refresh "Shows up" for both now
		// rather than waiting for their next badge read.
		for _, member := range []string{view.ProposerUserID, view.InviteeUserID} {
			if s.trust != nil {
				_, _, _ = s.trust.recomputeUserTrustBadges(r.Context(), member)
			} else if s.store != nil {
				_, _, _ = s.store.recomputeUserTrustBadges(member)
			}
		}
	}
	writeJSON(w, http.StatusOK, map[string]any{"plan": view})
}

func (s *Server) listMemberDatePlans(w http.ResponseWriter, r *http.Request) {
	principal, err := requestPrincipal(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	svc, err := s.datePlans()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	scope := strings.ToLower(strings.TrimSpace(r.URL.Query().Get("scope")))
	plans, err := svc.memberPlans(r.Context(), principal.UserID, scope, boundedQueryLimit(r, 20, 100))
	if err != nil {
		writeDatePlanError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"plans": plans})
}

func (s *Server) listFriendDatePlans(w http.ResponseWriter, r *http.Request) {
	principal, err := requestPrincipal(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	svc, err := s.datePlans()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	plans, err := svc.friendPlans(r.Context(), principal.UserID, boundedQueryLimit(r, 30, 100))
	if err != nil {
		writeDatePlanError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"plans": plans})
}

// ── Sweep worker ─────────────────────────────────────────────────────────────
// Expires unanswered proposals once their window closes, reminds each member
// to check in an hour after the window, and escalates to the member's friends
// two hours after that.

const datePlanSweepInterval = 5 * time.Minute

type datePlanSweepWorker struct {
	svc      *datePlanService
	log      *zap.Logger
	interval time.Duration
	cancel   context.CancelFunc
	done     sync.WaitGroup
}

func newDatePlanSweepWorker(db *sql.DB, log *zap.Logger, interval time.Duration) *datePlanSweepWorker {
	svc := newDatePlanService(db)
	if svc == nil {
		return nil
	}
	if log == nil {
		log = zap.NewNop()
	}
	if interval <= 0 {
		interval = datePlanSweepInterval
	}
	return &datePlanSweepWorker{svc: svc, log: log, interval: interval}
}

func (w *datePlanSweepWorker) Start(parent context.Context) {
	if w == nil || w.cancel != nil {
		return
	}
	ctx, cancel := context.WithCancel(parent)
	w.cancel = cancel
	w.done.Add(1)
	go func() {
		defer w.done.Done()
		ticker := time.NewTicker(w.interval)
		defer ticker.Stop()
		w.runOnce(ctx)
		for {
			select {
			case <-ctx.Done():
				return
			case <-ticker.C:
				w.runOnce(ctx)
			}
		}
	}()
}

func (w *datePlanSweepWorker) runOnce(ctx context.Context) {
	run := observability.NewHeartbeat(workerDatePlanSweep, w.interval).Begin()
	expired, reminders, escalations, err := w.svc.sweep(ctx)
	if err != nil && !errors.Is(err, context.Canceled) {
		run.End(err)
		w.log.Warn("date_plan_sweep_failed", zap.Error(err))
		return
	}
	runErr := err // only a cancellation reaches here; End ignores it
	defer func() {
		run.Items("processed", expired+reminders+escalations)
		run.End(runErr)
	}()
	// Friend intros share the cadence (migration 096).
	if social := newFriendSocialService(w.svc.db); social != nil {
		if n, err := social.sweep(ctx); err != nil && !errors.Is(err, context.Canceled) {
			runErr = err
			w.log.Warn("friend_intro_sweep_failed", zap.Error(err))
		} else {
			expired += n
		}
	}
	if expired+reminders+escalations > 0 {
		w.log.Info("date_plan_sweep",
			zap.Int("expired", expired), zap.Int("reminders", reminders), zap.Int("escalations", escalations))
	}
}

func (w *datePlanSweepWorker) Stop() {
	if w == nil || w.cancel == nil {
		return
	}
	w.cancel()
	w.done.Wait()
}
