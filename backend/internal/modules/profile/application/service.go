package application

import (
	"context"
	"fmt"
	"strings"

	"go.uber.org/zap"

	"github.com/verified-dating/backend/internal/platform/mediatr"
)

type Gateway interface {
	GetProfile(context.Context, string) (map[string]any, error)
	GetProfileSummary(context.Context, string) (map[string]any, error)
	UpsertProfile(context.Context, map[string]any) (map[string]any, error)
	GetDraft(context.Context, string) (map[string]any, error)
	PatchDraft(context.Context, string, map[string]any) (map[string]any, error)
	AddPhoto(context.Context, string, string) (map[string]any, error)
	DeletePhoto(context.Context, string, string) (map[string]any, error)
	ReorderPhotos(context.Context, string, []string) (map[string]any, error)
	CompleteProfile(context.Context, string) (map[string]any, error)
	GetSettings(context.Context, string) (map[string]any, error)
	PatchSettings(context.Context, string, map[string]any) (map[string]any, error)
	ListEmergencyContacts(context.Context, string) ([]map[string]any, error)
	AddEmergencyContact(context.Context, string, string, string) ([]map[string]any, error)
	UpdateEmergencyContact(context.Context, string, string, string, string) ([]map[string]any, error)
	DeleteEmergencyContact(context.Context, string, string) ([]map[string]any, error)
	ListBlockedUsers(context.Context, string) ([]map[string]any, error)
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
	bus.Register(GetProfileCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(GetProfileCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid get profile command", ErrValidation)
		}
		return service.HandleGetProfile(ctx, command)
	})

	bus.Register(GetProfileSummaryCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(GetProfileSummaryCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid get profile summary command", ErrValidation)
		}
		return service.HandleGetProfileSummary(ctx, command)
	})

	bus.Register(UpsertProfileCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(UpsertProfileCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid upsert profile command", ErrValidation)
		}
		return service.HandleUpsertProfile(ctx, command)
	})
}

func RegisterStoreHandlers(bus *mediatr.Mediator, service *Service) {
	bus.Register(GetProfileDraftCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(GetProfileDraftCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid get profile draft command", ErrValidation)
		}
		return service.HandleGetProfileDraft(ctx, command)
	})
	bus.Register(PatchProfileDraftCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(PatchProfileDraftCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid patch profile draft command", ErrValidation)
		}
		return service.HandlePatchProfileDraft(ctx, command)
	})
	bus.Register(AddProfilePhotoCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(AddProfilePhotoCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid add profile photo command", ErrValidation)
		}
		return service.HandleAddProfilePhoto(ctx, command)
	})
	bus.Register(DeleteProfilePhotoCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(DeleteProfilePhotoCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid delete profile photo command", ErrValidation)
		}
		return service.HandleDeleteProfilePhoto(ctx, command)
	})
	bus.Register(ReorderProfilePhotosCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(ReorderProfilePhotosCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid reorder profile photos command", ErrValidation)
		}
		return service.HandleReorderProfilePhotos(ctx, command)
	})
	bus.Register(CompleteProfileCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(CompleteProfileCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid complete profile command", ErrValidation)
		}
		return service.HandleCompleteProfile(ctx, command)
	})
	bus.Register(GetSettingsCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(GetSettingsCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid get settings command", ErrValidation)
		}
		return service.HandleGetSettings(ctx, command)
	})
	bus.Register(PatchSettingsCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(PatchSettingsCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid patch settings command", ErrValidation)
		}
		return service.HandlePatchSettings(ctx, command)
	})
	bus.Register(ListEmergencyContactsCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(ListEmergencyContactsCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid list emergency contacts command", ErrValidation)
		}
		return service.HandleListEmergencyContacts(ctx, command)
	})
	bus.Register(AddEmergencyContactCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(AddEmergencyContactCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid add emergency contact command", ErrValidation)
		}
		return service.HandleAddEmergencyContact(ctx, command)
	})
	bus.Register(UpdateEmergencyContactCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(UpdateEmergencyContactCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid update emergency contact command", ErrValidation)
		}
		return service.HandleUpdateEmergencyContact(ctx, command)
	})
	bus.Register(DeleteEmergencyContactCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(DeleteEmergencyContactCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid delete emergency contact command", ErrValidation)
		}
		return service.HandleDeleteEmergencyContact(ctx, command)
	})
	bus.Register(ListBlockedUsersCommandName, func(ctx context.Context, request any) (any, error) {
		command, ok := request.(ListBlockedUsersCommand)
		if !ok {
			return nil, fmt.Errorf("%w: invalid list blocked users command", ErrValidation)
		}
		return service.HandleListBlockedUsers(ctx, command)
	})
}

