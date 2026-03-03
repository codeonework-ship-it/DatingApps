package mobile

import (
	"errors"
	"sort"
	"strconv"
	"strings"
	"time"
)

const (
	roomLifecycleScheduled = "scheduled"
	roomLifecycleActive    = "active"
	roomLifecycleClosed    = "closed"
)

var (
	errRoomNotFound             = errors.New("room not found")
	errRoomClosed               = errors.New("room is closed")
	errRoomCapacityReached      = errors.New("room capacity reached")
	errRoomNotParticipant       = errors.New("user is not a participant in the room")
	errRoomBlockedActiveSession = errors.New("user is blocked from this active room session")
	errRoomModerationAction     = errors.New("invalid moderation action")
	errRoomModerationNotActive  = errors.New("room moderation removal requires active room")
)

const (
	roomModerationActionWarn   = "warn_user"
	roomModerationActionRemove = "remove_user"
)

type conversationRoomRecord struct {
	ID          string
	Theme       string
	Description string
	StartsAt    time.Time
	EndsAt      time.Time
	Capacity    int
}

type conversationRoomParticipant struct {
	UserID   string
	JoinedAt time.Time
}

type conversationRoomBlock struct {
	UserID       string
	BlockedUntil time.Time
	Reason       string
	BlockedBy    string
	BlockedAt    time.Time
}

type conversationRoomModerationAction struct {
	ID              string `json:"id"`
	RoomID          string `json:"room_id"`
	ModeratorUserID string `json:"moderator_user_id"`
	TargetUserID    string `json:"target_user_id"`
	Action          string `json:"action"`
	Reason          string `json:"reason,omitempty"`
	CreatedAt       string `json:"created_at"`
}

type conversationRoomView struct {
	ID               string   `json:"id"`
	Theme            string   `json:"theme"`
	Description      string   `json:"description"`
	LifecycleState   string   `json:"lifecycle_state"`
	StartsAt         string   `json:"starts_at"`
	EndsAt           string   `json:"ends_at"`
	Capacity         int      `json:"capacity"`
	ParticipantCount int      `json:"participant_count"`
	ParticipantUsers []string `json:"participant_user_ids"`
	IsParticipant    bool     `json:"is_participant"`
}

func defaultConversationRoomRecords() map[string]conversationRoomRecord {
	now := time.Now().UTC()
	return map[string]conversationRoomRecord{
		"room-communication-reset": {
			ID:          "room-communication-reset",
			Theme:       "Communication Reset",
			Description: "Share one communication pattern that improved your connections this week.",
			StartsAt:    now.Add(-30 * time.Minute),
			EndsAt:      now.Add(30 * time.Minute),
			Capacity:    20,
		},
		"room-red-flag-roundtable": {
			ID:          "room-red-flag-roundtable",
			Theme:       "Red Flag Roundtable",
			Description: "Discuss early warning signs and respectful boundary-setting.",
			StartsAt:    now.Add(24 * time.Hour),
			EndsAt:      now.Add(25 * time.Hour),
			Capacity:    25,
		},
		"room-weekly-wrap": {
			ID:          "room-weekly-wrap",
			Theme:       "Weekly Wrap",
			Description: "A closed room archive from the previous weekly conversation.",
			StartsAt:    now.Add(-48 * time.Hour),
			EndsAt:      now.Add(-47 * time.Hour),
			Capacity:    30,
		},
	}
}

func roomLifecycleState(startsAt, endsAt, now time.Time) string {
	if now.Before(startsAt) {
		return roomLifecycleScheduled
	}
	if now.Before(endsAt) {
		return roomLifecycleActive
	}
	return roomLifecycleClosed
}

