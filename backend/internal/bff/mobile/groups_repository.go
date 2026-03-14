package mobile

import (
	"context"
	"crypto/rand"
	"errors"
	"fmt"
	"net/url"
	"strings"
	"time"

	"github.com/verified-dating/backend/internal/platform/config"
	"github.com/verified-dating/backend/internal/platform/supabase"
)

type communityGroupRepository struct {
	cfg config.Config
	db  *supabase.Client
}

func newCommunityGroupRepository(cfg config.Config) *communityGroupRepository {
	apiKey := strings.TrimSpace(cfg.SupabaseServiceRole)
	if apiKey == "" {
		apiKey = strings.TrimSpace(cfg.SupabaseAnonKey)
	}
	if strings.TrimSpace(cfg.SupabaseURL) == "" || apiKey == "" {
		return nil
	}
	client := supabase.NewClient(
		cfg.SupabaseURL,
		cfg.SupabaseAnonKey,
		cfg.SupabaseServiceRole,
		time.Duration(cfg.SupabaseHTTPTimeoutSec)*time.Second,
	)
	client.SetReadBaseURL(cfg.SupabaseReadReplicaURL)
	return &communityGroupRepository{cfg: cfg, db: client}
}

func (r *communityGroupRepository) createGroup(
	ctx context.Context,
	ownerUserID,
	name,
	city,
	topic,
	description,
	visibility string,
	inviteeUserIDs []string,
	now time.Time,
) (communityGroupView, []communityGroupInviteView, error) {
	ownerID := strings.TrimSpace(ownerUserID)
	groupName := strings.TrimSpace(name)
	groupCity := strings.TrimSpace(city)
	groupTopic := strings.TrimSpace(topic)
	groupDescription := strings.TrimSpace(description)
	if ownerID == "" || groupName == "" || groupCity == "" || groupTopic == "" {
		return communityGroupView{}, nil, errors.New("owner_user_id, name, city, and topic are required")
	}

	timestamp := now.UTC().Format(time.RFC3339)
	groupID := newGroupUUID()
	rows, err := r.db.Insert(ctx, r.cfg.MatchingSchema, r.cfg.CommunityGroupsTable, []map[string]any{{
		"id":                 groupID,
		"name":               groupName,
		"city":               groupCity,
		"topic":              groupTopic,
		"description":        groupDescription,
		"visibility":         normalizeCommunityVisibility(visibility),
		"created_by_user_id": ownerID,
		"created_at":         timestamp,
		"updated_at":         timestamp,
	}})
	if err != nil {
		return communityGroupView{}, nil, err
	}
	if len(rows) == 0 {
		return communityGroupView{}, nil, errors.New("community group persistence returned empty result")
	}

	_, err = r.db.Upsert(ctx, r.cfg.MatchingSchema, r.cfg.CommunityGroupMembersTable, []map[string]any{{
		"group_id":           groupID,
		"user_id":            ownerID,
		"role":               communityGroupRoleOwner,
		"status":             "active",
		"invited_by_user_id": nil,
		"joined_at":          timestamp,
		"left_at":            nil,
	}}, "group_id,user_id")
	if err != nil {
		return communityGroupView{}, nil, err
	}

	invites, err := r.createInvites(ctx, groupID, ownerID, inviteeUserIDs, now)
	if err != nil {
		return communityGroupView{}, nil, err
	}

	group, _, err := r.getGroupView(ctx, groupID, ownerID)
	if err != nil {
		return communityGroupView{}, nil, err
	}
	return group, invites, nil
}

