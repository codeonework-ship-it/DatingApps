package mobile

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"
)

func scanVerification(scanner interface{ Scan(...any) error }) (verificationState, error) {
	var item verificationState
	var rejectionReason, reviewedBy sql.NullString
	var submittedAt, reviewedAt sql.NullTime
	if err := scanner.Scan(&item.UserID, &item.Status, &rejectionReason, &submittedAt, &reviewedAt, &reviewedBy, &item.EvidenceReceived); err != nil {
		return verificationState{}, err
	}
	item.RejectionReason, item.ReviewedBy = rejectionReason.String, reviewedBy.String
	if submittedAt.Valid {
		item.SubmittedAt = submittedAt.Time.UTC().Format(time.RFC3339)
	}
	if reviewedAt.Valid {
		item.ReviewedAt = reviewedAt.Time.UTC().Format(time.RFC3339)
	}
	return item, nil
}

const verificationSelect = `user_id::text,status,rejection_reason,submitted_at,reviewed_at,reviewed_by::text,(COALESCE(details,'{}'::jsonb) ? 'id_document' AND COALESCE(details,'{}'::jsonb) ? 'selfie')`

func (r *verificationRepository) attachVerificationEvidencePostgres(ctx context.Context, userID string, details map[string]any) (verificationState, error) {
	payload, err := json.Marshal(details)
	if err != nil {
		return verificationState{}, fmt.Errorf("encode verification evidence: %w", err)
	}
	item, err := scanVerification(r.pg.QueryRowContext(ctx, `
		UPDATE matching.verification_states
		SET details=COALESCE(details,'{}'::jsonb) || $2::jsonb, updated_at=NOW()
		WHERE user_id=$1
		RETURNING `+verificationSelect, strings.TrimSpace(userID), payload))
	if errors.Is(err, sql.ErrNoRows) {
		return verificationState{}, errors.New("verification not found")
	}
	return item, err
}

func (r *verificationRepository) getVerificationPostgres(ctx context.Context, userID string) (verificationState, error) {
	userID = strings.TrimSpace(userID)
	if userID == "" {
		return verificationState{}, errors.New("user_id is required")
	}
	item, err := scanVerification(r.pg.QueryRowContext(ctx, `SELECT `+verificationSelect+` FROM matching.verification_states WHERE user_id=$1`, userID))
	if errors.Is(err, sql.ErrNoRows) {
		return verificationState{UserID: userID}, nil
	}
	return item, err
}

func (r *verificationRepository) submitVerificationPostgres(ctx context.Context, userID string) (verificationState, error) {
	userID = strings.TrimSpace(userID)
	if userID == "" {
		return verificationState{}, errors.New("user_id is required")
	}
	tx, err := r.pg.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelReadCommitted})
	if err != nil {
		return verificationState{}, err
	}
	defer func() { _ = tx.Rollback() }()
	item, err := scanVerification(tx.QueryRowContext(ctx, `
		INSERT INTO matching.verification_states(user_id,status,submitted_at,review_deadline_at,reviewed_at,reviewed_by,rejection_reason,updated_at)
		VALUES($1,'pending',NOW(),NOW()+INTERVAL '24 hours',NULL,NULL,NULL,NOW())
		ON CONFLICT(user_id) DO UPDATE SET status='pending',submitted_at=NOW(),review_deadline_at=NOW()+INTERVAL '24 hours',reviewed_at=NULL,reviewed_by=NULL,rejection_reason=NULL,updated_at=NOW()
		RETURNING `+verificationSelect, userID))
	if err != nil {
		return verificationState{}, err
	}
	if err = insertSecurityEventTx(ctx, tx, "verification.submitted", userID, "user", userID, "verification", userID, map[string]any{"status": "pending", "review_sla_hours": 24}); err != nil {
		return verificationState{}, err
	}
	if err = tx.Commit(); err != nil {
		return verificationState{}, err
	}
	return item, nil
}

func (r *verificationRepository) reviewVerificationPostgres(ctx context.Context, userID, status, rejectionReason, reviewedBy string) (verificationState, error) {
	userID, status, reviewedBy = strings.TrimSpace(userID), strings.ToLower(strings.TrimSpace(status)), strings.TrimSpace(reviewedBy)
	if status == "approved" {
		status = "verified"
	}
	if userID == "" || reviewedBy == "" || (status != "verified" && status != "rejected") {
		return verificationState{}, errors.New("valid user_id, status, and authenticated reviewer are required")
	}
	if status == "rejected" && strings.TrimSpace(rejectionReason) == "" {
		return verificationState{}, errors.New("rejection_reason is required")
	}
	tx, err := r.pg.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelReadCommitted})
	if err != nil {
		return verificationState{}, err
	}
	defer func() { _ = tx.Rollback() }()
	var current string
	if err = tx.QueryRowContext(ctx, `SELECT status FROM matching.verification_states WHERE user_id=$1 FOR UPDATE`, userID).Scan(&current); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return verificationState{}, errors.New("verification not found")
		}
		return verificationState{}, err
	}
	item, err := scanVerification(tx.QueryRowContext(ctx, `UPDATE matching.verification_states SET status=$2,rejection_reason=NULLIF($3,''),reviewed_by=$4,reviewed_at=NOW(),updated_at=NOW() WHERE user_id=$1 RETURNING `+verificationSelect, userID, status, strings.TrimSpace(rejectionReason), reviewedBy))
	if err != nil {
		return verificationState{}, err
	}
	if _, err = tx.ExecContext(ctx, `UPDATE user_management.users SET is_verified=$2,updated_at=NOW() WHERE id=$1`, userID, status == "verified"); err != nil {
		return verificationState{}, err
	}
	if err = insertSecurityEventTx(ctx, tx, "verification."+status, reviewedBy, "operator", userID, "verification", userID, map[string]any{"previous_status": current, "status": status, "rejection_reason": item.RejectionReason}); err != nil {
		return verificationState{}, err
	}
	if _, err = tx.ExecContext(ctx, `SELECT matching.enqueue_notification(
		$1::uuid,$2::uuid,'verification.reviewed','safety',NULL,
		$3,'Verification updated',$4,'/verification/status',
		jsonb_build_object('status',$5),9)`, userID, reviewedBy,
		"verification-status:"+userID+":"+status,
		"Your identity verification is now "+status+".", status); err != nil {
		return verificationState{}, err
	}
	if err = tx.Commit(); err != nil {
		return verificationState{}, err
	}
	return item, nil
}

func (r *verificationRepository) listVerificationsPostgres(ctx context.Context, status string, limit int) ([]verificationState, error) {
	if limit <= 0 || limit > 500 {
		limit = 100
	}
	status = strings.ToLower(strings.TrimSpace(status))
	rows, err := r.pg.QueryContext(ctx, `SELECT `+verificationSelect+` FROM matching.verification_states WHERE ($1='' OR status=$1) ORDER BY submitted_at DESC NULLS LAST LIMIT $2`, status, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := make([]verificationState, 0)
	for rows.Next() {
		item, e := scanVerification(rows)
		if e != nil {
			return nil, e
		}
		out = append(out, item)
	}
	return out, rows.Err()
}
