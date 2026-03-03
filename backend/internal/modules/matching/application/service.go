package application

import (
	"context"
	"fmt"
	"strings"

	"go.uber.org/zap"

	"github.com/verified-dating/backend/internal/platform/mediatr"
)

type Gateway interface {
	GetCandidates(context.Context, string, int) (map[string]any, error)
	Swipe(context.Context, map[string]any) (map[string]any, error)
	ListMatches(context.Context, string) (map[string]any, error)
	Unmatch(context.Context, string, string) (map[string]any, error)
	MarkAsRead(context.Context, map[string]any) (map[string]any, error)
	GetQuestTemplate(context.Context, string) (map[string]any, error)
	UpsertQuestTemplate(context.Context, string, string, string, int, int) (map[string]any, error)
	GetQuestWorkflow(context.Context, string) (map[string]any, error)
	SubmitQuestResponse(context.Context, string, string, string) (map[string]any, error)
	ReviewQuestResponse(context.Context, string, string, string, string) (map[string]any, error)
	ListMatchGestures(context.Context, string) ([]map[string]any, error)
	CreateMatchGesture(context.Context, string, string, string, string, string, string) (map[string]any, error)
	DecideMatchGesture(context.Context, string, string, string, string, string) (map[string]any, error)
	GetGestureScore(context.Context, string, string) (map[string]any, error)
}

type Service struct {
	gateway Gateway
	log     *zap.Logger
}

func NewService(gateway Gateway, log *zap.Logger) *Service {
	return &Service{gateway: gateway, log: log}
}

func RegisterHandlers(bus *mediatr.Mediator, service *Service) {
	RegisterRPCHandlers(bus, service)
	RegisterStoreHandlers(bus, service)
}

func RegisterRPCHandlers(bus *mediatr.Mediator, service *Service) {
	bus.Register(GetCandidatesCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(GetCandidatesCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid get candidates command", ErrValidation)
		}
		return service.HandleGetCandidates(ctx, command)
	})
	bus.Register(SwipeCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(SwipeCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid swipe command", ErrValidation)
		}
		return service.HandleSwipe(ctx, command)
	})
	bus.Register(ListMatchesCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(ListMatchesCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid list matches command", ErrValidation)
		}
		return service.HandleListMatches(ctx, command)
	})
	bus.Register(UnmatchCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(UnmatchCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid unmatch command", ErrValidation)
		}
		return service.HandleUnmatch(ctx, command)
	})
	bus.Register(MarkAsReadCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(MarkAsReadCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid mark as read command", ErrValidation)
		}
		return service.HandleMarkAsRead(ctx, command)
	})
}

func RegisterStoreHandlers(bus *mediatr.Mediator, service *Service) {
	bus.Register(GetQuestTemplateCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(GetQuestTemplateCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid get quest template command", ErrValidation)
		}
		return service.HandleGetQuestTemplate(ctx, command)
	})
	bus.Register(UpsertQuestTemplateCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(UpsertQuestTemplateCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid upsert quest template command", ErrValidation)
		}
		return service.HandleUpsertQuestTemplate(ctx, command)
	})
	bus.Register(GetQuestWorkflowCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(GetQuestWorkflowCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid get quest workflow command", ErrValidation)
		}
		return service.HandleGetQuestWorkflow(ctx, command)
	})
	bus.Register(SubmitQuestResponseCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(SubmitQuestResponseCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid submit quest response command", ErrValidation)
		}
		return service.HandleSubmitQuestResponse(ctx, command)
	})
	bus.Register(ReviewQuestResponseCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(ReviewQuestResponseCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid review quest response command", ErrValidation)
		}
		return service.HandleReviewQuestResponse(ctx, command)
	})
	bus.Register(ListGestureTimelineCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(ListGestureTimelineCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid list gesture timeline command", ErrValidation)
		}
		return service.HandleListGestureTimeline(ctx, command)
	})
	bus.Register(CreateGestureCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(CreateGestureCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid create gesture command", ErrValidation)
		}
		return service.HandleCreateGesture(ctx, command)
	})
	bus.Register(DecideGestureCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(DecideGestureCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid decide gesture command", ErrValidation)
		}
		return service.HandleDecideGesture(ctx, command)
	})
	bus.Register(GetGestureScoreCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(GetGestureScoreCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid get gesture score command", ErrValidation)
		}
		return service.HandleGetGestureScore(ctx, command)
	})
}

func (s *Service) HandleGetCandidates(ctx context.Context, command GetCandidatesCommand) (map[string]any, error) {
	userID := strings.TrimSpace(command.UserID)
	if userID == "" {
		return nil, fmt.Errorf("%w: user id is required", ErrValidation)
	}
	limit := command.Limit
	if limit <= 0 {
		limit = 25
	}

	s.log.Info("matching_candidates_command")
	response, err := s.gateway.GetCandidates(ctx, userID, limit)
	if err != nil {
		return nil, fmt.Errorf("get candidates failed: %w", err)
	}
	return response, nil
}

