package auth

import (
	"context"
	"testing"

	"go.uber.org/zap"
	"google.golang.org/protobuf/types/known/structpb"
)

type fakeRepository struct {
	sendOut map[string]any
	sendErr error

	verifyOut map[string]any
	verifyErr error

	sendCalls   int
	verifyCalls int
}

func (f *fakeRepository) SendOTP(_ context.Context, _ string) (map[string]any, error) {
	f.sendCalls++
	return f.sendOut, f.sendErr
}

func (f *fakeRepository) VerifyOTP(_ context.Context, _, _ string) (map[string]any, error) {
	f.verifyCalls++
	return f.verifyOut, f.verifyErr
}

func TestService_SendOtp_ValidatesInput(t *testing.T) {
	repo := &fakeRepository{}
	svc := NewService(repo, zap.NewNop())

	req, err := structpb.NewStruct(map[string]any{"email": "   "})
	if err != nil {
		t.Fatalf("structpb.NewStruct error: %v", err)
	}

	resp, err := svc.SendOtp(context.Background(), req)
	if err != nil {
		t.Fatalf("SendOtp error = %v", err)
	}

	got := resp.AsMap()
	if got["accepted"] != false {
		t.Fatalf("expected accepted=false, got %v", got["accepted"])
	}
	if repo.sendCalls != 0 {
		t.Fatalf("expected repo not to be called")
	}
}

func TestService_VerifyOtp_ValidatesInput(t *testing.T) {
	repo := &fakeRepository{}
	svc := NewService(repo, zap.NewNop())

	req, err := structpb.NewStruct(map[string]any{"email": "", "otp": ""})
	if err != nil {
		t.Fatalf("structpb.NewStruct error: %v", err)
	}

	resp, err := svc.VerifyOtp(context.Background(), req)
	if err != nil {
		t.Fatalf("VerifyOtp error = %v", err)
	}

	got := resp.AsMap()
	if got["success"] != false {
		t.Fatalf("expected success=false, got %v", got["success"])
	}
	if repo.verifyCalls != 0 {
		t.Fatalf("expected repo not to be called")
	}
}

func TestService_SendOtp_PassesRepositoryResponse(t *testing.T) {
	repo := &fakeRepository{
		sendOut: map[string]any{
			"accepted":       true,
			"correlation_id": "cid-1",
		},
	}
	svc := NewService(repo, zap.NewNop())

	req, err := structpb.NewStruct(map[string]any{"email": "test@example.com"})
	if err != nil {
		t.Fatalf("structpb.NewStruct error: %v", err)
	}

	resp, err := svc.SendOtp(context.Background(), req)
	if err != nil {
		t.Fatalf("SendOtp error = %v", err)
	}

	got := resp.AsMap()
	if got["accepted"] != true {
		t.Fatalf("expected accepted=true, got %v", got["accepted"])
	}
	if got["correlation_id"] != "cid-1" {
		t.Fatalf("expected correlation id cid-1, got %v", got["correlation_id"])
	}
}

func TestService_VerifyOtp_PassesRepositoryResponse(t *testing.T) {
	repo := &fakeRepository{
		verifyOut: map[string]any{
			"success":      true,
			"user_id":      "user-1",
			"access_token": "token-1",
		},
	}
	svc := NewService(repo, zap.NewNop())

	req, err := structpb.NewStruct(map[string]any{"email": "test@example.com", "otp": "123456"})
	if err != nil {
		t.Fatalf("structpb.NewStruct error: %v", err)
	}

	resp, err := svc.VerifyOtp(context.Background(), req)
	if err != nil {
		t.Fatalf("VerifyOtp error = %v", err)
	}

	got := resp.AsMap()
	if got["success"] != true {
		t.Fatalf("expected success=true, got %v", got["success"])
	}
	if got["user_id"] != "user-1" {
		t.Fatalf("expected user_id user-1, got %v", got["user_id"])
	}
}
