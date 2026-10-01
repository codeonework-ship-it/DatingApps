package mobile

import (
	"database/sql"
	"errors"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)

func (s *Server) adminListEconomyFraudCases(w http.ResponseWriter, r *http.Request) {
	if err := requireAdminUser(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	if s.store == nil || s.store.billingRepo == nil {
		writeError(w, http.StatusServiceUnavailable, errBillingNotDurable)
		return
	}
	status := trimEconomyStatus(r.URL.Query().Get("status"))
	if status == "" {
		status = "open"
	}
	if status != "all" && status != "open" && status != "reviewing" && status != "cleared" && status != "confirmed" {
		writeError(w, http.StatusBadRequest, errors.New("invalid case status"))
		return
	}
	limit := 100
	if n, e := strconv.Atoi(r.URL.Query().Get("limit")); e == nil && n > 0 && n <= 500 {
		limit = n
	}
	query := `SELECT id::text,user_id::text,rule_code,event_type,status,severity,recommended_action,action_taken,observed_value,trigger_value,window_seconds,occurrence_count,COALESCE(match_id::text,''),COALESCE(receiver_user_id::text,''),first_detected_at,last_detected_at,lock_until,COALESCE(resolution_note,'') FROM matching.coin_economy_fraud_cases`
	args := []any{}
	if status != "all" {
		query += " WHERE status=$1"
		args = append(args, status)
	}
	args = append(args, limit)
	query += " ORDER BY CASE severity WHEN 'critical' THEN 0 WHEN 'high' THEN 1 WHEN 'medium' THEN 2 ELSE 3 END,last_detected_at DESC LIMIT $" + strconv.Itoa(len(args))
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	rows, err := s.store.billingRepo.db.QueryContext(ctx, query, args...)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	defer rows.Close()
	cases := []map[string]any{}
	for rows.Next() {
		var id, user, rule, event, st, severity, recommended, taken, match, receiver, note string
		var observed, trigger, window, count int
		var first, last time.Time
		var lock sql.NullTime
		if err = rows.Scan(&id, &user, &rule, &event, &st, &severity, &recommended, &taken, &observed, &trigger, &window, &count, &match, &receiver, &first, &last, &lock, &note); err != nil {
			writeError(w, http.StatusBadGateway, err)
			return
		}
		item := map[string]any{"id": id, "user_id": user, "rule_code": rule, "event_type": event, "status": st, "severity": severity, "recommended_action": recommended, "action_taken": taken, "observed_value": observed, "trigger_value": trigger, "window_seconds": window, "occurrence_count": count, "match_id": match, "receiver_user_id": receiver, "first_detected_at": first.UTC().Format(time.RFC3339), "last_detected_at": last.UTC().Format(time.RFC3339), "resolution_note": note}
		if lock.Valid {
			item["lock_until"] = lock.Time.UTC().Format(time.RFC3339)
		}
		cases = append(cases, item)
	}
	writeJSON(w, http.StatusOK, map[string]any{"cases": cases, "count": len(cases), "status": status})
}

func (s *Server) adminListEconomyFraudRules(w http.ResponseWriter, r *http.Request) {
	if err := requireAdminUser(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	if s.store == nil || s.store.billingRepo == nil {
		writeError(w, http.StatusServiceUnavailable, errBillingNotDurable)
		return
	}
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	rows, err := s.store.billingRepo.db.QueryContext(ctx, `SELECT rule_code,event_type,metric,window_seconds,trigger_value,response_action,lock_seconds,severity,enabled,description,updated_at FROM matching.coin_economy_fraud_rules ORDER BY event_type,rule_code`)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	defer rows.Close()
	rules := []map[string]any{}
	for rows.Next() {
		var code, event, metric, action, severity, description string
		var window, trigger, lock int
		var enabled bool
		var updated time.Time
		if err = rows.Scan(&code, &event, &metric, &window, &trigger, &action, &lock, &severity, &enabled, &description, &updated); err != nil {
			writeError(w, http.StatusBadGateway, err)
			return
		}
		rules = append(rules, map[string]any{"rule_code": code, "event_type": event, "metric": metric, "window_seconds": window, "trigger_value": trigger, "response_action": action, "lock_seconds": lock, "severity": severity, "enabled": enabled, "description": description, "updated_at": updated.UTC().Format(time.RFC3339)})
	}
	writeJSON(w, http.StatusOK, map[string]any{"rules": rules, "count": len(rules)})
}

func (s *Server) adminUpdateEconomyFraudRule(w http.ResponseWriter, r *http.Request) {
	p, _, ok := operatorRoleFor(r, "admin", "ops_admin")
	if !ok {
		writeError(w, http.StatusForbidden, errors.New("fraud rule changes require admin or ops_admin"))
		return
	}
	if s.store == nil || s.store.billingRepo == nil {
		writeError(w, http.StatusServiceUnavailable, errBillingNotDurable)
		return
	}
	code := strings.TrimSpace(chi.URLParam(r, "ruleCode"))
	payload, valid := readJSON(w, r)
	if !valid {
		return
	}
	action := trimEconomyStatus(toString(payload["response_action"]))
	trigger := orInt(payload["trigger_value"], 0)
	window := orInt(payload["window_seconds"], 0)
	lock := orInt(payload["lock_seconds"], 0)
	severity := trimEconomyStatus(toString(payload["severity"]))
	enabled := orBool(payload["enabled"], true)
	if code == "" || validateEconomyRuleAction(action) != nil || trigger < 1 || window < 60 || window > 2678400 || lock < 0 || lock > 604800 || (action == "temporary_lock" && lock < 300) || (severity != "low" && severity != "medium" && severity != "high" && severity != "critical") {
		writeError(w, http.StatusBadRequest, errors.New("invalid fraud rule values"))
		return
	}
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	res, err := s.store.billingRepo.db.ExecContext(ctx, `UPDATE matching.coin_economy_fraud_rules SET trigger_value=$2,window_seconds=$3,response_action=$4,lock_seconds=$5,severity=$6,enabled=$7,updated_by=$8::uuid,updated_at=NOW() WHERE rule_code=$1`, code, trigger, window, action, lock, severity, enabled, p.UserID)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	if n, _ := res.RowsAffected(); n == 0 {
		writeError(w, http.StatusNotFound, errors.New("fraud rule not found"))
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"rule_code": code, "updated": true})
}

func (s *Server) adminResolveEconomyFraudCase(w http.ResponseWriter, r *http.Request) {
	p, role, ok := operatorRoleFor(r, "admin", "ops_admin", "trust_safety")
	if !ok {
		writeError(w, http.StatusForbidden, errors.New("fraud review requires admin, ops_admin or trust_safety"))
		return
	}
	if s.store == nil || s.store.billingRepo == nil {
		writeError(w, http.StatusServiceUnavailable, errBillingNotDurable)
		return
	}
	caseID := strings.TrimSpace(chi.URLParam(r, "caseID"))
	if _, err := uuid.Parse(caseID); err != nil {
		writeError(w, http.StatusBadRequest, errors.New("case id must be a UUID"))
		return
	}
	payload, valid := readJSON(w, r)
	if !valid {
		return
	}
	resolution := trimEconomyStatus(toString(payload["resolution"]))
	note := strings.TrimSpace(toString(payload["note"]))
	if (resolution != "cleared" && resolution != "confirmed") || len([]rune(note)) < 10 || len([]rune(note)) > 1000 {
		writeError(w, http.StatusBadRequest, errFraudResolution)
		return
	}
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	tx, err := s.store.billingRepo.db.BeginTx(ctx, nil)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	defer tx.Rollback()
	var userID, status string
	if err = tx.QueryRowContext(ctx, `SELECT user_id::text,status FROM matching.coin_economy_fraud_cases WHERE id=$1::uuid FOR UPDATE`, caseID).Scan(&userID, &status); errors.Is(err, sql.ErrNoRows) {
		writeError(w, http.StatusNotFound, errors.New("fraud case not found"))
		return
	} else if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	if status != "open" && status != "reviewing" {
		writeError(w, http.StatusConflict, errFraudCaseNotOpen)
		return
	}
	if _, err = tx.ExecContext(ctx, `UPDATE matching.coin_economy_fraud_cases SET status=$2,resolved_at=NOW(),resolved_by=$3::uuid,resolution_note=$4,updated_at=NOW() WHERE id=$1::uuid`, caseID, resolution, p.UserID, note); err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	if resolution == "cleared" {
		if _, err = tx.ExecContext(ctx, `UPDATE matching.user_wallets SET risk_locked_until=NULL,risk_lock_reason=NULL,risk_lock_case_id=NULL,updated_at=NOW() WHERE user_id=$1::uuid AND risk_lock_case_id=$2::uuid`, userID, caseID); err != nil {
			writeError(w, http.StatusBadGateway, err)
			return
		}
	}
	if err = insertSecurityEventTx(ctx, tx, "fraud.coin_economy.case_"+resolution, p.UserID, role, userID, "fraud_case", caseID, map[string]any{"resolution": resolution, "note": note}); err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	if err = tx.Commit(); err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"case_id": caseID, "status": resolution, "wallet_risk_lock_cleared": resolution == "cleared"})
}
