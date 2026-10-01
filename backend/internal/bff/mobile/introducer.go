package mobile

import (
	"context"
	"crypto/sha256"
	"database/sql"
	"errors"
	"net/http"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)

var errIntroducerConsent = errors.New("this invitation or permission is unavailable; ask your friend for a new invitation")

// This allowlist is independent of client navigation and is checked against the
// account kind resolved from the durable session, never a request field.
func introducerRouteAllowed(prefix, method, path string, p securityPrincipal) bool {
	path = strings.TrimPrefix(path, prefix)
	if path == "/auth/logout" || path == "/auth/sessions/revoke" || path == "/auth/password/change" || path == "/auth/recovery-code/rotate" {
		return method == http.MethodPost
	}
	if path == "/users/"+p.UserID+"/agreements/terms" {
		return method == http.MethodGet || method == http.MethodPatch
	}
	if path == "/settings/"+p.UserID {
		return method == http.MethodGet || method == http.MethodPatch
	}
	for _, suffix := range []string{"lifecycle", "deactivate", "reactivate", "deletion", "export"} {
		if path == "/account/"+p.UserID+"/"+suffix {
			return true
		}
	}
	if path == "/config/flags" || path == "/operations/status" {
		return method == http.MethodGet
	}
	if !p.TermsAccepted {
		return false
	}
	if path == "/introducer/connections" {
		return method == http.MethodGet
	}
	if path == "/introducer/redeem" {
		return method == http.MethodPost
	}
	if strings.HasPrefix(path, "/introducer/connections/") {
		return method == http.MethodDelete
	}
	if path == "/friends/"+p.UserID+"/intros" {
		return method == http.MethodGet || method == http.MethodPost
	}
	return false
}

type introducerConnection struct {
	ID         string `json:"id"`
	UserID     string `json:"user_id"`
	Name       string `json:"name"`
	Status     string `json:"status"`
	SharePhoto bool   `json:"share_photo"`
	ShareCity  bool   `json:"share_city"`
}

type introducerInvite struct {
	Code      string `json:"code"`
	ExpiresAt string `json:"expires_at"`
}

func (s *friendSocialService) createIntroducerInvite(ctx context.Context, member string, photo, city bool) (introducerInvite, error) {
	token, err := secureRandomToken()
	if err != nil {
		return introducerInvite{}, err
	}
	hash := sha256.Sum256([]byte(token))
	tx, err := s.db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		return introducerInvite{}, err
	}
	defer tx.Rollback()
	var kind string
	if err = tx.QueryRowContext(ctx, `SELECT account_kind FROM user_management.users WHERE id=$1 AND is_active AND NOT is_banned AND terms_accepted AND deactivated_at IS NULL AND deletion_requested_at IS NULL AND erased_at IS NULL FOR UPDATE`, member).Scan(&kind); err != nil {
		return introducerInvite{}, errIntroducerConsent
	}
	if kind != "dating" {
		return introducerInvite{}, errIntroducerConsent
	}
	var count int
	if err = tx.QueryRowContext(ctx, `SELECT count(*) FROM matching.introducer_invites WHERE member_user_id=$1 AND created_at>NOW()-INTERVAL '1 day'`, member).Scan(&count); err != nil {
		return introducerInvite{}, err
	}
	if count >= 10 {
		return introducerInvite{}, errors.New("invitation limit reached; try again tomorrow")
	}
	if _, err = tx.ExecContext(ctx, `UPDATE matching.introducer_invites SET revoked_at=NOW() WHERE member_user_id=$1 AND revoked_at IS NULL AND consumed_at IS NULL`, member); err != nil {
		return introducerInvite{}, err
	}
	var expires time.Time
	if err = tx.QueryRowContext(ctx, `INSERT INTO matching.introducer_invites(member_user_id,token_hash,share_photo,share_city) VALUES($1,$2,$3,$4) RETURNING expires_at`, member, hash[:], photo, city).Scan(&expires); err != nil {
		return introducerInvite{}, err
	}
	return introducerInvite{token, expires.UTC().Format(time.RFC3339)}, tx.Commit()
}

