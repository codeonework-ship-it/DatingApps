package auth

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"database/sql"
	"encoding/base64"
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
	"go.uber.org/zap"
	"golang.org/x/crypto/bcrypt"

	authdomain "github.com/verified-dating/backend/internal/modules/auth/domain"
	"github.com/verified-dating/backend/internal/platform/config"
	"github.com/verified-dating/backend/internal/platform/postgresdata"
)

const (
	accessTokenLifetime  = 30 * time.Minute
	refreshTokenLifetime = 30 * 24 * time.Hour
	recoveryCodeLifetime = 365 * 24 * time.Hour
	loginFailureWindow   = 15 * time.Minute
	loginLockDuration    = 15 * time.Minute
	maxLoginFailures     = 5
)

type PostgresRepository struct {
	db  *sql.DB
	log *zap.Logger
}

func NewPostgresRepository(cfg config.Config, log *zap.Logger) *PostgresRepository {
	db, err := postgresdata.OpenSQL(cfg.DatabaseURL, postgresdata.Options{
		StatementTimeout:       time.Duration(cfg.PostgresStatementTimeoutMS) * time.Millisecond,
		LockTimeout:            time.Duration(cfg.PostgresLockTimeoutMS) * time.Millisecond,
		IdleTransactionTimeout: time.Duration(cfg.PostgresIdleTransactionTimeoutMS) * time.Millisecond,
		MaxConns:               12,
		MinConns:               4,
	})
	if err != nil {
		log.Error("open_local_postgres_failed", zap.Error(err))
		return &PostgresRepository{log: log}
	}
	return &PostgresRepository{db: db, log: log}
}

