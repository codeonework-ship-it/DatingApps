package mobile

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)

func (s *Server) growthDB() (*sql.DB, error) {
	if s.store == nil || s.store.profileRepo == nil || s.store.profileRepo.pg == nil {
		return nil, errors.New("growth portfolio persistence is unavailable")
	}
	return s.store.profileRepo.pg, nil
}

func requestPrincipal(r *http.Request) (securityPrincipal, error) {
	principal, ok := principalFromRequest(r)
	if !ok || strings.TrimSpace(principal.UserID) == "" {
		return securityPrincipal{}, errors.New("valid bearer session is required")
	}
	return principal, nil
}

func boundedQueryLimit(r *http.Request, fallback, maximum int) int {
	limit, err := strconv.Atoi(strings.TrimSpace(r.URL.Query().Get("limit")))
	if err != nil || limit < 1 {
		return fallback
	}
	if limit > maximum {
		return maximum
	}
	return limit
}

func nullString(value sql.NullString) any {
	if !value.Valid {
		return nil
	}
	return value.String
}

func nullTime(value sql.NullTime) any {
	if !value.Valid {
		return nil
	}
	return value.Time
}

func (s *Server) getGrowthPortfolio(w http.ResponseWriter, r *http.Request) {
	db, err := s.growthDB()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	rows, err := db.QueryContext(r.Context(), `
		SELECT m.module_key,m.display_name,m.risk_tier,m.lifecycle,m.owner,
		       m.production_enabled,m.blocker,m.decision_note,m.updated_at,
		       COALESCE(f.value_bool,FALSE)
		FROM growth.portfolio_modules m
		LEFT JOIN matching.platform_feature_flags f ON f.key=m.module_key||'_enabled'
		ORDER BY CASE m.risk_tier WHEN 'monetized' THEN 1 WHEN 'sensitive' THEN 2 ELSE 3 END,m.module_key`)
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	defer rows.Close()
	modules := make([]map[string]any, 0)
	for rows.Next() {
		var key, name, risk, lifecycle, owner, note string
		var blocker sql.NullString
		var production, runtime bool
		var updated time.Time
		if err = rows.Scan(&key, &name, &risk, &lifecycle, &owner, &production, &blocker, &note, &updated, &runtime); err != nil {
			writeError(w, http.StatusServiceUnavailable, err)
			return
		}
		modules = append(modules, map[string]any{
			"key": key, "name": name, "risk_tier": risk, "lifecycle": lifecycle,
			"owner": owner, "production_enabled": production, "runtime_enabled": runtime,
			"blocker": nullString(blocker), "decision_note": note, "updated_at": updated,
		})
	}
	if err = rows.Err(); err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"success": true, "portfolio": "deferred_growth", "priority": "P2", "modules": modules,
		"guardrails": []string{
			"No cash, coins, XP, entitlement or rank side effects without a separately approved monetized launch gate.",
			"Fraud graph signals are review-only and cannot automatically restrict a member.",
			"Social import stores revocable consent only; precise and background location history are prohibited.",
		},
	})
}

func (s *Server) listGrowthEvents(w http.ResponseWriter, r *http.Request) {
	db, err := s.growthDB()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	rows, err := db.QueryContext(r.Context(), `
		SELECT e.id::text,e.title,e.summary,e.city,e.venue_name,e.starts_at,e.registration_closes_at,
		       e.capacity,e.safety_contact,COUNT(r.member_id) FILTER(WHERE r.status='registered')::int
		FROM growth.events e LEFT JOIN growth.event_registrations r ON r.event_id=e.id
		WHERE e.status='published' AND e.starts_at>NOW() AND NOT EXISTS(SELECT 1 FROM growth.city_pilot_experiences x WHERE x.event_id=e.id)
		GROUP BY e.id ORDER BY e.starts_at LIMIT $1`, boundedQueryLimit(r, 50, 100))
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	defer rows.Close()
	items := make([]map[string]any, 0)
	for rows.Next() {
		var id, title, summary, city, safety string
		var venue sql.NullString
		var starts, closes time.Time
		var capacity, registered int
		if err = rows.Scan(&id, &title, &summary, &city, &venue, &starts, &closes, &capacity, &safety, &registered); err != nil {
			writeError(w, http.StatusServiceUnavailable, err)
			return
		}
		items = append(items, map[string]any{"id": id, "title": title, "summary": summary, "city": city, "venue_name": nullString(venue), "starts_at": starts, "registration_closes_at": closes, "capacity": capacity, "registered": registered, "spaces_remaining": capacity - registered, "safety_contact": safety, "is_free": true})
	}
	writeJSON(w, http.StatusOK, map[string]any{"success": true, "events": items})
}

