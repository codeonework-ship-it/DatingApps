package application

import (
	"context"
	"fmt"
	"strings"

	"go.uber.org/zap"

	"github.com/verified-dating/backend/internal/platform/mediatr"
)

type Gateway interface {
	ListActivities(context.Context, int) ([]map[string]any, error)
	ListReports(context.Context, string, int) ([]map[string]any, error)
	ActionReport(context.Context, string, string, string, string) (map[string]any, error)
	AnalyticsOverview(context.Context) (map[string]any, error)
	UserAnalytics(context.Context, string) (map[string]any, error)
}

type Service struct {
	gateway Gateway
	log     *zap.Logger
}

func NewService(gateway Gateway, log *zap.Logger) *Service {
	return &Service{gateway: gateway, log: log}
}

func RegisterHandlers(bus *mediatr.Mediator, service *Service) {
	bus.Register(ListActivitiesCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(ListActivitiesCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid list activities command", ErrValidation)
		}
		return service.HandleListActivities(ctx, command)
	})
	bus.Register(ListReportsCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(ListReportsCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid list reports command", ErrValidation)
		}
		return service.HandleListReports(ctx, command)
	})
	bus.Register(ActionReportCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(ActionReportCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid action report command", ErrValidation)
		}
		return service.HandleActionReport(ctx, command)
	})
	bus.Register(AnalyticsOverviewCommandName, func(ctx context.Context, request any) (any, error) {
		_, ok := request.(AnalyticsOverviewCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid analytics overview command", ErrValidation)
		}
		return service.HandleAnalyticsOverview(ctx)
	})
	bus.Register(UserAnalyticsCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(UserAnalyticsCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid user analytics command", ErrValidation)
		}
		return service.HandleUserAnalytics(ctx, command)
	})
}

func (s *Service) HandleListActivities(ctx context.Context, command ListActivitiesCommand) (map[string]any, error) {
	limit := command.Limit
	if limit <= 0 {
		limit = 100
	}

	s.log.Info("admin_list_activities_command")
	items, err := s.gateway.ListActivities(ctx, limit)
	if err != nil {
		return nil, fmt.Errorf("list activities failed: %w", err)
	}
	return map[string]any{"activities": items}, nil
}

func (s *Service) HandleListReports(ctx context.Context, command ListReportsCommand) (map[string]any, error) {
	limit := command.Limit
	if limit <= 0 {
		limit = 100
	}

	s.log.Info("admin_list_reports_command")
	items, err := s.gateway.ListReports(ctx, strings.TrimSpace(command.Status), limit)
	if err != nil {
		return nil, fmt.Errorf("list reports failed: %w", err)
	}
	return map[string]any{"reports": items}, nil
}

func (s *Service) HandleActionReport(ctx context.Context, command ActionReportCommand) (map[string]any, error) {
	reportID := strings.TrimSpace(command.ReportID)
	status := strings.TrimSpace(command.Status)
	if reportID == "" {
		return nil, fmt.Errorf("%w: report id is required", ErrValidation)
	}
	if status == "" {
		return nil, fmt.Errorf("%w: status is required", ErrValidation)
	}
	reviewedBy := strings.TrimSpace(command.ReviewedBy)
	if reviewedBy == "" {
		reviewedBy = "control-panel"
	}

	s.log.Info("admin_action_report_command")
	report, err := s.gateway.ActionReport(ctx, reportID, status, strings.TrimSpace(command.Action), reviewedBy)
	if err != nil {
		return nil, fmt.Errorf("action report failed: %w", err)
	}
	return map[string]any{"report": report, "success": true}, nil
}

func (s *Service) HandleAnalyticsOverview(ctx context.Context) (map[string]any, error) {
	s.log.Info("admin_analytics_overview_command")
	overview, err := s.gateway.AnalyticsOverview(ctx)
	if err != nil {
		return nil, fmt.Errorf("analytics overview failed: %w", err)
	}
	return map[string]any{"metrics": overview}, nil
}

func (s *Service) HandleUserAnalytics(ctx context.Context, command UserAnalyticsCommand) (map[string]any, error) {
	userID := strings.TrimSpace(command.UserID)
	if userID == "" {
		return nil, fmt.Errorf("%w: user id is required", ErrValidation)
	}

	s.log.Info("admin_user_analytics_command")
	metrics, err := s.gateway.UserAnalytics(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("user analytics failed: %w", err)
	}
	return map[string]any{"metrics": metrics}, nil
}
