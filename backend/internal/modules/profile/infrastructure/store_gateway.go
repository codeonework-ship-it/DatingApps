package infrastructure

import (
	"context"
	"encoding/json"
	"errors"
)

type StoreGateway struct {
	getDraft               func(string) any
	patchDraft             func(string, map[string]any) any
	addPhoto               func(string, string) any
	deletePhoto            func(string, string) any
	reorderPhotos          func(string, []string) any
	completeProfile        func(string) (any, error)
	getSettings            func(string) any
	patchSettings          func(string, map[string]any) any
	listEmergencyContacts  func(string) any
	addEmergencyContact    func(string, string, string) (any, error)
	updateEmergencyContact func(string, string, string, string) (any, error)
	deleteEmergencyContact func(string, string) any
	listBlockedUsers       func(string) any
}

func NewStoreGateway(
	getDraft func(string) any,
	patchDraft func(string, map[string]any) any,
	addPhoto func(string, string) any,
	deletePhoto func(string, string) any,
	reorderPhotos func(string, []string) any,
	completeProfile func(string) (any, error),
	getSettings func(string) any,
	patchSettings func(string, map[string]any) any,
	listEmergencyContacts func(string) any,
	addEmergencyContact func(string, string, string) (any, error),
	updateEmergencyContact func(string, string, string, string) (any, error),
	deleteEmergencyContact func(string, string) any,
	listBlockedUsers func(string) any,
) *StoreGateway {
	return &StoreGateway{
		getDraft:               getDraft,
		patchDraft:             patchDraft,
		addPhoto:               addPhoto,
		deletePhoto:            deletePhoto,
		reorderPhotos:          reorderPhotos,
		completeProfile:        completeProfile,
		getSettings:            getSettings,
		patchSettings:          patchSettings,
		listEmergencyContacts:  listEmergencyContacts,
		addEmergencyContact:    addEmergencyContact,
		updateEmergencyContact: updateEmergencyContact,
		deleteEmergencyContact: deleteEmergencyContact,
		listBlockedUsers:       listBlockedUsers,
	}
}

func (g *StoreGateway) GetDraft(_ context.Context, userID string) (map[string]any, error) {
	return toMap(g.getDraft(userID))
}

func (g *StoreGateway) GetProfile(context.Context, string) (map[string]any, error) {
	return nil, errors.New("profile grpc method not supported by store gateway")
}

func (g *StoreGateway) GetProfileSummary(context.Context, string) (map[string]any, error) {
	return nil, errors.New("profile grpc method not supported by store gateway")
}

func (g *StoreGateway) UpsertProfile(context.Context, map[string]any) (map[string]any, error) {
	return nil, errors.New("profile grpc method not supported by store gateway")
}

func (g *StoreGateway) PatchDraft(_ context.Context, userID string, payload map[string]any) (map[string]any, error) {
	return toMap(g.patchDraft(userID, payload))
}

func (g *StoreGateway) AddPhoto(_ context.Context, userID, photoURL string) (map[string]any, error) {
	return toMap(g.addPhoto(userID, photoURL))
}

func (g *StoreGateway) DeletePhoto(_ context.Context, userID, photoID string) (map[string]any, error) {
	return toMap(g.deletePhoto(userID, photoID))
}

func (g *StoreGateway) ReorderPhotos(_ context.Context, userID string, photoIDs []string) (map[string]any, error) {
	return toMap(g.reorderPhotos(userID, photoIDs))
}

func (g *StoreGateway) CompleteProfile(_ context.Context, userID string) (map[string]any, error) {
	out, err := g.completeProfile(userID)
	if err != nil {
		return nil, err
	}
	return toMap(out)
}

func (g *StoreGateway) GetSettings(_ context.Context, userID string) (map[string]any, error) {
	return toMap(g.getSettings(userID))
}

func (g *StoreGateway) PatchSettings(_ context.Context, userID string, payload map[string]any) (map[string]any, error) {
	return toMap(g.patchSettings(userID, payload))
}

func (g *StoreGateway) ListEmergencyContacts(_ context.Context, userID string) ([]map[string]any, error) {
	return toMapSlice(g.listEmergencyContacts(userID))
}

func (g *StoreGateway) AddEmergencyContact(
	_ context.Context,
	userID, name, phoneNumber string,
) ([]map[string]any, error) {
	items, err := g.addEmergencyContact(userID, name, phoneNumber)
	if err != nil {
		return nil, err
	}
	return toMapSlice(items)
}

func (g *StoreGateway) UpdateEmergencyContact(
	_ context.Context,
	userID, contactID, name, phoneNumber string,
) ([]map[string]any, error) {
	items, err := g.updateEmergencyContact(userID, contactID, name, phoneNumber)
	if err != nil {
		return nil, err
	}
	return toMapSlice(items)
}

func (g *StoreGateway) DeleteEmergencyContact(_ context.Context, userID, contactID string) ([]map[string]any, error) {
	return toMapSlice(g.deleteEmergencyContact(userID, contactID))
}

func (g *StoreGateway) ListBlockedUsers(_ context.Context, userID string) ([]map[string]any, error) {
	return toMapSlice(g.listBlockedUsers(userID))
}

func toMap(value any) (map[string]any, error) {
	data, err := json.Marshal(value)
	if err != nil {
		return nil, err
	}
	var out map[string]any
	if err := json.Unmarshal(data, &out); err != nil {
		return nil, err
	}
	if out == nil {
		out = map[string]any{}
	}
	return out, nil
}

func toMapSlice(value any) ([]map[string]any, error) {
	data, err := json.Marshal(value)
	if err != nil {
		return nil, err
	}
	var out []map[string]any
	if err := json.Unmarshal(data, &out); err != nil {
		return nil, err
	}
	if out == nil {
		out = []map[string]any{}
	}
	return out, nil
}