func (r *communityGroupRepository) createInvites(
	ctx context.Context,
	groupID,
	inviterUserID string,
	inviteeUserIDs []string,
	now time.Time,
) ([]communityGroupInviteView, error) {
	trimmedGroupID := strings.TrimSpace(groupID)
	trimmedInviter := strings.TrimSpace(inviterUserID)
	if trimmedGroupID == "" || trimmedInviter == "" {
		return nil, errors.New("group_id and inviter_user_id are required")
	}

	record, found, err := r.getGroupRecord(ctx, trimmedGroupID)
	if err != nil {
		return nil, err
	}
	if !found {
		return nil, errCommunityGroupNotFound
	}

	params := url.Values{}
	params.Set("group_id", "eq."+trimmedGroupID)
	params.Set("user_id", "eq."+trimmedInviter)
	params.Set("status", "eq.active")
	params.Set("limit", "1")
	memberRows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, r.cfg.CommunityGroupMembersTable, params)
	if err != nil {
		return nil, err
	}
	if len(memberRows) == 0 {
		return nil, errCommunityGroupAccessDenied
	}

	if len(inviteeUserIDs) == 0 {
		return []communityGroupInviteView{}, nil
	}

	seen := map[string]struct{}{}
	invitees := make([]string, 0, len(inviteeUserIDs))
	for _, rawInvitee := range inviteeUserIDs {
		inviteeID := strings.TrimSpace(rawInvitee)
		if inviteeID == "" || inviteeID == trimmedInviter {
			continue
		}
		if _, ok := seen[inviteeID]; ok {
			continue
		}
		seen[inviteeID] = struct{}{}
		invitees = append(invitees, inviteeID)
		if len(invitees) >= communityGroupMaxInvitesPerRequest {
			break
		}
	}
	if len(invitees) == 0 {
		return []communityGroupInviteView{}, nil
	}

	activeMembers := map[string]bool{}
	memberParams := url.Values{}
	memberParams.Set("group_id", "eq."+trimmedGroupID)
	memberParams.Set("user_id", "in."+buildInList(invitees))
	memberParams.Set("status", "eq.active")
	memberParams.Set("select", "user_id")
	memberRows, err = r.db.SelectRead(ctx, r.cfg.MatchingSchema, r.cfg.CommunityGroupMembersTable, memberParams)
	if err != nil {
		return nil, err
	}
	for _, row := range memberRows {
		uid := strings.TrimSpace(toString(row["user_id"]))
		if uid != "" {
			activeMembers[uid] = true
		}
	}

	existingInvites := map[string]communityGroupInvite{}
	inviteParams := url.Values{}
	inviteParams.Set("group_id", "eq."+trimmedGroupID)
	inviteParams.Set("invitee_user_id", "in."+buildInList(invitees))
	inviteRows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, r.cfg.CommunityGroupInvitesTable, inviteParams)
	if err != nil {
		return nil, err
	}
	for _, row := range inviteRows {
		item := mapCommunityGroupInviteRow(row)
		if item.InviteeUserID != "" {
			existingInvites[item.InviteeUserID] = item
		}
	}

	out := make([]communityGroupInviteView, 0, len(invitees))
	timestamp := now.UTC().Format(time.RFC3339)
	for _, inviteeID := range invitees {
		if activeMembers[inviteeID] {
			continue
		}

		existing, hasExisting := existingInvites[inviteeID]
		if hasExisting && existing.Status == communityGroupInviteStatusPending {
			out = append(out, buildCommunityGroupInviteView(record, existing))
			continue
		}

		var stored communityGroupInvite
		if hasExisting {
			updated, updateErr := r.db.Update(
				ctx,
				r.cfg.MatchingSchema,
				r.cfg.CommunityGroupInvitesTable,
				map[string]any{
					"inviter_user_id": trimmedInviter,
					"status":          communityGroupInviteStatusPending,
					"invited_at":      timestamp,
					"responded_at":    nil,
				},
				url.Values{
					"group_id":        []string{"eq." + trimmedGroupID},
					"invitee_user_id": []string{"eq." + inviteeID},
				},
			)
			if updateErr != nil {
				return nil, updateErr
			}
			if len(updated) == 0 {
				return nil, errors.New("community group invite update returned empty result")
			}
			stored = mapCommunityGroupInviteRow(updated[0])
		} else {
			inserted, insertErr := r.db.Insert(
				ctx,
				r.cfg.MatchingSchema,
				r.cfg.CommunityGroupInvitesTable,
				[]map[string]any{{
					"id":              newGroupUUID(),
					"group_id":        trimmedGroupID,
					"inviter_user_id": trimmedInviter,
					"invitee_user_id": inviteeID,
					"status":          communityGroupInviteStatusPending,
					"invited_at":      timestamp,
					"responded_at":    nil,
				}},
			)
			if insertErr != nil {
				return nil, insertErr
			}
			if len(inserted) == 0 {
				return nil, errors.New("community group invite persistence returned empty result")
			}
			stored = mapCommunityGroupInviteRow(inserted[0])
		}

		out = append(out, buildCommunityGroupInviteView(record, stored))
	}

	_, _ = r.db.Update(
		ctx,
		r.cfg.MatchingSchema,
		r.cfg.CommunityGroupsTable,
		map[string]any{"updated_at": timestamp},
		url.Values{"id": []string{"eq." + trimmedGroupID}},
	)

	return out, nil
}

