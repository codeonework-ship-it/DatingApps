package mobile

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)

// Lifestyle community groups and private friend groups (migration 118).

type groupsHarness struct {
	t *testing.T
	f datePlanFixture
	s *Server
}

func newGroupsHarness(t *testing.T) groupsHarness {
	t.Helper()
	f := newDatePlanFixture(t)
	var ready bool
	if err := f.db.QueryRow(`SELECT to_regclass('matching.group_categories') IS NOT NULL`).Scan(&ready); err != nil {
		t.Fatal(err)
	}
	if !ready {
		t.Skip("migration 118_lifestyle_groups is not applied")
	}
	users := []string{f.proposer, f.invitee, f.proposerFriend, f.inviteeFriend, f.blockedFriend, f.groupMate, f.stranger}
	// Registered after the fixture, so it runs before the members are deleted:
	// group channels have no foreign key to the group.
	t.Cleanup(func() {
		for _, u := range users {
			_, _ = f.db.Exec(`DELETE FROM matching.social_channels WHERE kind='group' AND ref_id IN(SELECT id FROM matching.community_groups WHERE created_by_user_id=$1)`, u)
			_, _ = f.db.Exec(`DELETE FROM matching.community_groups WHERE created_by_user_id=$1`, u)
		}
	})
	return groupsHarness{t: t, f: f, s: blogServer(f)}
}

func groupRequest(method, user, query, body string, params map[string]string) *http.Request {
	target := "/"
	if query != "" {
		target += "?" + query
	}
	r := httptest.NewRequest(method, target, strings.NewReader(body))
	r.Header.Set("Content-Type", "application/json")
	rc := chi.NewRouteContext()
	for k, v := range params {
		rc.URLParams.Add(k, v)
	}
	ctx := context.WithValue(r.Context(), chi.RouteCtxKey, rc)
	if user != "" {
		ctx = context.WithValue(ctx, securityPrincipalContextKey{}, securityPrincipal{UserID: user, Roles: map[string]bool{"user": true}})
	}
	return r.WithContext(ctx)
}

func (h groupsHarness) call(handler http.HandlerFunc, method, user, query, body string, params map[string]string) (int, map[string]any) {
	h.t.Helper()
	rec := httptest.NewRecorder()
	handler(rec, groupRequest(method, user, query, body, params))
	out := map[string]any{}
	if err := json.Unmarshal(rec.Body.Bytes(), &out); err != nil {
		h.t.Fatalf("decode %d %s: %v", rec.Code, rec.Body.String(), err)
	}
	return rec.Code, out
}

func (h groupsHarness) create(user string, body map[string]any) (int, map[string]any) {
	h.t.Helper()
	raw, _ := json.Marshal(body)
	return h.call(h.s.createCommunityGroup, http.MethodPost, user, "", string(raw), nil)
}

func (h groupsHarness) mustCreate(user string, body map[string]any) map[string]any {
	h.t.Helper()
	code, out := h.create(user, body)
	if code != http.StatusCreated {
		h.t.Fatalf("create group code=%d body=%v", code, out)
	}
	return out["group"].(map[string]any)
}

func (h groupsHarness) detail(user, groupID string) (int, map[string]any) {
	h.t.Helper()
	code, out := h.call(h.s.communityGroupHandler, http.MethodGet, user, "", "", map[string]string{"groupID": groupID})
	g, _ := out["group"].(map[string]any)
	return code, g
}

func (h groupsHarness) post(handler http.HandlerFunc, user, groupID, body string) (int, map[string]any) {
	h.t.Helper()
	return h.call(handler, http.MethodPost, user, "", body, map[string]string{"groupID": groupID})
}

func (h groupsHarness) manage(actor, groupID, target, action string) int {
	h.t.Helper()
	code, _ := h.call(h.s.manageCommunityGroupMemberHandler, http.MethodPost, actor, "", `{"action":"`+action+`"}`,
		map[string]string{"groupID": groupID, "userID": target})
	return code
}

func (h groupsHarness) owner(groupID string) string {
	h.t.Helper()
	var owner string
	if err := h.f.db.QueryRow(`SELECT created_by_user_id::text FROM matching.community_groups WHERE id=$1`, groupID).Scan(&owner); err != nil {
		h.t.Fatal(err)
	}
	return owner
}

func groupIDs(list any) []string {
	ids := []string{}
	items, _ := list.([]any)
	for _, item := range items {
		ids = append(ids, toString(item.(map[string]any)["id"]))
	}
	return ids
}

