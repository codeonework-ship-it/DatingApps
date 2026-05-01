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

type messageSchemaProfile struct {
	schema         string
	matchIDField   string
	senderIDField  string
	createdAtField string
	readAtField    string
	deletedField   string
	deletedAtField string
	selectClause   string
	orderClause    string
}

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
		"deleted":     deleted,
		"message_id":  messageID,
		"reason_code": reasonCode,
	})
}

func (r *SupabaseRepository) ListMessages(ctx context.Context, matchID string, limit int) ([]map[string]any, error) {
	profile := r.primaryMessageSchemaProfile()
	rows, err := r.listMessagesWithProfile(ctx, profile, matchID, limit)
	if err == nil || !isSchemaUnavailable(err) {
		return rows, err
	}
	if fallback, ok := r.fallbackMessageSchemaProfile(profile); ok {
		return r.listMessagesWithProfile(ctx, fallback, matchID, limit)
	}
	return nil, err
}

func (r *SupabaseRepository) SendMessage(ctx context.Context, matchID, senderID, text string) (string, error) {
	profile := r.primaryMessageSchemaProfile()
	id, err := r.sendMessageWithProfile(ctx, profile, matchID, senderID, text)
	if err == nil || !isSchemaUnavailable(err) {
		return id, err
	}
	if fallback, ok := r.fallbackMessageSchemaProfile(profile); ok {
		return r.sendMessageWithProfile(ctx, fallback, matchID, senderID, text)
	}
	return "", err
}

func (r *SupabaseRepository) DeleteMessage(
	ctx context.Context,
	matchID,
	messageID,
	requesterUserID string,
) (bool, string, error) {
	profile := r.primaryMessageSchemaProfile()
	deleted, reasonCode, err := r.deleteMessageWithProfile(ctx, profile, matchID, messageID, requesterUserID)
	if err == nil || !isSchemaUnavailable(err) {
		return deleted, reasonCode, err
	}
	if fallback, ok := r.fallbackMessageSchemaProfile(profile); ok {
		return r.deleteMessageWithProfile(ctx, fallback, matchID, messageID, requesterUserID)
	}
	return false, "", err
}

func (r *SupabaseRepository) listMessagesWithProfile(
	ctx context.Context,
	profile messageSchemaProfile,
	matchID string,
	limit int,
) ([]map[string]any, error) {
	params := url.Values{}
	params.Set(profile.matchIDField, "eq."+matchID)
	params.Set("or", "("+profile.deletedField+".is.null,"+profile.deletedField+".eq.false)")
	params.Set("select", profile.selectClause)
	params.Set("order", profile.orderClause)
	params.Set("limit", strconv.Itoa(limit))
	return r.db.Select(ctx, profile.schema, r.cfg.MessagesTable, params)
}

func (r *SupabaseRepository) sendMessageWithProfile(
	ctx context.Context,
	profile messageSchemaProfile,
	matchID,
	senderID,
	text string,
) (string, error) {
	rows, err := r.db.Insert(ctx, profile.schema, r.cfg.MessagesTable, []map[string]any{{
		profile.matchIDField:  matchID,
		profile.senderIDField: senderID,
		"text":                strings.TrimSpace(text),
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

func (r *SupabaseRepository) deleteMessageWithProfile(
	ctx context.Context,
	profile messageSchemaProfile,
	matchID,
	messageID,
	requesterUserID string,
) (bool, string, error) {
	lookup := url.Values{}
	lookup.Set("id", "eq."+messageID)
	lookup.Set(profile.matchIDField, "eq."+matchID)
	lookup.Set(profile.senderIDField, "eq."+requesterUserID)
	lookup.Set("or", "("+profile.deletedField+".is.null,"+profile.deletedField+".eq.false)")
	lookup.Set("select", "id,"+profile.createdAtField)
	lookup.Set("limit", "1")

	rows, err := r.db.Select(ctx, profile.schema, r.cfg.MessagesTable, lookup)
	if err != nil {
		return false, "", err
	}
	if len(rows) == 0 {
		return false, "NOT_FOUND_OR_NOT_OWNER", nil
	}

	createdAtRaw, _ := rows[0][profile.createdAtField].(string)
	createdAt, parseErr := time.Parse(time.RFC3339, strings.TrimSpace(createdAtRaw))
	if parseErr == nil && time.Since(createdAt.UTC()) > 24*time.Hour {
		return false, "DELETE_WINDOW_EXPIRED", nil
	}

	filters := url.Values{}
	filters.Set("id", "eq."+messageID)
	filters.Set(profile.matchIDField, "eq."+matchID)
	filters.Set(profile.senderIDField, "eq."+requesterUserID)
	filters.Set("or", "("+profile.deletedField+".is.null,"+profile.deletedField+".eq.false)")

	updatedRows, err := r.db.Update(
		ctx,
		profile.schema,
		r.cfg.MessagesTable,
		map[string]any{
			profile.deletedField:   true,
			profile.deletedAtField: time.Now().UTC().Format(time.RFC3339),
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

func (r *SupabaseRepository) primaryMessageSchemaProfile() messageSchemaProfile {
	if strings.EqualFold(strings.TrimSpace(r.cfg.MatchingSchema), "public") || r.prefersPublicCoreMessages() {
		return publicMessageSchemaProfile()
	}
	return matchingMessageSchemaProfile(strings.TrimSpace(r.cfg.MatchingSchema))
}

func (r *SupabaseRepository) fallbackMessageSchemaProfile(profile messageSchemaProfile) (messageSchemaProfile, bool) {
	if strings.EqualFold(strings.TrimSpace(profile.schema), "public") {
		return messageSchemaProfile{}, false
	}
	return publicMessageSchemaProfile(), true
}

func matchingMessageSchemaProfile(schema string) messageSchemaProfile {
	if strings.TrimSpace(schema) == "" {
		schema = "matching"
	}
	return messageSchemaProfile{
		schema:         schema,
		matchIDField:   "match_id",
		senderIDField:  "sender_id",
		createdAtField: "created_at",
		readAtField:    "read_at",
		deletedField:   "is_deleted",
		deletedAtField: "deleted_at",
		selectClause:   "id,match_id,sender_id,text,created_at,delivered_at,read_at,is_deleted,deleted_at",
		orderClause:    "created_at.desc",
	}
}

func publicMessageSchemaProfile() messageSchemaProfile {
	return messageSchemaProfile{
		schema:         "public",
		matchIDField:   "matchId",
		senderIDField:  "senderId",
		createdAtField: "createdAt",
		readAtField:    "readAt",
		deletedField:   "isDeleted",
		deletedAtField: "deletedAt",
		selectClause:   "id,matchId,senderId,text,createdAt,deliveredAt,readAt,isDeleted,deletedAt",
		orderClause:    "createdAt.desc",
	}
}

func isSchemaUnavailable(err error) bool {
	if err == nil {
		return false
	}
	msg := strings.ToLower(err.Error())
	return strings.Contains(msg, "pgrst106") ||
		strings.Contains(msg, "invalid schema") ||
		strings.Contains(msg, "could not find the table")
}

func (r *SupabaseRepository) prefersPublicCoreMessages() bool {
	base := strings.TrimRight(strings.TrimSpace(r.cfg.SupabaseURL), "/")
	if base == "" || strings.HasSuffix(base, "/rest/v1") {
		return false
	}
	parsed, err := url.Parse(base)
	if err != nil {
		return false
	}
	host := strings.ToLower(parsed.Hostname())
	return host == "localhost" || host == "127.0.0.1"
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
