package mobile

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"net/url"
	"sort"
	"strings"
	"time"

	"github.com/verified-dating/backend/internal/platform/config"
	"github.com/verified-dating/backend/internal/platform/postgresdata"
)

type profileRepository struct {
	cfg config.Config
	db  repositoryDB
	pg  *sql.DB
}

type signupBootstrapInput struct {
	UserID      string
	Username    string
	PhoneNumber string
	Name        string
	DateOfBirth string
	Gender      string
}

var errSignupUsernameAlreadyExists = errors.New("username already has an account")

func newProfileRepository(cfg config.Config, supplied ...repositoryDB) *profileRepository {
	direct := repositoryDBFor(cfg, supplied)

	// Open the SQL pool whenever a database URL is configured, not only in
	// local mode. Sessions, roles and account status all live in
	// user_management.* and are read over this handle by
	// principalForAccessToken. Leaving pg nil outside local mode is what forced
	// securityMiddleware to be skipped there, which disabled authentication,
	// the admin role check and the X-Admin-User strip on exactly the
	// deployments that need them most. cfg.DatabaseURL is populated in both
	// modes (LOCAL_DATABASE_URL locally, DATABASE_URL/PROD_DATABASE_URL or a
	// URL built from SUPABASE_DB_* otherwise).
	if strings.TrimSpace(cfg.DatabaseURL) != "" {
		db, err := postgresdata.OpenSQL(cfg.DatabaseURL, postgresOptions(cfg, primaryPoolMaxConns(cfg), 4))
		if err == nil {
			return &profileRepository{cfg: cfg, db: direct, pg: db}
		}
		if cfg.UseLocalDB {
			// Local mode has no other persistence to fall back to.
			return nil
		}
	}
	if direct == nil {
		return nil
	}
	return &profileRepository{cfg: cfg, db: direct}
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
	if r.pg != nil {
		return r.getDraftPostgres(ctx, userID)
	}
	trimmedUserID := strings.TrimSpace(userID)
	if trimmedUserID == "" {
		return profileDraft{}, errors.New("user_id is required")
	}
	durableDraft, durableFound, durableErr := r.getDurableProfileDraft(ctx, trimmedUserID)
	if durableErr != nil {
		return profileDraft{}, durableErr
	}
	params := url.Values{}
	params.Set("user_id", "eq."+trimmedUserID)
	params.Set("limit", "1")
	params.Set("select", "draft_payload,completed_at")
	rows, err := r.db.SelectRead(ctx, r.cfg.UserSchema, "profile_drafts", params)
	if err != nil {
		return profileDraft{}, err
	}
	if len(rows) == 0 {
		if durableFound {
			return copyDraft(durableDraft), nil
		}
		return defaultDraft(trimmedUserID), nil
	}
	payloadMap, _ := rows[0]["draft_payload"].(map[string]any)
	if payloadMap == nil {
		if durableFound {
			return copyDraft(durableDraft), nil
		}
		return defaultDraft(trimmedUserID), nil
	}
	data, marshalErr := json.Marshal(payloadMap)
	if marshalErr != nil {
		if durableFound {
			return copyDraft(durableDraft), nil
		}
		return defaultDraft(trimmedUserID), nil
	}
	draft := defaultDraft(trimmedUserID)
	if unmarshalErr := json.Unmarshal(data, &draft); unmarshalErr != nil {
		if durableFound {
			return copyDraft(durableDraft), nil
		}
		return defaultDraft(trimmedUserID), nil
	}
	if strings.TrimSpace(draft.UserID) == "" {
		draft.UserID = trimmedUserID
	}
	if durableFound {
		draft = mergeProfileDraftWithDurable(draft, durableDraft)
	}
	return draft, nil
}

