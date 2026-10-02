package mobile

import (
	"context"
	"crypto/sha256"
	"database/sql"
	"encoding/json"
	"errors"
	"strings"
	"time"

	"github.com/jackc/pgx/v5/pgconn"
	profileapp "github.com/verified-dating/backend/internal/modules/profile/application"
)

type signupWorkflowStatus struct {
	UserID          string `json:"user_id"`
	Username        string `json:"username"`
	State           string `json:"state"`
	CurrentActivity string `json:"current_activity"`
	LockVersion     int    `json:"lock_version"`
	SignupRequired  bool   `json:"signup_required"`
	UpdatedAt       string `json:"updated_at"`
}

func (r *profileRepository) userIDForAccessToken(ctx context.Context, authorization string) (string, error) {
	parts := strings.Fields(strings.TrimSpace(authorization))
	if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") || strings.TrimSpace(parts[1]) == "" {
		return "", errors.New("bearer token is required")
	}
	hash := sha256.Sum256([]byte(parts[1]))
	var userID string
	err := r.pg.QueryRowContext(ctx, `
		SELECT user_id::text FROM user_management.auth_sessions
		WHERE access_token_hash=$1 AND revoked_at IS NULL AND access_expires_at > NOW()`, hash[:],
	).Scan(&userID)
	return userID, err
}

func (r *profileRepository) getSignupWorkflow(ctx context.Context, userID string) (signupWorkflowStatus, error) {
	var status signupWorkflowStatus
	var updatedAt sql.NullTime
	err := r.pg.QueryRowContext(ctx, `
		SELECT user_id::text,username,state,current_activity,lock_version,updated_at
		FROM user_management.signup_workflows WHERE user_id=$1`, userID,
	).Scan(&status.UserID, &status.Username, &status.State, &status.CurrentActivity, &status.LockVersion, &updatedAt)
	if err != nil {
		return status, err
	}
	status.SignupRequired = status.State != "completed"
	if updatedAt.Valid {
		status.UpdatedAt = updatedAt.Time.UTC().Format("2006-01-02T15:04:05Z07:00")
	}
	return status, nil
}

func (r *profileRepository) getDraftPostgres(ctx context.Context, userID string) (profileDraft, error) {
	userID = strings.TrimSpace(userID)
	if userID == "" {
		return profileDraft{}, errors.New("user_id is required")
	}
	var payload []byte
	err := r.pg.QueryRowContext(ctx, `
		SELECT COALESCE(
		  (SELECT NULLIF(draft_payload,'{}'::jsonb) FROM user_management.profile_drafts WHERE user_id=$1),
		  (SELECT profile_payload FROM user_management.profile_snapshots WHERE user_id=$1)
		)`, userID).Scan(&payload)
	if errors.Is(err, sql.ErrNoRows) || (err == nil && len(payload) == 0) {
		draft := defaultDraft(userID)
		photos, photoErr := r.listActivePhotosPostgres(ctx, userID)
		if photoErr != nil {
			return profileDraft{}, photoErr
		}
		draft.Photos = photos
		return draft, nil
	}
	if err != nil {
		return profileDraft{}, err
	}
	draft := defaultDraft(userID)
	if err := json.Unmarshal(payload, &draft); err != nil {
		return profileDraft{}, err
	}
	draft.UserID = userID
	photos, err := r.listActivePhotosPostgres(ctx, userID)
	if err != nil {
		return profileDraft{}, err
	}
	draft.Photos = photos
	return draft, nil
}

