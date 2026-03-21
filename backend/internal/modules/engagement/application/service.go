package application

import (
	"context"
	"fmt"
	"strings"

	"go.uber.org/zap"

	"github.com/verified-dating/backend/internal/platform/mediatr"
)

type Gateway interface {
	GetCircleChallenge(context.Context, string, string) (map[string]any, error)
	JoinCircle(context.Context, string, string) (map[string]any, error)
	SubmitCircleChallenge(context.Context, string, string, string, string, string) (map[string]any, map[string]any, error)

	GetDailyPrompt(context.Context, string) (map[string]any, error)
	SubmitDailyPromptAnswer(context.Context, string, string, string) (map[string]any, bool, error)
	ListDailyPromptResponders(context.Context, string, int, int) (map[string]any, error)

	SendMatchNudge(context.Context, string, string, string, string) (map[string]any, error)
	ClickMatchNudge(context.Context, string, string) (map[string]any, error)
	MarkConversationResumed(context.Context, string, string, string) (map[string]any, error)

	ListVoicePrompts(context.Context) ([]map[string]any, error)
	StartVoiceIcebreaker(context.Context, string, string, string, string) (map[string]any, error)
	SendVoiceIcebreaker(context.Context, string, string, string, int) (map[string]any, error)
	PlayVoiceIcebreaker(context.Context, string, string) (map[string]any, error)

	CreateGroupCoffeePoll(context.Context, string, []string, []GroupCoffeeOptionInput, string) (map[string]any, error)
	ListGroupCoffeePolls(context.Context, string, string, int) ([]map[string]any, error)
	GetGroupCoffeePoll(context.Context, string) (map[string]any, bool, error)
	VoteGroupCoffeePoll(context.Context, string, string, string) (map[string]any, error)
	FinalizeGroupCoffeePoll(context.Context, string, string) (map[string]any, map[string]any, error)

	CreateCommunityGroup(context.Context, string, string, string, string, string, string, []string) (map[string]any, []map[string]any, error)
	ListCommunityGroups(context.Context, string, string, string, bool, int) ([]map[string]any, error)
	InviteCommunityGroupMembers(context.Context, string, string, []string) ([]map[string]any, error)
	RespondCommunityGroupInvite(context.Context, string, string, string) (map[string]any, map[string]any, error)
	ListCommunityGroupInvites(context.Context, string, string, int) ([]map[string]any, error)
}

type Service struct {
	gateway Gateway
	log     *zap.Logger
}

func NewService(gateway Gateway, log *zap.Logger) *Service {
	return &Service{gateway: gateway, log: log}
}

