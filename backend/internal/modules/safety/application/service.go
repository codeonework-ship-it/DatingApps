package application

import (
	"context"
	"fmt"
	"strings"

	"go.uber.org/zap"

	"github.com/verified-dating/backend/internal/platform/mediatr"
)

type Gateway interface {
	ReportUser(context.Context, string, string, string, string) (map[string]any, error)
	BlockUser(context.Context, string, string) error
	UnblockUser(context.Context, string, string) error
	TriggerSOS(context.Context, string, string, string, string, float64, float64) (map[string]any, error)
	ListSOS(context.Context, string, int) ([]map[string]any, error)
	ResolveSOS(context.Context, string, string, string) (map[string]any, error)
}

type Service struct {
	gateway Gateway
	log     *zap.Logger
}

func NewService(gateway Gateway, log *zap.Logger) *Service {
	return &Service{gateway: gateway, log: log}
}

func RegisterHandlers(bus *mediatr.Mediator, service *Service) {
	bus.Register(ReportUserCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(ReportUserCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid report user command", ErrValidation)
		}
		return service.HandleReportUser(ctx, command)
	})
	bus.Register(BlockUserCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(BlockUserCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid block user command", ErrValidation)
		}
		return service.HandleBlockUser(ctx, command)
	})
	bus.Register(UnblockUserCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(UnblockUserCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid unblock user command", ErrValidation)
		}
		return service.HandleUnblockUser(ctx, command)
	})
	bus.Register(TriggerSOSCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(TriggerSOSCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid trigger sos command", ErrValidation)
		}
		return service.HandleTriggerSOS(ctx, command)
	})
	bus.Register(ListSOSCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(ListSOSCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid list sos command", ErrValidation)
		}
		return service.HandleListSOS(ctx, command)
	})
	bus.Register(ResolveSOSCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(ResolveSOSCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid resolve sos command", ErrValidation)
		}
		return service.HandleResolveSOS(ctx, command)
	})
}

func (s *Service) HandleReportUser(
	ctx context.Context,
	command ReportUserCommand,
) (map[string]any, error) {
	reporterUserID := strings.TrimSpace(command.ReporterUserID)
	reportedUserID := strings.TrimSpace(command.ReportedUserID)
	reason := strings.TrimSpace(command.Reason)
	if reportedUserID == "" || reason == "" {
		return nil, fmt.Errorf("%w: reported_user_id and reason are required", ErrValidation)
	}

	s.log.Info("safety_report_command")
	report, err := s.gateway.ReportUser(ctx, reporterUserID, reportedUserID, reason, strings.TrimSpace(command.Description))
	if err != nil {
		return nil, fmt.Errorf("report user failed: %w", err)
	}
	return map[string]any{"accepted": true, "report": report}, nil
}

func (s *Service) HandleBlockUser(ctx context.Context, command BlockUserCommand) (map[string]any, error) {
	userID := strings.TrimSpace(command.UserID)
	blockedUserID := strings.TrimSpace(command.BlockedUserID)
	if userID == "" || blockedUserID == "" {
		return nil, fmt.Errorf("%w: user_id and blocked_user_id are required", ErrValidation)
	}

	s.log.Info("safety_block_command")
	if err := s.gateway.BlockUser(ctx, userID, blockedUserID); err != nil {
		return nil, fmt.Errorf("block user failed: %w", err)
	}
	return map[string]any{"accepted": true}, nil
}

func (s *Service) HandleUnblockUser(ctx context.Context, command UnblockUserCommand) (map[string]any, error) {
	userID := strings.TrimSpace(command.UserID)
	blockedUserID := strings.TrimSpace(command.BlockedUserID)
	if userID == "" || blockedUserID == "" {
		return nil, fmt.Errorf("%w: user_id and blocked_user_id are required", ErrValidation)
	}

	s.log.Info("safety_unblock_command")
	if err := s.gateway.UnblockUser(ctx, userID, blockedUserID); err != nil {
		return nil, fmt.Errorf("unblock user failed: %w", err)
	}
	return map[string]any{"accepted": true}, nil
}

func (s *Service) HandleTriggerSOS(ctx context.Context, command TriggerSOSCommand) (map[string]any, error) {
	userID := strings.TrimSpace(command.UserID)
	if userID == "" {
		return nil, fmt.Errorf("%w: user id is required", ErrValidation)
	}

	s.log.Info("safety_trigger_sos_command")
	alert, err := s.gateway.TriggerSOS(
		ctx,
		userID,
		strings.TrimSpace(command.MatchID),
		strings.TrimSpace(command.EmergencyLevel),
		strings.TrimSpace(command.Message),
		command.Latitude,
		command.Longitude,
	)
	if err != nil {
		return nil, fmt.Errorf("trigger sos failed: %w", err)
	}
	return map[string]any{"accepted": true, "alert": alert}, nil
}

func (s *Service) HandleListSOS(ctx context.Context, command ListSOSCommand) (map[string]any, error) {
	userID := strings.TrimSpace(command.UserID)
	if userID == "" {
		return nil, fmt.Errorf("%w: user id is required", ErrValidation)
	}
	limit := command.Limit
	if limit <= 0 {
		limit = 100
	}

	s.log.Info("safety_list_sos_command")
	alerts, err := s.gateway.ListSOS(ctx, userID, limit)
	if err != nil {
		return nil, fmt.Errorf("list sos failed: %w", err)
	}
	return map[string]any{"alerts": alerts}, nil
}

func (s *Service) HandleResolveSOS(ctx context.Context, command ResolveSOSCommand) (map[string]any, error) {
	alertID := strings.TrimSpace(command.AlertID)
	if alertID == "" {
		return nil, fmt.Errorf("%w: alert id is required", ErrValidation)
	}

	s.log.Info("safety_resolve_sos_command")
	alert, err := s.gateway.ResolveSOS(
		ctx,
		alertID,
		strings.TrimSpace(command.ResolvedBy),
		strings.TrimSpace(command.ResolutionNote),
	)
	if err != nil {
		return nil, fmt.Errorf("resolve sos failed: %w", err)
	}
	return map[string]any{"success": true, "alert": alert}, nil
}
