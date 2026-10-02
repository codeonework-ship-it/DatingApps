package mobile

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	authapp "github.com/verified-dating/backend/internal/modules/auth/application"
	"github.com/verified-dating/backend/internal/platform/config"
)

// ─── Admin Repository ────────────────────────────────────────────────────────

type adminRepository struct {
	cfg config.Config
	db  roseGiftRepositoryDB // reuse same interface (SelectRead/Insert/Update/Delete)
	pg  *sql.DB
}

func (s *Server) runtimeFeatureEnabled(ctx context.Context, key string, fallback bool) (bool, error) {
	repo := s.store.adminRepo
	if repo == nil {
		return fallback, nil
	}
	if repo.pg != nil {
		var enabled bool
		err := repo.pg.QueryRowContext(
			ctx,
			`SELECT value_bool FROM matching.platform_feature_flags WHERE key = $1`,
			strings.TrimSpace(key),
		).Scan(&enabled)
		if errors.Is(err, sql.ErrNoRows) {
			return fallback, nil
		}
		if err != nil {
			return fallback, err
		}
		return enabled, nil
	}
	params := url.Values{}
	params.Set("select", "value_bool")
	params.Set("key", "eq."+strings.TrimSpace(key))
	params.Set("limit", "1")
	rows, err := repo.db.SelectRead(ctx, repo.cfg.MatchingSchema, "platform_feature_flags", params)
	if err != nil {
		return fallback, err
	}
	if len(rows) == 0 {
		return fallback, nil
	}
	return orBool(rows[0]["value_bool"], fallback), nil
}

func newAdminRepository(cfg config.Config, supplied ...repositoryDB) *adminRepository {
	db := repositoryDBFor(cfg, supplied)
	if db == nil {
		return nil
	}
	return &adminRepository{cfg: cfg, db: db}
}

// ─── Helper: require X-Admin-User ────────────────────────────────────────────

// requireAdminUser authorizes an operator request.
//
// This previously accepted any request carrying a non-empty X-Admin-User
// header. That header is client-supplied, so on any deployment where the
// security middleware did not run it was a complete authorization bypass: a
// caller could reach every admin handler by inventing a value for it.
//
// Authorization now derives entirely from the authenticated principal
// established by securityMiddleware. The header is retained only as an audit
// label and is overwritten by the middleware from the verified principal, so it
// can no longer grant access on its own.
func requireAdminUser(r *http.Request) error {
	_, err := authenticatedOperatorID(r)
	return err
}

func authenticatedOperatorID(r *http.Request) (string, error) {
	principal, ok := principalFromRequest(r)
	if !ok || strings.TrimSpace(principal.UserID) == "" ||
		(!principal.Roles["admin"] && !principal.Roles["trust_safety"] &&
			!principal.Roles["ops_admin"] && !principal.Roles["moderator"] &&
			!principal.Roles["analyst"] && !principal.Roles["finance"] && !principal.Roles["support"]) {
		return "", errors.New("authenticated operator role is required")
	}
	return principal.UserID, nil
}

// adminListAuditEvents exposes the append-only operator audit view to
// authenticated operators. Product activities and operator mutations are
// separate evidence streams; the command center needs both to explain what
// happened and who changed platform state.
func (s *Server) adminListAuditEvents(w http.ResponseWriter, r *http.Request) {
	if err := requireAdminUser(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	repo := s.store.adminRepo
	if repo == nil || repo.pg == nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("operator audit store unavailable"))
		return
	}

	limit := 100
	if raw := strings.TrimSpace(r.URL.Query().Get("limit")); raw != "" {
		if parsed, err := strconv.Atoi(raw); err == nil && parsed > 0 && parsed <= 500 {
			limit = parsed
		}
	}
	clauses := []string{"TRUE"}
	args := []any{}
	addFilter := func(column, value string) {
		value = strings.TrimSpace(value)
		if value == "" {
			return
		}
		args = append(args, value)
		clauses = append(clauses, fmt.Sprintf("%s = $%d", column, len(args)))
	}
	addFilter("event_type", r.URL.Query().Get("event_type"))
	addFilter("actor_user_id::text", r.URL.Query().Get("actor_user_id"))
	addFilter("subject_user_id::text", r.URL.Query().Get("subject_user_id"))
	addFilter("resource_type", r.URL.Query().Get("resource_type"))
	args = append(args, limit)

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	query := fmt.Sprintf(`
		SELECT id, occurred_at, txid, event_type,
		       COALESCE(actor_user_id::text,''), actor_role,
		       COALESCE(subject_user_id::text,''), resource_type,
		       COALESCE(resource_id,''), COALESCE(correlation_id,''), payload
		FROM audit.operator_action_log
		WHERE %s
		ORDER BY occurred_at DESC, id DESC
		LIMIT $%d`, strings.Join(clauses, " AND "), len(args))
	rows, err := repo.pg.QueryContext(ctx, query, args...)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	defer rows.Close()

	events := make([]map[string]any, 0, limit)
	for rows.Next() {
		var id, txid int64
		var occurredAt time.Time
		var eventType, actorUserID, actorRole, subjectUserID string
		var resourceType, resourceID, correlationID string
		var rawPayload []byte
		if err := rows.Scan(
			&id, &occurredAt, &txid, &eventType, &actorUserID, &actorRole,
			&subjectUserID, &resourceType, &resourceID, &correlationID, &rawPayload,
		); err != nil {
			writeError(w, http.StatusBadGateway, err)
			return
		}
		payload := map[string]any{}
		_ = json.Unmarshal(rawPayload, &payload)
		events = append(events, map[string]any{
			"id": id, "occurred_at": occurredAt.UTC(), "txid": txid,
			"event_type": eventType, "actor_user_id": actorUserID, "actor_role": actorRole,
			"subject_user_id": subjectUserID, "resource_type": resourceType,
			"resource_id": resourceID, "correlation_id": correlationID, "payload": payload,
		})
	}
	if err := rows.Err(); err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"events": events, "count": len(events), "limit": limit,
		"source": "audit.operator_action_log", "append_only": true,
		"as_of": time.Now().UTC(),
	})
}

// ─── Gift Catalog Admin ───────────────────────────────────────────────────────

func (s *Server) adminListCatalogGifts(w http.ResponseWriter, r *http.Request) {
	if err := requireAdminUser(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	repo := s.store.adminRepo
	if repo == nil {
		// fallback: in-memory catalog
		catalog := s.store.listRoseGiftCatalog()
		writeJSON(w, http.StatusOK, map[string]any{
			"gifts":  catalog,
			"count":  len(catalog),
			"source": "memory",
		})
		return
	}
	params := url.Values{}
	params.Set("select", "id,name,gif_url,tier,price_coins,icon_key,icon_emoji,category,description,max_per_match_per_day,is_active,sort_order,start_date,end_date,created_at,updated_at")
	params.Set("order", "sort_order.asc,created_at.asc")

	// pagination
	limit := 50
	if raw := strings.TrimSpace(r.URL.Query().Get("limit")); raw != "" {
		if v, err := strconv.Atoi(raw); err == nil && v > 0 && v <= 500 {
			limit = v
		}
	}
	offset := 0
	if raw := strings.TrimSpace(r.URL.Query().Get("offset")); raw != "" {
		if v, err := strconv.Atoi(raw); err == nil && v >= 0 {
			offset = v
		}
	}
	params.Set("limit", strconv.Itoa(limit))
	params.Set("offset", strconv.Itoa(offset))

	// optional filters
	if cat := strings.TrimSpace(r.URL.Query().Get("category")); cat != "" {
		params.Set("category", "eq."+cat)
	}
	if tier := strings.TrimSpace(r.URL.Query().Get("tier")); tier != "" {
		params.Set("tier", "eq."+tier)
	}
	if active := strings.TrimSpace(r.URL.Query().Get("active")); active != "" {
		switch active {
		case "yes":
			params.Set("is_active", "eq.true")
		case "no":
			params.Set("is_active", "eq.false")
		}
	}
	if q := strings.TrimSpace(r.URL.Query().Get("q")); q != "" {
		params.Set("name", "ilike.*"+q+"*")
	}

	rows, err := repo.db.SelectRead(ctx, repo.cfg.MatchingSchema, repo.cfg.GiftCatalogTable, params)
	if err != nil {
		// fallback: in-memory catalog
		catalog := s.store.listRoseGiftCatalog()
		writeJSON(w, http.StatusOK, map[string]any{
			"gifts":  catalog,
			"count":  len(catalog),
			"source": "memory",
		})
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"gifts":  rows,
		"count":  len(rows),
		"source": "db",
	})
}

