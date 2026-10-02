package mobile

import (
	"context"
	"crypto/sha256"
	"database/sql"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"
)

// erasureTombstone replaces free-text identity fields.
//
// A literal marker rather than NULL so an operator reading the row can tell
// scrubbed data from data that was never supplied.
const erasureTombstone = "[erased]"

type erasureSummary struct {
	UserID          string         `json:"user_id"`
	ErasedAt        string         `json:"erased_at"`
	RowsScrubbed    map[string]int `json:"rows_scrubbed"`
	StoragePaths    []string       `json:"storage_paths_released"`
	RetainedTables  []string       `json:"retained_tables"`
	SessionsRevoked int            `json:"sessions_revoked"`
	StorageReleased bool           `json:"storage_released"`
}

// errAccountOnLegalHold defers an erasure while a legal hold is active.
var errAccountOnLegalHold = errors.New("account is on legal hold; erasure deferred")

// retainedForSafetyAndLedger records what deliberately survives erasure.
//
// Two different reasons, both deliberate: the XP ledger cannot be deleted
// (append-only, RESTRICT foreign key), and the safety and audit records are
// evidence about conduct that outlives the account. Once the identity columns
// are scrubbed these rows no longer identify anybody — with one exception the
// scrub has to handle explicitly: audit.change_log stores full before/after
// copies of member rows, so erasure minimises the member's history to field
// names (audit.minimize_member_history, migration 081). The rows survive; the
// copied personal data does not.
var retainedForSafetyAndLedger = []string{
	"progression.xp_ledger",
	"audit.security_events",
	"audit.change_log",
	"user_management.media_moderation_events",
	"matching.voice_moderation_events",
	"matching.moderation_reports",
	"matching.moderation_appeals",
	// Room hosts' and operators' warnings and removals (migration 117).
	"matching.conversation_room_moderation_actions",
}