func RegisterHandlers(bus *mediatr.Mediator, service *Service) {
	bus.Register(GetCircleChallengeCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(GetCircleChallengeCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid get circle challenge command", ErrValidation)
		}
		return service.HandleGetCircleChallenge(ctx, command)
	})
	bus.Register(JoinCircleCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(JoinCircleCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid join circle command", ErrValidation)
		}
		return service.HandleJoinCircle(ctx, command)
	})
	bus.Register(SubmitCircleChallengeCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(SubmitCircleChallengeCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid submit circle challenge command", ErrValidation)
		}
		return service.HandleSubmitCircleChallenge(ctx, command)
	})
	bus.Register(GetDailyPromptCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(GetDailyPromptCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid get daily prompt command", ErrValidation)
		}
		return service.HandleGetDailyPrompt(ctx, command)
	})
	bus.Register(SubmitDailyPromptAnswerCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(SubmitDailyPromptAnswerCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid submit daily prompt answer command", ErrValidation)
		}
		return service.HandleSubmitDailyPromptAnswer(ctx, command)
	})
	bus.Register(ListDailyPromptRespondersCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(ListDailyPromptRespondersCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid list daily prompt responders command", ErrValidation)
		}
		return service.HandleListDailyPromptResponders(ctx, command)
	})
	bus.Register(SendMatchNudgeCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(SendMatchNudgeCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid send match nudge command", ErrValidation)
		}
		return service.HandleSendMatchNudge(ctx, command)
	})
	bus.Register(ClickMatchNudgeCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(ClickMatchNudgeCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid click match nudge command", ErrValidation)
		}
		return service.HandleClickMatchNudge(ctx, command)
	})
	bus.Register(MarkConversationResumedCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(MarkConversationResumedCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid mark conversation resumed command", ErrValidation)
		}
		return service.HandleMarkConversationResumed(ctx, command)
	})
	bus.Register(ListVoicePromptsCommandName, func(ctx context.Context, request any) (any, error) {
		_, ok := request.(ListVoicePromptsCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid list voice prompts command", ErrValidation)
		}
		return service.HandleListVoicePrompts(ctx)
	})
	bus.Register(StartVoiceIcebreakerCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(StartVoiceIcebreakerCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid start voice icebreaker command", ErrValidation)
		}
		return service.HandleStartVoiceIcebreaker(ctx, command)
	})
	bus.Register(SendVoiceIcebreakerCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(SendVoiceIcebreakerCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid send voice icebreaker command", ErrValidation)
		}
		return service.HandleSendVoiceIcebreaker(ctx, command)
	})
	bus.Register(PlayVoiceIcebreakerCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(PlayVoiceIcebreakerCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid play voice icebreaker command", ErrValidation)
		}
		return service.HandlePlayVoiceIcebreaker(ctx, command)
	})
	bus.Register(CreateGroupCoffeePollCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(CreateGroupCoffeePollCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid create group coffee poll command", ErrValidation)
		}
		return service.HandleCreateGroupCoffeePoll(ctx, command)
	})
	bus.Register(ListGroupCoffeePollsCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(ListGroupCoffeePollsCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid list group coffee polls command", ErrValidation)
		}
		return service.HandleListGroupCoffeePolls(ctx, command)
	})
	bus.Register(GetGroupCoffeePollCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(GetGroupCoffeePollCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid get group coffee poll command", ErrValidation)
		}
		return service.HandleGetGroupCoffeePoll(ctx, command)
	})
	bus.Register(VoteGroupCoffeePollCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(VoteGroupCoffeePollCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid vote group coffee poll command", ErrValidation)
		}
		return service.HandleVoteGroupCoffeePoll(ctx, command)
	})
	bus.Register(FinalizeGroupCoffeePollCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(FinalizeGroupCoffeePollCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid finalize group coffee poll command", ErrValidation)
		}
		return service.HandleFinalizeGroupCoffeePoll(ctx, command)
	})
	bus.Register(CreateCommunityGroupCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(CreateCommunityGroupCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid create community group command", ErrValidation)
		}
		return service.HandleCreateCommunityGroup(ctx, command)
	})
	bus.Register(ListCommunityGroupsCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(ListCommunityGroupsCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid list community groups command", ErrValidation)
		}
		return service.HandleListCommunityGroups(ctx, command)
	})
	bus.Register(InviteCommunityGroupMembersCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(InviteCommunityGroupMembersCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid invite community group members command", ErrValidation)
		}
		return service.HandleInviteCommunityGroupMembers(ctx, command)
	})
	bus.Register(RespondCommunityGroupInviteCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(RespondCommunityGroupInviteCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid respond community group invite command", ErrValidation)
		}
		return service.HandleRespondCommunityGroupInvite(ctx, command)
	})
	bus.Register(ListCommunityGroupInvitesCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(ListCommunityGroupInvitesCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid list community group invites command", ErrValidation)
		}
		return service.HandleListCommunityGroupInvites(ctx, command)
	})
}

func (s *Service) HandleGetCircleChallenge(ctx context.Context, command GetCircleChallengeCommand) (map[string]any, error) {
	circleID := strings.TrimSpace(command.CircleID)
	if circleID == "" {
		return nil, fmt.Errorf("%w: circle id is required", ErrValidation)
	}
	view, err := s.gateway.GetCircleChallenge(ctx, circleID, strings.TrimSpace(command.UserID))
	if err != nil {
		return nil, fmt.Errorf("get circle challenge failed: %w", err)
	}
	return map[string]any{"circle_challenge": view}, nil
}

