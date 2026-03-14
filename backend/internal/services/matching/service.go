package matching

import (
	"context"
	"fmt"
	"net/url"
	"strconv"
	"strings"
	"sync"
	"time"

	"go.uber.org/zap"
	"golang.org/x/sync/errgroup"
	"google.golang.org/protobuf/types/known/structpb"

	"github.com/verified-dating/backend/internal/platform/config"
	"github.com/verified-dating/backend/internal/platform/supabase"
)

type Repository interface {
	GetSwipedTargetIDs(context.Context, string) ([]string, error)
	GetMatchedUserPairs(context.Context, string) ([]map[string]any, error)
	ListActiveUsers(context.Context, int) ([]map[string]any, error)
	GetUserPhotos(context.Context, []string) (map[string][]string, error)
	EnsureUsersExist(context.Context, []string) error

	UpsertSwipe(context.Context, string, string, bool) error
	HasMutualLike(context.Context, string, string) (bool, error)
	UpsertMatch(context.Context, string, string) (string, error)

	ListMatches(context.Context, string) ([]map[string]any, error)
	GetUsersByIDs(context.Context, []string) (map[string]map[string]any, error)
	GetPrimaryPhotosByUserIDs(context.Context, []string) (map[string]string, error)
	GetLatestMessagesByMatchIDs(context.Context, []string) (map[string]map[string]any, error)
	GetUnreadCounts(context.Context, []string, string) (map[string]int, error)

	GetMatchByID(context.Context, string) (map[string]any, error)
	UpdateMatchStatus(context.Context, string, map[string]any) error
	MarkMessagesRead(context.Context, string, string, string) error
}

type SupabaseRepository struct {
	db          *supabase.Client
	cfg         config.Config
	mu          sync.Mutex
	mockSwipes  map[string]map[string]bool
	mockMatches map[string]map[string]any
}

func NewRepository(db *supabase.Client, cfg config.Config) Repository {
	return &SupabaseRepository{
		db:          db,
		cfg:         cfg,
		mockSwipes:  map[string]map[string]bool{},
		mockMatches: map[string]map[string]any{},
	}
}

type Service struct {
	repo Repository
	log  *zap.Logger
	cfg  config.Config
}

func NewService(repo Repository, log *zap.Logger, cfg config.Config) *Service {
	return &Service{repo: repo, log: log, cfg: cfg}
}

func (s *Service) GetCandidates(ctx context.Context, req *structpb.Struct) (*structpb.Struct, error) {
	payload := req.AsMap()
	userID := strings.TrimSpace(toString(payload["user_id"]))
	s.log.Info("matching_candidates_requested", zap.String("user_id", userID))
	if userID == "" {
		return structpb.NewStruct(map[string]any{"error": "user_id is required"})
	}

	limit := 25
	if rawLimit, ok := payload["limit"].(float64); ok {
		limit = int(rawLimit)
	}
	if limit <= 0 || limit > 100 {
		limit = 25
	}

	var swipedIDs []string
	var matchedPairs []map[string]any
	g, gctx := errgroup.WithContext(ctx)
	g.Go(func() error {
		var err error
		swipedIDs, err = s.repo.GetSwipedTargetIDs(gctx, userID)
		return err
	})
	g.Go(func() error {
		var err error
		matchedPairs, err = s.repo.GetMatchedUserPairs(gctx, userID)
		return err
	})
	if err := g.Wait(); err != nil {
		s.log.Error("matching_candidates_preload_failed", zap.String("user_id", userID), zap.Error(err))
		return nil, err
	}

	excluded := map[string]struct{}{userID: {}}
	for _, id := range swipedIDs {
		excluded[id] = struct{}{}
	}
	for _, row := range matchedPairs {
		user1 := toString(row["userId1"])
		user2 := toString(row["userId2"])
		if user1 != "" {
			excluded[user1] = struct{}{}
		}
		if user2 != "" {
			excluded[user2] = struct{}{}
		}
	}

	users, err := s.repo.ListActiveUsers(ctx, limit*3)
	if err != nil {
		s.log.Error("matching_candidates_users_failed", zap.String("user_id", userID), zap.Error(err))
		return nil, err
	}

	candidates := make([]map[string]any, 0, limit)
	candidateIDs := make([]string, 0, limit)
	for _, row := range users {
		id := toString(row["id"])
		if id == "" {
			continue
		}
		if _, skip := excluded[id]; skip {
			continue
		}
		candidates = append(candidates, row)
		candidateIDs = append(candidateIDs, id)
		if len(candidates) >= limit {
			break
		}
	}

	photosByUser, err := s.repo.GetUserPhotos(ctx, candidateIDs)
	if err != nil {
		s.log.Error("matching_candidates_photos_failed", zap.String("user_id", userID), zap.Error(err))
		return nil, err
	}

	for i := range candidates {
		id := toString(candidates[i]["id"])
		photoURLs := photosByUser[id]
		if len(photoURLs) == 0 {
			photoURLs = []string{s.cfg.DefaultProfileImageURL}
		}
		candidates[i]["photoUrls"] = stringsToAnySlice(photoURLs)
	}

	s.log.Info(
		"matching_candidates_completed",
		zap.String("user_id", userID),
		zap.Int("count", len(candidates)),
	)
	return structpb.NewStruct(map[string]any{"candidates": mapsToAnySlice(candidates)})
}