func TestGroupsCreateFriendOnlyInviteesPostgres(t *testing.T) {
	h := newGroupsHarness(t)
	f := h.f
	g := h.mustCreate(f.proposer, map[string]any{
		"kind": "private", "name": "Sunday brunch crew", "description": "Pancakes and gossip",
		"cover_emoji": "🥞", "cover_color": "tertiary", "invitee_user_ids": []string{f.proposerFriend, f.proposer},
	})
	if g["kind"] != "private" || g["visibility"] != "private" || g["my_role"] != "owner" || toString(g["channel_id"]) == "" {
		t.Fatalf("unexpected group %v", g)
	}
	if n := int(g["member_count"].(float64)); n != 1 {
		t.Fatalf("owner should be the only member until invites are accepted, got %d", n)
	}
	if got := f.notifications(t, f.proposerFriend, "group.invite.received"); got != 1 {
		t.Fatalf("friend invite notifications=%d", got)
	}
	var title string
	if err := f.db.QueryRow(`SELECT title FROM matching.notification_outbox WHERE recipient_user_id=$1 AND event_type='group.invite.received'`, f.proposerFriend).Scan(&title); err != nil {
		t.Fatal(err)
	}
	if title != "Priya invited you to Sunday brunch crew" {
		t.Fatalf("invite title %q", title)
	}

	// Strangers, matches who aren't friends, and friends on either side of a
	// block cannot be invited; nothing is created.
	for _, invitee := range []string{f.stranger, f.invitee, f.blockedFriend} {
		code, out := h.create(f.proposer, map[string]any{"kind": "private", "name": "Not allowed", "invitee_user_ids": []string{invitee}})
		if code != http.StatusForbidden {
			t.Fatalf("invitee %s: code=%d body=%v", invitee, code, out)
		}
	}
	var leaked int
	if err := f.db.QueryRow(`SELECT COUNT(*) FROM matching.community_groups WHERE created_by_user_id=$1 AND name='Not allowed'`, f.proposer).Scan(&leaked); err != nil {
		t.Fatal(err)
	}
	if leaked != 0 {
		t.Fatalf("rejected creates left %d groups", leaked)
	}

	// Community groups need a known lifestyle category.
	if code, _ := h.create(f.proposer, map[string]any{"kind": "community", "name": "Runners"}); code != http.StatusBadRequest {
		t.Fatalf("community without category code=%d", code)
	}
	if code, _ := h.create(f.proposer, map[string]any{"kind": "community", "name": "Runners", "category_slug": "nope"}); code != http.StatusBadRequest {
		t.Fatalf("unknown category code=%d", code)
	}
	if code, _ := h.create(f.proposer, map[string]any{"kind": "club", "name": "Runners"}); code != http.StatusBadRequest {
		t.Fatalf("unknown kind code=%d", code)
	}
	id := uuid.NewString()
	c := h.mustCreate(f.proposer, map[string]any{"group_id": id, "kind": "community", "category_slug": "fitness-running", "name": "Cubbon Park runners"})
	if c["category_title"] != "Fitness & running" || c["visibility"] != "public" || c["category_emoji"] != "🏃" {
		t.Fatalf("community group %v", c)
	}
	// A retried create with the same id returns the same group.
	again := h.mustCreate(f.proposer, map[string]any{"group_id": id, "kind": "community", "category_slug": "fitness-running", "name": "Cubbon Park runners"})
	if again["id"] != id {
		t.Fatalf("retry returned %v", again["id"])
	}
	if code, _ := h.create(f.stranger, map[string]any{"group_id": id, "kind": "private", "name": "Hijack"}); code != http.StatusConflict {
		t.Fatalf("reused id by another member code=%d", code)
	}
}

func TestGroupsIdentityComesFromPrincipalPostgres(t *testing.T) {
	h := newGroupsHarness(t)
	f := h.f
	// The identity middleware rejects a body naming another actor.
	for _, key := range []string{"owner_user_id", "inviter_user_id", "user_id"} {
		r := groupRequest(http.MethodPost, f.stranger, "", `{"`+key+`":"`+f.proposer+`","name":"x"}`, nil)
		if err := enforceBodyIdentity(r, f.stranger); err == nil {
			t.Fatalf("%s spoof was accepted", key)
		}
	}
	// Without a session nothing happens.
	if code, _ := h.call(h.s.createCommunityGroup, http.MethodPost, "", "", `{"kind":"private","name":"Anon"}`, nil); code != http.StatusUnauthorized {
		t.Fatalf("anonymous create code=%d", code)
	}
	// The owner is always the principal, whatever the body says.
	g := h.mustCreate(f.stranger, map[string]any{"kind": "private", "name": "Mine not yours", "owner_user_id": f.proposer})
	if h.owner(toString(g["id"])) != f.stranger {
		t.Fatal("owner taken from the body")
	}
	// Responding for someone else is impossible: the invitee is the principal.
	code, _ := h.post(h.s.respondCommunityGroupInvite, f.stranger, f.groupID, `{"user_id":"`+f.groupMate+`","decision":"accept"}`)
	if code != http.StatusNotFound {
		t.Fatalf("stranger responding to a private group code=%d", code)
	}
}

