package infrastructure

import (
	"context"
	"encoding/json"

	engagementapp "github.com/verified-dating/backend/internal/modules/engagement/application"
)

type StoreGateway struct {
	getCircleChallenge    func(string, string) (any, error)
	joinCircle            func(string, string) (any, error)
	submitCircleChallenge func(string, string, string, string, string) (any, any, error)
	getDailyPrompt        func(string) (any, error)
	submitDailyPrompt     func(string, string, string) (any, bool, error)
	listDailyResponders   func(string, int, int) (any, error)
	sendMatchNudge        func(string, string, string, string) (any, error)
	clickMatchNudge       func(string, string) (any, error)
	resumeConversation    func(string, string, string) (any, error)

	listVoicePrompts     func() any
	startVoiceIcebreaker func(string, string, string, string) (any, error)
	sendVoiceIcebreaker  func(string, string, string, int) (any, error)
	playVoiceIcebreaker  func(string, string) (any, error)

	createGroupCoffeePoll   func(string, []string, []engagementapp.GroupCoffeeOptionInput, string) (any, error)
	listGroupCoffeePolls    func(string, string, int) any
	getGroupCoffeePoll      func(string) (any, bool)
	voteGroupCoffeePoll     func(string, string, string) (any, error)
	finalizeGroupCoffeePoll func(string, string) (any, any, error)

	createCommunityGroup      func(string, string, string, string, string, string, []string) (any, any, error)
	listCommunityGroups       func(string, string, string, bool, int) any
	inviteCommunityGroupUsers func(string, string, []string) (any, error)
	respondCommunityInvite    func(string, string, string) (any, any, error)
	listCommunityInvites      func(string, string, int) any
}

func NewStoreGateway(
	getCircleChallenge func(string, string) (any, error),
	joinCircle func(string, string) (any, error),
	submitCircleChallenge func(string, string, string, string, string) (any, any, error),
	getDailyPrompt func(string) (any, error),
	submitDailyPrompt func(string, string, string) (any, bool, error),
	listDailyResponders func(string, int, int) (any, error),
	sendMatchNudge func(string, string, string, string) (any, error),
	clickMatchNudge func(string, string) (any, error),
	resumeConversation func(string, string, string) (any, error),
	listVoicePrompts func() any,
	startVoiceIcebreaker func(string, string, string, string) (any, error),
	sendVoiceIcebreaker func(string, string, string, int) (any, error),
	playVoiceIcebreaker func(string, string) (any, error),
	createGroupCoffeePoll func(string, []string, []engagementapp.GroupCoffeeOptionInput, string) (any, error),
	listGroupCoffeePolls func(string, string, int) any,
	getGroupCoffeePoll func(string) (any, bool),
	voteGroupCoffeePoll func(string, string, string) (any, error),
	finalizeGroupCoffeePoll func(string, string) (any, any, error),
	createCommunityGroup func(string, string, string, string, string, string, []string) (any, any, error),
	listCommunityGroups func(string, string, string, bool, int) any,
	inviteCommunityGroupUsers func(string, string, []string) (any, error),
	respondCommunityInvite func(string, string, string) (any, any, error),
	listCommunityInvites func(string, string, int) any,
) *StoreGateway {
	return &StoreGateway{
		getCircleChallenge:        getCircleChallenge,
		joinCircle:                joinCircle,
		submitCircleChallenge:     submitCircleChallenge,
		getDailyPrompt:            getDailyPrompt,
		submitDailyPrompt:         submitDailyPrompt,
		listDailyResponders:       listDailyResponders,
		sendMatchNudge:            sendMatchNudge,
		clickMatchNudge:           clickMatchNudge,
		resumeConversation:        resumeConversation,
		listVoicePrompts:          listVoicePrompts,
		startVoiceIcebreaker:      startVoiceIcebreaker,
		sendVoiceIcebreaker:       sendVoiceIcebreaker,
		playVoiceIcebreaker:       playVoiceIcebreaker,
		createGroupCoffeePoll:     createGroupCoffeePoll,
		listGroupCoffeePolls:      listGroupCoffeePolls,
		getGroupCoffeePoll:        getGroupCoffeePoll,
		voteGroupCoffeePoll:       voteGroupCoffeePoll,
		finalizeGroupCoffeePoll:   finalizeGroupCoffeePoll,
		createCommunityGroup:      createCommunityGroup,
		listCommunityGroups:       listCommunityGroups,
		inviteCommunityGroupUsers: inviteCommunityGroupUsers,
		respondCommunityInvite:    respondCommunityInvite,
		listCommunityInvites:      listCommunityInvites,
	}
}