func (s *Service) Swipe(ctx context.Context, req *structpb.Struct) (*structpb.Struct, error) {
	payload := req.AsMap()
	userID := strings.TrimSpace(toString(payload["user_id"]))
	targetUserID := strings.TrimSpace(toString(payload["target_user_id"]))
	isLike, _ := payload["is_like"].(bool)
	s.log.Info(
		"matching_swipe_requested",
		zap.String("user_id", userID),
		zap.String("target_user_id", targetUserID),
		zap.Bool("is_like", isLike),
	)

	if userID == "" || targetUserID == "" {
		return structpb.NewStruct(map[string]any{
			"accepted": false,
			"error":    "missing user ids",
		})
	}

	if err := s.repo.EnsureUsersExist(ctx, []string{userID, targetUserID}); err != nil {
		s.log.Error(
			"matching_swipe_ensure_users_failed",
			zap.String("user_id", userID),
			zap.String("target_user_id", targetUserID),
			zap.Error(err),
		)
		return nil, err
	}

	if err := s.repo.UpsertSwipe(ctx, userID, targetUserID, isLike); err != nil {
		s.log.Error(
			"matching_swipe_upsert_failed",
			zap.String("user_id", userID),
			zap.String("target_user_id", targetUserID),
			zap.Error(err),
		)
		return nil, err
	}

	mutual := false
	matchID := ""
	if isLike {
		hasMutual, err := s.repo.HasMutualLike(ctx, userID, targetUserID)
		if err != nil {
			s.log.Error("matching_swipe_mutual_check_failed", zap.Error(err))
			return nil, err
		}
		mutual = hasMutual
		if mutual {
			createdMatchID, err := s.repo.UpsertMatch(ctx, userID, targetUserID)
			if err != nil {
				s.log.Error("matching_swipe_match_upsert_failed", zap.Error(err))
				return nil, err
			}
			matchID = createdMatchID
		}
	}

	s.log.Info(
		"matching_swipe_completed",
		zap.String("user_id", userID),
		zap.String("target_user_id", targetUserID),
		zap.Bool("mutual_match", mutual),
		zap.String("match_id", matchID),
	)
	return structpb.NewStruct(map[string]any{
		"accepted":     true,
		"mutual_match": mutual,
		"match_id":     matchID,
	})
}