func (m *memoryStore) listConversationRooms(userID, state string, friendOnly bool, limit int, now time.Time) []conversationRoomView {
	normalizedUserID := strings.TrimSpace(userID)
	normalizedState := strings.ToLower(strings.TrimSpace(state))
	if limit <= 0 || limit > 200 {
		limit = 50
	}

	m.mu.RLock()
	defer m.mu.RUnlock()

	records := make([]conversationRoomRecord, 0, len(m.rooms))
	for _, item := range m.rooms {
		records = append(records, item)
	}
	sort.Slice(records, func(i, j int) bool {
		if records[i].StartsAt.Equal(records[j].StartsAt) {
			return records[i].ID < records[j].ID
		}
		return records[i].StartsAt.Before(records[j].StartsAt)
	})

	out := make([]conversationRoomView, 0, len(records))
	for _, room := range records {
		lifecycle := roomLifecycleState(room.StartsAt, room.EndsAt, now)
		if normalizedState != "" && lifecycle != normalizedState {
			continue
		}
		if friendOnly {
			if normalizedUserID == "" {
				continue
			}
			if !m.roomHasFriendParticipantLocked(room.ID, normalizedUserID) {
				continue
			}
		}
		out = append(out, m.buildConversationRoomViewLocked(room, normalizedUserID, now))
		if len(out) >= limit {
			break
		}
	}

	return out
}

func (m *memoryStore) roomHasFriendParticipantLocked(roomID, userID string) bool {
	participants := m.roomParticipants[roomID]
	if len(participants) == 0 {
		return false
	}
	if _, isParticipant := participants[userID]; isParticipant {
		return true
	}
	userFriends := m.friends[userID]
	if len(userFriends) == 0 {
		return false
	}
	for participantUserID := range participants {
		if _, isFriend := userFriends[participantUserID]; isFriend {
			return true
		}
	}
	return false
}

func (m *memoryStore) joinConversationRoom(roomID, userID string, now time.Time) (conversationRoomView, error) {
	normalizedRoomID := strings.TrimSpace(roomID)
	normalizedUserID := strings.TrimSpace(userID)
	if normalizedRoomID == "" || normalizedUserID == "" {
		return conversationRoomView{}, errors.New("room id and user id are required")
	}

	m.mu.Lock()
	defer m.mu.Unlock()

	room, ok := m.rooms[normalizedRoomID]
	if !ok {
		return conversationRoomView{}, errRoomNotFound
	}
	if roomLifecycleState(room.StartsAt, room.EndsAt, now) == roomLifecycleClosed {
		return conversationRoomView{}, errRoomClosed
	}

	participants := m.roomParticipants[normalizedRoomID]
	if participants == nil {
		participants = make(map[string]conversationRoomParticipant)
		m.roomParticipants[normalizedRoomID] = participants
	}
	if blockedUsers := m.roomActiveBlocks[normalizedRoomID]; blockedUsers != nil {
		if block, isBlocked := blockedUsers[normalizedUserID]; isBlocked && now.Before(block.BlockedUntil) {
			return conversationRoomView{}, errRoomBlockedActiveSession
		}
	}
	if _, alreadyJoined := participants[normalizedUserID]; !alreadyJoined {
		if len(participants) >= room.Capacity {
			return conversationRoomView{}, errRoomCapacityReached
		}
		participants[normalizedUserID] = conversationRoomParticipant{
			UserID:   normalizedUserID,
			JoinedAt: now,
		}
	}

	return m.buildConversationRoomViewLocked(room, normalizedUserID, now), nil
}