func (s *Service) HandleJoinCircle(ctx context.Context, command JoinCircleCommand) (map[string]any, error) {
	circleID := strings.TrimSpace(command.CircleID)
	userID := strings.TrimSpace(command.UserID)
	if circleID == "" || userID == "" {
		return nil, fmt.Errorf("%w: circle id and user id are required", ErrValidation)
	}
	membership, err := s.gateway.JoinCircle(ctx, circleID, userID)
	if err != nil {
		return nil, fmt.Errorf("join circle failed: %w", err)
	}
	return map[string]any{"membership": membership}, nil
}

func (s *Service) HandleSubmitCircleChallenge(ctx context.Context, command SubmitCircleChallengeCommand) (map[string]any, error) {
	circleID := strings.TrimSpace(command.CircleID)
	userID := strings.TrimSpace(command.UserID)
	if circleID == "" || userID == "" {
		return nil, fmt.Errorf("%w: circle id and user id are required", ErrValidation)
	}
	view, entry, err := s.gateway.SubmitCircleChallenge(
		ctx,
		circleID,
		strings.TrimSpace(command.ChallengeID),
		userID,
		strings.TrimSpace(command.EntryText),
		strings.TrimSpace(command.ImageURL),
	)
	if err != nil {
		return nil, fmt.Errorf("submit circle challenge failed: %w", err)
	}
	return map[string]any{"circle_challenge": view, "entry": entry}, nil
}

func (s *Service) HandleGetDailyPrompt(ctx context.Context, command GetDailyPromptCommand) (map[string]any, error) {
	userID := strings.TrimSpace(command.UserID)
	if userID == "" {
		return nil, fmt.Errorf("%w: user id is required", ErrValidation)
	}
	view, err := s.gateway.GetDailyPrompt(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("get daily prompt failed: %w", err)
	}
	return map[string]any{"daily_prompt": view}, nil
}

func (s *Service) HandleSubmitDailyPromptAnswer(ctx context.Context, command SubmitDailyPromptAnswerCommand) (map[string]any, error) {
	userID := strings.TrimSpace(command.UserID)
	if userID == "" {
		return nil, fmt.Errorf("%w: user id is required", ErrValidation)
	}
	view, isEdit, err := s.gateway.SubmitDailyPromptAnswer(ctx, userID, strings.TrimSpace(command.PromptID), strings.TrimSpace(command.AnswerText))
	if err != nil {
		return nil, fmt.Errorf("submit daily prompt answer failed: %w", err)
	}
	return map[string]any{"daily_prompt": view, "is_edit": isEdit}, nil
}

func (s *Service) HandleListDailyPromptResponders(ctx context.Context, command ListDailyPromptRespondersCommand) (map[string]any, error) {
	userID := strings.TrimSpace(command.UserID)
	if userID == "" {
		return nil, fmt.Errorf("%w: user id is required", ErrValidation)
	}
	page, err := s.gateway.ListDailyPromptResponders(ctx, userID, command.Limit, command.Offset)
	if err != nil {
		return nil, fmt.Errorf("list daily prompt responders failed: %w", err)
	}
	return page, nil
}

func (s *Service) HandleSendMatchNudge(ctx context.Context, command SendMatchNudgeCommand) (map[string]any, error) {
	if strings.TrimSpace(command.MatchID) == "" || strings.TrimSpace(command.UserID) == "" || strings.TrimSpace(command.CounterpartyUserID) == "" {
		return nil, fmt.Errorf("%w: match_id, user_id, and counterparty_user_id are required", ErrValidation)
	}
	nudge, err := s.gateway.SendMatchNudge(ctx, strings.TrimSpace(command.MatchID), strings.TrimSpace(command.UserID), strings.TrimSpace(command.CounterpartyUserID), strings.TrimSpace(command.NudgeType))
	if err != nil {
		return nil, fmt.Errorf("send match nudge failed: %w", err)
	}
	return map[string]any{"nudge": nudge}, nil
}