func TestGroupsDiscoverJoinAndPrivacyPostgres(t *testing.T) {
	h := newGroupsHarness(t)
	f := h.f
	community := h.mustCreate(f.proposer, map[string]any{"kind": "community", "category_slug": "books", "name": "Koramangala readers", "description": "One book a month"})
	cid := toString(community["id"])
	private := h.mustCreate(f.proposer, map[string]any{"kind": "private", "name": "Close friends"})
	pid := toString(private["id"])

	code, out := h.call(h.s.listCommunityGroups, http.MethodGet, f.stranger, "scope=discover&category=books", "", nil)
	if code != 200 || !containsString(groupIDs(out["groups"]), cid) || containsString(groupIDs(out["groups"]), pid) {
		t.Fatalf("discover code=%d groups=%v", code, groupIDs(out["groups"]))
	}
	_, out = h.call(h.s.listCommunityGroups, http.MethodGet, f.stranger, "scope=discover&category=music", "", nil)
	if containsString(groupIDs(out["groups"]), cid) {
		t.Fatal("category filter ignored")
	}
	_, out = h.call(h.s.listCommunityGroups, http.MethodGet, f.stranger, "scope=discover&q=koramangala", "", nil)
	if !containsString(groupIDs(out["groups"]), cid) {
		t.Fatal("search did not find the group")
	}
	// Someone who blocked the owner never sees the owner's groups.
	_, out = h.call(h.s.listCommunityGroups, http.MethodGet, f.blockedFriend, "scope=discover", "", nil)
	if containsString(groupIDs(out["groups"]), cid) {
		t.Fatal("blocked member discovered the owner's group")
	}
	if code, _ := h.detail(f.blockedFriend, cid); code != http.StatusNotFound {
		t.Fatalf("blocked member detail code=%d", code)
	}

	// Non-members see a community group without its chat or member list.
	code, g := h.detail(f.stranger, cid)
	if code != 200 || g["is_member"] != false || toString(g["channel_id"]) != "" || g["members_preview"] != nil || g["can_join"] != true {
		t.Fatalf("non-member detail code=%d %v", code, g)
	}
	if code, _ := h.call(h.s.communityGroupMembersHandler, http.MethodGet, f.stranger, "", "", map[string]string{"groupID": cid}); code != http.StatusForbidden {
		t.Fatalf("non-member members code=%d", code)
	}
	// Private groups are invisible and unjoinable for non-members.
	if code, _ := h.detail(f.stranger, pid); code != http.StatusNotFound {
		t.Fatalf("private detail code=%d", code)
	}
	if code, _ := h.post(h.s.joinCommunityGroupHandler, f.stranger, pid, `{}`); code != http.StatusNotFound {
		t.Fatalf("join private code=%d", code)
	}
	if code, _ := h.call(h.s.communityGroupMembersHandler, http.MethodGet, f.stranger, "", "", map[string]string{"groupID": pid}); code != http.StatusNotFound {
		t.Fatalf("private members code=%d", code)
	}
	// The legacy fixture group: a non-member who knows the id still cannot join.
	if code, _ := h.post(h.s.joinCommunityGroupHandler, f.stranger, f.groupID, `{}`); code != http.StatusNotFound {
		t.Fatalf("join legacy private code=%d", code)
	}

	code, out = h.post(h.s.joinCommunityGroupHandler, f.stranger, cid, `{}`)
	if code != 200 {
		t.Fatalf("join code=%d %v", code, out)
	}
	joined := out["group"].(map[string]any)
	if joined["is_member"] != true || joined["my_role"] != "member" || toString(joined["channel_id"]) == "" || int(joined["member_count"].(float64)) != 2 {
		t.Fatalf("joined %v", joined)
	}
	if code, _ := h.post(h.s.joinCommunityGroupHandler, f.stranger, cid, `{}`); code != 200 {
		t.Fatalf("repeat join code=%d", code)
	}
	code, out = h.call(h.s.communityGroupMembersHandler, http.MethodGet, f.stranger, "", "", map[string]string{"groupID": cid})
	if code != 200 || int(out["count"].(float64)) != 2 {
		t.Fatalf("members code=%d %v", code, out)
	}
	first := out["members"].([]any)[0].(map[string]any)
	if first["user_id"] != f.proposer || first["role"] != "owner" || first["name"] != "Priya" {
		t.Fatalf("owner should be listed first: %v", first)
	}
	_, out = h.call(h.s.listCommunityGroups, http.MethodGet, f.stranger, "scope=mine", "", nil)
	if !containsString(groupIDs(out["groups"]), cid) {
		t.Fatal("joined group missing from my groups")
	}
	_, out = h.call(h.s.listCommunityGroups, http.MethodGet, f.stranger, "scope=discover", "", nil)
	if containsString(groupIDs(out["groups"]), cid) {
		t.Fatal("joined group still offered in discover")
	}

	// Legacy group created before 118: the creator is its owner and gets a chat.
	code, legacy := h.detail(f.proposer, f.groupID)
	if code != 200 || legacy["my_role"] != "owner" || toString(legacy["channel_id"]) == "" {
		t.Fatalf("legacy detail code=%d %v", code, legacy)
	}
}

