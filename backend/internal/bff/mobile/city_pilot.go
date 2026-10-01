package mobile

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)

// Pilot metrics are computed from canonical rows, never message bodies or private
// notes. There is deliberately no per-member drilldown or arbitrary slice API.
type cityPilot struct {
	ID                 string    `json:"id"`
	City               string    `json:"city"`
	Country            string    `json:"country"`
	Owner              string    `json:"owner"`
	SafetyOwner        string    `json:"safety_owner"`
	Status             string    `json:"status"`
	StartsAt           time.Time `json:"starts_at"`
	ClosesAt           time.Time `json:"closes_at"`
	Capacity           int       `json:"capacity"`
	MinimumPairs       int       `json:"minimum_pairs"`
	ConversationTarget int       `json:"conversation_target"`
	PlanTarget         int       `json:"plan_target"`
	DateTarget         int       `json:"date_target"`
	ReviewNote         string    `json:"review_note"`
	SafetyReady        bool      `json:"safety_ready"`
	Version            int       `json:"version"`
}
type pilotQueryer interface {
	QueryRowContext(context.Context, string, ...any) *sql.Row
}

func readCityPilot(ctx context.Context, q pilotQueryer, id string, lock bool) (*cityPilot, error) {
	query := `SELECT id::text,city,country,owner,safety_owner,status,starts_at,closes_at,capacity,minimum_pairs,conversation_target,plan_target,date_target,review_note,safety_ready,version FROM growth.city_pilots WHERE ($1='' OR id::text=$1) ORDER BY created_at DESC LIMIT 1`
	if lock {
		query += " FOR UPDATE"
	}
	p := new(cityPilot)
	err := q.QueryRowContext(ctx, query, id).Scan(&p.ID, &p.City, &p.Country, &p.Owner, &p.SafetyOwner, &p.Status, &p.StartsAt, &p.ClosesAt, &p.Capacity, &p.MinimumPairs, &p.ConversationTarget, &p.PlanTarget, &p.DateTarget, &p.ReviewNote, &p.SafetyReady, &p.Version)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil
	}
	return p, err
}

type pilotCounts struct{ Members, Pairs, ConversationDenominator, Conversations, DateDenominator, Plans, Dates, AnsweredPairs, OpenReports, Registrations, Feedback, Attended, Worthwhile int }

