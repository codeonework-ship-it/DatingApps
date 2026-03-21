package mobile

import (
	"context"
	"encoding/json"
	"errors"
	"net/url"
	"sort"
	"strings"
	"time"

	"github.com/verified-dating/backend/internal/platform/config"
	"github.com/verified-dating/backend/internal/platform/supabase"
)

type profileRepository struct {
	cfg config.Config
	db  *supabase.Client
}

func newProfileRepository(cfg config.Config) *profileRepository {
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
	client.SetReadBaseURL(cfg.SupabaseReadReplicaURL)
	return &profileRepository{cfg: cfg, db: client}
}

func isProfileRepoPersistenceUnavailable(err error) bool {
	if err == nil {
		return false
	}
	msg := strings.ToLower(err.Error())
	return strings.Contains(msg, "pgrst106") ||
		strings.Contains(msg, "pgrst205") ||
		strings.Contains(msg, "invalid schema") ||
		strings.Contains(msg, "could not find the table")
}

func (r *profileRepository) getDraft(ctx context.Context, userID string) (profileDraft, error) {
	trimmedUserID := strings.TrimSpace(userID)
	if trimmedUserID == "" {
		return profileDraft{}, errors.New("user_id is required")
	}
	params := url.Values{}
	params.Set("user_id", "eq."+trimmedUserID)
	params.Set("limit", "1")
	params.Set("select", "draft_payload")
	rows, err := r.db.SelectRead(ctx, r.cfg.UserSchema, "profile_drafts", params)
	if err != nil {
		return profileDraft{}, err
	}
	if len(rows) == 0 {
		return defaultDraft(trimmedUserID), nil
	}
	payloadMap, _ := rows[0]["draft_payload"].(map[string]any)
	if payloadMap == nil {
		return defaultDraft(trimmedUserID), nil
	}
	data, marshalErr := json.Marshal(payloadMap)
	if marshalErr != nil {
		return defaultDraft(trimmedUserID), nil
	}
	draft := defaultDraft(trimmedUserID)
	if unmarshalErr := json.Unmarshal(data, &draft); unmarshalErr != nil {
		return defaultDraft(trimmedUserID), nil
	}
	if strings.TrimSpace(draft.UserID) == "" {
		draft.UserID = trimmedUserID
	}
	return draft, nil
}

func (r *profileRepository) upsertDraft(ctx context.Context, draft profileDraft) error {
	trimmedUserID := strings.TrimSpace(draft.UserID)
	if trimmedUserID == "" {
		return errors.New("user_id is required")
	}
	data, err := json.Marshal(draft)
	if err != nil {
		return err
	}
	payload := map[string]any{}
	if err := json.Unmarshal(data, &payload); err != nil {
		return err
	}
	_, err = r.db.Upsert(ctx, r.cfg.UserSchema, "profile_drafts", []map[string]any{{
		"user_id":       trimmedUserID,
		"draft_payload": payload,
		"updated_at":    time.Now().UTC().Format(time.RFC3339),
	}}, "user_id")
	return err
}

func (r *profileRepository) getSettings(ctx context.Context, userID string) (userSettings, error) {
	trimmedUserID := strings.TrimSpace(userID)
	if trimmedUserID == "" {
		return userSettings{}, errors.New("user_id is required")
	}
	params := url.Values{}
	params.Set("user_id", "eq."+trimmedUserID)
	params.Set("limit", "1")
	params.Set("select", "user_id,show_age,show_exact_distance,show_online_status,notify_new_match,notify_new_message,notify_likes,theme,updated_at")
	rows, err := r.db.SelectRead(ctx, r.cfg.UserSchema, "user_settings", params)
	if err != nil {
		return userSettings{}, err
	}
	if len(rows) == 0 {
		return defaultSettings(trimmedUserID), nil
	}
	row := rows[0]
	return userSettings{
		UserID:            trimmedUserID,
		ShowAge:           toBoolValue(row["show_age"]),
		ShowExactDistance: toBoolValue(row["show_exact_distance"]),
		ShowOnlineStatus:  toBoolValue(row["show_online_status"]),
		NotifyNewMatch:    toBoolValue(row["notify_new_match"]),
		NotifyNewMessage:  toBoolValue(row["notify_new_message"]),
		NotifyLikes:       toBoolValue(row["notify_likes"]),
		Theme:             strings.TrimSpace(toString(row["theme"])),
		UpdatedAt:         normalizeTimestampString(row["updated_at"]),
	}, nil
}

