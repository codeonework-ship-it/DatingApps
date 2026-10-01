package mobile

import (
	"context"
	"database/sql"
	"errors"
	"net/http"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"go.uber.org/zap"
)

// Per-plan daily like and message limits (BILL-002 entitlements).
//
// The plan catalog carries likes_per_day and messages_per_day (-1 =
// unlimited). The member's entitlement is the plan of their live paid
// subscription (active, or past_due inside the grace window) and otherwise
// the Free plan. Usage is counted from the durable swipes and messages tables
// over the current UTC day, so the limit is the same on every device and
// cannot be reset by reinstalling the app.

type planEntitlement struct {
	PlanID         string
	PlanName       string
	LikesPerDay    int
	MessagesPerDay int
}

type quotaStatus struct {
	Limit     int       `json:"limit"`
	Used      int       `json:"used"`
	Remaining int       `json:"remaining"`
	Unlimited bool      `json:"unlimited"`
	ResetsAt  time.Time `json:"resets_at"`
}

func (q quotaStatus) exhausted() bool { return !q.Unlimited && q.Used >= q.Limit }

func utcDayStart(now time.Time) (time.Time, time.Time) {
	now = now.UTC()
	start := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, time.UTC)
	return start, start.AddDate(0, 0, 1)
}

// entitlementFor resolves the member's current plan limits.
func (r *billingRepository) entitlementFor(ctx context.Context, userID string, grace time.Duration) (planEntitlement, error) {
	planCode := "free"
	sub, err := r.getSubscriptionWithGrace(ctx, userID, grace)
	if err == nil && sub.IsPaid && sub.Entitled && sub.PlanID != "" {
		planCode = sub.PlanID
	}
	var ent planEntitlement
	err = r.db.QueryRowContext(ctx, `
		SELECT code, name, likes_per_day, messages_per_day FROM matching.billing_plans WHERE code=$1`, planCode).Scan(
		&ent.PlanID, &ent.PlanName, &ent.LikesPerDay, &ent.MessagesPerDay)
	if errors.Is(err, sql.ErrNoRows) {
		if planCode != "free" {
			// Paid plan missing from the catalog: never punish a paying
			// member for a catalog gap.
			return planEntitlement{PlanID: planCode, PlanName: titlePlanName(planCode), LikesPerDay: -1, MessagesPerDay: -1}, nil
		}
		return planEntitlement{PlanID: "free", PlanName: "Free", LikesPerDay: -1, MessagesPerDay: -1}, nil
	}
	return ent, err
}

func (r *billingRepository) countLikesSince(ctx context.Context, userID string, since time.Time) (int, error) {
	var n int
	err := r.db.QueryRowContext(ctx, `
		SELECT COUNT(*) FROM matching.swipes WHERE user_id=$1 AND is_like AND created_at >= $2`, userID, since).Scan(&n)
	return n, err
}

func (r *billingRepository) countMessagesSince(ctx context.Context, userID string, since time.Time) (int, error) {
	var n int
	err := r.db.QueryRowContext(ctx, `
		SELECT (SELECT COUNT(*) FROM matching.messages WHERE sender_id=$1 AND created_at >= $2)
 + (SELECT COUNT(*) FROM matching.blog_responses WHERE sender_id=$1 AND created_at >= $2)
 + (SELECT COUNT(*) FROM matching.blog_responses WHERE sender_id=$1 AND sender_contributed_at >= $2)
 + (SELECT COUNT(*) FROM matching.blog_responses WHERE author_id=$1 AND author_contributed_at >= $2)`, userID, since).Scan(&n)
	return n, err
}

func quotaFor(limit, used int, resets time.Time) quotaStatus {
	q := quotaStatus{Limit: limit, Used: used, ResetsAt: resets, Unlimited: limit < 0}
	if q.Unlimited {
		q.Remaining = -1
		return q
	}
	q.Remaining = limit - used
	if q.Remaining < 0 {
		q.Remaining = 0
	}
	return q
}

