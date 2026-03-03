package application

import (
	"context"
	"errors"
	"strings"
	"testing"

	"go.uber.org/zap"
)

type mockGateway struct {
	sendOTPResponse    map[string]any
	verifyOTPResponse  map[string]any
	sendOTPErr         error
	verifyOTPErr       error
	lastSendOTPEmail   string
	lastVerifyOTPEmail string
	lastVerifyOTPCode  string
}

func (m *mockGateway) SendOTP(_ context.Context, email string) (map[string]any, error) {
	m.lastSendOTPEmail = email
	if m.sendOTPErr != nil {
		return nil, m.sendOTPErr
	}
	return m.sendOTPResponse, nil
}

func (m *mockGateway) VerifyOTP(_ context.Context, email, otp string) (map[string]any, error) {
	m.lastVerifyOTPEmail = email
	m.lastVerifyOTPCode = otp
	if m.verifyOTPErr != nil {
		return nil, m.verifyOTPErr
	}
	return m.verifyOTPResponse, nil
}

func TestHandleSendOTPValidation(t *testing.T) {
	service := NewService(&mockGateway{}, zap.NewNop())

	_, err := service.HandleSendOTP(context.Background(), SendOTPCommand{Email: "invalid"})
	if err == nil {
		t.Fatal("expected validation error")
	}
	if !errors.Is(err, ErrValidation) {
		t.Fatalf("expected ErrValidation, got %v", err)
	}
}

func TestHandleSendOTPSuccess(t *testing.T) {
	gateway := &mockGateway{sendOTPResponse: map[string]any{"accepted": true}}
	service := NewService(gateway, zap.NewNop())

	response, err := service.HandleSendOTP(context.Background(), SendOTPCommand{Email: " Test.User@Example.com "})
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}
	if gateway.lastSendOTPEmail != "test.user@example.com" {
		t.Fatalf("expected normalized email to be sent, got %s", gateway.lastSendOTPEmail)
	}
	if accepted, _ := response["accepted"].(bool); !accepted {
		t.Fatalf("expected accepted=true response, got %v", response)
	}
}

func TestHandleVerifyOTPValidation(t *testing.T) {
	service := NewService(&mockGateway{}, zap.NewNop())

	_, err := service.HandleVerifyOTP(context.Background(), VerifyOTPCommand{Email: "test@example.com", OTP: "12"})
	if err == nil {
		t.Fatal("expected validation error")
	}
	if !errors.Is(err, ErrValidation) {
		t.Fatalf("expected ErrValidation, got %v", err)
	}
}

func TestHandleVerifyOTPGatewayError(t *testing.T) {
	gateway := &mockGateway{verifyOTPErr: errors.New("upstream failed")}
	service := NewService(gateway, zap.NewNop())

	_, err := service.HandleVerifyOTP(context.Background(), VerifyOTPCommand{Email: "test@example.com", OTP: "123456"})
	if err == nil {
		t.Fatal("expected gateway error")
	}
	if !strings.Contains(err.Error(), "verify otp failed") {
		t.Fatalf("expected wrapped verify otp error, got %v", err)
	}
}
