package mobile

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"strings"
	"time"
)

type mediaModerationReviewItem struct {
	PhotoID       string                 `json:"photo_id"`
	UserID        string                 `json:"user_id"`
	Username      string                 `json:"username"`
	PhotoURL      string                 `json:"photo_url"`
	MimeType      string                 `json:"mime_type"`
	WidthPx       int                    `json:"width_px"`
	HeightPx      int                    `json:"height_px"`
	SizeBytes     int64                  `json:"size_bytes"`
	Status        string                 `json:"status"`
	Reason        string                 `json:"reason,omitempty"`
	Provider      string                 `json:"provider,omitempty"`
	ModelVersion  string                 `json:"model_version,omitempty"`
	MaxConfidence float32                `json:"max_confidence,omitempty"`
	Labels        []mediaModerationLabel `json:"labels"`
	UploadedAt    string                 `json:"uploaded_at"`
}

func (r *profileRepository) recordRejectedMediaModerationPostgres(
	ctx context.Context,
	userID string,
	upload validatedPhotoUpload,
) error {
	_, err := r.pg.ExecContext(ctx, `
		INSERT INTO user_management.media_moderation_events
		  (user_id,content_sha256,mime_type,provider,model_version,decision,
		   reason,labels,duration_ms,actor_type,actor_id)
		VALUES ($1,$2,$3,$4,NULLIF($5,''),'rejected',NULLIF($6,''),$7::jsonb,$8,'provider',$4)`,
		userID, upload.ContentSHA256, upload.MimeType, upload.Moderation.Provider,
		upload.Moderation.ModelVersion, upload.Moderation.Reason,
		upload.ModerationLabels, upload.Moderation.DurationMS)
	return err
}

// scanMediaModerationReviewItem reads one review-queue row in the column
// order shared by the queue queries.
func scanMediaModerationReviewItem(rows *sql.Rows) (mediaModerationReviewItem, error) {
	var item mediaModerationReviewItem
	var labelsJSON []byte
	var uploadedAt time.Time
	if err := rows.Scan(
		&item.PhotoID, &item.UserID, &item.Username, &item.PhotoURL, &item.MimeType,
		&item.WidthPx, &item.HeightPx, &item.SizeBytes, &item.Status, &item.Reason,
		&item.Provider, &item.ModelVersion, &item.MaxConfidence, &labelsJSON, &uploadedAt,
	); err != nil {
		return mediaModerationReviewItem{}, err
	}
	item.Labels = []mediaModerationLabel{}
	if len(labelsJSON) > 0 {
		_ = json.Unmarshal(labelsJSON, &item.Labels)
	}
	item.UploadedAt = uploadedAt.UTC().Format(time.RFC3339)
	return item, nil
}

func (r *profileRepository) decideMediaModerationPostgres(
	ctx context.Context,
	photoID, decision, reason, operatorID string,
) (mediaModerationReviewItem, error) {
	decision = strings.TrimSpace(decision)
	if decision != mediaModerationApproved && decision != mediaModerationRejected {
		return mediaModerationReviewItem{}, errors.New("decision must be approved or rejected")
	}
	reason = strings.TrimSpace(reason)
	if decision == mediaModerationRejected && reason == "" {
		return mediaModerationReviewItem{}, errors.New("reason is required when rejecting media")
	}
	tx, err := r.pg.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		return mediaModerationReviewItem{}, err
	}
	defer func() { _ = tx.Rollback() }()

	var item mediaModerationReviewItem
	var contentSHA, storagePath string
	var labelsJSON []byte
	var uploadedAt time.Time
	err = tx.QueryRowContext(ctx, `
		SELECT p.id::text,p.user_id::text,u.username,p.photo_url,COALESCE(p.storage_path,''),
		       COALESCE(p.mime_type,''),COALESCE(p.width_px,0),COALESCE(p.height_px,0),
		       COALESCE(p.size_bytes,0),COALESCE(p.content_sha256,''),p.moderation_status,
		       COALESCE(p.moderation_reason,''),COALESCE(p.moderation_provider,''),
		       COALESCE(p.moderation_model_version,''),COALESCE(p.moderation_confidence,0)::real,
		       p.moderation_labels,p.uploaded_at
		FROM user_management.photos p
		JOIN user_management.users u ON u.id=p.user_id
		WHERE p.id=$1::uuid AND p.deleted_at IS NULL
		FOR UPDATE OF p`, photoID).Scan(
		&item.PhotoID, &item.UserID, &item.Username, &item.PhotoURL, &storagePath,
		&item.MimeType, &item.WidthPx, &item.HeightPx, &item.SizeBytes, &contentSHA,
		&item.Status, &item.Reason, &item.Provider, &item.ModelVersion,
		&item.MaxConfidence, &labelsJSON, &uploadedAt,
	)
	if err != nil {
		return mediaModerationReviewItem{}, err
	}
	if item.Status != mediaModerationReviewRequired && item.Status != "provider_error" {
		return mediaModerationReviewItem{}, errors.New("photo is not awaiting moderation review")
	}

	if decision == mediaModerationApproved {
		_, err = tx.ExecContext(ctx, `
			UPDATE user_management.photos
			SET moderation_status='approved',moderation_reason=NULL,is_moderated=TRUE,
			    is_flagged=FALSE,moderated_at=NOW()
			WHERE id=$1::uuid`, photoID)
	} else {
		_, err = tx.ExecContext(ctx, `
			UPDATE user_management.photos
			SET moderation_status='rejected',moderation_reason=$2,is_moderated=TRUE,
			    is_flagged=TRUE,moderated_at=NOW(),lifecycle_status='delete_pending',
			    deleted_at=NOW(),retained_until=NOW()
			WHERE id=$1::uuid`, photoID, reason)
	}
	if err != nil {
		return mediaModerationReviewItem{}, err
	}
	if _, err = tx.ExecContext(ctx, `
		INSERT INTO user_management.media_moderation_events
		  (user_id,photo_id,content_sha256,mime_type,provider,model_version,decision,
		   reason,labels,duration_ms,actor_type,actor_id)
		VALUES ($1,$2::uuid,$3,$4,'operator_review',NULL,$5,NULLIF($6,''),$7::jsonb,0,'operator',$8)`,
		item.UserID, item.PhotoID, contentSHA, item.MimeType, decision, reason,
		labelsJSON, operatorID); err != nil {
		return mediaModerationReviewItem{}, err
	}
	if err = tx.Commit(); err != nil {
		return mediaModerationReviewItem{}, err
	}
	item.Status = decision
	item.Reason = reason
	item.Labels = []mediaModerationLabel{}
	_ = json.Unmarshal(labelsJSON, &item.Labels)
	item.UploadedAt = uploadedAt.UTC().Format(time.RFC3339)
	return item, nil
}