func (s *Service) HandleClickMatchNudge(ctx context.Context, command ClickMatchNudgeCommand) (map[string]any, error) {
	if strings.TrimSpace(command.NudgeID) == "" || strings.TrimSpace(command.UserID) == "" {
		return nil, fmt.Errorf("%w: nudge id and user_id are required", ErrValidation)
	}
	nudge, err := s.gateway.ClickMatchNudge(ctx, strings.TrimSpace(command.NudgeID), strings.TrimSpace(command.UserID))
	if err != nil {
		return nil, fmt.Errorf("click match nudge failed: %w", err)
	}
	return map[string]any{"nudge": nudge}, nil
}

func (s *Service) HandleMarkConversationResumed(ctx context.Context, command MarkConversationResumedCommand) (map[string]any, error) {
	if strings.TrimSpace(command.MatchID) == "" || strings.TrimSpace(command.UserID) == "" {
		return nil, fmt.Errorf("%w: match_id and user_id are required", ErrValidation)
	}
	item, err := s.gateway.MarkConversationResumed(ctx, strings.TrimSpace(command.MatchID), strings.TrimSpace(command.UserID), strings.TrimSpace(command.TriggerNudgeID))
	if err != nil {
		return nil, fmt.Errorf("mark conversation resumed failed: %w", err)
	}
	return map[string]any{"conversation": item}, nil
}

func (s *Service) HandleListVoicePrompts(ctx context.Context) (map[string]any, error) {
	prompts, err := s.gateway.ListVoicePrompts(ctx)
	if err != nil {
		return nil, fmt.Errorf("list voice prompts failed: %w", err)
	}
	return map[string]any{"prompts": prompts}, nil
}

func (s *Service) HandleStartVoiceIcebreaker(ctx context.Context, command StartVoiceIcebreakerCommand) (map[string]any, error) {
	if strings.TrimSpace(command.MatchID) == "" || strings.TrimSpace(command.SenderUserID) == "" || strings.TrimSpace(command.ReceiverUserID) == "" {
		return nil, fmt.Errorf("%w: match_id, sender_user_id, and receiver_user_id are required", ErrValidation)
	}
	item, err := s.gateway.StartVoiceIcebreaker(
		ctx,
		strings.TrimSpace(command.MatchID),
		strings.TrimSpace(command.SenderUserID),
		strings.TrimSpace(command.ReceiverUserID),
		strings.TrimSpace(command.PromptID),
	)
	if err != nil {
		return nil, fmt.Errorf("start voice icebreaker failed: %w", err)
	}
	return map[string]any{"voice_icebreaker": item}, nil
}

func (s *Service) HandleSendVoiceIcebreaker(ctx context.Context, command SendVoiceIcebreakerCommand) (map[string]any, error) {
	if strings.TrimSpace(command.IcebreakerID) == "" || strings.TrimSpace(command.SenderUserID) == "" {
		return nil, fmt.Errorf("%w: icebreaker_id and sender_user_id are required", ErrValidation)
	}
	if command.DurationSeconds <= 0 {
		return nil, fmt.Errorf("%w: duration_seconds must be greater than zero", ErrValidation)
	}
	item, err := s.gateway.SendVoiceIcebreaker(
		ctx,
		strings.TrimSpace(command.IcebreakerID),
		strings.TrimSpace(command.SenderUserID),
		strings.TrimSpace(command.Transcript),
		command.DurationSeconds,
	)
	if err != nil {
		return nil, fmt.Errorf("send voice icebreaker failed: %w", err)
	}
	return map[string]any{"voice_icebreaker": item}, nil
}

func (s *Service) HandlePlayVoiceIcebreaker(ctx context.Context, command PlayVoiceIcebreakerCommand) (map[string]any, error) {
	if strings.TrimSpace(command.IcebreakerID) == "" || strings.TrimSpace(command.UserID) == "" {
		return nil, fmt.Errorf("%w: icebreaker_id and user_id are required", ErrValidation)
	}
	item, err := s.gateway.PlayVoiceIcebreaker(ctx, strings.TrimSpace(command.IcebreakerID), strings.TrimSpace(command.UserID))
	if err != nil {
		return nil, fmt.Errorf("play voice icebreaker failed: %w", err)
	}
	return map[string]any{"voice_icebreaker": item}, nil
}