func (s *Server) adminCreateCatalogGift(w http.ResponseWriter, r *http.Request) {
	if err := requireAdminUser(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}

	var body map[string]any
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, errors.New("invalid JSON body"))
		return
	}

	// Validate required fields
	giftName, _ := body["name"].(string)
	if strings.TrimSpace(giftName) == "" {
		writeError(w, http.StatusBadRequest, errors.New("name is required"))
		return
	}
	giftID, _ := body["gift_id"].(string)
	if strings.TrimSpace(giftID) == "" {
		writeError(w, http.StatusBadRequest, errors.New("gift_id is required"))
		return
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	repo := s.store.adminRepo
	if repo == nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("admin repository unavailable"))
		return
	}

	// Sanitise — map to actual DB column names (matching.gift_catalog)
	payload := map[string]any{
		"id":                    strings.TrimSpace(giftID),
		"name":                  strings.TrimSpace(giftName),
		"category":              orString(body["category"], "roses"),
		"tier":                  orString(body["tier"], "free"),
		"price_coins":           orInt(body["price_coins"], 0),
		"icon_emoji":            orString(body["icon_emoji"], "🌹"),
		"icon_key":              orString(body["icon_key"], ""),
		"gif_url":               orString(body["gif_url"], ""),
		"description":           orString(body["description"], ""),
		"max_per_match_per_day": orInt(body["max_per_match_per_day"], 0),
		"is_active":             orBool(body["is_active"], true),
		"sort_order":            orInt(body["sort_order"], 100),
	}
	if v, ok := body["start_date"].(string); ok && v != "" {
		payload["start_date"] = v
	}
	if v, ok := body["end_date"].(string); ok && v != "" {
		payload["end_date"] = v
	}

	rows, err := repo.db.Insert(ctx, repo.cfg.MatchingSchema, repo.cfg.GiftCatalogTable, []map[string]any{payload})
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	if len(rows) == 0 {
		writeError(w, http.StatusBadGateway, errors.New("insert returned no rows"))
		return
	}
	writeJSON(w, http.StatusCreated, rows[0])
}

func (s *Server) adminUpdateCatalogGift(w http.ResponseWriter, r *http.Request) {
	if err := requireAdminUser(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	giftID := strings.TrimSpace(chi.URLParam(r, "giftID"))
	if giftID == "" {
		writeError(w, http.StatusBadRequest, errors.New("giftID is required"))
		return
	}

	var body map[string]any
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, errors.New("invalid JSON body"))
		return
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	repo := s.store.adminRepo
	if repo == nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("admin repository unavailable"))
		return
	}

	payload := map[string]any{"updated_at": time.Now().UTC().Format(time.RFC3339)}
	allowedFields := []string{"name", "category", "tier", "price_coins", "icon_emoji", "icon_key",
		"gif_url", "description", "max_per_match_per_day", "is_active", "sort_order", "start_date", "end_date"}
	for _, f := range allowedFields {
		if v, ok := body[f]; ok {
			payload[f] = v
		}
	}

	filters := url.Values{}
	filters.Set("id", "eq."+giftID)

	rows, err := repo.db.Update(ctx, repo.cfg.MatchingSchema, repo.cfg.GiftCatalogTable, payload, filters)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"updated": len(rows) > 0,
		"gift_id": giftID,
	})
}

func (s *Server) adminToggleCatalogGift(w http.ResponseWriter, r *http.Request) {
	if err := requireAdminUser(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	giftID := strings.TrimSpace(chi.URLParam(r, "giftID"))
	if giftID == "" {
		writeError(w, http.StatusBadRequest, errors.New("giftID is required"))
		return
	}

	var body struct {
		IsActive bool `json:"is_active"`
	}
	_ = json.NewDecoder(r.Body).Decode(&body)

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	repo := s.store.adminRepo
	if repo == nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("admin repository unavailable"))
		return
	}

	filters := url.Values{}
	filters.Set("id", "eq."+giftID)
	payload := map[string]any{
		"is_active":  body.IsActive,
		"updated_at": time.Now().UTC().Format(time.RFC3339),
	}
	_, err := repo.db.Update(ctx, repo.cfg.MatchingSchema, repo.cfg.GiftCatalogTable, payload, filters)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"gift_id":   giftID,
		"is_active": body.IsActive,
		"updated":   true,
	})
}

func (s *Server) adminDeleteCatalogGift(w http.ResponseWriter, r *http.Request) {
	if err := requireAdminUser(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	giftID := strings.TrimSpace(chi.URLParam(r, "giftID"))
	if giftID == "" {
		writeError(w, http.StatusBadRequest, errors.New("giftID is required"))
		return
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	repo := s.store.adminRepo
	if repo == nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("admin repository unavailable"))
		return
	}

	filters := url.Values{}
	filters.Set("id", "eq."+giftID)
	_, err := repo.db.Delete(ctx, repo.cfg.MatchingSchema, repo.cfg.GiftCatalogTable, filters)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"gift_id": giftID, "deleted": true})
}

// ─── User Admin ─────────────────────────────────────────────────────────────