func (r *communityGroupRepository) respondInvite(
	ctx context.Context,
	groupID,
	userID,
	decision string,
	now time.Time,
) (communityGroupView, communityGroupInviteView, error) {
	trimmedGroupID := strings.TrimSpace(groupID)
	trimmedUserID := strings.TrimSpace(userID)
	normalizedDecision := strings.ToLower(strings.TrimSpace(decision))
	if trimmedGroupID == "" || trimmedUserID == "" {
		return communityGroupView{}, communityGroupInviteView{}, errors.New("group_id and user_id are required")
	}
	if normalizedDecision != "accept" && normalizedDecision != "decline" {
		return communityGroupView{}, communityGroupInviteView{}, errCommunityGroupInvalidAction
	}

	record, found, err := r.getGroupRecord(ctx, trimmedGroupID)
	if err != nil {
		return communityGroupView{}, communityGroupInviteView{}, err
	}
	if !found {
		return communityGroupView{}, communityGroupInviteView{}, errCommunityGroupNotFound
	}

	params := url.Values{}
	params.Set("group_id", "eq."+trimmedGroupID)
	params.Set("invitee_user_id", "eq."+trimmedUserID)
	params.Set("limit", "1")
	rows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, r.cfg.CommunityGroupInvitesTable, params)
	if err != nil {
		return communityGroupView{}, communityGroupInviteView{}, err
	}
	if len(rows) == 0 {
		return communityGroupView{}, communityGroupInviteView{}, errCommunityGroupInviteMissing
	}
	invite := mapCommunityGroupInviteRow(rows[0])
	if invite.Status != communityGroupInviteStatusPending {
		return communityGroupView{}, communityGroupInviteView{}, errCommunityGroupInviteMissing
	}

	timestamp := now.UTC().Format(time.RFC3339)
	status := communityGroupInviteStatusDeclined
	if normalizedDecision == "accept" {
		status = communityGroupInviteStatusAccepted
	}
	updatedInviteRows, err := r.db.Update(
		ctx,
		r.cfg.MatchingSchema,
		r.cfg.CommunityGroupInvitesTable,
		map[string]any{
			"status":       status,
			"responded_at": timestamp,
		},
		url.Values{"id": []string{"eq." + invite.ID}},
	)
	if err != nil {
		return communityGroupView{}, communityGroupInviteView{}, err
	}
	if len(updatedInviteRows) == 0 {
		return communityGroupView{}, communityGroupInviteView{}, errCommunityGroupInviteMissing
	}
	storedInvite := mapCommunityGroupInviteRow(updatedInviteRows[0])

	if normalizedDecision == "accept" {
		_, err = r.db.Upsert(ctx, r.cfg.MatchingSchema, r.cfg.CommunityGroupMembersTable, []map[string]any{{
			"group_id":           trimmedGroupID,
			"user_id":            trimmedUserID,
			"role":               communityGroupRoleMember,
			"status":             "active",
			"invited_by_user_id": nullableUUID(storedInvite.InviterUserID),
			"joined_at":          timestamp,
			"left_at":            nil,
		}}, "group_id,user_id")
		if err != nil {
			return communityGroupView{}, communityGroupInviteView{}, err
		}
	}

	_, _ = r.db.Update(
		ctx,
		r.cfg.MatchingSchema,
		r.cfg.CommunityGroupsTable,
		map[string]any{"updated_at": timestamp},
		url.Values{"id": []string{"eq." + trimmedGroupID}},
	)

	group, _, err := r.getGroupView(ctx, trimmedGroupID, trimmedUserID)
	if err != nil {
		return communityGroupView{}, communityGroupInviteView{}, err
	}
	return group, buildCommunityGroupInviteView(record, storedInvite), nil
}