func (s *Service) HandleCreateGroupCoffeePoll(ctx context.Context, command CreateGroupCoffeePollCommand) (map[string]any, error) {
	creatorUserID := strings.TrimSpace(command.CreatorUserID)
	if creatorUserID == "" {
		return nil, fmt.Errorf("%w: creator_user_id is required", ErrValidation)
	}
	options := make([]GroupCoffeeOptionInput, 0, len(command.Options))
	for _, option := range command.Options {
		options = append(options, GroupCoffeeOptionInput{
			Day:          strings.TrimSpace(option.Day),
			TimeWindow:   strings.TrimSpace(option.TimeWindow),
			Neighborhood: strings.TrimSpace(option.Neighborhood),
		})
	}
	poll, err := s.gateway.CreateGroupCoffeePoll(ctx, creatorUserID, command.ParticipantUserIDs, options, strings.TrimSpace(command.DeadlineAt))
	if err != nil {
		return nil, fmt.Errorf("create group coffee poll failed: %w", err)
	}
	return map[string]any{"poll": poll}, nil
}

func (s *Service) HandleListGroupCoffeePolls(ctx context.Context, command ListGroupCoffeePollsCommand) (map[string]any, error) {
	userID := strings.TrimSpace(command.UserID)
	if userID == "" {
		return nil, fmt.Errorf("%w: user_id is required", ErrValidation)
	}
	limit := command.Limit
	if limit <= 0 {
		limit = 50
	}
	polls, err := s.gateway.ListGroupCoffeePolls(ctx, userID, strings.TrimSpace(command.Status), limit)
	if err != nil {
		return nil, fmt.Errorf("list group coffee polls failed: %w", err)
	}
	return map[string]any{"polls": polls}, nil
}

func (s *Service) HandleGetGroupCoffeePoll(ctx context.Context, command GetGroupCoffeePollCommand) (map[string]any, error) {
	pollID := strings.TrimSpace(command.PollID)
	if pollID == "" {
		return nil, fmt.Errorf("%w: poll id is required", ErrValidation)
	}
	poll, found, err := s.gateway.GetGroupCoffeePoll(ctx, pollID)
	if err != nil {
		return nil, fmt.Errorf("get group coffee poll failed: %w", err)
	}
	if !found {
		return nil, fmt.Errorf("group coffee poll not found")
	}
	return map[string]any{"poll": poll}, nil
}

func (s *Service) HandleVoteGroupCoffeePoll(ctx context.Context, command VoteGroupCoffeePollCommand) (map[string]any, error) {
	if strings.TrimSpace(command.PollID) == "" || strings.TrimSpace(command.UserID) == "" || strings.TrimSpace(command.OptionID) == "" {
		return nil, fmt.Errorf("%w: poll_id, user_id, and option_id are required", ErrValidation)
	}
	poll, err := s.gateway.VoteGroupCoffeePoll(
		ctx,
		strings.TrimSpace(command.PollID),
		strings.TrimSpace(command.UserID),
		strings.TrimSpace(command.OptionID),
	)
	if err != nil {
		return nil, fmt.Errorf("vote group coffee poll failed: %w", err)
	}
	return map[string]any{"poll": poll}, nil
}

func (s *Service) HandleFinalizeGroupCoffeePoll(ctx context.Context, command FinalizeGroupCoffeePollCommand) (map[string]any, error) {
	if strings.TrimSpace(command.PollID) == "" || strings.TrimSpace(command.UserID) == "" {
		return nil, fmt.Errorf("%w: poll_id and user_id are required", ErrValidation)
	}
	poll, selected, err := s.gateway.FinalizeGroupCoffeePoll(
		ctx,
		strings.TrimSpace(command.PollID),
		strings.TrimSpace(command.UserID),
	)
	if err != nil {
		return nil, fmt.Errorf("finalize group coffee poll failed: %w", err)
	}
	return map[string]any{"poll": poll, "selected_option": selected}, nil
}