func (r *profileRepository) upsertSettings(ctx context.Context, settings userSettings) error {
	trimmedUserID := strings.TrimSpace(settings.UserID)
	if trimmedUserID == "" {
		return errors.New("user_id is required")
	}
	_, err := r.db.Upsert(ctx, r.cfg.UserSchema, "user_settings", []map[string]any{{
		"user_id":             trimmedUserID,
		"show_age":            settings.ShowAge,
		"show_exact_distance": settings.ShowExactDistance,
		"show_online_status":  settings.ShowOnlineStatus,
		"notify_new_match":    settings.NotifyNewMatch,
		"notify_new_message":  settings.NotifyNewMessage,
		"notify_likes":        settings.NotifyLikes,
		"theme":               strings.TrimSpace(settings.Theme),
		"updated_at":          time.Now().UTC().Format(time.RFC3339),
	}}, "user_id")
	return err
}

func (r *profileRepository) listEmergencyContacts(ctx context.Context, userID string) ([]emergencyContact, error) {
	trimmedUserID := strings.TrimSpace(userID)
	if trimmedUserID == "" {
		return nil, errors.New("user_id is required")
	}
	params := url.Values{}
	params.Set("user_id", "eq."+trimmedUserID)
	params.Set("order", "ordering.asc")
	params.Set("select", "id,user_id,name,phone_number,ordering,added_at")
	rows, err := r.db.SelectRead(ctx, r.cfg.UserSchema, "emergency_contacts", params)
	if err != nil {
		return nil, err
	}
	items := make([]emergencyContact, 0, len(rows))
	for _, row := range rows {
		ordering, _ := toInt(row["ordering"])
		items = append(items, emergencyContact{
			ID:          strings.TrimSpace(toString(row["id"])),
			UserID:      trimmedUserID,
			Name:        strings.TrimSpace(toString(row["name"])),
			PhoneNumber: strings.TrimSpace(toString(row["phone_number"])),
			Ordering:    ordering,
			AddedAt:     normalizeTimestampString(row["added_at"]),
		})
	}
	return items, nil
}

func (r *profileRepository) addEmergencyContact(ctx context.Context, userID, name, phoneNumber string, ordering int) (emergencyContact, error) {
	trimmedUserID := strings.TrimSpace(userID)
	if trimmedUserID == "" {
		return emergencyContact{}, errors.New("user_id is required")
	}
	rows, err := r.db.Insert(ctx, r.cfg.UserSchema, "emergency_contacts", []map[string]any{{
		"user_id":      trimmedUserID,
		"name":         strings.TrimSpace(name),
		"phone_number": strings.TrimSpace(phoneNumber),
		"ordering":     ordering,
		"added_at":     time.Now().UTC().Format(time.RFC3339),
		"updated_at":   time.Now().UTC().Format(time.RFC3339),
	}})
	if err != nil {
		return emergencyContact{}, err
	}
	if len(rows) == 0 {
		return emergencyContact{}, errors.New("emergency contact persistence returned empty result")
	}
	order, _ := toInt(rows[0]["ordering"])
	return emergencyContact{
		ID:          strings.TrimSpace(toString(rows[0]["id"])),
		UserID:      trimmedUserID,
		Name:        strings.TrimSpace(toString(rows[0]["name"])),
		PhoneNumber: strings.TrimSpace(toString(rows[0]["phone_number"])),
		Ordering:    order,
		AddedAt:     normalizeTimestampString(rows[0]["added_at"]),
	}, nil
}

func (r *profileRepository) updateEmergencyContact(ctx context.Context, userID, contactID, name, phoneNumber string) error {
	filters := url.Values{}
	filters.Set("id", "eq."+strings.TrimSpace(contactID))
	filters.Set("user_id", "eq."+strings.TrimSpace(userID))
	_, err := r.db.Update(ctx, r.cfg.UserSchema, "emergency_contacts", map[string]any{
		"name":         strings.TrimSpace(name),
		"phone_number": strings.TrimSpace(phoneNumber),
		"updated_at":   time.Now().UTC().Format(time.RFC3339),
	}, filters)
	return err
}