func TestGroupsInvitesRespondAndNotifyPostgres(t *testing.T) {
	h := newGroupsHarness(t)
	f := h.f
	g := h.mustCreate(f.proposer, map[string]any{"kind": "private", "name": "Trek planners", "invitee_user_ids": []string{f.proposerFriend}})
	id := toString(g["id"])

	// The invitee sees the pending invitation and the group itself.
	code, out := h.call(h.s.listCommunityGroupInvites, http.MethodGet, f.proposerFriend, "", "", nil)
	invites, _ := out["invites"].([]any)
	if code != 200 || len(invites) != 1 {
		t.Fatalf("invites code=%d %v", code, out)
	}
	inv := invites[0].(map[string]any)
	if inv["inviter_name"] != "Priya" || inv["group"].(map[string]any)["name"] != "Trek planners" {
		t.Fatalf("invite %v", inv)
	}
	if code, d := h.detail(f.proposerFriend, id); code != 200 || toString(d["invite_id"]) == "" || toString(d["channel_id"]) != "" {
		t.Fatalf("invitee detail code=%d %v", code, d)
	}
	if code, _ := h.post(h.s.respondCommunityGroupInvite, f.proposerFriend, id, `{"decision":"maybe"}`); code != http.StatusBadRequest {
		t.Fatalf("bad decision code=%d", code)
	}
	code, out = h.post(h.s.respondCommunityGroupInvite, f.proposerFriend, id, `{"decision":"accept"}`)
	if code != 200 || out["group"].(map[string]any)["is_member"] != true {
		t.Fatalf("accept code=%d %v", code, out)
	}
	if code, _ := h.post(h.s.respondCommunityGroupInvite, f.proposerFriend, id, `{"decision":"accept"}`); code != 200 {
		t.Fatalf("retried accept code=%d", code)
	}
	if got := f.notifications(t, f.proposer, "group.invite.accepted"); got != 1 {
		t.Fatalf("accepted notifications=%d", got)
	}

	// A plain member of a private group cannot invite.
	blogExec(t, f, `INSERT INTO matching.friend_connections(user_id,friend_user_id,status) VALUES($1,$2,'accepted'),($2,$1,'accepted')`, f.proposerFriend, f.stranger)
	if code, _ := h.post(h.s.inviteCommunityGroupMembers, f.proposerFriend, id, `{"invitee_user_ids":["`+f.stranger+`"]}`); code != http.StatusForbidden {
		t.Fatalf("member invite to private group code=%d", code)
	}
	// After promotion they can, and the invitee may decline.
	if code := h.manage(f.proposer, id, f.proposerFriend, "make_moderator"); code != 200 {
		t.Fatalf("promote code=%d", code)
	}
	code, out = h.post(h.s.inviteCommunityGroupMembers, f.proposerFriend, id, `{"invitee_user_ids":["`+f.stranger+`"]}`)
	if code != 200 || len(out["invited_user_ids"].([]any)) != 1 {
		t.Fatalf("moderator invite code=%d %v", code, out)
	}
	// A friend the owner isn't friends with can't be invited by the owner.
	if code, _ := h.post(h.s.inviteCommunityGroupMembers, f.proposer, id, `{"invitee_user_ids":["`+f.stranger+`"]}`); code != http.StatusForbidden {
		t.Fatalf("owner inviting a non-friend code=%d", code)
	}
	if code, _ := h.post(h.s.respondCommunityGroupInvite, f.stranger, id, `{"decision":"decline"}`); code != 200 {
		t.Fatalf("decline code=%d", code)
	}
	if code, _ := h.detail(f.stranger, id); code != http.StatusNotFound {
		t.Fatalf("declined invitee still sees the private group: %d", code)
	}

	// Community groups: any member invites their own friends.
	c := h.mustCreate(f.proposer, map[string]any{"kind": "community", "category_slug": "music", "name": "Indie gigs"})
	cid := toString(c["id"])
	if code, _ := h.post(h.s.joinCommunityGroupHandler, f.invitee, cid, `{}`); code != 200 {
		t.Fatalf("join code=%d", code)
	}
	if code, out := h.post(h.s.inviteCommunityGroupMembers, f.invitee, cid, `{"invitee_user_ids":["`+f.inviteeFriend+`"]}`); code != 200 {
		t.Fatalf("member invite in community code=%d %v", code, out)
	}
	if got := f.notifications(t, f.inviteeFriend, "group.invite.received"); got != 1 {
		t.Fatalf("community invite notifications=%d", got)
	}
	// The invite picker reflects standing.
	code, out = h.call(h.s.listGroupFriendsHandler, http.MethodGet, f.invitee, "group_id="+cid, "", nil)
	if code != 200 {
		t.Fatalf("group friends code=%d", code)
	}
	friends := out["friends"].([]any)
	if len(friends) != 1 || friends[0].(map[string]any)["status"] != "invited" {
		t.Fatalf("group friends %v", friends)
	}
	_, out = h.call(h.s.listGroupFriendsHandler, http.MethodGet, f.proposer, "", "", nil)
	for _, fr := range out["friends"].([]any) {
		if fr.(map[string]any)["user_id"] == f.blockedFriend {
			t.Fatal("blocked friend offered in the picker")
		}
	}
}

func TestGroupsLeaveHandsOverOwnershipPostgres(t *testing.T) {
	h := newGroupsHarness(t)
	f := h.f
	g := h.mustCreate(f.proposer, map[string]any{"kind": "community", "category_slug": "outdoors-hiking", "name": "Nandi sunrise hikers"})
	id := toString(g["id"])
	for _, u := range []string{f.proposerFriend, f.stranger} {
		if code, _ := h.post(h.s.joinCommunityGroupHandler, u, id, `{}`); code != 200 {
			t.Fatalf("join code=%d", code)
		}
	}
	// The later joiner is a moderator, so they outrank the earlier member.
	if code := h.manage(f.proposer, id, f.stranger, "make_moderator"); code != 200 {
		t.Fatalf("promote code=%d", code)
	}
	code, out := h.post(h.s.leaveCommunityGroupHandler, f.proposer, id, `{}`)
	if code != 200 || out["new_owner_user_id"] != f.stranger || out["deleted"] != false {
		t.Fatalf("owner leave code=%d %v", code, out)
	}
	if h.owner(id) != f.stranger {
		t.Fatal("ownership not handed to the moderator")
	}
	if _, d := h.detail(f.stranger, id); d["my_role"] != "owner" || d["can_manage"] != true {
		t.Fatalf("new owner detail %v", d)
	}
	if code, _ := h.post(h.s.leaveCommunityGroupHandler, f.stranger, id, `{}`); code != 200 {
		t.Fatalf("second leave code=%d", code)
	}
	if h.owner(id) != f.proposerFriend {
		t.Fatal("ownership not handed to the longest-standing member")
	}
	code, out = h.post(h.s.leaveCommunityGroupHandler, f.proposerFriend, id, `{}`)
	if code != 200 || out["deleted"] != true {
		t.Fatalf("last leave code=%d %v", code, out)
	}
	var left int
	if err := f.db.QueryRow(`SELECT (SELECT COUNT(*) FROM matching.community_groups WHERE id=$1)+(SELECT COUNT(*) FROM matching.social_channels WHERE kind='group' AND ref_id=$1)`, id).Scan(&left); err != nil {
		t.Fatal(err)
	}
	if left != 0 {
		t.Fatal("empty group or its chat survived")
	}
	// The group is gone for everyone.
	if code, _ := h.post(h.s.leaveCommunityGroupHandler, f.stranger, id, `{}`); code != http.StatusNotFound {
		t.Fatalf("leave deleted group code=%d", code)
	}
}