func (s *Service) HandleSwipe(ctx context.Context, command SwipeCommand) (map[string]any, error) {
	if command.Payload == nil {
		return nil, fmt.Errorf("%w: payload is required", ErrValidation)
	}

	s.log.Info("matching_swipe_command")
	response, err := s.gateway.Swipe(ctx, command.Payload)
	if err != nil {
		return nil, fmt.Errorf("swipe failed: %w", err)
	}
	return response, nil
}

func (s *Service) HandleListMatches(ctx context.Context, command ListMatchesCommand) (map[string]any, error) {
	userID := strings.TrimSpace(command.UserID)
	if userID == "" {
		return nil, fmt.Errorf("%w: user id is required", ErrValidation)
	}

	s.log.Info("matching_list_command")
	response, err := s.gateway.ListMatches(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("list matches failed: %w", err)
	}
	return response, nil
}

func (s *Service) HandleUnmatch(ctx context.Context, command UnmatchCommand) (map[string]any, error) {
	matchID := strings.TrimSpace(command.MatchID)
	userID := strings.TrimSpace(command.UserID)
	if matchID == "" || userID == "" {
		return nil, fmt.Errorf("%w: match id and user id are required", ErrValidation)
	}

	s.log.Info("matching_unmatch_command")
	response, err := s.gateway.Unmatch(ctx, matchID, userID)
	if err != nil {
		return nil, fmt.Errorf("unmatch failed: %w", err)
	}
	return response, nil
}

func (s *Service) HandleMarkAsRead(ctx context.Context, command MarkAsReadCommand) (map[string]any, error) {
	matchID := strings.TrimSpace(command.MatchID)
	if matchID == "" {
		return nil, fmt.Errorf("%w: match id is required", ErrValidation)
	}

	payload := command.Payload
	if payload == nil {
		payload = map[string]any{}
	}
	payload["match_id"] = matchID

	s.log.Info("matching_read_command")
	response, err := s.gateway.MarkAsRead(ctx, payload)
	if err != nil {
		return nil, fmt.Errorf("mark as read failed: %w", err)
	}
	return response, nil
}

func (s *Service) HandleGetQuestTemplate(ctx context.Context, command GetQuestTemplateCommand) (map[string]any, error) {
	matchID := strings.TrimSpace(command.MatchID)
	if matchID == "" {
		return nil, fmt.Errorf("%w: match id is required", ErrValidation)
	}

	response, err := s.gateway.GetQuestTemplate(ctx, matchID)
	if err != nil {
		return nil, fmt.Errorf("get quest template failed: %w", err)
	}
	return map[string]any{"quest_template": response}, nil
}

func (s *Service) HandleUpsertQuestTemplate(
	ctx context.Context,
	command UpsertQuestTemplateCommand,
) (map[string]any, error) {
	matchID := strings.TrimSpace(command.MatchID)
	creatorUserID := strings.TrimSpace(command.CreatorUserID)
	prompt := strings.TrimSpace(command.Prompt)
	if matchID == "" || creatorUserID == "" {
		return nil, fmt.Errorf("%w: match id and creator user id are required", ErrValidation)
	}
	if prompt == "" {
		return nil, fmt.Errorf("%w: prompt template is required", ErrValidation)
	}

	minChars := command.MinChars
	maxChars := command.MaxChars
	if minChars <= 0 {
		minChars = 60
	}
	if maxChars <= 0 {
		maxChars = 280
	}

	response, err := s.gateway.UpsertQuestTemplate(
		ctx,
		matchID,
		creatorUserID,
		prompt,
		minChars,
		maxChars,
	)
	if err != nil {
		return nil, fmt.Errorf("upsert quest template failed: %w", err)
	}
	return map[string]any{"quest_template": response}, nil
}

func (s *Service) HandleGetQuestWorkflow(ctx context.Context, command GetQuestWorkflowCommand) (map[string]any, error) {
	matchID := strings.TrimSpace(command.MatchID)
	if matchID == "" {
		return nil, fmt.Errorf("%w: match id is required", ErrValidation)
	}

	response, err := s.gateway.GetQuestWorkflow(ctx, matchID)
	if err != nil {
		return nil, fmt.Errorf("get quest workflow failed: %w", err)
	}
	return map[string]any{"quest_workflow": response}, nil
}

func (s *Service) HandleSubmitQuestResponse(
	ctx context.Context,
	command SubmitQuestResponseCommand,
) (map[string]any, error) {
	matchID := strings.TrimSpace(command.MatchID)
	submitterUserID := strings.TrimSpace(command.SubmitterUserID)
	responseText := strings.TrimSpace(command.ResponseText)
	if matchID == "" || submitterUserID == "" {
		return nil, fmt.Errorf("%w: match id and submitter user id are required", ErrValidation)
	}
	if responseText == "" {
		return nil, fmt.Errorf("%w: response text is required", ErrValidation)
	}

	response, err := s.gateway.SubmitQuestResponse(ctx, matchID, submitterUserID, responseText)
	if err != nil {
		return nil, fmt.Errorf("submit quest response failed: %w", err)
	}
	return map[string]any{"quest_workflow": response}, nil
}