func (r *profileRepository) deleteEmergencyContact(ctx context.Context, userID, contactID string) error {
	filters := url.Values{}
	filters.Set("id", "eq."+strings.TrimSpace(contactID))
	filters.Set("user_id", "eq."+strings.TrimSpace(userID))
	_, err := r.db.Delete(ctx, r.cfg.UserSchema, "emergency_contacts", filters)
	return err
}

func (r *profileRepository) listBlockedUsers(ctx context.Context, userID string) ([]blockedUser, error) {
	trimmedUserID := strings.TrimSpace(userID)
	if trimmedUserID == "" {
		return nil, errors.New("user_id is required")
	}
	params := url.Values{}
	params.Set("user_id", "eq."+trimmedUserID)
	params.Set("order", "blocked_at.desc")
	params.Set("select", "blocked_user_id")
	rows, err := r.db.SelectRead(ctx, r.cfg.UserSchema, "blocked_users", params)
	if err != nil {
		return nil, err
	}
	ids := make([]string, 0, len(rows))
	for _, row := range rows {
		id := strings.TrimSpace(toString(row["blocked_user_id"]))
		if id != "" {
			ids = append(ids, id)
		}
	}
	nameByID, _ := r.loadBlockedUserNames(ctx, ids)
	out := make([]blockedUser, 0, len(ids))
	for _, id := range ids {
		out = append(out, blockedUser{ID: id, Name: nameByID[id]})
	}
	return out, nil
}

func (r *profileRepository) blockUser(ctx context.Context, userID, blockedUserID string, reason string) error {
	_, err := r.db.Upsert(ctx, r.cfg.UserSchema, "blocked_users", []map[string]any{{
		"user_id":         strings.TrimSpace(userID),
		"blocked_user_id": strings.TrimSpace(blockedUserID),
		"reason":          strings.TrimSpace(reason),
		"created_at":      time.Now().UTC().Format(time.RFC3339),
	}}, "user_id,blocked_user_id")
	return err
}

func (r *profileRepository) unblockUser(ctx context.Context, userID, blockedUserID string) error {
	filters := url.Values{}
	filters.Set("user_id", "eq."+strings.TrimSpace(userID))
	filters.Set("blocked_user_id", "eq."+strings.TrimSpace(blockedUserID))
	_, err := r.db.Delete(ctx, r.cfg.UserSchema, "blocked_users", filters)
	return err
}

func (r *profileRepository) loadBlockedUserNames(ctx context.Context, ids []string) (map[string]string, error) {
	unique := make([]string, 0, len(ids))
	seen := map[string]struct{}{}
	for _, id := range ids {
		trimmed := strings.TrimSpace(id)
		if trimmed == "" {
			continue
		}
		if _, ok := seen[trimmed]; ok {
			continue
		}
		seen[trimmed] = struct{}{}
		unique = append(unique, trimmed)
	}
	if len(unique) == 0 {
		return map[string]string{}, nil
	}
	params := url.Values{}
	params.Set("id", "in.("+strings.Join(unique, ",")+")")
	params.Set("select", "id,name")
	rows, err := r.db.SelectRead(ctx, r.cfg.UserSchema, r.cfg.UsersTable, params)
	if err != nil {
		return nil, err
	}
	nameByID := map[string]string{}
	for _, row := range rows {
		id := strings.TrimSpace(toString(row["id"]))
		if id == "" {
			continue
		}
		nameByID[id] = strings.TrimSpace(toString(row["name"]))
	}
	for _, id := range unique {
		if strings.TrimSpace(nameByID[id]) == "" {
			nameByID[id] = "Blocked User"
		}
	}
	return nameByID, nil
}

func (r *profileRepository) reorderEmergencyContacts(ctx context.Context, userID string) error {
	items, err := r.listEmergencyContacts(ctx, userID)
	if err != nil {
		return err
	}
	sort.Slice(items, func(i, j int) bool { return items[i].Ordering < items[j].Ordering })
	for idx, item := range items {
		filters := url.Values{}
		filters.Set("id", "eq."+item.ID)
		filters.Set("user_id", "eq."+strings.TrimSpace(userID))
		_, updateErr := r.db.Update(ctx, r.cfg.UserSchema, "emergency_contacts", map[string]any{
			"ordering":   idx + 1,
			"updated_at": time.Now().UTC().Format(time.RFC3339),
		}, filters)
		if updateErr != nil {
			return updateErr
		}
	}
	return nil
}
