package mobile

import (
	"context"
	"errors"
	"fmt"
	"net/url"
	"sort"
	"strings"
	"time"

	"github.com/verified-dating/backend/internal/platform/config"
	"github.com/verified-dating/backend/internal/platform/supabase"
)

const defaultConversationRoomCapacity = 20

type conversationRoomRepository struct {
	cfg config.Config
	db  *supabase.Client
}

func newConversationRoomRepository(cfg config.Config) *conversationRoomRepository {
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
	return &conversationRoomRepository{cfg: cfg, db: client}
}

func isConversationRoomRepoPersistenceUnavailable(err error) bool {
	if err == nil {
		return false
	}
	msg := strings.ToLower(err.Error())
	return strings.Contains(msg, "pgrst106") ||
		strings.Contains(msg, "pgrst205") ||
		strings.Contains(msg, "invalid schema") ||
		strings.Contains(msg, "could not find the table")
}

func (r *conversationRoomRepository) listConversationRooms(
	ctx context.Context,
	userID,
	state string,
	friendOnly bool,
	limit int,
	now time.Time,
) ([]conversationRoomView, error) {
	normalizedUserID := strings.TrimSpace(userID)
	normalizedState := strings.ToLower(strings.TrimSpace(state))
	if limit <= 0 || limit > 200 {
		limit = 50
	}
	if friendOnly && normalizedUserID == "" {
		return []conversationRoomView{}, nil
	}

	params := url.Values{}
	params.Set("select", "*")
	params.Set("order", "starts_at.asc")
	params.Set("limit", fmt.Sprintf("%d", limit*4))
	roomRows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "conversation_rooms", params)
	if err != nil {
		return nil, err
	}

	rooms := make([]conversationRoomRecord, 0, len(roomRows))
	for _, row := range roomRows {
		rooms = append(rooms, mapConversationRoomRecord(row))
	}
	if len(rooms) == 0 {
		return []conversationRoomView{}, nil
	}

	participantsByRoom, err := r.loadActiveParticipantsByRoom(ctx, roomIDsFromRecords(rooms))
	if err != nil {
		return nil, err
	}

	friendSet := map[string]struct{}{}
	if friendOnly {
		friendSet, err = r.loadFriendSet(ctx, normalizedUserID)
		if err != nil {
			return nil, err
		}
	}

	out := make([]conversationRoomView, 0, minInt(len(rooms), limit))
	for _, room := range rooms {
		lifecycle := roomLifecycleState(room.StartsAt, room.EndsAt, now)
		if normalizedState != "" && lifecycle != normalizedState {
			continue
		}

		participants := participantsByRoom[room.ID]
		if friendOnly && !roomHasFriendParticipant(participants, normalizedUserID, friendSet) {
			continue
		}

		view := buildConversationRoomView(room, participants, normalizedUserID, now)
		out = append(out, view)
		if len(out) >= limit {
			break
		}
	}

	return out, nil
}

func (r *conversationRoomRepository) joinConversationRoom(
	ctx context.Context,
	roomID,
	userID string,
	now time.Time,
) (conversationRoomView, error) {
	normalizedRoomID := strings.TrimSpace(roomID)
	normalizedUserID := strings.TrimSpace(userID)
	if normalizedRoomID == "" || normalizedUserID == "" {
		return conversationRoomView{}, errors.New("room id and user id are required")
	}

	room, err := r.getConversationRoom(ctx, normalizedRoomID)
	if err != nil {
		return conversationRoomView{}, err
	}
	if roomLifecycleState(room.StartsAt, room.EndsAt, now) == roomLifecycleClosed {
		return conversationRoomView{}, errRoomClosed
	}

	blocked, err := r.isUserBlockedInRoom(ctx, normalizedRoomID, normalizedUserID, now)
	if err != nil {
		return conversationRoomView{}, err
	}
	if blocked {
		return conversationRoomView{}, errRoomBlockedActiveSession
	}

	participants, err := r.loadActiveParticipants(ctx, normalizedRoomID)
	if err != nil {
		return conversationRoomView{}, err
	}

	if containsString(participants, normalizedUserID) {
		return buildConversationRoomView(room, participants, normalizedUserID, now), nil
	}
	if len(participants) >= room.Capacity {
		return conversationRoomView{}, errRoomCapacityReached
	}

	_, _ = r.deleteConversationRoomParticipant(ctx, normalizedRoomID, normalizedUserID)
	insertRows := []map[string]any{{
		"room_id":   normalizedRoomID,
		"user_id":   normalizedUserID,
		"joined_at": now.Format(time.RFC3339),
		"left_at":   nil,
	}}
	if _, err := r.db.Insert(ctx, r.cfg.MatchingSchema, "conversation_room_participants", insertRows); err != nil {
		return conversationRoomView{}, err
	}

	participants, err = r.loadActiveParticipants(ctx, normalizedRoomID)
	if err != nil {
		return conversationRoomView{}, err
	}
	return buildConversationRoomView(room, participants, normalizedUserID, now), nil
}

