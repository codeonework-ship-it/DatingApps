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

type signupBootstrapInput struct {
	UserID      string
	PhoneNumber string
	Name        string
	DateOfBirth string
	Gender      string
}

var errSignupPhoneAlreadyExists = errors.New("mobile number already has an account")

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

func (r *profileRepository) completeProfile(ctx context.Context, draft profileDraft) error {
	trimmedUserID := strings.TrimSpace(draft.UserID)
	if trimmedUserID == "" {
		return errors.New("user_id is required")
	}
	usersTable := strings.TrimSpace(r.cfg.UsersTable)
	if usersTable == "" {
		usersTable = "users"
	}
	now := time.Now().UTC().Format(time.RFC3339)

	filters := url.Values{}
	filters.Set("id", "eq."+trimmedUserID)
	if _, err := r.db.Update(ctx, r.cfg.UserSchema, usersTable, map[string]any{
		"name":                strings.TrimSpace(draft.Name),
		"date_of_birth":       strings.TrimSpace(draft.DateOfBirth),
		"gender":              storedGenderValue(draft.Gender),
		"bio":                 nullableStringValue(draft.Bio),
		"height_cm":           draft.HeightCm,
		"education":           draft.Education,
		"profession":          draft.Profession,
		"income_range":        draft.IncomeRange,
		"drinking":            nullableStringValue(draft.Drinking),
		"smoking":             nullableStringValue(draft.Smoking),
		"religion":            draft.Religion,
		"mother_tongue":       draft.MotherTongue,
		"relationship_status": draft.RelationshipStatus,
		"personality_type":    draft.PersonalityType,
		"country":             draft.Country,
		"state":               draft.RegionState,
		"city":                draft.City,
		"profile_completion":  100,
		"is_active":           true,
		"updated_at":          now,
	}, filters); err != nil {
		return err
	}

	if _, err := r.db.Upsert(ctx, r.cfg.UserSchema, "preferences", []map[string]any{{
		"user_id":           trimmedUserID,
		"seeking_genders":   storedGenderListValue(draft.SeekingGenders),
		"min_age_years":     draft.MinAgeYears,
		"max_age_years":     draft.MaxAgeYears,
		"max_distance_km":   draft.MaxDistanceKm,
		"education_filter":  draft.EducationFilter,
		"serious_only":      draft.SeriousOnly,
		"verified_only":     draft.VerifiedOnly,
		"intent_tags":       draft.IntentTags,
		"language_tags":     draft.LanguageTags,
		"deal_breaker_tags": draft.DealBreakerTags,
		"updated_at":        now,
	}}, "user_id"); err != nil {
		return err
	}

	photoFilters := url.Values{}
	photoFilters.Set("user_id", "eq."+trimmedUserID)
	if _, err := r.db.Delete(ctx, r.cfg.UserSchema, "photos", photoFilters); err != nil {
		return err
	}
	photos := make([]map[string]any, 0, len(draft.Photos))
	for i, photo := range draft.Photos {
		photoURL := strings.TrimSpace(photo.PhotoURL)
		if photoURL == "" {
			continue
		}
		photos = append(photos, map[string]any{
			"user_id":      trimmedUserID,
			"photo_url":    photoURL,
			"storage_path": nullableStringValue(photo.StoragePath),
			"ordering":     i,
			"uploaded_at":  now,
		})
	}
	if len(photos) > 0 {
		if _, err := r.db.Insert(ctx, r.cfg.UserSchema, "photos", photos); err != nil {
			return err
		}
	}

	if err := r.upsertDraft(ctx, draft); err != nil {
		return err
	}
	draftFilters := url.Values{}
	draftFilters.Set("user_id", "eq."+trimmedUserID)
	if _, err := r.db.Update(ctx, r.cfg.UserSchema, "profile_drafts", map[string]any{
		"completed_at":      now,
		"completion_source": "mobile_setup_wizard",
		"updated_at":        now,
	}, draftFilters); err != nil {
		return err
	}

	_, _ = r.db.Upsert(ctx, r.cfg.UserSchema, "profile_setup_completions", []map[string]any{{
		"user_id":                trimmedUserID,
		"completed_at":           now,
		"completion_source":      "mobile_setup_wizard",
		"photos_count":           len(draft.Photos),
		"bio_length":             len([]rune(strings.TrimSpace(draft.Bio))),
		"has_height":             draft.HeightCm != nil,
		"has_education":          draft.Education != nil && strings.TrimSpace(*draft.Education) != "",
		"has_profession":         draft.Profession != nil && strings.TrimSpace(*draft.Profession) != "",
		"has_lifestyle":          strings.TrimSpace(draft.Drinking) != "" || strings.TrimSpace(draft.Smoking) != "" || draft.Religion != nil,
		"profile_completion_pct": 100,
		"idempotency_key":        "mobile_setup_wizard:" + trimmedUserID,
		"created_at":             now,
	}}, "idempotency_key")

	return nil
}

