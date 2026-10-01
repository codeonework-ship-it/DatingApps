package mobile

import (
	"context"
	"crypto/sha256"
	"database/sql"
	"errors"
	"net/http"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/go-chi/chi/v5"
	"go.uber.org/zap"
)

// Account recovery assistance (PEN-06 / AUTH-009, migration 082).
//
// A member who lost their recovery code asks for help from the sign-in screen.
// The request never changes credentials. A trust & safety operator verifies
// identity out of band and either declines or issues a single-use recovery
// code that is shown once and expires quickly; issuing it revokes every
// session so recovery cannot revive a revoked session. The member then uses
// the existing password-recovery flow with that code.

const (
	recoveryRequestsPerDay     = 3
	recoveryRequestOpenWindow  = 30 * 24 * time.Hour
	operatorRecoveryCodeTTL    = 72 * time.Hour
	recoveryMemberMessageLimit = 500
)

var (
	errRecoveryRequestNotOpen  = errors.New("recovery request is not open")
	errRecoveryAccountInactive = errors.New("account cannot be recovered: it is erased, pending deletion or disabled")
	errRecoveryInvalidAction   = errors.New("action must be issue_recovery_code or decline")
	errRecoveryIdentityCheck   = errors.New("identity_check must be verified_identity_match, account_detail_match or other")
	errRecoveryNoteRequired    = errors.New("resolution_note must describe the identity check (10-1000 characters)")
)

// requestRecoveryAssistance records a help request. It reports nothing about
// whether the username exists: unknown, erased or rate-limited requests are
// dropped silently and the caller answers the member identically.
func (r *profileRepository) requestRecoveryAssistance(ctx context.Context, username, message string) error {
	if r == nil || r.pg == nil {
		return errors.New("account recovery persistence is unavailable")
	}
	username = strings.ToLower(strings.TrimSpace(username))
	message = strings.TrimSpace(message)
	if utf8.RuneCountInString(message) > recoveryMemberMessageLimit {
		message = string([]rune(message)[:recoveryMemberMessageLimit])
	}
	_, err := r.pg.ExecContext(ctx, `
		INSERT INTO user_management.account_recovery_requests (user_id, member_message)
		SELECT c.user_id, NULLIF($2, '')
		FROM user_management.auth_credentials c
		JOIN user_management.users u ON u.id = c.user_id
		WHERE LOWER(c.username) = $1
		  AND u.erased_at IS NULL
		  AND (SELECT COUNT(*) FROM user_management.account_recovery_requests q
		       WHERE q.user_id = c.user_id AND q.created_at > NOW() - INTERVAL '1 day') < $3`,
		username, message, recoveryRequestsPerDay)
	return err
}

type recoveryRequestView struct {
	ID                 string `json:"id"`
	UserID             string `json:"user_id"`
	Username           string `json:"username"`
	MemberMessage      string `json:"member_message,omitempty"`
	Status             string `json:"status"`
	CreatedAt          string `json:"created_at"`
	IdentityVerified   bool   `json:"identity_verified"`
	AccountRecoverable bool   `json:"account_recoverable"`
	IdentityCheck      string `json:"identity_check,omitempty"`
	ResolvedBy         string `json:"resolved_by,omitempty"`
	ResolvedAt         string `json:"resolved_at,omitempty"`
}

