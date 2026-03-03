package auth

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"

	"github.com/google/uuid"
	"go.uber.org/zap"
	"google.golang.org/protobuf/types/known/structpb"

	"github.com/verified-dating/backend/internal/platform/config"
)

type Repository interface {
	SendOTP(context.Context, string) (map[string]any, error)
	VerifyOTP(context.Context, string, string) (map[string]any, error)
}

type SupabaseRepository struct {
	cfg        config.Config
	log        *zap.Logger
	httpClient *http.Client
}

func NewRepository(cfg config.Config, log *zap.Logger) Repository {
	return &SupabaseRepository{
		cfg:        cfg,
		log:        log,
		httpClient: &http.Client{Timeout: cfg.AuthHTTPTimeout()},
	}
}

type Service struct {
	repo Repository
	log  *zap.Logger
}

func NewService(repo Repository, log *zap.Logger) *Service {
	return &Service{repo: repo, log: log}
}

func (s *Service) SendOtp(ctx context.Context, req *structpb.Struct) (*structpb.Struct, error) {
	payload := req.AsMap()
	email, _ := payload["email"].(string)
	if strings.TrimSpace(email) == "" {
		email, _ = payload["phone"].(string)
	}
	email = strings.TrimSpace(strings.ToLower(email))
	s.log.Info("auth_send_otp_requested", zap.String("email", email))
	if email == "" {
		return structpb.NewStruct(map[string]any{
			"accepted": false,
			"error":    "email is required",
		})
	}

	out, err := s.repo.SendOTP(ctx, email)
	if err != nil {
		s.log.Error("auth_send_otp_failed", zap.String("email", email), zap.Error(err))
		return nil, err
	}
	s.log.Info("auth_send_otp_completed", zap.String("email", email))
	return structpb.NewStruct(out)
}

func (s *Service) VerifyOtp(ctx context.Context, req *structpb.Struct) (*structpb.Struct, error) {
	payload := req.AsMap()
	email, _ := payload["email"].(string)
	if strings.TrimSpace(email) == "" {
		email, _ = payload["phone"].(string)
	}
	otp, _ := payload["otp"].(string)
	email = strings.TrimSpace(strings.ToLower(email))
	otp = strings.TrimSpace(otp)
	s.log.Info("auth_verify_otp_requested", zap.String("email", email))

	if email == "" || otp == "" {
		return structpb.NewStruct(map[string]any{
			"success": false,
			"error":   "email and otp are required",
		})
	}

	out, err := s.repo.VerifyOTP(ctx, email, otp)
	if err != nil {
		s.log.Error("auth_verify_otp_failed", zap.String("email", email), zap.Error(err))
		return nil, err
	}
	s.log.Info("auth_verify_otp_completed", zap.String("email", email))
	return structpb.NewStruct(out)
}

func (r *SupabaseRepository) SendOTP(ctx context.Context, email string) (map[string]any, error) {
	correlationID := uuid.NewString()
	if r.cfg.MockOTPEnabled {
		r.log.Info(
			"auth_send_otp_mock",
			zap.String("email", email),
			zap.String("correlation_id", correlationID),
		)
		return map[string]any{
			"accepted":       true,
			"correlation_id": correlationID,
			"mock_otp":       r.cfg.MockOTPCode,
		}, nil
	}

	body, _ := json.Marshal(map[string]any{
		"email":       email,
		"create_user": true,
	})

	reqHTTP, err := http.NewRequestWithContext(
		ctx,
		http.MethodPost,
		r.cfg.SupabaseURL+"/auth/v1/otp",
		bytes.NewReader(body),
	)
	if err != nil {
		return nil, err
	}
	reqHTTP.Header.Set("apikey", r.cfg.SupabaseAnonKey)
	reqHTTP.Header.Set("Authorization", "Bearer "+r.cfg.SupabaseAnonKey)
	reqHTTP.Header.Set("Content-Type", "application/json")

	resp, err := r.httpClient.Do(reqHTTP)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	resBody, _ := io.ReadAll(resp.Body)
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		errorMessage := "failed to send otp"
		if len(resBody) > 0 {
			var upstream map[string]any
			if err := json.Unmarshal(resBody, &upstream); err == nil {
				if msg, ok := upstream["msg"].(string); ok && strings.TrimSpace(msg) != "" {
					errorMessage = strings.TrimSpace(msg)
				} else if msg, ok := upstream["error_description"].(string); ok && strings.TrimSpace(msg) != "" {
					errorMessage = strings.TrimSpace(msg)
				} else if msg, ok := upstream["error"].(string); ok && strings.TrimSpace(msg) != "" {
					errorMessage = strings.TrimSpace(msg)
				}
			}
		}
		r.log.Warn(
			"auth_send_otp_failed",
			zap.Int("status", resp.StatusCode),
			zap.ByteString("body", resBody),
		)
		return map[string]any{
			"accepted": false,
			"error":    errorMessage,
		}, nil
	}

	return map[string]any{
		"accepted":       true,
		"correlation_id": correlationID,
	}, nil
}

func (r *SupabaseRepository) VerifyOTP(ctx context.Context, email, otp string) (map[string]any, error) {
	if r.cfg.MockOTPEnabled {
		expected := strings.TrimSpace(r.cfg.MockOTPCode)
		ok := len(otp) == 6 && (expected == "" || otp == expected)
		return map[string]any{
			"success":       ok,
			"access_token":  r.cfg.MockAccessToken,
			"refresh_token": r.cfg.MockRefreshToken,
			"user_id":       r.cfg.MockUserID,
		}, nil
	}

	body, _ := json.Marshal(map[string]any{
		"type":  "email",
		"email": email,
		"token": otp,
	})

	reqHTTP, err := http.NewRequestWithContext(
		ctx,
		http.MethodPost,
		r.cfg.SupabaseURL+"/auth/v1/verify",
		bytes.NewReader(body),
	)
	if err != nil {
		return nil, err
	}
	reqHTTP.Header.Set("apikey", r.cfg.SupabaseAnonKey)
	reqHTTP.Header.Set("Authorization", "Bearer "+r.cfg.SupabaseAnonKey)
	reqHTTP.Header.Set("Content-Type", "application/json")

	resp, err := r.httpClient.Do(reqHTTP)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	resBody, _ := io.ReadAll(resp.Body)
	if resp.StatusCode < 200 || resp.StatusCode >= 299 {
		r.log.Warn(
			"auth_verify_otp_failed",
			zap.Int("status", resp.StatusCode),
			zap.ByteString("body", resBody),
		)
		return map[string]any{"success": false, "error": "invalid otp"}, nil
	}

	var decoded map[string]any
	if err := json.Unmarshal(resBody, &decoded); err != nil {
		return nil, fmt.Errorf("decode verify response: %w", err)
	}

	session, _ := decoded["session"].(map[string]any)
	user, _ := decoded["user"].(map[string]any)
	userID, _ := user["id"].(string)
	accessToken, _ := session["access_token"].(string)
	refreshToken, _ := session["refresh_token"].(string)

	return map[string]any{
		"success":       accessToken != "",
		"access_token":  accessToken,
		"refresh_token": refreshToken,
		"user_id":       userID,
	}, nil
}