func nullableStringValue(value string) any {
	trimmed := strings.TrimSpace(value)
	if trimmed == "" {
		return nil
	}
	return trimmed
}

func storedGenderValue(value string) string {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case "m", "male", "man":
		return "male"
	case "f", "female", "woman":
		return "female"
	case "other", "non-binary", "nonbinary":
		return "other"
	default:
		return strings.ToLower(strings.TrimSpace(value))
	}
}

func storedGenderListValue(values []string) []string {
	normalized := make([]string, 0, len(values))
	seen := map[string]struct{}{}
	for _, value := range values {
		gender := storedGenderValue(value)
		if gender == "" {
			continue
		}
		if _, ok := seen[gender]; ok {
			continue
		}
		seen[gender] = struct{}{}
		normalized = append(normalized, gender)
	}
	return normalized
}

func (r *profileRepository) bootstrapSignup(ctx context.Context, input signupBootstrapInput) (profileDraft, bool, error) {
	trimmedUserID := strings.TrimSpace(input.UserID)
	if trimmedUserID == "" {
		return profileDraft{}, false, errors.New("user_id is required")
	}
	usersTable := strings.TrimSpace(r.cfg.UsersTable)
	if usersTable == "" {
		usersTable = "users"
	}

	phoneParams := url.Values{}
	phoneParams.Set("phone_number", "eq."+strings.TrimSpace(input.PhoneNumber))
	phoneParams.Set("limit", "1")
	phoneParams.Set("select", "id,phone_number")
	phoneRows, err := r.db.SelectRead(ctx, r.cfg.UserSchema, usersTable, phoneParams)
	if err != nil {
		return profileDraft{}, false, err
	}
	if len(phoneRows) > 0 && strings.TrimSpace(toString(phoneRows[0]["id"])) != trimmedUserID {
		return profileDraft{}, false, errSignupPhoneAlreadyExists
	}

	params := url.Values{}
	params.Set("id", "eq."+trimmedUserID)
	params.Set("limit", "1")
	params.Set("select", "id,phone_number,name,date_of_birth,gender,profile_completion")
	rows, err := r.db.SelectRead(ctx, r.cfg.UserSchema, usersTable, params)
	if err != nil {
		return profileDraft{}, false, err
	}

	now := time.Now().UTC().Format(time.RFC3339)
	created := len(rows) == 0
	if created {
		_, err = r.db.Insert(ctx, r.cfg.UserSchema, usersTable, []map[string]any{{
			"id":                 trimmedUserID,
			"phone_number":       strings.TrimSpace(input.PhoneNumber),
			"name":               strings.TrimSpace(input.Name),
			"date_of_birth":      strings.TrimSpace(input.DateOfBirth),
			"gender":             storedGenderValue(input.Gender),
			"profile_completion": 25,
			"is_active":          true,
			"created_at":         now,
			"updated_at":         now,
		}})
		if err != nil {
			return profileDraft{}, false, err
		}
	} else {
		row := rows[0]
		patch := map[string]any{"updated_at": now}
		if strings.TrimSpace(toString(row["phone_number"])) == "" {
			patch["phone_number"] = strings.TrimSpace(input.PhoneNumber)
		}
		if strings.TrimSpace(toString(row["name"])) == "" {
			patch["name"] = strings.TrimSpace(input.Name)
		}
		if strings.TrimSpace(toString(row["date_of_birth"])) == "" {
			patch["date_of_birth"] = strings.TrimSpace(input.DateOfBirth)
		}
		if strings.TrimSpace(toString(row["gender"])) == "" {
			patch["gender"] = storedGenderValue(input.Gender)
		}
		if _, ok := toInt(row["profile_completion"]); !ok {
			patch["profile_completion"] = 25
		}
		if len(patch) > 1 {
			filters := url.Values{}
			filters.Set("id", "eq."+trimmedUserID)
			if _, err := r.db.Update(ctx, r.cfg.UserSchema, usersTable, patch, filters); err != nil {
				return profileDraft{}, false, err
			}
		}
	}

	draft, err := r.getDraft(ctx, trimmedUserID)
	if err != nil {
		return profileDraft{}, created, err
	}
	draft = mergeSignupIntoDraft(draft, input)
	if err := r.upsertDraft(ctx, draft); err != nil {
		return profileDraft{}, created, err
	}
	return copyDraft(draft), created, nil
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
