package profile

import (
	"context"
	"fmt"
	"net/url"
	"strings"

	"go.uber.org/zap"
	"google.golang.org/protobuf/types/known/structpb"

	"github.com/verified-dating/backend/internal/platform/config"
	"github.com/verified-dating/backend/internal/platform/supabase"
)

type Repository interface {
	GetUser(context.Context, string) (map[string]any, bool, error)
	UpsertUser(context.Context, map[string]any) (map[string]any, error)
	GetPhotos(context.Context, string) ([]string, error)
	GetPreferences(context.Context, string) (map[string]any, error)
	GetStats(context.Context, string) (map[string]any, error)
}

type SupabaseRepository struct {
	db  *supabase.Client
	cfg config.Config
}

func NewRepository(db *supabase.Client, cfg config.Config) Repository {
	return &SupabaseRepository{db: db, cfg: cfg}
}

type Service struct {
	repo Repository
	log  *zap.Logger
}

func NewService(repo Repository, log *zap.Logger) *Service {
	return &Service{repo: repo, log: log}
}

func (s *Service) GetProfile(ctx context.Context, req *structpb.Struct) (*structpb.Struct, error) {
	payload := req.AsMap()
	userID, _ := payload["user_id"].(string)
	userID = strings.TrimSpace(userID)
	s.log.Info("profile_get_requested", zap.String("user_id", userID))
	if userID == "" {
		return structpb.NewStruct(map[string]any{"error": "user_id is required"})
	}

	user, found, err := s.repo.GetUser(ctx, userID)
	if err != nil {
		s.log.Error("profile_get_failed", zap.String("user_id", userID), zap.Error(err))
		return nil, err
	}
	if !found {
		s.log.Info("profile_get_not_found", zap.String("user_id", userID))
		return structpb.NewStruct(map[string]any{
			"profile": map[string]any{},
			"found":   false,
		})
	}

	photos, err := s.repo.GetPhotos(ctx, userID)
	if err != nil {
		s.log.Error("profile_get_photos_failed", zap.String("user_id", userID), zap.Error(err))
		return nil, err
	}
	user["photoUrls"] = photos

	s.log.Info("profile_get_completed", zap.String("user_id", userID))
	return structpb.NewStruct(map[string]any{
		"profile": user,
		"found":   true,
	})
}

func (s *Service) UpsertProfile(ctx context.Context, req *structpb.Struct) (*structpb.Struct, error) {
	payload := req.AsMap()
	profile, _ := payload["profile"].(map[string]any)
	if len(profile) == 0 {
		return structpb.NewStruct(map[string]any{
			"success": false,
			"error":   "profile payload required",
		})
	}
	s.log.Info("profile_upsert_requested", zap.String("user_id", toString(profile["id"])))

	updated, err := s.repo.UpsertUser(ctx, profile)
	if err != nil {
		s.log.Error("profile_upsert_failed", zap.String("user_id", toString(profile["id"])), zap.Error(err))
		return nil, err
	}

	s.log.Info("profile_upsert_completed", zap.String("user_id", toString(updated["id"])))
	return structpb.NewStruct(map[string]any{
		"success": true,
		"profile": updated,
	})
}

func (s *Service) GetProfileSummary(ctx context.Context, req *structpb.Struct) (*structpb.Struct, error) {
	payload := req.AsMap()
	userID, _ := payload["user_id"].(string)
	userID = strings.TrimSpace(userID)
	s.log.Info("profile_summary_requested", zap.String("user_id", userID))
	if userID == "" {
		return structpb.NewStruct(map[string]any{"error": "user_id is required"})
	}

	user, found, err := s.repo.GetUser(ctx, userID)
	if err != nil {
		s.log.Error("profile_summary_failed", zap.String("user_id", userID), zap.Error(err))
		return nil, err
	}
	if !found {
		return structpb.NewStruct(map[string]any{
			"found":       false,
			"user":        map[string]any{},
			"preferences": map[string]any{},
			"stats": map[string]any{
				"likes_count":    0,
				"matches_count":  0,
				"messages_count": 0,
			},
		})
	}

	preferences, err := s.repo.GetPreferences(ctx, userID)
	if err != nil {
		s.log.Error("profile_summary_preferences_failed", zap.String("user_id", userID), zap.Error(err))
		return nil, err
	}
	stats, err := s.repo.GetStats(ctx, userID)
	if err != nil {
		s.log.Error("profile_summary_stats_failed", zap.String("user_id", userID), zap.Error(err))
		return nil, err
	}

	s.log.Info("profile_summary_completed", zap.String("user_id", userID))
	return structpb.NewStruct(map[string]any{
		"found":       true,
		"user":        user,
		"preferences": preferences,
		"stats":       stats,
	})
}

