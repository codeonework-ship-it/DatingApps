package mobile

import (
	"context"
	"errors"
	"fmt"
	"sort"
	"strings"
	"time"
)

const (
	communityGroupVisibilityPrivate = "private"
	communityGroupVisibilityPublic  = "public"

	communityGroupInviteStatusPending  = "pending"
	communityGroupInviteStatusAccepted = "accepted"
	communityGroupInviteStatusDeclined = "declined"

	communityGroupRoleOwner  = "owner"
	communityGroupRoleMember = "member"

	communityGroupMaxInvitesPerRequest = 50
)

var (
	errCommunityGroupNotFound      = errors.New("community group not found")
	errCommunityGroupAccessDenied  = errors.New("community group access denied")
	errCommunityGroupInvalidAction = errors.New("invalid group invite action")
	errCommunityGroupInviteMissing = errors.New("group invite not found")
)

type communityGroupRecord struct {
	ID          string
	Name        string
	City        string
	Topic       string
	Description string
	Visibility  string
	CreatedBy   string
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

type communityGroupMember struct {
	GroupID   string
	UserID    string
	Role      string
	JoinedAt  time.Time
	IsActive  bool
	InvitedBy string
}

type communityGroupInvite struct {
	ID            string
	GroupID       string
	InviterUserID string
	InviteeUserID string
	Status        string
	InvitedAt     time.Time
	RespondedAt   time.Time
}

type communityGroupView struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	City        string `json:"city"`
	Topic       string `json:"topic"`
	Description string `json:"description"`
	Visibility  string `json:"visibility"`
	CreatedBy   string `json:"created_by_user_id"`
	CreatedAt   string `json:"created_at"`
	UpdatedAt   string `json:"updated_at"`
	MemberCount int    `json:"member_count"`
	IsMember    bool   `json:"is_member"`
	MemberRole  string `json:"member_role,omitempty"`
}

type communityGroupInviteView struct {
	ID            string `json:"id"`
	GroupID       string `json:"group_id"`
	GroupName     string `json:"group_name"`
	GroupCity     string `json:"group_city"`
	GroupTopic    string `json:"group_topic"`
	InviterUserID string `json:"inviter_user_id"`
	InviteeUserID string `json:"invitee_user_id"`
	Status        string `json:"status"`
	InvitedAt     string `json:"invited_at"`
	RespondedAt   string `json:"responded_at,omitempty"`
}

func normalizeCommunityVisibility(raw string) string {
	normalized := strings.ToLower(strings.TrimSpace(raw))
	switch normalized {
	case communityGroupVisibilityPublic:
		return communityGroupVisibilityPublic
	default:
		return communityGroupVisibilityPrivate
	}
}

func (m *memoryStore) createCommunityGroup(
	ownerUserID,
	name,
	city,
	topic,
	description,
	visibility string,
	inviteeUserIDs []string,
	now time.Time,
) (communityGroupView, []communityGroupInviteView, error) {
	if m.communityGroupRepo != nil {
		return m.communityGroupRepo.createGroup(
			context.Background(),
			ownerUserID,
			name,
			city,
			topic,
			description,
			visibility,
			inviteeUserIDs,
			now,
		)
	}

	if m.durableEngagementRequired() {
		return communityGroupView{}, nil, errors.New("durable community group persistence unavailable")
	}

	ownerID := strings.TrimSpace(ownerUserID)
	groupName := strings.TrimSpace(name)
	groupCity := strings.TrimSpace(city)
	groupTopic := strings.TrimSpace(topic)
	groupDescription := strings.TrimSpace(description)
	if ownerID == "" || groupName == "" || groupCity == "" || groupTopic == "" {
		return communityGroupView{}, nil, errors.New("owner_user_id, name, city, and topic are required")
	}

	m.mu.Lock()
	defer m.mu.Unlock()

	m.activitySeq++
	groupID := fmt.Sprintf("community-group-%d", m.activitySeq)
	record := communityGroupRecord{
		ID:          groupID,
		Name:        groupName,
		City:        groupCity,
		Topic:       groupTopic,
		Description: groupDescription,
		Visibility:  normalizeCommunityVisibility(visibility),
		CreatedBy:   ownerID,
		CreatedAt:   now.UTC(),
		UpdatedAt:   now.UTC(),
	}
	m.communityGroups[groupID] = record

	members := m.communityGroupMembers[groupID]
	if members == nil {
		members = make(map[string]communityGroupMember)
		m.communityGroupMembers[groupID] = members
	}
	members[ownerID] = communityGroupMember{
		GroupID:  groupID,
		UserID:   ownerID,
		Role:     communityGroupRoleOwner,
		JoinedAt: now.UTC(),
		IsActive: true,
	}

	invites, err := m.createCommunityGroupInvitesLocked(groupID, ownerID, inviteeUserIDs, now)
	if err != nil {
		return communityGroupView{}, nil, err
	}

	view := m.buildCommunityGroupViewLocked(record, ownerID)
	return view, invites, nil
}

