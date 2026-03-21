package chat

import (
	"context"
	"net/url"
	"strconv"
	"strings"
	"sync"
	"time"

	"go.uber.org/zap"
	"google.golang.org/protobuf/types/known/structpb"

	"github.com/verified-dating/backend/internal/platform/concurrency"
	"github.com/verified-dating/backend/internal/platform/config"
	"github.com/verified-dating/backend/internal/platform/supabase"
)

type Repository interface {
	ListMessages(context.Context, string, int) ([]map[string]any, error)
	SendMessage(context.Context, string, string, string) (string, error)
	DeleteMessage(context.Context, string, string, string) (bool, string, error)
}

type SupabaseRepository struct {
	db  *supabase.Client
	cfg config.Config
}

func NewRepository(db *supabase.Client, cfg config.Config) Repository {
	return &SupabaseRepository{db: db, cfg: cfg}
}

type Service struct {
	repo     Repository
	realtime *supabase.RealtimeClient
	workers  *concurrency.WorkerPool
	log      *zap.Logger
	cfg      config.Config
	mu       sync.RWMutex
	events   []map[string]any
}

func NewService(
	repo Repository,
	realtime *supabase.RealtimeClient,
	workers *concurrency.WorkerPool,
	log *zap.Logger,
	cfg config.Config,
) *Service {
	return &Service{
		repo:     repo,
		realtime: realtime,
		workers:  workers,
		log:      log,
		cfg:      cfg,
		events:   make([]map[string]any, 0, cfg.ChatRealtimeMaxEvents),
	}
}

func (s *Service) StartRealtime(ctx context.Context) error {
	if err := s.realtime.Connect(ctx); err != nil {
		s.log.Error("chat_realtime_connect_failed", zap.Error(err))
		return err
	}

	return s.realtime.SubscribeToTable(s.cfg.ChatRealtimeSchema, s.cfg.ChatRealtimeTable, func(envelope map[string]any) {
		s.workers.Submit(func(context.Context) {
			s.mu.Lock()
			s.events = append(s.events, envelope)
			if len(s.events) > s.cfg.ChatRealtimeMaxEvents {
				s.events = s.events[len(s.events)-s.cfg.ChatRealtimeMaxEvents:]
			}
			s.mu.Unlock()
			s.log.Info("chat_realtime_event_received", zap.Int("queued_events", len(s.events)))
		})
	})
}

func (s *Service) ListMessages(ctx context.Context, req *structpb.Struct) (*structpb.Struct, error) {
	payload := req.AsMap()
	matchID, _ := payload["match_id"].(string)
	matchID = strings.TrimSpace(matchID)
	s.log.Info("chat_list_messages_requested", zap.String("match_id", matchID))
	if matchID == "" {
		return structpb.NewStruct(map[string]any{"error": "match_id is required"})
	}

	limit := 50
	if rawLimit, ok := payload["limit"].(float64); ok {
		limit = int(rawLimit)
	}
	if limit <= 0 || limit > 200 {
		limit = 50
	}

	rows, err := s.repo.ListMessages(ctx, matchID, limit)
	if err != nil {
		s.log.Error("chat_list_messages_failed", zap.String("match_id", matchID), zap.Error(err))
		return nil, err
	}
	s.log.Info("chat_list_messages_completed", zap.String("match_id", matchID), zap.Int("count", len(rows)))
	return structpb.NewStruct(map[string]any{"messages": mapsToAnySlice(rows)})
}

func (s *Service) SendMessage(ctx context.Context, req *structpb.Struct) (*structpb.Struct, error) {
	payload := req.AsMap()
	matchID, _ := payload["match_id"].(string)
	senderID, _ := payload["sender_id"].(string)
	text, _ := payload["text"].(string)
	s.log.Info(
		"chat_send_message_requested",
		zap.String("match_id", matchID),
		zap.String("sender_id", senderID),
	)

	if matchID == "" || senderID == "" || strings.TrimSpace(text) == "" {
		return structpb.NewStruct(map[string]any{
			"accepted": false,
			"error":    "match_id, sender_id and text are required",
		})
	}

	messageID, err := s.repo.SendMessage(ctx, matchID, senderID, text)
	if err != nil {
		s.log.Error("chat_send_message_failed", zap.String("match_id", matchID), zap.Error(err))
		return nil, err
	}

	s.log.Info("chat_send_message_completed", zap.String("match_id", matchID), zap.String("message_id", messageID))
	return structpb.NewStruct(map[string]any{
		"accepted":   true,
		"message_id": messageID,
	})
}