func (s *Service) ListMatches(ctx context.Context, req *structpb.Struct) (*structpb.Struct, error) {
	payload := req.AsMap()
	currentUserID := strings.TrimSpace(toString(payload["user_id"]))
	s.log.Info("matching_list_requested", zap.String("user_id", currentUserID))
	if currentUserID == "" {
		return structpb.NewStruct(map[string]any{
			"matches": []any{},
			"error":   "user_id is required",
		})
	}

	matchRows, err := s.repo.ListMatches(ctx, currentUserID)
	if err != nil {
		s.log.Error("matching_list_failed", zap.String("user_id", currentUserID), zap.Error(err))
		return nil, err
	}
	if len(matchRows) == 0 {
		return structpb.NewStruct(map[string]any{"matches": []any{}})
	}

	matchIDs := make([]string, 0, len(matchRows))
	otherUserIDs := make([]string, 0, len(matchRows))
	for _, row := range matchRows {
		matchIDs = append(matchIDs, toString(row["id"]))
		userID1 := toString(row["userId1"])
		userID2 := toString(row["userId2"])
		if userID1 == currentUserID {
			otherUserIDs = append(otherUserIDs, userID2)
		} else {
			otherUserIDs = append(otherUserIDs, userID1)
		}
	}

	var usersByID map[string]map[string]any
	var photoByUserID map[string]string
	var latestByMatchID map[string]map[string]any
	var unreadByMatchID map[string]int

	g, gctx := errgroup.WithContext(ctx)
	g.Go(func() error {
		var err error
		usersByID, err = s.repo.GetUsersByIDs(gctx, unique(otherUserIDs))
		return err
	})
	g.Go(func() error {
		var err error
		photoByUserID, err = s.repo.GetPrimaryPhotosByUserIDs(gctx, unique(otherUserIDs))
		return err
	})
	g.Go(func() error {
		var err error
		latestByMatchID, err = s.repo.GetLatestMessagesByMatchIDs(gctx, unique(matchIDs))
		return err
	})
	g.Go(func() error {
		var err error
		unreadByMatchID, err = s.repo.GetUnreadCounts(gctx, unique(matchIDs), currentUserID)
		return err
	})
	if err := g.Wait(); err != nil {
		s.log.Error("matching_list_aggregate_failed", zap.String("user_id", currentUserID), zap.Error(err))
		return nil, err
	}

	out := make([]map[string]any, 0, len(matchRows))
	for _, row := range matchRows {
		matchID := toString(row["id"])
		userID1 := toString(row["userId1"])
		userID2 := toString(row["userId2"])

		otherUserID := userID1
		if otherUserID == currentUserID {
			otherUserID = userID2
		}

		user := usersByID[otherUserID]
		name := toString(user["name"])
		if name == "" {
			name = "Unknown"
		}

		lastLogin := parseTimeAny(user["lastLogin"])
		isOnline := false
		if lastLogin != nil {
			isOnline = time.Since(*lastLogin) <= 5*time.Minute
		}

		latest := latestByMatchID[matchID]
		lastMessage := toString(latest["text"])
		if lastMessage == "" {
			lastMessage = "Say hi 👋"
		}
		lastMessageTime := parseTimeAny(latest["createdAt"])
		if lastMessageTime == nil {
			lastMessageTime = parseTimeAny(row["createdAt"])
		}
		isoTime := time.Now().UTC().Format(time.RFC3339)
		if lastMessageTime != nil {
			isoTime = lastMessageTime.UTC().Format(time.RFC3339)
		}

		userPhoto := photoByUserID[otherUserID]
		if userPhoto == "" {
			userPhoto = s.cfg.DefaultAvatarImageURL
		}

		out = append(out, map[string]any{
			"id":              matchID,
			"userId":          otherUserID,
			"userName":        name,
			"userPhoto":       userPhoto,
			"lastMessage":     lastMessage,
			"lastMessageTime": isoTime,
			"unreadCount":     unreadByMatchID[matchID],
			"isOnline":        isOnline,
		})
	}

	s.log.Info("matching_list_completed", zap.String("user_id", currentUserID), zap.Int("count", len(out)))
	return structpb.NewStruct(map[string]any{"matches": mapsToAnySlice(out)})
}

func (s *Service) MarkAsRead(ctx context.Context, req *structpb.Struct) (*structpb.Struct, error) {
	payload := req.AsMap()
	matchID := strings.TrimSpace(toString(payload["match_id"]))
	userID := strings.TrimSpace(toString(payload["user_id"]))
	if matchID == "" || userID == "" {
		return structpb.NewStruct(map[string]any{
			"success": false,
			"error":   "match_id and user_id are required",
		})
	}

	if err := s.repo.MarkMessagesRead(
		ctx,
		matchID,
		userID,
		time.Now().UTC().Format(time.RFC3339),
	); err != nil {
		return nil, err
	}

	return structpb.NewStruct(map[string]any{"success": true})
}