func TestGroupsManageEditDeletePostgres(t *testing.T) {
	h := newGroupsHarness(t)
	f := h.f
	g := h.mustCreate(f.proposer, map[string]any{"kind": "community", "category_slug": "foodies", "name": "Dosa trail"})
	id := toString(g["id"])
	for _, u := range []string{f.proposerFriend, f.stranger, f.invitee} {
		if code, _ := h.post(h.s.joinCommunityGroupHandler, u, id, `{}`); code != 200 {
			t.Fatalf("join code=%d", code)
		}
	}
	if code := h.manage(f.stranger, id, f.invitee, "make_moderator"); code != http.StatusForbidden {
		t.Fatalf("member promoting code=%d", code)
	}
	if code := h.manage(f.proposer, id, f.proposerFriend, "make_moderator"); code != 200 {
		t.Fatalf("promote code=%d", code)
	}
	if code := h.manage(f.proposerFriend, id, f.proposer, "remove"); code != http.StatusForbidden {
		t.Fatalf("moderator removing owner code=%d", code)
	}
	if code := h.manage(f.proposerFriend, id, f.stranger, "make_moderator"); code != http.StatusForbidden {
		t.Fatalf("moderator promoting code=%d", code)
	}
	if code := h.manage(f.proposerFriend, id, f.stranger, "remove"); code != 200 {
		t.Fatalf("moderator removing member code=%d", code)
	}
	if code, _ := h.post(h.s.joinCommunityGroupHandler, f.stranger, id, `{}`); code != http.StatusForbidden {
		t.Fatalf("removed member rejoin code=%d", code)
	}
	if code := h.manage(f.proposer, id, f.proposerFriend, "make_member"); code != 200 {
		t.Fatalf("demote code=%d", code)
	}
	if code := h.manage(f.proposer, id, f.proposer, "remove"); code != http.StatusBadRequest {
		t.Fatalf("self manage code=%d", code)
	}

	patch := func(user, body string) (int, map[string]any) {
		return h.call(h.s.communityGroupHandler, http.MethodPatch, user, "", body, map[string]string{"groupID": id})
	}
	if code, _ := patch(f.proposerFriend, `{"name":"Taken over"}`); code != http.StatusForbidden {
		t.Fatalf("member edit code=%d", code)
	}
	if code, _ := patch(f.proposer, `{"kind":"private"}`); code != http.StatusBadRequest {
		t.Fatalf("kind switch code=%d", code)
	}
	if code, _ := patch(f.proposer, `{"category_slug":""}`); code != http.StatusBadRequest {
		t.Fatalf("community without category code=%d", code)
	}
	code, out := patch(f.proposer, `{"name":"Dosa & chutney trail","category_slug":"culture-heritage","cover_emoji":"🫓"}`)
	edited, _ := out["group"].(map[string]any)
	if code != 200 || edited["name"] != "Dosa & chutney trail" || edited["category_slug"] != "culture-heritage" || edited["cover_emoji"] != "🫓" {
		t.Fatalf("edit code=%d %v", code, out)
	}

	del := func(user string) int {
		code, _ := h.call(h.s.communityGroupHandler, http.MethodDelete, user, "", "", map[string]string{"groupID": id})
		return code
	}
	if code := del(f.invitee); code != http.StatusForbidden {
		t.Fatalf("member delete code=%d", code)
	}
	if code := del(f.groupMate); code != http.StatusNotFound {
		t.Fatalf("outsider delete code=%d", code)
	}
	if code := del(f.proposer); code != 200 {
		t.Fatalf("owner delete code=%d", code)
	}
	if code, _ := h.detail(f.invitee, id); code != http.StatusNotFound {
		t.Fatalf("deleted group detail code=%d", code)
	}
}