func (r *communityGroupRepository) listGroups(
	ctx context.Context,
	userID,
	city,
	topic string,
	onlyJoined bool,
	limit int,
) ([]communityGroupView, error) {
	trimmedUserID := strings.TrimSpace(userID)
	trimmedCity := strings.ToLower(strings.TrimSpace(city))
	trimmedTopic := strings.ToLower(strings.TrimSpace(topic))
	if limit <= 0 {
		limit = 50
	} else if limit > 200 {
		limit = 200
	}

	params := url.Values{}
	params.Set("limit", fmt.Sprintf("%d", limit))
	params.Set("order", "created_at.desc")
	if trimmedCity != "" {
		params.Set("city", "eq."+city)
	}
	if trimmedTopic != "" {
		params.Set("topic", "eq."+topic)
	}
	rows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, r.cfg.CommunityGroupsTable, params)
	if err != nil {
		return nil, err
	}

	records := make([]communityGroupRecord, 0, len(rows))
	groupIDs := make([]string, 0, len(rows))
	for _, row := range rows {
		record := mapCommunityGroupRecordRow(row)
		if record.ID == "" {
			continue
		}
		records = append(records, record)
		groupIDs = append(groupIDs, record.ID)
	}

	memberCountByGroup := map[string]int{}
	userMembershipByGroup := map[string]communityGroupMember{}
	if len(groupIDs) > 0 {
		memberParams := url.Values{}
		memberParams.Set("group_id", "in."+buildInList(groupIDs))
		memberParams.Set("status", "eq.active")
		memberParams.Set("select", "group_id,user_id,role,status,joined_at,invited_by_user_id")
		memberRows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, r.cfg.CommunityGroupMembersTable, memberParams)
		if err != nil {
			return nil, err
		}
		for _, row := range memberRows {
			member := mapCommunityGroupMemberRow(row)
			if member.GroupID == "" || member.UserID == "" {
				continue
			}
			memberCountByGroup[member.GroupID]++
			if trimmedUserID != "" && member.UserID == trimmedUserID {
				userMembershipByGroup[member.GroupID] = member
			}
		}
	}

	out := make([]communityGroupView, 0, len(records))
	for _, record := range records {
		member, isMember := userMembershipByGroup[record.ID]
		view := communityGroupView{
			ID:          record.ID,
			Name:        record.Name,
			City:        record.City,
			Topic:       record.Topic,
			Description: record.Description,
			Visibility:  record.Visibility,
			CreatedBy:   record.CreatedBy,
			CreatedAt:   record.CreatedAt.UTC().Format(time.RFC3339),
			UpdatedAt:   record.UpdatedAt.UTC().Format(time.RFC3339),
			MemberCount: memberCountByGroup[record.ID],
			IsMember:    isMember,
		}
		if isMember {
			view.MemberRole = member.Role
		}

		if onlyJoined && !view.IsMember {
			continue
		}
		if !view.IsMember && record.Visibility == communityGroupVisibilityPrivate {
			continue
		}
		out = append(out, view)
	}
	if len(out) > limit {
		out = out[:limit]
	}
	return out, nil
}