func (r *profileRepository) getDurableProfileDraft(ctx context.Context, userID string) (profileDraft, bool, error) {
	usersTable := strings.TrimSpace(r.cfg.UsersTable)
	if usersTable == "" {
		usersTable = "users"
	}
	params := url.Values{}
	params.Set("id", "eq."+userID)
	params.Set("limit", "1")
	userRows, err := r.db.SelectRead(ctx, r.cfg.UserSchema, usersTable, params)
	if err != nil {
		return profileDraft{}, false, err
	}
	if len(userRows) == 0 {
		return profileDraft{}, false, nil
	}

	draft := defaultDraft(userID)
	userRow := userRows[0]
	draft.Username = strings.TrimSpace(toString(userRow["username"]))
	draft.PhoneNumber = strings.TrimSpace(toString(userRow["phone_number"]))
	draft.Name = strings.TrimSpace(toString(userRow["name"]))
	draft.DateOfBirth = strings.TrimSpace(toString(userRow["date_of_birth"]))
	draft.Gender = strings.TrimSpace(toString(userRow["gender"]))
	draft.Bio = strings.TrimSpace(toString(userRow["bio"]))
	if value, ok := toInt(userRow["height_cm"]); ok {
		draft.HeightCm = &value
	}
	if value, ok := toOptionalString(userRow["education"]); ok {
		draft.Education = value
	}
	if value, ok := toOptionalString(userRow["profession"]); ok {
		draft.Profession = value
	}
	if value, ok := toOptionalString(userRow["income_range"]); ok {
		draft.IncomeRange = value
	}
	if value, ok := toOptionalString(userRow["country"]); ok {
		draft.Country = value
	}
	if value, ok := toOptionalString(userRow["state"]); ok {
		draft.RegionState = value
	}
	if value, ok := toOptionalString(userRow["city"]); ok {
		draft.City = value
	}
	if value, ok := toOptionalString(userRow["drinking"]); ok && value != nil {
		draft.Drinking = *value
	}
	if value, ok := toOptionalString(userRow["smoking"]); ok && value != nil {
		draft.Smoking = *value
	}
	if value, ok := toOptionalString(userRow["religion"]); ok {
		draft.Religion = value
	}
	if value, ok := toOptionalString(userRow["mother_tongue"]); ok {
		draft.MotherTongue = value
	}
	if value, ok := toOptionalString(userRow["relationship_status"]); ok {
		draft.RelationshipStatus = value
	}
	if value, ok := toOptionalString(userRow["personality_type"]); ok {
		draft.PersonalityType = value
	}
	if value, ok := toInt(userRow["profile_completion"]); ok {
		draft.ProfileCompletion = value
	}

	prefParams := url.Values{}
	prefParams.Set("user_id", "eq."+userID)
	prefParams.Set("limit", "1")
	if prefRows, prefErr := r.db.SelectRead(ctx, r.cfg.UserSchema, "preferences", prefParams); prefErr == nil && len(prefRows) > 0 {
		prefRow := prefRows[0]
		if value, ok := toStringSlice(prefRow["seeking_genders"]); ok && len(value) > 0 {
			draft.SeekingGenders = value
		}
		if value, ok := toInt(prefRow["min_age_years"]); ok {
			draft.MinAgeYears = value
		}
		if value, ok := toInt(prefRow["max_age_years"]); ok {
			draft.MaxAgeYears = value
		}
		if value, ok := toInt(prefRow["max_distance_km"]); ok {
			draft.MaxDistanceKm = value
		}
		if value, ok := toStringSlice(prefRow["education_filter"]); ok {
			draft.EducationFilter = value
		}
		if value, ok := prefRow["serious_only"].(bool); ok {
			draft.SeriousOnly = value
		}
		if value, ok := prefRow["verified_only"].(bool); ok {
			draft.VerifiedOnly = value
		}
		if value, ok := toStringSlice(prefRow["intent_tags"]); ok {
			draft.IntentTags = value
		}
		if value, ok := toStringSlice(prefRow["language_tags"]); ok {
			draft.LanguageTags = value
		}
		if value, ok := toStringSlice(prefRow["deal_breaker_tags"]); ok {
			draft.DealBreakerTags = value
		}
	}

	photoParams := url.Values{}
	photoParams.Set("user_id", "eq."+userID)
	photoParams.Set("order", "ordering.asc")
	if photoRows, photoErr := r.db.SelectRead(ctx, r.cfg.UserSchema, "photos", photoParams); photoErr == nil {
		photos := make([]profilePhoto, 0, len(photoRows))
		for i, row := range photoRows {
			photoURL := strings.TrimSpace(toString(row["photo_url"]))
			if photoURL == "" {
				continue
			}
			ordering, ok := toInt(row["ordering"])
			if !ok {
				ordering = i
			}
			photos = append(photos, profilePhoto{
				ID:          strings.TrimSpace(toString(row["id"])),
				PhotoURL:    photoURL,
				Ordering:    ordering,
				StoragePath: strings.TrimSpace(toString(row["storage_path"])),
			})
		}
		if len(photos) > 0 {
			sort.SliceStable(photos, func(i, j int) bool { return photos[i].Ordering < photos[j].Ordering })
			draft.Photos = photos
		}
	}

	return draft, true, nil
}