func TestGroupsChatFollowsMembershipPostgres(t *testing.T) {
	h := newGroupsHarness(t)
	f := h.f
	ctx := context.Background()
	g := h.mustCreate(f.proposer, map[string]any{"kind": "private", "name": "Board game night", "invitee_user_ids": []string{f.proposerFriend}})
	id, channel := toString(g["id"]), toString(g["channel_id"])
	if code, _ := h.post(h.s.respondCommunityGroupInvite, f.proposerFriend, id, `{"decision":"accept"}`); code != 200 {
		t.Fatalf("accept code=%d", code)
	}
	ch, _, err := loadChannel(ctx, f.db, f.proposer, channel)
	if err != nil || ch.Kind != "group" || ch.Title != "Board game night" || !ch.CanModerate || ch.MemberCount != 2 {
		t.Fatalf("owner channel %+v err=%v", ch, err)
	}
	if ch, _, err = loadChannel(ctx, f.db, f.proposerFriend, channel); err != nil || ch.CanModerate {
		t.Fatalf("member channel %+v err=%v", ch, err)
	}
	if _, _, err = loadChannel(ctx, f.db, f.stranger, channel); !errors.Is(err, errDatePlanNotFound) {
		t.Fatalf("non-member read the group chat: %v", err)
	}
	if _, err = sendSocialMessage(ctx, f.db, f.stranger, channel, uuid.NewString(), "let me in"); err == nil {
		t.Fatal("non-member posted")
	}
	m, err := sendSocialMessage(ctx, f.db, f.proposerFriend, channel, uuid.NewString(), "Catan on Friday?")
	if err != nil {
		t.Fatal(err)
	}
	if got := f.notifications(t, f.proposer, "social.message.new"); got != 1 {
		t.Fatalf("group message notifications=%d", got)
	}
	_, mine := h.call(h.s.listCommunityGroups, http.MethodGet, f.proposer, "scope=mine", "", nil)
	for _, item := range mine["groups"].([]any) {
		if gm := item.(map[string]any); gm["id"] == id && int(gm["unread_count"].(float64)) != 1 {
			t.Fatalf("unread count %v", gm["unread_count"])
		}
	}
	// The owner moderates the chat.
	if err = deleteSocialMessage(ctx, f.db, f.proposer, channel, m.ID); err != nil {
		t.Fatal(err)
	}
	// Leaving revokes the chat at once.
	if code, _ := h.post(h.s.leaveCommunityGroupHandler, f.proposerFriend, id, `{}`); code != 200 {
		t.Fatalf("leave code=%d", code)
	}
	if _, _, err = loadChannel(ctx, f.db, f.proposerFriend, channel); !errors.Is(err, errDatePlanNotFound) {
		t.Fatalf("former member still reads the chat: %v", err)
	}
}

func TestGroupCategoriesListedPostgres(t *testing.T) {
	h := newGroupsHarness(t)
	code, out := h.call(h.s.listGroupCategoriesHandler, http.MethodGet, h.f.stranger, "", "", nil)
	if code != 200 {
		t.Fatalf("categories code=%d", code)
	}
	slugs := []string{}
	for _, c := range out["categories"].([]any) {
		cat := c.(map[string]any)
		if toString(cat["emoji"]) == "" || toString(cat["title"]) == "" {
			t.Fatalf("incomplete category %v", cat)
		}
		slugs = append(slugs, toString(cat["slug"]))
	}
	for _, want := range []string{"fitness-running", "foodies", "faith-spirituality", "lgbtq-community", "parents-family", "books", "social"} {
		if !containsString(slugs, want) {
			t.Fatalf("missing category %s in %v", want, slugs)
		}
	}
	if len(slugs) < 20 {
		t.Fatalf("only %d categories", len(slugs))
	}
}

func TestGroupsRoutesRequireSessionAndFlag(t *testing.T) {
	for _, path := range []string{"/v1/engagement/groups", "/v1/engagement/groups/abc/join", "/v1/engagement/group-invites", "/v1/engagement/group-categories", "/v1/engagement/group-friends"} {
		if got := featureFlagForRoute("/v1", path); got != "groups_enabled" {
			t.Fatalf("%s maps to %q", path, got)
		}
	}
	if got := featureFlagForRoute("/v1", "/v1/engagement/group-coffee-polls"); got != "group_coffee_polls_enabled" {
		t.Fatalf("coffee polls map to %q", got)
	}
	server := newQuestWorkflowTestServer(t)
	defer server.Close()
	req := httptest.NewRequest(http.MethodPost, "/v1/engagement/groups", strings.NewReader(`{"kind":"private","name":"Anon"}`))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, req)
	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("anonymous create code=%d body=%s", rec.Code, rec.Body.String())
	}
}

func TestGroupsMissingGroupMapsNotFoundPostgres(t *testing.T) {
	h := newGroupsHarness(t)
	missing := uuid.NewString()
	for name, call := range map[string]func() int{
		"detail": func() int { c, _ := h.detail(h.f.proposer, missing); return c },
		"invite": func() int {
			c, _ := h.post(h.s.inviteCommunityGroupMembers, h.f.proposer, missing, `{"invitee_user_ids":["`+h.f.proposerFriend+`"]}`)
			return c
		},
		"respond": func() int {
			c, _ := h.post(h.s.respondCommunityGroupInvite, h.f.proposer, missing, `{"decision":"accept"}`)
			return c
		},
		"join": func() int { c, _ := h.post(h.s.joinCommunityGroupHandler, h.f.proposer, missing, `{}`); return c },
		"bad id": func() int {
			c, _ := h.post(h.s.joinCommunityGroupHandler, h.f.proposer, "group-missing", `{}`)
			return c
		},
	} {
		if code := call(); code != http.StatusNotFound {
			t.Fatalf("%s on a missing group code=%d", name, code)
		}
	}
}

