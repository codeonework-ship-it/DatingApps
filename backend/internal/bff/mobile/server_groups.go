package mobile

import (
	"errors"
	"net/http"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
)

func (s *Server) listCommunityGroups(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(r.URL.Query().Get("user_id"))
	city := strings.TrimSpace(r.URL.Query().Get("city"))
	topic := strings.TrimSpace(r.URL.Query().Get("topic"))
	onlyJoined := parseBoolQuery(r.URL.Query().Get("joined_only"))
	limit := parseRoomLimit(r.URL.Query().Get("limit"), 50)

	groups := s.store.listCommunityGroups(userID, city, topic, onlyJoined, limit)
	writeJSON(w, http.StatusOK, map[string]any{
		"groups":       groups,
		"count":        len(groups),
		"city_filter":  city,
		"topic_filter": topic,
		"joined_only":  onlyJoined,
	})
}

func (s *Server) createCommunityGroup(w http.ResponseWriter, r *http.Request) {
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}

	ownerUserID := strings.TrimSpace(toString(payload["owner_user_id"]))
	name := strings.TrimSpace(toString(payload["name"]))
	city := strings.TrimSpace(toString(payload["city"]))
	topic := strings.TrimSpace(toString(payload["topic"]))
	description := strings.TrimSpace(toString(payload["description"]))
	visibility := strings.TrimSpace(toString(payload["visibility"]))
	inviteeUserIDs := []string{}
	if parsedInvitees, ok := toStringSlice(payload["invitee_user_ids"]); ok {
		inviteeUserIDs = parsedInvitees
	}

	group, invites, err := s.store.createCommunityGroup(
		ownerUserID,
		name,
		city,
		topic,
		description,
		visibility,
		inviteeUserIDs,
		time.Now().UTC(),
	)
	if err != nil {
		writeError(w, http.StatusBadRequest, err)
		return
	}

	s.store.recordActivity(activityEvent{
		UserID:   ownerUserID,
		Actor:    ownerUserID,
		Action:   "community_group_created",
		Status:   "success",
		Resource: "/engagement/groups",
		Details: map[string]any{
			"group_id":       group.ID,
			"group_city":     group.City,
			"group_topic":    group.Topic,
			"member_count":   group.MemberCount,
			"invite_count":   len(invites),
			"visibility":     group.Visibility,
			"group_name":     group.Name,
			"created_by_uid": ownerUserID,
		},
	})

	writeJSON(w, http.StatusCreated, map[string]any{
		"group":   group,
		"invites": invites,
	})
}

func (s *Server) inviteCommunityGroupMembers(w http.ResponseWriter, r *http.Request) {
	groupID := strings.TrimSpace(chi.URLParam(r, "groupID"))
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}

	inviterUserID := strings.TrimSpace(toString(payload["inviter_user_id"]))
	inviteeUserIDs := []string{}
	if parsedInvitees, ok := toStringSlice(payload["invitee_user_ids"]); ok {
		inviteeUserIDs = parsedInvitees
	}

	invites, err := s.store.createCommunityGroupInvites(groupID, inviterUserID, inviteeUserIDs, time.Now().UTC())
	if err != nil {
		switch {
		case errors.Is(err, errCommunityGroupNotFound):
			writeError(w, http.StatusNotFound, err)
			return
		case errors.Is(err, errCommunityGroupAccessDenied):
			writeJSON(w, http.StatusForbidden, map[string]any{
				"success":    false,
				"error":      err.Error(),
				"error_code": "GROUP_ACCESS_DENIED",
			})
			return
		default:
			writeError(w, http.StatusBadRequest, err)
			return
		}
	}

	s.store.recordActivity(activityEvent{
		UserID:   inviterUserID,
		Actor:    inviterUserID,
		Action:   "community_group_invites_sent",
		Status:   "success",
		Resource: "/engagement/groups/" + groupID + "/invites",
		Details: map[string]any{
			"group_id":        groupID,
			"invite_count":    len(invites),
			"inviter_user_id": inviterUserID,
		},
	})

	writeJSON(w, http.StatusOK, map[string]any{
		"group_id": groupID,
		"invites":  invites,
	})
}

func (s *Server) respondCommunityGroupInvite(w http.ResponseWriter, r *http.Request) {
	groupID := strings.TrimSpace(chi.URLParam(r, "groupID"))
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}

	userID := strings.TrimSpace(toString(payload["user_id"]))
	decision := strings.TrimSpace(toString(payload["decision"]))

	group, invite, err := s.store.respondCommunityGroupInvite(groupID, userID, decision, time.Now().UTC())
	if err != nil {
		switch {
		case errors.Is(err, errCommunityGroupNotFound):
			writeError(w, http.StatusNotFound, err)
			return
		case errors.Is(err, errCommunityGroupInviteMissing):
			writeJSON(w, http.StatusNotFound, map[string]any{
				"success":    false,
				"error":      err.Error(),
				"error_code": "GROUP_INVITE_NOT_FOUND",
			})
			return
		case errors.Is(err, errCommunityGroupInvalidAction):
			writeError(w, http.StatusBadRequest, err)
			return
		default:
			writeError(w, http.StatusBadRequest, err)
			return
		}
	}

	s.store.recordActivity(activityEvent{
		UserID:   userID,
		Actor:    userID,
		Action:   "community_group_invite_responded",
		Status:   "success",
		Resource: "/engagement/groups/" + groupID + "/invites/respond",
		Details: map[string]any{
			"group_id": group.ID,
			"decision": decision,
			"status":   invite.Status,
		},
	})

	writeJSON(w, http.StatusOK, map[string]any{
		"group":  group,
		"invite": invite,
	})
}

func (s *Server) listCommunityGroupInvites(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(r.URL.Query().Get("user_id"))
	status := strings.TrimSpace(r.URL.Query().Get("status"))
	limit := parseRoomLimit(r.URL.Query().Get("limit"), 50)

	invites := s.store.listCommunityGroupInvites(userID, status, limit)
	writeJSON(w, http.StatusOK, map[string]any{
		"invites": invites,
		"count":   len(invites),
		"status":  status,
	})
}