func (s *Service) HandleGetProfile(ctx context.Context, command GetProfileCommand) (map[string]any, error) {
	userID := strings.TrimSpace(command.UserID)
	if userID == "" {
		return nil, fmt.Errorf("%w: user id is required", ErrValidation)
	}

	s.log.Info("profile_get_command")
	response, err := s.gateway.GetProfile(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("get profile failed: %w", err)
	}
	return response, nil
}

func (s *Service) HandleGetProfileSummary(ctx context.Context, command GetProfileSummaryCommand) (map[string]any, error) {
	userID := strings.TrimSpace(command.UserID)
	if userID == "" {
		return nil, fmt.Errorf("%w: user id is required", ErrValidation)
	}

	s.log.Info("profile_summary_command")
	response, err := s.gateway.GetProfileSummary(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("get profile summary failed: %w", err)
	}
	return response, nil
}

func (s *Service) HandleUpsertProfile(ctx context.Context, command UpsertProfileCommand) (map[string]any, error) {
	userID := strings.TrimSpace(command.UserID)
	if userID == "" {
		return nil, fmt.Errorf("%w: user id is required", ErrValidation)
	}

	profile := command.Profile
	if profile == nil {
		profile = map[string]any{}
	}
	profile["id"] = userID

	s.log.Info("profile_upsert_command")
	response, err := s.gateway.UpsertProfile(ctx, map[string]any{"profile": profile})
	if err != nil {
		return nil, fmt.Errorf("upsert profile failed: %w", err)
	}
	return response, nil
}

func (s *Service) HandleGetProfileDraft(ctx context.Context, command GetProfileDraftCommand) (map[string]any, error) {
	userID := strings.TrimSpace(command.UserID)
	if userID == "" {
		return nil, fmt.Errorf("%w: user id is required", ErrValidation)
	}
	draft, err := s.gateway.GetDraft(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("get profile draft failed: %w", err)
	}
	return map[string]any{"draft": draft}, nil
}

func (s *Service) HandlePatchProfileDraft(ctx context.Context, command PatchProfileDraftCommand) (map[string]any, error) {
	userID := strings.TrimSpace(command.UserID)
	if userID == "" {
		return nil, fmt.Errorf("%w: user id is required", ErrValidation)
	}
	payload := command.Payload
	if payload == nil {
		payload = map[string]any{}
	}
	draft, err := s.gateway.PatchDraft(ctx, userID, payload)
	if err != nil {
		return nil, fmt.Errorf("patch profile draft failed: %w", err)
	}
	return map[string]any{"draft": draft}, nil
}

func (s *Service) HandleAddProfilePhoto(ctx context.Context, command AddProfilePhotoCommand) (map[string]any, error) {
	userID := strings.TrimSpace(command.UserID)
	if userID == "" {
		return nil, fmt.Errorf("%w: user id is required", ErrValidation)
	}
	draft, err := s.gateway.AddPhoto(ctx, userID, strings.TrimSpace(command.PhotoURL))
	if err != nil {
		return nil, fmt.Errorf("add profile photo failed: %w", err)
	}
	return map[string]any{"draft": draft}, nil
}

func (s *Service) HandleDeleteProfilePhoto(ctx context.Context, command DeleteProfilePhotoCommand) (map[string]any, error) {
	userID := strings.TrimSpace(command.UserID)
	photoID := strings.TrimSpace(command.PhotoID)
	if userID == "" || photoID == "" {
		return nil, fmt.Errorf("%w: user id and photo id are required", ErrValidation)
	}
	draft, err := s.gateway.DeletePhoto(ctx, userID, photoID)
	if err != nil {
		return nil, fmt.Errorf("delete profile photo failed: %w", err)
	}
	return map[string]any{"draft": draft}, nil
}

func (s *Service) HandleReorderProfilePhotos(ctx context.Context, command ReorderProfilePhotosCommand) (map[string]any, error) {
	userID := strings.TrimSpace(command.UserID)
	if userID == "" {
		return nil, fmt.Errorf("%w: user id is required", ErrValidation)
	}
	if len(command.PhotoIDs) == 0 {
		return nil, fmt.Errorf("%w: photo_ids are required", ErrValidation)
	}
	draft, err := s.gateway.ReorderPhotos(ctx, userID, command.PhotoIDs)
	if err != nil {
		return nil, fmt.Errorf("reorder profile photos failed: %w", err)
	}
	return map[string]any{"draft": draft}, nil
}

