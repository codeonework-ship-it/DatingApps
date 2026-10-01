package mobile

import (
	"context"
	"database/sql"
	"net/http"
	"strings"

	"github.com/go-chi/chi/v5"
)

// HTTP handlers for lifestyle community groups and private friend groups
// (lifestyle_groups.go, migration 118). Every actor is the authenticated
// principal; actor ids in request bodies are ignored (and owner_user_id,
// inviter_user_id or user_id naming someone else is rejected by the identity
// middleware before a handler runs).

func (s *Server) groupsContext(w http.ResponseWriter, r *http.Request) (string, *sql.DB, bool) {
	actor, err := requestPrincipal(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return "", nil, false
	}
	db, err := s.growthDB()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return "", nil, false
	}
	w.Header().Set("Cache-Control", "private, no-store")
	return actor.UserID, db, true
}

func (s *Server) groupFromPath(w http.ResponseWriter, r *http.Request) (string, *sql.DB, string, bool) {
	actor, db, ok := s.groupsContext(w, r)
	if !ok {
		return "", nil, "", false
	}
	groupID := strings.TrimSpace(chi.URLParam(r, "groupID"))
	if !activityUUID(w, groupID) {
		return "", nil, "", false
	}
	return actor, db, groupID, true
}

func (s *Server) recordGroupActivity(actor, action, groupID string, details map[string]any) {
	if s.store == nil {
		return
	}
	if details == nil {
		details = map[string]any{}
	}
	details["group_id"] = groupID
	s.store.recordActivity(activityEvent{
		UserID: actor, Actor: actor, Action: action, Status: "success",
		Resource: "/engagement/groups/" + groupID, Details: details,
	})
}

// GET /v1/engagement/group-categories
func (s *Server) listGroupCategoriesHandler(w http.ResponseWriter, r *http.Request) {
	_, db, ok := s.groupsContext(w, r)
	if !ok {
		return
	}
	categories, err := listGroupCategories(r.Context(), db)
	if err != nil {
		writeActivityError(w, err, groupsUnavailable)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"categories": categories})
}

// GET /v1/engagement/groups?scope=mine|discover&category=&q=
func (s *Server) listCommunityGroups(w http.ResponseWriter, r *http.Request) {
	actor, db, ok := s.groupsContext(w, r)
	if !ok {
		return
	}
	query := r.URL.Query()
	scope := strings.TrimSpace(query.Get("scope"))
	if scope == "" || parseBoolQuery(query.Get("joined_only")) {
		scope = "mine"
	}
	category := strings.TrimSpace(query.Get("category"))
	groups, err := listGroups(r.Context(), db, actor, scope, category, query.Get("q"), boundedQueryLimit(r, 50, 50))
	if err != nil {
		writeActivityError(w, err, groupsUnavailable)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"groups": groups, "count": len(groups), "scope": scope, "category": category})
}

// POST /v1/engagement/groups
func (s *Server) createCommunityGroup(w http.ResponseWriter, r *http.Request) {
	actor, db, ok := s.groupsContext(w, r)
	if !ok {
		return
	}
	body, ok := readJSON(w, r)
	if !ok {
		return
	}
	in := groupInput{
		ID:          strings.TrimSpace(toString(body["group_id"])),
		Kind:        toString(body["kind"]),
		Category:    toString(body["category_slug"]),
		Name:        toString(body["name"]),
		Description: toString(body["description"]),
		City:        toString(body["city"]),
		CoverEmoji:  toString(body["cover_emoji"]),
		CoverColor:  toString(body["cover_color"]),
	}
	// Older clients sent visibility instead of kind.
	if strings.TrimSpace(in.Kind) == "" {
		switch strings.TrimSpace(toString(body["visibility"])) {
		case "public":
			in.Kind = "community"
		case "private":
			in.Kind = "private"
		}
	}
	if ids, ok := toStringSlice(body["invitee_user_ids"]); ok {
		in.Invitees = ids
	}
	g, invited, err := createGroup(r.Context(), db, actor, in)
	if err != nil {
		writeActivityError(w, err, groupsUnavailable)
		return
	}
	s.recordGroupActivity(actor, "community_group_created", g.ID, map[string]any{
		"kind": g.Kind, "category": g.CategorySlug, "invite_count": len(invited),
	})
	writeJSON(w, http.StatusCreated, map[string]any{"group": g, "invited_user_ids": invited})
}

// GET, PATCH and DELETE /v1/engagement/groups/{groupID}
func (s *Server) communityGroupHandler(w http.ResponseWriter, r *http.Request) {
	actor, db, groupID, ok := s.groupFromPath(w, r)
	if !ok {
		return
	}
	switch r.Method {
	case http.MethodPatch:
		body, ok := readJSON(w, r)
		if !ok {
			return
		}
		g, err := updateGroup(r.Context(), db, actor, groupID, body)
		if err != nil {
			writeActivityError(w, err, groupsUnavailable)
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{"group": g})
	case http.MethodDelete:
		if err := deleteGroup(r.Context(), db, actor, groupID); err != nil {
			writeActivityError(w, err, groupsUnavailable)
			return
		}
		s.releaseGroupCoverMedia(context.WithoutCancel(r.Context()), groupID)
		s.recordGroupActivity(actor, "community_group_deleted", groupID, nil)
		writeJSON(w, http.StatusOK, map[string]any{"deleted": true, "group_id": groupID})
	default:
		g, err := readGroupDetail(r.Context(), db, actor, groupID)
		if err == nil && g.IsMember && !g.Removed && g.ChannelID == "" {
			// Groups created before group chat get their channel on first view.
			if g.ChannelID, err = ensureRefChannel(r.Context(), db, "group", groupID); err != nil {
				writeActivityError(w, err, groupsUnavailable)
				return
			}
		}
		if err != nil {
			writeActivityError(w, err, groupsUnavailable)
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{"group": g})
	}
}

