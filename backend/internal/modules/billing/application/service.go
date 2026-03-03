package application

import (
	"context"
	"fmt"
	"strings"

	"go.uber.org/zap"

	"github.com/verified-dating/backend/internal/platform/mediatr"
)

type Gateway interface {
	ListPlans(context.Context) ([]map[string]any, error)
	GetSubscription(context.Context, string) (map[string]any, error)
	Subscribe(context.Context, string, string, string) (map[string]any, map[string]any, error)
	ListPayments(context.Context, string, int) ([]map[string]any, error)
}

type Service struct {
	gateway Gateway
	log     *zap.Logger
}

func NewService(gateway Gateway, log *zap.Logger) *Service {
	return &Service{gateway: gateway, log: log}
}

func RegisterHandlers(bus *mediatr.Mediator, service *Service) {
	bus.Register(ListPlansCommandName, func(ctx context.Context, request any) (any, error) {
		_, ok := request.(ListPlansCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid list plans command", ErrValidation)
		}
		return service.HandleListPlans(ctx)
	})
	bus.Register(GetSubscriptionCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(GetSubscriptionCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid get subscription command", ErrValidation)
		}
		return service.HandleGetSubscription(ctx, command)
	})
	bus.Register(SubscribePlanCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(SubscribePlanCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid subscribe plan command", ErrValidation)
		}
		return service.HandleSubscribe(ctx, command)
	})
	bus.Register(ListPaymentsCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(ListPaymentsCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid list payments command", ErrValidation)
		}
		return service.HandleListPayments(ctx, command)
	})
}

func (s *Service) HandleListPlans(ctx context.Context) (map[string]any, error) {
	s.log.Info("billing_list_plans_command")
	plans, err := s.gateway.ListPlans(ctx)
	if err != nil {
		return nil, fmt.Errorf("list plans failed: %w", err)
	}
	return map[string]any{"plans": plans}, nil
}

func (s *Service) HandleGetSubscription(ctx context.Context, command GetSubscriptionCommand) (map[string]any, error) {
	userID := strings.TrimSpace(command.UserID)
	if userID == "" {
		return nil, fmt.Errorf("%w: user id is required", ErrValidation)
	}

	s.log.Info("billing_get_subscription_command")
	subscription, err := s.gateway.GetSubscription(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("get subscription failed: %w", err)
	}
	return map[string]any{"subscription": subscription}, nil
}

func (s *Service) HandleSubscribe(ctx context.Context, command SubscribePlanCommand) (map[string]any, error) {
	userID := strings.TrimSpace(command.UserID)
	planID := strings.TrimSpace(command.PlanID)
	billingCycle := strings.TrimSpace(command.BillingCycle)
	if userID == "" || planID == "" {
		return nil, fmt.Errorf("%w: user_id and plan_id are required", ErrValidation)
	}

	s.log.Info("billing_subscribe_command")
	subscription, payment, err := s.gateway.Subscribe(ctx, userID, planID, billingCycle)
	if err != nil {
		return nil, fmt.Errorf("subscribe failed: %w", err)
	}
	return map[string]any{"success": true, "subscription": subscription, "payment": payment}, nil
}

func (s *Service) HandleListPayments(ctx context.Context, command ListPaymentsCommand) (map[string]any, error) {
	userID := strings.TrimSpace(command.UserID)
	if userID == "" {
		return nil, fmt.Errorf("%w: user id is required", ErrValidation)
	}
	limit := command.Limit
	if limit <= 0 {
		limit = 100
	}

	s.log.Info("billing_list_payments_command")
	payments, err := s.gateway.ListPayments(ctx, userID, limit)
	if err != nil {
		return nil, fmt.Errorf("list payments failed: %w", err)
	}
	return map[string]any{"payments": payments}, nil
}