func (r *PostgresRepository) Signup(ctx context.Context, username, password string) (map[string]any, error) {
	return r.signup(ctx, username, password, "", "")
}
func (r *PostgresRepository) SignupIntroducer(ctx context.Context, username, password, name, dob string) (map[string]any, error) {
	name = strings.TrimSpace(name)
	birthday, err := time.Parse("2006-01-02", dob)
	now := time.Now().UTC()
	today := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, time.UTC)
	if len([]rune(name)) < 2 || len([]rune(name)) > 80 || err != nil || birthday.After(today.AddDate(-18, 0, 0)) || !birthday.After(today.AddDate(-81, 0, 0)) {
		return map[string]any{"success": false, "error": "provide a name and date of birth for an adult aged 18–80"}, nil
	}
	return r.signup(ctx, username, password, name, dob)
}
func (r *PostgresRepository) signup(ctx context.Context, username, password, introducerName, dob string) (map[string]any, error) {
	identity, validationErr := authdomain.NewUsername(username)
	if validationErr != nil {
		return map[string]any{"success": false, "error": "username must be 3-30 characters using letters, numbers, _ or . and start and end with a letter or number"}, nil
	}
	username = identity.Value()
	if r.db == nil {
		return nil, errors.New("local postgres auth is not configured")
	}
	if len(password) < 8 || !hasLetterAndDigit(password) {
		return map[string]any{"success": false, "error": "password must be at least 8 characters with letters and numbers"}, nil
	}

	passwordHash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return nil, err
	}
	userID := uuid.NewString()
	tx, err := r.db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		return nil, err
	}
	defer func() { _ = tx.Rollback() }()

	var existing bool
	if err = tx.QueryRowContext(ctx,
		`SELECT EXISTS (SELECT 1 FROM user_management.auth_credentials WHERE LOWER(username) = LOWER($1))`,
		username,
	).Scan(&existing); err != nil {
		return nil, err
	}
	if existing {
		return map[string]any{"success": false, "error": "username is already taken"}, nil
	}
	if _, err = tx.ExecContext(ctx, `
		INSERT INTO user_management.auth_credentials (user_id, username, password_hash)
		VALUES ($1, $2, $3)`, userID, username, string(passwordHash)); err != nil {
		if strings.Contains(strings.ToLower(err.Error()), "unique") {
			return map[string]any{"success": false, "error": "username is already taken"}, nil
		}
		return nil, err
	}
	if _, err = tx.ExecContext(ctx, `
		INSERT INTO user_management.signup_workflows (user_id, username)
		VALUES ($1, $2)`, userID, username); err != nil {
		return nil, err
	}
	if _, err = tx.ExecContext(ctx, `
		INSERT INTO user_management.signup_workflow_activities
		  (user_id, activity, status, idempotency_key, payload)
		VALUES ($1, 'create_credentials', 'completed', 'create_credentials', jsonb_build_object('username', $2::text))`,
		userID, username); err != nil {
		return nil, err
	}
	state, activity := "credentials_created", "bootstrap_profile"
	if introducerName != "" {
		if _, err = tx.ExecContext(ctx, `INSERT INTO user_management.users(id,username,name,date_of_birth,gender,account_kind,profile_completion)
   VALUES($1,$2,$3,$4::date,NULL,'introducer',0)`, userID, username, introducerName, dob); err != nil {
			return nil, err
		}
		state, activity = "basics_captured", "accept_terms"
		if _, err = tx.ExecContext(ctx, `UPDATE user_management.signup_workflows SET state=$2,current_activity=$3,basics_captured_at=NOW() WHERE user_id=$1`, userID, state, activity); err != nil {
			return nil, err
		}
	}
	result, err := issueSession(ctx, tx, userID, state, activity)
	if err != nil {
		return nil, err
	}
	recoveryCode, err := randomToken()
	if err != nil {
		return nil, err
	}
	recoveryHash := sha256.Sum256([]byte(recoveryCode))
	if _, err = tx.ExecContext(ctx, `
		INSERT INTO user_management.auth_recovery_codes (user_id, code_hash, expires_at)
		VALUES ($1, $2, $3)`, userID, recoveryHash[:], time.Now().Add(recoveryCodeLifetime)); err != nil {
		return nil, err
	}
	if _, err = tx.ExecContext(ctx, `
		INSERT INTO user_management.auth_account_roles (user_id, role)
		VALUES ($1, 'user') ON CONFLICT DO NOTHING`, userID); err != nil {
		return nil, err
	}
	result["recovery_code"] = recoveryCode
	if err = tx.Commit(); err != nil {
		return nil, err
	}
	return result, nil
}