func TestGroupsAccountErasureHandsOverAndDeletesPostgres(t *testing.T) {
	h := newGroupsHarness(t)
	f := h.f
	ctx := context.Background()
	shared := h.mustCreate(f.proposer, map[string]any{"kind": "community", "category_slug": "pets", "name": "Dog park mornings"})
	sharedID := toString(shared["id"])
	for _, u := range []string{f.stranger, f.groupMate} {
		if code, _ := h.post(h.s.joinCommunityGroupHandler, u, sharedID, `{}`); code != 200 {
			t.Fatalf("join code=%d", code)
		}
	}
	if code := h.manage(f.proposer, sharedID, f.groupMate, "make_moderator"); code != 200 {
		t.Fatalf("promote code=%d", code)
	}
	alone := h.mustCreate(f.proposer, map[string]any{"kind": "private", "name": "Just me", "invitee_user_ids": []string{f.proposerFriend}})
	aloneID := toString(alone["id"])

	tx, err := f.db.BeginTx(ctx, nil)
	if err != nil {
		t.Fatal(err)
	}
	for _, step := range accountErasureSteps() {
		if !strings.HasPrefix(step.label, "group") {
			continue
		}
		if _, err = tx.ExecContext(ctx, step.query, f.proposer); err != nil {
			_ = tx.Rollback()
			t.Fatal(step.label, err)
		}
	}
	if err = tx.Commit(); err != nil {
		t.Fatal(err)
	}
	var role string
	if err = f.db.QueryRow(`SELECT m.role FROM matching.community_group_members m JOIN matching.community_groups g ON g.id=m.group_id AND m.user_id=g.created_by_user_id WHERE g.id=$1`, sharedID).Scan(&role); err != nil {
		t.Fatal(err)
	}
	if h.owner(sharedID) != f.groupMate || role != "owner" {
		t.Fatalf("group not handed to the moderator: owner=%s role=%s", h.owner(sharedID), role)
	}
	var left int
	if err = f.db.QueryRow(`SELECT (SELECT COUNT(*) FROM matching.community_groups WHERE id=$1)
 +(SELECT COUNT(*) FROM matching.community_group_invites WHERE inviter_user_id=$2 OR invitee_user_id=$2)
 +(SELECT COUNT(*) FROM matching.community_group_members WHERE user_id=$2)`, aloneID, f.proposer).Scan(&left); err != nil {
		t.Fatal(err)
	}
	if left != 0 {
		t.Fatalf("erasure left %d group rows", left)
	}
}