func (s *Service) Unmatch(ctx context.Context, req *structpb.Struct) (*structpb.Struct, error) {
	payload := req.AsMap()
	matchID := strings.TrimSpace(toString(payload["match_id"]))
	userID := strings.TrimSpace(toString(payload["user_id"]))
	if matchID == "" || userID == "" {
		return structpb.NewStruct(map[string]any{
			"success": false,
			"error":   "match_id and user_id are required",
		})
	}

	row, err := s.repo.GetMatchByID(ctx, matchID)
	if err != nil {
		return nil, err
	}
	if len(row) == 0 {
		return structpb.NewStruct(map[string]any{
			"success": false,
			"error":   "match not found",
		})
	}

	userID1 := toString(row["userId1"])
	fields := map[string]any{}
	if userID1 == userID {
		fields["user1Status"] = "unmatched"
	} else {
		fields["user2Status"] = "unmatched"
	}

	if err := s.repo.UpdateMatchStatus(ctx, matchID, fields); err != nil {
		return nil, err
	}

	return structpb.NewStruct(map[string]any{"success": true})
}

func (r *SupabaseRepository) GetSwipedTargetIDs(ctx context.Context, userID string) ([]string, error) {
	params := url.Values{}
	params.Set("userId", "eq."+userID)
	params.Set("isLike", "eq.true")
	params.Set("select", "targetUserId")
	rows, err := r.db.Select(ctx, r.cfg.MatchingSchema, r.cfg.SwipesTable, params)
	if err != nil {
		if r.cfg.MockOTPEnabled {
			r.mu.Lock()
			defer r.mu.Unlock()
			liked := r.mockSwipes[userID]
			out := make([]string, 0, len(liked))
			for targetID, isLike := range liked {
				if isLike {
					out = append(out, targetID)
				}
			}
			return out, nil
		}
		return nil, err
	}
	out := make([]string, 0, len(rows))
	for _, row := range rows {
		id := toString(row["targetUserId"])
		if id != "" {
			out = append(out, id)
		}
	}
	return out, nil
}

func (r *SupabaseRepository) GetMatchedUserPairs(ctx context.Context, userID string) ([]map[string]any, error) {
	params := url.Values{}
	params.Set("or", "(userId1.eq."+userID+",userId2.eq."+userID+")")
	params.Set("select", "userId1,userId2")
	rows, err := r.db.Select(ctx, r.cfg.MatchingSchema, r.cfg.MatchesTable, params)
	if err != nil {
		if r.cfg.MockOTPEnabled {
			r.mu.Lock()
			defer r.mu.Unlock()
			out := make([]map[string]any, 0)
			for _, match := range r.mockMatches {
				userID1 := toString(match["userId1"])
				userID2 := toString(match["userId2"])
				if userID1 == userID || userID2 == userID {
					out = append(out, map[string]any{"userId1": userID1, "userId2": userID2})
				}
			}
			return out, nil
		}
		return nil, err
	}
	return rows, nil
}

func (r *SupabaseRepository) ListActiveUsers(ctx context.Context, limit int) ([]map[string]any, error) {
	params := url.Values{}
	params.Set("select", "id,name,dateOfBirth,bio,profession,education,isVerified,gender")
	params.Set("isActive", "eq.true")
	params.Set("limit", strconv.Itoa(limit))
	rows, err := r.db.Select(ctx, r.cfg.UserSchema, r.cfg.UsersTable, params)
	if err != nil {
		if r.cfg.MockOTPEnabled {
			return r.mockUsers(limit), nil
		}
		return nil, err
	}
	if len(rows) == 0 && r.cfg.MockOTPEnabled {
		return r.mockUsers(limit), nil
	}
	return rows, nil
}