func (r *PostgresRepository) Login(ctx context.Context, username, password string) (map[string]any, error) {
	username = strings.ToLower(strings.TrimSpace(username))
	if r.db == nil {
		return nil, errors.New("local postgres auth is not configured")
	}
	var userID, passwordHash, workflowState, currentActivity string
	var disabled bool
	var failedCount int
	var failedWindow, lockedUntil sql.NullTime
	err := r.db.QueryRowContext(ctx, `
		SELECT c.user_id::text, c.password_hash, c.is_disabled, c.failed_login_count,
		       c.failed_login_window_started_at, c.locked_until, w.state, w.current_activity
		FROM user_management.auth_credentials c
		JOIN user_management.signup_workflows w ON w.user_id = c.user_id
		JOIN user_management.users u ON u.id=c.user_id
		WHERE LOWER(c.username) = LOWER($1)`, username,
	).Scan(&userID, &passwordHash, &disabled, &failedCount, &failedWindow, &lockedUntil, &workflowState, &currentActivity)
	if errors.Is(err, sql.ErrNoRows) || disabled {
		return map[string]any{"success": false, "error": "invalid username or password"}, nil
	}
	if err != nil {
		return nil, err
	}
	var accountAllowed bool
	if err = r.db.QueryRowContext(ctx, `SELECT is_active AND NOT is_banned AND (suspended_at IS NULL OR (suspended_until IS NOT NULL AND suspended_until<=NOW())) FROM user_management.users WHERE id=$1`, userID).Scan(&accountAllowed); err != nil || !accountAllowed {
		return map[string]any{"success": false, "error": "account is suspended or banned"}, nil
	}
	if lockedUntil.Valid && lockedUntil.Time.After(time.Now()) {
		return map[string]any{"success": false, "error": "account temporarily locked; try again later"}, nil
	}
	if bcrypt.CompareHashAndPassword([]byte(passwordHash), []byte(password)) != nil {
		now := time.Now()
		if !failedWindow.Valid || now.Sub(failedWindow.Time) > loginFailureWindow {
			failedCount = 0
			failedWindow = sql.NullTime{Time: now, Valid: true}
		}
		failedCount++
		var nextLockedUntil any
		if failedCount >= maxLoginFailures {
			nextLockedUntil = now.Add(loginLockDuration)
		}
		_, _ = r.db.ExecContext(ctx, `
			UPDATE user_management.auth_credentials
			SET failed_login_count = $2, failed_login_window_started_at = $3,
			    locked_until = $4, updated_at = NOW()
			WHERE user_id = $1`, userID, failedCount, failedWindow.Time, nextLockedUntil)
		return map[string]any{"success": false, "error": "invalid username or password"}, nil
	}

	tx, err := r.db.BeginTx(ctx, nil)
	if err != nil {
		return nil, err
	}
	defer func() { _ = tx.Rollback() }()
	if _, err = tx.ExecContext(ctx, `
		UPDATE user_management.auth_credentials
		SET failed_login_count = 0, failed_login_window_started_at = NULL,
		    locked_until = NULL, last_login_at = NOW(), updated_at = NOW()
		WHERE user_id = $1`, userID); err != nil {
		return nil, err
	}
	result, err := issueSession(ctx, tx, userID, workflowState, currentActivity)
	if err != nil {
		return nil, err
	}
	if err = tx.Commit(); err != nil {
		return nil, err
	}
	return result, nil
}

func issueSession(ctx context.Context, tx *sql.Tx, userID, workflowState, currentActivity string) (map[string]any, error) {
	accessToken, err := randomToken()
	if err != nil {
		return nil, err
	}
	refreshToken, err := randomToken()
	if err != nil {
		return nil, err
	}
	accessHash := sha256.Sum256([]byte(accessToken))
	refreshHash := sha256.Sum256([]byte(refreshToken))
	if _, err = tx.ExecContext(ctx, `
		INSERT INTO user_management.auth_sessions
		  (user_id, access_token_hash, refresh_token_hash, access_expires_at, refresh_expires_at)
		VALUES ($1, $2, $3, $4, $5)`,
		userID, accessHash[:], refreshHash[:], time.Now().Add(accessTokenLifetime), time.Now().Add(refreshTokenLifetime)); err != nil {
		return nil, err
	}
	var accountKind string
	if err := tx.QueryRowContext(ctx, `SELECT COALESCE((SELECT account_kind FROM user_management.users WHERE id=$1),'dating')`, userID).Scan(&accountKind); err != nil {
		return nil, err
	}
	return map[string]any{
		"account_kind":     accountKind,
		"success":          true,
		"user_id":          userID,
		"access_token":     accessToken,
		"refresh_token":    refreshToken,
		"expires_in":       int(accessTokenLifetime.Seconds()),
		"workflow_state":   workflowState,
		"current_activity": currentActivity,
		"signup_required":  workflowState != "completed",
	}, nil
}

func randomToken() (string, error) {
	raw := make([]byte, 32)
	if _, err := rand.Read(raw); err != nil {
		return "", err
	}
	return base64.RawURLEncoding.EncodeToString(raw), nil
}

func hasLetterAndDigit(value string) bool {
	hasLetter, hasDigit := false, false
	for _, char := range value {
		switch {
		case char >= 'a' && char <= 'z', char >= 'A' && char <= 'Z':
			hasLetter = true
		case char >= '0' && char <= '9':
			hasDigit = true
		}
	}
	return hasLetter && hasDigit
}