func (r *profileRepository) listRecoveryRequests(ctx context.Context, status string, limit int) ([]recoveryRequestView, error) {
	if r == nil || r.pg == nil {
		return nil, errors.New("account recovery persistence is unavailable")
	}
	if limit <= 0 || limit > 200 {
		limit = 50
	}
	if err := r.expireRecoveryRequests(ctx); err != nil {
		return nil, err
	}
	rows, err := r.pg.QueryContext(ctx, `
		SELECT q.id::text, q.user_id::text, COALESCE(c.username,''), COALESCE(q.member_message,''),
		       q.status, q.created_at,
		       EXISTS(SELECT 1 FROM matching.verification_states v
		              WHERE v.user_id = q.user_id AND v.status = 'verified'),
		       (u.erased_at IS NULL AND u.deletion_effective_at IS NULL
		        AND NOT COALESCE(c.is_disabled, TRUE)),
		       COALESCE(q.identity_check,''), COALESCE(q.resolved_by::text,''), q.resolved_at
		FROM user_management.account_recovery_requests q
		JOIN user_management.users u ON u.id = q.user_id
		LEFT JOIN user_management.auth_credentials c ON c.user_id = q.user_id
		WHERE ($1 = '' OR q.status = $1)
		ORDER BY q.created_at
		LIMIT $2`, strings.TrimSpace(status), limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []recoveryRequestView{}
	for rows.Next() {
		var view recoveryRequestView
		var created time.Time
		var resolved sql.NullTime
		if err := rows.Scan(&view.ID, &view.UserID, &view.Username, &view.MemberMessage, &view.Status,
			&created, &view.IdentityVerified, &view.AccountRecoverable, &view.IdentityCheck,
			&view.ResolvedBy, &resolved); err != nil {
			return nil, err
		}
		view.CreatedAt = created.UTC().Format(time.RFC3339)
		if resolved.Valid {
			view.ResolvedAt = resolved.Time.UTC().Format(time.RFC3339)
		}
		out = append(out, view)
	}
	return out, rows.Err()
}

func (r *profileRepository) expireRecoveryRequests(ctx context.Context) error {
	_, err := r.pg.ExecContext(ctx, `
		UPDATE user_management.account_recovery_requests q
		SET status = 'expired', resolved_at = NOW(), updated_at = NOW()
		FROM platform.retention_policies p
		WHERE p.policy_name = 'open_recovery_requests' AND p.enabled
		  AND q.status = 'open' AND q.created_at < NOW() - p.retention_interval`)
	return err
}

type recoveryResolution struct {
	Status        string
	RecoveryCode  string
	CodeExpiresAt string
	DisplayOnce   bool
}

// resolveRecoveryRequest declines a request or issues a recovery code. Issuing
// replaces every outstanding recovery code and revokes every session in the
// same transaction, and is recorded as a security event.
func (r *profileRepository) resolveRecoveryRequest(
	ctx context.Context,
	requestID, operatorID, operatorRole, action, identityCheck, note string,
) (recoveryResolution, error) {
	if r == nil || r.pg == nil {
		return recoveryResolution{}, errors.New("account recovery persistence is unavailable")
	}
	action = strings.TrimSpace(action)
	identityCheck = strings.TrimSpace(identityCheck)
	note = strings.TrimSpace(note)
	if action != "issue_recovery_code" && action != "decline" {
		return recoveryResolution{}, errRecoveryInvalidAction
	}
	if n := utf8.RuneCountInString(note); n < 10 || n > 1000 {
		return recoveryResolution{}, errRecoveryNoteRequired
	}
	if action == "issue_recovery_code" {
		switch identityCheck {
		case "verified_identity_match", "account_detail_match", "other":
		default:
			return recoveryResolution{}, errRecoveryIdentityCheck
		}
	}

	tx, err := r.pg.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		return recoveryResolution{}, err
	}
	defer func() { _ = tx.Rollback() }()

	var userID, status string
	var created time.Time
	if err = tx.QueryRowContext(ctx, `
		SELECT user_id::text, status, created_at FROM user_management.account_recovery_requests
		WHERE id = $1::uuid FOR UPDATE`, requestID).Scan(&userID, &status, &created); err != nil {
		return recoveryResolution{}, err
	}
	if status != "open" || time.Since(created) > recoveryRequestOpenWindow {
		return recoveryResolution{}, errRecoveryRequestNotOpen
	}

	if action == "decline" {
		if _, err = tx.ExecContext(ctx, `
			UPDATE user_management.account_recovery_requests
			SET status='declined', resolution_note=$2, identity_check=NULLIF($3,''),
			    resolved_by=$4::uuid, resolved_at=NOW(), updated_at=NOW()
			WHERE id=$1::uuid`, requestID, note, identityCheck, operatorID); err != nil {
			return recoveryResolution{}, err
		}
		if err = insertSecurityEventTx(ctx, tx, "auth.recovery_request_declined", operatorID, operatorRole,
			userID, "account_recovery_request", requestID, map[string]any{}); err != nil {
			return recoveryResolution{}, err
		}
		return recoveryResolution{Status: "declined"}, tx.Commit()
	}

	var recoverable bool
	if err = tx.QueryRowContext(ctx, `
		SELECT u.erased_at IS NULL AND u.deletion_effective_at IS NULL AND NOT COALESCE(c.is_disabled, TRUE)
		FROM user_management.users u
		LEFT JOIN user_management.auth_credentials c ON c.user_id = u.id
		WHERE u.id = $1::uuid`, userID).Scan(&recoverable); err != nil {
		return recoveryResolution{}, err
	}
	if !recoverable {
		return recoveryResolution{}, errRecoveryAccountInactive
	}

	code, err := secureRandomToken()
	if err != nil {
		return recoveryResolution{}, err
	}
	hash := sha256.Sum256([]byte(code))
	expiresAt := time.Now().UTC().Add(operatorRecoveryCodeTTL)
	if _, err = tx.ExecContext(ctx, `
		UPDATE user_management.auth_recovery_codes SET used_at=COALESCE(used_at,NOW())
		WHERE user_id=$1::uuid AND used_at IS NULL`, userID); err != nil {
		return recoveryResolution{}, err
	}
	if _, err = tx.ExecContext(ctx, `
		INSERT INTO user_management.auth_recovery_codes(user_id,code_hash,expires_at)
		VALUES($1::uuid,$2,$3)`, userID, hash[:], expiresAt); err != nil {
		return recoveryResolution{}, err
	}
	if _, err = tx.ExecContext(ctx, `
		UPDATE user_management.auth_sessions
		SET revoked_at=COALESCE(revoked_at,NOW()), revoked_reason='operator_assisted_recovery'
		WHERE user_id=$1::uuid AND revoked_at IS NULL`, userID); err != nil {
		return recoveryResolution{}, err
	}
	if _, err = tx.ExecContext(ctx, `
		UPDATE user_management.account_recovery_requests
		SET status='code_issued', identity_check=$2, resolution_note=$3, resolved_by=$4::uuid,
		    resolved_at=NOW(), code_expires_at=$5, updated_at=NOW()
		WHERE id=$1::uuid`, requestID, identityCheck, note, operatorID, expiresAt); err != nil {
		return recoveryResolution{}, err
	}
	if err = insertSecurityEventTx(ctx, tx, "auth.recovery_code_issued_by_operator", operatorID, operatorRole,
		userID, "account_recovery_request", requestID, map[string]any{
			"identity_check":  identityCheck,
			"code_expires_at": expiresAt.Format(time.RFC3339),
		}); err != nil {
		return recoveryResolution{}, err
	}
	if err = tx.Commit(); err != nil {
		return recoveryResolution{}, err
	}
	return recoveryResolution{
		Status: "code_issued", RecoveryCode: code,
		CodeExpiresAt: expiresAt.Format(time.RFC3339), DisplayOnce: true,
	}, nil
}

