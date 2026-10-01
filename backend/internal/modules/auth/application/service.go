package application

import (
	"context"
	"errors"
	"fmt"

	"go.uber.org/zap"

	"github.com/verified-dating/backend/internal/modules/auth/domain"
	"github.com/verified-dating/backend/internal/platform/mediatr"
	"github.com/verified-dating/backend/internal/platform/observability"
)

type Gateway interface {
	Login(context.Context, string, string) (map[string]any, error)
	Signup(context.Context, string, string) (map[string]any, error)
}

type Service struct {
	gateway Gateway
	log     *zap.Logger
}

func NewService(gateway Gateway, log *zap.Logger) *Service {
	return &Service{gateway: gateway, log: log}
}

func RegisterHandlers(bus *mediatr.Mediator, service *Service) {
	bus.Register(LoginCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(LoginCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid login command", ErrValidation)
		}
		return service.HandleLogin(ctx, command)
	})
	bus.Register(SignupCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(SignupCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid signup command", ErrValidation)
		}
		return service.HandleSignup(ctx, command)
	})
}

func (s *Service) HandleLogin(ctx context.Context, command LoginCommand) (map[string]any, error) {
	username, err := domain.NewUsername(command.Username)
	if err != nil {
		return nil, usernameValidationError(err)
	}
	if command.Password == "" {
		return nil, fmt.Errorf("%w: password is required", ErrValidation)
	}
	s.log.Info("auth_login_command", zap.String("username_ref", observability.PseudonymizeIdentifier(username.Value())))
	response, err := s.gateway.Login(ctx, username.Value(), command.Password)
	if err != nil {
		return nil, fmt.Errorf("login failed: %w", err)
	}
	return response, nil
}

func (s *Service) HandleSignup(ctx context.Context, command SignupCommand) (map[string]any, error) {
	username, err := domain.NewUsername(command.Username)
	if err != nil {
		return nil, usernameValidationError(err)
	}
	if err := domain.ValidatePassword(command.Password); err != nil {
		return nil, fmt.Errorf("%w: password must be 8-72 UTF-8 bytes and contain letters and numbers", ErrValidation)
	}
	s.log.Info("auth_signup_command", zap.String("username_ref", observability.PseudonymizeIdentifier(username.Value())))
	var response map[string]any
	if command.AccountKind != "" && command.AccountKind != "dating" {
		gateway, ok := s.gateway.(interface {
			SignupIntroducer(context.Context, string, string, string, string) (map[string]any, error)
		})
		if command.AccountKind != "introducer" || !ok {
			return nil, fmt.Errorf("%w: account type is unavailable", ErrValidation)
		}
		response, err = gateway.SignupIntroducer(ctx, username.Value(), command.Password, command.Name, command.DateOfBirth)
	} else {
		response, err = s.gateway.Signup(ctx, username.Value(), command.Password)
	}
	if err != nil {
		return nil, fmt.Errorf("signup failed: %w", err)
	}
	return response, nil
}

func usernameValidationError(err error) error {
	if errors.Is(err, domain.ErrInvalidUsername) {
		return fmt.Errorf("%w: username must be 3-30 characters using letters, numbers, underscore, or dot", ErrValidation)
	}
	return err
}