func (s *Server) registerGrowthEvent(w http.ResponseWriter, r *http.Request) {
	principal, err := requestPrincipal(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	accepted, _ := payload["safety_terms_accepted"].(bool)
	if !accepted {
		writeError(w, http.StatusBadRequest, errors.New("event safety terms must be accepted"))
		return
	}
	db, err := s.growthDB()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	tx, err := db.BeginTx(r.Context(), &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	defer func() { _ = tx.Rollback() }()
	eventID := chi.URLParam(r, "eventID")
	var capacity, registered int
	err = tx.QueryRowContext(r.Context(), `SELECT capacity,(SELECT COUNT(*) FROM growth.event_registrations WHERE event_id=e.id AND status='registered')::int FROM growth.events e WHERE e.id=$1 AND e.status='published' AND e.registration_closes_at>NOW() AND NOT EXISTS(SELECT 1 FROM growth.city_pilot_experiences x WHERE x.event_id=e.id) FOR UPDATE`, eventID).Scan(&capacity, &registered)
	if errors.Is(err, sql.ErrNoRows) {
		writeError(w, http.StatusNotFound, errors.New("event is unavailable for registration"))
		return
	}
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	if registered >= capacity {
		writeError(w, http.StatusConflict, errors.New("event is full"))
		return
	}
	if _, err = tx.ExecContext(r.Context(), `INSERT INTO growth.event_registrations(event_id,member_id,status,safety_terms_accepted_at) VALUES($1,$2,'registered',NOW()) ON CONFLICT(event_id,member_id) DO UPDATE SET status='registered',safety_terms_accepted_at=NOW(),updated_at=NOW()`, eventID, principal.UserID); err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	if err = tx.Commit(); err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"success": true, "event_id": eventID, "status": "registered"})
}

func (s *Server) cancelGrowthEventRegistration(w http.ResponseWriter, r *http.Request) {
	principal, err := requestPrincipal(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	db, err := s.growthDB()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	result, err := db.ExecContext(r.Context(), `UPDATE growth.event_registrations SET status='cancelled',updated_at=NOW() WHERE event_id=$1 AND member_id=$2 AND status='registered'`, chi.URLParam(r, "eventID"), principal.UserID)
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	affected, _ := result.RowsAffected()
	if affected == 0 {
		writeError(w, http.StatusNotFound, errors.New("active registration not found"))
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"success": true, "status": "cancelled"})
}

func (s *Server) getReferralCode(w http.ResponseWriter, r *http.Request) {
	principal, err := requestPrincipal(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	db, err := s.growthDB()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	var id, storedCode, status string
	var created time.Time
	err = db.QueryRowContext(r.Context(), `SELECT id::text,code,status,created_at FROM growth.referral_codes WHERE owner_id=$1`, principal.UserID).Scan(&id, &storedCode, &status, &created)
	if errors.Is(err, sql.ErrNoRows) {
		writeError(w, http.StatusNotFound, errors.New("referral code has not been created"))
		return
	}
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"success": true, "referral": map[string]any{"id": id, "code": storedCode, "status": status, "created_at": created, "reward": nil}})
}

func (s *Server) createReferralCode(w http.ResponseWriter, r *http.Request) {
	principal, err := requestPrincipal(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	db, err := s.growthDB()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	code := strings.ToUpper(strings.ReplaceAll(uuid.NewString(), "-", "")[:10])
	var id, storedCode, status string
	var created time.Time
	err = db.QueryRowContext(r.Context(), `INSERT INTO growth.referral_codes(owner_id,code) VALUES($1,$2) ON CONFLICT(owner_id) DO UPDATE SET owner_id=EXCLUDED.owner_id RETURNING id::text,code,status,created_at`, principal.UserID, code).Scan(&id, &storedCode, &status, &created)
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"success": true, "referral": map[string]any{"id": id, "code": storedCode, "status": status, "created_at": created, "reward": nil}})
}

