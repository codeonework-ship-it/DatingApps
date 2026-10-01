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

// Deletion is deferred, not immediate.
//
// An account erased on the instant of a tap cannot be recovered from a misclick
// or from a request made under pressure, and the member has no way back. The
// grace window is the recovery path.
const (
	accountDeletionGraceDays = 14
	accountExportRetention   = 7 * 24 * time.Hour
)

type accountLifecycleState struct {
	UserID              string `json:"user_id"`
	IsActive            bool   `json:"is_active"`
	Deactivated         bool   `json:"deactivated"`
	DeactivatedAt       string `json:"deactivated_at,omitempty"`
	DeletionRequestedAt string `json:"deletion_requested_at,omitempty"`
	DeletionEffectiveAt string `json:"deletion_effective_at,omitempty"`
	DeletionCancellable bool   `json:"deletion_cancellable"`
	ExportReady         bool   `json:"export_ready"`
	ExportExpiresAt     string `json:"export_expires_at,omitempty"`
}

func timeText(value sql.NullTime) string {
	if !value.Valid {
		return ""
	}
	return value.Time.UTC().Format(time.RFC3339)
}

// recordLifecycleEvent appends to the immutable security log.
//
// Deactivation, deletion and export are exactly the actions a member may later
// dispute, so each one is attributed and written to the append-only table
// rather than inferred from the mutable request row.
func recordLifecycleEvent(
	ctx context.Context,
	tx *sql.Tx,
	eventType, actorID, actorRole, subjectID, resourceID string,
	payload map[string]any,
) error {
	encoded, err := json.Marshal(payload)
	if err != nil {
		return err
	}
	_, err = tx.ExecContext(ctx, `
		INSERT INTO audit.security_events
		  (event_type,actor_user_id,actor_role,subject_user_id,
		   resource_type,resource_id,payload)
		VALUES ($1,NULLIF($2,'')::uuid,$3,NULLIF($4,'')::uuid,'account',$5,$6::jsonb)`,
		eventType, actorID, actorRole, subjectID, resourceID, encoded)
	return err
}

func (r *profileRepository) accountLifecycleState(
	ctx context.Context,
	userID string,
) (accountLifecycleState, error) {
	if r.pg == nil {
		return accountLifecycleState{}, errors.New("account lifecycle persistence is unavailable")
	}
	state := accountLifecycleState{UserID: userID}
	var deactivated, requested, effective sql.NullTime
	err := r.pg.QueryRowContext(ctx, `
		SELECT is_active,deactivated_at,deletion_requested_at,deletion_effective_at
		FROM user_management.users WHERE id=$1::uuid`, userID).
		Scan(&state.IsActive, &deactivated, &requested, &effective)
	if err != nil {
		return accountLifecycleState{}, err
	}
	// Reported separately from is_active so a caller can tell an
	// operator-disabled account from one the member paused themselves.
	state.Deactivated = deactivated.Valid
	state.DeactivatedAt = timeText(deactivated)
	state.DeletionRequestedAt = timeText(requested)
	state.DeletionEffectiveAt = timeText(effective)
	state.DeletionCancellable = effective.Valid && effective.Time.After(time.Now())

	var expires sql.NullTime
	err = r.pg.QueryRowContext(ctx, `
		SELECT export_expires_at
		FROM user_management.account_lifecycle_requests
		WHERE user_id=$1::uuid AND request_type='export' AND status='completed'
		  AND export_payload IS NOT NULL
		  AND (export_expires_at IS NULL OR export_expires_at > NOW())
		ORDER BY requested_at DESC LIMIT 1`, userID).Scan(&expires)
	switch {
	case errors.Is(err, sql.ErrNoRows):
	case err != nil:
		return accountLifecycleState{}, err
	default:
		state.ExportReady = true
		state.ExportExpiresAt = timeText(expires)
	}
	return state, nil
}

