package mobile

import (
	"context"
	"database/sql"
	"errors"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
)

// Lifestyle community groups and private friend groups (migration 118).
//
// A group is either a community group (kind 'community': public, listed under
// a lifestyle category, anyone can join) or a private group (kind 'private':
// a friends group, invitation only). Every actor comes from the authenticated
// principal. Rules:
//
//   - Invitations go to accepted friends only, never to anyone either side has
//     blocked, at most 50 per request.
//   - Community groups: any member may invite their friends (the group is open
//     to everyone anyway). Private groups: only the owner and moderators invite,
//     so members of a friends group are never surprised by strangers.
//   - The owner edits, deletes, promotes and demotes moderators and removes
//     anyone; moderators remove plain members. Removed members cannot rejoin a
//     community group by themselves (the owner or a moderator may re-invite).
//   - When the owner leaves, ownership passes to the longest-standing moderator,
//     else the longest-standing member; a group with nobody else is deleted.
//   - Members see the member list and the group's chat channel. Non-members of
//     a community group see the description and the member count only.
//
// Group chat is the shared engine's channel kind 'group'; membership is read
// live, so leaving or being removed revokes the chat at once.

const groupsUnavailable = "Groups are temporarily unavailable. Please retry."

const (
	groupMaxInvitesPerRequest = 50
	groupMaxInvitesPerDay     = 200
	groupMaxOwned             = 10
	groupMaxJoined            = 50
	groupCommunityCap         = 200
	groupPrivateCap           = 50
	groupMembersPreview       = 8
)

func init() {
	registerChannelSpec(channelSpec{
		Kind: "group",
		// A group removed after a review (moderation_state='removed') has no
		// chat until an operator restores it.
		MembersSQL: `SELECT gm.user_id FROM matching.community_group_members gm JOIN matching.community_groups gg ON gg.id=gm.group_id
 WHERE gm.group_id=c.ref_id AND gm.status='active' AND gg.moderation_state='active'`,
		ModeratorsSQL: `SELECT gm.user_id FROM matching.community_group_members gm JOIN matching.community_groups gg ON gg.id=gm.group_id
 WHERE gm.group_id=c.ref_id AND gm.status='active' AND gg.moderation_state='active' AND (gm.user_id=gg.created_by_user_id OR gm.role IN ('owner','moderator'))`,
		TitleSQL: `(SELECT gg.name FROM matching.community_groups gg WHERE gg.id=c.ref_id)`,
		// Group members hear about new messages at most once per ten minutes
		// per group (the engine's bucket), the same as friend conversations.
		Notify: true,
		Route:  "/groups",
	})
}

type groupCategory struct {
	Slug        string `json:"slug"`
	Title       string `json:"title"`
	Emoji       string `json:"emoji"`
	Description string `json:"description"`
	SortOrder   int    `json:"sort_order"`
	GroupCount  int    `json:"group_count"`
}

type groupView struct {
	ID            string `json:"id"`
	Kind          string `json:"kind"`
	Visibility    string `json:"visibility"`
	CategorySlug  string `json:"category_slug"`
	CategoryTitle string `json:"category_title"`
	CategoryEmoji string `json:"category_emoji"`
	Name          string `json:"name"`
	Description   string `json:"description"`
	City          string `json:"city"`
	CoverEmoji    string `json:"cover_emoji"`
	CoverColor    string `json:"cover_color"`
	MemberCount   int    `json:"member_count"`
	MemberCap     int    `json:"member_cap"`
	OwnerID       string `json:"owner_user_id,omitempty"`
	MyRole        string `json:"my_role"`
	IsMember      bool   `json:"is_member"`
	InviteID      string `json:"invite_id,omitempty"`
	ChannelID     string `json:"channel_id,omitempty"`
	UnreadCount   int    `json:"unread_count"`
	CanInvite     bool   `json:"can_invite"`
	CanManage     bool   `json:"can_manage"`
	CanJoin       bool   `json:"can_join"`
	// ModerationState is "removed" after a review removed the group: members
	// still see it (with a notice), nobody can join or chat.
	ModerationState string `json:"moderation_state"`
	Removed         bool   `json:"removed"`
	// Cover photo (migration 121, group_covers.go). cover_photo_url and
	// cover_photo_id are set only when the viewer may see the photo: an
	// approved cover of an active group (pending covers: the owner only),
	// never one uploaded by someone either side has blocked. The cover_emoji
	// and cover_color stay the fallback. cover_photo_status is for the owner
	// only: pending (under review), approved, or rejected (the last upload
	// was not approved).
	CoverPhotoURL    string        `json:"cover_photo_url,omitempty"`
	CoverPhotoID     string        `json:"cover_photo_id,omitempty"`
	CoverPhotoStatus string        `json:"cover_photo_status,omitempty"`
	CreatedAt        time.Time     `json:"created_at"`
	UpdatedAt        time.Time     `json:"updated_at"`
	Members          []groupMember `json:"members_preview,omitempty"`
}

type groupMember struct {
	UserID   string    `json:"user_id"`
	Name     string    `json:"name"`
	PhotoURL string    `json:"photo_url"`
	Role     string    `json:"role"`
	JoinedAt time.Time `json:"joined_at"`
	IsMe     bool      `json:"is_me"`
	IsFriend bool      `json:"is_friend"`
}

type groupInviteView struct {
	ID              string    `json:"id"`
	GroupID         string    `json:"group_id"`
	Status          string    `json:"status"`
	InviterID       string    `json:"inviter_user_id"`
	InviterName     string    `json:"inviter_name"`
	InviterPhotoURL string    `json:"inviter_photo_url"`
	InvitedAt       time.Time `json:"invited_at"`
	Group           groupView `json:"group"`
}

type groupFriend struct {
	UserID   string `json:"user_id"`
	Name     string `json:"name"`
	PhotoURL string `json:"photo_url"`
	// available, member or invited (for the group asked about).
	Status string `json:"status"`
}

type groupInput struct {
	ID          string
	Kind        string
	Category    string
	Name        string
	Description string
	City        string
	CoverEmoji  string
	CoverColor  string
	Invitees    []string
}

// groupRoleSQL: the effective role of member row m in group g. The group's
// created_by_user_id is the single source of truth for ownership.
const groupRoleSQL = `CASE WHEN m.user_id=g.created_by_user_id THEN 'owner' WHEN m.role='owner' THEN 'moderator' ELSE m.role END`