func (s *Service) DeleteMessage(ctx context.Context, req *structpb.Struct) (*structpb.Struct, error) {
	payload := req.AsMap()
	matchID, _ := payload["match_id"].(string)
	messageID, _ := payload["message_id"].(string)
	requesterUserID, _ := payload["requester_user_id"].(string)
	matchID = strings.TrimSpace(matchID)
	messageID = strings.TrimSpace(messageID)
	requesterUserID = strings.TrimSpace(requesterUserID)

	s.log.Info(
		"chat_delete_message_requested",
		zap.String("match_id", matchID),
		zap.String("message_id", messageID),
		zap.String("requester_user_id", requesterUserID),
	)

	if matchID == "" || messageID == "" || requesterUserID == "" {
		return structpb.NewStruct(map[string]any{
			"deleted": false,
			"error":   "match_id, message_id and requester_user_id are required",
		})
	}

	deleted, reasonCode, err := s.repo.DeleteMessage(ctx, matchID, messageID, requesterUserID)
	if err != nil {
		s.log.Error(
			"chat_delete_message_failed",
			zap.String("match_id", matchID),
			zap.String("message_id", messageID),
			zap.Error(err),
		)
		return nil, err
	}

	s.log.Info(
		"chat_delete_message_completed",
		zap.String("match_id", matchID),
		zap.String("message_id", messageID),
		zap.Bool("deleted", deleted),
	)

	return structpb.NewStruct(map[string]any{
		"deleted":    deleted,
		"message_id": messageID,
		"reason_code": reasonCode,
	})
}

func (r *SupabaseRepository) ListMessages(ctx context.Context, matchID string, limit int) ([]map[string]any, error) {
	params := url.Values{}
	params.Set("matchId", "eq."+matchID)
	params.Set("or", "(isDeleted.is.null,isDeleted.eq.false)")
	params.Set("select", "id,matchId,senderId,text,createdAt,deliveredAt,readAt,isDeleted,deletedAt")
	params.Set("order", "createdAt.desc")
	params.Set("limit", strconv.Itoa(limit))
	return r.db.Select(ctx, r.cfg.MatchingSchema, r.cfg.MessagesTable, params)
}

func (r *SupabaseRepository) SendMessage(ctx context.Context, matchID, senderID, text string) (string, error) {
	rows, err := r.db.Insert(ctx, r.cfg.MatchingSchema, r.cfg.MessagesTable, []map[string]any{{
		"matchId":  matchID,
		"senderId": senderID,
		"text":     strings.TrimSpace(text),
	}})
	if err != nil {
		return "", err
	}
	if len(rows) == 0 {
		return "", nil
	}
	id, _ := rows[0]["id"].(string)
	return id, nil
}

func (r *SupabaseRepository) DeleteMessage(
	ctx context.Context,
	matchID,
	messageID,
	requesterUserID string,
) (bool, string, error) {
	lookup := url.Values{}
	lookup.Set("id", "eq."+messageID)
	lookup.Set("matchId", "eq."+matchID)
	lookup.Set("senderId", "eq."+requesterUserID)
	lookup.Set("or", "(isDeleted.is.null,isDeleted.eq.false)")
	lookup.Set("select", "id,createdAt")
	lookup.Set("limit", "1")

	rows, err := r.db.Select(ctx, r.cfg.MatchingSchema, r.cfg.MessagesTable, lookup)
	if err != nil {
		return false, "", err
	}
	if len(rows) == 0 {
		return false, "NOT_FOUND_OR_NOT_OWNER", nil
	}

	createdAtRaw, _ := rows[0]["createdAt"].(string)
	createdAt, parseErr := time.Parse(time.RFC3339, strings.TrimSpace(createdAtRaw))
	if parseErr == nil && time.Since(createdAt.UTC()) > 24*time.Hour {
		return false, "DELETE_WINDOW_EXPIRED", nil
	}

	filters := url.Values{}
	filters.Set("id", "eq."+messageID)
	filters.Set("matchId", "eq."+matchID)
	filters.Set("senderId", "eq."+requesterUserID)
	filters.Set("or", "(isDeleted.is.null,isDeleted.eq.false)")

	updatedRows, err := r.db.Update(
		ctx,
		r.cfg.MatchingSchema,
		r.cfg.MessagesTable,
		map[string]any{
			"isDeleted": true,
			"deletedAt": time.Now().UTC().Format(time.RFC3339),
		},
		filters,
	)
	if err != nil {
		return false, "", err
	}
	if len(updatedRows) == 0 {
		return false, "NOT_FOUND_OR_NOT_OWNER", nil
	}
	return true, "DELETED", nil
}

func mapsToAnySlice(input []map[string]any) []any {
	if len(input) == 0 {
		return []any{}
	}
	out := make([]any, 0, len(input))
	for _, row := range input {
		out = append(out, row)
	}
	return out
}
