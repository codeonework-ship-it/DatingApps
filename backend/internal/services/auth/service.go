package auth

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"sync"

	"github.com/google/uuid"
	"go.uber.org/zap"
	"google.golang.org/protobuf/types/known/structpb"

	"github.com/verified-dating/backend/internal/platform/config"
	"github.com/verified-dating/backend/internal/platform/observability"
)

type Repository interface {
	Login(context.Context, string, string) (map[string]any, error)
	Signup(context.Context, string, string) (map[string]any, error)
}

type mockCredential struct {
	password string
	userID   string
}

type SupabaseRepository struct {
	cfg        config.Config
	log        *zap.Logger
	httpClient *http.Client
	mockMu     sync.Mutex
	mockUsers  map[string]mockCredential
}

func NewRepository(cfg config.Config, log *zap.Logger) Repository {
	if cfg.UseLocalDB {
		return NewPostgresRepository(cfg, log)
	}
	return &SupabaseRepository{
		cfg:        cfg,
		log:        log,
		httpClient: &http.Client{Timeout: cfg.AuthHTTPTimeout()},
		mockUsers:  make(map[string]mockCredential),
	}
}

type Service struct {
	repo Repository
	log  *zap.Logger
}

func NewService(repo Repository, log *zap.Logger) *Service {
	return &Service{repo: repo, log: log}
}

func (s *Service) Login(ctx context.Context, req *structpb.Struct) (*structpb.Struct, error) {
	username, password := credentials(req)
	s.log.Info("auth_login_requested", zap.String("username_ref", observability.PseudonymizeIdentifier(username)))
	if username == "" || password == "" {
		return structpb.NewStruct(map[string]any{
			"success": false,
			"error":   "username and password are required",
		})
	}
	out, err := s.repo.Login(ctx, username, password)
	if err != nil {
		s.log.Error("auth_login_failed", zap.String("username_ref", observability.PseudonymizeIdentifier(username)), zap.Error(err))
		return nil, err
	}
	return structpb.NewStruct(out)
}

func (s *Service) Signup(ctx context.Context, req *structpb.Struct) (*structpb.Struct, error) {
	username, password := credentials(req)
	s.log.Info("auth_signup_requested", zap.String("username_ref", observability.PseudonymizeIdentifier(username)))
	if username == "" || password == "" {
		return structpb.NewStruct(map[string]any{
			"success": false,
			"error":   "username and password are required",
		})
	}
	var out map[string]any
	var err error
	kind, _ := req.AsMap()["account_kind"].(string)
	if kind != "" && kind != "dating" {
		repo, ok := s.repo.(interface {
			SignupIntroducer(context.Context, string, string, string, string) (map[string]any, error)
		})
		if kind != "introducer" || !ok {
			return structpb.NewStruct(map[string]any{"success": false, "error": "account type is unavailable"})
		}
		name, _ := req.AsMap()["name"].(string)
		dob, _ := req.AsMap()["date_of_birth"].(string)
		out, err = repo.SignupIntroducer(ctx, username, password, name, dob)
	} else {
		out, err = s.repo.Signup(ctx, username, password)
	}
	if err != nil {
		s.log.Error("auth_signup_failed", zap.String("username_ref", observability.PseudonymizeIdentifier(username)), zap.Error(err))
		return nil, err
	}
	return structpb.NewStruct(out)
}

func credentials(req *structpb.Struct) (string, string) {
	payload := req.AsMap()
	username, _ := payload["username"].(string)
	password, _ := payload["password"].(string)
	return strings.ToLower(strings.TrimSpace(username)), password
}

func (r *SupabaseRepository) Login(ctx context.Context, username, password string) (map[string]any, error) {
	username = strings.ToLower(strings.TrimSpace(username))
	if r.cfg.MockAuthEnabled {
		return r.mockLogin(username, password), nil
	}
	return r.passwordGrant(ctx, username, password)
}

func (r *SupabaseRepository) Signup(ctx context.Context, username, password string) (map[string]any, error) {
	username = strings.ToLower(strings.TrimSpace(username))
	if r.cfg.MockAuthEnabled {
		return r.mockSignup(username, password), nil
	}

	email := internalEmail(username)
	body := map[string]any{
		"email":    email,
		"password": password,
		"user_metadata": map[string]any{
			"username": username,
		},
	}
	endpoint := r.cfg.SupabaseURL + "/auth/v1/signup"
	authorization := r.cfg.SupabaseAnonKey
	if serviceRole := strings.TrimSpace(r.cfg.SupabaseServiceRole); serviceRole != "" {
		endpoint = r.cfg.SupabaseURL + "/auth/v1/admin/users"
		authorization = serviceRole
		body["email_confirm"] = true
	}

	status, decoded, raw, err := r.authRequest(ctx, endpoint, authorization, body)
	if err != nil {
		return nil, err
	}
	if status < 200 || status >= 300 {
		message := upstreamAuthError(raw, "username is already taken")
		if status == http.StatusUnprocessableEntity || status == http.StatusConflict {
			message = "username is already taken"
		}
		return map[string]any{"success": false, "error": message}, nil
	}

	// Admin creation does not return a session, so authenticate immediately.
	if strings.TrimSpace(r.cfg.SupabaseServiceRole) != "" {
		return r.passwordGrant(ctx, username, password)
	}
	return sessionResponse(decoded), nil
}