func (r *conversationRoomRepository) leaveConversationRoom(
	ctx context.Context,
	roomID,
	userID string,
	now time.Time,
) (conversationRoomView, error) {
	normalizedRoomID := strings.TrimSpace(roomID)
	normalizedUserID := strings.TrimSpace(userID)
	if normalizedRoomID == "" || normalizedUserID == "" {
		return conversationRoomView{}, errors.New("room id and user id are required")
	}

	room, err := r.getConversationRoom(ctx, normalizedRoomID)
	if err != nil {
		return conversationRoomView{}, err
	}

	participants, err := r.loadActiveParticipants(ctx, normalizedRoomID)
	if err != nil {
		return conversationRoomView{}, err
	}
	if !containsString(participants, normalizedUserID) {
		return conversationRoomView{}, errRoomNotParticipant
	}

	if _, err := r.deleteConversationRoomParticipant(ctx, normalizedRoomID, normalizedUserID); err != nil {
		return conversationRoomView{}, err
	}

	participants, err = r.loadActiveParticipants(ctx, normalizedRoomID)
	if err != nil {
		return conversationRoomView{}, err
	}
	return buildConversationRoomView(room, participants, normalizedUserID, now), nil
}

func (r *conversationRoomRepository) moderateConversationRoom(
	ctx context.Context,
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

	room, err := r.getConversationRoom(ctx, normalizedRoomID)
	if err != nil {
		return conversationRoomView{}, conversationRoomModerationAction{}, err
	}
	if normalizedAction == roomModerationActionRemove && roomLifecycleState(room.StartsAt, room.EndsAt, now) != roomLifecycleActive {
		return conversationRoomView{}, conversationRoomModerationAction{}, errRoomModerationNotActive
	}

	if normalizedAction == roomModerationActionRemove {
		if _, err := r.deleteConversationRoomParticipant(ctx, normalizedRoomID, normalizedTarget); err != nil {
			return conversationRoomView{}, conversationRoomModerationAction{}, err
		}
		blockUpsert := []map[string]any{{
			"room_id":            normalizedRoomID,
			"blocked_user_id":    normalizedTarget,
			"blocked_by_user_id": normalizedModerator,
			"reason":             normalizedReason,
			"created_at":         now.Format(time.RFC3339),
			"expires_at":         room.EndsAt.UTC().Format(time.RFC3339),
		}}
		if _, err := r.db.Upsert(ctx, r.cfg.MatchingSchema, "conversation_room_blocks", blockUpsert, "room_id,blocked_user_id"); err != nil {
			return conversationRoomView{}, conversationRoomModerationAction{}, err
		}
	}

	dbAction := mapModerationActionForDB(normalizedAction)
	entry, err := r.insertModerationAction(ctx, normalizedRoomID, normalizedModerator, normalizedTarget, dbAction, normalizedReason, now)
	if err != nil {
		return conversationRoomView{}, conversationRoomModerationAction{}, err
	}
	entry.Action = normalizedAction

	participants, err := r.loadActiveParticipants(ctx, normalizedRoomID)
	if err != nil {
		return conversationRoomView{}, conversationRoomModerationAction{}, err
	}
	return buildConversationRoomView(room, participants, normalizedModerator, now), entry, nil
}