func (m *memoryStore) createCommunityGroupInvites(
	groupID,
	inviterUserID string,
	inviteeUserIDs []string,
	now time.Time,
) ([]communityGroupInviteView, error) {
	if m.communityGroupRepo != nil {
		return m.communityGroupRepo.createInvites(
			context.Background(),
			groupID,
			inviterUserID,
			inviteeUserIDs,
			now,
		)
	}

	if m.durableEngagementRequired() {
		return nil, errors.New("durable community group persistence unavailable")
	}

	trimmedGroupID := strings.TrimSpace(groupID)
	trimmedInviter := strings.TrimSpace(inviterUserID)
	if trimmedGroupID == "" || trimmedInviter == "" {
		return nil, errors.New("group_id and inviter_user_id are required")
	}

	m.mu.Lock()
	defer m.mu.Unlock()
	return m.createCommunityGroupInvitesLocked(trimmedGroupID, trimmedInviter, inviteeUserIDs, now)
}

func (m *memoryStore) createCommunityGroupInvitesLocked(
	groupID,
	inviterUserID string,
	inviteeUserIDs []string,
	now time.Time,
) ([]communityGroupInviteView, error) {
	record, ok := m.communityGroups[groupID]
	if !ok {
		return nil, errCommunityGroupNotFound
	}

	members := m.communityGroupMembers[groupID]
	inviterMember, inviterJoined := members[inviterUserID]
	if !inviterJoined || !inviterMember.IsActive {
		return nil, errCommunityGroupAccessDenied
	}

	if len(inviteeUserIDs) == 0 {
		return []communityGroupInviteView{}, nil
	}

	invitesByInvitee := m.communityGroupInvites[groupID]
	if invitesByInvitee == nil {
		invitesByInvitee = make(map[string]communityGroupInvite)
		m.communityGroupInvites[groupID] = invitesByInvitee
	}

	seen := map[string]struct{}{}
	out := make([]communityGroupInviteView, 0, len(inviteeUserIDs))
	created := 0
	for _, rawInvitee := range inviteeUserIDs {
		inviteeID := strings.TrimSpace(rawInvitee)
		if inviteeID == "" || inviteeID == inviterUserID {
			continue
		}
		if _, already := seen[inviteeID]; already {
			continue
		}
		seen[inviteeID] = struct{}{}
		if member, joined := members[inviteeID]; joined && member.IsActive {
			continue
		}
		if created >= communityGroupMaxInvitesPerRequest {
			break
		}

		existing, hasExisting := invitesByInvitee[inviteeID]
		if hasExisting && existing.Status == communityGroupInviteStatusPending {
			out = append(out, m.buildCommunityGroupInviteViewLocked(record, existing))
			continue
		}

		m.activitySeq++
		invite := communityGroupInvite{
			ID:            fmt.Sprintf("community-group-invite-%d", m.activitySeq),
			GroupID:       groupID,
			InviterUserID: inviterUserID,
			InviteeUserID: inviteeID,
			Status:        communityGroupInviteStatusPending,
			InvitedAt:     now.UTC(),
		}
		invitesByInvitee[inviteeID] = invite
		out = append(out, m.buildCommunityGroupInviteViewLocked(record, invite))
		created++
	}

	record.UpdatedAt = now.UTC()
	m.communityGroups[groupID] = record
	return out, nil
}