func (m *memoryStore) moderateConversationRoom(
	roomID,
	moderatorUserID,
	targetUserID,
	action,
	reason string,
	now time.Time,
) (conversationRoomView, conversationRoomModerationAction, error) {
	normalizedRoomID := strings.TrimSpace(roomID)
	normalizedModerator := strings.TrimSpace(moderatorUserID)
	normalizedTarget := strings.TrimSpace(targetUserID)
	normalizedAction := strings.ToLower(strings.TrimSpace(action))
	normalizedReason := strings.TrimSpace(reason)

	if normalizedRoomID == "" || normalizedModerator == "" || normalizedTarget == "" {
		return conversationRoomView{}, conversationRoomModerationAction{}, errors.New("room id, moderator user id, and target user id are required")
	}
	if normalizedAction != roomModerationActionWarn && normalizedAction != roomModerationActionRemove {
		return conversationRoomView{}, conversationRoomModerationAction{}, errRoomModerationAction
	}

	m.mu.Lock()
	defer m.mu.Unlock()

	room, ok := m.rooms[normalizedRoomID]
	if !ok {
		return conversationRoomView{}, conversationRoomModerationAction{}, errRoomNotFound
	}

	lifecycle := roomLifecycleState(room.StartsAt, room.EndsAt, now)
	if normalizedAction == roomModerationActionRemove && lifecycle != roomLifecycleActive {
		return conversationRoomView{}, conversationRoomModerationAction{}, errRoomModerationNotActive
	}

	if normalizedAction == roomModerationActionRemove {
		participants := m.roomParticipants[normalizedRoomID]
		if participants != nil {
			delete(participants, normalizedTarget)
		}
		blockedUsers := m.roomActiveBlocks[normalizedRoomID]
		if blockedUsers == nil {
			blockedUsers = make(map[string]conversationRoomBlock)
			m.roomActiveBlocks[normalizedRoomID] = blockedUsers
		}
		blockedUsers[normalizedTarget] = conversationRoomBlock{
			UserID:       normalizedTarget,
			BlockedUntil: room.EndsAt,
			Reason:       normalizedReason,
			BlockedBy:    normalizedModerator,
			BlockedAt:    now,
		}
	}

	actionEntry := conversationRoomModerationAction{
		ID:              "room-mod-" + normalizedRoomID + "-" + now.Format("20060102150405") + "-" + strconv.Itoa(len(m.roomModerationActions[normalizedRoomID])+1),
		RoomID:          normalizedRoomID,
		ModeratorUserID: normalizedModerator,
		TargetUserID:    normalizedTarget,
		Action:          normalizedAction,
		Reason:          normalizedReason,
		CreatedAt:       now.UTC().Format(time.RFC3339),
	}
	m.roomModerationActions[normalizedRoomID] = append(m.roomModerationActions[normalizedRoomID], actionEntry)

	view := m.buildConversationRoomViewLocked(room, normalizedModerator, now)
	return view, actionEntry, nil
}

func (m *memoryStore) leaveConversationRoom(roomID, userID string, now time.Time) (conversationRoomView, error) {
	normalizedRoomID := strings.TrimSpace(roomID)
	normalizedUserID := strings.TrimSpace(userID)
	if normalizedRoomID == "" || normalizedUserID == "" {
		return conversationRoomView{}, errors.New("room id and user id are required")
	}

	m.mu.Lock()
	defer m.mu.Unlock()

	room, ok := m.rooms[normalizedRoomID]
	if !ok {
		return conversationRoomView{}, errRoomNotFound
	}

	participants := m.roomParticipants[normalizedRoomID]
	if participants == nil {
		return conversationRoomView{}, errRoomNotParticipant
	}
	if _, joined := participants[normalizedUserID]; !joined {
		return conversationRoomView{}, errRoomNotParticipant
	}
	delete(participants, normalizedUserID)

	return m.buildConversationRoomViewLocked(room, normalizedUserID, now), nil
}

func (m *memoryStore) buildConversationRoomViewLocked(
	room conversationRoomRecord,
	userID string,
	now time.Time,
) conversationRoomView {
	participants := m.roomParticipants[room.ID]
	participantUsers := make([]string, 0, len(participants))
	for participantUserID := range participants {
		participantUsers = append(participantUsers, participantUserID)
	}
	sort.Strings(participantUsers)

	normalizedUserID := strings.TrimSpace(userID)
	isParticipant := false
	if normalizedUserID != "" {
		_, isParticipant = participants[normalizedUserID]
	}

	return conversationRoomView{
		ID:               room.ID,
		Theme:            room.Theme,
		Description:      room.Description,
		LifecycleState:   roomLifecycleState(room.StartsAt, room.EndsAt, now),
		StartsAt:         room.StartsAt.UTC().Format(time.RFC3339),
		EndsAt:           room.EndsAt.UTC().Format(time.RFC3339),
		Capacity:         room.Capacity,
		ParticipantCount: len(participantUsers),
		ParticipantUsers: participantUsers,
		IsParticipant:    isParticipant,
	}
}