func (r *profileRepository) listActivePhotosPostgres(ctx context.Context, userID string) ([]profilePhoto, error) {
	rows, err := r.pg.QueryContext(ctx, `
		SELECT id::text,photo_url,COALESCE(storage_path,''),ordering,
		       COALESCE(original_filename,''),COALESCE(mime_type,''),
		       COALESCE(width_px,0),COALESCE(height_px,0),COALESCE(size_bytes,0),
		       COALESCE(moderation_status,'pending'),COALESCE(moderation_reason,'')
		FROM user_management.photos
		WHERE user_id=$1 AND deleted_at IS NULL AND moderation_status <> 'rejected'
		ORDER BY ordering,id`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	photos := make([]profilePhoto, 0, maxProfilePhotos)
	for rows.Next() {
		var photo profilePhoto
		if err := rows.Scan(
			&photo.ID, &photo.PhotoURL, &photo.StoragePath, &photo.Ordering,
			&photo.OriginalFilename, &photo.MimeType, &photo.WidthPx,
			&photo.HeightPx, &photo.SizeBytes, &photo.ModerationStatus, &photo.ModerationReason,
		); err != nil {
			return nil, err
		}
		photos = append(photos, photo)
	}
	return photos, rows.Err()
}

func (r *profileRepository) addPhotoPostgres(
	ctx context.Context,
	draft profileDraft,
	upload profileapp.ProfilePhotoUploadInput,
) error {
	payload, err := json.Marshal(draft)
	if err != nil {
		return err
	}
	tx, err := r.pg.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		return err
	}
	defer func() { _ = tx.Rollback() }()

	var ignored string
	if err = tx.QueryRowContext(ctx, `
		SELECT id::text FROM user_management.users WHERE id=$1 FOR UPDATE`, draft.UserID,
	).Scan(&ignored); err != nil {
		return err
	}
	var photoCount int
	var storageBytes int64
	if err = tx.QueryRowContext(ctx, `
		SELECT COUNT(*),COALESCE(SUM(size_bytes),0)
		FROM user_management.photos
		WHERE user_id=$1 AND deleted_at IS NULL`, draft.UserID,
	).Scan(&photoCount, &storageBytes); err != nil {
		return err
	}
	if photoCount >= maxProfilePhotos {
		return errors.New("photo quota reached: maximum 5 photos")
	}
	if upload.SizeBytes > 0 && storageBytes+upload.SizeBytes > maxProfileStorageBytes {
		return errors.New("storage quota reached: maximum 50 MB per user")
	}

	lifecycleStatus := "staged"
	var retainedUntil any = time.Now().UTC().Add(30 * 24 * time.Hour)
	if draft.ProfileCompletion >= 100 {
		lifecycleStatus = "active"
		retainedUntil = nil
	}
	moderationStatus := normalizedMediaModerationStatus(upload.ModerationStatus)
	labelsJSON := upload.ModerationLabelsJSON
	if len(labelsJSON) == 0 {
		labelsJSON = []byte("[]")
	}
	if _, err = tx.ExecContext(ctx, `
		INSERT INTO user_management.photos
		  (id,user_id,photo_url,storage_path,ordering,original_filename,mime_type,
		   width_px,height_px,size_bytes,content_sha256,lifecycle_status,
		   retained_until,moderation_status,moderation_reason,moderation_provider,
		   moderation_model_version,moderation_labels,moderation_confidence,moderated_at,is_moderated)
		VALUES
		  ($1::uuid,$2,$3,NULLIF($4,''),$5,NULLIF($6,''),NULLIF($7,''),
		   NULLIF($8,0),NULLIF($9,0),NULLIF($10,0),NULLIF($11,''),$12,$13,$14,
		   NULLIF($15,''),NULLIF($16,''),NULLIF($17,''),$18::jsonb,NULLIF($19,0),NOW(),$14='approved')`,
		upload.ID, draft.UserID, upload.PhotoURL, upload.StoragePath, len(draft.Photos)-1,
		upload.OriginalFilename, upload.MimeType, upload.WidthPx, upload.HeightPx,
		upload.SizeBytes, upload.ContentSHA256, lifecycleStatus, retainedUntil, moderationStatus,
		upload.ModerationReason, upload.ModerationProvider, upload.ModerationModelVersion,
		labelsJSON, upload.ModerationConfidence); err != nil {
		return err
	}
	if moderationStatus != "pending" && strings.TrimSpace(upload.ModerationProvider) != "" {
		if _, err = tx.ExecContext(ctx, `
			INSERT INTO user_management.media_moderation_events
			  (user_id,photo_id,content_sha256,mime_type,provider,model_version,decision,
			   reason,labels,duration_ms,actor_type,actor_id)
			VALUES ($1,$2::uuid,$3,$4,$5,NULLIF($6,''),$7,NULLIF($8,''),$9::jsonb,$10,'provider',$5)`,
			draft.UserID, upload.ID, upload.ContentSHA256, upload.MimeType,
			upload.ModerationProvider, upload.ModerationModelVersion, moderationStatus,
			upload.ModerationReason, labelsJSON, upload.ModerationDurationMS); err != nil {
			return err
		}
	}
	if _, err = tx.ExecContext(ctx, `
		INSERT INTO user_management.profile_drafts (user_id,draft_payload)
		VALUES ($1,$2::jsonb)
		ON CONFLICT (user_id) DO UPDATE SET
		  draft_payload=EXCLUDED.draft_payload,
		  lock_version=user_management.profile_drafts.lock_version+1,
		  updated_at=NOW(),purged_at=NULL`, draft.UserID, payload); err != nil {
		return err
	}
	if _, err = tx.ExecContext(ctx, `
		INSERT INTO user_management.signup_workflow_activities
		  (user_id,activity,status,idempotency_key,payload)
		VALUES ($1,'profile_photo_upload','completed',$2,
		  jsonb_build_object('photo_id',$3::text,'size_bytes',$4::bigint,
		  'width_px',$5::int,'height_px',$6::int,'mime_type',$7::text))
		ON CONFLICT (user_id,idempotency_key) WHERE idempotency_key IS NOT NULL DO NOTHING`,
		draft.UserID, "profile_photo_upload:"+upload.ID, upload.ID, upload.SizeBytes,
		upload.WidthPx, upload.HeightPx, upload.MimeType); err != nil {
		return err
	}
	return tx.Commit()
}