// groupFriendsSQL: a and b are accepted friends in both directions.
func groupFriendsSQL(a, b string) string {
	return `(EXISTS(SELECT 1 FROM matching.friend_connections f1 WHERE f1.user_id=` + a + ` AND f1.friend_user_id=` + b + ` AND f1.status='accepted')
 AND EXISTS(SELECT 1 FROM matching.friend_connections f2 WHERE f2.user_id=` + b + ` AND f2.friend_user_id=` + a + ` AND f2.status='accepted'))`
}

// groupSelect reads groups for viewer $1 (alias g).
func groupSelect() string {
	return `SELECT g.id::text,g.kind,g.visibility,COALESCE(g.category_slug,''),COALESCE(cat.title,''),COALESCE(cat.emoji,''),
 g.name,COALESCE(g.description,''),COALESCE(g.city,''),COALESCE(g.cover_emoji,''),COALESCE(g.cover_color,''),g.member_cap,
 g.created_by_user_id::text,g.created_at,g.updated_at,g.moderation_state,
 (SELECT COUNT(*) FROM matching.community_group_members cm JOIN user_management.users u ON u.id=cm.user_id
   WHERE cm.group_id=g.id AND cm.status='active' AND ` + blogActive + `),
 COALESCE((SELECT ` + groupRoleSQL + ` FROM matching.community_group_members m WHERE m.group_id=g.id AND m.user_id=$1::uuid AND m.status='active'),''),
 COALESCE((SELECT m.status FROM matching.community_group_members m WHERE m.group_id=g.id AND m.user_id=$1::uuid),''),
 COALESCE((SELECT i.id::text FROM matching.community_group_invites i WHERE i.group_id=g.id AND i.invitee_user_id=$1::uuid AND i.status='pending'),''),
 COALESCE(sc.id::text,''),
 COALESCE((SELECT COUNT(*) FROM matching.social_messages sm WHERE sm.channel_id=sc.id AND sm.sender_id<>$1::uuid
   AND sm.deleted_at IS NULL AND sm.moderation_state='active' AND ` + socialNotBlockedSQL("sm.sender_id", "$1::uuid") + `
   AND sm.created_at>COALESCE((SELECT r.last_read_at FROM matching.social_channel_reads r WHERE r.channel_id=sc.id AND r.user_id=$1::uuid),'-infinity')),0),
 COALESCE(cv.id::text,''),COALESCE(cv.moderation_status,''),(cv.id IS NOT NULL AND ` + groupCoverVisibleSQL + `),
 COALESCE((SELECT rc.delete_reason='rejected' AND rc.created_at>NOW()-interval '14 days' FROM matching.community_group_covers rc
   WHERE rc.group_id=g.id ORDER BY rc.created_at DESC,rc.id LIMIT 1),FALSE)
 FROM matching.community_groups g
 LEFT JOIN matching.group_categories cat ON cat.slug=g.category_slug
 LEFT JOIN matching.social_channels sc ON sc.kind='group' AND sc.ref_id=g.id
 LEFT JOIN matching.community_group_covers cv ON cv.group_id=g.id AND cv.deleted_at IS NULL
 WHERE TRUE`
}

// groupVisibleSQL: viewer $1 may see group g — a member, an invitee, or a
// community group whose owner neither side has blocked. A group removed after
// a review stays visible to its members only (they see a notice).
const groupVisibleSQL = ` AND (EXISTS(SELECT 1 FROM matching.community_group_members vm WHERE vm.group_id=g.id AND vm.user_id=$1::uuid AND vm.status='active')
 OR (g.moderation_state='active' AND EXISTS(SELECT 1 FROM matching.community_group_invites vi WHERE vi.group_id=g.id AND vi.invitee_user_id=$1::uuid AND vi.status='pending'))
 OR (g.kind='community' AND g.moderation_state='active' AND NOT EXISTS(SELECT 1 FROM user_management.blocked_users bl WHERE (bl.user_id=$1::uuid AND bl.blocked_user_id=g.created_by_user_id) OR (bl.user_id=g.created_by_user_id AND bl.blocked_user_id=$1::uuid))))`

func scanGroup(row interface{ Scan(...any) error }) (groupView, error) {
	var g groupView
	var myStatus, coverID, coverStatus string
	var coverVisible, recentlyRejected bool
	err := row.Scan(&g.ID, &g.Kind, &g.Visibility, &g.CategorySlug, &g.CategoryTitle, &g.CategoryEmoji,
		&g.Name, &g.Description, &g.City, &g.CoverEmoji, &g.CoverColor, &g.MemberCap,
		&g.OwnerID, &g.CreatedAt, &g.UpdatedAt, &g.ModerationState, &g.MemberCount, &g.MyRole, &myStatus, &g.InviteID, &g.ChannelID, &g.UnreadCount,
		&coverID, &coverStatus, &coverVisible, &recentlyRejected)
	if err != nil {
		return g, err
	}
	if coverVisible {
		g.CoverPhotoID, g.CoverPhotoURL = coverID, groupCoverURL(g.ID, coverID)
	}
	if g.MyRole == "owner" {
		switch {
		case coverID != "":
			g.CoverPhotoStatus = coverStatus
		case recentlyRejected:
			g.CoverPhotoStatus = "rejected"
		}
	}
	g.IsMember = g.MyRole != ""
	g.Removed = g.ModerationState == "removed"
	if !g.IsMember || g.Removed {
		// Chat and ownership details are for members only; a removed group
		// has no chat.
		g.ChannelID, g.UnreadCount = "", 0
	}
	if !g.IsMember {
		g.OwnerID = ""
	}
	g.CanManage = g.MyRole == "owner"
	g.CanInvite = g.IsMember && !g.Removed && (g.Kind == "community" || g.MyRole == "owner" || g.MyRole == "moderator")
	g.CanJoin = !g.IsMember && !g.Removed && g.Kind == "community" && myStatus != "removed" && g.MemberCount < g.MemberCap
	return g, nil
}

// readGroup returns a group the actor may see, or errDatePlanNotFound.
func readGroup(ctx context.Context, q blogQuerier, actor, groupID string) (groupView, error) {
	g, err := scanGroup(q.QueryRowContext(ctx, groupSelect()+groupVisibleSQL+` AND g.id=$2::uuid`, actor, groupID))
	if errors.Is(err, sql.ErrNoRows) {
		return g, errDatePlanNotFound
	}
	return g, err
}

