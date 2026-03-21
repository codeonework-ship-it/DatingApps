package application

import (
	"context"
	"fmt"
	"strings"

	"go.uber.org/zap"

	"github.com/verified-dating/backend/internal/platform/mediatr"
)

type Gateway interface {
	ListMessages(context.Context, string, int) (map[string]any, error)
	SendMessage(context.Context, map[string]any) (map[string]any, error)
	DeleteMessage(context.Context, map[string]any) (map[string]any, error)
}

type Service struct {
	gateway Gateway
	log     *zap.Logger
}

func NewService(gateway Gateway, log *zap.Logger) *Service {
	return &Service{gateway: gateway, log: log}
}

func RegisterHandlers(bus *mediatr.Mediator, service *Service) {
	bus.Register(ListMessagesCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(ListMessagesCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid list messages command", ErrValidation)
		}
		return service.HandleListMessages(ctx, command)
	})
	bus.Register(SendMessageCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(SendMessageCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid send message command", ErrValidation)
		}
		return service.HandleSendMessage(ctx, command)
	})
	bus.Register(DeleteMessageCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(DeleteMessageCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid delete message command", ErrValidation)
		}
		return service.HandleDeleteMessage(ctx, command)
	})
}

func (s *Service) HandleListMessages(ctx context.Context, command ListMessagesCommand) (map[string]any, error) {
	matchID := strings.TrimSpace(command.MatchID)
	if matchID == "" {
		return nil, fmt.Errorf("%w: match id is required", ErrValidation)
	}
	limit := command.Limit
	if limit <= 0 {
		limit = 50
	}

	s.log.Info("chat_list_messages_command")
	response, err := s.gateway.ListMessages(ctx, matchID, limit)
	if err != nil {
		return nil, fmt.Errorf("list messages failed: %w", err)
	}
	return response, nil
}

func (s *Service) HandleSendMessage(ctx context.Context, command SendMessageCommand) (map[string]any, error) {
	matchID := strings.TrimSpace(command.MatchID)
	if matchID == "" {
		return nil, fmt.Errorf("%w: match id is required", ErrValidation)
	}
	payload := command.Payload
	if payload == nil {
		return nil, fmt.Errorf("%w: payload is required", ErrValidation)
	}
	payload["match_id"] = matchID

	s.log.Info("chat_send_message_command")
	response, err := s.gateway.SendMessage(ctx, payload)
	if err != nil {
		return nil, fmt.Errorf("send message failed: %w", err)
	}
	return response, nil
}

func (s *Service) HandleDeleteMessage(ctx context.Context, command DeleteMessageCommand) (map[string]any, error) {
	matchID := strings.TrimSpace(command.MatchID)
	if matchID == "" {
		return nil, fmt.Errorf("%w: match id is required", ErrValidation)
	}
	payload := command.Payload
	if payload == nil {
		return nil, fmt.Errorf("%w: payload is required", ErrValidation)
	}
	payload["match_id"] = matchID

	s.log.Info("chat_delete_message_command")
	response, err := s.gateway.DeleteMessage(ctx, payload)
	if err != nil {
		return nil, fmt.Errorf("delete message failed: %w", err)
	}
	return response, nil
}