func (r *profileRepository) deletePhotoPostgres(
	ctx context.Context,
	userID, photoID string,
) (profileDraft, string, error) {
	draft, err := r.getDraftPostgres(ctx, userID)
	if err != nil {
		return profileDraft{}, "", err
	}
	remaining := make([]profilePhoto, 0, len(draft.Photos))
	found := false
	for _, photo := range draft.Photos {
		if photo.ID == photoID {
			found = true
			continue
		}
		photo.Ordering = len(remaining)
		remaining = append(remaining, photo)
	}
	if !found {
		return profileDraft{}, "", errors.New("profile photo not found")
	}
	draft.Photos = remaining
	payload, err := json.Marshal(draft)
	if err != nil {
		return profileDraft{}, "", err
	}
	tx, err := r.pg.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		return profileDraft{}, "", err
	}
	defer func() { _ = tx.Rollback() }()
	var lockedUserID string
	if err = tx.QueryRowContext(ctx, `
		SELECT id::text FROM user_management.users WHERE id=$1 FOR UPDATE`, userID,
	).Scan(&lockedUserID); err != nil {
		return profileDraft{}, "", err
	}
	var storagePath string
	if err = tx.QueryRowContext(ctx, `
		UPDATE user_management.photos
		SET lifecycle_status='delete_pending',deleted_at=NOW(),retained_until=NOW()
		WHERE id=$1::uuid AND user_id=$2 AND deleted_at IS NULL
		RETURNING COALESCE(storage_path,'')`, photoID, userID).Scan(&storagePath); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return profileDraft{}, "", errors.New("profile photo not found")
		}
		return profileDraft{}, "", err
	}
	if _, err = tx.ExecContext(ctx, `
		UPDATE user_management.photos SET ordering=ordering+1000
		WHERE user_id=$1 AND deleted_at IS NULL`, userID); err != nil {
		return profileDraft{}, "", err
	}
	if _, err = tx.ExecContext(ctx, `
		WITH ranked AS (
		  SELECT id,ROW_NUMBER() OVER (ORDER BY ordering,id)-1 AS new_order
		  FROM user_management.photos
		  WHERE user_id=$1 AND deleted_at IS NULL
		)
		UPDATE user_management.photos p SET ordering=ranked.new_order
		FROM ranked WHERE p.id=ranked.id`, userID); err != nil {
		return profileDraft{}, "", err
	}
	if _, err = tx.ExecContext(ctx, `
		UPDATE user_management.profile_drafts
		SET draft_payload=$2::jsonb,lock_version=lock_version+1,updated_at=NOW(),purged_at=NULL
		WHERE user_id=$1`, userID, payload); err != nil {
		return profileDraft{}, "", err
	}
	if _, err = tx.ExecContext(ctx, `
		INSERT INTO user_management.signup_workflow_activities
		  (user_id,activity,status,idempotency_key,payload)
		VALUES ($1,'profile_photo_delete','completed',$2,jsonb_build_object('photo_id',$3::text))
		ON CONFLICT (user_id,idempotency_key) WHERE idempotency_key IS NOT NULL DO NOTHING`,
		userID, "profile_photo_delete:"+photoID, photoID); err != nil {
		return profileDraft{}, "", err
	}
	if err = tx.Commit(); err != nil {
		return profileDraft{}, "", err
	}
	return draft, storagePath, nil
}