func (s *Server) adminListUsers(w http.ResponseWriter, r *http.Request) {
	if err := requireAdminUser(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}

	limit := 50
	if raw := strings.TrimSpace(r.URL.Query().Get("limit")); raw != "" {
		if v, err := strconv.Atoi(raw); err == nil && v > 0 && v <= 500 {
			limit = v
		}
	}
	offset := 0
	if raw := strings.TrimSpace(r.URL.Query().Get("offset")); raw != "" {
		if v, err := strconv.Atoi(raw); err == nil && v >= 0 {
			offset = v
		}
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	repo := s.store.adminRepo
	if repo == nil {
		writeJSON(w, http.StatusOK, map[string]any{"users": []any{}, "count": 0, "source": "unavailable"})
		return
	}

	params := url.Values{}
	params.Set("select", "id,username,name,phone_number,gender,bio,height_cm,education,profession,city,state,country,profile_completion,is_verified,last_login_at,created_at,suspended_at,suspended_reason,is_banned")
	params.Set("order", "created_at.desc")
	params.Set("limit", strconv.Itoa(limit))
	params.Set("offset", strconv.Itoa(offset))

	if q := strings.TrimSpace(r.URL.Query().Get("q")); q != "" {
		params.Set("or", "(username.ilike.*"+q+"*,name.ilike.*"+q+"*,phone_number.ilike.*"+q+"*)")
	}
	if gender := strings.TrimSpace(r.URL.Query().Get("gender")); gender != "" {
		params.Set("gender", "eq."+gender)
	}
	if verified := strings.TrimSpace(r.URL.Query().Get("verified")); verified != "" {
		switch verified {
		case "yes":
			params.Set("is_verified", "eq.true")
		case "no":
			params.Set("is_verified", "eq.false")
		}
	}
	if status := strings.TrimSpace(r.URL.Query().Get("status")); status != "" {
		switch status {
		case "suspended":
			params.Set("suspended_at", "not.is.null")
		case "banned":
			params.Set("is_banned", "eq.true")
		case "active":
			params.Set("suspended_at", "is.null")
			params.Set("is_banned", "eq.false")
		}
	}

	rows, err := repo.db.SelectRead(ctx, repo.cfg.UserSchema, repo.cfg.UsersTable, params)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	total := len(rows)
	kpis := map[string]any{
		"total":        total,
		"active":       0,
		"suspended":    0,
		"banned":       0,
		"verified":     0,
		"verified_pct": 0.0,
		"scope":        "returned_page",
	}
	if repo.pg != nil {
		where, args := adminUserFilterSQL(r)
		if err := repo.pg.QueryRowContext(ctx, "SELECT COUNT(*) FROM user_management.users"+where, args...).Scan(&total); err != nil {
			writeError(w, http.StatusBadGateway, err)
			return
		}
		var all, active, suspended, banned, verified int
		if err := repo.pg.QueryRowContext(ctx, `
			SELECT COUNT(*),
			       COUNT(*) FILTER (WHERE COALESCE(is_active,TRUE) AND NOT COALESCE(is_banned,FALSE)
			         AND NOT (suspended_at IS NOT NULL AND (suspended_until IS NULL OR suspended_until > NOW()))),
			       COUNT(*) FILTER (WHERE suspended_at IS NOT NULL AND (suspended_until IS NULL OR suspended_until > NOW())),
			       COUNT(*) FILTER (WHERE COALESCE(is_banned,FALSE)),
			       COUNT(*) FILTER (WHERE COALESCE(is_verified,FALSE))
			FROM user_management.users`).Scan(&all, &active, &suspended, &banned, &verified); err != nil {
			writeError(w, http.StatusBadGateway, err)
			return
		}
		verifiedPct := 0.0
		if all > 0 {
			verifiedPct = float64(verified) * 100 / float64(all)
		}
		kpis = map[string]any{
			"total": all, "active": active, "suspended": suspended,
			"banned": banned, "verified": verified, "verified_pct": verifiedPct,
			"scope": "all_users", "as_of": time.Now().UTC(),
		}
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"users": rows,
		"total": total,
		"kpis":  kpis,
	})
}

func adminUserFilterSQL(r *http.Request) (string, []any) {
	clauses := []string{}
	args := []any{}
	add := func(clause string, value any) {
		args = append(args, value)
		clauses = append(clauses, fmt.Sprintf(clause, len(args)))
	}
	if q := strings.TrimSpace(r.URL.Query().Get("q")); q != "" {
		add("(username ILIKE $%[1]d OR name ILIKE $%[1]d OR phone_number ILIKE $%[1]d)", "%"+q+"%")
		// The clause contains the same placeholder three times intentionally.
	}
	if gender := strings.TrimSpace(r.URL.Query().Get("gender")); gender != "" {
		add("gender = $%d", gender)
	}
	switch strings.TrimSpace(r.URL.Query().Get("verified")) {
	case "yes":
		clauses = append(clauses, "COALESCE(is_verified,FALSE) = TRUE")
	case "no":
		clauses = append(clauses, "COALESCE(is_verified,FALSE) = FALSE")
	}
	switch strings.TrimSpace(r.URL.Query().Get("status")) {
	case "active":
		clauses = append(clauses, "COALESCE(is_active,TRUE) = TRUE", "COALESCE(is_banned,FALSE) = FALSE", "NOT (suspended_at IS NOT NULL AND (suspended_until IS NULL OR suspended_until > NOW()))")
	case "suspended":
		clauses = append(clauses, "suspended_at IS NOT NULL AND (suspended_until IS NULL OR suspended_until > NOW())")
	case "banned":
		clauses = append(clauses, "COALESCE(is_banned,FALSE) = TRUE")
	}
	if len(clauses) == 0 {
		return "", args
	}
	return " WHERE " + strings.Join(clauses, " AND "), args
}

func (s *Server) adminGetUser(w http.ResponseWriter, r *http.Request) {
	if err := requireAdminUser(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("userID is required"))
		return
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	repo := s.store.adminRepo
	if repo == nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("admin repository unavailable"))
		return
	}

	params := url.Values{}
	params.Set("id", "eq."+userID)
	params.Set("select", "id,username,name,phone_number,gender,bio,height_cm,education,profession,income_range,drinking,smoking,religion,mother_tongue,personality_type,city,state,country,profile_completion,is_verified,is_active,last_login_at,created_at,updated_at,suspended_at,suspended_reason,suspended_until,is_banned")
	params.Set("limit", "1")

	rows, err := repo.db.SelectRead(ctx, repo.cfg.UserSchema, repo.cfg.UsersTable, params)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	if len(rows) == 0 {
		writeError(w, http.StatusNotFound, errors.New("user not found"))
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"user": rows[0]})
}

func (s *Server) adminSuspendUser(w http.ResponseWriter, r *http.Request) {
	if err := requireAdminUser(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("userID is required"))
		return
	}

	var body struct {
		Reason string `json:"reason"`
		Days   int    `json:"days"` // 0 = permanent
	}
	_ = json.NewDecoder(r.Body).Decode(&body)

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	repo := s.store.adminRepo
	if repo == nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("admin repository unavailable"))
		return
	}
	if repo.pg != nil {
		operatorID, authErr := authenticatedOperatorID(r)
		if authErr != nil {
			writeError(w, http.StatusForbidden, authErr)
			return
		}
		var until *time.Time
		if body.Days > 0 {
			value := time.Now().UTC().AddDate(0, 0, body.Days)
			until = &value
		}
		if err := repo.setUserSuspension(ctx, operatorID, userID, body.Reason, until, true); err != nil {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{"user_id": userID, "suspended": true, "reason": body.Reason})
		return
	}

	now := time.Now().UTC()
	payload := map[string]any{
		"suspended_at":     now.Format(time.RFC3339),
		"suspended_reason": body.Reason,
	}
	if body.Days > 0 {
		payload["suspended_until"] = now.AddDate(0, 0, body.Days).Format(time.RFC3339)
	}

	filters := url.Values{}
	filters.Set("id", "eq."+userID)
	_, err := repo.db.Update(ctx, repo.cfg.UserSchema, repo.cfg.UsersTable, payload, filters)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"user_id": userID, "suspended": true, "reason": body.Reason})
}

func (s *Server) adminUnsuspendUser(w http.ResponseWriter, r *http.Request) {
	if err := requireAdminUser(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("userID is required"))
		return
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	repo := s.store.adminRepo
	if repo == nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("admin repository unavailable"))
		return
	}
	if repo.pg != nil {
		operatorID, authErr := authenticatedOperatorID(r)
		if authErr != nil {
			writeError(w, http.StatusForbidden, authErr)
			return
		}
		if err := repo.setUserSuspension(ctx, operatorID, userID, "", nil, false); err != nil {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{"user_id": userID, "suspended": false})
		return
	}

	filters := url.Values{}
	filters.Set("id", "eq."+userID)
	payload := map[string]any{
		"suspended_at":     nil,
		"suspended_reason": nil,
		"suspended_until":  nil,
	}
	_, err := repo.db.Update(ctx, repo.cfg.UserSchema, repo.cfg.UsersTable, payload, filters)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"user_id": userID, "suspended": false})
}