func (s *friendSocialService) redeemIntroducerInvite(ctx context.Context, actor, code string) error {
	code = strings.TrimSpace(code)
	if len(code) != 43 {
		return errIntroducerConsent
	}
	hash := sha256.Sum256([]byte(code))
	tx, err := s.db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		return err
	}
	defer tx.Rollback()
	var kind string
	if err = tx.QueryRowContext(ctx, `SELECT account_kind FROM user_management.users WHERE id=$1 AND is_active AND NOT is_banned AND terms_accepted AND deactivated_at IS NULL AND deletion_requested_at IS NULL AND erased_at IS NULL FOR UPDATE`, actor).Scan(&kind); err != nil || kind != "introducer" {
		return errIntroducerConsent
	}
	var id, member string
	var consumed sql.NullString
	var revoked sql.NullTime
	var expires time.Time
	var photo, city bool
	err = tx.QueryRowContext(ctx, `SELECT id::text,member_user_id::text,consumed_by::text,revoked_at,expires_at,share_photo,share_city FROM matching.introducer_invites WHERE token_hash=$1 FOR UPDATE`, hash[:]).Scan(&id, &member, &consumed, &revoked, &expires, &photo, &city)
	if err != nil || member == actor || revoked.Valid {
		return errIntroducerConsent
	}
	if consumed.Valid {
		if consumed.String != actor {
			return errIntroducerConsent
		}
		var live bool
		err = tx.QueryRowContext(ctx, `SELECT EXISTS(SELECT 1 FROM matching.introducer_consents WHERE introducer_user_id=$1 AND member_user_id=$2 AND revoked_at IS NULL)`, actor, member).Scan(&live)
		if err != nil {
			return err
		}
		if !live {
			return errIntroducerConsent
		}
		return tx.Commit()
	}
	if !expires.After(s.now()) {
		return errIntroducerConsent
	}
	var available bool
	if err = tx.QueryRowContext(ctx, `SELECT EXISTS(SELECT 1 FROM user_management.users m WHERE m.id=$2 AND m.account_kind='dating' AND m.is_active AND NOT m.is_banned AND m.erased_at IS NULL AND m.deactivated_at IS NULL AND m.deletion_requested_at IS NULL
 AND (m.suspended_at IS NULL OR (m.suspended_until IS NOT NULL AND m.suspended_until<=NOW()))
 AND NOT EXISTS(SELECT 1 FROM user_management.blocked_users WHERE (user_id=$1 AND blocked_user_id=$2) OR (user_id=$2 AND blocked_user_id=$1)))`, actor, member).Scan(&available); err != nil {
		return err
	}
	if !available {
		return errIntroducerConsent
	}
	var count int
	if err = tx.QueryRowContext(ctx, `SELECT count(*) FROM matching.introducer_consents WHERE introducer_user_id=$1 AND revoked_at IS NULL`, actor).Scan(&count); err != nil {
		return err
	}
	if count >= 20 {
		return errors.New("your introduction circle is full")
	}
	// A redeemed code requests permission. The member must still approve the
	// named introducer before they can make an introduction.
	var consentID, consentStatus string
	if err = tx.QueryRowContext(ctx, `INSERT INTO matching.introducer_consents(introducer_user_id,member_user_id,share_photo,share_city)
 VALUES($1,$2,$3,$4) ON CONFLICT(introducer_user_id,member_user_id) DO UPDATE SET
 status=CASE WHEN matching.introducer_consents.revoked_at IS NOT NULL THEN 'pending' ELSE matching.introducer_consents.status END,
 revoked_at=NULL,share_photo=EXCLUDED.share_photo,share_city=EXCLUDED.share_city,updated_at=NOW() RETURNING id::text,status`, actor, member, photo, city).Scan(&consentID, &consentStatus); err != nil {
		return err
	}
	if consentStatus == "pending" {
		if err = enqueueNotificationTx(ctx, tx, member, actor, "introducer.permission_requested", "friend_plan", consentID,
			"introducer-permission:"+id, memberName(ctx, tx, actor, "A friend")+" would like to introduce you",
			"Review their request in Your introducers. Nothing is shared until you approve.", "/friends",
			map[string]any{"consent_id": consentID}, 5); err != nil {
			return err
		}
	}

	if _, err = tx.ExecContext(ctx, `UPDATE matching.introducer_invites SET consumed_by=$2,consumed_at=NOW() WHERE id=$1`, id, actor); err != nil {
		return err
	}
	return tx.Commit()
}

func (s *friendSocialService) introducerConnections(ctx context.Context, actor string) ([]introducerConnection, error) {
	rows, err := s.db.QueryContext(ctx, `SELECT c.id::text,u.id::text,COALESCE(NULLIF(u.name,''),'A friend'),
 CASE WHEN c.status='pending' THEN 'pending' WHEN COALESCE(p.allow_friend_intros,FALSE) THEN 'active' ELSE 'paused' END,
 c.share_photo,c.share_city
 FROM matching.introducer_consents c
 JOIN user_management.users u ON u.id=CASE WHEN c.introducer_user_id=$1 THEN c.member_user_id ELSE c.introducer_user_id END
 LEFT JOIN matching.dating_preferences p ON p.user_id=c.member_user_id
 WHERE (c.member_user_id=$1 OR c.introducer_user_id=$1) AND c.revoked_at IS NULL
 AND u.is_active AND NOT u.is_banned AND u.deactivated_at IS NULL AND u.deletion_requested_at IS NULL AND u.erased_at IS NULL
 AND (u.suspended_at IS NULL OR (u.suspended_until IS NOT NULL AND u.suspended_until<=NOW()))
 AND NOT EXISTS(SELECT 1 FROM user_management.blocked_users b WHERE (b.user_id=$1 AND b.blocked_user_id=u.id) OR (b.user_id=u.id AND b.blocked_user_id=$1))
 ORDER BY c.created_at,c.id`, actor)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []introducerConnection{}
	for rows.Next() {
		var c introducerConnection
		if err = rows.Scan(&c.ID, &c.UserID, &c.Name, &c.Status, &c.SharePhoto, &c.ShareCity); err != nil {
			return nil, err
		}
		out = append(out, c)
	}
	return out, rows.Err()
}