func (r *conversationRoomRepository) insertModerationAction(
	ctx context.Context,
	roomID,
	moderatorUserID,
	targetUserID,
	action,
	reason string,
	now time.Time,
) (conversationRoomModerationAction, error) {
	actorPayload := []map[string]any{{
		"room_id":        roomID,
		"actor_user_id":  moderatorUserID,
		"target_user_id": targetUserID,
		"action":         action,
		"reason":         reason,
		"created_at":     now.Format(time.RFC3339),
	}}
	rows, err := r.db.Insert(ctx, r.cfg.MatchingSchema, "conversation_room_moderation_actions", actorPayload)
	if err == nil {
		if len(rows) == 0 {
			return conversationRoomModerationAction{}, errors.New("conversation room moderation persistence returned empty result")
		}
		return mapConversationRoomModerationAction(rows[0]), nil
	}

	msg := strings.ToLower(err.Error())
	if !strings.Contains(msg, "actor_user_id") {
		return conversationRoomModerationAction{}, err
	}

	moderatorPayload := []map[string]any{{
		"room_id":           roomID,
		"moderator_user_id": moderatorUserID,
		"target_user_id":    targetUserID,
		"action":            action,
		"reason":            reason,
		"created_at":        now.Format(time.RFC3339),
	}}
	rows, fallbackErr := r.db.Insert(ctx, r.cfg.MatchingSchema, "conversation_room_moderation_actions", moderatorPayload)
	if fallbackErr != nil {
		return conversationRoomModerationAction{}, fallbackErr
	}
	if len(rows) == 0 {
		return conversationRoomModerationAction{}, errors.New("conversation room moderation persistence returned empty result")
	}
	return mapConversationRoomModerationAction(rows[0]), nil
}

func (r *conversationRoomRepository) deleteConversationRoomParticipant(ctx context.Context, roomID, userID string) ([]map[string]any, error) {
	filters := url.Values{}
	filters.Set("room_id", "eq."+strings.TrimSpace(roomID))
	filters.Set("user_id", "eq."+strings.TrimSpace(userID))
	return r.db.Delete(ctx, r.cfg.MatchingSchema, "conversation_room_participants", filters)
}

func (r *conversationRoomRepository) isUserBlockedInRoom(ctx context.Context, roomID, userID string, now time.Time) (bool, error) {
	params := url.Values{}
	params.Set("room_id", "eq."+strings.TrimSpace(roomID))
	params.Set("blocked_user_id", "eq."+strings.TrimSpace(userID))
	params.Set("limit", "1")
	params.Set("select", "expires_at")
	rows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "conversation_room_blocks", params)
	if err != nil {
		return false, err
	}
	if len(rows) == 0 {
		return false, nil
	}
	expiresAt := parseConversationRoomTime(rows[0]["expires_at"])
	if expiresAt.IsZero() {
		return true, nil
	}
	return now.Before(expiresAt), nil
}

func (r *conversationRoomRepository) getConversationRoom(ctx context.Context, roomID string) (conversationRoomRecord, error) {
	params := url.Values{}
	params.Set("id", "eq."+strings.TrimSpace(roomID))
	params.Set("limit", "1")
	params.Set("select", "*")
	rows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "conversation_rooms", params)
	if err != nil {
		return conversationRoomRecord{}, err
	}
	if len(rows) == 0 {
		return conversationRoomRecord{}, errRoomNotFound
	}
	return mapConversationRoomRecord(rows[0]), nil
}

func (r *conversationRoomRepository) loadActiveParticipantsByRoom(ctx context.Context, roomIDs []string) (map[string][]string, error) {
	if len(roomIDs) == 0 {
		return map[string][]string{}, nil
	}

	params := url.Values{}
	params.Set("select", "room_id,user_id,status,left_at")
	params.Set("room_id", "in.("+strings.Join(roomIDs, ",")+")")
	rows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "conversation_room_participants", params)
	if err != nil {
		return nil, err
	}

	participantsByRoom := make(map[string][]string, len(roomIDs))
	for _, row := range rows {
		status := strings.ToLower(strings.TrimSpace(toString(row["status"])))
		if isInactiveRoomParticipant(status, row["left_at"]) {
			continue
		}
		roomID := strings.TrimSpace(toString(row["room_id"]))
		userID := strings.TrimSpace(toString(row["user_id"]))
		if roomID == "" || userID == "" {
			continue
		}
		participantsByRoom[roomID] = append(participantsByRoom[roomID], userID)
	}

	for roomID := range participantsByRoom {
		sort.Strings(participantsByRoom[roomID])
	}
	return participantsByRoom, nil
}

func (r *conversationRoomRepository) loadActiveParticipants(ctx context.Context, roomID string) ([]string, error) {
	participantsByRoom, err := r.loadActiveParticipantsByRoom(ctx, []string{strings.TrimSpace(roomID)})
	if err != nil {
		return nil, err
	}
	participants := participantsByRoom[strings.TrimSpace(roomID)]
	if participants == nil {
		return []string{}, nil
	}
	return participants, nil
}

func (r *conversationRoomRepository) loadFriendSet(ctx context.Context, userID string) (map[string]struct{}, error) {
	params := url.Values{}
	params.Set("user_id", "eq."+strings.TrimSpace(userID))
	params.Set("status", "eq.accepted")
	params.Set("select", "friend_user_id")
	rows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "friend_connections", params)
	if err != nil {
		return nil, err
	}
	friendSet := make(map[string]struct{}, len(rows))
	for _, row := range rows {
		friendID := strings.TrimSpace(toString(row["friend_user_id"]))
		if friendID != "" {
			friendSet[friendID] = struct{}{}
		}
	}
	return friendSet, nil
}