func (s *Service) HandleCompleteProfile(ctx context.Context, command CompleteProfileCommand) (map[string]any, error) {
	userID := strings.TrimSpace(command.UserID)
	if userID == "" {
		return nil, fmt.Errorf("%w: user id is required", ErrValidation)
	}
	draft, err := s.gateway.CompleteProfile(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("complete profile failed: %w", err)
	}
	return map[string]any{"draft": draft, "success": true}, nil
}

func (s *Service) HandleGetSettings(ctx context.Context, command GetSettingsCommand) (map[string]any, error) {
	userID := strings.TrimSpace(command.UserID)
	if userID == "" {
		return nil, fmt.Errorf("%w: user id is required", ErrValidation)
	}
	settings, err := s.gateway.GetSettings(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("get settings failed: %w", err)
	}
	return map[string]any{"settings": settings}, nil
}

func (s *Service) HandlePatchSettings(ctx context.Context, command PatchSettingsCommand) (map[string]any, error) {
	userID := strings.TrimSpace(command.UserID)
	if userID == "" {
		return nil, fmt.Errorf("%w: user id is required", ErrValidation)
	}
	payload := command.Payload
	if payload == nil {
		payload = map[string]any{}
	}
	settings, err := s.gateway.PatchSettings(ctx, userID, payload)
	if err != nil {
		return nil, fmt.Errorf("patch settings failed: %w", err)
	}
	return map[string]any{"settings": settings}, nil
}

func (s *Service) HandleListEmergencyContacts(ctx context.Context, command ListEmergencyContactsCommand) (map[string]any, error) {
	userID := strings.TrimSpace(command.UserID)
	if userID == "" {
		return nil, fmt.Errorf("%w: user id is required", ErrValidation)
	}
	contacts, err := s.gateway.ListEmergencyContacts(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("list emergency contacts failed: %w", err)
	}
	return map[string]any{"contacts": contacts}, nil
}

func (s *Service) HandleAddEmergencyContact(ctx context.Context, command AddEmergencyContactCommand) (map[string]any, error) {
	userID := strings.TrimSpace(command.UserID)
	name := strings.TrimSpace(command.Name)
	phoneNumber := strings.TrimSpace(command.PhoneNumber)
	if userID == "" {
		return nil, fmt.Errorf("%w: user id is required", ErrValidation)
	}
	if name == "" || phoneNumber == "" {
		return nil, fmt.Errorf("%w: name and phone_number are required", ErrValidation)
	}
	contacts, err := s.gateway.AddEmergencyContact(ctx, userID, name, phoneNumber)
	if err != nil {
		return nil, fmt.Errorf("add emergency contact failed: %w", err)
	}
	return map[string]any{"contacts": contacts}, nil
}

func (s *Service) HandleUpdateEmergencyContact(ctx context.Context, command UpdateEmergencyContactCommand) (map[string]any, error) {
	userID := strings.TrimSpace(command.UserID)
	contactID := strings.TrimSpace(command.ContactID)
	name := strings.TrimSpace(command.Name)
	phoneNumber := strings.TrimSpace(command.PhoneNumber)
	if userID == "" || contactID == "" {
		return nil, fmt.Errorf("%w: user id and contact id are required", ErrValidation)
	}
	if name == "" || phoneNumber == "" {
		return nil, fmt.Errorf("%w: name and phone_number are required", ErrValidation)
	}
	contacts, err := s.gateway.UpdateEmergencyContact(ctx, userID, contactID, name, phoneNumber)
	if err != nil {
		return nil, fmt.Errorf("update emergency contact failed: %w", err)
	}
	return map[string]any{"contacts": contacts}, nil
}

func (s *Service) HandleDeleteEmergencyContact(ctx context.Context, command DeleteEmergencyContactCommand) (map[string]any, error) {
	userID := strings.TrimSpace(command.UserID)
	contactID := strings.TrimSpace(command.ContactID)
	if userID == "" || contactID == "" {
		return nil, fmt.Errorf("%w: user id and contact id are required", ErrValidation)
	}
	contacts, err := s.gateway.DeleteEmergencyContact(ctx, userID, contactID)
	if err != nil {
		return nil, fmt.Errorf("delete emergency contact failed: %w", err)
	}
	return map[string]any{"contacts": contacts}, nil
}

func (s *Service) HandleListBlockedUsers(ctx context.Context, command ListBlockedUsersCommand) (map[string]any, error) {
	userID := strings.TrimSpace(command.UserID)
	if userID == "" {
		return nil, fmt.Errorf("%w: user id is required", ErrValidation)
	}
	blocked, err := s.gateway.ListBlockedUsers(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("list blocked users failed: %w", err)
	}
	return map[string]any{"blocked_users": blocked}, nil
}