func (r *profileRepository) reorderPhotosPostgres(
	ctx context.Context,
	userID string,
	photoIDs []string,
) (profileDraft, error) {
	draft, err := r.getDraftPostgres(ctx, userID)
	if err != nil {
		return profileDraft{}, err
	}
	if len(photoIDs) != len(draft.Photos) {
		return profileDraft{}, &photoOrderError{msg: "photo_ids must include every active photo"}
	}
	byID := make(map[string]profilePhoto, len(draft.Photos))
	for _, photo := range draft.Photos {
		byID[photo.ID] = photo
	}
	reordered := make([]profilePhoto, 0, len(photoIDs))
	for index, photoID := range photoIDs {
		photo, ok := byID[photoID]
		if !ok {
			return profileDraft{}, &photoOrderError{msg: "photo_ids contain an unknown or duplicate photo"}
		}
		delete(byID, photoID)
		photo.Ordering = index
		reordered = append(reordered, photo)
	}
	draft.Photos = reordered
	payload, err := json.Marshal(draft)
	if err != nil {
		return profileDraft{}, err
	}
	photoIDsJSON, err := json.Marshal(photoIDs)
	if err != nil {
		return profileDraft{}, err
	}
	tx, err := r.pg.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		return profileDraft{}, err
	}
	defer func() { _ = tx.Rollback() }()
	var lockedUserID string
	if err = tx.QueryRowContext(ctx, `
		SELECT id::text FROM user_management.users WHERE id=$1 FOR UPDATE`, userID,
	).Scan(&lockedUserID); err != nil {
		return profileDraft{}, err
	}
	if _, err = tx.ExecContext(ctx, `
		UPDATE user_management.photos SET ordering=ordering+1000
		WHERE user_id=$1 AND deleted_at IS NULL`, userID); err != nil {
		return profileDraft{}, err
	}
	for index, photoID := range photoIDs {
		result, updateErr := tx.ExecContext(ctx, `
			UPDATE user_management.photos SET ordering=$3
			WHERE id=$1::uuid AND user_id=$2 AND deleted_at IS NULL`, photoID, userID, index)
		if updateErr != nil {
			return profileDraft{}, updateErr
		}
		if affected, _ := result.RowsAffected(); affected != 1 {
			return profileDraft{}, errors.New("profile photo changed during reorder")
		}
	}
	if _, err = tx.ExecContext(ctx, `
		UPDATE user_management.profile_drafts
		SET draft_payload=$2::jsonb,lock_version=lock_version+1,updated_at=NOW(),purged_at=NULL
		WHERE user_id=$1`, userID, payload); err != nil {
		return profileDraft{}, err
	}
	if _, err = tx.ExecContext(ctx, `
		INSERT INTO user_management.signup_workflow_activities
		  (user_id,activity,status,idempotency_key,payload)
		VALUES ($1,'profile_photo_reorder','completed',$2,jsonb_build_object('photo_ids',$3::jsonb))
		ON CONFLICT (user_id,idempotency_key) WHERE idempotency_key IS NOT NULL DO UPDATE
		SET payload=EXCLUDED.payload,occurred_at=NOW()`,
		userID, "profile_photo_reorder", photoIDsJSON); err != nil {
		return profileDraft{}, err
	}
	if err = tx.Commit(); err != nil {
		return profileDraft{}, err
	}
	return draft, nil
}

func (r *profileRepository) upsertDraftPostgres(ctx context.Context, draft profileDraft) error {
	if strings.TrimSpace(draft.UserID) == "" {
		return errors.New("user_id is required")
	}
	payload, err := json.Marshal(draft)
	if err != nil {
		return err
	}
	tx, err := r.pg.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer func() { _ = tx.Rollback() }()
	if _, err = tx.ExecContext(ctx, `
		INSERT INTO user_management.profile_drafts (user_id, draft_payload)
		VALUES ($1, $2::jsonb)
		ON CONFLICT (user_id) DO UPDATE SET
		  draft_payload = EXCLUDED.draft_payload,
		  lock_version = user_management.profile_drafts.lock_version + 1,
		  updated_at = NOW()`, draft.UserID, payload); err != nil {
		return err
	}
	if _, err = tx.ExecContext(ctx, `
		UPDATE user_management.signup_workflows
		SET state = CASE WHEN state = 'terms_accepted' THEN 'profile_in_progress' ELSE state END,
		    current_activity = CASE WHEN state = 'terms_accepted' THEN 'build_profile' ELSE current_activity END,
		    profile_started_at = COALESCE(profile_started_at, NOW()),
		    lock_version = lock_version + 1,
		    updated_at = NOW()
		WHERE user_id = $1 AND state <> 'completed'`, draft.UserID); err != nil {
		return err
	}
	_, err = tx.ExecContext(ctx, `
		INSERT INTO user_management.signup_workflow_activities
		  (user_id, activity, status, idempotency_key, payload)
		VALUES ($1, 'build_profile', 'started', 'build_profile', jsonb_build_object('profile_completion', $2::int))
		ON CONFLICT (user_id, idempotency_key) WHERE idempotency_key IS NOT NULL DO NOTHING`,
		draft.UserID, draft.ProfileCompletion)
	if err != nil {
		return err
	}
	return tx.Commit()
}

