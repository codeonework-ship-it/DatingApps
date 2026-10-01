package mobile

import (
	"context"
	"database/sql"
	"errors"
)

type mediaCleanupCandidate struct {
	PhotoID     string
	StoragePath string
}

type mediaAccessRecord struct {
	PhotoID          string
	UserID           string
	StoragePath      string
	ModerationStatus string
	MimeType         string
}

func (r *profileRepository) mediaAccessByStoragePathPostgres(
	ctx context.Context,
	storagePath string,
) (mediaAccessRecord, error) {
	var record mediaAccessRecord
	err := r.pg.QueryRowContext(ctx, `
		SELECT id::text,user_id::text,COALESCE(storage_path,''),moderation_status,COALESCE(mime_type,'')
		FROM user_management.photos
		WHERE storage_path=$1 AND deleted_at IS NULL`, storagePath,
	).Scan(&record.PhotoID, &record.UserID, &record.StoragePath, &record.ModerationStatus, &record.MimeType)
	return record, err
}

func (r *profileRepository) mediaAccessByPhotoIDPostgres(
	ctx context.Context,
	photoID string,
) (mediaAccessRecord, error) {
	var record mediaAccessRecord
	err := r.pg.QueryRowContext(ctx, `
		SELECT id::text,user_id::text,COALESCE(storage_path,''),moderation_status,COALESCE(mime_type,'')
		FROM user_management.photos
		WHERE id=$1::uuid AND deleted_at IS NULL`, photoID,
	).Scan(&record.PhotoID, &record.UserID, &record.StoragePath, &record.ModerationStatus, &record.MimeType)
	return record, err
}

func (r *profileRepository) profilePhotoStoragePathPostgres(
	ctx context.Context,
	userID, photoID string,
) (string, error) {
	var storagePath string
	err := r.pg.QueryRowContext(ctx, `
		SELECT COALESCE(storage_path,'')
		FROM user_management.photos
		WHERE id=$1::uuid AND user_id=$2 AND deleted_at IS NULL`, photoID, userID,
	).Scan(&storagePath)
	return storagePath, err
}

func (r *profileRepository) listMediaCleanupCandidatesPostgres(
	ctx context.Context,
	limit int,
) ([]mediaCleanupCandidate, error) {
	if limit <= 0 || limit > 500 {
		limit = 100
	}
	rows, err := r.pg.QueryContext(ctx, `
		SELECT id::text,COALESCE(storage_path,'')
		FROM user_management.photos
		WHERE storage_path IS NOT NULL AND storage_path <> '' AND (
		  lifecycle_status='delete_pending'
		  OR (lifecycle_status IN ('staged','quarantined') AND retained_until < NOW())
		)
		ORDER BY COALESCE(retained_until,uploaded_at),id
		LIMIT $1`, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	items := make([]mediaCleanupCandidate, 0, limit)
	for rows.Next() {
		var item mediaCleanupCandidate
		if err := rows.Scan(&item.PhotoID, &item.StoragePath); err != nil {
			return nil, err
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func (r *profileRepository) referencedMediaPathsPostgres(ctx context.Context) (map[string]struct{}, error) {
	rows, err := r.pg.QueryContext(ctx, `
		SELECT storage_path FROM user_management.photos
		WHERE deleted_at IS NULL AND storage_path IS NOT NULL AND storage_path <> ''`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	paths := make(map[string]struct{})
	for rows.Next() {
		var path string
		if err := rows.Scan(&path); err != nil {
			return nil, err
		}
		paths[path] = struct{}{}
	}
	return paths, rows.Err()
}

func (r *profileRepository) markMediaDeletedPostgres(ctx context.Context, photoID string) error {
	result, err := r.pg.ExecContext(ctx, `
		UPDATE user_management.photos
		SET lifecycle_status='deleted',deleted_at=COALESCE(deleted_at,NOW()),retained_until=NULL
		WHERE id=$1::uuid`, photoID)
	if err != nil {
		return err
	}
	if affected, _ := result.RowsAffected(); affected == 0 {
		return sql.ErrNoRows
	}
	return nil
}

func (r *profileRepository) markExpiredStagedPhotoDeletedPostgres(
	ctx context.Context,
	photoID string,
) error {
	_, err := r.pg.ExecContext(ctx, `
		UPDATE user_management.photos
		SET lifecycle_status='deleted',deleted_at=COALESCE(deleted_at,NOW()),retained_until=NULL
		WHERE id=$1::uuid AND lifecycle_status IN ('staged','quarantined','delete_pending')`, photoID)
	return err
}

func (r *profileRepository) purgeExpiredDraftSnapshotsPostgres(ctx context.Context) (int64, error) {
	result, err := r.pg.ExecContext(ctx, `
		UPDATE user_management.profile_drafts
		SET draft_payload='{}'::jsonb,purged_at=NOW(),lock_version=lock_version+1,updated_at=NOW()
		WHERE completed_at IS NOT NULL AND retained_until < NOW() AND purged_at IS NULL`)
	if err != nil {
		return 0, err
	}
	return result.RowsAffected()
}

func ignoreMissingMediaRow(err error) error {
	if errors.Is(err, sql.ErrNoRows) {
		return nil
	}
	return err
}
