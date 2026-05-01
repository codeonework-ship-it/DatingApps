package mobile

import (
	"encoding/json"
	"errors"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/verified-dating/backend/internal/platform/config"
	"github.com/verified-dating/backend/internal/platform/supabase"
)

// ─── Admin Repository ────────────────────────────────────────────────────────

type adminRepository struct {
	cfg config.Config
	db  roseGiftRepositoryDB // reuse same interface (SelectRead/Insert/Update/Delete)
}

func newAdminRepository(cfg config.Config) *adminRepository {
	apiKey := strings.TrimSpace(cfg.SupabaseServiceRole)
	if apiKey == "" {
		apiKey = strings.TrimSpace(cfg.SupabaseAnonKey)
	}
	if strings.TrimSpace(cfg.SupabaseURL) == "" || apiKey == "" {
		return nil
	}
	client := supabase.NewClient(
		cfg.SupabaseURL,
		cfg.SupabaseAnonKey,
		cfg.SupabaseServiceRole,
		time.Duration(cfg.SupabaseHTTPTimeoutSec)*time.Second,
	)
	return &adminRepository{cfg: cfg, db: client}
}

// ─── Helper: require X-Admin-User ────────────────────────────────────────────

func requireAdminUser(r *http.Request) error {
	h := strings.TrimSpace(r.Header.Get("X-Admin-User"))
	if h == "" {
		return errors.New("missing X-Admin-User header")
	}
	return nil
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
	params.Set("select", "id,name,phone_number,gender,bio,height_cm,education,profession,city,state,country,profile_completion,is_verified,last_login_at,created_at,suspended_at,suspended_reason,is_banned")
	params.Set("order", "created_at.desc")
	params.Set("limit", strconv.Itoa(limit))
	params.Set("offset", strconv.Itoa(offset))

	if q := strings.TrimSpace(r.URL.Query().Get("q")); q != "" {
		params.Set("or", "(name.ilike.*"+q+"*,phone_number.ilike.*"+q+"*)")
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
	writeJSON(w, http.StatusOK, map[string]any{
		"users": rows,
		"total": len(rows),
	})
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
	params.Set("select", "id,name,phone_number,gender,bio,height_cm,education,profession,income_range,drinking,smoking,religion,mother_tongue,personality_type,city,state,country,profile_completion,is_verified,is_active,last_login_at,created_at,updated_at,suspended_at,suspended_reason,suspended_until,is_banned")
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
	phone, _ := body["phone_number"].(string)
	if strings.TrimSpace(name) == "" || strings.TrimSpace(phone) == "" {
		writeError(w, http.StatusBadRequest, errors.New("name and phone_number are required"))
		return
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	repo := s.store.adminRepo
	if repo == nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("admin repository unavailable"))
		return
	}

	dob := orString(body["date_of_birth"], "2000-01-01")
	payload := map[string]any{
		"name":           strings.TrimSpace(name),
		"phone_number":   strings.TrimSpace(phone),
		"date_of_birth":  dob,
		"gender":         orString(body["gender"], "other"),
		"bio":            orString(body["bio"], ""),
		"terms_accepted": true,
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

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	repo := s.store.adminRepo
	if repo == nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("admin repository unavailable"))
		return
	}

	filters := url.Values{}
	filters.Set("id", "eq."+userID)
	_, err := repo.db.Delete(ctx, repo.cfg.UserSchema, repo.cfg.UsersTable, filters)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"user_id": userID, "deleted": true})
}

// ─── Feature Flags ──────────────────────────────────────────────────────────

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
	wallet := s.store.getWalletCoins(userID)
	writeJSON(w, http.StatusOK, map[string]any{"wallet": wallet})
}

// ─── Billing Stats / KPI ─────────────────────────────────────────────────────

