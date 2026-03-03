package application

import (
	"context"
	"fmt"
	"strings"

	"go.uber.org/zap"

	"github.com/verified-dating/backend/internal/platform/mediatr"
)

type Gateway interface {
	StartCall(context.Context, string, string, string) (map[string]any, error)
	EndCall(context.Context, string, string) (map[string]any, error)
	ListHistory(context.Context, string, int) ([]map[string]any, error)
}

type Service struct {
	gateway Gateway
	log     *zap.Logger
}

func NewService(gateway Gateway, log *zap.Logger) *Service {
	return &Service{gateway: gateway, log: log}
}

func RegisterHandlers(bus *mediatr.Mediator, service *Service) {
	bus.Register(StartCallCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(StartCallCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid start call command", ErrValidation)
		}
		return service.HandleStartCall(ctx, command)
	})
	bus.Register(EndCallCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(EndCallCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid end call command", ErrValidation)
		}
		return service.HandleEndCall(ctx, command)
	})
	bus.Register(ListCallHistoryCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(ListCallHistoryCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid list call history command", ErrValidation)
		}
		return service.HandleListCallHistory(ctx, command)
	})
}

func (s *Service) HandleStartCall(ctx context.Context, command StartCallCommand) (map[string]any, error) {
	matchID := strings.TrimSpace(command.MatchID)
	initiatorUserID := strings.TrimSpace(command.InitiatorUserID)
	recipientUserID := strings.TrimSpace(command.RecipientUserID)
	if initiatorUserID == "" || recipientUserID == "" {
		return nil, fmt.Errorf("%w: initiator_id and recipient_id are required", ErrValidation)
	}

	s.log.Info("calls_start_command")
	session, err := s.gateway.StartCall(ctx, matchID, initiatorUserID, recipientUserID)
	if err != nil {
		return nil, fmt.Errorf("start call failed: %w", err)
	}
	return map[string]any{"accepted": true, "session": session}, nil
}

func (s *Service) HandleEndCall(ctx context.Context, command EndCallCommand) (map[string]any, error) {
	callID := strings.TrimSpace(command.CallID)
	if callID == "" {
		return nil, fmt.Errorf("%w: call id is required", ErrValidation)
	}

	s.log.Info("calls_end_command")
	session, err := s.gateway.EndCall(ctx, callID, strings.TrimSpace(command.EndedByUserID))
	if err != nil {
		return nil, fmt.Errorf("end call failed: %w", err)
	}
	return map[string]any{"success": true, "session": session}, nil
}

func (s *Service) HandleListCallHistory(ctx context.Context, command ListCallHistoryCommand) (map[string]any, error) {
	userID := strings.TrimSpace(command.UserID)
	if userID == "" {
		return nil, fmt.Errorf("%w: user id is required", ErrValidation)
	}
	limit := command.Limit
	if limit <= 0 {
		limit = 100
	}

	s.log.Info("calls_list_history_command")
	history, err := s.gateway.ListHistory(ctx, userID, limit)
	if err != nil {
		return nil, fmt.Errorf("list call history failed: %w", err)
	}
	return map[string]any{"history": history}, nil
}