func (s *Server) adminCreateUser(w http.ResponseWriter, r *http.Request) {
	if err := requireAdminUser(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}

	var body map[string]any
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, errors.New("invalid JSON body"))
		return
	}

	name, _ := body["name"].(string)
	username, _ := body["username"].(string)
	password, _ := body["password"].(string)
	phone, _ := body["phone_number"].(string)
	if strings.TrimSpace(name) == "" || strings.TrimSpace(username) == "" || password == "" {
		writeError(w, http.StatusBadRequest, errors.New("name, username, and password are required"))
		return
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	repo := s.store.adminRepo
	if repo == nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("admin repository unavailable"))
		return
	}

	username = strings.ToLower(strings.TrimSpace(username))
	authResponse, err := s.mediator.Send(ctx, authapp.SignupCommandName, authapp.SignupCommand{
		Username: username,
		Password: password,
	})
	if err != nil {
		if errors.Is(err, authapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}
	authPayload, ok := authResponse.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected signup response payload"))
		return
	}
	if success, _ := authPayload["success"].(bool); !success {
		writeError(w, http.StatusConflict, errors.New(orString(authPayload["error"], "username is already taken")))
		return
	}
	userID := strings.TrimSpace(toString(authPayload["user_id"]))
	if userID == "" {
		writeError(w, http.StatusBadGateway, errors.New("signup response did not include user_id"))
		return
	}

	dob := orString(body["date_of_birth"], "2000-01-01")
	payload := map[string]any{
		"id":             userID,
		"username":       username,
		"name":           strings.TrimSpace(name),
		"date_of_birth":  dob,
		"gender":         orString(body["gender"], "other"),
		"bio":            orString(body["bio"], ""),
		"terms_accepted": true,
	}
	if strings.TrimSpace(phone) != "" {
		payload["phone_number"] = strings.TrimSpace(phone)
	}
	if v, ok := body["height_cm"]; ok {
		payload["height_cm"] = v
	}
	if v, _ := body["education"].(string); v != "" {
		payload["education"] = v
	}
	if v, _ := body["profession"].(string); v != "" {
		payload["profession"] = v
	}
	if v, _ := body["city"].(string); v != "" {
		payload["city"] = v
	}
	if v, _ := body["state"].(string); v != "" {
		payload["state"] = v
	}

	rows, err := repo.db.Insert(ctx, repo.cfg.UserSchema, repo.cfg.UsersTable, []map[string]any{payload})
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	if len(rows) == 0 {
		writeError(w, http.StatusBadGateway, errors.New("insert returned no rows"))
		return
	}
	writeJSON(w, http.StatusCreated, rows[0])
}

func (s *Server) adminUpdateUser(w http.ResponseWriter, r *http.Request) {
	if err := requireAdminUser(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("userID is required"))
		return
	}

	var body map[string]any
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, errors.New("invalid JSON body"))
		return
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	repo := s.store.adminRepo
	if repo == nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("admin repository unavailable"))
		return
	}

	payload := map[string]any{"updated_at": time.Now().UTC().Format(time.RFC3339)}
	allowedFields := []string{"name", "phone_number", "gender", "bio", "height_cm", "education",
		"profession", "income_range", "drinking", "smoking", "religion", "mother_tongue",
		"personality_type", "city", "state", "country"}
	for _, f := range allowedFields {
		if v, ok := body[f]; ok {
			payload[f] = v
		}
	}

	filters := url.Values{}
	filters.Set("id", "eq."+userID)
	_, err := repo.db.Update(ctx, repo.cfg.UserSchema, repo.cfg.UsersTable, payload, filters)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"user_id": userID, "updated": true})
}

func (s *Server) adminDeleteUser(w http.ResponseWriter, r *http.Request) {
	if err := requireAdminUser(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("userID is required"))
		return
	}
	// A hard delete of the users row skipped erasure entirely: storage
	// objects, audit copies and SOS data survived, nothing was audited, and
	// RESTRICT foreign keys could fail it halfway. Operator removal now
	// schedules the same erasure a member's own deletion does.
	repo := s.store.profileRepo
	if repo == nil || repo.pg == nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("account erasure persistence is unavailable"))
		return
	}
	operatorID := ""
	if principal, ok := principalFromRequest(r); ok {
		operatorID = principal.UserID
	}
	reason := strings.TrimSpace(r.URL.Query().Get("reason"))
	if reason == "" {
		reason = "operator_account_removal"
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	state, err := repo.scheduleAccountDeletion(ctx, userID, operatorID, "operator", reason)
	if err != nil {
		switch {
		case errors.Is(err, sql.ErrNoRows):
			writeError(w, http.StatusNotFound, errors.New("user not found"))
		case strings.Contains(err.Error(), "already scheduled"):
			writeJSON(w, http.StatusConflict, map[string]any{
				"success": false, "error": err.Error(), "error_code": "DELETION_ALREADY_SCHEDULED",
			})
		default:
			writeError(w, http.StatusBadGateway, err)
		}
		return
	}
	writeJSON(w, http.StatusAccepted, map[string]any{
		"user_id":            userID,
		"deletion_scheduled": true,
		"deleted":            false,
		"lifecycle":          state,
	})
}

// ─── Feature Flags ──────────────────────────────────────────────────────────

// runtimeConfigFlags is the application-facing projection of the operator
// feature-flag table. It intentionally omits operator identity and descriptions:
// the mobile client only needs the current switch values and their revision.
func (s *Server) runtimeConfigFlags(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	repo := s.store.adminRepo
	if repo == nil {
		writeJSON(w, http.StatusOK, map[string]any{
			"flags": s.applyReleaseExclusions(defaultFeatureFlags()), "source": "defaults",
		})
		return
	}

	params := url.Values{}
	params.Set("select", "key,value_bool,updated_at")
	params.Set("order", "key.asc")
	rows, err := repo.db.SelectRead(ctx, repo.cfg.MatchingSchema, "platform_feature_flags", params)
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("runtime feature flags unavailable"))
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"flags": s.applyReleaseExclusions(rows), "source": "db"})
}

// applyReleaseExclusions reports every release-excluded flag as off, adding a
// row when the database has none, so shipped clients hide those surfaces.
func (s *Server) applyReleaseExclusions(rows []map[string]any) []map[string]any {
	if len(s.cfg.ReleaseExcludedFlags) == 0 {
		return rows
	}
	seen := map[string]bool{}
	for _, row := range rows {
		key := strings.TrimSpace(toString(row["key"]))
		seen[key] = true
		if s.cfg.IsReleaseExcluded(key) {
			row["value_bool"] = false
			row["release_excluded"] = true
		}
	}
	for _, key := range s.cfg.ReleaseExcludedFlags {
		if !seen[key] {
			rows = append(rows, map[string]any{"key": key, "value_bool": false, "release_excluded": true})
		}
	}
	return rows
}

func (s *Server) adminListConfigFlags(w http.ResponseWriter, r *http.Request) {
	if err := requireAdminUser(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	repo := s.store.adminRepo
	if repo == nil {
		// fallback: all flags default to true
		flags := defaultFeatureFlags()
		writeJSON(w, http.StatusOK, map[string]any{"flags": flags, "source": "defaults"})
		return
	}

	params := url.Values{}
	params.Set("select", "key,value_bool,description,updated_by,updated_at")
	params.Set("order", "key.asc")

	rows, err := repo.db.SelectRead(ctx, repo.cfg.MatchingSchema, "platform_feature_flags", params)
	if err != nil {
		flags := defaultFeatureFlags()
		writeJSON(w, http.StatusOK, map[string]any{"flags": flags, "source": "defaults"})
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"flags": rows, "source": "db"})
}