func (r *SupabaseRepository) GetUserPhotos(ctx context.Context, userIDs []string) (map[string][]string, error) {
	if len(userIDs) == 0 {
		return map[string][]string{}, nil
	}
	params := url.Values{}
	params.Set("select", "userId,photoUrl,ordering")
	params.Set("userId", "in."+buildIn(unique(userIDs)))
	params.Set("order", "ordering.asc")
	rows, err := r.db.Select(ctx, r.cfg.UserSchema, r.cfg.PhotosTable, params)
	if err != nil {
		if r.cfg.MockOTPEnabled {
			photosByUser := map[string][]string{}
			for _, userID := range unique(userIDs) {
				photosByUser[userID] = []string{
					mockPhotoURL(r.cfg.MockPhotoSeedURLTemplate, userID+"-1"),
					mockPhotoURL(r.cfg.MockPhotoSeedURLTemplate, userID+"-2"),
				}
			}
			return photosByUser, nil
		}
		return nil, err
	}
	photosByUser := map[string][]string{}
	for _, row := range rows {
		userID := toString(row["userId"])
		url := toString(row["photoUrl"])
		if userID == "" || url == "" {
			continue
		}
		photosByUser[userID] = append(photosByUser[userID], url)
	}
	if r.cfg.MockOTPEnabled {
		for _, userID := range userIDs {
			if len(photosByUser[userID]) > 0 || !strings.HasPrefix(userID, "mock-") {
				continue
			}
			photosByUser[userID] = []string{
				mockPhotoURL(r.cfg.MockPhotoSeedURLTemplate, userID+"-1"),
				mockPhotoURL(r.cfg.MockPhotoSeedURLTemplate, userID+"-2"),
			}
		}
	}
	return photosByUser, nil
}

func (r *SupabaseRepository) UpsertSwipe(ctx context.Context, userID, targetUserID string, isLike bool) error {
	_, err := r.db.Upsert(ctx, r.cfg.MatchingSchema, r.cfg.SwipesTable, []map[string]any{{
		"userId":       userID,
		"targetUserId": targetUserID,
		"isLike":       isLike,
	}}, "userId,targetUserId")
	if err != nil && r.cfg.MockOTPEnabled {
		r.mu.Lock()
		defer r.mu.Unlock()
		if r.mockSwipes[userID] == nil {
			r.mockSwipes[userID] = map[string]bool{}
		}
		r.mockSwipes[userID][targetUserID] = isLike
		return nil
	}
	return err
}

func (r *SupabaseRepository) EnsureUsersExist(ctx context.Context, userIDs []string) error {
	ids := unique(userIDs)
	if len(ids) == 0 {
		return nil
	}

	params := url.Values{}
	params.Set("id", "in."+buildIn(ids))
	params.Set("select", "id")
	rows, err := r.db.Select(ctx, r.cfg.UserSchema, r.cfg.UsersTable, params)
	if err != nil {
		if r.cfg.MockOTPEnabled {
			return nil
		}
		return err
	}

	existing := make(map[string]struct{}, len(rows))
	for _, row := range rows {
		id := strings.TrimSpace(toString(row["id"]))
		if id != "" {
			existing[id] = struct{}{}
		}
	}

	missing := make([]map[string]any, 0)
	for _, id := range ids {
		if _, ok := existing[id]; ok {
			continue
		}
		suffix := strings.ReplaceAll(id, "-", "")
		if len(suffix) > 10 {
			suffix = suffix[len(suffix)-10:]
		}
		missing = append(missing, map[string]any{
			"id":          id,
			"phoneNumber": "bootstrap-" + suffix,
			"name":        "Member",
			"dateOfBirth": "1998-01-01",
			"gender":      "U",
			"isVerified":  false,
			"isActive":    true,
		})
	}

	if len(missing) == 0 {
		return nil
	}

	_, err = r.db.Upsert(ctx, r.cfg.UserSchema, r.cfg.UsersTable, missing, "id")
	if err != nil && r.cfg.MockOTPEnabled {
		return nil
	}
	return err
}

func (r *SupabaseRepository) HasMutualLike(ctx context.Context, userID, targetUserID string) (bool, error) {
	params := url.Values{}
	params.Set("userId", "eq."+targetUserID)
	params.Set("targetUserId", "eq."+userID)
	params.Set("isLike", "eq.true")
	params.Set("select", "id")
	params.Set("limit", "1")
	rows, err := r.db.Select(ctx, r.cfg.MatchingSchema, r.cfg.SwipesTable, params)
	if err != nil {
		if r.cfg.MockOTPEnabled {
			r.mu.Lock()
			defer r.mu.Unlock()
			return r.mockSwipes[targetUserID][userID], nil
		}
		return false, err
	}
	return len(rows) > 0, nil
}

