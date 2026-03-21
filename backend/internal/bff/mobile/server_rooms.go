package mobile

import (
	"errors"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
)

func (s *Server) listConversationRooms(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(r.URL.Query().Get("user_id"))
	state := strings.TrimSpace(r.URL.Query().Get("state"))
	friendOnly := parseBoolQuery(r.URL.Query().Get("friend_only"))
	limit := parseRoomLimit(r.URL.Query().Get("limit"), 50)

	now := time.Now().UTC()
	var (
		rooms []conversationRoomView
		err   error
	)
	if s.rooms != nil {
		ctx, cancel := s.withRequestTimeout(r.Context())
		rooms, err = s.rooms.listConversationRooms(ctx, userID, state, friendOnly, limit, now)
		cancel()
		if err != nil && (!isConversationRoomRepoPersistenceUnavailable(err) || s.cfg.RequireDurableEngagementStore) {
			writeError(w, http.StatusBadGateway, err)
			return
		}
	}
	if s.rooms == nil || (err != nil && isConversationRoomRepoPersistenceUnavailable(err) && !s.cfg.RequireDurableEngagementStore) {
		rooms = s.store.listConversationRooms(userID, state, friendOnly, limit, now)
	}
	if err != nil && s.rooms == nil {
		writeError(w, http.StatusBadRequest, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"rooms":          rooms,
		"count":          len(rooms),
		"state_filter":   strings.ToLower(state),
		"friend_only":    friendOnly,
		"requested_user": userID,
	})
}

func (s *Server) joinConversationRoom(w http.ResponseWriter, r *http.Request) {
	roomID := strings.TrimSpace(chi.URLParam(r, "roomID"))
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	userID := strings.TrimSpace(toString(payload["user_id"]))

	now := time.Now().UTC()
	var (
		room conversationRoomView
		err  error
	)
	if s.rooms != nil {
		ctx, cancel := s.withRequestTimeout(r.Context())
		room, err = s.rooms.joinConversationRoom(ctx, roomID, userID, now)
		cancel()
		if err != nil && (!isConversationRoomRepoPersistenceUnavailable(err) || s.cfg.RequireDurableEngagementStore) {
			switch {
			case errors.Is(err, errRoomNotFound):
				writeError(w, http.StatusNotFound, err)
				return
			case errors.Is(err, errRoomClosed):
				writeJSON(w, http.StatusConflict, map[string]any{
					"success":    false,
					"error":      err.Error(),
					"error_code": "ROOM_CLOSED",
				})
				return
			case errors.Is(err, errRoomCapacityReached):
				writeJSON(w, http.StatusConflict, map[string]any{
					"success":    false,
					"error":      err.Error(),
					"error_code": "ROOM_CAPACITY_REACHED",
				})
				return
			case errors.Is(err, errRoomBlockedActiveSession):
				writeJSON(w, http.StatusConflict, map[string]any{
					"success":    false,
					"error":      err.Error(),
					"error_code": "ROOM_BLOCKED_ACTIVE_SESSION",
				})
				return
			default:
				writeError(w, http.StatusBadRequest, err)
				return
			}
		}
	}
	if s.rooms == nil || (err != nil && isConversationRoomRepoPersistenceUnavailable(err) && !s.cfg.RequireDurableEngagementStore) {
		room, err = s.store.joinConversationRoom(roomID, userID, now)
	}
	if err != nil {
		switch {
		case errors.Is(err, errRoomNotFound):
			writeError(w, http.StatusNotFound, err)
			return
		case errors.Is(err, errRoomClosed):
			writeJSON(w, http.StatusConflict, map[string]any{
				"success":    false,
				"error":      err.Error(),
				"error_code": "ROOM_CLOSED",
			})
			return
		case errors.Is(err, errRoomCapacityReached):
			writeJSON(w, http.StatusConflict, map[string]any{
				"success":    false,
				"error":      err.Error(),
				"error_code": "ROOM_CAPACITY_REACHED",
			})
			return
		case errors.Is(err, errRoomBlockedActiveSession):
			writeJSON(w, http.StatusConflict, map[string]any{
				"success":    false,
				"error":      err.Error(),
				"error_code": "ROOM_BLOCKED_ACTIVE_SESSION",
			})
			return
		default:
			writeError(w, http.StatusBadRequest, err)
			return
		}
	}

	s.store.recordActivity(activityEvent{
		UserID:   userID,
		Actor:    userID,
		Action:   "room.participation.join",
		Status:   "success",
		Resource: "/rooms/" + roomID + "/join",
		Details: map[string]any{
			"room_id":           room.ID,
			"lifecycle_state":   room.LifecycleState,
			"participant_count": room.ParticipantCount,
		},
	})

	writeJSON(w, http.StatusOK, map[string]any{
		"room":   room,
		"joined": true,
	})
}