// eraseAccount irreversibly anonymises one member inside a single transaction.
//
// Idempotent: an account already carrying `erased_at` is left alone and
// reported as such, so a retried or overlapping sweep cannot double-run.
func (r *profileRepository) eraseAccount(
	ctx context.Context,
	userID, actorID, actorRole string,
) (erasureSummary, error) {
	if r.pg == nil {
		return erasureSummary{}, errors.New("account erasure persistence is unavailable")
	}
	summary := erasureSummary{
		UserID:         userID,
		RowsScrubbed:   map[string]int{},
		StoragePaths:   []string{},
		RetainedTables: retainedForSafetyAndLedger,
	}

	tx, err := r.pg.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		return erasureSummary{}, err
	}
	defer func() { _ = tx.Rollback() }()

	var alreadyErased sql.NullTime
	var effective sql.NullTime
	if err = tx.QueryRowContext(ctx, `
		SELECT erased_at, deletion_effective_at FROM user_management.users
		WHERE id=$1::uuid FOR UPDATE`, userID).Scan(&alreadyErased, &effective); err != nil {
		return erasureSummary{}, err
	}
	if alreadyErased.Valid {
		summary.ErasedAt = alreadyErased.Time.UTC().Format(time.RFC3339)
		return summary, nil
	}
	// The grace window is the member's protection. A sweep that erased early
	// would remove exactly the recovery path the window exists to provide.
	if !effective.Valid {
		return erasureSummary{}, errors.New("no deletion is scheduled for this account")
	}
	if effective.Time.After(time.Now()) {
		return erasureSummary{}, fmt.Errorf(
			"deletion grace period has not elapsed (effective %s)",
			effective.Time.UTC().Format(time.RFC3339))
	}
	// A legal hold overrides erasure (trust_operations.v1.json). The request
	// stays pending and the sweep erases once the hold is released.
	var onHold bool
	if err = tx.QueryRowContext(ctx,
		`SELECT platform.member_on_legal_hold($1::uuid)`, userID).Scan(&onHold); err != nil {
		return erasureSummary{}, err
	}
	if onHold {
		return erasureSummary{}, errAccountOnLegalHold
	}

	// Storage objects are released by a separate media sweep, so collect the
	// paths before the rows that carry them are removed.
	rows, err := tx.QueryContext(ctx, `
		SELECT storage_path FROM (
		  SELECT storage_path
		  FROM user_management.photos
		  WHERE user_id=$1::uuid
		  UNION ALL
		  SELECT details->'id_document'->>'storage_path'
		  FROM matching.verification_states
		  WHERE user_id=$1::uuid
		  UNION ALL
		  SELECT details->'selfie'->>'storage_path'
		  FROM matching.verification_states
		  WHERE user_id=$1::uuid
		  UNION ALL
		  SELECT audio_storage_path
		  FROM matching.voice_icebreakers
		  WHERE sender_user_id=$1::uuid
		  UNION ALL
		  SELECT storage_path FROM matching.blog_photos ph WHERE author_id=$1::uuid AND NOT EXISTS(SELECT 1 FROM matching.blog_evidence_photos e WHERE e.storage_path=ph.storage_path)
		  UNION ALL
		  SELECT storage_path FROM matching.photo_theme_entries te WHERE author_id=$1::uuid AND NOT EXISTS(SELECT 1 FROM matching.blog_evidence_photos e WHERE e.storage_path=te.storage_path)
		  UNION ALL
		  -- Group covers (migration 121): every cover the member uploaded, and
		  -- the covers of groups erasure deletes (nobody else is in them).
		  SELECT storage_path FROM matching.community_group_covers gc WHERE gc.storage_path<>'' AND gc.storage_released_at IS NULL
		   AND (gc.uploaded_by=$1::uuid OR gc.group_id IN(SELECT og.id FROM matching.community_groups og WHERE og.created_by_user_id=$1::uuid
		    AND NOT EXISTS(SELECT 1 FROM matching.community_group_members om WHERE om.group_id=og.id AND om.user_id<>$1::uuid AND om.status='active')))
		   AND NOT EXISTS(SELECT 1 FROM matching.blog_evidence_photos e WHERE e.storage_path=gc.storage_path)
		) private_media(storage_path)
		WHERE COALESCE(BTRIM(storage_path),'') <> ''`, userID)
	if err != nil {
		return erasureSummary{}, err
	}
	for rows.Next() {
		var path string
		if scanErr := rows.Scan(&path); scanErr != nil {
			rows.Close()
			return erasureSummary{}, scanErr
		}
		summary.StoragePaths = append(summary.StoragePaths, path)
	}
	rows.Close()
	if err = rows.Err(); err != nil {
		return erasureSummary{}, err
	}

	// Ordered so that content disappears before the identity it belongs to.
	steps := accountErasureSteps()
	for _, step := range steps {
		var result sql.Result
		if step.usesTombstone {
			result, err = tx.ExecContext(ctx, step.query, userID, erasureTombstone)
		} else {
			result, err = tx.ExecContext(ctx, step.query, userID)
		}
		if err != nil {
			// Erasure is the one operation that cannot be partially right: a
			// step that fails leaves personal data behind while the account is
			// marked erased. Abort so the sweep retries rather than reporting
			// a scrub that did not happen.
			return erasureSummary{}, fmt.Errorf("erase %s: %w", step.label, err)
		}
		affected, _ := result.RowsAffected()
		summary.RowsScrubbed[step.label] = int(affected)
	}

	// Credentials disabled and every session revoked: an erased identity must
	// not be able to authenticate, and username is freed only after the
	// credential row can no longer be used.
	// `auth_credentials.username` is a separate copy of the member's handle and
	// is the table's primary key. Disabling the row leaves that handle in the
	// database, so the most recognisable identifier the member had would have
	// survived an erasure that reported success. No foreign key references the
	// username column — every relationship is on user_id — so the key can be
	// rewritten to the same tombstone the users row carries.
	if _, err = tx.ExecContext(ctx, `
		UPDATE user_management.auth_credentials
		SET is_disabled=TRUE, username=$2, updated_at=NOW()
		WHERE user_id=$1::uuid`, userID, erasureTombstoneUsername(userID)); err != nil {
		return erasureSummary{}, err
	}
	sessionResult, err := tx.ExecContext(ctx, `
		UPDATE user_management.auth_sessions
		SET revoked_at=COALESCE(revoked_at,NOW()),revoked_reason='account_erased'
		WHERE user_id=$1::uuid AND revoked_at IS NULL`, userID)
	if err != nil {
		return erasureSummary{}, err
	}
	revoked, _ := sessionResult.RowsAffected()
	summary.SessionsRevoked = int(revoked)

	// Identity columns. `username`, `name`, `date_of_birth` and `gender` are
	// NOT NULL, so they are replaced rather than cleared. The username is
	// rewritten to an id-derived tombstone: keeping the original would retain
	// the most recognisable identifier the member had. A sha256 digest
	// truncated to 23 hex characters satisfies the 30-character format cap
	// without the prefix collisions that truncating the uuid itself caused.
	if _, err = tx.ExecContext(ctx, `
		UPDATE user_management.users SET
		  username='erased_'||substr(encode(sha256(id::text::bytea),'hex'),1,23),
		  name=$2, phone_number=NULL, email=NULL, bio=NULL,
		  date_of_birth=DATE '1900-01-01', height_cm=NULL, education=NULL,
		  profession=NULL, income_range=NULL, drinking=NULL, smoking=NULL,
		  religion=NULL, mother_tongue=NULL, relationship_status=NULL,
		  personality_type=NULL, country=NULL, state=NULL, city=NULL,
		  profile_completion=0, is_verified=FALSE, is_active=FALSE,
		  deactivated_at=COALESCE(deactivated_at,NOW()),
		  erased_at=NOW(), updated_at=NOW()
		WHERE id=$1::uuid`, userID, erasureTombstone); err != nil {
		return erasureSummary{}, err
	}
	summary.ErasedAt = time.Now().UTC().Format(time.RFC3339)

	// Last, so it also covers the history rows this transaction's own updates
	// just wrote: those carry the pre-erasure values as old_data.
	var minimised int
	if err = tx.QueryRowContext(ctx,
		`SELECT audit.minimize_member_history($1::uuid)`, userID).Scan(&minimised); err != nil {
		return erasureSummary{}, fmt.Errorf("erase audit history: %w", err)
	}
	summary.RowsScrubbed["audit_history_minimised"] = minimised

	// Close the request and drop any export payload: a copy of the member's
	// data must not outlive the data itself.
	if _, err = tx.ExecContext(ctx, `
		UPDATE user_management.account_lifecycle_requests
		SET status='completed', completed_at=NOW(), updated_at=NOW(),
		    erasure_summary=$2::jsonb
		WHERE user_id=$1::uuid AND request_type='delete' AND status='pending'`,
		userID, mustJSON(summary)); err != nil {
		return erasureSummary{}, err
	}
	if _, err = tx.ExecContext(ctx, `
		UPDATE user_management.account_lifecycle_requests
		SET export_payload=NULL, export_expires_at=NULL, updated_at=NOW()
		WHERE user_id=$1::uuid AND export_payload IS NOT NULL`, userID); err != nil {
		return erasureSummary{}, err
	}

	if err = recordLifecycleEvent(ctx, tx, "account.erased", actorID, actorRole,
		userID, userID, map[string]any{
			"rows_scrubbed":    summary.RowsScrubbed,
			"sessions_revoked": summary.SessionsRevoked,
			"storage_released": len(summary.StoragePaths),
			"retained_tables":  summary.RetainedTables,
		}); err != nil {
		return erasureSummary{}, err
	}
	if err = tx.Commit(); err != nil {
		return erasureSummary{}, err
	}
	return summary, nil
}