func (r *profileRepository) bootstrapSignupPostgres(ctx context.Context, input signupBootstrapInput) (profileDraft, bool, error) {
	input.UserID = strings.TrimSpace(input.UserID)
	input.Username = strings.ToLower(strings.TrimSpace(input.Username))
	tx, err := r.pg.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		return profileDraft{}, false, err
	}
	defer func() { _ = tx.Rollback() }()

	var credentialUsername string
	if err = tx.QueryRowContext(ctx, `
		SELECT username FROM user_management.auth_credentials WHERE user_id = $1 FOR UPDATE`, input.UserID,
	).Scan(&credentialUsername); errors.Is(err, sql.ErrNoRows) {
		return profileDraft{}, false, errors.New("signup credentials do not exist")
	} else if err != nil {
		return profileDraft{}, false, err
	}
	if !strings.EqualFold(credentialUsername, input.Username) {
		return profileDraft{}, false, errors.New("signup identity does not match authenticated credentials")
	}

	var exists bool
	if err = tx.QueryRowContext(ctx, `SELECT EXISTS (SELECT 1 FROM user_management.users WHERE id = $1)`, input.UserID).Scan(&exists); err != nil {
		return profileDraft{}, false, err
	}
	if _, err = tx.ExecContext(ctx, `
		INSERT INTO user_management.users
		  (id, username, name, date_of_birth, gender, profile_completion, is_active)
		VALUES ($1, $2, $3, $4::date, $5, 25, TRUE)
		ON CONFLICT (id) DO UPDATE SET updated_at = NOW()`,
		input.UserID, input.Username, strings.TrimSpace(input.Name), input.DateOfBirth, storedGenderValue(input.Gender)); err != nil {
		if strings.Contains(strings.ToLower(err.Error()), "username") || strings.Contains(strings.ToLower(err.Error()), "unique") {
			return profileDraft{}, false, errSignupUsernameAlreadyExists
		}
		return profileDraft{}, false, err
	}

	draft := mergeSignupIntoDraft(defaultDraft(input.UserID), input)
	payload, err := json.Marshal(draft)
	if err != nil {
		return profileDraft{}, false, err
	}
	if _, err = tx.ExecContext(ctx, `
		INSERT INTO user_management.profile_drafts (user_id, draft_payload)
		VALUES ($1, $2::jsonb)
		ON CONFLICT (user_id) DO UPDATE SET draft_payload = EXCLUDED.draft_payload,
		  lock_version = user_management.profile_drafts.lock_version + 1, updated_at = NOW()`,
		input.UserID, payload); err != nil {
		return profileDraft{}, false, err
	}
	if _, err = tx.ExecContext(ctx, `
		INSERT INTO user_management.user_settings (user_id) VALUES ($1)
		ON CONFLICT (user_id) DO NOTHING`, input.UserID); err != nil {
		return profileDraft{}, false, err
	}
	if _, err = tx.ExecContext(ctx, `
		UPDATE user_management.signup_workflows
		SET state = 'basics_captured', current_activity = 'accept_terms',
		    basics_captured_at = COALESCE(basics_captured_at, NOW()),
		    lock_version = lock_version + 1, last_error = NULL, updated_at = NOW()
		WHERE user_id = $1 AND state <> 'completed'`, input.UserID); err != nil {
		return profileDraft{}, false, err
	}
	if _, err = tx.ExecContext(ctx, `
		INSERT INTO user_management.signup_workflow_activities
		  (user_id, activity, status, idempotency_key, payload)
		VALUES ($1, 'bootstrap_profile', 'completed', 'bootstrap_profile',
		  jsonb_build_object('name', $2::text, 'date_of_birth', $3::text, 'gender', $4::text))
		ON CONFLICT (user_id, idempotency_key) WHERE idempotency_key IS NOT NULL DO NOTHING`,
		input.UserID, input.Name, input.DateOfBirth, input.Gender); err != nil {
		return profileDraft{}, false, err
	}
	if err = tx.Commit(); err != nil {
		return profileDraft{}, false, err
	}
	return copyDraft(draft), !exists, nil
}

