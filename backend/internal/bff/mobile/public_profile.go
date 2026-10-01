package mobile

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"time"

	"github.com/google/uuid"
)

type profileRowReader interface {
	QueryRowContext(context.Context, string, ...any) *sql.Row
}

const publicProfileQuery = `
		SELECT to_jsonb(u) || jsonb_build_object('show_age',COALESCE(settings.show_age,TRUE)), COALESCE(s.profile_payload,'{}'::jsonb), media.urls
		FROM user_management.users u
		LEFT JOIN user_management.user_settings settings ON settings.user_id=u.id
		LEFT JOIN user_management.profile_snapshots s ON s.user_id=u.id
		CROSS JOIN LATERAL (
		  SELECT COALESCE(jsonb_agg(p.photo_url ORDER BY p.ordering,p.id),'[]'::jsonb) urls,
		         COUNT(*) approved_count
		  FROM user_management.photos p
		  WHERE p.user_id=u.id AND p.deleted_at IS NULL
		    AND p.lifecycle_status='active' AND p.moderation_status='approved'
		) media
		WHERE u.id=ANY($2::uuid[]) AND u.profile_completion=100 AND u.account_kind='dating'
		  AND u.is_active AND NOT u.is_banned AND u.deactivated_at IS NULL AND u.erased_at IS NULL
		  AND (u.suspended_at IS NULL OR (u.suspended_until IS NOT NULL AND u.suspended_until<=NOW()))
		  AND media.approved_count>=2
		  AND NOT EXISTS (SELECT 1 FROM user_management.auth_credentials c
		                  WHERE c.user_id=u.id AND c.is_disabled)
		  AND NOT EXISTS (SELECT 1 FROM user_management.blocked_users b
		                  WHERE (b.user_id=$1::uuid AND b.blocked_user_id=u.id)
		                     OR (b.user_id=u.id AND b.blocked_user_id=$1::uuid))`

// Read publication, current enforcement and current media in one database
// snapshot. Never consult the mutable private draft or its cached photo URLs.
func loadPublicProfile(ctx context.Context, db profileRowReader, viewerID, userID string) (map[string]any, bool, error) {
	var userJSON, snapshotJSON, photosJSON []byte
	err := db.QueryRowContext(ctx, publicProfileQuery, viewerID, []string{userID}).
		Scan(&userJSON, &snapshotJSON, &photosJSON)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, false, nil
	}
	if err != nil {
		return nil, false, err
	}
	var user, snapshot map[string]any
	var photos []string
	for _, item := range []struct {
		raw []byte
		dst any
	}{
		{userJSON, &user}, {snapshotJSON, &snapshot}, {photosJSON, &photos},
	} {
		if err := json.Unmarshal(item.raw, item.dst); err != nil {
			return nil, false, err
		}
	}
	return publicProfileProjection(user, snapshot, photos), true, nil
}

// loadPublicProfiles is loadPublicProfile for many members in one snapshot,
// keyed by member id. Members the viewer may not see are simply absent.
func loadPublicProfiles(ctx context.Context, db profileRowsReader, viewerID string, userIDs []string) (map[string]map[string]any, error) {
	profiles := make(map[string]map[string]any, len(userIDs))
	if len(userIDs) == 0 {
		return profiles, nil
	}
	rows, err := db.QueryContext(ctx, publicProfileQuery, viewerID, userIDs)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		var userJSON, snapshotJSON, photosJSON []byte
		if err := rows.Scan(&userJSON, &snapshotJSON, &photosJSON); err != nil {
			return nil, err
		}
		var user, snapshot map[string]any
		var photos []string
		for _, item := range []struct {
			raw []byte
			dst any
		}{
			{userJSON, &user}, {snapshotJSON, &snapshot}, {photosJSON, &photos},
		} {
			if err := json.Unmarshal(item.raw, item.dst); err != nil {
				return nil, err
			}
		}
		profiles[toString(user["id"])] = publicProfileProjection(user, snapshot, photos)
	}
	return profiles, rows.Err()
}

// An explicit allowlist prevents new database columns (contact details, precise
// location, enforcement metadata, etc.) from silently becoming member-visible.
func publicProfileProjection(user, snapshot map[string]any, photos []string) map[string]any {
	result := map[string]any{}
	for _, key := range []string{
		"id", "name", "gender", "bio", "height_cm",
		"education", "profession", "drinking", "smoking", "religion",
		"mother_tongue", "relationship_status", "personality_type",
		"country", "state", "city", "is_verified",
	} {
		if value, ok := user[key]; ok {
			result[key] = value
		}
	}
	// These are published member-authored display attributes retained by the
	// completion snapshot after mutable drafts expire. Current user/media state
	// above always owns identity, verification and photo visibility.
	for _, key := range []string{
		"additional_info", "instagram_handle", "hobbies", "favorite_books",
		"favorite_novels", "favorite_songs", "extra_curriculars", "party_lover",
		"intent_tags", "language_tags", "pet_preference", "diet_preference",
		"workout_frequency", "diet_type", "sleep_schedule", "travel_style",
		"political_comfort_range", "hookup_only", "deal_breaker_tags",
	} {
		if value, ok := snapshot[key]; ok {
			result[key] = value
		}
	}
	if age := publicAge(user); age != nil {
		result["age"] = *age
	}
	result["photoUrls"] = photos
	return result
}