func (r *SupabaseRepository) UpsertMatch(ctx context.Context, userID, targetUserID string) (string, error) {
	userID1, userID2 := userID, targetUserID
	if userID1 > userID2 {
		userID1, userID2 = userID2, userID1
	}
	_, err := r.db.Upsert(ctx, r.cfg.MatchingSchema, r.cfg.MatchesTable, []map[string]any{{
		"userId1": userID1,
		"userId2": userID2,
	}}, "userId1,userId2")
	if err != nil {
		if r.cfg.MockOTPEnabled {
			matchID := "mock-match-" + strings.ReplaceAll(userID1+"-"+userID2, "-", "")
			r.mu.Lock()
			defer r.mu.Unlock()
			r.mockMatches[matchID] = map[string]any{
				"id":          matchID,
				"userId1":     userID1,
				"userId2":     userID2,
				"user1Status": "active",
				"user2Status": "active",
				"createdAt":   time.Now().UTC().Format(time.RFC3339),
			}
			return matchID, nil
		}
		return "", err
	}

	params := url.Values{}
	params.Set("userId1", "eq."+userID1)
	params.Set("userId2", "eq."+userID2)
	params.Set("select", "id")
	params.Set("limit", "1")
	rows, err := r.db.Select(ctx, r.cfg.MatchingSchema, r.cfg.MatchesTable, params)
	if err != nil {
		if r.cfg.MockOTPEnabled {
			matchID := "mock-match-" + strings.ReplaceAll(userID1+"-"+userID2, "-", "")
			r.mu.Lock()
			defer r.mu.Unlock()
			if existing, ok := r.mockMatches[matchID]; ok {
				return toString(existing["id"]), nil
			}
			r.mockMatches[matchID] = map[string]any{
				"id":          matchID,
				"userId1":     userID1,
				"userId2":     userID2,
				"user1Status": "active",
				"user2Status": "active",
				"createdAt":   time.Now().UTC().Format(time.RFC3339),
			}
			return matchID, nil
		}
		return "", err
	}
	if len(rows) == 0 {
		return "", nil
	}
	return toString(rows[0]["id"]), nil
}

func (r *SupabaseRepository) ListMatches(ctx context.Context, userID string) ([]map[string]any, error) {
	params := url.Values{}
	params.Set("select", "id,userId1,userId2,lastMessageAt,createdAt,user1Status,user2Status")
	params.Set("or", "(userId1.eq."+userID+",userId2.eq."+userID+")")
	params.Set("user1Status", "eq.active")
	params.Set("user2Status", "eq.active")
	params.Set("order", "lastMessageAt.desc")
	rows, err := r.db.Select(ctx, r.cfg.MatchingSchema, r.cfg.MatchesTable, params)
	if err != nil {
		if r.cfg.MockOTPEnabled {
			r.mu.Lock()
			defer r.mu.Unlock()
			out := make([]map[string]any, 0)
			for _, row := range r.mockMatches {
				userID1 := toString(row["userId1"])
				userID2 := toString(row["userId2"])
				if userID1 == userID || userID2 == userID {
					out = append(out, row)
				}
			}
			return out, nil
		}
		return nil, err
	}
	return rows, nil
}

func (r *SupabaseRepository) GetUsersByIDs(ctx context.Context, userIDs []string) (map[string]map[string]any, error) {
	if len(userIDs) == 0 {
		return map[string]map[string]any{}, nil
	}
	params := url.Values{}
	params.Set("id", "in."+buildIn(unique(userIDs)))
	params.Set("select", "id,name,lastLogin")
	rows, err := r.db.Select(ctx, r.cfg.UserSchema, r.cfg.UsersTable, params)
	if err != nil {
		if r.cfg.MockOTPEnabled {
			out := map[string]map[string]any{}
			for _, userID := range unique(userIDs) {
				out[userID] = map[string]any{
					"id":        userID,
					"name":      "Member",
					"lastLogin": time.Now().UTC().Format(time.RFC3339),
				}
			}
			return out, nil
		}
		return nil, err
	}
	out := map[string]map[string]any{}
	for _, row := range rows {
		id := toString(row["id"])
		if id == "" {
			continue
		}
		out[id] = row
	}
	return out, nil
}