func (s *Server) leaveConversationRoom(w http.ResponseWriter, r *http.Request) {
	roomID := strings.TrimSpace(chi.URLParam(r, "roomID"))
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	userID := strings.TrimSpace(toString(payload["user_id"]))

	now := time.Now().UTC()
	var (
		room conversationRoomView
		err  error
	)
	if s.rooms != nil {
		ctx, cancel := s.withRequestTimeout(r.Context())
		room, err = s.rooms.leaveConversationRoom(ctx, roomID, userID, now)
		cancel()
		if err != nil && (!isConversationRoomRepoPersistenceUnavailable(err) || s.cfg.RequireDurableEngagementStore) {
			switch {
			case errors.Is(err, errRoomNotFound):
				writeError(w, http.StatusNotFound, err)
				return
			case errors.Is(err, errRoomNotParticipant):
				writeJSON(w, http.StatusConflict, map[string]any{
					"success":    false,
					"error":      err.Error(),
					"error_code": "ROOM_NOT_JOINED",
				})
				return
			default:
				writeError(w, http.StatusBadRequest, err)
				return
			}
		}
	}
	if s.rooms == nil || (err != nil && isConversationRoomRepoPersistenceUnavailable(err) && !s.cfg.RequireDurableEngagementStore) {
		room, err = s.store.leaveConversationRoom(roomID, userID, now)
	}
	if err != nil {
		switch {
		case errors.Is(err, errRoomNotFound):
			writeError(w, http.StatusNotFound, err)
			return
		case errors.Is(err, errRoomNotParticipant):
			writeJSON(w, http.StatusConflict, map[string]any{
				"success":    false,
				"error":      err.Error(),
				"error_code": "ROOM_NOT_JOINED",
			})
			return
		default:
			writeError(w, http.StatusBadRequest, err)
			return
		}
	}

	s.store.recordActivity(activityEvent{
		UserID:   userID,
		Actor:    userID,
		Action:   "room.participation.leave",
		Status:   "success",
		Resource: "/rooms/" + roomID + "/leave",
		Details: map[string]any{
			"room_id":           room.ID,
			"lifecycle_state":   room.LifecycleState,
			"participant_count": room.ParticipantCount,
		},
	})

	writeJSON(w, http.StatusOK, map[string]any{
		"room": room,
		"left": true,
	})
}

func (s *Server) moderateConversationRoom(w http.ResponseWriter, r *http.Request) {
	roomID := strings.TrimSpace(chi.URLParam(r, "roomID"))
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}

	moderatorUserID := strings.TrimSpace(toString(payload["moderator_user_id"]))
	targetUserID := strings.TrimSpace(toString(payload["target_user_id"]))
	action := strings.TrimSpace(toString(payload["action"]))
	reason := strings.TrimSpace(toString(payload["reason"]))

	now := time.Now().UTC()
	var (
		room             conversationRoomView
		moderationAction conversationRoomModerationAction
		err              error
	)
	if s.rooms != nil {
		ctx, cancel := s.withRequestTimeout(r.Context())
		room, moderationAction, err = s.rooms.moderateConversationRoom(
			ctx,
			roomID,
			moderatorUserID,
			targetUserID,
			action,
			reason,
			now,
		)
		cancel()
		if err != nil && (!isConversationRoomRepoPersistenceUnavailable(err) || s.cfg.RequireDurableEngagementStore) {
			switch {
			case errors.Is(err, errRoomNotFound):
				writeError(w, http.StatusNotFound, err)
				return
			case errors.Is(err, errRoomModerationAction):
				writeError(w, http.StatusBadRequest, err)
				return
			case errors.Is(err, errRoomModerationNotActive):
				writeJSON(w, http.StatusConflict, map[string]any{
					"success":    false,
					"error":      err.Error(),
					"error_code": "ROOM_NOT_ACTIVE",
				})
				return
			default:
				writeError(w, http.StatusBadRequest, err)
				return
			}
		}
	}
	if s.rooms == nil || (err != nil && isConversationRoomRepoPersistenceUnavailable(err) && !s.cfg.RequireDurableEngagementStore) {
		room, moderationAction, err = s.store.moderateConversationRoom(
			roomID,
			moderatorUserID,
			targetUserID,
			action,
			reason,
			now,
		)
	}
	if err != nil {
		switch {
		case errors.Is(err, errRoomNotFound):
			writeError(w, http.StatusNotFound, err)
			return
		case errors.Is(err, errRoomModerationAction):
			writeError(w, http.StatusBadRequest, err)
			return
		case errors.Is(err, errRoomModerationNotActive):
			writeJSON(w, http.StatusConflict, map[string]any{
				"success":    false,
				"error":      err.Error(),
				"error_code": "ROOM_NOT_ACTIVE",
			})
			return
		default:
			writeError(w, http.StatusBadRequest, err)
			return
		}
	}

	s.store.recordActivity(activityEvent{
		UserID:   targetUserID,
		Actor:    moderatorUserID,
		Action:   "room.moderation.action",
		Status:   "success",
		Resource: "/rooms/" + roomID + "/moderate",
		Details: map[string]any{
			"room_id":              room.ID,
			"moderation_action":    moderationAction.Action,
			"target_user_id":       moderationAction.TargetUserID,
			"moderator_user_id":    moderationAction.ModeratorUserID,
			"participant_count":    room.ParticipantCount,
			"lifecycle_state":      room.LifecycleState,
			"moderation_reason":    moderationAction.Reason,
			"moderation_action_id": moderationAction.ID,
		},
	})

	writeJSON(w, http.StatusOK, map[string]any{
		"room":              room,
		"moderation_action": moderationAction,
		"policy_enforced":   true,
	})
}

func parseRoomLimit(raw string, fallback int) int {
	trimmed := strings.TrimSpace(raw)
	if trimmed == "" {
		return fallback
	}
	parsed, err := strconv.Atoi(trimmed)
	if err != nil || parsed <= 0 {
		return fallback
	}
	if parsed > 200 {
		return 200
	}
	return parsed
}

func parseBoolQuery(raw string) bool {
	normalized := strings.ToLower(strings.TrimSpace(raw))
	return normalized == "true" || normalized == "1" || normalized == "yes"
}