// serializableAttempts bounds how often a SERIALIZABLE transaction is re-run
// after Postgres cancels it with a serialization failure.
const serializableAttempts = 3

// isSerializationFailure reports SQLSTATE 40001. Postgres asks the client to
// retry the whole transaction; nothing of the failed attempt was committed.
func isSerializationFailure(err error) bool {
	var pgErr *pgconn.PgError
	return errors.As(err, &pgErr) && pgErr.Code == "40001"
}

// retrySerializable runs fn (one complete transaction) again when it fails
// with a serialization failure, up to attempts times, with a short backoff.
func retrySerializable(ctx context.Context, attempts int, fn func() error) error {
	var err error
	for attempt := 1; ; attempt++ {
		if err = fn(); err == nil || !isSerializationFailure(err) || attempt >= attempts {
			return err
		}
		select {
		case <-ctx.Done():
			return err
		case <-time.After(time.Duration(attempt) * 15 * time.Millisecond):
		}
	}
}

// completeProfilePostgres is the last signup step. Its SERIALIZABLE
// transaction fires audit and outbox triggers that write shared tables, so
// concurrent signups can cancel it with 40001; that is retried instead of
// surfacing as a 502 (API-23).
func (r *profileRepository) completeProfilePostgres(ctx context.Context, draft profileDraft) error {
	if err := validateDraftReadyForCompletion(draft); err != nil {
		return err
	}
	return retrySerializable(ctx, serializableAttempts, func() error {
		return r.completeProfilePostgresOnce(ctx, draft)
	})
}