// POST /v1/engagement/groups/{groupID}/join
func (s *Server) joinCommunityGroupHandler(w http.ResponseWriter, r *http.Request) {
	actor, db, groupID, ok := s.groupFromPath(w, r)
	if !ok {
		return
	}
	g, err := joinCommunityGroup(r.Context(), db, actor, groupID)
	if err != nil {
		writeActivityError(w, err, groupsUnavailable)
		return
	}
	s.recordGroupActivity(actor, "community_group_joined", groupID, nil)
	writeJSON(w, http.StatusOK, map[string]any{"group": g})
}

// POST /v1/engagement/groups/{groupID}/leave
func (s *Server) leaveCommunityGroupHandler(w http.ResponseWriter, r *http.Request) {
	actor, db, groupID, ok := s.groupFromPath(w, r)
	if !ok {
		return
	}
	result, err := leaveGroup(r.Context(), db, actor, groupID)
	if err != nil {
		writeActivityError(w, err, groupsUnavailable)
		return
	}
	if result["deleted"] == true {
		s.releaseGroupCoverMedia(context.WithoutCancel(r.Context()), groupID)
	}
	s.recordGroupActivity(actor, "community_group_left", groupID, map[string]any{"deleted": result["deleted"]})
	writeJSON(w, http.StatusOK, result)
}

// GET /v1/engagement/groups/{groupID}/members (members only)
func (s *Server) communityGroupMembersHandler(w http.ResponseWriter, r *http.Request) {
	actor, db, groupID, ok := s.groupFromPath(w, r)
	if !ok {
		return
	}
	g, err := readGroup(r.Context(), db, actor, groupID)
	if err == nil && !g.IsMember {
		err = activityFail(http.StatusForbidden, "Join this group to see who's in it.")
	}
	if err != nil {
		writeActivityError(w, err, groupsUnavailable)
		return
	}
	members, err := readGroupMembers(r.Context(), db, actor, groupID, 0)
	if err != nil {
		writeActivityError(w, err, groupsUnavailable)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"members": members, "count": len(members)})
}

// POST /v1/engagement/groups/{groupID}/members/{userID}
func (s *Server) manageCommunityGroupMemberHandler(w http.ResponseWriter, r *http.Request) {
	actor, db, groupID, ok := s.groupFromPath(w, r)
	if !ok {
		return
	}
	target := strings.TrimSpace(chi.URLParam(r, "userID"))
	if !activityUUID(w, target) {
		return
	}
	body, ok := readJSON(w, r)
	if !ok {
		return
	}
	members, err := manageGroupMember(r.Context(), db, actor, groupID, target, toString(body["action"]))
	if err != nil {
		writeActivityError(w, err, groupsUnavailable)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"members": members})
}

// POST /v1/engagement/groups/{groupID}/invites
func (s *Server) inviteCommunityGroupMembers(w http.ResponseWriter, r *http.Request) {
	actor, db, groupID, ok := s.groupFromPath(w, r)
	if !ok {
		return
	}
	body, ok := readJSON(w, r)
	if !ok {
		return
	}
	ids, _ := toStringSlice(body["invitee_user_ids"])
	invited, err := inviteToGroup(r.Context(), db, actor, groupID, ids)
	if err != nil {
		writeActivityError(w, err, groupsUnavailable)
		return
	}
	s.recordGroupActivity(actor, "community_group_invites_sent", groupID, map[string]any{"invite_count": len(invited)})
	writeJSON(w, http.StatusOK, map[string]any{"group_id": groupID, "invited_user_ids": invited})
}

// POST /v1/engagement/groups/{groupID}/invites/respond
func (s *Server) respondCommunityGroupInvite(w http.ResponseWriter, r *http.Request) {
	actor, db, groupID, ok := s.groupFromPath(w, r)
	if !ok {
		return
	}
	body, ok := readJSON(w, r)
	if !ok {
		return
	}
	decision := toString(body["decision"])
	g, err := respondGroupInvite(r.Context(), db, actor, groupID, decision)
	if err != nil {
		writeActivityError(w, err, groupsUnavailable)
		return
	}
	s.recordGroupActivity(actor, "community_group_invite_responded", groupID, map[string]any{"decision": decision})
	writeJSON(w, http.StatusOK, map[string]any{"group": g, "decision": strings.ToLower(strings.TrimSpace(decision))})
}

// GET /v1/engagement/group-invites (the member's pending invitations)
func (s *Server) listCommunityGroupInvites(w http.ResponseWriter, r *http.Request) {
	actor, db, ok := s.groupsContext(w, r)
	if !ok {
		return
	}
	invites, err := listGroupInvites(r.Context(), db, actor)
	if err != nil {
		writeActivityError(w, err, groupsUnavailable)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"invites": invites, "count": len(invites), "status": "pending"})
}

// GET /v1/engagement/group-friends?group_id= (friends for the invite picker)
func (s *Server) listGroupFriendsHandler(w http.ResponseWriter, r *http.Request) {
	actor, db, ok := s.groupsContext(w, r)
	if !ok {
		return
	}
	groupID := strings.TrimSpace(r.URL.Query().Get("group_id"))
	if groupID != "" {
		if !activityUUID(w, groupID) {
			return
		}
		if _, err := readGroup(r.Context(), db, actor, groupID); err != nil {
			writeActivityError(w, err, groupsUnavailable)
			return
		}
	}
	friends, err := listGroupFriends(r.Context(), db, actor, groupID)
	if err != nil {
		writeActivityError(w, err, groupsUnavailable)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"friends": friends})
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