// setAccountActivation deactivates or reactivates an account.
//
// Visibility is withdrawn through `deactivated_at`, deliberately not through
// `is_active`. `is_active` already means "the platform has enabled this
// account": both the login check and the bearer-session check reject a member
// without it. Reusing it for a self-service pause locked the member out of the
// only endpoint that could undo the pause — deactivation was advertised as
// reversible and was in fact a one-way trip needing operator help.
//
// Sessions are left intact for the same reason. A member who paused their
// account must still be able to reach in and unpause it.
func (r *profileRepository) setAccountActivation(
	ctx context.Context,
	userID, actorID, reason string,
	active bool,
) (accountLifecycleState, error) {
	if r.pg == nil {
		return accountLifecycleState{}, errors.New("account lifecycle persistence is unavailable")
	}
	tx, err := r.pg.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		return accountLifecycleState{}, err
	}
	defer func() { _ = tx.Rollback() }()

	var banned bool
	var deletionEffective sql.NullTime
	if err = tx.QueryRowContext(ctx, `
		SELECT is_banned,deletion_effective_at FROM user_management.users
		WHERE id=$1::uuid FOR UPDATE`, userID).Scan(&banned, &deletionEffective); err != nil {
		return accountLifecycleState{}, err
	}
	// Reactivating out of a ban would let a member undo an enforcement action
	// against them. Enforcement outranks self-service.
	if active && banned {
		return accountLifecycleState{}, errors.New("a banned account cannot be reactivated by its member")
	}
	if active && deletionEffective.Valid {
		return accountLifecycleState{}, errors.New("cancel the pending deletion before reactivating")
	}

	requestType := "deactivate"
	if active {
		requestType = "reactivate"
		_, err = tx.ExecContext(ctx, `
			UPDATE user_management.users
			SET deactivated_at=NULL,updated_at=NOW()
			WHERE id=$1::uuid`, userID)
	} else {
		_, err = tx.ExecContext(ctx, `
			UPDATE user_management.users
			SET deactivated_at=COALESCE(deactivated_at,NOW()),updated_at=NOW()
			WHERE id=$1::uuid`, userID)
	}
	if err != nil {
		return accountLifecycleState{}, err
	}

	var requestID string
	if err = tx.QueryRowContext(ctx, `
		INSERT INTO user_management.account_lifecycle_requests
		  (user_id,request_type,status,completed_at,reason,actor_user_id,actor_role)
		VALUES ($1::uuid,$2,'completed',NOW(),NULLIF($3,''),NULLIF($4,'')::uuid,'member')
		RETURNING id::text`, userID, requestType, reason, actorID).Scan(&requestID); err != nil {
		return accountLifecycleState{}, err
	}
	if err = recordLifecycleEvent(ctx, tx, "account."+requestType, actorID, "member",
		userID, requestID, map[string]any{"reason": reason}); err != nil {
		return accountLifecycleState{}, err
	}
	if err = tx.Commit(); err != nil {
		return accountLifecycleState{}, err
	}
	return r.accountLifecycleState(ctx, userID)
}

// requestAccountDeletion schedules erasure after the grace window.
//
// The member disappears from the product immediately and the data stays
// recoverable until the window closes. Access is deliberately retained: a
// grace period the member cannot sign in to use is not a grace period.
// errOperatorDeletionNotCancellable stops a member from withdrawing a
// deletion the safety team scheduled.
var errOperatorDeletionNotCancellable = errors.New("this deletion was scheduled by the Connect team and cannot be cancelled from the app")

func (r *profileRepository) requestAccountDeletion(
	ctx context.Context,
	userID, actorID, reason string,
) (accountLifecycleState, error) {
	return r.scheduleAccountDeletion(ctx, userID, actorID, "member", reason)
}