// Apply the same publication rule in one query before ranking and exposure
// accounting. The resulting deck is the only input to spotlight selection.
// Both list keys are supported so callers can also revalidate an existing deck.
type profileRowsReader interface {
	QueryContext(context.Context, string, ...any) (*sql.Rows, error)
}

func publicAge(user map[string]any) *int {
	if user["show_age"] == false {
		return nil
	}
	raw := toString(user["date_of_birth"])
	age := ageYearsFromDateOfBirth(raw[:min(10, len(raw))], time.Now().UTC())
	if age <= 0 {
		return nil
	}
	return &age
}

type publishedDiscoveryProfile struct {
	Age      *int
	Photos   []string
	Verified bool
}

func filterPublishedDiscovery(ctx context.Context, db profileRowsReader, viewerID string, response map[string]any, criteria ...advancedFilterCriteria) error {
	ids := make([]string, 0)
	seen := map[string]bool{}
	for _, key := range []string{"candidates", "spotlight_profiles"} {
		rows, _ := response[key].([]any)
		for _, raw := range rows {
			row, _ := raw.(map[string]any)
			id, _ := row["id"].(string)
			if _, err := uuid.Parse(id); err == nil && id != viewerID && !seen[id] {
				ids = append(ids, id)
				seen[id] = true
			}
		}
	}
	visible := map[string]publishedDiscoveryProfile{}
	eligibility := map[string]profileDraft{}
	if len(ids) > 0 {
		rows, err := db.QueryContext(ctx, publicProfileQuery, viewerID, ids)
		if err != nil {
			return err
		}
		defer rows.Close()
		for rows.Next() {
			var userJSON, snapshotJSON, photosJSON []byte
			if err := rows.Scan(&userJSON, &snapshotJSON, &photosJSON); err != nil {
				return err
			}
			var user map[string]any
			var photos []string
			if err := json.Unmarshal(userJSON, &user); err != nil {
				return err
			}
			if err := json.Unmarshal(photosJSON, &photos); err != nil {
				return err
			}
			// Filter current published attributes, never mutable/expired private drafts.
			var published map[string]any
			if err := json.Unmarshal(snapshotJSON, &published); err != nil {
				return err
			}
			if published == nil {
				published = map[string]any{}
			}
			for key, value := range user {
				published[key] = value
			}
			published["date_of_birth"] = toString(user["date_of_birth"])
			rawDOB := toString(published["date_of_birth"])
			published["date_of_birth"] = rawDOB[:min(10, len(rawDOB))]
			payload, err := json.Marshal(published)
			if err != nil {
				return err
			}
			var draft profileDraft
			if err := json.Unmarshal(payload, &draft); err != nil {
				return err
			}
			eligibility[toString(user["id"])] = draft
			visible[toString(user["id"])] = publishedDiscoveryProfile{Photos: photos, Verified: user["is_verified"] == true, Age: publicAge(user)}
		}
		if err := rows.Err(); err != nil {
			return err
		}
	}
	applyPublishedDiscovery(response, visible)
	if len(criteria) > 0 {
		rows, _ := response["candidates"].([]any)
		filtered, summary := applyAdvancedFilterRows(rows, "id", criteria[0], func(id string) profileDraft { return eligibility[id] })
		response["candidates"] = filtered
		response["advanced_filter"] = summary
	}
	return nil
}

func applyPublishedDiscovery(response map[string]any, visible map[string]publishedDiscoveryProfile) {
	for _, key := range []string{"candidates", "spotlight_profiles"} {
		rows, exists := response[key].([]any)
		if !exists {
			continue
		}
		filtered := make([]any, 0, len(rows))
		for _, raw := range rows {
			row, ok := raw.(map[string]any)
			if !ok {
				continue
			}
			id, _ := row["id"].(string)
			published, ok := visible[id]
			if !ok {
				continue
			}
			for _, key := range []string{"age", "dateOfBirth", "date_of_birth"} {
				delete(row, key)
			}
			if published.Age != nil {
				row["age"] = *published.Age
			}
			row["photoUrls"] = published.Photos
			row["isVerified"] = published.Verified
			delete(row, "photo_urls")
			filtered = append(filtered, row)
		}
		response[key] = filtered
	}
}