func (r *profileRepository) completeProfilePostgresOnce(ctx context.Context, draft profileDraft) error {
	draft.ProfileCompletion = 100
	payload, err := json.Marshal(draft)
	if err != nil {
		return err
	}
	tx, err := r.pg.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		return err
	}
	defer func() { _ = tx.Rollback() }()

	var termsAccepted bool
	if err = tx.QueryRowContext(ctx, `
		SELECT terms_accepted FROM user_management.users WHERE id = $1 FOR UPDATE`, draft.UserID,
	).Scan(&termsAccepted); err != nil {
		return err
	}
	if !termsAccepted {
		return completionProblem(errors.New("terms must be accepted before completing profile"))
	}
	var approvedPhotos int
	if err = tx.QueryRowContext(ctx, `
		SELECT COUNT(*) FROM user_management.photos
		WHERE user_id=$1 AND deleted_at IS NULL AND moderation_status='approved'`, draft.UserID,
	).Scan(&approvedPhotos); err != nil {
		return err
	}
	if approvedPhotos < len(draft.Photos) {
		return completionProblem(errors.New("all profile photos must be approved before profile completion"))
	}
	if _, err = tx.ExecContext(ctx, `
		UPDATE user_management.users SET
		  name=$2, date_of_birth=$3::date, gender=$4, bio=$5, height_cm=$6,
		  education=$7, profession=$8, income_range=$9, drinking=$10, smoking=$11,
		  religion=$12, mother_tongue=$13, relationship_status=$14, personality_type=$15,
		  country=$16, state=$17, city=$18, profile_completion=100, is_active=TRUE, updated_at=NOW()
		WHERE id=$1`, draft.UserID, strings.TrimSpace(draft.Name), draft.DateOfBirth,
		storedGenderValue(draft.Gender), nullableStringValue(draft.Bio), draft.HeightCm,
		draft.Education, draft.Profession, draft.IncomeRange, nullableStringValue(draft.Drinking),
		nullableStringValue(draft.Smoking), draft.Religion, draft.MotherTongue,
		draft.RelationshipStatus, draft.PersonalityType, draft.Country, draft.RegionState, draft.City); err != nil {
		return err
	}
	if _, err = tx.ExecContext(ctx, `
		UPDATE user_management.signup_workflow_activities
		SET status='completed', payload=payload || jsonb_build_object('completed_at', NOW())
		WHERE user_id=$1 AND idempotency_key='build_profile' AND status='started'`, draft.UserID); err != nil {
		return err
	}
	if _, err = tx.ExecContext(ctx, `
		INSERT INTO user_management.preferences
		  (user_id,seeking_genders,min_age_years,max_age_years,max_distance_km,education_filter,
		   serious_only,verified_only,intent_tags,language_tags,deal_breaker_tags)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
		ON CONFLICT (user_id) DO UPDATE SET
		  seeking_genders=EXCLUDED.seeking_genders,min_age_years=EXCLUDED.min_age_years,
		  max_age_years=EXCLUDED.max_age_years,max_distance_km=EXCLUDED.max_distance_km,
		  education_filter=EXCLUDED.education_filter,serious_only=EXCLUDED.serious_only,
		  verified_only=EXCLUDED.verified_only,intent_tags=EXCLUDED.intent_tags,
		  language_tags=EXCLUDED.language_tags,deal_breaker_tags=EXCLUDED.deal_breaker_tags,updated_at=NOW()`,
		draft.UserID, storedGenderListValue(draft.SeekingGenders), draft.MinAgeYears, draft.MaxAgeYears,
		draft.MaxDistanceKm, draft.EducationFilter, draft.SeriousOnly, draft.VerifiedOnly,
		draft.IntentTags, draft.LanguageTags, draft.DealBreakerTags); err != nil {
		return err
	}
	result, err := tx.ExecContext(ctx, `
		UPDATE user_management.photos
		SET lifecycle_status='active',retained_until=NULL
		WHERE user_id=$1 AND deleted_at IS NULL`, draft.UserID)
	if err != nil {
		return err
	}
	if affected, _ := result.RowsAffected(); int(affected) < len(draft.Photos) {
		return errors.New("durable photo metadata is incomplete")
	}
	if _, err = tx.ExecContext(ctx, `
		INSERT INTO user_management.profile_snapshots (user_id,profile_payload)
		VALUES ($1,$2::jsonb)
		ON CONFLICT (user_id) DO UPDATE SET
		  profile_payload=EXCLUDED.profile_payload,updated_at=NOW()`, draft.UserID, payload); err != nil {
		return err
	}
	if _, err = tx.ExecContext(ctx, `
		UPDATE user_management.profile_drafts SET draft_payload=$2::jsonb, completed_at=NOW(),
		  completion_source='mobile_setup_wizard',retained_until=NOW()+INTERVAL '30 days',
		  purged_at=NULL,lock_version=lock_version+1,updated_at=NOW()
		WHERE user_id=$1`, draft.UserID, payload); err != nil {
		return err
	}
	if _, err = tx.ExecContext(ctx, `
		INSERT INTO user_management.profile_setup_completions
		  (user_id,completion_source,photos_count,bio_length,has_height,has_education,
		   has_profession,has_lifestyle,profile_completion_pct,idempotency_key)
		VALUES ($1,'mobile_setup_wizard',$2,$3,$4,$5,$6,$7,100,$8)
		ON CONFLICT (idempotency_key) DO NOTHING`, draft.UserID, len(draft.Photos),
		len([]rune(strings.TrimSpace(draft.Bio))), draft.HeightCm != nil,
		draft.Education != nil, draft.Profession != nil,
		strings.TrimSpace(draft.Drinking) != "" || strings.TrimSpace(draft.Smoking) != "",
		"mobile_setup_wizard:"+draft.UserID); err != nil {
		return err
	}
	if _, err = tx.ExecContext(ctx, `
		UPDATE user_management.signup_workflows
		SET state='completed', current_activity='done', completed_at=COALESCE(completed_at,NOW()),
		    lock_version=lock_version+1, last_error=NULL, updated_at=NOW()
		WHERE user_id=$1`, draft.UserID); err != nil {
		return err
	}
	if _, err = tx.ExecContext(ctx, `
		INSERT INTO user_management.signup_workflow_activities
		  (user_id,activity,status,idempotency_key,payload)
		VALUES ($1,'complete_profile','completed','complete_profile',
		  jsonb_build_object('photos_count',$2::int,'bio_length',$3::int))
		ON CONFLICT (user_id,idempotency_key) WHERE idempotency_key IS NOT NULL DO NOTHING`,
		draft.UserID, len(draft.Photos), len([]rune(strings.TrimSpace(draft.Bio)))); err != nil {
		return err
	}
	return tx.Commit()
}