func (g *StoreGateway) GetCircleChallenge(_ context.Context, circleID, userID string) (map[string]any, error) {
	result, err := g.getCircleChallenge(circleID, userID)
	if err != nil {
		return nil, err
	}
	return toMap(result)
}

func (g *StoreGateway) JoinCircle(_ context.Context, circleID, userID string) (map[string]any, error) {
	result, err := g.joinCircle(circleID, userID)
	if err != nil {
		return nil, err
	}
	return toMap(result)
}

func (g *StoreGateway) SubmitCircleChallenge(
	_ context.Context,
	circleID, challengeID, userID, entryText, imageURL string,
) (map[string]any, map[string]any, error) {
	view, entry, err := g.submitCircleChallenge(circleID, challengeID, userID, entryText, imageURL)
	if err != nil {
		return nil, nil, err
	}
	viewMap, err := toMap(view)
	if err != nil {
		return nil, nil, err
	}
	entryMap, err := toMap(entry)
	if err != nil {
		return nil, nil, err
	}
	return viewMap, entryMap, nil
}

func (g *StoreGateway) GetDailyPrompt(_ context.Context, userID string) (map[string]any, error) {
	result, err := g.getDailyPrompt(userID)
	if err != nil {
		return nil, err
	}
	return toMap(result)
}

func (g *StoreGateway) SubmitDailyPromptAnswer(_ context.Context, userID, promptID, answerText string) (map[string]any, bool, error) {
	result, isEdit, err := g.submitDailyPrompt(userID, promptID, answerText)
	if err != nil {
		return nil, false, err
	}
	mapped, err := toMap(result)
	if err != nil {
		return nil, false, err
	}
	return mapped, isEdit, nil
}

func (g *StoreGateway) ListDailyPromptResponders(_ context.Context, userID string, limit, offset int) (map[string]any, error) {
	result, err := g.listDailyResponders(userID, limit, offset)
	if err != nil {
		return nil, err
	}
	return toMap(result)
}

func (g *StoreGateway) SendMatchNudge(_ context.Context, matchID, userID, counterpartyUserID, nudgeType string) (map[string]any, error) {
	result, err := g.sendMatchNudge(matchID, userID, counterpartyUserID, nudgeType)
	if err != nil {
		return nil, err
	}
	return toMap(result)
}

func (g *StoreGateway) ClickMatchNudge(_ context.Context, nudgeID, userID string) (map[string]any, error) {
	result, err := g.clickMatchNudge(nudgeID, userID)
	if err != nil {
		return nil, err
	}
	return toMap(result)
}

func (g *StoreGateway) MarkConversationResumed(_ context.Context, matchID, userID, triggerNudgeID string) (map[string]any, error) {
	result, err := g.resumeConversation(matchID, userID, triggerNudgeID)
	if err != nil {
		return nil, err
	}
	return toMap(result)
}

func (g *StoreGateway) ListVoicePrompts(_ context.Context) ([]map[string]any, error) {
	return toMapSlice(g.listVoicePrompts())
}

func (g *StoreGateway) StartVoiceIcebreaker(
	_ context.Context,
	matchID, senderUserID, receiverUserID, promptID string,
) (map[string]any, error) {
	result, err := g.startVoiceIcebreaker(matchID, senderUserID, receiverUserID, promptID)
	if err != nil {
		return nil, err
	}
	return toMap(result)
}

func (g *StoreGateway) SendVoiceIcebreaker(
	_ context.Context,
	icebreakerID, senderUserID, transcript string,
	durationSeconds int,
) (map[string]any, error) {
	result, err := g.sendVoiceIcebreaker(icebreakerID, senderUserID, transcript, durationSeconds)
	if err != nil {
		return nil, err
	}
	return toMap(result)
}

func (g *StoreGateway) PlayVoiceIcebreaker(_ context.Context, icebreakerID, userID string) (map[string]any, error) {
	result, err := g.playVoiceIcebreaker(icebreakerID, userID)
	if err != nil {
		return nil, err
	}
	return toMap(result)
}