func (m *memoryStore) respondCommunityGroupInvite(
	groupID,
	userID,
	decision string,
	now time.Time,
) (communityGroupView, communityGroupInviteView, error) {
	if m.communityGroupRepo != nil {
		return m.communityGroupRepo.respondInvite(
			context.Background(),
			groupID,
			userID,
			decision,
			now,
		)
	}

	if m.durableEngagementRequired() {
		return communityGroupView{}, communityGroupInviteView{}, errors.New("durable community group persistence unavailable")
	}

	trimmedGroupID := strings.TrimSpace(groupID)
	trimmedUserID := strings.TrimSpace(userID)
	normalizedDecision := strings.ToLower(strings.TrimSpace(decision))
	if trimmedGroupID == "" || trimmedUserID == "" {
		return communityGroupView{}, communityGroupInviteView{}, errors.New("group_id and user_id are required")
	}
	if normalizedDecision != "accept" && normalizedDecision != "decline" {
		return communityGroupView{}, communityGroupInviteView{}, errCommunityGroupInvalidAction
	}

	m.mu.Lock()
	defer m.mu.Unlock()

	record, ok := m.communityGroups[trimmedGroupID]
	if !ok {
		return communityGroupView{}, communityGroupInviteView{}, errCommunityGroupNotFound
	}

	invitesByInvitee := m.communityGroupInvites[trimmedGroupID]
	if invitesByInvitee == nil {
		return communityGroupView{}, communityGroupInviteView{}, errCommunityGroupInviteMissing
	}
	invite, hasInvite := invitesByInvitee[trimmedUserID]
	if !hasInvite || invite.Status != communityGroupInviteStatusPending {
		return communityGroupView{}, communityGroupInviteView{}, errCommunityGroupInviteMissing
	}

	if normalizedDecision == "accept" {
		invite.Status = communityGroupInviteStatusAccepted
		members := m.communityGroupMembers[trimmedGroupID]
		if members == nil {
			members = make(map[string]communityGroupMember)
			m.communityGroupMembers[trimmedGroupID] = members
		}
		members[trimmedUserID] = communityGroupMember{
			GroupID:   trimmedGroupID,
			UserID:    trimmedUserID,
			Role:      communityGroupRoleMember,
			JoinedAt:  now.UTC(),
			IsActive:  true,
			InvitedBy: invite.InviterUserID,
		}
	} else {
		invite.Status = communityGroupInviteStatusDeclined
	}
	invite.RespondedAt = now.UTC()
	invitesByInvitee[trimmedUserID] = invite

	record.UpdatedAt = now.UTC()
	m.communityGroups[trimmedGroupID] = record

	groupView := m.buildCommunityGroupViewLocked(record, trimmedUserID)
	inviteView := m.buildCommunityGroupInviteViewLocked(record, invite)
	return groupView, inviteView, nil
}

