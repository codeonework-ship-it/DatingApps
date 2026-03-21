package mobile

import (
	"errors"
	"net/http"
	"strings"

	"github.com/go-chi/chi/v5"

	engagementapp "github.com/verified-dating/backend/internal/modules/engagement/application"
)

func (s *Server) listCommunityGroups(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(r.URL.Query().Get("user_id"))
	city := strings.TrimSpace(r.URL.Query().Get("city"))
	topic := strings.TrimSpace(r.URL.Query().Get("topic"))
	onlyJoined := parseBoolQuery(r.URL.Query().Get("joined_only"))
	limit := parseRoomLimit(r.URL.Query().Get("limit"), 50)

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		engagementapp.ListCommunityGroupsCommandName,
		engagementapp.ListCommunityGroupsCommand{
			UserID:     userID,
			City:       city,
			Topic:      topic,
			OnlyJoined: onlyJoined,
			Limit:      limit,
		},
	)
	if err != nil {
		if errors.Is(err, engagementapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadRequest, err)
		return
	}

	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected list community groups response payload"))
		return
	}
	groups := mapSlice(resp["groups"])
	writeJSON(w, http.StatusOK, map[string]any{
		"groups":       groups,
		"count":        numericValue(resp["count"]),
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

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		engagementapp.CreateCommunityGroupCommandName,
		engagementapp.CreateCommunityGroupCommand{
			OwnerUserID:    ownerUserID,
			Name:           name,
			City:           city,
			Topic:          topic,
			Description:    description,
			Visibility:     visibility,
			InviteeUserIDs: inviteeUserIDs,
		},
	)
	if err != nil {
		if errors.Is(err, engagementapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadRequest, err)
		return
	}

	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected create community group response payload"))
		return
	}
	group, _ := resp["group"].(map[string]any)
	invites := mapSlice(resp["invites"])

	s.store.recordActivity(activityEvent{
		UserID:   ownerUserID,
		Actor:    ownerUserID,
		Action:   "community_group_created",
		Status:   "success",
		Resource: "/engagement/groups",
		Details: map[string]any{
			"group_id":       toString(group["id"]),
			"group_city":     toString(group["city"]),
			"group_topic":    toString(group["topic"]),
			"member_count":   numericValue(group["member_count"]),
			"invite_count":   len(invites),
			"visibility":     toString(group["visibility"]),
			"group_name":     toString(group["name"]),
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

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		engagementapp.InviteCommunityGroupMembersCommandName,
		engagementapp.InviteCommunityGroupMembersCommand{GroupID: groupID, InviterUserID: inviterUserID, InviteeUserIDs: inviteeUserIDs},
	)
	if err != nil {
		errMsg := strings.ToLower(err.Error())
		switch {
		case strings.Contains(errMsg, "not found"):
			writeError(w, http.StatusNotFound, err)
			return
		case strings.Contains(errMsg, "access") || strings.Contains(errMsg, "only owners"):
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

	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected invite community group members response payload"))
		return
	}
	invites := mapSlice(resp["invites"])

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

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		engagementapp.RespondCommunityGroupInviteCommandName,
		engagementapp.RespondCommunityGroupInviteCommand{GroupID: groupID, UserID: userID, Decision: decision},
	)
	if err != nil {
		errMsg := strings.ToLower(err.Error())
		switch {
		case strings.Contains(errMsg, "not found"):
			writeError(w, http.StatusNotFound, err)
			return
		case strings.Contains(errMsg, "invite") && strings.Contains(errMsg, "not found"):
			writeJSON(w, http.StatusNotFound, map[string]any{
				"success":    false,
				"error":      err.Error(),
				"error_code": "GROUP_INVITE_NOT_FOUND",
			})
			return
		case strings.Contains(errMsg, "decision") || strings.Contains(errMsg, "invalid"):
			writeError(w, http.StatusBadRequest, err)
			return
		default:
			writeError(w, http.StatusBadRequest, err)
			return
		}
	}

	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected respond community group invite response payload"))
		return
	}
	group, _ := resp["group"].(map[string]any)
	invite, _ := resp["invite"].(map[string]any)

	s.store.recordActivity(activityEvent{
		UserID:   userID,
		Actor:    userID,
		Action:   "community_group_invite_responded",
		Status:   "success",
		Resource: "/engagement/groups/" + groupID + "/invites/respond",
		Details: map[string]any{
			"group_id": toString(group["id"]),
			"decision": decision,
			"status":   toString(invite["status"]),
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

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		engagementapp.ListCommunityGroupInvitesCommandName,
		engagementapp.ListCommunityGroupInvitesCommand{UserID: userID, Status: status, Limit: limit},
	)
	if err != nil {
		if errors.Is(err, engagementapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadRequest, err)
		return
	}

	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected list community group invites response payload"))
		return
	}
	invites := mapSlice(resp["invites"])
	writeJSON(w, http.StatusOK, map[string]any{
		"invites": invites,
		"count":   numericValue(resp["count"]),
		"status":  toString(resp["status"]),
	})
}

func mapSlice(value any) []map[string]any {
	if value == nil {
		return []map[string]any{}
	}
	if mapped, ok := value.([]map[string]any); ok {
		return mapped
	}
	items, ok := value.([]any)
	if !ok {
		return []map[string]any{}
	}
	out := make([]map[string]any, 0, len(items))
	for _, item := range items {
		if mapped, ok := item.(map[string]any); ok {
			out = append(out, mapped)
		}
	}
	return out
}