func (r *communityGroupRepository) listInvites(
	ctx context.Context,
	userID,
	status string,
	limit int,
) ([]communityGroupInviteView, error) {
	trimmedUserID := strings.TrimSpace(userID)
	trimmedStatus := strings.ToLower(strings.TrimSpace(status))
	if trimmedUserID == "" {
		return []communityGroupInviteView{}, nil
	}
	if limit <= 0 {
		limit = 50
	} else if limit > 200 {
		limit = 200
	}

	params := url.Values{}
	params.Set("invitee_user_id", "eq."+trimmedUserID)
	params.Set("limit", fmt.Sprintf("%d", limit))
	params.Set("order", "invited_at.desc")
	if trimmedStatus != "" {
		params.Set("status", "eq."+trimmedStatus)
	}
	rows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, r.cfg.CommunityGroupInvitesTable, params)
	if err != nil {
		return nil, err
	}

	invites := make([]communityGroupInvite, 0, len(rows))
	groupIDs := make([]string, 0, len(rows))
	seen := map[string]struct{}{}
	for _, row := range rows {
		invite := mapCommunityGroupInviteRow(row)
		if invite.ID == "" || invite.GroupID == "" {
			continue
		}
		invites = append(invites, invite)
		if _, ok := seen[invite.GroupID]; !ok {
			seen[invite.GroupID] = struct{}{}
			groupIDs = append(groupIDs, invite.GroupID)
		}
	}

	groups := map[string]communityGroupRecord{}
	if len(groupIDs) > 0 {
		groupParams := url.Values{}
		groupParams.Set("id", "in."+buildInList(groupIDs))
		groupRows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, r.cfg.CommunityGroupsTable, groupParams)
		if err != nil {
			return nil, err
		}
		for _, row := range groupRows {
			record := mapCommunityGroupRecordRow(row)
			if record.ID != "" {
				groups[record.ID] = record
			}
		}
	}

	out := make([]communityGroupInviteView, 0, len(invites))
	for _, invite := range invites {
		record, ok := groups[invite.GroupID]
		if !ok {
			continue
		}
		out = append(out, buildCommunityGroupInviteView(record, invite))
	}
	return out, nil
}

func (r *communityGroupRepository) getGroupRecord(
	ctx context.Context,
	groupID string,
) (communityGroupRecord, bool, error) {
	params := url.Values{}
	params.Set("id", "eq."+strings.TrimSpace(groupID))
	params.Set("limit", "1")
	rows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, r.cfg.CommunityGroupsTable, params)
	if err != nil {
		return communityGroupRecord{}, false, err
	}
	if len(rows) == 0 {
		return communityGroupRecord{}, false, nil
	}
	record := mapCommunityGroupRecordRow(rows[0])
	if record.ID == "" {
		return communityGroupRecord{}, false, nil
	}
	return record, true, nil
}

func (r *communityGroupRepository) getGroupView(
	ctx context.Context,
	groupID,
	forUserID string,
) (communityGroupView, bool, error) {
	record, found, err := r.getGroupRecord(ctx, groupID)
	if err != nil {
		return communityGroupView{}, false, err
	}
	if !found {
		return communityGroupView{}, false, nil
	}

	memberParams := url.Values{}
	memberParams.Set("group_id", "eq."+record.ID)
	memberParams.Set("status", "eq.active")
	memberParams.Set("select", "group_id,user_id,role,status,joined_at,invited_by_user_id")
	memberRows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, r.cfg.CommunityGroupMembersTable, memberParams)
	if err != nil {
		return communityGroupView{}, false, err
	}

	count := 0
	role := ""
	isMember := false
	trimmedUserID := strings.TrimSpace(forUserID)
	for _, row := range memberRows {
		member := mapCommunityGroupMemberRow(row)
		if member.GroupID == "" || member.UserID == "" {
			continue
		}
		count++
		if trimmedUserID != "" && member.UserID == trimmedUserID {
			isMember = true
			role = member.Role
		}
	}

	view := communityGroupView{
		ID:          record.ID,
		Name:        record.Name,
		City:        record.City,
		Topic:       record.Topic,
		Description: record.Description,
		Visibility:  record.Visibility,
		CreatedBy:   record.CreatedBy,
		CreatedAt:   record.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:   record.UpdatedAt.UTC().Format(time.RFC3339),
		MemberCount: count,
		IsMember:    isMember,
		MemberRole:  role,
	}
	return view, true, nil
}