// scheduleAccountDeletion starts the standard erasure journey: deactivate now,
// erase after the grace window. Operator removals use the same path so the
// member's media, audit history and SOS data are erased exactly as for a
// self-service deletion, and so an operator mistake stays recoverable for the
// grace window. An operator removal also revokes every session immediately.
func (r *profileRepository) scheduleAccountDeletion(
	ctx context.Context,
	userID, actorID, actorRole, reason string,
) (accountLifecycleState, error) {
	if actorRole != "member" && actorRole != "operator" {
		return accountLifecycleState{}, fmt.Errorf("unsupported deletion actor role %q", actorRole)
	}
	if r.pg == nil {
		return accountLifecycleState{}, errors.New("account lifecycle persistence is unavailable")
	}
	tx, err := r.pg.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		return accountLifecycleState{}, err
	}
	defer func() { _ = tx.Rollback() }()

	var existing sql.NullTime
	if err = tx.QueryRowContext(ctx, `
		SELECT deletion_effective_at FROM user_management.users
		WHERE id=$1::uuid FOR UPDATE`, userID).Scan(&existing); err != nil {
		return accountLifecycleState{}, err
	}
	if existing.Valid {
		return accountLifecycleState{}, errors.New("account deletion is already scheduled")
	}

	effectiveAt := time.Now().UTC().Add(accountDeletionGraceDays * 24 * time.Hour)
	if _, err = tx.ExecContext(ctx, `
		UPDATE user_management.users
		SET deletion_requested_at=NOW(),deletion_effective_at=$2,
		    deactivated_at=COALESCE(deactivated_at,NOW()),updated_at=NOW()
		WHERE id=$1::uuid`, userID, effectiveAt); err != nil {
		return accountLifecycleState{}, err
	}

	var requestID string
	if err = tx.QueryRowContext(ctx, `
		INSERT INTO user_management.account_lifecycle_requests
		  (user_id,request_type,status,effective_at,reason,actor_user_id,actor_role)
		VALUES ($1::uuid,'delete','pending',$2,NULLIF($3,''),NULLIF($4,'')::uuid,$5)
		RETURNING id::text`, userID, effectiveAt, reason, actorID, actorRole).Scan(&requestID); err != nil {
		return accountLifecycleState{}, err
	}
	if actorRole == "operator" {
		if _, err = tx.ExecContext(ctx, `
			UPDATE user_management.auth_sessions
			SET revoked_at=NOW(),revoked_reason='operator_account_removal'
			WHERE user_id=$1::uuid AND revoked_at IS NULL`, userID); err != nil {
			return accountLifecycleState{}, err
		}
	}
	if err = recordLifecycleEvent(ctx, tx, "account.deletion_requested", actorID, actorRole,
		userID, requestID, map[string]any{
			"reason":       reason,
			"effective_at": effectiveAt.Format(time.RFC3339),
			"grace_days":   accountDeletionGraceDays,
		}); err != nil {
		return accountLifecycleState{}, err
	}
	if err = tx.Commit(); err != nil {
		return accountLifecycleState{}, err
	}
	return r.accountLifecycleState(ctx, userID)
}

// cancelAccountDeletion withdraws a scheduled deletion inside the grace window.
func (r *profileRepository) cancelAccountDeletion(
	ctx context.Context,
	userID, actorID string,
) (accountLifecycleState, error) {
	if r.pg == nil {
		return accountLifecycleState{}, errors.New("account lifecycle persistence is unavailable")
	}
	tx, err := r.pg.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		return accountLifecycleState{}, err
	}
	defer func() { _ = tx.Rollback() }()

	var effective sql.NullTime
	if err = tx.QueryRowContext(ctx, `
		SELECT deletion_effective_at FROM user_management.users
		WHERE id=$1::uuid FOR UPDATE`, userID).Scan(&effective); err != nil {
		return accountLifecycleState{}, err
	}
	if !effective.Valid {
		return accountLifecycleState{}, errors.New("no deletion is scheduled for this account")
	}
	// Past the window the erasure is already owed; withdrawing it here would
	// contradict the sweep that may have started.
	if !effective.Time.After(time.Now()) {
		return accountLifecycleState{}, errors.New("the deletion grace period has elapsed")
	}
	var operatorScheduled bool
	if err = tx.QueryRowContext(ctx, `
		SELECT EXISTS(SELECT 1 FROM user_management.account_lifecycle_requests
		  WHERE user_id=$1::uuid AND request_type='delete' AND status='pending'
		    AND actor_role='operator')`, userID).Scan(&operatorScheduled); err != nil {
		return accountLifecycleState{}, err
	}
	if operatorScheduled {
		return accountLifecycleState{}, errOperatorDeletionNotCancellable
	}

	if _, err = tx.ExecContext(ctx, `
		UPDATE user_management.users
		SET deletion_requested_at=NULL,deletion_effective_at=NULL,
		    deactivated_at=NULL,updated_at=NOW()
		WHERE id=$1::uuid`, userID); err != nil {
		return accountLifecycleState{}, err
	}
	if _, err = tx.ExecContext(ctx, `
		UPDATE user_management.account_lifecycle_requests
		SET status='cancelled',cancelled_at=NOW(),updated_at=NOW()
		WHERE user_id=$1::uuid AND request_type='delete' AND status='pending'`,
		userID); err != nil {
		return accountLifecycleState{}, err
	}
	if err = recordLifecycleEvent(ctx, tx, "account.deletion_cancelled", actorID, "member",
		userID, userID, map[string]any{}); err != nil {
		return accountLifecycleState{}, err
	}
	if err = tx.Commit(); err != nil {
		return accountLifecycleState{}, err
	}
	return r.accountLifecycleState(ctx, userID)
}