func (s *Server) adminBillingStats(w http.ResponseWriter, r *http.Request) {
	if err := requireAdminUser(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	repo := s.store.adminRepo
	if repo == nil {
		writeJSON(w, http.StatusOK, map[string]any{
			"total_coins_purchased": 0, "total_revenue_minor": 0,
			"unique_buyers": 0, "transaction_count": 0, "source": "unavailable",
		})
		return
	}

	// Total coins purchased + revenue + unique buyers via wallet_coin_purchases
	txParams := url.Values{}
	txParams.Set("select", "coins,amount_minor,user_id")
	allTx, err := repo.db.SelectRead(ctx, repo.cfg.MatchingSchema, "wallet_coin_purchases", txParams)

	totalCoins := 0
	totalRevenue := 0
	uniqueBuyers := map[string]bool{}
	if err == nil {
		for _, row := range allTx {
			if c, ok := toInt(row["coins"]); ok {
				totalCoins += c
			}
			if a, ok := toInt(row["amount_minor"]); ok {
				totalRevenue += a
			}
			if uid, ok := row["user_id"].(string); ok && uid != "" {
				uniqueBuyers[uid] = true
			}
		}
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"total_coins_purchased": totalCoins,
		"total_revenue_minor":   totalRevenue,
		"unique_buyers":         len(uniqueBuyers),
		"transaction_count":     len(allTx),
		"source":                "db",
	})
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
	params.Set("select", "id,user_id,plan_code,status,billing_cycle,start_date,end_date,next_billing_date,auto_renew,provider_subscription_id,created_at,updated_at")
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
	params.Set("select", "id,user_id,subscription_id,amount_paise,currency,status,provider_payment_id,provider_order_id,paid_at,created_at,metadata")
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

func (s *Server) adminRevenueAnalytics(w http.ResponseWriter, r *http.Request) {
	if err := requireAdminUser(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	repo := s.store.adminRepo
	if repo == nil {
		writeJSON(w, http.StatusOK, map[string]any{
			"coin_purchases": map[string]any{},
			"subscriptions":  map[string]any{},
			"payments":       map[string]any{},
			"source":         "unavailable",
		})
		return
	}

	// --- Coin purchases aggregates ---
	coinParams := url.Values{}
	coinParams.Set("select", "coins,amount_minor,user_id,source,created_at")
	allCoins, _ := repo.db.SelectRead(ctx, repo.cfg.MatchingSchema, "wallet_coin_purchases", coinParams)

	totalCoins, totalMinor, uniqueBuyers := 0, 0, map[string]bool{}
	sourceCounts := map[string]int{}
	for _, row := range allCoins {
		if c, ok := toInt(row["coins"]); ok {
			totalCoins += c
		}
		if a, ok := toInt(row["amount_minor"]); ok {
			totalMinor += a
		}
		if uid, ok := row["user_id"].(string); ok {
			uniqueBuyers[uid] = true
		}
		if src, ok := row["source"].(string); ok {
			sourceCounts[src]++
		}
	}

	coinStats := map[string]any{
		"total_coins":   totalCoins,
		"total_minor":   totalMinor,
		"total_count":   len(allCoins),
		"unique_buyers": len(uniqueBuyers),
		"by_source":     sourceCounts,
	}

	// --- Subscription aggregates ---
	subParams := url.Values{}
	subParams.Set("select", "status,plan_code,billing_cycle")
	allSubs, _ := repo.db.SelectRead(ctx, repo.cfg.MatchingSchema, "billing_subscriptions_runtime", subParams)
	subStatusCounts := map[string]int{}
	subPlanCounts := map[string]int{}
	for _, row := range allSubs {
		if s, ok := row["status"].(string); ok {
			subStatusCounts[s]++
		}
		if p, ok := row["plan_code"].(string); ok {
			subPlanCounts[p]++
		}
	}
	subStats := map[string]any{
		"total":     len(allSubs),
		"by_status": subStatusCounts,
		"by_plan":   subPlanCounts,
	}

	// --- Payment aggregates ---
	payParams := url.Values{}
	payParams.Set("select", "amount_paise,currency,status")
	allPay, _ := repo.db.SelectRead(ctx, repo.cfg.MatchingSchema, "billing_payments_runtime", payParams)
	payStatusCounts := map[string]int{}
	totalPaisePaid := 0
	for _, row := range allPay {
		if s, ok := row["status"].(string); ok {
			payStatusCounts[s]++
			if s == "success" {
				if a, ok := toInt(row["amount_paise"]); ok {
					totalPaisePaid += a
				}
			}
		}
	}
	payStats := map[string]any{
		"total":            len(allPay),
		"by_status":        payStatusCounts,
		"total_paid_paise": totalPaisePaid,
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"coin_purchases": coinStats,
		"subscriptions":  subStats,
		"payments":       payStats,
		"source":         "db",
	})
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