func mapCommunityGroupRecordRow(row map[string]any) communityGroupRecord {
	createdAt := parseRFC3339OrZero(strings.TrimSpace(toString(row["created_at"])))
	if createdAt.IsZero() {
		createdAt = time.Now().UTC()
	}
	updatedAt := parseRFC3339OrZero(strings.TrimSpace(toString(row["updated_at"])))
	if updatedAt.IsZero() {
		updatedAt = createdAt
	}
	return communityGroupRecord{
		ID:          strings.TrimSpace(toString(row["id"])),
		Name:        strings.TrimSpace(toString(row["name"])),
		City:        strings.TrimSpace(toString(row["city"])),
		Topic:       strings.TrimSpace(toString(row["topic"])),
		Description: strings.TrimSpace(toString(row["description"])),
		Visibility:  normalizeCommunityVisibility(toString(row["visibility"])),
		CreatedBy:   strings.TrimSpace(toString(row["created_by_user_id"])),
		CreatedAt:   createdAt,
		UpdatedAt:   updatedAt,
	}
}

func mapCommunityGroupMemberRow(row map[string]any) communityGroupMember {
	joinedAt := parseRFC3339OrZero(strings.TrimSpace(toString(row["joined_at"])))
	if joinedAt.IsZero() {
		joinedAt = time.Now().UTC()
	}
	status := strings.ToLower(strings.TrimSpace(toString(row["status"])))
	if status == "" {
		status = "active"
	}
	return communityGroupMember{
		GroupID:   strings.TrimSpace(toString(row["group_id"])),
		UserID:    strings.TrimSpace(toString(row["user_id"])),
		Role:      strings.TrimSpace(toString(row["role"])),
		JoinedAt:  joinedAt,
		IsActive:  status == "active",
		InvitedBy: strings.TrimSpace(toString(row["invited_by_user_id"])),
	}
}

func mapCommunityGroupInviteRow(row map[string]any) communityGroupInvite {
	invitedAt := parseRFC3339OrZero(strings.TrimSpace(toString(row["invited_at"])))
	if invitedAt.IsZero() {
		invitedAt = time.Now().UTC()
	}
	respondedAt := parseRFC3339OrZero(strings.TrimSpace(toString(row["responded_at"])))
	return communityGroupInvite{
		ID:            strings.TrimSpace(toString(row["id"])),
		GroupID:       strings.TrimSpace(toString(row["group_id"])),
		InviterUserID: strings.TrimSpace(toString(row["inviter_user_id"])),
		InviteeUserID: strings.TrimSpace(toString(row["invitee_user_id"])),
		Status:        strings.ToLower(strings.TrimSpace(toString(row["status"]))),
		InvitedAt:     invitedAt,
		RespondedAt:   respondedAt,
	}
}

func buildCommunityGroupInviteView(record communityGroupRecord, invite communityGroupInvite) communityGroupInviteView {
	view := communityGroupInviteView{
		ID:            invite.ID,
		GroupID:       invite.GroupID,
		GroupName:     record.Name,
		GroupCity:     record.City,
		GroupTopic:    record.Topic,
		InviterUserID: invite.InviterUserID,
		InviteeUserID: invite.InviteeUserID,
		Status:        invite.Status,
		InvitedAt:     invite.InvitedAt.UTC().Format(time.RFC3339),
	}
	if !invite.RespondedAt.IsZero() {
		view.RespondedAt = invite.RespondedAt.UTC().Format(time.RFC3339)
	}
	return view
}

func newGroupUUID() string {
	buf := make([]byte, 16)
	if _, err := rand.Read(buf); err != nil {
		nanos := uint64(time.Now().UTC().UnixNano())
		for i := range buf {
			buf[i] = byte(nanos >> (uint(i%8) * 8))
		}
	}
	buf[6] = (buf[6] & 0x0f) | 0x40
	buf[8] = (buf[8] & 0x3f) | 0x80
	return fmt.Sprintf(
		"%08x-%04x-%04x-%04x-%012x",
		uint32(buf[0])<<24|uint32(buf[1])<<16|uint32(buf[2])<<8|uint32(buf[3]),
		uint16(buf[4])<<8|uint16(buf[5]),
		uint16(buf[6])<<8|uint16(buf[7]),
		uint16(buf[8])<<8|uint16(buf[9]),
		uint64(buf[10])<<40|uint64(buf[11])<<32|uint64(buf[12])<<24|uint64(buf[13])<<16|uint64(buf[14])<<8|uint64(buf[15]),
	)
}