// buildAccountExport assembles the member's own record.
//
// Deliberately excluded: password and recovery-code hashes, session and refresh
// tokens, and other members' profile data. An export is the requester's record,
// not a route to everyone they ever matched with — counterparties appear as
// opaque ids only. Message bodies the member wrote are theirs and are included;
// bodies written *to* them are not.
func (r *profileRepository) buildAccountExport(
	ctx context.Context,
	userID, actorID string,
) (map[string]any, error) {
	if r.pg == nil {
		return nil, errors.New("account lifecycle persistence is unavailable")
	}
	export := map[string]any{
		"schema_version": 1,
		"generated_at":   time.Now().UTC().Format(time.RFC3339),
		"user_id":        userID,
	}

	sections := accountExportSections()

	for _, section := range sections {
		var raw []byte
		err := r.pg.QueryRowContext(ctx, section.query, userID).Scan(&raw)
		switch {
		case errors.Is(err, sql.ErrNoRows):
			export[section.name] = nil
			continue
		case err != nil:
			// Never mark a partial export complete. A schema drift or unavailable
			// section is a failed request that can be retried after repair; hiding
			// the error inside an otherwise successful payload would misrepresent
			// the member's data as complete.
			return nil, fmt.Errorf("export %s: %w", section.name, err)
		}
		var decoded any
		if err := json.Unmarshal(raw, &decoded); err != nil {
			return nil, fmt.Errorf("decode %s: %w", section.name, err)
		}
		export[section.name] = decoded
	}
	return export, nil
}

// createAccountExport builds an export and stores it against a request row.
func (r *profileRepository) createAccountExport(
	ctx context.Context,
	userID, actorID string,
) (map[string]any, string, error) {
	export, err := r.buildAccountExport(ctx, userID, actorID)
	if err != nil {
		return nil, "", err
	}
	encoded, err := json.Marshal(export)
	if err != nil {
		return nil, "", err
	}
	expiresAt := time.Now().UTC().Add(accountExportRetention)

	tx, err := r.pg.BeginTx(ctx, nil)
	if err != nil {
		return nil, "", err
	}
	defer func() { _ = tx.Rollback() }()

	// Supersede any earlier export so the unique open-request index holds and
	// an old payload cannot be fetched after a fresh request.
	if _, err = tx.ExecContext(ctx, `
		UPDATE user_management.account_lifecycle_requests
		SET status='cancelled',cancelled_at=NOW(),export_payload=NULL,updated_at=NOW()
		WHERE user_id=$1::uuid AND request_type='export' AND status='pending'`,
		userID); err != nil {
		return nil, "", err
	}

	var requestID string
	if err = tx.QueryRowContext(ctx, `
		INSERT INTO user_management.account_lifecycle_requests
		  (user_id,request_type,status,completed_at,actor_user_id,actor_role,
		   export_payload,export_expires_at)
		VALUES ($1::uuid,'export','completed',NOW(),NULLIF($2,'')::uuid,'member',
		        $3::jsonb,$4)
		RETURNING id::text`, userID, actorID, encoded, expiresAt).Scan(&requestID); err != nil {
		return nil, "", err
	}
	if err = recordLifecycleEvent(ctx, tx, "account.export_created", actorID, "member",
		userID, requestID, map[string]any{
			"expires_at": expiresAt.Format(time.RFC3339),
			"bytes":      len(encoded),
		}); err != nil {
		return nil, "", err
	}
	if err = tx.Commit(); err != nil {
		return nil, "", err
	}
	return export, requestID, nil
}