func (s *friendSocialService) changeIntroducerConsent(ctx context.Context, actor, id string, approve bool) error {
	if _, err := uuid.Parse(id); err != nil {
		return errIntroducerConsent
	}
	tx, err := s.db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		return err
	}
	defer tx.Rollback()
	var introducer, member, status string
	var revoked sql.NullTime
	if err = tx.QueryRowContext(ctx, `SELECT introducer_user_id::text,member_user_id::text,status,revoked_at FROM matching.introducer_consents WHERE id=$1`, id).Scan(&introducer, &member, &status, &revoked); err != nil {
		return errIntroducerConsent
	}
	if actor != member && (approve || actor != introducer) {
		return errIntroducerConsent
	}
	if _, err = tx.ExecContext(ctx, `SELECT id FROM user_management.users WHERE id=$1 FOR UPDATE`, introducer); err != nil {
		return err
	}
	if approve {
		if revoked.Valid {
			return errIntroducerConsent
		}
		if status == "active" {
			return tx.Commit()
		}
		var blocked bool
		if err = tx.QueryRowContext(ctx, `SELECT EXISTS(SELECT 1 FROM user_management.blocked_users WHERE (user_id=$1 AND blocked_user_id=$2) OR (user_id=$2 AND blocked_user_id=$1))`, member, introducer).Scan(&blocked); err != nil {
			return err
		}
		if blocked {
			return errIntroducerConsent
		}
		if _, err = tx.ExecContext(ctx, `UPDATE matching.introducer_consents SET status='active',updated_at=NOW() WHERE id=$1 AND revoked_at IS NULL`, id); err != nil {
			return err
		}
		if _, err = tx.ExecContext(ctx, `INSERT INTO matching.dating_preferences(user_id,allow_friend_intros) VALUES($1,TRUE) ON CONFLICT(user_id) DO UPDATE SET allow_friend_intros=TRUE,version=matching.dating_preferences.version+1,updated_at=NOW()`, member); err != nil {
			return err
		}
	} else {
		if _, err = tx.ExecContext(ctx, `UPDATE matching.introducer_consents SET revoked_at=COALESCE(revoked_at,NOW()),updated_at=NOW() WHERE id=$1`, id); err != nil {
			return err
		}
		if _, err = tx.ExecContext(ctx, `UPDATE matching.friend_intros SET status='expired' WHERE introducer_user_id=$1 AND (first_user_id=$2 OR second_user_id=$2) AND status='open'`, introducer, member); err != nil {
			return err
		}
	}
	return tx.Commit()
}

func (s *Server) introducerHandler(w http.ResponseWriter, r *http.Request) {
	p, err := requestPrincipal(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	svc, err := s.friendSocial()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	// Deletion remains available when the rollout flag is disabled.
	path := strings.TrimPrefix(r.URL.Path, s.cfg.APIPrefix)
	if r.Method != http.MethodDelete && r.Method != http.MethodGet {
		enabled, e := s.runtimeFeatureEnabled(r.Context(), "friend_intros_enabled", false)
		if e != nil || !enabled || s.cfg.IsReleaseExcluded("friend_intros_enabled") {
			writeError(w, http.StatusForbidden, errors.New("friend introductions are unavailable"))
			return
		}
	}
	result := map[string]any{"success": true}
	switch {
	case r.Method == http.MethodGet:
		var connections []introducerConnection
		connections, err = svc.introducerConnections(r.Context(), p.UserID)
		result = map[string]any{"connections": connections}
	case path == "/introducer/invites" && r.Method == http.MethodDelete:
		_, err = svc.db.ExecContext(r.Context(), `UPDATE matching.introducer_invites SET revoked_at=NOW() WHERE member_user_id=$1 AND consumed_at IS NULL AND revoked_at IS NULL`, p.UserID)
	case path == "/introducer/invites":
		data, ok := readJSON(w, r)
		if !ok {
			return
		}
		photo, _ := data["share_photo"].(bool)
		city, _ := data["share_city"].(bool)
		var invite introducerInvite
		invite, err = svc.createIntroducerInvite(r.Context(), p.UserID, photo, city)
		result = map[string]any{"code": invite.Code, "expires_at": invite.ExpiresAt}
	case path == "/introducer/redeem":
		data, ok := readJSON(w, r)
		if !ok {
			return
		}
		err = svc.redeemIntroducerInvite(r.Context(), p.UserID, toString(data["code"]))
	default:
		err = svc.changeIntroducerConsent(r.Context(), p.UserID, chi.URLParam(r, "consentID"), r.Method == http.MethodPost)
	}
	if err != nil {
		if errors.Is(err, errIntroducerConsent) {
			writeError(w, http.StatusConflict, err)
			return
		}
		if strings.Contains(err.Error(), "limit reached") || strings.Contains(err.Error(), "circle is full") {
			writeError(w, http.StatusTooManyRequests, err)
			return
		}
		writeError(w, http.StatusServiceUnavailable, errors.New("could not update introduction permissions; refresh and try again"))
		return
	}
	writeJSON(w, http.StatusOK, result)
}
