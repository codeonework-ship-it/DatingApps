package application

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"go.uber.org/zap"

	"github.com/verified-dating/backend/internal/modules/auth/domain"
	"github.com/verified-dating/backend/internal/platform/mediatr"
)

type Gateway interface {
	SendOTP(context.Context, string) (map[string]any, error)
	VerifyOTP(context.Context, string, string) (map[string]any, error)
}

type Service struct {
	gateway Gateway
	log     *zap.Logger
}

func NewService(gateway Gateway, log *zap.Logger) *Service {
	return &Service{gateway: gateway, log: log}
}

func RegisterHandlers(bus *mediatr.Mediator, service *Service) {
	bus.Register(SendOTPCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(SendOTPCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid send otp command", ErrValidation)
		}
		return service.HandleSendOTP(ctx, command)
	})

	bus.Register(VerifyOTPCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(VerifyOTPCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid verify otp command", ErrValidation)
		}
		return service.HandleVerifyOTP(ctx, command)
	})
}

func (s *Service) HandleSendOTP(ctx context.Context, command SendOTPCommand) (map[string]any, error) {
	email, err := domain.NewEmail(command.Email)
	if err != nil {
		if errors.Is(err, domain.ErrInvalidEmail) {
			return nil, fmt.Errorf("%w: valid email is required", ErrValidation)
		}
		return nil, err
	}

	s.log.Info("auth_send_otp_command")
	response, err := s.gateway.SendOTP(ctx, email.Value())
	if err != nil {
		return nil, fmt.Errorf("send otp failed: %w", err)
	}
	return response, nil
}

func (s *Service) HandleVerifyOTP(ctx context.Context, command VerifyOTPCommand) (map[string]any, error) {
	email, err := domain.NewEmail(command.Email)
	if err != nil {
		if errors.Is(err, domain.ErrInvalidEmail) {
			return nil, fmt.Errorf("%w: valid email is required", ErrValidation)
		}
		return nil, err
	}

	otp := strings.TrimSpace(command.OTP)
	if len(otp) != 6 {
		return nil, fmt.Errorf("%w: otp must be 6 digits", ErrValidation)
	}

	s.log.Info("auth_verify_otp_command")
	response, err := s.gateway.VerifyOTP(ctx, email.Value(), otp)
	if err != nil {
		return nil, fmt.Errorf("verify otp failed: %w", err)
	}
	return response, nil
}
