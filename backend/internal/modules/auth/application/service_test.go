package application

import (
	"context"
	"errors"
	"testing"

	"go.uber.org/zap"
)

type mockGateway struct {
	loginResponse  map[string]any
	signupResponse map[string]any
	lastUsername   string
	lastPassword   string
}

func (m *mockGateway) Login(_ context.Context, username, password string) (map[string]any, error) {
	m.lastUsername, m.lastPassword = username, password
	return m.loginResponse, nil
}

func (m *mockGateway) Signup(_ context.Context, username, password string) (map[string]any, error) {
	m.lastUsername, m.lastPassword = username, password
	return m.signupResponse, nil
}

func TestHandleLoginNormalizesUsername(t *testing.T) {
	gateway := &mockGateway{loginResponse: map[string]any{"success": true}}
	service := NewService(gateway, zap.NewNop())
	response, err := service.HandleLogin(context.Background(), LoginCommand{
		Username: " User.Name ", Password: "secret",
	})
	if err != nil || response["success"] != true || gateway.lastUsername != "user.name" {
		t.Fatalf("unexpected login response=%v username=%q error=%v", response, gateway.lastUsername, err)
	}
}

func TestHandleSignupValidatesUsernameAndPassword(t *testing.T) {
	service := NewService(&mockGateway{}, zap.NewNop())
	for _, command := range []SignupCommand{
		{Username: "bad name", Password: "Password123"},
		{Username: "valid_name", Password: "short"},
	} {
		_, err := service.HandleSignup(context.Background(), command)
		if err == nil || !errors.Is(err, ErrValidation) {
			t.Fatalf("expected validation error for %+v, got %v", command, err)
		}
	}
}

func TestHandleSignupSuccess(t *testing.T) {
	gateway := &mockGateway{signupResponse: map[string]any{"success": true}}
	service := NewService(gateway, zap.NewNop())
	response, err := service.HandleSignup(context.Background(), SignupCommand{
		Username: "New_User", Password: "Password123",
	})
	if err != nil || response["success"] != true || gateway.lastUsername != "new_user" {
		t.Fatalf("unexpected signup response=%v username=%q error=%v", response, gateway.lastUsername, err)
	}
}