func mapConversationRoomRecord(row map[string]any) conversationRoomRecord {
	theme := strings.TrimSpace(toString(row["theme"]))
	if theme == "" {
		theme = strings.TrimSpace(toString(row["title"]))
	}
	description := strings.TrimSpace(toString(row["description"]))
	if description == "" {
		description = strings.TrimSpace(toString(row["topic"]))
	}
	if description == "" {
		description = strings.TrimSpace(toString(row["city"]))
	}
	capacity, hasCapacity := toInt(row["capacity"])
	if !hasCapacity || capacity <= 0 {
		capacity = defaultConversationRoomCapacity
	}

	startsAt := parseConversationRoomTime(row["starts_at"])
	endsAt := parseConversationRoomTime(row["ends_at"])
	if startsAt.IsZero() {
		startsAt = time.Now().UTC().Add(-time.Hour)
	}
	if endsAt.IsZero() {
		endsAt = startsAt.Add(time.Hour)
	}

	return conversationRoomRecord{
		ID:          strings.TrimSpace(toString(row["id"])),
		Theme:       theme,
		Description: description,
		StartsAt:    startsAt,
		EndsAt:      endsAt,
		Capacity:    capacity,
	}
}

func mapConversationRoomModerationAction(row map[string]any) conversationRoomModerationAction {
	moderatorUserID := strings.TrimSpace(toString(row["moderator_user_id"]))
	if moderatorUserID == "" {
		moderatorUserID = strings.TrimSpace(toString(row["actor_user_id"]))
	}
	return conversationRoomModerationAction{
		ID:              strings.TrimSpace(toString(row["id"])),
		RoomID:          strings.TrimSpace(toString(row["room_id"])),
		ModeratorUserID: moderatorUserID,
		TargetUserID:    strings.TrimSpace(toString(row["target_user_id"])),
		Action:          strings.TrimSpace(toString(row["action"])),
		Reason:          strings.TrimSpace(toString(row["reason"])),
		CreatedAt:       parseConversationRoomTime(row["created_at"]).UTC().Format(time.RFC3339),
	}
}

func parseConversationRoomTime(value any) time.Time {
	raw := strings.TrimSpace(toString(value))
	if raw == "" {
		return time.Time{}
	}
	parsed, err := time.Parse(time.RFC3339, raw)
	if err == nil {
		return parsed.UTC()
	}
	if parsed, err = time.Parse("2006-01-02T15:04:05.999999Z07:00", raw); err == nil {
		return parsed.UTC()
	}
	if parsed, err = time.Parse("2006-01-02 15:04:05-07", raw); err == nil {
		return parsed.UTC()
	}
	return time.Time{}
}

func roomHasFriendParticipant(participants []string, userID string, friendSet map[string]struct{}) bool {
	normalizedUserID := strings.TrimSpace(userID)
	for _, participantUserID := range participants {
		if participantUserID == normalizedUserID {
			return true
		}
		if _, ok := friendSet[participantUserID]; ok {
			return true
		}
	}
	return false
}

func buildConversationRoomView(
	room conversationRoomRecord,
	participants []string,
	userID string,
	now time.Time,
) conversationRoomView {
	normalizedUserID := strings.TrimSpace(userID)
	participantUsers := append([]string{}, participants...)
	sort.Strings(participantUsers)
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
		IsParticipant:    containsString(participantUsers, normalizedUserID),
	}
}

func roomIDsFromRecords(rooms []conversationRoomRecord) []string {
	ids := make([]string, 0, len(rooms))
	for _, room := range rooms {
		id := strings.TrimSpace(room.ID)
		if id != "" {
			ids = append(ids, id)
		}
	}
	return ids
}

func isInactiveRoomParticipant(status string, leftAt any) bool {
	if strings.TrimSpace(toString(leftAt)) != "" {
		return true
	}
	switch status {
	case "left", "removed", "blocked", "muted":
		return true
	default:
		return false
	}
}

func mapModerationActionForDB(action string) string {
	switch strings.ToLower(strings.TrimSpace(action)) {
	case roomModerationActionRemove:
		return "remove"
	case roomModerationActionWarn:
		return "warn"
	default:
		return strings.ToLower(strings.TrimSpace(action))
	}
}
