package application

import (
	"context"
	"fmt"
	"strings"

	"go.uber.org/zap"

	"github.com/verified-dating/backend/internal/platform/mediatr"
)

type Gateway interface {
	GetVerification(context.Context, string) (map[string]any, error)
	SubmitVerification(context.Context, string) (map[string]any, error)
	ListVerifications(context.Context, string, int) ([]map[string]any, error)
	ReviewVerification(context.Context, string, string, string, string) (map[string]any, error)
}

type Service struct {
	gateway Gateway
	log     *zap.Logger
}

func NewService(gateway Gateway, log *zap.Logger) *Service {
	return &Service{gateway: gateway, log: log}
}

func RegisterHandlers(bus *mediatr.Mediator, service *Service) {
	bus.Register(GetVerificationCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(GetVerificationCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid get verification command", ErrValidation)
		}
		return service.HandleGetVerification(ctx, command)
	})
	bus.Register(SubmitVerificationCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(SubmitVerificationCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid submit verification command", ErrValidation)
		}
		return service.HandleSubmitVerification(ctx, command)
	})
	bus.Register(ListVerificationsCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(ListVerificationsCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid list verifications command", ErrValidation)
		}
		return service.HandleListVerifications(ctx, command)
	})
	bus.Register(ApproveVerificationCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(ApproveVerificationCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid approve verification command", ErrValidation)
		}
		return service.HandleApproveVerification(ctx, command)
	})
	bus.Register(RejectVerificationCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(RejectVerificationCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid reject verification command", ErrValidation)
		}
		return service.HandleRejectVerification(ctx, command)
	})
}

func (s *Service) HandleGetVerification(ctx context.Context, command GetVerificationCommand) (map[string]any, error) {
	userID := strings.TrimSpace(command.UserID)
	if userID == "" {
		return nil, fmt.Errorf("%w: user id is required", ErrValidation)
	}

	s.log.Info("verification_get_command")
	state, err := s.gateway.GetVerification(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("get verification failed: %w", err)
	}
	return map[string]any{"status": state["status"], "rejection_reason": state["rejection_reason"]}, nil
}

func (s *Service) HandleSubmitVerification(ctx context.Context, command SubmitVerificationCommand) (map[string]any, error) {
	userID := strings.TrimSpace(command.UserID)
	if userID == "" {
		return nil, fmt.Errorf("%w: user id is required", ErrValidation)
	}

	s.log.Info("verification_submit_command")
	state, err := s.gateway.SubmitVerification(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("submit verification failed: %w", err)
	}
	return map[string]any{
		"status":           state["status"],
		"rejection_reason": state["rejection_reason"],
		"submitted_at":     state["submitted_at"],
		"accepted":         true,
	}, nil
}

func (s *Service) HandleListVerifications(ctx context.Context, command ListVerificationsCommand) (map[string]any, error) {
	limit := command.Limit
	if limit <= 0 {
		limit = 100
	}

	s.log.Info("verification_admin_list_command")
	items, err := s.gateway.ListVerifications(ctx, strings.TrimSpace(command.Status), limit)
	if err != nil {
		return nil, fmt.Errorf("list verifications failed: %w", err)
	}
	return map[string]any{"verifications": items}, nil
}

func (s *Service) HandleApproveVerification(ctx context.Context, command ApproveVerificationCommand) (map[string]any, error) {
	userID := strings.TrimSpace(command.UserID)
	if userID == "" {
		return nil, fmt.Errorf("%w: user id is required", ErrValidation)
	}
	reviewedBy := strings.TrimSpace(command.ReviewedBy)
	if reviewedBy == "" {
		reviewedBy = "control-panel"
	}

	s.log.Info("verification_admin_approve_command")
	state, err := s.gateway.ReviewVerification(ctx, userID, "approved", "", reviewedBy)
	if err != nil {
		return nil, fmt.Errorf("approve verification failed: %w", err)
	}
	return map[string]any{"verification": state, "success": true}, nil
}

func (s *Service) HandleRejectVerification(ctx context.Context, command RejectVerificationCommand) (map[string]any, error) {
	userID := strings.TrimSpace(command.UserID)
	reason := strings.TrimSpace(command.RejectionReason)
	if userID == "" {
		return nil, fmt.Errorf("%w: user id is required", ErrValidation)
	}
	if reason == "" {
		return nil, fmt.Errorf("%w: rejection_reason is required", ErrValidation)
	}
	reviewedBy := strings.TrimSpace(command.ReviewedBy)
	if reviewedBy == "" {
		reviewedBy = "control-panel"
	}

	s.log.Info("verification_admin_reject_command")
	state, err := s.gateway.ReviewVerification(ctx, userID, "rejected", reason, reviewedBy)
	if err != nil {
		return nil, fmt.Errorf("reject verification failed: %w", err)
	}
	return map[string]any{"verification": state, "success": true}, nil
}
