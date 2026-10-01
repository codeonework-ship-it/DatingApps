package auth

import (
	"context"
	"testing"

	"go.uber.org/zap"
	"google.golang.org/protobuf/types/known/structpb"

	"github.com/verified-dating/backend/internal/platform/config"
)

func TestSupabaseRepository_MockSignupAndLogin(t *testing.T) {
	repo := &SupabaseRepository{
		cfg: config.Config{
			MockAuthEnabled:  true,
			MockAuthUsername: "qa_user",
			MockAuthPassword: "Password123!",
			MockAccessToken:  "access-1",
			MockRefreshToken: "refresh-1",
			MockUserID:       "user-1",
		},
		log:       zap.NewNop(),
		mockUsers: make(map[string]mockCredential),
	}

	created, err := repo.Signup(context.Background(), "new_user", "Secure123")
	if err != nil || created["success"] != true {
		t.Fatalf("expected mock signup success, response=%v error=%v", created, err)
	}
	duplicate, _ := repo.Signup(context.Background(), "new_user", "Secure123")
	if duplicate["success"] != false || duplicate["error"] != "username is already taken" {
		t.Fatalf("expected duplicate username rejection, got %v", duplicate)
	}
	loggedIn, err := repo.Login(context.Background(), "NEW_USER", "Secure123")
	if err != nil || loggedIn["success"] != true || loggedIn["user_id"] != created["user_id"] {
		t.Fatalf("expected login for created username, response=%v error=%v", loggedIn, err)
	}
}

type fakeRepository struct {
	loginOut    map[string]any
	signupOut   map[string]any
	loginCalls  int
	signupCalls int
}

func (f *fakeRepository) Login(_ context.Context, _, _ string) (map[string]any, error) {
	f.loginCalls++
	return f.loginOut, nil
}

func (f *fakeRepository) Signup(_ context.Context, _, _ string) (map[string]any, error) {
	f.signupCalls++
	return f.signupOut, nil
}

func TestServiceCredentialOperations(t *testing.T) {
	repo := &fakeRepository{
		loginOut:  map[string]any{"success": true, "user_id": "user-1"},
		signupOut: map[string]any{"success": true, "user_id": "user-2"},
	}
	svc := NewService(repo, zap.NewNop())

	loginReq, _ := structpb.NewStruct(map[string]any{"username": "User.Name", "password": "Password123"})
	loginResp, err := svc.Login(context.Background(), loginReq)
	if err != nil || loginResp.AsMap()["success"] != true || repo.loginCalls != 1 {
		t.Fatalf("unexpected login result response=%v calls=%d error=%v", loginResp, repo.loginCalls, err)
	}

	signupReq, _ := structpb.NewStruct(map[string]any{"username": "new_user", "password": "Password123"})
	signupResp, err := svc.Signup(context.Background(), signupReq)
	if err != nil || signupResp.AsMap()["success"] != true || repo.signupCalls != 1 {
		t.Fatalf("unexpected signup result response=%v calls=%d error=%v", signupResp, repo.signupCalls, err)
	}
}

func TestServiceRejectsMissingCredentials(t *testing.T) {
	repo := &fakeRepository{}
	svc := NewService(repo, zap.NewNop())
	req, _ := structpb.NewStruct(map[string]any{"username": "", "password": ""})
	resp, err := svc.Login(context.Background(), req)
	if err != nil || resp.AsMap()["success"] != false || repo.loginCalls != 0 {
		t.Fatalf("expected validation failure without repository call")
	}
}