func (r *SupabaseRepository) GetUser(ctx context.Context, userID string) (map[string]any, bool, error) {
	params := url.Values{}
	params.Set("id", "eq."+userID)
	params.Set("limit", "1")
	rows, err := r.db.Select(ctx, r.cfg.UserSchema, r.cfg.UsersTable, params)
	if err != nil {
		return nil, false, err
	}
	if len(rows) == 0 {
		return map[string]any{}, false, nil
	}
	return rows[0], true, nil
}

func (r *SupabaseRepository) UpsertUser(ctx context.Context, profile map[string]any) (map[string]any, error) {
	rows, err := r.db.Upsert(
		ctx,
		r.cfg.UserSchema,
		r.cfg.UsersTable,
		[]map[string]any{profile},
		"id",
	)
	if err != nil {
		return nil, err
	}
	if len(rows) == 0 {
		return map[string]any{}, nil
	}
	return rows[0], nil
}

func (r *SupabaseRepository) GetPreferences(ctx context.Context, userID string) (map[string]any, error) {
	params := url.Values{}
	params.Set("userId", "eq."+userID)
	params.Set("limit", "1")
	rows, err := r.db.Select(ctx, r.cfg.UserSchema, r.cfg.PreferencesTable, params)
	if err != nil {
		return nil, err
	}
	if len(rows) == 0 {
		return map[string]any{}, nil
	}
	return rows[0], nil
}

func (r *SupabaseRepository) GetPhotos(ctx context.Context, userID string) ([]string, error) {
	params := url.Values{}
	params.Set("userId", "eq."+userID)
	params.Set("select", "photoUrl,ordering")
	params.Set("order", "ordering.asc")
	rows, err := r.db.Select(ctx, r.cfg.UserSchema, r.cfg.PhotosTable, params)
	if err != nil {
		return nil, err
	}
	out := make([]string, 0, len(rows))
	for _, row := range rows {
		photoURL := toString(row["photoUrl"])
		if photoURL != "" {
			out = append(out, photoURL)
		}
	}
	return out, nil
}

func (r *SupabaseRepository) GetStats(ctx context.Context, userID string) (map[string]any, error) {
	likesParams := url.Values{}
	likesParams.Set("userId", "eq."+userID)
	likesParams.Set("isLike", "eq.true")
	likesParams.Set("select", "id")
	likesRows, err := r.db.Select(ctx, r.cfg.MatchingSchema, r.cfg.SwipesTable, likesParams)
	if err != nil {
		return nil, err
	}

	matchesParams := url.Values{}
	matchesParams.Set("or", "(userId1.eq."+userID+",userId2.eq."+userID+")")
	matchesParams.Set("user1Status", "eq.active")
	matchesParams.Set("user2Status", "eq.active")
	matchesParams.Set("select", "id")
	matchesRows, err := r.db.Select(ctx, r.cfg.MatchingSchema, r.cfg.MatchesTable, matchesParams)
	if err != nil {
		return nil, err
	}

	messagesParams := url.Values{}
	messagesParams.Set("senderId", "eq."+userID)
	messagesParams.Set("select", "id")
	messagesRows, err := r.db.Select(ctx, r.cfg.MatchingSchema, r.cfg.MessagesTable, messagesParams)
	if err != nil {
		return nil, err
	}

	photosParams := url.Values{}
	photosParams.Set("userId", "eq."+userID)
	photosParams.Set("select", "id")
	photosRows, err := r.db.Select(ctx, r.cfg.UserSchema, r.cfg.PhotosTable, photosParams)
	if err != nil {
		return nil, err
	}

	return map[string]any{
		"likes_count":    len(likesRows),
		"matches_count":  len(matchesRows),
		"messages_count": len(messagesRows),
		"photo_count":    len(photosRows),
	}, nil
}

func toString(value any) string {
	if typed, ok := value.(string); ok {
		return typed
	}
	return strings.TrimSpace(fmt.Sprintf("%v", value))
}