func (s *Server) adminUpdateConfigFlag(w http.ResponseWriter, r *http.Request) {
	if err := requireAdminUser(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	key := strings.TrimSpace(chi.URLParam(r, "key"))
	if key == "" {
		writeError(w, http.StatusBadRequest, errors.New("key is required"))
		return
	}

	var body struct {
		Value     bool   `json:"value_bool"`
		UpdatedBy string `json:"updated_by"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, errors.New("invalid JSON body"))
		return
	}
	if strings.TrimSpace(body.UpdatedBy) == "" {
		body.UpdatedBy = r.Header.Get("X-Admin-User")
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	repo := s.store.adminRepo
	if repo == nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("admin repository unavailable"))
		return
	}

	filters := url.Values{}
	filters.Set("key", "eq."+key)
	payload := map[string]any{
		"value_bool": body.Value,
		"updated_by": body.UpdatedBy,
		"updated_at": time.Now().UTC().Format(time.RFC3339),
	}
	_, err := repo.db.Update(ctx, repo.cfg.MatchingSchema, "platform_feature_flags", payload, filters)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"key": key, "value_bool": body.Value, "updated": true})
}

// ─── Engagement Prompts ──────────────────────────────────────────────────────

func (s *Server) adminListEngagementPrompts(w http.ResponseWriter, r *http.Request) {
	if err := requireAdminUser(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	repo := s.store.adminRepo
	if repo == nil {
		writeJSON(w, http.StatusOK, map[string]any{"prompts": []any{}, "count": 0})
		return
	}

	params := url.Values{}
	params.Set("select", "id,question_text,category,active_date,is_active,response_count,created_by,created_at")
	params.Set("order", "created_at.desc")
	params.Set("limit", "100")

	rows, err := repo.db.SelectRead(ctx, repo.cfg.MatchingSchema, "admin_daily_prompts", params)
	if err != nil {
		writeJSON(w, http.StatusOK, map[string]any{"prompts": []any{}, "count": 0, "error": err.Error()})
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"prompts": rows, "count": len(rows)})
}

func (s *Server) adminListEngagementNudges(w http.ResponseWriter, r *http.Request) {
	if err := requireAdminUser(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	repo := s.store.adminRepo
	if repo == nil {
		writeJSON(w, http.StatusOK, map[string]any{"nudges": []any{}, "count": 0, "by_type": map[string]int{}})
		return
	}
	params := url.Values{}
	params.Set("select", "id,match_id,user_id,counterparty_user_id,nudge_type,created_at,clicked_at")
	params.Set("order", "created_at.desc")
	params.Set("limit", "100")
	rows, err := repo.db.SelectRead(ctx, repo.cfg.MatchingSchema, "match_nudges", params)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	byType := map[string]int{}
	clicked := 0
	for _, row := range rows {
		byType[strings.TrimSpace(toString(row["nudge_type"]))]++
		if strings.TrimSpace(toString(row["clicked_at"])) != "" {
			clicked++
		}
	}
	enabled, _ := s.runtimeFeatureEnabled(ctx, "match_nudges_enabled", true)
	writeJSON(w, http.StatusOK, map[string]any{
		"nudges": rows, "count": len(rows), "clicked": clicked,
		"by_type": byType, "enabled": enabled,
	})
}

func (s *Server) adminCreateEngagementPrompt(w http.ResponseWriter, r *http.Request) {
	if err := requireAdminUser(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}

	var body map[string]any
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, errors.New("invalid JSON body"))
		return
	}

	text, _ := body["question_text"].(string)
	if strings.TrimSpace(text) == "" {
		writeError(w, http.StatusBadRequest, errors.New("question_text is required"))
		return
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	repo := s.store.adminRepo
	if repo == nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("admin repository unavailable"))
		return
	}

	payload := map[string]any{
		"question_text": strings.TrimSpace(text),
		"category":      orString(body["category"], "general"),
		"is_active":     orBool(body["is_active"], false),
		"created_by":    r.Header.Get("X-Admin-User"),
	}
	if v, ok := body["active_date"].(string); ok && v != "" {
		payload["active_date"] = v
	}

	rows, err := repo.db.Insert(ctx, repo.cfg.MatchingSchema, "admin_daily_prompts", []map[string]any{payload})
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	if len(rows) == 0 {
		writeError(w, http.StatusBadGateway, errors.New("insert returned no rows"))
		return
	}
	writeJSON(w, http.StatusCreated, rows[0])
}

func (s *Server) adminUpdateEngagementPrompt(w http.ResponseWriter, r *http.Request) {
	if err := requireAdminUser(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	promptID := strings.TrimSpace(chi.URLParam(r, "promptID"))
	if promptID == "" {
		writeError(w, http.StatusBadRequest, errors.New("promptID is required"))
		return
	}

	var body map[string]any
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, errors.New("invalid JSON body"))
		return
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	repo := s.store.adminRepo
	if repo == nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("admin repository unavailable"))
		return
	}

	payload := map[string]any{"updated_at": time.Now().UTC().Format(time.RFC3339)}
	for _, f := range []string{"question_text", "category", "is_active", "active_date"} {
		if v, ok := body[f]; ok {
			payload[f] = v
		}
	}

	filters := url.Values{}
	filters.Set("id", "eq."+promptID)
	_, err := repo.db.Update(ctx, repo.cfg.MatchingSchema, "admin_daily_prompts", payload, filters)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"prompt_id": promptID, "updated": true})
}

func (s *Server) adminActivateEngagementPrompt(w http.ResponseWriter, r *http.Request) {
	if err := requireAdminUser(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	promptID := strings.TrimSpace(chi.URLParam(r, "promptID"))
	if promptID == "" {
		writeError(w, http.StatusBadRequest, errors.New("promptID is required"))
		return
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	repo := s.store.adminRepo
	if repo == nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("admin repository unavailable"))
		return
	}

	// Deactivate all others first
	allFilters := url.Values{}
	allFilters.Set("is_active", "eq.true")
	_, _ = repo.db.Update(ctx, repo.cfg.MatchingSchema, "admin_daily_prompts",
		map[string]any{"is_active": false}, allFilters)

	// Activate this one
	thisFilter := url.Values{}
	thisFilter.Set("id", "eq."+promptID)
	now := time.Now().UTC()
	_, err := repo.db.Update(ctx, repo.cfg.MatchingSchema, "admin_daily_prompts", map[string]any{
		"is_active":   true,
		"active_date": now.Format("2006-01-02"),
		"updated_at":  now.Format(time.RFC3339),
	}, thisFilter)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"prompt_id": promptID, "activated": true})
}

// ─── Admin Billing ──────────────────────────────────────────────────────────

func (s *Server) adminListBillingPlans(w http.ResponseWriter, r *http.Request) {
	if err := requireAdminUser(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	// Try durable billing_plans table first; fall back to in-memory
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	repo := s.store.adminRepo
	if repo != nil {
		params := url.Values{}
		params.Set("select", "id,name,monthly_price,yearly_price,likes_per_day,messages_per_day,features,is_active,sort_order,created_at,updated_at")
		params.Set("order", "sort_order.asc")
		rows, err := repo.db.SelectRead(ctx, repo.cfg.MatchingSchema, "billing_plans", params)
		if err == nil && len(rows) > 0 {
			writeJSON(w, http.StatusOK, map[string]any{"plans": rows, "count": len(rows), "source": "db"})
			return
		}
	}
	// Fallback to mediator/in-memory path
	s.listBillingPlans(w, r)
}

func (s *Server) adminListCoinPackages(w http.ResponseWriter, r *http.Request) {
	if err := requireAdminUser(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	repo := s.store.adminRepo
	if repo == nil {
		writeJSON(w, http.StatusOK, map[string]any{"packages": defaultCoinPackages(), "source": "defaults"})
		return
	}

	params := url.Values{}
	params.Set("select", "id,label,coin_amount,price_usd,is_active,sort_order")
	params.Set("order", "sort_order.asc")

	rows, err := repo.db.SelectRead(ctx, repo.cfg.MatchingSchema, "coin_packages", params)
	if err != nil {
		writeJSON(w, http.StatusOK, map[string]any{"packages": defaultCoinPackages(), "source": "defaults"})
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"packages": rows, "count": len(rows), "source": "db"})
}

func (s *Server) adminToggleCoinPackage(w http.ResponseWriter, r *http.Request) {
	if err := requireAdminUser(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	packageID := strings.TrimSpace(chi.URLParam(r, "packageID"))
	if packageID == "" {
		writeError(w, http.StatusBadRequest, errors.New("packageID is required"))
		return
	}
	var body struct {
		IsActive bool `json:"is_active"`
	}
	_ = json.NewDecoder(r.Body).Decode(&body)

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	repo := s.store.adminRepo
	if repo == nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("admin repository unavailable"))
		return
	}

	filters := url.Values{}
	filters.Set("id", "eq."+packageID)
	_, err := repo.db.Update(ctx, repo.cfg.MatchingSchema, "coin_packages",
		map[string]any{"is_active": body.IsActive}, filters)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"package_id": packageID, "is_active": body.IsActive})
}

// ─── Ban / Unban / Verify ───────────────────────────────────────────────────

func (s *Server) adminBanUser(w http.ResponseWriter, r *http.Request) {
	if err := requireAdminUser(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("userID is required"))
		return
	}
	var body struct {
		Reason string `json:"reason"`
	}
	_ = json.NewDecoder(r.Body).Decode(&body)

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	repo := s.store.adminRepo
	if repo == nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("admin repository unavailable"))
		return
	}
	if repo.pg != nil {
		operatorID, authErr := authenticatedOperatorID(r)
		if authErr != nil {
			writeError(w, http.StatusForbidden, authErr)
			return
		}
		if err := repo.setUserBan(ctx, operatorID, userID, body.Reason, true); err != nil {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{"user_id": userID, "banned": true, "reason": body.Reason})
		return
	}

	filters := url.Values{}
	filters.Set("id", "eq."+userID)
	payload := map[string]any{
		"is_banned":        true,
		"suspended_reason": body.Reason,
	}
	_, err := repo.db.Update(ctx, repo.cfg.UserSchema, repo.cfg.UsersTable, payload, filters)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"user_id": userID, "banned": true, "reason": body.Reason})
}

func (s *Server) adminUnbanUser(w http.ResponseWriter, r *http.Request) {
	if err := requireAdminUser(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("userID is required"))
		return
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	repo := s.store.adminRepo
	if repo == nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("admin repository unavailable"))
		return
	}
	if repo.pg != nil {
		operatorID, authErr := authenticatedOperatorID(r)
		if authErr != nil {
			writeError(w, http.StatusForbidden, authErr)
			return
		}
		if err := repo.setUserBan(ctx, operatorID, userID, "", false); err != nil {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{"user_id": userID, "banned": false})
		return
	}

	filters := url.Values{}
	filters.Set("id", "eq."+userID)
	payload := map[string]any{
		"is_banned": false,
	}
	_, err := repo.db.Update(ctx, repo.cfg.UserSchema, repo.cfg.UsersTable, payload, filters)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"user_id": userID, "banned": false})
}

func (s *Server) adminForceVerifyUser(w http.ResponseWriter, r *http.Request) {
	if err := requireAdminUser(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("userID is required"))
		return
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	repo := s.store.adminRepo
	if repo == nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("admin repository unavailable"))
		return
	}
	if repo.pg != nil {
		operatorID, authErr := authenticatedOperatorID(r)
		if authErr != nil {
			writeError(w, http.StatusForbidden, authErr)
			return
		}
		if err := repo.forceVerifyUser(ctx, operatorID, userID); err != nil {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{"user_id": userID, "verified": true})
		return
	}

	filters := url.Values{}
	filters.Set("id", "eq."+userID)
	payload := map[string]any{
		"is_verified": true,
	}
	_, err := repo.db.Update(ctx, repo.cfg.UserSchema, repo.cfg.UsersTable, payload, filters)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"user_id": userID, "verified": true})
}

// ─── Billing Transactions ──────────────────────────────────────────────────

func (s *Server) adminListBillingTransactions(w http.ResponseWriter, r *http.Request) {
	if err := requireAdminUser(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}

	limit := 50
	if raw := strings.TrimSpace(r.URL.Query().Get("limit")); raw != "" {
		if v, err := strconv.Atoi(raw); err == nil && v > 0 && v <= 500 {
			limit = v
		}
	}
	offset := 0
	if raw := strings.TrimSpace(r.URL.Query().Get("offset")); raw != "" {
		if v, err := strconv.Atoi(raw); err == nil && v >= 0 {
			offset = v
		}
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	repo := s.store.adminRepo
	if repo == nil {
		writeJSON(w, http.StatusOK, map[string]any{"transactions": []any{}, "total": 0})
		return
	}

	params := url.Values{}
	params.Set("select", "id,user_id,package_id,source,provider,coins,amount_minor,currency,purchase_ref,created_at")
	params.Set("order", "created_at.desc")
	params.Set("limit", strconv.Itoa(limit))
	params.Set("offset", strconv.Itoa(offset))

	if source := strings.TrimSpace(r.URL.Query().Get("source")); source != "" {
		params.Set("source", "eq."+source)
	}
	if provider := strings.TrimSpace(r.URL.Query().Get("provider")); provider != "" {
		params.Set("provider", "eq."+provider)
	}
	// CON-04: the console's member page asks for that member's rows instead
	// of filtering the latest page platform-wide.
	if userID := strings.TrimSpace(r.URL.Query().Get("user_id")); userID != "" {
		if !uuidPattern.MatchString(userID) {
			writeError(w, http.StatusBadRequest, errors.New("user_id must be a member UUID"))
			return
		}
		params.Set("user_id", "eq."+strings.ToLower(userID))
	}

	rows, err := repo.db.SelectRead(ctx, repo.cfg.MatchingSchema, "wallet_coin_purchases", params)
	if err != nil {
		writeJSON(w, http.StatusOK, map[string]any{"transactions": []any{}, "total": 0, "note": "table not found"})
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"transactions": rows, "total": len(rows)})
}

// ─── Coin Package CRUD ─────────────────────────────────────────────────────

func (s *Server) adminCreateCoinPackage(w http.ResponseWriter, r *http.Request) {
	if err := requireAdminUser(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}

	var body map[string]any
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, errors.New("invalid JSON body"))
		return
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	repo := s.store.adminRepo
	if repo == nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("admin repository unavailable"))
		return
	}

	allowed := map[string]bool{"label": true, "coin_amount": true, "price_usd": true, "bonus_percent": true, "sort_order": true, "is_active": true, "description": true}
	payload := map[string]any{}
	for k, v := range body {
		if allowed[k] {
			payload[k] = v
		}
	}
	if payload["label"] == nil || payload["coin_amount"] == nil || payload["price_usd"] == nil {
		writeError(w, http.StatusBadRequest, errors.New("label, coin_amount, and price_usd are required"))
		return
	}

	_, err := repo.db.Insert(ctx, repo.cfg.MatchingSchema, "coin_packages", payload)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	writeJSON(w, http.StatusCreated, map[string]any{"created": true})
}

func (s *Server) adminUpdateCoinPackage(w http.ResponseWriter, r *http.Request) {
	if err := requireAdminUser(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	packageID := strings.TrimSpace(chi.URLParam(r, "packageID"))
	if packageID == "" {
		writeError(w, http.StatusBadRequest, errors.New("packageID is required"))
		return
	}

	var body map[string]any
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, errors.New("invalid JSON body"))
		return
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	repo := s.store.adminRepo
	if repo == nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("admin repository unavailable"))
		return
	}

	allowed := map[string]bool{"label": true, "coin_amount": true, "price_usd": true, "bonus_percent": true, "sort_order": true, "is_active": true, "description": true}
	payload := map[string]any{}
	for k, v := range body {
		if allowed[k] {
			payload[k] = v
		}
	}

	filters := url.Values{}
	filters.Set("id", "eq."+packageID)
	_, err := repo.db.Update(ctx, repo.cfg.MatchingSchema, "coin_packages", payload, filters)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"package_id": packageID, "updated": true})
}

// ─── Safety / SOS ──────────────────────────────────────────────────────────

func (s *Server) adminListSOSAlerts(w http.ResponseWriter, r *http.Request) {
	if err := requireAdminUser(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	repo := s.store.adminRepo
	if repo == nil {
		writeJSON(w, http.StatusOK, map[string]any{"alerts": []any{}, "count": 0})
		return
	}
	if repo.pg != nil && s.store.safetyRepo != nil {
		alerts, listErr := s.store.safetyRepo.listSOSAlerts(ctx, "", 100)
		if listErr != nil {
			writeError(w, http.StatusBadGateway, listErr)
			return
		}
		metrics, metricsErr := s.store.safetyRepo.sosDeliveryMetrics(ctx)
		if metricsErr != nil {
			writeError(w, http.StatusBadGateway, metricsErr)
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{"alerts": alerts, "count": len(alerts), "delivery_metrics": metrics})
		return
	}

	params := url.Values{}
	params.Set("select", "id,user_id,status,created_at,resolved_at,resolved_by")
	params.Set("order", "created_at.desc")
	params.Set("limit", "100")

	// The SOS table name — try user schema first
	rows, err := repo.db.SelectRead(ctx, repo.cfg.UserSchema, "safety_alerts", params)
	if err != nil {
		writeJSON(w, http.StatusOK, map[string]any{"alerts": []any{}, "count": 0, "note": "table not found"})
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"alerts": rows, "count": len(rows)})
}

func (s *Server) adminResolveSOSAlert(w http.ResponseWriter, r *http.Request) {
	if err := requireAdminUser(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	alertID := strings.TrimSpace(chi.URLParam(r, "alertID"))
	if alertID == "" {
		writeError(w, http.StatusBadRequest, errors.New("alertID is required"))
		return
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	repo := s.store.adminRepo
	if repo == nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("admin repository unavailable"))
		return
	}
	if repo.pg != nil && s.store.safetyRepo != nil {
		operatorID, authErr := authenticatedOperatorID(r)
		if authErr != nil {
			writeError(w, http.StatusForbidden, authErr)
			return
		}
		alert, resolveErr := s.store.safetyRepo.resolveSOSAlert(ctx, alertID, operatorID, "")
		if resolveErr != nil {
			writeError(w, http.StatusBadRequest, resolveErr)
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{"alert": alert, "alert_id": alertID, "resolved": true})
		return
	}

	now := time.Now().UTC()
	filters := url.Values{}
	filters.Set("id", "eq."+alertID)
	payload := map[string]any{
		"status":      "resolved",
		"resolved_at": now.Format(time.RFC3339),
		"resolved_by": r.Header.Get("X-Admin-User"),
	}
	_, err := repo.db.Update(ctx, repo.cfg.UserSchema, "safety_alerts", payload, filters)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"alert_id": alertID, "resolved": true})
}

// ─── Admin Wallet Balance ─────────────────────────────────────────────────────

func (s *Server) adminGetWalletBalance(w http.ResponseWriter, r *http.Request) {
	if err := requireAdminUser(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("userID is required"))
		return
	}
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	// GO-02: this is a read. An unknown member is a 404 (no wallet row is
	// created and nothing is written for them), and a member without a wallet
	// reads as a zero balance.
	if repo := s.store.adminRepo; repo != nil {
		if !uuidPattern.MatchString(userID) {
			writeError(w, http.StatusNotFound, errors.New("member not found"))
			return
		}
		params := url.Values{}
		params.Set("id", "eq."+userID)
		params.Set("select", "id")
		params.Set("limit", "1")
		rows, err := repo.db.SelectRead(ctx, repo.cfg.UserSchema, repo.cfg.UsersTable, params)
		if err != nil {
			writeError(w, http.StatusBadGateway, err)
			return
		}
		if len(rows) == 0 {
			writeError(w, http.StatusNotFound, errors.New("member not found"))
			return
		}
	}
	wallet, err := s.store.readWalletCoins(ctx, userID)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"wallet": wallet})
}

// ─── Billing Stats / KPI ─────────────────────────────────────────────────────

// adminBillingStats is windowed (since/until, default 30 days), aggregated in
// SQL, excludes local activations, sandbox (unless mode=sandbox|all), admin
// grants and promotions, and reports money per currency. See
// business_reports.go and documents/BUSINESS_REPORTS_2026-10-01.md.
func (s *Server) adminBillingStats(w http.ResponseWriter, r *http.Request) {
	s.billingStatsSummary(w, r)
}

// ─── Admin Grant Coins (from billing page — user_id in body) ─────────────────

func (s *Server) adminGrantCoins(w http.ResponseWriter, r *http.Request) {
	if err := requireAdminUser(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	body, ok := readJSON(w, r)
	if !ok {
		return
	}
	userID := strings.TrimSpace(toString(body["user_id"]))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("user_id is required"))
		return
	}
	amount, _ := toInt(body["amount"])
	if amount < 1 || amount > 100000 {
		writeError(w, http.StatusBadRequest, errors.New("amount must be 1–100000"))
		return
	}
	reason := strings.TrimSpace(toString(body["reason"]))
	if reason == "" {
		reason = "admin_grant"
	}
	wallet, err := s.store.topUpWalletCoins(userID, amount, reason)
	if err != nil {
		writeError(w, http.StatusBadRequest, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"user_id":     userID,
		"coins":       amount,
		"new_balance": wallet.CoinBalance,
		"granted":     true,
	})
}

// ─── Admin Subscriptions (FR-09) ─────────────────────────────────────────────

func (s *Server) adminListSubscriptions(w http.ResponseWriter, r *http.Request) {
	if err := requireAdminUser(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}

	limit := 50
	if raw := strings.TrimSpace(r.URL.Query().Get("limit")); raw != "" {
		if v, err := strconv.Atoi(raw); err == nil && v > 0 && v <= 500 {
			limit = v
		}
	}
	offset := 0
	if raw := strings.TrimSpace(r.URL.Query().Get("offset")); raw != "" {
		if v, err := strconv.Atoi(raw); err == nil && v >= 0 {
			offset = v
		}
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	repo := s.store.adminRepo
	if repo == nil {
		writeJSON(w, http.StatusOK, map[string]any{"subscriptions": []any{}, "total": 0})
		return
	}

	params := url.Values{}
	params.Set("select", "id,user_id,plan_code,status,billing_cycle,start_date,end_date,next_billing_date,auto_renew,cancel_at_period_end,current_period_end,provider,provider_subscription_id,payment_method_brand,payment_method_last4,amount_minor,currency,created_at,updated_at")
	params.Set("order", "created_at.desc")
	params.Set("limit", strconv.Itoa(limit))
	params.Set("offset", strconv.Itoa(offset))

	if status := strings.TrimSpace(r.URL.Query().Get("status")); status != "" {
		params.Set("status", "eq."+status)
	}
	if planCode := strings.TrimSpace(r.URL.Query().Get("plan_code")); planCode != "" {
		params.Set("plan_code", "eq."+planCode)
	}

	rows, err := repo.db.SelectRead(ctx, repo.cfg.MatchingSchema, "billing_subscriptions_runtime", params)
	if err != nil {
		writeJSON(w, http.StatusOK, map[string]any{"subscriptions": []any{}, "total": 0, "note": "table not found"})
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"subscriptions": rows, "total": len(rows)})
}

func (s *Server) adminListPayments(w http.ResponseWriter, r *http.Request) {
	if err := requireAdminUser(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}

	limit := 50
	if raw := strings.TrimSpace(r.URL.Query().Get("limit")); raw != "" {
		if v, err := strconv.Atoi(raw); err == nil && v > 0 && v <= 500 {
			limit = v
		}
	}
	offset := 0
	if raw := strings.TrimSpace(r.URL.Query().Get("offset")); raw != "" {
		if v, err := strconv.Atoi(raw); err == nil && v >= 0 {
			offset = v
		}
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	repo := s.store.adminRepo
	if repo == nil {
		writeJSON(w, http.StatusOK, map[string]any{"payments": []any{}, "total": 0})
		return
	}

	params := url.Values{}
	params.Set("select", "id,user_id,subscription_id,amount_paise,currency,status,provider,provider_payment_id,provider_invoice_id,billing_reason,payment_method_brand,payment_method_last4,refunded_amount_paise,failure_reason,paid_at,created_at,metadata")
	params.Set("order", "created_at.desc")
	params.Set("limit", strconv.Itoa(limit))
	params.Set("offset", strconv.Itoa(offset))

	if status := strings.TrimSpace(r.URL.Query().Get("status")); status != "" {
		params.Set("status", "eq."+status)
	}

	rows, err := repo.db.SelectRead(ctx, repo.cfg.MatchingSchema, "billing_payments_runtime", params)
	if err != nil {
		writeJSON(w, http.StatusOK, map[string]any{"payments": []any{}, "total": 0, "note": "table not found"})
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"payments": rows, "total": len(rows)})
}

// ─── Revenue Analytics (FR-10) ───────────────────────────────────────────────

// adminRevenueAnalytics shares its definitions with the business revenue
// report and the reconciliation report: windowed, SQL-aggregated, live and
// sandbox separated, admin grants and promotions excluded, partial refunds
// netted, and money kept per currency.
func (s *Server) adminRevenueAnalytics(w http.ResponseWriter, r *http.Request) {
	s.billingRevenueAnalytics(w, r)
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

func orString(v any, def string) string {
	if s, ok := v.(string); ok && strings.TrimSpace(s) != "" {
		return strings.TrimSpace(s)
	}
	return def
}

func orInt(v any, def int) int {
	switch x := v.(type) {
	case float64:
		return int(x)
	case int:
		return x
	case string:
		if i, err := strconv.Atoi(x); err == nil {
			return i
		}
	}
	return def
}

func orBool(v any, def bool) bool {
	if b, ok := v.(bool); ok {
		return b
	}
	return def
}

func defaultFeatureFlags() []map[string]any {
	keys := []struct{ k, d string }{
		{"gifts_enabled", "Show/hide gift tray in chat"},
		{"voice_icebreakers_enabled", "Show/hide voice icebreaker CTA"},
		{"rooms_enabled", "Show/hide conversation rooms tab"},
		{"calls_enabled", "Show/hide video call button"},
		{"billing_enabled", "Show/hide paywall and billing"},
		{"quest_workflow_v2_enabled", "Use quest workflow v2"},
		{"circles_enabled", "Enable community circles"},
		{"daily_prompts_enabled", "Show daily engagement prompts"},
		{"match_nudges_enabled", "Enable match nudge sending"},
		{"group_coffee_polls_enabled", "Enable group coffee polls"},
		{"safety_sos_enabled", "Enable SOS delivery commands"},
		{"level_progression_enabled", "Enable level and XP progression"},
		{"intentional_dating_enabled", "Opt-in dating rhythm and private chemistry"},
		{"date_plans_enabled", "Date plans on matches shared with friends and friend groups"},
		{"graduation_enabled", "Graduation: a matched pair leaves Connect together, discovery pauses, friends celebrate"},
		{"friend_intros_enabled", "Friend vouches on profiles and friend-made intros"},
		{"copilot_enabled", "Writing copilot drafts with honest assisted-message marks"},
		{"curated_daily_set_enabled", "Curated daily candidate set with fair-exposure ranking and reasons"},
		{"photo_themes_enabled", "Photo Themes: one moderated photo per prompt"},
		{"clubs_enabled", "Book & Film Clubs: weekly picks, discussion, reviews and lists"},
	}
	out := make([]map[string]any, len(keys))
	for i, kd := range keys {
		out[i] = map[string]any{"key": kd.k, "value_bool": true, "description": kd.d, "source": "defaults"}
	}
	return out
}

func defaultCoinPackages() []map[string]any {
	return []map[string]any{
		{"id": "starter", "label": "Starter Pack", "coin_amount": 100, "price_usd": 0.99, "is_active": true, "sort_order": 1},
		{"id": "popular", "label": "Popular", "coin_amount": 500, "price_usd": 3.99, "is_active": true, "sort_order": 2},
		{"id": "value", "label": "Best Value", "coin_amount": 1200, "price_usd": 7.99, "is_active": true, "sort_order": 3},
		{"id": "premium", "label": "Premium", "coin_amount": 3000, "price_usd": 17.99, "is_active": true, "sort_order": 4},
	}
}

// ─── Webhook ledger (PEN-01) ────────────────────────────────────────────────

// adminListBillingWebhookEvents exposes the provider event ledger so an
// operator can see what the provider actually reported, whether it was
// applied, ignored, deduplicated or failed, and why.
func (s *Server) adminListBillingWebhookEvents(w http.ResponseWriter, r *http.Request) {
	if err := requireAdminUser(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	limit := 50
	if raw := strings.TrimSpace(r.URL.Query().Get("limit")); raw != "" {
		if v, err := strconv.Atoi(raw); err == nil && v > 0 && v <= 500 {
			limit = v
		}
	}
	offset := 0
	if raw := strings.TrimSpace(r.URL.Query().Get("offset")); raw != "" {
		if v, err := strconv.Atoi(raw); err == nil && v >= 0 {
			offset = v
		}
	}
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	repo := s.store.adminRepo
	if repo == nil {
		writeJSON(w, http.StatusOK, map[string]any{"events": []any{}, "total": 0})
		return
	}
	params := url.Values{}
	params.Set("select", "id,provider,event_id,event_type,event_created_at,received_at,processed_at,status,error")
	params.Set("order", "received_at.desc")
	params.Set("limit", strconv.Itoa(limit))
	params.Set("offset", strconv.Itoa(offset))
	if status := strings.TrimSpace(r.URL.Query().Get("status")); status != "" {
		params.Set("status", "eq."+status)
	}
	if eventType := strings.TrimSpace(r.URL.Query().Get("event_type")); eventType != "" {
		params.Set("event_type", "eq."+eventType)
	}
	rows, err := repo.db.SelectRead(ctx, repo.cfg.MatchingSchema, "billing_webhook_events", params)
	if err != nil {
		writeJSON(w, http.StatusOK, map[string]any{"events": []any{}, "total": 0, "note": "table not found"})
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"events": rows, "total": len(rows)})
}