func (g *StoreGateway) CreateGroupCoffeePoll(
	_ context.Context,
	creatorUserID string,
	participantUserIDs []string,
	options []engagementapp.GroupCoffeeOptionInput,
	deadlineAt string,
) (map[string]any, error) {
	result, err := g.createGroupCoffeePoll(creatorUserID, participantUserIDs, options, deadlineAt)
	if err != nil {
		return nil, err
	}
	return toMap(result)
}

func (g *StoreGateway) ListGroupCoffeePolls(_ context.Context, userID, status string, limit int) ([]map[string]any, error) {
	return toMapSlice(g.listGroupCoffeePolls(userID, status, limit))
}

func (g *StoreGateway) GetGroupCoffeePoll(_ context.Context, pollID string) (map[string]any, bool, error) {
	poll, found := g.getGroupCoffeePoll(pollID)
	if !found {
		return nil, false, nil
	}
	mapped, err := toMap(poll)
	if err != nil {
		return nil, false, err
	}
	return mapped, true, nil
}

func (g *StoreGateway) VoteGroupCoffeePoll(_ context.Context, pollID, userID, optionID string) (map[string]any, error) {
	result, err := g.voteGroupCoffeePoll(pollID, userID, optionID)
	if err != nil {
		return nil, err
	}
	return toMap(result)
}

func (g *StoreGateway) FinalizeGroupCoffeePoll(_ context.Context, pollID, userID string) (map[string]any, map[string]any, error) {
	poll, selectedOption, err := g.finalizeGroupCoffeePoll(pollID, userID)
	if err != nil {
		return nil, nil, err
	}
	pollMap, err := toMap(poll)
	if err != nil {
		return nil, nil, err
	}
	selectedMap, err := toMap(selectedOption)
	if err != nil {
		return nil, nil, err
	}
	return pollMap, selectedMap, nil
}

func (g *StoreGateway) CreateCommunityGroup(
	_ context.Context,
	ownerUserID, name, city, topic, description, visibility string,
	inviteeUserIDs []string,
) (map[string]any, []map[string]any, error) {
	group, invites, err := g.createCommunityGroup(ownerUserID, name, city, topic, description, visibility, inviteeUserIDs)
	if err != nil {
		return nil, nil, err
	}
	groupMap, err := toMap(group)
	if err != nil {
		return nil, nil, err
	}
	inviteMaps, err := toMapSlice(invites)
	if err != nil {
		return nil, nil, err
	}
	return groupMap, inviteMaps, nil
}

func (g *StoreGateway) ListCommunityGroups(_ context.Context, userID, city, topic string, onlyJoined bool, limit int) ([]map[string]any, error) {
	return toMapSlice(g.listCommunityGroups(userID, city, topic, onlyJoined, limit))
}

func (g *StoreGateway) InviteCommunityGroupMembers(_ context.Context, groupID, inviterUserID string, inviteeUserIDs []string) ([]map[string]any, error) {
	invites, err := g.inviteCommunityGroupUsers(groupID, inviterUserID, inviteeUserIDs)
	if err != nil {
		return nil, err
	}
	return toMapSlice(invites)
}

func (g *StoreGateway) RespondCommunityGroupInvite(_ context.Context, groupID, userID, decision string) (map[string]any, map[string]any, error) {
	group, invite, err := g.respondCommunityInvite(groupID, userID, decision)
	if err != nil {
		return nil, nil, err
	}
	groupMap, err := toMap(group)
	if err != nil {
		return nil, nil, err
	}
	inviteMap, err := toMap(invite)
	if err != nil {
		return nil, nil, err
	}
	return groupMap, inviteMap, nil
}

func (g *StoreGateway) ListCommunityGroupInvites(_ context.Context, userID, status string, limit int) ([]map[string]any, error) {
	return toMapSlice(g.listCommunityInvites(userID, status, limit))
}

func toMap(value any) (map[string]any, error) {
	data, err := json.Marshal(value)
	if err != nil {
		return nil, err
	}
	var out map[string]any
	if err := json.Unmarshal(data, &out); err != nil {
		return nil, err
	}
	if out == nil {
		out = map[string]any{}
	}
	return out, nil
}

func toMapSlice(value any) ([]map[string]any, error) {
	data, err := json.Marshal(value)
	if err != nil {
		return nil, err
	}
	var out []map[string]any
	if err := json.Unmarshal(data, &out); err != nil {
		return nil, err
	}
	if out == nil {
		out = []map[string]any{}
	}
	return out, nil
}