func (r *SupabaseRepository) passwordGrant(ctx context.Context, username, password string) (map[string]any, error) {
	endpoint := r.cfg.SupabaseURL + "/auth/v1/token?grant_type=password"
	status, decoded, raw, err := r.authRequest(ctx, endpoint, r.cfg.SupabaseAnonKey, map[string]any{
		"email":    internalEmail(username),
		"password": password,
	})
	if err != nil {
		return nil, err
	}
	if status < 200 || status >= 300 {
		return map[string]any{
			"success": false,
			"error":   upstreamAuthError(raw, "invalid username or password"),
		}, nil
	}
	return sessionResponse(decoded), nil
}

func (r *SupabaseRepository) authRequest(
	ctx context.Context,
	endpoint string,
	authorization string,
	payload map[string]any,
) (int, map[string]any, []byte, error) {
	body, _ := json.Marshal(payload)
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, endpoint, bytes.NewReader(body))
	if err != nil {
		return 0, nil, nil, err
	}
	req.Header.Set("apikey", r.cfg.SupabaseAnonKey)
	req.Header.Set("Authorization", "Bearer "+authorization)
	req.Header.Set("Content-Type", "application/json")
	resp, err := r.httpClient.Do(req)
	if err != nil {
		return 0, nil, nil, err
	}
	defer resp.Body.Close()
	raw, _ := io.ReadAll(resp.Body)
	decoded := map[string]any{}
	if len(raw) > 0 {
		if err := json.Unmarshal(raw, &decoded); err != nil && resp.StatusCode >= 200 && resp.StatusCode < 300 {
			return resp.StatusCode, nil, raw, fmt.Errorf("decode auth response: %w", err)
		}
	}
	return resp.StatusCode, decoded, raw, nil
}

func (r *SupabaseRepository) mockLogin(username, password string) map[string]any {
	r.mockMu.Lock()
	defer r.mockMu.Unlock()
	if username == r.cfg.MockAuthUsername && password == r.cfg.MockAuthPassword {
		return mockSession(r.cfg.MockUserID, r.cfg.MockAccessToken, r.cfg.MockRefreshToken)
	}
	credential, ok := r.mockUsers[username]
	if !ok || credential.password != password {
		return map[string]any{"success": false, "error": "invalid username or password"}
	}
	return mockSession(credential.userID, "mock-access-"+credential.userID, "mock-refresh-"+credential.userID)
}

func (r *SupabaseRepository) mockSignup(username, password string) map[string]any {
	r.mockMu.Lock()
	defer r.mockMu.Unlock()
	if username == r.cfg.MockAuthUsername {
		return map[string]any{"success": false, "error": "username is already taken"}
	}
	if r.mockUsers == nil {
		r.mockUsers = make(map[string]mockCredential)
	}
	if _, exists := r.mockUsers[username]; exists {
		return map[string]any{"success": false, "error": "username is already taken"}
	}
	userID := uuid.NewSHA1(uuid.NameSpaceURL, []byte("username:"+username)).String()
	r.mockUsers[username] = mockCredential{password: password, userID: userID}
	return mockSession(userID, "mock-access-"+userID, "mock-refresh-"+userID)
}

func mockSession(userID, accessToken, refreshToken string) map[string]any {
	return map[string]any{
		"success":          true,
		"user_id":          userID,
		"access_token":     accessToken,
		"refresh_token":    refreshToken,
		"workflow_state":   "completed",
		"current_activity": "done",
		"signup_required":  false,
	}
}

func sessionResponse(decoded map[string]any) map[string]any {
	user, _ := decoded["user"].(map[string]any)
	userID, _ := user["id"].(string)
	accessToken, _ := decoded["access_token"].(string)
	refreshToken, _ := decoded["refresh_token"].(string)
	if accessToken == "" || userID == "" {
		return map[string]any{
			"success": false,
			"error":   "account created without an active session; verify the auth provider configuration",
		}
	}
	return map[string]any{
		"success":       true,
		"user_id":       userID,
		"access_token":  accessToken,
		"refresh_token": refreshToken,
	}
}

func internalEmail(username string) string {
	return strings.ToLower(strings.TrimSpace(username)) + "@username.local"
}

func upstreamAuthError(body []byte, fallback string) string {
	if len(body) == 0 {
		return fallback
	}
	var upstream map[string]any
	if err := json.Unmarshal(body, &upstream); err != nil {
		return fallback
	}
	for _, key := range []string{"msg", "error_description", "error", "message"} {
		if message, ok := upstream[key].(string); ok && strings.TrimSpace(message) != "" {
			return strings.TrimSpace(message)
		}
	}
	return fallback
}