func mergeProfileDraftWithDurable(draft, durable profileDraft) profileDraft {
	if strings.TrimSpace(durable.Username) != "" {
		draft.Username = durable.Username
	}
	if strings.TrimSpace(durable.PhoneNumber) != "" {
		draft.PhoneNumber = durable.PhoneNumber
	}
	if strings.TrimSpace(durable.Name) != "" {
		draft.Name = durable.Name
	}
	if strings.TrimSpace(durable.DateOfBirth) != "" {
		draft.DateOfBirth = durable.DateOfBirth
	}
	if strings.TrimSpace(durable.Gender) != "" {
		draft.Gender = durable.Gender
	}
	if len(durable.Photos) > 0 {
		draft.Photos = append([]profilePhoto{}, durable.Photos...)
	}
	if strings.TrimSpace(durable.Bio) != "" {
		draft.Bio = durable.Bio
	}
	if durable.HeightCm != nil {
		draft.HeightCm = durable.HeightCm
	}
	if durable.Education != nil {
		draft.Education = durable.Education
	}
	if durable.Profession != nil {
		draft.Profession = durable.Profession
	}
	if durable.IncomeRange != nil {
		draft.IncomeRange = durable.IncomeRange
	}
	if len(durable.SeekingGenders) > 0 {
		draft.SeekingGenders = append([]string{}, durable.SeekingGenders...)
	}
	if durable.MinAgeYears > 0 {
		draft.MinAgeYears = durable.MinAgeYears
	}
	if durable.MaxAgeYears > 0 {
		draft.MaxAgeYears = durable.MaxAgeYears
	}
	if durable.MaxDistanceKm > 0 {
		draft.MaxDistanceKm = durable.MaxDistanceKm
	}
	draft.EducationFilter = append([]string{}, durable.EducationFilter...)
	draft.SeriousOnly = durable.SeriousOnly
	draft.VerifiedOnly = durable.VerifiedOnly
	if durable.Country != nil {
		draft.Country = durable.Country
	}
	if durable.RegionState != nil {
		draft.RegionState = durable.RegionState
	}
	if durable.City != nil {
		draft.City = durable.City
	}
	if len(durable.IntentTags) > 0 {
		draft.IntentTags = append([]string{}, durable.IntentTags...)
	}
	if len(durable.LanguageTags) > 0 {
		draft.LanguageTags = append([]string{}, durable.LanguageTags...)
	}
	draft.DealBreakerTags = append([]string{}, durable.DealBreakerTags...)
	if strings.TrimSpace(durable.Drinking) != "" {
		draft.Drinking = durable.Drinking
	}
	if strings.TrimSpace(durable.Smoking) != "" {
		draft.Smoking = durable.Smoking
	}
	if durable.Religion != nil {
		draft.Religion = durable.Religion
	}
	if durable.MotherTongue != nil {
		draft.MotherTongue = durable.MotherTongue
	}
	if durable.RelationshipStatus != nil {
		draft.RelationshipStatus = durable.RelationshipStatus
	}
	if durable.PersonalityType != nil {
		draft.PersonalityType = durable.PersonalityType
	}
	if durable.ProfileCompletion > 0 {
		draft.ProfileCompletion = durable.ProfileCompletion
	}
	return draft
}

func (r *profileRepository) upsertDraft(ctx context.Context, draft profileDraft) error {
	if r.pg != nil {
		return r.upsertDraftPostgres(ctx, draft)
	}
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
	if r.pg != nil {
		return r.completeProfilePostgres(ctx, draft)
	}
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
	if r.pg != nil {
		return r.bootstrapSignupPostgres(ctx, input)
	}
	trimmedUserID := strings.TrimSpace(input.UserID)
	if trimmedUserID == "" {
		return profileDraft{}, false, errors.New("user_id is required")
	}
	usersTable := strings.TrimSpace(r.cfg.UsersTable)
	if usersTable == "" {
		usersTable = "users"
	}

	usernameParams := url.Values{}
	usernameParams.Set("username", "eq."+strings.TrimSpace(input.Username))
	usernameParams.Set("limit", "1")
	usernameParams.Set("select", "id,username")
	usernameRows, err := r.db.SelectRead(ctx, r.cfg.UserSchema, usersTable, usernameParams)
	if err != nil {
		return profileDraft{}, false, err
	}
	if len(usernameRows) > 0 && strings.TrimSpace(toString(usernameRows[0]["id"])) != trimmedUserID {
		return profileDraft{}, false, errSignupUsernameAlreadyExists
	}

	params := url.Values{}
	params.Set("id", "eq."+trimmedUserID)
	params.Set("limit", "1")
	params.Set("select", "id,username,phone_number,name,date_of_birth,gender,profile_completion")
	rows, err := r.db.SelectRead(ctx, r.cfg.UserSchema, usersTable, params)
	if err != nil {
		return profileDraft{}, false, err
	}

	now := time.Now().UTC().Format(time.RFC3339)
	created := len(rows) == 0
	if created {
		_, err = r.db.Insert(ctx, r.cfg.UserSchema, usersTable, []map[string]any{{
			"id":                 trimmedUserID,
			"username":           strings.TrimSpace(input.Username),
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
		if strings.TrimSpace(toString(row["username"])) == "" {
			patch["username"] = strings.TrimSpace(input.Username)
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
	params.Set("select", "user_id,show_age,show_exact_distance,show_online_status,notify_new_match,notify_new_message,notify_likes,theme,locale,updated_at")
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
		Locale:            strings.TrimSpace(toString(row["locale"])),
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
		"locale":              nullableTrimmedString(settings.Locale),
		"updated_at":          time.Now().UTC().Format(time.RFC3339),
	}}, "user_id")
	return err
}

// nullableTrimmedString stores "" as SQL NULL so a cleared locale satisfies
// user_settings_locale_check instead of tripping it with an empty string.
func nullableTrimmedString(value string) any {
	trimmed := strings.TrimSpace(value)
	if trimmed == "" {
		return nil
	}
	return trimmed
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
	params.Set("order", "created_at.desc")
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