func (r *SupabaseRepository) GetPrimaryPhotosByUserIDs(ctx context.Context, userIDs []string) (map[string]string, error) {
	if len(userIDs) == 0 {
		return map[string]string{}, nil
	}
	params := url.Values{}
	params.Set("userId", "in."+buildIn(unique(userIDs)))
	params.Set("select", "userId,photoUrl,ordering")
	params.Set("order", "ordering.asc")
	rows, err := r.db.Select(ctx, r.cfg.UserSchema, r.cfg.PhotosTable, params)
	if err != nil {
		if r.cfg.MockOTPEnabled {
			out := map[string]string{}
			for _, userID := range unique(userIDs) {
				out[userID] = mockPhotoURL(r.cfg.MockPhotoSeedURLTemplate, userID+"-primary")
			}
			return out, nil
		}
		return nil, err
	}
	out := map[string]string{}
	for _, row := range rows {
		userID := toString(row["userId"])
		photoURL := toString(row["photoUrl"])
		if userID == "" || photoURL == "" {
			continue
		}
		if _, ok := out[userID]; ok {
			continue
		}
		out[userID] = photoURL
	}
	return out, nil
}

func (r *SupabaseRepository) GetLatestMessagesByMatchIDs(ctx context.Context, matchIDs []string) (map[string]map[string]any, error) {
	if len(matchIDs) == 0 {
		return map[string]map[string]any{}, nil
	}
	params := url.Values{}
	params.Set("matchId", "in."+buildIn(unique(matchIDs)))
	params.Set("select", "matchId,text,createdAt")
	params.Set("order", "createdAt.desc")
	rows, err := r.db.Select(ctx, r.cfg.MatchingSchema, r.cfg.MessagesTable, params)
	if err != nil {
		if r.cfg.MockOTPEnabled {
			return map[string]map[string]any{}, nil
		}
		return nil, err
	}
	out := map[string]map[string]any{}
	for _, row := range rows {
		matchID := toString(row["matchId"])
		if matchID == "" {
			continue
		}
		if _, ok := out[matchID]; ok {
			continue
		}
		out[matchID] = row
	}
	return out, nil
}

func (r *SupabaseRepository) GetUnreadCounts(ctx context.Context, matchIDs []string, currentUserID string) (map[string]int, error) {
	if len(matchIDs) == 0 {
		return map[string]int{}, nil
	}
	params := url.Values{}
	params.Set("matchId", "in."+buildIn(unique(matchIDs)))
	params.Set("readAt", "is.null")
	params.Set("senderId", "neq."+currentUserID)
	params.Set("select", "matchId")
	rows, err := r.db.Select(ctx, r.cfg.MatchingSchema, r.cfg.MessagesTable, params)
	if err != nil {
		if r.cfg.MockOTPEnabled {
			return map[string]int{}, nil
		}
		return nil, err
	}
	out := map[string]int{}
	for _, row := range rows {
		matchID := toString(row["matchId"])
		if matchID == "" {
			continue
		}
		out[matchID] = out[matchID] + 1
	}
	return out, nil
}

func (r *SupabaseRepository) GetMatchByID(ctx context.Context, matchID string) (map[string]any, error) {
	params := url.Values{}
	params.Set("id", "eq."+matchID)
	params.Set("select", "id,userId1,userId2")
	params.Set("limit", "1")
	rows, err := r.db.Select(ctx, r.cfg.MatchingSchema, r.cfg.MatchesTable, params)
	if err != nil {
		return nil, err
	}
	if len(rows) == 0 {
		return map[string]any{}, nil
	}
	return rows[0], nil
}

func (r *SupabaseRepository) UpdateMatchStatus(ctx context.Context, matchID string, fields map[string]any) error {
	filters := url.Values{}
	filters.Set("id", "eq."+matchID)
	_, err := r.db.Update(ctx, r.cfg.MatchingSchema, r.cfg.MatchesTable, fields, filters)
	return err
}

func (r *SupabaseRepository) MarkMessagesRead(
	ctx context.Context,
	matchID,
	currentUserID,
	readAtISO string,
) error {
	filters := url.Values{}
	filters.Set("matchId", "eq."+matchID)
	filters.Set("readAt", "is.null")
	filters.Set("senderId", "neq."+currentUserID)
	_, err := r.db.Update(ctx, r.cfg.MatchingSchema, r.cfg.MessagesTable, map[string]any{
		"readAt": readAtISO,
	}, filters)
	return err
}