// Reporting a whole group (case kind "group", migration 120).
func TestGroupsReportRemoveRestorePostgres(t *testing.T) {
	h := newGroupsHarness(t)
	f := h.f
	ctx := context.Background()
	var ready bool
	if err := f.db.QueryRow(`SELECT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema='matching' AND table_name='community_groups' AND column_name='moderation_state')`).Scan(&ready); err != nil {
		t.Fatal(err)
	}
	if !ready {
		t.Skip("migration 120_group_reports_friend_search_optout is not applied")
	}
	community := h.mustCreate(f.proposer, map[string]any{"kind": "community", "category_slug": "books", "name": "Late night readers",
		"description": "Spammy description", "cover_emoji": "📚", "invitee_user_ids": []string{f.proposerFriend}})
	cid := toString(community["id"])
	channel := toString(community["channel_id"])
	if community["moderation_state"] != "active" || community["removed"] != false {
		t.Fatalf("new group state %v", community)
	}
	private := h.mustCreate(f.proposer, map[string]any{"kind": "private", "name": "Inner circle"})
	pid := toString(private["id"])
	if code, _ := h.post(h.s.joinCommunityGroupHandler, f.groupMate, cid, `{}`); code != 200 {
		t.Fatalf("join code=%d", code)
	}

	// Who can report: anyone who can see the group, never the owner, never
	// someone who cannot see it.
	if _, err := createBlogCase(ctx, f.db, f.proposer, "group", cid, "fraud", ""); err == nil {
		t.Fatal("owner reported their own group")
	}
	if _, err := createBlogCase(ctx, f.db, f.stranger, "group", pid, "fraud", ""); !errors.Is(err, errDatePlanNotFound) {
		t.Fatalf("non-member reported a private group: %v", err)
	}
	if _, err := createBlogCase(ctx, f.db, f.blockedFriend, "group", cid, "fraud", ""); !errors.Is(err, errDatePlanNotFound) {
		t.Fatalf("member who blocked the owner reported an invisible group: %v", err)
	}
	// A non-member reports over HTTP.
	rec := httptest.NewRecorder()
	h.s.blogReportHandler(rec, groupRequest(http.MethodPost, f.stranger, "", `{"reason":"inappropriate","description":"Selling things"}`,
		map[string]string{"kind": "group", "contentID": cid}))
	if rec.Code != 200 {
		t.Fatalf("report code=%d %s", rec.Code, rec.Body.String())
	}
	var out map[string]any
	_ = json.Unmarshal(rec.Body.Bytes(), &out)
	caseID := toString(out["report"].(map[string]any)["id"])
	var subject, snapshot string
	if err := f.db.QueryRow(`SELECT subject_id::text,snapshot::text FROM matching.blog_cases WHERE id=$1 AND content_type='group'`, caseID).Scan(&subject, &snapshot); err != nil {
		t.Fatal(err)
	}
	if subject != f.proposer || !strings.Contains(snapshot, "Late night readers") || !strings.Contains(snapshot, "Spammy description") ||
		!strings.Contains(snapshot, `"category_slug": "books"`) || !strings.Contains(snapshot, f.proposer) {
		t.Fatalf("case subject=%s snapshot=%s", subject, snapshot)
	}
	// A member of a private group can report it too.
	if _, err := f.db.Exec(`INSERT INTO matching.community_group_members(group_id,user_id,status,role) VALUES($1,$2,'active','member')`, pid, f.groupMate); err != nil {
		t.Fatal(err)
	}
	if _, err := createBlogCase(ctx, f.db, f.groupMate, "group", pid, "harassment", ""); err != nil {
		t.Fatalf("private member report: %v", err)
	}

	// Removal: hidden from Discover, no joining, invitations or chat.
	if err := decideBlogCase(ctx, f.db, f.stranger, caseID, "removed", "Group exists to sell things", 1); err != nil {
		t.Fatal(err)
	}
	if got := f.notifications(t, f.proposer, "blog.review.completed"); got != 1 {
		t.Fatalf("owner review notices=%d", got)
	}
	_, list := h.call(h.s.listCommunityGroups, http.MethodGet, f.inviteeFriend, "scope=discover&category=books", "", nil)
	if containsString(groupIDs(list["groups"]), cid) {
		t.Fatal("removed group still in discover")
	}
	if code, _ := h.detail(f.inviteeFriend, cid); code != http.StatusNotFound {
		t.Fatalf("non-member saw a removed group code=%d", code)
	}
	if code, _ := h.post(h.s.joinCommunityGroupHandler, f.inviteeFriend, cid, `{}`); code != http.StatusNotFound {
		t.Fatalf("join removed group code=%d", code)
	}
	code, g := h.detail(f.groupMate, cid)
	if code != 200 || g["removed"] != true || g["moderation_state"] != "removed" || toString(g["channel_id"]) != "" || g["can_invite"] != false {
		t.Fatalf("member view of removed group code=%d %v", code, g)
	}
	_, mine := h.call(h.s.listCommunityGroups, http.MethodGet, f.groupMate, "scope=mine", "", nil)
	if !containsString(groupIDs(mine["groups"]), cid) {
		t.Fatal("members should still find the removed group in their groups")
	}
	if _, _, err := loadChannel(ctx, f.db, f.groupMate, channel); !errors.Is(err, errDatePlanNotFound) {
		t.Fatalf("chat of a removed group stayed open: %v", err)
	}
	if _, err := sendSocialMessage(ctx, f.db, f.proposer, channel, uuid.NewString(), "still here?"); err == nil {
		t.Fatal("owner posted in a removed group")
	}
	_, invites := h.call(h.s.listCommunityGroupInvites, http.MethodGet, f.proposerFriend, "", "", nil)
	if containsString(groupIDs(invitesGroups(invites["invites"])), cid) {
		t.Fatal("invitation to a removed group still listed")
	}
	if code, _ := h.post(h.s.respondCommunityGroupInvite, f.proposerFriend, cid, `{"decision":"accept"}`); code != http.StatusForbidden {
		t.Fatalf("accept into removed group code=%d", code)
	}
	if code, _ := h.post(h.s.inviteCommunityGroupMembers, f.proposer, cid, `{"invitee_user_ids":["`+f.proposerFriend+`"]}`); code != http.StatusForbidden {
		t.Fatalf("invite into removed group code=%d", code)
	}
	if code, _ := h.call(h.s.communityGroupHandler, http.MethodPatch, f.proposer, "", `{"name":"Renamed readers"}`, map[string]string{"groupID": cid}); code != http.StatusForbidden {
		t.Fatalf("edit removed group code=%d", code)
	}

	// The owner appeals; restore brings everything back.
	var version int
	if err := f.db.QueryRow(`SELECT version FROM matching.blog_cases WHERE id=$1`, caseID).Scan(&version); err != nil {
		t.Fatal(err)
	}
	if err := decideBlogCase(ctx, f.db, f.stranger, caseID, "restored", "Appeal accepted after review", version); err != nil {
		t.Fatal(err)
	}
	_, list = h.call(h.s.listCommunityGroups, http.MethodGet, f.inviteeFriend, "scope=discover&category=books", "", nil)
	if !containsString(groupIDs(list["groups"]), cid) {
		t.Fatal("restored group missing from discover")
	}
	if _, _, err := loadChannel(ctx, f.db, f.groupMate, channel); err != nil {
		t.Fatalf("restored group chat: %v", err)
	}
	if code, _ := h.post(h.s.respondCommunityGroupInvite, f.proposerFriend, cid, `{"decision":"accept"}`); code != 200 {
		t.Fatalf("accept after restore code=%d", code)
	}
	var state string
	var groupVersion int
	if err := f.db.QueryRow(`SELECT moderation_state,version FROM matching.community_groups WHERE id=$1`, cid).Scan(&state, &groupVersion); err != nil {
		t.Fatal(err)
	}
	if state != "active" || groupVersion != 3 {
		t.Fatalf("group state=%s version=%d", state, groupVersion)
	}
}

func invitesGroups(list any) []any {
	out := []any{}
	items, _ := list.([]any)
	for _, item := range items {
		out = append(out, item.(map[string]any)["group"])
	}
	return out
}