func (m *memoryStore) listCommunityGroups(
	userID,
	city,
	topic string,
	onlyJoined bool,
	limit int,
) []communityGroupView {
	if m.communityGroupRepo != nil {
		groups, err := m.communityGroupRepo.listGroups(
			context.Background(),
			userID,
			city,
			topic,
			onlyJoined,
			limit,
		)
		if err == nil {
			return groups
		}
		return []communityGroupView{}
	}

	if m.durableEngagementRequired() {
		return []communityGroupView{}
	}

	trimmedUserID := strings.TrimSpace(userID)
	trimmedCity := strings.ToLower(strings.TrimSpace(city))
	trimmedTopic := strings.ToLower(strings.TrimSpace(topic))
	if limit <= 0 {
		limit = 50
	} else if limit > 200 {
		limit = 200
	}

	m.mu.RLock()
	defer m.mu.RUnlock()

	records := make([]communityGroupRecord, 0, len(m.communityGroups))
	for _, item := range m.communityGroups {
		records = append(records, item)
	}
	sort.Slice(records, func(i, j int) bool {
		return records[i].CreatedAt.After(records[j].CreatedAt)
	})

	out := make([]communityGroupView, 0, len(records))
	for _, record := range records {
		if trimmedCity != "" && strings.ToLower(record.City) != trimmedCity {
			continue
		}
		if trimmedTopic != "" && strings.ToLower(record.Topic) != trimmedTopic {
			continue
		}
		view := m.buildCommunityGroupViewLocked(record, trimmedUserID)
		if onlyJoined && !view.IsMember {
			continue
		}
		if !view.IsMember && record.Visibility == communityGroupVisibilityPrivate {
			continue
		}
		out = append(out, view)
		if len(out) >= limit {
			break
		}
	}
	return out
}

func (m *memoryStore) listCommunityGroupInvites(userID, status string, limit int) []communityGroupInviteView {
	if m.communityGroupRepo != nil {
		invites, err := m.communityGroupRepo.listInvites(
			context.Background(),
			userID,
			status,
			limit,
		)
		if err == nil {
			return invites
		}
		return []communityGroupInviteView{}
	}

	if m.durableEngagementRequired() {
		return []communityGroupInviteView{}
	}

	trimmedUserID := strings.TrimSpace(userID)
	trimmedStatus := strings.ToLower(strings.TrimSpace(status))
	if trimmedUserID == "" {
		return []communityGroupInviteView{}
	}
	if limit <= 0 {
		limit = 50
	} else if limit > 200 {
		limit = 200
	}

	m.mu.RLock()
	defer m.mu.RUnlock()

	out := make([]communityGroupInviteView, 0)
	for groupID, invitesByInvitee := range m.communityGroupInvites {
		record, ok := m.communityGroups[groupID]
		if !ok {
			continue
		}
		invite, exists := invitesByInvitee[trimmedUserID]
		if !exists {
			continue
		}
		if trimmedStatus != "" && invite.Status != trimmedStatus {
			continue
		}
		out = append(out, m.buildCommunityGroupInviteViewLocked(record, invite))
	}

	sort.Slice(out, func(i, j int) bool {
		return out[i].InvitedAt > out[j].InvitedAt
	})
	if len(out) > limit {
		out = out[:limit]
	}
	return out
}

func (m *memoryStore) buildCommunityGroupViewLocked(record communityGroupRecord, userID string) communityGroupView {
	members := m.communityGroupMembers[record.ID]
	memberCount := 0
	isMember := false
	memberRole := ""
	trimmedUserID := strings.TrimSpace(userID)
	for memberUserID, member := range members {
		if !member.IsActive {
			continue
		}
		memberCount++
		if trimmedUserID != "" && memberUserID == trimmedUserID {
			isMember = true
			memberRole = member.Role
		}
	}

	return communityGroupView{
		ID:          record.ID,
		Name:        record.Name,
		City:        record.City,
		Topic:       record.Topic,
		Description: record.Description,
		Visibility:  record.Visibility,
		CreatedBy:   record.CreatedBy,
		CreatedAt:   record.CreatedAt.UTC().Format(time.RFC3339),
		UpdatedAt:   record.UpdatedAt.UTC().Format(time.RFC3339),
		MemberCount: memberCount,
		IsMember:    isMember,
		MemberRole:  memberRole,
	}
}

func (m *memoryStore) buildCommunityGroupInviteViewLocked(
	record communityGroupRecord,
	invite communityGroupInvite,
) communityGroupInviteView {
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