func unique(input []string) []string {
	if len(input) == 0 {
		return []string{}
	}
	seen := map[string]struct{}{}
	out := make([]string, 0, len(input))
	for _, raw := range input {
		v := strings.TrimSpace(raw)
		if v == "" {
			continue
		}
		if _, ok := seen[v]; ok {
			continue
		}
		seen[v] = struct{}{}
		out = append(out, v)
	}
	return out
}

func buildIn(values []string) string {
	if len(values) == 0 {
		return "()"
	}
	return "(" + strings.Join(values, ",") + ")"
}

func toString(value any) string {
	switch typed := value.(type) {
	case string:
		return typed
	case fmt.Stringer:
		return typed.String()
	default:
		return strings.TrimSpace(fmt.Sprintf("%v", value))
	}
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

func stringsToAnySlice(input []string) []any {
	if len(input) == 0 {
		return []any{}
	}
	out := make([]any, 0, len(input))
	for _, value := range input {
		out = append(out, value)
	}
	return out
}

func parseTimeAny(value any) *time.Time {
	raw := strings.TrimSpace(toString(value))
	if raw == "" || raw == "<nil>" {
		return nil
	}
	t, err := time.Parse(time.RFC3339, raw)
	if err != nil {
		return nil
	}
	return &t
}

func mockPhotoURL(template, seed string) string {
	trimmed := strings.TrimSpace(template)
	if trimmed == "" {
		trimmed = "https://picsum.photos/seed/%s/720/960"
	}
	if strings.Contains(trimmed, "%s") {
		return fmt.Sprintf(trimmed, seed)
	}
	return trimmed
}

func (r *SupabaseRepository) mockUsers(limit int) []map[string]any {
	if limit <= 0 {
		limit = 25
	}

	femaleCount := r.cfg.MockFemaleUsersCount
	if femaleCount <= 0 {
		femaleCount = 100
	}
	maleCount := r.cfg.MockMaleUsersCount
	if maleCount <= 0 {
		maleCount = 100
	}

	minAge := r.cfg.MockMinAgeYears
	maxAge := r.cfg.MockMaxAgeYears
	if minAge <= 0 {
		minAge = 18
	}
	if maxAge <= 0 {
		maxAge = 45
	}
	if minAge > maxAge {
		minAge, maxAge = maxAge, minAge
	}

	ageSpan := (maxAge - minAge) + 1
	now := time.Now()
	namesFemale := []string{"Anya", "Rhea", "Mira", "Nina", "Sara", "Lia", "Ava", "Zara"}
	namesMale := []string{"Arjun", "Rohan", "Kian", "Noah", "Rey", "Vihaan", "Kabir", "Dev"}
	professions := []string{
		"Product Designer",
		"Software Engineer",
		"Marketing Lead",
		"Doctor",
		"Architect",
		"Data Analyst",
		"Teacher",
		"Photographer",
	}
	educations := []string{"B.Tech", "MBA", "B.Des", "B.Sc", "BA", "M.Tech"}
	bios := []string{
		"Loves weekend coffee walks and meaningful conversations.",
		"Into travel, books, and long evening drives.",
		"Career-focused and looking for genuine connection.",
		"Enjoys food trails, live music, and quality time.",
	}

	profiles := make([]map[string]any, 0, femaleCount+maleCount)
	add := func(prefix, gender string, count int, names []string) {
		for i := 0; i < count; i++ {
			age := minAge + (i % ageSpan)
			dob := time.Date(now.Year()-age, time.January, 1, 0, 0, 0, 0, time.UTC)
			profiles = append(profiles, map[string]any{
				"id":          fmt.Sprintf("%s-%03d", prefix, i+1),
				"name":        names[i%len(names)],
				"dateOfBirth": dob.Format("2006-01-02"),
				"bio":         bios[i%len(bios)],
				"profession":  professions[i%len(professions)],
				"education":   educations[i%len(educations)],
				"isVerified":  i%3 != 0,
				"gender":      gender,
				"isActive":    true,
			})
		}
	}

	add("mock-female", "F", femaleCount, namesFemale)
	add("mock-male", "M", maleCount, namesMale)

	if len(profiles) > limit {
		return profiles[:limit]
	}
	return profiles
}