func (s *Service) HandleCreateCommunityGroup(ctx context.Context, command CreateCommunityGroupCommand) (map[string]any, error) {
	if strings.TrimSpace(command.OwnerUserID) == "" || strings.TrimSpace(command.Name) == "" || strings.TrimSpace(command.City) == "" || strings.TrimSpace(command.Topic) == "" {
		return nil, fmt.Errorf("%w: owner_user_id, name, city, and topic are required", ErrValidation)
	}
	group, invites, err := s.gateway.CreateCommunityGroup(
		ctx,
		strings.TrimSpace(command.OwnerUserID),
		strings.TrimSpace(command.Name),
		strings.TrimSpace(command.City),
		strings.TrimSpace(command.Topic),
		strings.TrimSpace(command.Description),
		strings.TrimSpace(command.Visibility),
		command.InviteeUserIDs,
	)
	if err != nil {
		return nil, fmt.Errorf("create community group failed: %w", err)
	}
	return map[string]any{"group": group, "invites": invites}, nil
}

func (s *Service) HandleListCommunityGroups(ctx context.Context, command ListCommunityGroupsCommand) (map[string]any, error) {
	limit := command.Limit
	if limit <= 0 {
		limit = 50
	}
	groups, err := s.gateway.ListCommunityGroups(
		ctx,
		strings.TrimSpace(command.UserID),
		strings.TrimSpace(command.City),
		strings.TrimSpace(command.Topic),
		command.OnlyJoined,
		limit,
	)
	if err != nil {
		return nil, fmt.Errorf("list community groups failed: %w", err)
	}
	return map[string]any{"groups": groups, "count": len(groups)}, nil
}

func (s *Service) HandleInviteCommunityGroupMembers(ctx context.Context, command InviteCommunityGroupMembersCommand) (map[string]any, error) {
	if strings.TrimSpace(command.GroupID) == "" || strings.TrimSpace(command.InviterUserID) == "" {
		return nil, fmt.Errorf("%w: group_id and inviter_user_id are required", ErrValidation)
	}
	invites, err := s.gateway.InviteCommunityGroupMembers(ctx, strings.TrimSpace(command.GroupID), strings.TrimSpace(command.InviterUserID), command.InviteeUserIDs)
	if err != nil {
		return nil, fmt.Errorf("invite community group members failed: %w", err)
	}
	return map[string]any{"group_id": strings.TrimSpace(command.GroupID), "invites": invites}, nil
}

func (s *Service) HandleRespondCommunityGroupInvite(ctx context.Context, command RespondCommunityGroupInviteCommand) (map[string]any, error) {
	if strings.TrimSpace(command.GroupID) == "" || strings.TrimSpace(command.UserID) == "" || strings.TrimSpace(command.Decision) == "" {
		return nil, fmt.Errorf("%w: group_id, user_id, and decision are required", ErrValidation)
	}
	group, invite, err := s.gateway.RespondCommunityGroupInvite(ctx, strings.TrimSpace(command.GroupID), strings.TrimSpace(command.UserID), strings.TrimSpace(command.Decision))
	if err != nil {
		return nil, fmt.Errorf("respond community group invite failed: %w", err)
	}
	return map[string]any{"group": group, "invite": invite}, nil
}

func (s *Service) HandleListCommunityGroupInvites(ctx context.Context, command ListCommunityGroupInvitesCommand) (map[string]any, error) {
	userID := strings.TrimSpace(command.UserID)
	if userID == "" {
		return nil, fmt.Errorf("%w: user id is required", ErrValidation)
	}
	limit := command.Limit
	if limit <= 0 {
		limit = 50
	}
	invites, err := s.gateway.ListCommunityGroupInvites(ctx, userID, strings.TrimSpace(command.Status), limit)
	if err != nil {
		return nil, fmt.Errorf("list community group invites failed: %w", err)
	}
	return map[string]any{"invites": invites, "count": len(invites), "status": strings.TrimSpace(command.Status)}, nil
}