func cityPilotCounts(ctx context.Context, q pilotQueryer, p *cityPilot, now time.Time) (pilotCounts, error) {
	var c pilotCounts
	err := q.QueryRowContext(ctx, `
 WITH members AS (SELECT member_id,joined_at FROM growth.city_pilot_members WHERE pilot_id=$1 AND withdrawn_at IS NULL),
 pairs AS (
 SELECT m.* FROM matching.matches m JOIN members a ON a.member_id=m.user_id_1 JOIN members b ON b.member_id=m.user_id_2
 WHERE m.created_at>=GREATEST(a.joined_at,b.joined_at,$2) AND m.created_at<$3 AND m.created_at<=$4
 ), signals AS (
 SELECT m.id,m.created_at,
 (SELECT COUNT(*) FROM matching.messages x WHERE x.match_id=m.id AND x.sender_id=m.user_id_1 AND NOT x.is_deleted AND x.created_at>=m.created_at AND x.created_at<m.created_at+INTERVAL '7 days')>=3
 AND (SELECT COUNT(*) FROM matching.messages x WHERE x.match_id=m.id AND x.sender_id=m.user_id_2 AND NOT x.is_deleted AND x.created_at>=m.created_at AND x.created_at<m.created_at+INTERVAL '7 days')>=3 AS conversation,
 EXISTS(SELECT 1 FROM matching.match_date_plans dp JOIN matching.match_date_plan_events ev ON ev.plan_id=dp.id
 WHERE dp.match_id=m.id AND ev.to_status='accepted' AND ev.created_at>=m.created_at AND ev.created_at<m.created_at+INTERVAL '28 days') AS planned,
 EXISTS(SELECT 1 FROM matching.match_date_plans dp JOIN matching.match_date_plan_debriefs a ON a.plan_id=dp.id AND a.user_id=m.user_id_1
 JOIN matching.match_date_plan_debriefs b ON b.plan_id=dp.id AND b.user_id=m.user_id_2
 WHERE dp.match_id=m.id AND dp.created_at>=m.created_at AND a.happened AND b.happened AND GREATEST(a.created_at,b.created_at)<m.created_at+INTERVAL '28 days') AS dated,
 EXISTS(SELECT 1 FROM matching.match_date_plans dp JOIN matching.match_date_plan_debriefs a ON a.plan_id=dp.id AND a.user_id=m.user_id_1
 JOIN matching.match_date_plan_debriefs b ON b.plan_id=dp.id AND b.user_id=m.user_id_2
 WHERE dp.match_id=m.id AND dp.created_at>=m.created_at AND GREATEST(a.created_at,b.created_at)<m.created_at+INTERVAL '28 days') AS answered
 FROM pairs m
 ) SELECT (SELECT COUNT(*) FROM members),COUNT(*),
 COUNT(*) FILTER(WHERE created_at+INTERVAL '7 days'<=$4), COUNT(*) FILTER(WHERE created_at+INTERVAL '7 days'<=$4 AND conversation),
 COUNT(*) FILTER(WHERE created_at+INTERVAL '28 days'<=$4),COUNT(*) FILTER(WHERE created_at+INTERVAL '28 days'<=$4 AND planned),
 COUNT(*) FILTER(WHERE created_at+INTERVAL '28 days'<=$4 AND dated),COUNT(*) FILTER(WHERE created_at+INTERVAL '28 days'<=$4 AND answered),
 (SELECT COUNT(*) FROM matching.moderation_reports r WHERE r.status='pending' AND r.created_at>=$2 AND (r.reporter_user_id IN(SELECT member_id FROM members) OR r.reported_user_id IN(SELECT member_id FROM members))),
 (SELECT COUNT(*) FROM growth.event_registrations r JOIN growth.city_pilot_experiences e ON e.event_id=r.event_id JOIN members m ON m.member_id=r.member_id WHERE e.pilot_id=$1 AND r.status='registered' AND EXISTS(SELECT 1 FROM growth.events ev WHERE ev.id=e.event_id AND ev.status<>'cancelled')),
 (SELECT COUNT(*) FROM growth.city_pilot_feedback f JOIN growth.city_pilot_experiences e ON e.event_id=f.event_id JOIN members m ON m.member_id=f.member_id WHERE e.pilot_id=$1),
 (SELECT COUNT(*) FROM growth.city_pilot_feedback f JOIN growth.city_pilot_experiences e ON e.event_id=f.event_id JOIN members m ON m.member_id=f.member_id WHERE e.pilot_id=$1 AND f.attended),
 (SELECT COUNT(*) FROM growth.city_pilot_feedback f JOIN growth.city_pilot_experiences e ON e.event_id=f.event_id JOIN members m ON m.member_id=f.member_id WHERE e.pilot_id=$1 AND f.worthwhile IS TRUE)
 FROM signals`, p.ID, p.StartsAt, p.ClosesAt, now).Scan(&c.Members, &c.Pairs, &c.ConversationDenominator, &c.Conversations, &c.DateDenominator, &c.Plans, &c.Dates, &c.AnsweredPairs, &c.OpenReports, &c.Registrations, &c.Feedback, &c.Attended, &c.Worthwhile)
	return c, err
}
func pilotGate(p *cityPilot, c pilotCounts, now time.Time) bool {
	return !now.Before(p.ClosesAt.Add(28*24*time.Hour)) && c.DateDenominator >= p.MinimumPairs && c.OpenReports == 0 &&
		c.Conversations*100 >= c.ConversationDenominator*p.ConversationTarget && c.Plans*100 >= c.DateDenominator*p.PlanTarget && c.Dates*100 >= c.DateDenominator*p.DateTarget
}
func pilotCountLabel(n int) string {
	if n > 0 && n < 5 {
		return "<5"
	}
	return fmt.Sprint(n)
}
func pilotMetricRows(c pilotCounts) []map[string]string {
	rows := []map[string]string{}
	for _, r := range []struct {
		key, label string
		n          int
		note       string
	}{
		{"members", "Consenting members", c.Members, "Current opt-ins; withdrawn members are excluded."},
		{"pairs", "New pilot pairs", c.Pairs, "Both members joined before matching, within recruitment dates."},
		{"conversation_denominator", "Pairs with 7 days of follow-up", c.ConversationDenominator, "Denominator for conversation outcomes."},
		{"conversations", "Two-way conversations", c.Conversations, "At least 3 non-deleted messages from each person within 7 days. A proxy, not a quality score."},
		{"date_denominator", "Pairs with 28 days of follow-up", c.DateDenominator, "Denominator for plan and date outcomes."},
		{"plans", "Pairs with an accepted plan", c.Plans, "At least one mutual acceptance in the first 28 days, including subsequently cancelled plans."},
		{"dates", "Pairs who both said the date happened", c.Dates, "Voluntary reports from both people within 28 days. Missing answers are unknown, not failed dates."},
		{"answered_pairs", "Pairs with two date answers", c.AnsweredPairs, "Coverage of voluntary feedback, including disagreement and dates that did not happen."},
		{"registrations", "Experience RSVPs", c.Registrations, "Active registrations across pilot experiences."},
		{"feedback", "Experience responses", c.Feedback, "Voluntary post-experience answers."},
		{"attended", "Reported attendance", c.Attended, "Self-reported, not verified check-in."},
		{"worthwhile", "Worthwhile experiences", c.Worthwhile, "Members who opted to say the experience was worthwhile."},
	} {
		rows = append(rows, map[string]string{"key": r.key, "label": r.label, "value": pilotCountLabel(r.n), "note": r.note})
	}
	return rows
}
func (s *Server) pilotEnabled(ctx context.Context, q pilotQueryer) bool {
	var enabled bool
	err := q.QueryRowContext(ctx, `SELECT value_bool FROM matching.platform_feature_flags WHERE key='city_pilot_enabled'`).Scan(&enabled)
	return err == nil && enabled && !s.cfg.IsReleaseExcluded("city_pilot_enabled")
}
func pilotBad(w http.ResponseWriter, status int, message string) {
	writeError(w, status, errors.New(message))
}
func pilotBody(w http.ResponseWriter, r *http.Request, target any) bool {
	v, ok := readJSON(w, r)
	if !ok {
		return false
	}
	b, _ := json.Marshal(v)
	if json.Unmarshal(b, target) != nil {
		pilotBad(w, 400, "Invalid pilot request")
		return false
	}
	return true
}
func validPilot(p *cityPilot, now time.Time) bool {
	p.City = strings.TrimSpace(p.City)
	p.Country = strings.TrimSpace(p.Country)
	p.Owner = strings.TrimSpace(p.Owner)
	p.SafetyOwner = strings.TrimSpace(p.SafetyOwner)
	return len(p.City) >= 2 && len(p.City) <= 100 && len(p.Country) >= 2 && len(p.Country) <= 100 && len(p.Owner) >= 3 && len(p.Owner) <= 120 && len(p.SafetyOwner) >= 3 && len(p.SafetyOwner) <= 120 && p.StartsAt.After(now) && p.ClosesAt.After(p.StartsAt) && p.ClosesAt.Sub(p.StartsAt) <= 56*24*time.Hour && p.Capacity >= 20 && p.Capacity <= 5000 && p.MinimumPairs >= 20 && p.MinimumPairs <= 10000 && p.ConversationTarget >= 1 && p.ConversationTarget <= 100 && p.PlanTarget >= 1 && p.PlanTarget <= 100 && p.DateTarget >= 1 && p.DateTarget <= 100
}
func (s *Server) adminCityPilot(w http.ResponseWriter, r *http.Request) {
	db, err := s.growthDB()
	if err != nil {
		pilotBad(w, 503, "Pilot service unavailable")
		return
	}
	// One repeatable-read snapshot prevents mixed denominators during joins/withdrawals.
	tx, err := db.BeginTx(r.Context(), &sql.TxOptions{Isolation: sql.LevelRepeatableRead, ReadOnly: true})
	if err != nil {
		pilotBad(w, 503, "Pilot service unavailable")
		return
	}
	defer tx.Rollback()
	p, err := readCityPilot(r.Context(), tx, "", false)
	if err != nil {
		pilotBad(w, 503, "Pilot service unavailable")
		return
	}
	principal, _ := requestPrincipal(r)
	data := map[string]any{"success": true, "pilot": p, "enabled": s.pilotEnabled(r.Context(), tx), "can_edit": principal.Roles["admin"] || principal.Roles["ops_admin"], "can_pause": principal.Roles["admin"] || principal.Roles["ops_admin"] || principal.Roles["trust_safety"]}
	if p != nil {
		c, e := cityPilotCounts(r.Context(), tx, p, time.Now().UTC())
		if e != nil {
			pilotBad(w, 503, "Pilot metrics unavailable")
			return
		}
		data["metrics"] = pilotMetricRows(c)
		data["outcome_gate_met"] = pilotGate(p, c, time.Now().UTC())
		data["safety_review_required"] = c.OpenReports > 0
		data["review_opens_at"] = p.ClosesAt.Add(28 * 24 * time.Hour)
	}
	writeJSON(w, 200, data)
}
func (s *Server) adminSaveCityPilot(w http.ResponseWriter, r *http.Request) {
	var p cityPilot
	if !pilotBody(w, r, &p) {
		return
	}
	if !validPilot(&p, time.Now()) {
		pilotBad(w, 400, "Provide city, country, accountable owners, future recruitment dates (up to 56 days), capacity, at least 20 pairs and targets from 1 to 100 percent")
		return
	}
	db, err := s.growthDB()
	if err != nil {
		pilotBad(w, 503, "Pilot service unavailable")
		return
	}
	tx, err := db.BeginTx(r.Context(), nil)
	if err != nil {
		pilotBad(w, 503, "Pilot service unavailable")
		return
	}
	defer tx.Rollback()
	// Serializes draft creation too, when no pilot row exists yet.
	if _, err = tx.ExecContext(r.Context(), `SELECT pg_advisory_xact_lock(103,1)`); err != nil {
		pilotBad(w, 503, "Pilot service unavailable")
		return
	}
	current, err := readCityPilot(r.Context(), tx, "", true)
	if err != nil {
		pilotBad(w, 503, "Pilot service unavailable")
		return
	}
	if p.ID == "" {
		if current != nil && current.Status != "completed" {
			pilotBad(w, 409, "A pilot already exists. Refresh before editing")
			return
		}
		p.ID = uuid.NewString()
		_, err = tx.ExecContext(r.Context(), `INSERT INTO growth.city_pilots(id,city,country,owner,safety_owner,starts_at,closes_at,capacity,minimum_pairs,conversation_target,plan_target,date_target) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)`, p.ID, p.City, p.Country, p.Owner, p.SafetyOwner, p.StartsAt, p.ClosesAt, p.Capacity, p.MinimumPairs, p.ConversationTarget, p.PlanTarget, p.DateTarget)
	} else {
		if current == nil || current.ID != p.ID || current.Status != "draft" || current.Version != p.Version {
			pilotBad(w, 409, "Only the latest draft can be edited. Refresh first")
			return
		}
		_, err = tx.ExecContext(r.Context(), `UPDATE growth.city_pilots SET city=$2,country=$3,owner=$4,safety_owner=$5,starts_at=$6,closes_at=$7,capacity=$8,minimum_pairs=$9,conversation_target=$10,plan_target=$11,date_target=$12,version=version+1,updated_at=NOW() WHERE id=$1`, p.ID, p.City, p.Country, p.Owner, p.SafetyOwner, p.StartsAt, p.ClosesAt, p.Capacity, p.MinimumPairs, p.ConversationTarget, p.PlanTarget, p.DateTarget)
	}
	if err != nil || tx.Commit() != nil {
		pilotBad(w, 503, "Could not save pilot. Refresh before retrying")
		return
	}
	writeJSON(w, 200, map[string]any{"success": true, "id": p.ID})
}
func (s *Server) adminTransitionCityPilot(w http.ResponseWriter, r *http.Request) {
	var input struct {
		Status      string `json:"status"`
		Version     int    `json:"version"`
		Note        string `json:"note"`
		SafetyReady bool   `json:"safety_ready"`
	}
	if !pilotBody(w, r, &input) {
		return
	}
	input.Note = strings.TrimSpace(input.Note)
	if len(input.Note) < 10 || len(input.Note) > 2000 {
		pilotBad(w, 400, "Record a review or stop reason (10–2000 characters)")
		return
	}
	principal, _ := requestPrincipal(r)
	if !principal.Roles["admin"] && !principal.Roles["ops_admin"] && !(principal.Roles["trust_safety"] && input.Status == "paused") {
		pilotBad(w, 403, "This role can only pause the pilot")
		return
	}
	db, err := s.growthDB()
	if err != nil {
		pilotBad(w, 503, "Pilot service unavailable")
		return
	}
	tx, err := db.BeginTx(r.Context(), nil)
	if err != nil {
		pilotBad(w, 503, "Pilot service unavailable")
		return
	}
	defer tx.Rollback()
	p, err := readCityPilot(r.Context(), tx, chi.URLParam(r, "pilotID"), true)
	if err != nil {
		pilotBad(w, 503, "Pilot service unavailable")
		return
	}
	if p == nil || p.Version != input.Version {
		pilotBad(w, 409, "Pilot changed. Refresh first")
		return
	}
	allowed := input.Status == "paused" && p.Status != "draft" && p.Status != "completed" || input.Status == "completed" && p.Status != "completed" || input.Status == "recruiting" && p.Status == "draft" || input.Status == "measuring" && (p.Status == "recruiting" || p.Status == "paused") || input.Status == "experiences" && p.Status == "measuring"
	if !allowed {
		pilotBad(w, 409, "This pilot stage transition is unavailable")
		return
	}
	if input.Status == "recruiting" || input.Status == "experiences" {
		if !s.pilotEnabled(r.Context(), tx) || !input.SafetyReady {
			pilotBad(w, 409, "Enable the pilot flag and confirm the safety operating plan before opening participation")
			return
		}
	}
	if input.Status == "recruiting" && time.Now().After(p.ClosesAt) {
		pilotBad(w, 409, "Recruitment dates have ended")
		return
	}
	if input.Status == "experiences" {
		counts, e := cityPilotCounts(r.Context(), tx, p, time.Now().UTC())
		if e != nil {
			pilotBad(w, 503, "Pilot metrics unavailable")
			return
		}
		if !pilotGate(p, counts, time.Now().UTC()) {
			pilotBad(w, 409, "Complete 28-day follow-up, meet the predeclared sample and outcome targets, and resolve pending cohort safety reports before hosted experiences")
			return
		}
	}
	_, err = tx.ExecContext(r.Context(), `UPDATE growth.city_pilots SET status=$2,review_note=$3,safety_ready=$4,version=version+1,updated_at=NOW() WHERE id=$1`, p.ID, input.Status, input.Note, input.SafetyReady)
	if err == nil && (input.Status == "paused" || input.Status == "completed") {
		_, err = tx.ExecContext(r.Context(), `UPDATE growth.events SET status='cancelled' WHERE id IN(SELECT event_id FROM growth.city_pilot_experiences WHERE pilot_id=$1) AND starts_at>NOW() AND status='published'`, p.ID)
	}
	if err != nil || tx.Commit() != nil {
		pilotBad(w, 503, "Could not update pilot. Refresh before retrying")
		return
	}
	writeJSON(w, 200, map[string]any{"success": true})
}
func (s *Server) memberCityPilot(w http.ResponseWriter, r *http.Request) {
	principal, err := requestPrincipal(r)
	if err != nil {
		pilotBad(w, 401, "Sign in to see your pilot")
		return
	}
	db, err := s.growthDB()
	if err != nil {
		pilotBad(w, 503, "Pilot service unavailable")
		return
	}
	// Return an existing membership even after a newer pilot opens, so leaving is always reachable.
	var memberPilot string
	err = db.QueryRowContext(r.Context(), `SELECT m.pilot_id::text FROM growth.city_pilot_members m JOIN growth.city_pilots p ON p.id=m.pilot_id WHERE m.member_id=$1 AND m.withdrawn_at IS NULL ORDER BY p.created_at DESC LIMIT 1`, principal.UserID).Scan(&memberPilot)
	if err != nil && !errors.Is(err, sql.ErrNoRows) {
		pilotBad(w, 503, "Pilot service unavailable")
		return
	}
	p, err := readCityPilot(r.Context(), db, memberPilot, false)
	if err != nil {
		pilotBad(w, 503, "Pilot service unavailable")
		return
	}
	data := map[string]any{"success": true, "pilot": nil, "membership": "none", "can_join": false, "experiences": []any{}}
	if p == nil {
		writeJSON(w, 200, data)
		return
	}
	var status string
	var eligible bool
	err = db.QueryRowContext(r.Context(), `SELECT COALESCE((SELECT CASE WHEN withdrawn_at IS NULL THEN 'joined' ELSE 'withdrawn' END FROM growth.city_pilot_members WHERE pilot_id=$1 AND member_id=$2),'none'),EXISTS(SELECT 1 FROM user_management.users WHERE id=$2 AND account_kind='dating' AND terms_accepted AND is_active AND profile_completion=100 AND LOWER(TRIM(city))=LOWER($3) AND LOWER(TRIM(country))=LOWER($4))`, p.ID, principal.UserID, p.City, p.Country).Scan(&status, &eligible)
	if err != nil {
		pilotBad(w, 503, "Pilot service unavailable")
		return
	}
	enabled := s.pilotEnabled(r.Context(), db)
	if p.Status == "draft" && status == "none" {
		writeJSON(w, 200, data)
		return
	}
	if !eligible && status == "none" {
		writeJSON(w, 200, data)
		return
	}
	data["pilot"] = map[string]any{"id": p.ID, "city": p.City, "country": p.Country, "status": p.Status, "starts_at": p.StartsAt, "closes_at": p.ClosesAt, "review_opens_at": p.ClosesAt.Add(28 * 24 * time.Hour), "enabled": enabled}
	data["membership"] = status
	data["can_join"] = enabled && eligible && status == "none" && p.Status == "recruiting" && !time.Now().Before(p.StartsAt) && time.Now().Before(p.ClosesAt)
	if status == "joined" {
		events, e := listPilotExperiences(r.Context(), db, p.ID, principal.UserID, false, enabled && p.Status == "experiences")
		if e != nil {
			pilotBad(w, 503, "Experiences unavailable")
			return
		}
		data["experiences"] = events
	}
	writeJSON(w, 200, data)
}
func (s *Server) cityPilotMembership(w http.ResponseWriter, r *http.Request) {
	principal, err := requestPrincipal(r)
	if err != nil {
		pilotBad(w, 401, "Sign in first")
		return
	}
	var input struct {
		PilotID string `json:"pilot_id"`
		Consent string `json:"consent_version"`
	}
	if !pilotBody(w, r, &input) {
		return
	}
	if _, err = uuid.Parse(input.PilotID); err != nil {
		pilotBad(w, 400, "Invalid pilot")
		return
	}
	db, err := s.growthDB()
	if err != nil {
		pilotBad(w, 503, "Pilot service unavailable")
		return
	}
	tx, err := db.BeginTx(r.Context(), nil)
	if err != nil {
		pilotBad(w, 503, "Pilot service unavailable")
		return
	}
	defer tx.Rollback()
	p, err := readCityPilot(r.Context(), tx, input.PilotID, true)
	if err != nil {
		pilotBad(w, 503, "Pilot service unavailable")
		return
	}
	if p == nil {
		pilotBad(w, 404, "Pilot unavailable")
		return
	}
	if r.Method == http.MethodDelete {
		_, err = tx.ExecContext(r.Context(), `UPDATE growth.city_pilot_members SET withdrawn_at=COALESCE(withdrawn_at,NOW()) WHERE pilot_id=$1 AND member_id=$2`, p.ID, principal.UserID)
		if err == nil {
			_, err = tx.ExecContext(r.Context(), `DELETE FROM growth.city_pilot_feedback WHERE member_id=$2 AND event_id IN(SELECT event_id FROM growth.city_pilot_experiences WHERE pilot_id=$1)`, p.ID, principal.UserID)
		}
		if err == nil {
			_, err = tx.ExecContext(r.Context(), `UPDATE growth.event_registrations SET status='cancelled',updated_at=NOW() WHERE member_id=$2 AND status='registered' AND event_id IN(SELECT event_id FROM growth.city_pilot_experiences WHERE pilot_id=$1)`, p.ID, principal.UserID)
		}
	} else {
		if input.Consent != "city-pilot-v1" {
			pilotBad(w, 400, "Explicit pilot measurement consent is required")
			return
		}
		var joined, withdrawn bool
		err = tx.QueryRowContext(r.Context(), `SELECT EXISTS(SELECT 1 FROM growth.city_pilot_members WHERE pilot_id=$1 AND member_id=$2 AND withdrawn_at IS NULL),EXISTS(SELECT 1 FROM growth.city_pilot_members WHERE pilot_id=$1 AND member_id=$2 AND withdrawn_at IS NOT NULL)`, p.ID, principal.UserID).Scan(&joined, &withdrawn)
		if err != nil {
			pilotBad(w, 503, "Pilot service unavailable")
			return
		}
		if joined {
			writeJSON(w, 200, map[string]any{"success": true})
			return
		}
		if withdrawn || p.Status != "recruiting" || !s.pilotEnabled(r.Context(), tx) || time.Now().Before(p.StartsAt) || !time.Now().Before(p.ClosesAt) {
			pilotBad(w, 409, "This pilot is not accepting participation")
			return
		}
		var eligible bool
		var count int
		err = tx.QueryRowContext(r.Context(), `SELECT EXISTS(SELECT 1 FROM user_management.users WHERE id=$1 AND account_kind='dating' AND terms_accepted AND is_active AND profile_completion=100 AND LOWER(TRIM(city))=LOWER($2) AND LOWER(TRIM(country))=LOWER($3)),(SELECT COUNT(*) FROM growth.city_pilot_members WHERE pilot_id=$4 AND withdrawn_at IS NULL)`, principal.UserID, p.City, p.Country, p.ID).Scan(&eligible, &count)
		if err != nil {
			pilotBad(w, 503, "Pilot service unavailable")
			return
		}
		if !eligible {
			pilotBad(w, 403, "A completed dating profile in the pilot city is required")
			return
		}
		if count >= p.Capacity {
			pilotBad(w, 409, "This pilot is full")
			return
		}
		_, err = tx.ExecContext(r.Context(), `INSERT INTO growth.city_pilot_members(pilot_id,member_id) VALUES($1,$2)`, p.ID, principal.UserID)
	}
	if err != nil || tx.Commit() != nil {
		pilotBad(w, 503, "Could not save participation. Refresh before retrying")
		return
	}
	writeJSON(w, 200, map[string]any{"success": true})
}