func mustJSON(value any) []byte {
	encoded, err := json.Marshal(value)
	if err != nil {
		return []byte(`{}`)
	}
	return encoded
}

// dueAccountErasures lists deletions whose grace period has elapsed.
func (r *profileRepository) dueAccountErasures(
	ctx context.Context,
	limit int,
) ([]string, error) {
	if r.pg == nil {
		return nil, errors.New("account erasure persistence is unavailable")
	}
	if limit <= 0 {
		limit = 50
	}
	rows, err := r.pg.QueryContext(ctx, `
		SELECT u.id::text
		FROM user_management.users u
		WHERE u.deletion_effective_at IS NOT NULL
		  AND u.deletion_effective_at <= NOW()
		  AND u.erased_at IS NULL
		ORDER BY u.deletion_effective_at
		LIMIT $1`, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	ids := make([]string, 0, limit)
	for rows.Next() {
		var id string
		if err := rows.Scan(&id); err != nil {
			return nil, err
		}
		ids = append(ids, id)
	}
	return ids, rows.Err()
}

// pruneExpiredExports drops export payloads past their retention window.
//
// The request row survives as evidence that an export was produced; only the
// copy of the member's data goes.
func (r *profileRepository) pruneExpiredExports(ctx context.Context) (int, error) {
	if r.pg == nil {
		return 0, errors.New("account lifecycle persistence is unavailable")
	}
	result, err := r.pg.ExecContext(ctx, `
		UPDATE user_management.account_lifecycle_requests
		SET export_payload=NULL, updated_at=NOW()
		WHERE export_payload IS NOT NULL
		  AND export_expires_at IS NOT NULL
		  AND export_expires_at <= NOW()`)
	if err != nil {
		return 0, err
	}
	affected, _ := result.RowsAffected()
	return int(affected), nil
}

// accountErasureStep is one scrub or delete performed during erasure.
type accountErasureStep struct {
	label         string
	query         string
	usesTombstone bool
}

// accountErasureSteps is the ordered list of what erasure removes.
//
// Declared as data so the boundary is testable: nothing here may touch the
// tables erasure deliberately retains, and the list must still cover the
// member's content.
func accountErasureSteps() []accountErasureStep {
	return []accountErasureStep{
		{label: "city_pilot_feedback", query: `DELETE FROM growth.city_pilot_feedback WHERE member_id=$1::uuid`},
		{label: "city_pilot_members", query: `DELETE FROM growth.city_pilot_members WHERE member_id=$1::uuid`},
		{label: "city_pilot_bookings", query: `DELETE FROM growth.event_registrations WHERE member_id=$1::uuid AND event_id IN(SELECT event_id FROM growth.city_pilot_experiences)`},
		{label: "introducer_intros", query: `DELETE FROM matching.friend_intros WHERE introducer_user_id=$1::uuid OR first_user_id=$1::uuid OR second_user_id=$1::uuid`},
		{label: "introducer_invites", query: `DELETE FROM matching.introducer_invites WHERE member_user_id=$1::uuid OR consumed_by=$1::uuid`},
		{label: "introducer_consents", query: `DELETE FROM matching.introducer_consents WHERE member_user_id=$1::uuid OR introducer_user_id=$1::uuid`},
		{label: "photos", query: `DELETE FROM user_management.photos WHERE user_id=$1::uuid`},
		{label: "date_plan_preferences", query: `UPDATE matching.match_date_plans SET atmosphere_preferences='{}',accessibility_preferences='{}',budget_preference='flexible',lock_version=lock_version+1 WHERE (proposer_user_id=$1::uuid OR invitee_user_id=$1::uuid) AND (cardinality(atmosphere_preferences)>0 OR cardinality(accessibility_preferences)>0 OR budget_preference<>'flexible')`},
		{label: "profile_stories", query: `DELETE FROM user_management.profile_stories WHERE user_id=$1::uuid`},
		{label: "blog_publications", query: `DELETE FROM matching.blog_publications WHERE owner_id=$1::uuid OR partner_id=$1::uuid`},
		{label: "blog_responses", query: `DELETE FROM matching.blog_responses WHERE sender_id=$1::uuid OR author_id=$1::uuid`},
		// Shared chat (migration 115): the member's messages and read markers.
		// Friend channels go with the account through their foreign keys.
		{label: "social_messages", query: `DELETE FROM matching.social_messages WHERE sender_id=$1::uuid`},
		{label: "social_channel_reads", query: `DELETE FROM matching.social_channel_reads WHERE user_id=$1::uuid`},
		// Per-conversation notification mutes (migration 119).
		{label: "social_channel_prefs", query: `DELETE FROM matching.social_channel_prefs WHERE user_id=$1::uuid`},
		{label: "social_friend_channels", query: `DELETE FROM matching.social_channels WHERE kind='friend' AND (user_low=$1::uuid OR user_high=$1::uuid)`},
		// Conversation Rooms (migration 117): memberships and removals go; a
		// room the member was hosting closes and no longer names them.
		{label: "conversation_room_participants", query: `DELETE FROM matching.conversation_room_participants WHERE user_id=$1::uuid`},
		{label: "conversation_room_blocks", query: `DELETE FROM matching.conversation_room_blocks WHERE blocked_user_id=$1::uuid`},
		{label: "conversation_rooms_hosted", query: `UPDATE matching.conversation_rooms SET lifecycle_state=CASE WHEN always_on THEN lifecycle_state ELSE 'closed' END,created_by_user_id=NULL,updated_at=NOW() WHERE created_by_user_id=$1::uuid`},
		// Friends (migration 116): friendships, open requests, declines and
		// the daily request ledger.
		{label: "friend_connections", query: `DELETE FROM matching.friend_connections WHERE user_id=$1::uuid OR friend_user_id=$1::uuid`},
		{label: "friend_request_declines", query: `DELETE FROM matching.friend_request_declines WHERE requester_id=$1::uuid OR recipient_id=$1::uuid`},
		{label: "friend_request_sends", query: `DELETE FROM matching.friend_request_sends WHERE requester_id=$1::uuid OR recipient_id=$1::uuid`},
		// Community and friend groups (migration 118): a group the member owns
		// passes to its longest-standing moderator, else member; a group with
		// nobody else is deleted with its chat.
		// Group covers (migration 121): covers the member uploaded come down
		// even where the group passes to someone else (it falls back to its
		// emoji cover); the media worker releases the objects.
		{label: "group_covers_uploaded", query: `UPDATE matching.community_group_covers SET deleted_at=COALESCE(deleted_at,NOW()),delete_reason=COALESCE(delete_reason,'erased') WHERE uploaded_by=$1::uuid`},
		{label: "group_ownership_handoff", query: `UPDATE matching.community_groups g SET created_by_user_id=h.user_id,updated_at=NOW()
		  FROM (SELECT DISTINCT ON (m.group_id) m.group_id,m.user_id FROM matching.community_group_members m JOIN matching.community_groups og ON og.id=m.group_id
		        WHERE og.created_by_user_id=$1::uuid AND m.user_id<>$1::uuid AND m.status='active'
		        ORDER BY m.group_id,(m.role IN ('owner','moderator')) DESC,m.joined_at,m.user_id) h
		  WHERE g.id=h.group_id`},
		{label: "group_new_owners", query: `UPDATE matching.community_group_members m SET role='owner',updated_at=NOW() FROM matching.community_groups g
		  WHERE g.id=m.group_id AND m.user_id=g.created_by_user_id AND m.status='active' AND m.role<>'owner' AND g.created_by_user_id<>$1::uuid
		    AND EXISTS(SELECT 1 FROM matching.community_group_members x WHERE x.group_id=g.id AND x.user_id=$1::uuid)`},
		{label: "group_memberships", query: `DELETE FROM matching.community_group_members WHERE user_id=$1::uuid`},
		{label: "group_invites", query: `DELETE FROM matching.community_group_invites WHERE invitee_user_id=$1::uuid OR inviter_user_id=$1::uuid`},
		{label: "group_covers_without_members", query: `UPDATE matching.community_group_covers SET deleted_at=NOW(),delete_reason='group_deleted' WHERE deleted_at IS NULL AND group_id IN(SELECT id FROM matching.community_groups WHERE created_by_user_id=$1::uuid)`},
		{label: "group_channels_without_members", query: `DELETE FROM matching.social_channels WHERE kind='group' AND ref_id IN(SELECT id FROM matching.community_groups WHERE created_by_user_id=$1::uuid)`},
		{label: "groups_without_members", query: `DELETE FROM matching.community_groups WHERE created_by_user_id=$1::uuid`},
		{label: "group_cover_uploaders", query: `UPDATE matching.community_group_covers SET uploaded_by=NULL WHERE uploaded_by=$1::uuid`},
		{label: "blog_subscriptions", query: `DELETE FROM matching.blog_subscriptions WHERE subscriber_id=$1::uuid OR author_id=$1::uuid`},
		{label: "blog_comments", query: `DELETE FROM matching.blog_comments WHERE author_id=$1::uuid OR post_author_id=$1::uuid`},
		{label: "blog_likes", query: `DELETE FROM matching.blog_likes WHERE user_id=$1::uuid`},
		{label: "blog_wall_deliveries", query: `DELETE FROM matching.blog_wall_deliveries WHERE recipient_id=$1::uuid`},
		{label: "blog_posts", query: `DELETE FROM matching.blog_posts WHERE author_id=$1::uuid`},
		// Photo Themes and Book & Film Clubs (migration 107). A club the member
		// owns passes to its longest-standing moderator or member so the rest of
		// the club keeps its discussion; a club with nobody else is deleted.
		{label: "content_views", query: `DELETE FROM matching.content_views WHERE viewer_id=$1::uuid`},
		{label: "wall_daily_picks", query: `DELETE FROM matching.wall_daily_picks WHERE recipient_id=$1::uuid`},
		{label: "wall_celebrations", query: `DELETE FROM matching.wall_celebrations WHERE author_id=$1::uuid`},
		{label: "photo_entry_comments", query: `DELETE FROM matching.photo_entry_comments WHERE author_id=$1::uuid OR owner_id=$1::uuid`},
		{label: "photo_entry_likes", query: `DELETE FROM matching.photo_entry_likes WHERE user_id=$1::uuid`},
		{label: "photo_wall_deliveries", query: `DELETE FROM matching.photo_wall_deliveries WHERE recipient_id=$1::uuid`},
		{label: "photo_theme_entries", query: `DELETE FROM matching.photo_theme_entries WHERE author_id=$1::uuid`},
		{label: "club_ownership_handoff", query: `UPDATE matching.clubs c SET owner_id=h.user_id,version=c.version+1,updated_at=NOW()
		  FROM (SELECT DISTINCT ON (m.club_id) m.club_id,m.user_id FROM matching.club_members m JOIN matching.clubs oc ON oc.id=m.club_id
		        WHERE oc.owner_id=$1::uuid AND m.user_id<>$1::uuid AND m.status='active'
		        ORDER BY m.club_id,(m.role='moderator') DESC,m.joined_at,m.user_id) h
		  WHERE c.id=h.club_id`},
		{label: "club_memberships", query: `DELETE FROM matching.club_members WHERE user_id=$1::uuid`},
		{label: "club_new_owners", query: `UPDATE matching.club_members m SET role='owner',updated_at=NOW() FROM matching.clubs c
		  WHERE c.id=m.club_id AND m.user_id=c.owner_id AND m.status='active' AND m.role<>'owner' AND c.owner_id<>$1::uuid`},
		{label: "clubs_without_members", query: `DELETE FROM matching.clubs WHERE owner_id=$1::uuid`},
		{label: "club_posts", query: `DELETE FROM matching.club_posts WHERE author_id=$1::uuid`},
		{label: "club_post_moderators", query: `UPDATE matching.club_posts SET hidden_by=NULL WHERE hidden_by=$1::uuid`},
		{label: "club_selection_choosers", query: `UPDATE matching.club_selections SET chosen_by=NULL WHERE chosen_by=$1::uuid`},
		{label: "club_title_contributors", query: `UPDATE matching.club_titles SET created_by=NULL WHERE created_by=$1::uuid`},
		{label: "title_reviews", query: `DELETE FROM matching.title_reviews WHERE author_id=$1::uuid`},
		{label: "member_lists", query: `DELETE FROM matching.member_lists WHERE owner_id=$1::uuid`},
		{label: "profile_drafts", query: `DELETE FROM user_management.profile_drafts WHERE user_id=$1::uuid`},
		{label: "profile_snapshots", query: `DELETE FROM user_management.profile_snapshots WHERE user_id=$1::uuid`},
		{label: "preferences", query: `DELETE FROM user_management.preferences WHERE user_id=$1::uuid`},
		{label: "emergency_contacts", query: `DELETE FROM user_management.emergency_contacts WHERE user_id=$1::uuid`},
		{label: "device_push_tokens", query: `DELETE FROM user_management.device_push_tokens WHERE user_id=$1::uuid`},
		// Product analytics keeps per-member day rows (migration 123); daily
		// rollups are anonymous counts and stay.
		{label: "analytics_member_active_days", query: `DELETE FROM analytics.member_active_days WHERE user_id=$1::uuid`},
		{label: "analytics_member_surface_days", query: `DELETE FROM analytics.member_surface_days WHERE user_id=$1::uuid`},
		{label: "analytics_member_milestones", query: `DELETE FROM analytics.member_milestones WHERE user_id=$1::uuid`},
		{label: "analytics_excluded_accounts", query: `DELETE FROM analytics.excluded_accounts WHERE user_id=$1::uuid`},
		// Request telemetry (migration 122): the member's API request records
		// go entirely; any other activity event about them keeps the fact
		// but loses network, device and location context.
		{label: "api_request_telemetry", query: `DELETE FROM matching.activity_events WHERE event_domain='api_request' AND (user_id=$1::uuid OR actor_user_id=$1::uuid)`},
		// Member actions (migration 132) are kept as facts too; their
		// IP, device id and user agent go with the rest of the context.
		{label: "activity_event_context", query: `UPDATE matching.activity_events
		                            SET ip_address=NULL,source_device_id=NULL,geo_country=NULL,geo_state=NULL,geo_city=NULL,
		                                geo_latitude=NULL,geo_longitude=NULL,
		                                payload=payload #- '{details,remote_addr}' #- '{details,query}'
		                                               #- '{details,user_agent}' #- '{details,device_id}'
		                            WHERE (user_id=$1::uuid OR actor_user_id=$1::uuid)
		                              AND (ip_address IS NOT NULL OR source_device_id IS NOT NULL OR geo_city IS NOT NULL
		                                   OR geo_latitude IS NOT NULL OR payload->'details' ? 'remote_addr' OR payload->'details' ? 'query'
		                                   OR payload->'details' ? 'user_agent' OR payload->'details' ? 'device_id')`},
		// Support tickets (migration 126) stay as anonymous records for SLA
		// reporting. What the member wrote, every message on their tickets
		// (agents quote them) and their attachments go; the support SLA worker
		// releases the attachment bytes.
		{label: "support_attachments", query: `UPDATE support.ticket_attachments SET deleted_at=COALESCE(deleted_at,NOW())
		                         WHERE uploader_id=$1::uuid OR ticket_id IN (SELECT id FROM support.tickets WHERE requester_member_id=$1::uuid)`},
		{label: "support_messages", usesTombstone: true, query: `UPDATE support.ticket_messages SET body=$2
		                      WHERE ((author_id=$1::uuid AND author_kind='member') OR ticket_id IN (SELECT id FROM support.tickets WHERE requester_member_id=$1::uuid))
		                        AND body<>$2`},
		{label: "support_tickets", usesTombstone: true, query: `UPDATE support.tickets
		                     SET subject=$2, satisfaction_comment=NULL, app_version=NULL, os_version=NULL, device_model=NULL, locale=NULL, updated_at=NOW()
		                     WHERE requester_member_id=$1::uuid AND subject<>$2`},
		// An SOS alert's message and location are among the most sensitive
		// things a member ever sends; the alert row survives for the safety
		// record, its content does not. Delivery snapshots copied the
		// member's trusted contacts, which are also cleared.
		{label: "sos_alerts", query: `UPDATE matching.sos_alerts
		                SET message=NULL,latitude=NULL,longitude=NULL
		                WHERE user_id=$1::uuid AND (message IS NOT NULL OR latitude IS NOT NULL OR longitude IS NOT NULL)`},
		{label: "sos_delivery_outbox", query: `UPDATE matching.sos_delivery_outbox
		                         SET contact_name='[erased]',contact_phone='[erased]',message=NULL,
		                             latitude=NULL,longitude=NULL,
		                             status=CASE WHEN status IN ('pending','retry','processing') THEN 'cancelled' ELSE status END,
		                             updated_at=NOW()
		                         WHERE user_id=$1::uuid AND contact_phone<>'[erased]'`},
		{label: "verification_evidence", query: `UPDATE matching.verification_states
		                           SET details='{}'::jsonb,rejection_reason=NULL,updated_at=NOW()
		                           WHERE user_id=$1::uuid`},
		{label: "voice_icebreakers", usesTombstone: true, query: `UPDATE matching.voice_icebreakers
		                       SET transcript=$2,audio_storage_path=NULL,audio_mime_type=NULL,
		                           audio_size_bytes=NULL,audio_content_sha256=NULL,updated_at=NOW()
		                       WHERE sender_user_id=$1::uuid`},
		// The member's own words are their personal data. The row survives so
		// the counterparty's conversation keeps its shape and ordering, but the
		// text does not.
		{label: "messages", usesTombstone: true, query: `UPDATE matching.messages SET text=$2
		              WHERE sender_id=$1::uuid AND text <> $2`},
		{label: "prompt_answers", usesTombstone: true, query: `UPDATE matching.prompt_answers
		                    SET answer_text=$2, normalized_answer=$2
		                    WHERE user_id=$1::uuid AND answer_text <> $2`},
	}
}

// accountErasureStepSQL concatenates the step queries for boundary tests.
func accountErasureStepSQL() string {
	var builder strings.Builder
	for _, step := range accountErasureSteps() {
		builder.WriteString(step.label)
		builder.WriteString(" ")
		builder.WriteString(step.query)
		builder.WriteString("\n")
	}
	return builder.String()
}

// erasureTombstoneUsername derives the username an erased row must carry.
//
// Mirrors the SQL in 067_username_erasure_carveout.sql. The trigger accepts
// only this exact value, and `users_username_check` caps a username at 30
// characters, so the two rules have to agree or erasure aborts.
func erasureTombstoneUsername(userID string) string {
	digest := sha256.Sum256([]byte(userID))
	return "erased_" + hex.EncodeToString(digest[:])[:23]
}

// pendingStorageRelease is an erased account whose objects still need deleting.
type pendingStorageRelease struct {
	RequestID string
	UserID    string
	Paths     []string
}

// pendingStorageReleases lists erasures whose storage objects are unreleased.
//
// Read from the persisted erasure summary rather than from the photo rows,
// because erasure deletes those rows — which is exactly why the orphan sweep
// could not find the objects afterwards.
func (r *profileRepository) pendingStorageReleases(
	ctx context.Context,
	limit int,
) ([]pendingStorageRelease, error) {
	if r.pg == nil {
		return nil, errors.New("account lifecycle persistence is unavailable")
	}
	if limit <= 0 {
		limit = 50
	}
	rows, err := r.pg.QueryContext(ctx, `
		SELECT id::text, user_id::text,
		       COALESCE(erasure_summary->'storage_paths_released','[]'::jsonb)
		FROM user_management.account_lifecycle_requests
		WHERE request_type='delete' AND status='completed'
		  AND storage_released_at IS NULL
		ORDER BY completed_at
		LIMIT $1`, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	pending := make([]pendingStorageRelease, 0, limit)
	for rows.Next() {
		var item pendingStorageRelease
		var raw []byte
		if err := rows.Scan(&item.RequestID, &item.UserID, &raw); err != nil {
			return nil, err
		}
		if err := json.Unmarshal(raw, &item.Paths); err != nil {
			item.Paths = nil
		}
		pending = append(pending, item)
	}
	return pending, rows.Err()
}

// markStorageReleased records that every object for an erasure is gone.
//
// Only called once all paths deleted successfully; a partial release leaves the
// marker null so the next sweep retries the remainder. Deleting an object twice
// is harmless, losing one is not.
func (r *profileRepository) markStorageReleased(
	ctx context.Context,
	requestID string,
) error {
	if r.pg == nil {
		return errors.New("account lifecycle persistence is unavailable")
	}
	_, err := r.pg.ExecContext(ctx, `
		UPDATE user_management.account_lifecycle_requests
		SET storage_released_at=NOW(), updated_at=NOW()
		WHERE id=$1::uuid`, requestID)
	return err
}
