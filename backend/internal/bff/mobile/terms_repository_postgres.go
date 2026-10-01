package mobile

import (
	"context"
	"database/sql"
	"errors"
	"strings"
	"time"
)

func (r *termsAgreementRepository) getAgreementPostgres(ctx context.Context, userID string) (termsAgreementRecord, error) {
	var accepted bool
	var acceptedAt sql.NullTime
	var termsVersion sql.NullString
	err := r.pg.QueryRowContext(ctx, `
		SELECT terms_accepted, terms_accepted_at, terms_version
		FROM user_management.users WHERE id=$1`, userID,
	).Scan(&accepted, &acceptedAt, &termsVersion)
	if errors.Is(err, sql.ErrNoRows) {
		return defaultTermsAgreementRecord(userID), nil
	}
	if err != nil {
		return termsAgreementRecord{}, err
	}
	record := termsAgreementRecord{UserID: userID, Accepted: accepted, TermsVersion: termsVersion.String,
		PersistedInDB: true, PersistenceMode: "postgres"}
	if acceptedAt.Valid {
		record.AcceptedAt = acceptedAt.Time.UTC().Format(time.RFC3339)
	}
	return record, nil
}

func (r *termsAgreementRepository) updateAgreementPostgres(ctx context.Context, userID string, accepted bool, termsVersion string) (termsAgreementRecord, error) {
	version := strings.TrimSpace(termsVersion)
	if version == "" {
		version = "v1"
	}
	tx, err := r.pg.BeginTx(ctx, nil)
	if err != nil {
		return termsAgreementRecord{}, err
	}
	defer func() { _ = tx.Rollback() }()
	var acceptedAt sql.NullTime
	if err = tx.QueryRowContext(ctx, `
		UPDATE user_management.users
		SET terms_accepted=$2, terms_version=$3,
		    terms_accepted_at=CASE WHEN $2 THEN COALESCE(terms_accepted_at,NOW()) ELSE NULL END,
		    updated_at=NOW()
		WHERE id=$1 RETURNING terms_accepted_at`, userID, accepted, version,
	).Scan(&acceptedAt); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return termsAgreementRecord{}, errors.New("signup profile must be bootstrapped before accepting terms")
		}
		return termsAgreementRecord{}, err
	}
	if accepted {
		if _, err = tx.ExecContext(ctx, `
			UPDATE user_management.signup_workflows
			SET state=CASE WHEN EXISTS(SELECT 1 FROM user_management.users WHERE id=$1 AND account_kind='introducer') THEN 'completed' ELSE 'terms_accepted' END,
 current_activity=CASE WHEN EXISTS(SELECT 1 FROM user_management.users WHERE id=$1 AND account_kind='introducer') THEN 'done' ELSE 'build_profile' END,
 completed_at=CASE WHEN EXISTS(SELECT 1 FROM user_management.users WHERE id=$1 AND account_kind='introducer') THEN NOW() ELSE completed_at END,
			    terms_accepted_at=COALESCE(terms_accepted_at,NOW()),
			    lock_version=lock_version+1, updated_at=NOW()
			WHERE user_id=$1 AND state IN ('basics_captured','terms_accepted')`, userID); err != nil {
			return termsAgreementRecord{}, err
		}
		if _, err = tx.ExecContext(ctx, `
			INSERT INTO user_management.signup_workflow_activities
			  (user_id,activity,status,idempotency_key,payload)
			VALUES ($1,'accept_terms','completed','accept_terms',jsonb_build_object('terms_version',$2::text))
			ON CONFLICT (user_id,idempotency_key) WHERE idempotency_key IS NOT NULL DO NOTHING`, userID, version); err != nil {
			return termsAgreementRecord{}, err
		}
	}
	if err = tx.Commit(); err != nil {
		return termsAgreementRecord{}, err
	}
	record := termsAgreementRecord{UserID: userID, Accepted: accepted, TermsVersion: version,
		UpdatedAt: time.Now().UTC().Format(time.RFC3339), PersistedInDB: true, PersistenceMode: "postgres"}
	if acceptedAt.Valid {
		record.AcceptedAt = acceptedAt.Time.UTC().Format(time.RFC3339)
	}
	return record, nil
}