// requestAccountRecoveryAssistance is public: a member who cannot sign in has
// no session. The answer is the same whatever the username, so the endpoint
// cannot be used to discover accounts.
func (s *Server) requestAccountRecoveryAssistance(w http.ResponseWriter, r *http.Request) {
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	username := strings.TrimSpace(toString(payload["username"]))
	if username == "" || len(username) > 64 {
		writeError(w, http.StatusBadRequest, errors.New("username is required"))
		return
	}
	if s.store == nil || s.store.profileRepo == nil || s.store.profileRepo.pg == nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("account recovery is unavailable"))
		return
	}
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	if err := s.store.profileRepo.requestRecoveryAssistance(ctx, username, toString(payload["message"])); err != nil {
		// Logged, not surfaced: a distinct error would itself reveal something.
		s.log.Error("account_recovery_request_failed", zap.Error(err))
	}
	writeJSON(w, http.StatusAccepted, map[string]any{
		"accepted": true,
		"message": "If this username belongs to a Connect account, our safety team will review the " +
			"request. We never ask for your password. You'll need to confirm your identity before " +
			"a recovery code is issued.",
	})
}

func (s *Server) adminListAccountRecoveryRequests(w http.ResponseWriter, r *http.Request) {
	if err := requireAdminUser(r); err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	if s.store == nil || s.store.profileRepo == nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("account recovery is unavailable"))
		return
	}
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	items, err := s.store.profileRepo.listRecoveryRequests(ctx, r.URL.Query().Get("status"), 100)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"requests": items, "count": len(items)})
}

func (s *Server) adminResolveAccountRecoveryRequest(w http.ResponseWriter, r *http.Request) {
	principal, ok := principalFromRequest(r)
	if !ok {
		writeError(w, http.StatusUnauthorized, errors.New("authenticated operator role is required"))
		return
	}
	payload, valid := readJSON(w, r)
	if !valid {
		return
	}
	action := strings.TrimSpace(toString(payload["action"]))
	role := ""
	switch {
	case principal.Roles["admin"]:
		role = "admin"
	case principal.Roles["trust_safety"]:
		role = "trust_safety"
	case principal.Roles["moderator"] && action == "decline":
		role = "moderator"
	default:
		// Handing out a credential is restricted to trust & safety leads.
		writeError(w, http.StatusForbidden, errors.New("issuing a recovery code requires the trust_safety or admin role"))
		return
	}
	if s.store == nil || s.store.profileRepo == nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("account recovery is unavailable"))
		return
	}
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	result, err := s.store.profileRepo.resolveRecoveryRequest(ctx,
		strings.TrimSpace(chi.URLParam(r, "requestID")), principal.UserID, role, action,
		toString(payload["identity_check"]), toString(payload["resolution_note"]))
	switch {
	case err == nil:
		response := map[string]any{"status": result.Status}
		if result.RecoveryCode != "" {
			response["recovery_code"] = result.RecoveryCode
			response["code_expires_at"] = result.CodeExpiresAt
			response["display_once"] = true
		}
		writeJSON(w, http.StatusOK, response)
	case errors.Is(err, sql.ErrNoRows):
		writeError(w, http.StatusNotFound, errors.New("recovery request not found"))
	case errors.Is(err, errRecoveryRequestNotOpen), errors.Is(err, errRecoveryAccountInactive):
		writeError(w, http.StatusConflict, err)
	case errors.Is(err, errRecoveryInvalidAction), errors.Is(err, errRecoveryIdentityCheck),
		errors.Is(err, errRecoveryNoteRequired):
		writeError(w, http.StatusBadRequest, err)
	default:
		writeError(w, http.StatusBadGateway, err)
	}
}
