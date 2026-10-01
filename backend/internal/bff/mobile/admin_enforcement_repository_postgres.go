package mobile

import (
	"context"
	"database/sql"
	"errors"
	"strings"
	"time"
)

func (r *adminRepository) setUserSuspension(ctx context.Context, operatorID, userID, reason string, until *time.Time, suspended bool) error {
	operatorID, userID = strings.TrimSpace(operatorID), strings.TrimSpace(userID)
	if operatorID == "" || userID == "" {
		return errors.New("authenticated operator and user_id are required")
	}
	if operatorID == userID {
		return errors.New("operators cannot suspend their own account")
	}
	tx, err := r.pg.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelReadCommitted})
	if err != nil {
		return err
	}
	defer func() { _ = tx.Rollback() }()
	var lockedUserID string
	if err = tx.QueryRowContext(ctx, `SELECT id::text FROM user_management.users WHERE id=$1 FOR UPDATE`, userID).Scan(&lockedUserID); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return errors.New("user not found")
		}
		return err
	}
	if suspended {
		if strings.TrimSpace(reason) == "" {
			return errors.New("suspension reason is required")
		}
		if _, err = tx.ExecContext(ctx, `UPDATE user_management.users SET suspended_at=NOW(),suspended_reason=$2,suspended_until=$3,updated_at=NOW() WHERE id=$1`, userID, strings.TrimSpace(reason), until); err != nil {
			return err
		}
		if _, err = tx.ExecContext(ctx, `UPDATE user_management.auth_sessions SET revoked_at=COALESCE(revoked_at,NOW()),revoked_reason='account_suspended' WHERE user_id=$1 AND revoked_at IS NULL`, userID); err != nil {
			return err
		}
	} else {
		if _, err = tx.ExecContext(ctx, `UPDATE user_management.users SET suspended_at=NULL,suspended_reason=NULL,suspended_until=NULL,updated_at=NOW() WHERE id=$1`, userID); err != nil {
			return err
		}
	}
	eventType := "admin.user.unsuspended"
	if suspended {
		eventType = "admin.user.suspended"
	}
	payload := map[string]any{"suspended": suspended, "reason": strings.TrimSpace(reason)}
	if until != nil {
		payload["suspended_until"] = until.UTC().Format(time.RFC3339)
	}
	if err = insertSecurityEventTx(ctx, tx, eventType, operatorID, "admin", userID, "user_account", userID, payload); err != nil {
		return err
	}
	return tx.Commit()
}

func (r *adminRepository) setUserBan(ctx context.Context, operatorID, userID, reason string, banned bool) error {
	operatorID, userID = strings.TrimSpace(operatorID), strings.TrimSpace(userID)
	if operatorID == "" || userID == "" {
		return errors.New("authenticated operator and user_id are required")
	}
	if operatorID == userID {
		return errors.New("operators cannot ban their own account")
	}
	if banned && strings.TrimSpace(reason) == "" {
		return errors.New("ban reason is required")
	}
	tx, err := r.pg.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelReadCommitted})
	if err != nil {
		return err
	}
	defer func() { _ = tx.Rollback() }()
	result, err := tx.ExecContext(ctx, `UPDATE user_management.users SET is_banned=$2,suspended_reason=CASE WHEN $2 THEN $3 ELSE NULL END,updated_at=NOW() WHERE id=$1`, userID, banned, strings.TrimSpace(reason))
	if err != nil {
		return err
	}
	affected, _ := result.RowsAffected()
	if affected == 0 {
		return errors.New("user not found")
	}
	if banned {
		if _, err = tx.ExecContext(ctx, `UPDATE user_management.auth_sessions SET revoked_at=COALESCE(revoked_at,NOW()),revoked_reason='account_banned' WHERE user_id=$1 AND revoked_at IS NULL`, userID); err != nil {
			return err
		}
	}
	eventType := "admin.user.unbanned"
	if banned {
		eventType = "admin.user.banned"
	}
	if err = insertSecurityEventTx(ctx, tx, eventType, operatorID, "admin", userID, "user_account", userID, map[string]any{"banned": banned, "reason": strings.TrimSpace(reason)}); err != nil {
		return err
	}
	return tx.Commit()
}

func (r *adminRepository) forceVerifyUser(ctx context.Context, operatorID, userID string) error {
	operatorID, userID = strings.TrimSpace(operatorID), strings.TrimSpace(userID)
	if operatorID == "" || userID == "" {
		return errors.New("authenticated operator and user_id are required")
	}
	tx, err := r.pg.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelReadCommitted})
	if err != nil {
		return err
	}
	defer func() { _ = tx.Rollback() }()
	result, err := tx.ExecContext(ctx, `UPDATE user_management.users SET is_verified=TRUE,updated_at=NOW() WHERE id=$1`, userID)
	if err != nil {
		return err
	}
	affected, _ := result.RowsAffected()
	if affected == 0 {
		return errors.New("user not found")
	}
	if _, err = tx.ExecContext(ctx, `INSERT INTO matching.verification_states(user_id,status,submitted_at,reviewed_at,reviewed_by,review_deadline_at,updated_at) VALUES($1,'verified',NOW(),NOW(),$2,NOW(),NOW()) ON CONFLICT(user_id) DO UPDATE SET status='verified',rejection_reason=NULL,reviewed_at=NOW(),reviewed_by=$2,updated_at=NOW()`, userID, operatorID); err != nil {
		return err
	}
	if err = insertSecurityEventTx(ctx, tx, "verification.force_verified", operatorID, "admin", userID, "verification", userID, map[string]any{"status": "verified"}); err != nil {
		return err
	}
	return tx.Commit()
}