// latestAccountExport returns the most recent unexpired export payload.
func (r *profileRepository) latestAccountExport(
	ctx context.Context,
	userID string,
) (map[string]any, error) {
	if r.pg == nil {
		return nil, errors.New("account lifecycle persistence is unavailable")
	}
	var raw []byte
	err := r.pg.QueryRowContext(ctx, `
		SELECT export_payload FROM user_management.account_lifecycle_requests
		WHERE user_id=$1::uuid AND request_type='export' AND status='completed'
		  AND export_payload IS NOT NULL
		  AND (export_expires_at IS NULL OR export_expires_at > NOW())
		ORDER BY requested_at DESC LIMIT 1`, userID).Scan(&raw)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	var export map[string]any
	if err := json.Unmarshal(raw, &export); err != nil {
		return nil, err
	}
	return export, nil
}

// accountExportSections is the explicit allow-list of what an export contains.
//
// Declared as data, and separately testable, so the boundary can be asserted
// rather than trusted: nothing here may read credential or session tables.
func accountExportSections() []struct {
	name  string
	query string
} {
	return []struct {
		name  string
		query string
	}{
		{"account", `SELECT to_jsonb(t) FROM (
			SELECT id::text,username,name,phone_number,gender,date_of_birth,bio,account_kind,
			       city,state,country,profile_completion,is_verified,is_active,
			       created_at,updated_at,deactivated_at,deletion_effective_at
			FROM user_management.users WHERE id=$1::uuid) t`},
		{"preferences", `SELECT COALESCE(jsonb_agg(to_jsonb(t)),'[]'::jsonb) FROM (
			SELECT * FROM user_management.preferences WHERE user_id=$1::uuid) t`},
		{"profile_stories", `SELECT to_jsonb(t) FROM user_management.profile_stories t WHERE user_id=$1::uuid`},
		{"blog_responses", `SELECT COALESCE(jsonb_agg(jsonb_build_object('id',id,'post_id',post_id,'status',status,'my_response',CASE WHEN sender_id=$1 THEN text ELSE '' END,'my_contribution',CASE WHEN sender_id=$1 THEN sender_story ELSE author_story END,'created_at',created_at)),'[]') FROM matching.blog_responses WHERE sender_id=$1 OR author_id=$1`},
		{"blog_publications", `SELECT COALESCE(jsonb_agg(to_jsonb(t)),'[]') FROM matching.blog_publications t WHERE owner_id=$1 OR partner_id=$1`},
		{"blog_notices", `SELECT COALESCE(jsonb_agg(jsonb_build_object('id',id,'content_type',content_type,'content_id',content_id,'status',status,'decision_note',decision_note,'appeal',appeal)),'[]') FROM matching.blog_cases WHERE subject_id=$1`},
		{"blog_posts", `SELECT COALESCE(jsonb_agg(to_jsonb(t)),'[]'::jsonb) FROM matching.blog_posts t WHERE author_id=$1::uuid AND deleted_at IS NULL`},
		{"blog_photos", `SELECT COALESCE(jsonb_agg(to_jsonb(t)),'[]'::jsonb) FROM (SELECT id,post_id,alt_text,mime_type,size_bytes,created_at FROM matching.blog_photos WHERE author_id=$1::uuid AND deleted_at IS NULL) t`},
		{"blog_comments_written", `SELECT COALESCE(jsonb_agg(to_jsonb(t)),'[]'::jsonb) FROM (SELECT id,post_id,body,status,moderation_state,created_at FROM matching.blog_comments WHERE author_id=$1::uuid AND deleted_at IS NULL) t`},
		{"blog_subscriptions", `SELECT COALESCE(jsonb_agg(to_jsonb(t)),'[]'::jsonb) FROM (SELECT author_id AS following,created_at FROM matching.blog_subscriptions WHERE subscriber_id=$1::uuid) t`},
		{"blog_likes", `SELECT COALESCE(jsonb_agg(to_jsonb(t)),'[]'::jsonb) FROM (SELECT post_id,reaction,created_at,updated_at FROM matching.blog_likes WHERE user_id=$1::uuid) t`},
		{"photo_comments_written", `SELECT COALESCE(jsonb_agg(to_jsonb(t)),'[]'::jsonb) FROM (SELECT id,entry_id,body,status,moderation_state,created_at FROM matching.photo_entry_comments WHERE author_id=$1::uuid AND deleted_at IS NULL) t`},
		{"conversation_rooms", `SELECT COALESCE(jsonb_agg(to_jsonb(t) ORDER BY t.joined_at),'[]'::jsonb) FROM (SELECT r.title,r.always_on,p.role,p.status,p.joined_at,p.left_at,p.last_seen_at,(r.created_by_user_id=$1::uuid) AS hosted FROM matching.conversation_room_participants p JOIN matching.conversation_rooms r ON r.id=p.room_id WHERE p.user_id=$1::uuid) t`},
		{"chat_messages_sent", `SELECT COALESCE(jsonb_agg(to_jsonb(t) ORDER BY t.created_at),'[]'::jsonb) FROM (SELECT m.id,c.kind AS channel_kind,m.body,m.created_at,m.deleted_at IS NOT NULL AS deleted FROM matching.social_messages m JOIN matching.social_channels c ON c.id=m.channel_id WHERE m.sender_id=$1::uuid) t`},
		{"photo_likes", `SELECT COALESCE(jsonb_agg(to_jsonb(t)),'[]'::jsonb) FROM (SELECT entry_id,reaction,created_at,updated_at FROM matching.photo_entry_likes WHERE user_id=$1::uuid) t`},
		{"photo_theme_entries", `SELECT COALESCE(jsonb_agg(to_jsonb(t)),'[]'::jsonb) FROM (SELECT e.id,th.title AS theme,e.caption,e.alt_text,e.mime_type,e.size_bytes,e.moderation_state,e.created_at FROM matching.photo_theme_entries e JOIN matching.photo_themes th ON th.id=e.theme_id WHERE e.author_id=$1::uuid AND e.deleted_at IS NULL) t`},
		{"group_memberships", `SELECT COALESCE(jsonb_agg(to_jsonb(t)),'[]'::jsonb) FROM (SELECT g.id AS group_id,g.name,g.kind,g.category_slug,g.description,g.created_by_user_id=$1::uuid AS owner,m.role,m.status,m.joined_at,m.left_at FROM matching.community_group_members m JOIN matching.community_groups g ON g.id=m.group_id WHERE m.user_id=$1::uuid) t`},
		{"group_invitations", `SELECT COALESCE(jsonb_agg(to_jsonb(t)),'[]'::jsonb) FROM (SELECT i.id,i.group_id,g.name AS group_name,i.inviter_user_id=$1::uuid AS sent_by_me,i.status,i.invited_at,i.responded_at FROM matching.community_group_invites i JOIN matching.community_groups g ON g.id=i.group_id WHERE i.invitee_user_id=$1::uuid OR i.inviter_user_id=$1::uuid) t`},
		// Cover photos the member uploaded (migration 121), including replaced,
		// removed and rejected uploads still on record. Metadata only: never the
		// storage key or the image bytes.
		{"group_covers_uploaded", `SELECT COALESCE(jsonb_agg(to_jsonb(t) ORDER BY t.uploaded_at),'[]'::jsonb) FROM (SELECT group_id,id AS cover_id,moderation_status AS status,created_at AS uploaded_at,mime_type,size_bytes,deleted_at AS removed_at FROM matching.community_group_covers WHERE uploaded_by=$1::uuid) t`},
		{"club_memberships", `SELECT COALESCE(jsonb_agg(to_jsonb(t)),'[]'::jsonb) FROM (SELECT c.id AS club_id,c.name,c.kind,m.role,m.status,m.joined_at FROM matching.club_members m JOIN matching.clubs c ON c.id=m.club_id WHERE m.user_id=$1::uuid) t`},
		{"club_posts", `SELECT COALESCE(jsonb_agg(to_jsonb(t)),'[]'::jsonb) FROM (SELECT id,club_id,selection_id,body,has_spoilers,hidden_at,moderation_state,created_at FROM matching.club_posts WHERE author_id=$1::uuid AND deleted_at IS NULL) t`},
		{"title_reviews", `SELECT COALESCE(jsonb_agg(to_jsonb(t)),'[]'::jsonb) FROM (SELECT r.id,ti.kind,ti.title,ti.creator,r.rating,r.body,r.has_spoilers,r.audience,r.moderation_state,r.created_at,r.updated_at FROM matching.title_reviews r JOIN matching.club_titles ti ON ti.id=r.title_id WHERE r.author_id=$1::uuid AND r.deleted_at IS NULL) t`},
		{"member_lists", `SELECT COALESCE(jsonb_agg(to_jsonb(t)),'[]'::jsonb) FROM (SELECT l.id,l.name,l.kind,l.audience,l.created_at,(SELECT COALESCE(jsonb_agg(jsonb_build_object('title',ti.title,'creator',ti.creator,'note',i.note) ORDER BY i.position),'[]'::jsonb) FROM matching.member_list_items i JOIN matching.club_titles ti ON ti.id=i.title_id WHERE i.list_id=l.id) AS items FROM matching.member_lists l WHERE l.owner_id=$1::uuid AND l.deleted_at IS NULL) t`},
		{"date_plan_preferences", `SELECT COALESCE(jsonb_agg(to_jsonb(t)),'[]'::jsonb) FROM (SELECT id AS plan_id,window_start,window_end,budget_preference,atmosphere_preferences,accessibility_preferences,status FROM matching.match_date_plans WHERE proposer_user_id=$1::uuid OR invitee_user_id=$1::uuid) t`},
		{"date_plan_sharing", `SELECT to_jsonb(t) FROM matching.date_plan_sharing t WHERE user_id=$1::uuid`},
		{"city_pilot_participation", `SELECT COALESCE(jsonb_agg(to_jsonb(t)),'[]'::jsonb) FROM growth.city_pilot_members t WHERE member_id=$1::uuid`},
		{"city_pilot_feedback", `SELECT COALESCE(jsonb_agg(to_jsonb(t)),'[]'::jsonb) FROM growth.city_pilot_feedback t WHERE member_id=$1::uuid`},
		{"city_pilot_bookings", `SELECT COALESCE(jsonb_agg(to_jsonb(t)),'[]'::jsonb) FROM growth.event_registrations t WHERE member_id=$1::uuid AND event_id IN(SELECT event_id FROM growth.city_pilot_experiences)`},
		{"introducer_permissions", `SELECT COALESCE(jsonb_agg(to_jsonb(t)),'[]'::jsonb) FROM (SELECT id,introducer_user_id,member_user_id,status,share_photo,share_city,revoked_at,created_at FROM matching.introducer_consents WHERE member_user_id=$1::uuid OR introducer_user_id=$1::uuid) t`},
		{"introducer_invitations", `SELECT COALESCE(jsonb_agg(to_jsonb(t)),'[]'::jsonb) FROM (SELECT id,share_photo,share_city,expires_at,consumed_at,revoked_at,created_at FROM matching.introducer_invites WHERE member_user_id=$1::uuid) t`},
		{"dating_preferences", `SELECT to_jsonb(t) FROM matching.dating_preferences t WHERE user_id=$1::uuid`},
		{"chemistry_answers", `SELECT COALESCE(jsonb_agg(to_jsonb(t)),'[]'::jsonb) FROM (SELECT moment_id,answer,created_at FROM matching.chemistry_answers WHERE user_id=$1::uuid) t`},
		{"profile_draft", `SELECT to_jsonb(t) FROM (
			SELECT * FROM user_management.profile_drafts WHERE user_id=$1::uuid) t`},
		{"photos", `SELECT COALESCE(jsonb_agg(to_jsonb(t)),'[]'::jsonb) FROM (
			SELECT id::text,photo_url,ordering,mime_type,width_px,height_px,
			       size_bytes,moderation_status,lifecycle_status,uploaded_at
			FROM user_management.photos
			WHERE user_id=$1::uuid AND deleted_at IS NULL) t`},
		{"settings", `SELECT COALESCE(jsonb_agg(to_jsonb(t)),'[]'::jsonb) FROM (
			SELECT * FROM user_management.user_settings WHERE user_id=$1::uuid) t`},
		{"terms_acceptances", `SELECT to_jsonb(t) FROM (
            SELECT terms_accepted,terms_accepted_at,terms_version FROM user_management.users WHERE id=$1::uuid) t`},
		{"blocked_users", `SELECT COALESCE(jsonb_agg(to_jsonb(t)),'[]'::jsonb) FROM (
			SELECT blocked_user_id::text,reason,created_at
			FROM user_management.blocked_users WHERE user_id=$1::uuid) t`},
		{"matches", `SELECT COALESCE(jsonb_agg(to_jsonb(t)),'[]'::jsonb) FROM (
			SELECT id::text,
			       CASE WHEN user_id_1=$1::uuid THEN user_id_2::text
			            ELSE user_id_1::text END AS counterparty_user_id,
			       CASE WHEN user_id_1=$1::uuid THEN user_1_status
			            ELSE user_2_status END AS member_status,
			       created_at,unmatched_at,ended_reason
			FROM matching.matches
			WHERE user_id_1=$1::uuid OR user_id_2=$1::uuid) t`},
		{"messages_sent", `SELECT COALESCE(jsonb_agg(to_jsonb(t)),'[]'::jsonb) FROM (
			SELECT id::text,match_id::text,text,created_at,delivered_at,read_at,is_deleted
			FROM matching.messages WHERE sender_id=$1::uuid) t`},
		{"emergency_contacts", `SELECT COALESCE(jsonb_agg(to_jsonb(t)),'[]'::jsonb) FROM (
			SELECT id::text,name,phone_number,ordering,added_at,updated_at
			FROM user_management.emergency_contacts WHERE user_id=$1::uuid) t`},
		{"verification", `SELECT to_jsonb(t) FROM (
			SELECT status,submitted_at,reviewed_at,rejection_reason,updated_at
			FROM matching.verification_states WHERE user_id=$1::uuid) t`},
		{"voice_icebreakers_sent", `SELECT COALESCE(jsonb_agg(to_jsonb(t)),'[]'::jsonb) FROM (
			SELECT id::text,match_id::text,prompt_id,transcript,duration_seconds,status,
			       sent_at,played_at,created_at
			FROM matching.voice_icebreakers WHERE sender_user_id=$1::uuid) t`},
		// API request telemetry (migration 122) as daily counts only: the raw
		// rows are operational logs, kept 90 days, and never carry IPs or
		// query strings. Crash reports are not linked to an account, so there
		// is nothing of the member's to export from them.
		{"api_activity_summary", `SELECT COALESCE(jsonb_agg(jsonb_build_object('day',t.day,'requests',t.requests) ORDER BY t.day),'[]'::jsonb) FROM (
			SELECT (created_at AT TIME ZONE 'UTC')::date AS day, COUNT(*) AS requests
			FROM matching.activity_events
			WHERE event_domain='api_request' AND (user_id=$1::uuid OR actor_user_id=$1::uuid)
			GROUP BY 1) t`},
	}
}

// accountExportSectionSQL concatenates the section queries for boundary tests.
func accountExportSectionSQL() string {
	var builder strings.Builder
	for _, section := range accountExportSections() {
		builder.WriteString(section.name)
		builder.WriteString(" ")
		builder.WriteString(section.query)
		builder.WriteString("\n")
	}
	return builder.String()
}