func listGroupCategories(ctx context.Context, q blogQuerier) ([]groupCategory, error) {
	rows, err := q.QueryContext(ctx, `SELECT c.slug,c.title,c.emoji,c.description,c.sort_order,
 (SELECT COUNT(*) FROM matching.community_groups g WHERE g.kind='community' AND g.moderation_state='active' AND g.category_slug=c.slug)
 FROM matching.group_categories c WHERE c.is_active ORDER BY c.sort_order,c.title`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []groupCategory{}
	for rows.Next() {
		var c groupCategory
		if err = rows.Scan(&c.Slug, &c.Title, &c.Emoji, &c.Description, &c.SortOrder, &c.GroupCount); err != nil {
			return nil, err
		}
		out = append(out, c)
	}
	return out, rows.Err()
}

// listGroups: scope "mine" (active memberships, most recently active first) or
// "discover" (community groups the actor is not in, optionally by category or
// a name search, most members first).
func listGroups(ctx context.Context, q blogQuerier, actor, scope, category, search string, limit int) ([]groupView, error) {
	if limit <= 0 || limit > 50 {
		limit = 50
	}
	var query string
	args := []any{actor}
	switch scope {
	case "mine":
		query = groupSelect() + ` AND EXISTS(SELECT 1 FROM matching.community_group_members vm WHERE vm.group_id=g.id AND vm.user_id=$1::uuid AND vm.status='active')
 ORDER BY GREATEST(COALESCE(sc.last_message_at,'-infinity'),g.updated_at) DESC,g.id LIMIT $2`
		args = append(args, limit)
	case "discover":
		query = groupSelect() + groupVisibleSQL + ` AND g.kind='community' AND g.moderation_state='active'
 AND NOT EXISTS(SELECT 1 FROM matching.community_group_members vm WHERE vm.group_id=g.id AND vm.user_id=$1::uuid AND vm.status IN ('active','removed'))
 AND ($2='' OR g.category_slug=$2)
 AND ($3='' OR g.name ILIKE '%'||$3||'%' OR COALESCE(g.description,'') ILIKE '%'||$3||'%')
 ORDER BY (SELECT COUNT(*) FROM matching.community_group_members cm WHERE cm.group_id=g.id AND cm.status='active') DESC,g.updated_at DESC,g.id LIMIT $4`
		search = strings.NewReplacer(`%`, ``, `_`, ``, `\`, ``).Replace(strings.TrimSpace(search))
		args = append(args, category, search, limit)
	default:
		return nil, blogInputError("Choose your groups or discover")
	}
	rows, err := q.QueryContext(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []groupView{}
	for rows.Next() {
		g, err := scanGroup(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, g)
	}
	return out, rows.Err()
}

// readGroupMembers lists active members for a member, hiding anyone either
// side has blocked.
func readGroupMembers(ctx context.Context, q blogQuerier, actor, groupID string, limit int) ([]groupMember, error) {
	if limit <= 0 {
		limit = 500
	}
	rows, err := q.QueryContext(ctx, `SELECT m.user_id::text,`+socialMemberCardSQL("m.user_id")+`,`+groupRoleSQL+`,m.joined_at,
 m.user_id=$1::uuid,`+groupFriendsSQL("$1::uuid", "m.user_id")+`
 FROM matching.community_group_members m JOIN matching.community_groups g ON g.id=m.group_id
 JOIN user_management.users u ON u.id=m.user_id
 WHERE m.group_id=$2::uuid AND m.status='active' AND `+blogActive+`
 AND (m.user_id=$1::uuid OR `+socialNotBlockedSQL("$1::uuid", "m.user_id")+`)
 ORDER BY CASE `+groupRoleSQL+` WHEN 'owner' THEN 0 WHEN 'moderator' THEN 1 ELSE 2 END,m.joined_at,m.user_id LIMIT $3`, actor, groupID, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []groupMember{}
	for rows.Next() {
		var m groupMember
		if err = rows.Scan(&m.UserID, &m.Name, &m.PhotoURL, &m.Role, &m.JoinedAt, &m.IsMe, &m.IsFriend); err != nil {
			return nil, err
		}
		out = append(out, m)
	}
	return out, rows.Err()
}

// readGroupDetail is a group with its member preview and channel (members).
func readGroupDetail(ctx context.Context, q blogQuerier, actor, groupID string) (groupView, error) {
	g, err := readGroup(ctx, q, actor, groupID)
	if err != nil || !g.IsMember {
		return g, err
	}
	g.Members, err = readGroupMembers(ctx, q, actor, groupID, groupMembersPreview)
	return g, err
}

func groupBegin(ctx context.Context, db *sql.DB, actor string) (*sql.Tx, error) {
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return nil, err
	}
	if err = lockBlogAuthor(ctx, tx, actor); err != nil {
		_ = tx.Rollback()
		return nil, err
	}
	return tx, nil
}

// lockGroup locks the group row and returns its kind, owner and member cap.
func lockGroup(ctx context.Context, tx *sql.Tx, groupID string) (kind, owner, name string, capacity int, err error) {
	err = tx.QueryRowContext(ctx, `SELECT kind,created_by_user_id::text,name,member_cap FROM matching.community_groups WHERE id=$1::uuid FOR UPDATE`, groupID).
		Scan(&kind, &owner, &name, &capacity)
	if errors.Is(err, sql.ErrNoRows) {
		err = errDatePlanNotFound
	}
	return
}

var errGroupRemoved = activityFail(403, "This group was removed after a review.")

// checkGroupActive refuses joining, inviting, accepting and editing while the
// group is removed after a review.
func checkGroupActive(ctx context.Context, q blogQuerier, groupID string) error {
	var state string
	err := q.QueryRowContext(ctx, `SELECT moderation_state FROM matching.community_groups WHERE id=$1::uuid`, groupID).Scan(&state)
	if errors.Is(err, sql.ErrNoRows) {
		return errDatePlanNotFound
	}
	if err != nil {
		return err
	}
	if state != "active" {
		return errGroupRemoved
	}
	return nil
}

// groupRole is the actor's effective role in a group, or "" if not active.
func groupRole(ctx context.Context, q blogQuerier, groupID, userID string) (string, error) {
	var role string
	err := q.QueryRowContext(ctx, `SELECT `+groupRoleSQL+` FROM matching.community_group_members m JOIN matching.community_groups g ON g.id=m.group_id
 WHERE m.group_id=$1::uuid AND m.user_id=$2::uuid AND m.status='active'`, groupID, userID).Scan(&role)
	if errors.Is(err, sql.ErrNoRows) {
		return "", nil
	}
	return role, err
}

func activeGroupMemberCount(ctx context.Context, q blogQuerier, groupID string) (int, error) {
	var n int
	err := q.QueryRowContext(ctx, `SELECT COUNT(*) FROM matching.community_group_members WHERE group_id=$1::uuid AND status='active'`, groupID).Scan(&n)
	return n, err
}

func normalizeGroupInput(in *groupInput, creating bool) error {
	in.Kind = strings.TrimSpace(strings.ToLower(in.Kind))
	in.Category = strings.TrimSpace(strings.ToLower(in.Category))
	in.Name = strings.Join(strings.Fields(in.Name), " ")
	in.Description = strings.TrimSpace(in.Description)
	in.City = strings.Join(strings.Fields(in.City), " ")
	in.CoverEmoji = strings.TrimSpace(in.CoverEmoji)
	in.CoverColor = strings.TrimSpace(strings.ToLower(in.CoverColor))
	if creating && in.Kind != "community" && in.Kind != "private" {
		return blogInputError("Choose a community group or a private group")
	}
	if runeLen(in.Name) < 3 || runeLen(in.Name) > 60 {
		return blogInputError("Give your group a name of 3–60 characters")
	}
	if runeLen(in.Description) > 500 {
		return blogInputError("Keep the description under 500 characters")
	}
	if runeLen(in.City) > 60 {
		return blogInputError("Keep the city under 60 characters")
	}
	if runeLen(in.CoverEmoji) > 8 {
		return blogInputError("Choose a single emoji for the cover")
	}
	if in.CoverColor != "" && in.CoverColor != "primary" && in.CoverColor != "secondary" && in.CoverColor != "tertiary" {
		return blogInputError("Choose a cover colour from the palette")
	}
	return nil
}

// normalizeInvitees de-duplicates ids, drops the actor and validates shape.
func normalizeInvitees(actor string, ids []string) ([]string, error) {
	seen := map[string]bool{}
	out := []string{}
	for _, raw := range ids {
		id := strings.TrimSpace(raw)
		if id == "" || id == actor || seen[id] {
			continue
		}
		if _, err := uuid.Parse(id); err != nil {
			return nil, blogInputError("Choose friends from your friends list")
		}
		seen[id] = true
		out = append(out, id)
	}
	if len(out) > groupMaxInvitesPerRequest {
		return nil, blogInputError("Invite up to 50 friends at a time")
	}
	return out, nil
}

// checkGroupCategory: community groups need an active category; private
// groups may have one.
func checkGroupCategory(ctx context.Context, q blogQuerier, kind, slug string) error {
	if slug == "" {
		if kind == "community" {
			return blogInputError("Pick a lifestyle category for your community group")
		}
		return nil
	}
	var ok bool
	if err := q.QueryRowContext(ctx, `SELECT EXISTS(SELECT 1 FROM matching.group_categories WHERE slug=$1 AND is_active)`, slug).Scan(&ok); err != nil {
		return err
	}
	if !ok {
		return blogInputError("Pick a lifestyle category from the list")
	}
	return nil
}

var errGroupInviteeNotFriend = activityFail(403, "You can invite accepted friends only, and nobody you've blocked or who has blocked you.")

// inviteFriendsTx creates or refreshes pending invitations from actor and
// notifies each invitee. Every invitee must be an accepted, unblocked friend
// of the actor and an active member. Existing members are skipped.
func inviteFriendsTx(ctx context.Context, tx *sql.Tx, actor, groupID, groupName string, invitees []string) ([]string, error) {
	if len(invitees) == 0 {
		return []string{}, nil
	}
	var sentToday int
	if err := tx.QueryRowContext(ctx, `SELECT COUNT(*) FROM matching.community_group_invites WHERE inviter_user_id=$1::uuid AND invited_at>NOW()-interval '1 day'`, actor).Scan(&sentToday); err != nil {
		return nil, err
	}
	if sentToday+len(invitees) > groupMaxInvitesPerDay {
		return nil, activityFail(429, "You've sent a lot of group invitations today. Try again tomorrow.")
	}
	for _, id := range invitees {
		var ok bool
		if err := tx.QueryRowContext(ctx, `SELECT EXISTS(SELECT 1 FROM user_management.users u WHERE u.id=$2::uuid AND `+blogActive+`)
 AND `+groupFriendsSQL("$1::uuid", "$2::uuid")+` AND `+socialNotBlockedSQL("$1::uuid", "$2::uuid"), actor, id).Scan(&ok); err != nil {
			return nil, err
		}
		if !ok {
			return nil, errGroupInviteeNotFriend
		}
	}
	inviterName := memberName(ctx, tx, actor, "A friend")
	invited := []string{}
	for _, id := range invitees {
		var inviteID string
		var invitedAt time.Time
		err := tx.QueryRowContext(ctx, `INSERT INTO matching.community_group_invites(group_id,inviter_user_id,invitee_user_id,status,invited_at)
 SELECT $1::uuid,$2::uuid,$3::uuid,'pending',NOW()
 WHERE NOT EXISTS(SELECT 1 FROM matching.community_group_members m WHERE m.group_id=$1::uuid AND m.user_id=$3::uuid AND m.status='active')
 ON CONFLICT (group_id,invitee_user_id) DO UPDATE SET inviter_user_id=EXCLUDED.inviter_user_id,status='pending',invited_at=NOW(),responded_at=NULL
   WHERE matching.community_group_invites.status<>'pending'
 RETURNING id::text,invited_at`, groupID, actor, id).Scan(&inviteID, &invitedAt)
		if errors.Is(err, sql.ErrNoRows) {
			continue // already a member, or an invitation is already pending
		}
		if err != nil {
			return nil, err
		}
		invited = append(invited, id)
		if err = enqueueNotificationTx(ctx, tx, id, actor, "group.invite.received", "system", groupID,
			"group-invite:"+inviteID+":"+strconv.FormatInt(invitedAt.UnixMicro(), 10),
			inviterName+" invited you to "+groupName, "Open Groups to join them, or decline.", "/groups",
			map[string]any{"group_id": groupID, "invite_id": inviteID}, 3); err != nil {
			return nil, err
		}
	}
	return invited, nil
}

// joinGroupTx makes the actor an active member and marks the chat read up to
// now, so a newcomer is not greeted by a wall of unread messages.
func joinGroupTx(ctx context.Context, tx *sql.Tx, actor, groupID, role, invitedBy string) error {
	if _, err := tx.ExecContext(ctx, `INSERT INTO matching.community_group_members(group_id,user_id,status,role,joined_at,updated_at,invited_by_user_id,left_at)
 VALUES($1::uuid,$2::uuid,'active',$3,NOW(),NOW(),NULLIF($4,'')::uuid,NULL)
 ON CONFLICT (group_id,user_id) DO UPDATE SET status='active',role=EXCLUDED.role,joined_at=NOW(),updated_at=NOW(),
  invited_by_user_id=COALESCE(EXCLUDED.invited_by_user_id,matching.community_group_members.invited_by_user_id),left_at=NULL`,
		groupID, actor, role, invitedBy); err != nil {
		return err
	}
	channelID, err := ensureRefChannel(ctx, tx, "group", groupID)
	if err != nil {
		return err
	}
	if _, err = tx.ExecContext(ctx, `INSERT INTO matching.social_channel_reads(channel_id,user_id,last_read_at) VALUES($1,$2,NOW())
 ON CONFLICT (channel_id,user_id) DO UPDATE SET last_read_at=NOW()`, channelID, actor); err != nil {
		return err
	}
	_, err = tx.ExecContext(ctx, `UPDATE matching.community_groups SET updated_at=NOW() WHERE id=$1::uuid`, groupID)
	return err
}

func checkJoinLimits(ctx context.Context, tx *sql.Tx, actor, groupID string, capacity int) error {
	count, err := activeGroupMemberCount(ctx, tx, groupID)
	if err != nil {
		return err
	}
	if count >= capacity {
		return activityFail(409, "This group is full.")
	}
	var joined int
	if err = tx.QueryRowContext(ctx, `SELECT COUNT(*) FROM matching.community_group_members WHERE user_id=$1::uuid AND status='active'`, actor).Scan(&joined); err != nil {
		return err
	}
	if joined >= groupMaxJoined {
		return activityFail(409, "You're in 50 groups already. Leave one to join another.")
	}
	return nil
}

// createGroup creates a group owned by the actor and invites the chosen
// friends. A repeated id from the same owner returns the group unchanged.
func createGroup(ctx context.Context, db *sql.DB, actor string, in groupInput) (groupView, []string, error) {
	if err := normalizeGroupInput(&in, true); err != nil {
		return groupView{}, nil, err
	}
	invitees, err := normalizeInvitees(actor, in.Invitees)
	if err != nil {
		return groupView{}, nil, err
	}
	if in.ID == "" {
		in.ID = uuid.NewString()
	} else if _, err = uuid.Parse(in.ID); err != nil {
		return groupView{}, nil, blogInputError("group_id must be a UUID")
	}
	tx, err := groupBegin(ctx, db, actor)
	if err != nil {
		return groupView{}, nil, err
	}
	defer tx.Rollback()
	var existingOwner string
	err = tx.QueryRowContext(ctx, `SELECT created_by_user_id::text FROM matching.community_groups WHERE id=$1::uuid`, in.ID).Scan(&existingOwner)
	switch {
	case err == nil && existingOwner == actor:
		g, e := readGroupDetail(ctx, tx, actor, in.ID)
		if e != nil {
			return g, nil, e
		}
		return g, []string{}, tx.Commit()
	case err == nil:
		return groupView{}, nil, errDatingConflict
	case !errors.Is(err, sql.ErrNoRows):
		return groupView{}, nil, err
	}
	if err = checkGroupCategory(ctx, tx, in.Kind, in.Category); err != nil {
		return groupView{}, nil, err
	}
	var owned, joined int
	if err = tx.QueryRowContext(ctx, `SELECT (SELECT COUNT(*) FROM matching.community_groups WHERE created_by_user_id=$1::uuid),
 (SELECT COUNT(*) FROM matching.community_group_members WHERE user_id=$1::uuid AND status='active')`, actor).Scan(&owned, &joined); err != nil {
		return groupView{}, nil, err
	}
	if owned >= groupMaxOwned {
		return groupView{}, nil, activityFail(409, "You can run up to 10 groups at a time.")
	}
	if joined >= groupMaxJoined {
		return groupView{}, nil, activityFail(409, "You're in 50 groups already. Leave one to start another.")
	}
	visibility, capacity := "private", groupPrivateCap
	if in.Kind == "community" {
		visibility, capacity = "public", groupCommunityCap
	}
	if len(invitees)+1 > capacity {
		return groupView{}, nil, blogInputError("That's more people than this group can hold")
	}
	if _, err = tx.ExecContext(ctx, `INSERT INTO matching.community_groups(id,name,city,topic,description,visibility,created_by_user_id,kind,category_slug,cover_emoji,cover_color,member_cap)
 VALUES($1::uuid,$2,$3,COALESCE((SELECT title FROM matching.group_categories WHERE slug=NULLIF($8,'')),''),$4,$5,$6::uuid,$7,NULLIF($8,''),NULLIF($9,''),NULLIF($10,''),$11)`,
		in.ID, in.Name, in.City, in.Description, visibility, actor, in.Kind, in.Category, in.CoverEmoji, in.CoverColor, capacity); err != nil {
		return groupView{}, nil, err
	}
	if err = joinGroupTx(ctx, tx, actor, in.ID, "owner", ""); err != nil {
		return groupView{}, nil, err
	}
	invited, err := inviteFriendsTx(ctx, tx, actor, in.ID, in.Name, invitees)
	if err != nil {
		return groupView{}, nil, err
	}
	g, err := readGroupDetail(ctx, tx, actor, in.ID)
	if err != nil {
		return g, nil, err
	}
	return g, invited, tx.Commit()
}

// inviteToGroup invites more friends. Community groups: any member. Private
// groups: the owner and moderators.
func inviteToGroup(ctx context.Context, db *sql.DB, actor, groupID string, ids []string) ([]string, error) {
	invitees, err := normalizeInvitees(actor, ids)
	if err != nil {
		return nil, err
	}
	if len(invitees) == 0 {
		return nil, blogInputError("Choose at least one friend to invite")
	}
	tx, err := groupBegin(ctx, db, actor)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback()
	kind, _, name, capacity, err := lockGroup(ctx, tx, groupID)
	if err != nil {
		return nil, err
	}
	role, err := groupRole(ctx, tx, groupID, actor)
	if err != nil {
		return nil, err
	}
	if role == "" {
		return nil, errDatePlanNotFound
	}
	if err = checkGroupActive(ctx, tx, groupID); err != nil {
		return nil, err
	}
	if kind == "private" && role == "member" {
		return nil, activityFail(403, "Only the group owner and moderators can invite people to a private group.")
	}
	count, err := activeGroupMemberCount(ctx, tx, groupID)
	if err != nil {
		return nil, err
	}
	if count >= capacity {
		return nil, activityFail(409, "This group is full.")
	}
	// Re-inviting someone a moderator removed needs a moderator.
	if role == "member" {
		var removed bool
		for _, id := range invitees {
			if err = tx.QueryRowContext(ctx, `SELECT EXISTS(SELECT 1 FROM matching.community_group_members WHERE group_id=$1::uuid AND user_id=$2::uuid AND status='removed')`, groupID, id).Scan(&removed); err != nil {
				return nil, err
			}
			if removed {
				return nil, activityFail(403, "A moderator removed one of these friends. Ask the owner or a moderator to invite them.")
			}
		}
	}
	invited, err := inviteFriendsTx(ctx, tx, actor, groupID, name, invitees)
	if err != nil {
		return nil, err
	}
	return invited, tx.Commit()
}

// listGroupInvites lists the actor's pending invitations, hiding any from
// someone either side has blocked.
func listGroupInvites(ctx context.Context, q blogQuerier, actor string) ([]groupInviteView, error) {
	rows, err := q.QueryContext(ctx, `SELECT i.id::text,i.group_id::text,i.status,i.inviter_user_id::text,`+socialMemberCardSQL("i.inviter_user_id")+`,i.invited_at
 FROM matching.community_group_invites i
 WHERE i.invitee_user_id=$1::uuid AND i.status='pending' AND `+socialNotBlockedSQL("i.inviter_user_id", "$1::uuid")+`
 ORDER BY i.invited_at DESC LIMIT 100`, actor)
	if err != nil {
		return nil, err
	}
	invites := []groupInviteView{}
	for rows.Next() {
		var v groupInviteView
		if err = rows.Scan(&v.ID, &v.GroupID, &v.Status, &v.InviterID, &v.InviterName, &v.InviterPhotoURL, &v.InvitedAt); err != nil {
			rows.Close()
			return nil, err
		}
		invites = append(invites, v)
	}
	err = rows.Err()
	rows.Close()
	if err != nil {
		return nil, err
	}
	out := []groupInviteView{}
	for _, v := range invites {
		g, err := readGroup(ctx, q, actor, v.GroupID)
		if errors.Is(err, errDatePlanNotFound) {
			continue
		}
		if err != nil {
			return nil, err
		}
		v.Group = g
		out = append(out, v)
	}
	return out, nil
}

// respondGroupInvite accepts or declines the actor's pending invitation.
func respondGroupInvite(ctx context.Context, db *sql.DB, actor, groupID, decision string) (groupView, error) {
	decision = strings.ToLower(strings.TrimSpace(decision))
	switch decision {
	case "accept", "accepted":
		decision = "accept"
	case "decline", "declined":
		decision = "decline"
	default:
		return groupView{}, blogInputError("Choose accept or decline")
	}
	tx, err := groupBegin(ctx, db, actor)
	if err != nil {
		return groupView{}, err
	}
	defer tx.Rollback()
	_, _, name, capacity, err := lockGroup(ctx, tx, groupID)
	if err != nil {
		return groupView{}, err
	}
	var inviteID, inviter, status string
	err = tx.QueryRowContext(ctx, `SELECT id::text,inviter_user_id::text,status FROM matching.community_group_invites WHERE group_id=$1::uuid AND invitee_user_id=$2::uuid FOR UPDATE`, groupID, actor).
		Scan(&inviteID, &inviter, &status)
	if errors.Is(err, sql.ErrNoRows) {
		return groupView{}, activityFail(404, "This invitation is no longer available.")
	}
	if err != nil {
		return groupView{}, err
	}
	role, err := groupRole(ctx, tx, groupID, actor)
	if err != nil {
		return groupView{}, err
	}
	// Retried responses return the settled result.
	if status != "pending" {
		if (status == "accepted" && role != "") || status == "declined" {
			g, e := readGroupDetail(ctx, tx, actor, groupID)
			if errors.Is(e, errDatePlanNotFound) && status == "declined" {
				return groupView{ID: groupID}, tx.Commit()
			}
			if e != nil {
				return g, e
			}
			return g, tx.Commit()
		}
		return groupView{}, activityFail(404, "This invitation is no longer available.")
	}
	if decision == "decline" {
		if _, err = tx.ExecContext(ctx, `UPDATE matching.community_group_invites SET status='declined',responded_at=NOW() WHERE id=$1::uuid`, inviteID); err != nil {
			return groupView{}, err
		}
		g, e := readGroup(ctx, tx, actor, groupID)
		if errors.Is(e, errDatePlanNotFound) {
			return groupView{ID: groupID}, tx.Commit()
		}
		if e != nil {
			return g, e
		}
		return g, tx.Commit()
	}
	if role == "" {
		if err = checkGroupActive(ctx, tx, groupID); err != nil {
			return groupView{}, err
		}
		if err = checkJoinLimits(ctx, tx, actor, groupID, capacity); err != nil {
			return groupView{}, err
		}
		if err = joinGroupTx(ctx, tx, actor, groupID, "member", inviter); err != nil {
			return groupView{}, err
		}
	}
	if _, err = tx.ExecContext(ctx, `UPDATE matching.community_group_invites SET status='accepted',responded_at=NOW() WHERE id=$1::uuid`, inviteID); err != nil {
		return groupView{}, err
	}
	var notBlocked bool
	if err = tx.QueryRowContext(ctx, `SELECT `+socialNotBlockedSQL("$1::uuid", "$2::uuid"), actor, inviter).Scan(&notBlocked); err != nil {
		return groupView{}, err
	}
	if notBlocked {
		if err = enqueueNotificationTx(ctx, tx, inviter, actor, "group.invite.accepted", "system", groupID,
			"group-invite-accepted:"+inviteID+":"+actor, memberName(ctx, tx, actor, "A friend")+" joined "+name,
			"Say hello in the group chat.", "/groups", map[string]any{"group_id": groupID, "invite_id": inviteID}, 4); err != nil {
			return groupView{}, err
		}
	}
	g, err := readGroupDetail(ctx, tx, actor, groupID)
	if err != nil {
		return g, err
	}
	return g, tx.Commit()
}

// joinCommunityGroup joins a community group directly.
func joinCommunityGroup(ctx context.Context, db *sql.DB, actor, groupID string) (groupView, error) {
	tx, err := groupBegin(ctx, db, actor)
	if err != nil {
		return groupView{}, err
	}
	defer tx.Rollback()
	if _, err = readGroup(ctx, tx, actor, groupID); err != nil {
		return groupView{}, err
	}
	kind, _, _, capacity, err := lockGroup(ctx, tx, groupID)
	if err != nil {
		return groupView{}, err
	}
	var status string
	err = tx.QueryRowContext(ctx, `SELECT status FROM matching.community_group_members WHERE group_id=$1::uuid AND user_id=$2::uuid`, groupID, actor).Scan(&status)
	if err != nil && !errors.Is(err, sql.ErrNoRows) {
		return groupView{}, err
	}
	switch {
	case status == "active":
		// Already in: a retried join returns the group.
	case kind != "community":
		return groupView{}, activityFail(403, "This is a private group. You can join when a member invites you.")
	case status == "removed":
		return groupView{}, activityFail(403, "A moderator removed you from this group.")
	default:
		if err = checkGroupActive(ctx, tx, groupID); err != nil {
			return groupView{}, err
		}
		if err = checkJoinLimits(ctx, tx, actor, groupID, capacity); err != nil {
			return groupView{}, err
		}
		if err = joinGroupTx(ctx, tx, actor, groupID, "member", ""); err != nil {
			return groupView{}, err
		}
		if _, err = tx.ExecContext(ctx, `UPDATE matching.community_group_invites SET status='accepted',responded_at=NOW() WHERE group_id=$1::uuid AND invitee_user_id=$2::uuid AND status='pending'`, groupID, actor); err != nil {
			return groupView{}, err
		}
	}
	g, err := readGroupDetail(ctx, tx, actor, groupID)
	if err != nil {
		return g, err
	}
	return g, tx.Commit()
}

// groupSuccessorSQL: the longest-standing moderator, else member, other than $2.
const groupSuccessorSQL = `SELECT m.user_id::text FROM matching.community_group_members m JOIN user_management.users u ON u.id=m.user_id
 WHERE m.group_id=$1::uuid AND m.user_id<>$2::uuid AND m.status='active' AND ` + blogActive + `
 ORDER BY (m.role IN ('owner','moderator')) DESC,m.joined_at,m.user_id LIMIT 1`

// deleteGroupTx removes a group, its invitations, memberships and chat. Its
// cover rows are tombstoned; the caller releases their objects after commit
// (releaseGroupCoverMedia), and the media worker retries.
func deleteGroupTx(ctx context.Context, tx *sql.Tx, groupID string) error {
	if _, err := tx.ExecContext(ctx, `DELETE FROM matching.social_channels WHERE kind='group' AND ref_id=$1::uuid`, groupID); err != nil {
		return err
	}
	if _, err := tx.ExecContext(ctx, `UPDATE matching.community_group_covers SET deleted_at=NOW(),delete_reason='group_deleted'
 WHERE group_id=$1::uuid AND deleted_at IS NULL`, groupID); err != nil {
		return err
	}
	_, err := tx.ExecContext(ctx, `DELETE FROM matching.community_groups WHERE id=$1::uuid`, groupID)
	return err
}

// leaveGroup: the owner hands over to the longest-standing moderator or
// member; an owner alone deletes the group.
func leaveGroup(ctx context.Context, db *sql.DB, actor, groupID string) (map[string]any, error) {
	tx, err := groupBegin(ctx, db, actor)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback()
	_, owner, _, _, err := lockGroup(ctx, tx, groupID)
	if err != nil {
		return nil, err
	}
	role, err := groupRole(ctx, tx, groupID, actor)
	if err != nil {
		return nil, err
	}
	result := map[string]any{"left": true, "deleted": false, "group_id": groupID}
	if role == "" {
		return result, tx.Commit()
	}
	if owner == actor {
		var successor string
		err = tx.QueryRowContext(ctx, groupSuccessorSQL, groupID, actor).Scan(&successor)
		if errors.Is(err, sql.ErrNoRows) {
			if err = deleteGroupTx(ctx, tx, groupID); err != nil {
				return nil, err
			}
			result["deleted"] = true
			return result, tx.Commit()
		}
		if err != nil {
			return nil, err
		}
		if _, err = tx.ExecContext(ctx, `UPDATE matching.community_groups SET created_by_user_id=$2::uuid,updated_at=NOW() WHERE id=$1::uuid`, groupID, successor); err != nil {
			return nil, err
		}
		if _, err = tx.ExecContext(ctx, `UPDATE matching.community_group_members SET role='owner',updated_at=NOW() WHERE group_id=$1::uuid AND user_id=$2::uuid`, groupID, successor); err != nil {
			return nil, err
		}
		result["new_owner_user_id"] = successor
	}
	if _, err = tx.ExecContext(ctx, `UPDATE matching.community_group_members SET status='left',role='member',left_at=NOW(),updated_at=NOW() WHERE group_id=$1::uuid AND user_id=$2::uuid`, groupID, actor); err != nil {
		return nil, err
	}
	return result, tx.Commit()
}

// manageGroupMember: the owner promotes, demotes and removes; moderators
// remove plain members.
func manageGroupMember(ctx context.Context, db *sql.DB, actor, groupID, target, action string) ([]groupMember, error) {
	if action != "make_moderator" && action != "make_member" && action != "remove" {
		return nil, blogInputError("Choose make_moderator, make_member or remove")
	}
	if target == actor {
		return nil, blogInputError("Use Leave to change your own membership")
	}
	tx, err := groupBegin(ctx, db, actor)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback()
	if _, _, _, _, err = lockGroup(ctx, tx, groupID); err != nil {
		return nil, err
	}
	mine, err := groupRole(ctx, tx, groupID, actor)
	if err != nil {
		return nil, err
	}
	if mine == "" {
		return nil, errDatePlanNotFound
	}
	theirs, err := groupRole(ctx, tx, groupID, target)
	if err != nil {
		return nil, err
	}
	if theirs == "" {
		return nil, errDatePlanNotFound
	}
	allowed := false
	switch action {
	case "make_moderator", "make_member":
		allowed = mine == "owner" && theirs != "owner"
	case "remove":
		allowed = (mine == "owner" && theirs != "owner") || (mine == "moderator" && theirs == "member")
	}
	if !allowed {
		return nil, activityFail(403, "Only the group owner, or a moderator for members, can do that.")
	}
	if action == "remove" {
		_, err = tx.ExecContext(ctx, `UPDATE matching.community_group_members SET status='removed',role='member',left_at=NOW(),updated_at=NOW() WHERE group_id=$1::uuid AND user_id=$2::uuid AND status='active'`, groupID, target)
	} else {
		role := map[string]string{"make_moderator": "moderator", "make_member": "member"}[action]
		_, err = tx.ExecContext(ctx, `UPDATE matching.community_group_members SET role=$3,updated_at=NOW() WHERE group_id=$1::uuid AND user_id=$2::uuid AND status='active'`, groupID, target, role)
	}
	if err != nil {
		return nil, err
	}
	members, err := readGroupMembers(ctx, tx, actor, groupID, 0)
	if err != nil {
		return nil, err
	}
	return members, tx.Commit()
}

// updateGroup edits name, description, city, cover and (community groups)
// category. Owner only; a group never switches between community and private.
func updateGroup(ctx context.Context, db *sql.DB, actor, groupID string, body map[string]any) (groupView, error) {
	tx, err := groupBegin(ctx, db, actor)
	if err != nil {
		return groupView{}, err
	}
	defer tx.Rollback()
	kind, owner, _, _, err := lockGroup(ctx, tx, groupID)
	if err != nil {
		return groupView{}, err
	}
	if role, e := groupRole(ctx, tx, groupID, actor); e != nil {
		return groupView{}, e
	} else if role == "" {
		return groupView{}, errDatePlanNotFound
	}
	if owner != actor {
		return groupView{}, activityFail(403, "Only the group owner can edit the group.")
	}
	// The reviewed content stays as reviewed until a decision restores it.
	if err = checkGroupActive(ctx, tx, groupID); err != nil {
		return groupView{}, err
	}
	g, err := readGroup(ctx, tx, actor, groupID)
	if err != nil {
		return g, err
	}
	in := groupInput{Kind: kind, Category: g.CategorySlug, Name: g.Name, Description: g.Description, City: g.City, CoverEmoji: g.CoverEmoji, CoverColor: g.CoverColor}
	if requested := strings.TrimSpace(toString(body["kind"])); requested != "" && requested != kind {
		return groupView{}, blogInputError("A group cannot switch between community and private")
	}
	set := func(key string, target *string) {
		if v, ok := body[key]; ok {
			*target = toString(v)
		}
	}
	set("name", &in.Name)
	set("description", &in.Description)
	set("city", &in.City)
	set("cover_emoji", &in.CoverEmoji)
	set("cover_color", &in.CoverColor)
	set("category_slug", &in.Category)
	if err = normalizeGroupInput(&in, false); err != nil {
		return groupView{}, err
	}
	if err = checkGroupCategory(ctx, tx, kind, in.Category); err != nil {
		return groupView{}, err
	}
	if _, err = tx.ExecContext(ctx, `UPDATE matching.community_groups SET name=$2,description=$3,city=$4,cover_emoji=NULLIF($5,''),cover_color=NULLIF($6,''),
 category_slug=NULLIF($7,''),topic=COALESCE((SELECT title FROM matching.group_categories WHERE slug=NULLIF($7,'')),topic),updated_at=NOW() WHERE id=$1::uuid`,
		groupID, in.Name, in.Description, in.City, in.CoverEmoji, in.CoverColor, in.Category); err != nil {
		return groupView{}, err
	}
	g, err = readGroupDetail(ctx, tx, actor, groupID)
	if err != nil {
		return g, err
	}
	return g, tx.Commit()
}

// deleteGroup removes a group for everyone. Owner only.
func deleteGroup(ctx context.Context, db *sql.DB, actor, groupID string) error {
	tx, err := groupBegin(ctx, db, actor)
	if err != nil {
		return err
	}
	defer tx.Rollback()
	_, owner, _, _, err := lockGroup(ctx, tx, groupID)
	if err != nil {
		return err
	}
	if owner != actor {
		if role, e := groupRole(ctx, tx, groupID, actor); e != nil {
			return e
		} else if role == "" {
			return errDatePlanNotFound
		}
		return activityFail(403, "Only the group owner can delete the group.")
	}
	if err = deleteGroupTx(ctx, tx, groupID); err != nil {
		return err
	}
	return tx.Commit()
}

// listGroupFriends lists the actor's accepted, unblocked friends with their
// standing in groupID (available, member or invited) for the invite picker.
func listGroupFriends(ctx context.Context, q blogQuerier, actor, groupID string) ([]groupFriend, error) {
	rows, err := q.QueryContext(ctx, `SELECT f.friend_user_id::text,`+socialMemberCardSQL("f.friend_user_id")+`,
 CASE WHEN $2='' THEN 'available'
  WHEN EXISTS(SELECT 1 FROM matching.community_group_members m WHERE m.group_id=NULLIF($2,'')::uuid AND m.user_id=f.friend_user_id AND m.status='active') THEN 'member'
  WHEN EXISTS(SELECT 1 FROM matching.community_group_invites i WHERE i.group_id=NULLIF($2,'')::uuid AND i.invitee_user_id=f.friend_user_id AND i.status='pending') THEN 'invited'
  ELSE 'available' END
 FROM matching.friend_connections f JOIN user_management.users u ON u.id=f.friend_user_id
 WHERE f.user_id=$1::uuid AND f.status='accepted' AND `+blogActive+`
 AND EXISTS(SELECT 1 FROM matching.friend_connections r WHERE r.user_id=f.friend_user_id AND r.friend_user_id=$1::uuid AND r.status='accepted')
 AND `+socialNotBlockedSQL("$1::uuid", "f.friend_user_id")+`
 ORDER BY lower(COALESCE(NULLIF(u.name,''),u.username,'')),f.friend_user_id LIMIT 500`, actor, groupID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []groupFriend{}
	for rows.Next() {
		var f groupFriend
		if err = rows.Scan(&f.UserID, &f.Name, &f.PhotoURL, &f.Status); err != nil {
			return nil, err
		}
		out = append(out, f)
	}
	return out, rows.Err()
}

// readGroupForReport captures a whole group for the moderation case queue
// (content type "group"). Anyone who can see the group may report it: any
// member, an invitee, or anyone who can see a community group. The reported
// content is what they see: name, description, category and cover. The
// subject is the owner. The cover photo the reporter sees (if any) is
// returned as the case's photo, so createBlogCase copies it into
// matching.blog_evidence_photos and it outlives a later replacement.
func readGroupForReport(ctx context.Context, q blogQuerier, actor, groupID string) (string, any, []string, error) {
	if _, err := uuid.Parse(groupID); err != nil {
		return "", nil, nil, errDatePlanNotFound
	}
	g, err := readGroup(ctx, q, actor, groupID)
	if err != nil {
		return "", nil, nil, err
	}
	var owner string
	if err = q.QueryRowContext(ctx, `SELECT created_by_user_id::text FROM matching.community_groups WHERE id=$1::uuid`, groupID).Scan(&owner); err != nil {
		return "", nil, nil, err
	}
	var photos []string
	if g.CoverPhotoID != "" {
		photos = []string{g.CoverPhotoID}
	}
	return owner, map[string]any{
		"title":          "Group · " + g.Name,
		"body":           g.Description,
		"name":           g.Name,
		"description":    g.Description,
		"kind":           g.Kind,
		"category_slug":  g.CategorySlug,
		"category_title": g.CategoryTitle,
		"city":           g.City,
		"cover_emoji":    g.CoverEmoji,
		"owner_user_id":  owner,
		"member_count":   g.MemberCount,
		"cover_photo_id": g.CoverPhotoID,
	}, photos, nil
}