// entitlementsEnforced reports whether daily limits apply on this server:
// durable billing persistence must exist and the switch must be on.
func (s *Server) entitlementsEnforced() bool {
	return s.cfg.BillingEnforceDailyLimits && s.store != nil && s.store.billingRepo != nil
}

func (s *Server) entitlementGrace() time.Duration {
	days := s.cfg.BillingPastDueGraceDays
	if days <= 0 {
		days = 7
	}
	return time.Duration(days) * 24 * time.Hour
}

// memberEntitlements returns the plan and today's like/message quotas.
func (s *Server) memberEntitlements(ctx context.Context, userID string, now time.Time) (planEntitlement, quotaStatus, quotaStatus, error) {
	repo := s.store.billingRepo
	ent, err := repo.entitlementFor(ctx, userID, s.entitlementGrace())
	if err != nil {
		return planEntitlement{}, quotaStatus{}, quotaStatus{}, err
	}
	start, resets := utcDayStart(now)
	likes, err := repo.countLikesSince(ctx, userID, start)
	if err != nil {
		return planEntitlement{}, quotaStatus{}, quotaStatus{}, err
	}
	messages, err := repo.countMessagesSince(ctx, userID, start)
	if err != nil {
		return planEntitlement{}, quotaStatus{}, quotaStatus{}, err
	}
	return ent, quotaFor(ent.LikesPerDay, likes, resets), quotaFor(ent.MessagesPerDay, messages, resets), nil
}

// enforceDailyQuota answers 429 with a structured payload when the member's
// plan quota for kind ("like" | "message") is used up. It returns true when
// the request may proceed.
func (s *Server) enforceDailyQuota(w http.ResponseWriter, r *http.Request, userID, kind string) bool {
	if !s.entitlementsEnforced() || strings.TrimSpace(userID) == "" {
		return true
	}
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	ent, likes, messages, err := s.memberEntitlements(ctx, userID, time.Now())
	if err != nil {
		// A quota lookup failure must not take the product down; log and
		// allow, the ledger is still the source of truth for money.
		s.log.Warn("entitlement_lookup_failed", zap.Error(err))
		return true
	}
	quota := likes
	code := "DAILY_LIKE_LIMIT_REACHED"
	noun := "likes"
	if kind == "message" {
		quota = messages
		code = "DAILY_MESSAGE_LIMIT_REACHED"
		noun = "messages"
	}
	if !quota.exhausted() {
		return true
	}
	writeJSON(w, http.StatusTooManyRequests, map[string]any{
		"success":    false,
		"error":      "you have used today's " + noun + " on the " + ent.PlanName + " plan; upgrade for more or try again after the reset",
		"error_code": code,
		"plan_id":    ent.PlanID,
		"plan_name":  ent.PlanName,
		"limit":      quota.Limit,
		"used":       quota.Used,
		"resets_at":  quota.ResetsAt.UTC().Format(time.RFC3339),
	})
	return false
}

// getBillingEntitlements is the member's view of their daily quotas.
func (s *Server) getBillingEntitlements(w http.ResponseWriter, r *http.Request) {
	userID := s.requestUserID(r, chi.URLParam(r, "userID"))
	if s.store == nil || s.store.billingRepo == nil {
		_, resets := utcDayStart(time.Now())
		writeJSON(w, http.StatusOK, map[string]any{
			"plan_id": "free", "plan_name": "Free", "enforced": false,
			"likes":    quotaFor(-1, 0, resets),
			"messages": quotaFor(-1, 0, resets),
		})
		return
	}
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	ent, likes, messages, err := s.memberEntitlements(ctx, userID, time.Now())
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"plan_id":   ent.PlanID,
		"plan_name": ent.PlanName,
		"enforced":  s.entitlementsEnforced(),
		"likes":     likes,
		"messages":  messages,
		"resets_at": likes.ResetsAt.UTC().Format(time.RFC3339),
	})
}