func (s *Service) HandleReviewQuestResponse(
	ctx context.Context,
	command ReviewQuestResponseCommand,
) (map[string]any, error) {
	matchID := strings.TrimSpace(command.MatchID)
	reviewerUserID := strings.TrimSpace(command.ReviewerUserID)
	decisionStatus := strings.ToLower(strings.TrimSpace(command.DecisionStatus))
	reviewReason := strings.TrimSpace(command.ReviewReason)

	if matchID == "" || reviewerUserID == "" {
		return nil, fmt.Errorf("%w: match id and reviewer user id are required", ErrValidation)
	}
	if decisionStatus != "approved" && decisionStatus != "rejected" {
		return nil, fmt.Errorf("%w: decision status must be approved or rejected", ErrValidation)
	}
	if decisionStatus == "rejected" && reviewReason == "" {
		return nil, fmt.Errorf("%w: review reason is required for rejection", ErrValidation)
	}

	response, err := s.gateway.ReviewQuestResponse(
		ctx,
		matchID,
		reviewerUserID,
		decisionStatus,
		reviewReason,
	)
	if err != nil {
		return nil, fmt.Errorf("review quest response failed: %w", err)
	}
	return map[string]any{"quest_workflow": response}, nil
}

func (s *Service) HandleListGestureTimeline(
	ctx context.Context,
	command ListGestureTimelineCommand,
) (map[string]any, error) {
	matchID := strings.TrimSpace(command.MatchID)
	if matchID == "" {
		return nil, fmt.Errorf("%w: match id is required", ErrValidation)
	}

	response, err := s.gateway.ListMatchGestures(ctx, matchID)
	if err != nil {
		return nil, fmt.Errorf("list gesture timeline failed: %w", err)
	}
	return map[string]any{"timeline": response}, nil
}

func (s *Service) HandleCreateGesture(
	ctx context.Context,
	command CreateGestureCommand,
) (map[string]any, error) {
	matchID := strings.TrimSpace(command.MatchID)
	senderUserID := strings.TrimSpace(command.SenderUserID)
	receiverUserID := strings.TrimSpace(command.ReceiverUserID)
	gestureType := strings.ToLower(strings.TrimSpace(command.GestureType))
	contentText := strings.TrimSpace(command.ContentText)
	tone := strings.TrimSpace(command.Tone)

	if matchID == "" || senderUserID == "" || receiverUserID == "" {
		return nil, fmt.Errorf("%w: match id, sender user id, and receiver user id are required", ErrValidation)
	}
	if contentText == "" {
		return nil, fmt.Errorf("%w: content text is required", ErrValidation)
	}
	if gestureType != "thoughtful_opener" && gestureType != "micro_card" && gestureType != "challenge_token" {
		return nil, fmt.Errorf("%w: gesture type must be thoughtful_opener, micro_card, or challenge_token", ErrValidation)
	}

	response, err := s.gateway.CreateMatchGesture(
		ctx,
		matchID,
		senderUserID,
		receiverUserID,
		gestureType,
		contentText,
		tone,
	)
	if err != nil {
		return nil, fmt.Errorf("create gesture failed: %w", err)
	}
	return map[string]any{"gesture": response}, nil
}

func (s *Service) HandleDecideGesture(
	ctx context.Context,
	command DecideGestureCommand,
) (map[string]any, error) {
	matchID := strings.TrimSpace(command.MatchID)
	gestureID := strings.TrimSpace(command.GestureID)
	reviewerUserID := strings.TrimSpace(command.ReviewerUserID)
	decision := strings.ToLower(strings.TrimSpace(command.Decision))
	reason := strings.TrimSpace(command.Reason)

	if matchID == "" || gestureID == "" || reviewerUserID == "" {
		return nil, fmt.Errorf("%w: match id, gesture id, and reviewer user id are required", ErrValidation)
	}
	if decision != "appreciate" && decision != "decline" && decision != "request_better" {
		return nil, fmt.Errorf("%w: decision must be appreciate, decline, or request_better", ErrValidation)
	}
	if (decision == "decline" || decision == "request_better") && reason == "" {
		return nil, fmt.Errorf("%w: reason is required for decline/request_better", ErrValidation)
	}

	response, err := s.gateway.DecideMatchGesture(ctx, matchID, gestureID, reviewerUserID, decision, reason)
	if err != nil {
		return nil, fmt.Errorf("decide gesture failed: %w", err)
	}
	return map[string]any{"gesture": response}, nil
}

func (s *Service) HandleGetGestureScore(
	ctx context.Context,
	command GetGestureScoreCommand,
) (map[string]any, error) {
	matchID := strings.TrimSpace(command.MatchID)
	gestureID := strings.TrimSpace(command.GestureID)
	if matchID == "" || gestureID == "" {
		return nil, fmt.Errorf("%w: match id and gesture id are required", ErrValidation)
	}

	response, err := s.gateway.GetGestureScore(ctx, matchID, gestureID)
	if err != nil {
		return nil, fmt.Errorf("get gesture score failed: %w", err)
	}
	return map[string]any{"effort_score": response}, nil
}