func (s *Server) redeemReferralCode(w http.ResponseWriter, r *http.Request) {
	principal, err := requestPrincipal(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	code := strings.ToUpper(strings.TrimSpace(toString(payload["code"])))
	if len(code) < 8 || len(code) > 16 {
		writeError(w, http.StatusBadRequest, errors.New("valid referral code is required"))
		return
	}
	db, err := s.growthDB()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	var redemptionID string
	err = db.QueryRowContext(r.Context(), `
		INSERT INTO growth.referral_redemptions(code_id,referred_member_id)
		SELECT id,$2 FROM growth.referral_codes WHERE code=$1 AND status='active' AND owner_id<>$2
		ON CONFLICT(referred_member_id) DO NOTHING RETURNING id::text`, code, principal.UserID).Scan(&redemptionID)
	if errors.Is(err, sql.ErrNoRows) {
		writeError(w, http.StatusConflict, errors.New("referral code is invalid, self-owned, or already redeemed"))
		return
	}
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	writeJSON(w, http.StatusCreated, map[string]any{"success": true, "redemption_id": redemptionID, "status": "recorded", "reward_granted": false})
}

func (s *Server) listGrowthPartnerships(w http.ResponseWriter, r *http.Request) {
	db, err := s.growthDB()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	rows, err := db.QueryContext(r.Context(), `SELECT id::text,name,category,summary,website_url,due_diligence_completed_at FROM growth.partnerships WHERE status='published' ORDER BY name LIMIT $1`, boundedQueryLimit(r, 50, 100))
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	defer rows.Close()
	items := make([]map[string]any, 0)
	for rows.Next() {
		var id, name, category, summary string
		var website sql.NullString
		var reviewed sql.NullTime
		if err = rows.Scan(&id, &name, &category, &summary, &website, &reviewed); err != nil {
			writeError(w, http.StatusServiceUnavailable, err)
			return
		}
		items = append(items, map[string]any{"id": id, "name": name, "category": category, "summary": summary, "website_url": nullString(website), "due_diligence_completed_at": nullTime(reviewed)})
	}
	writeJSON(w, http.StatusOK, map[string]any{"success": true, "partnerships": items})
}

func (s *Server) listRecommendationEdges(w http.ResponseWriter, r *http.Request) {
	principal, err := requestPrincipal(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	db, err := s.growthDB()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	rows, err := db.QueryContext(r.Context(), `SELECT id::text,candidate_id::text,score::float8,reasons,model_version,expires_at,created_at FROM growth.recommendation_edges WHERE member_id=$1 AND expires_at>NOW() ORDER BY score DESC LIMIT $2`, principal.UserID, boundedQueryLimit(r, 25, 100))
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	defer rows.Close()
	items := make([]map[string]any, 0)
	for rows.Next() {
		var id, candidateID, model string
		var score float64
		var raw []byte
		var expires, created time.Time
		if err = rows.Scan(&id, &candidateID, &score, &raw, &model, &expires, &created); err != nil {
			writeError(w, http.StatusServiceUnavailable, err)
			return
		}
		var reasons []any
		_ = json.Unmarshal(raw, &reasons)
		items = append(items, map[string]any{"id": id, "candidate_id": candidateID, "score": score, "reasons": reasons, "model_version": model, "expires_at": expires, "created_at": created})
	}
	writeJSON(w, http.StatusOK, map[string]any{"success": true, "recommendations": items, "automated_adverse_action": false})
}

func (s *Server) upsertSocialImportConsent(w http.ResponseWriter, r *http.Request) {
	principal, err := requestPrincipal(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	provider := strings.ToLower(strings.TrimSpace(toString(payload["provider"])))
	if provider != "google_contacts" && provider != "apple_contacts" && provider != "manual" {
		writeError(w, http.StatusBadRequest, errors.New("approved provider is required"))
		return
	}
	db, err := s.growthDB()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	var id string
	var expires time.Time
	err = db.QueryRowContext(r.Context(), `
		INSERT INTO growth.social_import_consents(member_id,provider,scope,status,expires_at)
		VALUES($1,$2,ARRAY['discover_existing_members'],'granted',NOW()+INTERVAL '30 days')
		ON CONFLICT(member_id,provider) DO UPDATE SET scope=EXCLUDED.scope,status='granted',granted_at=NOW(),revoked_at=NULL,expires_at=EXCLUDED.expires_at
		RETURNING id::text,expires_at`, principal.UserID, provider).Scan(&id, &expires)
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"success": true, "consent": map[string]any{"id": id, "provider": provider, "status": "granted", "scope": []string{"discover_existing_members"}, "expires_at": expires}, "contacts_ingested": 0})
}

func (s *Server) revokeSocialImportConsent(w http.ResponseWriter, r *http.Request) {
	principal, err := requestPrincipal(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	db, err := s.growthDB()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	result, err := db.ExecContext(r.Context(), `UPDATE growth.social_import_consents SET status='revoked',revoked_at=NOW() WHERE member_id=$1 AND provider=$2 AND status='granted'`, principal.UserID, chi.URLParam(r, "provider"))
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	affected, _ := result.RowsAffected()
	if affected == 0 {
		writeError(w, http.StatusNotFound, errors.New("active consent not found"))
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"success": true, "status": "revoked"})
}

func (s *Server) getMemberGrowthHistory(w http.ResponseWriter, r *http.Request) {
	principal, err := requestPrincipal(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	db, err := s.growthDB()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	prefRows, err := db.QueryContext(r.Context(), `SELECT id::text,snapshot,changed_fields,created_at FROM growth.preference_history WHERE member_id=$1 ORDER BY created_at DESC LIMIT $2`, principal.UserID, boundedQueryLimit(r, 50, 100))
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	preferences := make([]map[string]any, 0)
	for prefRows.Next() {
		var id, raw, fields string
		var created time.Time
		if err = prefRows.Scan(&id, &raw, &fields, &created); err != nil {
			prefRows.Close()
			writeError(w, http.StatusServiceUnavailable, err)
			return
		}
		var snapshot map[string]any
		_ = json.Unmarshal([]byte(raw), &snapshot)
		preferences = append(preferences, map[string]any{"id": id, "snapshot": snapshot, "changed_fields": strings.Trim(fields, "{}"), "created_at": created})
	}
	prefRows.Close()
	locationRows, err := db.QueryContext(r.Context(), `SELECT id::text,city,state,country,expires_at,created_at FROM growth.location_checkins WHERE member_id=$1 AND expires_at>NOW() ORDER BY created_at DESC LIMIT $2`, principal.UserID, boundedQueryLimit(r, 50, 100))
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	defer locationRows.Close()
	locations := make([]map[string]any, 0)
	for locationRows.Next() {
		var id, city, state, country string
		var expires, created time.Time
		if err = locationRows.Scan(&id, &city, &state, &country, &expires, &created); err != nil {
			writeError(w, http.StatusServiceUnavailable, err)
			return
		}
		locations = append(locations, map[string]any{"id": id, "city": city, "state": state, "country": country, "source": "foreground_checkin", "expires_at": expires, "created_at": created})
	}
	writeJSON(w, http.StatusOK, map[string]any{"success": true, "preference_history": preferences, "location_checkins": locations, "precise_location_stored": false})
}

func (s *Server) capturePreferenceHistory(w http.ResponseWriter, r *http.Request) {
	principal, err := requestPrincipal(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	db, err := s.growthDB()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	var id string
	err = db.QueryRowContext(r.Context(), `
		INSERT INTO growth.preference_history(member_id,snapshot,changed_fields)
		SELECT user_id,jsonb_build_object('seeking_genders',seeking_genders,'min_age_years',min_age_years,'max_age_years',max_age_years,'max_distance_km',max_distance_km,'serious_only',serious_only,'verified_only',verified_only,'intent_tags',intent_tags,'language_tags',language_tags),
		       ARRAY['seeking_genders','age_range','max_distance_km','serious_only','verified_only','intent_tags','language_tags']
		FROM user_management.preferences WHERE user_id=$1 RETURNING id::text`, principal.UserID).Scan(&id)
	if errors.Is(err, sql.ErrNoRows) {
		writeError(w, http.StatusNotFound, errors.New("member preferences not found"))
		return
	}
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	writeJSON(w, http.StatusCreated, map[string]any{"success": true, "history_id": id})
}

func (s *Server) createLocationCheckin(w http.ResponseWriter, r *http.Request) {
	principal, err := requestPrincipal(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	city, state, country := strings.TrimSpace(toString(payload["city"])), strings.TrimSpace(toString(payload["state"])), strings.TrimSpace(toString(payload["country"]))
	if city == "" || state == "" || country == "" || len(city) > 100 || len(state) > 100 || len(country) > 100 {
		writeError(w, http.StatusBadRequest, errors.New("city, state and country are required"))
		return
	}
	db, err := s.growthDB()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	var id string
	var expires time.Time
	err = db.QueryRowContext(r.Context(), `INSERT INTO growth.location_checkins(member_id,city,state,country) VALUES($1,$2,$3,$4) RETURNING id::text,expires_at`, principal.UserID, city, state, country).Scan(&id, &expires)
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	writeJSON(w, http.StatusCreated, map[string]any{"success": true, "checkin": map[string]any{"id": id, "city": city, "state": state, "country": country, "source": "foreground_checkin", "expires_at": expires}})
}

func (s *Server) deleteMemberGrowthHistory(w http.ResponseWriter, r *http.Request) {
	principal, err := requestPrincipal(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	db, err := s.growthDB()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	tx, err := db.BeginTx(r.Context(), nil)
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	defer func() { _ = tx.Rollback() }()
	prefResult, err := tx.ExecContext(r.Context(), `DELETE FROM growth.preference_history WHERE member_id=$1`, principal.UserID)
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	locationResult, err := tx.ExecContext(r.Context(), `DELETE FROM growth.location_checkins WHERE member_id=$1`, principal.UserID)
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	if err = tx.Commit(); err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	prefs, _ := prefResult.RowsAffected()
	locations, _ := locationResult.RowsAffected()
	writeJSON(w, http.StatusOK, map[string]any{"success": true, "deleted": map[string]any{"preference_history": prefs, "location_checkins": locations}})
}

func (s *Server) adminListFraudGraph(w http.ResponseWriter, r *http.Request) {
	db, err := s.growthDB()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	page, err := parseAdminListParams(r, adminFraudGraphSpec)
	if err != nil {
		writeAdminListParamError(w, err)
		return
	}
	member, err := adminUUIDParam(r, "member")
	if err != nil {
		writeAdminListParamError(w, err)
		return
	}
	filter := newSQLFilter()
	filter.Eq("review_status", r.URL.Query().Get("status")).Eq("signal_type", r.URL.Query().Get("signal_type"))
	if member != "" {
		arg := filter.Arg(member)
		filter.Where("(left_member_id = " + arg + " OR right_member_id = " + arg + ")")
	}
	filter.Search(page.Q, "signal_type", "action_mode")
	filter.TimeRange("created_at", page)
	items := make([]map[string]any, 0)
	total, err := queryAdminPage(r.Context(), db,
		`id::text,left_member_id::text,right_member_id::text,signal_type,confidence::float8,evidence,review_status,action_mode,reviewed_by::text,reviewed_at,created_at`,
		` FROM growth.fraud_graph_edges`, filter, page, func(rows *sql.Rows) error {
			var id, left, right, signal, evidence, status, action string
			var confidence float64
			var reviewer sql.NullString
			var reviewed sql.NullTime
			var created time.Time
			if err := rows.Scan(&id, &left, &right, &signal, &confidence, &evidence, &status, &action, &reviewer, &reviewed, &created); err != nil {
				return err
			}
			var evidenceMap map[string]any
			_ = json.Unmarshal([]byte(evidence), &evidenceMap)
			items = append(items, map[string]any{"id": id, "left_member_id": left, "right_member_id": right, "signal_type": signal, "confidence": confidence, "evidence": evidenceMap, "review_status": status, "action_mode": action, "reviewed_by": nullString(reviewer), "reviewed_at": nullTime(reviewed), "created_at": created})
			return nil
		})
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	writeJSON(w, http.StatusOK, page.Page(map[string]any{"success": true, "edges": items, "automatic_enforcement": false}, total))
}

// The default keeps the old order: strongest signal first, then oldest.
var adminFraudGraphSpec = adminListSpec{
	DefaultLimit: 100, MaxLimit: 500,
	Sorts: map[string]string{
		"confidence": "confidence {dir}, created_at",
		"created_at": "created_at",
	},
	DefaultSort: "confidence", TieBreak: "id",
}

func (s *Server) adminResolveFraudGraphEdge(w http.ResponseWriter, r *http.Request) {
	operator, err := authenticatedOperatorID(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	status := strings.ToLower(strings.TrimSpace(toString(payload["status"])))
	if status != "dismissed" && status != "confirmed" {
		writeError(w, http.StatusBadRequest, errors.New("status must be dismissed or confirmed"))
		return
	}
	db, err := s.growthDB()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	result, err := db.ExecContext(r.Context(), `UPDATE growth.fraud_graph_edges SET review_status=$2,reviewed_by=$3,reviewed_at=NOW() WHERE id=$1 AND review_status='open'`, chi.URLParam(r, "edgeID"), status, operator)
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	affected, _ := result.RowsAffected()
	if affected == 0 {
		writeError(w, http.StatusConflict, errors.New("open fraud graph edge not found"))
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"success": true, "status": status, "automatic_enforcement": false})
}

func growthUnavailableHandler(module string) http.HandlerFunc {
	return func(w http.ResponseWriter, _ *http.Request) {
		writeJSON(w, http.StatusForbidden, map[string]any{
			"success": false, "error": fmt.Sprintf("%s is blocked by its production launch contract", module),
			"error_code": "GROWTH_LAUNCH_BLOCKED", "module": module,
		})
	}
}

// Referenced by focused tests without requiring a live database.
func validateGrowthGuardrails() error {
	for key, category := range supportCategories {
		if strings.TrimSpace(key) == "" || !supportTeams[category.Team] || !supportPriorities[category.Priority] {
			return errors.New("support category contract is invalid")
		}
	}
	return nil
}

// Keep context imported in focused builds that select repository helpers.
var _ = context.Background
